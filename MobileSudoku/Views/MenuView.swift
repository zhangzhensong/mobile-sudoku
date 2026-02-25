import SwiftUI

struct MenuView: View {
    let onStart: (Difficulty) -> Void
    @State private var selected: Difficulty = .medium

    var body: some View {
        VStack(spacing: 0) {
            Text("数独")
                .font(.system(size: 56, weight: .bold))
                .padding(.top, 72)

            Text("Sudoku")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 48)

            VStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyRow(difficulty: difficulty, isSelected: selected == difficulty) {
                        selected = difficulty
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onStart(selected)
            } label: {
                Text("开始游戏")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}

private struct DifficultyRow: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : .clear, lineWidth: 2)
            )
        }
        .foregroundStyle(.primary)
    }

    private var subtitleText: String {
        switch difficulty {
        case .easy:   return "~45 clues · up to 5 hints"
        case .medium: return "~35 clues · up to 3 hints"
        case .hard:   return "~29 clues · up to 2 hints"
        case .expert: return "~25 clues · 1 hint only"
        }
    }
}
