<!-- Generated from spec/components, tokens/westron.resolver.json, spec/icons/icons.yaml, spec/conventions.md,
design-language and spec/patterns by `tools/westron generate`. Do not edit: change the source and generate again
(decisions/0016). -->

# westron: index

westron is a design system: tokens, component contracts, a design language, and on Apple the SwiftUI library WestronUI.
Read this file first, then only the files the task needs: the cards of the components a screen uses, and the pattern of
its job where there is one. Paths are relative to this file; the rules for using westron are in `../SKILL.md`.

## Components

`import WestronUI`. Each line: the card, the shortest call, what the component is. A card ends with a
pointer to its details file, the contract's prose, for cases the card does not settle.

The option enums the cards list (`ButtonVariant`, `ButtonSize`, …) are in `WestronContract`, which `WestronUI`
re-exports. A product's shared code, which cannot import SwiftUI, imports `WestronContract` instead, and `WestronTokens`
for `Westron.Icon` and `Westron.Category`; neither imports anything.

- [Button](components/button.md), `.buttonStyle(…)`: A push button that runs an action: westron's style on the platform's own button, with a label and a leading icon.
- [Checkbox](components/checkbox.md), `.toggleStyle(…)`: The round check that marks a task or a subtask done: westron's style on the platform's own toggle, which keeps its role, its value and its keyboard.
- [Chip](components/chip.md), `.toggleStyle(…)`, `.buttonStyle(…)` or `.labelStyle(…)`: A compact capsule with a short label and an optional leading icon: a tag, a filter, a value.
- [Disclosure](components/disclosure.md), `.disclosureGroupStyle(…)`: The collapse chevron of a group that folds and unfolds: westron's style on the platform's own disclosure group, which keeps its role, its expanded or collapsed value and its binding.
- [Icon](components/icon.md), `Icon(.tray)`: An icon of westron's registry, drawn as the platform's own glyph image: westron adds the names, how a glyph is drawn and what assistive technology hears of it (design-language/07, decisions/0011).
- [IconTile](components/icon-tile.md), `IconTile(.tray)`: A list's mark: a rounded square in the list's color with the list's glyph on it, which stands beside a list's title in a row, a screen header, a picker and the card a drag carries, and alone above the words of an empty screen.
- [ListRow](components/list-row.md), `ListRow(action: { … }) { … }`: The core row of a list or a tree: a title, a second line under it, a leading slot and a trailing slot, at a nesting level with guide lines, on a highlight that shows hover, pressed, selected and a drop onto it.
- [Rule](components/rule.md), `Rule()`: A straight line that separates two groups, or marks where a dragged item would land: westron's own line, the same on every platform, rather than the system's separator, whose thickness and color the system fixes.
- [Surface](components/surface.md), `content.surface(.raised)`: The ground a card or a panel stands on, which westron draws behind content the product lays out: a background, a corner and, where it stands off what is under it, a shadow.
- [Text](components/text.md), `Text("…").textRole(.body.regular)`: A text role on the platform's own text view: westron adds no text type of its own, only the role.
- [TextField](components/text-field.md), `.textFieldStyle(…)`: A field a person types text into: westron's style on the platform's own text field, which keeps editing, selection, input methods, the keyboard and the system's text input.

## Patterns

A pattern composes westron's components, the system's containers and tokens for one job on a screen: which component
takes which part, with which options, what stays the system's, what assistive technology hears, and one complete SwiftUI
example. It is rules and an example, not an API: its calls are the cards'. Read the pattern for a job before composing
its screen.

- [A list of choices in a sheet](patterns/choice-list-sheet.md): Pick one place or value from a list or a tree in a system sheet; the current choice checked, one tap takes one.
- [An empty state](patterns/empty-state.md): What a screen shows when it has nothing; the system's ContentUnavailableView with the thing's IconTile, a title, a line that says what fills it and at most one action.
- [Errors beyond a field](patterns/errors.md): How a screen says that something failed, or asks before what cannot be undone; the system's alert with a destructive action and Cancel for a confirmation, a status line in place, with a retry where one can mend it, for a failure.
- [A form](patterns/form.md): Fields a person fills and the product keeps; framed fields with a label above, an error or a hint under each, Cancel and one primary Button at the end, or inline fields kept as they are typed.

## Tokens

- [Colors](tokens/color.md): 66 semantic colors, `Westron.Color`: `.foregroundStyle(.text.primary)`, `.background(.background.surface)`; 12 list colors, `Westron.Category`
- [Text roles](tokens/typography.md): 17 text roles, `Westron.TextRole`: `.textRole(.body.regular)`
- [Space, size, radius, stroke and opacity](tokens/layout.md): 39 lengths, `CGFloat` in points: `.padding(.space.card)`, `VStack(spacing: .space.withinGroup)`, `.radius.card`, `.stroke.thin`, `.size.target.minimum`; 1 number, `Double`: `.opacity.disabled`
- [Motion and shadows](tokens/motion-and-shadow.md): 8 motions, SwiftUI `Animation`: `.animation(.fade, value: …)`; 3 shadows, `Westron.Shadow`: `.shadow(.raised)`

## Icons

- [Icons](icons.md): 36 names, `Westron.Icon`: `Icon(.tray)`, what each draws and its SF Symbol

## SwiftUI

- [westron in SwiftUI](swiftui.md): how a contract's options, states, slots and accessibility become SwiftUI API, and what stays the system's

## Design language

Why westron looks and behaves as it does; read a chapter when a card or a token points to it.

- [00. Principles](design-language/00-principles.md): The rules that decide the cases the other chapters do not cover
- [01. Tone](design-language/01-tone.md): The voice of interface copy and direction B's visual temperament
- [02. Color](design-language/02-color.md): Cool neutrals, the cobalt accent, statuses, list colors, charts, the four themes, contrast
- [03. Typography](design-language/03-typography.md): Onest headings, the system font for body text, Geist Mono for code, the seventeen text roles
- [04. Shape](design-language/04-shape.md): Radius roles, strokes, two-layer shadows by theme
- [05. Motion](design-language/05-motion.md): The eight motions, one spring model for every platform, Reduce Motion
- [06. Layout](design-language/06-layout.md): The space ladder, direction B's rhythm, density, size by platform
- [07. Icons](design-language/07-icons.md): Icon names, system icons and westron's domain set, status glyphs, size relative to text
- [08. Accessibility](design-language/08-accessibility.md): Targets and how westron checks them
- [09. Platform adaptation](design-language/09-platform-adaptation.md): What stays with the system and what westron controls (#9)
