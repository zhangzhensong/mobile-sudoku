import SwiftUI

struct CellView: View {
    let cell: CellState
    let background: Color
    let size: CGFloat
    let shakeID: Int
    let onTap: () -> Void

    @State private var shakes: CGFloat = 0

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
        .modifier(ShakeEffect(shakes: shakes))
        .onTapGesture(perform: onTap)
        .onChange(of: shakeID) { _, newID in
            guard newID > 0 else { return }
            shakes = 0
            withAnimation(.linear(duration: 0.4)) { shakes = 1 }
        }
    }

    private var foregroundColor: Color {
        if cell.isError { return .red }
        return cell.isGiven ? .primary : .blue
    }
}

// MARK: - Shake animation

private struct ShakeEffect: AnimatableModifier {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func body(content: Content) -> some View {
        content.offset(x: sin(shakes * .pi * 4) * 5)
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
