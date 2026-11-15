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
                        RoundedRectangle(cornerRadius: .strokeThin)
                            .fill(.backgroundAccent)
                            .frame(width: CGFloat(step), height: .space150)
                    }
                }
            }
        }
    }
}

private struct ShapePage: View {
    var body: some View {
        TokenPage(
            title: "Radius, stroke, shadow",
            summary: "A capsule uses the platform's capsule shape, not a radius. A shadow's radius on Apple is half "
                + "its CSS blur."
        ) {
            section("Radius · radius.*") {
                ForEach(Westron.Dimension.all.filter { $0.name.hasPrefix("radius.") }, id: \.name) { radius in
                    sample(radius.name, [Points(radius.value).text]) {
                        RoundedRectangle(cornerRadius: CGFloat(radius))
                            .fill(.backgroundMuted)
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(radius))
                                    .strokeBorder(.borderDefault, lineWidth: .strokeThin)
                            )
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
            section("Stroke · stroke.*") {
                ForEach(Westron.Dimension.all.filter { $0.name.hasPrefix("stroke.") }, id: \.name) { stroke in
                    sample(stroke.name, [Points(stroke.value).text]) {
                        RoundedRectangle(cornerRadius: .radius100)
                            .strokeBorder(.textPrimary, lineWidth: CGFloat(stroke))
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
            section("Shadow · shadow.*") {
                ForEach(Westron.Shadow.all, id: \.name) { shadow in
                    sample(shadow.name, ["y \(Points(shadow.y).text)", "blur \(Points(shadow.blur).text)"]) {
                        RoundedRectangle(cornerRadius: .radius150)
                            .fill(.backgroundSurface)
                            .shadow(shadow)
                            .frame(width: Size.square, height: Size.square)
                    }
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .font(.subheadlineStrong)
                .foregroundStyle(.textPrimary)
            HStack(alignment: .top, spacing: .space150) {
                content()
            }
        }
    }

    private func sample(_ name: String, _ details: [String], @ViewBuilder shape: () -> some View) -> some View {
        VStack(spacing: .space75) {
            shape()
            VStack(spacing: 0) {
                Text(name.split(separator: ".").last.map(String.init) ?? name)
                    .font(.footnoteMedium.monospaced())
                    .foregroundStyle(.textPrimary)
                ForEach(details, id: \.self) { TokenDetail($0) }
            }
        }
        .fixedSize()
    }

    private enum Size {
        static let square: CGFloat = 44
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
