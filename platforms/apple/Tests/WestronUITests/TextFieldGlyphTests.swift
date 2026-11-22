import Foundation
import SwiftUI
import Testing

@testable import WestronUI

/// TextField's glyphs at its start and its end (the contract's `leadingIcon` and `trailingIcon`, #115; its
/// decisions/0003), laid out in a window: where they stand, how they align with the text, their tokens, and the
/// generated overload that takes them. A package test's window exposes no accessibility elements and takes no focus, so
/// that the glyphs are hidden from assistive technology and that a tap on one focuses the field are checked in the
/// catalog app (CatalogUITests/TextFieldBehaviorTests, on iOS and macOS).
@Suite("TextField glyphs")
@MainActor
struct TextFieldGlyphTests {
    /// What a styled field laid out: its size and first baseline, and the bounds of its glyphs and of the field
    /// between them, in its own coordinates.
    struct Laidout {
        var size: CGSize = .zero
        var baseline: CGFloat = .zero
        var parts: [TextFieldGlyphAnchors.Part: CGRect] = [:]
    }

    /// Lays `field` out in a window, offered a width of 300.
    static func layOut(_ field: some View, direction: LayoutDirection = .leftToRight) -> Laidout {
        let box = Box()
        TextFieldStyleTests.show(
            Probe(box: box) {
                field
                    .overlayPreferenceValue(TextFieldGlyphAnchors.self) { anchors in
                        GeometryReader { proxy in
                            let _ = (box.value.parts = anchors.mapValues { proxy[$0] })
                            Color.clear
                        }
                    }
            }
            .frame(width: 300)
            .environment(\.layoutDirection, direction))
        return box.value
    }

    static func field(
        _ variant: TextFieldVariant, size: TextFieldSize = .m, axis: Axis = .horizontal, text: String = "Groceries",
        leading: Westron.Icon? = .magnifier, trailing: Westron.Icon? = nil
    ) -> some View {
        TextField("Search", text: .constant(text), axis: axis)
            .textFieldStyle(variant, size: size, leadingIcon: leading, trailingIcon: trailing)
            .textRole(.body.regular)
    }

    /// The padding and gap a field of `variant` and `size` draws at the default text size.
    static func metrics(_ variant: TextFieldVariant, _ size: TextFieldSize) -> (padding: CGFloat, gap: CGFloat) {
        let metrics = TextFieldMetrics(variant: variant, size: size, axis: .horizontal)
        return (metrics.paddingHorizontal.map(CGFloat.init) ?? .zero, CGFloat(metrics.gap))
    }

    /// The tolerance of a position: the width the hold of #113 adds to a field on macOS is at most 31/2048 pt.
    static let tolerance: CGFloat = 0.05

    @Test(
        "a glyph stands at the field's horizontal padding and container.gap from its text, at each size",
        arguments: [TextFieldVariant.framed, .inline], TextFieldSize.allCases)
    func paddingAndGap(variant: TextFieldVariant, size: TextFieldSize) throws {
        let (padding, gap) = Self.metrics(variant, size.offered)
        let laidOut = Self.layOut(Self.field(variant, size: size, trailing: .hash))
        let leading = try #require(laidOut.parts[.leading])
        let field = try #require(laidOut.parts[.field])
        let trailing = try #require(laidOut.parts[.trailing])
        #expect(abs(leading.minX - padding) < Self.tolerance, "\(leading) padding \(padding)")
        #expect(abs(field.minX - leading.maxX - gap) < Self.tolerance, "\(field) after \(leading), gap \(gap)")
        #expect(abs(trailing.minX - field.maxX - gap) < Self.tolerance, "\(trailing) after \(field), gap \(gap)")
        #expect(abs(laidOut.size.width - padding - trailing.maxX) < Self.tolerance, "\(trailing) in \(laidOut.size)")
        // The glyphs take room from the text, not from the field's width.
        #expect(laidOut.size.width == 300)
    }

    @Test("right to left, the glyph at the start stands at the right and the one at the end at the left")
    func rightToLeft() throws {
        let (padding, gap) = Self.metrics(.framed, .m)
        let laidOut = Self.layOut(
            Self.field(.framed, text: "מצרכים", trailing: .hash), direction: .rightToLeft)
        let leading = try #require(laidOut.parts[.leading])
        let field = try #require(laidOut.parts[.field])
        let trailing = try #require(laidOut.parts[.trailing])
        // Anchors resolve left to right whatever the direction: the start is at the right edge.
        #expect(abs(laidOut.size.width - padding - leading.maxX) < Self.tolerance, "\(leading) in \(laidOut.size)")
        #expect(abs(leading.minX - field.maxX - gap) < Self.tolerance, "\(field) before \(leading)")
        #expect(abs(field.minX - trailing.maxX - gap) < Self.tolerance, "\(trailing) before \(field)")
        #expect(abs(trailing.minX - padding) < Self.tolerance, "\(trailing)")
    }

    @Test(
        "on one line and on several, a glyph's baseline is the field's first baseline, and the field keeps its own",
        arguments: [TextFieldVariant.framed, .inline], [Axis.horizontal, .vertical])
    func baselineOnTheFirstLine(variant: TextFieldVariant, axis: Axis) throws {
        let text = axis == .vertical ? "Milk\nApples\nBread" : "Groceries"
        let bare = Self.layOut(Self.field(variant, axis: axis, text: text, leading: nil))
        // framed draws its glyphs in body.regular; inline in the context's role, which `field` sets to body.regular.
        let magnifier = Self.layOut(Icon(.magnifier).textRole(.body.regular))
        let hash = Self.layOut(Icon(.hash).textRole(.body.regular))
        let laidOut = Self.layOut(Self.field(variant, axis: axis, text: text, trailing: .hash))
        let leading = try #require(laidOut.parts[.leading])
        let trailing = try #require(laidOut.parts[.trailing])
        // The field gives its first line's baseline, not its bottom, which a view without a baseline gives.
        #expect(bare.baseline < bare.size.height - 1, "a baseline at the bottom: \(bare)")
        if axis == .vertical {
            // Three lines: the first baseline is in the top third.
            #expect(bare.baseline < bare.size.height / 2, "\(bare)")
        }
        // The glyphs change neither the field's height nor where its text stands: they stand beside the field in a row
        // that is sized by the field alone, and add no height, even where one reaches higher above its baseline than
        // the first line (on iOS a glyph by a pixel, which a glyph beside the field in a stack added to a multi-line
        // field's height).
        #expect(abs(laidOut.size.height - bare.size.height) < Self.tolerance, "\(laidOut.size) for \(bare.size)")
        #expect(abs(laidOut.baseline - bare.baseline) < Self.tolerance, "\(laidOut.baseline) for \(bare.baseline)")
        // Each glyph stands on the field's first baseline, its place rounded to the pixel.
        for (frame, glyph) in [(leading, magnifier), (trailing, hash)] {
            #expect(
                abs(frame.minY + glyph.baseline - laidOut.baseline) <= Self.pixel, "\(frame), \(glyph), \(laidOut)")
        }
    }

    /// The most a place rounded to the pixel may be off: half a point, a pixel at 2x, a little more than one at 3x.
    static let pixel: CGFloat = 0.5

    @Test(
        "the glyphs and their gaps stop growing at xxxLarge, and the field's text grows on",
        arguments: [TextFieldVariant.framed, .inline], [Axis.horizontal, .vertical])
    func glyphsStopAtTheLargestTextSize(variant: TextFieldVariant, axis: Axis) throws {
        let text = axis == .vertical ? "Milk\nApples" : "Groceries"
        func layOut(_ size: DynamicTypeSize) throws -> (leading: CGRect, trailing: CGRect, field: CGRect) {
            let laidOut = Self.layOut(
                Self.field(variant, axis: axis, text: text, trailing: .hash).dynamicTypeSize(size))
            return (
                try #require(laidOut.parts[.leading]), try #require(laidOut.parts[.trailing]),
                try #require(laidOut.parts[.field])
            )
        }
        #expect(TextFieldGlyph.largestTextSize == .xxxLarge)
        let large = try layOut(.large)
        let largest = try layOut(.xxxLarge)
        // The room each glyph takes beside the text: its own width and the gap.
        func rooms(_ parts: (leading: CGRect, trailing: CGRect, field: CGRect)) -> (CGFloat, CGFloat) {
            (parts.field.minX - parts.leading.minX, parts.trailing.maxX - parts.field.maxX)
        }
        // The gap itself, between each glyph and the field's text.
        func gaps(_ parts: (leading: CGRect, trailing: CGRect, field: CGRect)) -> (CGFloat, CGFloat) {
            (parts.field.minX - parts.leading.maxX, parts.trailing.minX - parts.field.maxX)
        }
        for size in [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5] {
            let parts = try layOut(size)
            // The gaps are xxxLarge's, not the glyph's room alone.
            let (leadingGap, trailingGap) = gaps(parts)
            let (leadingGapAtLargest, trailingGapAtLargest) = gaps(largest)
            #expect(abs(leadingGap - leadingGapAtLargest) < Self.tolerance, "\(size): gap \(leadingGap)")
            #expect(abs(trailingGap - trailingGapAtLargest) < Self.tolerance, "\(size): gap \(trailingGap)")
            // The glyphs are drawn as at xxxLarge, and the field leaves them the same room.
            for (glyph, atLargest) in [(parts.leading, largest.leading), (parts.trailing, largest.trailing)] {
                #expect(abs(glyph.width - atLargest.width) < Self.tolerance, "\(size): \(glyph) for \(atLargest)")
                #expect(abs(glyph.height - atLargest.height) < Self.tolerance, "\(size): \(glyph) for \(atLargest)")
            }
            let (leadingRoom, trailingRoom) = rooms(parts)
            let (leadingAtLargest, trailingAtLargest) = rooms(largest)
            #expect(abs(leadingRoom - leadingAtLargest) < Self.tolerance, "\(size): \(leadingRoom)")
            #expect(abs(trailingRoom - trailingAtLargest) < Self.tolerance, "\(size): \(trailingRoom)")
            #if os(iOS)
                // The field's text grows on past xxxLarge: its lines are higher.
                #expect(parts.field.height > largest.field.height + 1, "\(size): \(parts.field) for \(largest.field)")
            #endif
        }
        #if os(iOS)
            // Up to xxxLarge the glyph grows with the text, as an icon beside text does.
            #expect(largest.leading.height > large.leading.height + 1, "\(largest.leading) for \(large.leading)")
            #expect(rooms(largest).0 > rooms(large).0 + 1, "\(rooms(largest)) for \(rooms(large))")
            // And so does the gap, on its own: a gap that kept its default size beside a growing glyph would fail.
            #expect(gaps(largest).0 > gaps(large).0 + 1, "gaps \(gaps(largest)) for \(gaps(large))")
            #expect(gaps(largest).1 > gaps(large).1 + 1, "gaps \(gaps(largest)) for \(gaps(large))")
        #else
            // macOS has no Dynamic Type: the glyph is the same at every text size.
            #expect(abs(largest.leading.height - large.leading.height) < Self.tolerance)
        #endif
    }

    @Test(
        "at the accessibility sizes a glyph is centred on the field's first line; up to xxxLarge it stands on its baseline",
        arguments: [TextFieldVariant.framed, .inline], [Axis.horizontal, .vertical])
    func centredOnTheFirstLineAtTheAccessibilitySizes(variant: TextFieldVariant, axis: Axis) throws {
        let text = axis == .vertical ? "Milk\nApples" : "Groceries"
        for size in [DynamicTypeSize.large, .xxxLarge, .accessibility1, .accessibility3, .accessibility5] {
            let laidOut = Self.layOut(
                Self.field(variant, axis: axis, text: text, trailing: .hash).dynamicTypeSize(size))
            // A line of the field's text role at this size, and the glyphs as they are drawn, at most at xxxLarge.
            let line = Self.layOut(Text(verbatim: "A").textRole(.body.regular).dynamicTypeSize(size))
            let largest = min(size, TextFieldGlyph.largestTextSize)
            let glyphs: [(CGRect, Laidout)] = [
                (
                    try #require(laidOut.parts[.leading]),
                    Self.layOut(Icon(.magnifier).textRole(.body.regular).dynamicTypeSize(largest))
                ),
                (
                    try #require(laidOut.parts[.trailing]),
                    Self.layOut(Icon(.hash).textRole(.body.regular).dynamicTypeSize(largest))
                ),
            ]
            for (frame, glyph) in glyphs {
                #if os(macOS)
                    let centred = false
                #else
                    let centred = size.isAccessibilitySize
                #endif
                if centred {
                    let middle = laidOut.baseline - line.baseline + line.size.height / 2
                    #expect(abs(frame.midY - middle) <= Self.pixel, "\(size): \(frame) for a line's middle \(middle)")
                    // Centred, it stands higher than on the baseline: the glyph is smaller than its text.
                    #expect(
                        frame.minY + glyph.baseline < laidOut.baseline - 1, "\(size): \(frame), \(glyph), \(laidOut)")
                } else {
                    #expect(
                        abs(frame.minY + glyph.baseline - laidOut.baseline) <= Self.pixel,
                        "\(size): \(frame), \(glyph), \(laidOut)")
                }
            }
        }
    }

    @Test(
        "a context's image scale changes neither a glyph nor the room the field leaves it",
        arguments: [TextFieldVariant.framed, .inline], [Image.Scale.small, .large])
    func imageScaleIsFixed(variant: TextFieldVariant, scale: Image.Scale) throws {
        let plain = Self.layOut(Self.field(variant, trailing: .hash))
        let scaled = Self.layOut(Self.field(variant, trailing: .hash).imageScale(scale))
        for part in [TextFieldGlyphAnchors.Part.leading, .field, .trailing] {
            let expected = try #require(plain.parts[part])
            let laidOut = try #require(scaled.parts[part])
            #expect(
                abs(laidOut.minX - expected.minX) < Self.tolerance && abs(laidOut.minY - expected.minY) < Self.tolerance
                    && abs(laidOut.width - expected.width) < Self.tolerance
                    && abs(laidOut.height - expected.height) < Self.tolerance,
                "\(part) under \(scale): \(laidOut) for \(expected)")
        }
        #expect(scaled.size == plain.size)
    }

    @Test(
        "a glyph as tall as its line or taller grows no field, and stays inside a framed one but at s on one line",
        arguments: [DynamicTypeSize.large, .xxxLarge])
    func aGlyphTallerThanItsLine(size: DynamicTypeSize) throws {
        // framed's text role, body.regular, which `field` gives inline's context too; each glyph at its fixed scale.
        let line = Self.layOut(Text(verbatim: "A").textRole(.body.regular).dynamicTypeSize(size))
        let heights = Westron.Icon.allCases.map { icon in
            (
                icon,
                Self.layOut(Icon(icon).imageScale(.medium).textRole(.body.regular).dynamicTypeSize(size)).size.height
            )
        }
        // The glyphs within a point of a line's height or taller (on macOS at large the trash and the wrench are
        // taller, on iOS at xxxLarge seven are as tall or taller), and the tallest, whether it is or not.
        let tallest = try #require(heights.max { $0.1 < $1.1 })
        let tall = heights.filter { $0.1 > line.size.height - 1 }
        print("TextFieldGlyphTests at \(size): a line \(line.size.height) pt; as tall or taller: \(tall)")
        var reachPastAFramedField: CGFloat = .zero
        for icon in Set(tall.map(\.0) + [tallest.0]).sorted(by: { $0.rawValue < $1.rawValue }) {
            for variant in [TextFieldVariant.framed, .inline] {
                for fieldSize in TextFieldSize.allCases {
                    for axis in [Axis.horizontal, .vertical] {
                        let text = axis == .vertical ? "Milk\nApples" : "Groceries"
                        let bare = Self.layOut(
                            Self.field(variant, size: fieldSize, axis: axis, text: text, leading: nil)
                                .dynamicTypeSize(size))
                        let laidOut = Self.layOut(
                            Self.field(variant, size: fieldSize, axis: axis, text: text, leading: icon, trailing: icon)
                                .dynamicTypeSize(size))
                        let name = "\(icon) on \(variant) \(fieldSize) \(axis) at \(size)"
                        // The row is the field's height: the glyph adds none.
                        #expect(
                            abs(laidOut.size.height - bare.size.height) < Self.tolerance, "\(name): \(laidOut.size)")
                        guard variant == .framed else { continue }
                        for part in [TextFieldGlyphAnchors.Part.leading, .trailing] {
                            let frame = try #require(laidOut.parts[part])
                            let reach = max(.zero, -frame.minY, frame.maxY - laidOut.size.height)
                            if fieldSize == .s && axis == .horizontal {
                                // At s on one line the field is no taller than its line at the larger text sizes (on
                                // iOS at xxxLarge), and such a glyph reaches past its fill, by at most a point and a
                                // half (the contract's description).
                                reachPastAFramedField = max(reachPastAFramedField, reach)
                                #expect(reach <= 1.5, "\(name): \(frame) in \(laidOut.size)")
                            } else {
                                // Elsewhere on framed it reaches into the field's padding, inside its fill.
                                #expect(reach <= Self.tolerance, "\(name): \(frame) in \(laidOut.size)")
                            }
                        }
                    }
                }
            }
        }
        print(
            "TextFieldGlyphTests at \(size): the farthest a glyph reaches past a framed field at s: \(reachPastAFramedField)"
        )
    }

    @Test("the generated overload takes the glyphs, each optional, after the variant and the size")
    func generatedSignature() {
        let both = TextField("Search", text: .constant(""))
            .textFieldStyle(.framed, size: .m, leadingIcon: .magnifier, trailingIcon: .hash)
        let leading = TextField("Search", text: .constant("")).textFieldStyle(.framed, leadingIcon: .magnifier)
        let trailing = TextField("Search", text: .constant("")).textFieldStyle(.inline, trailingIcon: .hash)
        let neither = TextField("Search", text: .constant("")).textFieldStyle(.framed, size: .s)
        _ = (both, leading, trailing, neither)
        let style = TextFieldVariantStyle(
            variant: .framed, size: nil, leadingIcon: .magnifier, trailingIcon: nil)
        #expect(style.leadingIcon == .magnifier && style.trailingIcon == nil)
        #expect(TextFieldGlyphNames(leading: nil, trailing: nil).isEmpty)
        #expect(!TextFieldGlyphNames(leading: nil, trailing: .hash).isEmpty)
    }

    @Test("a glyph takes the field's text role on framed and the context's on inline, in text.secondary in every state")
    func glyphTokens() {
        for states in TextFieldStyleTests.stateCombinations {
            let framed = TextFieldTokens(variant: .framed, states: states, highContrast: false)
            let inline = TextFieldTokens(variant: .inline, states: states, highContrast: true)
            #expect(framed.glyphFont == .body.regular && framed.glyphFont == framed.textFont)
            #expect(inline.glyphFont == nil)
            #expect(framed.glyphColor == .text.secondary && inline.glyphColor == .text.secondary)
        }
        #expect(TextFieldMetrics(variant: .framed, size: .s, axis: .vertical).gap == .space75)
        #expect(TextFieldMetrics(variant: .framed, size: .m, axis: .horizontal).gap == .space100)
        #expect(TextFieldMetrics(variant: .inline, size: .s, axis: .horizontal).gap == .space100)
    }
}

/// What a probe saw, written from its layout.
@MainActor
private final class Box {
    var value = TextFieldGlyphTests.Laidout()
}

/// Offers its one subview a width of 300 and records its size and its first baseline.
private struct Probe: Layout {
    let box: Box

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(ProposedViewSize(width: 300, height: nil)) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }
        let proposal = ProposedViewSize(width: 300, height: nil)
        let dimensions = subview.dimensions(in: proposal)
        let size = CGSize(width: dimensions.width, height: dimensions.height)
        let baseline = dimensions[.firstTextBaseline]
        MainActor.assumeIsolated {
            box.value.size = size
            box.value.baseline = baseline
        }
        subview.place(at: bounds.origin, proposal: proposal)
    }
}
