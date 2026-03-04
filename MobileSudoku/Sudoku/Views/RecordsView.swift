import SwiftUI

struct RecordsView: View {
    @State private var selected: Difficulty = .easy

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("难度", selection: $selected) {
                    ForEach(Difficulty.allCases, id: \.self) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                let list = RecordsStore.shared.records(for: selected)

                if list.isEmpty {
                    Spacer()
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .padding(.bottom, 12)
                    Text("暂无记录")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(Array(list.enumerated()), id: \.element.id) { idx, record in
                            HStack(spacing: 14) {
                                Text(rankLabel(idx + 1))
                                    .font(.title3.bold())
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.timeString)
                                        .font(.title3.monospacedDigit().bold())
                                    Text("\(record.mistakeCount) 次错误 · \(formattedDate(record.date))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if idx == 0 {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("最佳成绩")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f.string(from: date)
    }
}
