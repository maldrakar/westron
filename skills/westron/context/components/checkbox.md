<!-- Generated from spec/components/checkbox/checkbox.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# Checkbox

`checkbox` · approved · a style on `SwiftUI.Toggle` · used by todo-app/list-screen

The round check that marks a task or a subtask done: westron's style on the platform's own toggle, which keeps its role,
its value and its keyboard.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Toggle(…)
    .toggleStyle(.check)
Toggle(isOn: $isOn, accessibilityLabel: "…")
    .toggleStyle(.check)
```

What WestronUI declares for it:

```swift
extension Toggle where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier> {
    public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey)
    @_disfavoredOverload public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S)
}
extension View {
    public func toggleStyle(_: CheckboxVariant) -> some View
}
public enum CheckboxVariant: String, CaseIterable, Sendable { case check }
```

## Options

- `variant`, `CheckboxVariant`: `.check`; no default. The round check; the only variant. The system's own style names
  (automatic, switch, button, checkbox) are not values: westron's overload would shadow them (decisions/0003).

## Slots

`label`: through the system control's own initializer and label, never a westron parameter.

## States

- `checked`: the toggle's value, `isOn`.
- `pressed`: the system's, while a press is held.
- `focus`: the system's keyboard focus. Never entered on watchOS.
- `disabled`: `.disabled(_:)`, the system's.

## Accessibility

- Role: `checkbox`. A person can toggle it. Announced: `checked` as checked, `disabled` as disabled.
- **The caller gives every instance a label**: it is the accessible name, also where it is not drawn. Name what it does
  or holds, never what it looks like.
- A control beside its own title draws no label: write `Toggle(isOn: …, accessibilityLabel: …)`, which requires the
  name, and hide the title beside it from assistive technology.

The platform's own toggle role, announced as on or off, checked or unchecked, in the platform's words, with the label as
its name: the task's title. The label is required also where it is not shown beside the circle, as in a row whose title
is a separate text: such a check draws no label, takes no room for one, and is given the label as its accessible name
alone, where it is created, as a required argument (hiddenLabel; decisions/0002). The separate title is then hidden from
assistive technology, so the name is read once. In disabled, the check is announced as unavailable.

## Behavior

It is a circle on every platform, never a square box. Unchecked, it is a quiet ring in color.border.default at
stroke.regular, the same for every list. The ring stands about 1.27:1 off the canvas in light and 1.46:1 in dark, below
the 3:1 that WCAG 1.4.11 asks of a component's boundary: in the standard themes a deviation like the text field's, which
the owner accepted on 2026-11-20 for the field, taken for the ring too pending the owner's confirmation;
design-language/08 records it with the measured values (decisions/0003). In the high-contrast themes the ring is
color.border.strong at the same width, which meets the non-text target there. The bindings below cannot say this, since
a case has no contrast key, so this description is the contract for it, as Button's is for its outline. Checked, it is a
disc filled with the list's color with a check mark on it, so it shows a shape and not only a color
(design-language/08): the list's color comes from the context, the accent when the context sets none. With the accent
the disc is color.background.accent and the mark color.text.on-accent; with a list's color the disc is
color.category.<name>.control and the mark color.category.<name>.on-control, for each of the twelve list colors, the
disc meeting 3:1 as a non-text color on canvas, surface and sunken, 4.5:1 in high contrast. The bindings below are the
accent's, since the list's color is the context's and not an option of the contract; this text is the contract for a
list's color. Checking pops the disc and its mark in with motion.check, the one overshoot in westron: they scale up from
80 % to full size, and the spring's bounce carries them past it and back; Reduce Motion drops the scale and keeps the
fill appearing (design-language/05). Unchecking fades the disc and the mark out in motion.fade, with no pop. A press
scales the check down to 98 % in motion.press, as every control's press does (design-language/05, "Shapes belong to
components"), and Reduce Motion drops that scale too. The circle has no size option: it is sized by the text role of the
label beside it, as an icon is, and grows with the person's text size (design-language/07, "Size relative to text"). Its
hit area is at least the platform's recommended target, size.target.minimum, 44 pt on iOS and watchOS and 28 pt on
macOS, also where the circle is smaller (design-language/08). Disabled draws the whole check at opacity.disabled, with
no colors of its own; at the start of a disabled ListRow the row's dimming is that opacity, and the check does not dim
itself again (the ListRow contract: a disabled row dims its content once).

## On Apple

.toggleStyle(.check) on the system Toggle, with the text role set on the toggle, so that the label and the circle share
it: Toggle(task.title, isOn: $task.isDone).toggleStyle(.check).textRole(.body.regular). checked is configuration.isOn.
The list's color reaches the style through the environment: .category(_:), a shared modifier that takes a
Westron.Category? (nil, the default, is the accent) and cascades like .tint(_:), set once around a list's rows:
.category(Westron.Category(rawValue: list.color)). It is named for what it sets, not for the check, so that every
westron control that takes the list's color reads it; the API parity lint accounts for it as a reviewed adapter in its
own file (APIParity.otherAdapters, Category.swift), since no contract option can give it (decisions/0001, P15).
ToggleStyleConfiguration has no isPressed, so the style's body is a system Button that toggles the value, drawn by a
ButtonStyle, which sees isPressed; the button is the check's activation and its focusable element (keyboard focus on
macOS: platforms.apple.macos). For assistive technology the body is replaced by the system's own Toggle on the same
value and label (accessibilityRepresentation), so assistive technology is meant to meet the toggle's role and value and
no button. The circle's diameter is 1.2 times the line height of the text role that reaches the style, and its hit area
is a square of at least size.target.minimum and at least size.control.m around it, the label beside it included
(decisions/0001, P10, P16, P17; the minimum target since 2026-11-20, when size.control.m on iOS fell below the touch
target, so that no hit area shrank). A row whose title is a separate text writes its check with no drawn label, through
westron's initializer of the system Toggle that takes no label view and requires the accessible name, Toggle(isOn:
$task.isDone, accessibilityLabel: task.title).toggleStyle(.check), with a localized twin for a LocalizedStringKey; the
separate title is hidden from assistive technology, so the name is read once (the catalog's live row and
checkbox-in-list, CheckboxBehaviorTests). Its label is an EmptyView that carries the name (.accessibilityLabel(_:)), so
the style draws the circle's hit area alone, with no gap, and the system Toggle of the representation takes the name
from it: the same on every OS, measured on iOS 17.5 and 26.3 (decisions/0002). .labelsHidden() also hides the label, and
keeps it as the name, only from iOS 18, macOS 15 and watchOS 11, where a custom style sees it (labelsVisibility); on iOS
17, macOS 14 and watchOS 10 the style draws the label beside the circle, so a row with a separate title writes the
initializer, not .labelsHidden(). The focus ring is the system's, so the focusRing bindings do not apply, as for Button.
The mark is the registry's check glyph. The high-contrast ring follows colorSchemeContrast, as Button's outline does.

### iOS

The accessibility hierarchy holds the system Toggle of the representation: a switch with its label, its value on or off,
and no button, measured on iOS 26.3 as XCUITest reads the hierarchy (CatalogUITests/CheckboxBehaviorTests), not with
VoiceOver itself. On iOS 17.5 the check with no drawn label was measured the same way, as on iOS 26.3: a switch named by
its accessibility label, its value, a 44 pt square with nothing drawn beside the circle (decisions/0002); the rest of
the style runs the same code on iOS 17, not measured there. No hover. The hit area is at least 44 pt,
size.target.minimum.

### macOS

The system's checkbox toggle is square; westron's check stays round, as on the other OSes. The accessibility hierarchy
holds a checkbox with its label and its value, and no button, measured on macOS 26 as XCUITest reads the hierarchy
(CatalogUITests/CheckboxBehaviorTests), not with VoiceOver itself, the check with no drawn label included, a checkbox
named by its accessibility label in a 32 pt square (decisions/0002); macOS 14 runs the same code, not measured. The hit
area is at least size.control.m, 32 pt, above size.target.minimum, the recommended 28. Keyboard focus, measured with the
Mac's keyboard navigation off: neither westron's check nor a system Toggle in checkbox style takes focus, from Tab or
from code; with .focusable() added, both take focus and show the system's ring, and Space toggles neither. With keyboard
navigation on, Tab and Space are unverified, pending the owner's run of CheckboxBehaviorTests.testKeyboardFocusAndSpace
(decisions/0001, "Open points").

### watchOS

No keyboard focus to draw. The style is the same code as on iOS, the system Toggle of the representation included, and
it compiles for watchOS 10; nothing was measured on watchOS, VoiceOver included. The hit area is at least 44 pt,
size.target.minimum and size.control.m.
