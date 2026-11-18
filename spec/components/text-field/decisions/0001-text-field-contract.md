# 0001. The TextField contract

Date: 2026-11-18. Status: accepted (#30), approved as written on 2026-11-18 under the owner's delegation of that day.
The owner answered the interview on 2026-11-18. This record keeps three things apart: what the owner answered, what the
documents had already decided, and what the agent proposed on top of both, which the approval confirms; the items
decided by the agent under the delegation stay marked so, pending the owner's confirmation.

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
- **Chosen: (a).** watchOS enters no focus (P8), so the ring is drawn on iOS and macOS, and the contract says so. On
  macOS the field's focus is then drawn in westron's focus color, not in the accent color the
  person chose. This differs from what design-language/08 and 09 say today, so it is recorded as the owner's decision
  for this component, here and in the contract's `platforms.apple.macos`, and the chapters are revised at approval:
  - design-language/08:123, "Focus is always visible, and the platform draws it. A custom component shows focus the
    way the platform does.";
  - design-language/09:54, the macOS row, "Stays with the system: … the focus ring";
  - spec/conventions.md:47, the row "States the system control has", "The system draws the focus ring (chapter 08)".
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
- **What "as Button does" can mean.** Button binds `footnote.strong` at `s` and `subheadline.strong` at `m` and `l`,
  never `body`; so the owner's model is the shape (a role fixed by the variant, not by the context), not Button's
  roles. Which role `framed` takes at each size is P3 below.

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
| P3 | `framed` by size: the height `size.control.s/m/l` and the padding `space.100/150/200`; the text `typography.body.regular` at every size. The size changes the frame, not the text | Chapter 03:49 makes a field's text `body.regular`, and the pilot's row field, about `s`, draws body text: 17 pt in a 34 pt field on the phone, 13 pt in a 24 pt field on the Mac (inventory:385, :439). `footnote.regular` at `s`, Button's smaller role in the regular weight, would shrink it to 13 pt on iOS and 10 pt on the Mac. The trade-off: at `s` the field is tight, 17 pt text in a 32 pt field on iOS and 13 pt text in 24 pt on the Mac, and it grows past `s`'s height at the larger text sizes, as the height is a minimum. Text role at every size: decided by the agent under the owner's delegation of 2026-11-18, pending the owner's confirmation |
| P4 | `framed`'s outline is `stroke.thin` | Chapter 04 names the outline's color, not its width; `stroke.thin` is the width of Button's `secondary` outline |
| P5 | The focus ring is drawn on both variants, on iOS and macOS | Focus must always be visible (08:123); an inline field would otherwise show focus only by its caret. The owner may prefer the caret alone for `inline` |
| P6 | States `focus` and `disabled`; no `hover` | A field shows nothing on hover in the documents or the pilot; the pointer's I-beam is the system's |
| P7 | `inline` has no height, radius, outline, padding or fill, and takes its text role and its text color from the context (the product sets `.textRole` and `.foregroundStyle`); the size changes nothing on it | The owner's inline answer: it is part of the text around it. The color follows for the same reason: the card's notes, an inline field, are in the pilot's secondary ink, its title in the primary (inventory:148–156) |
| P8 | watchOS draws the system field as it is: a tap opens the system's text input, there is no focus to draw, and `roundedBorder` is not available there. `size` offers `m` with a fallback to `m`, and the states are `disabled` | The watch has no field to frame; the restriction keeps one generated enum for every OS (spec/conventions.md) |
| P9 | Slots `label` and `placeholder`, the system field's title and prompt; a multiline field is the system's `axis: .vertical` | The system field already has both; the card's notes are multiline |
| P10 | Accessibility: role `textField`, intents and keyboard intents `edit`, a required label, `disabled` announced as unavailable | A placeholder disappears as the person types, so it cannot be the field's name |
| P11 | Web, provisional: a native `<input>`, a `<textarea>` for multiline, with westron's CSS and the ring on `:focus-visible`; GTK, provisional: the stock `GtkEntry` with style classes, its focus ring decided in phase 7 | The native elements keep input; as Button's web and GTK entries |
| P12 | On macOS a `framed` field at `s` keeps a hit area of at least 28 pt around its drawn 24 pt, as chapter 08 asks; no exception like Button's. Against it (the reviewer's counter-argument, as for Button's `s`): a frame grown past the drawn field takes clicks meant for a close neighbor, which is why the owner gave Button's `s` its drawn 24 pt (spec/components/button, decisions/0001) | Decided by the agent under the owner's delegation of 2026-11-18, pending the owner's confirmation; the owner may take Button's exception instead |
| P13 | `framed`'s text is `color.text.primary` | A field that stands on its own holds a name the person types, primary text on any ground (02:22–24); nobody decided it, so it is listed |

## Open points

- **What the implementation must show before the second gate:** whether a `TextFieldStyle` built on
  `_body(configuration:)` can read the field's focus (the configuration is the field itself, and
  `@Environment(\.isFocused)` may describe an ancestor), and whether `focusEffectDisabled()` turns off the system's
  ring around a macOS text field. If either fails, the contract changes first.
  The implementation's probe (#30, 2026-11-18) answered it: a `@FocusState` the style binds to the field reads its
  focus, and `@Environment(\.isFocused)` does not; `focusEffectDisabled()` does not turn off the ring of the default,
  bezeled macOS field, but the field drawn in the system's plain style inside westron's has no ring of its own. The
  contract's `platforms.apple` records both.
- **The ring's place** (outside the outline, over it, or replacing it while focused) is left to the implementation and
  the snapshot matrix; the contract binds only its color and width. The implementation's proposal is under "Decided at
  implementation", I4.
- **Left open by the implementation (2026-11-19), with no decision:**
  - an `inline` field has no hit-area rule: on macOS a one-line inline field takes clicks only in its own height,
    about 17 to 22 pt, below chapter 08's 28 pt (on iOS the system's touch tolerance reaches past it);
  - `framed` binds no vertical padding, so a multiline field and one-line text at the accessibility text sizes, which
    grow the field past its minimum height, touch the outline at the top and the bottom (Button has the same);
  - whether disabled removes the focus ring: the contract binds the ring on `focus` alone, so a focused field that is
    disabled keeps it, at `opacity.disabled`;
  - no token carries macOS's recommended target, 28 pt, so the style holds it as a literal with the lint's marker
    (`TextFieldTokens.swift`); a platform token for the target would remove the exception;
  - nobody checked whether iPadOS keyboard navigation draws a system highlight beside westron's ring; the probe ran on
    the iPhone simulator and macOS only;
  - iOS 17, macOS 14 and watchOS 10 are compile-only on the implementing machine, which has no iOS 17 or watch runtime
    and runs macOS 26.7; what holds was run on iOS 26.3 and macOS 26.7.

## Decided at implementation (2026-11-19)

The implementation (#30) found three points where Apple cannot do what the contract says. The coordinator decided each
under the owner's delegation of 2026-11-18, pending the owner's confirmation, with no API change; the contract's
`platforms.apple` records each as a platform difference. A fourth item is the implementation's own proposal.

| # | Point | Options considered | Decided | Measured |
|---|---|---|---|---|
| I1 | The placeholder's color, bound to `color.text.placeholder` | (a) on Apple the prompt is the system's placeholder color, recorded as a difference; (b) the product colors its prompt, `prompt: Text("Untitled").foregroundStyle(.text.placeholder)`; (c) westron draws its own prompt, which needs the field's text and so is not a `TextFieldStyle`: an API change; (d) reflection or introspection of the private field, fragile | (a), with (b) documented for iOS. (c) stays open for the owner. This misses chapter 08's contrast target for the placeholder on Apple. The binding stays for the platforms that can apply it (web, GTK) | A `TextFieldStyle` cannot set the prompt's color: neither `foregroundStyle` at any level nor `tint` reaches it, and `ShapeStyle.placeholder` only reads the system's color. A color the product sets on its prompt reaches it on iOS and is ignored on macOS 26. The system's placeholder against `background.canvas`: 1.72:1 on iOS in light, 2.42:1 in dark, about 3.9:1 on macOS in light; `color.text.placeholder` gives 5.27:1 and 6.22:1 |
| I2 | The accessible label, `label: required` | (a) the product names the field with `.accessibilityLabel(…)`; (b) accept the system's behavior | (a): the contract's example shows it, and the catalog labels every sample field so | On iOS 26.3 and macOS 26.7 `TextField("List name", text:, prompt:)` exposes no accessibility label from its title, with westron's style or without it (an unstyled field measured beside the styled one); the prompt is only its placeholder value |
| I3 | Disabled on macOS: the whole field at `opacity.disabled`, "with no colors of its own" | (a) record that the system field applies its own disabled text color under westron's opacity; (b) on macOS apply the opacity only to what westron draws | (a), no code change | Disabled text (57, 60, 66) against `background.canvas` (17, 19, 24) in dark, where `text.primary` at `opacity.disabled` alone gives (96, 101, 108); the outline is at `opacity.disabled` alone. On iOS disabled text is exactly `text.primary` at `opacity.disabled`, (162, 166, 171) in light |
| I4 | The ring's place (a proposal, for the owner) | (a) the ring over the outline, replacing it; (b) the ring outside the kept outline | (b) on `framed`: `stroke.thick` in `border.focus`, `space.25` outside the outline, its corners the outline's grown by that distance. On `inline`, which has no outline: around the field, `space.100` out across and `space.50` up and down, with `radius.control`. Every distance is a token | `border.focus` and `border.strong` are about equally light, 1.01:1 in light (3.53:1 and 3.50:1 against the canvas), so a ring replacing the outline would show focus mostly by its hue, which chapter 08 ("Color is never the only signal") forbids; outside the outline, focus changes the shape from one line to two. The accessibility review of #30 found it |

## What the tools need before an approved TextField is generated

Nothing new: an approved contract generates today (checked on a copy with `status: approved`) `TextFieldVariant`
(`framed`, `inline`), `TextFieldSize`, `textFieldStyle(_ variant: TextFieldVariant, size: TextFieldSize? = nil)`, the
`controlSize` mapping, watchOS's fallback to `m`, and `TextFieldState` with `focus` not entered on watchOS, into
`WestronUI/Generated/TextField+Contract.swift`, and its matrix into `WestronCatalog/Generated/TextField+Matrix.swift`.
The implementation then writes `TextFieldVariantStyle` (the `_body(configuration:)` probe, P2) in `WestronUI` and
`TextFieldMatrixCell` in the catalog, and the parity lint holds the generated API.
