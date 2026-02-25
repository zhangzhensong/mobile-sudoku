import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    @State private var selectedDifficulty: Difficulty = .medium

    var body: some View {
        if showGame {
            GameView(difficulty: selectedDifficulty) {
                showGame = false
            }
        } else {
            MenuView { difficulty in
                selectedDifficulty = difficulty
                showGame = true
            }
        }
    }
}
