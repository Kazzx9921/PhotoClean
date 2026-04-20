import Foundation
import Photos
import UIKit
import Observation

@MainActor
@Observable
final class HomeViewModel {
    let service: PhotoLibraryService
    let trash: TrashStore
    let undo: UndoStack

    private(set) var queue: [PHAsset] = []
    private(set) var currentIndex: Int = 0
    private(set) var pendingTrashBytes: Int64 = 0
    private(set) var peekStripAssets: [PHAsset] = []

    var peekOverrideAsset: PHAsset?

    private var prefetchedAssets: [PHAsset] = []
    private var lastLibraryVersion: Int = -1

    var currentAsset: PHAsset? {
        guard queue.indices.contains(currentIndex) else { return nil }
        return queue[currentIndex]
    }

    var displayedAsset: PHAsset? { peekOverrideAsset ?? currentAsset }

    var progressText: String {
        guard !queue.isEmpty || currentIndex > 0 else { return "0 / 0 · 0 MB" }
        let numerator = processedCount + 1
        let denominator = processedCount + queue.count
        return "\(numerator.formatted()) / \(denominator.formatted()) · \(FormatHelper.fileSize(pendingTrashBytes))"
    }

    var remainingCount: Int { max(0, queue.count - currentIndex) }
    var processedCount: Int { currentIndex }
    var trashedCount: Int { trash.trashedIds.count }

    var currentPeekOffset: Int {
        min(currentIndex, max(0, peekStripAssets.count - 1))
    }

    private func refreshPeekStrip() {
        peekStripAssets = queue.isEmpty ? [] : Array(queue.prefix(6))
    }

    init(service: PhotoLibraryService, trash: TrashStore, undo: UndoStack) {
        self.service = service
        self.trash = trash
        self.undo = undo
    }

    func onAppear() async {
        guard service.authorizationStatus != .notDetermined else { return }
        if service.assets.isEmpty { service.refreshAssets() }
        syncFromLibrary()
    }

    func rebuildQueue() {
        queue = service.assets.filter { trash.decision(for: $0.localIdentifier) == .pending }
        if currentIndex >= queue.count {
            currentIndex = max(0, queue.count - 1)
        }
        peekOverrideAsset = nil
        refreshPeekStrip()
        refreshPendingBytes()
    }

    func swipeLeft() {
        guard let asset = currentAsset else { return }
        let id = asset.localIdentifier
        let size = service.fileSize(for: asset)
        trash.markTrashed(id: id)
        undo.push(.trashed(id: id, fileSize: size))
        pendingTrashBytes += size
        advanceAfterDecision()
    }

    func swipeRight() {
        guard let asset = currentAsset else { return }
        let id = asset.localIdentifier
        trash.markKept(id: id)
        undo.push(.kept(id: id))
        advanceAfterDecision()
    }

    func undoLast() {
        guard let action = undo.pop() else { return }
        switch action {
        case .trashed(let id, let size):
            trash.unmarkTrashed(id: id)
            pendingTrashBytes = max(0, pendingTrashBytes - (size ?? 0))
            reinsertAsset(id: id)
        case .kept(let id):
            trash.unmarkKept(id: id)
            reinsertAsset(id: id)
        }
    }

    func tapPeek(at offset: Int) {
        peekOverrideAsset = nil
        guard !queue.isEmpty else { return }
        currentIndex = min(offset, queue.count - 1)
    }

    func beginPeekPreview(asset: PHAsset) { peekOverrideAsset = asset }
    func endPeekPreview() { peekOverrideAsset = nil }

    func onScenePhaseBecameActive() async {
        syncFromLibrary()
    }

    private func syncFromLibrary() {
        guard lastLibraryVersion != service.libraryVersion else { return }
        lastLibraryVersion = service.libraryVersion
        rebuildQueue()
        let batch = Array(queue.prefix(10))
        service.stopCaching(assets: prefetchedAssets)
        service.startCaching(assets: batch)
        prefetchedAssets = batch
    }

    private func advanceAfterDecision() {
        queue.remove(at: currentIndex)
        if currentIndex >= queue.count {
            currentIndex = max(0, queue.count - 1)
        }
        peekOverrideAsset = nil
        refreshPeekStrip()
        prefetchUpcoming()
    }

    private func reinsertAsset(id: String) {
        let matches = service.assets(withIds: [id])
        guard let asset = matches.first else {
            rebuildQueue()
            return
        }
        queue.insert(asset, at: currentIndex)
        refreshPeekStrip()
    }

    private func prefetchUpcoming() {
        let start = currentIndex
        let end = min(start + 10, queue.count)
        let newBatch = start < end ? Array(queue[start..<end]) : []
        service.stopCaching(assets: prefetchedAssets)
        service.startCaching(assets: newBatch)
        prefetchedAssets = newBatch
    }

    private func refreshPendingBytes() {
        let ids = Array(trash.trashedIds)
        guard !ids.isEmpty else { pendingTrashBytes = 0; return }
        let matches = service.assets(withIds: ids)
        pendingTrashBytes = matches.reduce(Int64(0)) { $0 + service.fileSize(for: $1) }
    }
}
