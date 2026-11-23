// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show Disclosure's
// states that a screenshot cannot produce, hover, focus and pressed, and readouts of the hover the style draws and of
// the toggles its chevron makes, which its UI tests read. Everything here is `package`, visible to the targets of this
// Swift package and never to a product that imports WestronUI: it is not public API, and the parity lint (#21) does not
// see it.

#if !os(watchOS)
    import SwiftUI

    extension EnvironmentValues {
        /// States the westron Disclosure style draws in addition to the real ones. Catalog only: a product never sets it.
        @Entry var forcedDisclosureStates: Set<DisclosureState> = []
        /// Called when a westron chevron's hover state changes, with the new state. Catalog only.
        @Entry var disclosureHoverObserver: (@MainActor @Sendable (Bool) -> Void)? = nil
        /// Called when a westron chevron toggles its group, with the new expansion. Catalog only.
        @Entry var disclosureToggleObserver: (@MainActor @Sendable (Bool) -> Void)? = nil
    }

    /// One of Disclosure's states from its contract, as the catalog names it. Catalog only.
    ///
    /// It wraps the generated, internal `DisclosureState`, so the catalog lists the states the contract declares, in its
    /// order, without a list of its own. Its properties switch exhaustively over `DisclosureState`, so a state added to
    /// or renamed in the contract fails the build here instead of dropping a row from the catalog.
    package struct DisclosureCatalogState: Hashable, Sendable {
        let state: DisclosureState

        /// The state's name in the contract: `expanded`, `hover`.
        package var name: String { state.rawValue }

        /// Whether the current OS ever enters the state (the contract's `platforms` block).
        package var isEntered: Bool { state.isEntered }

        /// Whether a screenshot can only show the state when the catalog forces it: hover, focus, pressed.
        package var isForced: Bool {
            switch state {
            case .hover, .focus, .pressed: true
            case .expanded, .disabled: false
            }
        }

        /// Whether the group is expanded, which the catalog sets with the group's own binding.
        package var isExpanded: Bool {
            switch state {
            case .expanded: true
            case .hover, .focus, .pressed, .disabled: false
            }
        }

        /// Whether it is disabled, which the catalog sets with the system's `.disabled(_:)`.
        package var isDisabled: Bool {
            switch state {
            case .disabled: true
            case .expanded, .hover, .focus, .pressed: false
            }
        }

        /// The contract's states, in its order.
        package static var all: [DisclosureCatalogState] { DisclosureState.allCases.map(DisclosureCatalogState.init) }

        /// The state with the contract's name, if the contract declares it.
        package init?(named name: String) {
            guard let state = DisclosureState(rawValue: name) else { return nil }
            self.state = state
        }

        init(_ state: DisclosureState) {
            self.state = state
        }
    }

    extension View {
        /// Draws the westron chevrons in this view as if they were also in `states`. Catalog only: it forces how a state
        /// looks, for a screenshot, and changes nothing a chevron does.
        package func forcingDisclosureStates(_ states: Set<DisclosureCatalogState>) -> some View {
            environment(\.forcedDisclosureStates, Set(states.filter(\.isForced).map(\.state)))
        }

        /// Calls `action` when a westron chevron in this view enters or leaves hover, the state the style draws from the
        /// pointer over its circle, so that the catalog can show it and its UI tests read it. Catalog only.
        package func onDisclosureHover(_ action: @escaping @MainActor @Sendable (Bool) -> Void) -> some View {
            environment(\.disclosureHoverObserver, action)
        }

        /// Calls `action` when a westron chevron in this view toggles its group, with the new expansion, so that the
        /// catalog counts the chevron's toggles apart from the binding's. Catalog only.
        package func onDisclosureToggle(_ action: @escaping @MainActor @Sendable (Bool) -> Void) -> some View {
            environment(\.disclosureToggleObserver, action)
        }
    }
#endif
