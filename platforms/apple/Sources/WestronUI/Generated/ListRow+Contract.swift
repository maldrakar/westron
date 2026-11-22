// Generated from spec/components/list-row/list-row.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// ListRow's API from its contract: the enums of its marks' parameters, its states and its forms. It is an own
// component, and the view `ListRow` and its initializers, the modifier `insertionMark`, the state modifier `selected`
// and the state modifier `dropTarget` are hand-written in WestronUI/; the API parity lint holds their signatures to the
// contract (spec/conventions.md, "Own components").

/// The parameter `edge` of ListRow's mark `insertion`, from its contract: `.insertionMark(…)`, hand-written in
/// WestronUI/ListRow/.
///
/// The edge of the row the mark is drawn over.
public enum ListRowInsertionEdge: String, CaseIterable, Sendable {
    case top
    case bottom
}

/// The states of a ListRow in its contract, in its order. The view carries hover, focus, pressed, disabled itself; the
/// others are set through the environment (spec/conventions.md).
///
/// Not entered: on watchOS, hover, focus, dropTarget (the contract's `platforms` block).
enum ListRowState: String, CaseIterable, Sendable {
    case hover
    case focus
    case pressed
    case selected
    case disabled
    case dropTarget

    /// Whether the current OS ever enters the state.
    var isEntered: Bool {
        #if os(watchOS)
            switch self {
            case .hover: return false
            case .focus: return false
            case .pressed: return true
            case .selected: return true
            case .disabled: return true
            case .dropTarget: return false
            }
        #else
            return true
        #endif
    }
}

/// The forms of a ListRow in its contract, in its order, each an initializer of the view (spec/conventions.md, "Own
/// components"): pressable, with an action; static, without one.
package enum ListRowForm: String, CaseIterable, Sendable {
    case pressable
    case `static`

    /// Whether a person acts on the form: its initializer takes `action`.
    var takesAction: Bool {
        switch self {
        case .pressable: true
        case .static: false
        }
    }

    /// The states the form enters (the contract's `forms`).
    var states: Set<ListRowState> {
        switch self {
        case .pressable: [.hover, .focus, .pressed, .selected, .disabled, .dropTarget]
        case .static: [.selected, .disabled, .dropTarget]
        }
    }
}
