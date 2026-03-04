import Foundation

@MainActor
final class ChineseChessViewModel: ObservableObject {
    @Published var board = ChessBoard()
    @Published var selected: (Int, Int)? = nil
    @Published var highlights: [(Int, Int)] = []
    @Published var isThinking = false
    let playerSide: CCPlayer = .red

    func tap(row: Int, col: Int) {
        guard board.winner == nil, !isThinking else { return }
        guard board.currentTurn == playerSide else { return }

        if let sel = selected {
            if highlights.contains(where: { $0.0 == row && $0.1 == col }) {
                _ = board.move(fromRow: sel.0, fromCol: sel.1, toRow: row, toCol: col)
                selected = nil; highlights = []
                if board.winner == nil { triggerAI() }
                return
            }
        }

        if let piece = board.pieces[row][col], piece.player == playerSide {
            selected = (row, col)
            highlights = board.validMoves(row: row, col: col)
        } else {
            selected = nil; highlights = []
        }
    }

    private func triggerAI() {
        isThinking = true
        let snapshot = board
        Task.detached(priority: .userInitiated) {
            let result = ChessAI.bestMove(board: snapshot, for: .black, depth: 3)
            await MainActor.run {
                if let (from, to) = result {
                    _ = self.board.move(fromRow: from.0, fromCol: from.1, toRow: to.0, toCol: to.1)
                }
                self.isThinking = false
            }
        }
    }

    func newGame() {
        board = ChessBoard()
        selected = nil; highlights = []; isThinking = false
    }
}
