import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size / 9

            ZStack(alignment: .topLeading) {
                // Cells
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                CellView(
                                    cell: vm.board[row, col],
                                    background: vm.cellBackground(row: row, col: col),
                                    size: cellSize,
                                    shakeID: vm.shakeID(row: row, col: col),
                                    onTap: { vm.selectCell(row: row, col: col) }
                                )
                            }
                        }
                    }
                }

                // Grid lines drawn on top
                GridLinesView(size: size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Grid lines overlay

struct GridLinesView: View {
    let size: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            let cell = size / 9

            for i in 1..<9 {
                let pos = cell * CGFloat(i)
                let isBoxEdge = i % 3 == 0
                let lineWidth: CGFloat = isBoxEdge ? 2.0 : 0.5
                let color = isBoxEdge ? Color.primary : Color.gray.opacity(0.35)

                // Vertical
                ctx.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: pos, y: 0))
                        p.addLine(to: CGPoint(x: pos, y: size))
                    },
                    with: .color(color),
                    lineWidth: lineWidth
                )
                // Horizontal
                ctx.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: pos))
                        p.addLine(to: CGPoint(x: size, y: pos))
                    },
                    with: .color(color),
                    lineWidth: lineWidth
                )
            }

            // Outer border
            ctx.stroke(
                Path(CGRect(x: 0, y: 0, width: size, height: size)),
                with: .color(.primary),
                lineWidth: 2.5
            )
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}
