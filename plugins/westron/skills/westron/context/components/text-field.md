<!-- Generated from spec/components/text-field/text-field.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# TextField

`text-field` · approved · a style on `SwiftUI.TextField` · used by todo-app/lists-screen, todo-app/list-screen

A field a person types text into: westron's style on the platform's own text field, which keeps editing, selection,
input methods, the keyboard and the system's text input.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
TextField(…)
    .textFieldStyle(.framed)
```

What WestronUI declares for it:

```swift
extension View {
    public func textFieldStyle(
        _: TextFieldVariant,
        size: TextFieldSize? = nil,
        leadingIcon: Westron.Icon? = nil,
        trailingIcon: Westron.Icon? = nil
    ) -> some View
}
```

Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. A product's shared
code, which cannot import SwiftUI, imports `WestronContract` instead, and its models keep these values, never a size, a
color or a font:

```swift
public enum TextFieldVariant: String, CaseIterable, Sendable { case framed, inline }
public enum TextFieldSize: String, CaseIterable, Sendable { case s, m, l }
```

The option `lines` is the system's own `SwiftUI.Axis`: the product sets it where SwiftUI takes it, and westron reads it
from there. westron adds no argument for it.

## Options

- `variant`, `TextFieldVariant`: `.framed`, `.inline`; no default. No default: every use names its variant. The system's
  own style names (automatic, plain, roundedBorder, squareBorder, bordered) are not values: westron's overload would
  shadow them (decisions/0003).
- `size`, `TextFieldSize?`: `.s`, `.m`, `.l`; left out, the size comes from `controlSize` (`regular` is `.m`). framed:
  the height is size.control.s, m or l, 24, 32 and 40 with a pointer (macOS), 28, 36 and 50 on iOS and iPadOS, 44 on
  watchOS, as a minimum, so the field grows with its text; its padding follows the size, and its text is body.regular at
  every size. A field drawn below size.target.minimum, the platform's recommended target, 28 pt on macOS and 44 pt on
  iOS, keeps a hit area of that height (design-language/08): at s on macOS, at s and m on iOS. inline takes its height
  and its text role from its context, so the size changes nothing on it. Where an OS lacks a value: on watchOS it draws
  `s` as `m` and `l` as `m`.
- `lines`, the system's `SwiftUI.Axis`: the values `single`, `multiple`; by default `single`. single is a field of one
  line, whose text scrolls sideways, such as a list's name; multiple is a field whose text wraps and which grows a line
  at a time, such as a card's notes. framed draws single as a capsule and multiple as a rounded rectangle of radius.150,
  its lines held off its top and bottom edges by a padding that, at the default text size, makes a field of one line as
  tall as a single one of its size, and that does not grow with the text, as the minimum heights do not; inline draws
  both alike. On Apple it is the system field's own axis (platforms.apple.systemOptions).
- `leadingIcon`, `Westron.Icon?`: a name of the icon registry (`../icons.md`); by default `nil`, no glyph. The glyph at
  the field's start, a name of the icon registry that names what the field is for, never an action, or none, which draws
  no glyph there and gives the text that room. A search field's magnifier. It is decoration and says nothing to
  assistive technology, so the field's label still names the field.
- `trailingIcon`, `Westron.Icon?`: a name of the icon registry (`../icons.md`); by default `nil`, no glyph. The glyph at
  the field's end, a name of the icon registry that names what the field is for, never an action, or none, such as a
  number sign at the end of a field that holds a tag's name. Decoration, as the leading one. A glyph that acts when it
  is pressed, or draws an action, such as a clear mark or a microphone that starts dictation, is not this option
  (decisions/0003-icons-at-the-start-and-the-end.md).

## Slots

`label` and `placeholder`: through the system control's own initializer and label, never a westron parameter.

## States

- `focus`: the system's keyboard focus. Never entered on watchOS.
- `disabled`: `.disabled(_:)`, the system's.

## Accessibility

- Role: `textField`. A person can edit it. Announced: `disabled` as disabled.
- **Every instance needs an accessible name**: the label the system's own initializer of `TextField` takes, its title or
  the view of its `label:`. westron adds no parameter for it. Name what it does or holds, never what it looks like.

More: `text-field.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI
builds it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or
"#120" points into westron's repository, not into this bundle.
