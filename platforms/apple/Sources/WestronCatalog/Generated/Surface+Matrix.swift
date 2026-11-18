// Generated from spec/components/surface/surface.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Surface's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `SurfaceMatrixCell`
// draws each cell.

import WestronUI

extension ComponentMatrix {
    /// Surface's matrix: 3 variant × 2 outlined at rest (the contract has no states) = 6 combinations, none forbidden
    /// by a constraint, on 2 sheets.
    static let surface = ComponentMatrix(
        component: "surface",
        options: [
            Option("variant", values: ["raised", "dragged", "sunken"]),
            Option("outlined", values: ["false", "true"]),
        ],
        states: [],
        unbound: [],
        columns: "variant",
        platforms: [],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["raised", "false"], state: nil),
            Combination(["raised", "true"], state: nil),
            Combination(["dragged", "false"], state: nil),
            Combination(["dragged", "true"], state: nil),
            Combination(["sunken", "false"], state: nil),
            Combination(["sunken", "true"], state: nil),
        ],
        sheets: [
            Sheet(
                "outlined-false",
                fixed: ["false"],
                columns: ["raised", "dragged", "sunken"],
                rows: [nil]
            ),
            Sheet(
                "outlined-true",
                fixed: ["true"],
                columns: ["raised", "dragged", "sunken"],
                rows: [nil]
            ),
        ]
    ) { SurfaceMatrixCell(SurfaceMatrixValues($0)) }
}

/// One combination of Surface's matrix, typed for `SurfaceMatrixCell`: the generated enum of each enum option, `Bool`
/// for a bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
struct SurfaceMatrixValues {
    private let variant: SurfaceVariant
    private let outlined: Bool
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (variant: SurfaceVariant, outlined: Bool, state: String?)

    var fields: Fields { (variant, outlined, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.variant = SurfaceVariant(rawValue: combination.values[0])!
        self.outlined = combination.values[1] == "true"
        self.state = combination.state
    }
}
