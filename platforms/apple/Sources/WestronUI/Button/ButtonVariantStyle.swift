// Hand-written. Button's look and behavior from its contract, spec/components/button/button.spec.yaml, on SwiftUI's own
// Button (decisions/0001, 0003). The generated `buttonStyle(_:size:iconOnly:)` (Generated/Button+Contract.swift)
// applies it; the tokens it draws come from ButtonTokens.swift.
//
// It is a `PrimitiveButtonStyle`, not a `ButtonStyle`, because only a primitive style decides whether an activation
// runs the action: loading refuses presses (the contract), and a `ButtonStyle` cannot. Its body is a system `Button`
// whose action calls `configuration.trigger()` unless the button is loading. Inside, a `ButtonStyle` draws it, since
// only a `ButtonStyle` sees `isPressed`.
//
// The gate refuses a touch and a click. SwiftUI runs the product's action for two other inputs itself, on the product's
// `Button`, around its style: an accessibility activation (VoiceOver, Switch Control, Voice Control), which
// `.loading(_:)` refuses from outside the button (States.swift), and a keyboard shortcut on macOS, which nothing in
// westron can refuse (a contract gap, #23). The catalog's UI tests measure each (CatalogUITests/ButtonBehaviorTests).

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
        // button". The value is cleared at rest. A value the product gives the button wins over it (see `.loading(_:)`).
        .accessibilityValue(
            isLoading
                ? Text(
                    "Loading", bundle: .module,
                    comment: "A button's state while its action runs: its accessibility value, read after its label.")
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

    /// Whether the button is in a state of its contract, read where the system or westron's modifier keeps it, or
    /// forced by the catalog (`forcedButtonStates`). The switch is exhaustive over the generated `ButtonState`, so a
    /// state added to or renamed in the contract fails the build here until the style follows it (#20).
    private func isIn(_ state: ButtonState) -> Bool {
        guard state.isEntered else { return false }
        if forcedStates.contains(state) { return true }
        switch state {
        case .hover: return isHovered
        case .focus: return isFocused
        case .pressed: return configuration.isPressed
        case .disabled: return !isEnabled
        case .loading: return isLoading
        }
    }

    var body: some View {
        let states = Set(ButtonState.allCases.filter(isIn))
        let tokens = ButtonTokens(variant: variant, destructive: configuration.role == .destructive, states: states)
        let metrics = ButtonMetrics(ButtonSize.resolved(explicit: explicitSize, controlSize: controlSize))
        let scalesDown = ButtonTokens.scalesDown(states: states) && !reduceMotion

        ButtonSurface(
            label: configuration.label, tokens: tokens, metrics: metrics, iconOnly: iconOnly,
            isLoading: states.contains(.loading), isHovered: states.contains(.hover),
            isPressed: states.contains(.pressed)
        )
        .scaleEffect(scalesDown ? ButtonTokens.pressScale : 1)
        .animation(.press, value: scalesDown)
        #if !os(watchOS)
            .onHover { hovering in
                isHovered = hovering && ButtonState.hover.isEntered
            }
        #endif
        // A disabled view may receive no hover events, so a pointer that leaves while the button is disabled would
        // leave it hovered, and the tint would come back when it is enabled again with the pointer away.
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { isHovered = false }
        }
    }
}

/// The drawn button: its content, padding, frame, fill, border, hit area and opacity. The horizontal padding and the
/// icon–label gap scale with Dynamic Type from their tokens, relative to the label's text style.
private struct ButtonSurface<Label: View>: View {
    let label: Label
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let iconOnly: Bool
    let isLoading: Bool
    let isHovered: Bool
    let isPressed: Bool
    @ScaledMetric private var padding: CGFloat
    @ScaledMetric private var gap: CGFloat

    init(
        label: Label, tokens: ButtonTokens, metrics: ButtonMetrics, iconOnly: Bool, isLoading: Bool,
        isHovered: Bool, isPressed: Bool
    ) {
        self.label = label
        self.tokens = tokens
        self.metrics = metrics
        self.iconOnly = iconOnly
        self.isLoading = isLoading
        self.isHovered = isHovered
        self.isPressed = isPressed
        let textStyle = Font.TextStyle(metrics.labelFont.textStyle)
        _padding = ScaledMetric(wrappedValue: CGFloat(metrics.paddingHorizontal), relativeTo: textStyle)
        _gap = ScaledMetric(wrappedValue: CGFloat(metrics.gap), relativeTo: textStyle)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CGFloat(ButtonMetrics.radius), style: .continuous)

        ButtonContent(
            label: label, tokens: tokens, metrics: metrics, gap: gap, iconOnly: iconOnly, isLoading: isLoading
        )
        .padding(.horizontal, iconOnly ? 0 : padding)
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
            .animation(.fade, value: isHovered)
            .animation(.press, value: isPressed)
        }
        // The hit area (chapter 08: at least the platform's recommended target) is the system's, not grown by a content
        // shape, measured in CatalogUITests/ButtonBehaviorTests.swift (#23):
        // - iOS: the system's touch tolerance reaches about 16 pt past a 32 pt button, beyond the 44 pt target, and
        //   gives a tap between two buttons to the closer one. A content shape grown to the target gave every tap in
        //   the overlap to the later sibling, even one closer to the first, so westron adds none.
        // - watchOS: the only size, m, is drawn at the target.
        // - macOS: a click outside the frame misses, whatever the content shape: size s keeps its drawn 24 pt, below
        //   the recommended 28 (a contract gap).
        .contentShape(.accessibility, shape)
        #if os(macOS) || os(watchOS)
            // The system's focus ring follows the button's corners.
            .contentShape(.focusEffect, shape)
        #endif
        .opacity(tokens.opacity.map(Double.init) ?? 1)
    }
}

/// The label slot and the icon slot, and the progress indicator in loading.
///
/// The resting content is laid out once, invisible and hidden from accessibility, and decides the size; what is drawn
/// is an overlay at that size. So loading never changes the width when the label has an icon (P13): the indicator
/// takes the icon's place. A label without an icon is laid out by `ButtonLoadingLayout`.
private struct ButtonContent<Label: View>: View {
    let label: Label
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let gap: CGFloat
    let iconOnly: Bool
    let isLoading: Bool

    @Environment(\.buttonLoadingLayout) private var loadingLayout
    /// Whether the label has an icon slot, for the layouts that change the size by it; a frame late on appearing.
    @State private var hasIcon = true

    var body: some View {
        sizing
            .opacity(0)
            .accessibilityHidden(true)
            .overlayPreferenceValue(ButtonLabelHasIconKey.self) { hasIcon in
                visible(hasIcon: hasIcon)
            }
            .onPreferenceChange(ButtonLabelHasIconKey.self) { value in
                hasIcon = value
            }
    }

    /// What decides the size: the resting content, with the indicator's slot for the layouts that keep one.
    @ViewBuilder private var sizing: some View {
        switch loadingLayout {
        case .sharedWidth, .replacesLabel:
            styled(isLoading: false)
        case .grows, .reservedSlot:
            let slot = !hasIcon && (loadingLayout == .reservedSlot || isLoading)
            HStack(spacing: slot ? gap : 0) {
                if slot { progress }
                styled(isLoading: false)
            }
        }
    }

    @ViewBuilder private func visible(hasIcon: Bool) -> some View {
        if hasIcon || !isLoading {
            if !hasIcon && loadingLayout == .reservedSlot {
                HStack(spacing: gap) {
                    progress.hidden()
                    styled(isLoading: false)
                }
            } else {
                styled(isLoading: isLoading)
            }
        } else {
            // A label without an icon, loading: what is drawn may truncate or hide the label, so it is hidden from
            // accessibility, and the button takes its name, whole, from the system's icon-only label, which carries
            // its title with no text of its own on screen.
            loadingWithoutIcon
                .accessibilityHidden(true)
                .background {
                    SwiftUI.Label {
                        styled(isLoading: true)
                    } icon: {
                        EmptyView()
                    }
                    .labelStyle(.iconOnly)
                    // At its own size: laid out in what is drawn, the title it carries would read as clipped.
                    .fixedSize()
                }
        }
    }

    @ViewBuilder private var loadingWithoutIcon: some View {
        switch loadingLayout {
        case .sharedWidth:
            // The indicator, the gap and the label share the resting width; the label truncates on one line, or
            // gives its place up whole when less than two thirds of it would show.
            ButtonSharedWidthLayout(gap: gap) {
                progress
                styled(isLoading: true).lineLimit(1)
            }
        case .grows, .reservedSlot:
            HStack(spacing: gap) {
                progress
                styled(isLoading: true)
            }
        case .replacesLabel:
            // The indicator takes the label's place, centered.
            styled(isLoading: true)
                .hidden()
                .overlay { progress }
        }
    }

    private var progress: some View {
        ButtonProgress(color: tokens.progress)
    }

    private func styled(isLoading: Bool) -> some View {
        label
            .labelStyle(
                ButtonLabelStyle(tokens: tokens, metrics: metrics, gap: gap, iconOnly: iconOnly, isLoading: isLoading)
            )
            .textRole(metrics.labelFont)
            .foregroundStyle(tokens.label)
            .multilineTextAlignment(.center)
    }
}

/// Lays out the indicator and the label in the width the button has at rest: the indicator at its size, the gap, and
/// the label in what is left. A label that cannot show even an ellipsis there is not drawn at all.
private struct ButtonSharedWidthLayout: Layout {
    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + gap
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: width, height: proposal.height ?? height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let indicator = subviews[0].sizeThatFits(.unspecified)
        let left = max(0, bounds.width - indicator.width - gap)
        let title = subviews[1]
        // The title on one line in what is left, truncated with an ellipsis, or not at all when less than two thirds of
        // it would show: narrower than its first glyph and an ellipsis, SwiftUI draws clipped glyphs ("Sa" for "Save")
        // instead of truncating, and a lone ellipsis says nothing.
        let ideal = title.sizeThatFits(.unspecified).width
        let fitted = title.sizeThatFits(ProposedViewSize(width: left, height: bounds.height))
        let showsTitle = left * 3 >= ideal * 2 && fitted.width > 0  // westron-lint: allow a ratio, not a length
        let titleSize = showsTitle ? fitted : .zero
        let total = indicator.width + (showsTitle ? gap + titleSize.width : 0)
        var x = bounds.midX - total / 2
        subviews[0].place(
            at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(indicator))
        x += indicator.width + gap
        // Proposed the width it was measured at, not its fitted width, which can lay a tracked text out differently.
        title.place(
            at: CGPoint(x: x, y: bounds.midY), anchor: .leading,
            proposal: showsTitle ? ProposedViewSize(width: left, height: bounds.height) : .zero)
    }
}

/// Whether the button's label is a `Label`, which has an icon slot: its label style sets it.
private struct ButtonLabelHasIconKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

/// Lays out a `Label` in the button: the icon before the title with the size's gap, the icon decorative; in icon-only,
/// the icon alone, hidden from accessibility, with the title as the button's label; in loading, the indicator in the
/// icon's place.
private struct ButtonLabelStyle: LabelStyle {
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let gap: CGFloat
    let iconOnly: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if iconOnly {
                // The system's icon-only style keeps the title as the button's label, with no text of its own to clip
                // at large text sizes. The glyph's own traits would leak into the button's (the checkmark symbol
                // reads as "Selected"), so they are taken away.
                SwiftUI.Label {
                    configuration.title
                } icon: {
                    icon(configuration)
                }
                .labelStyle(.iconOnly)
                .accessibilityRemoveTraits([.isSelected, .isImage])
            } else {
                HStack(spacing: gap) {
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
                    ButtonProgress(color: tokens.progress)
                }
            }
    }
}

/// The system's spinning progress indicator, at its small control size, in the label's color. It is decorative: the
/// button announces loading as its value.
///
/// macOS draws its spinner in its own gray and ignores `tint`, so the label's color is painted through the spinner's
/// shape, the same way on every platform. The spinner's spokes are translucent, its leading spoke about half opaque, so
/// the shape is stacked on itself with three shadows that do not blur: each one doubles the cover, and the leading
/// spoke reaches about 94 % of the label's color while the trailing spokes keep their fade.
private struct ButtonProgress: View {
    let color: Westron.Color

    var body: some View {
        spinner
            .opacity(0)
            .overlay {
                Color(color).mask {
                    spinner
                        .shadow(color: Color(color), radius: 0)
                        .shadow(color: Color(color), radius: 0)
                        .shadow(color: Color(color), radius: 0)
                }
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
