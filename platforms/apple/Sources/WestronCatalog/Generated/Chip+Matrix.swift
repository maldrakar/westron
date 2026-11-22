// Generated from spec/components/chip/chip.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Chip's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `ChipMatrixCell` draws
// each cell.

import WestronUI

extension ComponentMatrix {
    /// Chip's matrix: 3 form × 1 variant, each form at rest and in each state it enters alone = 12 combinations, none
    /// forbidden by a constraint, on 3 sheets.
    static let chip = ComponentMatrix(
        component: "chip",
        options: [Option("form", values: ["selectable", "pressable", "static"]), Option("variant", values: ["chip"])],
        states: ["checked", "hover", "focus", "pressed", "disabled"],
        unbound: ["focus"],
        columns: "variant",
        platforms: [Platform("watchos", drawn: [:], notEntered: ["hover", "focus"])],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["selectable", "chip"], state: nil),
            Combination(["selectable", "chip"], state: "checked"),
            Combination(["selectable", "chip"], state: "hover"),
            Combination(["selectable", "chip"], state: "focus"),
            Combination(["selectable", "chip"], state: "pressed"),
            Combination(["selectable", "chip"], state: "disabled"),
            Combination(["pressable", "chip"], state: nil),
            Combination(["pressable", "chip"], state: "hover"),
            Combination(["pressable", "chip"], state: "focus"),
            Combination(["pressable", "chip"], state: "pressed"),
            Combination(["pressable", "chip"], state: "disabled"),
            Combination(["static", "chip"], state: nil),
        ],
        sheets: [
            Sheet(
                "form-selectable",
                fixed: ["selectable"],
                columns: ["chip"],
                rows: [nil, "checked", "hover", "focus", "pressed", "disabled"]
            ),
            Sheet(
                "form-pressable",
                fixed: ["pressable"],
                columns: ["chip"],
                rows: [nil, "hover", "focus", "pressed", "disabled"]
            ),
            Sheet(
                "form-static",
                fixed: ["static"],
                columns: ["chip"],
                rows: [nil]
            ),
        ]
    ) { ChipMatrixCell(ChipMatrixValues($0)) }
}

/// One combination of Chip's matrix, typed for `ChipMatrixCell`: the generated enum of each enum option, `Bool` for a
/// bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
struct ChipMatrixValues {
    /// The form: the system control the cell styles (the contract's `forms`).
    private let form: ChipForm
    private let variant: ChipVariant
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (form: ChipForm, variant: ChipVariant, state: String?)

    var fields: Fields { (form, variant, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.form = ChipForm(rawValue: combination.values[0])!
        self.variant = ChipVariant(rawValue: combination.values[1])!
        self.state = combination.state
    }
}
