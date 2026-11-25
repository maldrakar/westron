# 0001. The Chip contract: a tag, a filter, a value

Date: 2026-11-22. Status: approved on 2026-11-22, and revised the same day after the contract check and the
accessibility audit ("Revision after the audits, 2026-11-22", at the end), both by the coordinating agent under the
owner's delegation for phase 4 (decisions/0005, the first gate; decisions/0014, "Process"). There was no interview: the
agent that wrote the draft answered the questions of `/new-component` from the sources, and each answer below names its
source. Where the sources were silent, the answer was the agent's guess, listed under "Open questions" with a
recommendation; the approver's answers are under "Approval", and what the implementation on Apple measured and decided
under the same delegation, pending the owner's review at the second gate, under "Implementation on Apple". The proposals
below are the draft's; where an answer changed one, "Approval" says so.

## Context

decisions/0014 puts Chip in the core of phase 4 (#117): "a compact capsule with a label and an optional icon,
selectable (a filter) or pressable (a value)". The pilot, todo-app, composes three things on `todo-app/list-screen`
from it (read at todo-app's `Sources/DesignSystemComponents/`, `Sources/Features/TaskList/` and
`Apps/Apple/Sources/TodoAppleUI/ListScreen/`):

| Pilot family | What it is | How the pilot draws it |
|---|---|---|
| Tag chip (`TagChipModel`, `TagChipStyle`, in `TagBarView`) | A tag of the list's tasks in the tag bar; a tap lights it and filters the screen (list-screen.md, section 7) | A `Button` with `.plain` style, a capsule 30 high on the phone and 26 on the Mac, in a tap area 44 and 32 high; unlit on the neutral fill with the title in ink and the hash in ink 2; lit on the list's check fill with both in its mark's color; `.isSelected` while lit; tinted under the pointer on the Mac; the colors change on an ease of 0.18 s |
| Pill (`PillModel`, `PillStyle`, in `TaskCardView`) | The open card's When, Deadline and one per tag (list-screen.md, section 3) | A capsule 32 high on the phone and 26 on the Mac on the neutral fill, with a glyph and a text; "drawn and inert in this epic", since "the pickers are the Task screen's" (list-screen.md, lines 31 and 57) |
| Meta item with a capsule (`MetaItemStyle.Capsule`) | The tag in a task row's line of metadata on the Mac (`TaskList+PaneMetrics.swift`, `paneTagCapsule`) | A capsule 20 high on the neutral fill, padded 8, with the tag's name; not a control: the row is |

The pilot is right about behavior and roles; the look is westron's (decisions/0011–0013). The pilot's numbers are
compared below, not taken.

## Already decided by the documents

| What | Source |
|---|---|
| A system control beats westron's own; westron gives it a style, named by an unlabeled variant | decisions/0003, spec/conventions.md |
| A tag is a capsule, the platform's own, at any height; a tag casts no shadow | design-language/04:32–35, 04:73 |
| `color.background.muted` is "a tag or a badge without a color" | design-language/02:19; the token's usage note |
| A list's color: `background` a tag's ground, `fill` a lit tag, `on-fill` the words on that fill; tags keep `fill`, not `control` | design-language/02:79–90; the usage notes of `color.category.<name>.control` and `on-control` |
| A muted control darkens to `muted-hover` and `muted-pressed`; the accent fill to `accent-hover` and `accent-pressed` | design-language/02:19–23, 02:42–45 |
| `typography.footnote.strong` is "the words on a chip, a pill or a small button" | design-language/03:59, 03:74 |
| `motion.fade` is a hover tint and a selection; `motion.press` a press, scaling to 98 %; Reduce Motion drops the scale and keeps the tint | design-language/05:21–22, 05:82–94 |
| The hit area is at least `size.target.minimum`, 44 pt on iOS and watchOS and 28 on macOS, also where the drawn control is smaller | design-language/08:115–131 |
| Disabled is the whole control at `opacity.disabled`, announced as unavailable | design-language/08:43–47 |
| States are announced: selected, unavailable, busy | design-language/08:110 |
| A value from the context, the list's color, reaches a style through `.category(_:)`, the accent when none is set | spec/conventions.md, "Context a style reads"; Checkbox |
| The pilot's tag filter chips, card pills and the Mac row's tag are a Chip; the tag bar is the pilot's composition | decisions/0014, "The pilot's families, mapped" |

## The interview, answered from the sources

1. **Purpose.** A person lights tag chips in the tag bar to filter the list, and sees a task's day, deadline and
   tags as pills in its open card and its tags in its row on the Mac (above, "Context").
2. **System control.** On Apple the selectable chip is a value that is on or off, the system `Toggle`, as Checkbox
   is; the pressable chip is the system `Button`; the static chip is the system `Label`, which takes `labelStyle`.
   The web has `<button>`, GTK `GtkToggleButton` and `GtkButton`. So westron gives styles (P1, P2).
3. **Options.** One variant, no size, no flags (P3–P5, P15).
4. **States.** checked, hover, focus, pressed, disabled; watchOS enters checked, pressed and disabled (P16).
5. **Slots.** `label` and an optional `icon`: the pilot's chips and pills each have a glyph and a text.
6. **Constraints.** None between options; the forms differ in the states they enter (P1).
7. **Accessibility.** A toggle button announced as selected while on; a button; static text (P13).
8. **Platform differences.** Hover only with a pointer; the hit area by platform; watchOS as plain as the schema
   allows until #34 (P16).

## Proposed

| # | Proposal | Options considered, and why this one |
|---|---|---|
| P1 | **One contract, three forms on three Apple bases**: selectable `.toggleStyle(.chip)` on `SwiftUI.Toggle`, pressable `.buttonStyle(.chip)` on `SwiftUI.Button`, static `.labelStyle(.chip)` on `SwiftUI.Label`. The form is the control the product writes, not an argument. The draft names the Toggle as its base, since the schema takes one; the other two need the tools below before approval | (A) this, one look recorded once, every form the system's own control (decisions/0003), the issue's one component; it needs the tools. (B) Separate contracts, `chip` on `SwiftUI.Button`, `filter-chip` on `SwiftUI.Toggle` and a third on `SwiftUI.Label`: the tools allow it today (the variant `chip` collides with no value of Button or Checkbox on the shared modifiers, and every variant is required), but one look is written three times, nothing checks that the copies agree, and the core gets three names for one thing, against decisions/0014's small core. (C) One contract on `SwiftUI.Button` with a westron state `selected`, set by a shared `.selected(_:)` modifier and announced with `.isSelected`, as the pilot does: the tools allow it today and ListRow (#119) may share the modifier, but a value that is on or off would be the product's state on a button instead of the system toggle's value, unlike Checkbox, and the static form still needs a base. (D) The pressable chip as a variant of Button (`.buttonStyle(.chip)` in Button's contract) and the selectable one a contract on Toggle: it changes an approved contract and still splits one look in two. Recommended: A; if the tools cannot wait, B, and A merges B later |
| P2 | **The static form is a style on `SwiftUI.Label`**, `Label(tag.name, icon: .hash).labelStyle(.chip)` | (a) this: a system view with a style modifier, so decisions/0003 asks for a style; like any label style it cascades to every `Label` below it, which a product sets on the chip itself. (b) An own view, `Chip(tag.name, icon: .hash)`, as Icon and Rule are: needs an own view with slots and a variant, which the tools do not derive yet. (c) No static form: the pilot composes a capsule from Text, Icon and tokens; decisions/0014 names the Mac's tag a Chip, and the look would drift from the chip's |
| P3 | **One variant, `chip`**: `.toggleStyle(.chip)`, `.buttonStyle(.chip)`, `.labelStyle(.chip)` | Not a system style of any of the three bases (`SystemStyles`: Toggle's `automatic`, `button`, `checkbox`, `switch`; Button's ten; Label's `automatic`, `iconOnly`, `titleAndIcon`, `titleOnly`), nor a value of Button's or Checkbox's variant. Checkbox's `check` is the precedent of a one-value variant |
| P4 | **No size option**: the height is `size.control.s`, a minimum, 28 pt on iOS, 24 on macOS, 32 on watchOS | The pilot's chips and pills are 30 and 32 on the phone and 26 on the Mac, between `s` and `m`, nearer `s`; one size serves every use the pilot has. The Mac row's tag, 20 in the pilot, is Q7 |
| P5 | **Padding `space.125` on both sides, gap `space.50`** | The pilot pads 10 and 12 on the phone and 8 and 10 on the Mac, the icon's side narrower; a symmetric padding needs no case on whether an icon is there, which a binding cannot name (a slot is not an option). Button's size s gap is `space.50`; the pilot's is 5–6. Q10 |
| P6 | **At rest**: fill `color.background.muted`, label `color.text.primary`, icon `color.text.secondary` | The documents' neutral tag; the pilot's title in ink and glyph in ink 2 |
| P7 | **Checked**: with the accent, fill `color.background.accent`, label and icon `color.text.on-accent`; with a list's color, `color.category.<name>.fill` and `on-fill`. The bindings are the accent's, the description the contract for a list's color, as Checkbox's is | (a) `fill` and `on-fill`, the roles design-language/02 gives a lit tag. (b) `control` and `on-control`, the pilot's own choice (its lit chip is the check's fill and mark), which meets 3:1 on the ground; the token notes say to avoid them for tags. (c) `background.selected` under `text.primary` for the accent, quieter, but then the accent and a list's color would light differently. Recommended: (a), Q5 |
| P8 | **Hover and pressed**: unchecked to `muted-hover` and `muted-pressed`; checked with the accent to `accent-hover` and `accent-pressed`; checked in a list's color keeps its fill; a disabled chip never tints or scales | The documents' tints. A list's color has no hover or pressed fill: Q4 |
| P9 | **High contrast**: every chip draws `color.border.strong` at `stroke.thin` over its fill, in every state | Button's secondary does the same, for the same reason: the muted fill stands about 1.1:1 off the canvas, and a list's `fill` is held to no contrast on the ground. A case has no contrast key, so the description carries it, as Button's does |
| P10 | **Hit area**: the selectable and pressable forms lay out a frame at least `size.target.minimum` high around the drawn chip; across, the chip's width; the static form takes no hit area | The pilot's tap areas are 44 and 32 high. Laid out, as Checkbox's square is, so it never takes a neighbor's clicks (Button's #75 on macOS). On iOS Button relies on the system's touch tolerance instead, which a neighbor within about 16 pt shares; chips stand 6 pt apart in the pilot's tag bar, so the frame is the safer choice. Q11 |
| P11 | **Hover and pressed tints are in the description, not in the bindings** | A case's `state` matches any of the states it names, so no case can say "checked and pressed": the tint depends on both. Button escapes this with an option (its variant); a chip's selection is a state. The tools need a case that requires several states at once (below) |
| P12 | **One line, truncated at the end; Dynamic Type grows the chip** | The pilot sets one line on both. Tag names are a person's and may be long; a chip in a scrolling bar gets its width, a chip in a row's metadata may not. The whole label stays the accessible name |
| P13 | **Accessibility**: the selectable form a toggle button, announced as selected while on; the pressable form a button; the static form adds no role and reads as its label; the icon is hidden; the label is required | The pilot marks a lit chip `.isSelected`; design-language/08 names "selected". The draft's fields are the selectable form's (`role: button`, `intents: [toggle]`, `states: { checked: selected }`), since one contract has one accessibility block today. How Apple announces it is Q6 |
| P14 | **Motion**: checking and hover change color in `motion.fade`; a press scales to 98 % in `motion.press`; Reduce Motion drops the scale | The documents. The pilot's chip changes color on an ease of 0.18 s, which is `motion.fade`'s role |
| P15 | **No remove button, no icon-only form, no size option** | The pilot needs none: adding or removing a tag is outside the list screen (list-screen.md, line 31: editing a task's tags is the Task screen's), and every chip and pill has words (AGENTS.md, rule 6) |
| P16 | **Platforms**: Apple as P1; iOS hovers only with a pointer; watchOS enters checked, pressed and disabled and nothing else is said, as plain as the schema allows until #34; the web and GTK provisional, the web's selectable form a `<button aria-pressed>`, GTK's a `GtkToggleButton`; Android planned | Button's and Checkbox's blocks. The web and GTK base fields name the selectable form's, as Apple's does |

## What the tools need before an approved Chip is generated

For P1, option A; options B and C need none of it.

1. **Several bases in one contract.** The schema gives `platforms.<platform>.base` one string. Chip needs its forms
   named once in the neutral part, each with the states it enters and its accessibility, and a base per form on each
   platform. One shape: a top-level `forms:` map, `{ selectable: { states: [checked, hover, focus, pressed,
   disabled], accessibility: { role: button, intents: [toggle], states: { checked: selected } } }, pressable: {
   states: [hover, focus, pressed, disabled], accessibility: { role: button, intents: [activate] } }, static: {
   states: [], accessibility: { role: none } } }`, and `platforms.apple.bases: { selectable: SwiftUI.Toggle,
   pressable: SwiftUI.Button, static: SwiftUI.Label }` in place of `base`. A contract without `forms` keeps `base`.
2. **`spec check`**: each base checked as `base` is now (in `SystemStyles`, the strategy fits it, no option value is
   one of its system styles); each form's states a subset of the contract's, and a state the base does not carry
   (`SystemStyles.Base.states`) one a westron modifier sets; the `role: none` rules per form.
3. **`SystemStyles`** gains `SwiftUI.Label`: modifier `labelStyle`, protocol `LabelStyle`, styles `automatic`,
   `iconOnly`, `titleAndIcon`, `titleOnly`, no states; `SwiftUITypesTests` holds it to SwiftUI's interface.
4. **The generator** writes one overload per base, `toggleStyle(_: ChipVariant)`, `buttonStyle(_: ChipVariant)` and
   `labelStyle(_: ChipVariant)`, each applying its own hand-written style (today the one style is
   `<Component>VariantStyle`; three need three names, such as `ChipToggleStyle`, `ChipButtonStyle`, `ChipLabelStyle`,
   which the type-name collision check covers), and `ChipState.isEntered` per form. The ambiguity check runs per
   modifier: Chip beside Button on `buttonStyle` and beside Checkbox on `toggleStyle` passes, since the variants
   share no value and all are required.
5. **The API parity lint** expects the three overloads.
6. **The snapshot matrix** gets a row per form, each in the states it enters.
7. **Cases over several states at once** (P11): a case that matches only when every named state holds, such as
   `when: { state: { all: [checked, pressed] } }`, so that the tints are bindings and not prose. Without it the
   description carries them, as it carries Button's high-contrast outline. Its reachability check has to enumerate
   the sets of states, which it does not today.
8. **`spec/conventions.md`** and `spec/components/README.md` describe forms.

## What the tokens need

- **Contrast declarations, no new values**: `color.text.secondary`, the resting icon, is declared on
  `color.background.muted`, `hover` and `pressed` but not on `muted-hover` and `muted-pressed`, which an unchecked
  chip's icon sits on under the pointer and pressed. `tools/westron tokens contrast` then proves them.
- **If Q4 is answered (b)**: `color.category.<name>.fill-hover` and `fill-pressed` for the twelve list colors, solved
  by the palette generator as `accent-hover` and `accent-pressed` are, with `on-fill` declared on them.
- Nothing else: every other binding is an existing token.

## Open questions

Each is a guess the sources do not settle; the recommendation comes first.

- **Q1. One contract with three bases, or separate contracts?** (P1.) Recommended: one contract (A), with the tools
  above as a separate issue before the implementation; the draft stays a draft until then. If the phase cannot wait,
  B now, merged into A when the tools carry forms.
- **Q2. Does westron hold the static form?** (P2.) Recommended: yes, as `.labelStyle(.chip)`: decisions/0014 names
  the Mac row's tag a Chip, and a composition in the pilot would copy the look. The alternative is the pilot's own
  capsule from Text, Icon and tokens.
- **Q3. The pressable form has no live consumer yet.** The pilot's pills are "drawn and inert in this epic" and the
  pickers are the Task screen's (list-screen.md, lines 31 and 57); the issue and decisions/0014 name the pressable
  chip, and the brief says the pills open pickers. Recommended: keep it, since the pills become pressable with the
  pickers and the form costs a base, not a look; until then the pilot draws its pills as static chips. The
  alternative is to drop it until the Task screen's epic (AGENTS.md, rule 6).
- **Q4. A list's color under the pointer and pressed.** (P8.) (a) The fill stays, and the press's 98 % scale is the
  feedback; (b) new tokens `fill-hover` and `fill-pressed` for each list color. Recommended: (a) now; (b) if the
  owner finds the lit chip too still in the snapshot matrix.
- **Q5. Which fill lights a chip in a list's color?** (P7.) Recommended: `fill` and `on-fill`, as design-language/02
  says for a lit tag. The pilot uses the check's fill, `control`, which meets 3:1 on the ground; in a list whose color
  is amber or olive, a lit chip and a checked task check would then differ in shade on one screen.
- **Q6. How Apple announces the selectable chip.** Recommended: the style's accessibility representation is the
  system's own `Toggle` in its `.button` style, on the same value and label, so that the system decides the words;
  measured at the implementation in the accessibility hierarchy, as Checkbox's were. If that is not announced as
  selected, a system `Button` with `.isSelected` while on, as the pilot does.
- **Q7. The Mac row's tag is 20 pt high in the pilot; the chip is `size.control.s`, 24.** Recommended: accept the
  4 pt now and revisit with ListRow (#119), where the line of metadata is laid out. The alternative is a static form
  that hugs its text, with no minimum height, since it is not a control.
- **Q8. The pills' meaning colors and their empty look.** The pilot draws an unset When or Deadline in ink 2 with its
  placeholder word, the set day's sun in Today's amber, and a due deadline in red. Recommended: none of it in this
  contract until the pills become pressable (Q3); the chip draws westron's colors and the product writes the words.
  The alternative is an option, such as a `tone` with `neutral` and `danger`, or a placeholder flag, decided with the
  Task screen's pickers.
- **Q9. A second signal for checked.** The fill and the words' color change together, and the state is announced;
  there is no check mark. Recommended: no mark, as the pilot draws it and as the system's button-style toggle does.
  The alternative is the `check` glyph in the icon's place while on, as Material's filter chip has.
- **Q10. Symmetric padding.** (P5.) Recommended: `space.125` both sides. The alternative is a narrower padding on the
  icon's side, which needs a binding that knows whether the icon is there.
- **Q11. A laid-out hit area on iOS.** (P10.) Recommended: laid out, as Checkbox's is and as the pilot's tag bar
  needs it (44 pt). The alternative is Button's iOS rule, the system's touch tolerance, which the 6 pt gap between
  chips would share.

## Approval

The coordinating agent approved the contract on 2026-11-22 under the owner's delegation (decisions/0014), with these
answers.

| Question | Answer |
|---|---|
| Q1 | A: one contract in several forms on several system bases. decisions/0003 will produce this shape again, so the tools learn it now: `forms` and per-platform `bases`, as small as Chip needs, every new rule tested, and a contract without `forms` behaving exactly as before (the other contracts' generated files did not change by a byte) |
| Q2 | Yes: the static form, `.labelStyle(.chip)` |
| Q3 | Keep the pressable form: decisions/0014, the list the owner confirmed, names Chip "selectable (a filter) or pressable (a value)". Its pilot consumer arrives with the Task screen's pickers; until then the pilot draws its inert pills as static chips |
| Q4 | (a): a chip lit in a list's color keeps its fill under the pointer and pressed; no new tokens |
| Q5 | `color.category.<name>.fill` and `on-fill`, as design-language/02 gives a lit tag; the contrast of a lit chip's fill is measured below, and no token changes for it |
| Q6 | As recommended, measured in the accessibility hierarchy, with the fallback as described: see "Implementation on Apple". Reversed after the audits: the system Toggle as the representation ("Revision after the audits", B) |
| Q7 | Accept `size.control.s` for the static form |
| Q8 | Out of this contract |
| Q9 | No check mark. Reversed after the audits: a lit chip shows the check in the icon's place ("Revision after the audits", A) |
| Q10 | `space.125` on both sides |
| Q11 | A laid-out frame at least `size.target.minimum` high |
| Tools, item 7 | Yes, here, since ListRow (#119) needs it too: a case that matches only when all the states it names hold, `state: { all: [checked, pressed] }`. The hover and pressed tints moved from the description into the bindings (P8, P11) |
| Tokens | Add the two missing contrast declarations, `color.text.secondary` on `muted-hover` and `muted-pressed`, unless a pair fails; then report instead of changing a value. Both failed as text; on review they were declared as non-text, since the icon is the only thing drawn there: below |

What changed from the draft: P1's bases and P13's accessibility are now `forms` and `bases` (the schema carries
them); P11 is answered by cases over several states, so the tints are bindings; P16's web and GTK bases are per form.

### The contrast of a lit chip's fill (Q5)

With no check mark (Q9), the fill is the only visible sign that a chip is on (the label's color changes with it); the
revision after the audits (A, at the end) adds the mark.
WCAG 2 contrast of the lit fill against the unlit fill, `color.background.muted`, and against the grounds a chip
stands on, the canvas and a raised surface (`color.background.surface`), in the four themes, from the resolved token
values (sRGB hex of `tokens/primitive/color.<theme>.tokens.json`, the semantic aliases of
`tokens/semantic/color.tokens.json`). Below 3:1 in bold.

| Fill | light: muted / canvas / surface | dark | light-hc | dark-hc |
|---|---|---|---|---|
| accent | 4.69 / 5.21 / 5.45 | **2.76** / 3.42 / 3.14 | 6.02 / 6.69 / 7.00 | 5.69 / 7.04 / 6.48 |
| blue | 4.69 / 5.21 / 5.45 | **2.76** / 3.42 / 3.14 | 6.02 / 6.69 / 7.00 | 5.69 / 7.04 / 6.48 |
| sky | 3.90 / 4.33 / 4.53 | 3.32 / 4.10 / 3.77 | 6.03 / 6.70 / 7.01 | 5.67 / 7.02 / 6.45 |
| teal | 3.89 / 4.33 / 4.53 | 3.32 / 4.11 / 3.78 | 6.09 / 6.76 / 7.07 | 5.67 / 7.02 / 6.45 |
| emerald | 3.88 / 4.31 / 4.51 | 3.34 / 4.13 / 3.80 | 6.09 / 6.77 / 7.08 | 5.68 / 7.03 / 6.47 |
| green | 3.88 / 4.31 / 4.50 | 3.34 / 4.13 / 3.80 | 6.03 / 6.69 / 7.00 | 5.68 / 7.03 / 6.46 |
| olive | **1.59 / 1.76 / 1.84** | 8.16 / 10.10 / 9.29 | **1.59 / 1.76 / 1.84** | 8.16 / 10.10 / 9.29 |
| amber | **1.64 / 1.82 / 1.90** | 7.91 / 9.78 / 9.00 | **1.64 / 1.82 / 1.90** | 7.91 / 9.78 / 9.00 |
| orange | 3.89 / 4.32 / 4.52 | 3.33 / 4.12 / 3.79 | 6.06 / 6.73 / 7.04 | 5.66 / 7.01 / 6.44 |
| red | 6.27 / 6.97 / 7.29 | **2.06 / 2.55 / 2.35** | 6.27 / 6.97 / 7.29 | 5.67 / 7.02 / 6.45 |
| pink | 4.40 / 4.89 / 5.11 | **2.94** / 3.64 / 3.35 | 6.04 / 6.71 / 7.02 | 5.68 / 7.02 / 6.46 |
| violet | 4.69 / 5.21 / 5.46 | **2.76** / 3.41 / 3.14 | 6.03 / 6.70 / 7.00 | 5.66 / 7.01 / 6.44 |
| indigo | 5.01 / 5.56 / 5.82 | **2.59** / 3.20 / **2.94** | 6.04 / 6.71 / 7.02 | 5.68 / 7.03 / 6.46 |

Plainly: 21 pairs fall under 3:1. In light and light-hc, a lit olive or amber chip stands about 1.6:1 off an unlit
one and under 2:1 off the canvas and a surface, in every case (their fills are light, under dark words). In dark, a
lit red chip is under 3:1 against all three grounds (2.06 off an unlit chip), and the accent, blue, pink, violet and
indigo fall under 3:1 against an unlit chip (2.59 to 2.94), indigo also against a surface. In the high-contrast
themes every chip also draws `color.border.strong` (P9), which gives its edge but not its state. The label's color
changes with the fill and the state is announced, so "on" is not color alone for assistive technology; on screen the
fill is the signal. No token changed (the approver's instruction); the owner decides at the second gate whether to
accept it, as for the text field's edge, or to answer it, with a check mark (Q9's alternative) or other fills.

### Two contrast declarations, as non-text

`color.text.secondary` on `color.background.muted-hover` and `muted-pressed` is drawn only by an unlit chip's icon
under the pointer or pressed: a decorative glyph beside the chip's label, never text (the label is
`color.text.primary`). Declared first as text (4.5:1; 7:1 in high contrast), all eight pairs failed. The approver
then had them declared as non-text (3:1; 4.5:1 in high contrast), with the reason in the token's description
(`tokens/semantic/color.tokens.json`); no value changed. `tools/westron tokens contrast`:

| Pair (non-text) | light | dark | light-hc | dark-hc |
|---|---|---|---|---|
| text.secondary on muted-hover | 4.20 | 4.42 | 6.59 | 6.85 |
| text.secondary on muted-pressed | 3.71 | 3.77 | 5.81 | 5.84 |

All eight pass. A future use of `text.secondary` as words on those fills would need its own declaration as text,
which fails today.

## Implementation on Apple

Decided and measured by the implementing agent on 2026-11-22 under the same delegation, pending the owner's review
of the snapshot matrix (the second gate).

- **Three styles, one look.** `ChipToggleStyle`, `ChipButtonStyle` and `ChipLabelStyle` (WestronUI/Chip/) draw one
  view from one table of tokens (`ChipTokens`), which the unit tests compare with the contract's bindings for every
  combination of the five states, cases over two states included (ChipStyleTests).
- **Q6, measured.** In the accessibility hierarchy as XCUITest reads it (iOS 26.3, the catalog's `chip` entry), the
  recommended representation, the system's own Toggle in its `.button` style, is a switch with the value 0 or 1,
  never selected; so is the style's body with no representation. So the fallback: the representation is a system
  Button with the toggle trait removed and `.isSelected` while on. Measured on iOS 26.3 and macOS 26: a button,
  labelled with the chip's words, selected while on, not while off; the pressable chip a button never selected; the
  static chip's words a text. A chip whose label is only text (`Toggle("Reading", isOn:)`) is the same element. The
  element also carries the value 0 or 1 (XCUITest reads the lit Home chip as a button, label "Home", value 1,
  selected): the product's Toggle around the style gives it, and the style cannot clear it, since
  `.accessibilityValue` inside the representation or around it on the style's body changed nothing (iOS 26.3). Only
  a product that wrote a plain Button with `.isSelected` instead of a Toggle would lose it, which would give up the
  system Toggle as the base (Q1), so it was not tried. What VoiceOver itself speaks for it is not measured. iOS 17,
  macOS 14 and watchOS run the same code, not measured (ChipBehaviorTests).
- **Q11.** The selectable and pressable forms lay out a frame at least `size.target.minimum` high around the drawn
  capsule, every point of it taking the press; across, the chip's width (ChipStyleTests; ChipBehaviorTests presses
  2 pt inside the frame's top edge, above the capsule). On macOS the system's focus ring follows the drawn capsule
  (`contentShape(.focusEffect, …)`). `ChipBehaviorTests.testKeyboardFocusAndSpace` tabs to the selectable chip,
  presses Space twice and checks that the next Tab reaches the next chip (one focus stop, not two); it runs on a Mac
  with keyboard navigation on and is skipped otherwise, and the Mac it ran on had it off, so keyboard focus is still
  not measured.
- **Truncation and the text role.** The label is one line, truncated at its end, in the width the container gives,
  in `label.font`; the icon keeps its size. The selectable and pressable styles set the text role, the one line and
  the truncation around the whole label, as Button's does, so a label that is only text, which no label style
  reaches, is drawn as a `Label`'s title is (ChipStyleTests, `textOnlyLabel`; the catalog's "A label that is only
  text"; the supplements `text-only-selectable` and `text-only-pressable`).
- **The snapshot matrix** draws each form in the states it enters, and supplementary sheets: a chip lit in the accent
  in each state (accent-hover and accent-pressed, which the generated sheets, each state alone, do not draw), the
  twelve list colors lit in each state, three to a sheet, a long label in a narrow place in each form and state, and
  a label that is only text, short and long, in each state of the selectable and pressable forms.
  The list-color sheets stop growing at the default text size, so a cell is one line on an iPhone; the text sizes
  are the generated sheets'.
- **The accessibility audit** of the `chip` entry passes on iOS 26.3 in its five configurations, with three
  suppressions, each in `CatalogAccessibilityAuditTests` with its reason: contrast on the disabled samples, which
  the system disables (WCAG exempts an inactive control); "text clipped" on the long label, with an icon or text
  only, truncated by the contract while the element's label is the whole name; and "text clipped" on the pressable
  chip the catalog holds pressed, in every configuration that runs that audit (the default settings and
  accessibility5). Its cause is measured: the contract draws a pressed chip at 0.98 of its size, and with the scale
  set to 1 the finding was gone; the text is whole in the screenshots. A real press draws the same scale while it
  lasts, when no audit runs. No lit chip and no list color was reported at the default size or in the other themes.

## Revision after the audits, 2026-11-22

After the code review, a check of the implementation against the contract and an accessibility audit found what is
below. The coordinating agent approved each change under the owner's delegation (decisions/0014); the contract was
changed first, then the code. No token changed and no token was added.

### A. A lit chip shows a mark (Q9 reversed)

Q9 left the fill the only sign on screen that a chip is on. The audit measured that this fails WCAG
[1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color) and [1.4.11](https://www.w3.org/TR/WCAG22/#non-text-contrast) in
ten cases of a color and a theme, where a lit chip stands under 3:1 off an unlit one (the table under "The contrast of
a lit chip's fill"): in light and light-hc, olive 1.59 and amber 1.64; in dark, the accent, blue and violet 2.76, red
2.06, indigo 2.59 and pink 2.94. In every color it also falls short of design-language/08, "A checked control shows a
mark". So a checked selectable chip draws the registry's `check` glyph in the icon's place, at the icon's size, in
the words' color on the fill (`icon.color`'s checked case: `color.text.on-accent`, or the list's `on-fill`), decorative
and hidden from assistive technology, which announces the state itself (B).

- **A chip with an icon** swaps its icon for the check while it is on: the check is drawn over the icon's place, the
  icon hidden, so the chip keeps its width and nothing beside it moves.
- **A chip whose label is only text** has no icon to swap: it grows by the check and `container.gap` before its label
  while it is on, as Material's filter chip does. The style learns in the same update whether the label it draws has
  an icon, from the label's layout, as Button's loading indicator does (`IndicatorBeforeLabelLayout`).
- **Motion.** The check comes in and goes with the fill as a fade, in `motion.fade`. A text-only chip's width changes
  with them; with Reduce Motion the fades stay (design-language/05, "Color fades stay") and the width changes at once,
  so that nothing slides ("Travel becomes a fade"): the check fades in, and leaves at once with its room.
- **The fills do not change.** The lit fills keep the contrast measured above, now beside a mark; the owner may still
  answer the fills at the second gate.
- The contract format has no binding for a glyph: the description says that the icon becomes the check while the
  chip is on, as it says the list's color; the check's color is `icon.color`, whose checked case already gives the
  words' color.

### B. The selectable chip is the system's toggle to assistive technology (Q6's fallback reversed)

The fallback of Q6 represented the selectable chip as a system Button with the toggle trait removed and `.isSelected`
while on. The product's Toggle around the style still gave that element the value 0 or 1, which nothing in a style
can clear (above, "Implementation on Apple"), so VoiceOver would likely say "Home, 1, button": a button with a stray
number. design-language/08 says "A system control keeps its own role and traits". So the representation is the
system's own Toggle on the same value and label, in its automatic style, as Checkbox's is
(`CheckboxVariantStyle.swift`): assistive technology meets the toggle's role and traits and its value, on or off, in
the platform's words, and no button; `.isSelected` is not added, since the state would then be said twice. The
contract's `accessibility` now gives the selectable form the role `toggleButton` and announces `checked` as the
toggle's own checked value, on or off, instead of "selected"; "off, it is announced with no state" is gone, since the
value is announced in either state. The words design-language/08 lists, "selected, unavailable, busy", are examples of
announced states: the selectable chip's is the toggle's on or off, as a checkbox's is.

### C. Smaller changes

- **The press's tint** moves in `motion.press`, as Button's does and as design-language/05 gives a press "its tint,
  and its scale"; hover and checking keep `motion.fade`.
- **The hit area is at least `size.target.minimum` across** as well as high: a chip of one or two letters is narrower
  than the target, so its laid-out frame is widened to the target, the drawn capsule keeping its size, centred. It is
  laid out, so chips side by side move apart instead of overlapping: where a short chip's frame is wider than its
  capsule, the gap between two capsules grows by the difference.
- **Hover on macOS** starts and ends at the drawn capsule, as Button's does (`contentShape(.interaction, …)` on the
  capsule), not at the corners of the hit area beyond it; the click is still taken in the whole hit area. Measured on
  macOS afterwards, that content shape did not hold the hover to the capsule, and the location of the pointer is now
  tested against it (below, "Measured on macOS").
- **The accessibility shape** is the drawn capsule, `contentShape(.accessibility, …)`, on every OS, and the focus
  effect's shape the capsule on macOS and watchOS, as Button's are.
- **A truncated label** is whole only to a screen reader, so the contract says that a product gives a chip the width
  its label needs, in a tag bar that scrolls or a row that wraps, and that truncation is the last resort.
- **The static form under `.disabled(true)`** is drawn as it is, undimmed: the form enters no state, disabled
  included. Nothing else is decided for it.
- **watchOS** gives its hit-area numbers, 44 pt high and across around the 32 pt chip, as iOS and macOS do.

### Measured after the revision

On iOS 26.3 (the iPhone 17 simulator), as XCUITest reads the hierarchy (`ChipBehaviorTests`), not with VoiceOver
itself; `type` is XCUIElement's element type:

| Element | What the hierarchy holds |
|---|---|
| Selectable, Work (off), Home (on), Errands (green, off) | A switch (type 40), label "Work", value 0 (Home 1), not selected, enabled, frame 44 pt high; no button, no image under it, the name once |
| Selectable, text only, Reading (on) | A switch, label "Reading", value 1, not selected |
| Selectable, disabled and "disabled, on" | Switches with value 0 and 1, not enabled |
| Pressable, Tue | A button (type 9), label "Tue", not selected, 44 pt high; under it its words as a text, and the icon and the check, each an element of type other with no label, value or trait |
| Pressable, disabled | A button, not enabled |
| Static, Garden and Groceries | Texts, 28 pt high: the capsule |
| The long label, truncated | A switch, a button and a text each labelled with the whole label |

- **The icon under a button (C).** A westron Button with a Label in the same hierarchy shows its icon as an image named
  after its symbol, the check with the trait selected (`Button` entry, iOS 26.3), from `.accessibilityHidden(true)`
  as Chip had it. Chip's glyphs now also give an empty representation, as IconTile's symbol does (#118): XCUITest
  then lists each as an element of type other with nothing in it. `.accessibilityElement(children: .combine)` around
  the label did not remove them. Button's own icon is outside this change.
- **The accessibility frame (C).** With `contentShape(.accessibility, …)` on the drawn capsule, as Button sets it, the
  element's frame is still the 44 pt hit area on iOS.
- **The hit area.** `ChipBehaviorTests.testHitAreaAroundTheChip` presses 1 pt inside the element's top edge, 7 pt
  above the drawn capsule on iOS and 1 pt above it on macOS, and toggles on both; a one-letter chip, `Toggle("I", …)`,
  lays out 44 pt across on iOS and 28 on macOS (`ChipStyleTests`).
- **The check in a narrower icon's place.** The check is drawn centred over the hidden icon at its own size, so over
  an icon narrower than it, it reaches past the icon's frame by half the difference on each side, into the padding
  and into the gap before the label. `ChipStyleTests.markInEveryIconsPlace` measures every registry icon at the
  default text size and at accessibility5: a lit chip keeps the unlit one's width and height, and the check spills
  less than the gap as laid out at that size. The most it spills is 1.5 pt of the 4 pt gap on macOS, over
  `chevronLeft`, 6 pt wide against the check's 9 (macOS has no Dynamic Type, so both sizes measure the same); on iOS
  26.3, 6.5 pt of the 11.3 pt gap at accessibility5, over `chevronLeft` too. It never reaches the label, so nothing
  changed.

### Measured on macOS, 2026-11-22

On macOS 26.7.1, as XCUITest reads the hierarchy (`ChipBehaviorTests`), not with VoiceOver itself, after the Mac's
screen, locked when the revision was made, could run the catalog again:

| Element | What the hierarchy holds |
|---|---|
| Selectable, Work (off), Home (on), Errands (green, off) | A checkbox (type 12), label "Work", value 0 (Home 1), not selected, enabled, frame 28 pt high: the hit area; no button, no image under it, the name once |
| Selectable, text only, Reading (on) | A checkbox, label "Reading", value 1, not selected |
| Selectable, disabled and "disabled, on" | Checkboxes with value 0 and 1, not enabled |
| Pressable, Tue | A button (type 9), label "Tue", value empty, not selected, 28 pt high, with no element under it |
| Pressable, disabled | A button, not enabled |
| Static, Garden and Groceries | Texts (type 48) with an empty label and their words as the value, 24 pt high: the capsule |
| The long label, truncated | A checkbox, a button and a text each named with the whole label |

- **The hit area.** A click 1 pt inside the element's top edge, 1 pt above the drawn capsule, toggles the chip
  (`testHitAreaAroundTheChip`).
- **Hover did not end at the capsule.** `testHoverAtTheCapsule` moves the pointer and reads the hover the style draws
  from a readout on the catalog page (`onChipHover`, catalog only). With `.contentShape(.interaction, capsule)` before
  `.onHover`, as the revision had it (C), the pointer 1 pt above the capsule, outside the capsule's frame, left the
  chip at rest, but the pointer 2 pt in from the frame's left edge and 1 pt below its top, outside the capsule's round
  end, hovered it: `onHover` follows the whole frame, and a rectangular interaction shape measured the same. So the
  style now tests the pointer's place in the frame against the capsule (`onContinuousHover`, `ChipHover`): the
  pointer in the margin and in the corner leaves the chip at rest, inside the capsule it is hovered, and leaving for
  the margin or the corner ends the hover. Button's style, whose comment says that its interaction shape holds hover
  to its drawn edge, uses the same `onHover`; it is outside this change.

  Note of 2026-11-24 (#130): `ChipHover` moved to WestronUI as `ShapeHover`, which Chip and Button now share. Measured
  on macOS with Button's `onHover` before that change, Button's comment held for its buttons on the `button-behavior`
  page, which read no hover in their frames' corners; only its floating buttons were hovered there, and why is not
  established. The record above is left as it was.
- **Keyboard focus** is not measured: `testKeyboardFocusAndSpace` is skipped on a Mac with keyboard navigation off,
  as this one has it, as it was before.
- **The screenshot** of the `chip` entry (`tools/apple/catalog-screenshot.sh macos --entry chip`, dark) draws each
  form in its states, the live tag bar and both readouts, as on iOS.
- The accessibility audit of the `chip` entry passes on iOS in its five configurations with the three suppressions
  above. An unlit sample at rest first in its own row moved the page so that the audit's second screenful reported
  "potentially inaccessible text" with no element; the sample stands beside the lit one in the row of `checked`
  instead, and the audit passes.

### Note of 2026-11-24: the glyphs leave no element (#131)

Chip's glyph modifier moved to WestronUI as `DecorativeGlyph`, which Button's icon now uses too, with its two
modifiers the other way round: hidden, then represented by nothing. In that order XCUITest lists nothing under the
pressable chip, neither the empty elements of type other of the table above nor the words as a text, as under a
button whose label is only text; the button's own element is what it was (iOS 26.3, `ButtonBehaviorTests`'
`testIconIsNoElement` and `ChipBehaviorTests`). What VoiceOver speaks is not measured.

On macOS the glyphs are hidden alone, as Button's were before #131: there the empty representation last made a loading
Button's value read twice, "Loading, Loading", through the progress indicator before its label, and hidden alone lists
nothing under the pressable chip or a westron Button either (macOS 26.7, the same tests; `DecorativeGlyph` records
the measurement).

### Note of 2026-11-25: the hover and pressed steps in every theme (#170)

Agreed by the owner on 2026-11-25. The contract said that the fill "darkens a step" under the pointer and pressed, and
the `unset` text of `reads` that the accent is "a step darker". The bindings are unchanged; the tokens they name are not
darker in every theme:

| Theme | `muted` → `muted-hover` → `muted-pressed` | `accent` → `accent-hover` → `accent-pressed` | `text.on-accent` |
|---|---|---|---|
| light | `#EBEEF4` → `#DEE1E7` → `#D1D4DA` | `#2863D7` → `#1C56C9` → `#0F4ABC` | `#FFFFFF` |
| dark | `#22272D` → `#2C3037` → `#363B41` | `#2863D7` → `#1C56C9` → `#0F4ABC` | `#FFFFFF` |
| light, high contrast | `#EBEEF4` → `#DEE1E7` → `#D1D4DA` | `#1651C3` → `#0844B6` → `#0038A5` | `#FFFFFF` |
| dark, high contrast | `#22272D` → `#2C3037` → `#363B41` | `#6A9EFF` → `#7EACFF` → `#93B9FF` | `#101318` |

The muted fill moves towards its label, `text.primary`, in every theme: darker in the light themes, lighter in the dark
ones. The accent fill moves away from its words in every theme: darker in three, lighter in dark high contrast, where
the accent is light and its words dark (design-language/02, "A filled control darkens as it is pressed", says so of
dark high contrast). The description now says that, and the `reads` entry says it in words, without token paths, as
the short card of the agent context prints it; the description keeps the token-level account. The table of "Already
decided by the documents" above keeps its summary of the time.
