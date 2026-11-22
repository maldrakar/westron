# 0001. The IconTile contract

Date: 2026-11-22. Status: approved on 2026-11-22 by the coordinating agent under the owner's delegation of the first
gate in phase 4 (decisions/0014, "Process"), with question 3, the fill of a list's color, open with the owner. There was
no interview: the agent answered the questions of `/new-component` from the owner's decision, the documents and the
pilot, and gave the source of each answer; the answers no source gave were the open questions below, which the
approver answered ("The approval").

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
- **Chosen: (a)** (approved, question 2). The accent marks the primary action and the selection (design-language/00,
  principle 3; 02, "One accent"); a list with no color is not selected. The pilot draws a list with no color and "Top
  level" neutral. The pair exists and is declared (`text.secondary` on `muted`, 4.74:1 in light), and `muted` is already
  "a tag or a badge without a color". The conventions let a contract choose its nil ("nil being the contract's
  default"); the doc comment of `.category(_:)` now names both defaults.

### C. The fill of a list's color: solid, with the quiet pair open with the owner

- Considered: (a) quiet: `color.category.<name>.background` with the glyph in `color.category.<name>.icon`; (b) solid:
  `color.category.<name>.fill` with the glyph in `on-fill`; (c) both, as an option.
- Both pairs are declared in `tokens/` and pass in every theme (`tools/westron tokens contrast --all`, 2026-11-22):
  (a) `icon` on `background`, non-text, 3.19–3.22 in light, 3.48–3.52 in dark, 4.79–4.85 in light-hc and 5.21–5.27 in
  dark-hc against 3 and 4.5; (b) `on-fill` on `fill`, text, at least 4.5, and 7 in high contrast.
- The agent recommended (a): the pilot's role, a calm column of twelve hues (principle 3; direction B's soft look,
  decisions/0013), the solid list color left to the checked check, and a neutral twin that exists where a neutral solid
  pair does not.
- **Implemented: (b), pending the owner (question 3).** design-language/02 and the usage notes of every
  `color.category.<name>.control` token say "tags, tiles and statuses keep `fill`", an accepted chapter of the look, so
  the approver did not settle the fill against it and asked the owner. Until they answer, a list's tile is solid; the
  neutral tile stays `background.muted` and `text.secondary` either way. The two mappings sit in one place,
  `IconTileColors` in `WestronUI/IconTile/IconTileTokens.swift`, so the owner's answer is a two-line change there and in
  the contract's description. The catalog's supplementary sheet "list colors and none" draws, under the contract's
  row, a second row captioned "quiet: open with the owner" from the same tokens, through a `package` environment value
  no product sees (`IconTileCatalogSupport.swift`), so the owner compares both in one picture; it goes once they choose.
  (c) has no pilot use (rule 6).
- A rounded square, not a circle, so a solid tile is not read as a checked disc. No line in any theme: the glyph carries
  the meaning, its pair holds in high contrast on the same ground, and a tile's edge is not information (WCAG 1.4.11
  asks it of the glyph). Surface's high-contrast line answers a shadow, which a tile does not have.

### D. Size, Dynamic Type and the corner: from the text, no size option

- Considered: (a) sized by the text role of its context, as Icon and Checkbox are, with Icon's relative `scale`;
  (b) an enum `size` (`s`, `m`, `l`) bound to `size.control.*`; (c) `size` bound to new tile tokens.
- **Chosen: (a)** (approved, question 1). design-language/07 decides it: "Inside a shape, an icon is sized by the shape
  … and the shape scales with the text beside it"; "A relative scale is the only size choice". It grows with Dynamic
  Type with the text it stands by, and follows the platform's text: the Mac's 13 pt body gives a smaller tile than the
  phone's 17 pt, as the pilot's 22 and 30 differ. (b) misuses `size.control.*`, control heights whose usage note avoids
  anything else; it does not fit the empty screen (50 and 40 against the pilot's 64 and 60), does not grow with text,
  and an own component's `size` option is not derived yet. (c) invents values.
- **The proportions** (approved, question 5, settled against the renders of 2026-11-22): the side is 1.5 times the line
  height of the role, the glyph is fitted into a square of 0.6 of the side, the corner is a quarter of the side. The
  pilot's tiles are 1.42–1.58 lines (30 beside a 17 pt line of about 20.3, 22 beside a 13 pt line of about 15.5, 64 for a
  34 pt role's line of about 41), its glyphs 0.5–0.63 of the tile. In the renders the glyph sits clear of the corners at
  every scale and role, and beside heading.large and at accessibility5 the tile reads as the line's mark, not larger
  than its title. The constants are in `IconTileMetrics`, marked `// westron-lint: allow` as Checkbox's 1.2 is.
- The corner scales with the tile: a shape "whose corner scales with its own size keeps its rule in its contract"
  (design-language/04, "Off-ladder corners belong to one component"), so no radius token is bound. `radius.control`,
  8 at every size, was considered: a quarter at 32 only, an eighth at 64 and a third at 24.

### E. Accessibility

- Role `image`, label `optional`, as Icon (its decisions/0001, "Screen readers"). Without a label the tile is hidden:
  beside its list's title it would only repeat it, and the glyph's system name ("tray") and the color name say nothing
  of the list. With a label, the list's name, it is one element announced as an image (approved, question 4: kept for
  parity with Icon and a tile without its title, though every pilot tile today stands beside its title).
- Not interactive: no intents, no hit area. A product that makes a tile act puts it in a Button, which carries the
  target.

### F. The platforms block

- Apple: `own-component`, form `view`, `systemOptions: { scale: SwiftUI.Image.Scale }`. watchOS restricts nothing (an
  own component takes no restriction yet) and is drawn as elsewhere; what a list's tile is on the watch belongs to the
  watchOS subset, decided separately (#34). Web, Linux and Android are planned, their cells provisional as the
  conventions' are.

## What the tools derive

Unchanged tools derive it, as read before the approval in `AppleOwnComponents.swift` and confirmed after it:
`tools/westron generate` wrote `WestronCatalog/Generated/IconTile+Matrix.swift` (glyph down the rows, scale across, 108
combinations on 6 sheets) and no `IconTile+Contract.swift`, since the contract has no enum option of its own; before the
view existed, `tools/westron lint api-parity` reported exactly the missing `public struct IconTile: View` with
`init(_: Westron.Icon)`, `init(_: Westron.Icon, label: LocalizedStringKey)`,
`@_disfavoredOverload init<S: StringProtocol>(_: Westron.Icon, label: S)` and `public var body: some View`.

## The implementation on Apple

- `IconTile` lays out five subviews: a hidden line of the context's text, which gives the side and the tile's text
  baseline (its middle, so a row aligned on the first baseline centers the tile on its title's line); the glyph hidden
  at the context's image scale and at medium, whose ratio is the scale's step; the shape; and the resizable glyph,
  which keeps the weight of the font in the environment, seen in the renders beside body and the Onest headings.
- The snapshot matrix's own cells stop growing at accessibility2: six rows of tiles at accessibility5 run past an
  iPhone's height, and the generated sheets take six rows to a picture for every component. The supplement "beside a
  title" grows to accessibility5.
- The in-process render on macOS (`CARenderer`) draws no icon of `ContentUnavailableView`, not even a plain `Icon`, so
  the supplement "an empty screen" is read on iOS; the catalog entry's screenshot shows it on the Mac.

## Open with the owner

3. **Quiet or solid?** The contract and the code take solid, as design-language/02 says; the catalog shows the quiet
   pair beside it. If the owner chooses quiet: the two lines of `IconTileColors`, the contract's description,
   design-language/02 and the usage notes of `color.category.<name>.control` change, and the catalog's second row and
   `IconTileCatalogSupport.swift` go.

## Consequences

- ListRow (#119), the pilot's header, picker, drag card and empty screen take `IconTile` in their compositions.
- The description of `color.background.accent-subtle` ("the tile behind an empty state's icon") no longer names a
  westron component's use; it is left as it is for a product's own composition, a token change out of this issue.
