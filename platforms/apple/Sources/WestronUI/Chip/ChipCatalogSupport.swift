// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show Chip's states
// that a screenshot cannot produce: hover, focus and pressed, also held with checked; and a readout of the hover the
// style draws, which its UI tests read. Everything here is `package`, visible to the targets of this Swift package and
// never to a product that imports WestronUI: it is not public API, and the parity lint (#21) does not see it.

import SwiftUI

extension EnvironmentValues {
    /// States the westron Chip styles draw in addition to the real ones. Catalog only: a product never sets it.
    @Entry var forcedChipStates: Set<ChipState> = []
    /// Called when a westron chip's hover state changes, with the new state. Catalog only: a product never sets it.
    @Entry var chipHoverObserver: (@MainActor @Sendable (Bool) -> Void)? = nil
}

/// One of Chip's states from its contract, as the catalog names it. Catalog only.
///
/// It wraps the generated, internal `ChipState`, so the catalog lists the states the contract declares, in its order,
/// without a list of its own. Its properties switch exhaustively over `ChipState`, so a state added to or renamed in
/// the contract fails the build here instead of dropping a row from the catalog.
package struct ChipCatalogState: Hashable, Sendable {
    let state: ChipState

    /// The state's name in the contract: `checked`, `hover`.
    package var name: String { state.rawValue }

    /// Whether the current OS ever enters the state (the contract's `platforms` block).
    package var isEntered: Bool { state.isEntered }

    /// Whether a screenshot can only show the state when the catalog forces it: hover, focus, pressed.
    package var isForced: Bool {
        switch state {
        case .hover, .focus, .pressed: true
        case .checked, .disabled: false
        }
    }

    /// Whether the toggle is on, which the catalog sets with the toggle's own value.
    package var isChecked: Bool {
        switch state {
        case .checked: true
        case .hover, .focus, .pressed, .disabled: false
        }
    }

    /// Whether it is disabled, which the catalog sets with the system's `.disabled(_:)`.
    package var isDisabled: Bool {
        switch state {
        case .disabled: true
        case .checked, .hover, .focus, .pressed: false
        }
    }

    /// Whether the form enters the state (the contract's `forms`).
    package func isEntered(by form: ChipForm) -> Bool { form.states.contains(state) }

    /// The contract's states, in its order.
    package static var all: [ChipCatalogState] { ChipState.allCases.map(ChipCatalogState.init) }

    /// The state with the contract's name, if the contract declares it.
    package init?(named name: String) {
        guard let state = ChipState(rawValue: name) else { return nil }
        self.state = state
    }

    init(_ state: ChipState) {
        self.state = state
    }
}

extension View {
    /// Draws the westron chips in this view as if they were also in `states`. Catalog only: it forces how a state looks,
    /// for a screenshot, and changes nothing a chip does.
    package func forcingChipStates(_ states: Set<ChipCatalogState>) -> some View {
        environment(\.forcedChipStates, Set(states.map(\.state)))
    }

    /// Calls `action` when a westron chip in this view enters or leaves hover, the state the style draws from the
    /// pointer over its capsule, so that the catalog can show it and its UI tests read it (ChipBehaviorTests). Catalog
    /// only: it changes nothing a chip does.
    package func onChipHover(_ action: @escaping @MainActor @Sendable (Bool) -> Void) -> some View {
        environment(\.chipHoverObserver, action)
    }
}
