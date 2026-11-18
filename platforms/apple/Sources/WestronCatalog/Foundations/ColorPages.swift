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

    /// The twelve list colors with their six roles, in the catalog's theme.
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        TokenPage(title: title, summary: summary) {
            if dynamicTypeSize.isAccessibilitySize {
                TokenDetail(group + "*")
            }
            Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: SampleMetrics.rowSpacing) {
                if dynamicTypeSize.isAccessibilitySize {
                    // At an accessibility size a name takes a line of its own, above its cells: beside them it would
                    // get a column too narrow for one word.
                    GridRow {
                        themeTitles
                    }
                    ForEach(colors, id: \.name) { color in
                        GridRow {
                            label(color)
                                .gridCellColumns(Westron.Theme.allCases.count)
                        }
                        GridRow {
                            cells(color)
                        }
                    }
                } else {
                    GridRow {
                        TokenDetail(group + "*")
                        themeTitles
                    }
                    ForEach(colors, id: \.name) { color in
                        GridRow {
                            label(color)
                            cells(color)
                        }
                    }
                }
            }
        }
    }

    private var themeTitles: some View {
        ForEach(Westron.Theme.allCases, id: \.self) { theme in
            TokenDetail(theme.title)
                .gridColumnAlignment(.center)
        }
    }

    /// The color's name and, for a foreground, the background it is drawn on.
    private func label(_ color: Westron.Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TokenName(String(color.name.dropFirst(group.count)))
            if sample == .foreground {
                TokenDetail(ground(color).label)
            }
        }
    }

    /// The color in each theme.
    private func cells(_ color: Westron.Color) -> some View {
        ForEach(Westron.Theme.allCases, id: \.self) { theme in
            cell(color)
                .theme(theme)
        }
    }

    @ViewBuilder
    private func cell(_ color: Westron.Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: .radius75)
        switch sample {
        case .background:
            shape.fill(.background.canvas)
                .overlay(shape.inset(by: .space75).fill(Color(color)))
                .overlay(shape.strokeBorder(.border.default, lineWidth: .stroke.thin))
                .frame(width: SampleMetrics.cell.width, height: SampleMetrics.cell.height)
        case .foreground:
            // No frame round the cell: it would read as part of a border sample.
            if dynamicTypeSize.isAccessibilitySize {
                // At an accessibility size the sample sets the cell's height and the cells share the width, so that
                // the sample stays on its own ground instead of running past the cell.
                ForegroundSample(color: color)
                    .padding(.vertical, .space50)
                    .frame(maxWidth: .infinity, minHeight: SampleMetrics.cell.height)
                    .background { ColorStack(names: ground(color).names) }
                    .clipShape(shape)
            } else {
                ColorStack(names: ground(color).names)
                    .overlay { ForegroundSample(color: color) }
                    .clipShape(shape)
                    .frame(width: SampleMetrics.cell.width, height: SampleMetrics.cell.height)
            }
        }
    }

    /// The first background a foreground's token declares, top first, and its label; the canvas when it declares
    /// none.
    private func ground(_ color: Westron.Color) -> (names: [String], label: String) {
        guard let first = color.backgrounds.first else {
            return ([Westron.Color.background.canvas.name], "none declared; canvas")
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
                .textRole(.body.regular)
                .foregroundStyle(Color(color))
        } else if color.name.hasPrefix("color.icon.") {
            Icon(.grip)
                .textRole(.body.regular)
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
        case Westron.Color.border.focus.name: .stroke.thick
        default: .stroke.thin
        }
    }
}

/// The list colors in the catalog's own theme: a row per color, a column per role, each drawn as it is used.
private struct CategoryColorsPage: View {
    /// The roles in the order of the columns.
    private static let roles = [
        "background", "border", "icon", "text", "fill", "on-fill", "control", "on-control",
    ]

    var body: some View {
        TokenPage(
            title: "List colors",
            summary: "color.category.<name>.<role> in this screenshot's theme, each drawn as it is used: a tile with "
                + "its glyph, an outline, a dot, text, a fill and a glyph on it, a checked control's fill and its "
                + "check. control stands out from every ground at 3:1, 4.5:1 in high contrast."
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
                        Circle()
                            .strokeBorder(category.border, lineWidth: .stroke.regular)
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        Circle()
                            .fill(category.icon)
                            .frame(width: Size.dot, height: Size.dot)
                        Text("Aa")
                            .textRole(.body.strong)
                            .foregroundStyle(category.text)
                        Circle()
                            .fill(category.fill)
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        Circle()
                            .fill(category.fill)
                            .overlay {
                                Icon(.check)
                                    .font(Font(.caption.medium).weight(.bold))
                                    .foregroundStyle(category.onFill)
                            }
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        Circle()
                            .fill(category.control)
                            .frame(width: SampleMetrics.mark, height: SampleMetrics.mark)
                        Circle()
                            .fill(category.control)
                            .overlay {
                                Icon(.check)
                                    .font(Font(.caption.medium).weight(.bold))
                                    .foregroundStyle(category.onControl)
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
                        .font(Font(.caption.medium).monospaced())
                        .foregroundStyle(.text.secondary)
                        .fixedSize()
                }
            }
    }

    /// The tile under a list's glyph, with the glyph in the list's text color, as the sidebar draws it.
    private func tile(_ category: Westron.Category) -> some View {
        RoundedRectangle(cornerRadius: .radius100)
            .fill(category.background)
            .overlay {
                Icon(.tray)
                    .textRole(.footnote.medium)
                    .foregroundStyle(category.text)
            }
            .frame(width: SampleMetrics.tile, height: SampleMetrics.tile)
    }

    private enum Size {
        /// The narrowest a column gets; a role's name may be wider, on its own header line.
        static let cell: CGFloat = 30
        static let header: CGFloat = 14
        static let dot: CGFloat = 10
    }
}
