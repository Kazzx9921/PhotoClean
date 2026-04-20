import SwiftUI

struct SettingsView: View {
    @Environment(TrashStore.self) private var trash
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.dismiss) private var dismiss

    @State private var showingPaywall = false

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
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
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
            .controlSize(.large)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 14, y: 6)
        } else {
            Button { showingPaywall = true } label: {
                unlockLabel(priceText: priceText)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func unlockLabel(priceText: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.open.fill")
                .font(.callout.weight(.bold))
            Text("Unlock Unlimited — \(priceText)")
                .font(.callout.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
