// Generated from spec/components/text-field/text-field.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// TextField's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple
// OS draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written
// `TextFieldMatrixCell` draws each cell.

import WestronUI

extension ComponentMatrix {
    /// TextField's matrix: 2 variant × 3 size × 2 lines × 3 states (rest and each state alone) = 36 combinations, none
    /// forbidden by a constraint, on 6 sheets.
    static let textField = ComponentMatrix(
        component: "text-field",
        options: [
            Option("variant", values: ["framed", "inline"]),
            Option("size", values: ["s", "m", "l"]),
            Option("lines", values: ["single", "multiple"], system: "SwiftUI.Axis"),
        ],
        states: ["focus", "disabled"],
        unbound: [],
        columns: "variant",
        platforms: [Platform("watchos", drawn: ["size": ["s": "m", "l": "m"]], notEntered: ["focus"])],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["framed", "s", "single"], state: nil),
            Combination(["framed", "s", "single"], state: "focus"),
            Combination(["framed", "s", "single"], state: "disabled"),
            Combination(["framed", "s", "multiple"], state: nil),
            Combination(["framed", "s", "multiple"], state: "focus"),
            Combination(["framed", "s", "multiple"], state: "disabled"),
            Combination(["framed", "m", "single"], state: nil),
            Combination(["framed", "m", "single"], state: "focus"),
            Combination(["framed", "m", "single"], state: "disabled"),
            Combination(["framed", "m", "multiple"], state: nil),
            Combination(["framed", "m", "multiple"], state: "focus"),
            Combination(["framed", "m", "multiple"], state: "disabled"),
            Combination(["framed", "l", "single"], state: nil),
            Combination(["framed", "l", "single"], state: "focus"),
            Combination(["framed", "l", "single"], state: "disabled"),
            Combination(["framed", "l", "multiple"], state: nil),
            Combination(["framed", "l", "multiple"], state: "focus"),
            Combination(["framed", "l", "multiple"], state: "disabled"),
            Combination(["inline", "s", "single"], state: nil),
            Combination(["inline", "s", "single"], state: "focus"),
            Combination(["inline", "s", "single"], state: "disabled"),
            Combination(["inline", "s", "multiple"], state: nil),
            Combination(["inline", "s", "multiple"], state: "focus"),
            Combination(["inline", "s", "multiple"], state: "disabled"),
            Combination(["inline", "m", "single"], state: nil),
            Combination(["inline", "m", "single"], state: "focus"),
            Combination(["inline", "m", "single"], state: "disabled"),
            Combination(["inline", "m", "multiple"], state: nil),
            Combination(["inline", "m", "multiple"], state: "focus"),
            Combination(["inline", "m", "multiple"], state: "disabled"),
            Combination(["inline", "l", "single"], state: nil),
            Combination(["inline", "l", "single"], state: "focus"),
            Combination(["inline", "l", "single"], state: "disabled"),
            Combination(["inline", "l", "multiple"], state: nil),
            Combination(["inline", "l", "multiple"], state: "focus"),
            Combination(["inline", "l", "multiple"], state: "disabled"),
        ],
        sheets: [
            Sheet(
                "size-s_lines-single",
                fixed: ["s", "single"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-s_lines-multiple",
                fixed: ["s", "multiple"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-m_lines-single",
                fixed: ["m", "single"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-m_lines-multiple",
                fixed: ["m", "multiple"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-l_lines-single",
                fixed: ["l", "single"],
                columns: ["framed", "inline"],
                rows: [nil, "focus", "disabled"]
            ),
            Sheet(
                "size-l_lines-multiple",
                fixed: ["l", "multiple"],
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
    /// The contract's value of `lines`, which is the system's `SwiftUI.Axis`.
    private let lines: String
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (variant: TextFieldVariant, size: TextFieldSize, lines: String, state: String?)

    var fields: Fields { (variant, size, lines, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.variant = TextFieldVariant(rawValue: combination.values[0])!
        self.size = TextFieldSize(rawValue: combination.values[1])!
        self.lines = combination.values[2]
        self.state = combination.state
    }
}
