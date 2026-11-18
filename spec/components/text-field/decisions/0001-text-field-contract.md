# 0001. The TextField contract

Date: 2026-11-18. Status: draft for approval (#30). The owner answered the interview on 2026-11-18. This record keeps
three things apart: what the owner answered, what the documents had already decided, and what the agent proposes on
top of both, which is still to confirm.

## Context

Both pilot screens have fields (decisions/0006, `research_notes/pilot-inventory.md` 1.4, 4.1, 4.2): on
`todo-app/lists-screen` the name field in a list's row and the area field, on `todo-app/list-screen` the list-name
field in a block's header and the title, notes and subtask fields inside an open task card. The pilot draws its row
field as a fill (`surface`) with a 2 pt accent ring when focused, and the card's fields with no frame at all. Every
platform has a system text field, so westron gives it a style (decisions/0003).

Issue #30 names "states, density, error states, hints". Density is settled: a contract has no density option; it is a
mode, set by the `density` modifier with #33 (spec/conventions.md, "Modes: theme, contrast, density"; design-language
00, principle 4). Error states and hints wait for a consumer (below).

## What the owner answered

### Two variants

- **Chosen: `framed` and `inline`.** `framed` is a field that stands on its own, the name field in a list's row;
  `inline` is a plain field set into the text it belongs to, the fields inside the task card. The system's style names
  (`automatic`, `plain`, `roundedBorder`, `squareBorder`, `bordered`) stay forbidden as values: westron's overload
  would shadow them (decisions/0003, and its note of 2026-11-18).

### `framed` at rest

- Considered: (a) an outline in `color.border.strong`, no fill of its own, the ground under it showing; (b) a fill
  only, as the pilot draws it; (c) both.
- **Chosen: (a).** A fill would need a new `background.field` and would miss 3:1 against near grounds; `border.strong`
  meets 3:1 by construction (design-language/02:25–27).

### Focus

- Considered: (a) westron's ring, `color.border.focus` at `stroke.thick`, on every Apple OS, macOS included, where the
  system's own ring is turned off; (b) westron's ring on iOS, the system's on macOS.
- **Chosen: (a).** On macOS the field's focus is then drawn in westron's focus color, not in the accent color the
  person chose. This differs from what design-language/08 and 09 say today, so it is recorded as the owner's decision
  for this component, here and in the contract's `platforms.apple.macos`, and the chapters are revised at approval:
  - design-language/08:123, "Focus is always visible, and the platform draws it. A custom component shows focus the
    way the platform does.";
  - design-language/09:54, the macOS row, "Stays with the system: … the focus ring".
  - To read at the same time, since they leave focus to the system in general: design-language/09:52 (Apple, all:
    "… text input, scrolling, focus"), design-language/00-principles:39 and decisions/0001:23 ("Left to the system:
    … text input, focus"). Focus itself, its order and the keyboard, stays the system's; only its drawing on this
    field changes, so these may need a clause rather than a revision.

### No error state, hint or message in version 1

- **Chosen: none.** No pilot screen shows one (AGENTS.md, rule 6), and a field marked only by a danger border would
  tell an error by color alone, which design-language/08:127–136 forbids. Issue #30's "error states, hints" wait for a
  consumer, which will bring a message with the border.

### Sizes

- Considered: (a) `s`, `m`, `l` as Button has them, default `m`, following `controlSize`; (b) one height.
- **Chosen: (a).** The pilot's row field is about `s`.

### The text role

- Considered: (a) `inline` takes its font from its context (the product sets `.textRole`), `framed` fixes its role by
  size as Button does; (b) always `body.regular`.
- **Chosen: (a).** An inline field is part of a text, the card's title or its notes, so it is set in that text's role.

## Already decided by the documents

| What | Source |
|---|---|
| `radius.control` is a field's radius | design-language/04:21 |
| `color.border.strong` draws a field's outline and meets 3:1 | 02:25–27, 04:58–59 |
| `color.border.focus` at `stroke.thick` is the focus ring | 04:51–54, 04:58–59 |
| A field's text is `typography.body.regular` | 03:49 |
| The placeholder is `color.text.placeholder` | the token's usage in `tokens/semantic/color.tokens.json` |
| Heights are `size.control.s`, `m` and `l`; `m` is the recommended target on touch; a control drawn at `s` keeps a hit area of the recommended size | 08:111–116, `tokens/platform/*.tokens.json` |
| Disabled is the whole control at `opacity.disabled`, announced as unavailable | 08:31–34 |
| A contract has no density option | spec/conventions.md, "Modes"; design-language/00, principle 4 |
| `SecureField` takes `textFieldStyle`, as `TextField` does | spec/conventions.md, "One base control, several components" |
| Text input stays the system's; westron styles the field | design-language/09:52, decisions/0001:23 |

## Proposed, to confirm

| # | Proposal | Reason |
|---|---|---|
| P1 | Strategy `style-on-system-control`, `base: SwiftUI.TextField`; the same style serves `SecureField` | The system field keeps editing, input methods and the keyboard (decisions/0003) |
| P2 | On Apple the style is a `TextFieldStyle`, whose only requirement is the underscored `_body(configuration:)`; the implementation probes it on iOS, macOS and watchOS and records what holds | `TextFieldStyle` has no public requirement in the Xcode 27.1 interface; if the probe fails on an OS, the contract records the difference first |
| P3 | `framed` by size: the height `size.control.s/m/l`; the padding `space.100/150/200`; the role `footnote.regular` at `s` and `body.regular` at `m` and `l` | Button's bindings are the model the owner named, in the regular weight of a field's text; `body.regular` at `m` is chapter 03's. **The pilot's row field, about `s`, draws body text (17 pt on the phone)**, so `footnote.regular` at `s` would shrink it; the alternative is `body.regular` at every size. The owner chooses |
| P4 | `framed`'s outline is `stroke.thin` | Chapter 04 names the outline's color, not its width; `stroke.thin` is the width of Button's `secondary` outline |
| P5 | The focus ring is drawn on both variants | Focus must always be visible (08:123); an inline field would otherwise show focus only by its caret. The owner may prefer the caret alone for `inline` |
| P6 | States `focus` and `disabled`; no `hover` | A field shows nothing on hover in the documents or the pilot; the pointer's I-beam is the system's |
| P7 | `inline` has no height, radius, outline, padding or fill, and takes its text role from the context; the size changes nothing on it | The owner's inline answer: it is part of the text around it |
| P8 | watchOS draws the system field as it is: a tap opens the system's text input, there is no focus to draw, and `roundedBorder` is not available there. `size` offers `m` with a fallback to `m`, and the states are `disabled` | The watch has no field to frame; the restriction keeps one generated enum for every OS (spec/conventions.md) |
| P9 | Slots `label` and `placeholder`, the system field's title and prompt; a multiline field is the system's `axis: .vertical` | The system field already has both; the card's notes are multiline |
| P10 | Accessibility: role `textField`, intents and keyboard intents `edit`, a required label, `disabled` announced as unavailable | A placeholder disappears as the person types, so it cannot be the field's name |
| P11 | Web, provisional: a native `<input>`, a `<textarea>` for multiline, with westron's CSS and the ring on `:focus-visible`; GTK, provisional: the stock `GtkEntry` with style classes, its focus ring decided in phase 7 | The native elements keep input; as Button's web and GTK entries |

## Open points

- **P3's role at `s`** is the one point where the owner's model (Button) and the pilot disagree.
- **The ring's place** (outside the outline, over it, or replacing it while focused) is left to the implementation and
  the snapshot matrix; the contract binds only its color and width.

## What the tools need before an approved TextField is generated

Nothing new: an approved contract generates today (checked on a copy with `status: approved`) `TextFieldVariant`
(`framed`, `inline`), `TextFieldSize`, `textFieldStyle(_ variant: TextFieldVariant, size: TextFieldSize? = nil)`, the
`controlSize` mapping, watchOS's fallback to `m`, and `TextFieldState` with `focus` not entered on watchOS, into
`WestronUI/Generated/TextField+Contract.swift`, and its matrix into `WestronCatalog/Generated/TextField+Matrix.swift`.
The implementation then writes `TextFieldVariantStyle` (the `_body(configuration:)` probe, P2) in `WestronUI` and
`TextFieldMatrixCell` in the catalog, and the parity lint holds the generated API.
