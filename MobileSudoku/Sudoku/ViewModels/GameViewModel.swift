import Foundation
import Combine
import SwiftUI

enum InputMode {
    case normal
    case candidate
}

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published state

    @Published var board: SudokuBoard
    @Published var selectedCell: (row: Int, col: Int)? = nil
    @Published var inputMode: InputMode = .normal
    @Published var elapsedSeconds: Int = 0
    @Published var hintsRemaining: Int
    @Published var isComplete: Bool = false
    @Published var isGameOver: Bool = false
    @Published var completionRank: Int? = nil
    @Published var isNewBest: Bool = false
    @Published var mistakeCount: Int = 0
    @Published private(set) var difficulty: Difficulty
    @Published var isGenerating: Bool = true
    @Published var isPaused: Bool = false
    @Published var cellShakeTriggers: [String: Int] = [:]

    let maxMistakes: Int  // 0 = unlimited

    // MARK: - Private

    private var timer: AnyCancellable?

    private struct GameSnapshot {
        let board: SudokuBoard
        let hintsRemaining: Int
    }
    private var undoStack: [GameSnapshot] = []

    // MARK: - Init

    init(difficulty: Difficulty = .medium, maxMistakes: Int = 0) {
        self.difficulty = difficulty
        self.maxMistakes = maxMistakes
        let empty = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        self.board = SudokuBoard(puzzle: empty, solution: empty)
        self.hintsRemaining = difficulty.maxHints
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                SudokuGenerator.generate(difficulty: difficulty)
            }.value
            guard let self else { return }
            self.board = SudokuBoard(puzzle: result.puzzle, solution: result.solution)
            self.isGenerating = false
            self.startTimer()
        }
    }

    // MARK: - User actions

    func selectCell(row: Int, col: Int) {
        if selectedCell?.row == row && selectedCell?.col == col {
            selectedCell = nil
        } else {
            selectedCell = (row, col)
        }
    }

    func inputNumber(_ num: Int) {
        guard !isComplete, !isGameOver else { return }
        guard let (row, col) = selectedCell else { return }
        guard !board[row, col].isGiven else { return }

        switch inputMode {
        case .normal:
            guard board[row, col].value != num else { return }
            saveUndo()
            if board.solution[row][col] != num { mistakeCount += 1 }
            board.setValue(num, row: row, col: col)
            if maxMistakes > 0 && mistakeCount >= maxMistakes {
                isGameOver = true
                stopTimer()
                return
            }
            checkCompletion()
        case .candidate:
            guard board[row, col].value == 0 else { return }
            if !board[row, col].candidates.contains(num) {
                let conflicts = conflictingCells(for: num, row: row, col: col)
                if !conflicts.isEmpty {
                    for (r, c) in conflicts {
                        cellShakeTriggers["\(r)-\(c)", default: 0] += 1
                    }
                    return
                }
            }
            saveUndo()
            board.toggleCandidate(num, row: row, col: col)
        }
    }

    func clearSelected() {
        guard !isComplete, !isGameOver else { return }
        guard let (row, col) = selectedCell else { return }
        saveUndo()
        board.clearCell(row: row, col: col)
    }

    func useHint() {
        guard !isGameOver, hintsRemaining > 0, let hint = board.hint() else { return }
        saveUndo()
        hintsRemaining -= 1
        selectedCell = (hint.row, hint.col)
        board.setValue(hint.value, row: hint.row, col: hint.col)
        checkCompletion()
    }

    func undo() {
        guard let snap = undoStack.popLast() else { return }
        board = snap.board
        hintsRemaining = snap.hintsRemaining
        isComplete = false
        // mistakeCount is intentionally NOT restored
    }

    var canUndo: Bool { !undoStack.isEmpty }

    func togglePause() {
        guard !isComplete, !isGameOver, !isGenerating else { return }
        isPaused.toggle()
        isPaused ? stopTimer() : startTimer()
    }

    func newGame(difficulty: Difficulty) {
        stopTimer()
        self.difficulty = difficulty
        let empty = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        board = SudokuBoard(puzzle: empty, solution: empty)
        hintsRemaining = difficulty.maxHints
        selectedCell = nil
        elapsedSeconds = 0
        isComplete = false
        isGameOver = false
        completionRank = nil
        isNewBest = false
        mistakeCount = 0
        inputMode = .normal
        isPaused = false
        isGenerating = true
        undoStack = []
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                SudokuGenerator.generate(difficulty: difficulty)
            }.value
            guard let self else { return }
            self.board = SudokuBoard(puzzle: result.puzzle, solution: result.solution)
            self.isGenerating = false
            self.startTimer()
        }
    }

    // MARK: - Derived values

    func shakeID(row: Int, col: Int) -> Int {
        cellShakeTriggers["\(row)-\(col)"] ?? 0
    }

    private func conflictingCells(for num: Int, row: Int, col: Int) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for c in 0..<9 where c != col && board[row, c].value == num { result.append((row, c)) }
        for r in 0..<9 where r != row && board[r, col].value == num { result.append((r, col)) }
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 where (r != row || c != col) && board[r, c].value == num {
                if !result.contains(where: { $0.0 == r && $0.1 == c }) { result.append((r, c)) }
            }
        }
        return result
    }

    var completedNumbers: Set<Int> {
        var counts = [Int: Int]()
        for r in 0..<9 {
            for c in 0..<9 {
                let cell = board[r, c]
                if cell.value != 0 && cell.value == board.solution[r][c] {
                    counts[cell.value, default: 0] += 1
                }
            }
        }
        return Set(counts.compactMap { $0.value == 9 ? $0.key : nil })
    }

    var timeString: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    var score: Int {
        let timePenalty    = min(elapsedSeconds * 2, difficulty.scoreBase / 2)
        let mistakePenalty = mistakeCount * 50
        return max(0, difficulty.scoreBase - timePenalty - mistakePenalty)
    }

    // MARK: - Cell background helper

    func cellBackground(row: Int, col: Int) -> Color {
        guard let sel = selectedCell else { return .clear }

        if sel.row == row && sel.col == col {
            return Color.blue.opacity(0.35)
        }
        let sameGroup = sel.row == row
            || sel.col == col
            || (sel.row / 3 == row / 3 && sel.col / 3 == col / 3)
        if sameGroup { return Color.blue.opacity(0.10) }

        let selVal = board[sel.row, sel.col].value
        if selVal != 0 && board[row, col].value == selVal {
            return Color.blue.opacity(0.18)
        }
        return .clear
    }

    // MARK: - Private helpers

    private func saveUndo() {
        undoStack.append(GameSnapshot(board: board, hintsRemaining: hintsRemaining))
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func checkCompletion() {
        if board.isSolved {
            isComplete = true
            stopTimer()
            let record = GameRecord(elapsedSeconds: elapsedSeconds, mistakeCount: mistakeCount)
            let result = RecordsStore.shared.add(record, for: difficulty)
            completionRank = result.rank
            isNewBest = result.isNewBest
        }
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.elapsedSeconds += 1 }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}
