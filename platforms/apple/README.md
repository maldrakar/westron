# westron for Apple

A SwiftUI library for iOS, iPadOS, macOS and watchOS. The package manifest lives at the repository root.

| Path | What is there |
|---|---|
| `Sources/WestronTokens/` | Token values as plain Swift with no imports, for a product's shared code and its WebAssembly build |
| `Sources/WestronUI/` | Styles, components and the SwiftUI accessors of the tokens: what products import |
| `Sources/WestronCatalog/` | Catalog entries, their host and launch arguments |
| `Tests/` | Package tests (Swift Testing) |
| `Catalog/` | Catalog app for iOS and macOS and its UI tests: screenshots, the snapshot matrix and the accessibility audit |

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
    .padding(.horizontal, .space200)              // space.200: 16 pt
    .background(.background.surface, in: RoundedRectangle(cornerRadius: .radius.card))
    .shadow(.raised)                              // shadow.raised
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
  no westron statics, so SwiftUI's `Font.body` stays as it is.
- Motions with a spring are `.spring(duration:bounce:)`; the others are `.timingCurve`, and `.delay` when they wait.
- The adapters from WestronTokens values to SwiftUI values are hand-written in `Sources/WestronUI/TokenAdapters.swift`.

## Icons

`tools/westron generate` also writes the icons from their registry, `spec/icons/icons.yaml` (decisions/0011):
`Westron.Icon` in `WestronTokens`, a `String`-backed enum of westron's names, and in `WestronUI` the SF Symbol of each.

```swift
let icon = Westron.Icon(rawValue: list.icon) ?? .fallback   // by the name the store keeps; bullets when unknown

Image(icon)                                       // its SF Symbol, which takes the font of the text it goes with
    .textRole(.body.regular)
    .foregroundStyle(list.color.text)
Label("Rename", icon: .pen)                       // as Label(_:systemImage:)
Button("Add", systemImage: Westron.Icon.plus.systemName) { add() }   // any call that takes systemImage:
```

## Catalog

Open in Xcode 27.1: `platforms/apple/Catalog/Catalog.xcodeproj`. Without arguments, the catalog shows navigation
across all entries. With `-WestronEntry <id>`, it shows one entry full screen; this is how
`tools/apple/catalog-screenshot.sh` captures it. `-WestronAppearance light|dark`, `-WestronContrast standard|high` and
`-WestronDynamicType <size>` set the conditions; `-WestronScrollAnchor <0…1>` holds a point of the entry's scroll
content in view (the accessibility audit uses it).

The Foundations section holds the token samples, each fitting one screenshot on an iPhone 17 and in the macOS window:
`color-backgrounds` and `color-foregrounds` draw every color in the four themes side by side, each cell under its own
color scheme and contrast; `color-categories` draws the list colors and `color-status` the statuses and the chart
series in the catalog's theme; `color-in-use` draws a task list, a table of deployments, notices and buttons with the
semantic colors, the page the owner approves the palette on; `typography`,
`space`, `shape` and `motion` show the rest, and `icons` draws every icon with its name at the size of body text. To
review the colors in every mode:

```sh
tools/apple/catalog-screenshot.sh ios --entry color-in-use --appearance dark --contrast high
```

### Snapshot matrix

The owner approves a component's look from its snapshot matrix (decisions/0005, the second gate; #24). `tools/westron
generate` writes it from each approved contract into `Sources/WestronCatalog/Generated/<Component>+Matrix.swift`:
every option's values (a bool as `false` and `true`, an option that is the system's own API such as Button's `role`
included), rest and each state alone, the combinations a constraint of severity `error` leaves out, what each Apple OS
draws differently (`platforms.apple`), and the sheets. A sheet fixes every option but the variant: the variants are
its columns, rest and the states its rows, at most 3 × 6, so it fits an iPhone 17 in portrait and the macOS window.
The hand-written `<Component>MatrixCell` (Button's is in `Components/ButtonPages.swift`) draws one cell with the real
component: hover, focus and pressed forced as on the `button-states` pages, disabled and loading with the real
modifiers. The rows of a state the OS never enters are left out, as on those pages; a value the OS does not offer is
drawn with its fallback and marked, and a combination a `warning` constraint advises against is drawn with a caption.
A state no token binding names in a case looks as rest, and the sheet and the review page say so: Button's focus,
whose ring the system draws. The sheets are not catalog entries, so the accessibility audit does not walk them;
`-WestronMatrixSheet <component>.<sheet>` shows one. The matrix shows only what a contract option sets, and a label
without an icon is not one: Button's cells have an icon and a label, or are icon-only. So loading without an icon, the
indicator before the label and the button wider, is on the `button-states` catalog pages and in `ButtonLabelKindTests`.

```sh
tools/apple/snapshot-matrix.sh ios                       # or macos; --component button for one component
tools/apple/snapshot-matrix.sh compare <before> <after>  # exit 0 when every image is the same, 1 otherwise
```

The capture runs the UI test `SnapshotMatrixTests` once (one `xcodebuild test`), which launches the catalog for every
sheet in light, dark, light-hc and dark-hc, waits until the sheet stands still, checks that the number of cells on
screen matches the matrix and that each lies inside the picture, and attaches the screenshot: the screen on iOS, the
sheet without the title bar on macOS. It pins the text size, the language and the locale, the window's size on macOS,
and freezes Core Animation in the sheet's window so a loading indicator draws the same frame every time. The script exports the PNGs, `<component>.<sheet>.<theme>.png`, with the manifest `matrix.json` to
`.build/snapshot-matrix/<platform>/`, writes the review page `index.html` there (sheets down, themes across, with the
OS version, device and scale, and each picture's size) and prints its path; it fails when an image is missing or a sheet failed a check. The
comparison writes `before/`, `after/`, `diff/` and its `index.html` to `.build/snapshot-matrix/compare/` (`--out` to
change it). Compare only captures from the same environment: two local runs, or two CI artifacts (decisions/0008).
CI's `snapshot-matrix` job uploads both platforms' pages as the `snapshot-matrix` artifact.

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

CI runs the audit in its own job, `accessibility-audit`, side by side (`fail-fast: false`, 35 minutes each): one job
for each of the three contrast tests, and the two slow tests split by entries, `testAccessibilityDynamicType` into three
shards and `testDefaultSettings` into two (`WESTRON_ENTRY_SHARD`). The runner is about 3 times slower than a local Mac:
with the Button entries (PR #66, 2026-11-17) it took over 36.6 minutes for `testAccessibilityDynamicType`, past the
timeout, 32.4 minutes for `testDefaultSettings`, and 16–19 minutes for each of the others, against 627 s, 476 s and
194–196 s locally. The cost is eight parallel jobs, each with its own catalog build, about two runner-hours per run, so
the audit runs on every push to `main` and on a pull request only when it changes a path the audit depends on:
`platforms/apple/`, `tokens/`, `spec/`, `tools/apple/`, `Package.swift`, `Package.resolved`, `.xcode-version` or
`.github/workflows/ci.yml`. The job `audit-scope` decides, from the pull request's merge commit; otherwise the audit's
jobs show as skipped. If `audit-scope` itself fails, the audit runs. A job that nears its 35 minutes as pages are added
gets another shard.

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
  clock or on nothing. Such an element is not counted there; the screenful before showed it whole.
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
- An issue that is not the entry's fault, or that the catalog cannot fix, is suppressed one by one, with its reason,
  in `CatalogAccessibilityAuditTests.suppressions`; an audit type is never turned off as a whole.
- `WESTRON_ENTRY=<id>[,<id>…] tools/apple/check.sh a11y` audits those entries only: one while its issues are being
  fixed, or a share of the catalog.
- When a run ends, passed, failed or interrupted, the script stops the simulator's `testmanagerd` (launchd starts it
  again for the next test): after audits it has been seen to keep running at 400–1400 % CPU for hours with no test
  left (2026-11-17). A daemon that another `xcodebuild` on the same simulator still uses is left alone.
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
