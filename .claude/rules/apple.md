---
paths:
  - "platforms/apple/**"
  - "Package.swift"
---

# Rules for Apple (SwiftUI)

## API shape

- A style on top of a system control: `Button("Save") { … }.buttonStyle(.primary, size: .m)`.
  There are no custom wrapper types (`WButton`). A custom component only when there is no system one (Badge, Banner, EmptyState),
  and its name comes from the contract, with no prefix (decisions/0003).
- Enums of variants and sizes (`ButtonVariant`, `ButtonSize`) are generated from the contract. Do not write them by hand.
- Sizes are named `s`, `m`, `l`, as in the contract. The default takes `@Environment(\.controlSize)` into account.
- States that the system control does not have (for example, `loading`) are set with a modifier through the environment.
- A variant value must not match the name of a system style of the same control (`plain`, `bordered`,
  `borderedProminent`, `borderless`, `automatic`, `link`, `glass`, `glassProminent`), otherwise the call is ambiguous.

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
  - list colors: `Westron.Category(rawValue: name)` with `.background`, `.text`, …, as in
    `.foregroundStyle(list.color.text)`;
  - text: a text role in its text style, `.textRole(.heading.large)`, which applies the font and its tracking, or
    `Font(.body.regular)` where only a font fits (`.font(Font(.caption.medium).monospaced())`). `Font` has no westron
    statics, so SwiftUI's `Font.body` stays unambiguous. Headings in Onest and code in Geist Mono go through
    `Font.custom(_:size:relativeTo:)`, the rest `Font.system`. A view never calls either with a size of its own, so
    that Dynamic Type works (decisions/0011, 0013);
  - space, radius, stroke: `CGFloat.space100`, `.radius.card`, `.stroke.thin`; motion: `withAnimation(.move)`;
    shadow: `.shadow(.raised)`, which picks the layers of the environment's theme.
  - icons: `Image(Westron.Icon.sun)`, `Label("Rename", icon: .pen)`, not `Image(systemName:)` with a symbol spelled
    out; a stored name reads as `Westron.Icon(rawValue: name) ?? .fallback`. The names and their SF Symbols are in
    `spec/icons/icons.yaml` (decisions/0011).
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
  in the same pull request; the entry's `id` equals the component's `id` in the contract.
- The entry renders the matrix of variants, sizes and states from the contract, with no navigation inside.
- The snapshot matrix (#24) is generated from the contract into `WestronCatalog/Generated/<Component>+Matrix.swift`;
  the component adds the hand-written `<Component>MatrixCell`, which draws one combination with the real component.
  `tools/apple/snapshot-matrix.sh ios|macos` captures every sheet in four themes at `large` (on iOS also light at
  `xSmall` and `accessibility5`), with supplementary sheets marked "not a contract option", and prints the path to
  `index.html`.
- The catalog project is `Catalog.xcodeproj/project.xcproj` in Xcode 27 format. Files are picked up from the
  `Catalog/` and `CatalogUITests/` folders automatically; edit the project only to change settings or targets.
- Look at the result: `tools/apple/catalog-screenshot.sh ios|macos --entry <id>` prints the path to the PNG.
  `ImageRenderer` and `cacheDisplay` do not work for this: on macOS they do not see SwiftUI content.
