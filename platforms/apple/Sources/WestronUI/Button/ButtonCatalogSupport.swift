// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show Button's states
// that a screenshot cannot produce: hover, pressed and focus.
// Everything here is `package`, visible to the targets of this Swift package and never to a product that imports
// WestronUI: it is not public API, and the parity lint (#21) does not see it.

import SwiftUI

extension EnvironmentValues {
    /// States the westron Button style draws in addition to the real ones. Catalog only: a product never sets it.
    @Entry var forcedButtonStates: Set<ButtonState> = []
}

/// One of Button's states from its contract, as the catalog names it. Catalog only.
///
/// It wraps the generated, internal `ButtonState`, so the catalog lists the states the contract declares, in its
/// order, without a list of its own. Its properties switch exhaustively over `ButtonState`, so a state added to or
/// renamed in the contract fails the build here instead of dropping a row from the catalog.
package struct ButtonCatalogState: Hashable, Sendable {
    let state: ButtonState

    /// The state's name in the contract: `hover`, `pressed`.
    package var name: String { state.rawValue }

    /// Whether the current OS ever enters the state (the contract's `platforms` block).
    package var isEntered: Bool { state.isEntered }

    /// Whether a screenshot can only show the state when the catalog forces it: hover, focus, pressed.
    package var isForced: Bool {
        switch state {
        case .hover, .focus, .pressed: true
        case .disabled, .loading: false
        }
    }

    /// Whether it is disabled, which the catalog sets with the system's `.disabled(_:)`.
    package var isDisabled: Bool {
        switch state {
        case .disabled: true
        case .hover, .focus, .pressed, .loading: false
        }
    }

    /// Whether it is loading, which the catalog sets with westron's `.loading(_:)`.
    package var isLoading: Bool {
        switch state {
        case .loading: true
        case .hover, .focus, .pressed, .disabled: false
        }
    }

    /// Whether it excludes hover and pressed (the contract's first `container.background` cases): disabled, loading.
    package var excludesTint: Bool {
        switch state {
        case .disabled, .loading: true
        case .hover, .focus, .pressed: false
        }
    }

    /// Whether disabled and loading exclude it: hover, pressed.
    package var isTint: Bool {
        switch state {
        case .hover, .pressed: true
        case .focus, .disabled, .loading: false
        }
    }

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
