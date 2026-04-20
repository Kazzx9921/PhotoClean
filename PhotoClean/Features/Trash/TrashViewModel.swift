import Foundation
import Photos
import Observation

@MainActor
@Observable
final class TrashViewModel {
    let service: PhotoLibraryService
    let trash: TrashStore
    let paywall: PaywallStore

    private(set) var items: [PHAsset] = []
    private(set) var totalBytes: Int64 = 0

    var isConfirmingCommit = false
    var isCommitting = false
    var didCommitSucceed = false
    var lastCommittedCount = 0
    var lastCommittedBytes: Int64 = 0

    var count: Int { items.count }

    var freeQuotaRemaining: Int {
        paywall.freeQuotaRemaining(currentTotal: trash.totalCommittedCount)
    }

    init(service: PhotoLibraryService, trash: TrashStore, paywall: PaywallStore) {
        self.service = service
        self.trash = trash
        self.paywall = paywall
    }

    func rebuildItems() {
        items = service.assets(withIds: Array(trash.trashedIds))
        totalBytes = items.reduce(0) { $0 + service.fileSize(for: $1) }
    }

    func restore(id: String) {
        trash.unmarkTrashed(id: id)
        rebuildItems()
    }

    func restoreAll() {
        trash.restoreAllFromTrash()
        rebuildItems()
    }

    func requestCommit() {
        guard !items.isEmpty else { return }
        if !paywall.canCommit(currentTotal: trash.totalCommittedCount, adding: items.count) {
            paywall.shouldShowPaywall = true
            return
        }
        isConfirmingCommit = true
    }

    func cancelCommit() { isConfirmingCommit = false }

    func performCommit() async {
        isConfirmingCommit = false
        await commit(assets: items, freedBytes: totalBytes)
    }

    /// Commit only the first N items (used from the paywall when the user
    /// prefers to stay on the free tier). N is clamped to remaining quota and
    /// current item count.
    func commitFreeQuotaOnly() async {
        let n = min(freeQuotaRemaining, items.count)
        guard n > 0 else { return }
        let snapshot = Array(items.prefix(n))
        let bytes = snapshot.reduce(0) { $0 + service.fileSize(for: $1) }
        paywall.shouldShowPaywall = false
        await commit(assets: snapshot, freedBytes: bytes)
    }

    private func commit(assets: [PHAsset], freedBytes: Int64) async {
        isCommitting = true
        let ok = await service.commitDeletion(assets: assets)
        if ok {
            lastCommittedCount = assets.count
            lastCommittedBytes = freedBytes
            trash.commitTrashed(ids: assets.map { $0.localIdentifier }, freedBytes: freedBytes)
            didCommitSucceed = true
            Haptics.commitSuccess()
        }
        isCommitting = false
        rebuildItems()
    }
}
