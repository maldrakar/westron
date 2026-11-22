// Generated from spec/components/disclosure/disclosure.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Disclosure's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple
// OS draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written
// `DisclosureMatrixCell` draws each cell.

import WestronUI

#if !os(watchOS)
    extension ComponentMatrix {
        /// Disclosure's matrix: 1 variant × 6 states (rest and each state alone) = 6 combinations, none forbidden by a
        /// constraint, on 1 sheet.
        static let disclosure = ComponentMatrix(
            component: "disclosure",
            options: [Option("variant", values: ["chevron"])],
            states: ["expanded", "hover", "focus", "pressed", "disabled"],
            unbound: ["expanded", "focus"],
            columns: "variant",
            platforms: [],
            excluded: [],
            advisedAgainst: [],
            combinations: [
                Combination(["chevron"], state: nil),
                Combination(["chevron"], state: "expanded"),
                Combination(["chevron"], state: "hover"),
                Combination(["chevron"], state: "focus"),
                Combination(["chevron"], state: "pressed"),
                Combination(["chevron"], state: "disabled"),
            ],
            sheets: [
                Sheet(
                    "all",
                    fixed: [],
                    columns: ["chevron"],
                    rows: [nil, "expanded", "hover", "focus", "pressed", "disabled"]
                )
            ]
        ) { DisclosureMatrixCell(DisclosureMatrixValues($0)) }
    }

    /// One combination of Disclosure's matrix, typed for `DisclosureMatrixCell`: the generated enum of each enum
    /// option, `Bool` for a bool option, and the contract's value of an option that is the system's own API.
    ///
    /// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes
    /// the tuple and fails the cell's build until it draws the option too.
    struct DisclosureMatrixValues {
        private let variant: DisclosureVariant
        /// The state; nil at rest.
        private let state: String?

        /// Every value, in the contract's order of the options, then the state.
        typealias Fields = (variant: DisclosureVariant, state: String?)

        var fields: Fields { (variant, state) }

        init(_ combination: ComponentMatrix.Combination) {
            self.variant = DisclosureVariant(rawValue: combination.values[0])!
            self.state = combination.state
        }
    }
#endif
