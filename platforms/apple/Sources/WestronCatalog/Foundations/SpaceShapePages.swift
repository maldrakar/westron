import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The space ladder as bars of their true length.
    static let space = CatalogEntry(id: "space", title: "Space", section: .foundations) {
        SpacePage()
    }

    /// The radius ladder, the strokes and the shadows.
    static let shape = CatalogEntry(id: "shape", title: "Radius, stroke, shadow", section: .foundations) {
        ShapePage()
    }
}

private struct SpacePage: View {
    private var steps: [Westron.Dimension] {
        Westron.Dimension.all.filter { $0.name.hasPrefix("space.") }
    }

    var body: some View {
        TokenPage(
            title: "Space",
            summary: "space.*: steps on a ladder where 100 is the base unit of 8 pt. Each bar is as long as its step."
        ) {
            Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: .space75) {
                ForEach(steps, id: \.name) { step in
                    GridRow {
                        TokenName(step.name)
                        TokenDetail(Points(step.value).text)
                            .gridColumnAlignment(.trailing)
                        RoundedRectangle(cornerRadius: .stroke.thin)
                            .fill(.background.accent)
                            .frame(width: CGFloat(step), height: .space150)
                    }
                }
            }
        }
    }
}

private struct ShapePage: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    /// The radius ladder's steps, then the radius of each kind of shape.
    private var radii: (ladder: [Westron.Dimension], roles: [Westron.Dimension]) {
        let all = Westron.Dimension.all.filter { $0.name.hasPrefix("radius.") }
        let isStep = { (radius: Westron.Dimension) in radius.name.dropFirst("radius.".count).allSatisfy(\.isNumber) }
        return (all.filter(isStep), all.filter { !isStep($0) })
    }

    var body: some View {
        TokenPage(
            title: "Radius, stroke, shadow",
            summary: "A capsule uses the platform's capsule shape, not a radius. A shadow's radius on Apple is half "
                + "its CSS blur; the layers are this screenshot's theme's."
        ) {
            section("Radius · radius.<step>") {
                ForEach(radii.ladder, id: \.name) { radius in
                    sample(radius.name, [Points(radius.value).text]) {
                        RoundedRectangle(cornerRadius: CGFloat(radius))
                            .fill(.background.muted)
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(radius))
                                    .strokeBorder(.border.default, lineWidth: .stroke.thin)
                            )
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
            section("Radius · radius.<shape>") {
                ForEach(radii.roles, id: \.name) { radius in
                    sample(radius.name, [Points(radius.value).text]) {
                        RoundedRectangle(cornerRadius: CGFloat(radius))
                            .fill(.background.muted)
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(radius))
                                    .strokeBorder(.border.default, lineWidth: .stroke.thin)
                            )
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
            section("Stroke · stroke.*") {
                ForEach(Westron.Dimension.all.filter { $0.name.hasPrefix("stroke.") }, id: \.name) { stroke in
                    sample(stroke.name, [Points(stroke.value).text]) {
                        RoundedRectangle(cornerRadius: .radius100)
                            .strokeBorder(.text.primary, lineWidth: CGFloat(stroke))
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
            section("Shadow · shadow.*", column: Size.wideColumn) {
                ForEach(Westron.Shadow.all, id: \.name) { shadow in
                    sample(shadow.name, details(shadow)) {
                        RoundedRectangle(cornerRadius: .radius150)
                            .fill(.background.surface)
                            .shadow(shadow)
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
        }
    }

    /// Each layer of the shadow in this theme, as its offset and blur; "none" for a theme that casts none.
    private func details(_ shadow: Westron.Shadow) -> [String] {
        let layers = shadow[Westron.Theme(colorScheme: colorScheme, contrast: contrast)]
        guard !layers.isEmpty else { return ["none"] }
        return layers.map { "y \(Points($0.y).text), blur \(Points($0.blur).text)" }
    }

    private func section(
        _ title: String, column: CGFloat = Size.column, @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            AdaptiveGrid(minimum: column, spacing: .space100, rowSpacing: .space150) {
                content()
            }
        }
    }

    private func sample(_ name: String, _ details: [String], @ViewBuilder shape: () -> some View) -> some View {
        VStack(spacing: .space75) {
            shape()
            VStack(spacing: 0) {
                Text(name.split(separator: ".").last.map(String.init) ?? name)
                    .font(Font(.footnote.medium).monospaced())
                    .foregroundStyle(.text.primary)
                ForEach(details, id: \.self) { TokenDetail($0) }
            }
        }
        .fixedSize()
    }

    private enum Size {
        static let square: CGFloat = 44
        static let column: CGFloat = 64
        static let wideColumn: CGFloat = 140
    }
}

/// A length as the samples label it: `8 pt`, `0.5 pt`.
struct Points {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    var text: String {
        (value.rounded() == value ? String(Int(value)) : String(value)) + " pt"
    }
}
