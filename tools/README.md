# Tools

The westron generators and checks are a separate SwiftPM package (decisions/0009). It builds on macOS and Linux.

| Path | What it does |
|---|---|
| `westron` | Runs the `westron` executable: `lint raw-values`, `lint api-parity`, `generate [--check]`, `tokens check`, `tokens contrast`, `icons check`, `spec check`. Builds the package if needed |
| `check.sh` | Builds and tests the package, then runs the raw-values lint, `generate --check`, `tokens check`, `tokens contrast`, `icons check`, `spec check` and the API parity lint; CI runs it on Linux |
| `Sources/WestronTools/RawValues.swift` | The raw-values lint ("no raw values") for `WestronUI` |
| `Sources/WestronTools/APIParity/` | The API parity lint (#21, below): `SwiftDeclarations.swift` reads declarations and their effective access with swift-syntax, `APIParity.swift` derives the expected API from the contracts and compares |
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
`SystemStyles.swift` exists. CI runs it in the `apple` job, which runs the tools tests on macOS too. After
`.xcode-version` changes, refresh the file from the repository root:

```sh
source tools/apple/xcode-env.sh && WESTRON_REFRESH_SWIFTUI_TYPES=1 swift test --package-path tools --filter SwiftUITypesTests
```

## The API parity lint

`tools/westron lint api-parity` checks that the public API of `platforms/apple/Sources/WestronUI` is exactly the
component API the contracts give through `spec/conventions.md` (AGENTS.md, rules 4 and 5; #21). The generator makes
the names equal by construction; the lint checks the result from the sources, so hand-written code cannot quietly add,
rename or drop component API. It prints `file:line: message` for each problem and exits with 1.

**Expected**, from each contract that is approved or later and styled on an Apple system control, as the generator
decides (`AppleComponents.generates`):

- `public enum <Component><Option>: String, CaseIterable, Sendable` for each enum option not in
  `platforms.apple.systemOptions`: the contract's values as cases, in order, raw values as written, no other public
  member or conformance. Button: `ButtonVariant` (`primary`, `secondary`, `tertiary`) and `ButtonSize` (`s`, `m`,
  `l`); `role` is `SwiftUI.ButtonRole`, so no `ButtonRole`;
- in `extension View`, the overload of the base's style modifier: the variant unlabeled, with a default only when the
  contract gives one, then the other options in the contract's order, labeled; `size: <Component>Size? = nil`; a bool
  option `<name>: Bool = <default>`; no attributes, generics or effects; `-> some View`. Button:
  `public func buttonStyle(_ variant: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false) -> some View`;
- in `extension View`, one shared modifier per state the system control lacks, named as the state:
  `public func loading(_ isLoading: Bool) -> some View`. The system's states are pressed, hover, focus and disabled,
  for every control, as the conventions name them (`APIParity.systemStates`); a contract does not mark them.

**The boundary.** Component API is: a type named after a component (`Button…` for `button`), a member or a
conformance of one, an overload of a style modifier (`SystemStyles`), a function named after a component
(`buttonLoading`) or as a contract's state, and a type named like component API of no contract (`…Variant`, `…State`,
`…Style`, or conforming to a `…Style` protocol). Component API that no contract gives is an error, with the reason when
its contract is draft or its Apple strategy gives no API yet. The token area is three files, `TokenAdapters.swift`,
`Generated/Tokens+SwiftUI.swift` and `Generated/Icons+SwiftUI.swift` (`APIParity.tokenArea`): its token accessors,
adapters and icons are not compared with contracts, and it may only extend existing types, so a new public top-level
type there is an error. Any other public declaration in `WestronUI` is an error, so new public API cannot appear
unnoticed: add it to a contract, or, if it is token API, to the token area.

**Per OS.** A public declaration under `#if` is an error: a component's public API is the same on every Apple OS, and
`platforms.apple.<os>` entries act through the style's fallbacks (`offered`), not through the API.

**Exceptions.** `// westron-lint: allow <reason>` on the declaration's line or a comment line just above excuses it
from the last three rules, never from the expected API. Access is the effective one: a `public` member of an internal
type is not public, a member of a `public extension` is.

**Not checked:** doc comments; the bodies (what a style draws, that `.loading(_:)` sets the environment, that the
overload applies `<Component>VariantStyle`): the build, `generate --check` and `spec-reviewer` cover them; type
spellings are compared as written, so `Optional<ButtonSize>` differs from `ButtonSize?`; own components, whose API
conventions question Q2 leaves open; public API of `WestronTokens`.

**swift-syntax** (`exact: "604.0.0"`) is the parser: Swift's own, so the lint reads exactly what the compiler reads,
`#if` clauses, attributes and effects included, where a regular expression parser would guess. It is the version
swift-json-schema already resolves for Swift 6.4, so the package resolves one copy. It builds from source in debug: on
an M4 Pro with Xcode 27.1, a clean `swift build` of `tools/` went from 12 s to 18 s, `swift build --build-tests` from
18 s to 21 s (CPU time 34 s to 76 s); a runner with fewer cores pays more.
