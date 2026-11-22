// Hand-written. IconTile's colors and proportions from its contract, spec/components/icon-tile/icon-tile.spec.yaml, as
// pure functions of the context's list color, so that IconTile draws exactly what they return and the tests compare
// them with the contract (Tests/WestronUITests/IconTileTests.swift).

import SwiftUI

/// The two colors a tile draws with, for one list color: the contract's bindings with no list color, its description
/// with one, the solid fill the owner chose (decisions/0001 of the contract, question 3).
struct IconTileColors: Equatable, Sendable {
    /// `tile.background`.
    var tile: Westron.Color
    /// `glyph.color`.
    var glyph: Westron.Color

    /// The colors of a tile in the list color `category` of its context; nil: the neutral tile, the contract's
    /// bindings, `color.background.muted` and `color.text.secondary`, never the accent; with one, the color's `fill`
    /// with the glyph in its `on-fill` (design-language/02).
    init(category: Westron.Category?) {
        guard let category else {
            tile = .background.muted
            glyph = .text.secondary
            return
        }
        tile = category.fill
        glyph = category.onFill
    }
}

/// The tile's proportions, which the contract gives as proportions and not as tokens: the tile is sized by the text of
/// its context, as Checkbox's circle is, and its glyph and corner by the tile (design-language/07, "Inside a shape, an
/// icon is sized by the shape"; design-language/04, "Off-ladder corners belong to one component").
enum IconTileMetrics {
    /// The symbol whose height at the context's image scale against medium gives every tile its scale's step, so the
    /// step is one for all tiles whatever they draw. A tall one: a short symbol's height, rounded to the screen's
    /// pixels, gives a step a few percent off on iOS.
    static let scaleReference: Westron.Icon = .folder

    /// The side as a multiple of the line height of the text role in the context: the pilot's tiles stand 1.42 to
    /// 1.58 lines tall beside their text, and the contract settles on 1.5 against the snapshot matrix.
    static let sidePerLine: CGFloat = 1.5  // westron-lint: allow a proportion to the text, the contract's 1.5 lines

    /// The side of the square the glyph is fitted into, as a part of the tile's side: the pilot's glyphs are 0.5 to
    /// 0.63 of their tiles, and the contract settles on 0.6.
    static let glyphPerSide: CGFloat = 0.6  // westron-lint: allow the glyph's proportion to its tile, the contract's

    /// The corner as a part of the side: a quarter, westron's ratio of a corner to a height (design-language/04).
    static let cornerPerSide: CGFloat = 0.25  // westron-lint: allow the corner's proportion to its tile, a quarter

    /// The tile's side beside text whose line is `lineHeight` tall, at a scale that draws a symbol `scaleStep` times
    /// its medium height.
    static func side(lineHeight: CGFloat, scaleStep: CGFloat) -> CGFloat {
        lineHeight * sidePerLine * scaleStep
    }

    /// The side of the square the glyph of a tile of `side` is fitted into.
    static func glyph(side: CGFloat) -> CGFloat {
        side * glyphPerSide
    }

    /// The corner radius of a tile of `side`.
    static func corner(side: CGFloat) -> CGFloat {
        side * cornerPerSide
    }
}
