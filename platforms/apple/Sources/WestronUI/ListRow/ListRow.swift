// Hand-written. westron's ListRow (spec/components/list-row/list-row.spec.yaml), an own view (decisions/0003, point 2):
// SwiftUI has no row outside a List. Its initializers follow the contract through spec/conventions.md, "Own
// components", and the API parity lint holds them to it; the enums, the states and the forms are generated
// (Generated/ListRow+Contract.swift).
//
// The pressable row is a system Button whose label is the whole drawn row, so the pointer, the keyboard, the press and
// .disabled(_:) are the system's, and a press anywhere on the row's frame is the row's action. The controls of its
// slots, a Checkbox at the start, are nested in that label and take their own press: the inner control's gesture wins
// (decisions/0001, "Revision of Q1 at implementation"). To assistive technology the Button would merge those controls
// into its own element, so the row is given there by `accessibilityRepresentation`: the same layout, the leading slot's
// elements as they are, the words, the title, the second line and the trailing slot, combined into one element with the
// button trait, and the Disclosure chevron's cell as its own element (decisions/0001, "Measured").

import SwiftUI

/// The core row of a list or a tree: a title, a second line under it, a leading slot and a trailing slot, at a
/// nesting level with guide lines, on a highlight that shows hover, pressed, selected and a drop onto it
/// (decisions/0014).
///
///     ListRow(level: 1, action: { open(list) }) {
///         Text(list.title)
///     } leading: {
///         Icon(.tray)
///     } trailing: {
///         Text(list.count)
///     }
///     .selected(list == chosen)
///
/// A row without an action, such as a subtask's, whose check is its only control:
///
///     ListRow(level: 2) {
///         Text(subtask.title)
///     } leading: {
///         Toggle(isOn: $subtask.isDone, accessibilityLabel: subtask.title).toggleStyle(.check)
///     }
///
/// The title is the content every row has; every other slot is optional. The title and the second line hold text and
/// decorative content, never a control: a row being renamed is replaced by the product's field for that time. A control
/// belongs at the start; the trailing slot holds words and glyphs, which join the row's spoken name. `.selected(_:)`,
/// `.chosen(_:)` and `.dropTarget(_:)` set the states the system lacks: selected is the open row, drawn with its look;
/// chosen the row that holds the current value of a choice, drawn as at rest, marked by the product's decorative check
/// and announced as selected. `.insertionMark(_:level:)` marks where a dragged row would land, and `.disabled(_:)` dims
/// the row. A title on one line (`lineLimit(1)`) belongs below the accessibility text sizes
/// only, so that at those sizes it wraps. In a `List`, give the row `.listRowInsets(EdgeInsets())`,
/// `.listRowBackground(Color.clear)` and `.listRowSeparator(.hidden)`, and bind no `List` selection: the row draws its
/// own.
public struct ListRow: View {
    let level: Int
    let guides: Bool
    let action: (() -> Void)?
    let parts: ListRowParts

    /// A row with an action: a button to assistive technology, named by its words (the form `pressable`).
    ///
    /// - Parameters:
    ///   - level: The nesting level, 0 at the top of a tree; the row is indented by `container.indent` per level.
    ///   - guides: Whether a row at level 1 or deeper draws one guide per level above it; by default `true`.
    ///   - action: What a press on the row does: anywhere on its frame but on the control at its start.
    ///   - title: The row's first line, in `body.regular`, `body.strong` while selected, unless it sets its own role;
    ///     text and decorative content, no control.
    ///   - subtitle: The second line, in `footnote.regular` and `text.secondary`; text and decorative content, no
    ///     control.
    ///   - leading: An IconTile, an Icon or a Checkbox at the start, on the title's first line, in `body.regular`.
    ///   - trailing: Words and glyphs at the end, such as a count, in `body.regular` unless they set their own role;
    ///     under the text at the accessibility sizes.
    public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
        level: Int = 0, guides: Bool = true, action: @escaping () -> Void, @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle = { EmptyView() }, @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.level = max(0, level)
        self.guides = guides
        self.action = action
        parts = ListRowParts(title: title(), subtitle: subtitle(), leading: leading(), trailing: trailing())
    }

    /// A row without an action (the form `static`): it adds no role, and its words are read as text, in one element.
    /// The parameters are those of the row with an action.
    public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
        level: Int = 0, guides: Bool = true, @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle = { EmptyView() }, @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.level = max(0, level)
        self.guides = guides
        action = nil
        parts = ListRowParts(title: title(), subtitle: subtitle(), leading: leading(), trailing: trailing())
    }

    /// The form the initializer chose.
    var form: ListRowForm { action == nil ? .static : .pressable }

    public var body: some View {
        ListRowBody(level: level, guides: guides, action: action, parts: parts)
    }
}

/// The slots of a row, each nil where the product left it out.
struct ListRowParts {
    let title: AnyView
    let subtitle: AnyView?
    let leading: AnyView?
    let trailing: AnyView?

    init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
        title: Title, subtitle: Subtitle, leading: Leading, trailing: Trailing
    ) {
        self.title = AnyView(title)
        self.subtitle = Subtitle.self == EmptyView.self ? nil : AnyView(subtitle)
        self.leading = Leading.self == EmptyView.self ? nil : AnyView(leading)
        self.trailing = Trailing.self == EmptyView.self ? nil : AnyView(trailing)
    }
}

// MARK: - The Disclosure chevron's cell

extension EnvironmentValues {
    /// The Disclosure chevron's cell, which westron's chevron style on a `DisclosureGroup` (#120) hands the row that is
    /// its label: the row draws it as the last item at its end, inside its highlight, and clears it for its own slots,
    /// so that a row inside a slot draws none. Package-internal: no product sets it (decisions/0001, "The Disclosure
    /// chevron's place").
    @Entry var listRowDisclosureCell: AnyView? = nil

    /// A leaf's empty chevron cell, which Disclosure's `.disclosureAlignsLeaves()` sets on a tree (#120, the contract's
    /// `context`): a row with no `listRowDisclosureCell` draws it in the same place, so that its trailing slot stands in
    /// its branches' column. The row clears it for its own slots. Package-internal: the product sets it only through
    /// Disclosure's modifier.
    @Entry var listRowLeafCell: AnyView? = nil

    /// What names the Disclosure chevron's cell for assistive technology when a row draws it: the row's title, which the
    /// row sets around the cell. Package-internal.
    @Entry var listRowDisclosureCellName: AnyView? = nil

    /// Told when the pressable row's system Button begins and ends a press: the catalog counts the presses, so that a
    /// UI test can see whether a press on a control in a slot also presses the row. Package-internal.
    @Entry var listRowPressObserver: (@MainActor @Sendable (Bool) -> Void)? = nil

    /// Whether a disabled ListRow around this view already draws it at `opacity.disabled`: a disabled row dims what it
    /// holds once, so a control in its slots, a Checkbox at its start, draws no opacity of its own for disabled while
    /// this is true, and a row inside it none either (the contract's disabled). The Disclosure chevron's cell is not
    /// dimmed by the row (`listRowOpacity`) and dims itself as its group's state says. Package-internal: only the row
    /// sets it.
    @Entry var listRowDimsContent: Bool = false

    /// The opacity the row's layout draws its parts at, the slots, the words and the guides, but not the Disclosure
    /// chevron's cell: `opacity.disabled` in a disabled row, else 1. Package-internal: only the row sets it.
    @Entry var listRowOpacity: Double = 1
}

// MARK: - The row

/// The row in its form: a system Button around the drawn row, or the drawn row alone; the states the system and the
/// environment report; and the representation assistive technology reads.
private struct ListRowBody: View {
    let level: Int
    let guides: Bool
    let action: (() -> Void)?
    let parts: ListRowParts

    @Environment(\.listRowDisclosureCell) private var disclosureCell
    @Environment(\.listRowLeafCell) private var leafCell
    @Environment(\.isSelected) private var isSelected
    @Environment(\.isChosen) private var isChosen
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        // A branch's chevron; otherwise, in a tree whose leaves line up, a leaf's empty cell.
        let cell = disclosureCell ?? leafCell
        let content = ListRowContent(level: level, guides: guides, parts: parts, cell: cell)
        // Announced as selected while selected or chosen, once when both; only selected is drawn (the highlight reads
        // `isSelected` alone), so chosen draws the row as at rest (decisions/0002).
        let announcedSelected = isSelected || isChosen
        // The representation lays the title out in the role the drawn row draws it in, strong while selected, so
        // that each element's frame is where its words are drawn.
        let titleFont = ListRowTokens(form: action == nil ? .static : .pressable, states: isSelected ? [.selected] : [])
            .titleFont
        Group {
            if let action {
                Button(action: action) {
                    content
                }
                .buttonStyle(ListRowPressStyle())
                .accessibilityRepresentation {
                    ListRowContent(
                        level: level, guides: false, parts: parts, cell: cell,
                        words: .button(action: isEnabled ? action : nil, selected: announcedSelected)
                    )
                    .environment(\.listRowTitleFont, titleFont)
                }
            } else {
                content
                    .modifier(ListRowHighlight(form: .static, isPressed: false, isHovered: false, isFocused: false))
                    .accessibilityRepresentation {
                        ListRowContent(
                            level: level, guides: false, parts: parts, cell: cell,
                            words: .text(selected: announcedSelected)
                        )
                        .environment(\.listRowTitleFont, titleFont)
                    }
            }
        }
        // The row takes every line its words need at the width it is given: neither line has a limit of the row's
        // own, so a stack that offers less height neither truncates nor squeezes it.
        .fixedSize(horizontal: false, vertical: true)
        // The cell is this row's: a row inside one of its slots draws none.
        .environment(\.listRowDisclosureCell, nil)
        .environment(\.listRowLeafCell, nil)
        // Tells the Disclosure style whose label this row is that the row drew its chevron, so that the style draws no
        // second one after the label.
        .preference(key: ListRowTookDisclosureCell.self, value: disclosureCell != nil)
        // And tells the style's header layout in the same pass, so that it keeps no place for a second cell.
        .layoutValue(key: ListRowTakesDisclosureCell.self, value: disclosureCell != nil)
    }
}

/// The same as `ListRowTookDisclosureCell`, as a layout value: the Disclosure style's header reads it on its label's
/// views while it lays them out, in the same pass. Package-internal.
struct ListRowTakesDisclosureCell: LayoutValueKey {
    static let defaultValue = false
}

/// Whether a ListRow drew the Disclosure chevron's cell it was handed (`listRowDisclosureCell`): the Disclosure style
/// reads it on its label, and draws the cell after a label that is no such row. Package-internal.
struct ListRowTookDisclosureCell: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// The pressable row's style: the highlight in the states the system reports, and the pointer tracked over the whole
/// row.
private struct ListRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ListRowPressBody(configuration: configuration)
    }
}

private struct ListRowPressBody: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.listRowPressObserver) private var pressObserver

    var body: some View {
        configuration.label
            .modifier(
                ListRowHighlight(
                    form: .pressable, isPressed: configuration.isPressed, isHovered: isHovered, isFocused: isFocused)
            )
            #if !os(watchOS)
                .onHover { hovering in
                    isHovered = hovering && ListRowState.hover.isEntered
                }
            #endif
            // A disabled view may receive no hover events, so a pointer that leaves while the row is disabled would
            // leave it hovered, as Button's style says.
            .onChange(of: isEnabled) { _, enabled in
                if !enabled { isHovered = false }
            }
            .onChange(of: configuration.isPressed) { _, pressed in
                pressObserver?(pressed)
            }
    }
}

/// The highlight under the row, its bar, its ring, its opacity, and the shapes the system's pointer, focus ring and
/// assistive technology take: the highlight's rounded rectangle at `container.radius`, filling the row's frame.
private struct ListRowHighlight: ViewModifier {
    let form: ListRowForm
    let isPressed: Bool
    let isHovered: Bool
    let isFocused: Bool

    @Environment(\.isSelected) private var isSelected
    @Environment(\.isDropTarget) private var isDropTarget
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.forcedListRowStates) private var forcedStates
    @Environment(\.listRowDimsContent) private var dimmedAround

    func body(content: Content) -> some View {
        // What the system and the environment report, and what the catalog forces for a screenshot.
        let states = ListRowHighlight.states(
            pressed: isPressed, hovered: isHovered, focused: isFocused, selected: isSelected,
            dropTarget: isDropTarget, enabled: isEnabled
        ).union(forcedStates)
        let effective = ListRowTokens.effective(states, form: form)
        let tokens = ListRowTokens(form: form, states: states)
        let radius = CGFloat(ListRowMetrics.radius)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // A disabled row dims what it draws once: here, unless a disabled row around it already does. The layout dims
        // each part but the chevron's cell (`listRowOpacity`), whose look follows its group's state, as after any
        // other label; a control in a slot reads `listRowDimsContent` and draws no opacity of its own for disabled.
        let opacity = (dimmedAround ? nil : tokens.opacity).map(Double.init) ?? 1

        return
            content
            .environment(\.listRowTitleFont, tokens.titleFont)
            .environment(\.listRowDimsContent, dimmedAround || opacity < 1)
            .environment(\.listRowOpacity, opacity)
            .background {
                ZStack(alignment: .leading) {
                    if let background = tokens.background {
                        shape.fill(background)
                            .listRowProbed("highlight")
                    }
                    // A selected row's bar, at the highlight's leading edge and inside it, as long as the highlight's
                    // straight side: a cue of selection that is neither the tint nor the title's weight.
                    if let barColor = tokens.barColor, let barWidth = tokens.barWidth {
                        Capsule(style: .continuous)
                            .fill(barColor)
                            .frame(width: CGFloat(barWidth))
                            .listRowProbed("bar")
                            .padding(.vertical, radius)
                    }
                }
                // The tint of a press in `motion.press`; of the pointer, the selection and a drop in `motion.fade`.
                .animation(ListRowMotion.highlight, value: effective.contains(.hover))
                .animation(ListRowMotion.highlight, value: effective.contains(.selected))
                .animation(ListRowMotion.highlight, value: effective.contains(.dropTarget))
                .animation(ListRowMotion.press, value: effective.contains(.pressed))
                .opacity(opacity)
            }
            // The drop target's ring, above the row's content, so that the guides do not cross it.
            .overlay {
                ZStack {
                    if let ringColor = tokens.ringColor, let ringWidth = tokens.ringWidth {
                        shape.strokeBorder(ringColor, lineWidth: CGFloat(ringWidth))
                            .listRowProbed("ring")
                    }
                }
                .animation(ListRowMotion.highlight, value: effective.contains(.dropTarget))
                .opacity(opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            #if os(macOS)
                .contentShape(.interaction, shape)
            #endif
            .contentShape(.accessibility, shape)
            #if os(macOS) || os(watchOS)
                // The system's focus ring follows the highlight.
                .contentShape(.focusEffect, shape)
            #endif
    }

    /// The states that hold, from what the system and the environment report.
    static func states(
        pressed: Bool, hovered: Bool, focused: Bool, selected: Bool, dropTarget: Bool, enabled: Bool
    ) -> Set<ListRowState> {
        var states: Set<ListRowState> = []
        if pressed { states.insert(.pressed) }
        if hovered { states.insert(.hover) }
        if focused { states.insert(.focus) }
        if selected { states.insert(.selected) }
        if dropTarget { states.insert(.dropTarget) }
        if !enabled { states.insert(.disabled) }
        return states
    }
}

extension EnvironmentValues {
    /// The title's text role in the row's states: `title.font`, which a role the product sets on its title wins over.
    @Entry var listRowTitleFont: Westron.TextRole = .body.regular
}

// MARK: - The layout

/// What the row's words are to assistive technology: nothing, in the drawn row, which the representation replaces; a
/// button, in the pressable row's representation, whose activation is the row's action while it is enabled (nil while
/// disabled); text in one element, in the static row's.
enum ListRowWords {
    case drawn
    case button(action: (() -> Void)?, selected: Bool)
    case text(selected: Bool)
}

/// The drawn row: the indent, the leading slot, the title and the second line, the trailing slot, and the chevron's
/// cell, padded, at least `container.minHeight` high, over the guides. The horizontal spacing scales with Dynamic Type
/// from its tokens, relative to the title's text style, up to `ListRowMetrics.structureLimit`; the vertical spacing at
/// every size. The representation uses the same layout, so that each element's frame is where its part is drawn.
struct ListRowContent: View {
    let level: Int
    let guides: Bool
    let parts: ListRowParts
    let cell: AnyView?
    var words: ListRowWords = .drawn

    var body: some View {
        ListRowSpacingReader { spacing in
            ListRowLayout(level: level, guides: guides, parts: parts, cell: cell, words: words, spacing: spacing)
        }
    }
}

private struct ListRowLayout: View {
    let level: Int
    let guides: Bool
    let parts: ListRowParts
    let cell: AnyView?
    let words: ListRowWords
    let spacing: ListRowSpacing

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.listRowTitleFont) private var titleFont
    @Environment(\.listRowOpacity) private var opacity
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var paddingVertical = CGFloat(
        ListRowMetrics.paddingVertical)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var subtitleGap = CGFloat(ListRowMetrics.subtitleGap)

    private var compact: Bool {
        #if os(iOS)
            sizeClass == .compact
        #elseif os(watchOS)
            true
        #else
            false
        #endif
    }

    var body: some View {
        let stacks = ListRowMetrics.stacksTrailing(dynamicTypeSize)
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let leading = parts.leading {
                leading
                    .textRole(ListRowMetrics.slotRole)
                    .anchorPreference(key: ListRowLeadingBounds.self, value: .bounds) { $0 }
                    .listRowProbed("leading")
                    .opacity(opacity)
                    .padding(.trailing, spacing.gap)
            }
            wordsElement(stacks: stacks)
                .opacity(opacity)
            if let cell {
                // In the slots' role, so that the chevron sizes from the row's text as an Icon at the end does. Not at
                // the row's opacity: the cell's look follows its group's state, which a row disabled alone leaves
                // enabled, so that it folds the branch and is drawn as after any other label (the contract's disabled).
                cell
                    // The cell is named by the row's title, read here in the row's own tree: the group's label view,
                    // drawn again inside the cell's representation, would resolve to the outermost group's in a tree.
                    .environment(\.listRowDisclosureCellName, parts.title)
                    .textRole(ListRowMetrics.slotRole)
                    .padding(.leading, spacing.trailingGap)
            }
        }
        .padding(.leading, ListRowMetrics.slotStart(level: level, indent: spacing.indent, padding: spacing.padding))
        .padding(.trailing, spacing.padding)
        .frame(maxWidth: .infinity, minHeight: ListRowMetrics.minHeight, alignment: .leading)
        .backgroundPreferenceValue(ListRowLeadingBounds.self) { leading in
            if guides && level > 0 {
                GeometryReader { proxy in
                    ListRowGuides(
                        centres: ListRowMetrics.guides(
                            level: level, enabled: guides, spacing: spacing,
                            slotWidth: leading.map { proxy[$0].width } ?? 0),
                        width: ListRowMetrics.guideWidth(compact: compact))
                }
                .opacity(opacity)
                .accessibilityHidden(true)
            }
        }
    }

    /// The title, the second line and, at the accessibility sizes, the trailing slot under them; otherwise the trailing
    /// slot at the end. Together they are the row's words: one element to assistive technology. The text is padded
    /// vertically, and the trailing slot at the end stands beside that padding, on the title's first line, as the
    /// leading slot does: a frame taller than the line, such as a static Chip's, stands in the padding and grows the
    /// row only where it would cross the row's edge.
    @ViewBuilder private func wordsElement(stacks: Bool) -> some View {
        let column = HStack(alignment: .firstTextBaseline, spacing: 0) {
            VStack(alignment: .leading, spacing: subtitleGap) {
                parts.title
                    .textRole(titleFont)
                    .foregroundStyle(ListRowMetrics.titleColor)
                if let subtitle = parts.subtitle {
                    subtitle
                        .textRole(ListRowMetrics.subtitleFont)
                        .foregroundStyle(ListRowMetrics.subtitleColor)
                }
                if stacks, let trailing = parts.trailing {
                    trailing.textRole(ListRowMetrics.slotRole)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, stacks ? 0 : paddingVertical)
            if !stacks, let trailing = parts.trailing {
                trailing
                    .textRole(ListRowMetrics.slotRole)
                    .padding(.leading, spacing.trailingGap)
            }
        }
        // Stacked, nothing stands beside the text: the padding goes around the whole column, as it always has, so that
        // the row's height rounds to the same pixels.
        .padding(.vertical, stacks ? paddingVertical : 0)
        .listRowProbed("words")
        switch words {
        case .drawn:
            column
        case .button(let action, let selected):
            // One element of the words, a button: activating it is the row's action while the row is enabled. A
            // system Button here would drop the selected trait (measured on iOS 26, decisions/0001, "Measured"); its
            // frame is the row's height.
            column
                .frame(minHeight: ListRowMetrics.minHeight)
                .contentShape(.accessibility, Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
                .modifier(ListRowActivation(action: action))
                .modifier(ListRowLevelContent(level: level))
        case .text(let selected):
            // One element of the words, as text, its frame the row's height as the button's is.
            column
                .frame(minHeight: ListRowMetrics.minHeight)
                .contentShape(.accessibility, Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .modifier(ListRowLevelContent(level: level))
        }
    }
}

/// The words' activation, the row's action, only while the row is enabled.
private struct ListRowActivation: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.accessibilityAction { action() }
        } else {
            content
        }
    }
}

/// The level as more content, from level 1 on, counted from 1, not spoken unless asked (decisions/0001, Q8): a row at
/// level 1 carries "Level" "2".
struct ListRowLevelContent: ViewModifier {
    let level: Int
    @Environment(\.listRowProbe) private var probe

    func body(content: Content) -> some View {
        if let spoken = ListRowMetrics.spokenLevel(level) {
            let _ = probe?.note("level \(spoken)")
            content.accessibilityCustomContent(
                Text("Level", bundle: .module, comment: "The nesting level of a row in a tree, as more content."),
                Text(spoken, format: .number))
        } else {
            content
        }
    }
}

/// The bounds of the row's leading slot, for its guides.
private struct ListRowLeadingBounds: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// The guides: one vertical line per ancestor level, the whole height of the row, decorative.
private struct ListRowGuides: View {
    let centres: [CGFloat]
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(centres.indices, id: \.self) { index in
                Rectangle()
                    .fill(ListRowMetrics.guideColor)
                    .frame(width: width)
                    .listRowProbed("guide \(index)")
                    .padding(.leading, centres[index] - width / 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
