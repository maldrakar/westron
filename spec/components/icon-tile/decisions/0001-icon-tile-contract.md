# 0001. The IconTile contract

Date: 2026-11-22. Status: draft, for the first gate (#118). In phase 4 the owner delegates the approval of a contract to
the coordinating agent (decisions/0014, "Process"). There was no interview: the agent answered the questions of
`/new-component` from the owner's decision, the documents and the pilot, and gives the source of each answer. An answer
no source gives is marked as a guess and listed under "Open questions", with the agent's recommendation.

## Context

The owner keeps the tile a component rather than a composition of Surface and Icon: "a colored tile with an icon, its
color from the context, as Checkbox takes the list's color" (#118; decisions/0014, the core of phase 4). The pilot,
todo-app (read at its working tree of 2026-11-22), draws it in five places: a row of the Lists screen
(`ListRowModel.swift`), the header of the List screen (`ScreenHeaderModel.swift`), the "Move to…" picker
(`PickerModel.swift`), the card a dragged list carries (`DragStyle.swift`) and the empty screen (`EmptyScreenModel.swift`).
`TileModel` is a glyph and a `TileStyle`: a color, a side, a corner radius, a glyph size and weight.

What the pilot gets right, its roles: the tile marks a list by its color and glyph; it stands beside the list's title in
a row, a header, a picker and a drag card, and alone above the words of an empty screen; a list without a color gets a
neutral tile (`TaskViewList+Rows.swift`, `tileColor`: `?? .stone`), and so does the picker's "Top level"
(`PickerTopLevelStyle.tileColor: .fill`, its glyph in ink 2). Its look: a tinted ground, the base color at 15 % (24 % in
dark), with the glyph in the base color mixed toward ink (`Color+Components.swift`, `Tile`); a rounded square whose
corner is 0.27 to 0.29 of its side; sides of 30 and 26 in a phone row, 22 and 18 in the Mac sidebar, 18 in the drag card,
38 and 40 in a header, 64 and 60 in an empty screen; glyph weight medium. The values are the pilot's, not westron's
(decisions/0011–0013).

## The interview, answered from the sources

| Question | Answer | Source |
|---|---|---|
| 1. Need, scenarios | A list's mark in a row, a header, a picker, a drag card, an empty screen | #118; decisions/0014, the mapped families; the pilot's files above |
| 2. System control | None on any platform: SwiftUI, GTK and the web have no tile. westron builds its own view, as it does Icon | decisions/0003, point 2; chapter 09 lists tiles among westron's content-layer components |
| 3. Options | `glyph` (the registry's names); `scale` (the platform's relative scale). No size, no color, no fill option | below, A–D |
| 4. States | None. A picker row that cannot be chosen dims the whole row, tile included (the pilot's `disabledOpacity`), which is the row's | the pilot's `PickerModel.swift` |
| 5. Slots | `label`, spoken, not drawn, as Icon's | below, E |
| 6. Constraints | None | — |
| 7. Accessibility | Role `image`; decorative without a label, announced with one | below, E |
| 8. Platform differences | Corners continuous on Apple, circular elsewhere; watchOS drawn as elsewhere, its subset decided in #34 | design-language/04; decisions/0014, "Postponed" |

## The choices

### A. The Apple API: an own view, `IconTile(.tray)`

- Considered: (a) a view, `IconTile(.tray)`, `IconTile(.folder, label: list.title)`, the glyph first and unlabeled, as
  Icon's; (b) a modifier on Icon, `Icon(.tray).tile()`; (c) a label style, `Label(title, icon: .tray).labelStyle(.tile)`;
  (d) a composition of Surface and Icon in the pilot.
- **Chosen: (a).** (d) is the owner's rejection. (b) splits one image between two components, so the label and the
  role would be the icon's while the tile draws around it, and the conventions do not derive an option whose values are
  icons on a modifier. (c) needs a title, but the tile stands without one: in `ContentUnavailableView`'s icon, in
  ListRow's leading slot (#119), in a drag card. The name `IconTile` is the issue's, and no SwiftUI type
  (`tools/Sources/WestronTools/Contracts/SwiftUITypes.swift`, Xcode 27.1); `Tile` alone was too generic to keep free.

### B. Color: the context's list color, and a neutral tile with none

- The color arrives as Checkbox's does: the shared `.category(_: Westron.Category?)`, set once around a list's rows or
  a screen, read from the environment (`platforms/apple/Sources/WestronUI/Category.swift`; spec/conventions.md, "Context
  a style reads"). IconTile adds no API for it. The contract states it in prose, since no schema field takes a context
  value; Checkbox's P15 waits for a second kind of context value, and this is a second reader of the same one.
- With no list color, considered: (a) a neutral tile, `color.background.muted` and `color.text.secondary`; (b) the
  accent, as a checked Checkbox, `background.accent-subtle` and `text.accent`, whose description names "the tile behind
  an empty state's icon".
- **Proposed: (a).** The accent marks the primary action and the selection (design-language/00, principle 3; 02, "One
  accent"); a list with no color is not selected. The pilot draws a list with no color and "Top level" neutral. The pair
  exists and is declared (`text.secondary` on `muted`, 4.74:1 in light), and `muted` is already "a tag or a badge
  without a color". The conventions let a contract choose its nil ("nil being the contract's default"). A guess: open
  question 2.

### C. The fill: a quiet ground with a colored glyph

- Considered: (a) quiet: `color.category.<name>.background` with the glyph in `color.category.<name>.icon`; (b) solid:
  `color.category.<name>.fill` with the glyph in `on-fill`; (c) both, as an option.
- Both pairs are declared in `tokens/` and pass in every theme (`tools/westron tokens contrast --all`, 2026-11-22):
  (a) `icon` on `background`, non-text, 3.19–3.22 in light, 3.48–3.52 in dark, 4.79–4.85 in light-hc and 5.21–5.27 in
  dark-hc against 3 and 4.5; (b) `on-fill` on `fill`, text, at least 4.5, and 7 in high contrast.
- **Proposed: (a).** It is the pilot's role and keeps a column of twelve hues calm (principle 3; direction B's soft
  look, decisions/0013). It leaves the solid list color to the checked check (`control`), so a tile, a square, never
  reads as a checked disc beside it on the List screen. Its neutral twin exists (B), and a solid one does not: no
  neutral `fill` and `on-fill` pair exists outside `status.neutral`, which means a status. Against it: design-language/02
  and the `control` tokens' usage notes say "tags, tiles and statuses keep `fill`", a sentence written when separating
  `control` from `fill` (decisions/0012, revision of 2026-11-18), which assumes a solid tile. (c) has no pilot use
  (rule 6). A guess: open question 3.
- No line in any theme: the glyph carries the meaning, its ratio rises in high contrast on the same ground, and a
  tile's edge is not information (WCAG 1.4.11 asks it of the glyph). Surface's high-contrast line answers a shadow,
  which a tile does not have.

### D. Size, Dynamic Type and the corner: from the text, no size option

- Considered: (a) sized by the text role of its context, as Icon and Checkbox are, with Icon's relative `scale`;
  (b) an enum `size` (`s`, `m`, `l`) bound to `size.control.*`; (c) `size` bound to new tile tokens.
- **Proposed: (a).** design-language/07 decides it: "Inside a shape, an icon is sized by the shape … and the shape
  scales with the text beside it"; "A relative scale is the only size choice". It grows with Dynamic Type with the text
  it stands by, and it follows the platform's text: the Mac's 13 pt body gives a smaller tile than the phone's 17 pt, as
  the pilot's 22 and 30 differ. The pilot's tiles are 1.42–1.58 times the line of the text they stand by (30 beside a
  17 pt body line of about 20.3, 22 beside a 13 pt line of about 15.5, 64 for an empty screen whose tile takes a
  34 pt role's line of about 41), so the side is proposed at about 1.5 lines and the glyph at about 0.6 of the side, set
  at implementation and reviewed in the snapshot matrix, as Checkbox's 1.2 was (its decisions/0001, P10). The roles:
  a row takes its title's role; a header and an empty screen set a role, or a scale, on the tile, which is the pilot's
  composition. (b) misuses `size.control.*`, the heights of controls whose usage note avoids anything else; it fits the
  rows (28 and 24) and the header (36 and 32) but not the empty screen (50 and 40 against 64 and 60); it does not grow
  with text; and an own component's `size` option is not derived yet (below). (c) invents values. The choice between
  them is open question 1.
- The corner is a quarter of the side, westron's ratio of a corner to a height (design-language/04, "About a quarter of
  the height"), and scales with the tile. A shape "whose corner scales with its own size keeps its rule in its
  contract" (04, "Off-ladder corners belong to one component"), so no radius token is bound. `radius.control`, 8 at
  every size, was considered: it is a quarter at 32 only, an eighth at 64 and a third at 24. Continuous on Apple,
  circular elsewhere (04). A rounded square, not a circle: the circle is the check's shape.

### E. Accessibility

- Role `image`, label `optional`, as Icon (its decisions/0001, "Screen readers"). Without a label the tile is hidden:
  beside its list's title it would only repeat it, and the glyph's system name ("tray") and the color name say nothing
  of the list. With a label, the list's name, it is announced as an image. No pilot use today stands without the title
  (the drag card carries it too), so the label is a guess kept for parity with Icon and for a tile without its
  title, at no cost to the generator: open question 4.
- Not interactive: no intents, no hit area. A product that makes a tile act puts it in a Button, which carries the
  target.

### F. The platforms block

- Apple: `own-component`, form `view`, `systemOptions: { scale: SwiftUI.Image.Scale }`. watchOS restricts nothing (an
  own component takes no restriction yet) and is drawn as elsewhere; what a list's tile is on the watch belongs to the
  watchOS subset, decided separately (#34). Web, Linux and Android are planned, their cells provisional as the
  conventions' are.

## What the tools derive today

Read in `tools/Sources/WestronTools/Contracts/AppleOwnComponents.swift` (`AppleComponents.Own.init`) and
`SnapshotMatrix.swift`; approving the draft to run them was not done, since approval is the gate's. The contract has
the shape Icon has: a view, an option whose values are icons (the first, unlabeled `Westron.Icon`), `scale` as a system
option (no parameter, no enum), the one slot `label` with `accessibility.label: optional` (three initializers), no states
and no restriction (a watchOS entry with only a description passes). So, approved, it generates no
`IconTile+Contract.swift` (it has no enum option of its own), the API parity lint expects `public struct IconTile: View`
with `init(_: Westron.Icon)`, `init(_: Westron.Icon, label: LocalizedStringKey)`,
`@_disfavoredOverload init<S: StringProtocol>(_: Westron.Icon, label: S)` and `public var body: some View`, and the
matrix generator writes `IconTile+Matrix.swift`, glyph down the rows and `scale` across, on a hand-written
`IconTileMatrixCell`. The list colors are no axis (they are the context's), so the twelve colors and the neutral tile are
a hand-written supplement, as the text sizes are. No tool changes.

With option (b) of D, the tools would need: `Own.init` to derive an enum option named `size` on an own view (today "a
size option: not derived yet", since a style's `size` defaults from `controlSize` and an own view has no such rule), the
conventions to say whether an own view's size reads `controlSize` or takes its contract default, the parity lint's
expectation and tests to follow; and a watchOS restriction of it would need the `offered` tables an own component lacks.

## Tokens

Every bound token exists in every mode (`tools/westron spec check`). Missing with the proposals: none. Missing with the
alternatives: a neutral solid pair (C (b)); size tokens for a tile that fit the empty screen and grow with text (D (c));
a radius token cannot express a proportion, so the quarter rule stays in the contract with any option.

## Open questions for the approver

1. **Size: from the text role, or a `size` option?** Recommended: from the text role, with `scale` (D (a)): the design
   language decides it, it grows with Dynamic Type, and the tools derive it today. The alternative, `size: [s, m, l]` on
   `size.control.*`, does not fit the empty screen, does not grow with text and needs tool work.
2. **No list color: neutral or the accent?** Recommended: neutral, `background.muted` and `text.secondary` (B (a)).
   If the accent is chosen, `accent-subtle` and `text.accent`, and the picker's "Top level" needs its own answer.
3. **Quiet or solid?** Recommended: quiet, `category.<name>.background` and `.icon` (C (a)). If chosen,
   design-language/02 and the usage notes of `color.category.<name>.control` should say that tiles take `background`
   and `icon`, not `fill`. If solid is chosen, the neutral tile needs a solid pair or the accent.
4. **The spoken label.** Recommended: keep `label` (E), for parity with Icon and a tile without its title, at no cost.
   Without it the tile is always hidden and no pilot use loses anything today.
5. **The proportions.** Recommended: about 1.5 lines for the side, 0.6 of the side for the glyph, a quarter of the side
   for the corner, settled in the snapshot matrix at the second gate, as Checkbox's were.

## Consequences

- Approved, `/implement-platform icon-tile apple` writes `WestronUI/IconTile/IconTile.swift`, its matrix cell and the
  color supplement. The doc comment of `.category(_:)` (`Category.swift`), which says nil draws the accent, then names the
  tile's neutral default as well.
- ListRow (#119), the pilot's header, picker, drag card and empty screen take `IconTile` in their compositions.
