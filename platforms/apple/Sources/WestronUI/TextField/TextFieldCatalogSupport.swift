// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to show TextField's
// focus state on many fields at once, which a screenshot cannot produce: only one field holds the keyboard focus.
// Everything here is `package`, visible to the targets of this Swift package and never to a product that imports
// WestronUI: it is not public API, and the parity lint (#21) does not see it.

import SwiftUI

extension EnvironmentValues {
    /// States the westron TextField style draws in addition to the real ones. Catalog only: a product never sets it.
    @Entry var forcedTextFieldStates: Set<TextFieldState> = []
}

/// One of TextField's states from its contract, as the catalog names it. Catalog only.
///
/// It wraps the generated, internal `TextFieldState`, so the catalog lists the states the contract declares, in its
/// order, without a list of its own. Its properties switch exhaustively over `TextFieldState`, so a state added to or
/// renamed in the contract fails the build here instead of dropping a row from the catalog.
package struct TextFieldCatalogState: Hashable, Sendable {
    let state: TextFieldState

    /// The state's name in the contract: `focus`, `disabled`.
    package var name: String { state.rawValue }

    /// Whether the current OS ever enters the state (the contract's `platforms` block).
    package var isEntered: Bool { state.isEntered }

    /// Whether a screenshot of many fields can only show the state when the catalog forces it: focus.
    package var isForced: Bool {
        switch state {
        case .focus: true
        case .disabled: false
        }
    }

    /// Whether it is disabled, which the catalog sets with the system's `.disabled(_:)`.
    package var isDisabled: Bool {
        switch state {
        case .disabled: true
        case .focus: false
        }
    }

    /// The contract's states, in its order.
    package static var all: [TextFieldCatalogState] { TextFieldState.allCases.map(TextFieldCatalogState.init) }

    /// The state with the contract's name, if the contract declares it.
    package init?(named name: String) {
        guard let state = TextFieldState(rawValue: name) else { return nil }
        self.state = state
    }

    init(_ state: TextFieldState) {
        self.state = state
    }
}

extension TextFieldVariant {
    /// How far the focus ring of a field of this variant reaches outside its laid out frame, on each side: what a
    /// layout around a focused field keeps clear (the contract's `platforms.apple`). Catalog only: the matrix cells
    /// keep it, so that forced rings neither touch each other nor the picture's edge. On watchOS, which draws no ring,
    /// none.
    package var focusRingClearance: EdgeInsets {
        #if os(watchOS)
            EdgeInsets()
        #else
            switch offered {
            case .framed:
                let outset = CGFloat(Westron.Dimension.stroke.thick)
                return EdgeInsets(top: outset, leading: outset, bottom: outset, trailing: outset)
            case .inline:
                let across = CGFloat(TextFieldMetrics.inlineRingOutsetHorizontal)
                let upDown = CGFloat(TextFieldMetrics.inlineRingOutsetVertical)
                return EdgeInsets(top: upDown, leading: across, bottom: upDown, trailing: across)
            }
        #endif
    }
}

/// The axis each westron text field in a view resolved from the field SwiftUI gave its style, the contract's `lines`
/// (`TextFieldAxis`), one entry per field. Tests and the catalog read it with `onPreferenceChange(_:perform:)`, so that a
/// SwiftUI that no longer gives the style the field's axis fails a test instead of drawing every field as one line.
/// Package only: a product never reads it.
package struct TextFieldResolvedAxes: PreferenceKey {
    package static var defaultValue: [Axis] { [] }

    package static func reduce(value: inout [Axis], nextValue: () -> [Axis]) {
        value += nextValue()
    }
}

extension View {
    /// Draws the westron text fields in this view as if they were also in `states`. Catalog only: it forces how a
    /// state looks, for a screenshot, and changes nothing a field does; the field takes no keyboard focus.
    package func forcingTextFieldStates(_ states: Set<TextFieldCatalogState>) -> some View {
        environment(\.forcedTextFieldStates, Set(states.map(\.state)))
    }
}
