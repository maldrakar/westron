// Hand-written. Rule from its contract, spec/components/rule/rule.spec.yaml: westron's straight line between two
// groups, which may carry the name of the group under it, or which marks where a dragged item would be dropped. It is
// an own component in the form of a view (`platforms.apple.form`): the generated `RuleAxis` and `RulePurpose`
// (Generated/Rule+Contract.swift) name its options, and the API parity lint holds `Rule` and its initializers to the
// contract (spec/conventions.md, "Own components"). It is not named Divider, which would collide with SwiftUI's in
// every file that imports SwiftUI (decisions/0003, point 3).

import SwiftUI

/// westron's rule: a straight line that fills the length it is offered along its axis.
///
/// - `Rule()` runs along the width and separates groups stacked one above the other; `Rule(axis: .vertical)` runs
///   along the height and separates groups side by side: `color.border.default`, `stroke.thin` across its axis.
///   Unlike the system `Divider`, it takes its axis from the argument, not from its stack.
/// - `Rule(purpose: .insertion)` marks where a dragged item would be dropped: `color.border.insertion`,
///   `stroke.thick`, its ends round. Where it stands, and when, is the list's or the product's, which follows the drag.
/// - `Rule("Work")`, or `Rule(area.name)` for a label that is not localized, is a horizontal separator that names
///   the group under it: the label at its leading end in `heading.overline` and `text.secondary`, on one line and
///   truncated at its end when the rule is narrower than it, then `space100`, scaled with the label, and the line
///   across the rest. The product
///   writes the label's capitals. The label is a heading for assistive technology.
///
/// The product gives the rule its length and the space around it with its stack and spacing tokens. A rule without a
/// label, of either purpose, is decorative, so it is hidden from assistive technology.
public struct Rule: View {
    let axis: RuleAxis
    let purpose: RulePurpose
    let label: Text?

    /// The label's text role, `heading.overline`.
    private static let labelRole: Westron.TextRole = .heading.overline

    /// The gap between the label and the line, `space100`, scaled with the text style of the label's role, so that it
    /// keeps its proportion to the label at every text size and follows the role if its text style changes.
    @ScaledMetric(relativeTo: Font.TextStyle(Rule.labelRole.textStyle)) private var gap: CGFloat = .space100

    /// - Parameters:
    ///   - axis: See `RuleAxis`; by default `.horizontal`.
    ///   - purpose: See `RulePurpose`; by default `.separator`.
    public init(axis: RuleAxis = .horizontal, purpose: RulePurpose = .separator) {
        self.axis = axis
        self.purpose = purpose
        label = nil
    }

    /// A horizontal separator with a localized label: the name of the group under it.
    public init(_ label: LocalizedStringKey) {
        axis = .horizontal
        purpose = .separator
        self.label = Text(label)
    }

    /// A horizontal separator with a label that is not localized, such as a name the person gave. An empty name is
    /// no label: the rule is drawn alone and hidden, as an unnamed area's line is.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ label: S) {
        axis = .horizontal
        purpose = .separator
        self.label = label.isEmpty ? nil : Text(label)
    }

    public var body: some View {
        if let label {
            HStack(spacing: gap) {
                label
                    .textRole(Self.labelRole)
                    .foregroundStyle(.text.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    // The label takes what it needs first, and the line the rest, down to nothing.
                    .layoutPriority(1)
                    .accessibilityAddTraits(.isHeader)
                line
            }
        } else {
            line
        }
    }

    /// The line itself, never announced.
    @ViewBuilder
    private var line: some View {
        // A filled shape, as the pilot draws its rules, rather than a stroked path: its thickness is exact.
        switch purpose {
        case .separator:
            Rectangle()
                .fill(.border.default)
                .frame(width: axis == .vertical ? .stroke.thin : nil, height: axis == .horizontal ? .stroke.thin : nil)
                .accessibilityHidden(true)
        case .insertion:
            Capsule()
                .fill(.border.insertion)
                .frame(
                    width: axis == .vertical ? .stroke.thick : nil, height: axis == .horizontal ? .stroke.thick : nil
                )
                .accessibilityHidden(true)
        }
    }
}
