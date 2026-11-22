---
paths:
  - "platforms/apple/**"
  - "Package.swift"
---

# Rules for Apple (SwiftUI)

## API shape

- A style on top of a system control: `Button("Save") { … }.buttonStyle(.primary, size: .m)`. There are no custom
  wrapper types (`WButton`). The contract's `platforms.apple.strategy` gives the shape (decisions/0003,
  `spec/conventions.md`):
  - `style-on-system-control`: a generated overload of the control's style modifier, as above;
  - `extension-on-system-control`, for a system view with no style modifier: a hand-written modifier named after what
    it sets, `Text("Inbox").textRole(.heading.medium)`;
  - `own-component`, only when there is no system control or as an exception the decision records (decisions/0003,
    "Exceptions in phase 3"): named as in the contract, with no prefix, in the `platforms.apple.form` it names,
    `modifier` (`.surface(.raised)`) or `view` (`Rule()`, `Icon(.tray)`). Only its enums are generated; the modifier
    or view is hand-written in `WestronUI/<Component>/`, and `tools/westron lint api-parity` holds it to the contract.
- Enums of variants and sizes (`ButtonVariant`, `ButtonSize`, `SurfaceVariant`) are generated from the contract. Do
  not write them by hand.
- Sizes are named `s`, `m`, `l`, as in the contract. The default takes `@Environment(\.controlSize)` into account.
- States that the system control does not have (for example, `loading`) are set with a modifier through the environment.
- No option value may be the static name of a system style of the same control: `.buttonStyle(.plain)` would still
  compile and silently take westron's overload, which shadows the system style (decisions/0003, note of 2026-11-18).
  `tools/westron spec check` rejects it; the names per control are in
  `tools/Sources/WestronTools/Contracts/SystemStyles.swift`.
- What exists, before you draw your own (each per `spec/components/<id>/`): `.buttonStyle(_:size:iconOnly:)` with
  `.loading(_:)`, `.textFieldStyle(.framed|.inline, size:leadingIcon:trailingIcon:)` (decorative glyphs, each
  optional, naming what the field is for and never an action: no microphone, clear mark or chevron; a search field is
  `TextField("Search", text: $query, prompt: Text("Search").foregroundStyle(.text.placeholder))` with
  `.textFieldStyle(.framed, leadingIcon: .magnifier)`, `.accessibilityLabel("Search")` and
  `.accessibilityAddTraits(.isSearchField)`, or the system's `.searchable` where the system places it),
  `.toggleStyle(.check)` (Checkbox), `.toggleStyle(.chip)`, `.buttonStyle(.chip)` and `.labelStyle(.chip)` (Chip),
  `.textRole(_:)`, `Icon(_:)` and `Icon(_:label:)`, `IconTile(_:)` and `IconTile(_:label:)` (a list's tile in the
  `.category(_:)` of its context, neutral with none), `.surface(.raised|.dragged|.sunken, outlined:)`,
  `Rule(axis:purpose:)` and `Rule("Label")`.
  A check beside a separate title draws no label: `Toggle(isOn: $task.isDone, accessibilityLabel:
  task.title).toggleStyle(.check)`, not `.labelsHidden()`, which a custom style sees only from iOS 18, macOS 15 and
  watchOS 11, so on iOS 17 the label would be drawn (`spec/components/checkbox/decisions/0002`).

## Values

- Tokens only. The hook and `tools/westron lint raw-values` catch raw colors, sizes, spacing, radii, opacity and animation
  in `WestronUI`. An exception is `// westron-lint: allow <reason>`, with a real reason.
- Tokens come from `tools/westron generate` (decisions/0010): never edit `WestronTokens/Generated/`,
  `WestronUI/Generated/` or `WestronUI/Tokens.xcassets`; change the tokens and generate again. Names follow the token
  path, a member per segment, without the group the type already names; a step joins its ladder (`space100`):
  - colors: `.foregroundStyle(.text.secondary)`, `.background(.background.surface)`, `.fill`, `.stroke`,
    `.strokeBorder` and `.tint` take a `Westron.Color` through WestronUI's overloads; any other call takes
    `Color(.text.secondary)`, and so do a color's own modifiers (`Color(.text.secondary).opacity(0.5)`). Colors
    come from colorsets, so they switch with the theme and the contrast setting by themselves;
  - list colors: `Westron.Category(rawValue: name)` with `.background`, `.text`, `.icon`, …, as in
    `.foregroundStyle(list.color.text)`. A westron control drawn in its list's color (a checked Checkbox, in the
    color's `control` and `onControl`) reads it from `.category(_:)`, set once around the row as `.tint(_:)` is
    (`WestronUI/Category.swift`, decisions/0012);
  - text: a text role in its text style, `.textRole(.heading.large)`, which applies the font, its tracking at the
    drawn size and, under Bold Text, a role in Onest or Geist Mono a weight up (up to Onest ExtraBold, Geist Mono Bold);
    or `Font(.body.regular)` where only a font fits (`.font(Font(.caption.medium).monospaced())`), with neither.
    Inside `Text` interpolation, `Text(count).textRole(.footnote.medium)` takes the disfavoured `Text` twin, which
    reads no environment; a role in a variable needs the part typed first, `let part: Text = …` (the comment above
    it in `TokenAdapters.swift`). `Font` has no westron statics, so SwiftUI's `Font.body` stays unambiguous. Headings
    in Onest and code in Geist Mono go through `Font.custom(_:size:relativeTo:)`, the rest, and every role on
    watchOS, `Font.system`. A view never calls either with a size of its own, so that Dynamic Type works
    (decisions/0011, 0013, `spec/components/text/`);
  - space, radius, stroke: `CGFloat.space100`, `.radius.card`, `.stroke.thin`; where space has a role, the role, not
    its step: `.space.card`, `.space.withinGroup`, `.space.betweenGroups`, and `.space.page.narrow` / `.wide` for
    layout the product builds itself, not a system List, Form or bar (design-language/06, decisions/0013);
    motion: `withAnimation(.move)`; shadow: `.shadow(.raised)`, which picks the layers of the environment's theme.
  - icons: `Icon(.tray)`, decorative and hidden from assistive technology, or `Icon(.sun, label: "Today")` when it
    means something; it takes its size and weight from the text role around it and its color from the context (no
    color option), `.imageScale(_:)` for a relative size. `Image(_: Westron.Icon)` where only an `Image` fits, and
    `Label("Rename", icon: .pen)`, also in a `Menu`, which an `Icon` breaks, are adapters that keep the symbol's
    system name; never `Image(systemName:)` with a symbol spelled out. A stored name reads as
    `Westron.Icon(rawValue: name) ?? .fallback`. The names and their SF Symbols are in `spec/icons/icons.yaml`
    (decisions/0011, `spec/components/icon/`).
- Scalable spacing goes through `@ScaledMetric`, with a token as its base value.
- The adapters from WestronTokens values to SwiftUI values are hand-written in `WestronUI/TokenAdapters.swift`.
  `WestronTokens` imports nothing, not even Foundation: shared code and its WebAssembly build use it.

## Platforms

- Minimum: iOS 17, macOS 14, watchOS 10. Liquid Glass and other 26+ APIs go inside `if #available(iOS 26, macOS 26,
  watchOS 26, *)` with an honest fallback for older systems (decisions/0008).
- Liquid Glass is for controls and navigation, not for the content layer (HIG Materials).
- watchOS gets a reduced subset; what exists on the watch is recorded in the contract's `platforms` block.
- Hover, keyboard focus and pointer are states that touch-based iOS and watchOS simply never enter.
- Code that only one platform needs goes behind `#if os(...)`; the package must compile for all three
  (`tools/apple/check.sh platforms`).

## Swift

- Swift 6, strict concurrency. Views and their helpers are `@MainActor`.
- Package tests use Swift Testing (`import Testing`). Catalog UI tests use XCTest, because XCUITest requires it.
- Formatting: `swift format` with the `.swift-format` config; the hook formats the file after every edit.

## Catalog

- Every component adds an entry to `Catalog.entries` (`platforms/apple/Sources/WestronCatalog/Catalog.swift`)
  in the same pull request; the entry's `id` equals the component's `id` in the contract. The accessibility audit
  (`tools/apple/check.sh a11y`) walks every entry, not the matrix sheets.
- The entry renders the matrix of variants, sizes and states from the contract, with no navigation inside.
- The snapshot matrix (#24) is generated from the contract into `WestronCatalog/Generated/<Component>+Matrix.swift`;
  the component adds the hand-written `<Component>MatrixCell` (in `WestronCatalog/Components/<Component>Pages.swift`),
  which draws one combination with the real component, and what no option sets as a supplement, defined in the same
  file (`extension ComponentMatrix.Supplement`) and registered in `Supplement.all`
  (`SnapshotMatrix/Supplements.swift`). `tools/apple/snapshot-matrix.sh ios|macos [--component a,b]` renders every
  sheet, or those components', in-process (the unit tests in `platforms/apple/Tests/WestronSnapshotTests`), in four
  themes at `large` (on iOS also light at `xSmall` and `accessibility5`), with supplementary sheets marked "not a
  contract option", and prints the path to `index.html`; `compare` diffs two renders of one environment within one
  level. The references in `platforms/apple/Snapshots/` are the CI runner's, recorded only there; `check` against them
  is CI's job `snapshots`, and locally it reports that the environment differs (platforms/apple/README.md, "Snapshot
  matrix").
- The catalog project is `Catalog.xcodeproj/project.xcproj` in Xcode 27 format. Files are picked up from the
  `Catalog/` and `CatalogUITests/` folders automatically, and the hosted bundle `CatalogSnapshotTests` takes
  `../Tests/WestronSnapshotTests`; edit the project only to change settings or targets.
- Look at the result: `tools/apple/catalog-screenshot.sh ios|macos --entry <id>` prints the path to the PNG.
  `ImageRenderer` and `cacheDisplay` misdraw system controls; the matrix's in-process paths are `drawHierarchy` in the
  hosted iOS bundle and `CARenderer` on macOS (decisions/0008).
