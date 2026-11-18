# 0003. Styles on top of system controls, and the API shape

Date: 2026-11-14. Status: accepted. Note of 2026-11-18: the reason for the constraint on value names is corrected
(below); the constraint does not change.

## Decision

1. **If a system control exists**, the contract binds to it. westron provides a style and extensions, not its own type. There are no wrappers like `WButton`.
2. **If there is no system control** (for example, Badge, Banner, EmptyState), westron builds its own component, named as in the contract, without a prefix.
3. **A component's name may differ between platforms** if it cannot be named as in the contract. The design decisions must match: the values of variants, sizes and states, and the tokens, in the contract and in the generated code.

## API shape in SwiftUI

```swift
Button("Save") { save() }
    .buttonStyle(.primary, size: .m)
```

- `ButtonVariant` and `ButtonSize` are generated from the contract.
- `buttonStyle(_:size:)` is an overload in a `View` extension that takes the generated enums; inside, it applies a hand-written `ButtonStyle`.
- States the system button does not have (for example, `loading`) are set by a modifier through the environment.
- Sizes are named `s`, `m`, `l`, as in the contract, not `small/regular/large`.

## Constraint on value names

A variant value must not match the static name of a system style of the same control. For a button these include `plain`, `bordered`, `borderedProminent`, `borderless`, `automatic`, `link`, `glass`, `glassProminent`. Otherwise westron's overload would shadow the system style. We add this check to the contract validator.

Note of 2026-11-18. The first version said the call `.buttonStyle(.plain)` would become ambiguous. That is not what
happens: verified with Xcode 27.1 on 2026-11-18, the call compiles and silently resolves to westron's non-generic
overload, which shadows the system style. The system's `.plain` is then reachable only as `PlainButtonStyle()`, and
existing product code that wrote `.buttonStyle(.plain)` changes meaning without a diagnostic. The owner confirmed that
the ban stays, for this reason; the validator's rule does not change.

## Other platforms

- GTK: the standard `GtkButton`; variants map to CSS classes.
- Web: decided in the web phase; by the same logic, a native `<button>` with westron styles is preferred.
