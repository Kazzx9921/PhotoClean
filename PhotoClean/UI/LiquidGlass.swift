import SwiftUI

struct LiquidGlassBackground<S: Shape>: ViewModifier {
    var interactive: Bool
    var shape: S

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            let effect: Glass = interactive ? .regular.interactive() : .regular
            content.glassEffect(effect, in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

extension View {
    func liquidGlass(interactive: Bool = false, in shape: some Shape = Capsule()) -> some View {
        modifier(LiquidGlassBackground(interactive: interactive, shape: shape))
    }
}

/// A container that merges adjacent `.liquidGlass` children into one fluid glass surface on iOS 26+.
/// On older iOS it's a pass-through.
struct LiquidGlassGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { content() }
        } else {
            content()
        }
    }
}
