import Foundation

struct SudokuGenerator {

    /// Generates a Sudoku puzzle and its unique solution for the given difficulty.
    static func generate(difficulty: Difficulty) -> (puzzle: [[Int]], solution: [[Int]]) {
        let solution = buildSolution()
        let puzzle   = dig(solution: solution, difficulty: difficulty)
        return (puzzle, solution)
    }

    // MARK: - Build a complete valid solution

    private static func buildSolution() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        fill(&grid)
        return grid
    }

    /// Randomized backtracking fill of an empty grid.
    @discardableResult
    private static func fill(_ grid: inout [[Int]]) -> Bool {
        guard let (row, col) = firstEmpty(grid) else { return true }
        for num in (1...9).shuffled() {
            if SudokuSolver.isValid(grid, row: row, col: col, num: num) {
                grid[row][col] = num
                if fill(&grid) { return true }
                grid[row][col] = 0
            }
        }
        return false
    }

    // MARK: - Dig holes while preserving unique solution

    private static func dig(solution: [[Int]], difficulty: Difficulty) -> [[Int]] {
        var puzzle    = solution
        var positions = (0..<81).map { ($0 / 9, $0 % 9) }.shuffled()
        var removed   = 0

        for (row, col) in positions {
            guard removed < difficulty.cluesToRemove else { break }
            let backup = puzzle[row][col]
            puzzle[row][col] = 0
            if SudokuSolver.hasUniqueSolution(puzzle) {
                removed += 1
            } else {
                puzzle[row][col] = backup // restore — would create ambiguity
            }
        }
        return puzzle
    }

    // MARK: - Helpers

    private static func firstEmpty(_ grid: [[Int]]) -> (Int, Int)? {
        for r in 0..<9 {
            for c in 0..<9 where grid[r][c] == 0 { return (r, c) }
        }
        return nil
    }
}
