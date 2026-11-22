import SwiftUI
import WestronUI

// IconTile's catalog entry, from spec/components/icon-tile/icon-tile.spec.yaml: the real `IconTile` at the system's three
// scales, beside titles in several text roles, in the twelve list colors and neutral, decorative against labeled, and
// alone in an empty screen's `ContentUnavailableView`.

extension CatalogEntry {
    static let iconTile = CatalogEntry(id: "icon-tile", title: "IconTile", section: .components) {
        IconTilePage()
    }
}

/// The colors a tile is drawn in: none, the neutral tile, then the twelve list colors in token order.
enum IconTileSampleColors {
    static let all: [Westron.Category?] = [nil] + Westron.Category.allCases.map { $0 }

    /// The most tiles to a line, so that a line fits an iPhone at the largest text size the sheet draws.
    static let perLine = 5

    /// The roles a tile is shown beside: a picker's or a sidebar's row, a list's row, a section's heading and a
    /// screen's header.
    static let roles: [(name: String, role: Westron.TextRole)] = [
        ("subheadline.regular", .subheadline.regular),
        ("body.regular", .body.regular),
        ("heading.medium", .heading.medium),
        ("heading.large", .heading.large),
    ]
}

/// A tile in each color of `IconTileSampleColors`.
struct IconTileColorLines: View {
    let icon: Westron.Icon

    var body: some View {
        IconTileWrap(perLine: IconTileSampleColors.perLine) {
            ForEach(IconTileSampleColors.all.indices, id: \.self) { index in
                IconTile(icon)
                    .category(IconTileSampleColors.all[index])
            }
        }
    }
}

/// Lays tiles out in lines of at most `perLine`, and fewer where the width offered holds fewer, so that a sheet whose
/// columns would squeeze them sees the squeeze and gives each column a picture of its own (`MatrixSheetProbe`).
struct IconTileWrap: Layout {
    let perLine: Int
    var spacing: CGFloat = .space50

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = lines(subviews, width: proposal.width)
        let widths = lines.map { line in
            line.map(\.width).reduce(0, +) + spacing * CGFloat(max(line.count - 1, 0))
        }
        let heights = lines.map { $0.map(\.height).max() ?? 0 }
        return CGSize(
            width: widths.max() ?? 0, height: heights.reduce(0, +) + spacing * CGFloat(max(lines.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        var index = 0
        for line in lines(subviews, width: bounds.width) {
            var x = bounds.minX
            for size in line {
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
                index += 1
            }
            y += (line.map(\.height).max() ?? 0) + spacing
        }
    }

    /// The subviews' ideal sizes, in lines: a new line after `perLine`, or where the next would pass `width`.
    private func lines(_ subviews: Subviews, width: CGFloat?) -> [[CGSize]] {
        var lines: [[CGSize]] = []
        var current: [CGSize] = []
        var used: CGFloat = 0
        for size in subviews.map({ $0.sizeThatFits(.unspecified) }) {
            let next = current.isEmpty ? size.width : used + spacing + size.width
            let full = current.count == perLine || (width.map { next > $0 + 0.5 } ?? false)
            if !current.isEmpty && full {
                lines.append(current)
                current = [size]
                used = size.width
            } else {
                current.append(size)
                used = next
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
}

/// A tile beside a title, both in `role`, aligned on the title's first baseline as a row aligns them.
struct IconTileBesideTitle: View {
    let icon: Westron.Icon
    let role: Westron.TextRole
    let title: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .space75) {
            IconTile(icon)
            Text(title)
                .foregroundStyle(.text.primary)
        }
        .textRole(role)
    }
}

/// An empty screen as the pilot draws it: the system's `ContentUnavailableView`, its icon a list's tile and its words
/// in westron's text roles and colors (decisions/0014: westron styles what is inside a system view). The system's own
/// gray for the description does not meet the text contrast on westron's canvas.
struct IconTileEmptyScreen: View {
    let icon: Westron.Icon

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("No tasks")
                    .textRole(.heading.medium)
                    .foregroundStyle(.text.primary)
            } icon: {
                IconTile(icon)
            }
        } description: {
            Text("Add a task.")
                .textRole(.body.regular)
                .foregroundStyle(.text.secondary)
        }
    }
}

/// One cell of IconTile's snapshot matrix (#24): a glyph at a scale, in body text's role, neutral, as the contract's
/// bindings draw it with no list color in the context.
struct IconTileMatrixCell: View {
    let values: IconTileMatrixValues

    init(_ values: IconTileMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here. The
        // contract has no states, so the state is always rest.
        let (glyph, scale, _) = values.fields
        IconTile(glyph)
            .imageScale(Image.Scale(contract: scale))
            .textRole(.body.regular)
            // Six rows of tiles grown to accessibility5 run past an iPhone's height, so the matrix's cells stop at
            // accessibility2; the beside-title supplement grows to accessibility5.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            // The tile is decorative and hidden; one element marks the cell for the sheet's count.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: glyph.rawValue))
    }
}

extension ComponentMatrix.Supplement {
    static let iconTileListColors = ComponentMatrix.Supplement(
        component: "icon-tile", id: "list-colors", title: "list colors and none",
        note: "The color is not a contract option: the tile takes it from .category(_:). Each cell: neutral, then the "
            + "twelve list colors, in body.regular. Growth stops at accessibility1.",
        keeps: [:], rows: ["folder"], rowsPerPicture: 1
    ) {
        let (glyph, scale, _) = IconTileMatrixValues($0).fields
        IconTileColorLines(icon: glyph)
            .imageScale(Image.Scale(contract: scale))
            .textRole(.body.regular)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: glyph.rawValue))
    }

    static let iconTileBesideTitle = ComponentMatrix.Supplement(
        component: "icon-tile", id: "beside-title", title: "beside a title",
        note: "The text role is not a contract option: the tile takes its size from the role of its context. Each "
            + "cell, top down: "
            + IconTileSampleColors.roles.map(\.name).joined(separator: ", ")
            + ", in teal, aligned on the title's first baseline. It grows to the largest text size; the matrix's own "
            + "cells stop at accessibility2.",
        keeps: [:], rows: ["folder"], rowsPerPicture: 1
    ) {
        let (glyph, scale, _) = IconTileMatrixValues($0).fields
        VStack(alignment: .leading, spacing: .space50) {
            ForEach(IconTileSampleColors.roles, id: \.name) { item in
                IconTileBesideTitle(icon: glyph, role: item.role, title: "List")
            }
        }
        .imageScale(Image.Scale(contract: scale))
        .category(.teal)
    }

    static let iconTileEmptyScreen = ComponentMatrix.Supplement(
        component: "icon-tile", id: "empty-screen", title: "an empty screen",
        note: "Alone, as the empty screen draws it: the system's ContentUnavailableView, whose label's icon is the "
            + "tile, in the font the system gives that icon, in violet (decisions/0014). iOS only: the in-process "
            + "render on macOS draws no icon of ContentUnavailableView, not even a plain Icon, and draws its scroll "
            + "indicator, beside which the words sit in one place or another from one render to the next, so macOS "
            + "has no such sheet; the catalog entry shows it on the Mac.",
        keeps: [:], rows: ["tray"], rowsPerPicture: 1, onlyOn: ["ios"]
    ) {
        let (glyph, scale, _) = IconTileMatrixValues($0).fields
        IconTileEmptyScreen(icon: glyph)
            .imageScale(Image.Scale(contract: scale))
            .category(.violet)
    }
}

/// The scales, the roles, the list colors, decorative against labeled, and an empty screen.
private struct IconTilePage: View {
    private static let glyphs: [Westron.Icon] = [.tray, .sun, .folder, .briefcase, .book, .flag]

    var body: some View {
        TokenPage(
            title: "IconTile",
            summary: "IconTile(.tray) draws a list's tile in the list color .category(_:) gives it, neutral with none, "
                + "sized by the text role around it and hidden from assistive technology; IconTile(.folder, label: "
                + "\"Garden\") is an image labeled Garden. .imageScale(_:) sets the system's scale."
        ) {
            VStack(alignment: .leading, spacing: .space.betweenGroups) {
                section("scale: small, medium, large, in body.regular") {
                    // Wrapped, so that at the largest text sizes the tiles stay within the screen's width.
                    ForEach(ComponentMatrix.iconTile.options[1].values, id: \.self) { scale in
                        IconTileWrap(perLine: Self.glyphs.count) {
                            ForEach(Self.glyphs.indices, id: \.self) { index in
                                IconTile(Self.glyphs[index])
                                    .category(index == 0 ? nil : Westron.Category.allCases[index * 2])
                            }
                        }
                        .imageScale(Image.Scale(contract: scale))
                        .textRole(.body.regular)
                    }
                }
                section("beside a title: size from the role") {
                    // The role's name over its sample, so that a large title keeps the screen's width.
                    ForEach(IconTileSampleColors.roles, id: \.name) { item in
                        VStack(alignment: .leading, spacing: .space25) {
                            TokenDetail(item.name.replacingOccurrences(of: ".", with: " "))
                            IconTileBesideTitle(icon: .folder, role: item.role, title: "Garden")
                        }
                    }
                    .category(.green)
                }
                section("list colors: neutral, then the twelve") {
                    IconTileColorLines(icon: .folder)
                        .textRole(.body.regular)
                }
                section("decorative and labeled") {
                    HStack(spacing: .space150) {
                        IconTile(.folder)
                        TokenDetail("IconTile(.folder): hidden")
                    }
                    HStack(spacing: .space150) {
                        IconTile(.folder, label: "Garden")
                            .accessibilityIdentifier(IconTilePageID.labeled)
                        TokenDetail("IconTile(.folder, label: \"Garden\"): an image, Garden")
                    }
                    .category(.green)
                }
                .textRole(.body.regular)
                section("an empty screen: ContentUnavailableView") {
                    IconTileEmptyScreen(icon: .tray)
                        .category(.violet)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .space75) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }
}

/// Identifiers of the tile page's samples, which the catalog's UI tests read.
enum IconTilePageID {
    static let labeled = "westron.catalog.icon-tile.labeled"
}
