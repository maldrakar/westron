import SwiftUI
import WestronUI

// Surface's catalog entry, from spec/components/surface/surface.spec.yaml: every kind, plain and outlined, each on the
// ground it is meant for, drawn with the real `.surface(_:outlined:)`. The kinds come from the generated matrix, so the
// page follows the contract. A raised or dragged surface stands on the canvas; an outlined one on a fill, inside a
// sunken well; a sunken one is a well on the canvas, and an outlined well sits on a raised card.

extension CatalogEntry {
    static let surface = CatalogEntry(id: "surface", title: "Surface", section: .components) {
        SurfacePage()
    }
}

/// What a sample surface holds: a title and a line under it, padded with `space.card`, as a product pads a card.
private struct SurfaceContent: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: .space25) {
            Text(title)
                .textRole(.body.strong)
                .foregroundStyle(.text.primary)
            Text(detail)
                .textRole(.footnote.regular)
                .foregroundStyle(.text.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.space.card)
    }
}

/// A surface of one kind with sample content, on the ground the contract gives it: a plain one on the canvas, with
/// room around it for its shadow; an outlined one on a fill, which is a sunken well for a raised or dragged surface
/// and a raised card for a sunken one.
struct SurfaceSample: View {
    let variant: SurfaceVariant
    let outlined: Bool

    private var sample: some View {
        SurfaceContent(title: Self.titles[variant] ?? "", detail: outlined ? "on a fill" : "on the canvas")
            .surface(variant, outlined: outlined)
    }

    /// Short words, so that a cell wraps between them at the largest text size.
    private static let titles: [SurfaceVariant: String] = [.raised: "Card", .dragged: "Lifted", .sunken: "Well"]

    var body: some View {
        if outlined {
            sample
                .padding(.space150)
                .surface(variant == .sunken ? .raised : .sunken)
        } else {
            sample
                .padding(.space150)
        }
    }
}

/// One cell of Surface's snapshot matrix (#24): a kind, plain or outlined, drawn as `SurfaceSample`.
struct SurfaceMatrixCell: View {
    let values: SurfaceMatrixValues

    init(_ values: SurfaceMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here. The
        // contract has no states, so the state is always rest.
        let (variant, outlined, _) = values.fields
        SurfaceSample(variant: variant, outlined: outlined)
            // One element that contains the sample's texts, so the sheet's cell identifier marks the cell once; the
            // texts inside stay as they are, since a surface adds nothing for assistive technology.
            .accessibilityElement(children: .contain)
    }
}

/// Surfaces nested as a board nests them: two outlined cards of a kind in a sunken column, which pads them with
/// `space.card` and spaces them with `space.within-group`; for a sunken kind, an outlined well inside a raised card. The
/// nested shapes sit further in than the outer corner's radius, so each keeps `radius.card` (the contract's
/// description, design-language/04, "Nested corners share a center").
struct SurfaceNesting: View {
    let variant: SurfaceVariant

    var body: some View {
        if variant == .sunken {
            VStack(alignment: .leading, spacing: .space.withinGroup) {
                Text("Card")
                    .textRole(.body.strong)
                    .foregroundStyle(.text.primary)
                SurfaceContent(title: "Well", detail: "in a card")
                    .surface(.sunken, outlined: true)
            }
            .padding(.space.card)
            .surface(.raised)
        } else {
            VStack(alignment: .leading, spacing: .space.withinGroup) {
                Text("Column")
                    .textRole(.footnote.medium)
                    .foregroundStyle(.text.secondary)
                SurfaceContent(title: "Task", detail: "in a column")
                    .surface(variant, outlined: true)
                SurfaceContent(title: "Task", detail: "in a column")
                    .surface(variant, outlined: true)
            }
            .padding(.space.card)
            .surface(.sunken)
        }
    }
}

extension ComponentMatrix.Supplement {
    /// Surfaces nested as a board nests them (#29): outlined cards in a sunken column, and an outlined well in a raised
    /// card. No contract option sets the nesting; the contract's description says how a nested shape keeps its corner.
    static let surfaceNesting = ComponentMatrix.Supplement(
        component: "surface", id: "nesting", title: "nested",
        note: "Nesting is not a contract option: the product nests surfaces. Raised and dragged: two outlined cards in "
            + "a sunken column, padded with space.card. Sunken: an outlined well in a raised card. Each nested shape "
            + "sits further in than the outer corner's radius, so it keeps radius.card (the contract's description).",
        keeps: ["outlined": "true"]
    ) {
        SurfaceNesting(variant: SurfaceMatrixValues($0).fields.variant)
            .accessibilityElement(children: .contain)
    }
}

/// Every kind of the contract, plain and outlined, each on its ground, then nested.
private struct SurfacePage: View {
    /// The narrowest column of the page's grids: three fit an iPhone in portrait at the default text size, and it
    /// grows with the text, so that a sample's longest word, "Column", still fits its column at a large size.
    @ScaledMetric(relativeTo: .body) private var column: CGFloat = 96

    private var combinations: [(variant: SurfaceVariant, outlined: Bool)] {
        ComponentMatrix.surface.combinations.map {
            let fields = SurfaceMatrixValues($0).fields
            return (fields.variant, fields.outlined)
        }
    }

    var body: some View {
        TokenPage(
            title: "Surface",
            summary: "content.surface(_:outlined:): the kind's background in radius.card with continuous corners, its "
                + "shadow in this theme, and in high contrast a stroke.thin line on raised and dragged. Outlined adds a "
                + "hairline for a surface on a fill. The product pads the content."
        ) {
            // A dragged surface's shadow in light reaches far below it: the room between the sections and the rows keeps
            // it off the labels that follow.
            VStack(alignment: .leading, spacing: .space600) {
                section("On the canvas") {
                    ForEach(combinations.filter { !$0.outlined }, id: \.variant) { item in
                        labeled(item.variant.rawValue) { SurfaceSample(variant: item.variant, outlined: false) }
                    }
                }
                section("Outlined, on a fill") {
                    ForEach(combinations.filter(\.outlined), id: \.variant) { item in
                        labeled(item.variant.rawValue) { SurfaceSample(variant: item.variant, outlined: true) }
                    }
                }
                section("Nested") {
                    ForEach(SurfaceVariant.allCases, id: \.self) { variant in
                        labeled(variant.rawValue) { SurfaceNesting(variant: variant) }
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .space50) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            AdaptiveGrid(minimum: column, spacing: .space150, rowSpacing: .space600) {
                content()
            }
        }
    }

    private func labeled<Content: View>(_ name: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .space25) {
            TokenName(name)
            content()
        }
    }
}
