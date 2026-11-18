// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show Checkbox's
// states that a screenshot cannot produce: pressed and focus. Everything here is `package`, visible to the targets of
// this Swift package and never to a product that imports WestronUI: it is not public API, and the parity lint (#21)
// does not see it.

import SwiftUI

extension EnvironmentValues {
    /// States the westron Checkbox style draws in addition to the real ones. Catalog only: a product never sets it.
    @Entry var forcedCheckboxStates: Set<CheckboxState> = []
}

/// One of Checkbox's states from its contract, as the catalog names it. Catalog only.
///
/// It wraps the generated, internal `CheckboxState`, so the catalog lists the states the contract declares, in its
/// order, without a list of its own. Its properties switch exhaustively over `CheckboxState`, so a state added to or
/// renamed in the contract fails the build here instead of dropping a row from the catalog.
package struct CheckboxCatalogState: Hashable, Sendable {
    let state: CheckboxState

    /// The state's name in the contract: `checked`, `pressed`.
    package var name: String { state.rawValue }

    /// Whether the current OS ever enters the state (the contract's `platforms` block).
    package var isEntered: Bool { state.isEntered }

    /// Whether a screenshot can only show the state when the catalog forces it: pressed, focus.
    package var isForced: Bool {
        switch state {
        case .pressed, .focus: true
        case .checked, .disabled: false
        }
    }

    /// Whether the toggle is on, which the catalog sets with the toggle's own value.
    package var isChecked: Bool {
        switch state {
        case .checked: true
        case .pressed, .focus, .disabled: false
        }
    }

    /// Whether it is disabled, which the catalog sets with the system's `.disabled(_:)`.
    package var isDisabled: Bool {
        switch state {
        case .disabled: true
        case .checked, .pressed, .focus: false
        }
    }

    /// The contract's states, in its order.
    package static var all: [CheckboxCatalogState] { CheckboxState.allCases.map(CheckboxCatalogState.init) }

    /// The state with the contract's name, if the contract declares it.
    package init?(named name: String) {
        guard let state = CheckboxState(rawValue: name) else { return nil }
        self.state = state
    }

    init(_ state: CheckboxState) {
        self.state = state
    }
}

extension View {
    /// Draws the westron checks in this view as if they were also in `states`. Catalog only: it forces how a state
    /// looks, for a screenshot, and changes nothing a check does.
    package func forcingCheckboxStates(_ states: Set<CheckboxCatalogState>) -> some View {
        environment(\.forcedCheckboxStates, Set(states.map(\.state)))
    }
}
