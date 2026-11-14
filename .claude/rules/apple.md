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

- Tokens only. The hook and `npm run lint:raw-values` catch raw colors, sizes, spacing, radii, opacity and animation
  in `WestronUI`. An exception is `// westron-lint: allow <reason>`, with a real reason.
- Text goes through semantic text roles and `Font.custom(_:size:relativeTo:)`, so that Dynamic Type works.
  Scalable spacing goes through `@ScaledMetric`.

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
- The catalog project is `Catalog.xcodeproj/project.xcproj` in Xcode 27 format. Files are picked up from the
  `Catalog/` and `CatalogUITests/` folders automatically; edit the project only to change settings or targets.
- Look at the result: `tools/apple/catalog-screenshot.sh ios|macos --entry <id>` prints the path to the PNG.
  `ImageRenderer` and `cacheDisplay` do not work for this: on macOS they do not see SwiftUI content.
