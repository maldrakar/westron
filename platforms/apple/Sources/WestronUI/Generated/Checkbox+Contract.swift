// Generated from spec/components/checkbox/checkbox.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Checkbox's API from its contract: the enums of its options, the overload of `toggleStyle` that products call, which
// applies the hand-written `CheckboxVariantStyle` (decisions/0001), and the tables that style reads.

import SwiftUI

/// Checkbox's option `variant`, from its contract.
///
/// The round check; the only variant. The system's own style names (automatic, switch, button, checkbox) are not
/// values: westron's overload would shadow them (decisions/0003).
public enum CheckboxVariant: String, CaseIterable, Sendable {
    case check
}

extension View {
    /// Applies westron's Checkbox style, from its contract, to the system's `Toggle` in this view:
    /// `.toggleStyle(.check)`.
    ///
    /// - Parameters:
    ///   - variant: See `CheckboxVariant`. Every call names one.
    public func toggleStyle(_ variant: CheckboxVariant) -> some View {
        toggleStyle(CheckboxVariantStyle(variant: variant))
    }
}

extension CheckboxVariant {
    /// The variant the current OS draws for this one (the contract's `platforms` block). Every Apple OS offers every
    /// variant, so it is the value itself.
    var offered: CheckboxVariant {
        self
    }
}

/// The states of a Checkbox in its contract, in its order. The system control has some of them; the others are set
/// through the environment (spec/conventions.md).
///
/// Not entered: on watchOS, focus (the contract's `platforms` block).
enum CheckboxState: String, CaseIterable, Sendable {
    case checked
    case pressed
    case focus
    case disabled

    /// Whether the current OS ever enters the state.
    var isEntered: Bool {
        #if os(watchOS)
            switch self {
            case .checked: return true
            case .pressed: return true
            case .focus: return false
            case .disabled: return true
            }
        #else
            return true
        #endif
    }
}
