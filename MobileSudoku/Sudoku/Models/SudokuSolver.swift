import Foundation

struct SudokuSolver {

    // MARK: - Unique solution check

    /// Returns true if the board has exactly one solution.
    static func hasUniqueSolution(_ board: [[Int]]) -> Bool {
        var grid = board
        var count = 0
        countSolutions(&grid, count: &count)
        return count == 1
    }

    /// Backtracking search that counts solutions up to 2 (stops early when >1 found).
    @discardableResult
    private static func countSolutions(_ grid: inout [[Int]], count: inout Int) -> Bool {
        guard let (row, col) = firstEmpty(grid) else {
            count += 1
            return count > 1 // stop early once a second solution is found
        }
        for num in 1...9 {
            if isValid(grid, row: row, col: col, num: num) {
                grid[row][col] = num
                if countSolutions(&grid, count: &count) { return true }
                grid[row][col] = 0
            }
        }
        return false
    }

    // MARK: - Solution finder

    /// Returns the first found solution, or nil if unsolvable.
    static func solution(for board: [[Int]]) -> [[Int]]? {
        var grid = board
        return solve(&grid) ? grid : nil
    }

    @discardableResult
    private static func solve(_ grid: inout [[Int]]) -> Bool {
        guard let (row, col) = firstEmpty(grid) else { return true }
        for num in 1...9 {
            if isValid(grid, row: row, col: col, num: num) {
                grid[row][col] = num
                if solve(&grid) { return true }
                grid[row][col] = 0
            }
        }
        return false
    }

    // MARK: - Validation

    static func isValid(_ grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Row
        if grid[row].contains(num) { return false }
        // Column
        for r in 0..<9 where grid[r][col] == num { return false }
        // 3×3 box
        let br = (row / 3) * 3
        let bc = (col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 where grid[r][c] == num { return false }
        }
        return true
    }

    // MARK: - Helpers

    private static func firstEmpty(_ grid: [[Int]]) -> (Int, Int)? {
        for r in 0..<9 {
            for c in 0..<9 where grid[r][c] == 0 { return (r, c) }
        }
        return nil
    }
}
