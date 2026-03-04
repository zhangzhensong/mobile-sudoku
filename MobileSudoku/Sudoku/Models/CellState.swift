import Foundation

struct CellState: Equatable {
    var value: Int           // 0 = empty
    var isGiven: Bool        // pre-filled clue, cannot be edited
    var candidates: Set<Int> // pencil marks (only meaningful when value == 0)
    var isError: Bool        // conflicts with another cell in same row/col/box

    init(value: Int = 0, isGiven: Bool = false) {
        self.value = value
        self.isGiven = isGiven
        self.candidates = []
        self.isError = false
    }

    var isEmpty: Bool { value == 0 }
}
