import Foundation

enum CCPlayer { case red, black }

enum CCPieceType: Int {
    case general = 0  // 将/帅
    case advisor    // 士
    case elephant   // 象
    case horse      // 马
    case rook       // 车
    case cannon     // 炮
    case soldier    // 兵/卒
}

struct CCPiece {
    let type: CCPieceType
    let player: CCPlayer
}

struct ChessBoard {
    // 9 columns (0-8), 10 rows (0-9)
    // Red occupies rows 5-9 (bottom), Black occupies rows 0-4 (top)
    // River between rows 4-5

    static let cols = 9
    static let rows = 10

    var pieces: [[CCPiece?]]
    var currentTurn: CCPlayer = .red
    var winner: CCPlayer? = nil
    var lastMove: ((Int,Int),(Int,Int))? = nil  // from, to

    init() {
        pieces = Array(repeating: Array(repeating: nil, count: Self.cols), count: Self.rows)
        setup()
    }

    private mutating func setup() {
        // Black pieces (rows 0-3)
        let blackBack: [CCPieceType] = [.rook,.horse,.elephant,.advisor,.general,.advisor,.elephant,.horse,.rook]
        for col in 0..<9 { pieces[0][col] = CCPiece(type: blackBack[col], player: .black) }
        pieces[2][1] = CCPiece(type: .cannon, player: .black)
        pieces[2][7] = CCPiece(type: .cannon, player: .black)
        for col in [0,2,4,6,8] { pieces[3][col] = CCPiece(type: .soldier, player: .black) }

        // Red pieces (rows 6-9)
        let redBack: [CCPieceType] = [.rook,.horse,.elephant,.advisor,.general,.advisor,.elephant,.horse,.rook]
        for col in 0..<9 { pieces[9][col] = CCPiece(type: redBack[col], player: .red) }
        pieces[7][1] = CCPiece(type: .cannon, player: .red)
        pieces[7][7] = CCPiece(type: .cannon, player: .red)
        for col in [0,2,4,6,8] { pieces[6][col] = CCPiece(type: .soldier, player: .red) }
    }

    func validMoves(row: Int, col: Int) -> [(Int, Int)] {
        guard let piece = pieces[row][col] else { return [] }
        var moves: [(Int, Int)] = []

        switch piece.type {
        case .general:
            moves = generalMoves(row: row, col: col, player: piece.player)
        case .advisor:
            moves = advisorMoves(row: row, col: col, player: piece.player)
        case .elephant:
            moves = elephantMoves(row: row, col: col, player: piece.player)
        case .horse:
            moves = horseMoves(row: row, col: col)
        case .rook:
            moves = rookMoves(row: row, col: col)
        case .cannon:
            moves = cannonMoves(row: row, col: col)
        case .soldier:
            moves = soldierMoves(row: row, col: col, player: piece.player)
        }

        // Filter moves that would leave own general in check
        return moves.filter { (nr, nc) in
            var testBoard = self
            testBoard.pieces[nr][nc] = testBoard.pieces[row][col]
            testBoard.pieces[row][col] = nil
            return !testBoard.isInCheck(player: piece.player)
        }
    }

    private func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < Self.rows && c >= 0 && c < Self.cols
    }

    private func generalMoves(row: Int, col: Int, player: CCPlayer) -> [(Int,Int)] {
        // Palace: rows 0-2 cols 3-5 (black) / rows 7-9 cols 3-5 (red)
        let (minRow, maxRow) = player == .red ? (7,9) : (0,2)
        var moves: [(Int,Int)] = []
        for (dr,dc) in [(-1,0),(1,0),(0,-1),(0,1)] {
            let nr=row+dr, nc=col+dc
            if nr>=minRow && nr<=maxRow && nc>=3 && nc<=5 {
                if pieces[nr][nc]?.player != player { moves.append((nr,nc)) }
            }
        }
        // Flying general: if no piece between generals in same column
        // (handled in isInCheck)
        return moves
    }

    private func advisorMoves(row: Int, col: Int, player: CCPlayer) -> [(Int,Int)] {
        let (minRow, maxRow) = player == .red ? (7,9) : (0,2)
        var moves: [(Int,Int)] = []
        for (dr,dc) in [(-1,-1),(-1,1),(1,-1),(1,1)] {
            let nr=row+dr, nc=col+dc
            if nr>=minRow && nr<=maxRow && nc>=3 && nc<=5 {
                if pieces[nr][nc]?.player != player { moves.append((nr,nc)) }
            }
        }
        return moves
    }

    private func elephantMoves(row: Int, col: Int, player: CCPlayer) -> [(Int,Int)] {
        // Elephant can't cross river
        let maxRow = player == .red ? 9 : 4
        let minRow = player == .red ? 5 : 0
        var moves: [(Int,Int)] = []
        for (dr,dc) in [(-2,-2),(-2,2),(2,-2),(2,2)] {
            let nr=row+dr, nc=col+dc
            // Block (leg) check
            let mr=row+dr/2, mc=col+dc/2
            guard inBounds(nr,nc) && nr>=minRow && nr<=maxRow else { continue }
            guard pieces[mr][mc] == nil else { continue }
            if pieces[nr][nc]?.player != player { moves.append((nr,nc)) }
        }
        return moves
    }

    private func horseMoves(row: Int, col: Int) -> [(Int,Int)] {
        let player = pieces[row][col]!.player
        var moves: [(Int,Int)] = []
        // Horse moves: 1 step + 1 diagonal (with blocking)
        let legDirs: [(Int,Int,Int,Int)] = [
            (-1,0,-2,-1),(-1,0,-2,1),(1,0,2,-1),(1,0,2,1),
            (0,-1,-1,-2),(0,-1,1,-2),(0,1,-1,2),(0,1,1,2)
        ]
        for (lr,lc,mr,mc) in legDirs {
            let legR=row+lr, legC=col+lc
            let destR=row+mr, destC=col+mc
            guard inBounds(destR,destC) else { continue }
            guard pieces[legR][legC] == nil else { continue }
            if pieces[destR][destC]?.player != player { moves.append((destR,destC)) }
        }
        return moves
    }

    private func rookMoves(row: Int, col: Int) -> [(Int,Int)] {
        let player = pieces[row][col]!.player
        var moves: [(Int,Int)] = []
        for (dr,dc) in [(-1,0),(1,0),(0,-1),(0,1)] {
            var r=row+dr, c=col+dc
            while inBounds(r,c) {
                if let target = pieces[r][c] {
                    if target.player != player { moves.append((r,c)) }
                    break
                }
                moves.append((r,c)); r+=dr; c+=dc
            }
        }
        return moves
    }

    private func cannonMoves(row: Int, col: Int) -> [(Int,Int)] {
        let player = pieces[row][col]!.player
        var moves: [(Int,Int)] = []
        for (dr,dc) in [(-1,0),(1,0),(0,-1),(0,1)] {
            var r=row+dr, c=col+dc
            var foundPlatform = false
            while inBounds(r,c) {
                if !foundPlatform {
                    if pieces[r][c] == nil { moves.append((r,c)) }
                    else { foundPlatform = true }
                } else {
                    if let target = pieces[r][c] {
                        if target.player != player { moves.append((r,c)) }
                        break
                    }
                }
                r+=dr; c+=dc
            }
        }
        return moves
    }

    private func soldierMoves(row: Int, col: Int, player: CCPlayer) -> [(Int,Int)] {
        var moves: [(Int,Int)] = []
        // Red soldiers move up (decreasing row), black soldiers move down
        let fwd = player == .red ? -1 : 1
        let nr=row+fwd, nc=col
        if inBounds(nr,nc) && pieces[nr][nc]?.player != player { moves.append((nr,nc)) }
        // Can move sideways after crossing river
        let crossedRiver = player == .red ? row < 5 : row >= 5
        if crossedRiver {
            for dc in [-1,1] {
                let sc=col+dc
                if inBounds(row,sc) && pieces[row][sc]?.player != player { moves.append((row,sc)) }
            }
        }
        return moves
    }

    func isInCheck(player: CCPlayer) -> Bool {
        // Find general position
        var generalRow = -1, generalCol = -1
        for r in 0..<Self.rows { for c in 0..<Self.cols {
            if let piece = pieces[r][c], piece.type == .general, piece.player == player {
                generalRow = r; generalCol = c
            }
        }}
        guard generalRow >= 0 else { return true }

        // Check if any opponent can capture the general
        let opp: CCPlayer = player == .red ? .black : .red
        for r in 0..<Self.rows { for c in 0..<Self.cols {
            if let piece = pieces[r][c], piece.player == opp {
                // Use raw move generation (no filter) to avoid recursion
                var rawMoves: [(Int,Int)] = []
                switch piece.type {
                case .general: rawMoves = generalMoves(row: r, col: c, player: opp)
                case .advisor: rawMoves = advisorMoves(row: r, col: c, player: opp)
                case .elephant: rawMoves = elephantMoves(row: r, col: c, player: opp)
                case .horse: rawMoves = horseMoves(row: r, col: c)
                case .rook: rawMoves = rookMoves(row: r, col: c)
                case .cannon: rawMoves = cannonMoves(row: r, col: c)
                case .soldier: rawMoves = soldierMoves(row: r, col: c, player: opp)
                }
                if rawMoves.contains(where: { $0.0 == generalRow && $0.1 == generalCol }) { return true }
            }
        }}

        // Flying general check
        if let oppGenPos = findGeneral(player: opp) {
            if oppGenPos.1 == generalCol {
                var blocked = false
                let minR = min(generalRow, oppGenPos.0)+1
                let maxR = max(generalRow, oppGenPos.0)
                for r in minR..<maxR { if pieces[r][generalCol] != nil { blocked = true; break } }
                if !blocked { return true }
            }
        }

        return false
    }

    private func findGeneral(player: CCPlayer) -> (Int,Int)? {
        for r in 0..<Self.rows { for c in 0..<Self.cols {
            if let piece = pieces[r][c], piece.type == .general, piece.player == player {
                return (r,c)
            }
        }}
        return nil
    }

    mutating func move(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> Bool {
        guard let piece = pieces[fromRow][fromCol], piece.player == currentTurn else { return false }
        let valid = validMoves(row: fromRow, col: fromCol)
        guard valid.contains(where: { $0.0 == toRow && $0.1 == toCol }) else { return false }

        // Capture general = win
        if let target = pieces[toRow][toCol], target.type == .general {
            winner = piece.player
        }

        pieces[toRow][toCol] = piece
        pieces[fromRow][fromCol] = nil
        lastMove = ((fromRow,fromCol),(toRow,toCol))

        let opp: CCPlayer = piece.player == .red ? .black : .red
        currentTurn = opp

        // Check if opponent has no valid moves (checkmate simplified: no moves)
        return true
    }

    // Piece-square tables: row 0 = own back rank, row 9 = opponent's back rank
    static let horsePST: [[Int]] = [
        [ 0,  0,  0,  0,  0,  0,  0,  0,  0],
        [ 0,  2,  4,  4,  4,  4,  4,  2,  0],
        [ 0,  2,  6,  8,  6,  8,  6,  2,  0],
        [ 0,  4,  6,  8, 10,  8,  6,  4,  0],
        [ 2,  4,  8, 10, 10, 10,  8,  4,  2],
        [ 2,  6,  8, 10, 10, 10,  8,  6,  2],
        [ 4,  6,  8,  8,  8,  8,  8,  6,  4],
        [ 2,  4,  6,  6,  6,  6,  6,  4,  2],
        [ 0,  4,  4,  6,  6,  6,  4,  4,  0],
        [ 0,  0,  4,  4,  0,  4,  4,  0,  0]
    ]

    static let cannonPST: [[Int]] = [
        [ 0,  2,  4,  2,  0,  2,  4,  2,  0],
        [ 0,  2,  4,  4,  2,  4,  4,  2,  0],
        [ 0,  4,  6,  4,  4,  4,  6,  4,  0],
        [ 2,  4,  6,  6,  6,  6,  6,  4,  2],
        [ 2,  4,  6,  8,  8,  8,  6,  4,  2],
        [ 2,  4,  6,  8, 10,  8,  6,  4,  2],
        [ 2,  4,  6,  8, 10,  8,  6,  4,  2],
        [ 0,  4,  6,  6,  8,  6,  6,  4,  0],
        [ 0,  2,  4,  4,  6,  4,  4,  2,  0],
        [ 0,  0,  2,  4,  4,  4,  2,  0,  0]
    ]

    static let rookPST: [[Int]] = [
        [-2,  4,  2,  0,  0,  0,  2,  4, -2],
        [ 4,  8,  6,  4,  4,  4,  6,  8,  4],
        [ 0,  6,  4,  4,  4,  4,  4,  6,  0],
        [ 0,  4,  4,  4,  4,  4,  4,  4,  0],
        [-2,  4,  4,  4,  4,  4,  4,  4, -2],
        [-2,  4,  4,  4,  4,  4,  4,  4, -2],
        [ 0,  4,  4,  4,  4,  4,  4,  4,  0],
        [ 0,  6,  4,  4,  4,  4,  4,  6,  0],
        [ 4,  8,  6,  4,  4,  4,  6,  8,  4],
        [-2,  4,  2,  0,  0,  0,  2,  4, -2]
    ]

    static let soldierPST: [[Int]] = [
        [ 0,  0,  0,  0,  0,  0,  0,  0,  0],
        [ 0,  0,  0,  0,  0,  0,  0,  0,  0],
        [ 0,  0,  0,  0,  0,  0,  0,  0,  0],
        [ 0,  0,  0,  0,  0,  0,  0,  0,  0],
        [ 0,  0,  0,  0,  0,  0,  0,  0,  0],
        [ 0,  2,  4,  6, 10,  6,  4,  2,  0],
        [ 4,  8, 10, 12, 16, 12, 10,  8,  4],
        [10, 14, 18, 20, 24, 20, 18, 14, 10],
        [12, 16, 20, 22, 26, 22, 20, 16, 12],
        [14, 18, 22, 24, 28, 24, 22, 18, 14]
    ]

    func evaluate() -> Int {
        let values: [CCPieceType: Int] = [
            .rook:900, .cannon:450, .horse:400, .elephant:200,
            .advisor:200, .general:10000, .soldier:100
        ]
        var score = 0
        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                guard let piece = pieces[r][c] else { continue }
                let base = values[piece.type] ?? 0
                let pstRow = piece.player == .red ? 9 - r : r
                let pst: Int
                switch piece.type {
                case .horse:   pst = Self.horsePST[pstRow][c]
                case .cannon:  pst = Self.cannonPST[pstRow][c]
                case .rook:    pst = Self.rookPST[pstRow][c]
                case .soldier: pst = Self.soldierPST[pstRow][c]
                default:       pst = 0
                }
                score += piece.player == .red ? (base + pst) : -(base + pst)
            }
        }
        return score
    }
}
