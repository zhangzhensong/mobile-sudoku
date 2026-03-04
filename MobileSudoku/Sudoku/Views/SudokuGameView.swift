import SwiftUI

struct GameView: View {
    @ObservedObject var vm: GameViewModel
    let onBack: () -> Void
    @State private var showNewGameConfirm = false
    @State private var showRecords = false
    @State private var winAppear = false
    @State private var loseAppear = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
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

            if vm.isPaused {
                pauseOverlay
            }

            if vm.isComplete {
                winOverlay
            }

            if vm.isGameOver {
                loseOverlay
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && !vm.isPaused { vm.togglePause() }
        }
        .sheet(isPresented: $showRecords) { RecordsView() }
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
                let limitText = vm.maxMistakes > 0 ? "/\(vm.maxMistakes)" : ""
                Label("\(vm.mistakeCount)\(limitText)", systemImage: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)

                Button {
                    vm.togglePause()
                } label: {
                    Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                }
                .disabled(vm.isComplete || vm.isGameOver || vm.isGenerating)

                Button {
                    showNewGameConfirm = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
        }
    }

    // MARK: - Pause overlay

    private var pauseOverlay: some View {
        ZStack {
            Color(.systemBackground)
            VStack(spacing: 20) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("已暂停")
                    .font(.title.bold())
                Button("继续") { vm.togglePause() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Win overlay (normal / new record)

    private var winOverlay: some View {
        Group {
            if vm.isNewBest {
                newRecordOverlay
            } else {
                normalWinOverlay
            }
        }
    }

    // Normal win
    private var normalWinOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.38, blue: 0.95),
                         Color(red: 0.55, green: 0.15, blue: 0.90)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .scaleEffect(winAppear ? 1 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.45), value: winAppear)

                VStack(spacing: 6) {
                    Text("恭喜通关！")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text(praiseText)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    if let rank = vm.completionRank {
                        Text("排名第 \(rank) 名")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
                .opacity(winAppear ? 1 : 0)
                .animation(.easeIn(duration: 0.35).delay(0.2), value: winAppear)

                winStats(tint: .white)
                    .opacity(winAppear ? 1 : 0)
                    .animation(.easeIn(duration: 0.35).delay(0.4), value: winAppear)

                winButtons(tint: .white)
                    .opacity(winAppear ? 1 : 0)
                    .animation(.easeIn(duration: 0.35).delay(0.55), value: winAppear)
            }
            .padding(32)
        }
        .onAppear { winAppear = true }
        .onDisappear { winAppear = false }
    }

    // New record win
    private var newRecordOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.60, blue: 0.05),
                         Color(red: 0.95, green: 0.35, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 110))
                        .foregroundStyle(.yellow.opacity(0.35))
                        .scaleEffect(winAppear ? 1.2 : 0.1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.4), value: winAppear)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)
                        .scaleEffect(winAppear ? 1 : 0.1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.4).delay(0.1), value: winAppear)
                }

                VStack(spacing: 6) {
                    Text("新纪录！")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("你是目前最快的！")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(praiseText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .opacity(winAppear ? 1 : 0)
                .animation(.easeIn(duration: 0.35).delay(0.25), value: winAppear)

                winStats(tint: .white)
                    .opacity(winAppear ? 1 : 0)
                    .animation(.easeIn(duration: 0.35).delay(0.45), value: winAppear)

                winButtons(tint: .white)
                    .opacity(winAppear ? 1 : 0)
                    .animation(.easeIn(duration: 0.35).delay(0.6), value: winAppear)
            }
            .padding(32)
        }
        .onAppear { winAppear = true }
        .onDisappear { winAppear = false }
    }

    private var praiseText: String {
        switch vm.mistakeCount {
        case 0:     return "完美无误，神乎其技！"
        case 1...2: return "凤毛麟角，出类拔萃！"
        case 3...5: return "沉着冷静，实力超群！"
        default:    return "坚持不懈，终成大器！"
        }
    }

    private func winStats(tint: Color) -> some View {
        VStack(spacing: 10) {
            statRow(icon: "clock",      label: "用时", value: vm.timeString,        tint: tint)
            statRow(icon: "star.fill",  label: "得分", value: "\(vm.score)",         tint: tint)
            statRow(icon: "xmark.circle", label: "错误", value: "\(vm.mistakeCount) 次", tint: tint)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }

    private func winButtons(tint: Color) -> some View {
        VStack(spacing: 12) {
            Button("再来一局") { vm.newGame(difficulty: vm.difficulty) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint.opacity(0.25))
            HStack(spacing: 24) {
                Button("查看排行") { showRecords = true }
                    .foregroundStyle(tint.opacity(0.85))
                Button("返回菜单") { onBack() }
                    .foregroundStyle(tint.opacity(0.85))
            }
        }
    }

    private func statRow(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(tint.opacity(0.7))
            Text(label)
                .foregroundStyle(tint.opacity(0.8))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }

    // MARK: - Lose overlay

    private var loseOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.97)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                    .scaleEffect(loseAppear ? 1 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.45), value: loseAppear)

                VStack(spacing: 6) {
                    Text("再接再厉！")
                        .font(.largeTitle.bold())
                    Text("错误次数已达上限")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .opacity(loseAppear ? 1 : 0)
                .animation(.easeIn(duration: 0.35).delay(0.2), value: loseAppear)

                VStack(spacing: 10) {
                    statRow2(label: "用时", value: vm.timeString)
                    statRow2(label: "错误", value: "\(vm.mistakeCount) 次")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                .opacity(loseAppear ? 1 : 0)
                .animation(.easeIn(duration: 0.35).delay(0.35), value: loseAppear)

                VStack(spacing: 12) {
                    Button("再试一次") { vm.newGame(difficulty: vm.difficulty) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    Button("返回菜单") { onBack() }
                        .foregroundStyle(.secondary)
                }
                .opacity(loseAppear ? 1 : 0)
                .animation(.easeIn(duration: 0.35).delay(0.5), value: loseAppear)
            }
            .padding(32)
        }
        .onAppear { loseAppear = true }
        .onDisappear { loseAppear = false }
    }

    private func statRow2(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Control bar

    private var controlBar: some View {
        HStack(spacing: 0) {
            ControlButton(
                icon: "lightbulb.fill",
                label: "提示 \(vm.hintsRemaining)",
                iconColor: vm.hintsRemaining > 0 ? .yellow : .gray,
                disabled: vm.hintsRemaining == 0,
                action: { vm.useHint() }
            )
            ControlButton(
                icon: vm.inputMode == .candidate ? "pencil.circle.fill" : "pencil.circle",
                label: "候选",
                iconColor: vm.inputMode == .candidate ? .orange : .secondary,
                action: { vm.inputMode = vm.inputMode == .normal ? .candidate : .normal }
            )
            ControlButton(
                icon: "delete.left",
                label: "清除",
                iconColor: .secondary,
                action: { vm.clearSelected() }
            )
            ControlButton(
                icon: "arrow.uturn.backward",
                label: "回退",
                iconColor: vm.canUndo ? .primary : .secondary,
                disabled: !vm.canUndo,
                action: { vm.undo() }
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
