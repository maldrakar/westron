// Generated from spec/components/button/button.spec.yaml by `tools/westron generate`. Do not edit: change the contract
// and generate again (spec/conventions.md).
//
// Button's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a product's
// shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

/// Button's option `variant`, from its contract.
///
/// No default: every use names its variant. primary is filled with the accent, the one main action on a screen;
/// secondary is filled with a quiet gray, the muted fill; tertiary has no background and an accent label.
public enum ButtonVariant: String, CaseIterable, Sendable {
    case primary
    case secondary
    case tertiary
}

/// Button's option `size`, from its contract.
///
/// The height is size.control.s, m or l: 24, 32 and 40 with a pointer (macOS), 28, 36 and 50 on iOS and iPadOS, and 44,
/// the only size, on watchOS. It is a minimum, so the button grows with its text. The hit area is at least
/// size.target.minimum, the platform's recommended target (chapter 08), also where the drawn height is smaller, except
/// where the contract's platforms block says otherwise (on macOS the drawn button; on iOS the system's touch tolerance,
/// which a control nearby shares).
///
/// A call without `size:` takes the size from `controlSize`: mini and small → s, regular → m, large and extraLarge → l.
/// An explicit `size:` wins.
public enum ButtonSize: String, CaseIterable, Sendable {
    case s
    case m
    case l
}
