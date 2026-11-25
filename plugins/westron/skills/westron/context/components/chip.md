<!-- Generated from spec/components/chip/chip.spec.yaml by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Chip

`chip` · approved · a style on `SwiftUI.Toggle`, `SwiftUI.Button` or `SwiftUI.Label` · used by todo-app/list-screen

A compact capsule with a short label and an optional leading icon: a tag, a filter, a value.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Toggle(…)
    .toggleStyle(.chip)
Button(…)
    .buttonStyle(.chip)
Label(…)
    .labelStyle(.chip)
Toggle(…)
    .toggleStyle(.chip)
    .category(.blue)
```

What WestronUI declares for it:

```swift
extension View {
    public func toggleStyle(_: ChipVariant) -> some View
    public func buttonStyle(_: ChipVariant) -> some View
    public func labelStyle(_: ChipVariant) -> some View
    public func category(_: Westron.Category?) -> some View
}
```

Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. A product's shared
code, which cannot import SwiftUI, imports `WestronContract` instead, and its models keep these values, never a size, a
color or a font:

```swift
public enum ChipVariant: String, CaseIterable, Sendable { case chip }
```

It reads `category` from its context: `.category(_:)` on the component itself, or once on any view around it, such as a
row or a list, sets it for every westron component below that reads it, and the closest setting wins. In a list's color,
a checked chip, the selectable form's, is filled with color.category.<name>.fill, keeps that fill under the pointer and
pressed, and draws its label, icon and check in color.category.<name>.on-fill. An unchecked chip, and the pressable and
static forms, which are never checked, do not change. Without it, a checked chip is filled with the accent,
color.background.accent, a step darker under the pointer and pressed, and draws its label, icon and check in
color.text.on-accent.

## Options

- `variant`, `ChipVariant`: `.chip`; no default. The chip; the only variant, so that a call reads .toggleStyle(.chip),
  .buttonStyle(.chip) and .labelStyle(.chip). No system style of the three bases is named chip, and neither is a value
  of Button's or Checkbox's variant, which share two of the modifiers (decisions/0003; decisions/0001, P3).

## Slots

`label` and `icon`: through the system control's own initializer and label, never a westron parameter. `label` and
`icon` are the title and the icon of a `Label` in it: `Label("…", icon: .tray)` (`../icons.md`).

## States

- `checked`: the toggle's value, `isOn`.
- `hover`: the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it. Never entered on
  watchOS.
- `focus`: the system's keyboard focus. Never entered on watchOS.
- `pressed`: the system's, while a press is held.
- `disabled`: `.disabled(_:)`, the system's.

## Forms

The same look in several forms; the product picks one by what it writes.

- `selectable`: `Toggle` with `.toggleStyle(…)`. A filter that is on or off; checked while it is on. States: `checked`,
  `hover`, `focus`, `pressed`, `disabled`.
- `pressable`: `Button` with `.buttonStyle(…)`. A value that opens something when pressed. Its pilot consumer arrives
  with the Task screen's pickers; until then the pilot draws its inert pills as static chips (decisions/0001, Q3).
  States: `hover`, `focus`, `pressed`, `disabled`.
- `static`: `Label` with `.labelStyle(…)`. A value shown and not acted on; its label is read as text. States: none.

## Accessibility

- Role: `toggleButton`. A person can toggle it. Announced: `checked` as checked, `disabled` as disabled.
- **Every instance needs an accessible name**: the label the system's own initializer of `Toggle`, `Button` or `Label`
  takes, its title or the view of its `label:`, such as a `Label`, whose title is the name also where only its icon is
  drawn. westron adds no parameter for it. Name what it does or holds, never what it looks like.

More: `chip.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI builds
it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or "#120"
points into westron's repository, not into this bundle.
