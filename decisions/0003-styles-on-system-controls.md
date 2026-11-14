# 0003. Styles on top of system controls, and the API shape

Date: 2026-11-14. Status: accepted.

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

A variant value must not match the static name of a system style of the same control. For a button these include `plain`, `bordered`, `borderedProminent`, `borderless`, `automatic`, `link`, `glass`, `glassProminent`. Otherwise the call `.buttonStyle(.plain)` becomes ambiguous. We add this check to the contract validator.

## Other platforms

- GTK: the standard `GtkButton`; variants map to CSS classes.
- Web: decided in the web phase; by the same logic, a native `<button>` with westron styles is preferred.
