// Hand-written. Hover held to what a control draws, which Chip and Button share (#130).

import SwiftUI

/// Tracks the pointer over a drawn shape, not over the frame it is laid out in: the pointer's location in the view's
/// frame is tested against `shape` in that frame, so the corners of a capsule's or a circle's frame beyond its round
/// ends are not hovered. `onHover` reports the whole frame whatever the content shape: with
/// `.contentShape(.interaction, capsule)` before it, the pointer 1 pt inside the frame's corner, outside the capsule,
/// still hovered a chip and a button (macOS 26, ChipBehaviorTests and ButtonBehaviorTests, #130). It reports whether
/// the pointer is inside the shape as the pointer moves over the view, and `false` when it leaves the view. nil
/// `onHover`: no tracking, the view as it is. watchOS has no pointer and tracks none.
struct ShapeHover<HoverShape: Shape>: ViewModifier {
    let shape: HoverShape
    let onHover: ((Bool) -> Void)?

    @State private var size = CGSize.zero

    func body(content: Content) -> some View {
        #if os(watchOS)
            content
        #else
            if let onHover {
                content
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newSize in
                        size = newSize
                    }
                    .onContinuousHover(coordinateSpace: .local) { phase in
                        switch phase {
                        case .active(let location):
                            onHover(shape.path(in: CGRect(origin: .zero, size: size)).contains(location))
                        case .ended:
                            onHover(false)
                        }
                    }
            } else {
                content
            }
        #endif
    }
}
