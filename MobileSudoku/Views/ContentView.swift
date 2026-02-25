import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    @State private var currentVM: GameViewModel? = nil
    @State private var showContinueAlert = false
    @State private var pendingDifficulty: Difficulty = .medium
    @AppStorage("colorScheme")   private var colorSchemePreference: String = "system"
    @AppStorage("maxMistakes")   private var maxMistakes: Int = 3
    @AppStorage("lastDifficulty") private var lastDifficultyRaw: String = Difficulty.medium.rawValue

    private var menuDifficulty: Binding<Difficulty> {
        Binding(
            get: { Difficulty(rawValue: lastDifficultyRaw) ?? .medium },
            set: { lastDifficultyRaw = $0.rawValue }
        )
    }

    private var preferredScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        Group {
            if showGame, let vm = currentVM {
                GameView(vm: vm) {
                    if !vm.isPaused && !vm.isComplete && !vm.isGameOver { vm.togglePause() }
                    menuDifficulty.wrappedValue = vm.difficulty
                    showGame = false
                }
            } else {
                MenuView(
                    colorSchemePreference: $colorSchemePreference,
                    selectedDifficulty: menuDifficulty,
                    maxMistakes: $maxMistakes
                ) { difficulty in
                    if let vm = currentVM,
                       vm.difficulty == difficulty,
                       !vm.isComplete,
                       !vm.isGameOver,
                       !vm.isGenerating {
                        pendingDifficulty = difficulty
                        showContinueAlert = true
                    } else {
                        startNew(difficulty: difficulty)
                    }
                }
                .alert("继续上次游戏？", isPresented: $showContinueAlert) {
                    Button("继续") { showGame = true }
                    Button("新游戏", role: .destructive) { startNew(difficulty: pendingDifficulty) }
                    Button("取消", role: .cancel) {}
                }
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    private func startNew(difficulty: Difficulty) {
        menuDifficulty.wrappedValue = difficulty
        currentVM = GameViewModel(difficulty: difficulty, maxMistakes: maxMistakes)
        showGame = true
    }
}
