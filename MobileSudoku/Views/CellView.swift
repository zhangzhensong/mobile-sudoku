import SwiftUI

struct CellView: View {
    let cell: CellState
    let background: Color
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        ZStack {
            background

            if cell.value != 0 {
                Text("\(cell.value)")
                    .font(.system(size: size * 0.48, weight: cell.isGiven ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
            } else if !cell.candidates.isEmpty {
                CandidatesView(candidates: cell.candidates, size: size)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var foregroundColor: Color {
        if cell.isError { return .red }
        return cell.isGiven ? .primary : .blue
    }
}

// MARK: - 3×3 pencil-mark grid

struct CandidatesView: View {
    let candidates: Set<Int>
    let size: CGFloat

    var body: some View {
        let cellW = size / 3
        let fontSize = size * 0.22

        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let num = row * 3 + col + 1
                        Text(candidates.contains(num) ? "\(num)" : "")
                            .font(.system(size: fontSize))
                            .foregroundStyle(Color.gray)
                            .frame(width: cellW, height: cellW)
                    }
                }
            }
        }
    }
}
