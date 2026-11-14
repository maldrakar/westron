# Tools

The westron generators and checks are a separate SwiftPM package (decisions/0009). It builds on macOS and Linux.

| Path | What it does |
|---|---|
| `westron` | Runs the `westron` executable: `lint raw-values`, `generate [--check]`. Builds the package if needed |
| `check.sh` | Builds and tests the package, then runs the lint and `generate --check`; CI runs it on Linux |
| `Sources/WestronTools/RawValues.swift` | The raw-values lint ("no raw values") for `WestronUI` |
| `Sources/WestronTools/Generate.swift` | Generator registry; `--check` compares the committed code with a fresh generation |
| `Sources/westron/` | The executable: argument parsing and output |
| `apple/xcode-env.sh` | Finds the Xcode from `.xcode-version` and sets `DEVELOPER_DIR` |
| `apple/check.sh` | Build, tests, format and catalog build for Apple; CI and the Stop hook run the same script |
| `apple/catalog-screenshot.sh` | Screenshot of a catalog entry on iOS or macOS |

Paths given to `tools/westron` are relative to the repository root. On macOS it uses the Xcode from `.xcode-version`,
on Linux the `swift` on `PATH`.
