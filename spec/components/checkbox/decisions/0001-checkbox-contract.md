# 0001. The Checkbox contract: the round task check

Date: 2026-11-18. Status: approved on 2026-11-18 under the owner's delegation of 2026-11-18 (#31), pending the
owner's confirmation. The owner answered the interview and set the scope of #31 on 2026-11-18 and delegated the
approval: the coordinator, not the owner, approved the contract as written and every one of its "Proposed" items,
P1–P14, all of them pending the owner's confirmation. The owner's own answers are the sections "The scope of #31, set
by the owner" and "What the owner answered". Of the proposals, P9 (the system's focus ring on Apple) is the
substantive choice the agent made where the owner and the documents were silent; the control tokens that meet the
owner's 3:1 are option B of decisions/0012's revision, chosen under the delegation too ("Checked", below); and
P15–P19 were decided by the implementation on Apple under the same delegation. This record keeps four things apart:
what the owner answered, what the documents had already decided, what the agent proposed on top of both, and what the
implementation on Apple decided where the contract left it to it (P15–P19).

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
- **Chosen: (a).** The owner's answer is that the checked fill meets 3:1, with no ring. How it meets it is not the
  owner's answer: separate control tokens rather than darker shared list fills is option B of decisions/0012's
  revision of 2026-11-18, chosen under the owner's delegation of 2026-11-18 and pending the owner's confirmation.
  The tokens are in `tokens/`: `color.category.<name>.control`, the disc, and `color.category.<name>.on-control`, its
  mark, for each of the twelve list colors, and a non-text declaration of `color.background.accent` on canvas,
  surface and sunken. The contract binds the default case, the accent: `color.background.accent` for the disc and
  `color.text.on-accent` for the mark, and its description is the contract for a list's color, which comes from the
  context, not from an option.

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

## Proposed, approved as written (P1–P14)

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
| P10 | The circle's diameter scales with the text role of its label, through that role's text style; its ratio to the text is set at implementation from the pilot's (24 pt beside 17 pt body text on the phone, 18 pt beside a subtask's 15 pt), and reviewed in the snapshot matrix | The owner chose the text role, not a number; the ratio is a drawing detail the matrix shows. Set on Apple as P16 |
| P11 | Accessibility: role `checkbox`, intents and keyboard intents `toggle`, a required label (the task's title), also where the title is a separate text beside the circle | The system toggle's role carries the value; a row's check needs the task's name to be announced |
| P12 | Consumers: `todo-app/list-screen` only | The lists screen has no check that marks something done; its picker's check is a glyph |
| P13 | Web, provisional: a native `<input type="checkbox">` drawn round (`appearance: none`), `:checked`; GTK, provisional: a stock `GtkCheckButton` drawn round with a style class | The native checkbox keeps its role and its keyboard |
| P14 | The pop's shape: the disc and its mark scale up from 80 % to full size on `motion.check`, whose bounce carries them past full size and back; Reduce Motion drops the scale and keeps the fill appearing | A component's contract owns what moves and how far (05:84–86); the pilot pops from 0.8 through 1.14 to 1 with keyframes, and a westron spring gives the overshoot instead of a hand-made curve (05:72–73) |

## Decided by the implementation on Apple

Each of these is decided by the agent under the owner's delegation of 2026-11-18, pending the owner's confirmation.

| # | Decision | Reason |
|---|---|---|
| P15 | The list's color reaches the style through `.category(_ category: Westron.Category?) -> some View` on `View`, which sets an environment value; nil, the default, is the accent. It cascades like `.tint(_:)`, the closest one winning, so a product sets it once around a list's rows: `.category(Westron.Category(rawValue: list.color))`. It is named after the type it takes, as `.textRole(_:)` is after `Westron.TextRole`, not after the check, so every westron control that takes the list's color later reads the same value. The API parity lint accounts for it as a reviewed adapter in a file of its own, `APIParity.otherAdapters` (`Category.swift`: `View.category`), held to the adapters' rule that it takes a `Westron.*` value | No contract can give it: it is not one control's option but the context's, and the lint's other derived shape, a state modifier, takes a `Bool` for a state the control lacks. It is to westron's controls what `.tint(_: Westron.Color)`, already a reviewed adapter, is to the system's. A contract concept for a value read from the context (for example a top-level `context:` naming a token group) would let the lint derive it instead; it touches the schema, the contract reader, the rules and the lint, more than #31 needs, and can replace the adapter when a second context value appears (`spec/conventions.md`, "Context a style reads") |
| P16 | The circle's diameter is 1.2 times the line height of the text that reaches the style, measured on a hidden line of the environment's font, so a product sets the role on the toggle: `Toggle(…).toggleStyle(.check).textRole(.body.regular)`. With no role set, the system's body text sizes it. The mark is 0.55 of the diameter | The pilot's task check is 24 pt beside 17 pt body text on the phone, whose line is about 20.3 pt, and 18 pt beside 13 pt on the Mac, a line of about 15.5 pt: both about 1.2 lines. The pilot's subtask check, 18 pt beside 15 pt, is smaller still; one ratio keeps the circle following the role, and a subtask's `subheadline.regular` draws it at about 21 pt. A line height rather than a point size, since a hidden line measures it in any font and at any Dynamic Type size with no table of sizes. The registry's check glyph fills most of its frame, so 0.55 of the diameter draws it near the pilot's 15 pt mark in 24 pt. Both numbers are proportions of the contract, written under the raw-values lint's exception, as Button's 98 % is |
| P17 | The hit area is a square of at least `size.control.m` with the circle centered in it: 44 pt on iOS and watchOS, 32 pt on macOS, above the recommended 28; where the circle grows past it with the text, the square grows with it. The label beside it is part of the hit area too, as it is of a system checkbox on macOS and of a `<label>` on the web | `size.control.m` is the platform's control height and, on touch, the recommended target (chapter 08, tokens/platform), so no new number is needed. The square is laid out, not only hit-tested, so the check never overlaps a neighbor's target: on macOS Button found that a hit area grown past the laid-out frame hands clicks to the later sibling (Button's decisions/0001, #75) |
| P18 | The space between the hit area and the label is `space.50`, scaled with the text (`@ScaledMetric`) | The contract binds no gap. The hit area's own margin around the circle is most of the space at the default sizes (10 pt on iOS, about 7 pt on macOS, near the pilot's 12 and 11 pt), and `space.50` keeps the label off the circle at the accessibility sizes, where the circle fills the square. A binding `container.gap: space.50` would record it in the contract; the owner may move it there |
| P19 | The press, and what assistive technology meets. The style's body is a system `Button` that toggles the value, drawn by a `ButtonStyle`, which sees `isPressed`; for assistive technology the body is replaced by the system's own `Toggle` on the same value and label (`accessibilityRepresentation`, in the system's automatic style) | `ToggleStyleConfiguration` has no `isPressed` (P5). A gesture of the style's own would lose the system button's activation, and its keyboard focus, which on macOS is unverified (Open points). Without the representation, assistive technology would meet a button. Measured in the catalog's UI tests (`CheckboxBehaviorTests`) on iOS 26.3 and macOS 26 only, in the accessibility hierarchy as XCUITest reads it, not with VoiceOver itself; iOS 17, macOS 14 and watchOS run the same code, not measured: the hierarchy holds a switch on iOS and a checkbox on macOS, each with its label and its on or off value, and no button with the same identifier; the disabled check is not enabled in it |

## Open points

- **Keyboard focus on macOS** (what the implementation had to show before the second gate). The style's focusable
  element is the system `Button` in its body; whether it takes keyboard focus as a system button does is not shown
  yet. Measured on 2026-11-18 (macOS 26, Xcode 27.1) with the Mac's keyboard navigation off, its default:
  neither westron's check nor a system `Toggle` in `.checkbox` style takes focus, from Tab or from code
  (`.focused(_:)` set by a button); with `.focusable()` added by the product, both take focus and show the system's
  ring around the whole toggle, and Space toggles neither. With keyboard navigation on, Tab and Space were not
  measured: the setting is the person's and global, and neither `-AppleKeyboardUIMode 2` passed to the app nor
  replacing `isFullKeyboardAccessEnabled` in it turns it on. `CheckboxBehaviorTests.testKeyboardFocusAndSpace` tabs to
  the check, attaches a screenshot of the ring and presses Space twice; it runs on a Mac with keyboard navigation on
  and is skipped otherwise. Until it has run, the behavior with keyboard navigation on is unverified, and the
  contract's `keyboardIntents: [toggle]` and the system's ring on macOS are claimed, not shown. The options, for the owner: run that test once with keyboard navigation on (System
  Settings, Keyboard, "Keyboard navigation") and keep the contract as it is; or record on macOS that the check takes
  focus only as the system's own controls do, and leave the measurement to the phase that adds keyboard checks.

- **Details the implementation chose where the contract is silent**, for the owner to confirm or move into the
  contract (the reviews of the Apple implementation, 2026-11-19):
  - The press's 98 % and disabled's `opacity.disabled` apply to the check and its label together, the label being part
    of the control as it is of a Button (`container` in the bindings).
  - The mark is the check glyph at the bold weight, as the pilot draws its glyphs.
  - On macOS the system's focus ring goes around the whole toggle, the label included; westron sets no focus shape.
  - On iOS 17, macOS 14 and watchOS 10 a custom style cannot see `.labelsHidden()`, so a row with a separate title
    shows the title twice there; from iOS 18, macOS 15 and watchOS 11 the label is hidden and stays the name.
    **Settled on 2026-11-19 by decisions/0002 (#86)**, with the owner's choice of the form: such a row writes
    `Toggle(isOn: $task.isDone, accessibilityLabel: task.title)`, an initializer that takes no label view and
    requires the name, the same on every OS, measured on iOS 17.5 and 26.3. The empty-label workaround noted here was
    measured there too, and left a gap where the label would be.
  - The accessibility audit measures a check whose label is hidden as if its name were drawn in the circle's square,
    and reports its ring as text that "nearly passed" and its name as clipped; the catalog suppressed both, with the
    reason, on its live row. A product's own audit of such a row will report the same. Written with the initializer of
    decisions/0002 instead, the row draws no label view, and the audit reports neither (iOS 26.3, 2026-11-19): the
    catalog's suppressions are removed.

- **Questions for the owner from the review of the Apple implementation:**
  - A check whose body is a `Button` with a custom `ButtonStyle`, inside a real SwiftUI `List` row, as the pilot's
    task rows are: does the whole row take the press, or highlight? The catalog's `checkbox-in-list` entry puts two
    such checks in a `List` beside separate titles, and `CheckboxBehaviorTests.testCheckInAListRow` presses the check
    and then the title and attaches a screenshot. Measured on iOS 26.3 and macOS 26: a press on the check toggles it,
    a press on the title does not, and the screenshots after it show no row highlighted. On iOS the List gives the
    toggle's accessibility element the whole row (370 × 74 pt), so the row is the switch's element in the
    accessibility hierarchy (VoiceOver itself was not run); on macOS
    the element is the check's 32 pt square. What a product's own row action (a tap that opens the task) does beside
    the check is not measured.
  - The check's hit area makes a Mac row with a check at least 32 pt tall (`size.control.m`). The pilot's wide task
    row is at least 36 pt with a 32 × 36 check hit, its subtask check's hit 30 × 30, and its sidebar rows 30 pt
    (`research_notes/pilot-inventory.md` 4.2, 4.3). Compare with the pilot's row heights before the list screen adopts
    it.

## The control tokens

Separate control tokens, rather than darkening the shared list fills, are option B of decisions/0012's revision of
2026-11-18, chosen under the owner's delegation of 2026-11-18 and pending the owner's confirmation; the owner's answer
was only that the checked fill meets 3:1, with no ring. The control tokens of the parallel work are in `tokens/`:
`color.category.<name>.control` for the disc and
`color.category.<name>.on-control` for the mark, for the twelve list colors, and a non-text declaration of
`color.background.accent` on canvas, surface and sunken, so the contrast check proves the checked disc's 3:1;
`color.text.on-accent` already declares text contrast on the accent fills. No binding names the category tokens per
list, since the list's color is the context's, not an option of the contract: the bindings stay the accent's, and the
contract's description says which token the disc and the mark take for a list. The style resolves them in
`CheckboxTokens`, and the tests compare both cases (`CheckboxStyleTests`).

## What the tools need before an approved Checkbox is generated

Nothing new: an approved contract generates today (checked on a copy with `status: approved`) `CheckboxVariant`
(`check`), `toggleStyle(_ variant: CheckboxVariant)`, and `CheckboxState` with `focus` not entered on watchOS, into
`WestronUI/Generated/Checkbox+Contract.swift`, and its matrix into `WestronCatalog/Generated/Checkbox+Matrix.swift`.
No state modifier is expected, since `SystemStyles` lists every state of the contract as one the Toggle carries. The
implementation writes `CheckboxVariantStyle` and the environment value that carries the list's color (P15) in `WestronUI`,
and `CheckboxMatrixCell` in the catalog. If the list's color becomes an option of the contract, the generator must
first give a style a token-valued option, which it reports today as not supported.

## Revision of 2026-11-24: the context it reads, declared (#167)

Agreed by the owner on 2026-11-24, after the check of the agent context on the pilot (#37: a fresh agent with only the
skill moved todo-app's "Move to…" picker to westron). The IconTile card promised "the list's color" beside an
initializer that takes only the icon; the modifier that sets the color, `.category(_:)`, was in no contract, and the
agent found it in a details file. P15 had foreseen it: "a contract concept for a value read from the context […] can
replace the adapter when a second context value appears". There are three readers now, Checkbox, Chip and IconTile.

- **The schema** gains a top-level `reads` block beside `context` (the settings a contract gives others): the values of
  westron's shared context the component takes from where it stands, each with `description`, what it draws in the
  value, and `unset`, what it draws where nothing around it sets one. The names are the schema's, `category` so far,
  each set by the one shared modifier named after it, which no contract owns; that is "who sets it". A setting another
  contract declares in its `context`, Disclosure's `alignsLeaves`, stays described there: naming it in a reader's
  `reads` would make `spec check`, which reads one contract at a time, look into another.
- **The contracts.** Checkbox, Chip and IconTile declare `reads: category`, verified in WestronUI's sources: the only
  readers of the environment value are `CheckboxVariantStyle`, Chip's `ChipSurface` (every form, though only the
  selectable form is ever checked) and `IconTile`. Icon takes its color from `.foregroundStyle`, ListRow and the others
  read no list color. Nothing they draw changes, and no generated file of the platforms does.
- **The parity lint** expects `public func category(_: Westron.Category?) -> some View` on `View` from the contracts
  that read it, as it expects a shared state modifier, and `APIParity.otherAdapters`, which listed it alone, is gone
  (`spec/conventions.md`, "Context a style reads").
- **The agent context.** Each reader's card shows the modifier in its call, `IconTile(.tray).category(.blue)`, and says
  where it may be set and what the component draws without it, from the contract's `description` and `unset`.

Not here: consumer prose for every contract (`summary`, `usage`, `examples`), which the owner decided against for now.

## Note of 2026-11-25: the context it reads, in words (#170)

Agreed by the owner on 2026-11-25. The `description` and `unset` of `reads.category` named token paths, such as
`color.category.<name>.fill`, which the agent context prints into the component's short card, where a product's call
is and no product writes a token path. They now say in words what the component draws with a list's color and without
one; the contract's description keeps the token-level account, which the details file of the agent context carries.
Nothing drawn changes.
