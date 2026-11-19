// Generated from spec/components/icon/icon.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Icon's snapshot matrix (#24): its options, its states, the combinations its constraints allow, what each Apple OS
// draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. The hand-written `IconMatrixCell` draws
// each cell.

import WestronUI

extension ComponentMatrix {
    /// Icon's matrix: 36 glyph × 3 scale at rest (the contract has no states; glyph runs down the rows) = 108
    /// combinations, none forbidden by a constraint, on 6 sheets.
    static let icon = ComponentMatrix(
        component: "icon",
        options: [
            Option(
                "glyph",
                values: [
                    "tray",
                    "sun",
                    "calendar",
                    "week",
                    "logbook",
                    "trash",
                    "briefcase",
                    "house",
                    "hourglass",
                    "pen",
                    "bag",
                    "wrench",
                    "book",
                    "folder",
                    "list",
                    "bullets",
                    "ellipsis",
                    "plus",
                    "check",
                    "chevron",
                    "grip",
                    "magnifier",
                    "microphone",
                    "newWindow",
                    "checkCircle",
                    "divider",
                    "flag",
                    "hash",
                    "note",
                    "expand",
                    "columns",
                    "chevronLeft",
                    "checkCircleFill",
                    "xmarkCircleFill",
                    "exclamationTriangleFill",
                    "infoCircleFill",
                ]
            ),
            Option("scale", values: ["small", "medium", "large"], system: "SwiftUI.Image.Scale"),
        ],
        states: [],
        unbound: [],
        columns: "scale",
        rows: "glyph",
        platforms: [],
        excluded: [],
        advisedAgainst: [],
        combinations: [
            Combination(["tray", "small"], state: nil),
            Combination(["tray", "medium"], state: nil),
            Combination(["tray", "large"], state: nil),
            Combination(["sun", "small"], state: nil),
            Combination(["sun", "medium"], state: nil),
            Combination(["sun", "large"], state: nil),
            Combination(["calendar", "small"], state: nil),
            Combination(["calendar", "medium"], state: nil),
            Combination(["calendar", "large"], state: nil),
            Combination(["week", "small"], state: nil),
            Combination(["week", "medium"], state: nil),
            Combination(["week", "large"], state: nil),
            Combination(["logbook", "small"], state: nil),
            Combination(["logbook", "medium"], state: nil),
            Combination(["logbook", "large"], state: nil),
            Combination(["trash", "small"], state: nil),
            Combination(["trash", "medium"], state: nil),
            Combination(["trash", "large"], state: nil),
            Combination(["briefcase", "small"], state: nil),
            Combination(["briefcase", "medium"], state: nil),
            Combination(["briefcase", "large"], state: nil),
            Combination(["house", "small"], state: nil),
            Combination(["house", "medium"], state: nil),
            Combination(["house", "large"], state: nil),
            Combination(["hourglass", "small"], state: nil),
            Combination(["hourglass", "medium"], state: nil),
            Combination(["hourglass", "large"], state: nil),
            Combination(["pen", "small"], state: nil),
            Combination(["pen", "medium"], state: nil),
            Combination(["pen", "large"], state: nil),
            Combination(["bag", "small"], state: nil),
            Combination(["bag", "medium"], state: nil),
            Combination(["bag", "large"], state: nil),
            Combination(["wrench", "small"], state: nil),
            Combination(["wrench", "medium"], state: nil),
            Combination(["wrench", "large"], state: nil),
            Combination(["book", "small"], state: nil),
            Combination(["book", "medium"], state: nil),
            Combination(["book", "large"], state: nil),
            Combination(["folder", "small"], state: nil),
            Combination(["folder", "medium"], state: nil),
            Combination(["folder", "large"], state: nil),
            Combination(["list", "small"], state: nil),
            Combination(["list", "medium"], state: nil),
            Combination(["list", "large"], state: nil),
            Combination(["bullets", "small"], state: nil),
            Combination(["bullets", "medium"], state: nil),
            Combination(["bullets", "large"], state: nil),
            Combination(["ellipsis", "small"], state: nil),
            Combination(["ellipsis", "medium"], state: nil),
            Combination(["ellipsis", "large"], state: nil),
            Combination(["plus", "small"], state: nil),
            Combination(["plus", "medium"], state: nil),
            Combination(["plus", "large"], state: nil),
            Combination(["check", "small"], state: nil),
            Combination(["check", "medium"], state: nil),
            Combination(["check", "large"], state: nil),
            Combination(["chevron", "small"], state: nil),
            Combination(["chevron", "medium"], state: nil),
            Combination(["chevron", "large"], state: nil),
            Combination(["grip", "small"], state: nil),
            Combination(["grip", "medium"], state: nil),
            Combination(["grip", "large"], state: nil),
            Combination(["magnifier", "small"], state: nil),
            Combination(["magnifier", "medium"], state: nil),
            Combination(["magnifier", "large"], state: nil),
            Combination(["microphone", "small"], state: nil),
            Combination(["microphone", "medium"], state: nil),
            Combination(["microphone", "large"], state: nil),
            Combination(["newWindow", "small"], state: nil),
            Combination(["newWindow", "medium"], state: nil),
            Combination(["newWindow", "large"], state: nil),
            Combination(["checkCircle", "small"], state: nil),
            Combination(["checkCircle", "medium"], state: nil),
            Combination(["checkCircle", "large"], state: nil),
            Combination(["divider", "small"], state: nil),
            Combination(["divider", "medium"], state: nil),
            Combination(["divider", "large"], state: nil),
            Combination(["flag", "small"], state: nil),
            Combination(["flag", "medium"], state: nil),
            Combination(["flag", "large"], state: nil),
            Combination(["hash", "small"], state: nil),
            Combination(["hash", "medium"], state: nil),
            Combination(["hash", "large"], state: nil),
            Combination(["note", "small"], state: nil),
            Combination(["note", "medium"], state: nil),
            Combination(["note", "large"], state: nil),
            Combination(["expand", "small"], state: nil),
            Combination(["expand", "medium"], state: nil),
            Combination(["expand", "large"], state: nil),
            Combination(["columns", "small"], state: nil),
            Combination(["columns", "medium"], state: nil),
            Combination(["columns", "large"], state: nil),
            Combination(["chevronLeft", "small"], state: nil),
            Combination(["chevronLeft", "medium"], state: nil),
            Combination(["chevronLeft", "large"], state: nil),
            Combination(["checkCircleFill", "small"], state: nil),
            Combination(["checkCircleFill", "medium"], state: nil),
            Combination(["checkCircleFill", "large"], state: nil),
            Combination(["xmarkCircleFill", "small"], state: nil),
            Combination(["xmarkCircleFill", "medium"], state: nil),
            Combination(["xmarkCircleFill", "large"], state: nil),
            Combination(["exclamationTriangleFill", "small"], state: nil),
            Combination(["exclamationTriangleFill", "medium"], state: nil),
            Combination(["exclamationTriangleFill", "large"], state: nil),
            Combination(["infoCircleFill", "small"], state: nil),
            Combination(["infoCircleFill", "medium"], state: nil),
            Combination(["infoCircleFill", "large"], state: nil),
        ],
        sheets: [
            Sheet(
                "all_rows-1",
                fixed: [],
                columns: ["small", "medium", "large"],
                rows: ["tray", "sun", "calendar", "week", "logbook", "trash"]
            ),
            Sheet(
                "all_rows-2",
                fixed: [],
                columns: ["small", "medium", "large"],
                rows: ["briefcase", "house", "hourglass", "pen", "bag", "wrench"]
            ),
            Sheet(
                "all_rows-3",
                fixed: [],
                columns: ["small", "medium", "large"],
                rows: ["book", "folder", "list", "bullets", "ellipsis", "plus"]
            ),
            Sheet(
                "all_rows-4",
                fixed: [],
                columns: ["small", "medium", "large"],
                rows: ["check", "chevron", "grip", "magnifier", "microphone", "newWindow"]
            ),
            Sheet(
                "all_rows-5",
                fixed: [],
                columns: ["small", "medium", "large"],
                rows: ["checkCircle", "divider", "flag", "hash", "note", "expand"]
            ),
            Sheet(
                "all_rows-6",
                fixed: [],
                columns: ["small", "medium", "large"],
                rows: [
                    "columns", "chevronLeft", "checkCircleFill", "xmarkCircleFill", "exclamationTriangleFill",
                    "infoCircleFill",
                ]
            ),
        ]
    ) { IconMatrixCell(IconMatrixValues($0)) }
}

/// One combination of Icon's matrix, typed for `IconMatrixCell`: the generated enum of each enum option, `Bool` for a
/// bool option, and the contract's value of an option that is the system's own API.
///
/// The values are private: a cell takes them all at once from `fields`, so an option added to the contract changes the
/// tuple and fails the cell's build until it draws the option too.
///
/// An option whose values are icons is the icon itself, as `Westron.Icon`.
struct IconMatrixValues {
    private let glyph: Westron.Icon
    /// The contract's value of `scale`, which is the system's `SwiftUI.Image.Scale`.
    private let scale: String
    /// The state; nil at rest.
    private let state: String?

    /// Every value, in the contract's order of the options, then the state.
    typealias Fields = (glyph: Westron.Icon, scale: String, state: String?)

    var fields: Fields { (glyph, scale, state) }

    init(_ combination: ComponentMatrix.Combination) {
        self.glyph = Westron.Icon(rawValue: combination.values[0])!
        self.scale = combination.values[1]
        self.state = combination.state
    }
}
