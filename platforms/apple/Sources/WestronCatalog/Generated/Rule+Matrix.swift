// Generated from spec/components/rule/rule.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Rule's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `RuleMatrixCell` draws
// each cell.

import WestronUI

extension ComponentMatrix {
    /// Rule's matrix: 2 axis × 2 purpose at rest (the contract has no states) = 4 combinations, none forbidden by a
    /// constraint, on 2 sheets.
    static let rule = ComponentMatrix(
        component: "rule",
        options: [
            Option("axis", values: ["horizontal", "vertical"]),
            Option("purpose", values: ["separator", "insertion"]),
        ],
        states: [],
        unbound: [],
        columns: "axis",
        platforms: [],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["horizontal", "separator"], state: nil),
            Combination(["horizontal", "insertion"], state: nil),
            Combination(["vertical", "separator"], state: nil),
            Combination(["vertical", "insertion"], state: nil),
        ],
        sheets: [
            Sheet(
                "purpose-separator",
                fixed: ["separator"],
                columns: ["horizontal", "vertical"],
                rows: [nil]
            ),
            Sheet(
                "purpose-insertion",
                fixed: ["insertion"],
                columns: ["horizontal", "vertical"],
                rows: [nil]
            ),
        ]
    ) { RuleMatrixCell(RuleMatrixValues($0)) }
}

/// One combination of Rule's matrix, typed for `RuleMatrixCell`: the generated enum of each enum option, `Bool` for a
/// bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
struct RuleMatrixValues {
    private let axis: RuleAxis
    private let purpose: RulePurpose
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (axis: RuleAxis, purpose: RulePurpose, state: String?)

    var fields: Fields { (axis, purpose, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.axis = RuleAxis(rawValue: combination.values[0])!
        self.purpose = RulePurpose(rawValue: combination.values[1])!
        self.state = combination.state
    }
}
