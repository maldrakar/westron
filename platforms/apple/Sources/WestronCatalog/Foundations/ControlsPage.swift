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
        FillStates(
            name: "muted", word: "Cancel", label: .text.primary,
            states: [
                ("background.muted", .background.muted), ("muted-hover", .background.mutedHover),
                ("muted-pressed", .background.mutedPressed),
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
                + "height; size.target.minimum is the least hit area, whatever the height. Then the fills of a control "
                + "at rest, under the pointer and pressed, and opacity.disabled, which dims a whole control."
        ) {
            section("Height · size.control.* on \(Self.platform)") {
                Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: .space100) {
                    ForEach(Self.heights, id: \.name) { height in
                        GridRow {
                            TokenName(height.name)
                            TokenDetail(Points(height.value).text)
                                .gridColumnAlignment(.trailing)
                            sample("Save", fill: .background.accent, label: .text.onAccent, height: CGFloat(height))
                        }
                    }
                    GridRow {
                        TokenName(Westron.Dimension.size.target.minimum.name)
                        TokenDetail(Points(Westron.Dimension.size.target.minimum.value).text)
                            .gridColumnAlignment(.trailing)
                        TokenDetail("the least hit area")
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
                            Group {
                                sample("Save", fill: .background.accent, label: .text.onAccent)
                                sample("Delete", fill: .status.danger.fill, label: .status.danger.onFill)
                                sample("Cancel", fill: .background.muted, label: .text.primary)
                            }
                            .modifier(DisabledSample(disabled: disabled))
                            // The row's caption is not a control: it keeps its contrast.
                            TokenDetail(disabled ? "disabled" : "enabled")
                        }
                    }
                }
            }
        }
    }

    /// A button's face at a height token, a capsule (decisions/0013, revision of 2026-11-20). The height is its least: the
    /// face grows with its text at a large Dynamic Type size, as a control does, so the word is never clipped.
    private func sample(
        _ word: String, fill: Westron.Color, label: Westron.Color, height: CGFloat = .size.control.m
    ) -> some View {
        Text(word)
            .textRole(.body.strong)
            .foregroundStyle(label)
            .padding(.horizontal, .space200)
            .frame(minHeight: height)
            .background(fill, in: Capsule())
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

/// A disabled control's face: dimmed by opacity.disabled, and announced as disabled, as a disabled control is. WCAG
/// exempts an inactive control from the contrast minimum (design-language chapter 08); the accessibility audit lets
/// these samples through by that value (`CatalogAccessibilityAuditTests`).
private struct DisabledSample: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        if disabled {
            content
                .opacity(.opacity.disabled)
                .accessibilityValue(Text("disabled"))
        } else {
            content
        }
    }
}
