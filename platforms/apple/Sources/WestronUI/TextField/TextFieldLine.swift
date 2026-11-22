// Hand-written. A text field held to the height of its own lines on macOS, against a defect of SwiftUI (#113): the
// contract's description, a field's height "is that of its lines and its padding, or its minimum height", and its
// `platforms.apple.macos` block, which records the defect and this.
//
// The defect, found in #99 and forced by the package test `TextFieldLineTests`: SwiftUI lays the system field out
// between limits it takes from the line height of the font it measures the field with, from a cache of the three fonts
// it measured last, keyed by the font object's address. A font made at the address of one freed while that one's entry
// is still in the cache takes the freed font's height: a field of body.regular (a line of 16 pt on macOS) is laid out
// 17 pt high, heading.small's line, or a field of heading.small 16 or 13 pt high, which cuts off the bottom of its text.
// A multi-line field is held so where the product's line limit binds: one line under `lineLimit(1...4)`. What westron
// cannot do about it, measured on macOS 26.7.1 (#113):
// - set the system field's height from outside: SwiftUI holds it to those limits whatever height it is offered;
// - keep the measured font alive, so that its address is never taken: it is an object SwiftUI derives for the field,
//   which neither `Font.resolve(in:)` in the field's environment, nor a `Font` made from a Core Text font westron keeps,
//   nor the system field's own font is.
//
// What the style does, on macOS 26 and later, where `Font.resolve(in:)` gives the field's font as a Core Text font:
// - it measures the line of the field's font itself, as SwiftUI does on a miss of its cache: AppKit's default line
//   height for the resolved font;
// - when SwiftUI has laid the system field out at a height that is not its lines' (one line on a single-line field, a
//   whole number of lines on a multi-line one), the style gives the field its font with `leading(.standard)` added once
//   more, the leading the font has anyway, so that it draws the same pixels: a font SwiftUI resolves anew, makes a new
//   object for and measures, often at another address. With it, the field is offered a width more by 1/2048 of a point
//   more, up to 31/2048 and then from none again, at its right edge: a width SwiftUI has not sized the field for, so
//   that it sizes it anew. A new font alone has not been enough where the field's text and width stay the same: SwiftUI
//   then kept the field at the other font's height whatever font it was given, until the text or the width changed
//   (`TextFieldLineTests`, a field being edited). The field keeps that width once it is back at its lines: given its
//   own width back, it has been laid out at the other font's height again. Wider at the right edge, the field's frame
//   rounds to the same pixels at 1x and 2x, left to right and right to left (`TextFieldLineTests`, the review's probe):
//   a right edge at a half point rounds up either way, where a narrower field lost a pixel at 1x, and a field wider at
//   its left edge gained one;
// - it does so up to eight times in a row, and the count starts again once the field is laid out at its own lines, so
//   a field on screen for long is held each time the state comes back. In the forced states of the tests no field has
//   needed more than three;
// - a single-line field takes exactly its line's height, the system field at the top of it, so the layout around the
//   field and the place of its text are its own while SwiftUI holds the system field taller than its line.
// None of it changes a field laid out at its own height: the same layout and the same pixels (`TextFieldLineTests`, the
// snapshot matrix); and a field it held keeps the frame it had before, at 1x and 2x (`TextFieldLineTests`). A field being edited keeps its field editor, its text, its selection and an input method's marked
// text while its font is made anew, with no runtime warning from SwiftUI (`TextFieldLineTests`).
//
// Not covered:
// - a multi-line field held at another font's height that is a whole number of its own lines: a body.regular field (a
//   line of 16 pt) holding one line under `lineLimit(1...4)` laid out 32 pt high. The style cannot tell it from a field
//   of two lines without the field's text and line limit, which the style does not see, and leaves it; in the review's
//   probe, 1 to 26 of 750 layouts of such a field, as without the style;
// - macOS 14 and 15, where no public API resolves a font (whether the defect exists there is not known);
// - a field whose axis reflection cannot read (`TextFieldAxis.read`), which the style leaves as SwiftUI lays it out, as
//   it cannot know whether one line or a whole number of lines is its own;
// - a field with no font in its environment, which the system draws in the font of its control size;
// - iOS and watchOS, where the defect has not been seen and nothing here applies.
//
// Each font made anew adds one `leading(.standard)` to the field's font for as long as the field lives, so that it is a
// font SwiftUI has not resolved before: a field held often resolves a longer font.

import SwiftUI

#if os(macOS)
    import AppKit
#endif

/// The style's hold of a text field to its own lines on macOS (#113), seen from the package's tests.
package enum TextFieldLineWorkaround {
    /// Whether the style holds fields to their lines. Only a test switches it off, to show the defect.
    @MainActor package static var isEnabled = true
    /// How many times a field's font has been made anew because SwiftUI laid it out at another font's line, in this
    /// process: a test reads it to see that the defect was forced.
    @MainActor package internal(set) static var remade = 0
    /// The same, by the field's axis: a test reads it to see which of its fields were held.
    @MainActor package internal(set) static var remadeOnAxis: [Axis: Int] = [:]
}

/// On macOS 26 and later, the field held to the height of its own lines (#113); elsewhere the field as it is.
struct TextFieldLine: ViewModifier {
    /// The field's axis, the contract's `lines`, as read from the field; nil where it could not be read, and then the
    /// field is left as it is: a multi-line field taken for a single-line one would be held to one line.
    let axis: Axis?

    func body(content: Content) -> some View {
        #if os(macOS)
            if TextFieldLineWorkaround.isEnabled, let axis, #available(macOS 26, *) {
                content.modifier(TextFieldOwnLine(axis: axis))
            } else {
                content
            }
        #else
            content
        #endif
    }
}

#if os(macOS)
    @available(macOS 26, *)
    private struct TextFieldOwnLine: ViewModifier {
        let axis: Axis
        @Environment(\.font) private var font
        @Environment(\.fontResolutionContext) private var context
        @Environment(\.layoutDirection) private var layoutDirection
        /// How many times this field's font has been made anew, in all: each time a font SwiftUI has not resolved before.
        @State private var remade = 0
        /// How many times it has been made anew since the field was last laid out at its own lines.
        @State private var inARow = 0

        /// The most times a field's font is made anew in a row: the budget starts again once the field is laid out at
        /// its own lines, so that a field on screen for long is held each time the state comes back.
        private static let mostInARow = 8
        /// The width the field is offered more, one step more at each font made anew, from none to `widerSteps` - 1 of
        /// them and from none again: 31/2048 of a point at most.
        private static let wider: CGFloat = 1 / 2048  // westron-lint: allow a part of a pixel, no token's
        private static let widerSteps = 32

        func body(content: Content) -> some View {
            if let font {
                let line = Self.lineHeight(of: font.resolve(in: context).ctFont)
                let remade = remade
                content
                    .font(Self.font(font, remade: remade))
                    // The font made anew is part of the value: one made anew may be laid out at the same wrong height.
                    .onGeometryChange(for: LaidOut.self) {
                        LaidOut(height: $0.size.height, line: line, remade: remade)
                    } action: { laidOut in
                        if laidOut.isOwn(axis: axis) {
                            if inARow != .zero { inARow = .zero }
                            return
                        }
                        guard inARow < Self.mostInARow else { return }
                        inARow += 1
                        self.remade = laidOut.remade + 1
                        TextFieldLineWorkaround.remade += 1
                        TextFieldLineWorkaround.remadeOnAxis[axis, default: .zero] += 1
                    }
                    // A width SwiftUI has not sized the field for, so that it measures it anew: wider by a part of a
                    // pixel at its right edge, which rounds to the pixel it rounds to anyway, as a half point rounds
                    // up; narrower, or wider at the left edge, would move an edge at a half point by a pixel at 1x.
                    .padding(
                        layoutDirection == .rightToLeft ? .leading : .trailing,
                        -CGFloat(remade % Self.widerSteps) * Self.wider
                    )
                    .frame(height: axis == .horizontal ? line : nil, alignment: .top)
            } else {
                content
            }
        }

        /// The font, or after `remade` times, the same font with `leading(.standard)` added that many times: each one a
        /// font SwiftUI resolves anew, drawn as the font is.
        static func font(_ font: Font, remade: Int) -> Font {
            (0..<remade).reduce(font) { font, _ in font.leading(.standard) }
        }

        /// How SwiftUI laid the system field out: its height, the line of its font, and how many times its font had been
        /// made anew.
        struct LaidOut: Equatable {
            var height: CGFloat
            var line: CGFloat
            var remade: Int

            /// Whether the field is at its own lines' height: one line on a single-line field, a whole number of lines
            /// on a multi-line one. SwiftUI lays a field out on whole points, as AppKit's line heights are.
            func isOwn(axis: Axis) -> Bool {
                let height = height.rounded()
                let line = line.rounded()
                guard line > .zero else { return true }
                switch axis {
                case .horizontal: return height == line
                case .vertical: return height.truncatingRemainder(dividingBy: line) == .zero
                }
            }
        }

        @MainActor private static let layoutManager = NSLayoutManager()

        /// A font's line height as SwiftUI measures a field's line on a miss of its cache: AppKit's default line height
        /// for the font.
        @MainActor static func lineHeight(of font: CTFont) -> CGFloat {
            layoutManager.defaultLineHeight(for: font as NSFont)
        }
    }
#endif
