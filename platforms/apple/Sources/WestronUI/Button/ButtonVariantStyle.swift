// Hand-written. Button's look and behavior from its contract, spec/components/button/button.spec.yaml, on SwiftUI's own
// Button (decisions/0001, 0003). The generated `buttonStyle(_:size:iconOnly:)` (Generated/Button+Contract.swift)
// applies it; the tokens it draws come from ButtonTokens.swift.
//
// It is a `PrimitiveButtonStyle`, not a `ButtonStyle`, because only a primitive style decides whether an activation
// runs the action: loading refuses presses (the contract), and a `ButtonStyle` cannot. Its body is a system `Button`
// whose action calls `configuration.trigger()` unless the button is loading. Inside, a `ButtonStyle` draws it, since
// only a `ButtonStyle` sees `isPressed`.
//
// What the gate refuses, measured by the catalog's UI tests (CatalogUITests/ButtonBehaviorTests.swift): a touch and a
// click. What it cannot refuse, a contract gap (#23): an accessibility activation (VoiceOver, Switch Control, Voice
// Control) on iOS and macOS, and the keyboard shortcut a product attaches, on macOS (on iOS the simulator's keyboard
// does not reach shortcuts, so it is not measured). SwiftUI runs the product's action for those itself, on the
// product's `Button`, without its style.

import SwiftUI

/// westron's Button style, which the generated `buttonStyle(_:size:iconOnly:)` applies (decisions/0001, 0003).
struct ButtonVariantStyle: PrimitiveButtonStyle {
    let variant: ButtonVariant
    /// nil: the size comes from `controlSize`.
    let size: ButtonSize?
    let iconOnly: Bool

    func makeBody(configuration: Configuration) -> some View {
        ButtonGate(configuration: configuration, variant: variant, explicitSize: size, iconOnly: iconOnly)
    }
}

/// The system button that refuses activation while loading, and announces loading.
private struct ButtonGate: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool

    @Environment(\.isLoading) private var isLoading

    var body: some View {
        let isLoading = isLoading
        Button(role: configuration.role) {
            // Loading accepts no presses that reach this button; the button stays enabled, so it is not announced or
            // drawn as disabled (the contract's `loading`).
            if !isLoading { configuration.trigger() }
        } label: {
            configuration.label
        }
        .buttonStyle(ButtonLook(variant: variant, explicitSize: explicitSize, iconOnly: iconOnly))
        // Apple has no busy trait: loading is the button's accessibility value, read after its label, "Save, Loading,
        // button". The value is cleared at rest.
        .accessibilityValue(
            isLoading
                ? Text("Loading", bundle: .module, comment: "A button's state while its action runs")
                : Text(verbatim: ""))
    }
}

/// Draws the button from its tokens, in the states the system and the environment report.
private struct ButtonLook: ButtonStyle {
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool

    func makeBody(configuration: Configuration) -> some View {
        ButtonBody(configuration: configuration, variant: variant, explicitSize: explicitSize, iconOnly: iconOnly)
    }
}

private struct ButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isLoading) private var isLoading
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.forcedButtonStates) private var forcedStates
    @State private var isHovered = false

    /// The states the button is in, read where the system or westron's modifier keeps them, plus those the catalog
    /// forces (`forcedButtonStates`).
    private var states: Set<ButtonState> {
        var states = forcedStates
        if isHovered { states.insert(.hover) }
        if isFocused { states.insert(.focus) }
        if configuration.isPressed { states.insert(.pressed) }
        if !isEnabled { states.insert(.disabled) }
        if isLoading { states.insert(.loading) }
        return states.filter(\.isEntered)
    }

    var body: some View {
        let states = states
        let tokens = ButtonTokens(variant: variant, destructive: configuration.role == .destructive, states: states)
        let metrics = ButtonMetrics(ButtonSize.resolved(explicit: explicitSize, controlSize: controlSize))
        let shape = RoundedRectangle(cornerRadius: CGFloat(ButtonMetrics.radius), style: .continuous)
        let scalesDown = ButtonTokens.scalesDown(states: states) && !reduceMotion

        ButtonContent(
            label: configuration.label, tokens: tokens, metrics: metrics, iconOnly: iconOnly,
            isLoading: states.contains(.loading)
        )
        .padding(.horizontal, iconOnly ? 0 : CGFloat(metrics.paddingHorizontal))
        .modifier(ButtonFrame(minSide: CGFloat(metrics.height), isSquare: iconOnly))
        .background {
            ZStack {
                if let background = tokens.background {
                    shape.fill(background)
                }
                if let borderColor = tokens.borderColor, let borderWidth = tokens.borderWidth {
                    shape.strokeBorder(borderColor, lineWidth: CGFloat(borderWidth))
                }
            }
            .animation(.fade, value: states.contains(.hover))
            .animation(.press, value: states.contains(.pressed))
        }
        // The hit area is at least the recommended target, around what is drawn, without changing the layout. iOS and
        // watchOS honor a content shape larger than the frame; macOS does not, and there a click outside what is drawn
        // misses (a contract gap, #23): only size s, 24 pt, is below the target there.
        .contentShape(.interaction, MinimumTargetShape(minSide: CGFloat(ButtonMetrics.minimumTarget)))
        // Assistive technology outlines what is drawn, not the larger hit area.
        .contentShape(.accessibility, shape)
        #if os(macOS) || os(watchOS)
            // The system's focus ring follows the button's corners.
            .contentShape(.focusEffect, shape)
        #endif
        .opacity(tokens.opacity.map(Double.init) ?? 1)
        .scaleEffect(scalesDown ? ButtonTokens.pressScale : 1)
        .animation(.press, value: scalesDown)
        #if !os(watchOS)
            .onHover { hovering in
                isHovered = hovering && ButtonState.hover.isEntered
            }
        #endif
    }
}

/// The label slot and the icon slot, and the progress indicator in loading.
///
/// The resting content is laid out once, invisible and hidden from accessibility, and decides the size; what is drawn
/// is an overlay at that size. So loading never changes the width (P13): the indicator takes the icon's place, or,
/// when the label has no icon, the indicator, the gap and the label share the resting width and the label may
/// truncate.
private struct ButtonContent<Label: View>: View {
    let label: Label
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let iconOnly: Bool
    let isLoading: Bool

    var body: some View {
        styled(isLoading: false)
            .opacity(0)
            .accessibilityHidden(true)
            .overlayPreferenceValue(ButtonLabelHasIconKey.self) { hasIcon in
                if isLoading && !hasIcon {
                    // A label without an icon: the indicator goes before it.
                    HStack(spacing: CGFloat(metrics.gap)) {
                        ButtonProgress(color: tokens.progress, font: metrics.iconFont)
                        styled(isLoading: true)
                    }
                } else {
                    styled(isLoading: isLoading)
                }
            }
    }

    private func styled(isLoading: Bool) -> some View {
        label
            .labelStyle(
                ButtonLabelStyle(tokens: tokens, metrics: metrics, iconOnly: iconOnly, isLoading: isLoading)
            )
            .textRole(metrics.labelFont)
            .foregroundStyle(tokens.label)
            .multilineTextAlignment(.center)
    }
}

/// Whether the button's label is a `Label`, which has an icon slot: its label style sets it.
private struct ButtonLabelHasIconKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

/// Lays out a `Label` in the button: the icon before the title with the size's gap, the icon decorative; in icon-only,
/// the icon alone with the title as its accessible label; in loading, the indicator in the icon's place.
private struct ButtonLabelStyle: LabelStyle {
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let iconOnly: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if iconOnly {
                // The system's icon-only style keeps the title as the accessible label.
                SwiftUI.Label {
                    configuration.title
                } icon: {
                    icon(configuration)
                }
                .labelStyle(.iconOnly)
            } else {
                HStack(spacing: CGFloat(metrics.gap)) {
                    icon(configuration)
                        .accessibilityHidden(true)
                    configuration.title
                        .textRole(metrics.labelFont)
                        .foregroundStyle(tokens.label)
                }
            }
        }
        .preference(key: ButtonLabelHasIconKey.self, value: true)
    }

    /// The icon in its text role and color, or, in loading, the indicator over its place.
    private func icon(_ configuration: Configuration) -> some View {
        configuration.icon
            .textRole(metrics.iconFont)
            .foregroundStyle(tokens.icon)
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    ButtonProgress(color: tokens.progress, font: metrics.iconFont)
                }
            }
    }
}

/// The system's spinning progress indicator, in the color of the label and, where the platform lets it, about the size
/// of the icon it replaces. It is decorative: the button announces loading as its value.
private struct ButtonProgress: View {
    let color: Westron.Color
    let font: Westron.TextRole

    var body: some View {
        // macOS draws its spinner in its own gray and ignores `tint`, so the label's color is painted through the
        // spinner's shape instead, the same way on every platform.
        spinner
            .opacity(0)
            .overlay {
                Color(color).mask { spinner }
            }
            .accessibilityHidden(true)
    }

    private var spinner: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.small)
    }
}

/// A frame whose height is at least `minSide` and grows with the content; with `isSquare`, also as wide as it is
/// tall, so icon-only stays square when its glyph grows with Dynamic Type.
private struct ButtonFrame: ViewModifier {
    let minSide: CGFloat
    let isSquare: Bool

    func body(content: Content) -> some View {
        if isSquare {
            SquareLayout(minSide: minSide) { content }
        } else {
            content.frame(minHeight: minSide)
        }
    }
}

/// Lays its one subview out in a square: the larger of `minSide` and the subview's ideal width and height.
private struct SquareLayout: Layout {
    let minSide: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ideal = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        let side = max(minSide, ideal.width, ideal.height)
        return CGSize(width: side, height: side)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: ProposedViewSize(bounds.size))
    }
}

/// The view's rectangle, grown around its center to at least `minSide` on each side: the hit area of a button drawn
/// smaller than the platform's recommended target (chapter 08).
struct MinimumTargetShape: Shape {
    let minSide: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(Self.target(around: rect, minSide: minSide))
    }

    static func target(around rect: CGRect, minSide: CGFloat) -> CGRect {
        rect.insetBy(dx: -max(0, (minSide - rect.width) / 2), dy: -max(0, (minSide - rect.height) / 2))
    }
}
