// Generated from spec/components/list-row/list-row.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// ListRow's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `ListRowMatrixCell`
// draws each cell.

import WestronUI

extension ComponentMatrix {
    /// ListRow's matrix: 2 form × 2 guides, each form at rest and in each state it enters alone = 26 combinations, none
    /// forbidden by a constraint, on 3 sheets.
    static let listRow = ComponentMatrix(
        component: "list-row",
        options: [Option("form", values: ["pressable", "static"]), Option("guides", values: ["false", "true"])],
        states: ["hover", "focus", "pressed", "selected", "chosen", "disabled", "dropTarget"],
        unbound: ["focus", "chosen"],
        columns: "guides",
        platforms: [Platform("watchos", drawn: [:], notEntered: ["hover", "focus", "dropTarget"])],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["pressable", "false"], state: nil),
            Combination(["pressable", "false"], state: "hover"),
            Combination(["pressable", "false"], state: "focus"),
            Combination(["pressable", "false"], state: "pressed"),
            Combination(["pressable", "false"], state: "selected"),
            Combination(["pressable", "false"], state: "chosen"),
            Combination(["pressable", "false"], state: "disabled"),
            Combination(["pressable", "false"], state: "dropTarget"),
            Combination(["pressable", "true"], state: nil),
            Combination(["pressable", "true"], state: "hover"),
            Combination(["pressable", "true"], state: "focus"),
            Combination(["pressable", "true"], state: "pressed"),
            Combination(["pressable", "true"], state: "selected"),
            Combination(["pressable", "true"], state: "chosen"),
            Combination(["pressable", "true"], state: "disabled"),
            Combination(["pressable", "true"], state: "dropTarget"),
            Combination(["static", "false"], state: nil),
            Combination(["static", "false"], state: "selected"),
            Combination(["static", "false"], state: "chosen"),
            Combination(["static", "false"], state: "disabled"),
            Combination(["static", "false"], state: "dropTarget"),
            Combination(["static", "true"], state: nil),
            Combination(["static", "true"], state: "selected"),
            Combination(["static", "true"], state: "chosen"),
            Combination(["static", "true"], state: "disabled"),
            Combination(["static", "true"], state: "dropTarget"),
        ],
        sheets: [
            Sheet(
                "form-pressable_rows-1",
                fixed: ["pressable"],
                columns: ["false", "true"],
                rows: [nil, "hover", "focus", "pressed", "selected", "chosen"]
            ),
            Sheet(
                "form-pressable_rows-2",
                fixed: ["pressable"],
                columns: ["false", "true"],
                rows: ["disabled", "dropTarget"]
            ),
            Sheet(
                "form-static",
                fixed: ["static"],
                columns: ["false", "true"],
                rows: [nil, "selected", "chosen", "disabled", "dropTarget"]
            ),
        ]
    ) { ListRowMatrixCell(ListRowMatrixValues($0)) }
}

/// One combination of ListRow's matrix, typed for `ListRowMatrixCell`: the generated enum of each enum option, `Bool`
/// for a bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
struct ListRowMatrixValues {
    /// The form: the initializer the cell calls (the contract's `forms`).
    private let form: ListRowForm
    private let guides: Bool
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (form: ListRowForm, guides: Bool, state: String?)

    var fields: Fields { (form, guides, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.form = ListRowForm(rawValue: combination.values[0])!
        self.guides = combination.values[1] == "true"
        self.state = combination.state
    }
}
