import SwiftUI

struct GameView: View {
    @StateObject private var vm: GameViewModel
    let onBack: () -> Void
    @State private var showComplete = false
    @State private var showNewGameConfirm = false

    init(difficulty: Difficulty, onBack: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ZStack {
                BoardView(vm: vm)
                if vm.isGenerating {
                    Color(.systemBackground).opacity(0.85)
                    ProgressView("生成中…")
                }
            }
            .padding(.horizontal, 8)

            controlBar
                .padding(.top, 16)
                .padding(.bottom, 8)

            NumberPadView(vm: vm)
                .padding(.horizontal, 8)
                .padding(.bottom, 28)
        }
        .onChange(of: vm.isComplete) { _, complete in
            if complete { showComplete = true }
        }
        .alert("完成！", isPresented: $showComplete) {
            Button("再来一局") { vm.newGame(difficulty: vm.difficulty) }
            Button("返回菜单") { onBack() }
        } message: {
            Text("用时：\(vm.timeString)\n得分：\(vm.score)\n错误：\(vm.mistakeCount) 次")
        }
        .alert("开始新游戏？", isPresented: $showNewGameConfirm) {
            Button("确定", role: .destructive) { vm.newGame(difficulty: vm.difficulty) }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(vm.difficulty.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vm.timeString)
                    .font(.title2.monospacedDigit().bold())
            }

            Spacer()

            HStack(spacing: 12) {
                Label("\(vm.mistakeCount)", systemImage: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)

                Button {
                    showNewGameConfirm = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
        }
    }

    // MARK: - Control bar

    private var controlBar: some View {
        HStack(spacing: 0) {
            // Hint
            ControlButton(
                icon: "lightbulb.fill",
                label: "提示 \(vm.hintsRemaining)",
                iconColor: vm.hintsRemaining > 0 ? .yellow : .gray,
                disabled: vm.hintsRemaining == 0,
                action: { vm.useHint() }
            )

            // Candidate mode toggle
            ControlButton(
                icon: vm.inputMode == .candidate ? "pencil.circle.fill" : "pencil.circle",
                label: "候选",
                iconColor: vm.inputMode == .candidate ? .orange : .secondary,
                action: { vm.inputMode = vm.inputMode == .normal ? .candidate : .normal }
            )

            // Erase
            ControlButton(
                icon: "delete.left",
                label: "清除",
                iconColor: .secondary,
                action: { vm.clearSelected() }
            )
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Reusable control button

private struct ControlButton: View {
    let icon: String
    let label: String
    let iconColor: Color
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .disabled(disabled)
    }
}
