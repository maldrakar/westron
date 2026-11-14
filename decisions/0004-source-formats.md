# 0004. Data source formats

Date: 2026-11-14. Status: accepted.

## Decision

| What | Format |
|---|---|
| Tokens (color, spacing, radii, typography, animation) | DTCG 2025.10, `*.tokens.json` files |
| Modes (theme, contrast, density, platform) | DTCG resolver, JSON |
| Component contracts | Our own YAML, validated by JSON Schema |
| Design language and decisions | Markdown |

## Details

- We do not introduce our own token format: DTCG is a standard that Style Dictionary and Figma understand.
- Everything DTCG lacks (spring animation, platform mappings, usage rules for the agent) is stored in `$extensions` under the `dev.westron.*` key.
- Sizes are stored in px; the generators derive pt, dp, sp and rem.
- Tokens have two levels: primitive tokens and semantic tokens. A component level is added only when needed.
- "Styles" are not described in a separate format: they are bindings of tokens to variants and states inside the component contract.
- A component contract describes options, states, slots, constraints, token bindings, accessibility, and a `platforms` block with the differences between platforms. The schema is based on `component.schema.json` from Spectrum.
- The token generation engine is Style Dictionary 5 with our own formats and a small resolver preprocessor.
