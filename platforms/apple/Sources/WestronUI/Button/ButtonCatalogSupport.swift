// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show Button's states
// that a screenshot cannot produce, hover, pressed and focus. Everything here is `package`, visible to the targets of
// this Swift package and never to a product that imports WestronUI: it is not public API, and the parity lint (#21)
// does not see it.

import SwiftUI

extension EnvironmentValues {
    /// States the westron Button style draws in addition to the real ones. Catalog only: a product never sets it.
    @Entry var forcedButtonStates: Set<ButtonState> = []
}

/// One of Button's states from its contract, as the catalog names it. Catalog only.
///
/// It wraps the generated, internal `ButtonState`, so the catalog lists the states the contract declares, in its
/// order, without a list of its own.
package struct ButtonCatalogState: Hashable, Sendable {
    let state: ButtonState

    /// The state's name in the contract: `hover`, `pressed`.
    package var name: String { state.rawValue }

    /// Whether the current OS ever enters the state (the contract's `platforms` block).
    package var isEntered: Bool { state.isEntered }

    /// The contract's states, in its order.
    package static var all: [ButtonCatalogState] { ButtonState.allCases.map(ButtonCatalogState.init) }

    /// The state with the contract's name, if the contract declares it.
    package init?(named name: String) {
        guard let state = ButtonState(rawValue: name) else { return nil }
        self.state = state
    }

    init(_ state: ButtonState) {
        self.state = state
    }
}

extension View {
    /// Draws the westron buttons in this view as if they were also in `states`. Catalog only: it forces how a state
    /// looks, for a screenshot, and changes nothing a button does.
    package func forcingButtonStates(_ states: Set<ButtonCatalogState>) -> some View {
        environment(\.forcedButtonStates, Set(states.map(\.state)))
    }
}
