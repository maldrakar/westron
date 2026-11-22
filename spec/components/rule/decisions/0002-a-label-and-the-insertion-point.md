# 0002. A label, and the insertion point

Date: 2026-11-22 (#116). Status: proposed, waiting for the approver at the first gate (decisions/0005). It amends the
approved contract, which stays approved and unchanged until this revision is approved: the proposed contract is in
full at the end of this record, and `rule.spec.yaml` only points here. There was no interview: the agent answered the
`/new-component` questions from the owner's decision of 2026-11-22, the documents and the pilot, and every answer it
had to guess is a question below for the approver.

## Context

The pilot's Lists screen (`todo-app/lists-screen`, `~/todo-app/docs/specs/lists-screen.md`, sections 1, 3 and 6) draws
two lines that westron does not have yet:

- **An area's line.** "An area is a line across the tree: a named area carries its name on the line, an unnamed one
  is the line alone" (owner of the pilot, 2026-10-25). The pilot draws its label at the leading end, then the line
  across the rest (`AreaLineModel`, `AreaLineStyle`): on the phone in its area label font and second ink, sentence
  case, 10 pt before the line; in the sidebar in a caption in capitals in its third ink, 6 pt before the line. In
  edit mode a rename field takes the label's place. The line is 1 pt in the pilot's line color, as its other rules.
- **An insertion point.** While a row is dragged, the sidebar (Mac and iPad) marks where it would land with the
  Finder's indicator (`DropIndicatorStyle`, `TaskViewList+Components.swift`, `sidebarDrag`): a 2 pt line in the
  accent with round ends, from the tile of the drop's depth to short of the edge, and a ringed circle 10 across at its
  leading end. The phone instead opens a slot where the row would land, a rounded rectangle on the accent's soft
  fill with a dashed accent outline (`DragStyle.Slot`, `phoneDrag`).

decisions/0013 left "the labelled area line" to a phase 4 component, and Rule's own contract
(decisions/0001, "Scope") left "the line of a labeled area" to the component that draws it.

## What the owner decided

On 2026-11-22: these are not new components. **The area's line is the existing Rule with a label.** Whether the
insertion indicator is a Rule, for example in the accent color, is decided at this contract. Nesting guides are not
Rule's: they go with ListRow (#119).

## Already decided by the documents

| What | Source |
|---|---|
| `stroke.thin` draws rules; `stroke.thick` draws "a focus ring, a drop indicator and a selection ring", the lines that mark "where a dragged item will land" | design-language/04, "Lines" |
| A line's color comes from the border tokens; `border.focus` draws the focus ring | design-language/04, "Lines"; 02 |
| Words stop at `text.secondary`: any lighter ink fails the text target | design-language/02, "Two inks for words" |
| `heading.overline` is "a short label in capitals above a group: a sidebar section"; the product writes the capitals | design-language/03; `typography.heading.overline` |
| A one-line label may truncate with an ellipsis when its whole text is still read | design-language/03, "Text is never clipped" |
| A drop moves on `motion.move` | design-language/05 |
| The pilot is right about behaviour, westron's look is its own: roles, not the pilot's values | decisions/0006, 0011–0013 |

## Options considered

### The label

- **Where along the line.** (a) At the leading end, the line across the rest; (b) centred, the line on both sides;
  (c) an option for either. **Proposed: (a)**, the pilot's only use and the reading order of a heading. No option
  until a consumer needs another place (AGENTS.md, rule 6).
- **What it is.** (a) Text only: `Rule("Work")`; the rename field in edit mode is the product's own row, a field and
  an unlabelled `Rule()` side by side with the same gap; (b) any view, a `@ViewBuilder` label, so the field can sit in
  the label's place. **Proposed: (a)**: a text label is what a heading can truthfully be announced as (below), and a
  field in a heading's place would be announced as a heading.
- **A vertical rule with a label.** (a) Not allowed; (b) the label at the top, the line running down below it;
  (c) the label turned on its side. **Proposed: (a)**: no consumer has one, and a vertical rule in a bar is about as
  tall as one line of text. An insertion rule takes no label either.
- **Text role and color.** (a) `heading.overline` in `text.secondary`, the product writing the name in capitals;
  (b) a text role in sentence case, such as `footnote.medium` or `subheadline.strong`, in `text.secondary`.
  **Proposed: (a)**, the role chapter 03 names for a label above a group in a sidebar. The color is not a choice:
  the pilot's second and third inks both become `text.secondary`, since words stop there.
- **The gap between the label and the line.** `space.100`, 8, between the pilot's 10 on the phone and 6 in the
  sidebar, on the base of the ladder.

### Accessibility

Rule's role is `none` today: a line with no content, hidden. A labelled rule says something.

- (a) **Role `heading`**: the label is announced as a heading and names the group under it, so a person moves from
  area to area by headings (VoiceOver's rotor, a screen reader's heading keys); the line is not announced, and an
  unlabelled rule stays hidden as today.
- (b) **Role `none`**: the label is read as plain text, as content inside a component with no role of its own.
- (c) **Role `separator`** with the label as its name: ARIA makes a separator's content presentational, and the
  platforms announce a separator, which the unlabelled rule deliberately is not.

**Proposed: (a).** The label is the name of the group below it, which is what a heading is; (b) reads the same words
but leaves a long tree with no landmarks. One role covers both forms because an unlabelled rule has no content to
announce, which the contract's description says. Where the product makes the line tappable or gives it a menu, as
the pilot does, that is the product's control around the rule (or ListRow's, #119), and the heading trait stays on
the label.

### The insertion point

- (a) **A Rule with an option**, `purpose: insertion`: `stroke.thick` in `color.border.focus` with round ends; the
  list or the product places it in the gap where the item would land, at the depth's indent in a tree, and moves it
  with `motion.move`.
- (b) **A component of its own**, a drop indicator with the Finder's circle at its leading end.
- (c) **Not westron's**: each product, or ListRow (#119), draws its own mark.

**Proposed: (a).** Chapter 04 already gives a drop indicator its width and puts it among the lines; what differs from
a separator is the width, the color and the ends, which an option of the line covers, and axis, length and placement
work as for any rule. The circle is the Finder's look, not westron's: the line's leading end already shows the depth
at which the row would land. (c) would leave the color and width of a drag's mark to each product. Where it stands
and when it shows stays the list's or the product's, since only they follow the drag. The phone's slot is not a line
and is not a Rule: it is a placeholder a list opens between its rows, for ListRow (#119) or the list that reorders.

- **The option's name.** `purpose`, with `separator` (default) and `insertion`; named by what the line is for, not
  by its look, as tokens are. Not `variant`, which a view does not derive yet and which the default needs anyway; not
  `role`, which reads as the accessibility role or Button's `ButtonRole`; not `tone` or `emphasis`, which name a look.
- **The color.** (a) `color.border.focus`, a border token that already meets the non-text target (3:1, 4.5:1 in
  high contrast) on canvas, surface, sunken, hover and selected, every ground a list's rows stand on; (b) a token of
  its own, `color.border.insertion`, aliasing the same step; (c) `color.background.accent`, a fill, whose usage asks
  for one filled control on a screen. **Proposed: (a)**, with its description widened (below, "Tokens").
- **The ends.** Round, `line.shape: capsule` for `insertion`, as the pilot rounds its line and as direction B's soft
  shapes do (decisions/0013). A separator keeps square ends: at `stroke.thin` a capsule would change nothing visible
  and would change the approved snapshots.
- **A vertical insertion rule** is allowed, between items side by side, though no consumer needs it yet: `axis`
  exists already and costs nothing here.

## Proposed, to confirm

| # | Proposal | Source |
|---|---|---|
| P1 | The slot `label`, text only, at the leading end; then `container.gap` (`space.100`) and the line across the rest, centred across the label's line | Owner (Rule with a label); pilot for the place; the gap is the agent's |
| P2 | The label on one line, truncated at its end with an ellipsis, read whole; with no length left the line draws nothing | design-language/03 |
| P3 | The label in `typography.heading.overline` and `color.text.secondary`; the product writes the capitals | design-language/02, 03 |
| P4 | Only a horizontal separator takes a label; on Apple the label's initializers take no `axis` and no `purpose` | Agent |
| P5 | `accessibility.role: heading`, `label: optional`; an unlabelled rule stays hidden, the line is never announced | Agent |
| P6 | The option `purpose`, `separator` (default) or `insertion` | Owner (decide it at the contract); the form is the agent's |
| P7 | An insertion rule: `stroke.thick`, `color.border.focus`, round ends; no circle; placed and moved by the list or the product | design-language/04; the color and the dropped circle are the agent's |
| P8 | The phone's drop slot and the tree's nesting guides are not Rule's (ListRow, #119) | Owner (guides); agent (slot) |
| P9 | Web and GTK, provisional: a labelled rule is an element or a box with the heading role holding the label and a hidden line | Agent |

## Open questions for the approver

1. **The label's role** (P3): `heading.overline` in capitals, or a sentence-case role (`footnote.medium`,
   `subheadline.strong`), as the pilot's phone draws its area names? Guessed from chapter 03's "a sidebar section".
2. **The gap** (P1): `space.100`, 8? Guessed between the pilot's 10 and 6.
3. **Accessibility** (P5): a heading, or plain text (role `none`)?
4. **The insertion color** (P7): reuse `color.border.focus` and widen its description, or add a token of its own?
   Reusing it means a drop and focus share a color; they rarely show together, but they can on the Mac.
5. **The Finder's circle** (P7): dropped as the pilot's look, not westron's. Does the approver want a mark at the
   leading end?
6. **The rename field** (P1): text-only label with the field as the product's own row, or a view label?
7. **The name `purpose`** and its values `separator` and `insertion` (P6).
8. **A vertical insertion rule** with no consumer: keep it allowed, or forbid it until one needs it?

## What the tools need before this is implemented

Measured on 2026-11-22 by putting the proposed contract in place: `tools/westron spec check` passes it; `tools/westron
generate` refuses it, "a view with slots other than an icon's spoken label (an option whose values are icons and the
one slot label): the conventions do not derive an own-component's API for it yet", and the API parity lint then
reports `Rule` and `RuleAxis` as API no contract gives. So the contract stays as it is until approval, and the
implementation (#116, second gate) extends the tools first:

- **T1. A constraint that names a slot** (schema, `ContractRules`): the contract cannot say today that a labelled
  rule is a horizontal separator, since a constraint names options only. Proposed form:
  `{ when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, severity: error }`, the slot
  present in `when`. Until then P4 lives in the descriptions alone.
- **T2. The API of a view with a text label** (`AppleComponents.Own`, `spec/conventions.md`, "Own components"): a
  view with the one slot `label` and no option whose values are icons gets `init(axis: RuleAxis = .horizontal,
  purpose: RulePurpose = .separator)`, `init(_ label: LocalizedStringKey)` and
  `@_disfavoredOverload init<S: StringProtocol>(_ label: S)`, the label first and unlabeled, as `Text` and `Label`
  take their titles; the options a T1 constraint fixes to one value when the label is present are left out of the
  label's initializers. `RulePurpose` is not a SwiftUI type name. The API parity lint reads `Own.initializers`, so it
  follows.
- **T3. The snapshot matrix**: `purpose` becomes a generated axis by itself (2 × 2 combinations), and the generated
  `RuleMatrixValues` makes `RuleMatrixCell` draw it. The matrix has no slots, so the labelled rule needs a
  hand-written supplementary sheet, "not a contract option", with a short and a truncated label at the text sizes,
  as the text sizes are supplements today.
- **T4. The conventions**: a row for the role `heading` (Apple `.accessibilityAddTraits(.isHeader)` on the label;
  web `role="heading"` with a level, #40; GTK the heading accessible role; Compose `semantics { heading() }`), and
  the example of role `none` "on a component with no content (Rule)" rewritten, since Rule's role becomes `heading`.

## Tokens

None is missing for the proposal: `stroke.thick`, `color.border.focus`, `space.100`, `typography.heading.overline`
and `color.text.secondary` exist, and `border.focus` already declares the non-text pair on every ground of a list.
With open question 4 as proposed, `color.border.focus`'s description gains "and the line that marks where a dragged
item would land" (a text change of `tokens/semantic/color.tokens.json`, made with the implementation). If the
approver prefers a token of its own: `color.border.insertion`, aliasing `{color.blue.8}` as `border.focus` does,
with the same `dev.westron.contrast` declaration (non-text on canvas, surface, sunken, hover and selected).

## The proposed contract

`spec/components/rule/rule.spec.yaml` as it would read once approved. `tools/westron spec check` passes it.

```yaml
# westron's Rule contract (#29, which calls it a divider), approved on 2026-11-18 under the owner's delegation of that
# day: decisions/0001-rule-contract.md records the owner's answers, what the documents already decide, and the
# proposals approved on top of them; P2 still waits for the owner's confirmation. Revised by #116
# (decisions/0002-a-label-and-the-insertion-point.md): the label and the purpose `insertion`, on the owner's decision
# of 2026-11-22 that the area's line is a Rule with a label.
id: rule
status: approved
description: >-
  A straight line that separates two groups, or marks where a dragged item would land: westron's own line, the same
  on every platform, rather than the system's separator, whose thickness and color the system fixes. A separator is
  color.border.default at stroke.thin; in the standard themes it is decoration, since space and alignment also show
  the grouping, and in the high-contrast themes its color reaches 3:1 and its width stays (design-language/02, 04).
  A horizontal separator may carry a label at its leading end, the name of the group under it, such as an area's
  line across the Lists screen's tree: the label on one line, then the line across the rest. An insertion rule
  marks the point where a dragged row would be dropped, at stroke.thick in color.border.focus, which a person finds
  at once (design-language/04, "Lines"); where it stands, and when, is the list's or the product's, which follows
  the drag. A horizontal rule spans the width it is given, a vertical one the height; the product gives it that
  length and the space around it with its stack and spacing tokens. Only straight rules: a tree's nesting guides go
  with ListRow (#119), and the slot a dragged row opens on a phone, a dashed outline, is not a Rule. It has no
  states.
consumers: [todo-app/lists-screen, todo-app/list-screen]

options:
  axis:
    type: enum
    values: [horizontal, vertical]
    default: horizontal
    description: >-
      horizontal runs along the width and separates groups stacked one above the other; vertical runs along the
      height and separates groups side by side. A vertical rule takes no label.
  purpose:
    type: enum
    values: [separator, insertion]
    default: separator
    description: >-
      separator divides two groups and is quiet; insertion marks where a dragged item would be dropped, between two
      items of a list (horizontal) or of a row of items side by side (vertical), and must be found at once. An
      insertion rule takes no label.

slots: [label]

tokens:
  line.color:
    token: color.border.default
    cases:
      - { when: { purpose: insertion }, token: color.border.focus }
  line.thickness: { separator: stroke.thin, insertion: stroke.thick }
  line.shape:
    cases:
      - { when: { purpose: insertion }, token: capsule }
  container.gap: space.100
  label.font: typography.heading.overline
  label.color: color.text.secondary

accessibility:
  role: heading
  label: optional
  description: >-
    A rule without a label is decorative, whatever its purpose: it is hidden from assistive technology, which already
    reads the groups it separates by their own content, and learns of a drop's place from the drag, not from the
    line. A labelled rule names the group under it, so its label is announced as a heading with that text, and a
    person can move from one group to the next by headings; the line itself is not announced. The label is read
    whole, also where it is truncated on screen.

platforms:
  apple:
    strategy: own-component
    form: view
    description: >-
      A view named Rule: Rule(), Rule(axis: .vertical), Rule(purpose: .insertion), and Rule("Work") with a label,
      or Rule(area.name) for a label that is not localized, as Text and Label take their titles. The initializers
      with a label take no axis and no purpose, so a labelled rule is a horizontal separator by construction. A
      type named Divider would collide with SwiftUI.Divider in every file that imports SwiftUI (decisions/0003,
      point 3). The line is a filled rectangle across its axis, rounded as a Capsule for an insertion rule, that
      fills the length it is offered along it, so it needs no stack to orient it, unlike the system Divider. A label
      is a Text in .textRole(.heading.overline), on one line, truncated at its end with an ellipsis when the rule
      is narrower than it, carrying the trait isHeader; container.gap after it the line fills the rest, centred
      across the label's line, and draws nothing when no length is left. An unlabelled rule is hidden from
      accessibility. On watchOS a rule is drawn as on the other OSes.
  web:
    status: planned
    description: >-
      Provisional until phase 6 (#40): an <hr> with westron's CSS for an unlabelled horizontal rule, hidden from
      assistive technology with aria-hidden; a vertical rule is an element of its own, decided with the library's
      shape; a labelled rule is an element with role heading, its level decided with #40, holding the label and a
      line hidden from assistive technology.
  linux:
    status: planned
    description: >-
      Provisional until phase 7: a stock GtkSeparator in its orientation, with westron's color and width through a
      style class, hidden from assistive technology; a labelled rule is a box with a GtkLabel whose accessible role
      is a heading and a separator after it.
  android:
    status: planned
```
