# Tools

| Path | What it does |
|---|---|
| `apple/xcode-env.sh` | Finds the Xcode from `.xcode-version` and sets `DEVELOPER_DIR` |
| `apple/check.sh` | Build, tests, format and catalog build for Apple; CI and the Stop hook run the same script |
| `apple/catalog-screenshot.sh` | Screenshot of a catalog entry on iOS or macOS |
| `lint/raw-values.ts` | The raw-values lint ("no raw values") for `WestronUI` |
| `generate/generate.ts` | Generator registry; `--check` compares the committed code with a fresh generation |

TypeScript runs on Node 24 without a build step: `npm test`, `npm run typecheck`, `npm run generate`.
