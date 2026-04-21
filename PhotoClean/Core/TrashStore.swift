import Foundation
import Observation

@Observable final class TrashStore {
    private enum Keys {
        static let keptIds = "photoclean.keptIds"
        static let trashedIds = "photoclean.trashedIds"
        static let totalCommittedCount = "photoclean.totalCommittedCount"
        static let totalFreedBytes = "photoclean.totalFreedBytes"
        static let hasCompletedOnboarding = "photoclean.hasCompletedOnboarding"
        static let legacyCommittedIds = "photoclean.committedIds"
    }

    private(set) var keptIds: Set<String>
    private(set) var trashedIds: Set<String>
    private(set) var totalCommittedCount: Int
    private(set) var totalFreedBytes: Int64

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.setValue(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    init() {
        let defaults = UserDefaults.standard
        keptIds = Set(defaults.stringArray(forKey: Keys.keptIds) ?? [])
        trashedIds = Set(defaults.stringArray(forKey: Keys.trashedIds) ?? [])
        totalCommittedCount = defaults.integer(forKey: Keys.totalCommittedCount)
        totalFreedBytes = (defaults.object(forKey: Keys.totalFreedBytes) as? Int64) ?? 0
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Keys.legacyCommittedIds)
    }

    func markKept(id: String) {
        trashedIds.remove(id)
        keptIds.insert(id)
        persist()
    }

    func markTrashed(id: String) {
        keptIds.remove(id)
        trashedIds.insert(id)
        persist()
    }

    func unmarkKept(id: String) {
        keptIds.remove(id)
        persist()
    }

    func unmarkTrashed(id: String) {
        trashedIds.remove(id)
        persist()
    }

    func restoreAllFromTrash() {
        trashedIds.removeAll()
        persist()
    }

    func commitTrashed(ids: [String], freedBytes: Int64) {
        trashedIds.subtract(Set(ids))
        totalCommittedCount += ids.count
        totalFreedBytes += freedBytes
        persist()
    }

    func decision(for id: String) -> PhotoDecision {
        if trashedIds.contains(id) { return .trashed }
        if keptIds.contains(id) { return .kept }
        return .pending
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.setValue(Array(keptIds), forKey: Keys.keptIds)
        defaults.setValue(Array(trashedIds), forKey: Keys.trashedIds)
        defaults.setValue(totalCommittedCount, forKey: Keys.totalCommittedCount)
        defaults.setValue(totalFreedBytes, forKey: Keys.totalFreedBytes)
    }
}
