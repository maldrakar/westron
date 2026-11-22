# 0002. A label, and the insertion point

Date: 2026-11-22 (#116). Status: approved on 2026-11-22 by the coordinating agent under the owner's delegation
(decisions/0014), with the answers below, pending the owner's confirmation with the second gate. It amends the
approved contract, `rule.spec.yaml`, which now carries the label, the purpose `insertion` and a constraint on the
label. There was no interview: the agent answered the `/new-component` questions from the owner's decision of
2026-11-22, the documents and the pilot, and the approver answered the questions the agent had to guess.

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

- (a) **A Rule with an option**, `purpose: insertion`: `stroke.thick` in an accent border color with round ends; the
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
  for one filled control on a screen. The agent proposed (a), with its description widened; **the approver chose
  (b)** (answer 4, below, "Tokens").
- **The ends.** Round, `line.shape: capsule` for `insertion`, as the pilot rounds its line and as direction B's soft
  shapes do (decisions/0013). A separator keeps square ends: at `stroke.thin` a capsule would change nothing visible
  and would change the approved snapshots.
- **A vertical insertion rule** is allowed, between items side by side, though no consumer needs it yet: `axis`
  exists already and costs nothing here.

## Approved

| # | Proposal | Source |
|---|---|---|
| P1 | The slot `label`, text only, at the leading end; then `container.gap` (`space.100`) and the line across the rest, centred across the label's line | Owner (Rule with a label); pilot for the place; the gap is the agent's |
| P2 | The label on one line, truncated at its end with an ellipsis, read whole; with no length left the line draws nothing | design-language/03 |
| P3 | The label in `typography.heading.overline` and `color.text.secondary`; the product writes the capitals | design-language/02, 03 |
| P4 | Only a horizontal separator takes a label; on Apple the label's initializers take no `axis` and no `purpose` | Agent |
| P5 | `accessibility.role: heading`, `label: optional`; an unlabelled rule stays hidden, the line is never announced | Agent |
| P6 | The option `purpose`, `separator` (default) or `insertion` | Owner (decide it at the contract); the form is the agent's |
| P7 | An insertion rule: `stroke.thick`, `color.border.insertion` (answer 4), round ends; no circle; placed and moved by the list or the product | design-language/04; the approver |
| P8 | The phone's drop slot and the tree's nesting guides are not Rule's (ListRow, #119) | Owner (guides); agent (slot) |
| P9 | Web and GTK, provisional: a labelled rule is an element or a box with the heading role holding the label and a hidden line | Agent |

## The approver's answers

On 2026-11-22, by the coordinating agent under the owner's delegation (decisions/0014):

1. **The label's role**: `heading.overline`, as proposed; design-language/03 names it for a label above a group.
   Rule does not change the case: the product writes the capitals.
2. **The gap**: `space.100`, approved.
3. **Accessibility**: a labelled rule is a heading, an unlabelled one is hidden, approved.
4. **The insertion color**: a token of its own, `color.border.insertion`, aliasing `{color.blue.8}` with the same
   non-text contrast declaration as `color.border.focus`; focus's meaning is not widened. This changes P7.
5. **No Finder circle.**
6. **A text-only label**; the rename field is the product's own row.
7. **`purpose: separator | insertion`**, approved.
8. **A vertical insertion rule stays allowed.**

## How the tools settled it

Before this revision `tools/westron generate` refused the contract, "a view with slots other than an icon's spoken
label … the conventions do not derive an own-component's API for it yet", and the API parity lint then reported
`Rule` and `RuleAxis` as API no contract gives. The implementation (#116) extended them first, no wider than Rule
needs (spec/components/README.md; spec/conventions.md, "Own components"):

- **T1. A constraint on a slot** (schema description, `ContractRules.checkConstraints`, `ComponentContract.Constraint`):
  `{ when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, severity: error }`. It names slots
  the contract declares and no option in its `when`, forbids, and gives each enum option it requires one value. No
  option may be named `slots`. A combination of options fills no slot, so the snapshot matrix leaves nothing out for
  it.
- **T2. A view's drawn text label** (`AppleComponents.Own.textLabelInitializers`): `init(axis: RuleAxis =
  .horizontal, purpose: RulePurpose = .separator)`, `init(_ label: LocalizedStringKey)` and
  `@_disfavoredOverload init<S: StringProtocol>(_ label: S)`; the label's initializers leave out the options the T1
  constraint fixes. The API parity lint follows from `Own.initializers`.
- **T3. The snapshot matrix**: `purpose` is a generated axis (2 × 2, two sheets), and the supplement `labelled`
  draws labelled rules, a short label and a long one that truncates, at every text size the matrix renders.
- **T4. The conventions**: the role `heading` on each platform, and the role `none` example no longer cites Rule.

## Tokens

`color.border.insertion`, added with this revision: `{color.blue.8}`, the focus ring's step, with the non-text
declaration of `color.border.focus` (canvas, surface, sunken, hover, selected; 3:1, 4.5:1 in high contrast), so that
the two can change apart. design-language/02 and 04 list it among the border roles. The other bindings use tokens
that existed: `stroke.thin`, `stroke.thick`, `space.100`, `typography.heading.overline`, `color.text.secondary` and
`color.border.default`.
