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
        let laidOut = Self.layOut(Self.field(variant, size: size, trailing: .microphone))
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
            Self.field(.framed, text: "מצרכים", trailing: .microphone), direction: .rightToLeft)
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
        let microphone = Self.layOut(Icon(.microphone).textRole(.body.regular))
        let laidOut = Self.layOut(Self.field(variant, axis: axis, text: text, trailing: .microphone))
        let leading = try #require(laidOut.parts[.leading])
        let trailing = try #require(laidOut.parts[.trailing])
        // The field gives its first line's baseline, not its bottom, which a view without a baseline gives.
        #expect(bare.baseline < bare.size.height - 1, "a baseline at the bottom: \(bare)")
        if axis == .vertical {
            // Three lines: the first baseline is in the top third.
            #expect(bare.baseline < bare.size.height / 2, "\(bare)")
        }
        // The glyphs change neither the field's height nor where its text stands: they are drawn over the field's own
        // room and add no height, even where one reaches higher above its baseline than the first line (on iOS the
        // microphone, by a pixel, which a glyph beside the field in a stack added to a multi-line field's height).
        #expect(abs(laidOut.size.height - bare.size.height) < Self.tolerance, "\(laidOut.size) for \(bare.size)")
        #expect(abs(laidOut.baseline - bare.baseline) < Self.tolerance, "\(laidOut.baseline) for \(bare.baseline)")
        // Each glyph stands on the field's first baseline, its place rounded to the pixel.
        for (frame, glyph) in [(leading, magnifier), (trailing, microphone)] {
            #expect(
                abs(frame.minY + glyph.baseline - laidOut.baseline) <= Self.pixel, "\(frame), \(glyph), \(laidOut)")
        }
    }

    /// The most a place rounded to the pixel may be off: half a point, a pixel at 2x, a little more than one at 3x.
    static let pixel: CGFloat = 0.5

    @Test("the generated overload takes the glyphs, each optional, after the variant and the size")
    func generatedSignature() {
        let both = TextField("Search", text: .constant(""))
            .textFieldStyle(.framed, size: .m, leadingIcon: .magnifier, trailingIcon: .microphone)
        let leading = TextField("Search", text: .constant("")).textFieldStyle(.framed, leadingIcon: .magnifier)
        let trailing = TextField("Search", text: .constant("")).textFieldStyle(.inline, trailingIcon: .microphone)
        let neither = TextField("Search", text: .constant("")).textFieldStyle(.framed, size: .s)
        _ = (both, leading, trailing, neither)
        let style = TextFieldVariantStyle(
            variant: .framed, size: nil, leadingIcon: .magnifier, trailingIcon: nil)
        #expect(style.leadingIcon == .magnifier && style.trailingIcon == nil)
        #expect(TextFieldGlyphNames(leading: nil, trailing: nil).isEmpty)
        #expect(!TextFieldGlyphNames(leading: nil, trailing: .microphone).isEmpty)
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
