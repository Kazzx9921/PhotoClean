import SwiftUI
import UIKit

struct LimitedPermissionBanner: View {
    let service: PhotoLibraryService

    var body: some View {
        Button {
            if let vc = topViewController() {
                service.presentLimitedLibraryPicker(from: vc)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                Text("Limited access — tap to choose more photos")
                    .font(.footnote)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .liquidGlass(in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        var current = root
        while let presented = current.presentedViewController { current = presented }
        return current
    }
}
