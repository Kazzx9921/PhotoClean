import Foundation
import Photos
import PhotosUI
import UIKit
import Observation

@MainActor
@Observable
final class PhotoLibraryService {
    private(set) var authorizationStatus: PHAuthorizationStatus
    private(set) var assets: [PHAsset] = []
    private(set) var iCloudPhotosEnabled: Bool = false
    private(set) var libraryVersion: Int = 0

    private let imageManager = PHCachingImageManager()
    private var thumbnailCache: [String: UIImage] = [:]
    private var thumbnailOrder: [String] = []
    private var fileSizeCache: [String: Int64] = [:]

    private let changeObserver = ChangeObserver()
    private var observerRegistered = false

    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        changeObserver.onChange = { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshAssets()
            }
        }
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(changeObserver)
    }

    private func ensureObserverRegistered() {
        guard !observerRegistered else { return }
        PHPhotoLibrary.shared().register(changeObserver)
        observerRegistered = true
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    func presentLimitedLibraryPicker(from vc: UIViewController) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc)
    }

    func refreshAssets() {
        ensureObserverRegistered()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: #keyPath(PHAsset.creationDate), ascending: false)]
        options.predicate = NSPredicate(format: "mediaType IN %@", [PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue])

        let result = PHAsset.fetchAssets(with: options)
        var fetched: [PHAsset] = []
        fetched.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in fetched.append(asset) }
        assets = fetched
        libraryVersion &+= 1

        let probe = fetched.prefix(50)
        iCloudPhotosEnabled = probe.contains { $0.sourceType.contains(.typeCloudShared) }
    }

    func assets(withIds ids: [String]) -> [PHAsset] {
        guard !ids.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var out: [PHAsset] = []
        out.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in out.append(asset) }
        return out
    }

    func thumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 150, height: 150)) async -> UIImage? {
        let id = asset.localIdentifier
        if let cached = thumbnailCache[id] {
            touchLRU(id)
            return cached
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let image = await performImageRequest(
            for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options
        )
        guard let image else { return nil }

        thumbnailCache[id] = image
        thumbnailOrder.append(id)
        while thumbnailOrder.count > 50 {
            let evict = thumbnailOrder.removeFirst()
            thumbnailCache.removeValue(forKey: evict)
        }
        return image
    }

    func fullImage(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        return await performImageRequest(
            for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options
        )
    }

    private func performImageRequest(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            var didResume = false
            imageManager.requestImage(
                for: asset, targetSize: targetSize, contentMode: contentMode, options: options
            ) { image, info in
                if didResume { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if isDegraded && image != nil { return }
                didResume = true
                continuation.resume(returning: image)
            }
        }
    }

    private func touchLRU(_ id: String) {
        if let idx = thumbnailOrder.firstIndex(of: id) {
            thumbnailOrder.remove(at: idx)
            thumbnailOrder.append(id)
        }
    }

    func startCaching(assets: [PHAsset]) {
        imageManager.startCachingImages(
            for: assets,
            targetSize: CGSize(width: 150, height: 150),
            contentMode: .aspectFill,
            options: nil
        )
    }

    func stopCaching(assets: [PHAsset]) {
        imageManager.stopCachingImages(
            for: assets,
            targetSize: CGSize(width: 150, height: 150),
            contentMode: .aspectFill,
            options: nil
        )
    }

    func fileSize(for asset: PHAsset) -> Int64 {
        let id = asset.localIdentifier
        if let cached = fileSizeCache[id] { return cached }
        let resources = PHAssetResource.assetResources(for: asset)
        let total = resources.reduce(Int64(0)) { sum, resource in
            sum + ((resource.value(forKey: "fileSize") as? NSNumber)?.int64Value ?? 0)
        }
        fileSizeCache[id] = total
        return total
    }

    @discardableResult
    func commitDeletion(assets: [PHAsset]) async -> Bool {
        let batchSize = 500
        var index = 0
        while index < assets.count {
            let batch = Array(assets[index..<min(index + batchSize, assets.count)])
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(batch as NSArray)
                }
            } catch {
                return false
            }
            index += batchSize
        }
        return true
    }
}

private final class ChangeObserver: NSObject, PHPhotoLibraryChangeObserver {
    var onChange: (() -> Void)?

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        onChange?()
    }
}
