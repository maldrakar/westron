---
paths:
  - "tools/**"
---

# Rules for tools/

- The tools are a separate SwiftPM package, `tools/Package.swift`, not targets of the root package: products that
  use westron must never see the tools' dependencies (decisions/0009).
- They build on macOS and Linux. Foundation only: no AppKit, UIKit, SwiftUI, CoreGraphics or other Apple-only
  frameworks. CI builds and tests them in the `swift:6.4-noble` container.
- The logic lives in the `WestronTools` library and is tested there with Swift Testing. The `westron` executable
  only parses arguments and prints. Run it through `tools/westron`, which picks the toolchain and builds it.
- Generators conform to `Generator`, are registered in `Generate.generators`, and are deterministic: the same input
  gives the same bytes, with no dates, no random numbers and no dependence on file system traversal order.
- A generated file starts with a comment that says it is generated, from what and by which command.
- A new dependency only if things are noticeably worse without it, added with the first code that needs it and pinned
  to an exact version (`exact:`). In use: swift-json-schema (DTCG validation), Yams (the icon registry, then the
  contracts). Planned: SwiftSyntax (#21).
- Color conversion is our own code, tested against reference values (decisions/0009).
- Bash scripts: `set -euo pipefail`; on macOS they get Xcode through `source tools/apple/xcode-env.sh`.
  Apple-only scripts live in `tools/apple/`. JSON in scripts is parsed with `jq` or `plutil`, which ship with macOS.
