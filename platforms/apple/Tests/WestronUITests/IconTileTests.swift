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
        // The alternative fill changes only a list's colors.
        #expect(IconTileColors(category: nil, fill: .quiet) == colors)
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

    @Test("the quiet alternative open with the owner, which only the catalog draws: background and icon")
    func quietAlternative() {
        for category in Westron.Category.allCases {
            let colors = IconTileColors(category: category, fill: .quiet)
            #expect(colors.tile == category.background && colors.glyph == category.icon, "\(category)")
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
        let line = fittingSize(Text(verbatim: "X").textRole(role)).height
        let tile = fittingSize(IconTile(.folder).textRole(role))
        let expected = IconTileMetrics.side(lineHeight: line, scaleStep: 1)
        #expect(abs(tile.width - expected) < 0.5 && abs(tile.height - expected) < 0.5, "\(role.name): \(tile)")
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
        func side(_ scale: Image.Scale) -> CGFloat {
            fittingSize(IconTile(.folder).imageScale(scale).textRole(.body.regular)).height
        }
        func symbol(_ scale: Image.Scale) -> CGFloat {
            fittingSize(Image(IconTileMetrics.scaleReference).imageScale(scale).textRole(.body.regular)).height
        }
        let line = fittingSize(Text(verbatim: "X").textRole(.body.regular)).height
        #expect(abs(side(.medium) - IconTileMetrics.side(lineHeight: line, scaleStep: 1)) < 0.5)
        #expect(side(.small) < side(.medium) && side(.medium) < side(.large))
        for scale in [Image.Scale.small, .large] {
            let step = symbol(scale) / symbol(.medium)
            #expect(abs(side(scale) - IconTileMetrics.side(lineHeight: line, scaleStep: step)) < 0.5, "\(scale)")
        }
    }

    #if os(iOS)
        @Test("the tile grows with Dynamic Type in the ratio of the text's line")
        func growsWithDynamicType() {
            func measure(_ size: DynamicTypeSize) -> (line: CGFloat, side: CGFloat) {
                let line = fittingSize(Text(verbatim: "X").textRole(.body.regular).dynamicTypeSize(size)).height
                let side = fittingSize(IconTile(.folder).textRole(.body.regular).dynamicTypeSize(size)).height
                return (line, side)
            }
            let large = measure(.large)
            let accessibility = measure(.accessibility5)
            #expect(accessibility.side > large.side)
            for item in [large, accessibility] {
                #expect(abs(item.side / item.line - IconTileMetrics.sidePerLine) < 0.01, "\(item)")
            }
        }
    #endif

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
