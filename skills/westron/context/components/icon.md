<!-- Generated from spec/components/icon/icon.spec.yaml by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Icon

`icon` · approved · westron's own view · used by todo-app/lists-screen, todo-app/list-screen

An icon of westron's registry, drawn as the platform's own glyph image: westron adds the names, how a glyph is drawn and
what assistive technology hears of it (design-language/07, decisions/0011).

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
- A label is optional: read below what an instance without one is.

An icon without a label is decorative and hidden from assistive technology: beside its own words it would only repeat
them, and the system's name for a glyph ("tray", "pencil") is not what it means on the screen. A meaningful standalone
icon is made with a label, which names what it means there, not what it draws ("Today", not "Sun"); it is then announced
as an image with that label. An icon-only control is labeled by the control, not by its icon (Button, iconOnly). An icon
is never the only signal of a status: a status glyph comes with a word or a value (design-language/07, 08).

## Behavior

Next to text, an icon takes that text's role for its size and its weight, so it sits on the line like a letter and grows
with the person's text size; without text, it takes the role of its control's label; it never has a size of its own.
Where it must be smaller or larger than its text, it takes the platform's relative scale, small, medium or large. It has
no color option: it draws in the color its context gives it, and that is one of the roles chapter 07 lists, the color of
the text it goes with, color.status.<name>.icon for a status glyph, color.category.<name>.icon for a list's glyph,
color.icon.tertiary for a chevron or a grip, or the on-fill color of a solid fill it sits on (on-accent, a status's
on-fill, a list's on-fill). It is drawn in one color, outlined at rest; a filled glyph marks a state. The component has
no states. An icon inside a shape, such as a list's tile, is a component of its own (phase 4).

## On Apple

Icon(.tray) draws the glyph's SF Symbol and is hidden from assistive technology; Icon(.sun, label: "Today") is announced
as an image labeled "Today", and Icon(.folder, label: list.title) takes a label that is not localized, as Label(_:icon:)
takes its title. Icon is a view of westron's own, not an initializer of SwiftUI's Image: an Image of an SF Symbol always
carries the system's spoken name of the symbol ("Increase Brightness" for the sun), and SwiftUI has no initializer of an
Image of a symbol and no modifier returning an Image that hides it or names it (decisions/0001, "The Apple view").
Image(_: Westron.Icon) stays an adapter, not this component, for where only an Image fits, such as Text interpolation:
it keeps the system's name. Label("Rename", icon: .pen) keeps the system Label, as Label(_:systemImage:) makes it, so
whether its icon is hidden beside its title is the system's choice: in a control the title names it, and on its own iOS
26.3 has been seen both to read the symbol's system name before the title and to read the title alone. Hiding its icon
would hide a menu item built from the label as a whole, so westron leaves it as the system makes it (decisions/0001,
"The Apple view"). The glyph is the SF Symbol the registry names: a symbol takes the font of its context
(.textRole(_:)), which gives it the size and the weight of the text beside it, and the context's foregroundStyle, which
gives it its color; rendering is monochrome. scale is SwiftUI's own Image.Scale, which the product sets with
.imageScale(_:) on the icon or its container and the symbol inside reads from the environment, so Icon takes no scale
argument and no enum is generated. Weight, measured on iOS and macOS: at rest a symbol takes the weight of the role
around it, in the system font and in Onest and Geist Mono alike (Onest ExtraBold reads as regular, but no role draws it
at rest). Under Bold Text it differs from the text beside it: the symbol takes its font's weight and then the system's
Bold Text step, and a role in Onest or Geist Mono has already taken the heavier instance, so its icon steps twice and
draws heavier than its text, black beside heading.large's Onest ExtraBold, heavy beside code.regular's Geist Mono
SemiBold; beside a system-font role, text and icon take one step together (decisions/0001, open points). westron's own
glyphs become custom symbols built from a variable template, so they get the same weights, scales and alignment, with
phase 6 (design-language/07, open question 1). On watchOS the icon is drawn as on the other OSes; every role there is
the system font, so the Bold Text difference does not arise.
