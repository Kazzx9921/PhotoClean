import SwiftUI
import Photos
import AVKit

struct VideoPlayerView: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

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
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white, .black.opacity(0.5))
                    .padding(16)
            }
            .buttonStyle(.plain)
        }
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
