# Tools

The westron generators and checks are a separate SwiftPM package (decisions/0009). It builds on macOS and Linux.

| Path | What it does |
|---|---|
| `westron` | Runs the `westron` executable: `lint raw-values`, `generate [--check]`, `tokens check`, `tokens contrast`, `icons check`, `spec check`. Builds the package if needed |
| `check.sh` | Builds and tests the package, then runs the lint, `generate --check`, `tokens check`, `tokens contrast`, `icons check` and `spec check`; CI runs it on Linux |
| `Sources/WestronTools/RawValues.swift` | The raw-values lint ("no raw values") for `WestronUI` |
| `Sources/WestronTools/Generate.swift` | Generator registry; `--check` compares the committed code with a fresh generation and reports stale files in the directories generators own |
| `Sources/WestronTools/Apple/` | The Apple token generator (`tokens-apple`): `WestronTokens` values, the `WestronUI` asset catalog and SwiftUI accessors (decisions/0010) |
| `Sources/WestronTools/Icons/` | The icon registry reader (`spec/icons/icons.yaml`, YAML through Yams) and the Apple icon generator (`icons-apple`): `Westron.Icon` and its SF Symbols (decisions/0011) |
| `Sources/WestronTools/Contracts/` | The component contract check (`spec check`): YAML through Yams, the schema `spec/schema/component.schema.json` through swift-json-schema, then the rules a schema cannot express, such as no option value named like a system style (decisions/0003), bound tokens that exist, every case of a binding reachable (`CaseReachability.swift`) and every value reaching one each Apple OS offers (`spec/components/README.md`, "Check"). And the Swift API generator (`components-apple`, #20): it runs the same check first, then, from each approved contract styled on an Apple system control, writes `WestronUI/Generated/<Component>+Contract.swift` with the enums of its options, the style overload that applies the hand-written `<Component>VariantStyle`, the `controlSize` mapping, each OS's fallbacks and the states (`spec/conventions.md`). `SwiftUITypes.swift` is generated: SwiftUI's public type names, which a generated name must not take (below) |
| `Sources/WestronTools/Tokens/` | The DTCG token reader and resolver: parsing, the schema check, `dev.westron.*` keys, merging, references, modes (`Resolution`). [The supported subset](Sources/WestronTools/Tokens/README.md) |
| `Schemas/dtcg-2025.10/` | The official DTCG 2025.10 format and resolver JSON Schemas, copied unchanged, with their source and license |
| `Sources/WestronTools/Color/` | Color math after CSS Color 4: OkLCh, Oklab, XYZ, sRGB and Display P3, gamut mapping, hex, WCAG contrast, decimal format |
| `Sources/westron/` | The executable: argument parsing and output |
| `apple/xcode-env.sh` | Finds the Xcode from `.xcode-version` and sets `DEVELOPER_DIR` |
| `apple/check.sh` | Build, tests, format and catalog build for Apple; CI and the Stop hook run the same script |
| `apple/catalog-screenshot.sh` | Screenshot of a catalog entry on iOS or macOS |

Paths given to `tools/westron` are relative to the repository root. On macOS it uses the Xcode from `.xcode-version`,
on Linux the `swift` on `PATH`.

## SwiftUI's type names

The API generator refuses a generated name that would shadow a public SwiftUI type, such as `MenuOrder` for a `menu`
contract's option `order` (#62). The tools build on Linux, where there is no SDK, so the names are a checked-in file,
`Sources/WestronTools/Contracts/SwiftUITypes.swift`: the public top-level types of the SwiftUI and SwiftUICore module
interfaces of the macOS, iOS and watchOS SDKs of the Xcode in `.xcode-version`. On macOS, `SwiftUITypesTests` reads
those interfaces and fails while the file differs from them; it also checks that every style modifier in
`SystemStyles.swift` exists. After `.xcode-version` changes, refresh the file from the repository root:

```sh
source tools/apple/xcode-env.sh && WESTRON_REFRESH_SWIFTUI_TYPES=1 swift test --package-path tools --filter SwiftUITypesTests
```
