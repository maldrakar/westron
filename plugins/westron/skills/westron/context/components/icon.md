<!-- Generated from spec/components/icon/icon.spec.yaml by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Icon

`icon` · approved · westron's own view · used by todo-app/lists-screen, todo-app/list-screen

An icon of westron's registry, drawn as the platform's own glyph image: westron adds the names, how a glyph is drawn and
what assistive technology hears of it (design-language/07, decisions/0011).

Patterns that use it: [A list of choices in a sheet](../patterns/choice-list-sheet.md) and [A
form](../patterns/form.md).

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Icon(.tray)
Icon(.tray, label: "…")
```

What WestronUI declares for it:

```swift
public struct Icon: View {
    public init(_: Westron.Icon)
    public init(_: Westron.Icon, label: LocalizedStringKey)
    @_disfavoredOverload public init<S: StringProtocol>(_: Westron.Icon, label: S)
    public var body: some View
}
```

The option `scale` is the system's own `SwiftUI.Image.Scale`: the product sets it where SwiftUI takes it, and westron
reads it from there. westron adds no argument for it.

## Options

- `glyph`, `Westron.Icon`: a name of the icon registry (`../icons.md`); every use names one. No default: every use names
  its glyph. The values are the names of the icon registry, spec/icons/icons.yaml, in its order, so the contract and the
  registry cannot drift. A name says what the glyph draws, never what it means on a screen, and a released name is never
  renamed or removed; a name this version does not know draws the registry's default, bullets (design-language/07,
  "Names").
- `scale`, the system's `SwiftUI.Image.Scale`: the values `small`, `medium`, `large`; by default `medium`. The
  platform's relative scale against the text the icon takes its size from: medium is the text's own size. It is never a
  size in points (design-language/07, "Size relative to text").

## Slots

`label`: the glyph's spoken name, the initializer's `label:`; an instance without one is decorative and hidden from
assistive technology.

## Accessibility

- Role: `image`.
- The accessible name is the initializer's `label:`. Give it when the instance means something on the screen; without it
  the instance is decorative and hidden from assistive technology. Name what it does or holds, never what it looks like.

More: `icon.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI builds
it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or "#120"
points into westron's repository, not into this bundle.
