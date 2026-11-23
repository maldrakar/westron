# 0014. Core components and composition

Date: 2026-11-22. Status: accepted. The owner's decision on #32, the component list of phase 4. Revised 2026-11-23:
#121 is the floating Button alone, with no glass Surface (the owner's answer, decisions/0015).

## Context

decisions/0006 drew the phase 4 list from the pilot's inventory. The pilot, todo-app, keeps the components of its two
screens in `Sources/DesignSystemComponents/`: 77 files, a model and a style per family, every number, color and motion
of a component in its style (read at todo-app's commit `0162887`). Its specs, `docs/specs/lists-screen.md` and
`docs/specs/list-screen.md` (below, lists-screen.md and list-screen.md), name each of them as a component of the screen
(list-screen.md, section 11). Ported one to one, they would give westron some thirty components, and
most of them would name a part of one screen of one product: a task row, a Done strip, a tag bar, a search field. Each
would be a contract, an implementation, a snapshot matrix and a parity record on every platform, and a second product
would need few of them under those names.

Issue #32 asked for 10–15 components from the pilot's screens and the order to release them in.

## Decision

The owner rejected porting the pilot's components one to one (2026-11-22). westron holds a small core; the pilot and
other clients build their more custom parts from the core by composition. In the owner's words: define the main core
components that go into the design system, and on their basis, for example through composition, something more custom
can be made in the pilot and other clients. A SearchField, for example, is not a separate component: it is westron's
TextField, styled.

- **The core of phase 4** is four new components and three extensions of approved contracts, each with its issue.
- **What the system presents stays the system's** (decisions/0003, point 1): a menu, an alert, a sheet, swipe actions
  and the empty state take no westron component. westron styles what is inside them with its existing styles.
- **What is one product's stays in the product**, built there from westron's components and laid out with westron's
  tokens: the pilot's task row, card, bars and headers are its compositions, not westron's components.

### The core of phase 4

| Issue | What | Kind |
|---|---|---|
| #115 | TextField: icon slots at the start and the end. A search field is the framed field with a leading glyph | an extension of `spec/components/text-field/` |
| #116 | Rule: a rule that carries a label, the pilot's area line; and, decided at the contract, whether the insertion indicator of a reorderable list is a Rule or something else | an extension of `spec/components/rule/` |
| #117 | Chip: a compact capsule with a label and an optional icon, selectable (a filter) or pressable (a value) | new |
| #118 | IconTile: a colored tile with an icon, its color from the context, as Checkbox takes the list's color. The owner keeps it a component rather than a composition of Surface and Icon | new |
| #119 | ListRow: a leading slot, a title, a second line, a trailing slot; hover, pressed and selected; a nesting level with guide lines | new |
| #120 | Disclosure: the collapse chevron, a style on the system `DisclosureGroup` | new, a style on a system control |
| #121 | Glass: a floating Button and a glass Surface. The owner takes glass into this phase; what is drawn before iOS 26 is decided at the contracts. Revised 2026-11-23 (decisions/0015): the floating Button alone, Button's option `floating`; no glass Surface, since every bar takes the system's own glass | an extension of `spec/components/button/`; Surface's contract only says where a group's glass comes from |

Also in the phase: #113, the line height of a one-line TextField on macOS, which SwiftUI can take from another font; the
workaround goes into `WestronUI`. #115 starts after it, since both touch the same style.

**Order.** 1) TextField's slots (#115) and Rule's label (#116); 2) Chip (#117) and IconTile (#118); 3) ListRow (#119) and
Disclosure (#120), since a row holds a tile, a chip and a chevron; 4) glass (#121), last.

**Process** (the owner, 2026-11-22). One pull request per issue, the default of decisions/0005; phase 3's single pull
request is not repeated. In this phase the owner delegates the approval of a contract, the first gate, to the
coordinating agent; the second gate, the snapshot matrix, and the release stay the owner's. Phase 3's second gate, the
snapshot matrices of its six components, is passed.

**Postponed.** #33, dense components for technical interfaces, has no pilot consumer, and a component needs one
(decisions/0005, "Rules"). #34, the watchOS subset, is decided separately, not in this phase.

### What stays the system's

| What | The system's view | What westron gives it |
|---|---|---|
| A menu and a context menu: Show as, "…", the "+" menu, a row's menu | `Menu`, `.contextMenu` | nothing of its own; a menu's button is a westron Button |
| The delete confirmation | `.alert` (the pilot's, `Apps/Apple/Sources/TodoAppleUI/ListsScreen/ListsDialogs.swift`) or `.confirmationDialog` | nothing |
| A sheet: "Move to…" | `.sheet` | its content: rows, tiles, text roles |
| Swipe actions: a task's Delete | `.swipeActions` (open point 3) | the button it uncovers is a system `Button` with the destructive role |
| The empty state | `ContentUnavailableView` (iOS 17, macOS 14, watchOS 10) | its label and description: IconTile and text roles |

westron never draws over these: chapter 09 leaves sheets, menus and alerts to the system ("What stays with the system
and what westron controls"), and Surface's contract keeps westron's shadow off them.

### What stays a composition in the pilot

The screen header, the block header, the task row, the subtask row, the add row, the task card, the column, the "Done
today" strip, the bottom bar, the tag bar, the empty screen and the "Move to…" picker. Each is the pilot's own view,
built from westron's components; its layout, which part stands where and how far apart, is the pilot's, in westron's
tokens. The pilot's own motions, such as a done row lingering before it leaves, stay its behavior on westron's motion
tokens (decisions/0013).

### The pilot's families, mapped

Every family of `Sources/DesignSystemComponents/` in todo-app, by its files, and what it is built from. "westron" is a
component westron has or gets in this phase; "system" is the system's own view; "pilot" is a composition that stays in
the pilot.

| Pilot family (files) | Built from | Where |
|---|---|---|
| Text (`TextModel`, `TextStyle`) | Text: a role and a color role | westron |
| Icon (`IconModel`, `IconStyle`) | Icon | westron |
| Tile (`TileModel`, `TileStyle`) | IconTile (#118) | westron |
| Check (`CheckModel`, `CheckStyle`) | Checkbox; its pop and the tick that draws itself give way to Checkbox's `motion.check` | westron |
| Text field (`TextFieldModel`, `FieldStyle`) | TextField: framed for a name typed in a row, inline for a card's title and notes | westron |
| Search field (`SearchFieldModel`, `SearchFieldStyle`) | TextField, framed, with `magnifier` at the start and `microphone` at the end (#115) | westron's TextField |
| Button (`ButtonModel`, `ButtonLabelModel`, `ButtonLabelStyle`, `ControlFillStyle`) | Button. `ControlFillStyle.color`, a fill of its own, is a variant; `.container`, the glass under a bar's controls, is the system toolbar's own (decisions/0015) | westron |
| Menu (`MenuModel`, `MenuButtonModel`, `GlassMenuButtonModel`) | `Menu` and `.contextMenu`; the button that opens one is a Button, a floating one for "…" over content (#121), or the bar's own item | system |
| Confirmation (`ConfirmationModel`, `ChoiceModel`) | `.alert`, its choices the system's buttons | system |
| Glass buttons (`GlassButtonModel`, `GlassButtonLabelModel`, `GlassControlStyle`, `GlassCapsuleStyle`) | the floating Button (#121); the Mac pane's "+" and "…" in one capsule are the window toolbar's own group, on its glass from macOS 26 (decisions/0015) | westron (#121) |
| Floating "+" (`FloatingButtonModel`, `FloatingButtonStyle`) | the floating Button (#121), primary, icon-only | westron (#121) |
| List row (`ListRowModel`, `ListRowStyle`, `AccessoryModel`, `ChevronStyle`, `IndentStyle`) | ListRow (#119) at its nesting level with its guides: IconTile at the start, the title a Text, or a framed TextField while it is renamed; at the end the count a Text, the chevron a Disclosure (#120), the grip and the picker's check an Icon | pilot, on ListRow |
| Area line (`AreaLineModel`, `AreaLineStyle`) | Rule with a label (#116); an inline TextField in the label's place while it is named; the grip and the check an Icon; a ListRow (#119) where it stands among rows | pilot |
| Task row (`TaskRowModel`, `TaskRowStyle`, `MetaItemModel`, `MetaItemStyle`) | ListRow (#119): a Checkbox at the start, the title a Text, the second line the meta items, each an Icon and a Text (the Mac's tag a Chip, #117); lifted, a dragged Surface | pilot |
| Subtask row (`SubtaskRowModel`, `SubtaskRowStyle`) | ListRow (#119) with a Checkbox | pilot |
| Add row (`AddRowModel`, `AddRowStyle`) | ListRow (#119): the `plus` Icon and a Text; a Rule above it where it has one | pilot |
| Block header (`BlockHeaderModel`, `BlockHeaderStyle`) | Disclosure (#120), its label the title, a heading Text in the list's color, and the subtitle a Text; an inline TextField while the list is named; a Rule under it. A column's header has no chevron | pilot |
| Screen header (`ScreenHeaderModel`, `ScreenHeaderStyle`) | IconTile (#118), a heading Text, a subtitle Text | pilot |
| Tag bar (`TagBarModel`, `TagBarStyle`, `TagChipModel`, `TagChipStyle`) | selectable Chips (#117), lit in the list's color, in a horizontal `ScrollView` | pilot, on Chip |
| Pill (`PillModel`, `PillStyle`) | a pressable Chip (#117) | westron's Chip |
| Task card (`CardModel`, `CardStyle`, `EntranceStyle`) | a raised Surface: a Checkbox, inline TextFields for the title and the notes, an icon-only tertiary Button with `expand`, subtask rows, an add row, pills | pilot |
| Column (`ColumnModel`, `ColumnStyle`, `CardHoverStyle`) | a sunken Surface; a block header with no chevron; its cards raised, outlined Surfaces with task rows on them | pilot |
| Done strip (`DoneStripModel`, `DoneStripStyle`) | a secondary Button, the capsule, whose label is the list's Icon, a Text and the `chevron` Icon, and whose action opens the rows under it | pilot |
| Bottom bar (`BarModel`, `BarStyle`) | the system's bottom toolbar, its glass the bar's from iOS 26 (decisions/0015): the bar's items, the search TextField (#115), a group of items | pilot |
| Empty screen (`EmptyScreenModel`, `EmptyScreenStyle`) | `ContentUnavailableView`: an IconTile (#118), a heading Text, a Text | system, with the pilot's content |
| Move picker (`PickerModel`, `OptionPickerStyle`, `PickerTopLevelStyle`) | `.sheet`; its rows ListRows (#119) with IconTiles and the `check` Icon, an option that cannot be chosen at `opacity.disabled`; areas as labeled Rules (#116) | pilot, in a system sheet |
| Swipe (`SwipeModel`, `SwipeStyle`) | `.swipeActions` with a destructive `Button` | system; open point 3 |
| Drag in the tree (`DragStyle`, `DropIndicatorStyle`) | the card carried, a dragged Surface with an IconTile, a Text and the `grip` Icon; the Finder's line and circle, the insertion indicator (#116); the phone's dashed slot, open point 1 | pilot |
| Drag of a task (`TaskLiftStyle`, `BlockDropStyle`) | the lifted task, a dragged Surface; the place it would land, the insertion indicator (#116); a block it would move into, tinted and ringed with the list's `color.category.<name>.*` tokens; the row left behind, open point 1 | pilot |
| Leaving (`TaskLeavingStyle`) | the pilot's motion on `motion.leave` | pilot |
| Pointer tint (`HoverStyle`) | the hover state of the westron component under the pointer: Button, ListRow, Chip | westron, a state |
| Line (`LineStyle`) | Rule for a straight line, `border.*` and `stroke.*` for an edge; a dash, open point 1 | westron |
| The screen's own values (`ListScreenStyle`) | the pilot's layout in `space.*` tokens; the fade under the floating buttons is the pilot's, or the system's scroll edge effect from OS 26 | pilot |

### Open points

What the core and the tokens above do not cover. None of them adds a component in this decision; each is decided at a
contract of this phase or in the pilot.

1. **The looks of drag and drop.** Three roles have neither a component nor a token: a dashed outline, the phone's slot
   in the tree while a row is dragged (`DragStyle.swift`, `Slot.stroke`; lists-screen.md, section 7, "dashed at the
   depth the drop would take") and "+ Add list" as a column of the board (`AddRowStyle.swift`, `dash`), since Rule is
   straight and solid by its contract and no `stroke.*` token has a dash; the row a task is dragged from, dimmed to
   0.35 (`TaskLiftStyle.swift`, `opacity`), where `opacity.*` has only `disabled`; and the shadow a column's card deepens
   to under the pointer on the Mac (`CardHoverStyle.swift`), where Surface has no states and `shadow.*` has `raised`,
   `dragged` and `overlay`. Missing: tokens for these roles, or a contract that draws them. The tint under a task just
   dropped (`TaskRowStyle.swift`, `fresh`) may be `color.background.accent-subtle` or a list's `background`, the
   pilot's to choose.
2. **A tree wider than the screen.** The pilot's rows scroll sideways while the counts and chevrons stay pinned at the
   right edge over a fade (`ListRowStyle.swift`, `fadeWidth`; lists-screen.md, section 1, and "Risks", whose fallback
   is a title that truncates at depth). #119's description does not cover it: ListRow's contract decides whether its
   trailing slot pins over a fade or the title truncates.
3. **Swipe actions outside a list.** Before OS 27 `.swipeActions` acts on a row of a SwiftUI `List` ("Adds custom swipe
   actions to a row in a list", the SwiftUI documentation in Xcode 27.1); `swipeActionsContainer()`, which gives the
   rows of a `ScrollView` or a `LazyVStack` swipe actions, needs iOS 27, macOS 27 and watchOS 27. The pilot's rows
   stand in scroll views, where its own gesture uncovers Delete
   (`Apps/Apple/Sources/TodoAppleUI/ListScreen/SwipeToDelete.swift`, `RowSwipe.swift`; list-screen.md, section 6 and
   spike #174). Until OS 27 the pilot either puts
   the rows in a `List` or keeps its gesture, with a westron Button in the destructive role as what it uncovers; the
   choice is the pilot's, and westron adds no component for it.

## Consequences

- A pilot need is met first by composing westron's components. A new component, or a new part of a contract, is
  proposed when composition cannot draw it, through the first gate (`/new-component`, decisions/0005).
- #121 changes two approved contracts at the contract first: Button's description says floating glass buttons are not
  that component, and Surface's that a surface never takes glass (`spec/components/button/button.spec.yaml`,
  `spec/components/surface/surface.spec.yaml`). Chapter 09's open question 3, the fallback before OS 26, is answered
  there. Revised 2026-11-23 (decisions/0015): Button gains the option `floating`; Surface keeps "never takes glass".
- The pilot's move changes (decisions/0006, revision of 2026-11-22): it deletes the values and styles of
  `DesignSystemComponents` as westron covers them and keeps its compositions, built from westron's components.
- The `consumers` field of each contract in this phase names the pilot screen its compositions stand on, as each issue
  above does.
