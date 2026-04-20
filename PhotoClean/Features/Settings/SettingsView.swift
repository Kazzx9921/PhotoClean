import SwiftUI

struct SettingsView: View {
    @Environment(TrashStore.self) private var trash
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.dismiss) private var dismiss

    private let githubURL = URL(string: "https://github.com/Kazzx9921/PhotoClean")!
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

    var body: some View {
        NavigationStack {
            Form {
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

                unlockSection

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
                    Text("Runs 100% offline. Nothing is sent to any server.\n\nOpen source — clone from GitHub to install on your own device.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var unlockSection: some View {
        if paywall.isUnlocked {
            Section("Unlock") {
                HStack {
                    Label("Unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("Thank you!")
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Section {
                LabeledContent(
                    "Free quota",
                    value: "\(min(trash.totalCommittedCount, PaywallStore.freeQuota)) / \(PaywallStore.freeQuota)"
                )
                Button {
                    Task { await paywall.restore() }
                } label: {
                    if paywall.isRestoring {
                        ProgressView()
                    } else {
                        Text("Restore Purchase")
                    }
                }
                .disabled(paywall.isRestoring)
            } header: {
                Text("Unlock")
            } footer: {
                Text("Tap Restore if you've already purchased or redeemed a promo code on this Apple ID.")
            }
        }
    }
}
