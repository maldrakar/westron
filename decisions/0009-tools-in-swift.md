# 0009. Tools in Swift

Date: 2026-11-14. Status: accepted.

## Context

decisions/0004 first chose Style Dictionary 5, a Node library, as the token engine, so the tools were written
in TypeScript on Node to share its runtime. Since #51 the token generator is our own (decisions/0004), and Node
has no reason left to be in the repository.

## Decision

- Generators and checks are written in Swift, in a separate SwiftPM package `tools/` with one executable, `westron`.
  `tools/westron` runs it, and `tools/check.sh` builds it, tests it and runs its checks.
- The package is separate from the root package, so that its dependencies never reach the products that use westron.
- The tools build on macOS and Linux and use Foundation only. CI builds and tests them on Linux in the
  `swift:6.4-noble` container, which keeps them independent of Apple.
- Libraries are added with the first code that needs them, pinned to an exact version: Yams for the YAML contracts,
  swift-json-schema for validating token files against the DTCG JSON Schemas (draft-07), SwiftSyntax for lints
  that read Swift code (#21).
- Color conversion (OKLCH to sRGB and Display P3, with gamut mapping as in CSS Color 4) is our own code, tested
  against reference values. This changes decisions/0004, which expected a library.
- Hooks and scripts parse JSON with `plutil` and `jq`, which ship with macOS.

## Why Swift

- One language for the repository and the pilot, whose code is Swift throughout, including its WASM build.
- The generators write Swift, and the same toolchain builds them and the code they produce.
- Lints can read Swift through SwiftSyntax instead of regular expressions.
- A developer machine needs only Xcode.

## Costs

- Swift has no mature platform-neutral color library: the existing ones are small and tied to SwiftUI, which does not
  build on Linux. So color conversion is ours to maintain. The formulas and matrices are published in CSS Color 4.
- swift-json-schema is younger than Ajv (0.15, before 1.0) and implements draft 2020-12 only, while the DTCG schemas
  are draft-07. It validates them in part: it ignores tuple-form `items`, so the range of each color component and
  cubic Bézier coordinate goes unchecked. The token reader in `tools/` checks those itself (#13).
- A clean build of the tools takes longer than starting a script; incremental runs are fast. SwiftSyntax will make
  the clean build noticeably longer.
- The web library (phase 6) will need its own Node toolchain in `platforms/web/`. That does not move the tools.
