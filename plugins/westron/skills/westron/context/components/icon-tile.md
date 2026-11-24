<!-- Generated from spec/components/icon-tile/icon-tile.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# IconTile

`icon-tile` · approved · westron's own view · used by todo-app/lists-screen, todo-app/list-screen

A list's mark: a rounded square in the list's color with the list's glyph on it, which stands beside a list's title in a
row, a screen header, a picker and the card a drag carries, and alone above the words of an empty screen.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
IconTile(.tray)
IconTile(.tray, label: "…")
```

What WestronUI declares for it:

```swift
public struct IconTile: View {
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
  its glyph, the list's icon as the product stores it. The values are the names of the icon registry,
  spec/icons/icons.yaml, in its order, as Icon's are; a name this version does not know draws the registry's default,
  bullets.
- `scale`, the system's `SwiftUI.Image.Scale`: the values `small`, `medium`, `large`; by default `medium`. The
  platform's relative scale against the text role the tile takes its size from: medium is the role's own tile. It scales
  the tile and its glyph together, so the glyph keeps its proportion to the tile. It is never a size in points
  (design-language/07, "A relative scale is the only size choice").

## Slots

`label`: the glyph's spoken name, the initializer's `label:`; an instance without one is decorative and hidden from
assistive technology.

## Accessibility

- Role: `image`.
- The accessible name is the initializer's `label:`. Give it when the instance means something on the screen; without it
  the instance is decorative and hidden from assistive technology. Name what it does or holds, never what it looks like.

More: `icon-tile.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI
builds it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or
"#120" points into westron's repository, not into this bundle.
