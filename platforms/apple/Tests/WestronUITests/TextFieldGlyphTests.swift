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
        /// The window's pixels to a point (`layOutAll`).
        var displayScale: CGFloat = 1
    }

    /// Lays `field` out in a window, offered a width of 300.
    static func layOut(
        _ field: some View, direction: LayoutDirection = .leftToRight, displayScale: CGFloat? = nil
    ) -> Laidout {
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
            .environment(\.layoutDirection, direction)
            .transformEnvironment(\.displayScale) { scale in scale = displayScale ?? scale })
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

    /// The screens a glyph is laid out for: a Mac's at one pixel a point and at two, an iPhone's at three. The row reads
    /// the environment's `displayScale`, so each is set on the field whatever the screen running the tests.
    nonisolated static let displayScales: [CGFloat] = [1, 2, 3]

    @Test(
        "a glyph stands where it would within a pixel of its room, and is moved or fitted to it otherwise, at each scale",
        arguments: [DynamicTypeSize.large, .xxxLarge, .accessibility5], displayScales)
    func aGlyphStaysInItsRoom(size: DynamicTypeSize, displayScale: CGFloat) throws {
        // Every glyph of the registry at the size it is drawn at, at most xxxLarge, on its own: its size and baseline.
        let glyphSize = min(size, TextFieldGlyph.largestTextSize)
        let natural = Self.layOutAll(
            Westron.Icon.allCases.map {
                AnyView(Icon($0).imageScale(.medium).textRole(.body.regular).dynamicTypeSize(glyphSize))
            }, displayScale: displayScale)
        // A line of the fields' text role, body.regular, framed's and inline's context here, at the text's size.
        let line = Self.layOut(
            Text(verbatim: "A").textRole(.body.regular).dynamicTypeSize(size), displayScale: displayScale)
        #if os(macOS)
            let centred = false
        #else
            let centred = size.isAccessibilitySize
        #endif
        // A pixel and the margin: the layout snaps each edge of a glyph's frame to the pixel, half a pixel at most, which
        // the glyph's own size measured on its own is not; and what the rule allows past each edge of the room.
        let slack = TextFieldGlyphFitting.slack(displayScale: displayScale)
        for variant in [TextFieldVariant.framed, .inline] {
            for fieldSize in TextFieldSize.allCases {
                // Filled, and empty with the field's placeholder, on one line and on several.
                for (axis, text) in [
                    (Axis.horizontal, "Groceries"), (.horizontal, ""), (.vertical, "Milk\nApples"), (.vertical, ""),
                ] {
                    // The field's minimum height and vertical padding, which do not scale with the text.
                    let metrics = TextFieldMetrics(variant: variant, size: fieldSize, axis: axis)
                    let padding = metrics.paddingVertical.map(CGFloat.init) ?? .zero
                    let minimumHeight = metrics.height.map(CGFloat.init) ?? .zero
                    let fields = Self.layOutAll(
                        Westron.Icon.allCases.map {
                            AnyView(
                                Self.field(variant, size: fieldSize, axis: axis, text: text, leading: $0, trailing: $0)
                                    .dynamicTypeSize(size))
                        }, displayScale: displayScale)
                    for (index, icon) in Westron.Icon.allCases.enumerated() {
                        let field = fields[index]
                        let glyph = natural[index]
                        let name =
                            "\(icon) on \(variant) \(fieldSize) \(axis) \(text.isEmpty ? "empty" : "filled") at \(size), "
                            + "\(displayScale)x: the fill \(CGRect(origin: .zero, size: field.size)), a line "
                            + "\(line.size.height) pt, the glyph's own size \(glyph.size)"
                        #expect(field.displayScale == displayScale, "\(name): laid out at \(field.displayScale)x")
                        // The row is the system field's height: a glyph adds none. (A field beside two glyphs may wrap
                        // to more lines than one without, at the accessibility sizes: that is its text, not a glyph.)
                        let system = try #require(field.parts[.field], "\(name): no field")
                        #expect(
                            abs(field.size.height - max(minimumHeight, system.height + 2 * padding)) < Self.tolerance,
                            "\(name): \(field.size), the system field \(system)")
                        // The room: a framed field's fill, its frame; an inline field's first line, a line of its text
                        // role on the field's first baseline (never above a line's at its top, as an empty field of
                        // several lines gives on iOS), within the frame.
                        let fill = CGRect(origin: .zero, size: field.size)
                        let baseline = max(field.baseline, system.minY + line.baseline)
                        let firstLine = CGRect(
                            x: .zero, y: baseline - line.baseline, width: fill.width, height: line.size.height)
                        let room = variant == .framed ? fill : firstLine.intersection(fill)
                        // Where the glyph would stand: on the first baseline, or at the accessibility sizes centred on
                        // the first line, on the pixel.
                        let top =
                            centred
                            ? ((firstLine.midY - glyph.size.height / 2) * displayScale).rounded() / displayScale
                            : baseline - glyph.baseline
                        let standing = CGRect(x: .zero, y: top, width: glyph.size.width, height: glyph.size.height)
                        let (expected, fitted) = TextFieldGlyphFitting.place(
                            natural: standing, room: room, displayScale: displayScale)
                        for part in [TextFieldGlyphAnchors.Part.leading, .trailing] {
                            let frame = try #require(field.parts[part], "\(name): no \(part) glyph")
                            let what =
                                "\(name), the room \(room): the \(part) glyph at \(frame), standing at \(standing), "
                                + "placed at \(expected), fitted: \(fitted)"
                            // Where the rule places it, from where it would stand.
                            #expect(
                                abs(frame.minY - expected.minY) <= slack
                                    && abs(frame.height - expected.height) <= slack,
                                "\(what)")
                            // Never past its room by more than a pixel at an edge: a framed field's fill, an inline
                            // field's first line, on several lines too.
                            #expect(frame.minY >= room.minY - slack && frame.maxY <= room.maxY + slack, "\(what)")
                            // Its width is its own, so the field's text keeps its place.
                            #expect(abs(frame.width - glyph.size.width) <= slack, "\(what)")
                        }
                    }
                }
            }
        }
    }

    @Test("the rule of a glyph in its room, at one, two and three pixels a point", arguments: displayScales)
    func fittingRule(displayScale: CGFloat) {
        let pixel = 1 / displayScale
        let room = CGRect(x: 0, y: 0, width: 300, height: 16)
        func place(_ top: CGFloat, _ height: CGFloat, in room: CGRect = room) -> (frame: CGRect, fitted: Bool) {
            TextFieldGlyphFitting.place(
                natural: CGRect(x: 0, y: top, width: 18, height: height), room: room, displayScale: displayScale)
        }
        // A glyph two points taller than its room, centred, a point past each edge, as the wrench on a Mac's inline
        // field: within a pixel at 1x, left alone; at 2x and 3x scaled to the room, which it can no longer stand in.
        let wrench = place(-1, 18)
        if displayScale == 1 {
            #expect(!wrench.fitted && wrench.frame == CGRect(x: 0, y: -1, width: 18, height: 18), "\(wrench)")
        } else {
            #expect(wrench.fitted && wrench.frame == CGRect(x: 0, y: 0, width: 18, height: 16), "\(wrench)")
        }
        // A glyph a pixel taller than its room: left alone centred, and from the room's top, a pixel past its bottom.
        #expect(!place(-pixel / 2, 16 + pixel).fitted)
        #expect(!place(0, 16 + pixel).fitted)
        // Two pixels above, it is moved a pixel down, to a pixel past the top, at its own size.
        let raised = place(-2 * pixel, 16 + pixel)
        #expect(
            raised.fitted && abs(raised.frame.minY + pixel) < 1e-9 && raised.frame.height == 16 + pixel, "\(raised)")
        // A glyph that fits but stands off its baseline 1.5 pt past the room's bottom, as the new window on a Mac's
        // inline field: at 1x within no pixel, moved up to a pixel past it; so too at 2x and 3x.
        let low = place(5.5, 12)
        #expect(low.fitted && abs(low.frame.maxY - (16 + pixel)) < 1e-9 && low.frame.height == 12, "\(low)")
        // Half a pixel past is within a pixel: left alone.
        #expect(!place(4 + pixel / 2, 12).fitted)
        // iOS 27 at large, three pixels a point: a line of 61 pixels, 20.333333333333332 pt, from y = 1, and glyphs of 62,
        // 20.666666666666664 pt, which floating point puts a hair past room + 1/3. From the line's top the glyph is a
        // pixel past its bottom: left alone at 3x, and so at 1x and 2x, where it is less than a pixel past.
        let line = CGRect(x: 0, y: 1, width: 300, height: 20.333333333333332)
        let sun = place(1, 20.666666666666664, in: line)
        #expect(!sun.fitted && sun.frame.height == 20.666666666666664, "\(sun)")
        // A glyph of 22 pt in that line, from its top: past its bottom by 1.67 pt, more than two pixels taller at 2x
        // and 3x, scaled to the line; at 1x, 1.67 pt taller than the line, it stands at its own size from 0.67 pt
        // above its top, a pixel past its bottom.
        let tall = place(1, 22, in: line)
        if displayScale == 1 {
            #expect(tall.fitted && tall.frame.height == 22 && abs(tall.frame.maxY - (line.maxY + 1)) < 1e-9, "\(tall)")
        } else {
            #expect(tall.fitted && tall.frame == CGRect(x: 0, y: 1, width: 18, height: line.height), "\(tall)")
        }
    }

    @Test(
        "a fitted glyph is drawn within the field, as its own drawing scaled into its frame",
        arguments: [CGFloat(1), 2, 3, 4])
    func aFittedGlyphIsDrawnWithinItsRoom(displayScale: CGFloat) throws {
        // The anchors the tests above read are the glyph's layout frame; `TextFieldGlyphFit` scales its drawing into
        // that frame in a visual effect, which no anchor sees. So the pixels: each glyph of the registry on an empty
        // inline field of one line, whose room is the field, drawn and laid out at 1, 2, 3 and 4 pixels a point. On
        // macOS (no Dynamic Type) the wrench's frame, 18 pt, is taller than the field's 16 by a point at each edge:
        // within a pixel at 1x, scaled at 2x and more; on iOS at xxxLarge some frames outgrow the line, the wrench's
        // among them. A symbol's frame holds space above and below its ink, so a glyph drawn unscaled still inks within
        // the field here: the test also holds the ink to the glyph's own ink, scaled by the frame's height to its own
        // and centred in the frame. That fails at 2x, 3x and 4x if the drawing is not scaled (the wrench 0.86 to
        // 0.89 pt off at each edge); at 1x the wrench is left alone.
        #if os(macOS)
            let size = DynamicTypeSize.large
        #else
            let size = DynamicTypeSize.xxxLarge
        #endif
        let pixel = 1 / displayScale
        let slack = TextFieldGlyphFitting.slack(displayScale: displayScale)
        var scaled: [Westron.Icon] = []
        for icon in Westron.Icon.allCases {
            // The glyph on its own, as the field draws it: its size and the rows its ink spans, from its top.
            let own = try Self.draw(
                Icon(icon).imageScale(.medium).textRole(.body.regular).dynamicTypeSize(size), scale: displayScale)
            let ownSize = own.laidOut.size
            let ownInk = try #require(own.ink(fromX: 0, toX: CGFloat(own.width) / displayScale), "\(icon): no ink")
            let drawn = try Self.draw(
                Self.field(.inline, text: "", leading: icon).dynamicTypeSize(size), scale: displayScale)
            #expect(drawn.laidOut.displayScale == displayScale, "\(icon): laid out at \(drawn.laidOut.displayScale)x")
            let frame = try #require(drawn.laidOut.parts[.leading], "\(icon): no glyph")
            let field = try #require(drawn.laidOut.parts[.field], "\(icon): no field")
            if frame.height < ownSize.height - pixel / 2 { scaled.append(icon) }
            // The glyph's columns, from the image's edge to the middle of the gap before the field's text, so that
            // whatever the renderer draws for the system field is not read.
            let name =
                "\(icon) at \(size), \(displayScale)x: the field \(drawn.laidOut.size), the glyph's frame \(frame), its "
                + "own size \(ownSize), its own ink from \(ownInk.lowerBound - Drawn.margin) to "
                + "\(ownInk.upperBound - Drawn.margin)"
            let ink = try #require(
                drawn.ink(fromX: 0, toX: Drawn.margin + (frame.maxX + field.minX) / 2), "\(name): no ink")
            let top = ink.lowerBound - Drawn.margin
            let bottom = ink.upperBound - Drawn.margin
            // Within the field, to a pixel at each edge.
            #expect(
                top >= -slack && bottom <= drawn.laidOut.size.height + slack, "\(name): drawn from \(top) to \(bottom)")
            // Its own ink, scaled about its centre into its frame, to a pixel and a half: an edge of either ink may round
            // to the next pixel.
            let scale = frame.height / ownSize.height
            let expectedTop = frame.midY + (ownInk.lowerBound - Drawn.margin - ownSize.height / 2) * scale
            let expectedBottom = frame.midY + (ownInk.upperBound - Drawn.margin - ownSize.height / 2) * scale
            #expect(
                abs(top - expectedTop) <= 1.5 * pixel && abs(bottom - expectedBottom) <= 1.5 * pixel,
                "\(name): drawn from \(top) to \(bottom), for \(expectedTop) to \(expectedBottom)")
        }
        #if os(macOS)
            // The wrench is scaled where a pixel is less than the point it reaches past each edge.
            #expect(scaled.contains(.wrench) == (displayScale > 1), "scaled at \(displayScale)x: \(scaled)")
        #else
            if displayScale > 1 { #expect(scaled.contains(.wrench), "scaled at \(displayScale)x: \(scaled)") }
        #endif
    }

    /// A view drawn by `ImageRenderer`, with a clear margin around it so that a glyph drawn past the view is in the image,
    /// and what it laid out, read from the same render.
    struct Drawn {
        static let margin: CGFloat = 8
        let scale: CGFloat
        let laidOut: Laidout
        let width: Int
        let height: Int
        let alpha: [UInt8]

        /// The span, in points of the view's margin box, of the rows that hold a drawn pixel between two x positions.
        func ink(fromX minX: CGFloat, toX maxX: CGFloat) -> ClosedRange<CGFloat>? {
            let columns = max(0, Int((minX * scale).rounded(.down)))..<min(width, Int((maxX * scale).rounded(.up)))
            var rows: ClosedRange<Int>?
            for row in 0..<height where columns.contains(where: { alpha[row * width + $0] > 0 }) {
                rows = rows.map { min($0.lowerBound, row)...max($0.upperBound, row) } ?? row...row
            }
            return rows.map { CGFloat($0.lowerBound) / scale...CGFloat($0.upperBound + 1) / scale }
        }
    }

    /// Draws `view` at `scale` pixels a point, laid out at that scale too.
    static func draw(_ view: some View, scale: CGFloat) throws -> Drawn {
        let box = ManyBox(count: 1)
        let renderer = ImageRenderer(
            content:
                view
                .fixedSize(horizontal: false, vertical: true)
                .overlayPreferenceValue(TextFieldGlyphAnchors.self) { anchors in
                    Recorder(box: box, index: 0, anchors: anchors)
                }
                .frame(width: 300)
                .padding(Drawn.margin)
                .environment(\.colorScheme, .light)
                .environment(\.displayScale, scale))
        renderer.scale = scale
        let image = try #require(renderer.cgImage)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: &bytes, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let alpha = stride(from: 3, to: bytes.count, by: 4).map { bytes[$0] }
        return Drawn(scale: scale, laidOut: box.values[0], width: image.width, height: image.height, alpha: alpha)
    }

    @Test(
        "an empty field of several lines sets its glyphs on its placeholder's first baseline",
        arguments: [TextFieldVariant.framed, .inline])
    func emptyFieldOfSeveralLines(variant: TextFieldVariant) throws {
        // On iOS such a field gives a first baseline near its top, which set its glyphs above its fill and its
        // placeholder; its first line is at its top, so its baseline is a line's of its text role there.
        let line = Self.layOut(Text(verbatim: "A").textRole(.body.regular))
        let magnifier = Self.layOut(Icon(.magnifier).textRole(.body.regular))
        let hash = Self.layOut(Icon(.hash).textRole(.body.regular))
        let laidOut = Self.layOut(Self.field(variant, axis: .vertical, text: "", trailing: .hash))
        let field = try #require(laidOut.parts[.field])
        for (part, glyph) in [(TextFieldGlyphAnchors.Part.leading, magnifier), (.trailing, hash)] {
            let frame = try #require(laidOut.parts[part])
            #expect(
                abs(frame.minY + glyph.baseline - (field.minY + line.baseline)) <= Self.pixel,
                "\(part): \(frame), the field \(field), a line's baseline \(line.baseline)")
        }
    }

    /// Lays each view out in one window, each offered a width of 300, and returns its size, its first baseline, its
    /// glyphs and its field; at `displayScale` pixels a point where one is given, the window's otherwise.
    static func layOutAll(_ views: [AnyView], displayScale: CGFloat? = nil) -> [Laidout] {
        let box = ManyBox(count: views.count)
        TextFieldStyleTests.show(
            ZStack(alignment: .topLeading) {
                ForEach(views.indices, id: \.self) { index in
                    views[index]
                        .fixedSize(horizontal: false, vertical: true)
                        .alignmentGuide(.leading) { dimensions in
                            let baseline = dimensions[.firstTextBaseline]
                            MainActor.assumeIsolated { box.values[index].baseline = baseline }
                            return dimensions[.leading]
                        }
                        .overlayPreferenceValue(TextFieldGlyphAnchors.self) { anchors in
                            Recorder(box: box, index: index, anchors: anchors)
                        }
                }
            }
            .frame(width: 300, alignment: .topLeading)
            .transformEnvironment(\.displayScale) { scale in scale = displayScale ?? scale })
        return box.values
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

/// What each view of `layOutAll` laid out.
@MainActor
private final class ManyBox {
    var values: [TextFieldGlyphTests.Laidout]

    init(count: Int) {
        values = Array(repeating: TextFieldGlyphTests.Laidout(), count: count)
    }
}

/// Writes one view's size, its glyphs' and its field's bounds and its window's display scale into a `ManyBox`.
private struct Recorder: View {
    let box: ManyBox
    let index: Int
    let anchors: [TextFieldGlyphAnchors.Part: Anchor<CGRect>]
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { proxy in
            let _ = (box.values[index].size = proxy.size)
            let _ = (box.values[index].parts = anchors.mapValues { proxy[$0] })
            let _ = (box.values[index].displayScale = max(displayScale, 1))
            Color.clear
        }
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
