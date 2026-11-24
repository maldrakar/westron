// Generated from spec/components/button/button.spec.yaml by `tools/westron generate`. Do not edit: change the contract
// and generate again (spec/conventions.md).
//
// Button's API from its contract: the overload of `buttonStyle` that products call, which applies the hand-written
// `ButtonVariantStyle` (decisions/0001), and the tables that style reads. The enums of its options are in
// WestronContract/Generated/Button+Contract.swift (decisions/0017).

import SwiftUI
import WestronContract

extension View {
    /// Applies westron's Button style, from its contract, to the system's `Button` in this view:
    /// `.buttonStyle(.primary, size: .m)`.
    ///
    /// The option `role` is the system's own `SwiftUI.ButtonRole`, which the style reads from the control.
    ///
    /// - Parameters:
    ///   - variant: See `ButtonVariant`. Every call names one.
    ///   - size: The size; without it, the size comes from `controlSize` (`ButtonSize.init(_:)`).
    ///   - iconOnly: The same button showing only its icon: a circle whose diameter equals its height; padding and gap
    ///     do not apply. By default `false`.
    ///   - floating: The button stands over content, outside the layout and any bar, rather than among it: secondary on
    ///     the system's glass from OS 26 and on a raised surface before it, primary on its own fill with a shadow. By
    ///     default `false`.
    public func buttonStyle(
        _ variant: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false, floating: Bool = false
    ) -> some View {
        buttonStyle(ButtonVariantStyle(variant: variant, size: size, iconOnly: iconOnly, floating: floating))
    }
}

extension ButtonSize {
    /// The size of a call without `size:`, from the environment's `controlSize`: mini and small → s, regular → m, large
    /// and extraLarge → l (spec/conventions.md). SwiftUI cannot tell an unset `controlSize` from `regular`, so a call
    /// with neither takes the contract's default.
    init(_ controlSize: ControlSize) {
        switch controlSize {
        case .mini: self = .s
        case .small: self = .s
        case .regular: self = .m
        case .large: self = .l
        case .extraLarge: self = .l
        @unknown default: self = .m
        }
    }
}

extension ButtonVariant {
    /// The variant the current OS draws for this one (the contract's `platforms` block). Every Apple OS offers every
    /// variant, so it is the value itself.
    var offered: ButtonVariant {
        self
    }
}

extension ButtonSize {
    /// The size the current OS draws for this one (the contract's `platforms` block). Where an OS does not offer a
    /// value, the fallback the contract names: on watchOS, s → m, l → m.
    var offered: ButtonSize {
        #if os(watchOS)
            switch self {
            case .s: return .m
            case .m: return .m
            case .l: return .m
            }
        #else
            return self
        #endif
    }
}

/// The states of a Button in its contract, in its order. The system control has some of them; the others are set
/// through the environment (spec/conventions.md).
///
/// Not entered: on watchOS, hover (the contract's `platforms` block).
enum ButtonState: String, CaseIterable, Sendable {
    case hover
    case focus
    case pressed
    case disabled
    case loading

    /// Whether the current OS ever enters the state.
    var isEntered: Bool {
        #if os(watchOS)
            switch self {
            case .hover: return false
            case .focus: return true
            case .pressed: return true
            case .disabled: return true
            case .loading: return true
            }
        #else
            return true
        #endif
    }
}
