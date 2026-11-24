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
```

What WestronUI declares for it:

```swift
extension View {
    public func toggleStyle(_: ChipVariant) -> some View
    public func buttonStyle(_: ChipVariant) -> some View
    public func labelStyle(_: ChipVariant) -> some View
}
public enum ChipVariant: String, CaseIterable, Sendable { case chip }
```

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
- **The caller gives every instance a label**: it is the accessible name, also where it is not drawn. Name what it does
  or holds, never what it looks like.

The label is the accessible name, the whole of it also when it is truncated; the icon beside it, and the check in its
place, are decorative and hidden. These fields are the selectable form's, which the other forms replace in `forms`. The
selectable form is the platform's own toggle: it keeps the role and the traits of a toggle, is toggled, and is announced
with its value, on or off, in the platform's words, in either state; it is not announced as selected, which would say
the state twice (design-language/08, "A system control keeps its own role and traits"). The pressable form is a button
that is activated, with no checked state. The static form adds no role of its own: its label is read as text, and it
takes no intents. In disabled, a selectable or pressable chip is announced as unavailable.

## Behavior

One look in three forms, which the product picks by the control it writes. Selectable: a filter that is on or off, such
as a tag chip of a tag bar; it is in the state checked while it is on. Pressable: a value that opens something when
pressed, such as a card's day, deadline or tag pill, which opens a picker. Static: a value shown and not acted on, such
as the tag in a task row's line of metadata on the Mac, whose row is the control. Which states each form enters is in
`forms`. It is the platform's capsule at any height, its ends round when the text grows (design-language/04), flat, with
no shadow, glass or material. At rest it is filled with color.background.muted, its label in color.text.primary and its
icon in color.text.secondary. Checked, it is filled with the list's color, its label and icon are drawn in the words'
color on that fill, and it shows a mark (design-language/08, "A checked control shows a mark"): the registry's check
glyph in the icon's place, at the icon's size and in icon.color, decorative and hidden from assistive technology. A chip
with an icon swaps its icon for the check while it is on and keeps its width; a chip whose label is only text grows by
the check and container.gap before its label while it is on, as Material's filter chip does. The fill is not the only
sign that it is on (decisions/0001, Q9 and Q5, revised after the audits, where the contrast of each fill is measured).
The list's color comes from the context, the accent when the context sets none, as Checkbox's does. With the accent the
fill is color.background.accent and the words color.text.on-accent; with a list's color the fill is
color.category.<name>.fill and the words color.category.<name>.on-fill, the roles design-language/02 gives a lit tag,
for each of the twelve list colors. The bindings below are the accent's, since the list's color is the context's and not
an option; this text is the contract for a list's color, and for the check, a glyph and not a token. Under the pointer
and pressed, an unchecked chip's fill darkens a step each, to color.background.muted-hover and muted-pressed, and a
checked chip's accent fill to color.background.accent-hover and accent-pressed, as the bindings say; a checked chip in a
list's color keeps its fill under the pointer and pressed, since the list colors have no hover or pressed fill
(decisions/0001, Q4). A disabled chip never enters hover or pressed: its fill stays as at rest and it does not scale. A
press tints the fill and scales the chip down to 98 % in motion.press, and Reduce Motion drops the scale and keeps the
tint; a hover tint changes in motion.fade; checking changes the fill and the words' color and brings the check in or
out, as a fade, in motion.fade, and a text-only chip's width changes with them (design-language/05). With Reduce Motion
the fades stay, and a text-only chip's width changes at once, so that nothing slides: the check fades in, and leaves at
once with its room. In the high-contrast themes every chip also draws an outline, color.border.strong at stroke.thin,
over its fill, in every state, as Button's secondary does: the muted fill alone stands about 1.1:1 off the canvas, and a
list's fill is not held to a contrast on the ground (design-language/02, 08). The height is size.control.s, a minimum:
the chip grows with the person's text size and stays a capsule. The label is one line: it never wraps. The product gives
a chip the width its label needs, in a tag bar that scrolls or a row that wraps; truncation is the last resort, since
the truncated words are then whole only to a screen reader: where the container gives the chip less width than its label
needs, the label is truncated at its end with an ellipsis, and the whole label stays the accessible name. The hit area
of the selectable and pressable forms is a laid-out frame at least size.target.minimum high and at least
size.target.minimum across, around the drawn chip, which keeps its own size, centred in it: a chip of one or two letters
is narrower than the target, and its hit area is still the target. Since the frame is laid out, chips side by side never
overlap: where a short chip's frame is wider than its capsule, its neighbors move apart by the difference instead of
sharing a gap of 6 pt. Disabled draws the whole chip at opacity.disabled, with no colors of its own. The static form
enters no state: under .disabled(true) or its platform's equivalent it is drawn as it is, undimmed. A chip has no remove
button, no size option and no icon-only form: the pilot needs none of them (AGENTS.md, rule 6).

## On Apple

Three forms on three system bases (decisions/0001, Q1): selectable, the system Toggle, Toggle(isOn: $isPicked) {
Label(tag.name, icon: .hash) }.toggleStyle(.chip), checked being configuration.isOn; pressable, the system Button,
Button { openPicker() } label: { Label("Tue", icon: .sun) }.buttonStyle(.chip); static, the system Label,
Label(tag.name, icon: .hash).labelStyle(.chip), whose style, as the system's label styles do, also reaches every Label
below the modifier. The list's color reaches the style through .category(_:), as it reaches Checkbox: set once around
the tag bar, .category(Westron.Category(rawValue: list.color)). The label and the icon are the title and the icon of a
Label in the control's label (spec/conventions.md, "Slots"); the icon is the symbol's small scale in the label's text
role, its baseline on the label's, as Button's is, and the check is the registry's check glyph drawn the same way. Which
a label is, a Label with an icon or only text, the style learns in the same update from the label's layout, as Button's
loading indicator does. ToggleStyleConfiguration has no isPressed, so the selectable style follows a press as Checkbox's
does (Checkbox's decisions/0001, P19): its body is a system Button that toggles the value, and for assistive technology
it is replaced by the system's own Toggle on the same value and label (accessibilityRepresentation), as Checkbox's is,
so assistive technology meets the toggle's role, its traits and its value, on or off, and no button (decisions/0001, Q6,
revised after the audits). The focus ring is the system's, so the focusRing bindings do not apply, as for Button. The
high-contrast outline follows colorSchemeContrast, as Button's does. The hit area is laid out, not only hit-tested: a
frame of at least size.target.minimum high and across around the drawn chip, as Checkbox's square is (Checkbox's
decisions/0001, P17; decisions/0001, Q11), every point of it taking the press; the accessibility shape is the drawn
capsule (contentShape(.accessibility, …)), as Button's is.

### iOS

Hover only with a pointer, on iPad; an iPhone never enters it. The hit area is at least 44 pt high and 44 pt across
around the 28 pt chip. Measured on iOS 26.3 as XCUITest reads the hierarchy (CatalogUITests/ChipBehaviorTests), not with
VoiceOver itself: the selectable chip is a switch with its label and its value 0 or 1, never selected, and no button,
the text-only chip too; the pressable chip a button with its label, never selected; the static chip its text; the
disabled samples not enabled; a truncated label the whole name. Under the pressable chip XCUITest lists nothing: the
icon and the check are hidden, then represented by nothing, as a westron Button's icon is (#131). The element's frame is
the 44 pt hit area, not the drawn capsule, with contentShape(.accessibility, …) set as Button's is.

### macOS

The hit area is at least 28 pt high and 28 pt across around the 24 pt chip. Hover starts and ends at the drawn capsule,
not in the hit area's margin nor in the corners of the capsule's frame beyond its round ends: the pointer's place in the
chip's frame is tested against the capsule (onContinuousHover), since onHover reports the whole frame whatever its
content shape (decisions/0001, "Measured on macOS"). The click is taken in the whole hit area. The system's focus ring
follows the drawn capsule (contentShape(.focusEffect, …)), as Button's does. The selectable chip's representation is the
system Toggle, a checkbox on macOS, as Checkbox's is. Measured on macOS 26.7 as XCUITest reads the hierarchy
(CatalogUITests/ChipBehaviorTests), not with VoiceOver itself: the selectable chip is a checkbox with its label and its
value 0 or 1, never selected, and no button; the pressable chip a button with its label and nothing under it; the static
chip a text whose words are its value; the disabled samples not enabled; a truncated label the whole name. The element's
frame is the 28 pt hit area, and a click 1 pt above the drawn capsule toggles. Keyboard focus follows the system's
controls, as Checkbox's does; it is not measured, since keyboard navigation was off on the Mac that ran the tests.

### watchOS

As plain as the schema allows until #34 decides the watchOS subset of westron's components: no pointer, so no hover, and
no keyboard focus to draw. The style is the same code as on iOS. The hit area is at least 44 pt high and 44 pt across,
size.target.minimum, around the 32 pt chip, size.control.s. The pilot has no watchOS screen with a chip.
