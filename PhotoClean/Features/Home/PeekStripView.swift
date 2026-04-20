import SwiftUI
import Photos

struct PeekStripView: View {
    let assets: [PHAsset]
    let currentOffset: Int
    let service: PhotoLibraryService
    var onTap: (Int) -> Void
    var onLongPressBegin: (PHAsset) -> Void
    var onLongPressEnd: () -> Void

    private let containerHeight: CGFloat = 88
    private let hPadding: CGFloat = 14
    private let spacing: CGFloat = 8
    private let baseThumb: CGFloat = 54
    private let maxThumb: CGFloat = 58

    var body: some View {
        GeometryReader { geo in
            let n = max(assets.count, 1)
            let availableWidth = geo.size.width - hPadding * 2
            let totalSpacing = spacing * CGFloat(max(n - 1, 0))
            let thumb = min(maxThumb, max(baseThumb - 14, (availableWidth - totalSpacing) / CGFloat(n)))

            HStack(spacing: spacing) {
                ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { offset, asset in
                    PeekThumb(
                        asset: asset,
                        service: service,
                        isCurrent: offset == currentOffset,
                        size: thumb
                    )
                    .modifier(TapAndHoldGesture(
                        onTap: { onTap(offset) },
                        onHoldBegin: { onLongPressBegin(asset) },
                        onHoldEnd: { onLongPressEnd() }
                    ))
                }
                if assets.count < 6 { Spacer(minLength: 0) }
            }
            .padding(.horizontal, hPadding)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
        .frame(height: containerHeight)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
    }
}

private struct PeekThumb: View {
    let asset: PHAsset
    let service: PhotoLibraryService
    let isCurrent: Bool
    let size: CGFloat
    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: size, height: size)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isCurrent ? Color.white : Color.white.opacity(0.12), lineWidth: isCurrent ? 3 : 0.5)
        )
        .scaleEffect(isCurrent ? 1.08 : 0.92)
        .shadow(color: isCurrent ? Color.white.opacity(0.35) : .clear, radius: 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isCurrent)
        .task(id: asset.localIdentifier) {
            let px = size * displayScale
            image = await service.thumbnail(for: asset, targetSize: CGSize(width: px, height: px))
        }
    }
}

private struct TapAndHoldGesture: ViewModifier {
    let onTap: () -> Void
    let onHoldBegin: () -> Void
    let onHoldEnd: () -> Void

    @State private var pressing = false
    @State private var didHold = false
    @State private var holdTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressing else { return }
                        pressing = true
                        didHold = false
                        holdTask?.cancel()
                        holdTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(300))
                            guard !Task.isCancelled else { return }
                            didHold = true
                            onHoldBegin()
                        }
                    }
                    .onEnded { value in
                        holdTask?.cancel()
                        holdTask = nil
                        let moved = abs(value.translation.width) > 12 || abs(value.translation.height) > 12
                        if didHold {
                            onHoldEnd()
                        } else if !moved {
                            onTap()
                        }
                        pressing = false
                        didHold = false
                    }
            )
    }
}
