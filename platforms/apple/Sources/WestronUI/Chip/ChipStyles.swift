// Hand-written. Chip's look and behavior from its contract, spec/components/chip/chip.spec.yaml, in its three forms,
// each a style on its own system control (decisions/0001, 0003; the contract's decisions/0001, Q1): the generated
// `toggleStyle(_:)`, `buttonStyle(_:)` and `labelStyle(_:)` (Generated/Chip+Contract.swift) apply `ChipToggleStyle`,
// `ChipButtonStyle` and `ChipLabelStyle`; the tokens they draw come from ChipTokens.swift, and one view, `ChipSurface`,
// draws all three.
//
// Selectable: `ToggleStyleConfiguration` has no `isPressed`, so the style follows the press as Checkbox's does: its body
// is a system `Button` that toggles the value, drawn by a `ButtonStyle`. For assistive technology the button is
// replaced by the system's own Toggle on the same value (`accessibilityRepresentation`), as Checkbox's is, so VoiceOver
// meets the toggle's role, its traits and its on or off value, never a button (the contract's decisions/0001, revision
// B, measured in CatalogUITests/ChipBehaviorTests). Pressable: a `ButtonStyle` on the product's own Button. Static: a
// `LabelStyle`, which, as the system's label styles do, reaches every Label below the modifier.
//
// A checked chip shows the registry's check glyph (the contract's description; decisions/0001, revision A): in the
// icon's place when its label is a `Label`, the icon hidden, so the width holds; before the label, with the gap, when
// the label is only text, so the chip grows by them (`ChipMarkBeforeLabelLayout`).

import SwiftUI

/// westron's Chip style in its selectable form, which the generated `toggleStyle(_:)` applies.
struct ChipToggleStyle: ToggleStyle {
    let variant: ChipVariant

    func makeBody(configuration: Configuration) -> some View {
        ChipToggleBody(configuration: configuration, variant: variant)
    }
}

/// The system button that toggles the value, and the system toggle that assistive technology meets in its place.
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
        .accessibilityRepresentation {
            // The system's own style, not westron's, which the environment still holds here: the toggle keeps its role,
            // its traits and its value, on or off, with no `.isSelected`, which would say the state twice
            // (design-language/08, "A system control keeps its own role and traits").
            Toggle(isOn: isOn) {
                configuration.label
            }
            .toggleStyle(.automatic)
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
    @Environment(\.chipHoverObserver) private var hoverObserver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @ScaledMetric(relativeTo: Font.TextStyle(ChipMetrics.labelFont.textStyle)) private var gap = CGFloat(
        ChipMetrics.gap)

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
        let marked = ChipTokens.effective(states).contains(.checked)
        let motion = ChipMotion(reduceMotion: reduceMotion)
        ChipSurface(
            variant: variant, states: states, hitSide: ChipMetrics.minimumHitSide,
            onHover: { hovering in isHovered = hovering && ChipState.hover.isEntered }
        ) {
            ChipMarkBeforeLabelLayout(gap: gap, showsMark: marked) {
                // The check before a label that is only text; a `Label` draws it in its icon's place instead
                // (`ChipContent`), and the layout gives this one no room. Proposed no room, the frame is empty and
                // clips it.
                ChipMark()
                    .opacity(marked ? 1 : 0)
                    .animation(motion.check, value: marked)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    // Its place and size move with the layout, in `motion.resize`; its opacity fades, in `motion.check`.
                    .geometryGroup()
                // The text role and the one line around the whole label, as Button's style does: a label that is only
                // text, `Toggle("Work", isOn:)` or `Button("Tue")`, never reaches a label style, and would otherwise be
                // drawn in the system's body font and wrap. A `Label` gets the same from `ChipContent`.
                label
                    .labelStyle(ChipContentStyle())
                    .textRole(ChipMetrics.labelFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    // The words' color and a `Label`'s check fade, in `motion.check`; the label's place moves with the
                    // layout, in `motion.resize`.
                    .animation(motion.check, value: marked)
                    .geometryGroup()
            }
            .environment(\.chipMarked, marked)
        }
        // A disabled view may receive no hover events, so a pointer that leaves while the chip is disabled would leave
        // it hovered, and the tint would come back when it is enabled again with the pointer away.
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { isHovered = false }
        }
        // The catalog's readout of hover (`onChipHover`); nil in a product.
        .onChange(of: isHovered) { _, hovered in
            hoverObserver?(hovered)
        }
    }
}

/// westron's Chip style in its static form, which the generated `labelStyle(_:)` applies: a value shown and not acted
/// on. It enters no state, lays out no hit area and adds no role: its title is read as text (the contract's `forms`).
/// Under `.disabled(true)` it is drawn as it is, undimmed, since the form enters no state (the contract's description).
struct ChipLabelStyle: LabelStyle {
    let variant: ChipVariant

    func makeBody(configuration: Configuration) -> some View {
        ChipSurface(variant: variant, states: [], hitSide: nil, onHover: nil) {
            ChipContent(icon: configuration.icon, title: configuration.title)
        }
    }
}

/// Lays out a `Label` in a selectable or pressable chip as the static form does. A label that is only text never
/// reaches it: `ChipControl` gives such a label the text role, the one line and the truncation around it. It marks the
/// label as one with an icon slot (`chipLabelHasIcon`), so that `ChipMarkBeforeLabelLayout` draws no check before it.
private struct ChipContentStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChipContent(icon: configuration.icon, title: configuration.title)
            .alignmentGuide(.chipLabelHasIcon) { $0[VerticalAlignment.center] }
    }
}

/// The icon slot and the label slot: the icon decorative, on the label's first baseline, at the symbol's small scale in
/// `icon.font`; the label one line, truncated at its end, in `label.font`. While the chip is checked, the check is drawn
/// in the icon's place and the icon hidden, so the width holds. The colors come from `ChipSurface`, which sets the
/// label's as the foreground style and the icon's in `chipIconColor`.
private struct ChipContent<Icon: View, Title: View>: View {
    let icon: Icon
    let title: Title

    @Environment(\.chipIconColor) private var iconColor
    @Environment(\.chipMarked) private var marked
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
                .opacity(marked ? 0 : 1)
                .overlay {
                    ChipMark()
                        .opacity(marked ? 1 : 0)
                }
                .modifier(ChipDecorative())
            title
                .textRole(ChipMetrics.labelFont)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

/// The check a checked chip shows: the registry's `check` glyph, drawn as the icon is, in `icon.font` at the symbol's
/// small scale, in the icon's color, which is the words' color on a lit fill. It is decorative: the toggle announces
/// its value.
private struct ChipMark: View {
    @Environment(\.chipIconColor) private var iconColor

    var body: some View {
        Image(Westron.Icon.check)
            .textRole(ChipMetrics.iconFont)
            .imageScale(ChipMetrics.iconScale)
            .foregroundStyle(iconColor.map { AnyShapeStyle(Color($0)) } ?? AnyShapeStyle(.foreground))
            .fixedSize()
            .modifier(ChipDecorative())
    }
}

/// Hides a decorative glyph, the icon or the check, from assistive technology. Inside a button's label on iOS,
/// `.accessibilityHidden(true)` alone left each glyph an image element of its own under the button, named after its
/// symbol, the check with the trait selected, as under a westron Button with a Label (iOS 26.3, ChipBehaviorTests);
/// so the glyph also gives an empty representation, as IconTile's symbol does (#118). XCUITest then lists it as an
/// element of type other with no label, value or trait; `.accessibilityElement(children: .combine)` around the label
/// did not remove it either.
private struct ChipDecorative: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accessibilityRepresentation {
                EmptyView()
            }
            .accessibilityHidden(true)
    }
}

extension EnvironmentValues {
    /// The icon's color inside a chip, which `ChipSurface` sets for `ChipContent`; nil outside a chip.
    @Entry fileprivate var chipIconColor: Westron.Color? = nil
    /// Whether the chip around shows the check (`ChipTokens.mark`), which `ChipControl` sets for `ChipContent`.
    @Entry fileprivate var chipMarked: Bool = false
}

/// Marks a label that `ChipContentStyle` lays out, a `Label`, which has an icon slot: the style gives this guide an
/// explicit value, which no other view does. An explicit alignment reaches the layouts around the view that sets it in
/// the same update, so `ChipMarkBeforeLabelLayout` knows in the same update whether the label it lays out has an icon,
/// as Button's `IndicatorBeforeLabelLayout` does.
private enum ChipLabelHasIcon: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context[VerticalAlignment.center] }
}

extension VerticalAlignment {
    fileprivate static let chipLabelHasIcon = VerticalAlignment(ChipLabelHasIcon.self)
}

/// Lays out the label, and while the chip shows the check (`showsMark`) and the label has no icon (no explicit
/// `chipLabelHasIcon`), the check before it: the check at its own size, then the gap, then the label, the check on the
/// label's first text baseline, as a `Label`'s icon is. Its subviews are the check and the label. Otherwise the check is
/// proposed no room, its frame is empty and clips it, and the label takes the whole width.
private struct ChipMarkBeforeLabelLayout: Layout {
    let gap: CGFloat
    let showsMark: Bool

    /// The size of the check before the label, nil when it takes no room.
    private func markSize(_ proposal: ProposedViewSize, _ subviews: Subviews) -> CGSize? {
        guard showsMark, subviews.count == 2,
            subviews[1].dimensions(in: proposal)[explicit: .chipLabelHasIcon] == nil
        else { return nil }
        return subviews[0].sizeThatFits(.unspecified)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let label = subviews.last else { return .zero }
        guard let mark = markSize(proposal, subviews) else { return label.sizeThatFits(proposal) }
        let labelSize = label.sizeThatFits(labelProposal(proposal, mark: mark))
        return CGSize(width: mark.width + gap + labelSize.width, height: max(mark.height, labelSize.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let label = subviews.last else { return }
        guard let mark = markSize(proposal, subviews) else {
            if subviews.count == 2 {
                subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: .zero)
            }
            label.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: ProposedViewSize(bounds.size))
            return
        }
        let labelProposal = ProposedViewSize(width: max(0, bounds.width - mark.width - gap), height: bounds.height)
        let labelSize = label.dimensions(in: labelProposal)
        label.place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing, proposal: labelProposal)
        // The check's first baseline on the label's, as `ChipContent` aligns a `Label`'s icon.
        let markSize = subviews[0].dimensions(in: ProposedViewSize(mark))
        let baseline = bounds.midY - labelSize.height / 2 + labelSize[.firstTextBaseline]
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: baseline - markSize[.firstTextBaseline]), anchor: .topLeading,
            proposal: ProposedViewSize(mark))
    }

    /// What the label is offered beside the check and the gap.
    private func labelProposal(_ proposal: ProposedViewSize, mark: CGSize) -> ProposedViewSize {
        ProposedViewSize(width: proposal.width.map { max(0, $0 - mark.width - gap) }, height: proposal.height)
    }
}

/// The drawn chip around its content: the padding, the height, the capsule's fill and its high-contrast outline, the
/// opacity, the press's scale, and, for a control, the laid-out hit area around it. The padding and the gap scale with
/// Dynamic Type from their tokens, relative to the label's text style. The shape is the platform's capsule
/// (`container.shape`), SwiftUI's `Capsule`.
private struct ChipSurface<Content: View>: View {
    let variant: ChipVariant
    let states: Set<ChipState>
    /// The least height and width of the hit area; nil: the static form, which takes none.
    let hitSide: CGFloat?
    /// Called as the pointer enters and leaves the drawn capsule; nil: the static form, which tracks no hover.
    let onHover: ((Bool) -> Void)?
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
        let effective = ChipTokens.effective(states)
        let tokens = ChipTokens(category: category, states: states, highContrast: contrast == .increased)
        let motion = ChipMotion(reduceMotion: reduceMotion)
        let scalesDown = ChipTokens.scalesDown(states: states)
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
                // The tint of a press in `motion.press`, as Button's; of the pointer and of checking in `motion.fade`.
                .animation(motion.hover, value: effective.contains(.hover))
                .animation(motion.check, value: tokens.mark)
                .animation(motion.press, value: effective.contains(.pressed))
                // The capsule's size follows the content's, in the chip's transaction (`motion.resize`), not the tint's.
                .geometryGroup()
            }
            // Hover over the drawn capsule, in the drawn chip's frame, not over the hit area around it nor the corners
            // of the capsule's frame (`ShapeHover`); the click is still taken in the whole hit area (`ChipHitArea`).
            .modifier(ShapeHover(shape: shape, onHover: onHover))
            // The accessibility shape is the drawn capsule, not the hit area around it, as Button's is.
            .contentShape(.accessibility, shape)
            #if os(macOS) || os(watchOS)
                // The system's focus ring follows the drawn capsule, not the hit area around it.
                .contentShape(.focusEffect, shape)
            #endif
            .opacity(tokens.opacity.map(Double.init) ?? 1)
            .scaleEffect(motion.scale(pressed: scalesDown))
            .animation(motion.press, value: scalesDown)
            .modifier(ChipHitArea(minSide: hitSide))
            // The size of a text-only chip as the check comes in or goes: with the fill, or at once under Reduce Motion.
            .animation(motion.resize, value: tokens.mark)
    }
}

/// The hit area of a selectable or pressable chip: a frame at least `minSide` high and `minSide` across around the
/// drawn chip, which stays centred in it, laid out and not only hit-tested, so that it never takes a neighbor's touches
/// or clicks (decisions/0001, Q11 and revision C), every point of it taking the press. nil: no hit area, the static
/// form.
private struct ChipHitArea: ViewModifier {
    let minSide: CGFloat?

    func body(content: Content) -> some View {
        if let minSide {
            content
                .frame(minWidth: minSide, minHeight: minSide)
                .contentShape(Rectangle())
        } else {
            content
        }
    }
}
