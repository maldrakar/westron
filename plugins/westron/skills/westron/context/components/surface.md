<!-- Generated from spec/components/surface/surface.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# Surface

`surface` · approved · westron's own modifier · used by todo-app/lists-screen, todo-app/list-screen

The ground a card or a panel stands on, which westron draws behind content the product lays out: a background, a corner
and, where it stands off what is under it, a shadow.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
content
    .surface(.raised)
```

What WestronUI declares for it:

```swift
extension View {
    public func surface(_: SurfaceVariant, outlined: Bool = false) -> some View
}
```

Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. A product's shared
code, which cannot import SwiftUI, imports `WestronContract` instead, and its models keep these values, never a size, a
color or a font:

```swift
public enum SurfaceVariant: String, CaseIterable, Sendable { case raised, dragged, sunken }
```

## Options

- `variant`, `SurfaceVariant`: `.raised`, `.dragged`, `.sunken`; no default. No default: every use names its kind. The
  kinds differ by height: sunken lies below the canvas, raised barely lifts, dragged is unmistakable
  (design-language/04, "Shadows").
- `outlined`, `Bool`: by default `false`. The hairline for a surface that sits on a fill rather than on the canvas. In
  the high-contrast themes a raised or dragged surface draws the thicker high-contrast line in any case, an outlined one
  included.

## Slots

`content`: the view the modifier is applied to.

## Accessibility

- Role: `none`.

More: `surface.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI
builds it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or
"#120" points into westron's repository, not into this bundle.
