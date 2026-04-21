import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(TrashStore.self) private var trash
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.dismiss) private var dismiss

    @State private var showingPaywall = false
    @AppStorage("appLanguageOverride") private var languageOverride: String = ""
    @State private var showLanguageRestartAlert = false

    private let githubURL = URL(string: "https://github.com/Kazzx9921/PhotoClean")!
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    statusCard
                        .listRowInsets(EdgeInsets())
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
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.premiumGold)
                    .font(.system(size: 26, weight: .bold))
                Text("PhotoClean Pro")
                    .font(.title3.weight(.bold))
                Spacer()
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

            RestoreRedeemRow(isRestoring: paywall.isRestoring) {
                Task { await paywall.restore() }
            }
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
                    .background(GlossyCapsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func unlockLabel(priceText: String) -> some View {
        Text("Unlock Unlimited — \(priceText)")
            .font(.callout.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
    }
}
