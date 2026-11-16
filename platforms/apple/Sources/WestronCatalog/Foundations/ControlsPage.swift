import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The tokens a control is drawn with: its heights on this platform, its fills under the pointer and pressed, and
    /// the opacity of a disabled control.
    static let controls = CatalogEntry(
        id: "controls", title: "Controls: heights, fills, disabled", section: .foundations
    ) {
        ControlsPage()
    }
}

/// Token samples, not a component: plain shapes drawn at the tokens' values, in the catalog's theme.
private struct ControlsPage: View {
    /// The fills a control steps through as it is hovered and pressed, with the ink drawn on them.
    private struct FillStates {
        let name: String
        let word: String
        let label: Westron.Color
        let states: [(name: String, color: Westron.Color)]
    }

    private static let fills = [
        FillStates(
            name: "accent", word: "Save", label: .text.onAccent,
            states: [
                ("background.accent", .background.accent), ("accent-hover", .background.accentHover),
                ("accent-pressed", .background.accentPressed),
            ]),
        FillStates(
            name: "danger", word: "Delete", label: .status.danger.onFill,
            states: [
                ("status.danger.fill", .status.danger.fill), ("fill-hover", .status.danger.fillHover),
                ("fill-pressed", .status.danger.fillPressed),
            ]),
    ]

    private static let heights: [Westron.Dimension] = [.size.control.s, .size.control.m, .size.control.l]

    /// The platform this build's values belong to.
    private static var platform: String {
        #if os(macOS)
            "macOS"
        #elseif os(watchOS)
            "watchOS"
        #else
            "iOS"
        #endif
    }

    var body: some View {
        TokenPage(
            title: "Controls",
            summary: "size.control.* on \(Self.platform), the platform this build is for: the input decides the "
                + "height. Then the fills of a control at rest, under the pointer and pressed, and opacity.disabled, "
                + "which dims a whole control."
        ) {
            section("Height · size.control.* on \(Self.platform)") {
                Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: .space100) {
                    ForEach(Self.heights, id: \.name) { height in
                        GridRow {
                            TokenName(height.name)
                            TokenDetail(Points(height.value).text)
                                .gridColumnAlignment(.trailing)
                            sample("Save", fill: .background.accent, label: .text.onAccent)
                                .frame(height: CGFloat(height))
                        }
                    }
                }
            }
            section("Fills · at rest, hover, pressed") {
                Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: .space100) {
                    ForEach(Self.fills, id: \.name) { fill in
                        GridRow {
                            ForEach(fill.states, id: \.name) { state in
                                VStack(alignment: .leading, spacing: .space25) {
                                    sample(fill.word, fill: state.color, label: fill.label)
                                        .frame(height: .size.control.m)
                                    TokenDetail(state.name)
                                }
                            }
                        }
                    }
                }
            }
            section("Disabled · opacity.disabled \(String(Double.opacity.disabled))") {
                Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: .space100) {
                    ForEach([false, true], id: \.self) { disabled in
                        GridRow {
                            sample("Save", fill: .background.accent, label: .text.onAccent)
                            sample("Delete", fill: .status.danger.fill, label: .status.danger.onFill)
                            sample("Cancel", fill: .background.surface, label: .text.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: .radius.control)
                                        .strokeBorder(.border.strong, lineWidth: .stroke.thin))
                            TokenDetail(disabled ? "disabled" : "enabled")
                        }
                        .frame(height: .size.control.m)
                        .opacity(disabled ? .opacity.disabled : 1)
                    }
                }
            }
        }
    }

    private func sample(_ word: String, fill: Westron.Color, label: Westron.Color) -> some View {
        Text(word)
            .textRole(.body.strong)
            .foregroundStyle(label)
            .lineLimit(1)
            .padding(.horizontal, .space200)
            .frame(maxHeight: .infinity)
            .background(fill, in: RoundedRectangle(cornerRadius: .radius.control))
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}
