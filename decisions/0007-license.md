# 0007. Licenses

Date: 2026-11-14. Status: accepted.

## Context

The repository is public. Without a license, the code formally cannot be used even in the author's own products
if they are published separately. The design language documents are texts, and a content license
suits them better.

## Decision

| What | License | File |
|---|---|---|
| Everything except `design-language/`: code, tokens, contracts, generators, decisions, documentation | MIT | `LICENSE` |
| Design language texts and illustrations in `design-language/` | CC BY 4.0 | `design-language/LICENSE` |

## Why

- MIT is the shortest and most familiar license for SwiftPM and npm packages. Primer and Fluent are released under it.
- Apache-2.0 gives an explicit patent clause but requires maintaining a NOTICE file. For a single-author design system
  that is needless ceremony.
- CC BY 4.0 lets others reuse the design language texts with attribution. It does not suit code.

## Consequences

- Third-party fonts and icons stay under their own licenses. When we choose them in phase 1 (issue #16), we take only
  OFL, MIT, ISC and similar; SF Symbols and SF Pro are legally tied to Apple platforms.
- Tokens and contracts are data, and MIT applies to them.
