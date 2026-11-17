import SwiftUI
import WestronUI

extension CatalogEntry {
    /// Every icon of the registry with its name, at the size of body text.
    static let icons = CatalogEntry(id: "icons", title: "Icons", section: .foundations) {
        IconsPage()
    }
}

private struct IconsPage: View {
    /// The cell and the tile grow with the text they hold, so that a name and its glyph fit them at any Dynamic Type
    /// size.
    @ScaledMetric(relativeTo: .caption) private var cellWidth = Size.cell
    @ScaledMetric(relativeTo: .body) private var tileHeight = Size.tile

    var body: some View {
        TokenPage(
            title: "Icons",
            summary: "spec/icons/icons.yaml, in its order: each name says what the glyph draws. On Apple an SF Symbol "
                + "in the font of its text, here body. An unknown name draws the outlined one, bullets."
        ) {
            AdaptiveGrid(minimum: cellWidth, spacing: .space75, rowSpacing: .space100) {
                ForEach(Westron.Icon.allCases, id: \.self) { icon in
                    cell(icon)
                }
            }
        }
    }

    /// The glyph on a tile, its name under it.
    private func cell(_ icon: Westron.Icon) -> some View {
        VStack(spacing: .space50) {
            RoundedRectangle(cornerRadius: .radius100)
                .fill(.background.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: .radius100)
                        .strokeBorder(
                            icon == .fallback ? Westron.Color.border.focus : .border.default, lineWidth: .stroke.thin)
                }
                .overlay {
                    Image(icon)
                        .textRole(.body.regular)
                        .foregroundStyle(.text.primary)
                }
                .frame(height: tileHeight)
            Text(icon.rawValue)
                .font(Font(.caption.medium).monospaced())
                .foregroundStyle(.text.primary)
        }
        .accessibilityElement(children: .combine)
    }

    private enum Size {
        /// The narrowest a cell gets: room for `chevronLeft` in the caption's monospaced face.
        static let cell: CGFloat = 80
        #if os(macOS)
            static let tile: CGFloat = 36
        #else
            static let tile: CGFloat = 40
        #endif
    }
}
