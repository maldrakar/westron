# Tools

The westron generators and checks are a separate SwiftPM package (decisions/0009). It builds on macOS and Linux.

| Path | What it does |
|---|---|
| `westron` | Runs the `westron` executable: `lint raw-values`, `lint api-parity`, `generate [--check]`, `tokens check`, `tokens contrast`, `icons check`, `spec check`, `patterns check`. Builds the package if needed |
| `check.sh` | Builds and tests the package, then runs the raw-values lint, `generate --check`, `tokens check`, `tokens contrast`, `icons check`, `spec check`, `patterns check` and the API parity lint; CI runs it on Linux |
| `Sources/WestronTools/RawValues.swift` | The raw-values lint ("no raw values") for `WestronUI` |
| `Sources/WestronTools/APIParity/` | The API parity lint (#21, below): `SwiftDeclarations.swift` reads declarations and their effective access with swift-syntax, `APIParity.swift` derives the expected API from the contracts and compares |
| `Sources/WestronTools/Generate.swift` | Generator registry; `--check` compares the committed code with a fresh generation and reports stale files in the directories generators own |
| `Sources/WestronTools/Apple/` | The Apple token generator (`tokens-apple`): `WestronTokens` values, the `WestronUI` asset catalog and SwiftUI accessors (decisions/0010) |
| `Sources/WestronTools/Icons/` | The icon registry reader (`spec/icons/icons.yaml`, YAML through Yams) and the Apple icon generator (`icons-apple`): `Westron.Icon` and its SF Symbols (decisions/0011) |
| `Sources/WestronTools/Contracts/` | The component contract check (`spec check`): YAML through Yams, the schema `spec/schema/component.schema.json` through swift-json-schema, then the rules a schema cannot express, such as no option value named like a system style (decisions/0003), bound tokens that exist, every case of a binding reachable (`CaseReachability.swift`) and every value reaching one each Apple OS offers (`spec/components/README.md`, "Check"). And the Swift API generator (`components-apple`, #20): it runs the same check first, then, from each approved contract styled on an Apple system control, writes the enums of its options into `WestronContract/Generated/<Component>+Contract.swift`, a module with no imports (decisions/0017), and the SwiftUI side into `WestronUI/Generated/<Component>+Contract.swift`: the style overload that applies the hand-written `<Component>VariantStyle`, the `controlSize` mapping, each OS's fallbacks and the states (`spec/conventions.md`); from each approved own component (`platforms.apple.form`, `AppleOwnComponents.swift`), the enums of its options into `WestronContract/Generated/` and its states and forms, when it has any, into `WestronUI/Generated/`. The snapshot matrix generator (`matrix-apple`, #24, `SnapshotMatrix.swift` and `AppleSnapshotMatrix.swift`) reads the same contracts and writes each one's matrix into the catalog, `WestronCatalog/Generated/<Component>+Matrix.swift`, with `ComponentMatrix+All.swift` listing them: every option value (a bool as `false` and `true`) at rest and in each state alone, less the combinations a constraint of severity `error` forbids, what each Apple OS draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures (`platforms/apple/README.md`, "Snapshot matrix"). `SwiftUITypes.swift` is generated: SwiftUI's public type names, which a generated name must not take (below) |
| `Sources/WestronTools/Patterns/` | The pattern check (`patterns check`, decisions/0018, below): `Pattern.swift` reads a pattern's front matter through Yams and its sections, `PatternCheck.swift` holds them, `PatternNames.swift` holds the names its Swift example and prose write to WestronUI's API with swift-syntax |
| `Sources/WestronTools/Context/` | The agent context generator (`agent-context`, decisions/0016): the bundle of the westron plugin's skill, `plugins/westron/skills/westron/context/`, and `llms.txt`; `ContextPatterns.swift` copies each approved pattern into it, lists it in the index and names it on its components' cards |
| `Sources/WestronTools/Tokens/` | The DTCG token reader and resolver: parsing, the schema check, `dev.westron.*` keys, merging, references, modes (`Resolution`). [The supported subset](Sources/WestronTools/Tokens/README.md) |
| `Schemas/dtcg-2025.10/` | The official DTCG 2025.10 format and resolver JSON Schemas, copied unchanged, with their source and license |
| `Sources/WestronTools/Color/` | Color math after CSS Color 4: OkLCh, Oklab, XYZ, sRGB and Display P3, gamut mapping, hex, WCAG contrast, decimal format |
| `Sources/westron/` | The executable: argument parsing and output |
| `apple/xcode-env.sh` | Finds the Xcode from `.xcode-version` and sets `DEVELOPER_DIR` |
| `apple/check.sh` | Build, tests, format and catalog build for Apple; CI and the Stop hook run the same script |
| `apple/audit-scope.sh` | The catalog entries a pull request's accessibility audit covers, from its changed paths (`.github/workflows/ci.yml`); `apple/audit-scope-test.sh` tests it against the repository (`tools/check.sh audit-scope`) |
| `apple/catalog-screenshot.sh` | Screenshot of a catalog entry on iOS or macOS |
| `apple/snapshot-matrix.sh` | The snapshot matrix (#24, #92) on iOS or macOS, rendered in-process by unit tests, with its review page; the pixel comparison of two renders, the check against the references in `platforms/apple/Snapshots/` and their recording; `apple/snapshot-pages.swift` builds the pages and compares the images |

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
  option `<name>: Bool = <default>`; `-> some View`. Button:
  `public func buttonStyle(_ variant: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false) -> some View`;
- in `extension View`, one shared modifier per state the base control does not carry itself, named as the state:
  `public func loading(_ isLoading: Bool) -> some View`. What a control carries is in `SystemStyles.swift`, per base,
  next to its modifier and style names: Button carries pressed, hover, focus and disabled. A contract does not mark
  them; a base the file does not know is an error.

**Own components.** From each approved `own-component` with its `platforms.apple.form` (`AppleComponents.Own`): the
enums of its enum options, as above, and either, for `form: modifier`, the modifier in `extension View`, named after
the component, the variant unlabeled first and every other option labeled with its default (Surface:
`public func surface(_ variant: SurfaceVariant, outlined: Bool = false) -> some View`), or, for `form: view`, a
public struct named after the component that conforms to `View` alone, with one public initializer whose parameters
are the options, labeled with their defaults, and `public var body: some View` (Rule: `public init(axis: RuleAxis =
.horizontal)`; `APIParity.checkViews`). Any other public member of the view's type is component API no contract gives.
The generator writes only the enums; the modifier or the view is hand-written (`spec/conventions.md`, "Own
components"). An icon's view is derived too (Icon, #28): its option whose values are icons is the first, unlabeled
parameter, `Westron.Icon`, its one slot `label` gives the decorative initializer (unless the label is required) and
the two labeled ones (`AppleOwnComponents.swift`, `labelInitializers`), and its system options
(`platforms.apple.systemOptions`, Icon's `scale`) are the system's own modifiers, no parameter. A shape the
conventions do not derive yet (states, a `size` option, an option of tokens, icons on a modifier or a second icons
option, a restriction, several slots of a modifier, a variant of a view or slots of one other than an icon's `label`)
is reported, as generation reports it.

**A label that is not drawn.** From each such contract with `accessibility.hiddenLabel: true` (`AppleComponents.HiddenLabel`,
Checkbox, #86): two initializers of the base control in an extension with the `where` clause
`where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier>`, the base's own parameters before its
label (`SystemStyles.Base.hiddenLabelParameters`) and then the required name, `accessibilityLabel: LocalizedStringKey`,
and `@_disfavoredOverload` `accessibilityLabel: S` with `<S: StringProtocol>`. Toggle:
`public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey)`. Each is reported missing, changed (another
`where` clause or extras), or not public (`APIParity.checkHiddenLabels`); they are hand-written, and a base with no
parameters in `SystemStyles` fails `spec check` as not derived yet (`spec/conventions.md`, "A label that is not drawn").

**Constraints and attributes.** An extension's attributes, modifiers and `where` clause count as its members' own, so
`extension View where Self: Equatable { … buttonStyle … }` differs from the expected API. Expected API takes no
generics, effects or `where` clause, and only the attributes that change nothing about where or how a product calls
it: `@MainActor`, `nonisolated`, `@inlinable`, `@ViewBuilder`, `@discardableResult`, `@preconcurrency`
(`APIParity.harmlessExtras`). Any other is a difference: `@available` and `@backDeployed` narrow where it can be
called, `@_spi` who can call it, `@_disfavoredOverload` which overload a call takes.

**The boundary.** Component API is: a type named after a component (`Button…` for `button`), a member or a
conformance of westron's own such type, a member of an extension of a control's style protocol (`extension
PrimitiveButtonStyle { static var primary }`, which makes `.buttonStyle(.primary)`), an overload of a style modifier
(`buttonStyle`, or any `…Style` modifier other than `foregroundStyle` and `backgroundStyle`), a function named after a
component (`buttonLoading`) or as a contract's state, and a type named like component API of no contract (`…Variant`,
`…State`, `…Style`, or conforming to a `…Style` protocol). Component API that no contract gives is an error, with the
reason when its contract is draft or its Apple strategy gives no API yet. Any other public modifier on `View` is an
error too. Two kinds of file hold the rest of the public API. The generated token files, `Generated/Tokens+SwiftUI.swift`
and `Generated/Icons+SwiftUI.swift`, are what the token and icon generators write and `generate --check` guards:
there any public member of an extension of an existing type is fine, nested types included, and only a new top-level
type is an error. The hand-written `TokenAdapters.swift` may declare only the reviewed adapters, `APIParity.adapters`:
public initializers and instance methods on the types and with the names the list gives (`Color.init`,
`View.foregroundStyle`, `Label.init`, …), each taking a `Westron.*` value or extending a `Westron.*` type. The list is
what the file declared when the lint was written; a new adapter is added to it in the same pull request, where review
sees it. `View.category(_: Westron.Category?)` in `Category.swift`, the list color a westron style reads from the
context, is no adapter: the contracts that read it declare it (`reads: category`), and the lint expects it once for
all of them, as a shared state modifier (#167; it was a reviewed adapter of its own file from #31). The adapters are
checked before the component rules, so a contract named `label` or `text` does not claim `Label.init(_:icon:)` or
`.textRole(_:)`, while a new `LabelTint` type or a `labelStyle` overload is still its API.
Any other public declaration in `WestronUI` is an error, so new public API cannot appear unnoticed. `package` and
internal declarations are not public API, so catalog hooks with `package` access pass.

**Per OS.** A public declaration under `#if` is an error: a component's public API is the same on every Apple OS, and
`platforms.apple.<os>` entries act through the style's fallbacks (`offered`), not through the API.

**Exceptions.** `// westron-api-parity: allow <reason>` on the declaration's line or a comment line just above excuses
it from every rule but the expected API. It is this lint's own marker: the raw-values lint's `// westron-lint: allow`
does not excuse public API, and this marker does not contain that one, so it does not excuse a raw value either.
Access is the effective one: a `public` member of an internal type is not public, a member of a `public extension`
is.

**Not checked:** doc comments; the bodies (what a style draws, that `.loading(_:)` sets the environment, that the
overload applies `<Component>VariantStyle`): the build, `generate --check` and `spec-reviewer` cover them; type
spellings are compared as written, so `Optional<ButtonSize>` differs from `ButtonSize?`; an own component's
internal stored properties and helpers; public API of `WestronTokens`; the content of the generated token files beyond
the boundary above, which `generate --check` guards.

**swift-syntax** (`exact: "604.0.0"`) is the parser: Swift's own, so the lint reads exactly what the compiler reads,
`#if` clauses, attributes and effects included, where a regular expression parser would guess. It is the version
swift-json-schema already resolves for Swift 6.4, so the package resolves one copy. It builds from source in debug: on
an M4 Pro with Xcode 27.1, a clean `swift build` of `tools/` went from 12 s to 18 s, `swift build --build-tests` from
18 s to 21 s (CPU time 34 s to 76 s); a runner with fewer cores pays more.

## The pattern check

`tools/westron patterns check [FILE.md …]` checks every `spec/patterns/*.md`, or the files given (decisions/0018,
point 2). It reads the contracts that pass `spec check`, the token model, the icon registry and the API the parity lint
derives from the contracts, and prints `file:line: message` for each problem, exiting with 1:

- the front matter: a block between two lines `---` at the top, a YAML mapping with exactly the keys `id`, `title`,
  `status`, `summary`, `consumers`, `components`, `tokens`, `icons` and `gaps`; the first four non-empty strings, the
  rest lists of strings, `consumers` and `components` not empty; `id` kebab-case and the file's name; `status`
  `proposed` or `approved`; each consumer `<product>/<screen>`, as a contract's;
- each id of `components` has a contract, each name of `tokens` is a token's source name in the model
  (`space.page.narrow`, not the Swift member), each of `icons` is in the registry;
- the first heading is the `title`; the level-two sections are "When to use", "Parts", "Rules", "Accessibility",
  "Apple", "Not covered" and "Gaps", each once and in this order, and "Questions" only in a proposed pattern, last;
  headings inside a fenced block are code. A later platform's section is added to `PatternCheck.sections` with it;
- "Apple" holds exactly one fenced block ```` ```swift ````;
- each id of `gaps` has an entry `- **G3** …` in "Gaps", and each entry is in `gaps`;
- the names the example and the prose write are WestronUI's (`PatternNames`, on the names `ContextNames` gives the
  bundle's own prose): in the example, read by swift-syntax, an implicit member chain of two names or more
  (`.space.page.narrow`, `.text.secondary`) is a token's Swift member; a call of a westron view (`ListRow(…) { … }
  leading: { … }`, `WestronUI.Icon(.check)`) or function (`.selected(_:)`, `.textRole(_:)`) fits one of its declared
  initializers or overloads by labels, defaults and trailing closures; an argument written `.name` is a value of its
  parameter's type (an icon, a list color, a text role, an option's value). In the prose, a code span that starts with
  a token's first name and is dotted (`footnote.regular`, `space.within-group`) is a token's path or Swift member, and
  any other code span is read as Swift and held as the example is. SwiftUI's own calls and the product's names are not
  checked: without the SDK they cannot be told from a typo, and the pattern's catalog example compiles them. A lone
  unlabeled argument of a system style modifier, `.buttonStyle(.plain)`, may be SwiftUI's own style and passes.

`tools/westron generate` runs the same check on every pattern, proposed ones too, before it writes the bundle, and
copies only the approved ones (`Sources/WestronTools/Context/ContextPatterns.swift`): to `context/patterns/<id>.md`
without the front matter, with a line under the title of its id, status, consumers and links to its components' cards,
its links rewritten as the chapters' are (a link to a file the bundle holds points to the copy, any other link to the
repository becomes its text; fenced code is left alone); one line per pattern in the index's and `llms.txt`'s section
"Patterns", from `title` and `summary`; and a line "Patterns that use it" on the card of each component in
`components`.
