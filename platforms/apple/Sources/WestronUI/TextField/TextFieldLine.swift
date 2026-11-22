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
//   object for and measures, often at another address. The field takes its own height within the same layout: in the
//   forced state the third such font has been the first right one, rarely the fourth; at most eight are made;
// - a single-line field takes exactly its line's height, the system field at the top of it, so the layout around the
//   field and the place of its text are its own while SwiftUI holds the system field taller than its line.
// Neither changes a field laid out at its own height: the same layout and the same pixels (the snapshot matrix).
//
// Not covered: macOS 14 and 15, where no public API resolves a font (whether the defect exists there is not known); a
// field with no font in its environment, which the system draws in the font of its control size; iOS and watchOS, where
// the defect has not been seen and nothing here applies.

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
}

/// On macOS 26 and later, the field held to the height of its own lines (#113); elsewhere the field as it is.
struct TextFieldLine: ViewModifier {
    /// The field's axis, the contract's `lines`.
    let axis: Axis

    func body(content: Content) -> some View {
        #if os(macOS)
            if TextFieldLineWorkaround.isEnabled, #available(macOS 26, *) {
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
        /// How many times this field's font has been made anew.
        @State private var remade = 0

        /// The most times one field's font is made anew.
        private static let mostRemade = 8

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
                        guard laidOut.remade < Self.mostRemade, !laidOut.isOwn(axis: axis) else { return }
                        self.remade = laidOut.remade + 1
                        TextFieldLineWorkaround.remade += 1
                    }
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
