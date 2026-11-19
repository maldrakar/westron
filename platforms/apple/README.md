# westron for Apple

A SwiftUI library for iOS, iPadOS, macOS and watchOS. The package manifest lives at the repository root.

| Path | What is there |
|---|---|
| `Sources/WestronTokens/` | Token values as plain Swift with no imports, for a product's shared code and its WebAssembly build |
| `Sources/WestronUI/` | Styles, components and the SwiftUI accessors of the tokens: what products import |
| `Sources/WestronCatalog/` | Catalog entries, their host and launch arguments |
| `Tests/` | Package tests (Swift Testing) |
| `Catalog/` | Catalog app for iOS and macOS and its UI tests: screenshots, the snapshot matrix, the accessibility audit and behaviour |

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
option that is not a bool): its values are the columns, rest and the states the rows, at most 3 × 6, so it fits an
iPhone 17 in portrait and the macOS window. Text, with no states, has six sheets of one row: five of three roles each, and the last of two.
Surface has two sheets of one row, the three kinds with `outlined` false and true; Rule one, both axes. Icon, with no
states and an option whose values are icons, runs the registry's glyphs down the rows, six to a sheet, and its
`scale` across: six sheets (spec/conventions.md, "Own components").
The hand-written `<Component>MatrixCell` (Button's is in `Components/ButtonPages.swift`, Text's in
`Components/TextPages.swift`) draws one cell with the real component: Button's with hover, focus and pressed forced
as on the `button-states` pages, disabled and loading with the real modifiers; Text's with `.textRole(_:)`; Surface's
(`Components/SurfacePages.swift`) with `.surface(_:outlined:)` around sample content, a plain surface on the canvas
and an outlined one on a fill (a raised or dragged one in a sunken well, a sunken one in a raised card); Rule's
(`Components/RulePages.swift`) between two lines or two words; Icon's, Checkbox's and Text field's in
`Components/IconPages.swift`, `CheckboxPages.swift` and `TextFieldPages.swift`. The rows of a state the OS never
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
  macOS has no Dynamic Type: SwiftUI draws a cell the same at every `dynamicTypeSize` there, `-WestronDynamicType`
  included (`ComponentMatrixTests` checks it), so a Mac is captured at `large` alone and its page says why.
- **Supplementary sheets** show what no contract option sets. A component's catalog code adds a
  `ComponentMatrix.Supplement` to `Supplement.all`: the option values it keeps and a cell of its own. Its sheets are
  the generated sheets that keep those values, with their axes, states and rows, so nothing the contract lists is
  listed again by hand. Each sheet and its section of the review page are marked "Not a contract option". Over a
  matrix whose rows are icons, a supplement keeps a few of them (`rows`), on one sheet. Where its cell is taller than
  a generated one, `rowsPerPicture` caps the rows of one picture at a text size that splits sheets
  (`accessibility5`). There are ten (`SnapshotMatrix/Supplements.swift`, `Supplement.all`):
  - Button, `label-without-icon`: its generated cells have an icon and a label or are icon-only, so a label without an
    icon, which while loading has the indicator before the label and widens the button (P13), is shown on the sheets
    with iconOnly false: every variant, size and role, at rest and in each state, 108 combinations on 6 sheets.
  - Icon, `beside-text`: three glyphs, each beside text in four roles (one row to a picture at `accessibility5`); and
    `color-roles`: six glyphs in the color roles of design-language/07 (three rows to a picture there).
  - Surface, `nesting`, on the sheet with outlined true: for raised and dragged, two outlined cards of the kind in a
    sunken column; for sunken, an outlined well in a raised card.
  - Checkbox, `list-colors`: the twelve list colors through `.category(_:)` (three rows to a picture at
    `accessibility5`); and `text-roles`: a task's check and a subtask's beside labels of their roles.
  - Text field, at size m: `card-notes`, a card's title and multiline notes (two rows to a picture at
    `accessibility5`); `secure-field`, the style on `SecureField`; `on-surface` and `on-sunken`, a field on those
    grounds.

  Like the matrix, supplements are not catalog entries, so the accessibility audit does not walk them.

```sh
tools/apple/snapshot-matrix.sh ios                       # or macos; --component button,rule for some components
tools/apple/snapshot-matrix.sh compare <before> <after>  # exit 0 when every image is the same, 1 otherwise
tools/apple/snapshot-matrix.sh merge --expect button,rule <out> <capture>…  # captures taken apart, one page
```

The capture runs the UI test `SnapshotMatrixTests` once (one `xcodebuild test`), which launches the catalog for every
picture (a sheet, or a part of one) in every capture: light, dark, light-hc and dark-hc at `large`, and on iOS light at
`xSmall` and `accessibility5`. It waits until the sheet stands still, checks that the number of cells on screen
matches the matrix and that each lies inside the picture, and attaches the screenshot: the screen on iOS, the sheet
without the title bar on macOS. It pins the text size, the language and the locale, the window's size on macOS, and
freezes Core Animation in the sheet's window so a loading indicator draws the same frame every time. With Button's 12
generated and 6 supplementary sheets that is 144 images on iOS (18 × 4 themes, 18 at `xSmall`, 18 × 3 parts at
`accessibility5`) and 72 on macOS (18 × 4). The script exports the PNGs, `<component>.<sheet>.<theme>.png` at `large`
and `<component>.<sheet>[_part-<n>-of-<count>].light.<text size>.png` at the others, with the manifest `matrix.json`
to `.build/snapshot-matrix/<platform>/`, writes the review page `index.html` there (sheets down; across, each text size
with its themes, the parts of a sheet side by side; the supplements in sections of their own; with the OS version,
device and scale, and each picture's size) and prints its path; it fails when an image is missing or a sheet failed a
check. The
comparison writes `before/`, `after/`, `diff/` and its `index.html` to `.build/snapshot-matrix/compare/` (`--out` to
change it). Compare only captures from the same environment: two local runs, or two CI artifacts (decisions/0008).
Between two iOS captures (both manifests say `ios`, at one scale) the comparison ignores the home indicator
(`HomeIndicator` in `tools/apple/snapshot-pages.swift`): the system draws it over the app, and from launch to launch
draws it or not, or at another opacity, so two captures of the same commit differed there and nowhere else (iPhone 17,
iOS 26.3: every differing pixel in x 387–819, y 2583–2598 of 1206 × 2622, a capsule of 144 × 5 pt centred 10.3 pt above
the bottom). A pixel is ignored only on that footprint, with 1.5 pt of tolerance, and only when three things hold in
the image:
- the content stays clear of the box around the indicator (160 × 12 pt, from 16 to 4 pt above the bottom of the
  screen) in both pictures: the band from 4 pt above the box down to its bottom, across the whole width, is one color
  (`clearOfContent`). The box lies in the bottom safe-area inset (34 pt on iPhone 17), under which a sheet that fits
  draws only its canvas; a sheet that does not fit reaches into the band and is compared whole. Scanned on iOS
  captures of 2026-11-19, every sheet of Button, Icon, Text, Surface, Rule and Text field ends 39 pt or more above
  the bottom of the screen, and Checkbox's 22 pt or more but for its twelve list colors at `accessibility5`, which
  then overflowed the screen at both ends (13 pt above the bottom). Since e76d2d3 that sheet is taken in two
  pictures of three rows there, which fit under the status bar with nothing at the bottom (the Icon follow-up's
  capture; not scanned here);
- nothing in the box differs off the footprint (`onlyOnFootprint`): a block, a dot or a line elsewhere in the box, or
  wider or taller than the indicator, is reported, together with whatever differs on the footprint;
- both captures are iOS at one scale.

What is ignored stays visible: a diff draws it in amber, a changed image's line counts it apart, and every image that
differs on the indicator alone counts as unchanged but gets its diff picture under a heading of its own, "Unchanged but
for the home indicator", not collapsed, and in the summary line.

CI's `snapshot-matrix` job packs the components of the generated registry `ComponentMatrix.all` into legs by their
number of images (first fit, the largest first, at most 40 minutes of capture on the runner, 15 s an iOS image and 8 s
a macOS one; the counts are in the workflow's `IMAGES`, and the page job warns when a capture's count differs). Each leg
captures its components in one run (`--component a,b`) and uploads `snapshot-matrix-<platform>-<a+b>`; then
`snapshot-matrix-pages` puts each platform's legs together with `merge --expect` and uploads one page per platform,
`snapshot-matrix-ios` and `snapshot-matrix-macos`, as before. A page whose component no leg brought names it at its top.
With Text field, 365 iOS images go in three legs and 184 macOS images in one.

A capture that the machinery failed, not a sheet, is run once more, as the audit's retry is (#74): when the test wrote
no manifest and either the test runner did not start ("Failed to install or launch the test runner", "Early unexpected
exit, operation never finished bootstrapping") or every failure XCTest reported is one of its messages for a request
to a stalled simulator, the ones the audit counts as infrastructure (a launch that timed out, "Failed to launch
<XCUIApplicationImpl: …> via Xcode: Timed out while launching application", seen on CI in run 44444325775; a
background assertion, a terminate, a UI query that timed out). A failure of the test's own (a cell count, a cell
outside the window, a sheet that did not render or showed a problem, an unknown component), alone or among others, is
never retried, and nor is a capture that wrote its manifest. The script says `snapshot-matrix: retrying the capture:
…` and, on GitHub Actions, warns on the run; the first run's log stays as `snapshot-matrix-<platform>[-<a+b>].log`
and the retry's is `…-retry.log`, both in the leg's artifact. The retry captures everything again, so it starts only
within 25 minutes of the script's start (`WESTRON_MATRIX_RETRY_BY`); a leg's timeout is 30 minutes and its capture
time with a third more, so a retry that starts by then ends about 2 minutes before it (`.github/workflows/ci.yml`).

A run that goes silent is stopped: when the log of the build or of a capture has not grown for 10 minutes
(`WESTRON_MATRIX_STALL_SECONDS`, default 600), the script says `snapshot-matrix: stalled: xcodebuild wrote nothing
for …`, stops that xcodebuild and its children, and writes the same line into the log. A stalled capture counts as the
machinery's failure and is retried by the rules above, unless its test reported a failure of a sheet before the
silence; a stalled build fails as a build does; a second stall fails the capture. On macOS, stopping a run also stops
any catalog app or test runner started from this checkout's build products (they belong to launchd, not to
xcodebuild), so a concurrent macOS check in the same checkout would be stopped with it. In CI run 44461921450 the
macOS leg printed the capture's header and nothing more for 62 minutes, until the job's timeout, and a leg the timeout
kills uploads no logs. The capture's longest usual silences are the machinery's, 2.4–3.5 minutes (the runner
starting, a launch timing out, the runner crashing while bootstrapping); between the test's own lines, at most 2.3
seconds. CI also sets `WESTRON_MATRIX_DEADLINE` to the leg's timeout less 2 minutes, in minutes from the script's
start: then the script stops whatever it still does (an xcodebuild, the export of the attachments, the page), says
`snapshot-matrix: stopped at the deadline: … during <step>`, writes the same into the log, and exits 1 without a
retry, so the step fails rather than being cancelled and the logs go up. The trade: a run that would have finished in
the last 2 minutes or so before the timeout now fails, with its logs, instead of passing.

### Behaviour UI tests

`ButtonBehaviorTests`, `CheckboxBehaviorTests`, `TextFieldBehaviorTests` and `IconAccessibilityTests`, in
`Catalog/CatalogUITests`, check on the catalog's entries what a unit test cannot reach: presses and hit areas, the
accessibility hierarchy, the keyboard. No `tools/apple/check.sh` target runs them, and neither does CI; run one suite,
or one test of it, by hand after a change to its component:

```sh
source tools/apple/xcode-env.sh
xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog \
  -destination "platform=iOS Simulator,name=iPhone 17" -derivedDataPath .build/xcode/catalog \
  -only-testing:CatalogUITests/CheckboxBehaviorTests test    # …/CheckboxBehaviorTests/testPressToggles for one test
# on macOS: -destination "platform=macOS,arch=$(uname -m)"
```

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

CI runs the audit in its own job, `accessibility-audit`, side by side (`fail-fast: false`, 45 minutes each): ten legs
for the 28 entries of phase 3, `testDefaultSettings` in three shards (`WESTRON_ENTRY_SHARD`),
`testAccessibilityDynamicType` in four, and each of the three contrast tests in one leg, about 25–28 minutes each, its
build included (the arithmetic is in `.github/workflows/ci.yml`). Each leg pays about 10 minutes of build and setup
before its first entry, and at most 5 Mac jobs run at once, so fewer, longer legs finish the run sooner. The runner is
about 3 times slower than a local Mac: with the Button entries (PR #66, 2026-11-17) it took over 36.6 minutes for
`testAccessibilityDynamicType`, past the timeout, 32.4 minutes for `testDefaultSettings`, and 16–19 minutes for each of
the others, against 627 s, 476 s and 194–196 s locally. The cost is ten parallel jobs, about 4.3 runner-hours per run,
so the audit runs on every push to `main` and on a pull request only when it changes a path the audit depends on:
`platforms/apple/`, `tokens/`, `spec/`, `tools/apple/`, `Package.swift`, `Package.resolved`, `.xcode-version` or
`.github/workflows/ci.yml`. The job `audit-scope` decides, from the pull request's merge commit; otherwise the audit's
jobs show as skipped. If `audit-scope` itself fails, the audit runs. A leg that passes about 30 minutes as pages are
added (a contrast leg at about 31 entries) gets another shard, so that a retry still fits its 45.

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
  views either way keeps them: that page's `SideBySideOrStacked`, a row where it fits and a column otherwise.
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
  failed to complete in time", -56, which the test retries once on the spot) or the entry not rendering within
  30 s. XCTest stops the test method at a failed terminate, launch, query or drag, so the rest of the shard went
  unaudited and the leg failed.
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
    (`WESTRON_A11Y_RETRY_BUDGET`): a CI leg times out at 45, and a leg the timeout kills uploads no logs. A retry
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

Why not `screencapture` and not an in-process capture: see decisions/0008.
