// Generated from spec/components/text-field/text-field.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// TextField's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple
// OS draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written
// `TextFieldMatrixCell` draws each cell.

import WestronUI

extension ComponentMatrix {
    /// TextField's matrix: 2 variant × 3 size × 3 states (rest and each state alone) = 18 combinations, none forbidden
    /// by a constraint, on 3 sheets.
    static let textField = ComponentMatrix(
        component: "text-field",
        options: [Option("variant", values: ["framed", "inline"]), Option("size", values: ["s", "m", "l"])],
        states: ["focus", "disabled"],
        unbound: [],
        columns: "variant",
        platforms: [Platform("watchos", drawn: ["size": ["s": "m", "l": "m"]], notEntered: ["focus"])],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["framed", "s"], state: nil),
            Combination(["framed", "s"], state: "focus"),
            Combination(["framed", "s"], state: "disabled"),
            Combination(["framed", "m"], state: nil),
            Combination(["framed", "m"], state: "focus"),
            Combination(["framed", "m"], state: "disabled"),
            Combination(["framed", "l"], state: nil),
            Combination(["framed", "l"], state: "focus"),
            Combination(["framed", "l"], state: "disabled"),
            Combination(["inline", "s"], state: nil),
            Combination(["inline", "s"], state: "focus"),
            Combination(["inline", "s"], state: "disabled"),
            Combination(["inline", "m"], state: nil),
            Combination(["inline", "m"], state: "focus"),
            Combination(["inline", "m"], state: "disabled"),
            Combination(["inline", "l"], state: nil),
            Combination(["inline", "l"], state: "focus"),
            Combination(["inline", "l"], state: "disabled"),
        ],
        sheets: [
            Sheet(
                "size-s",
                fixed: ["s"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-m",
                fixed: ["m"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-l",
                fixed: ["l"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
        ]
    ) { TextFieldMatrixCell(TextFieldMatrixValues($0)) }
}

/// One combination of TextField's matrix, typed for `TextFieldMatrixCell`: the generated enum of each enum option,
/// `Bool` for a bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
struct TextFieldMatrixValues {
    private let variant: TextFieldVariant
    private let size: TextFieldSize
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (variant: TextFieldVariant, size: TextFieldSize, state: String?)

    var fields: Fields { (variant, size, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.variant = TextFieldVariant(rawValue: combination.values[0])!
        self.size = TextFieldSize(rawValue: combination.values[1])!
        self.state = combination.state
    }
}
