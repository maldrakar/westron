import SwiftUI
import WestronUI

extension CatalogEntry {
    /// Every icon of the registry with its name, at the size of body text.
    static let icons = CatalogEntry(id: "icons", title: "Icons", section: .foundations) {
        IconsPage()
    }
}

private struct IconsPage: View {
    var body: some View {
        TokenPage(
            title: "Icons",
            summary: "spec/icons/icons.yaml, in its order: each name says what the glyph draws. On Apple an SF Symbol "
                + "in the font of its text, here body. An unknown name draws the outlined one, bullets."
        ) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Size.cell), spacing: .space75, alignment: .top)],
                alignment: .leading,
                spacing: .space100
            ) {
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
                .fill(.backgroundSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: .radius100)
                        .strokeBorder(
                            icon == .fallback ? Color.borderFocus : Color.borderDefault, lineWidth: .strokeThin)
                }
                .overlay {
                    Image(icon)
                        .font(.bodyRegular)
                        .foregroundStyle(.textPrimary)
                }
                .frame(height: Size.tile)
            Text(icon.rawValue)
                .font(.captionMedium.monospaced())
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
