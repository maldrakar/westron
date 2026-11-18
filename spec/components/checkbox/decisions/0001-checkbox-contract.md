# 0001. The Checkbox contract: the round task check

Date: 2026-11-18. Status: draft for approval (#31). The owner answered the interview and set the scope of #31 on
2026-11-18. This record keeps three things apart: what the owner answered, what the documents had already decided,
and what the agent proposes on top of both, which is still to confirm.

## Context

The pilot's task rows, subtask rows and board cards on `todo-app/list-screen` each start with a round check that
marks the task done (decisions/0006; `research_notes/pilot-inventory.md` 1.4, 2.2 T11–T15, 4.2): a ring in the
list's color when open, a disc in the list's color with a mark when done, which pops in as it is checked. The pilot
draws it as a button (`CheckButton.swift`) whose label names the action. Issue #31 names checkbox, toggle and picker.

## The scope of #31, set by the owner

- **The Toggle (a switch) is deferred** until a pilot screen has one. The pilot's only toggle is a checked item in the
  system's "Show as" menu, which the system draws (design-language/09:52, menus stay the system's). AGENTS.md, rule 6.
- **The Picker is dropped from #31.** No pilot screen has a SwiftUI `Picker`; `PickerStyle` cannot be implemented
  outside Apple, so westron could not give it a style; and the principles leave pickers to the system
  (decisions/0001:23, design-language/00-principles:31–32, 09:52).
- **The checkbox of phase 3 is the pilot's round task-completion check,** for tasks and subtasks, not a square box.
  The contract id stays `checkbox` (P1).

## What the owner answered

### Shape and base

- **Chosen: round on every OS, westron's style on the system `Toggle`.** `ToggleStyle` is a public protocol a style
  can implement (`makeBody(configuration:)`). The list's color comes from the context, the environment on Apple, and
  is the accent where the context sets none.

### Assistive technology

- Considered: (a) the system toggle's role, announced as on or off, checked or unchecked; (b) a button whose label
  names the action, as the pilot does.
- **Chosen: (a).**

### Unchecked

- Considered: (a) a ring in the neutral `color.border.strong`; (b) a ring in the list's color.
- **Chosen: (a).** `border.strong` meets 3:1 as a non-text color on canvas, surface, sunken and muted (its contrast
  declaration in `tokens/semantic/color.tokens.json`).

### Checked

- Considered: (a) a disc filled with the list's color, which must meet 3:1 non-text contrast on canvas, surface and
  sunken; (b) a neutral ring around the disc; (c) leaving contrast to the mark alone.
- **Chosen: (a).** A parallel piece of work adds the tokens for it: `color.category.<name>.control`, the disc, and
  `color.category.<name>.on-control`, its mark, for each of the twelve list colors, and non-text declarations for
  `color.background.accent`. Until they are in `tokens/`, the contract binds the default case, the accent:
  `color.background.accent` for the disc and `color.text.on-accent` for the mark, and describes the list's case in
  its text.

### Size

- Considered: (a) the circle follows the text role beside it, as an icon does, and grows with Dynamic Type, with no
  size option; (b) sizes `s`, `m`, `l`.
- **Chosen: (a).**

## Already decided by the documents

| What | Source |
|---|---|
| A checked control is a fill with a mark, not only a color | design-language/08:135 |
| `stroke.regular` is a small check's ring | 04:52 |
| `border.strong` is a checkbox's outline and meets 3:1 | 02:25–27, 04:58–59 |
| The accent fills a checked box | 02:31–32 |
| `motion.check` is a check popping into a done task, the only visible overshoot; Reduce Motion drops the scale | 05:24, 05:52–53, 05:91–93 |
| A press scales every control down to 98 % in `motion.press`; Reduce Motion drops the scale | 05:22, 05:84–87, 05:93 |
| The hit area is at least 44 pt on iOS and watchOS and 28 pt on macOS, also where the drawn shape is smaller | 08:100–116 |
| Disabled is the whole control at `opacity.disabled`, announced as unavailable | 08:31–34 |
| An icon inside a shape keeps its proportion to the shape, and the shape scales with the text beside it | 07:113–114 |
| A system control keeps its own role and traits | 08:88–89 |

## Proposed, to confirm

| # | Proposal | Reason |
|---|---|---|
| P1 | The contract id `checkbox` | The issue's name and ARIA's role; the shape is round, and the contract says so |
| P2 | Strategy `style-on-system-control`, `base: SwiftUI.Toggle` | The owner's answer; `SystemStyles` gains `SwiftUI.Toggle` with `toggleStyle` and its styles `automatic`, `button`, `checkbox`, `switch`, held to SwiftUI's interface by a macOS test |
| P3 | One variant, `check`: `.toggleStyle(.check)` | The generated overload takes the variant first; the system's names are forbidden, and `check` reads as what it draws |
| P4 | On is the state `checked`, read from `configuration.isOn`, which `accessibility.states` announces as `checked`; off is the absence of it | A state is what the component is in, and on or off is the toggle's value, which the system carries; `checked` is the name ARIA, GTK's accessible state and the web's `:checked` give it, for a switch too. `on` would also need quoting in YAML, where it reads as a boolean |
| P5 | States `checked`, `pressed`, `focus`, `disabled`; no `hover`, no `mixed` | `pressed` because a press scales every control (above); `ToggleStyleConfiguration` has no `isPressed`, so the style follows the press itself, keeping the toggle's trait and value, which the implementation probes on each OS. No hover look is decided, and no pilot consumer needs `mixed` |
| P6 | The unchecked ring is `stroke.regular`; checked draws no ring | Chapter 04's small check's ring; the disc is the shape when checked |
| P7 | Unchecking fades the disc and the mark out in `motion.fade`, with no pop | Only checking overshoots (05:52–53); a fade is a color change, which Reduce Motion keeps |
| P8 | The mark is the registry's `check` glyph, sized by the circle | The glyph exists (`spec/icons/icons.yaml`), and an icon inside a shape keeps its proportion (07:113–114) |
| P9 | On Apple the focus ring is the system's, as for Button; web and GTK as Button's entries | The owner decided westron's own ring for TextField only; the check is a small control on a row, where Button's rule fits, and chapters 08 and 09 say so as written. The visible consequence on macOS: a row with a check beside a TextField shows two focus colors, the system's ring in the person's accent on the check and westron's `color.border.focus` on the field, whenever the person's accent is not westron's. Kept: decided by the agent under the owner's delegation of 2026-11-18, pending the owner's confirmation; the owner may extend the TextField decision to the check |
| P10 | The circle's diameter scales with the text role of its label, through that role's text style; its ratio to the text is set at implementation from the pilot's (24 pt beside 17 pt body text on the phone, 18 pt beside a subtask's 15 pt), and reviewed in the snapshot matrix | The owner chose the text role, not a number; the ratio is a drawing detail the matrix shows |
| P11 | Accessibility: role `checkbox`, intents and keyboard intents `toggle`, a required label (the task's title), also where the title is a separate text beside the circle | The system toggle's role carries the value; a row's check needs the task's name to be announced |
| P12 | Consumers: `todo-app/list-screen` only | The lists screen has no check that marks something done; its picker's check is a glyph |
| P13 | Web, provisional: a native `<input type="checkbox">` drawn round (`appearance: none`), `:checked`; GTK, provisional: a stock `GtkCheckButton` drawn round with a style class | The native checkbox keeps its role and its keyboard |
| P14 | The pop's shape: the disc and its mark scale up from 80 % to full size on `motion.check`, whose bounce carries them past full size and back; Reduce Motion drops the scale and keeps the fill appearing | A component's contract owns what moves and how far (05:84–86); the pilot pops from 0.8 through 1.14 to 1 with keyframes, and a westron spring gives the overshoot instead of a hand-made curve (05:72–73) |

## Open points

- **What the implementation must show before the second gate:** whether a custom `ToggleStyle` is keyboard-focusable
  on macOS at all, since the contract claims the system's focus ring and `keyboardIntents: [toggle]`. If it is not,
  the contract changes first: a focusable element inside the style, or a recorded difference on macOS.

## What the control tokens complete

The one thing to complete when the tokens of the parallel work land:

- The contract text names the expected tokens, added by the tokens piece: `color.category.<name>.control` for the
  disc and `color.category.<name>.on-control` for the mark, for the twelve list colors. They are not on this branch,
  so nothing binds them. No binding can name
  them per list today, since the list's color is the context's, not an option of the contract; so the bindings stay
  the accent's, and the contract's description says which token the disc and the mark take for a list. When the
  tokens land, the check that they exist is `spec check`'s once a binding names them, and the decision whether a binding can express "the
  context's list color" (for instance a token-valued option over `color.category` read from the environment) is made
  with the implementation.
- `color.background.accent` gains a non-text declaration on canvas, surface and sunken, so that the contrast check
  proves the checked disc's 3:1; `color.text.on-accent` already declares text contrast on the accent fills.

## What the tools need before an approved Checkbox is generated

Nothing new: an approved contract generates today (checked on a copy with `status: approved`) `CheckboxVariant`
(`check`), `toggleStyle(_ variant: CheckboxVariant)`, and `CheckboxState` with `focus` not entered on watchOS, into
`WestronUI/Generated/Checkbox+Contract.swift`, and its matrix into `WestronCatalog/Generated/Checkbox+Matrix.swift`.
No state modifier is expected, since `SystemStyles` lists every state of the contract as one the Toggle carries. The
implementation writes `CheckboxVariantStyle` and the environment value that carries the list's color in `WestronUI`,
and `CheckboxMatrixCell` in the catalog. If the list's color becomes an option of the contract, the generator must
first give a style a token-valued option, which it reports today as not supported.
