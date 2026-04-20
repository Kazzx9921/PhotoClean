import SwiftUI

struct SettingsView: View {
    @Environment(TrashStore.self) private var trash
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.dismiss) private var dismiss

    @State private var showingPaywall = false
    @AppStorage("appLanguageOverride") private var languageOverride: String = ""
    @State private var showLanguageRestartAlert = false

    private let githubURL = URL(string: "https://github.com/Kazzx9921/PhotoClean")!
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    statusCard
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                Section("Current") {
                    LabeledContent("Pending delete", value: "\(trash.trashedIds.count)")
                    LabeledContent("Kept", value: "\(trash.keptIds.count)")
                }

                Section {
                    LabeledContent("Photos deleted", value: "\(trash.totalCommittedCount)")
                    LabeledContent("Space freed", value: FormatHelper.fileSize(trash.totalFreedBytes))
                } header: {
                    Text("Lifetime")
                } footer: {
                    Text("Only counts photos confirmed deleted to iOS Recently Deleted. Items still in the app trash don't count.")
                }

                Section {
                    Picker("App language", selection: $languageOverride) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .onChange(of: languageOverride) { _, _ in
                        showLanguageRestartAlert = true
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Relaunch the app for the language change to take effect.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    Link(destination: githubURL) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                            Text("View on GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Runs 100% offline. Nothing is sent to any server.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Relaunch required", isPresented: $showLanguageRestartAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Close and reopen PhotoClean for the new language to take effect.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private enum AppLanguage: String, CaseIterable, Identifiable {
        case system = ""
        case en = "en"
        case zhHant = "zh-Hant"
        case zhHans = "zh-Hans"
        case ja = "ja"
        case es = "es"

        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .system: return "System default"
            case .en: return "English"
            case .zhHant: return "繁體中文"
            case .zhHans: return "简体中文"
            case .ja: return "日本語"
            case .es: return "Español"
            }
        }
    }

    // MARK: - Status card

    @ViewBuilder
    private var statusCard: some View {
        if paywall.isUnlocked {
            proCard
        } else {
            freeCard
        }
    }

    private var proCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.yellow)
                Text("PhotoClean Pro")
                    .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }
            Text("Unlimited cleanups unlocked. Thank you for supporting the project!")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var freeCard: some View {
        let used = min(trash.totalCommittedCount, PaywallStore.freeQuota)
        let progress = Double(used) / Double(PaywallStore.freeQuota)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Free Plan")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(used) / \(PaywallStore.freeQuota)")
                    .font(.footnote.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(.accentColor)

            unlockButton

            Button {
                Task { await paywall.restore() }
            } label: {
                if paywall.isRestoring {
                    ProgressView().tint(.secondary)
                } else {
                    Text("Already purchased? Restore")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.plain)
            .disabled(paywall.isRestoring)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var unlockButton: some View {
        let priceText = paywall.product?.displayPrice ?? "$2.99"

        if #available(iOS 26.0, *) {
            Button { showingPaywall = true } label: {
                unlockLabel(priceText: priceText)
            }
            .buttonStyle(.glassProminent)
            .tint(.accentColor)
        } else {
            Button { showingPaywall = true } label: {
                unlockLabel(priceText: priceText)
                    .foregroundStyle(.white)
                    .background(glossyCapsule)
            }
            .buttonStyle(.plain)
        }
    }

    private var glossyCapsule: some View {
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

    private func unlockLabel(priceText: String) -> some View {
        Text("Unlock Unlimited — \(priceText)")
            .font(.callout.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
    }
}
