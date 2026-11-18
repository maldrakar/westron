// Hand-written. Checkbox's look and behavior from its contract, spec/components/checkbox/checkbox.spec.yaml, on
// SwiftUI's own Toggle (decisions/0001, 0003): the round check that marks a task done. The generated
// `toggleStyle(_:)` (Generated/Checkbox+Contract.swift) applies it; the tokens it draws come from CheckboxTokens.swift.
//
// `ToggleStyleConfiguration` has no `isPressed`, so the style follows the press itself: its body is a system `Button`
// that toggles the value, drawn by a `ButtonStyle`, since only a `ButtonStyle` sees `isPressed`. The button also brings
// the system's activation and keyboard focus: Space toggles a focused check on macOS, and the system draws the focus
// ring (the contract's `focus`). For assistive technology the button is replaced by the system's own Toggle on the
// same value (`accessibilityRepresentation`), so VoiceOver meets the toggle's role and its on or off value, never a
// button: a switch on iOS and watchOS, a checkbox on macOS, as the contract's `platforms.apple` records.

import SwiftUI

/// westron's Checkbox style, which the generated `toggleStyle(_:)` applies (decisions/0001, 0003).
struct CheckboxVariantStyle: ToggleStyle {
    let variant: CheckboxVariant

    func makeBody(configuration: Configuration) -> some View {
        CheckboxBody(configuration: configuration, variant: variant)
    }
}

/// The system button that toggles the value, and the system toggle that assistive technology meets instead of it.
private struct CheckboxBody: View {
    let configuration: ToggleStyleConfiguration
    let variant: CheckboxVariant

    var body: some View {
        let isOn = configuration.$isOn
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            configuration.label
        }
        .buttonStyle(CheckboxLook(variant: variant, isOn: configuration.isOn))
        .accessibilityRepresentation {
            // The system's own style, not westron's, which the environment still holds here.
            Toggle(isOn: isOn) {
                configuration.label
            }
            .toggleStyle(.automatic)
        }
    }
}

/// Draws the check from its tokens, in the states the system, the toggle and the catalog report.
private struct CheckboxLook: ButtonStyle {
    let variant: CheckboxVariant
    let isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        CheckboxLookBody(label: configuration.label, variant: variant, isOn: isOn, isPressed: configuration.isPressed)
    }
}

private struct CheckboxLookBody<Label: View>: View {
    let label: Label
    let variant: CheckboxVariant
    let isOn: Bool
    let isPressed: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.category) private var category
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.forcedCheckboxStates) private var forcedStates
    /// The space between the check's hit area and its label, which grows with the text.
    @ScaledMetric private var gap: CGFloat = .space50

    /// Whether the check is in a state of its contract, read where the system or the toggle keeps it, or forced by the
    /// catalog (`forcedCheckboxStates`). The switch is exhaustive over the generated `CheckboxState`, so a state added
    /// to or renamed in the contract fails the build here until the style follows it (#20).
    private func isIn(_ state: CheckboxState) -> Bool {
        guard state.isEntered else { return false }
        if forcedStates.contains(state) { return true }
        switch state {
        case .checked: return isOn
        case .pressed: return isPressed
        case .focus: return isFocused
        case .disabled: return !isEnabled
        }
    }

    var body: some View {
        // The only variant draws the round check; a new one fails the build here until it is drawn.
        switch variant.offered {
        case .check: check
        }
    }

    private var check: some View {
        let states = Set(CheckboxState.allCases.filter(isIn))
        let tokens = CheckboxTokens(category: category, states: states)
        let motion = CheckboxMotion(reduceMotion: reduceMotion)
        let scalesDown = CheckboxTokens.scalesDown(states: states)

        // The circle sits on the label's first line: its cell carries the baseline of a line of the same text.
        return HStack(alignment: .firstTextBaseline, spacing: gap) {
            CheckboxCircle(tokens: tokens, isChecked: states.contains(.checked), motion: motion)
            label
        }
        // Every point of the check and its label takes the press, the empty corners of the hit area too.
        .contentShape(Rectangle())
        .scaleEffect(motion.scale(pressed: scalesDown))
        .animation(.press, value: scalesDown)
        .opacity(tokens.opacity.map(Double.init) ?? 1)
    }
}

/// The circle in its hit area: the ring when unchecked, the disc with the mark when checked. Its diameter follows the
/// line of the text it stands beside (`CheckboxMetrics`), measured on a hidden line of the environment's font, the
/// font the label's text takes when the product sets its text role on the toggle; the hidden line also gives the cell
/// its baseline. It is decorative: the toggle is announced with its label and value.
private struct CheckboxCircle: View {
    let tokens: CheckboxTokens
    let isChecked: Bool
    let motion: CheckboxMotion

    var body: some View {
        CheckboxCellLayout {
            Text(verbatim: "X")
                .hidden()
            ZStack {
                if let ring = tokens.ringColor, let width = tokens.ringWidth {
                    Circle()
                        .strokeBorder(ring, lineWidth: CGFloat(width))
                }
                if isChecked, let disc = tokens.disc, let mark = tokens.mark {
                    CheckboxDisc(disc: disc, mark: mark)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: motion.popScale).combined(with: .opacity)
                                    .animation(motion.check),
                                removal: .opacity.animation(motion.uncheck)))
                }
            }
            .animation(isChecked ? motion.check : motion.uncheck, value: isChecked)
        }
        .accessibilityHidden(true)
    }
}

/// The checked disc and the registry's check glyph on it, sized by the disc (P8).
private struct CheckboxDisc: View {
    let disc: Westron.Color
    let mark: Westron.Color

    var body: some View {
        ZStack {
            Circle()
                .fill(disc)
            GeometryReader { proxy in
                let side = CheckboxMetrics.mark(diameter: min(proxy.size.width, proxy.size.height))
                Image(Westron.Icon.check)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.bold)
                    .foregroundStyle(mark)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// Lays out the check's cell from two subviews, a hidden line of text and the circle: the circle's diameter is
/// `CheckboxMetrics.diameter` of the line's height, centered in a square of `CheckboxMetrics.hitSide`, which is the
/// cell's size and the check's least hit area. The line is centered too, so the cell's first text baseline, which the
/// layout takes from it, puts the circle's center on the middle of a line of the label beside it.
struct CheckboxCellLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let side = CheckboxMetrics.hitSide(diameter: diameter(subviews))
        return CGSize(width: side, height: side)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let diameter = diameter(subviews)
        for (index, subview) in subviews.enumerated() {
            let size = index == 0 ? ProposedViewSize.unspecified : ProposedViewSize(width: diameter, height: diameter)
            subview.place(at: center, anchor: .center, proposal: size)
        }
    }

    /// The circle's diameter: from the height of the hidden line, the first subview.
    private func diameter(_ subviews: Subviews) -> CGFloat {
        CheckboxMetrics.diameter(lineHeight: subviews.first?.sizeThatFits(.unspecified).height ?? 0)
    }
}
