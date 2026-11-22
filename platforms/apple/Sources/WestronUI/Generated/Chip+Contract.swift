// Generated from spec/components/chip/chip.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Chip's API from its contract: the enums of its options, an overload of each form's style modifier that products call,
// `toggleStyle`, `buttonStyle` and `labelStyle`, each applying its hand-written style, `ChipToggleStyle`,
// `ChipButtonStyle` and `ChipLabelStyle` (decisions/0001), and the tables those styles read.

import SwiftUI

/// Chip's option `variant`, from its contract.
///
/// The chip; the only variant, so that a call reads .toggleStyle(.chip), .buttonStyle(.chip) and .labelStyle(.chip). No
/// system style of the three bases is named chip, and neither is a value of Button's or Checkbox's variant, which share
/// two of the modifiers (decisions/0003; decisions/0001, P3).
public enum ChipVariant: String, CaseIterable, Sendable {
    case chip
}

extension View {
    /// Applies westron's Chip style in its form `selectable`, from its contract, to the system's `Toggle` in this view:
    /// `.toggleStyle(.chip)`.
    ///
    /// - Parameters:
    ///   - variant: See `ChipVariant`. Every call names one.
    public func toggleStyle(_ variant: ChipVariant) -> some View {
        toggleStyle(ChipToggleStyle(variant: variant))
    }
}

extension View {
    /// Applies westron's Chip style in its form `pressable`, from its contract, to the system's `Button` in this view:
    /// `.buttonStyle(.chip)`.
    ///
    /// - Parameters:
    ///   - variant: See `ChipVariant`. Every call names one.
    public func buttonStyle(_ variant: ChipVariant) -> some View {
        buttonStyle(ChipButtonStyle(variant: variant))
    }
}

extension View {
    /// Applies westron's Chip style in its form `static`, from its contract, to the system's `Label` in this view:
    /// `.labelStyle(.chip)`.
    ///
    /// - Parameters:
    ///   - variant: See `ChipVariant`. Every call names one.
    public func labelStyle(_ variant: ChipVariant) -> some View {
        labelStyle(ChipLabelStyle(variant: variant))
    }
}

extension ChipVariant {
    /// The variant the current OS draws for this one (the contract's `platforms` block). Every Apple OS offers every
    /// variant, so it is the value itself.
    var offered: ChipVariant {
        self
    }
}

/// The states of a Chip in its contract, in its order. The system control has some of them; the others are set through
/// the environment (spec/conventions.md).
///
/// Not entered: on watchOS, hover, focus (the contract's `platforms` block).
enum ChipState: String, CaseIterable, Sendable {
    case checked
    case hover
    case focus
    case pressed
    case disabled

    /// Whether the current OS ever enters the state.
    var isEntered: Bool {
        #if os(watchOS)
            switch self {
            case .checked: return true
            case .hover: return false
            case .focus: return false
            case .pressed: return true
            case .disabled: return true
            }
        #else
            return true
        #endif
    }
}

/// The forms of a Chip in its contract, in its order: the same look, each on its own system control, which a product
/// picks by the control it writes (spec/conventions.md, "Forms"): selectable, `.toggleStyle` on `Toggle`; pressable,
/// `.buttonStyle` on `Button`; static, `.labelStyle` on `Label`.
package enum ChipForm: String, CaseIterable, Sendable {
    case selectable
    case pressable
    case `static`

    /// The states the form enters (the contract's `forms`).
    var states: Set<ChipState> {
        switch self {
        case .selectable: [.checked, .hover, .focus, .pressed, .disabled]
        case .pressable: [.hover, .focus, .pressed, .disabled]
        case .static: []
        }
    }
}
