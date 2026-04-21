import SwiftUI
import Photos
import AVKit

struct VideoPlayerView: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var dragOffset: CGFloat = 0

    private let dismissThreshold: CGFloat = 120

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
            } else {
                ProgressView().tint(.white)
            }
        }
        .offset(y: max(0, dragOffset))
        .opacity(1.0 - min(0.4, dragOffset / 600))
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    let dy = value.translation.height
                    let dx = value.translation.width
                    guard dy > 0, dy > abs(dx) else { return }
                    dragOffset = dy
                }
                .onEnded { value in
                    let dy = value.translation.height
                    let dx = value.translation.width
                    if dy > dismissThreshold, dy > abs(dx) {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .task { await load() }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func load() async {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let avAsset: AVAsset? = await withCheckedContinuation { cont in
            var didResume = false
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard !didResume else { return }
                didResume = true
                cont.resume(returning: avAsset)
            }
        }

        if let avAsset {
            player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
        }
    }
}
