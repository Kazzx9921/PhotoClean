import Foundation
import Observation

@Observable final class UndoStack {
    private(set) var actions: [UndoAction] = []
    private let maxDepth = 50

    var canUndo: Bool { !actions.isEmpty }

    func push(_ action: UndoAction) {
        actions.append(action)
        if actions.count > maxDepth {
            actions.removeFirst()
        }
    }

    func pop() -> UndoAction? {
        guard !actions.isEmpty else { return nil }
        return actions.removeLast()
    }

    func clear() {
        actions.removeAll()
    }
}
