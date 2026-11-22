// Hand-written. westron's ListRow (spec/components/list-row/list-row.spec.yaml), an own view (decisions/0003, point 2):
// SwiftUI has no row outside a List. Its initializers follow the contract through spec/conventions.md, "Own
// components", and the API parity lint holds them to it; the enums, the states and the forms are generated
// (Generated/ListRow+Contract.swift).
//
// The pressable row is a system Button whose label is the whole drawn row, so the pointer, the keyboard, the press and
// .disabled(_:) are the system's, and a press anywhere on the row's frame is the row's action. A control at the start,
// a Checkbox, is nested in that label and takes its own press: the inner control's gesture wins. To assistive
// technology the Button would merge that control into its own element, so the row is given there by
// `accessibilityRepresentation`: the same layout, with the control at the start as its own element, a Button of the
// row's words, and the Disclosure chevron's cell as its own element (decisions/0001, "Measured").

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
/// The title is the content every row has; every other slot is optional. A control belongs at the start; the trailing
/// slot holds words and glyphs, which join the row's spoken name. `.selected(_:)` and `.dropTarget(_:)` set the states
/// the system lacks, `.insertionMark(_:level:)` marks where a dragged row would land, and `.disabled(_:)` dims the
/// row. In a `List`, give the row `.listRowInsets(EdgeInsets())`, `.listRowBackground(Color.clear)` and
/// `.listRowSeparator(.hidden)`, and bind no `List` selection: the row draws its own.
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
    ///   - title: The row's first line, in `body.regular`, `body.strong` while selected, unless it sets its own role.
    ///   - subtitle: The second line, in `footnote.regular` and `text.secondary`.
    ///   - leading: An IconTile, an Icon or a Checkbox at the start, on the title's first line.
    ///   - trailing: Words and glyphs at the end, such as a count; under the text at the accessibility sizes.
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
}

// MARK: - The row

/// The row in its form: a system Button around the drawn row, or the drawn row alone; the states the system and the
/// environment report; and the representation assistive technology reads.
private struct ListRowBody: View {
    let level: Int
    let guides: Bool
    let action: (() -> Void)?
    let parts: ListRowParts

    @Environment(\.listRowDisclosureCell) private var cell
    @Environment(\.isSelected) private var isSelected
    @Environment(\.isDropTarget) private var isDropTarget
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let content = ListRowContent(level: level, guides: guides, parts: parts, cell: cell)
        Group {
            if let action {
                Button(action: action) {
                    content
                }
                .buttonStyle(ListRowPressStyle())
                .accessibilityRepresentation {
                    ListRowContent(
                        level: level, guides: false, parts: parts, cell: cell,
                        words: .button(action: action, selected: isSelected))
                }
            } else {
                content
                    .modifier(ListRowHighlight(form: .static, isPressed: false, isHovered: false, isFocused: false))
                    .accessibilityRepresentation {
                        ListRowContent(
                            level: level, guides: false, parts: parts, cell: cell, words: .text(selected: isSelected))
                    }
            }
        }
        // The row takes every line its words need at the width it is given: neither line has a limit of the row's
        // own, so a stack that offers less height neither truncates nor squeezes it.
        .fixedSize(horizontal: false, vertical: true)
        // The cell is this row's: a row inside one of its slots draws none.
        .environment(\.listRowDisclosureCell, nil)
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
    }
}

/// The highlight under the row, its ring, its opacity, and the shapes the system's pointer, focus ring and assistive
/// technology take: the highlight's rounded rectangle at `container.radius`, filling the row's frame.
private struct ListRowHighlight: ViewModifier {
    let form: ListRowForm
    let isPressed: Bool
    let isHovered: Bool
    let isFocused: Bool

    @Environment(\.isSelected) private var isSelected
    @Environment(\.isDropTarget) private var isDropTarget
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.forcedListRowStates) private var forcedStates

    func body(content: Content) -> some View {
        // What the system and the environment report, and what the catalog forces for a screenshot.
        let states = ListRowHighlight.states(
            pressed: isPressed, hovered: isHovered, focused: isFocused, selected: isSelected,
            dropTarget: isDropTarget, enabled: isEnabled
        ).union(forcedStates)
        let effective = ListRowTokens.effective(states, form: form)
        let tokens = ListRowTokens(form: form, states: states, highContrast: contrast == .increased)
        let motion = ListRowMotion(reduceMotion: reduceMotion)
        let shape = RoundedRectangle(cornerRadius: CGFloat(ListRowMetrics.radius), style: .continuous)

        return
            content
            .environment(\.listRowTitleFont, tokens.titleFont)
            .background {
                ZStack {
                    if let background = tokens.background {
                        shape.fill(background)
                    }
                    if let ringColor = tokens.ringColor, let ringWidth = tokens.ringWidth {
                        shape.strokeBorder(ringColor, lineWidth: CGFloat(ringWidth))
                    }
                }
                // The tint of a press in `motion.press`; of the pointer, the selection and a drop in `motion.fade`.
                .animation(motion.highlight, value: effective.contains(.hover))
                .animation(motion.highlight, value: effective.contains(.selected))
                .animation(motion.highlight, value: effective.contains(.dropTarget))
                .animation(motion.press, value: effective.contains(.pressed))
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
            .opacity(tokens.opacity.map(Double.init) ?? 1)
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
/// button, in the pressable row's representation; text in one element, in the static row's.
enum ListRowWords {
    case drawn
    case button(action: () -> Void, selected: Bool)
    case text(selected: Bool)
}

/// The drawn row: the indent, the leading slot, the title and the second line, the trailing slot, and the chevron's
/// cell, padded, at least `container.minHeight` high, over the guides. The metrics scale with Dynamic Type from their
/// tokens, relative to the title's text style. The representation uses the same layout, so that each element's frame
/// is where its part is drawn.
struct ListRowContent: View {
    let level: Int
    let guides: Bool
    let parts: ListRowParts
    let cell: AnyView?
    var words: ListRowWords = .drawn

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.listRowTitleFont) private var titleFont
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var indent = CGFloat(ListRowMetrics.indent)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var padding = CGFloat(
        ListRowMetrics.paddingHorizontal)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var paddingVertical = CGFloat(
        ListRowMetrics.paddingVertical)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var gap = CGFloat(ListRowMetrics.gap)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var trailingGap = CGFloat(ListRowMetrics.trailingGap)
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
                    .anchorPreference(key: ListRowLeadingBounds.self, value: .bounds) { $0 }
                    .padding(.trailing, gap)
            }
            wordsElement(stacks: stacks)
            if let cell {
                cell.padding(.leading, trailingGap)
            }
        }
        .padding(.leading, ListRowMetrics.slotStart(level: level, indent: indent, padding: padding))
        .padding(.trailing, padding)
        .frame(maxWidth: .infinity, minHeight: ListRowMetrics.minHeight, alignment: .leading)
        .backgroundPreferenceValue(ListRowLeadingBounds.self) { leading in
            if guides && level > 0 {
                GeometryReader { proxy in
                    ListRowGuides(
                        centres: ListRowMetrics.guides(
                            level: level, enabled: guides, indent: indent, padding: padding,
                            slotWidth: leading.map { proxy[$0].width } ?? 0),
                        width: ListRowMetrics.guideWidth(compact: compact))
                }
                .accessibilityHidden(true)
            }
        }
    }

    /// The title, the second line and, at the accessibility sizes, the trailing slot under them; otherwise the trailing
    /// slot at the end. Together they are the row's words: one element to assistive technology.
    @ViewBuilder private func wordsElement(stacks: Bool) -> some View {
        let column = HStack(alignment: .firstTextBaseline, spacing: 0) {
            VStack(alignment: .leading, spacing: subtitleGap) {
                parts.title
                    .textRole(titleFont)
                    .foregroundStyle(.text.primary)
                if let subtitle = parts.subtitle {
                    subtitle
                        .textRole(ListRowMetrics.subtitleFont)
                        .foregroundStyle(.text.secondary)
                }
                if stacks, let trailing = parts.trailing {
                    trailing
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !stacks, let trailing = parts.trailing {
                trailing
                    .padding(.leading, trailingGap)
            }
        }
        .padding(.vertical, paddingVertical)
        switch words {
        case .drawn:
            column
        case .button(let action, let selected):
            // One element of the words, a button: activating it is the row's action. A system Button here would drop
            // the selected trait (measured on iOS 26, decisions/0001, "Measured"); its frame is the row's height.
            column
                .frame(minHeight: ListRowMetrics.minHeight)
                .contentShape(.accessibility, Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
                .accessibilityAction { action() }
                .modifier(ListRowLevelContent(level: level))
        case .text(let selected):
            column
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .modifier(ListRowLevelContent(level: level))
        }
    }
}

/// The level as more content, from level 1 on, counted from 1, not spoken unless asked (decisions/0001, Q8).
private struct ListRowLevelContent: ViewModifier {
    let level: Int

    func body(content: Content) -> some View {
        if let spoken = ListRowMetrics.spokenLevel(level) {
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
                    .fill(.border.guide)
                    .frame(width: width)
                    .padding(.leading, centres[index] - width / 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
