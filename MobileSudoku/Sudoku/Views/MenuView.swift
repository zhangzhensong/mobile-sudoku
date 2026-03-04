import SwiftUI

struct MenuView: View {
    @Binding var colorSchemePreference: String
    @Binding var selectedDifficulty: Difficulty
    @Binding var maxMistakes: Int
    let onStart: (Difficulty) -> Void

    @State private var showRecords = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showRecords = true
                } label: {
                    Image(systemName: "trophy")
                        .font(.title2)
                        .padding(16)
                }
                Spacer()
                Button {
                    switch colorSchemePreference {
                    case "system": colorSchemePreference = "light"
                    case "light":  colorSchemePreference = "dark"
                    default:       colorSchemePreference = "system"
                    }
                } label: {
                    Image(systemName: colorSchemeIcon)
                        .font(.title2)
                        .padding(16)
                }
            }

            Text("数独")
                .font(.system(size: 56, weight: .bold))
                .padding(.top, 16)

            Text("Sudoku")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyRow(difficulty: difficulty, isSelected: selectedDifficulty == difficulty) {
                        selectedDifficulty = difficulty
                    }
                }
            }
            .padding(.horizontal, 32)

            // Error limit setting
            HStack {
                Text("错误上限")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(maxMistakes == 0 ? "无限制" : "\(maxMistakes) 次")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Stepper("", value: $maxMistakes, in: 0...10)
                    .labelsHidden()
            }
            .padding()
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()

            Button {
                onStart(selectedDifficulty)
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
        .sheet(isPresented: $showRecords) { RecordsView() }
    }

    private var colorSchemeIcon: String {
        switch colorSchemePreference {
        case "light": return "sun.max.fill"
        case "dark":  return "moon.fill"
        default:      return "circle.lefthalf.filled"
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
