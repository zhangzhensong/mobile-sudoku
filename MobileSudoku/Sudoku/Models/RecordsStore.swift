import Foundation

final class RecordsStore {
    static let shared = RecordsStore()
    private init() {}

    func records(for difficulty: Difficulty) -> [GameRecord] {
        let key = "records_\(difficulty.rawValue)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([GameRecord].self, from: data)
        else { return [] }
        return list
    }

    /// Saves the record and returns (rank, isNewBest).
    /// rank is 1-based; nil if didn't make top 10.
    /// isNewBest is true if it's strictly faster than the previous #1 (or first-ever record).
    @discardableResult
    func add(_ record: GameRecord, for difficulty: Difficulty) -> (rank: Int?, isNewBest: Bool) {
        let existing = records(for: difficulty)
        let previousBest = existing.first?.elapsedSeconds

        var list = existing
        list.append(record)
        list.sort { $0.elapsedSeconds < $1.elapsedSeconds }

        let idx = list.firstIndex(where: { $0.id == record.id }) ?? (list.count - 1)
        let rank = idx + 1
        let top10 = Array(list.prefix(10))

        let key = "records_\(difficulty.rawValue)"
        if let data = try? JSONEncoder().encode(top10) {
            UserDefaults.standard.set(data, forKey: key)
        }

        let isNewBest = previousBest == nil || record.elapsedSeconds < previousBest!
        return (rank <= 10 ? rank : nil, isNewBest)
    }
}
