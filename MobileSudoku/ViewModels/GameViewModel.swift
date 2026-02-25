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
    @Published var mistakeCount: Int = 0
    @Published private(set) var difficulty: Difficulty
    @Published var isGenerating: Bool = true

    // MARK: - Private

    private var timer: AnyCancellable?

    // MARK: - Init

    init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
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
        guard let (row, col) = selectedCell else { return }
        guard !board[row, col].isGiven else { return }

        switch inputMode {
        case .normal:
            guard board[row, col].value != num else { return }
            if board.solution[row][col] != num { mistakeCount += 1 }
            board.setValue(num, row: row, col: col)
            checkCompletion()
        case .candidate:
            board.toggleCandidate(num, row: row, col: col)
        }
    }

    func clearSelected() {
        guard let (row, col) = selectedCell else { return }
        board.clearCell(row: row, col: col)
    }

    func useHint() {
        guard hintsRemaining > 0, let hint = board.hint() else { return }
        hintsRemaining -= 1
        selectedCell = (hint.row, hint.col)
        board.setValue(hint.value, row: hint.row, col: hint.col)
        checkCompletion()
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
        mistakeCount = 0
        inputMode = .normal
        isGenerating = true
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

    var timeString: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    var score: Int {
        let timePenalty    = min(elapsedSeconds * 2, difficulty.scoreBase / 2)
        let mistakePenalty = mistakeCount * 50
        return max(0, difficulty.scoreBase - timePenalty - mistakePenalty)
    }

    // MARK: - Cell background helper (used in BoardView)

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

    private func checkCompletion() {
        if board.isSolved {
            isComplete = true
            stopTimer()
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
