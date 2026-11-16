# westron for Apple

A SwiftUI library for iOS, iPadOS, macOS and watchOS. The package manifest lives at the repository root.

| Path | What is there |
|---|---|
| `Sources/WestronTokens/` | Token values as plain Swift with no imports, for a product's shared code and its WebAssembly build |
| `Sources/WestronUI/` | Styles, components and the SwiftUI accessors of the tokens: what products import |
| `Sources/WestronCatalog/` | Catalog entries, their host and launch arguments |
| `Tests/` | Package tests (Swift Testing) |
| `Catalog/` | Catalog app for iOS and macOS and its UI tests: screenshots and the accessibility audit |

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
`-WestronDynamicType <size>` set the conditions.

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

### Accessibility audit

`tools/apple/check.sh a11y` runs the UI test `CatalogAccessibilityAuditTests` on the iOS simulator (`iPhone 17` or
`$WESTRON_SIM_DEVICE`): it opens every entry of `Catalog.entries` in isolation, so a new entry is audited with no
change to the test, and runs `XCUIApplication.performAccessibilityAudit` on it. Every issue fails the test. CI runs it
in the `apple` job. The log goes to `.build/logs/a11y-ios.log`, the result bundle to
`.build/xcode/results/a11y-ios.xcresult`; the script prints each issue as a line starting with `a11y:`.

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
- The audit sees only what is on screen, so `testDefaultSettings` and `testAccessibilityDynamicType` audit a page a
  screenful at a time: the test waits until the page is still, audits it, drags it up by about two thirds of the
  screen without momentum, and stops when a drag no longer moves the page. The three theme tests audit the first
  screenful only: the pages are laid out to fit one at the default text size, and scrolling every page in every
  theme would take the run past 12 minutes.
- The Dynamic Type and text clipped audits change the system's text size, and after them the page's accessibility
  tree and its pixels disagree for a while: the next screenful's audit reads every text as failing contrast. In
  `testDefaultSettings` they run in a pass of their own, on a fresh launch for each screenful.
- The audit loses track of the cells of a lazy container (`LazyVGrid`, `List`, `Form`) when it changes the text
  size, and reports their text as not following Dynamic Type. A catalog page lays its content out eagerly: the
  sample grids with `AdaptiveGrid`, the same columns as an adaptive `LazyVGrid`, and the environment page with
  stacks in a scroll view rather than a `Form`.
- An issue that is not the entry's fault, or that the catalog cannot fix, is suppressed one by one, with its reason,
  in `CatalogAccessibilityAuditTests.suppressions`; an audit type is never turned off as a whole.
- `WESTRON_ENTRY=<id> tools/apple/check.sh a11y` audits one entry while its issues are being fixed.
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
