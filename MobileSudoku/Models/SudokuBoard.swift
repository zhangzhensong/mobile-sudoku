import Foundation

struct SudokuBoard {
    var cells: [[CellState]]
    let solution: [[Int]]

    init(puzzle: [[Int]], solution: [[Int]]) {
        self.solution = solution
        self.cells = puzzle.map { row in
            row.map { v in CellState(value: v, isGiven: v != 0) }
        }
    }

    // MARK: - Subscript

    subscript(row: Int, col: Int) -> CellState {
        get { cells[row][col] }
        set { cells[row][col] = newValue }
    }

    // MARK: - Queries

    var isSolved: Bool {
        for r in 0..<9 {
            for c in 0..<9 where cells[r][c].value != solution[r][c] { return false }
        }
        return true
    }

    // MARK: - Mutations

    mutating func setValue(_ value: Int, row: Int, col: Int) {
        guard !cells[row][col].isGiven else { return }
        cells[row][col].value = value
        cells[row][col].candidates = []
        if value != 0 {
            for c in 0..<9 { cells[row][c].candidates.remove(value) }
            for r in 0..<9 { cells[r][col].candidates.remove(value) }
            let br = (row / 3) * 3, bc = (col / 3) * 3
            for r in br..<br+3 { for c in bc..<bc+3 { cells[r][c].candidates.remove(value) } }
        }
        validateErrors()
    }

    mutating func clearCell(row: Int, col: Int) {
        guard !cells[row][col].isGiven else { return }
        cells[row][col].value = 0
        cells[row][col].candidates = []
        validateErrors()
    }

    mutating func toggleCandidate(_ num: Int, row: Int, col: Int) {
        guard !cells[row][col].isGiven, cells[row][col].value == 0 else { return }
        if cells[row][col].candidates.contains(num) {
            cells[row][col].candidates.remove(num)
        } else {
            cells[row][col].candidates.insert(num)
        }
    }

    // MARK: - Hint

    /// Returns the coordinates and correct value for a random incorrect/empty cell.
    func hint() -> (row: Int, col: Int, value: Int)? {
        var wrong: [(Int, Int)] = []
        for r in 0..<9 {
            for c in 0..<9 where !cells[r][c].isGiven && cells[r][c].value != solution[r][c] {
                wrong.append((r, c))
            }
        }
        guard let (r, c) = wrong.randomElement() else { return nil }
        return (r, c, solution[r][c])
    }

    // MARK: - Error validation

    mutating func validateErrors() {
        for r in 0..<9 {
            for c in 0..<9 {
                let v = cells[r][c].value
                cells[r][c].isError = v != 0 && !cells[r][c].isGiven && v != solution[r][c]
            }
        }
    }


}
