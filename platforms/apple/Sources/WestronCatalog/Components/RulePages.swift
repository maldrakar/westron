import SwiftUI
import WestronUI

// Rule's catalog entry, from spec/components/rule/rule.spec.yaml: both axes of the real `Rule`, each between two groups
// it separates, as a product lays it out. The axes come from the generated matrix, so the page follows the contract.

extension CatalogEntry {
    static let rule = CatalogEntry(id: "rule", title: "Rule", section: .components) {
        RulePage()
    }
}

/// A rule between two groups: a horizontal one between two lines of a column, spanning its width; a vertical one
/// between two words of a row, as tall as the row, which `fixedSize` makes as tall as its text, as a bar's divider is.
struct RuleSample: View {
    let axis: RuleAxis

    var body: some View {
        switch axis {
        case .horizontal:
            VStack(alignment: .leading, spacing: .space100) {
                group("Above")
                Rule()
                group("Below")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .vertical:
            HStack(spacing: .space100) {
                group("Left")
                Rule(axis: .vertical)
                group("Right")
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

/// One cell of Rule's snapshot matrix (#24): an axis, drawn as `RuleSample`.
struct RuleMatrixCell: View {
    let values: RuleMatrixValues

    init(_ values: RuleMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here. The
        // contract has no states, so the state is always rest.
        let (axis, _) = values.fields
        RuleSample(axis: axis)
            // One element that contains the two groups' texts, so the sheet's cell identifier marks the cell once;
            // the rule itself is hidden.
            .accessibilityElement(children: .contain)
    }
}

/// Every axis of the contract, then rules in use, between the rows of a card.
private struct RulePage: View {
    var body: some View {
        TokenPage(
            title: "Rule",
            summary: "Rule() and Rule(axis: .vertical): border.default at stroke.thin across its axis, filling the "
                + "length its stack offers along it. Hidden from assistive technology."
        ) {
            VStack(alignment: .leading, spacing: .space.betweenGroups) {
                ForEach(ComponentMatrix.rule.combinations.map { RuleMatrixValues($0).fields.axis }, id: \.self) {
                    axis in
                    VStack(alignment: .leading, spacing: .space50) {
                        TokenName(axis.rawValue)
                        RuleSample(axis: axis)
                    }
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
