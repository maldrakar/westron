// Hand-written. Chip's look and behavior from its contract, spec/components/chip/chip.spec.yaml, in its three forms,
// each a style on its own system control (decisions/0001, 0003; the contract's decisions/0001, Q1): the generated
// `toggleStyle(_:)`, `buttonStyle(_:)` and `labelStyle(_:)` (Generated/Chip+Contract.swift) apply `ChipToggleStyle`,
// `ChipButtonStyle` and `ChipLabelStyle`; the tokens they draw come from ChipTokens.swift, and one view, `ChipSurface`,
// draws all three.
//
// Selectable: `ToggleStyleConfiguration` has no `isPressed`, so the style follows the press as Checkbox's does: its body
// is a system `Button` that toggles the value, drawn by a `ButtonStyle`. Assistive technology meets that button,
// selected while on (`.isSelected`), as the pilot's tag chip is (the contract's decisions/0001, Q6, measured in
// CatalogUITests/ChipBehaviorTests). Pressable: a `ButtonStyle` on the product's own Button. Static: a `LabelStyle`,
// which, as the system's label styles do, reaches every Label below the modifier.

import SwiftUI

/// westron's Chip style in its selectable form, which the generated `toggleStyle(_:)` applies.
struct ChipToggleStyle: ToggleStyle {
    let variant: ChipVariant

    func makeBody(configuration: Configuration) -> some View {
        ChipToggleBody(configuration: configuration, variant: variant)
    }
}

/// The system button that toggles the value, and the selected button that assistive technology meets in its place.
private struct ChipToggleBody: View {
    let configuration: ToggleStyleConfiguration
    let variant: ChipVariant

    var body: some View {
        let isOn = configuration.$isOn
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            configuration.label
        }
        .buttonStyle(ChipLook(variant: variant, form: .selectable, isOn: configuration.isOn))
        // For assistive technology, a button that is selected while on, as the contract announces it (`checked:
        // selected`), with the toggle's trait taken off. Measured on iOS 26.3 (CatalogUITests/ChipBehaviorTests): the
        // system's own toggle in its button style as the representation, and the body with no representation, are
        // both a switch with the value 0 or 1, never selected; this one is a button, selected while on. The
        // surrounding Toggle, the product's, still gives it the value 0 or 1: `.accessibilityValue` inside the
        // representation or around it, on this body, does not change that (the contract's decisions/0001, Q6).
        .accessibilityRepresentation {
            Button {
                isOn.wrappedValue.toggle()
            } label: {
                configuration.label
            }
            .accessibilityRemoveTraits(.isToggle)
            .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
        }
    }
}

/// westron's Chip style in its pressable form, which the generated `buttonStyle(_:)` applies.
struct ChipButtonStyle: ButtonStyle {
    let variant: ChipVariant

    func makeBody(configuration: Configuration) -> some View {
        ChipLook(variant: variant, form: .pressable, isOn: false).makeBody(configuration: configuration)
    }
}

/// Draws a selectable or pressable chip from its tokens, in the states the system, the toggle and the catalog report.
private struct ChipLook: ButtonStyle {
    let variant: ChipVariant
    let form: ChipForm
    let isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        ChipControl(
            label: configuration.label, variant: variant, form: form, isOn: isOn, isPressed: configuration.isPressed)
    }
}

private struct ChipControl<Label: View>: View {
    let label: Label
    let variant: ChipVariant
    let form: ChipForm
    let isOn: Bool
    let isPressed: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.forcedChipStates) private var forcedStates
    @State private var isHovered = false

    /// Whether the chip is in a state of its contract, read where the system or the toggle keeps it, or forced by the
    /// catalog (`forcedChipStates`), among the states its form enters. The switch is exhaustive over the generated
    /// `ChipState`, so a state added to or renamed in the contract fails the build here until the style follows it.
    private func isIn(_ state: ChipState) -> Bool {
        guard state.isEntered, form.states.contains(state) else { return false }
        if forcedStates.contains(state) { return true }
        switch state {
        case .checked: return isOn
        case .hover: return isHovered
        case .focus: return isFocused
        case .pressed: return isPressed
        case .disabled: return !isEnabled
        }
    }

    var body: some View {
        let states = Set(ChipState.allCases.filter(isIn))
        ChipSurface(variant: variant, states: states, hitHeight: ChipMetrics.minimumHitHeight) {
            // The text role and the one line around the whole label, as Button's style does: a label that is only
            // text, `Toggle("Work", isOn:)` or `Button("Tue")`, never reaches a label style, and would otherwise be
            // drawn in the system's body font and wrap. A `Label` gets the same from `ChipContent`.
            label
                .labelStyle(ChipContentStyle())
                .textRole(ChipMetrics.labelFont)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        #if !os(watchOS)
            .onHover { hovering in
                isHovered = hovering && ChipState.hover.isEntered
            }
        #endif
        // A disabled view may receive no hover events, so a pointer that leaves while the chip is disabled would leave
        // it hovered, and the tint would come back when it is enabled again with the pointer away.
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { isHovered = false }
        }
    }
}

/// westron's Chip style in its static form, which the generated `labelStyle(_:)` applies: a value shown and not acted
/// on. It enters no state, lays out no hit area and adds no role: its title is read as text (the contract's `forms`).
struct ChipLabelStyle: LabelStyle {
    let variant: ChipVariant

    func makeBody(configuration: Configuration) -> some View {
        ChipSurface(variant: variant, states: [], hitHeight: nil) {
            ChipContent(icon: configuration.icon, title: configuration.title)
        }
    }
}

/// Lays out a `Label` in a selectable or pressable chip as the static form does. A label that is only text never
/// reaches it: `ChipControl` gives such a label the text role, the one line and the truncation around it.
private struct ChipContentStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChipContent(icon: configuration.icon, title: configuration.title)
    }
}

/// The icon slot and the label slot: the icon decorative, on the label's first baseline, at the symbol's small scale in
/// `icon.font`; the label one line, truncated at its end, in `label.font`. The colors come from `ChipSurface`, which
/// sets the label's as the foreground style and the icon's in `chipIconColor`.
private struct ChipContent<Icon: View, Title: View>: View {
    let icon: Icon
    let title: Title

    @Environment(\.chipIconColor) private var iconColor
    @ScaledMetric(relativeTo: Font.TextStyle(ChipMetrics.labelFont.textStyle)) private var gap = CGFloat(
        ChipMetrics.gap)

    var body: some View {
        // The icon sits on the label's first text baseline, not centered on it, as Button's does: a symbol's baseline
        // is its glyph's, so it lines up with the words as a letter would.
        HStack(alignment: .firstTextBaseline, spacing: gap) {
            icon
                .textRole(ChipMetrics.iconFont)
                .imageScale(ChipMetrics.iconScale)
                .foregroundStyle(iconColor.map { AnyShapeStyle(Color($0)) } ?? AnyShapeStyle(.foreground))
                .fixedSize()
                .accessibilityHidden(true)
            title
                .textRole(ChipMetrics.labelFont)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

extension EnvironmentValues {
    /// The icon's color inside a chip, which `ChipSurface` sets for `ChipContent`; nil outside a chip.
    @Entry fileprivate var chipIconColor: Westron.Color? = nil
}

/// The drawn chip around its content: the padding, the height, the capsule's fill and its high-contrast outline, the
/// opacity, the press's scale, and, for a control, the laid-out hit area around it. The padding and the gap scale with
/// Dynamic Type from their tokens, relative to the label's text style. The shape is the platform's capsule
/// (`container.shape`), SwiftUI's `Capsule`.
private struct ChipSurface<Content: View>: View {
    let variant: ChipVariant
    let states: Set<ChipState>
    /// The least height of the hit area; nil: the static form, which takes none.
    let hitHeight: CGFloat?
    @ViewBuilder let content: Content

    @Environment(\.category) private var category
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: Font.TextStyle(ChipMetrics.labelFont.textStyle)) private var padding = CGFloat(
        ChipMetrics.paddingHorizontal)

    var body: some View {
        // The only variant draws the chip; a new one fails the build here until it is drawn.
        switch variant.offered {
        case .chip: chip
        }
    }

    private var chip: some View {
        let tokens = ChipTokens(category: category, states: states, highContrast: contrast == .increased)
        let scalesDown = ChipTokens.scalesDown(states: states) && !reduceMotion
        let shape = Capsule()

        return
            content
            .foregroundStyle(tokens.label)
            .environment(\.chipIconColor, tokens.icon)
            .padding(.horizontal, padding)
            .frame(minHeight: CGFloat(ChipMetrics.height))
            .background {
                ZStack {
                    shape.fill(tokens.background)
                    if let borderColor = tokens.borderColor, let borderWidth = tokens.borderWidth {
                        shape.strokeBorder(borderColor, lineWidth: CGFloat(borderWidth))
                    }
                }
                .animation(.fade, value: tokens.background)
            }
            .animation(.fade, value: tokens.label)
            #if os(macOS) || os(watchOS)
                // The system's focus ring follows the drawn capsule, not the hit area around it.
                .contentShape(.focusEffect, shape)
            #endif
            .opacity(tokens.opacity.map(Double.init) ?? 1)
            .scaleEffect(scalesDown ? ChipTokens.pressScale : 1)
            .animation(.press, value: scalesDown)
            .modifier(ChipHitArea(minHeight: hitHeight))
    }
}

/// The hit area of a selectable or pressable chip: a frame at least `minHeight` high around the drawn chip, laid out
/// and not only hit-tested, so that it never takes a neighbor's touches or clicks (decisions/0001, Q11), every point of
/// it taking the press; across, the chip's width. nil: no hit area, the static form.
private struct ChipHitArea: ViewModifier {
    let minHeight: CGFloat?

    func body(content: Content) -> some View {
        if let minHeight {
            content
                .frame(minHeight: minHeight)
                .contentShape(Rectangle())
        } else {
            content
        }
    }
}
