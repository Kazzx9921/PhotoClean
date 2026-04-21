import SwiftUI
import StoreKit
import UIKit

extension Color {
    static let premiumGold = Color(red: 0.76, green: 0.58, blue: 0.18)
}

struct GlossyCapsule: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color.accentColor)
            Capsule().fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            Capsule()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        }
    }
}

struct RestoreRedeemRow: View {
    let isRestoring: Bool
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onRestore) {
                if isRestoring {
                    ProgressView().tint(.secondary)
                } else {
                    Text("Restore Purchase")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)

            Text("·")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                presentOfferCodeRedeemSheet()
            } label: {
                Text("Redeem code")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

func presentOfferCodeRedeemSheet() {
    Task { @MainActor in
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        try? await AppStore.presentOfferCodeRedeemSheet(in: scene)
    }
}
