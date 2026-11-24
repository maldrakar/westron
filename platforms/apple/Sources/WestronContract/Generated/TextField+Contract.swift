// Generated from spec/components/text-field/text-field.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// TextField's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a
// product's shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

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
