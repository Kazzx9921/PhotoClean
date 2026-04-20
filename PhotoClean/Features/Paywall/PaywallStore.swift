import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class PaywallStore {
    static let productID = "com.geekaz.PhotoClean.unlock"
    static let freeQuota = 100
    static let softWarningThreshold = 80

    private enum Keys {
        static let isUnlocked = "photoclean.isUnlocked"
    }

    private(set) var product: Product?
    private(set) var isUnlocked: Bool
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    var shouldShowPaywall = false
    var lastError: String?

    nonisolated private let updatesTaskBox = Box()

    private final class Box: @unchecked Sendable {
        var task: Task<Void, Never>?
    }

    init() {
        isUnlocked = UserDefaults.standard.bool(forKey: Keys.isUnlocked)
        updatesTaskBox.task = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    deinit { updatesTaskBox.task?.cancel() }

    // MARK: - Public API

    func canCommit(currentTotal: Int, adding: Int) -> Bool {
        isUnlocked || (currentTotal + adding <= Self.freeQuota)
    }

    func shouldShowSoftWarning(currentTotal: Int) -> Bool {
        !isUnlocked
            && currentTotal >= Self.softWarningThreshold
            && currentTotal < Self.freeQuota
    }

    func freeQuotaRemaining(currentTotal: Int) -> Int {
        max(0, Self.freeQuota - currentTotal)
    }

    func loadProduct() async {
        guard product == nil else { return }
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled:
                break
            case .pending:
                lastError = String(localized: "Purchase is pending approval.")
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        lastError = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                await handle(result)
                if isUnlocked { return }
            }
            if !isUnlocked {
                lastError = String(localized: "No prior purchase found.")
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Private

    private func handle(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == Self.productID else { return }
            if transaction.revocationDate == nil {
                setUnlocked(true)
            } else {
                setUnlocked(false)
            }
            await transaction.finish()
        case .unverified:
            lastError = String(localized: "Could not verify purchase.")
        }
    }

    private func setUnlocked(_ value: Bool) {
        isUnlocked = value
        UserDefaults.standard.set(value, forKey: Keys.isUnlocked)
    }
}
