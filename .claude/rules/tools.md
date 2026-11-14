---
paths:
  - "tools/**"
  - "package.json"
  - "tsconfig.json"
---

# Rules for tools/

- Node 24 runs TypeScript directly, without a build step (type stripping). So only erasable syntax is allowed:
  no `enum`, no `namespace`, no parameter properties in constructors; imports use the `.ts` extension.
  `npm run typecheck` checks the types, and so does CI.
- Tests use `node:test` and sit next to the code, in `*.test.ts` files. Testable logic goes in exported functions,
  the CLI wrapper goes under `if (import.meta.main)`.
- Generators are registered in `tools/generate/generate.ts` and are deterministic: the same input gives the same bytes,
  with no dates, no random numbers and no dependence on file system traversal order.
- A generated file starts with a comment that says it is generated, from what and by which command.
- A new dependency only if things are noticeably worse without it; pin the exact version (`--save-exact`).
- Bash scripts for Apple live in `tools/apple/`, with `set -euo pipefail`; they get Xcode through `source tools/apple/xcode-env.sh`.
