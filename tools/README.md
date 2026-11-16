# Tools

The westron generators and checks are a separate SwiftPM package (decisions/0009). It builds on macOS and Linux.

| Path | What it does |
|---|---|
| `westron` | Runs the `westron` executable: `lint raw-values`, `generate [--check]`, `tokens check`, `tokens contrast`, `icons check`. Builds the package if needed |
| `check.sh` | Builds and tests the package, then runs the lint, `generate --check`, `tokens check`, `tokens contrast` and `icons check`; CI runs it on Linux |
| `Sources/WestronTools/RawValues.swift` | The raw-values lint ("no raw values") for `WestronUI` |
| `Sources/WestronTools/Generate.swift` | Generator registry; `--check` compares the committed code with a fresh generation and reports stale files in the directories generators own |
| `Sources/WestronTools/Apple/` | The Apple token generator (`tokens-apple`): `WestronTokens` values, the `WestronUI` asset catalog and SwiftUI accessors (decisions/0010) |
| `Sources/WestronTools/Icons/` | The icon registry reader (`spec/icons/icons.yaml`, YAML through Yams) and the Apple icon generator (`icons-apple`): `Westron.Icon` and its SF Symbols (decisions/0011) |
| `Sources/WestronTools/Tokens/` | The DTCG token reader and resolver: parsing, the schema check, `dev.westron.*` keys, merging, references, modes (`Resolution`). [The supported subset](Sources/WestronTools/Tokens/README.md) |
| `Schemas/dtcg-2025.10/` | The official DTCG 2025.10 format and resolver JSON Schemas, copied unchanged, with their source and license |
| `Sources/WestronTools/Color/` | Color math after CSS Color 4: OkLCh, Oklab, XYZ, sRGB and Display P3, gamut mapping, hex, WCAG contrast, decimal format |
| `Sources/westron/` | The executable: argument parsing and output |
| `apple/xcode-env.sh` | Finds the Xcode from `.xcode-version` and sets `DEVELOPER_DIR` |
| `apple/check.sh` | Build, tests, format and catalog build for Apple; CI and the Stop hook run the same script |
| `apple/catalog-screenshot.sh` | Screenshot of a catalog entry on iOS or macOS |

Paths given to `tools/westron` are relative to the repository root. On macOS it uses the Xcode from `.xcode-version`,
on Linux the `swift` on `PATH`.
