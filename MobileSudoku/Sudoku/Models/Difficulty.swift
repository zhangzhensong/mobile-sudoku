import Foundation

enum Difficulty: String, CaseIterable, Codable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"
    case expert = "Expert"

    /// Number of clues to remove from a complete solution.
    var cluesToRemove: Int {
        switch self {
        case .easy:   return 36  // ~45 clues remain
        case .medium: return 46  // ~35 clues remain
        case .hard:   return 52  // ~29 clues remain
        case .expert: return 56  // ~25 clues remain
        }
    }

    var maxHints: Int {
        switch self {
        case .easy:   return 5
        case .medium: return 3
        case .hard:   return 2
        case .expert: return 1
        }
    }

    var scoreBase: Int {
        switch self {
        case .easy:   return 1000
        case .medium: return 2000
        case .hard:   return 4000
        case .expert: return 8000
        }
    }
}
