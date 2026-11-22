# 0001. The ListRow contract: the core row, its level and its guides

Date: 2026-11-22. Status: proposed. A draft for the first gate (decisions/0005), whose approval the owner delegated to
the coordinating agent for phase 4 (decisions/0014, "Process"). There was no interview: the agent that wrote the draft
answered the eight questions of `/new-component` from the sources, and each answer names its source. Where the sources
are silent the answer is the agent's proposal; where a proposal changes the contract's shape it is an open question
below, with the recommendation first, and the draft is written to the recommendation.

## Context

decisions/0014 puts ListRow in the core of phase 4 (#119): "a leading slot, a title, a second line, a trailing slot;
hover, pressed and selected; a nesting level with guide lines", and leaves it three open points: how drag and drop
looks (1), a tree wider than the screen (2) and swipe outside a List (3). decisions/0013 left the nesting guides to a
phase 4 component ("Left for later"). The pilot composes five rows from it, on `todo-app/lists-screen` and
`todo-app/list-screen`.

The pilot was read at todo-app's commit `0162887`:

| File | What it says about rows |
|---|---|
| `Sources/DesignSystemComponents/ListRowModel.swift`, `ListRowStyle.swift`, `AccessoryModel.swift`, `ChevronStyle.swift`, `IndentStyle.swift` | A list's row: tile, title or rename field, accessories at the right (count text, chevron, grip, check, space, hidden), a tap and a menu; height, leading by depth, background inset and corners, guides under each ancestor's tile centre, a fade under the accessories, a row's `need` that makes the tree scroll sideways |
| `TaskRowModel.swift`, `TaskRowStyle.swift`, `MetaItemModel.swift` | A task's row: check, title (struck when done), meta line under the title on the phone and after it on the Mac, at least 44 / 36 high, a hover tint on the Mac, lift, fresh tint, swipe, menu |
| `SubtaskRowModel.swift`, `SubtaskRowStyle.swift` | A check and a title, 44 / 30 high |
| `AddRowModel.swift`, `AddRowStyle.swift` | A plus in a cell and a title, the whole row a button, a rule above or a dashed edge where it has one, a hover tint on the Mac |
| `HoverStyle.swift` | The tint under the pointer, its corners and motion; none on the phone |
| `Sources/Features/TaskViewList/TaskViewList+Components.swift` | The numbers: the phone's rows 46 high, indent 20 + 22 per level, guides 1.5 pt; the sidebar's rows 30 high, indent 18 + 16 per level, guides 1 pt, selection inset 10 and rounded 7; the picker's rows with no guides, the moved list's subtree dimmed to 0.35, the present parent checked; the drag's slot (dashed, 52 high) and the Mac's indicator (a 2 pt line and a ring) |
| `Sources/Features/TaskList/TaskList+Metrics.swift`, `TaskList+PaneMetrics.swift` | The task row's paddings (11 / 9), minimum heights (44 / 36), check hit areas (42–44 × 44, 34 × 36) |
| `Apps/Apple/Sources/TodoAppleUI/DesignSystem/ListRowView.swift`, `Accessories.swift`, `DropIndicator.swift` | How the row and its end are laid out; the chevron is a `Button` labelled "Expand" / "Collapse", the grip and the check hidden from VoiceOver |
| `Apps/Apple/Sources/TodoAppleUI/ListsScreen/ListsTree.swift` | The tree is a `ScrollView` over both axes, not a `List` ("moves a row up and down a flat list and knows nothing of depth", spike #145); a tap gesture on the row, `.contextMenu`, a drag of its own; the accessories pinned at the screen's right over a fade while the rows scroll sideways |
| `ListsScreen/MovePickerSheet.swift`, `ListsSidebar.swift` | The picker's rows are `Button`s in `.plain` style in a `LazyVStack`, `.isSelected` on the checked one, `.disabled` and dimmed where it cannot be chosen |
| `ListScreen/TaskRowView.swift`, `AddRowView.swift`, `Hovering.swift`, `BlockView.swift` | The check is a sibling of the row's `Button`, not inside it; the rows stand in `LazyVStack`s, not a `List` |
| `ListScreen/SwipeToDelete.swift`, `RowSwipe.swift` | The pilot's own swipe, with a named accessibility action for Delete |
| `docs/specs/lists-screen.md` (sections 1, 5–8, "Risks"), `docs/specs/list-screen.md` (sections 1–7, 10, 11) | Behavior: tap opens, long press opens the menu, edit mode's grips and drag with depth, the Mac's drag at any time, the sideways tree and its fallback ("a title that truncates at depth"), swipe to delete, the drop marks |

The pilot is right about behavior and roles; the look is westron's (decisions/0011–0013). Its numbers are compared
below, not taken. No pilot row stands in a SwiftUI `List`.

## Already decided by the documents

| What | Source |
|---|---|
| A system control beats westron's own; where none exists, westron builds its own, named as in the contract | decisions/0003 |
| What the system presents stays the system's: menus, swipe actions, sheets; westron styles what is inside them | decisions/0014, "What stays the system's"; spec/conventions.md |
| The pilot's rows are its compositions on ListRow, not westron components | decisions/0014, "The pilot's families, mapped" |
| `color.background.hover`, `pressed`: a row under the pointer, pressed; `background.selected`: a selected row | design-language/02:19–20, 02:41; the tokens' descriptions |
| `radius.row`: the highlight of a row under the pointer or selected | design-language/04:22 |
| `stroke.thin`: tree guides in a sidebar; `stroke.regular`: guides on a phone; `stroke.thick`: a drop indicator and a selection ring | design-language/04:54–58 |
| A selected row is not shown by color alone: in high contrast it also shows a check or a `border.focus` outline | `color.background.selected`'s usage note, `tokens/semantic/color.tokens.json` |
| `typography.body.regular` is a row's title, `body.strong` the selected row and a row with children, `callout.regular` a nested row's title, `footnote.regular` a line under a title | the typography tokens' descriptions |
| `color.icon.tertiary` is a chevron and a grip | design-language/02:24–26 |
| A row's height is a minimum and grows with its text; rows on touch platforms keep the recommended target | design-language/06:56–58, 06:74, 09:86 |
| An indent per level of a tree is an off-ladder value that belongs to the component; it does not become a new step | design-language/06:23–25 |
| Spacing that belongs to text scales with it; a row that runs out of width stacks its parts | design-language/08:66–67 |
| `motion.fade` is a hover tint and a selection, `motion.press` a press, `motion.move` a reordered row; Reduce Motion keeps fades | design-language/05 |
| A system control keeps its own role and traits; decorative graphics are hidden; selected and unavailable are announced | design-language/08:105–110 |
| Every gesture has another way: a swipe and a drag are also a named action or a menu item | design-language/08:111–113 |
| The insertion point of a reorderable list is `Rule(purpose: insertion)` | spec/components/rule (#116, on its branch) |
| The carried copy of a drag is a dragged Surface | decisions/0014; spec/components/surface |
| westron's margins apply to layout the product builds; the system's `List` keeps its own insets | design-language/06:46–49 |

## The interview, answered from the sources

1. **Purpose.** A person opens a list or a task by its row, sees what is in it (a count, a tag, a due date), checks a
   task done at its start, folds a branch at its end, picks a destination in "Move to…", and drags a row to another
   place or level (above, "Context").
2. **System control.** On Apple a row is the content of a `List`; outside a `List` there is no system row. The pilot's
   rows all stand outside one, in stacks and a sheet. So ListRow is westron's own view (Q1), and in a `List` it is the
   row's content while the `List` keeps its behaviors (Q2). GTK has `AdwActionRow`, Android Material3's `ListItem`.
3. **Options.** `guides`, a Bool. The level is an integer, which the schema cannot type (gaps, 1). No variant and no
   size: the compact density's row sizes come with #33.
4. **States.** hover, focus, pressed (from the row's action, a system Button), selected, disabled, dropTarget.
   watchOS enters pressed, selected and disabled; an iPhone never hovers.
5. **Slots.** `leading`, `title`, `subtitle`, `trailing`.
6. **Constraints.** None between options. A row without an action enters no hover, focus or pressed, which a form of
   the contract would say (gaps, 2).
7. **Accessibility.** A row with an action is a button named by its words; a row without one adds no role; controls in
   slots stay their own elements; selected and disabled announced; the level as more content (Q8).
8. **Platform differences.** Hover with a pointer only; guides `stroke.regular` on a phone; macOS's smaller target;
   watchOS not designed in this phase (#34).

## Proposed

| # | Proposal | Reason |
|---|---|---|
| P1 | **An own view, `ListRow`**, with the slots as `@ViewBuilder` closures, `level: Int = 0`, `guides: Bool = true`, an optional `action` | Q1 |
| P2 | **The row's action is a system Button inside the row, beside the slots' controls, not around them.** A press anywhere on the row that is not on a control in a slot is the action; the whole frame is the hit area | The pilot keeps the check a sibling of the row's Button (`TaskRowView.swift`); a control inside a Button's label is merged into the button's element and loses its own role |
| P3 | **Only a row with an action enters hover, focus and pressed**; `selected`, `disabled`, `dropTarget` on any row | A highlight that answers the pointer promises an action; the subtask row has none |
| P4 | **`.selected(_:)` and `.dropTarget(_:)`**, shared state modifiers through the environment, Bools, named as the states | spec/conventions.md, "States the system control lacks"; the selection and the drag are the product's knowledge (the pilot's module holds both) |
| P5 | **At rest no background**; hover `background.hover`, pressed `background.pressed`, selected `background.selected`, dropTarget `background.accent-subtle` with a `border.focus` ring at `stroke.thick`; pressed wins over selected, selected over hover; a disabled row never tints and is drawn whole at `opacity.disabled` | The documents' tints; the order of the bindings' cases |
| P6 | **Selected sets the title in `body.strong`** where the product set no other role, and **in high contrast draws a `border.focus` ring at `stroke.thick`** | The usage note of `background.selected`; `body.strong`'s description. The pilot's sidebar emphasizes the highlighted title too. The tint is the palette's step 5, solved to stand 1.16:1 off the canvas in light and 1.36:1 in dark (decisions/0012), so weight is the second signal in the standard themes, the ring in high contrast |
| P7 | **Sizes**: at least `size.target.minimum`; text padded `space.75` vertically and `space.150` horizontally; `space.150` from the leading slot to the title, `space.100` from the title to the trailing slot, `space.25` from the title to the second line; corners `radius.row` | Below, "Sizes"; every value an existing token |
| P8 | **The slots stand on the title's first line**, centred on it, by the first text baseline that IconTile and the check give at their centre | IconTile's contract (a row aligned on the first text baseline); the pilot aligns its check with the title's top |
| P9 | **No line limit of the row's own**; a product sets one line where it wants it, the title truncated at its end and whole to assistive technology | The pilot's list rows are one line, its task rows wrap on the phone; one rule serves both |
| P10 | **At accessibility sizes the trailing slot moves under the text**, from the title's leading edge | design-language/08:67 |
| P11 | **The indent is `container.indent` per level, scaled with the text** (Q5) | design-language/06:23–25, 08:67 |
| P12 | **Guides**: one per ancestor level, centred under where that level's leading slot is centred (as wide as the row's own), the row's full height, `color.border.guide` (new, below) at `stroke.thin`, `stroke.regular` in the compact size class; hidden from assistive technology | The pilot draws them so (`childGuides`); design-language/04 gives the widths; Q7 the color |
| P13 | **No separator of the row's own**: a product adds a Rule | Rule is the separator; the pilot's rows have none between them |
| P14 | **The tree wider than its container truncates** (Q3) | 0014's open point 2 |
| P15 | **Drag and drop** (Q4): the insertion mark is Rule's, drawn by the row over its edge at a level; dropTarget for a drop onto the row; no dashed slot; the carried copy a ListRow on `.surface(.dragged)`; nothing announced | 0014's open point 1 |
| P16 | **Swipe is out of scope** (below, "Swipe") | 0014's open point 3 |
| P17 | **A press tints and does not scale** (Q6) | |
| P18 | **The level to assistive technology as more content** (Q8) | |
| P19 | **Right to left mirrors** the slots, the indent and the guides | The platform's leading and trailing |
| P20 | **watchOS** enters pressed, selected, disabled; drawn as on iOS; not designed until #34 | Chip's and Checkbox's blocks |
| P21 | **Web, GTK, Android planned**, with their directions: a native button inside a westron element with `tree`/`treeitem` and `aria-level`; `AdwActionRow`; Material3 `ListItem` | Other contracts' provisional blocks |

### Sizes

Computed from the tokens at the default text size (iOS body 17 pt on a 22 pt line, footnote on 18; macOS body 13 on
16, footnote on 13; IconTile 1.5 lines; the check's hit area the larger of `size.target.minimum` and `size.control.m`),
against the pilot's:

| Row | iOS | pilot phone | macOS | pilot Mac |
|---|---|---|---|---|
| Title only | 44 | — | 28 | — |
| IconTile and title (a list's row, a picker's) | 45 | 46 | 28 | 30 |
| Check and title (a subtask, a task without meta) | 44 | 44 | 32 | 30 / 36 |
| Check, title and a second line (a task with meta) | about 57 | about 61 | about 45 | about 50 |
| Indent per level | 24, scaled | 22 | 24, scaled | 16 |

The Mac's indent is the one number well off the pilot's: Q5.

## The pilot's rows, composed

Sketches, not compiled; the API is the draft's (P1, P4, Q4). `Disclosure` is #120's.

**A list's row in the tree** (`ListRowModel`, `ListsTree`):

```swift
ListRow(level: row.depth, action: { send(row.tap) }) {
    IconTile(list.icon)
} title: {
    if let draft = row.draft {
        TextField("Title", text: draftBinding).textFieldStyle(.framed)   // the rename field in the title's place
    } else {
        Text(list.title).lineLimit(1)
            .textRole(row.hasChildren ? .body.strong : .body.regular)   // the pilot's emphasis, the product's
    }
} trailing: {
    if !isEditing, let count { Text(count).textRole(.subheadline.regular).foregroundStyle(.text.secondary) }
    if list.hasChildren { Disclosure(isExpanded: expandedBinding) }        // #120, its own button
    if isEditing { Icon(.grip) }                                           // decorative; the drag is the tree's
}
.selected(row.isHighlighted)
.insertionMark(drag.edge(for: row), level: drag.level)                     // Q4
.dropTarget(drag.isInto(row))
.category(Westron.Category(rawValue: list.color))
.contextMenu { MenuItems(menu, send: send) }                               // the system's
```

The pilot's sideways scroll and the fade under the accessories go (Q3). The count and chevron columns hold by the
trailing slot's content: the pilot's empty `space` cells become a fixed-width frame the product gives the count.

**A task's row** (`TaskRowModel`, `TaskRowView`):

```swift
ListRow(action: { send(.rowTapped(task.id)) }) {
    Toggle(isOn: doneBinding, accessibilityLabel: task.title).toggleStyle(.check)   // its own element
} title: {
    Text(task.title).strikethrough(task.isDone, color: …)                            // the pilot's look of done
} subtitle: {
    WrappingRow { ForEach(task.meta) { MetaItem($0) } }   // the pilot's: Icon + Text; the Mac's tag .labelStyle(.chip)
}
.category(Westron.Category(rawValue: list.color))
.contextMenu { … }
```

On the Mac, where the pilot puts the meta after the title on its line, the meta goes in `trailing` and the title takes
`.lineLimit(1)`. The lift, the fresh tint, the leaving motion and the swipe stay the pilot's (decisions/0014).

**A subtask's row** (`SubtaskRowModel`): `ListRow { Toggle(isOn:accessibilityLabel:).toggleStyle(.check) } title: {
Text(subtask.title) }`, with no action: the check is its only control.

**An add row** (`AddRowModel`): `ListRow(action: addTask) { Icon(.plus) } title: { Text("Add task")
.textRole(.subheadline.medium) }`, with a `Rule()` above it in the product's stack where it has one. The board's
dashed "+ Add list" column is not a row and stays open (decisions/0014, open point 1).

**A row of "Move to…"** (`PickerModel`, `MovePickerSheet`):

```swift
ListRow(level: option.depth, guides: false, action: { send(option.tap) }) {
    IconTile(list.icon)
} title: {
    Text(list.title)
} trailing: {
    Icon(.check).opacity(option.isChecked ? 1 : 0)   // the column holds; decorative, the state is .selected's
}
.selected(option.isChecked)
.disabled(option.isDisabled)                          // opacity.disabled, where the pilot had 0.35
```

An area among the options is a labelled Rule in a row's frame (decisions/0014). "Top level" is a ListRow with a neutral
IconTile.

**The carried copy of a drag**: `ListRow { IconTile(list.icon) } title: { Text(list.title) } trailing: { Icon(.grip) }
.surface(.dragged)`.

## Swipe

Out of this contract. Swipe actions are the system's (decisions/0014, "What stays the system's"): `.swipeActions`
acts on a row of a `List`, and on the rows of a `ScrollView` or `LazyVStack` only with `swipeActionsContainer()`, from
OS 27. A ListRow in a `List` takes `.swipeActions` as any row does (Q2), and the button it uncovers is a system
`Button` with the destructive role. Outside a `List` before OS 27 the pilot keeps its own gesture, with its named
accessibility action. ListRow adds no swipe state and no offset: a row that slides is the gesture's, and a westron state
for it would be a second implementation of the system's swipe.

## Tokens

- **New: `color.border.guide`**, aliasing `{color.neutral.7}`, the palette's step whose job is "guides"
  (decisions/0012), which no semantic token named. Kind `separator`: decorative in the standard themes, 3:1 in high
  contrast, declared on canvas, surface, sunken, hover, pressed, selected and accent-subtle. Why not
  `color.border.default`: declared on the row's highlights, it fails in high contrast, 2.92, 2.74, 2.74 and 2.91 in
  light-hc and 2.92, 2.54, 2.53 and 2.92 in dark-hc on hover, pressed, selected and accent-subtle; the guide passes,
  4.41, 4.14, 4.15, 4.40 and 4.40, 3.82, 3.81, 4.40. In the standard themes the guide stands 1.32–1.90:1 off the
  grounds, a little firmer than a separator's 1.07–1.53. Q7.
- **New contrast declarations**: `color.icon.tertiary` (a chevron or a grip in the trailing slot) and
  `color.border.focus` (the drop and the high-contrast selection ring) on `pressed` and `accent-subtle`;
  `color.border.strong` (a Checkbox's and a Chip's high-contrast edge in a slot) on `hover`, `pressed` and `selected`.
  `text.primary` and `text.secondary` were declared on every row ground already.
- `tools/westron tokens contrast`: 333 pairs in each of the four themes, none failed.
- `tools/westron generate` writes the token into `WestronTokens/Generated/Tokens.swift` and
  `WestronUI/Tokens.xcassets/color.border.guide.colorset`, and the new declarations into `Tokens.swift`'s background
  lists; nothing else, since the draft contract generates nothing.
- The drop ring binds `color.border.focus` because `color.border.insertion`, Rule's insertion color, is on #116's
  branch and not on `main`; when #116 merges, the drop ring takes `color.border.insertion`, so the line and the ring
  between and onto rows are one color that can change apart from focus.

## The snapshot matrix

When approved, with the tools able to generate an own view with slots and states (gaps, 3): one sample row, an
IconTile, a title, a second line and a trailing count at level 1, in each state alone and at rest (seven cells),
across `guides` on and off: fourteen cells per theme, in the four themes, and in light at xSmall and accessibility5.

Hand-written supplements, marked "not a contract option":

1. A tree of levels 0 to 3 with guides, one row selected among them, in the four themes.
2. The slots: title alone; leading and title; title and second line; all four.
3. A task's row: a Checkbox at the start, a title over two lines, the meta line under it.
4. A long title on one line, truncated at level 4 in a narrow width.
5. Accessibility5: the trailing slot under the text.
6. The insertion mark at the top and the bottom edge at levels 0 and 2; dropTarget.
7. selected with pressed, selected with disabled, in the high-contrast themes (the ring).
8. Right to left.

## What the tools cannot express yet

Nothing in the tools was changed. Each gap is described in the contract's text instead.

1. **An integer option.** `level` is an `Int`; the schema's option types are enum, bool, tokens and icons.
2. **Forms.** A row with an action is a button, one without adds no role; the main schema has one `accessibility`
   block. Chip's branch adds `forms`, with per-form states and accessibility: ListRow should take two forms there,
   `action` (all six states, role button) and `static` (selected, disabled, dropTarget; role none).
3. **Generation and the API parity lint of an own view with slots and states** (spec/conventions.md, "Not derived
   yet"): slots of a view other than an icon's label (the conventions' open question 2), states on an own component
   (hover, focus, pressed and disabled from a system Button inside it; selected and dropTarget from shared state
   modifiers), and a restriction of an Apple OS on an own component (watchOS's states).
4. **Modifiers outside the vocabulary.** `.insertionMark(_:level:)` takes an edge and a level, which no option,
   state or slot can carry; it would be a reviewed adapter of the lint, as `.category(_:)` is.
5. **A binding by size class or platform.** The guide is `stroke.thin` in a sidebar and `stroke.regular` on a phone;
   a binding takes one token or one per enum value. A platform token would carry it per platform, not per size class.
6. **A case by contrast.** The high-contrast selection ring, as Button's high-contrast outline, is in the
   description.
7. **Cases over several states.** "A disabled row never tints" and "pressed over selected" are by order and prose;
   Chip's branch adds `state: { all: [...] }`, which would let a case say `disabled` with `hover`.
8. **A scaled metric.** That the indent scales with the text is in the description.

## Open questions

Each changes the contract; the recommendation is first, and the draft follows it.

- **Q1. What ListRow is on Apple.**
  (a) **Westron's own view**: the row's slots, level and guides, its action a system Button inside it beside the
  slots' controls, `selected` and `dropTarget` as shared state modifiers. Outside a `List` there is no system row
  (decisions/0003, point 2), and a control in a slot keeps its own press and element. Recommended.
  (b) A style on `SwiftUI.Button`, `.buttonStyle(.row)`, the row's content its label: closest to "a style on a
  system control", but a Checkbox or a Disclosure in the label is merged into the button's element and loses its role,
  a `List` row swallows nested buttons' taps, and the level and guides would still need a view. The pilot already
  keeps its check outside the row's Button for this reason.
  (c) Modifiers for a `List` row only (`listRowBackground`, insets, separators): no row outside a `List`, where every
  pilot row stands (spike #145: a `List` knows no depth in a drag).

- **Q2. ListRow in a SwiftUI `List`.**
  (a) **It works there too, the `List` keeping its behaviors and ListRow its look**: the product sets
  `.listRowInsets(EdgeInsets())`, `.listRowBackground(Color.clear)` and `.listRowSeparator(.hidden)`, and does not
  bind the `List`'s selection, whose own highlight would draw a second one; the `List` keeps `.swipeActions` (the
  way to swipe before OS 27), `.contextMenu`, `onMove`, `.dropDestination` and its keyboard navigation. It sets aside
  design-language/06's "the system's List keeps its own insets" for rows that ListRow draws, and the decision says
  so. Recommended: one look in and out of a `List`, and the `List`'s behaviors where a product wants them.
  (b) In a `List` the `List`'s look stays: ListRow draws no highlight there and the `List` draws its selection,
  separators and insets. The row looks different in and out of a `List`, and its own padding doubles the `List`'s
  insets.
  (c) ListRow only outside a `List`; in a `List`, the system's rows with westron's content components.

- **Q3. A tree wider than its container** (0014, open point 2).
  (a) **The title truncates**: the row never scrolls sideways; the indent and the slots keep their size, and the
  title takes what is left, on one line where the product sets it, whole to assistive technology. The pilot spec's
  own fallback ("Risks"), what a system sidebar does, and it keeps ListRow a row, not a container. Recommended.
  (b) The pilot's: the tree scrolls sideways while the trailing slot stays pinned at the visible edge over a fade of
  the row's background. It needs a tree container that knows its scroll offset, which westron does not have, and a
  fade token.
  (c) The indent stops growing past a depth, so deep levels share one indent and the guides stop multiplying.

- **Q4. The looks of drag and drop** (0014, open point 1).
  (a) **Between rows, the row draws `Rule(purpose: insertion)` over its top or bottom edge, at the level the drop
  would take, when the product marks that edge (`.insertionMark(_:level:)`); no gap opens. Onto a row,
  `dropTarget`: `accent-subtle` with a `stroke.thick` ring. No dashed slot on any platform, so no dash token. The row
  a drag was lifted from stays as the system's drag leaves it, so no `opacity.*` token for it. The carried copy is a
  ListRow on `.surface(.dragged)`. Nothing announced: the drag's other way is the product's menu item or action.**
  The level's geometry stays inside the row at every text size. Recommended.
  (b) The product places a Rule in a gap that opens between rows (`motion.move`), at an x it computes from the row's
  padding and indent: the Mac pilot's look, but the product repeats the row's scaled geometry.
  (c) The phone keeps a dashed slot: a `placeholder` state with a dash token, and an `opacity.lifted` token for the
  row left behind.

- **Q5. The indent per level.**
  (a) **`space.300`, 24, scaled with the title's text style, on every platform**: an existing step, no new token
  (design-language/06: an indent "does not become a new step"); a child's leading slot stays clear of its parent's
  guide at every text size, since both scale. On the Mac it is 8 pt wider per level than the pilot's 16.
  Recommended.
  (b) A platform token, `size.indent`, 24 on iOS and 16 on macOS and watchOS: the pilot's Mac, a new token and
  generated code.
  (c) Derived: half the row's leading slot plus `space.100`, so the gap between a guide and a child's slot is constant;
  no token, but a row without a leading slot, or rows of one tree with slots of different widths, misalign.

- **Q6. A press scales the row?**
  (a) **No: a press tints the row, and does not scale it.** design-language/05 fixes a 98 % scale "for every
  control"; a row is as wide as its list, and its scaled edges would move against the rows above and below it, which
  the pilot does not do. The deviation is the contract's. Recommended.
  (b) Yes, as every control: 98 % in `motion.press`, dropped by Reduce Motion.

- **Q7. The guides' color.**
  (a) **A new token, `color.border.guide`, on the palette's guides step** (above, "Tokens"). Recommended: added in
  this branch, with its generated files.
  (b) `color.border.default`, the separators' color, with its high-contrast failures on the row's highlights
  (2.53–2.92) recorded as a deviation, and no new token.

- **Q8. The level to assistive technology.**
  (a) **As more content**: from level 1 on, "Level" and the level counted from 1, which VoiceOver gives when a person
  asks for more content (`accessibilityCustomContent`, default importance), and not on every row. WCAG 1.3.1 asks
  that nesting shown by an indent be determinable; this keeps it there without lengthening every row. Recommended.
  (b) In the row's value, spoken on every nested row: "Inbox, level 2, button".
  (c) Not announced: the order and the Disclosure's expanded state carry the tree.
