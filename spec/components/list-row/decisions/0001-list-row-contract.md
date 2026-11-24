# 0001. The ListRow contract: the core row, its level and its guides

Date: 2026-11-22. Status: approved on 2026-11-22 by the coordinating agent under the owner's delegation for phase 4
(decisions/0014, "Process"), with the answers and changes below ("Approval"); implemented on Apple, measured below
("Measured"), and revised after the review ("Revision of Q1 at implementation", "Revision after the review"). It was
a draft for the first gate (decisions/0005). There was no interview: the agent that wrote the draft
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
| P2 | **The row's action is a system Button whose label is the whole row; the slots' controls are nested in it and take their own press**, and to assistive technology the row is an accessibility representation in which each control keeps its own element (revised at implementation: "Revision of Q1 at implementation"; the draft said "beside the slots' controls, not around them"). A press anywhere on the row that is not on a control in a slot is the action; the whole frame is the hit area | The pilot keeps the check a sibling of the row's Button (`TaskRowView.swift`), since a control inside a Button's label is merged into the button's element and loses its own role; the representation gives the control its element back, measured |
| P3 | **Only a row with an action enters hover, focus and pressed**; `selected`, `disabled`, `dropTarget` on any row | A highlight that answers the pointer promises an action; the subtask row has none |
| P4 | **`.selected(_:)` and `.dropTarget(_:)`**, shared state modifiers through the environment, Bools, named as the states | spec/conventions.md, "States the system control lacks"; the selection and the drag are the product's knowledge (the pilot's module holds both) |
| P5 | **At rest no background**; hover `background.hover`, pressed `background.pressed`, selected `background.selected`, dropTarget `background.accent-subtle` with a `border.insertion` ring at `stroke.thick`, drawn over the content (revised: Q4, D4); pressed wins over selected, selected over hover; a disabled row never tints and is drawn whole at `opacity.disabled` | The documents' tints; the order of the bindings' cases |
| P6 | **Selected draws a `border.focus` bar at `stroke.thick` at the highlight's leading edge, in every theme, and sets the title in `body.strong`** where the product set no other role (revised after the review, D3; the draft drew a ring in high contrast instead of the bar) | The usage note of `background.selected`; `body.strong`'s description. The pilot's sidebar emphasizes the highlighted title too. The tint is the palette's step 5, solved to stand 1.16:1 off the canvas in light and 1.36:1 in dark (decisions/0012), so a mark that is not a color carries the selection, and the weight is lost where a product sets the title's role |
| P7 | **Sizes**: at least `size.target.minimum`; text padded `space.75` vertically and `space.150` horizontally; `space.150` from the leading slot to the title, `space.100` from the title to the trailing slot, `space.25` from the title to the second line; corners `radius.row`; the horizontal ones scaled up to xxxLarge, the vertical ones at every size (D2) | Below, "Sizes"; every value an existing token |
| P8 | **The slots stand on the title's first line**, centred on it, by the first text baseline that IconTile and the check give at their centre | IconTile's contract (a row aligned on the first text baseline); the pilot aligns its check with the title's top |
| P9 | **No line limit of the row's own**; a product sets one line where it wants it, the title truncated at its end and whole to assistive technology | The pilot's list rows are one line, its task rows wrap on the phone; one rule serves both |
| P10 | **At accessibility sizes the trailing slot moves under the text**, from the title's leading edge | design-language/08:67 |
| P11 | **The indent is `container.indent` per level, scaled with the text up to xxxLarge** (Q5, D2) | design-language/06:23–25, 08:67 |
| P12 | **Guides**: one per ancestor level, centred under where that level's leading slot is centred (as wide as the row's own) but never closer than half `container.gap` to the next level's slot (D2), the row's full height, `color.border.guide` (new, below) at `stroke.thin`, `stroke.regular` in the compact size class; hidden from assistive technology | The pilot draws them so (`childGuides`); design-language/04 gives the widths; Q7 the color |
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
against the pilot's. The IconTile rows were computed for a component that was not on this branch (#118); measured
since (below, "Revision after the review of phase 4"), the IconTile row is the title alone's height, 44 on iOS and 28
on macOS, not the 45 computed for iOS. The check's rows are measured by the unit tests (44 on iOS, 32 on macOS):

| Row | iOS | pilot phone | macOS | pilot Mac |
|---|---|---|---|---|
| Title only | 44 | — | 28 | — |
| IconTile and title (a list's row, a picker's) | 44 (computed 45) | 46 | 28 | 30 |
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
    Text(list.title).lineLimit(isAccessibilitySize ? nil : 1)         // one line below the accessibility sizes
        .textRole(row.hasChildren ? .body.strong : .body.regular)     // the pilot's emphasis, the product's
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

While a row is renamed, the product draws its own field in the row's place, not a ListRow with a field in its title:
the title holds no control (D1; a text field there was measured as part of the row's button, below). The pilot's
sideways scroll and the fade under the accessories go (Q3). The count and chevron columns hold by the
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
  `color.border.focus` (the selected row's bar, D3) on `pressed` and `accent-subtle`;
  `color.border.strong` (a Checkbox's and a Chip's high-contrast edge in a slot) on `hover`, `pressed` and `selected`.
  `text.primary` and `text.secondary` were declared on every row ground already.
- `tools/westron tokens contrast`: 333 pairs in each of the four themes, none failed.
- `tools/westron generate` writes the token into `WestronTokens/Generated/Tokens.swift` and
  `WestronUI/Tokens.xcassets/color.border.guide.colorset`, and the new declarations into `Tokens.swift`'s background
  lists; nothing else, since the draft contract generates nothing.
- The drop ring binds `color.border.insertion`, Rule's insertion color (Q4), so the line and the ring between and onto
  rows are one color that can change apart from focus; its declarations gained `pressed` and `accent-subtle`.
- After the review (D3) `color.border.focus` draws the selected row's bar, 3.02–3.03:1 on `selected` and `pressed` in
  the standard themes and 4.56–4.57:1 in high contrast (`tools/westron tokens contrast --all`);
  `color.background.selected`'s usage note and `color.border.focus`'s description name the bar. 342 pairs in each theme, none failed.

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
7. selected with pressed, with disabled and with a drop onto it, the bar in every theme, also beside a title whose
   role the product set (D3).
8. Right to left.

## What the tools cannot express yet

Written for the draft, before any tool changed. The approval asked the tools to close gaps 1 to 4 honestly, with tests;
"What the tools now express", below, says which closed and which stay open.

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
   description. (After the review the ring went: the selected row's bar is drawn in every theme, D3.)
7. **Cases over several states.** "A disabled row never tints" and "pressed over selected" are by order and prose;
   Chip's branch adds `state: { all: [...] }`, which would let a case say `disabled` with `hover`.
8. **A scaled metric.** That the indent scales with the text is in the description.

## Open questions

Each changes the contract; the recommendation is first, and the draft follows it.

- **Q1. What ListRow is on Apple.**
  (a) **Westron's own view**: the row's slots, level and guides, its action a system Button inside it beside the
  slots' controls (built nested, the controls inside the Button's label: "Revision of Q1 at implementation"),
  `selected` and `dropTarget` as shared state modifiers. Outside a `List` there is no system row
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

## Approval

Approved on 2026-11-22 by the coordinating agent under the owner's delegation (decisions/0014, "Process"):

- **Q1 (a).** Westron's own view; the row's action a system Button beside the slots' controls. Revised at
  implementation and accepted by the coordinating agent after the review: the Button's label is the whole row and the
  slots' controls are nested in it ("Revision of Q1 at implementation").
- **Q2 (a), on condition of a measurement.** A behaviour UI test measures a ListRow inside a `List` on iOS and macOS:
  the row's action runs, a Checkbox in the leading slot keeps its own press, and `.swipeActions` works (on iOS; on
  macOS not measured, "Measured"). Were any to
  fail, the answer would fall back to (c), "not promised inside a List", saying what was measured. It held ("Measured"),
  so (a) stands, and design-language/06 records the exception to "the system's List keeps its own insets".
- **Q3 (a).** The title truncates. If the pilot keeps its sideways scroll, that is the pilot's composition: a scroll
  view around rows the product lays out wider; ListRow neither helps nor hinders it.
- **Q4 (a).** `.insertionMark(_:level:)` draws `Rule(purpose: .insertion)`; the drop ring binds `color.border.insertion`
  (merged from #116), not `color.border.focus`, so the line between rows and the ring onto a row are one color.
- **Q5 (a).** `space.300`, scaled. Flagged for the second gate: 24 pt per level on the Mac against the pilot's 16; and,
  measured, at accessibility5 on an iPhone the scaled indent left a row at level 2 or deeper little or no room for its
  words, which the review settled by stopping the horizontal metrics at xxxLarge (D2, "Revision after the review").
- **Q6 (a).** A press tints and does not scale; design-language/05 points here.
- **Q7 (a).** `color.border.guide`.
- **Q8 (a).** The level as accessibility custom content.

The approval also decided the place of the Disclosure chevron (below) and asked for the tools' gaps 1 to 4 to be
closed in the tools, with tests, before the contract and the Apple implementation.

## The Disclosure chevron's place

Disclosure (#120) will be a style on `DisclosureGroup` whose label is a ListRow, and its chevron must stand at the
row's end, inside the row's highlight, after the trailing slot. The mechanism is a package-internal environment hook,
no public API: `EnvironmentValues.listRowDisclosureCell: AnyView?` in WestronUI. The Disclosure style sets it to the
chevron's cell around its label; ListRow reads it and draws the cell as the last item at its end, `container.trailingGap`
after the trailing slot, on the title's first line also at the accessibility sizes, inside the highlight so the row's
tints run under it; and it clears the value for its own slots, so a ListRow inside a slot draws no cell. The cell is its
own control and element, after the row's. The catalog's stand-in, `listRowDisclosureCell(_:)` (package access, catalog
only), sets the same value with a chevron in a frame `size.target.minimum` wide; the unit tests measure the cell's place
with a stand-in. Disclosure itself is #120's.

**How a leaf lines up with a branch.** The row reserves nothing: a leaf among branches that wants its trailing slot in
the branches' column ends that slot with an empty frame as wide as the chevron's cell, `size.target.minimum`, and the
`container.trailingGap` the row puts before the cell, scaled as the row scales it (up to xxxLarge, D2), as the pilot's
leaf rows keep the cell empty. A row in a list of leaves alone, the common case, keeps the room. The catalog's
`ListRowCellColumn` shows a branch with the stand-in and a leaf beside it, their counts in one column; its empty cell is
`ListRowEmptyCell`, package-internal, which reads the row's own scaled gap, and a unit test holds the two counts in one
column. How a product asks for that frame, a public empty cell or a Disclosure option, is decided with Disclosure
(#120).

**Revision with Disclosure (#120), 2026-11-22.** Disclosure's style now sets the hook, and the stand-ins are gone:
the catalog draws the real Disclosure (`ListRowBranch`), `ListRowEmptyCell` is removed, and
`listRowDisclosureCell(_:)` stays for the unit tests alone, which measure the cell's place with a frame of their own.
A leaf lines up through Disclosure's context `alignsLeaves`, `.disclosureAlignsLeaves()` on the tree: it sets a
second package-internal value, `listRowLeafCell`, a hidden copy of the real cell, which a row with no
`listRowDisclosureCell` draws in the same place (the Disclosure contract's decisions/0001, "Leaf alignment"). The row
also tells the style that it drew the cell (the preference `ListRowTookDisclosureCell`), so that the style draws none
after it, and names the cell by its title for assistive technology (`listRowDisclosureCellName`). What XCUITest reads
of the real cell: a Button named by the title, 44 × 44, on iOS; a disclosure triangle named by the title, 28 × 28,
valued 1 or 0, on macOS, where the row itself becomes a disclosure triangle with the group's value, the system's doing
(the Disclosure decision's "Measured"). The table under "Measured" below is the stand-in's, as measured then.

## What the tools now express

Closed, with tests in `tools/Tests/WestronToolsTests/OwnViewSlotsTests.swift` and the updated `OwnComponentTests`,
`IconViewTests`:

1. **An integer option** (`type: integer`, `default`, `minimum`): a parameter `Int = default` on an own component; no
   matrix axis; rejected in cases, constraints, restrictions and system options, and on a style; a default below its
   minimum is rejected.
2. **Forms on an own view**, two slots or more: an initializer per form, `action` for one whose intents include
   `activate`; no `bases`; the generated package `ListRowForm` with `takesAction` and the states of each.
3. **An own view with slots and states**: generic `@ViewBuilder` slots, the first required and the rest
   `{ EmptyView() }`; hover, focus, pressed and disabled the view's own; selected and dropTarget the shared modifiers
   `.selected(_:)` and `.dropTarget(_:)`, which the lint expects; the generated internal `ListRowState` with `isEntered`
   per OS, from a watchOS restriction of states.
4. **Marks**: the contract's top-level `marks`, `.insertionMark(_ edge: ListRowInsertionEdge?, level: Int = 0)`, its enum
   generated and its signature held by the lint.

Still open, carried by the contract's description: a binding by size class (5, the guides' width), cases over several
states (7, from Chip's branch, not used here) and a scaled metric (8, the indent's scaling and where it stops, D2).
A case by contrast (6) is no longer needed: the bar that replaced the high-contrast ring binds in every theme.

## Revision of Q1 at implementation

Q1 (a) asked for the row's action as a system Button **beside** the slots' controls. What was built nests them: the
Button's label is the whole row, the leading and trailing slots included, and a control in a slot takes its own press
because the inner gesture wins over the Button's. To assistive technology the row is an `accessibilityRepresentation`:
the same layout, with each control in a slot as its own element and the words as one element with the button trait.

Why not beside. The row must be pressable on its whole frame: the padding, the leading slot's surroundings, the room
past the words (P2). Beside means the Button covers the words only, so a press on the rest of the frame needs a second
mechanism, a tap gesture on an ancestor; that gesture is not a Button, so it has no pressed state for the press tint,
no keyboard focus or Space on the Mac, and on iOS it fires together with the control's own tap unless each control is
excluded by hand. That shape ("approach N" in the working notes) was planned as the fallback and never built: the
nested shape passed every measurement first. What was tried and broke, inside the nested shape: a system Button inside
the representation (the representation's words a `Button`) lost `.isSelected` and its frame was the union of its texts,
20 pt high on iOS, under the target; the combined element replaced it, its frame the words' column at the row's height.

What the code is, and what the contract and P2 now say:

- The drawn row: `Button(action:) { the whole row }` with a package `ButtonStyle` that draws the highlight; hover from
  `onHover`; disabled from `.disabled(_:)`. A control in a slot is nested in the label and keeps its press.
- To assistive technology, in order: the leading slot's control, if any, as its own element; then the words (title,
  second line, the trailing slot's text) as one element, `children: .combine`, with the button trait, `.isSelected`
  while selected, the level as custom content, and an activate action that runs the row's action, added only while the
  row is enabled; then the Disclosure chevron's cell. The element's frame is the words' column at the row's height, at
  least `size.target.minimum` (44 on iOS, 28 on macOS, measured).
- The shapes: the hit shape and the focus ring's are the whole highlight; the drawn row's accessibility shape is the
  highlight's too, but the drawn row is not what assistive technology meets: the representation's words' element has
  its own rectangle, the words' column at the row's height, beside the leading control's element (the first text said
  "the accessibility shape is the highlight's", which held for the drawn row alone).
- The static form: the words as one element of text, `.isSelected` while selected, unavailable while disabled, its
  frame the row's height; no button trait.

Measured for the review (iOS and macOS, "Measured"): (a) the chevron's stand-in takes its own press without running the
row's action, and is its own element after the row's; (b) a control in the trailing slot, a Button and a check side by
side (iOS, removed after the measurement): each was listed as its own element, but the trailing slot is combined into the
words' element, and the row's own element became Switch "PinRow" with the check's value 0, the check's role and value
taken over; so the trailing slot holds text and decorative content, and a control stands in the leading slot or in the
chevron's cell (below, "Revision after the review", D1); (c) a press
held on the leading check, or on the chevron's cell, begins no press of the row's Button, so the row never tints as
pressed under it, and a press held on the row does; (d) Tab on the Mac reaching the nested check is written as a test,
`testKeyboardFocusAndSpace`, which skips itself with the Mac's keyboard navigation off, as on this Mac: unmeasured.

## Revision after the review

The coordinating agent's review of the implementation (2026-11-22) decided the following; the contract, its
description and accessibility text, this decision and the code follow it.

**D1. No control among the words.** The title and the second line are text and decorative content; a control goes to
the leading slot or, for Disclosure, the chevron's cell. Measured: a `TextField` in the title became part of the row's
button, read as Button "4" with value "Groceries", and a Toggle in the trailing slot became the row's role. A row being
renamed is replaced by the product's field, not given a field in its title (the rename sketch above). The trailing slot
holds text and decorative content too: this keeps the review's "controls go to the side slots" for the leading slot
only, since the trailing slot is combined into the words' element (measured, b). The contract's accessibility text says
so. A labelled Icon in the leading slot (`Icon(_:label:)`) is its own element, before the words (G9).

**D2. Large text.** Every horizontal metric stops growing at its xxxLarge value: the indent, `paddingHorizontal`,
`gap`, `trailingGap`, and the insertion mark's start and end, which read them. `paddingVertical` and `subtitleGap` keep
scaling, and so does the text. On Apple the four are `@ScaledMetric`s read inside an environment whose
`dynamicTypeSize` is `min(size, .xxxLarge)`, and the content is given the real size back. This settles G1 and the old
"Sizes at accessibility5" note; design-language/06 says it in one sentence. The guide's centre is
`min(slotWidth / 2, indent − container.gap / 2)` past its level's slot start: centred under the slot while the indent
allows, and never closer than half the gap to the next level's slot (chosen: half `container.gap`, so a guide always
stands in the middle of the space between its level's slot start and the child's, with a wide slot or a narrow one).
The supplements lost their accessibility2 cap: every sheet is drawn at accessibility5 too (the tree's without counts,
so that its five rows fit one iPhone screen there). Measured, iOS, iPhone 17
width (402 pt), accessibility5, `Icon(.folder)` in the leading slot (72.3 pt wide at that size), no chevron's cell
(`ListRowTests.wordsColumnAtDepth`):

| Level | The words' column |
|---|---|
| 1 | 251 pt |
| 2 | 219 pt |
| 3 | 188 pt |
| 4 | 156 pt |

Each level costs 31.7 pt, the capped indent (24 pt scaled to xxxLarge). The numbers do not call for stacking the
leading slot above the words: at level 4 the column still holds a short word per line at accessibility5, and a row at
levels 1 to 3 keeps half the width or more. Not built. The contract's guidance: a product sets the title on one line
(`lineLimit(1)`) only below the accessibility sizes.

**D3. A bar on a selected row, in every theme.** At the highlight's leading edge, inside it, `stroke.thick` wide, in
`color.border.focus`, inset vertically by `radius.row`, rounded ends, mirrored right to left. The high-contrast ring on
selected is gone: a ring means a drop target only. The bold title stays as a second cue, and the bar carries the
selection where a product sets the title's role. The tint is not the signal: `background.selected` and
`background.pressed` stand at equal luminance in some themes, which is acceptable with the bar, since a pressed row has
no bar. Contrast of the bar, 3.02–3.03:1 on `selected` and `pressed` in the standard themes, 4.56–4.57:1 in high
contrast. Collisions checked: the guides start at least 12 pt in, past the bar; the insertion mark lies over the row's
edges, which the bar's inset by the radius keeps clear; on a selected row that is also a drop target the bar lies along
the ring's leading side, `border.focus` beside `border.insertion`, and the two read as one thicker leading edge of the
ring (the matrix's `selected` supplement, row dropTarget). For the owner at the second gate: this is a visible design change.

**D4. Smaller decisions.**

- The static form announces selected and disabled; its role is `text` in the contract (the tools reject announced
  states on role `none`), one element, no button trait. A behaviour test measures the live static row.
- The accessibility representation lays the title out in the drawn font, `body.strong` while selected. With the
  regular role there, the text clipped audit reported the selected sample's title, which the drawn row shows whole;
  with the drawn font it reports neither selected sample ("Measured"). The pilot meets the same in its sidebar, whose
  selected and branch titles are strong: a product that sets the title's role sets it on the title it passes, which the
  representation lays out as drawn.
- The insertion mark fades, never travels: two fixed overlays, top and bottom, each fading in and out by its edge and
  level; it is drawn above the next row (`zIndex`), so a bottom mark is whole over a highlighted neighbour in one
  stack (`ListRowTests.markAboveTheNextRow` reads the pixel half a point below the edge, the mark's blue, over the next
  row's `background.selected`); `zIndex` orders the children of one stack only, so in a `List` it is measured apart
  (below, "The insertion mark in a List"); it is drawn whole beside a disabled row (G7); watchOS draws nothing. Its
  start and end at accessibility5 are a row's at that size, the spacing stopped at xxxLarge
  (`insertionMarkAtAnAccessibilitySize`).
- The drop ring is drawn above the content: `ListRowTests.ringOverContent` reads the pixels where a guide crosses the
  ring's band at the row's top and bottom, the ring's blue, and the guide's own colour halfway down the row.
- The activate action is added only while the row is enabled; the live Archived row has a counting action, and a press
  on it counts nothing. That press is an event, which a disabled Button ignores by itself; the guard itself, an
  activation sent to the element as VoiceOver sends it, is unmeasured (below, "Open points").
- "Level" is in `Localizable.xcstrings`; the contract gives the spoken example, a row at level 1 gives "Level, 2".
- Q2 on macOS: the swipe is a trackpad's gesture that XCUITest cannot make; the claim is narrowed to iOS, and on the Mac
  a product offers the swipe's actions as context menu items or accessibility actions.
- The leaf's alignment: the contract's text was off by the trailing gap; the empty frame is the cell's width plus the
  scaled (capped) trailing gap. The product-facing API is decided with #120.
- Guides with no leading slot (G5): the slot's width is 0, so `min(0, indent − gap / 2)` puts each guide at its
  level's slot start.
- The side slots' text role (G8): both slots are laid out in `body.regular`, so an Icon there sizes from the body's
  role, not from a title the product set in another role.
- The IconTile rows of "Sizes" are not verified (IconTile is #118).
- design-language/02 and 04 list `color.border.guide` and the bar.
- The catalog shows `guides: false`, as a picker's.
- The Mac keyboard in a tree (arrows to move, Left and Right to collapse and expand) is an open point for the pilot's
  tree and Disclosure (#120): ListRow gives Tab and Space through its system Button only.

## Measured

On 2026-11-22, iOS 26 on the iPhone 17 simulator and macOS 26, in the catalog's `list-row` and `list-row-in-list`
entries (`ListRowBehaviorTests`, `tools/apple/check.sh behavior ios|macos ListRowBehaviorTests`); remeasured after the
review.

**The accessibility shape** ("Revision of Q1 at implementation"). XCUITest's hierarchy of the live rows:

| Element | iOS | macOS |
|---|---|---|
| Pressable row "Inbox", count 12, selected | Button "Inbox, 12", Selected, 344 × 44 | Button "Inbox, 12", Selected, 670.5 × 28 |
| Nested row "Today", level 1 | Button "Today", 320.7 × 44 | Button "Today", 647 × 28 |
| The task's check | Switch "Call the plumber", value 0, 44 × 44 | CheckBox "Call the plumber", value 0, 32 × 32 |
| The task's row, with a second line | Button "Call the plumber, Tomorrow", 290 × 50, after the check | Button "Call the plumber, Tomorrow", 628 × 43, after the check |
| A branch "Projects" | Button "Projects", 259 × 44 | Button "Projects", 606.5 × 28 |
| Its chevron's cell, a stand-in | Button "Collapse", 44 × 44, after the row's | Button "Collapse", 28 × 28, after the row's |
| A static row "Buy washers", level 1, selected | StaticText "Buy washers", Selected, 320 × 44 | StaticText, value "Buy washers", Selected, 646.5 × 28 |
| A disabled row | Button "Archived", Disabled | Button "Archived", Disabled |
| The leading icon | no element | no element |

Against the first measurement: the branch and its cell and the static row are new on the page; the static row is one
element of text at the row's height (first measured at its words' height, 20 pt, and given the row's); the
rest is as before. The
words are listed under each button as texts too, as XCUITest lists them under a westron Button; nothing outside the
button repeats them. The level as more content is not visible to XCUITest; a unit test (`spokenLevel`) holds that it is
attached, "Level, 2" at level 1 and nothing at level 0, for both forms, and VoiceOver's "More content" rotor reads it.

**Presses.** A press on a row runs its action and chooses it; a press at the row's far end, past its words, and one in
its bottom padding, run it too: the whole frame is the hit area. A press on the check toggles it, and one on the
chevron's cell counts the cell's press; neither runs the row's action. Held for 0.6 s, a press on the check or on the
cell begins no press of the row's Button (0 presses counted by `listRowPressObserver`, a package hook), so the row
never tints as pressed under them; held on the row, it begins one. A disabled row takes no press, and its counting
action stays at 0. iOS and macOS alike.

**In a List** (Q2): the row's action runs, the check in the first row's leading slot keeps its own press, and on iOS the
List's `.swipeActions` (a destructive Delete) appears on a swipe and runs. On macOS the swipe is a trackpad's gesture
XCUITest cannot make: not measured, and the contract promises the List's swipe on iOS only. The keyboard: with the
Mac's keyboard navigation off, as on this Mac, `testKeyboardFocusAndSpace`, which now also asks Tab to reach the check
nested in a row, skips itself, as Chip's and Checkbox's do; it is not measured.

**Sizes at accessibility5** (D2): above, "Revision after the review". The words' column of a row at level 4 on an
iPhone is 156 pt.

**The audit** (`WESTRON_ENTRY=list-row,list-row-in-list tools/apple/check.sh a11y`, iOS, all five configurations):
clean but for suppressions recorded in `CatalogAccessibilityAuditTests`, each matched by its label: contrast on the
disabled samples and the live Archived row (an inactive row, at `opacity.disabled` by the contract), contrast on an
element under the status bar (the harness's own, for every entry), and "Text clipped" on the long title the page sets
on one line (truncated by the contract, Q3). The selected samples are no longer reported: with the representation's
title in the drawn font (D4) neither the pressable nor the static one is, so the earlier suppression of "pressable,
selected" was removed. With every sheet at accessibility5, the page at that size is 17 screenfuls; the contrast audit
gave up ("Audit failed to complete in time") on every try at the 14th, over the drag samples, and completed in a third
of a second with the page 30 pt before or 60 pt past that position. The harness now tries such a screenful a third time
with the page moved on by a tenth of the screen; it did, and the audit passed. The tenth the nudge scrolls off the top
was audited on the screenful before, which overlaps by more than a tenth; on the first screenful, and the first window
of the Dynamic Type pass, nothing was, so there the harness drags the page back after the nudged audit and audits it
once more where it was, and fails the entry for infrastructure if that audit gives up too (after the review, N2). Each
nudge and each drag back prints a line of its own in the log.

## The insertion mark in a List

`zIndex` orders the children of one stack; in a `List` each row is a cell of its own, which the row cannot draw above.
Measured on 2026-11-22 in the `list-row-in-list` entry, which now ends with rows at level 1 laid out as the contract
gives a row in a List: Garden with a bottom mark over Seeds, selected; Errands, selected, over Home with a top mark;
Work with a bottom mark over Bills, at rest; and Notes with a bottom mark over Trips with a top mark; every mark at
level 2.
Read from the screenshots' pixels (`catalog-screenshot.sh ios|macos --entry list-row-in-list`, dark):

| | iOS 26, iPhone 17 | macOS 26 |
|---|---|---|
| The rows | 44 pt each, in cells 8 pt apart | 28 pt each, the cells abutting |
| A bottom mark over a selected next row (Garden) | whole, 2 pt, centred on Garden's bottom edge, in the gap | its upper half only, 1 pt, inside Garden; Seeds' highlight shows below it |
| A top mark under a selected row (Home) | whole, 2 pt, centred on Home's top edge | its lower half only, 1 pt, inside Home |
| A bottom mark over a row at rest (Work) | whole | its upper half only: clipped by its cell, not covered |
| Both rows marked (Notes' bottom, Trips' top) | two lines, 8 pt apart | one whole line, 2 pt, centred on the edge between them |

So the List clips, on the Mac: the contract's `platforms` say so, rather than fighting the List. In a List on the Mac a
product marks both rows beside the place, whose halves meet in one line; on iOS it marks one, either edge, whole in the
gap. The 8 pt between the List's cells on iOS also parts the rows' highlights there, which a row outside a List does
not show; why the List sets its 44 pt rows 8 pt apart (its default minimum row height or its own spacing) is not
measured, and the swipe and the presses measured in that entry are not affected by it.

## Revision after the review of phase 4 (2026-11-24)

A review of the whole phase put the components together and found two defects that only show when they are composed,
and a gap: the lists screen's row was drawn nowhere.

**A disabled row dimmed what it holds twice.** The row drew everything at `opacity.disabled`, the Disclosure
chevron's cell and a Checkbox in its slot included, and each of them, reading the row's `isEnabled`, applied
`opacity.disabled` again: measured on main by the most opaque pixel on a transparent ground, in-process, the chevron
in a disabled row 0.16 against 1.0 enabled and 0.4 in a disabled group after a text label, and the check at the start
of a disabled row 0.16 against 0.4 for a disabled check alone (`ImageRenderer` on iOS and macOS and Core Animation's
renderer on macOS agree; the reviewer's own probe read 0.29 and 0.64 for the check, which neither renderer here
reproduces). And the cell, disabled with the row, locked the branch's fold, while a disabled label of any other kind
leaves the chevron enabled. Neither contract said the opposite; together they gave the second dimming, and nothing
decided the fold. The rule now in this contract and in Disclosure's and Checkbox's:

- A disabled row dims what it holds once. The row no longer lays one opacity over its whole content: it dims its
  slots, its words, its guides and its highlight (`listRowOpacity`), and tells the controls inside it that it does
  (`listRowDimsContent`, package-internal), so that a Checkbox at its start draws no opacity of its own for disabled;
  the check keeps every other part of being disabled. A row inside a disabled row's slot does not dim again either.
  Since SwiftUI's opacity reaches each layer drawn, the parts dimmed one by one draw the same pixels as the whole
  dimmed at once: no sheet without a chevron changes.
- Disabling a row does not lock its branch's fold. A disabled row is not pressable, but folding a branch is
  navigation, and the reviewer's case is the same call, `.disabled(true)` on the label, doing two things to the
  chevron depending on the label. The cell takes its enabled state and its look from its DisclosureGroup (Disclosure's
  revision): a row disabled alone keeps a chevron that folds and is drawn whole, as an active control meets its 3:1
  non-text contrast, which a chevron at `opacity.disabled` would not; a disabled group disables the chevron, which dims
  itself once while the row dims the rest. Chosen over the other reading, the chevron dimmed with the row but still
  folding, which would leave an operable control below its contrast.

Measured after, on iOS (iPhone 17 simulator, iOS 26) and macOS alike: the check in a disabled row 0.4, as alone
disabled; the chevron in a row disabled alone 1.0, as after a disabled text label, and in a disabled group's row 0.4,
as a disabled group's after a text label (`ListRowTests.disabledRowDimsTheCheckOnce` and
`disabledRowDimsTheChevronOnce`; `DisabledRowPixelTests` on macOS with Core Animation's renderer). The fold:
`DisclosureStyleTests.disabledLabelKeepsTheFold` (and once, on the iOS simulator, a behaviour test on a live sample
the catalog does not keep: Disclosure's decisions/0001, its revision).

**A static Chip at the end made a row taller.** The trailing slot stood inside the words' column, which was padded by
`container.paddingVertical`, so its frame could not stand in that padding as the leading slot's does, which the
contract allowed for any slot. Measured on macOS on main: the title alone 28, an Icon at the end 28, a static Chip at
the end 36, the same Chip at the start 28, a check at the start 32; with a second line 43, and 45.5 with a Chip at
the end. Now only the title and the second line are padded and the trailing slot stands beside them on the first line,
as the leading slot does: a static Chip at the end 28, with a second line 43, and a slot really taller than the row
still grows it (84 pt high: 93). On iOS (iPhone 17 simulator) the 44 pt minimum hid it on one line at the default
size, but not at xxxLarge, the largest size where the slot stays at the end (45.7 against 44), nor under a second
line (52.3 against 50 at the default size); now the Chip at the end is 44 at both sizes and 50 and 69.3 with a second
line, as without it. `ListRowTests.trailingSlotStandsInThePadding` holds both platforms at both sizes. One existing
sheet changes with it, on iOS alone: in `long-title`, where the row is given less width than its title needs at
level 4, the count at the end is squeezed onto two lines, and that frame, taller than the title's one line, now stands
in the padding too, so the row is about 46 pt high instead of 52, the count still inside it. Every other sheet keeps
its layout pixel for pixel; a row whose trailing slot stacks under its text, at the accessibility sizes, keeps its
padding around the whole column as before.

**The lists screen's row.** Nothing drew a ListRow with an IconTile at its start, the pilot's main composition. The
supplement `composition` draws IconTiles at the start, a count and a static Chip at the end, then the same rows as a
Disclosure branch with a leaf and a collapsed branch whose row is disabled alone, its chevron whole; and the row with an IconTile at the start, computed in
"Sizes" before IconTile existed, is measured: the title alone's height, 28 on macOS and 44 on iOS
(`ListRowTests.iconTileRowHeight`).

## Open points

- **A control at the end of the row** (after the review, N5). The trailing slot holds words and decorative content
  only: its words join the row's name, and `accessibilityElement(children: .combine)` over the words cannot keep a
  control apart from a slot's content, which the row sees only as an opaque view; measured, a toggle there became the
  row's role and value (above, "Revision of Q1 at implementation", b). Two ways out were not taken. A trailing slot of
  its own elements, outside the combined words, after the row's element as the chevron's cell is: a control there
  keeps its role, but the slot's words leave the row's name, so "Inbox, 12" becomes "Inbox" and a separate "12". And a
  separate accessory place at the end, a third kind of content beside the trailing words, as the Disclosure chevron's
  cell is, with the same hook or a public slot. The pilot's rows need neither (above, "The pilot's rows, composed");
  a later revision decides when a product does.
- **The activation guard** (after the review, N6). The words' element carries the row's activation only while the row
  is enabled (D4). An activation sent to the element, as VoiceOver's double tap sends it, does not reach it from this
  repository's tests: in-process, the hosting view of a unit test's window exposes no accessibility elements on iOS or
  macOS (tried: walking `accessibilityElements` and `accessibilityChildren()` found nothing to activate), XCUITest
  presses with events only, and the Accessibility API's `AXPress` from the Mac's UI test runner needs the runner to be
  trusted for accessibility, which it is not on this Mac. Unmeasured: the code adds `accessibilityAction` only when the
  row is enabled, and the disabled row's events are measured ("Presses").
- **The Mac keyboard in a tree** (D4): with the pilot's tree and Disclosure (#120).
