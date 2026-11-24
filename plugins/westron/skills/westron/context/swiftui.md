<!-- Generated from spec/conventions.md by `tools/westron generate`. Do not edit: change the source and generate again
(decisions/0016). -->

# westron in SwiftUI

How each concept of a component contract becomes SwiftUI API, and what stays the system's: from westron's platform
conventions. A card names these concepts; this page says what each means in code. A reference such as "decisions/0003"
or "#33" points into westron's repository and is not in this bundle.

## A style on the system control, not a wrapper

```swift
Button("Save") { save() }
    .buttonStyle(.primary, size: .m)
```

A system control keeps focus, keyboard support, VoiceOver traits, Liquid Glass adaptation and the next OS release
(chapter 09). A wrapper type would rebuild them, and its name would collide with `SwiftUI.Button` in every file that
imports SwiftUI. So westron has no wrapper types and no prefix (decisions/0003). The product writes the system
control, and westron adds one modifier.

What the system presents takes no westron component and no style: a menu and a context menu, an alert or a
confirmation dialog, a sheet, swipe actions, the empty state's `ContentUnavailableView`. The product writes them, and
westron styles what is inside them with its existing styles (decisions/0014, chapter 09).

So too search: `.searchable(text:)` is the system's search field, placed and drawn by the system in a navigation bar,
a toolbar or a sidebar, and a product that searches there writes it unstyled. A search field the product places
itself, in its own bar or in content, is westron's TextField with glyphs, `.textFieldStyle(.framed, leadingIcon:
.magnifier)`, to which the product adds the search field's trait, `.accessibilityAddTraits(.isSearchField)`, and its
name (spec/components/text-field, decisions/0003).

## The concepts in SwiftUI

### Component id and naming

System control: no westron type. The contract binds to the system control (`Button`), and westron adds an overload of
its style modifier. Own component: the shape its `platforms.apple.form` names, no prefix: a modifier on `View` named
after the id in lowerCamelCase (`surface` → `.surface(.raised)`), or a `View` named after the id in UpperCamelCase
(`rule` → `Rule()`). Generated types are `<Component><Option>`: `ButtonVariant`, `ButtonSize`. A name that would collide
with a SwiftUI type is recorded in the `platforms` block (decisions/0003, point 3)

### Forms (`forms`, `bases`)

One overload per form, of its base's style modifier, each applying its own hand-written `<Component><Control>Style`:
`.toggleStyle(.chip)`, `.buttonStyle(.chip)`, `.labelStyle(.chip)`; the product picks the form by the control it writes

### Enum option: the variant

A generated `public enum ButtonVariant: String, CaseIterable, Sendable`; cases are the contract's values in
lowerCamelCase. It is the first, unlabeled argument of the style overload and has no default, so it is always written:
`.buttonStyle(.primary, size: .m)`, `.buttonStyle(.secondary)`; the contract gives the variant no default. A value must
not match a system style's static name (`plain`, `bordered`, …); the validator checks it (#18). Another enum option is a
labeled argument named after it. Own component: the same generated enum; the first, unlabeled argument of its modifier
(`.surface(.raised)`); a view with a variant is not derived yet (Q2)

### Option whose values are tokens (`type: tokens`, `group: typography`)

The accessor of the token group, which the token generator already writes (decisions/0010): `Westron.TextRole` for
`typography`, its values the group's tokens, `.heading.large`. No `<Component><Option>` enum is generated, since the
values are the tokens', and its names follow them.

### Option whose values are icons (`type: icons`)

`Westron.Icon`, the enum the icon generator already writes from `spec/icons/icons.yaml` (decisions/0011), whose cases
are the registry's names (`AppleIcons.iconType`). No `<Component><Option>` enum is generated. On an own view it is the
glyph the view draws, its first, unlabeled argument: `Icon(.tray)`. On a style, an option with `optional: true`, a glyph
a use may leave out, is a labeled argument of the overload that defaults to none, `<name>: Westron.Icon? = nil`, among
the labeled arguments in the contract's order of options, as every option is:
`.textFieldStyle(.framed, leadingIcon: .magnifier)` (TextField, #115). `optional` is allowed only there (`spec check`):
an own view's glyph is named in every use. A style's icons option every use names, an extension's or an own modifier's
is not derived yet: generation and the parity lint report it as not supported

### Size option

A generated `public enum ButtonSize` with the contract's values `s`, `m`, `l`, never `small/regular/large`. A labeled
`size:` argument of the style overload. When the call leaves it out, the size comes from `@Environment(\.controlSize)`:
`mini` and `small` → `s`, `large` and `extraLarge` → `l`; an explicit `size:` wins. What `size:` does to `controlSize`
inside the label is Q5

### Bool option

A labeled `Bool` argument of the style overload, named as in the contract, with the contract's default:
`.buttonStyle(.primary, size: .m, iconOnly: true)`; so too on an own component's modifier or initializer,
`.surface(.sunken, outlined: true)`. Not an environment modifier, which would make the option look like a state, and not
a system modifier the style cannot read (`.labelStyle(.iconOnly)`, see "Slots"). A bool that is a state follows the
state rows

### States the system control has (pressed, hover, focus, disabled, checked)

The system owns them, and the style reads them: pressed is `configuration.isPressed`, disabled is
`@Environment(\.isEnabled)` set by `.disabled(_:)`, focus is `@Environment(\.isFocused)`, hover is `onHover`. A control
whose value is on or off is in `checked` when it is on: `ToggleStyleConfiguration.isOn`; its configuration has no
`isPressed`, so a toggle style follows a press itself, as it follows hover (`SystemStyles`). Touch iOS and watchOS never
enter hover, and `onHover` does not exist on watchOS. The system draws the focus ring (chapter 08), except where a
component's contract says westron draws it: today the text field's, on iOS and macOS (spec/components/text-field, the
owner's decision of 2026-11-18). A text field style reads focus with a `@FocusState` it binds to the field:
`@Environment(\.isFocused)` there describes the field's ancestors, not the field. Where states hold at once, the first
matching case of a binding wins, as the contract orders them

### States the system control lacks (loading)

A modifier sets an environment value, and the style reads it (decisions/0003): `.loading(isSaving)`. One shared modifier
per state, named as the state, for every component that has it: `.loading(_:)`, not `.buttonLoading(_:)`

### Context a style reads (a list's color)

A value a contract takes from the context, not from an option or a state: one shared modifier, named after the token
type it takes, sets an environment value that every westron style which takes it reads, and it cascades like
`.tint(_:)`: `.category(_: Westron.Category?)`, nil each contract's default: the accent for Checkbox (#31), the neutral
tile for IconTile (#118). A reviewed adapter for the parity lint, in a file of its own

### Slots

System control: the control's own `@ViewBuilder` label. The contract's `label` and `icon` are the title and the icon of
a `Label` inside it: `Button { save() } label: { Label("Save", icon: .check) }`. A decorative glyph beside a control
whose label is no `Label`, as a text field's, is not a slot but an optional option whose values are icons, an argument
of the style (row above; TextField's `leadingIcon`). Own component: a `@ViewBuilder` closure per slot, named after the
slot, plus convenience initializers that take text and a `Westron.Icon`, as SwiftUI's `Label` does

### Extension of a system view (`extension-on-system-control`)

The base takes no style (SwiftUI has no `textStyle`), so westron adds a modifier in `extension View`, named after what
it sets, and the same on the base where the base's own modifiers return it: `.textRole(.heading.large)` on any view, and
`Text.textRole(_:) -> Text`. No westron type and no style. The base is one of `SystemStyles.withoutStyle`; a base with a
style modifier takes a style instead, and `spec check` reports the other strategy

### Constraints between options

The contract states them (`when` / `require` / `severity`) and the validator checks the contract (#18). What code does
with a forbidden combination is Q3. A constraint on a slot (`when: { slots: [label] }`, severity `error`, one value for
each option it requires), allowed only on an own view whose one slot is a drawn label, is kept by the API: the
initializers that take the slot leave those options out (Rule: `Rule("Work")` takes no axis and no purpose).

### Token bindings

Written by hand in the style's or the component's body (decisions/0001), through WestronUI's accessors:
`.background(.background.accent, in: …)`, `.radius.control`, `.textRole(.body.strong)`, `.animation(.press, value: …)`.
A part's `shape: capsule` is SwiftUI's `Capsule()`, never a large radius (design-language/04). No raw values: the
raw-values lint and the `spec-reviewer` subagent check them (decisions/0005)

### Accessibility: role

System control: it keeps its own role and traits (chapter 08). Own component: `.accessibilityElement(children:)` and
`.accessibilityAddTraits` (`.isButton`, `.isHeader`, `.isSelected`, `.isToggle`). Role `none`: nothing on a container,
whose children stay as they are (Surface). Role `heading`: `.accessibilityAddTraits(.isHeader)` on the drawn label, and
an instance with no label, which has nothing to announce, `.accessibilityHidden(true)` (Rule). Role `disclosure`: what
the system's own `DisclosureGroup` is on each OS, a disclosure triangle valued 1 or 0 on macOS and a button with no
value on iOS, named by the label, as the representation of the style's own control (Disclosure)

### Accessibility: intents

`.accessibilityLabel`, `.accessibilityValue`, `.accessibilityAction(named:)`, `.accessibilityAdjustableAction`,
`.accessibilityAction(.escape)` for dismiss

### Accessibility: a label that is not drawn (`hiddenLabel`)

An initializer of the base control that takes no label view and requires the name:
`Toggle(isOn: $done, accessibilityLabel: title)`, with a `StringProtocol` twin; its label is an `EmptyView` carrying the
name, so nothing is drawn or laid out on any OS. Not `.labelsHidden()` alone, which a custom style sees only from iOS
18, macOS 15 and watchOS 11

### Accessibility: keyboard intents

System control: the system handles activation and focus. Own component: `.focusable()`, `.onKeyPress` (iOS 17, macOS 14;
not on watchOS), `.keyboardShortcut` (not on watchOS); on macOS also `.onMoveCommand` and `.onExitCommand`. On watchOS
the Digital Crown: `.digitalCrownRotation`

### The `platforms` block and recorded differences

The Apple entry names the strategy (a style on a system control, or an own component), the base control, and what each
of iOS, macOS and watchOS supports, with a reason for each deviation; the fields come with #18. Code that one OS needs
goes behind `#if os(…)`. The parity lint (#21) compares the public API with the contract and this block. A value an OS
does not support keeps its enum case on every OS, and the style falls back to the value the block's `fallback` names: a
watch draws `.buttonStyle(.primary, size: .l)` at `m`

### Defaults

An option's contract default is the argument's default value. An option with no default in the contract is a required
argument: the variant has none, so it is always written. The size is the exception: left out, it comes from
`controlSize`, and its contract default is the size `regular` maps to, `m`

### Modes: theme, contrast, density

Not options: a contract has no density option (chapter 00, principle 4). Theme and contrast switch in the colorsets by
themselves (decisions/0010). Density is an environment value set by a `density` modifier; its API arrives with #33
