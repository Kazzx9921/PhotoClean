import SwiftUI
import Photos

struct TrashView: View {
    @Bindable var vm: TrashViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        @Bindable var paywall = vm.paywall

        NavigationStack {
            content
                .navigationTitle("Trash")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                .task { vm.rebuildItems() }
                .alert("Empty Trash?", isPresented: $vm.isConfirmingCommit) {
                    Button("Cancel", role: .cancel) { vm.cancelCommit() }
                    Button("Empty", role: .destructive) {
                        Task { await vm.performCommit() }
                    }
                } message: {
                    Text("\(vm.count) photos will be moved to iOS Recently Deleted. About \(FormatHelper.fileSize(vm.totalBytes)) will be freed.")
                }
                .sheet(isPresented: $vm.didCommitSucceed) {
                    CommitSuccessView(
                        bytes: vm.lastCommittedBytes,
                        onDone: {
                            vm.didCommitSucceed = false
                            dismiss()
                        }
                    )
                    .interactiveDismissDisabled()
                }
                .sheet(isPresented: $paywall.shouldShowPaywall) {
                    PaywallView(
                        freeQuotaRemaining: vm.freeQuotaRemaining,
                        onCommitFreeQuota: {
                            Task { await vm.commitFreeQuotaOnly() }
                        }
                    )
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.count == 0 {
            ContentUnavailableView(
                "Trash is empty",
                systemImage: "trash",
                description: Text("Swipe left on photos to trash them. They'll show up here.")
            )
        } else {
            VStack(spacing: 0) {
                header
                grid
                bottomBar
            }
        }
    }

    private var header: some View {
        HStack {
            Text(FormatHelper.countAndSize(vm.count, bytes: vm.totalBytes))
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(vm.items, id: \.localIdentifier) { asset in
                    TrashThumb(
                        asset: asset,
                        service: vm.service,
                        onRestore: { vm.restore(id: asset.localIdentifier) }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.undo()
                withAnimation { vm.restoreAll() }
            } label: {
                Text("Restore All")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .liquidGlass(interactive: true, in: Capsule())
            }
            .buttonStyle(.plain)

            commitButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var commitButton: some View {
        if #available(iOS 26.0, *) {
            Button { vm.requestCommit() } label: {
                Text("Empty Trash")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glassProminent)
            .tint(.red)
            .disabled(vm.isCommitting)
        } else {
            Button { vm.requestCommit() } label: {
                Text("Empty Trash")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.red, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(vm.isCommitting)
        }
    }
}

private struct TrashThumb: View {
    let asset: PHAsset
    let service: PhotoLibraryService
    var onRestore: () -> Void
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image {
                        Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.15)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width)
                .clipped()

                Button(action: onRestore) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .task(id: asset.localIdentifier) {
            image = await service.thumbnail(for: asset, targetSize: CGSize(width: 200, height: 200))
        }
    }
}

private struct CommitSuccessView: View {
    let bytes: Int64
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce)
            Text("Freed \(FormatHelper.fileSize(bytes))!")
                .font(.title.weight(.bold))
            Text("Photos stay in iOS Recently Deleted for 30 days. Empty them from the system Photos app to free space immediately.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button { onDone() } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.black)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
