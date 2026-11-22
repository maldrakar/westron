import SwiftUI
import WestronUI

// Rule's catalog entry, from spec/components/rule/rule.spec.yaml: every axis and purpose of the real `Rule`, each
// between two groups or items as a product lays it out, then labelled rules. The axes and purposes come from the
// generated matrix, so the page follows the contract.

extension CatalogEntry {
    static let rule = CatalogEntry(id: "rule", title: "Rule", section: .components) {
        RulePage()
    }
}

/// A rule between two groups or items: a horizontal one between two lines of a column, spanning its width; a vertical
/// one between two words of a row, as tall as the row, which `fixedSize` makes as tall as its text, as a bar's divider
/// is. A separator stands between two groups; an insertion rule between two items, where a dragged one would land.
struct RuleSample: View {
    let axis: RuleAxis
    let purpose: RulePurpose

    var body: some View {
        let words = purpose == .separator ? ("Above", "Below", "Left", "Right") : ("Inbox", "Today", "Inbox", "Today")
        switch axis {
        case .horizontal:
            VStack(alignment: .leading, spacing: .space100) {
                group(words.0)
                Rule(axis: .horizontal, purpose: purpose)
                group(words.1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .vertical:
            HStack(spacing: .space100) {
                group(words.2)
                Rule(axis: .vertical, purpose: purpose)
                group(words.3)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func group(_ title: String) -> some View {
        Text(title)
            .textRole(.body.regular)
            .foregroundStyle(.text.primary)
    }
}

/// Labelled rules as an area's line stands in a list: a group's rows under it, a short name, a name the person gave
/// that is longer than the column and truncates, and a rule with no name.
struct RuleLabelled: View {
    static let longName = "Household errands, repairs and everything for the garden"

    var body: some View {
        VStack(alignment: .leading, spacing: .space100) {
            Rule("WORK")
            row("Reports")
            Rule(Self.longName.uppercased())
            row("Garden")
            Rule()
            row("Someday")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ title: String) -> some View {
        Text(title)
            .textRole(.body.regular)
            .foregroundStyle(.text.primary)
    }
}

/// One cell of Rule's snapshot matrix (#24): an axis and a purpose, drawn as `RuleSample`.
struct RuleMatrixCell: View {
    let values: RuleMatrixValues

    init(_ values: RuleMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here. The
        // contract has no states, so the state is always rest.
        let (axis, purpose, _) = values.fields
        RuleSample(axis: axis, purpose: purpose)
    }
}

extension ComponentMatrix.Supplement {
    /// A labelled rule: the label is a slot, not an option, so the generated matrix does not draw it.
    static let ruleLabelled = ComponentMatrix.Supplement(
        component: "rule", id: "labelled", title: "labelled",
        note: "The label is a slot, not a contract option. Horizontal: a short label, a long one truncated at its end, "
            + "and a rule with none, each above a row. Vertical: a vertical rule takes no label (the contract's "
            + "constraint), so the cell says so.",
        keeps: ["purpose": "separator"]
    ) {
        switch RuleMatrixValues($0).fields.axis {
        case .horizontal:
            RuleLabelled()
                .matrixCellTakesOfferedWidth()
        case .vertical:
            Text("No label: a vertical rule takes none")
                .textRole(.footnote.regular)
                .foregroundStyle(.text.secondary)
                .matrixCellTakesOfferedWidth()
        }
    }
}

/// Every axis and purpose of the contract, then labelled rules, then rules in use between the rows of a card.
private struct RulePage: View {
    var body: some View {
        TokenPage(
            title: "Rule",
            summary: "Rule(), Rule(axis: .vertical): border.default at stroke.thin across its axis, filling the length "
                + "its stack offers along it. Rule(purpose: .insertion): border.insertion at stroke.thick, round ends. "
                + "Rule(\"WORK\"): a label in heading.overline, a heading for assistive technology; a rule without one "
                + "is hidden."
        ) {
            VStack(alignment: .leading, spacing: .space.betweenGroups) {
                ForEach(ComponentMatrix.rule.combinations, id: \.self) { combination in
                    let (axis, purpose, _) = RuleMatrixValues(combination).fields
                    VStack(alignment: .leading, spacing: .space50) {
                        TokenName("\(axis.rawValue), \(purpose.rawValue)")
                        RuleSample(axis: axis, purpose: purpose)
                    }
                }
                VStack(alignment: .leading, spacing: .space50) {
                    TokenName("labelled")
                    RuleLabelled()
                }
                VStack(alignment: .leading, spacing: .space50) {
                    TokenName("in a card")
                    VStack(alignment: .leading, spacing: .space100) {
                        ForEach(["Inbox", "Today", "Garden"], id: \.self) { title in
                            if title != "Inbox" { Rule() }
                            Text(title)
                                .textRole(.body.regular)
                                .foregroundStyle(.text.primary)
                        }
                    }
                    .padding(.space.card)
                    .surface(.raised)
                }
            }
        }
    }
}
