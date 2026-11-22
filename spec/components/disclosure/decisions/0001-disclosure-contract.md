# 0001. The Disclosure contract: the collapse chevron on the system's disclosure group

Date: 2026-11-22. Status: proposed, for the coordinating agent's approval under the owner's delegation for phase 4
(decisions/0014, "Process"; decisions/0005, the first gate). There was no interview: the agent that wrote the draft
answered the questions of `/new-component` from the documents and the pilot, and each answer names its source. Where
they were silent, the answer is the agent's proposal; where a proposal changes the contract and has real
alternatives, it is an open question below, with options and a recommendation, and the contract is written to the
recommendation.

## Context

decisions/0014 puts Disclosure in the core of phase 4 (#120): "the collapse chevron, a style on the system
`DisclosureGroup`". Its pilot consumers are two compositions that stay the pilot's: a branch of the list tree on
`todo-app/lists-screen` (a list's row with lists inside it) and a block's header on `todo-app/list-screen` (a list's or
a group's block in the open list). ListRow (#119) is drafted at the same time; this contract states what it assumes of
it instead of defining rows ("Assumptions about ListRow").

What the pilot does, read at todo-app's commit `0162887`:

| | Tree branch (Lists screen) | Block header (List screen) |
|---|---|---|
| Where the chevron stands | At the row's right, after the count and before the grip in edit mode; a list with no lists inside keeps the chevron's cell empty, so the counts stand in one column; pinned to the right edge over a fade while the tree scrolls sideways (`TaskViewList+Components.swift`, `rowEnd`; `ListRowView.swift`, `End`) | At the header's right, after the title and its date (`BlockHeaderView.swift`) |
| What the rest of the header does | A tap on the row chooses the list (`rowSelected`) | A tap on the title opens the block as a screen (`blockTitleTapped`) |
| What the chevron does | Folds the branch (`disclosureTapped`) | Folds the block (`blockChevronTapped`) |
| How it looks | `chevron` (pointing down), 13 pt semibold on the phone, 12 on the Mac, in ink 2; in a cell at least 36 pt (phone) or 20 pt (Mac) wide | `chevron`, regular weight, in ink 2, centred in a square cell (`foldHitSide`) |
| How it turns | Down while open, a quarter turn (-90°, pointing right) while folded, on the popover's spring of 0.2 s | The same directions, on an ease of 0.22 s (`Animation.fold`) |
| What it reads aloud | "Expand" or "Collapse" | "Fold <title>" or "Unfold <title>"; the canvas carries the state in `aria-expanded`, which the pilot's model has no field for (the ruling on #175) |
| Hover (Mac) | The row's tint under the pointer | The title and the chevron's cell tinted apart |
| Reduce Motion | — | The chevron turns without its animation |
| Where the fold is kept | Per device, in the store (lists-screen.md, section 5) | Per device, per list (list-screen.md, section 2; ADR-0010) |

The Mac's sidebar spec says "the chevrons fold branches as disclosure triangles do" (lists-screen.md, section 8). A
column's header has no chevron, since columns do not fold. The Done strip's chevron, which turns half round, is not a
Disclosure: decisions/0014 makes the strip a secondary Button whose label holds the `chevron` Icon.

The pilot is right about behavior and roles; the look is westron's (decisions/0011–0013). Its numbers are compared,
not taken.

## Already decided by the documents

| What | Source |
|---|---|
| A system control beats westron's own; westron gives it a style, named by an unlabeled variant; no value is a system style's name | decisions/0003, spec/conventions.md |
| A chevron and a disclosure triangle are drawn in `color.icon.tertiary`, which needs 3:1 as a non-text glyph | design-language/07, "Drawing"; the token's usage note |
| An icon next to text takes that text's role, its size and weight; a smaller icon takes the platform's relative scale, never a size | design-language/07, "Size relative to text" |
| `motion.move` is "a section folding or unfolding"; a press tints and scales to 98 % in `motion.press`; a hover tint is `motion.fade` | design-language/05; `tokens/semantic/motion.tokens.json` |
| Reduce Motion: a spring loses its bounce, travel becomes a fade of at most 150 ms, scale changes are dropped, color fades stay | design-language/05, 08 |
| The hit area is at least `size.target.minimum`, 44 pt on iOS and 28 pt on macOS, also where the drawn control is smaller | design-language/08, "Hit targets" |
| Disabled is the control at `opacity.disabled`, announced as unavailable | design-language/08 |
| A system control keeps its own role and traits; decorative glyphs are hidden; states are announced | design-language/08, "Screen readers" |
| The focus ring is the platform's, except the text field's | design-language/08, "Keyboard and focus"; chapter 09 |
| A control under the pointer is tinted `color.background.hover`, pressed `color.background.pressed`, as Button's tertiary variant is | `spec/components/button/button.spec.yaml` |
| A press on a style whose configuration has no `isPressed` goes through a system Button in the body, represented to assistive technology by the system control | Checkbox's decisions/0001, P19; Chip's decisions/0001, "Revision after the audits", B |
| A hit area is a laid-out frame, so it never takes a neighbor's presses | Checkbox's decisions/0001, P17; Chip's decisions/0001, Q11 and C |
| Brand color stays in content; navigation and system lists keep the system's look | chapter 09 |

## What the system has

Read in the SwiftUI interface of Xcode 27.1 (`SwiftUI.swiftinterface`, macOS SDK, which carries every OS's
availability):

- `DisclosureGroup` is iOS 14 and macOS 11; `DisclosureGroupStyle`, `DisclosureGroupStyleConfiguration` and
  `View.disclosureGroupStyle(_:)` are iOS 16 and macOS 13. All of them are `@available(watchOS, unavailable)` and
  `@available(tvOS, unavailable)`.
- The configuration has `label`, `content` and `isExpanded`, a `Binding<Bool>` (`$isExpanded`); no `isPressed`.
- The only system style is `automatic` (`AutomaticDisclosureGroupStyle`). On iOS it draws the label and a trailing
  chevron, the whole header toggling; on macOS a leading disclosure triangle.
- `OutlineGroup` builds its subgroups as `DisclosureGroup<…, OutlineSubgroupChildren>`, so a style set above an
  `OutlineGroup` reaches them; `OutlineGroup` takes no binding for what is expanded. `List(_:children:)` builds an
  `OutlineGroup` inside a `List`, where the system draws a list's own disclosure indicator.

## The interview, answered from the sources

1. **Purpose.** A person folds a branch of the list tree and a block of the open list, to see less; the fold is kept
   per device. The chevron shows whether the group is open and is the control that folds it.
2. **System control.** `DisclosureGroup` with a `DisclosureGroupStyle` on iOS and macOS; none on watchOS. The web has
   ARIA's disclosure pattern on a native `<button>` (and `<details>`), GTK `GtkExpander` and `GtkTreeExpander`. So
   westron gives a style (P1).
3. **Options.** One variant, no size, no placement (P2, P3, Q3).
4. **States.** `expanded`, `hover`, `focus`, `pressed`, `disabled` (P8).
5. **Slots.** `label` and `content`, the configuration's own.
6. **Constraints.** None.
7. **Accessibility.** The system's disclosure, named by the label, valued expanded or collapsed (P13, Q4).
8. **Platform differences.** Hover with a pointer only; arrows on macOS; no watchOS (P14, P15).

## Proposed

| # | Proposal | Reason, and what else was considered |
|---|---|---|
| P1 | **Strategy `style-on-system-control` on `SwiftUI.DisclosureGroup`**, `.disclosureGroupStyle(.chevron)`. The style draws the header (the label, then the chevron's cell), the content's placement and its reveal; the label, the content, the expansion and its binding, the role and the focus ring stay the system's | decisions/0003. `DisclosureGroupStyle` is on westron's minimum iOS 17 and macOS 14 with no availability check. An own view (`Disclosure { … }`) would rebuild the binding, the role and OutlineGroup's use of it |
| P2 | **One variant, `chevron`** | The system's one style is `automatic`; `chevron` says what it draws, as Checkbox's `check` does, and shares no value with another contract on this modifier |
| P3 | **No variants for a tree branch and a block header** | In the pilot they differ in the label (a row with a tile and a count; a title with a date), the weight (semibold and regular, which follows the label's role here), the motion (two motions for one change, which westron makes one) and the words read aloud (which the role and the value replace, P13). The control is the same |
| P4 | **The glyph and its direction**: the registry's `chevron` (pointing down) while expanded; turned a quarter to point at the trailing side while collapsed, right in a left-to-right layout and left in a right-to-left one, so the turn is mirrored | The pilot's directions; the system's disclosure points the way of reading. One glyph turned, not `chevron` and `chevronLeft` swapped, so that the change is a turn |
| P5 | **Color `color.icon.tertiary`**, and the pair on `color.background.pressed` declared | The token's own use. It declared non-text contrast on the canvas, surface, sunken, hover and selected grounds; the pressed tint under the chevron (P7) was missing, so it is added to the token's `dev.westron.contrast` here: by the palette's rule step 8 meets 3 on every step 5, and `background.pressed` is step 5 (`tools/westron tokens contrast --all`: 3.01 light, 3.03 dark, 4.53 light-hc, 4.57 dark-hc). No new token |
| P6 | **Size and weight from the label's text role**, at the platform's small symbol scale, on the label's first text baseline | design-language/07; the pilot's 13 pt beside a 17 pt body is about the small scale. Sitting on the baseline keeps it on the title's line when the label wraps at large text sizes. No size option |
| P7 | **The cell**: a laid-out frame at least `size.target.minimum` high and across, the glyph centred; under the pointer a circle of `size.control.s` (`indicator.shape: capsule` on a square), growing with the glyph, in `background.hover`, pressed in `background.pressed`, the chevron scaling to 98 % | Button's tertiary tints; a press scales every control (design-language/05). The circle is the drawn control, the frame its hit area, as Chip's capsule and frame. Over a ListRow under the pointer the hover circle is the row's own tint and does not show; the pressed circle does |
| P8 | **States**: `expanded` (the configuration's value), `hover`, `focus`, `pressed`, `disabled`; collapsed is no state, as unchecked is none of Checkbox's | Checkbox's P4. Hover only with a pointer; `pressed`, `hover` and `focus` are the chevron's Button's |
| P9 | **Motion**: a toggle by the chevron or the keyboard runs in `motion.move`, one transaction for the chevron's turn, the content's reveal and what stands after the group; the content grows from the header's bottom edge and fades in; folding reverses it. The tint moves in `motion.fade`, the press in `motion.press` | `motion.move` is "a section folding". One motion keeps the chevron and the rows in step; `motion.toggle` (a small thing changing place) for the turn alone was considered, and would end before the rows settle. A change the product makes to the binding moves as its own transaction says, since the style cannot tell it from a change of data |
| P10 | **Reduce Motion**: the chevron points its new way at once, the content fades in or out, nothing slides, the press loses its scale | design-language/05: a turn is travel and a scale change, so it is dropped; the fade is `motion.move`'s reduced form (decisions/0013) |
| P11 | **The content**: directly under the header, flush with its leading edge, no indentation and no gap of the style's own; read only while expanded | A branch's children are indented by ListRow's nesting level, with its guides; a block's rows are not indented. An indentation in the style would add to the row's and break the guides |
| P12 | **Disabled**: the chevron and its cell at `opacity.disabled`, no hover or press, the expansion kept; the label and the content dim themselves where they are westron's | design-language/08. `.disabled` reaches every view in the group, so the style dims only what it draws |
| P13 | **Accessibility**: role `disclosure`, intents and keyboard intents `toggle`, a required label (the label's text), `expanded` announced; the chevron is one element, the label its own (Q4) | The system's disclosure role and value instead of the pilot's action words ("Expand", "Fold <title>"), as Checkbox took the toggle's role over the pilot's action button. ARIA's own disclosure is a button with `aria-expanded`; `disclosure` names the abstract role so each platform maps it to its own (`AXDisclosureTriangle` on macOS, a button with `aria-expanded` on the web) |
| P14 | **Keyboard on macOS**: with the chevron focused, Space toggles (the system button's activation), Right expands and Left collapses, mirrored right to left, as an outline's disclosure triangle | design-language/08, "every action is reachable from the keyboard"; the system's outline. iPad keyboards keep Space (the button) only: `onMoveCommand` is macOS's |
| P15 | **watchOS**: the component does not exist there | SwiftUI has no `DisclosureGroup` on watchOS. The pilot has no watch screen with a fold; #34 decides the watch's subset |
| P16 | **Web and GTK**: the web provisional, a native `<button>` with `aria-expanded` and `aria-controls`, not `<details>` (whose summary toggles on the whole header, against Q1); GTK planned, phase 7 choosing between `GtkExpander` and `GtkTreeExpander` | Button's and Checkbox's blocks |
| P17 | **The focus ring is the system's** on Apple, as Button's and Checkbox's | design-language/08 |

## Open questions

Each changes the contract; the draft is written to the recommendation, which comes first.

### Q1. What folds the group: the chevron only, or the whole header?

- **A. The chevron only (recommended).** The label is the product's and keeps its own action. Both pilot uses need
  this: a tap on a tree row chooses the list and a tap on a block's title opens the block; only the chevron folds.
  The macOS outline's triangle works this way.
- B. The whole header. What the system's automatic style does on iOS, `<details>` on the web and `GtkExpander` on
  GNOME. A label could then have no action of its own, and both pilot uses would lose theirs.
- C. A bool option, `labelToggles`, default false. Serves both, but no pilot use needs B (AGENTS.md, rule 6), and a
  style cannot tell whether a label already holds a button.

### Q2. Where the chevron's cell stands when the label is a ListRow

- **A. In the row's trailing place, inside the row (recommended).** After the label otherwise. The style hands its
  chevron to the label through the context, and ListRow's contract (#119) places it as the last item of its trailing
  slot, so the row's background, hover and selection run under it and it pins with the row's other accessories when
  the tree scrolls sideways (decisions/0014, open point 2). The pilot's selected row is highlighted under its
  chevron, and its counts and chevrons stand in columns. It ties the two contracts: ListRow must say it.
- B. Always after the label, outside it. No tie to ListRow, and a label of any kind gets the same header. A selected
  row's highlight and the sideways pin stop short of the chevron, and the pilot's grip, which follows the chevron in
  edit mode, comes before it.
- C. The product places the chevron itself, a westron view inside its label that reads the group's expansion. Free
  order and either edge; but a new public view a style contract does not derive, and a group whose label leaves it
  out has no control at all.

### Q3. A leading placement?

- **A. Trailing only, no option (recommended).** Both pilot uses put it at the end (AGENTS.md, rule 6); one look on
  every platform.
- B. An option `placement: [leading, trailing]`, default trailing, for a product that wants Finder's leading
  triangle.
- C. Per platform: leading on macOS, as the system's disclosure triangles are, trailing on iOS. The pilot's Mac
  draws it at the end, so it would not use it.

### Q4. One element for the chevron, or one for the whole header?

- **A. The chevron is its own element (recommended)**, the system's disclosure named by the label's text and valued
  expanded or collapsed; the label stays its own element with its own action. As the macOS outline's triangle is a
  child of its row. The label's text is read twice in a row (the label, then the disclosure's name); the
  accessibility audit of the implementation will show whether that needs a change.
- B. One element for the header: the label's action as its activation, expand and collapse as named accessibility
  actions, the value expanded or collapsed. One stop instead of two, but the disclosure's role is lost to the label's
  and the style would have to combine a label it does not own.

### Q5. A `List` and `OutlineGroup`

- **A. The style is for groups outside a `List`; inside one the contract promises nothing (recommended).** The pilot's
  tree is recursive `DisclosureGroup(isExpanded:)` in a lazy stack inside its scroll view, which it already is for
  sideways scrolling (decisions/0014, open points 2 and 3). `OutlineGroup` works outside a `List` but takes no
  binding, and the pilot keeps its folds per device, so it binds each group. The implementation measures what a
  `List` does with the style on iOS and macOS and records it in `platforms`.
- B. Promise westron's look in a `List` too. The macOS list draws rows as an outline with its own triangles, which a
  style may not reach; a promise the system can break is a parity bug waiting.

## Assumptions about ListRow (#119)

Not defined here; to be checked against ListRow's contract when both are reviewed:

1. ListRow is a row with a leading slot, a title, a second line, a trailing slot and a nesting level with guides; it
   draws its own background in its hover, pressed and selected states, and its own tap is the row's action.
2. Under Q2-A, ListRow, when it is the label of a westron disclosure, ends its trailing slot with the disclosure's
   chevron cell, inside its background; a row with no lists inside it keeps the place empty, at
   `size.target.minimum` across, where the product wants columns aligned (the pilot's leaf rows).
3. A row's indentation, its guides and its height are ListRow's; Disclosure indents nothing.
4. The sideways pin of the trailing slot (decisions/0014, open point 2) is ListRow's; under Q2-A the chevron pins with
   it.
5. The chevron's laid-out cell and the row's own press do not overlap: a press on the chevron folds, a press beside it
   is the row's.

## How the pilot composes it

Sketches only; ListRow's API is a placeholder until #119 settles it.

A branch of the tree, recursive, one `DisclosureGroup` per list with lists inside:

```swift
struct Branch: View {
    let node: TreeNode
    @Binding var folded: Set<ViewID>  // the device's folds, from the store

    var body: some View {
        if node.children.isEmpty {
            row
        } else {
            DisclosureGroup(isExpanded: expanded) {
                ForEach(node.children) { Branch(node: $0, folded: $folded) }
            } label: {
                row  // the chevron takes the row's last trailing place (Q2-A)
            }
            .disclosureGroupStyle(.chevron)
        }
    }

    private var row: some View {
        ListRow(level: node.depth, action: { select(node) }) {  // placeholder for #119
            IconTile(node.icon)
        } title: {
            Text(node.title)
        } trailing: {
            Text(node.count).textRole(.footnote.regular)
        }
    }

    private var expanded: Binding<Bool> {
        Binding(get: { !folded.contains(node.id) }, set: { folded.toggle(node.id, off: $0) })
    }
}
```

A block's header, the title opening the block and the chevron folding it:

```swift
DisclosureGroup(isExpanded: $isOpen) {
    ForEach(block.tasks) { TaskRow($0) }
    AddTaskRow(block)
} label: {
    Button { open(block) } label: {
        HStack(alignment: .firstTextBaseline) {
            Text(block.title).textRole(.heading.small).foregroundStyle(block.color)
            Text(block.date).textRole(.footnote.regular)
        }
    }
    .buttonStyle(...)  // the pilot's choice of a westron Button or ListRow
}
.disclosureGroupStyle(.chevron)
```

The Rule under the pilot's header is the pilot's: drawn in the label it ends before the chevron's cell under Q2-A and
B; drawn across the whole group's width it is a Rule above the group's content, shown while the group is open. A
column's header is the same label with no `DisclosureGroup` around it.

## The snapshot matrix

Generated once the contract is approved and the Apple entry is a strategy: 1 variant × 6 states (rest, which is
collapsed, and each state alone) on one sheet; its cell is a group with a one-line text label and two lines of
content. Supplements, hand-written, "not a contract option": expanded and pressed, expanded and disabled; a right to
left layout, collapsed and expanded; a three-level tree of ListRows, once ListRow exists; a label that wraps at
`accessibility5`, the chevron on its first line.

## The Apple entry, once the tools know the base

`platforms.apple` is `status: planned` in the draft only because `spec check` rejects an unknown base. With
`SwiftUI.DisclosureGroup` in `SystemStyles.byBase` it becomes the entry below, whose description is the planned
entry's text; the rest of the contract already passes with it (checked with the base replaced by one the tools know,
2026-11-22):

```yaml
  apple:
    strategy: style-on-system-control
    base: SwiftUI.DisclosureGroup
    description: >-
      (the planned entry's description, less its first sentence)
    ios:
      description: >-
        Hover only with a pointer, on iPad. The chevron's cell is at least 44 pt high and across.
    macos:
      keyboardIntents: [expand, collapse]
      description: >-
        The cell is at least 28 pt. With the chevron focused, Space toggles it and the Right and Left arrows expand
        and collapse it, mirrored right to left (onMoveCommand).
    watchos:
      description: >-
        SwiftUI has no DisclosureGroup or DisclosureGroupStyle on watchOS, so the component does not exist there.
```

## What the tools need

Found while drafting; not changed here.

1. **The base.** `SystemStyles.byBase` has no `SwiftUI.DisclosureGroup`, so `spec check` reports "the validator does
   not know the system styles of SwiftUI.DisclosureGroup" on a style on it. Its entry: modifier
   `disclosureGroupStyle`, protocol `DisclosureGroupStyle`, styles `["automatic"]` (the only static style in Xcode
   27.1's interface), states `expanded` (`configuration.isExpanded`) and `pressed`, `hover`, `focus`, `disabled`, which
   the style follows through its Button, as the Toggle's entry lists `pressed`.
2. **A component one Apple OS does not have.** An Apple OS can restrict options and states but cannot say the
   component is absent. `disclosureGroupStyle(_:)` and `DisclosureGroupStyle` are unavailable on watchOS, so the
   generated overload, `DisclosureState`, the matrix and the catalog entry must be behind `#if !os(watchOS)` (or
   `@available(watchOS, unavailable)`), or `tools/apple/check.sh platforms` fails to build for watchOS. The schema
   needs a way to say it, such as `watchos: { status: unavailable }`, and the generator and the API parity lint to
   follow it.
3. **The role `disclosure`** is a new abstract role; spec/conventions.md maps roles by example only. A row for it
   (Apple: the system's; web: a `button` with `aria-expanded`; GTK and Compose with their phases) would record it.
4. **A tie between two contracts** (Q2-A: ListRow keeps the chevron's place) has no field; both descriptions carry
   it.
5. **A binding by layout direction** (the turn mirrored right to left) has no key; the description carries it.

## Pilot files read

At todo-app's `0162887`: `Sources/DesignSystemComponents/` `ChevronStyle.swift`, `AccessoryModel.swift`,
`IndentStyle.swift`, `ListRowModel.swift`, `ListRowStyle.swift`, `BlockHeaderModel.swift`, `BlockHeaderStyle.swift`;
`Sources/DesignSystem/Animation.swift`; `Sources/Features/TaskViewList/TaskViewList+Components.swift`;
`Sources/Features/TaskList/TaskList+Components.swift`, `TaskList+Controls.swift`;
`Apps/Apple/Sources/TodoAppleUI/DesignSystem/ListRowView.swift`, `ListScreen/BlockHeaderView.swift`,
`ListsScreen/ListsTree.swift`; `docs/specs/lists-screen.md` and `docs/specs/list-screen.md`, where they speak of the
chevron and of folding.
