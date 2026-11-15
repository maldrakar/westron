import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The background colors in the four themes, each laid on its theme's canvas.
    static let colorBackgrounds = CatalogEntry(
        id: "color-backgrounds", title: "Colors: backgrounds", section: .foundations
    ) {
        ThemeColorsPage(
            title: "Background colors",
            summary: "color.background.* in the four themes. Each cell is the theme's canvas; a translucent color is "
                + "laid over it.",
            group: "color.background.",
            colors: Westron.Color.all.filter { $0.name.hasPrefix("color.background.") },
            sample: .background)
    }

    /// The text, icon and border colors in the four themes, each on its first declared background.
    static let colorForegrounds = CatalogEntry(
        id: "color-foregrounds", title: "Colors: text, icons, borders", section: .foundations
    ) {
        ThemeColorsPage(
            title: "Text, icon and border colors",
            summary: "Each on the first background its token declares for the contrast check: “Aa” for text, a "
                + "glyph for icons, a ring for borders.",
            group: "color.",
            colors: Westron.Color.all.filter { color in
                ["color.text.", "color.icon.", "color.border."].contains { color.name.hasPrefix($0) }
            },
            sample: .foreground)
    }

    /// The eleven list colors with their six roles, in the catalog's theme.
    static let colorCategories = CatalogEntry(
        id: "color-categories", title: "Colors: list colors", section: .foundations
    ) {
        CategoryColorsPage()
    }
}

/// A row per color, a column per theme; every cell is drawn under its own theme.
private struct ThemeColorsPage: View {
    enum Sample {
        case background, foreground
    }

    let title: String
    let summary: String
    /// The part of the names the header shows once, `color.background.`.
    let group: String
    let colors: [Westron.Color]
    let sample: Sample

    var body: some View {
        TokenPage(title: title, summary: summary) {
            Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: SampleMetrics.rowSpacing) {
                GridRow {
                    TokenDetail(group + "*")
                    ForEach(Westron.Theme.allCases, id: \.self) { theme in
                        TokenDetail(theme.title)
                            .gridColumnAlignment(.center)
                    }
                }
                ForEach(colors, id: \.name) { color in
                    GridRow {
                        VStack(alignment: .leading, spacing: 0) {
                            TokenName(String(color.name.dropFirst(group.count)))
                            if sample == .foreground {
                                TokenDetail(ground(color).label)
                            }
                        }
                        ForEach(Westron.Theme.allCases, id: \.self) { theme in
                            cell(color)
                                .theme(theme)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ color: Westron.Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: .radius75)
        switch sample {
        case .background:
            shape.fill(.backgroundCanvas)
                .overlay(shape.inset(by: .space75).fill(Color(color)))
                .overlay(shape.strokeBorder(.borderDefault, lineWidth: .strokeThin))
                .frame(width: SampleMetrics.cell.width, height: SampleMetrics.cell.height)
        case .foreground:
            // No frame round the cell: it would read as part of a border sample.
            ColorStack(names: ground(color).names)
                .overlay { ForegroundSample(color: color) }
                .clipShape(shape)
                .frame(width: SampleMetrics.cell.width, height: SampleMetrics.cell.height)
        }
    }

    /// The first background a foreground's token declares, top first, and its label; the canvas when it declares
    /// none.
    private func ground(_ color: Westron.Color) -> (names: [String], label: String) {
        guard let first = color.backgrounds.first else {
            return ([Westron.Color.backgroundCanvas.name], "none declared; canvas")
        }
        return (first, "on " + first.map { Westron.Color.named($0)?.shortName ?? $0 }.joined(separator: " over "))
    }
}

/// What a foreground is drawn as: words for text, a glyph for an icon, a line for a border.
private struct ForegroundSample: View {
    let color: Westron.Color

    var body: some View {
        if color.name.hasPrefix("color.text.") {
            Text("Aa")
                .font(.bodyRegular)
                .foregroundStyle(Color(color))
        } else if color.name.hasPrefix("color.icon.") {
            Image(Westron.Icon.grip)
                .font(.bodyRegular)
                .foregroundStyle(Color(color))
        } else {
            RoundedRectangle(cornerRadius: .radius75)
                .strokeBorder(Color(color), lineWidth: lineWidth)
                .padding(.space75)
        }
    }

    /// The stroke the border is drawn with where it is used (decisions/0013).
    private var lineWidth: CGFloat {
        switch color.name {
        case Westron.Color.borderAccent.name: .strokeThick
        case Westron.Color.borderGlass.name: .strokeHairline
        default: .strokeThin
        }
    }
}

/// The list colors in the catalog's own theme: a row per color, a column per role, each drawn as it is used.
private struct CategoryColorsPage: View {
    /// The roles in the order of the columns.
    private static let roles = ["background", "background-subtle", "text", "border", "fill", "on-fill"]

    var body: some View {
        TokenPage(
            title: "List colors",
            summary: "color.category.<name>.<role> in this screenshot's theme, each drawn as it is used: a tile with "
                + "its glyph, a tint, text, a check's ring, a done check."
        ) {
            Grid(alignment: .center, horizontalSpacing: .space75, verticalSpacing: SampleMetrics.rowSpacing) {
                GridRow {
                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    ForEach(Self.roles.indices, id: \.self) { index in
                        header(index, line: 0)
                    }
                }
                GridRow {
                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    ForEach(Self.roles.indices, id: \.self) { index in
                        header(index, line: 1)
                    }
                }
                ForEach(Westron.Category.allCases, id: \.self) { category in
                    GridRow {
                        TokenName(category.rawValue)
                            .gridColumnAlignment(.leading)
                        tile(category)
                        RoundedRectangle(cornerRadius: .radius75)
                            .fill(.categoryBackgroundSubtle(category))
                            .frame(width: Size.cell, height: SampleMetrics.mark)
                        Text("Aa")
                            .font(.bodyStrong)
                            .foregroundStyle(.categoryText(category))
                        Circle()
                            .strokeBorder(.categoryBorder(category), lineWidth: .strokeRegular)
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        Circle()
                            .fill(.categoryFill(category))
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        Circle()
                            .fill(.categoryFill(category))
                            .overlay {
                                Image(Westron.Icon.check)
                                    .font(.captionMedium.weight(.bold))
                                    .foregroundStyle(.categoryOnFill(category))
                            }
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                    }
                }
            }
        }
    }

    /// A role's name above its column, on one of two lines in turn, so that a long name can be wider than the column.
    private func header(_ index: Int, line: Int) -> some View {
        Color.clear
            .frame(width: Size.cell, height: Size.header)
            .overlay {
                if index % 2 == line {
                    Text(Self.roles[index])
                        .font(.captionMedium.monospaced())
                        .foregroundStyle(.textSecondary)
                        .fixedSize()
                }
            }
    }

    /// The tile under a list's glyph, with the glyph in the list's text color, as the sidebar draws it.
    private func tile(_ category: Westron.Category) -> some View {
        RoundedRectangle(cornerRadius: .radius100)
            .fill(.categoryBackground(category))
            .overlay {
                Image(systemName: "tray.fill")
                    .font(.footnoteMedium)
                    .foregroundStyle(.categoryText(category))
            }
            .frame(width: SampleMetrics.tile, height: SampleMetrics.tile)
    }

    private enum Size {
        static let cell: CGFloat = 44
        static let header: CGFloat = 14
    }
}
