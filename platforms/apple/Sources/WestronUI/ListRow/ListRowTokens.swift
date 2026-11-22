// Hand-written. ListRow's token bindings from its contract, spec/components/list-row/list-row.spec.yaml, as pure
// functions of its form, its states and the contrast, so that the row draws exactly what they return and the tests
// compare them with the contract's `tokens` block, case by case (Tests/WestronUITests/ListRowTests.swift).

import SwiftUI

/// The tokens a ListRow draws with, for one form, set of states and contrast: the contract's bindings, each resolved by
/// the first case that matches, and in the high-contrast themes the ring of a selected row that the contract's
/// description adds.
struct ListRowTokens: Equatable, Sendable {
    /// `container.background`; nil: no highlight, the row stands on what the product puts it on.
    var background: Westron.Color?
    /// `ring.color`, or the high-contrast ring of a selected row; nil: no ring.
    var ringColor: Westron.Color?
    /// `ring.width`; nil: no ring.
    var ringWidth: Westron.Dimension?
    /// `container.opacity`; nil: drawn whole.
    var opacity: Westron.Number?
    /// `title.font`, which a role the product sets on its title wins over.
    var titleFont: Westron.TextRole

    /// The tokens of a row of `form` in `states`, which hold at once. A state the current OS or the form never enters
    /// is ignored, and a disabled row never enters hover, pressed or dropTarget (`effective`). `highContrast`: one of
    /// the high-contrast themes, `colorSchemeContrast == .increased`, where a selected row draws `color.border.focus`
    /// at `stroke.thick` inside its highlight's edge.
    init(form: ListRowForm, states: Set<ListRowState>, highContrast: Bool) {
        let states = Self.effective(states, form: form)
        // The cases of container.background, in the contract's order: dropTarget, pressed, selected, hover.
        if states.contains(.dropTarget) {
            background = .background.accentSubtle
        } else if states.contains(.pressed) {
            background = .background.pressed
        } else if states.contains(.selected) {
            background = .background.selected
        } else if states.contains(.hover) {
            background = .background.hover
        } else {
            background = nil
        }
        if states.contains(.dropTarget) {
            ringColor = .border.insertion
            ringWidth = .stroke.thick
        } else if highContrast && states.contains(.selected) {
            ringColor = .border.focus
            ringWidth = .stroke.thick
        } else {
            ringColor = nil
            ringWidth = nil
        }
        opacity = states.contains(.disabled) ? .opacity.disabled : nil
        titleFont = states.contains(.selected) ? .body.strong : .body.regular
    }

    /// The states a row is drawn in: those the current OS and its form enter, and in disabled neither hover, pressed
    /// nor dropTarget (the contract's description).
    static func effective(_ states: Set<ListRowState>, form: ListRowForm) -> Set<ListRowState> {
        var states = states.filter { $0.isEntered && form.states.contains($0) }
        if states.contains(.disabled) { states.subtract([.hover, .pressed, .dropTarget]) }
        return states
    }
}

/// What moves when a row is hovered, pressed, selected or targeted, and how (the contract's description;
/// design-language/05): the timing belongs to the motion tokens. A row never scales (decisions/0001, Q6).
struct ListRowMotion: Equatable {
    let reduceMotion: Bool

    /// The scale of a pressed row: always 1, with or without Reduce Motion; a row is as wide as its list.
    func scale(pressed _: Bool) -> CGFloat { 1 }

    /// The motion of the highlight's tint as a press begins and ends: `container.pressMotion`, `motion.press`, which
    /// Reduce Motion keeps, a tint and no travel.
    var press: Animation { .press }

    /// The motion of the highlight under the pointer, as the row is selected and as it becomes a drop target:
    /// `container.highlightMotion`, `motion.fade`, which Reduce Motion keeps.
    var highlight: Animation { .fade }

    /// The motion of the insertion mark moving to another edge or level: a fade in `motion.fade`, with or without
    /// Reduce Motion, since the mark does not travel.
    var mark: Animation { .fade }
}

/// ListRow's bindings that do not depend on the states, and its layout's rules.
enum ListRowMetrics {
    /// `container.minHeight`: 44 pt on iOS and watchOS, 28 on macOS; the row grows with its text.
    static var minHeight: CGFloat { .size.target.minimum }
    /// `container.paddingHorizontal`, at either side, inside the highlight.
    static let paddingHorizontal: Westron.Dimension = .space150
    /// `container.paddingVertical`, above and below the text.
    static let paddingVertical: Westron.Dimension = .space75
    /// `container.gap`, between the leading slot and the title.
    static let gap: Westron.Dimension = .space150
    /// `container.trailingGap`, before the trailing slot and before the chevron's cell.
    static let trailingGap: Westron.Dimension = .space100
    /// `container.indent`, per level.
    static let indent: Westron.Dimension = .space300
    /// `container.radius`.
    static let radius: Westron.Dimension = .radius.row
    /// `subtitle.gap`, between the title and the second line.
    static let subtitleGap: Westron.Dimension = .space25
    /// `subtitle.font`.
    static let subtitleFont: Westron.TextRole = .footnote.regular
    /// The text style the row's metrics scale with: the title's.
    static let textStyle: Font.TextStyle = Font.TextStyle(Westron.TextRole.body.regular.textStyle)

    /// `guide.width`: `stroke.thin`, and `stroke.regular` in the compact horizontal size class, a phone's (the
    /// contract's description: the bindings cannot say a size class).
    static func guideWidth(compact: Bool) -> CGFloat {
        compact ? .stroke.regular : .stroke.thin
    }

    /// Whether the trailing slot moves under the title and the second line: at the accessibility text sizes.
    static func stacksTrailing(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    /// The leading edge of the level's leading slot from the row's leading edge: the padding and an indent per level.
    static func slotStart(level: Int, indent: CGFloat, padding: CGFloat) -> CGFloat {
        padding + CGFloat(max(0, level)) * indent
    }

    /// The centre of each guide of a row at `level`, from the row's leading edge: one per ancestor level, `0..<level`,
    /// under where that level's leading slot is centred, the row's own slot `slotWidth` wide.
    static func guideCentres(level: Int, indent: CGFloat, padding: CGFloat, slotWidth: CGFloat) -> [CGFloat] {
        (0..<max(0, level)).map { slotStart(level: $0, indent: indent, padding: padding) + slotWidth / 2 }
    }

    /// The centres of the guides a row draws: those of `guideCentres` with guides on, otherwise none.
    static func guides(level: Int, enabled: Bool, indent: CGFloat, padding: CGFloat, slotWidth: CGFloat) -> [CGFloat] {
        enabled ? guideCentres(level: level, indent: indent, padding: padding, slotWidth: slotWidth) : []
    }

    /// The level as more content, counted from 1, from level 1 on; nil at level 0 (decisions/0001, Q8).
    static func spokenLevel(_ level: Int) -> Int? {
        level >= 1 ? level + 1 : nil
    }
}
