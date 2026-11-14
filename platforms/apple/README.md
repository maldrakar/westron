# westron for Apple

A SwiftUI library for iOS, iPadOS, macOS and watchOS. The package manifest lives at the repository root.

| Path | What is there |
|---|---|
| `Sources/WestronUI/` | Styles and components: what products import |
| `Sources/WestronCatalog/` | Catalog entries, their host and launch arguments |
| `Tests/` | Package tests (Swift Testing) |
| `Catalog/` | Catalog app for iOS and macOS and the screenshot UI test |

## Adding the package

```swift
.package(url: "https://github.com/maldrakar/westron", from: "0.1.0")
// …
.product(name: "WestronUI", package: "westron")
```

## Catalog

Open in Xcode 27.1: `platforms/apple/Catalog/Catalog.xcodeproj`. Without arguments, the catalog shows navigation
across all entries. With `-WestronEntry <id>`, it shows one entry full screen; this is how
`tools/apple/catalog-screenshot.sh` captures it.

### Screenshots on macOS: turn on Automation Mode once

The UI tests on macOS that take the screenshots require Automation Mode. To turn it on without a password prompt
on every run:

```sh
sudo automationmodetool enable-automationmode-without-authentication
```

Why not `screencapture` and not an in-process capture: see decisions/0008.
