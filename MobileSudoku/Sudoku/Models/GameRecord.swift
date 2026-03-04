import Foundation

struct GameRecord: Codable, Identifiable {
    let id: UUID
    let elapsedSeconds: Int
    let mistakeCount: Int
    let date: Date

    init(elapsedSeconds: Int, mistakeCount: Int, date: Date = Date()) {
        self.id = UUID()
        self.elapsedSeconds = elapsedSeconds
        self.mistakeCount = mistakeCount
        self.date = date
    }

    var timeString: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }
}
