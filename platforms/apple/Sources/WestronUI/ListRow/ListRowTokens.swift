// Hand-written. ListRow's token bindings from its contract, spec/components/list-row/list-row.spec.yaml, as pure
// functions of its form and its states, so that the row draws exactly what they return and the tests compare them with
// the contract's `tokens` block, case by case (Tests/WestronUITests/ListRowTests.swift).

import SwiftUI

/// The tokens a ListRow draws with, for one form and set of states: the contract's bindings, each resolved by the first
/// case that matches. They are the same in every theme: the colors switch with the theme and the contrast by themselves.
struct ListRowTokens: Equatable, Sendable {
    /// `container.background`; nil: no highlight, the row stands on what the product puts it on.
    var background: Westron.Color?
    /// `ring.color`, a drop target's ring; nil: no ring.
    var ringColor: Westron.Color?
    /// `ring.width`; nil: no ring.
    var ringWidth: Westron.Dimension?
    /// `bar.color`, a selected row's bar at the highlight's leading edge; nil: no bar.
    var barColor: Westron.Color?
    /// `bar.width`; nil: no bar.
    var barWidth: Westron.Dimension?
    /// `container.opacity`; nil: drawn whole.
    var opacity: Westron.Number?
    /// `title.font`, which a role the product sets on its title wins over.
    var titleFont: Westron.TextRole

    /// The tokens of a row of `form` in `states`, which hold at once. A state the current OS or the form never enters
    /// is ignored, and a disabled row never enters hover, pressed or dropTarget (`effective`).
    init(form: ListRowForm, states: Set<ListRowState>) {
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
        } else {
            ringColor = nil
            ringWidth = nil
        }
        if states.contains(.selected) {
            barColor = .border.focus
            barWidth = .stroke.thick
        } else {
            barColor = nil
            barWidth = nil
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

/// How the highlight and the mark change, and in what timing (the contract's description; design-language/05): the
/// timing belongs to the motion tokens. Nothing travels or scales, so Reduce Motion changes none of it
/// (decisions/0001, Q6).
enum ListRowMotion {
    /// The motion of the highlight's tint as a press begins and ends: `container.pressMotion`, `motion.press`.
    static var press: Animation { .press }

    /// The motion of the highlight under the pointer, as the row is selected and as it becomes a drop target:
    /// `container.highlightMotion`, `motion.fade`.
    static var highlight: Animation { .fade }

    /// The motion of the insertion mark moving to another edge or level: the old mark fades out and the new one in,
    /// in `motion.fade`; the mark does not travel.
    static var mark: Animation { .fade }
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
    /// `title.color`.
    static let titleColor: Westron.Color = .text.primary
    /// `subtitle.gap`, between the title and the second line.
    static let subtitleGap: Westron.Dimension = .space25
    /// `subtitle.font`.
    static let subtitleFont: Westron.TextRole = .footnote.regular
    /// `subtitle.color`.
    static let subtitleColor: Westron.Color = .text.secondary
    /// `guide.color`.
    static let guideColor: Westron.Color = .border.guide
    /// The text style the row's metrics scale with: the title's.
    static let textStyle: Font.TextStyle = Font.TextStyle(Westron.TextRole.body.regular.textStyle)
    /// The text role the leading and the trailing slot take: the title's at rest, so that an Icon there sizes from it.
    /// Words the product puts there set their own role.
    static let slotRole: Westron.TextRole = .body.regular
    /// The largest text size the row's horizontal spacing scales to: the indent, the padding at either side, the gaps
    /// beside the title and the insertion mark's start. At the accessibility sizes the structure keeps this width and
    /// the words take the rest; the vertical spacing and the text scale on (the contract's description).
    static let structureLimit: DynamicTypeSize = .xxxLarge

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

    /// The distance of a level's guide from the start of that level's slot: under the slot's centre, the row's own
    /// slot `slotWidth` wide, but never closer than half `container.gap` to the next level's slot, which starts an
    /// indent further. An Icon in the slot grows with the text at every size while the indent stops at `structureLimit`,
    /// so at the accessibility sizes the guide stands at the indent less half the gap (decisions/0001, D2).
    static func guideOffset(indent: CGFloat, gap: CGFloat, slotWidth: CGFloat) -> CGFloat {
        max(0, min(slotWidth / 2, indent - gap / 2))
    }

    /// The centre of each guide of a row at `level`, from the row's leading edge: one per ancestor level, `0..<level`,
    /// `guideOffset` past that level's slot start. A row without a leading slot (`slotWidth` 0) draws them at each
    /// ancestor level's slot start.
    static func guideCentres(level: Int, spacing: ListRowSpacing, slotWidth: CGFloat) -> [CGFloat] {
        let offset = guideOffset(indent: spacing.indent, gap: spacing.gap, slotWidth: slotWidth)
        return (0..<max(0, level)).map {
            slotStart(level: $0, indent: spacing.indent, padding: spacing.padding) + offset
        }
    }

    /// The centres of the guides a row draws: those of `guideCentres` with guides on, otherwise none.
    static func guides(level: Int, enabled: Bool, spacing: ListRowSpacing, slotWidth: CGFloat) -> [CGFloat] {
        enabled ? guideCentres(level: level, spacing: spacing, slotWidth: slotWidth) : []
    }

    /// The level as more content, counted from 1, from level 1 on; nil at level 0 (decisions/0001, Q8): a row at
    /// level 1 says "Level 2".
    static func spokenLevel(_ level: Int) -> Int? {
        level >= 1 ? level + 1 : nil
    }
}

/// The row's horizontal spacing, scaled with the title's text style up to `ListRowMetrics.structureLimit`.
struct ListRowSpacing: Equatable, Sendable {
    /// `container.indent`, per level.
    var indent: CGFloat
    /// `container.paddingHorizontal`.
    var padding: CGFloat
    /// `container.gap`.
    var gap: CGFloat
    /// `container.trailingGap`.
    var trailingGap: CGFloat

    /// The tokens' own values, unscaled: the default text size's.
    static let base = ListRowSpacing(
        indent: CGFloat(ListRowMetrics.indent), padding: CGFloat(ListRowMetrics.paddingHorizontal),
        gap: CGFloat(ListRowMetrics.gap), trailingGap: CGFloat(ListRowMetrics.trailingGap))
}

/// Hands its content the row's horizontal spacing, scaled with the title's text style at the person's text size but no
/// further than `ListRowMetrics.structureLimit`: `@ScaledMetric` reads the text size of its environment, so the spacing
/// is read under the capped size and the content laid out under the person's own.
struct ListRowSpacingReader<Content: View>: View {
    @ViewBuilder let content: (ListRowSpacing) -> Content
    @Environment(\.dynamicTypeSize) private var size

    var body: some View {
        ListRowCappedSpacing(size: size, content: content)
            .environment(\.dynamicTypeSize, min(size, ListRowMetrics.structureLimit))
    }
}

private struct ListRowCappedSpacing<Content: View>: View {
    let size: DynamicTypeSize
    let content: (ListRowSpacing) -> Content

    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var indent = CGFloat(ListRowMetrics.indent)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var padding = CGFloat(
        ListRowMetrics.paddingHorizontal)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var gap = CGFloat(ListRowMetrics.gap)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var trailingGap = CGFloat(ListRowMetrics.trailingGap)

    var body: some View {
        content(ListRowSpacing(indent: indent, padding: padding, gap: gap, trailingGap: trailingGap))
            .environment(\.dynamicTypeSize, size)
    }
}

// MARK: - Probes

/// Where the row's drawn parts were laid out, for the package's tests: the bar, the ring, the guides, the words, the
/// insertion mark. Internal; nothing sets it but a test.
final class ListRowProbe: @unchecked Sendable {
    private(set) var frames: [String: CGRect] = [:]
    private(set) var marks: Set<String> = []

    subscript(name: String) -> CGRect? { frames[name] }

    func record(_ name: String, _ frame: CGRect) { frames[name] = frame }
    func note(_ name: String) { marks.insert(name) }
}

extension EnvironmentValues {
    /// The probe a test hands the row; nil everywhere else.
    @Entry var listRowProbe: ListRowProbe? = nil
}

extension View {
    /// Records this part's frame in the global space in the environment's probe, if a test set one.
    func listRowProbed(_ name: String) -> some View {
        modifier(ListRowProbing(name: name))
    }
}

private struct ListRowProbing: ViewModifier {
    let name: String
    @Environment(\.listRowProbe) private var probe

    func body(content: Content) -> some View {
        if let probe {
            content.onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: {
                probe.record(name, $0)
            }
        } else {
            content
        }
    }
}
