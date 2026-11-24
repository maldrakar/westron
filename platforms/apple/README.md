# westron for Apple

A SwiftUI library for iOS, iPadOS, macOS and watchOS. The package manifest lives at the repository root.

| Path | What is there |
|---|---|
| `Sources/WestronTokens/` | Token values as plain Swift with no imports, for a product's shared code and its WebAssembly build |
| `Sources/WestronUI/` | Styles, components and the SwiftUI accessors of the tokens: what products import |
| `Sources/WestronCatalog/` | Catalog entries, their host and launch arguments |
| `Tests/` | Package tests (Swift Testing); `Tests/WestronSnapshotTests/` renders the snapshot matrix, on iOS inside the catalog app |
| `Snapshots/` | The snapshot matrix's references, recorded on the CI runner (PNGs in Git LFS) |
| `Catalog/` | Catalog app for iOS and macOS and its UI tests: screenshots, the accessibility audit and behaviour |

## Adding the package

```swift
.package(url: "https://github.com/maldrakar/westron", from: "0.1.0")
// …
.product(name: "WestronUI", package: "westron")       // views
.product(name: "WestronTokens", package: "westron")   // shared code that must not import SwiftUI
```

## Tokens

`tools/westron generate` writes them from `tokens/westron.resolver.json` (decisions/0010); the generated files are
`Sources/WestronTokens/Generated/`, `Sources/WestronUI/Generated/` and `Sources/WestronUI/Tokens.xcassets`, and are not
edited by hand. Only semantic tokens are exposed. A Swift name follows the token path, a member per segment, without
the group the type already names, and a group is an enum: `color.text.secondary` is `Westron.Color.text.secondary`.
A step joins its ladder: `space.100` is `.space100`.

```swift
import WestronUI   // re-exports WestronTokens

Text(list.name)
    .textRole(.heading.small)                     // typography.heading.small: Onest SemiBold in the headline style
    .foregroundStyle(list.color.text)             // color.category.<name>.text, by the name the store keeps
    .padding(.space.card)                         // space.card: a card's padding, the rhythm's role (16 pt)
    .surface(.raised)                             // a card: background.surface, radius.card, shadow.raised
withAnimation(.move) { reorder(task) }            // motion.move: its spring

let color = Westron.Category(rawValue: stored) ?? .blue   // shared code: WestronTokens alone
let ink = Westron.Color.text.primary.dark                 // Westron.RGB(hex: 0xD7DFEA)
```

- Colors come from colorsets with four variants (any, dark, high contrast, dark with high contrast), so they switch
  with the system and with the SwiftUI environment. watchOS asset catalogs take no appearances, so the watch gets the
  dark theme alone, whatever its contrast setting.
- A view passes a `Westron.Color` straight to `foregroundStyle`, `background`, `fill`, `stroke`, `strokeBorder` and
  `tint`, which WestronUI overloads for it; any other call takes `Color(.text.primary)`.
- Text roles are taken with `.textRole(_:)` or `Font(_:)`, in the role's text style, so they follow Dynamic Type:
  Onest and Geist Mono through `Font.custom(_:size:relativeTo:)`, the rest `Font.system` (decisions/0011). `Font` has
  no westron statics, so SwiftUI's `Font.body` stays as it is. `.textRole(_:)` on a view also tracks by the role's
  share of the drawn size and takes the heavier Onest or Geist Mono under Bold Text; its `Text` twin, for a part inside
  interpolation or `Text + Text`, cannot read the environment, so it keeps the default size's tracking and the role's
  own weight. Inside interpolation, type a part whose role is a variable as `Text` first
  (`let part: Text = Text(count).textRole(role)`): otherwise it takes the View modifier and prints a debug description,
  and the compiler warns that `appendInterpolation` is deprecated (spec/components/text).
- Motions with a spring are `.spring(duration:bounce:)`; the others are `.timingCurve`, and `.delay` when they wait.
- The adapters from WestronTokens values to SwiftUI values are hand-written in `Sources/WestronUI/TokenAdapters.swift`.

## Icons

`tools/westron generate` also writes the icons from their registry, `spec/icons/icons.yaml` (decisions/0011):
`Westron.Icon` in `WestronTokens`, a `String`-backed enum of westron's names, and in `WestronUI` the SF Symbol of each.

```swift
let icon = Westron.Icon(rawValue: list.icon) ?? .fallback   // by the name the store keeps; bullets when unknown

Icon(icon)                                        // its SF Symbol, which takes the font of the text it goes with;
    .textRole(.body.regular)                      // decorative: hidden from assistive technology
    .foregroundStyle(list.color.icon)             // color.category.<name>.icon (design-language/07)
Icon(.sun, label: "Today")                        // a meaningful standalone icon: an image labeled Today
Icon(.chevron).imageScale(.small)                 // the system's relative scale
Label("Rename", icon: .pen)                       // as Label(_:systemImage:): the system reads it as it decides
Button { add() } label: { Icon(.plus, label: "Add task") }   // an icon-only control: the label names it
Text("\(Image(.flag)) Yesterday")                 // an Image where only an Image fits; it keeps the system's name,
    .accessibilityLabel("Flagged, yesterday")     // so the text says what the line means
Button("Add", systemImage: Westron.Icon.plus.systemName) { add() }   // any call that takes systemImage:
```

`Icon` is the component (spec/components/icon): an `Image` of an SF Symbol always carries the system's spoken name of
the symbol, which SwiftUI cannot hide or replace on an `Image`, so a standalone icon is `Icon`, not `Image`.
A label built by hand, `Label { Text(list.title) } icon: { Icon(.folder) }`, must not go inside a system `Menu`: there
the item becomes a cell assistive technology cannot reach (spec/components/icon, decisions/0001; held by
`IconAccessibilityTests.testMenuItemsBuiltFromLabels`), so a menu item is `Label("Rename", icon: .pen)`.

## Package tests

The unit tests in `Tests/` (Swift Testing) run on two platforms, both in CI's `apple` job and in
`tools/apple/check.sh all`:

```sh
tools/apple/check.sh package       # swift build + swift test, on macOS
tools/apple/check.sh package-ios   # the same tests through xcodebuild on the iOS simulator
```

On the simulator they take the iOS branches of the code, which macOS never reaches: the loading indicator's
(`ButtonProgressTests`) and a hosted button's layout (`ButtonLabelKindTests`). `package-ios` boots `iPhone 17` (or
`$WESTRON_SIM_DEVICE`) if it is not running, builds into `.build/xcode/package`, writes the log to
`.build/logs/package-ios.log` and prints each failure with its message and the totals of each test target ("Test run
with <n> tests in <m> suites passed"); `ButtonShortcutTests` is macOS-only, so iOS runs fewer. `all` includes it
although it needs a simulator: an incremental run takes about 12 s locally, and an iOS-only failure should stop the
same command that stops a macOS one. Only the accessibility audit, half an hour long, stays out of `all`.

## One run at a time: the simulator and the screen

Several agents run these scripts on one Mac at once, each in a worktree of its own, and two test runs on one simulator
fail or stall each other, as a macOS UI test captures whatever window is on top (#107). So `check.sh package-ios`,
`a11y` and `behavior`, `catalog-screenshot.sh` and the iOS render of `snapshot-matrix.sh` take a lock on what they use
alone, the simulator (by its UDID) or, on macOS, the Mac's screen, after their build and until they exit (`package-ios`
until its tests end, so that `all` goes on without it; `tools/apple/lock.sh`). A run that finds it held prints once whom
it waits for (pid, command and folder, since when) and waits, at most `WESTRON_LOCK_TIMEOUT` seconds (default 5400, 90
minutes: above the longest CI limit on work that takes the lock, the pull request audit's 55 (the iOS render's step
has 45), with room for a longer local audit), then fails saying who still holds it. With
nobody else running it waits for nothing. A lock whose process died is taken over at once: one killed with SIGKILL, or
stopped by Ctrl-C while bash 3.2 waited for a foreground command, which ends it without its EXIT trap. A script under
one that holds the lock goes on. The macOS render of the snapshot matrix draws in a window that is never ordered in, so
it takes no lock. The lock serializes these scripts only: a person using the screen still spoils a macOS capture. The
locks are symbolic links in the user's temporary folder, `$(getconf DARWIN_USER_TEMP_DIR)westron-locks/`, shared by
every worktree and session. `tools/apple/lock-test.sh` tests the helper without a simulator, on macOS or Linux
(`tools/check.sh locks`, so CI runs it).

## Catalog

Open in Xcode 27.1: `platforms/apple/Catalog/Catalog.xcodeproj`. Without arguments, the catalog shows navigation
across all entries. With `-WestronEntry <id>`, it shows one entry full screen; this is how
`tools/apple/catalog-screenshot.sh` captures it. `-WestronAppearance light|dark`, `-WestronContrast standard|high` and
`-WestronDynamicType <size>` set the conditions, and `-WestronLegibilityWeight regular|bold` the system's Bold Text;
`-WestronScrollAnchor <0…1>` holds a point of the entry's scroll content in view (the accessibility audit uses it).
`catalog-screenshot.sh` has no option for the last two: the screenshot test reads them from
`TEST_RUNNER_WESTRON_LEGIBILITY_WEIGHT` and `TEST_RUNNER_WESTRON_SCROLL_ANCHOR`, set before the script, with `--out`,
since the file name does not show them. The test runner inherits them from the environment: set them on the command
only, as below; an exported value silently applies to every later capture, and nothing in its file name says so.

```sh
TEST_RUNNER_WESTRON_LEGIBILITY_WEIGHT=bold tools/apple/catalog-screenshot.sh ios --entry typography-in-text \
  --out .build/screenshots/ios-typography-in-text-bold.png
```

The Foundations section holds the token samples, each fitting one screenshot on an iPhone 17 and in the macOS window:
`color-backgrounds` and `color-foregrounds` draw every color in the four themes side by side, each cell under its own
color scheme and contrast; `color-categories` draws the list colors and `color-status` the statuses and the chart
series in the catalog's theme; `color-in-use` draws a task list, a table of deployments, notices and buttons with the
semantic colors, the page the owner approves the palette on; `typography` draws the text roles, and
`typography-in-text` each role in Onest or Geist Mono through `.textRole(_:)` beside its `Text` twin inside
interpolation, with the width each takes, so that accessibility5 and Bold Text show what the twin does not follow;
`space`, `shape` and `motion` show the rest, and `icons` draws every icon with its name at the size of body text. To
review the colors in every mode:

```sh
tools/apple/catalog-screenshot.sh ios --entry color-in-use --appearance dark --contrast high
```

### Snapshot matrix

The owner approves a component's look from its snapshot matrix (decisions/0005, the second gate; #24). `tools/westron
generate` writes it from each approved contract into `Sources/WestronCatalog/Generated/<Component>+Matrix.swift`:
every option's values (a bool as `false` and `true`, an option that is the system's own API such as Button's `role`
included, and for an option whose values are tokens the group's tokens in token order, Text's seventeen roles),
rest and each state alone, the combinations a constraint of severity `error` leaves out, what each Apple OS draws
differently (`platforms.apple`), and the sheets. A sheet fixes every option but the variant (or, without one, the first
option that is not a bool): its values are the columns, rest and the states the rows, at most 3 × 6, which fits the
macOS window and, in most sheets, an iPhone 17 in portrait at the default text size; a sheet whose cells do not fit
side by side is captured in parts (below, "Text sizes"). Text, with no states, has six sheets of one row: five of three roles each, and the last of two.
Surface has two sheets of one row, the three kinds with `outlined` false and true; Rule one, both axes. Icon, with no
states and an option whose values are icons, runs the registry's glyphs down the rows, six to a sheet, and its
`scale` across: six sheets (spec/conventions.md, "Own components").
The hand-written `<Component>MatrixCell` (Button's is in `Components/ButtonPages.swift`, Text's in
`Components/TextPages.swift`) draws one cell with the real component: Button's with hover, focus and pressed forced
as on the `button-states` pages, disabled and loading with the real modifiers; Text's with `.textRole(_:)`; Surface's
(`Components/SurfacePages.swift`) with `.surface(_:outlined:)` around sample content, a plain surface on the canvas
and an outlined one on a fill (a raised or dragged one in a sunken well, a sunken one in a raised card); Rule's
(`Components/RulePages.swift`) between two lines or two words; Icon's, Checkbox's, Chip's, Text field's, IconTile's,
ListRow's and Disclosure's in `Components/IconPages.swift`, `CheckboxPages.swift`, `ChipPages.swift`,
`TextFieldPages.swift`, `IconTilePages.swift`, `ListRowPages.swift` and `DisclosurePages.swift`; Chip's draws each
of its forms on sheets of its own, in the states the form enters; ListRow's draws the sample row at level 1, in its
form, and Disclosure's a group with a text label, collapsed unless the state is expanded. The rows of a state the OS never
enters are left out, as on those pages; a value the OS does not offer is drawn with its fallback and marked, and a
combination a `warning` constraint advises against is drawn with a caption. A state no token binding names in a case looks as rest,
and the sheet and the review page say so: Button's focus, whose ring the system draws. The sheets are not catalog
entries, so the accessibility audit does not walk them; `-WestronMatrixSheet <component>.<sheet>` shows one.

Two additions are the catalog's, hand-written, and the generator knows nothing of them (#72), so the contract alone
still drives every generated sheet and combination:

- **Text sizes.** Every sheet is captured in the four themes at the default text size, `large`, and in the light theme
  at the smallest, `xSmall`, and the largest accessibility size, `accessibility5` (the audit's;
  `ComponentMatrix.TextSize`). Only the cells follow the text size; the sheet's title, notes and the names of columns
  and rows stay at `large`, and the sheet says so. At `accessibility5` a 3 × 6 sheet does not fit an iPhone: a button of
  size l with an icon and a label takes about 320 of its 402 points. So there a sheet is captured in parts, one column
  each (`pictures(of:at:)`, `_part-<n>-of-<count>` in the file name), with a short header that says what the part holds.
  The parts are laid out for the default device, iPhone 17 in portrait, which six rows just fit: on another device
  (`--device`), a shorter one above all, the capture may fail its check that every cell is inside the picture there.
  At every text size a sheet is also split where its cells do not fit side by side: the snapshot test draws the
  sheet, and when a cell is narrower than its ideal width ("squeezed"), it takes a column fewer to a picture and draws
  it again, down to one column, and keeps that split for the other themes at that text size
  (`pictures(of:at:columns:)`, SnapshotMatrixRenderTests `columnsPerPicture`; the columns go as evenly as they can, so
  a part's name tells its columns and `-WestronMatrixSheet` finds it). The Button contract leaves a width below the
  label's longest word unsupported: the product provides the room, so a sheet must too. On an iPhone 17 at `large`
  four sheets need it, Button's `size-l_role-destructive_iconOnly-false` and its supplement's
  `label-without-icon_size-l_role-destructive_iconOnly-false`, each also with `_floating-true` (a
  button of size l with "Delete" and an icon, or with the loading indicator, needs about 122 points of a column's 112),
  each two parts, primary and secondary, then tertiary. Such a part's header says what it holds and why, and leaves the notes to the review page, as a supplement's
  sheet with its notes all but fills the screen. A squeeze that fewer columns to a picture cure does not fail the run:
  the sheet is split, which shows as pictures added and removed in `compare` and in CI's `snapshots` check against the
  references; the run fails only when a cell is still squeezed with one column to a picture. A cell that takes the
  width it is offered by design, running text that wraps between its words (Text's roles, a surface's sample) or a
  field that fills its row (Text field's cells), is marked with `matrixCellTakesOfferedWidth()` and not checked so:
  for Text's roles and a surface's sample text a word that breaks inside itself, and for a text field a truncated
  placeholder or value, is not caught by the check and is left to the eye in the review.
  macOS has no Dynamic Type: SwiftUI draws a cell the same at every `dynamicTypeSize` there, `-WestronDynamicType`
  included (`ComponentMatrixTests` checks it), so a Mac is captured at `large` alone and its page says why.
- **Supplementary sheets** show what no contract option sets. A component's catalog code adds a
  `ComponentMatrix.Supplement` to `Supplement.all`: the option values it keeps and a cell of its own. Its sheets are
  the generated sheets that keep those values, with their axes, states and rows, so nothing the contract lists is
  listed again by hand. Each sheet and its section of the review page are marked "Not a contract option". Over a
  matrix whose rows are icons, a supplement keeps a few of them (`rows`), on one sheet. Where its cell is taller than
  a generated one, `rowsPerPicture` caps the rows of one picture at a text size that splits sheets
  (`accessibility5`); `splitsAtEverySize` splits its sheets into pictures of that many rows at every text size, and
  `columnsPerPicture` caps a picture's columns where the cells are wide. `ComponentMatrix.rowsAtLimit` caps the
  generated sheets of a component whose cells grow tall at the splitting size (ListRow, one row a picture). A
  supplement whose render on one OS is not worth reading, or not the same twice, names the OSes it is drawn on
  (`onlyOn`), and its note says why. One that must still be drawn there for the reviewer, but whose pixels the OS
  does not repeat from one render to the next, names that OS in `notCompared` with the reason: its pictures there are
  rendered and shown, and `compare`, `check` and `record` hold them to their presence and size, not their pixels
  (below, "Comparing"). There are forty-four (`SnapshotMatrix/Supplements.swift`, `Supplement.all`):
  - Button, `label-without-icon`: its generated cells have an icon and a label or are icon-only, so a label without an
    icon, which while loading has the indicator before the label and widens the button (P13), is shown on the sheets
    with iconOnly false: every variant, size and role, floating or not, at rest and in each state, but what the
    constraints forbid, 162 combinations on 12 sheets. `floating-on-glass` and `floating-on-glass-inverse` (#121,
    decisions/0015): every floating sheet of the default role, sizes s, m and l, with a label and icon-only, primary
    and secondary, at rest and in each state, on the system's glass, over a fixed busy ground of four list colors'
    stripes and over a band of `text.primary`'s color, dark in the light themes and light in the dark ones (Q5's
    test), three rows to a picture at every text size; tertiary, which does not float, is left out (`columns`).
  - Button's generated `_floating-true` sheets draw the bindings, the look where there is no glass (before OS 26), on
    every OS: the catalog's matrix cell sets `drawingButtonsWithoutGlass()`, `package` in WestronUI, and each such
    sheet's header says so (`ComponentMatrix.SheetNote`). Glass on the plain canvas differed now and then by a pixel
    from one iOS render to the next, so the system's glass is only in the two supplements above. On this Mac's iOS
    26.3 their renders were the same every time, but on the CI runner's iOS 27 they were not (a few levels over large
    areas between two runs of one commit), so on iOS both are `notCompared`: drawn and shown, not compared pixel by
    pixel. On macOS they are compared as every other picture (decisions/0015, "what was measured" and the note of
    2026-11-24). The option `floating` is named in no sheet's id or title at its default (`nameInMatrixAtDefault: false` in the contract), so every sheet that does not float keeps the
    name, the title and the pixels it had before the option.
  - Icon, `beside-text`: three glyphs, each beside text in four roles (one row to a picture at `accessibility5`); and
    `color-roles`: six glyphs in the color roles of design-language/07 (three rows to a picture there).
  - Surface, `nesting`, on the sheet with outlined true: for raised and dragged, two outlined cards of the kind in a
    sunken column; for sunken, an outlined well in a raised card.
  - Checkbox, `list-colors`: the twelve list colors through `.category(_:)` (three rows to a picture at
    `accessibility5`); and `text-roles`: a task's check and a subtask's beside labels of their roles.
  - Text field, at size m: `card-notes`, a card's title and multiline notes (two rows to a picture at
    `accessibility5`); `secure-field`, the style on `SecureField`; `on-surface` and `on-sunken`, a field on those
    grounds. Its glyphs (#115), optional options and so no axis of the generated matrix: at every size,
    `glyph-leading`, `glyph-trailing` and `glyphs-both`, the generated cells again with the magnifier at the start, a
    number sign at the end, or both (one row to a picture at `accessibility5`); at size m, `glyphs-long-text` and
    `glyphs-right-to-left`, a text longer than the field reaching the glyph at its end, left to right and in Hebrew;
    and at size m on one line, on iOS only, `search-prompt`, an empty search field with its prompt in
    `text.placeholder` (macOS ignores a prompt's colour).
  - Rule, `labelled`, on the sheet with purpose separator: a short label, a long one truncated and a rule with none,
    each above a row; a vertical rule takes no label.
  - IconTile, over the glyph folder or tray: `list-colors`, neutral and the twelve list colors; `beside-title`, a tile
    beside titles in four roles, growing to `accessibility5`; and `empty-screen`, on iOS only, the tile in the
    system's `ContentUnavailableView` (macOS draws no icon there and places its words differently from one render to
    the next).
  - Chip, on the selectable form: `lit`, a chip lit in the accent in each state, which under the pointer and pressed
    holds two states at once; `list-colors-1` to `list-colors-4`, the twelve list colors lit, three to a sheet; on
    each control, `text-only-selectable` and `text-only-pressable`, a label that is only text, short and truncated; and
    in every form, `long-label`, a long label in a narrow place.
  - ListRow, nine: `selected`, the selected row's bar in every state and theme, also beside a title whose role the
    product set; `tree`, rows at levels 0 to 3 with their guides; `slots`, a row with a second line, a leading icon
    and a trailing count; `task`, a static row with a check in its leading slot; `long-title`, a title on one line
    truncated at level 4; `drag`, the insertion mark at a level, drawn above the next row's highlight, and a drop
    target; `right-to-left`, the slots, indent, guides and bar mirrored; `accessibility5`, the trailing slot under
    the text at level 0; and `composition`, the lists screen's rows as the pilot composes them: IconTiles at the
    start, a count and a static Chip at the end, then the same as a Disclosure branch with a leaf and a collapsed
    branch whose row is disabled alone, guides on only. Every one but `composition` is drawn at every text size of the sheet, accessibility5
    included, where the row's horizontal spacing stops at its xxxLarge width (spec/components/list-row,
    decisions/0001, D2); `composition` stops at xxxLarge, as Disclosure's `tree` does, since five rows with their
    trailing slots stacked are taller than a phone's screen at accessibility5. The branches in `slots`,
    `right-to-left`, `accessibility5` and `composition` draw the real Disclosure chevron (#120).
  - Disclosure, five, on iOS and macOS only (SwiftUI has no DisclosureGroup on watchOS): `expanded`, expanded in each
    state; `right-to-left`, collapsed and expanded; `tree`, three levels of ListRows with `.disclosureAlignsLeaves()`;
    `block-header`, a title with its date over two rows with checks; and `accessibility5`, a label that wraps at
    accessibility5, the chevron on its first line.

  Like the matrix, supplements are not catalog entries, so the accessibility audit does not walk them.

```sh
tools/apple/snapshot-matrix.sh ios                       # or macos; --component button,rule for some components
tools/apple/snapshot-matrix.sh compare <before> <after>  # exit 0 when every image is the same, 1 otherwise; a
                                                         # supplement's not-compared pictures (glass on iOS) count
                                                         # by presence and size only; --strict compares them too
tools/apple/snapshot-matrix.sh check ios                 # against the references: 0 same, 1 changed, 3 none yet,
                                                         # 4 another environment (locally, always)
tools/apple/snapshot-matrix.sh record ios                # on CI only (snapshot-references.yml)
```

**Rendering** (#92, decisions/0008, the note of 2026-11-21). Unit tests draw the matrix in-process:
`Tests/WestronSnapshotTests`, one source compiled twice, as the package test target `WestronSnapshotTests` on macOS
(`swift test`) and as `CatalogSnapshotTests`, a unit-test bundle in the catalog project hosted by the catalog app, on
the iOS simulator (the project takes the same folder; without a host app iOS draws nothing). Each picture is the
catalog's own view for `-WestronMatrixSheet` with the capture's launch arguments (`CatalogRootView`), so the theme, the
contrast and the text size are applied as in the app, in light, dark, light-hc and dark-hc at `large`, and on iOS light
at `xSmall` and `accessibility5`. On iOS a window in the app's scene, over the app's own, is drawn with
`drawHierarchy(in:afterScreenUpdates:)`; on macOS a borderless window that is never ordered in, with its backing scale
fixed at 2 whatever the screens', is drawn by Core Animation's renderer (`CARenderer`) into a Metal texture.
`ImageRenderer`, `cacheDisplay` and `CALayer.render(in:)` misdraw system controls, so none of them is used. Core
Animation is frozen in the sheet's window as before, so a spinner draws one frame. The sheet reports its layout to
the tests through `MatrixSheetProbe`, an environment value only they set: the frame of its content and of each cell,
and each cell's ideal width, measured on a hidden copy of the cell behind it, which draws nothing.
The picture is cut to the content: the window's width, from the top of the sheet (under the status bar's safe area on
iOS; no status bar or home indicator is drawn) down to its bottom and the reach of the deepest shadow token below it
(`shadow.dragged`, 56 pt), as far as the window goes; it is opaque RGB. A picture fails by name when a cell lies
outside the window on either axis ("cut off" on the page), when a cell is drawn narrower than its ideal width even
one column to a picture ("squeezed", with the cells and their widths in the issue), when a cell draws nothing (the
drawn cells are counted against the matrix), or when four draws give no complete picture: a draw with no frame reported, `drawHierarchy`
returning false, or fewer than three colors is taken again with a longer pause, and a retry, or on iOS a draw slower
than 1.5 s, is taken twice and must agree pixel for pixel (on macOS `CARenderer` draws in the process, with no render
server to cut a draw short, so a slow draw there is only slow). Between draws, and while a sheet settles, the test gives the
main thread back to its run loop, so that UIKit and SwiftUI release each picture's window and controller; without
that, every window stayed alive and the CI runner drew the last pictures of the run blank (decisions/0008, the note
of 2026-11-21). On macOS some CI runs drew text-field pictures otherwise than every other run of the same code
(#99, runs 44885247356 and 44917113978). A probe on the runner (run 44932481160) caught the state: SwiftUI laid out the
AppKit text field under a `TextField` 1 pt off the height AppKit itself gives for it (17 pt where the field's
`intrinsicContentSize` and `cell.cellSize` say 16; on another runner 16 for a field in Onest whose line is 17). **The
mechanism** (`MeasuredFonts.swift` has it in full, with the evidence): SwiftUI takes a field's line height from a cache
of the three fonts looked up last, keyed by the address of the font object it measures the line with; when SwiftUI's
font cache lets that font go, it is freed, a font made later may be allocated at its address, and while the old entry
is among the three the new font takes its height. Shown: the internals, by symbol lookup and disassembly in the SwiftUI
framework of this Mac's macOS 26.7.1, the one a process runs (Xcode's SDK holds only `SwiftUI.tbd`, which does not
export them; the runner's macOS 27.0.1 SwiftUI was not disassembled, and there the traces and the forcing test show the
mechanism); the state forced by a test, locally and on the runner; on the runner without the fix, the state arising by
itself in 13 of 443 short processes, 12 of them with a trace showing exactly this (run 44942981800); and with the fix,
the same short-process loop on the runner (probe run 44948217745) with 0 of 458 processes in the state (27,680
pictures). Inferred: that the two CI failures, which had no trace, were this. **The fix**: `MeasuredFonts` keeps alive,
for the rest of the render's process, every font object whose line a layout manager measures, from before the first
picture is laid out, so no font can take an address the cache knows. **The forcing test**,
`fieldsKeepTheirLineThroughFontChurn` (`FieldLineHeightTests.swift`), runs in every macOS render, `--component` ones and
the workflow Snapshot references too (about 8 s locally, 21 to 35 s on the runner); it checks that every field keeps its
own height and that the font SwiftUI measures each field's line with is one `MeasuredFonts` keeps; its line in the log,
`snapshot: font churn (#99)`, gives the attempts, the fields off their line and the fonts kept, and the script prints it
too, so it is in the output of the CI job `snapshots`. With the fix on it cannot show that the forcing still forces;
after an update of Xcode or macOS run it without the fix, which must fail it:
`WESTRON_FONT_CHURN_UNFIXED=1 WESTRON_SNAPSHOTS=.build/font-churn swift test --filter fieldsKeepTheirLine`. Products
are not covered: the same SwiftUI behaviour can lay out a product's `TextField` off its line (#113). Checks still name
the state, so that if it ever shows again it does not read as a change to a pull request. **The fields' heights**
(`FieldHeights`): after each picture's layout and before its draw, the test walks the window's views and compares
every AppKit text field's
laid-out height with AppKit's own for it, its cell's size at the field's width (`cell.cellSize(forBounds:)`) and, for
a field that does not wrap, its `intrinsicContentSize`; a field off by more than half a pixel fails the picture with
the issue "the render was in the state of #99", which gives the picture, how far into the run, and each field's frame,
sizes, font (with its ascender, descender and leading) and text or prompt. The picture is still written and compared
as usual. Over the full matrix in the normal state every field agrees: 432 fields in the 40 text-field pictures of
the run's 196 (one-line, empty with a prompt, `SecureField`, multi-line of one and two lines, at every size), and 48
in the 4 text-field pictures among the 28 drawn again at the end, which go through the check too. The log gives both
counts, apart, in one line (`snapshot: text fields' laid-out heights against AppKit's (#99)`), after the pictures
drawn again (`snapshot: drawn again at the end`) and before the text metrics at the end and the count of images that
closes the log; the script prints that line too, so it is in the output of the CI job `snapshots`, where the log is
not. An `NSTextView` is not checked (the
matrix has none), nor a multi-line field past its `lineLimit`, which would be laid out shorter than its lines by
design (the matrix has none either; one added would fail the check until exempted). Its unit tests,
`FieldHeightsTests`, run in `swift test`. **The language.** The test pins the process's language and locale
(`AppleLanguages` `en`, `AppleLocale` `en_US`, in its argument domain, as `-testLanguage en -testRegion en_US` does on
iOS), since AppKit measures a line of text by the languages, a proven dependency but not #99's explanation; the log
has the languages and locale the process had before the pin (`snapshot: languages before the pin`) and the text
metrics at the start and the end (`snapshot: text metrics`), and a picture fails, named, when a fresh AppKit field
cell measures a line of body text otherwise than at the start of the run (the issue "drawn while the process measured
text otherwise than at the start of the run"). That names a change of the process's text metrics, not #99's state, in
which a fresh cell measures as usual (run 44917113978 logged 16 pt at its start and end). **Drawn again**: each
component's first picture in each capture is drawn again at the end and must give the same pixels, within a level
(`snapshot: drawn again at the end`): a state that ends within the run fails it; one that lasts to the end, as #99's
did in run 44917113978, passes it. Each failure logs the process's state then (`snapshot: state`: the metrics, the languages, the
capture's theme and the app's appearance, the accessibility display options, the key window and first responder, the
time into the run). The matrix's tests run only when `WESTRON_SNAPSHOTS` names the output directory (on the simulator through
`TEST_RUNNER_WESTRON_SNAPSHOTS`), so `swift test` and `tools/apple/check.sh package` skip them;
`WESTRON_SNAPSHOTS_COMPONENT` takes some components.

The script builds the tests incrementally, runs them (`swift test --filter WestronSnapshotTests` on macOS; on iOS one
`xcodebuild test-without-building -only-testing:CatalogSnapshotTests -testLanguage en -testRegion en_US` on `iPhone
17` or `$WESTRON_SIM_DEVICE`), and writes to `.build/snapshot-matrix/<platform>/` (`--out` to change it) the PNGs,
`<component>.<sheet>[_part-<n>-of-<count>].<theme>.png` at `large` and
`<component>.<sheet>[_part-<n>-of-<count>].light.<text size>.png` at the others, the manifest `matrix.json`, `environment.json` and the review page `index.html` (sheets down; across, each
text size with its themes, the parts of a sheet side by side; the supplements in sections of their own; with the
environment and each picture's size). It prints the images per component, the build and render times and the page's
path, and fails when a picture failed or is missing. The log, `.build/logs/snapshot-matrix-<platform>.log`, has a
line per picture with its time, the process's memory and its windows (`snapshot: <file> 0.091 s, 90 MB, 1 windows`),
and a line with each draw's outcome for a picture that took more than one (`snapshot: <file> draws: #1 blank (1
color) after 8.02 s; #2 drawn in 0.31 s, the same again in 0.30 s`). Locally (an M4 Pro, macOS 26.7.1, the iPhone 17 simulator on iOS 26.3.1) the 396 iOS images render in
46 s and the 196 macOS images in 13 s; two renders of one commit were byte-identical. On the CI runner, a 3-core VM,
the spike of 2026-11-20 measured 0.85 s an iOS image and 1.1 s a macOS one.

**Comparing.** `compare <before> <after>` compares two directories image by image and writes `before/`, `after/`,
`diff/` and its `index.html` to `.build/snapshot-matrix/compare/` (`--out` to change it): each changed image with the
two pictures and a diff (the pixels beyond the tolerance red, those within it amber, over the new picture faded), the
added and removed ones, and the changed components named. A pixel whose every channel differs by at most one level
counts as the same (`--tolerance <n>`): within one environment, renders have drifted by a level in a few pixels of a
shadow or an edge. Compare only renders from the same environment (decisions/0008): every image differs between this
Mac and the runner, in text and symbol anti-aliasing.
A picture of a supplement that is `notCompared` on the render's OS (the manifest's group carries the reason, and a
mark in either directory's `matrix.json` counts) is not compared pixel by pixel: it is listed in its own section,
"Not compared", with its reason and both pictures, counted on the summary line (`…; 168 not compared`), and never
makes the exit status 1. Its presence and its size still count: a missing one is removed, an unexpected one added, a
size that changed a change, each failing as for any picture. `--strict` compares them too. A larger tolerance is not
the answer for such pictures: the system's glass on the iOS simulator varies by an amount nobody bounds (a tone flip
exceeds any), and a tolerance would hide real changes while still failing at random.

**References and the check.** `Snapshots/<platform>/` holds the references, the PNGs in Git LFS, and
`environment.json`: the Mac's macOS and processor, Xcode, on iOS the simulator's runtime and device, the scale, the
number of images (`Snapshots/README.md`). They are recorded on the CI runner only, by
`.github/workflows/snapshot-references.yml`. `check <platform>` renders (or takes `--from <dir>`) and compares with them into
`.build/snapshot-matrix/check-<platform>/`; with no references yet it exits 3, and in another environment it says what
differs and exits 4 without comparing: on your Mac that is the usual outcome, so render before and after your change
and `compare` them. `record <platform>` writes a render into the references, keeping a reference within the tolerance
of its new picture, so a drift does not rewrite it; in another environment (or over no references) only the same
pixels keep one. A not-compared picture's reference is kept as it was in the same environment while its size holds,
whatever its pixels, and replaced only when its size changes: it marks that the picture exists, and recording does not
rewrite it on every run. So it shows the picture as first recorded in that environment, not kept current; the report
captions it so. In another environment it is held to the same pixels as any other, so recording for a new runner image
replaces it and it never shows an older OS's look. Both refuse a render with a failed picture (exit 1, naming it):
a missing PNG would read as a removed sheet, and `record` would delete its reference. `.lfsconfig` keeps the references out of what Git LFS fetches by
default (they would be pointers in a clone; `git lfs pull --include "platforms/apple/Snapshots/**" --exclude ""` gets
them).

**CI.** The job `snapshots` in `ci.yml` renders both platforms on every pull request and push to `main`, pulls the
references through a cache of `.git/lfs`, and checks: a difference fails it and uploads `snapshot-diff`, the report;
no references, or references from another runner image, pass on a pull request with a warning that they need
recording, and fail a push to `main`. Every run
uploads `snapshot-matrix`, the full page of both platforms. A look that changes on purpose is recorded with the label
`record-snapshots` on the pull request; the workflow commits the references to its branch and comments how to run the
checks again (a commit pushed by a workflow starts none). In both workflows the macOS render has a step timeout of 40
minutes and the iOS one 45, and the jobs 100 (`snapshots`) and 105 (the recording); the render costs about 1 s an image
on macOS on the runner (636 images in 771 s after a 117 s build, 2026-11-23) and about 0.4 s on iOS, so raise a step's
timeout when its build and images come within about two thirds of it (the arithmetic is in `ci.yml`'s comment).

### Behaviour UI tests

`ButtonBehaviorTests`, `CheckboxBehaviorTests`, `TextFieldBehaviorTests`, `TextFieldAccessibilityFrameTests`,
`IconAccessibilityTests`, `IconTileAccessibilityTests`, `ChipBehaviorTests`, `ListRowBehaviorTests` and
`DisclosureBehaviorTests`, in `Catalog/CatalogUITests`, check on
the catalog's entries what a unit test cannot reach: presses, hit areas and hover, the accessibility hierarchy, the
keyboard. Each class has branches of its own for iOS and macOS where the platforms differ. `tools/apple/check.sh
behavior` runs them, like the audit: the build first, a step of its own, then one `xcodebuild test-without-building`
for the classes named (all nine by default); it prints each failure with its message, each skip with its reason, the
test cases and the totals, and stops the simulator's test daemon afterwards. The log goes to
`.build/logs/behavior-<platform>[-<classes>].log`, the result bundle to `.build/xcode/results/`.

A run whose log gains no line for `WESTRON_BEHAVIOR_STALL_LIMIT` seconds (default 300; xcodebuild's own `[MT]`
messages do not count) has stopped making progress: the script stops it, says so in its output and the log, and
retries (#97). On CI the simulator once failed to terminate the catalog and xcodebuild then wrote nothing for 28
minutes (run 44863177076). The retry is one more `xcodebuild test-without-building` of the same classes, with
`-skip-testing` for every test that passed or skipped itself, so the test the stall hit runs again, as an audit
entry a stall hit does; its log and result bundle get `-retry` in their names. It runs too when the test runner
failed to start, or when a test's only failure is XCTest's "Failed to terminate" of the catalog. It never runs when
XCTest reported a failure of a test's own, an error line for it (an assertion, a crash it attributes to the test) or
its `Test Case … failed` line: the leg fails. A test that never finished, because the run stalled or the test runner
died under it with neither line for the test, is run again by a retry, as the audit does for an entry it did not
finish. There is one retry at most, a warning on the CI run
shows it, and a retry that would not finish before the deadline is not started. `WESTRON_BEHAVIOR_DEADLINE=<minutes>`
from the script's start stops everything, a retry included, at that time (xcodebuild and the test daemon stopped, a
line in the output and the log, exit 1): CI sets it 3 minutes before the job's timeout, so that a run gone silent
still uploads its logs. Run the class of a component after a change to it; macOS needs Automation Mode (below) and
takes over the screen.

```sh
tools/apple/check.sh behavior                            # every class on the iOS simulator
tools/apple/check.sh behavior ios CheckboxBehaviorTests  # one class or more, by name
tools/apple/check.sh behavior macos                      # on the Mac
```

One test alone has no option; run it with xcodebuild after `source tools/apple/xcode-env.sh`, as
`-only-testing:CatalogUITests/CheckboxBehaviorTests/testPressToggles` with `-destination "platform=iOS
Simulator,name=iPhone 17"` and `-derivedDataPath .build/xcode/catalog`.

CI runs them every night next to the full accessibility audit, in `.github/workflows/accessibility-audit.yml`, one
leg on iOS and one on macOS, under the same rule for skipping a commit already checked; a pull request does not run
them. A failed leg uploads its logs and its result bundle, with the screenshots XCTest takes at a failure; a leg that
retried uploads its logs, the first run's and the retry's, even when the retry passed (`behavior-retried-<platform>`).
A failed test fails the whole nightly run, so the next night runs every job again on the same commit, and a release
of that commit waits (`.claude/skills/release/SKILL.md`). For a flaky failure, "Re-run failed jobs" on that run (`gh
run rerun <id> --failed`) is the cheap remedy: the new attempt keeps the run's id and commit, and once it passes the
run counts as successful for both (seen with CI run 44461921450); `gh workflow run` starts all twelve Mac jobs again.
On macOS `CheckboxBehaviorTests.testKeyboardFocusAndSpace` skips itself when the system's keyboard navigation is off,
as it likely is on the runner: a green macOS leg may not have run it, and its output shows the skip. The macOS leg had
not run on CI when it was added.

### Accessibility audit

`tools/apple/check.sh a11y` runs the UI test `CatalogAccessibilityAuditTests` on the iOS simulator (`iPhone 17` or
`$WESTRON_SIM_DEVICE`): it opens every entry of `Catalog.entries` in isolation, so a new entry is audited with no
change to the test, and runs `XCUIApplication.performAccessibilityAudit` on it. Every issue fails the test. The log
goes to `.build/logs/a11y-ios[-<tests>].log`, the result bundle to `.build/xcode/results/a11y-ios[-<tests>].xcresult`
(the tests named, if any, are in the names); the script prints each issue as a line starting with `a11y:`. A full run
takes about 28 minutes with the Button entries (1689 s on 2026-11-17, iPhone 17 Pro simulator).

```sh
tools/apple/check.sh a11y                                  # all five tests below
tools/apple/check.sh a11y ios testDarkAppearance           # one or more of them, by name
WESTRON_ENTRY=controls,icons tools/apple/check.sh a11y     # those entries only
WESTRON_ENTRY_SHARD=2/3 tools/apple/check.sh a11y          # every third entry, from the second (after WESTRON_ENTRY)
```

CI runs the full audit once a night on `main`, and by hand on any branch (`gh workflow run accessibility-audit.yml
--ref <branch>`), in its own workflow, `.github/workflows/accessibility-audit.yml`: ten legs side by side
(`fail-fast: false`, 45 minutes each) for the 28 entries of phase 3, `testDefaultSettings` in three shards
(`WESTRON_ENTRY_SHARD`), `testAccessibilityDynamicType` in four, and each of the three contrast tests in one leg, about
25–28 minutes each, its build included (the arithmetic is in the workflow). Each leg pays about 10 minutes of build and
setup before its first entry, and at most 5 Mac jobs run at once, so fewer, longer legs finish the run sooner. The
runner is about 3 times slower than a local Mac: with the Button entries (PR #66, 2026-11-17) it took over 36.6
minutes for `testAccessibilityDynamicType`, past the timeout, 32.4 minutes for `testDefaultSettings`, and 16–19
minutes for each of the others, against 627 s, 476 s and 194–196 s locally. The cost is ten parallel jobs, about 4.3
runner-hours per run, so a scheduled run skips them when `main`'s head is the commit the last successful scheduled
run already audited. A leg that passes about 30 minutes as pages are added (a contrast leg at about 31 entries) gets
another shard, so that a retry still fits its 45.

A pull request audits only the entries of the components it changes, in `.github/workflows/ci.yml`: the job
`audit-scope` passes the merge commit's changed paths to `tools/apple/audit-scope.sh`, which prints the entry ids, and
one job runs all five tests for them (`WESTRON_ENTRY`), 55 minutes with a retry budget of 50, in shards of at most 5
entries when there are more. A path counts for a component when it is in the component's WestronUI directory, its
generated `<Name>+Contract.swift` or `<Name>+Matrix.swift`, its catalog page `Components/<Name>Pages.swift` or its
contract `spec/components/<id>/`, and gives the entries that page declares; a Foundations page that shares nothing
with other files gives its own entries. A component's change also gives the entries that draw it, since components
draw each other: the script derives who uses whom from the sources on every run, with no list to keep (its header,
"Use"). It splits WestronUI and the catalog's pages into units (top-level declarations, extension members, each
entry) and follows names from unit to unit, so ListRow's change also gives `disclosure` and the floating Button
entries, Rule's gives `list-row`, `list-row-in-list` and `color-in-use`, and a page's code other pages use
(`FlowLayout` in ButtonPages.swift) gives theirs. The cut is declared: a base component, listed with its reason in
the script's `base_components` (on 2026-11-24 Icon alone, drawn on 13 other entries), gives its own entries only, says
so in the job's log, and leaves the rest to the nightly run; the search does not go on through it. The limit is a
tripwire, not a switch: a change that would add more than 5 entries beyond its component's own (one leg) fails the
scope job, naming the component, its count and the choices (declare it base, move a page's shared code out of the
page, or raise the limit), and so does a declared base component back within the limit. The scan runs on every pull
request, so the one that adds the crossing use fails its own job. Four counts stand at the limit exactly (Button's
implementation and page, ListRow, Surface), with no headroom on purpose: the next use of any of them asks for the
decision. `tools/apple/audit-scope-test.sh` pins every count; `tools/apple/audit-scope.sh --uses` prints them with the
units each entry reaches the change through. Everything else gives nothing: shared paths (tokens, the shared files
of WestronUI, the catalog's host, the audit test, the scripts) touch every entry and wait for the nightly run, or for
a run by hand on the branch. The audit is skipped when there is nothing to audit, and on a push to `main`. The script
reads the registry, `Catalog.entries` in `Catalog.swift`, from its array literals and its `append(.<name>)` lines (an
entry some OS lacks); a registry it reads nothing from fails the job, and `tools/check.sh audit-scope`
(`tools/apple/audit-scope-test.sh`) checks that it reads every entry the catalog declares.

What a change to one file of each component directory selects, before (main at 48c2213) and after (2026-11-24):

| WestronUI/ | before | after |
|---|---|---|
| Button/ | its 10 entries | + text-field-behavior, text-field-focus-framed, text-field-focus-inline, color-in-use, controls (15) |
| Checkbox/ | checkbox, checkbox-in-list | + list-row, list-row-in-list, disclosure (5) |
| Disclosure/ | disclosure | + list-row (2) |
| ListRow/ | list-row, list-row-in-list | + the four button-floating entries, disclosure (7) |
| Rule/ | rule | + list-row, list-row-in-list, color-in-use (4) |
| Surface/ | surface | + rule, text-field-behavior, text-field-focus-framed, text-field-focus-inline, color-in-use (6) |
| Chip/, Icon/ (base), IconTile/, TextField/ | their own | their own, unchanged |

A change to ButtonPages.swift also gives checkbox, chip, color-categories, color-in-use and controls (15); the other
pages give their own entries only. The largest scope is Button's, 15 entries in 3 legs (about 1.9 runner-hours, from
1.3).

```sh
git diff --name-only main...HEAD | tools/apple/audit-scope.sh   # the entries a pull request from this branch audits:
                                                                # its commits since main, as CI diffs; not uncommitted
```

| Test | Launch arguments | Audit types on iOS |
|---|---|---|
| `testDefaultSettings` | `-WestronAppearance light`; the system's font size | all: contrast, element detection, hit region, sufficient element description, Dynamic Type, text clipped, trait |
| `testAccessibilityDynamicType` | `-WestronAppearance light -WestronDynamicType accessibility5` | all except Dynamic Type |
| `testIncreasedContrast` | `-WestronAppearance light -WestronContrast high` | contrast |
| `testDarkAppearance` | `-WestronAppearance dark` | contrast |
| `testDarkIncreasedContrast` | `-WestronAppearance dark -WestronContrast high` | contrast |

- The Dynamic Type and text clipped audits change the font size themselves, so they find text that does not scale or
  would be cut at a larger size even in `testDefaultSettings`. `-WestronDynamicType` pins the size in the view tree,
  where the system size the audit sets cannot reach it, so the Dynamic Type audit does not run there.
- The theme and the contrast change only colors, so their tests run the contrast audit alone.
- The audit sees only what is on screen, so every test audits a page a screenful at a time: it waits until the page
  is still, audits it, drags it up by about two thirds of the screen without momentum, and stops when a drag no
  longer moves the page. A page that is still moving after 5 s (an animation that runs on) is audited as it is, with
  a line in the log, and is not waited for again.
- After a drag, the contrast audit also reports an element under the status bar or off the screen, measured on the
  clock or on nothing. Such an element is not counted there; the screenful before showed it whole. An element the
  bottom of the screen cuts is measured on the strip that shows, under the home indicator, and is judged on the next
  screenful instead (`a11y: deferred in …`), but only when the next drag brings it whole into view; if the page ends
  there after all, it counts. On the CI runner "Report not sent" on `color-in-use`, 18 pt of it on screen, failed
  contrast once in `testAccessibilityDynamicType` and passed on the rerun (#74).
- The audit of a screenful sometimes gives up ("Audit failed to complete in time", -56) after 15 s, where it
  otherwise takes 0.2–3.5 s; the log has each audit's time (`a11y: <entry>, screen <n>: audit completed in 0.36 s`).
  Some scroll positions make the contrast audit give up every time (#127): measured on 2026-11-24 (iOS 26.3, iPhone
  17), `list-row` at accessibility5 gave up at screen 14 on every try and completed 7 pt further. A page of its four
  drag-sample rows alone gave up with the third row's top at 15 pt on screen and completed at every other whole point
  from 0 to 60, and so did four plain SwiftUI buttons, each a glyph, a title and a count, with no westron in them. It
  is the position of the page's elements, not the pixels (the rows drawn transparent gave up the same way) and not a
  scroll view (the rows offset in a plain stack did too); one text alone at that place did not. So the test first runs
  a screenful's audit once more where it is (a stalled simulator), then moves the page by a few points
  (`auditMoved`): on by f points, which scrolls a strip of f points off the top, and, if need be, back to b points
  before where it was, which scrolls a strip off the bottom. A slow drag of 20 pt with a hold before the release
  usually moves the page 10 pt (the touch slop takes the rest; 30 of 30 such drags on 2026-11-24, also right after an
  audit gave up), but once it moved the page 146.3 pt, for a reason not found. So the move is not trusted: it is
  measured from the elements' frames after every drag, and a drag that lands outside 1–16 pt is corrected by another
  toward 10 pt, at most four drags in all; only a move measured within 1–16 pt is audited (16 pt is the page's margin,
  so at the top of a page no element starts in the strip). The log has every drag (`a11y: <entry>, screen <n>: moving
  on, drag 1 asked 20.0 pt from 0.0 pt, the page is now 10.0 pt from where it was …`). From one snapshot of the
  page's elements before the move, it checks that every element the screenful showed whole was seen whole by a moved
  audit, or, for one in the top strip, by the screenful before (from screen 2; f is at most 16 pt, less than the 24 pt
  by which a deferred element clears the top). The log says so (`a11y: <entry>, screen <n>: audited whole with the
  page moved (moved on by 10.0 pt: completed)…`). An issue on an element both moved audits see is reported once
  (`a11y: reported already in …` for the second). When the moved audits do not cover the screenful (an element within
  f points of the top of a page, or of the bottom of its last screenful, a move that does not land within the bound,
  or an audit that gives up again), the entry fails for infrastructure, naming the elements not audited, and the
  script audits it again in a run of its own. A position that gives up is about a point wide, so a page does not need
  a rule on what one screenful may hold.
- The Dynamic Type and text clipped audits enlarge the page's text. A dragged scroll view goes back to its top when
  its content grows, so after a drag they would measure only the top of the page; and after them, the page's
  accessibility tree and its pixels disagree for a while, so that the next audit reads every text as failing
  contrast. In `testDefaultSettings` they run in a pass of their own, without drags: a fresh launch for each window
  of the page, one more window than the page has screenfuls, each held in place by `-WestronScrollAnchor` (0 the top
  of the page, 1 its bottom), from the top to the bottom. A line of fixed-size text at the top, in the middle and at
  the end of the typography page is reported in each place (2026-11-17).
- Limits. The windows of the separate pass are spread evenly over the page, and a window shows what the enlarged
  text leaves on screen; a page several screenfuls long can leave a line between two windows. The drags start low in
  the page: a control there that takes vertical drags itself would end the page early. On macOS the scroll call that
  moves the page is not verified to reach it; a page that does not move after the first scroll is logged
  ("did not move when scrolled") and audited on its first screenful only.
- The audit loses track of the cells of a lazy container (`LazyVGrid`, `List`, `Form`) when it changes the text
  size, and reports their text as not following Dynamic Type. A catalog page lays its content out eagerly: the
  sample grids with `AdaptiveGrid`, the same columns as an adaptive `LazyVGrid`, and the environment page with
  stacks in a scroll view rather than a `Form`.
- It does the same with the text of a `ViewThatFits` whose choice the enlarged text changes: the new branch's views
  take the place of the old one's, and the audit reports the old one's text, which scales, as not following Dynamic
  Type (`typography-in-text`, whose rows swapped from a row to a column, 2026-11-19). A layout that arranges the same
  views either way keeps them: `SideBySideOrStacked` (`WestronCatalog/Foundations`), a row where it fits and a column
  otherwise, which the space page uses too.
- An issue that is not the entry's fault, or that the catalog cannot fix, is suppressed one by one, with its reason,
  in `CatalogAccessibilityAuditTests.suppressions`; an audit type is never turned off as a whole.
- `WESTRON_ENTRY=<id>[,<id>…] tools/apple/check.sh a11y` audits those entries only: one while its issues are being
  fixed, or a share of the catalog.
- When a run ends, passed, failed or interrupted, the script stops the simulator's `testmanagerd` (launchd starts it
  again for the next test): after audits it has been seen to keep running at 400–1400 % CPU for hours with no test
  left (2026-11-17). A daemon that another `xcodebuild` on the same simulator still uses is left alone.
- The script builds the catalog and its UI tests first, in a step of its own (`<name>-build.log`): a build failure
  fails the audit at once, with no test run and no retry, and every test run uses what that build produced.
- A failed run is retried once, narrowly, when the machinery failed rather than a page (#74). On the CI runner the
  simulator now and then stalls for a minute or more, and whatever the test asks of it then fails: terminating the
  catalog ("Failed to terminate dev.westron.catalog:<pid>: Failed to terminate dev.westron.catalog:0", the same
  message a simulator whose `testmanagerd` is stopped gives), launching it ("does not have a process ID"; in run
  44444325775, in the first entry of a shard, "Failed to get background assertion for target app with pid <pid>:
  Timed out while acquiring background assertion.", and in the snapshot matrix's first launch "Failed to launch
  <XCUIApplicationImpl: …> via Xcode: Timed out while launching application via Xcode."; a launch that fails
  otherwise stays a finding), a UI
  query ("Failed to get matching snapshot: Timed out while evaluating UI query"; in the same local experiment also
  a drag and a screenshot, "Timed out while synthesizing event", "… requesting screenshot"), the audit ("Audit
  failed to complete in time", -56, which the test runs once more on the spot and then with the page moved, above)
  or the entry not rendering within 30 s. XCTest stops the test method at a failed terminate, launch, query or drag,
  so the rest of the shard went unaudited and the leg failed.
  - The test prints which entries it audits, when each starts and finishes, and each failure with its kind:
    `infrastructure` when its message starts as one of those (`CatalogAccessibilityAuditTests.isInfrastructure`;
    never by text further in, where a page's labels can appear), `finding` otherwise.
  - When the run fails, the script reads those lines and runs the test once more, after stopping `testmanagerd`,
    for the entries the run did not finish or that failed for infrastructure alone, with `a11y: retrying <test> for
    <entries>` in its output and, on GitHub Actions, a warning on the run. Its log is `<name>-retry-<test>.log`; CI
    uploads the logs of a leg that retried as the `a11y-retried-…` artifact, even when the retry passed.
  - Not retried, so the leg fails: a test with a finding (no entry is audited twice after a finding, so a finding
    that shows once in two runs still fails), a failure outside an entry, a test that did not start (but for the
    test runner failing to start, the one case where the whole test is run again: "Failed to install or launch the
    test runner", or "Early unexpected exit, operation never finished bootstrapping" when it crashed while preparing
    to run tests, run 44444325775), a run where XCTest reports more failures than the test classified, and a run
    where `xcodebuild` exits non-zero although
    every test passed (the runner died, or the result bundle was not written, after the last test), with
    `a11y: xcodebuild exited with status <n> although every test passed` in its output. A retry that fails again
    fails the leg.
  - A retry must fit a time budget, 40 minutes from the start of `check.sh a11y`, its build included
    (`WESTRON_A11Y_RETRY_BUDGET`): a nightly leg times out at 45, and a leg the timeout kills uploads no logs (a
    pull request's audit sets 50 of its 55). A retry
    is estimated at 90 s plus, for each entry to retry, the mean time of the entries the first run finished
    without a failure and without an audit the test retried on the spot (-56), from XCTest's `t = <s>s` activity
    times in the log; a stalled entry's time is never used. When there are none, as with a stall in the first
    entry, each entry counts at a time measured on CI with a margin: 90 s for `testDefaultSettings`, 130 s for
    `testAccessibilityDynamicType`, 38 s for the other three. A whole test is retried only in the first half of
    the budget. Past it, the leg fails with a line that says so. On CI the step spends 6.5–17.1 minutes, median
    10.0 and mean 10.4, before its first entry, so a stall in the first entry of the slowest leg, a contrast test's
    28 entries, is retried after a build of usual length (about 32.6 minutes in all) and after one of up to about
    17.8 minutes (`tools/apple/check.sh` has the numbers).
  - What the retry can hide: a catalog page that hangs the app only sometimes, since a hung app also times out UI
    queries.
  - `WESTRON_A11Y_FAIL_ONCE=<id>` is a test hook that fails that entry for infrastructure in the first run only, to
    see the retry at work.
- `WESTRON_ENTRY_SHARD=<i>/<n>` then audits every n-th of those entries, in registry order, from the i-th (1-based):
  the n shards hold each entry exactly once (`CatalogShard`, tested in `CatalogShardTests`). The log and the result
  bundle get `-shard<i>of<n>` in their names, and the run logs the entries of its shard (`a11y: shard 2/3: …`). A
  value that is not `<i>/<n>` with 1 ≤ i ≤ n fails the test without auditing anything.
- `tools/apple/check.sh a11y macos` runs the same tests on macOS, with the macOS audit types (contrast, element
  detection, hit region, sufficient element description, action, parent–child; macOS has no Dynamic Type or text
  clipped audit). It needs Automation Mode (below) and takes over the screen while it runs, so it is not a CI gate.
  Its issues are not triaged yet: the first run (2026-11-16, entry `icons`, on a machine whose screen was in use)
  reported every icon cell as failing contrast, and a group and the window as lacking a description.

### Screenshots on macOS: turn on Automation Mode once

The UI tests on macOS that take the screenshots require Automation Mode. To turn it on without a password prompt
on every run:

```sh
sudo automationmodetool enable-automationmode-without-authentication
```

Why not `screencapture` and not an in-process capture for an entry: see decisions/0008; the snapshot matrix is drawn
in-process (above).
