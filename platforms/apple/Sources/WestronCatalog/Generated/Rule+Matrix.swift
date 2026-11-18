// Generated from spec/components/rule/rule.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Rule's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `RuleMatrixCell` draws
// each cell.

import WestronUI

extension ComponentMatrix {
    /// Rule's matrix: 2 axis at rest (the contract has no states) = 2 combinations, none forbidden by a constraint, on
    /// 1 sheet.
    static let rule = ComponentMatrix(
        component: "rule",
        options: [Option("axis", values: ["horizontal", "vertical"])],
        states: [],
        unbound: [],
        columns: "axis",
        platforms: [],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["horizontal"], state: nil),
            Combination(["vertical"], state: nil),
        ],
        sheets: [
            Sheet(
                "all",
                fixed: [],
                columns: ["horizontal", "vertical"],
                rows: [nil]
            )
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
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (axis: RuleAxis, state: String?)

    var fields: Fields { (axis, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.axis = RuleAxis(rawValue: combination.values[0])!
        self.state = combination.state
    }
}
