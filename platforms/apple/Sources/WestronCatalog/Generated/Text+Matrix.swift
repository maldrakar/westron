// Generated from spec/components/text/text.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Text's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `TextMatrixCell` draws
// each cell.

import WestronUI

extension ComponentMatrix {
    /// Text's matrix: 17 role at rest (the contract has no states) = 17 combinations, none forbidden by a constraint,
    /// on 6 sheets.
    static let text = ComponentMatrix(
        component: "text",
        options: [
            Option(
                "role",
                values: [
                    "heading.large",
                    "heading.medium",
                    "heading.small",
                    "heading.overline",
                    "body.regular",
                    "body.strong",
                    "callout.regular",
                    "callout.strong",
                    "subheadline.regular",
                    "subheadline.medium",
                    "subheadline.strong",
                    "footnote.regular",
                    "footnote.medium",
                    "footnote.strong",
                    "caption.medium",
                    "code.regular",
                    "code.strong",
                ]
            )
        ],
        states: [],
        unbound: [],
        columns: "role",
        platforms: [],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["heading.large"], state: nil),
            Combination(["heading.medium"], state: nil),
            Combination(["heading.small"], state: nil),
            Combination(["heading.overline"], state: nil),
            Combination(["body.regular"], state: nil),
            Combination(["body.strong"], state: nil),
            Combination(["callout.regular"], state: nil),
            Combination(["callout.strong"], state: nil),
            Combination(["subheadline.regular"], state: nil),
            Combination(["subheadline.medium"], state: nil),
            Combination(["subheadline.strong"], state: nil),
            Combination(["footnote.regular"], state: nil),
            Combination(["footnote.medium"], state: nil),
            Combination(["footnote.strong"], state: nil),
            Combination(["caption.medium"], state: nil),
            Combination(["code.regular"], state: nil),
            Combination(["code.strong"], state: nil),
        ],
        sheets: [
            Sheet(
                "all_columns-1",
                fixed: [],
                columns: ["heading.large", "heading.medium", "heading.small"],
                rows: [nil]
            ),
            Sheet(
                "all_columns-2",
                fixed: [],
                columns: ["heading.overline", "body.regular", "body.strong"],
                rows: [nil]
            ),
            Sheet(
                "all_columns-3",
                fixed: [],
                columns: ["callout.regular", "callout.strong", "subheadline.regular"],
                rows: [nil]
            ),
            Sheet(
                "all_columns-4",
                fixed: [],
                columns: ["subheadline.medium", "subheadline.strong", "footnote.regular"],
                rows: [nil]
            ),
            Sheet(
                "all_columns-5",
                fixed: [],
                columns: ["footnote.medium", "footnote.strong", "caption.medium"],
                rows: [nil]
            ),
            Sheet(
                "all_columns-6",
                fixed: [],
                columns: ["code.regular", "code.strong"],
                rows: [nil]
            ),
        ]
    ) { TextMatrixCell(TextMatrixValues($0)) }
}

/// One combination of Text's matrix, typed for `TextMatrixCell`: the generated enum of each enum option, `Bool` for a
/// bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
///
/// An option whose values are tokens is the token itself, as its accessor: the cell applies it as a product does.
struct TextMatrixValues {
    private let role: Westron.TextRole
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (role: Westron.TextRole, state: String?)

    var fields: Fields { (role, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.role = Self.roleTokens[combination.values[0]]!
        self.state = combination.state
    }

    /// The token of each value of `role`, by its path after `typography`.
    private static let roleTokens: [String: Westron.TextRole] = [
        "heading.large": .heading.large,
        "heading.medium": .heading.medium,
        "heading.small": .heading.small,
        "heading.overline": .heading.overline,
        "body.regular": .body.regular,
        "body.strong": .body.strong,
        "callout.regular": .callout.regular,
        "callout.strong": .callout.strong,
        "subheadline.regular": .subheadline.regular,
        "subheadline.medium": .subheadline.medium,
        "subheadline.strong": .subheadline.strong,
        "footnote.regular": .footnote.regular,
        "footnote.medium": .footnote.medium,
        "footnote.strong": .footnote.strong,
        "caption.medium": .caption.medium,
        "code.regular": .code.regular,
        "code.strong": .code.strong,
    ]
}
