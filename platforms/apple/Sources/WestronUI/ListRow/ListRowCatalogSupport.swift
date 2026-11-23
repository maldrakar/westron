// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show ListRow's
// states that a screenshot cannot produce, hover, focus and pressed; and for the unit tests, a view in the Disclosure
// chevron's place (#120). Everything here is `package`, visible to the targets of this Swift package
// and never to a product that imports WestronUI: it is not public API, and the parity lint (#21) does not see it.

import SwiftUI

extension EnvironmentValues {
    /// States the westron ListRow draws in addition to the real ones. Catalog only: a product never sets it.
    @Entry var forcedListRowStates: Set<ListRowState> = []
}

/// One of ListRow's states from its contract, as the catalog names it. Catalog only.
///
/// It wraps the generated, internal `ListRowState`, so the catalog lists the states the contract declares, in its
/// order, without a list of its own. Its properties switch exhaustively over `ListRowState`, so a state added to or
/// renamed in the contract fails the build here instead of dropping a row from the catalog.
package struct ListRowCatalogState: Hashable, Sendable {
    let state: ListRowState

    /// The state's name in the contract: `hover`, `dropTarget`.
    package var name: String { state.rawValue }

    /// Whether the current OS ever enters the state (the contract's `platforms` block).
    package var isEntered: Bool { state.isEntered }

    /// Whether a screenshot can only show the state when the catalog forces it: hover, focus, pressed.
    package var isForced: Bool {
        switch state {
        case .hover, .focus, .pressed: true
        case .selected, .disabled, .dropTarget: false
        }
    }

    /// Whether the catalog sets it with `.selected(_:)`.
    package var isSelected: Bool { state == .selected }

    /// Whether the catalog sets it with the system's `.disabled(_:)`.
    package var isDisabled: Bool { state == .disabled }

    /// Whether the catalog sets it with `.dropTarget(_:)`.
    package var isDropTarget: Bool { state == .dropTarget }

    /// Whether the form enters the state (the contract's `forms`).
    package func isEntered(by form: ListRowForm) -> Bool { form.states.contains(state) }

    /// The contract's states, in its order.
    package static var all: [ListRowCatalogState] { ListRowState.allCases.map(ListRowCatalogState.init) }

    /// The state with the contract's name, if the contract declares it.
    package init?(named name: String) {
        guard let state = ListRowState(rawValue: name) else { return nil }
        self.state = state
    }

    init(_ state: ListRowState) {
        self.state = state
    }
}

extension View {
    /// Puts the westron rows in this view into `state`: hover, focus and pressed forced, as a screenshot cannot produce
    /// them; selected, disabled and dropTarget through their real modifiers. nil: at rest. Catalog only: forcing
    /// changes how a state looks, for a screenshot, and nothing a row does.
    package func listRowCatalogState(_ state: ListRowCatalogState?) -> some View {
        // selected and dropTarget only ever turn on here, so that a selection set around the cell, as a supplement's
        // `.selected(true)`, holds in every state; `.disabled(false)` never enables what is disabled around it.
        environment(\.forcedListRowStates, state.map { $0.isForced ? [$0.state] : [] } ?? [])
            .transformEnvironment(\.isSelected) { if state?.isSelected == true { $0 = true } }
            .transformEnvironment(\.isDropTarget) { if state?.isDropTarget == true { $0 = true } }
            .disabled(state?.isDisabled ?? false)
    }

    /// Hands the westron row in this view a view in the Disclosure chevron's place, as westron's chevron style on a
    /// `DisclosureGroup` hands it its cell (#120), so that a unit test measures the place with a frame of its own.
    /// Tests only.
    package func listRowDisclosureCell<Cell: View>(@ViewBuilder _ cell: () -> Cell) -> some View {
        environment(\.listRowDisclosureCell, AnyView(cell()))
    }

    /// Tells `observer` when a westron row in this view begins (true) and ends (false) a press of its system Button:
    /// the catalog counts them, so that a UI test sees whether a press on a slot's control also presses the row.
    /// Catalog only.
    package func listRowPressObserver(_ observer: @escaping @MainActor @Sendable (Bool) -> Void) -> some View {
        environment(\.listRowPressObserver, observer)
    }
}
