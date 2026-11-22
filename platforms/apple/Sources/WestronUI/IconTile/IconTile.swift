// Hand-written. IconTile from its contract, spec/components/icon-tile/icon-tile.spec.yaml: a list's mark, a rounded
// square in the list's color with the list's glyph on it. It is an own component in the form of a view
// (`platforms.apple.form`), since SwiftUI has no tile. The API parity lint holds `IconTile` and its initializers to the
// contract (spec/conventions.md, "Own components"). The glyph's type, `Westron.Icon`, is generated from
// spec/icons/icons.yaml; `scale` is the system's `.imageScale(_:)`; the list's color is the context's `.category(_:)`.

import SwiftUI

/// A list's tile: a rounded square in the list's color with the list's glyph on it (decisions/0011, 0012). Its color
/// comes from `.category(_:)` around it, as a checked check's does; with none, it is the neutral tile, never the accent.
/// It is sized by the text role of its context and grows with Dynamic Type; `.imageScale(_:)` makes it smaller or
/// larger than its text:
///
///     HStack { IconTile(.folder); Text(list.title) }
///         .textRole(.body.regular)
///         .category(Westron.Category(rawValue: list.color))
///
///     ContentUnavailableView {
///         Label { Text("No tasks") } icon: { IconTile(.tray) }
///     }
///
/// Without a label it is decorative and hidden from assistive technology: beside its list's title it would only repeat
/// it. A tile that stands without its list's name takes the name as its label, `IconTile(.folder, label: list.title)`,
/// and is announced as an image with it.
public struct IconTile: View {
    let icon: Westron.Icon
    /// The spoken label; nil for a decorative tile.
    let label: Text?

    @Environment(\.category) private var category

    /// A decorative tile, hidden from assistive technology: `IconTile(.tray)`.
    ///
    /// - Parameter icon: The list's glyph; a stored name reads as `Westron.Icon(rawValue: name) ?? .fallback`.
    public init(_ icon: Westron.Icon) {
        self.icon = icon
        label = nil
    }

    /// A tile announced as an image with a localized label: `IconTile(.sun, label: "Today")`.
    public init(_ icon: Westron.Icon, label: LocalizedStringKey) {
        self.icon = icon
        self.label = Text(label)
    }

    /// A tile with a label that is not localized, such as the name the person gave the list:
    /// `IconTile(.folder, label: list.title)`. An empty name is no label: the tile is decorative and hidden, so that a
    /// list with no title yet exposes no image without a name.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ icon: Westron.Icon, label: S) {
        self.icon = icon
        self.label = label.isEmpty ? nil : Text(label)
    }

    public var body: some View {
        let colors = IconTileColors(category: category)
        IconTileLayout {
            // The line of the context's text, which sizes the tile and gives it its baseline.
            Text(verbatim: "X")
                .hidden()
            // One symbol at the context's scale and at medium: their ratio is the scale's step. It is the same symbol
            // for every tile, not the tile's glyph, whose ratio differs a little from glyph to glyph at large, so
            // that tiles in a column keep one side.
            Image(IconTileMetrics.scaleReference)
                .hidden()
            Image(IconTileMetrics.scaleReference)
                .imageScale(.medium)
                .hidden()
            IconTileShape()
                .fill(colors.tile)
            Image(icon)
                .resizable()
                .symbolRenderingMode(.monochrome)
                .scaledToFit()
                .foregroundStyle(colors.glyph)
        }
        // The tile is one element, an image with its label. On iOS the symbol inside stays an image of its own, named
        // after the symbol, under `.accessibilityElement(children: .ignore)` or `.accessibilityHidden(true)` on it
        // (IconTileAccessibilityTests), so the tile replaces what its parts expose.
        .accessibilityRepresentation {
            Color.clear
                .accessibilityLabel(label ?? Text(verbatim: ""))
                .accessibilityAddTraits(.isImage)
        }
        .accessibilityHidden(label == nil)
    }
}

/// The tile's rounded square: a continuous corner of a quarter of its side, at any size.
struct IconTileShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        return RoundedRectangle(cornerRadius: IconTileMetrics.corner(side: side), style: .continuous).path(in: rect)
    }
}

/// Lays out a tile from five subviews: a hidden line of the context's text, the reference symbol
/// `IconTileMetrics.scaleReference` hidden at the context's scale and at medium, the shape and the tile's glyph. The
/// side is `IconTileMetrics.side` of the line's height and the scale's step; the shape fills it, and the glyph is
/// fitted into a square of `IconTileMetrics.glyph` of it, both centered. The line is centered too, and the tile's text
/// baselines are the line's, so a row aligned on its first text baseline puts the tile's center on the middle of its
/// title's first line.
struct IconTileLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let side = side(subviews)
        return CGSize(width: side, height: side)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let side = side(subviews)
        let glyph = IconTileMetrics.glyph(side: side)
        for (index, subview) in subviews.enumerated() {
            let size: ProposedViewSize =
                switch index {
                case 0, 1, 2: .unspecified
                case 3: ProposedViewSize(width: side, height: side)
                default: ProposedViewSize(width: glyph, height: glyph)
                }
            subview.place(at: center, anchor: .center, proposal: size)
        }
    }

    func explicitAlignment(
        of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
        cache: inout ()
    ) -> CGFloat? {
        guard guide == .firstTextBaseline || guide == .lastTextBaseline, let line = subviews.first else { return nil }
        let dimensions = line.dimensions(in: .unspecified)
        return bounds.midY - dimensions.height / 2 + dimensions[guide]
    }

    /// The tile's side: from the height of the hidden line and the ratio of the hidden reference symbols' heights.
    private func side(_ subviews: Subviews) -> CGFloat {
        guard subviews.count > 2 else { return 0 }
        let line = subviews[0].sizeThatFits(.unspecified).height
        let scaled = subviews[1].sizeThatFits(.unspecified).height
        let medium = subviews[2].sizeThatFits(.unspecified).height
        return IconTileMetrics.side(lineHeight: line, scaleStep: medium > 0 ? scaled / medium : 1)
    }
}
