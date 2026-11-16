# westron

A design system for everyday and technical products with a cross-platform core and a native UI on each platform.

**Status:** phase 1 "Design language and tokens". There are DTCG tokens in four themes with a palette generator and a contrast check, the Apple token output (`WestronTokens`, `WestronUI`), a catalog app for iOS and macOS with screenshots, CI and a Claude Code setup. There are no components yet. The pilot product is [todo-app](https://github.com/maldrakar/todo-app): its screens decide which components come first, and it is the first to adopt westron's look.

## The idea

- **One design language and one data source.** Tokens, component contracts and design language documents live in this repository and belong to no single platform.
- **A native library for each platform.** Apple (iOS, iPadOS, macOS, watchOS) in SwiftUI, web, Linux (GNOME: GTK4 + libadwaita), later Android (Compose).
- **Identical names.** The values of variants, sizes and states are generated from the contract, so they match on every platform.
- **System controls over custom ones.** If a platform has a native component, westron gives it a style and extensions, not a replacement.

```swift
Button("Save") { save() }
    .buttonStyle(.primary, size: .m)
```

## How the work goes

The pilot platform is Apple. Components appear in SwiftUI first, then move to web and Linux from the same contracts.

Phases are tracked as [milestones](../../milestones), tasks as [issues](../../issues). Each component passes three approval gates, all held by the human: contract, screenshot matrix, release.

## What lives where

| Path | Contents |
|---|---|
| `decisions/` | Accepted decisions (ADR) |
| `design-language/` | Design language (phase 1) |
| `tokens/` | DTCG tokens and the mode resolver (phase 1) |
| `spec/components/` | Component contracts (phase 2) |
| `platforms/apple/` | SwiftUI library and catalog app |
| `tools/` | Generators, checks and scripts |
| `reports/` | Final research report |
| `research_notes/` | Research notes with sources |

Build and check commands are in [AGENTS.md](AGENTS.md).

## License

Code, tokens and contracts: [MIT](LICENSE). Design language texts in `design-language/`: [CC BY 4.0](design-language/LICENSE).

## Decisions

- [0001. A shared contract instead of a shared UI library](decisions/0001-shared-contract-not-shared-ui.md)
- [0002. Platforms and stacks](decisions/0002-platforms-and-stacks.md)
- [0003. Styles on top of system controls, and the API shape](decisions/0003-styles-on-system-controls.md)
- [0004. Data source formats](decisions/0004-source-formats.md)
- [0005. Workflow](decisions/0005-workflow.md)
- [0006. Pilot product: todo-app](decisions/0006-pilot-product.md)
- [0007. Licenses](decisions/0007-license.md)
- [0008. Apple: versions, toolchain, catalog and screenshots](decisions/0008-apple-toolchain-and-catalog.md)
- [0009. Tools in Swift](decisions/0009-tools-in-swift.md)
- [0010. Token structure, modes and the Apple output](decisions/0010-token-structure-and-modes.md)
- [0011. Icons and fonts](decisions/0011-icons-and-fonts.md)
- [0012. Color](decisions/0012-color.md)
- [0013. Typography, space, shape and motion](decisions/0013-typography-space-shape-motion.md)
