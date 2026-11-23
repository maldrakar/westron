// Hand-written. Button's look and behavior from its contract, spec/components/button/button.spec.yaml, on SwiftUI's own
// Button (decisions/0001, 0003). The generated `buttonStyle(_:size:iconOnly:floating:)` (Generated/Button+Contract.swift)
// applies it; the tokens it draws come from ButtonTokens.swift.
//
// A floating secondary stands on the system's glass from OS 26, `glassEffect(.regular.interactive(), in: Capsule())`,
// with no fill, outline, shadow or press scale of westron's on it; before OS 26 on its opaque raised surface. A floating
// primary keeps its fill and casts `shadow.overlay` on every OS (decisions/0015 at the repository's root).
//
// It is a `PrimitiveButtonStyle`, not a `ButtonStyle`, because only a primitive style decides whether an activation
// runs the action: loading refuses presses (the contract), and a `ButtonStyle` cannot. Its body is a system `Button`
// whose action calls `configuration.trigger()` unless the button is loading. Inside, a `ButtonStyle` draws it, since
// only a `ButtonStyle` sees `isPressed`.
//
// The gate refuses a touch and a click. SwiftUI runs the product's action for two other inputs itself, on the product's
// `Button`, around its style: an accessibility activation (VoiceOver, Switch Control, Voice Control) and a keyboard
// shortcut. `.loading(_:)` refuses both from outside the button (States.swift): the shortcut only when it is set
// outside `.loading(_:)`. The catalog's UI tests measure each (CatalogUITests/ButtonBehaviorTests), and
// ButtonShortcutTests the shortcut's two orders.

import SwiftUI

/// westron's Button style, which the generated `buttonStyle(_:size:iconOnly:floating:)` applies (decisions/0001, 0003,
/// 0015).
struct ButtonVariantStyle: PrimitiveButtonStyle {
    let variant: ButtonVariant
    /// nil: the size comes from `controlSize`.
    let size: ButtonSize?
    let iconOnly: Bool
    /// Over content (the contract's `floating`); tertiary does not take it (`ButtonTokens.floats(_:floating:)`).
    var floating = false

    func makeBody(configuration: Configuration) -> some View {
        ButtonGate(
            configuration: configuration, variant: variant, explicitSize: size, iconOnly: iconOnly, floating: floating)
    }
}

/// The system button that refuses activation while loading, and announces loading.
private struct ButtonGate: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool
    let floating: Bool

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
        .buttonStyle(ButtonLook(variant: variant, explicitSize: explicitSize, iconOnly: iconOnly, floating: floating))
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
    let floating: Bool

    func makeBody(configuration: Configuration) -> some View {
        ButtonBody(
            configuration: configuration, variant: variant, explicitSize: explicitSize, iconOnly: iconOnly,
            floating: floating)
    }
}

private struct ButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: ButtonVariant
    let explicitSize: ButtonSize?
    let iconOnly: Bool
    let floating: Bool

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isLoading) private var isLoading
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.forcedButtonStates) private var forcedStates
    @Environment(\.drawsButtonsWithoutGlass) private var drawsWithoutGlass
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
        let onGlass = ButtonTokens.standsOnGlass(
            variant, floating: floating, glassAvailable: ButtonGlass.isAvailable && !drawsWithoutGlass)
        let tokens = ButtonTokens(
            variant: variant, destructive: configuration.role == .destructive, states: states,
            highContrast: contrast == .increased, floating: floating)
        let metrics = ButtonMetrics(ButtonSize.resolved(explicit: explicitSize, controlSize: controlSize))
        // On glass the press is the glass's own response, not westron's scale (decisions/0015).
        let scalesDown = ButtonTokens.scalesDown(states: states) && !reduceMotion && !onGlass

        ButtonSurface(
            label: configuration.label, tokens: onGlass ? tokens.onGlass() : tokens, metrics: metrics,
            iconOnly: iconOnly, isLoading: states.contains(.loading), isHovered: states.contains(.hover),
            isPressed: states.contains(.pressed),
            // The glass answers a touch or a pointer only while the button takes presses.
            glass: onGlass ? ButtonGlass(isInteractive: states.isDisjoint(with: [.disabled, .loading])) : nil
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
/// icon–label gap scale with Dynamic Type from their tokens, relative to the label's text style. The shape is the
/// platform's capsule (`container.shape`), SwiftUI's `Capsule` with its default continuous ends, as the prototype the
/// owner chose drew it; icon-only, laid out in a square, is a circle.
private struct ButtonSurface<Label: View>: View {
    let label: Label
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let iconOnly: Bool
    let isLoading: Bool
    let isHovered: Bool
    let isPressed: Bool
    /// The system's glass under the button; nil: none.
    let glass: ButtonGlass?
    @ScaledMetric private var padding: CGFloat
    @ScaledMetric private var gap: CGFloat

    init(
        label: Label, tokens: ButtonTokens, metrics: ButtonMetrics, iconOnly: Bool, isLoading: Bool,
        isHovered: Bool, isPressed: Bool, glass: ButtonGlass?
    ) {
        self.label = label
        self.tokens = tokens
        self.metrics = metrics
        self.iconOnly = iconOnly
        self.isLoading = isLoading
        self.isHovered = isHovered
        self.isPressed = isPressed
        self.glass = glass
        let textStyle = Font.TextStyle(metrics.labelFont.textStyle)
        _padding = ScaledMetric(wrappedValue: CGFloat(metrics.paddingHorizontal), relativeTo: textStyle)
        _gap = ScaledMetric(wrappedValue: CGFloat(metrics.gap), relativeTo: textStyle)
    }

    var body: some View {
        let shape = Capsule()

        ButtonContent(
            label: label, tokens: tokens, metrics: metrics, gap: gap, iconOnly: iconOnly, isLoading: isLoading
        )
        .padding(.horizontal, iconOnly ? 0 : padding)
        .modifier(ButtonFrame(minSide: CGFloat(metrics.height), isSquare: iconOnly))
        .background {
            ZStack {
                if let background = tokens.background {
                    // A floating button's shadow follows its shape, not its glyphs.
                    if let shadow = tokens.shadow {
                        shape.fill(background).shadow(shadow)
                    } else {
                        shape.fill(background)
                    }
                }
                if let borderColor = tokens.borderColor, let borderWidth = tokens.borderWidth {
                    shape.strokeBorder(borderColor, lineWidth: CGFloat(borderWidth))
                }
            }
            .animation(.fade, value: isHovered)
            .animation(.press, value: isPressed)
        }
        // After what draws the button, as Apple asks of the glass.
        .modifier(ButtonGlassEffect(glass: glass, shape: shape))
        // The hit area (chapter 08: at least the platform's recommended target, except where the contract's platform
        // block says otherwise) is never grown past what is drawn, measured in CatalogUITests/ButtonBehaviorTests.swift
        // (#23) and, on macOS, ButtonHitAreaTests:
        // - iOS: the system's touch tolerance reached about 16 pt past a 32 pt button (#23), and 16 to 19 pt past
        //   one of size s or m on iOS 26.3 and 27.0 alike (#102), beyond the 44 pt of size.target.minimum; the
        //   catalog's test taps 8 pt past a 28 pt one, the target's edge, with no other control near. It gives a tap
        //   between two buttons to the closer one, so a control closer than about 16 pt takes part of the button's
        //   tolerance (the contract's `platforms.apple.ios`, the owner's decision of 2026-11-21). A content shape grown to the target gave every tap in the
        //   overlap to the later sibling, even one closer to the first, so westron adds none. A tap inside an unfilled
        //   button, off its label, reaches it without one.
        // - watchOS: the only size, m, is drawn at the target.
        // - macOS: the hit area is the drawn button, as the contract's `platforms.apple.macos` records (the owner's
        //   decision of 2026-11-18, #75), so size s takes clicks in its 24 pt, below the recommended 28. Without a
        //   content shape the system takes clicks only where the button paints: on tertiary its label (#75). The
        //   interaction shape is the drawn capsule, so every click inside what is drawn reaches the button and none
        //   outside does; hover, too, starts and ends at the drawn edge. A click
        //   outside the frame misses whatever the content shape, and growing the frame does reach the target: padding
        //   the look by 2 pt inside the system button and taking it back outside with a negative padding kept the
        //   drawn and laid out size, and a click 1.5 pt below the drawn button reached it. But the grown frame
        //   overlaps a neighbor closer than 4 pt, and the later sibling wins there, inside the neighbor's drawn area:
        //   with `spacing: 0`, a click 1 pt inside the first button ran the second (measured in the review of #23 with
        //   NSEvent clicks in a window, in an HStack of icon-only buttons and a VStack of buttons with labels). The
        //   style cannot see its neighbors, so westron does not grow the frame.
        #if os(macOS)
            .contentShape(.interaction, shape)
        #endif
        .contentShape(.accessibility, shape)
        #if os(macOS) || os(watchOS)
            // The system's focus ring follows the button's capsule.
            .contentShape(.focusEffect, shape)
        #endif
        .opacity(tokens.opacity.map(Double.init) ?? 1)
    }
}

/// The system's glass under a floating secondary button (decisions/0015): regular, interactive while the button takes
/// presses, with nothing of westron's on it.
struct ButtonGlass: Equatable {
    let isInteractive: Bool

    /// Whether the OS draws glass: iOS, macOS and watchOS 26 and later.
    static var isAvailable: Bool {
        if #available(iOS 26, macOS 26, watchOS 26, *) { true } else { false }
    }
}

/// Lays the system's glass under the content in `shape`, where there is a `glass` and the OS has it.
private struct ButtonGlassEffect<GlassShape: Shape>: ViewModifier {
    let glass: ButtonGlass?
    let shape: GlassShape

    func body(content: Content) -> some View {
        if let glass {
            if #available(iOS 26, macOS 26, watchOS 26, *) {
                content.glassEffect(.regular.interactive(glass.isInteractive), in: shape)
            } else {
                content
            }
        } else {
            content
        }
    }
}

/// The label slot and the icon slot, and the progress indicator in loading (contract, P13). With an icon, the indicator
/// takes the icon's place (`ButtonLabelStyle`), so the width holds; without one, it goes before the label and the
/// button widens by the indicator and the gap (`IndicatorBeforeLabelLayout`). Which of the two follows the label in the
/// same update, with no state copied from it: a label that changes between `Text` and `Label` while loading, and a
/// renderer that draws a single update (`ImageRenderer`), never show two indicators or none (ButtonLabelKindTests).
/// The label is drawn as it is in every state, whole, with its own colors.
private struct ButtonContent<Label: View>: View {
    let label: Label
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let gap: CGFloat
    let iconOnly: Bool
    let isLoading: Bool

    var body: some View {
        IndicatorBeforeLabelLayout(gap: gap) {
            if isLoading {
                indicatorWithoutIcon
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            }
            styled(isLoading: isLoading)
        }
    }

    /// The indicator before a label without an icon. It takes an icon's slot, as it does beside an icon: a glyph in
    /// `icon.font` at the icon's scale, not drawn, sizes the slot, and the indicator fits it (`ButtonProgress`).
    private var indicatorWithoutIcon: some View {
        Image(Westron.Icon.checkCircle)
            .textRole(metrics.iconFont)
            .imageScale(ButtonMetrics.iconScale)
            .hidden()
            .accessibilityHidden(true)
            .overlay { ButtonProgress(color: tokens.progress) }
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

/// Marks a label that `ButtonLabelStyle` lays out, a `Label`, which has an icon slot: the style gives this guide an
/// explicit value, which no other view does. An explicit alignment reaches the layouts around the view that sets it in
/// the same update, through the label's own stacks, so `IndicatorBeforeLabelLayout` knows in the same update whether
/// the label it lays out has an icon, also when the label changes between `Text` and `Label` (#23).
private enum ButtonLabelHasIcon: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context[VerticalAlignment.center] }
}

extension VerticalAlignment {
    fileprivate static let buttonLabelHasIcon = VerticalAlignment(ButtonLabelHasIcon.self)
}

/// Lays out the label, and in loading the indicator before it when the label has no icon (the label has no explicit
/// `buttonLabelHasIcon`): the indicator at its own size, then the gap, then the label, centered vertically, as an
/// `HStack` would. Its subviews are the label, or, in loading, the indicator and the label. With an icon, the
/// indicator is in the icon's place already, and the one before the label is proposed no room: its frame is empty and
/// clips it.
private struct IndicatorBeforeLabelLayout: Layout {
    let gap: CGFloat

    /// The size of the indicator before the label, nil when it takes no room.
    private func indicatorSize(_ proposal: ProposedViewSize, _ subviews: Subviews) -> CGSize? {
        guard subviews.count == 2, subviews[1].dimensions(in: proposal)[explicit: .buttonLabelHasIcon] == nil else {
            return nil
        }
        return subviews[0].sizeThatFits(.unspecified)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let label = subviews.last else { return .zero }
        guard let indicator = indicatorSize(proposal, subviews) else { return label.sizeThatFits(proposal) }
        let labelSize = label.sizeThatFits(
            ProposedViewSize(
                width: proposal.width.map { max(0, $0 - indicator.width - gap) }, height: proposal.height))
        return CGSize(width: indicator.width + gap + labelSize.width, height: max(indicator.height, labelSize.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let label = subviews.last else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        guard let indicator = indicatorSize(proposal, subviews) else {
            if subviews.count == 2 { subviews[0].place(at: center, anchor: .center, proposal: .zero) }
            label.place(at: center, anchor: .center, proposal: ProposedViewSize(bounds.size))
            return
        }
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(indicator))
        label.place(
            at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing,
            proposal: ProposedViewSize(width: max(0, bounds.width - indicator.width - gap), height: bounds.height))
    }
}

/// The button's accessible name where its title is not drawn as text: the system's icon-only label style carries the
/// title as a label with nothing drawn, an empty icon, at the title's own size (laid out in a smaller frame, the title
/// it carries would read as clipped to the accessibility audit).
private struct ButtonName<Title: View>: View {
    let title: Title

    var body: some View {
        SwiftUI.Label {
            title
        } icon: {
            EmptyView()
        }
        .labelStyle(.iconOnly)
        .fixedSize()
    }
}

/// Lays out a `Label` in the button: the icon before the title with the size's gap, the icon decorative; in icon-only,
/// the icon alone, hidden from accessibility, with the title as the button's name (`ButtonName`); in loading, the
/// indicator in the icon's place.
private struct ButtonLabelStyle: LabelStyle {
    let tokens: ButtonTokens
    let metrics: ButtonMetrics
    let gap: CGFloat
    let iconOnly: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if iconOnly {
                // The glyph is hidden from accessibility, or its own traits would leak into the button's (the
                // checkmark reads as "Selected"); the button takes its name from `ButtonName`.
                icon(configuration)
                    .accessibilityHidden(true)
                    .background { ButtonName(title: configuration.title) }
            } else {
                // The icon sits on the label's first text baseline, not centered on it (the contract's description):
                // a symbol's baseline is its glyph's, so it lines up with the words as a letter would.
                HStack(alignment: .firstTextBaseline, spacing: gap) {
                    icon(configuration)
                        .accessibilityHidden(true)
                    configuration.title
                        .textRole(metrics.labelFont)
                        .foregroundStyle(tokens.label)
                }
            }
        }
        .alignmentGuide(.buttonLabelHasIcon) { $0[VerticalAlignment.center] }
    }

    /// The icon in its text role, at the symbol's small scale, and in its color, or, in loading, the indicator over its
    /// place.
    private func icon(_ configuration: Configuration) -> some View {
        configuration.icon
            .textRole(metrics.iconFont)
            .imageScale(ButtonMetrics.iconScale)
            .foregroundStyle(tokens.icon)
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    ButtonProgress(color: tokens.progress)
                }
            }
    }
}

/// The system's spinning progress indicator in `progress.color`, fitted to the icon's slot. It is decorative: the
/// button announces loading as its value.
///
/// It is drawn in the icon's slot, which it must fit (`ButtonProgressTests`): it fills what it is offered and draws the
/// spinner scaled down to fit it. The system draws its spinner at fixed sizes whatever the frame around it: on macOS
/// 16 pt at the small control size and 10 pt at mini, on iOS 14 pt at small. The icon at the symbol's small scale is
/// smaller than any of them at size s, 9 pt on macOS (#85), so the spinner is drawn at the smaller size the platform
/// has, mini on macOS (#23) and small elsewhere, and scaled down where it is still larger than the slot.
///
/// macOS draws its spinner in its own gray and ignores `tint`, so the color is laid over the spinner's shape with
/// `sourceAtop`, inside a compositing group, the same way on every platform. The spinner's spokes are translucent,
/// its leading spoke about half opaque, so its shape is first stacked on itself with three shadows that do not blur:
/// each one doubles the cover, and the leading spoke reaches about 94 % of the color while the trailing spokes keep
/// their fade. One spinner, no mask: a mask over an animating view costs an offscreen pass on every frame.
struct ButtonProgress: View {
    let color: Westron.Color
    /// Reports where the spinner is drawn, its scale included, in the slot's coordinates: ButtonProgressTests reads
    /// it, since the indicator's own frame is the slot whatever it draws.
    var drawn: (@MainActor (CGRect) -> Void)? = nil
    /// The spinner's own size, measured before it is scaled.
    @State private var natural: CGSize?

    var body: some View {
        GeometryReader { proxy in
            spinner
                .fixedSize()
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: {
                    natural = $0
                }
                // Inside the scale, so the frame is the drawn one.
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .named(ButtonProgress.slotSpace))
                } action: { frame in
                    drawn?(frame)
                }
                .scaleEffect(natural.map { Self.fittingScale(natural: $0, slot: proxy.size) } ?? 1)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .coordinateSpace(.named(ButtonProgress.slotSpace))
    }

    /// The slot's coordinate space, for `drawn`.
    static let slotSpace = "ButtonProgress.slot"

    /// The control size the spinner is drawn at: the smaller of the two the platform draws.
    static var controlSize: ControlSize {
        #if os(macOS)
            .mini
        #else
            .small
        #endif
    }

    /// How much a spinner of `natural` size is scaled to fit `slot`: never up, down as far as both sides fit.
    static func fittingScale(natural: CGSize, slot: CGSize) -> CGFloat {
        guard natural.width > 0, natural.height > 0 else { return 1 }
        return min(1, slot.width / natural.width, slot.height / natural.height)
    }

    var spinner: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(Self.controlSize)
            .shadow(color: Color(color), radius: 0)
            .shadow(color: Color(color), radius: 0)
            .shadow(color: Color(color), radius: 0)
            .overlay {
                Color(color).blendMode(.sourceAtop)
            }
            .compositingGroup()
            .accessibilityHidden(true)
    }
}

/// A frame whose height is at least `minSide` and grows with the content; with `isSquare`, also as wide as it is
/// tall, so icon-only stays a circle when its glyph grows with Dynamic Type.
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
