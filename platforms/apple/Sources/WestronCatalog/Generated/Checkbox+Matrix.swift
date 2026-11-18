// Generated from spec/components/checkbox/checkbox.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Checkbox's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `CheckboxMatrixCell`
// draws each cell.

import WestronUI

extension ComponentMatrix {
    /// Checkbox's matrix: 1 variant × 5 states (rest and each state alone) = 5 combinations, none forbidden by a
    /// constraint, on 1 sheets.
    static let checkbox = ComponentMatrix(
        component: "checkbox",
        options: [Option("variant", values: ["check"])],
        states: ["checked", "pressed", "focus", "disabled"],
        unbound: ["pressed", "focus"],
        columns: "variant",
        platforms: [Platform("watchos", drawn: [:], notEntered: ["focus"])],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["check"], state: nil),
            Combination(["check"], state: "checked"),
            Combination(["check"], state: "pressed"),
            Combination(["check"], state: "focus"),
            Combination(["check"], state: "disabled"),
        ],
        sheets: [
            Sheet(
                "all",
                fixed: [],
                columns: ["check"],
                rows: [nil, "checked", "pressed", "focus", "disabled"]
            )
        ]
    ) { CheckboxMatrixCell(CheckboxMatrixValues($0)) }
}

/// One combination of Checkbox's matrix, typed for `CheckboxMatrixCell`: the generated enum of each enum option, `Bool`
/// for a bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
struct CheckboxMatrixValues {
    private let variant: CheckboxVariant
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (variant: CheckboxVariant, state: String?)

    var fields: Fields { (variant, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.variant = CheckboxVariant(rawValue: combination.values[0])!
        self.state = combination.state
    }
}
