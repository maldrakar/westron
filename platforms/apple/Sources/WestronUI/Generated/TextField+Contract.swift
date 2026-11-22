// Generated from spec/components/text-field/text-field.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// TextField's API from its contract: the enums of its options, the overload of `textFieldStyle` that products call,
// which applies the hand-written `TextFieldVariantStyle` (decisions/0001), and the tables that style reads.

import SwiftUI

/// TextField's option `variant`, from its contract.
///
/// No default: every use names its variant. The system's own style names (automatic, plain, roundedBorder,
/// squareBorder, bordered) are not values: westron's overload would shadow them (decisions/0003).
public enum TextFieldVariant: String, CaseIterable, Sendable {
    case framed
    case inline
}

/// TextField's option `size`, from its contract.
///
/// framed: the height is size.control.s, m or l, 24, 32 and 40 with a pointer (macOS), 28, 36 and 50 on iOS and iPadOS,
/// 44 on watchOS, as a minimum, so the field grows with its text; its padding follows the size, and its text is
/// body.regular at every size. A field drawn below size.target.minimum, the platform's recommended target, 28 pt on
/// macOS and 44 pt on iOS, keeps a hit area of that height (design-language/08): at s on macOS, at s and m on iOS.
/// inline takes its height and its text role from its context, so the size changes nothing on it.
///
/// A call without `size:` takes the size from `controlSize`: mini and small → s, regular → m, large and extraLarge → l.
/// An explicit `size:` wins.
public enum TextFieldSize: String, CaseIterable, Sendable {
    case s
    case m
    case l
}

extension View {
    /// Applies westron's TextField style, from its contract, to the system's `TextField` in this view:
    /// `.textFieldStyle(.framed, size: .m)`.
    ///
    /// The option `lines` is the system's own `SwiftUI.Axis`, which the style reads from the control.
    ///
    /// - Parameters:
    ///   - variant: See `TextFieldVariant`. Every call names one.
    ///   - size: The size; without it, the size comes from `controlSize` (`TextFieldSize.init(_:)`).
    ///   - leadingIcon: The glyph at the field's start, a name of the icon registry, or none: a use that leaves it out
    ///     draws no glyph there and gives the text that room. A name of `Westron.Icon`; by default `nil`, none.
    ///   - trailingIcon: The glyph at the field's end, or none, such as a number sign at the end of a field that holds a
    ///     tag's name. A name of `Westron.Icon`; by default `nil`, none.
    public func textFieldStyle(
        _ variant: TextFieldVariant,
        size: TextFieldSize? = nil,
        leadingIcon: Westron.Icon? = nil,
        trailingIcon: Westron.Icon? = nil
    ) -> some View {
        let style = TextFieldVariantStyle(
            variant: variant,
            size: size,
            leadingIcon: leadingIcon,
            trailingIcon: trailingIcon)
        return textFieldStyle(style)
    }
}

extension TextFieldSize {
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

extension TextFieldVariant {
    /// The variant the current OS draws for this one (the contract's `platforms` block). Every Apple OS offers every
    /// variant, so it is the value itself.
    var offered: TextFieldVariant {
        self
    }
}

extension TextFieldSize {
    /// The size the current OS draws for this one (the contract's `platforms` block). Where an OS does not offer a
    /// value, the fallback the contract names: on watchOS, s → m, l → m.
    var offered: TextFieldSize {
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

/// The states of a TextField in its contract, in its order. The system control has some of them; the others are set
/// through the environment (spec/conventions.md).
///
/// Not entered: on watchOS, focus (the contract's `platforms` block).
enum TextFieldState: String, CaseIterable, Sendable {
    case focus
    case disabled

    /// Whether the current OS ever enters the state.
    var isEntered: Bool {
        #if os(watchOS)
            switch self {
            case .focus: return false
            case .disabled: return true
            }
        #else
            return true
        #endif
    }
}
