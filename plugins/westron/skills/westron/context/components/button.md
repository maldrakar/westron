<!-- Generated from spec/components/button/button.spec.yaml by `tools/westron generate`. Do not edit: change the source
and generate again (decisions/0016). -->

# Button

`button` · approved · a style on `SwiftUI.Button` · used by todo-app/lists-screen, todo-app/list-screen

A push button that runs an action: westron's style on the platform's own button, with a label and a leading icon.

Patterns that use it: [An empty state](../patterns/empty-state.md) and [A form](../patterns/form.md).

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Button(…)
    .buttonStyle(.primary)
….loading(isLoading)
```

What WestronUI declares for it:

```swift
extension View {
    public func buttonStyle(
        _: ButtonVariant,
        size: ButtonSize? = nil,
        iconOnly: Bool = false,
        floating: Bool = false
    ) -> some View
    public func loading(_: Bool) -> some View
}
```

Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. A product's shared
code, which cannot import SwiftUI, imports `WestronContract` instead, and its models keep these values, never a size, a
color or a font:

```swift
public enum ButtonVariant: String, CaseIterable, Sendable { case primary, secondary, tertiary }
public enum ButtonSize: String, CaseIterable, Sendable { case s, m, l }
```

The option `role` is the system's own `SwiftUI.ButtonRole`: the product sets it where SwiftUI takes it, and westron
reads it from there. westron adds no argument for it.

## Options

- `variant`, `ButtonVariant`: `.primary`, `.secondary`, `.tertiary`; no default. No default: every use names its
  variant. primary is filled with the accent, the one main action on a screen; secondary is filled with a quiet gray,
  the muted fill; tertiary has no background and an accent label.
- `size`, `ButtonSize?`: `.s`, `.m`, `.l`; left out, the size comes from `controlSize` (`regular` is `.m`). The height
  is size.control.s, m or l: 24, 32 and 40 with a pointer (macOS), 28, 36 and 50 on iOS and iPadOS, and 44, the only
  size, on watchOS. It is a minimum, so the button grows with its text. The hit area is at least size.target.minimum,
  the platform's recommended target (chapter 08), also where the drawn height is smaller, except where the contract's
  platforms block says otherwise (on macOS the drawn button; on iOS the system's touch tolerance, which a control nearby
  shares). Where an OS lacks a value: on watchOS it draws `s` as `m` and `l` as `m`.
- `role`, the system's `SwiftUI.ButtonRole`: the values `default`, `destructive`; by default `default`. destructive
  recolors any variant in the danger colors; it is not a variant of its own.
- `iconOnly`, `Bool`: by default `false`. The same button showing only its icon: a circle whose diameter equals its
  height; padding and gap do not apply. The label is still there as the accessible label.
- `floating`, `Bool`: by default `false`. The button stands over content, outside the layout and any bar, rather than
  among it: secondary on the system's glass from OS 26 and on a raised surface before it, primary on its own fill with a
  shadow. Not for a button in a system bar, toolbar or tab bar, whose glass is the bar's.

## Slots

`label` and `icon`: through the system control's own initializer and label, never a westron parameter. `label` and
`icon` are the title and the icon of a `Label` in it: `Label("…", icon: .tray)` (`../icons.md`).

## States

- `hover`: the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it. Never entered on
  watchOS.
- `focus`: the system's keyboard focus.
- `pressed`: the system's, while a press is held.
- `disabled`: `.disabled(_:)`, the system's.
- `loading`: `.loading(_:)`, westron's modifier, on the component: the product passes its own state.

## Accessibility

- Role: `button`. A person can activate it. Announced: `disabled` as disabled, `loading` as busy.
- **Every instance needs an accessible name**: the label the system's own initializer of `Button` takes, its title or
  the view of its `label:`, such as a `Label`, whose title is the name also where only its icon is drawn. westron adds
  no parameter for it. Name what it does or holds, never what it looks like.

## Do not

- **Never**: `floating: true` with `variant` other than `.primary` or `.secondary`. tertiary has no fill, so it has no
  ground to float on.
- **Never**: `variant: .secondary` and `floating: true` with `role` other than `` .`default` ``. The danger words read
  too faintly on the system's glass: they measured 2.96:1 in the light theme and 2.79 to 4.18:1 in the dark one over a
  busy ground (decisions/0015). A floating destructive primary, on its opaque fill, stays.

More: `button.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI builds
it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or "#120"
points into westron's repository, not into this bundle.
