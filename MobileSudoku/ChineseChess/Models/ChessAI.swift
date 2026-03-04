import Foundation

struct ChessAI {
    private static let pieceValues: [CCPieceType: Int] = [
        .rook:900, .cannon:450, .horse:400, .elephant:200,
        .advisor:200, .general:10000, .soldier:100
    ]

    private static func sortedMoves(board: ChessBoard, player: CCPlayer) -> [((Int,Int),(Int,Int))] {
        var moves: [((Int,Int),(Int,Int))] = []
        for r in 0..<ChessBoard.rows {
            for c in 0..<ChessBoard.cols {
                guard let p = board.pieces[r][c], p.player == player else { continue }
                for (nr, nc) in board.validMoves(row: r, col: c) {
                    moves.append(((r,c),(nr,nc)))
                }
            }
        }
        moves.sort { a, b in
            let va = board.pieces[a.1.0][a.1.1].map { pieceValues[$0.type] ?? 0 } ?? 0
            let vb = board.pieces[b.1.0][b.1.1].map { pieceValues[$0.type] ?? 0 } ?? 0
            return va > vb
        }
        return moves
    }

    static func bestMove(board: ChessBoard, for player: CCPlayer, depth: Int = 3) -> ((Int,Int),(Int,Int))? {
        var best: ((Int,Int),(Int,Int))? = nil
        var bestScore = player == .red ? Int.min : Int.max

        for ((fr,fc),(tr,tc)) in sortedMoves(board: board, player: player) {
            var bCopy = board
            _ = bCopy.move(fromRow: fr, fromCol: fc, toRow: tr, toCol: tc)
            let score = minimax(board: bCopy, depth: depth-1, alpha: Int.min, beta: Int.max,
                               isMaximizing: player == .black)
            if player == .red {
                if score > bestScore { bestScore = score; best = ((fr,fc),(tr,tc)) }
            } else {
                if score < bestScore { bestScore = score; best = ((fr,fc),(tr,tc)) }
            }
        }
        return best
    }

    private static func minimax(board: ChessBoard, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        if depth == 0 || board.winner != nil { return board.evaluate() }
        var alpha = alpha, beta = beta
        let player: CCPlayer = isMaximizing ? .red : .black
        var bestScore = isMaximizing ? Int.min : Int.max

        for ((fr,fc),(tr,tc)) in sortedMoves(board: board, player: player) {
            var bCopy = board
            _ = bCopy.move(fromRow: fr, fromCol: fc, toRow: tr, toCol: tc)
            let score = minimax(board: bCopy, depth: depth-1, alpha: alpha, beta: beta,
                               isMaximizing: !isMaximizing)
            if isMaximizing {
                bestScore = max(bestScore, score)
                alpha = max(alpha, score)
            } else {
                bestScore = min(bestScore, score)
                beta = min(beta, score)
            }
            if beta <= alpha { break }
        }
        return bestScore
    }
}
