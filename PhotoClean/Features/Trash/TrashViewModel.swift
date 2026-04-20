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
        isCommitting = true
        let bytes = totalBytes
        let snapshot = items
        let ok = await service.commitDeletion(assets: snapshot)
        if ok {
            lastCommittedCount = snapshot.count
            lastCommittedBytes = bytes
            trash.commitTrashed(ids: snapshot.map { $0.localIdentifier }, freedBytes: bytes)
            didCommitSucceed = true
            Haptics.commitSuccess()
        }
        isCommitting = false
        rebuildItems()
    }
}
