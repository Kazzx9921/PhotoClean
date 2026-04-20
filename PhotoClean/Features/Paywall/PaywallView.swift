import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PaywallStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var freeQuotaRemaining: Int? = nil
    var onCommitFreeQuota: (() -> Void)? = nil

    private var showsPartialOption: Bool {
        guard let remaining = freeQuotaRemaining, onCommitFreeQuota != nil else { return false }
        return remaining > 0
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 48)
                    header
                    benefits
                    Spacer(minLength: 16)
                    actions
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }

            closeButton
        }
        .task {
            await store.loadProduct()
        }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.yellow)
                .symbolEffect(.pulse)
                .padding(.bottom, 4)

            Text("You've cleaned 100 photos 🎉")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Reclaim your storage. Stop paying for iCloud or bigger phones just to hold photos you'll never look at again.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefit("infinity", "Clean unlimited photos and videos")
            benefit("xmark.seal.fill", "One-time purchase, no subscription")
            benefit("arrow.triangle.2.circlepath", "Free updates forever")
            benefit("lock.shield.fill", "100% offline — your data stays yours")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func benefit(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28)
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 14) {
            purchaseButton

            if showsPartialOption, let remaining = freeQuotaRemaining {
                Button {
                    onCommitFreeQuota?()
                } label: {
                    Text("Delete \(remaining) photos only (free)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .liquidGlass(interactive: true, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await store.restore() }
            } label: {
                if store.isRestoring {
                    ProgressView().tint(.secondary)
                } else {
                    Text("Restore Purchase")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isRestoring)

            if let error = store.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        let priceText = store.product?.displayPrice ?? "$0.99"

        if #available(iOS 26.0, *) {
            Button { Task { await store.purchase() } } label: {
                purchaseLabel(priceText: priceText)
            }
            .buttonStyle(.glassProminent)
            .tint(.accentColor)
            .disabled(store.isPurchasing || store.product == nil)
        } else {
            Button { Task { await store.purchase() } } label: {
                purchaseLabel(priceText: priceText)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.product == nil)
        }
    }

    private func purchaseLabel(priceText: String) -> some View {
        HStack {
            if store.isPurchasing {
                ProgressView().tint(.white)
            } else {
                Text("Unlock for \(priceText)")
                    .font(.body.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Close

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .liquidGlass(interactive: true, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
        .padding(.trailing, 16)
    }
}
