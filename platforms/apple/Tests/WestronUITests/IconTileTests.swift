import Foundation
import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// IconTile against its contract, spec/components/icon-tile/icon-tile.spec.yaml: the colors it draws with no list color
/// (the contract's bindings) and with each of the twelve (its description); its side, from the line of the text role
/// in its context and the system's image scale; its proportions; and its spoken label.
@Suite("IconTile")
@MainActor
struct IconTileTests {
    static let contractFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("spec/components/icon-tile/icon-tile.spec.yaml")

    /// A binding of the contract's `tokens:` block written on one line, `  <name>: <token>`.
    static func binding(_ name: String) throws -> String {
        let lines = try String(contentsOf: contractFile, encoding: .utf8).split(separator: "\n")
        let block = try #require(lines.firstIndex(of: "tokens:"))
        let line = try #require(lines[block...].first { $0.hasPrefix("  \(name): ") }, "no binding \(name)")
        return String(line.dropFirst("  \(name): ".count)).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Colors

    @Test("with no list color the tile draws the contract's bindings, the neutral tile, never the accent")
    func neutralTile() throws {
        let colors = IconTileColors(category: nil)
        #expect(colors.tile.name == (try Self.binding("tile.background")))
        #expect(colors.glyph.name == (try Self.binding("glyph.color")))
        #expect(colors.tile == .background.muted && colors.glyph == .text.secondary)
        #expect(colors.tile != .background.accent && colors.tile != .background.accentSubtle)
    }

    @Test("a list's color fills the tile with its fill and draws the glyph in its on-fill, for each of the twelve")
    func listColors() {
        #expect(Westron.Category.allCases.count == 12)
        for category in Westron.Category.allCases {
            let colors = IconTileColors(category: category)
            #expect(colors.tile == category.fill && colors.glyph == category.onFill, "\(category)")
            // The contract's description names them by their token paths.
            #expect(colors.tile.name == "color.category.\(category.rawValue).fill")
            #expect(colors.glyph.name == "color.category.\(category.rawValue).on-fill")
        }
    }

    // MARK: - Size

    @Test("the proportions: 1.5 lines for the side, 0.6 of the side for the glyph, a quarter for the corner")
    func proportions() {
        #expect(IconTileMetrics.side(lineHeight: 20, scaleStep: 1) == 30)
        #expect(IconTileMetrics.glyph(side: 30) == 18)
        #expect(IconTileMetrics.corner(side: 32) == 8)
        let path = IconTileShape().path(in: CGRect(x: 0, y: 0, width: 40, height: 40))
        #expect(path.boundingRect == CGRect(x: 0, y: 0, width: 40, height: 40))
    }

    @Test(
        "the tile is a square of 1.5 times the line of the text role in its context",
        arguments: [Westron.TextRole.caption.medium, .subheadline.regular, .body.regular, .heading.large])
    func sideFollowsTheTextRole(role: Westron.TextRole) {
        let heights = laidOutHeights(role: role)
        let expected = IconTileMetrics.side(lineHeight: heights.line, scaleStep: 1)
        #expect(
            abs(heights.tile.width - expected) < 0.01 && abs(heights.tile.height - expected) < 0.01,
            "\(role.name): expected \(expected), \(heights)")
    }

    @Test(
        "at each scale the side does not depend on the glyph or the list's color, so tiles in a column line up",
        arguments: [Image.Scale.small, .medium, .large])
    func sideIsTheTextsAlone(scale: Image.Scale) {
        let reference = fittingSize(IconTile(.tray).imageScale(scale).textRole(.body.regular))
        for icon in Westron.Icon.allCases {
            let size = fittingSize(IconTile(icon).imageScale(scale).textRole(.body.regular).category(.amber))
            #expect(
                abs(size.width - reference.width) < 0.5 && abs(size.height - reference.height) < 0.5,
                "\(icon) at \(scale): \(size) against \(reference)")
        }
    }

    @Test("the image scale scales the tile by the step the system scales a symbol by")
    func imageScale() {
        let medium = laidOutHeights(scale: .medium)
        let mediumSide = IconTileMetrics.side(lineHeight: medium.line, scaleStep: 1)
        #expect(abs(medium.tile.height - mediumSide) < 0.01, "medium: expected \(mediumSide), \(medium)")
        let small = laidOutHeights(scale: .small)
        let large = laidOutHeights(scale: .large)
        #expect(small.tile.height < medium.tile.height && medium.tile.height < large.tile.height)
        for (scale, heights) in [(Image.Scale.small, small), (.large, large)] {
            let step = heights.scaled / heights.medium
            let expected = IconTileMetrics.side(lineHeight: heights.line, scaleStep: step)
            #expect(
                abs(heights.tile.height - expected) < 0.01,
                "\(scale): step \(step), expected \(expected), \(heights)")
        }
    }

    #if os(iOS)
        @Test("the tile grows with Dynamic Type in the ratio of the text's line")
        func growsWithDynamicType() {
            let large = laidOutHeights(dynamicTypeSize: .large)
            let accessibility = laidOutHeights(dynamicTypeSize: .accessibility5)
            #expect(accessibility.tile.height > large.tile.height)
            for heights in [large, accessibility] {
                #expect(abs(heights.tile.height / heights.line - IconTileMetrics.sidePerLine) < 0.001, "\(heights)")
            }
        }
    #endif

    /// A tile and what it is sized by, side by side in one context: the line of the text role, the reference symbol at
    /// the context's image scale and at medium, as the tile's layout measures them, unrounded.
    ///
    /// Not through `fittingSize`: a hosting controller on iOS rounds its answer up to the next pixel, and a height
    /// already on a pixel often a whole pixel more, since it is a hair over it. The reference symbol at small,
    /// 14.33 points on a 3x screen, is 14.67 to the controller, and at medium the CI runner's simulator gave 18. A step
    /// of 14.67 / 18 from the controller's heights then made a side of 20.33 × 1.5 × 0.815 = 24.85, while the tile,
    /// from the heights its layout sees, 14.33 / 18, is 24.29, which the controller gives as 24.33: half a point
    /// apart, from rounding in the test's measure, not in the tile (#118). Measured as the layout measures, the heights
    /// carry no rounding of the test's own, and the side matches them to floating point.
    private func laidOutHeights(
        role: Westron.TextRole = .body.regular, scale: Image.Scale = .medium,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> LaidOutHeights.Heights {
        let measured = LaidOutHeights()
        _ = fittingSize(
            LaidOutHeights.Probe(measured: measured) {
                Text(verbatim: "X")
                Image(IconTileMetrics.scaleReference)
                Image(IconTileMetrics.scaleReference).imageScale(.medium)
                IconTile(.folder)
            }
            .imageScale(scale)
            .textRole(role)
            .dynamicTypeSize(dynamicTypeSize))
        return measured.heights
    }

    // MARK: - Accessibility

    @Test("without a label the tile is decorative; with one, the label is the list's name")
    func labels() {
        let decorative = IconTile(.tray)
        #expect(decorative.icon == .tray && decorative.label == nil)

        let localized = IconTile(.sun, label: "Today")
        #expect(localized.icon == .sun && localized.label == Text("Today"))

        // A name the person gave is not looked up as a key: the verbatim initializer takes a String.
        let title = "Garden"
        let verbatim = IconTile(.folder, label: title)
        #expect(verbatim.label == Text(verbatim: "Garden"))

        // A stored name that this version does not know draws the fallback.
        #expect(IconTile(Westron.Icon(rawValue: "no-such-icon") ?? .fallback).icon == .bullets)
    }

    @Test("an empty name is no label: a list with no title yet has a decorative tile, not an image without a name")
    func emptyLabel() {
        let untitled = IconTile(.folder, label: String())
        #expect(untitled.icon == .folder && untitled.label == nil)
        let substring = IconTile(.folder, label: "Garden".prefix(0))
        #expect(substring.label == nil)
    }

    private func fittingSize(_ view: some View) -> CGSize {
        #if os(macOS)
            // The controller's measure, not the view's fittingSize, which rounds up to whole points: a tile of 1.5
            // lines is often a half point.
            return NSHostingController(rootView: view).sizeThatFits(in: CGSize(width: 1000, height: 1000))
        #elseif os(iOS)
            return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 1000, height: 1000))
        #else
            return .zero
        #endif
    }
}

/// What a `LaidOutHeights.Probe` measured of its four subviews, as a layout sees them, unrounded.
final class LaidOutHeights: @unchecked Sendable {
    struct Heights: CustomStringConvertible {
        /// The height of the line of the text role.
        var line: CGFloat = 0
        /// The height of the reference symbol at the context's image scale.
        var scaled: CGFloat = 0
        /// The height of the reference symbol at medium.
        var medium: CGFloat = 0
        /// The tile's size.
        var tile: CGSize = .zero

        var description: String {
            "line \(line), symbol \(scaled) against \(medium) at medium, tile \(tile.width) × \(tile.height)"
        }
    }

    var heights = Heights()

    /// Measures its four subviews, the line, the reference symbol at the context's scale and at medium, and the tile,
    /// at their ideal sizes, as IconTile's layout measures its own, and stacks them.
    struct Probe: Layout {
        let measured: LaidOutHeights

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            if sizes.count == 4 {
                measured.heights = Heights(
                    line: sizes[0].height, scaled: sizes[1].height, medium: sizes[2].height, tile: sizes[3])
            }
            return CGSize(width: sizes.map(\.width).max() ?? 0, height: sizes.map(\.height).reduce(0, +))
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
            var y = bounds.minY
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: bounds.minX, y: y), proposal: ProposedViewSize(size))
                y += size.height
            }
        }
    }
}
