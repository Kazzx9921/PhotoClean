import SwiftUI
import Photos

struct HomeView: View {
    let vm: HomeViewModel
    @State private var trashVM: TrashViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PaywallStore.self) private var paywall

    @State private var showTrash = false
    @State private var showSettings = false

    init(vm: HomeViewModel, paywall: PaywallStore) {
        self.vm = vm
        self._trashVM = State(initialValue: TrashViewModel(
            service: vm.service,
            trash: vm.trash,
            paywall: paywall
        ))
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom
            let topInset: CGFloat = safeTop + 72
            let bottomInset: CGFloat = safeBot + 120

            ZStack {
                Color(.systemBackground)

                cardArea
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)
                    .padding(.horizontal, 16)

                VStack(spacing: 6) {
                    if vm.service.authorizationStatus == .limited {
                        LimitedPermissionBanner(service: vm.service)
                    }
                    topBar
                }
                .padding(.top, safeTop + 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if vm.peekStripAssets.count > 1 {
                    PeekStripView(
                        assets: vm.peekStripAssets,
                        currentOffset: vm.currentPeekOffset,
                        service: vm.service,
                        onTap: { offset in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                vm.tapPeek(at: offset)
                            }
                        },
                        onLongPressBegin: { vm.beginPeekPreview(asset: $0) },
                        onLongPressEnd: { vm.endPeekPreview() }
                    )
                    .padding(.bottom, safeBot + 6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .ignoresSafeArea()
        }
        .task { await vm.onAppear() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await vm.onScenePhaseBecameActive() } }
        }
        .sheet(isPresented: $showTrash) {
            TrashView(vm: trashVM)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var topBar: some View {
        LiquidGlassGroup {
            HStack(spacing: 12) {
                undoButton
                Spacer()
                progressButton
                Spacer()
                trashButton
            }
            .padding(.horizontal, 16)
        }
    }

    private var undoButton: some View {
        Button {
            Haptics.undo()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { vm.undoLast() }
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(.primary)
                .liquidGlass(interactive: true, in: Circle())
        }
        .buttonStyle(.plain)
        .opacity(vm.undo.canUndo ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.2), value: vm.undo.canUndo)
        .allowsHitTesting(vm.undo.canUndo)
    }

    private var progressButton: some View {
        Button { showSettings = true } label: {
            Text(vm.progressText)
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlass(interactive: true, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var trashButton: some View {
        Button { showTrash = true } label: {
            Image(systemName: "trash")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(.primary)
                .liquidGlass(interactive: true, in: Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardArea: some View {
        if let asset = vm.displayedAsset {
            PhotoCardView(
                asset: asset,
                service: vm.service,
                onSwipeLeft: { vm.swipeLeft() },
                onSwipeRight: { vm.swipeRight() }
            )
            .id(asset.localIdentifier)
        } else if vm.hasLoadedOnce {
            EmptyQueueView(
                trashedCount: vm.trashedCount,
                freedBytes: vm.pendingTrashBytes,
                onOpenTrash: { showTrash = true }
            )
        } else {
            ProgressView().tint(.primary)
        }
    }
}

private struct EmptyQueueView: View {
    let trashedCount: Int
    let freedBytes: Int64
    let onOpenTrash: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🎉").font(.system(size: 80))
            Text("All clean!")
                .font(.title.weight(.bold))
            if trashedCount > 0 {
                Text("Pending: \(FormatHelper.countAndSize(trashedCount, bytes: freedBytes))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Open Trash") { onOpenTrash() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            } else {
                Text("No photos to review")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .onAppear { Haptics.noMorePhotos() }
    }
}
