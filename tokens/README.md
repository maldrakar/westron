# Tokens

westron's tokens in the DTCG 2025.10 format (`*.tokens.json`) and the resolver that combines them into modes
(decisions/0004, 0010). The generators in `tools/` produce code for the platforms from them; generated files are not
edited by hand.

```
westron.resolver.json               the sets, the modifiers and the resolution order
primitive/*.tokens.json             the palettes in OKLCH with a hex fallback, easing curves, font families and weights
semantic/*.tokens.json              roles that do not depend on a mode: text roles, spacing, radii, strokes, shadows, motion
semantic/color.<theme>.tokens.json  the colors of a theme; a -hc file holds only what high contrast changes
density/<density>.tokens.json       none yet: compact gets values with the dense components (#33)
platform/<platform>.tokens.json     none yet: only where a value differs by platform
```

## Modes

| Modifier | Contexts | Default | Resolved |
|---|---|---|---|
| `theme` | `light`, `dark`, `light-hc` (light, then light-hc), `dark-hc` (dark, then dark-hc) | `light` | at runtime, by the platform's own switching |
| `density` | `regular`, `compact` | `regular` | at runtime, through the environment |
| `platform` | `ios`, `macos`, `watchos` | none: each generator names its own | at build time |

The resolver merges the `primitive` set, the `semantic` set, then each modifier's context, in that order. No two
modifiers set the same token, so their order never changes a result; the check fails otherwise.

## Rules

- Two tiers: primitive tokens are raw values that components never use; semantic tokens say what a value is for and
  alias primitives. Every semantic token has a `$description` (decisions/0010).
- What DTCG lacks lives in `$extensions` under `dev.westron.usage`, `dev.westron.contrast`, `dev.westron.apple` and
  `dev.westron.spring`; any other `dev.westron.*` key is an error. Contrast backgrounds are whole token paths:
  `color.background.canvas` (decisions/0012).
- A font weight given by name carries its own `$type`, because of a defect in the official DTCG schema.
- The reader supports a subset of DTCG and rejects the rest:
  [the supported subset](../tools/Sources/WestronTools/Tokens/README.md).

Icons are not tokens: their names and glyphs are a registry of their own, `spec/icons/icons.yaml` (decisions/0011),
which `tools/westron icons check` validates and `tools/westron generate` turns into `Westron.Icon`.

`tools/westron tokens check` validates the resolver and every token file against the official DTCG schemas and the
subset, fails on a token file the resolver does not use, and resolves every combination of contexts.
