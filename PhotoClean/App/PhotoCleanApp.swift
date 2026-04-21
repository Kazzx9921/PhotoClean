import SwiftUI
import Photos
import UIKit

@main
struct PhotoCleanApp: App {
    @State private var service = PhotoLibraryService()
    @State private var trash = TrashStore()
    @State private var undo = UndoStack()
    @State private var paywall = PaywallStore()

    init() {
        let override = UserDefaults.standard.string(forKey: "appLanguageOverride") ?? ""
        if AppLanguage.applicableRawValues.contains(override) {
            UserDefaults.standard.set([override], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(service)
                .environment(trash)
                .environment(undo)
                .environment(paywall)
                .preferredColorScheme(.dark)
        }
    }
}

private struct RootView: View {
    @Environment(PhotoLibraryService.self) private var service
    @Environment(TrashStore.self) private var trash
    @Environment(UndoStack.self) private var undo
    @Environment(PaywallStore.self) private var paywall

    var body: some View {
        if !trash.hasCompletedOnboarding {
            OnboardingView(service: service, onComplete: {
                trash.hasCompletedOnboarding = true
            })
        } else {
            switch service.authorizationStatus {
            case .authorized, .limited:
                HomeView(
                    vm: HomeViewModel(service: service, trash: trash, undo: undo),
                    paywall: paywall
                )
            case .denied, .restricted:
                PermissionDeniedView()
            case .notDetermined:
                OnboardingView(service: service, onComplete: {
                    trash.hasCompletedOnboarding = true
                })
            @unknown default:
                PermissionDeniedView()
            }
        }
    }
}

private struct PermissionDeniedView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Photo library access required")
                .font(.title2.weight(.semibold))
            Text("Open Settings → PhotoClean → Photos to grant access.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
