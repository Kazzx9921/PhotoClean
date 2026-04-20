import SwiftUI
import Photos

struct PhotoCardView: View {
    let asset: PHAsset
    let service: PhotoLibraryService
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void

    @State private var image: UIImage?
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var hasTriggeredHaptic = false
    @State private var isShowingMetadata = false
    @State private var isPlayingVideo = false

    private let swipeThresholdFraction: CGFloat = 0.30
    private let velocityThreshold: CGFloat = 500

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            Color(swipeTintColor)
                                .opacity(swipeTintOpacity(width: geo.size.width))
                                .allowsHitTesting(false)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.45), radius: 28, y: 14)
                } else {
                    ProgressView().tint(.primary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .overlay(alignment: .topLeading) { decisionIcon(.trashed) }
            .overlay(alignment: .topTrailing) { decisionIcon(.kept) }
            .overlay(alignment: .bottomTrailing) { videoDurationBadge }
            .overlay(alignment: .center) { videoPlayButton }
            .overlay(alignment: .center) { metadataOverlay }
            .rotationEffect(.degrees(rotation(width: geo.size.width)))
            .offset(dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                        if !hasTriggeredHaptic &&
                           abs(value.translation.width) > geo.size.width * swipeThresholdFraction {
                            Haptics.swipeThreshold()
                            hasTriggeredHaptic = true
                        }
                    }
                    .onEnded { value in
                        let passedDistance = abs(value.translation.width) > geo.size.width * swipeThresholdFraction
                        let passedVelocity = abs(value.predictedEndTranslation.width - value.translation.width) > velocityThreshold
                        let triggered = passedDistance || passedVelocity
                        if triggered {
                            let dir: CGFloat = value.translation.width < 0 ? -1 : 1
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = CGSize(width: dir * geo.size.width * 1.5, height: value.translation.height)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                if dir < 0 { onSwipeLeft() } else { onSwipeRight() }
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                        isDragging = false
                        hasTriggeredHaptic = false
                    }
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isShowingMetadata.toggle()
                }
            }
            .fullScreenCover(isPresented: $isPlayingVideo) {
                VideoPlayerView(asset: asset)
            }
            .task(id: asset.localIdentifier) { await load() }
        }
    }

    @ViewBuilder
    private var videoPlayButton: some View {
        if asset.mediaType == .video && !isShowingMetadata && !isDragging {
            Button { isPlayingVideo = true } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white, .black.opacity(0.45))
                    .shadow(color: .black.opacity(0.4), radius: 12)
            }
            .buttonStyle(.plain)
        }
    }

    private var swipeTintColor: Color {
        dragOffset.width < 0 ? .red : .green
    }

    private func swipeTintOpacity(width: CGFloat) -> Double {
        min(0.35, abs(Double(dragOffset.width) / Double(width)) * 0.6)
    }

    private func rotation(width: CGFloat) -> Double {
        Double(dragOffset.width / width) * 6.0
    }

    @ViewBuilder
    private func decisionIcon(_ decision: PhotoDecision) -> some View {
        let show = (decision == .trashed && dragOffset.width < -40) || (decision == .kept && dragOffset.width > 40)
        let systemName = (decision == .trashed) ? "trash.fill" : "heart.fill"
        let tint: Color = (decision == .trashed) ? .red : .green
        Image(systemName: systemName)
            .font(.system(size: 52, weight: .bold))
            .foregroundStyle(.white)
            .padding(14)
            .background(tint, in: Circle())
            .shadow(color: tint.opacity(0.4), radius: 12)
            .opacity(show ? min(1.0, abs(dragOffset.width) / 120) : 0)
            .padding(20)
    }

    @ViewBuilder
    private var videoDurationBadge: some View {
        if asset.mediaType == .video {
            HStack(spacing: 4) {
                Image(systemName: "play.fill").font(.caption2)
                Text(FormatHelper.duration(asset.duration))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(14)
        }
    }

    @ViewBuilder
    private var metadataOverlay: some View {
        if isShowingMetadata {
            VStack(alignment: .leading, spacing: 6) {
                if let date = asset.creationDate {
                    Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                }
                Label(FormatHelper.fileSize(service.fileSize(for: asset)), systemImage: "doc")
                if asset.location != nil {
                    Label("Has location", systemImage: "location")
                }
            }
            .font(.callout)
            .foregroundStyle(.white)
            .padding(16)
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
            .transition(.opacity.combined(with: .scale))
        }
    }

    private func load() async {
        self.image = await service.fullImage(for: asset)
    }
}
