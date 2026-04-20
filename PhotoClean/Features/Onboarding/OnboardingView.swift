import SwiftUI
import Photos

struct OnboardingView: View {
    let service: PhotoLibraryService
    var onComplete: () -> Void

    @State private var page: Int = 0
    private let pageCount = 3

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                gesturePage.tag(1)
                permissionPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(.systemBackground).ignoresSafeArea())

            progressBar
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { idx in
                Capsule()
                    .fill(idx == page ? Color.white : Color.white.opacity(0.22))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var welcomePage: some View {
        OnboardingPage(
            icon: "photo.stack",
            title: "Clean your photo library",
            subtitle: "One swipe at a time.",
            primaryLabel: "Next",
            primaryAction: { withAnimation { page = 1 } }
        )
    }

    private var gesturePage: some View {
        OnboardingPage(
            icon: "hand.draw",
            title: "Swipe left to trash,\nright to keep",
            subtitle: "Tap the thumbnails below to jump to a photo. Long-press to preview.",
            primaryLabel: "Next",
            primaryAction: { withAnimation { page = 2 } }
        )
    }

    private var permissionPage: some View {
        OnboardingPage(
            icon: "lock.shield",
            title: "Photo library access",
            subtitle: "Your photos never leave your device. Nothing is uploaded to any server.\n\nIf iCloud Photos is enabled, deletions sync to your other Apple devices.",
            primaryLabel: "Allow Access",
            primaryAction: { Task { await requestPermission() } }
        )
    }

    private func requestPermission() async {
        _ = await service.requestAuthorization()
        onComplete()
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let primaryLabel: LocalizedStringKey
    var primaryAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.white)
            Text(title)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            Button(action: primaryAction) {
                Text(primaryLabel)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.black)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
