# 0010. Token structure, modes and the Apple output

Date: 2026-11-15. Status: accepted.

## Context

decisions/0004 fixes the format (DTCG 2025.10, the resolver, two tiers, `$extensions` under `dev.westron.*`). This
decision fixes how the files are laid out, which modes exist and how they reach the platforms. Issue #12 proposed two
orthogonal modifiers, `appearance` and `contrast`. They are not orthogonal for colors: a high-contrast color differs
between the light and the dark theme, and a resolver context cannot depend on another modifier's context.

## Decision

### Modifiers

| Modifier | Contexts | Default | Owns | Resolved |
|---|---|---|---|---|
| `theme` | `light`, `dark`, `light-hc`, `dark-hc` | `light` | colors | at runtime, by the platform's own switching |
| `density` | `regular`, `compact` | `regular` | spacing and control sizes | at runtime, through the environment |
| `platform` | `ios`, `macos`, `watchos`; `web`, `gnome`, `android` arrive with their phases | — | values that differ by platform | at build time, by each platform's generator |

- A high-contrast context is its theme plus a small file of overrides: `light-hc` is `primitive/color.light` and then
  `primitive/color.light-hc`. So the high-contrast files hold only what changes. Since 2026-11-15 these files are the
  color ramps that the palette generator writes, and the semantic colors are one file for every theme
  (decisions/0012).
- `compact` has no values yet. It is filled when the dense components (#33) give it a consumer.
- Modifiers stay orthogonal: no token path is set by two modifiers. The resolver checks this and fails the build
  otherwise, so the order of the modifiers never changes the result.

### Files

```
tokens/
  westron.resolver.json             the sets, the modifiers and the resolution order
  palette.json                      the palette's anchors, which the generator solves into the color ramps
  primitive/*.tokens.json           the raw scales
  primitive/color.<theme>.tokens.json   the color ramps of a theme, generated
  semantic/*.tokens.json            roles that do not depend on a mode: colors, text roles, spacing, radii, motion
  density/<density>.tokens.json
  platform/<platform>.tokens.json   only where a value differs by platform
```

### Tiers and names

- Two tiers. Primitive tokens are raw values and are never used by components directly. Semantic tokens say what a
  value is for and alias primitives. A component tier appears only when a component needs one (decisions/0004).
- The color ramps are primitives that differ by theme, so the theme contexts merge them in. Every file in
  `tokens/primitive/` holds primitives, whichever set or context uses it, and the platform generators leave it out.
- A name goes from the general to the particular (namespace, object, base, modifier), in lowercase kebab-case path
  segments: `color.text.secondary`, `color.background.surface`, `typography.body.strong`. Ladders are named by step
  (`space.100`, `radius.150`; decisions/0013). The default variant has no suffix.
- Every semantic token has a `$description`. A token an agent could pick wrongly also has
  `$extensions.dev.westron.usage` with `use` (where it goes) and `avoid` (where it does not).

### `$extensions` keys

| Key | On | What it holds |
|---|---|---|
| `dev.westron.usage` | semantic tokens | `use` and `avoid` for the agent |
| `dev.westron.contrast` | text and glyph colors | the backgrounds the color is drawn on and the minimum WCAG 2 ratio; the contrast check (#15) reads it |
| `dev.westron.apple` | typography, motion | what DTCG has no word for on Apple: the text style and the design of a text role, and so on |
| `dev.westron.spring` | motion | a spring as `duration` and `bounce`, which DTCG has no type for |

The tools reject any other `dev.westron.*` key, so a misspelled key fails instead of being ignored.

### Apple

- `WestronTokens` is a generated target with no SwiftUI. It holds every resolved value as plain Swift numbers, for
  every theme and density, with the platform values behind `#if os(...)`. It builds for WebAssembly and Linux, because
  the pilot's own `DesignSystem` does and the pilot will replace it with this module (decisions/0006).
- `WestronUI` holds the SwiftUI side, generated from the same resolution: an asset catalog with one colorset per
  semantic color, each with the four theme variants, and `public` accessors through `Bundle.module`, because the
  symbols Xcode generates for assets are `internal`. A color outside sRGB is written in Display P3.
- On 2026-11-15, with Xcode 27.1, a probe package showed that `swift build` and `swift test` compile the asset
  catalog, and that `Color.resolve(in:)` returns each of the four variants for the matching `colorScheme` and
  `colorSchemeContrast`.

**Apple API** (#14). `tools/westron generate` writes the values; the types and the SwiftUI adapters are hand-written.

- `WestronTokens` imports nothing and has one top-level name, `Westron`. It holds the semantic tokens only:
  `Westron.Color` (a `Westron.RGB` per theme, 8-bit sRGB or Display P3, the token path as `name`, and the
  backgrounds its `dev.westron.contrast` declares),
  `Westron.Category` (the list colors: a `String`-backed `CaseIterable` enum of their names in the tokens, with a
  property per role), `Westron.TextRole`, `Westron.Transition`, `Westron.Shadow` and `Westron.Dimension`, each with
  an `all` list.
- A Swift name is the token path in lowerCamelCase, without the first segment where the type already names it:
  `color.text.secondary` is `Color.textSecondary`, `typography.heading.large` is `Font.headingLarge`,
  `motion.row-leave` is `Animation.rowLeave`, `shadow.raised` is `Westron.Shadow.raised`; a length keeps it:
  `CGFloat.space100`, `.radius150`, `.strokeThin`. A list color's role is `Color.categoryText(_:)`. A name that
  collides with a static SwiftUI already has on that type (`Color.primary`, `Font.body`, `Animation.default`) or with
  another token's fails generation.
- `WestronUI` re-exports `WestronTokens` and adds `public` statics: `Color` and `ShapeStyle where Self == Color`
  from colorsets through `Bundle.module`, `Font` as `Font.system(_:design:weight:)`, `Animation` as
  `.spring(duration:bounce:)` where the token has a spring and `.timingCurve` otherwise, with `.delay` when it waits,
  and `CGFloat`; `View.shadow(_:)` takes a `Westron.Shadow`, with half its CSS blur as the radius.
- Icons are not tokens, but come out of the same `generate` and the same split (decisions/0011): `Westron.Icon` in
  `WestronTokens` is a `String`-backed `CaseIterable` enum of the names in `spec/icons/icons.yaml`, with
  `fallback` for a name it does not know; `WestronUI` adds `systemName`, the SF Symbol, and the hand-written
  `Image(_:)` and `Label(_:icon:)`.
- A colorset is named by the token path and holds the four variants, plus one watch entry with the dark value:
  watchOS asset catalogs take no appearances (actool drops them as unassigned children, Xcode 27.1, 2026-11-15), so
  the watch is dark whatever its contrast setting.
- Density and platform switch nothing yet: the generator reads `density=regular` on each Apple platform and fails
  when any value differs between them, or when a token other than a color differs by theme. The mechanism comes
  with the first token that needs it.

## Why

- One `theme` modifier with four contexts is what Primer does, and it matches the targets directly: a colorset has the
  same four variants, libadwaita has light, dark and high contrast, the web has `prefers-color-scheme` and
  `prefers-contrast`. The alternative, two modifiers with an extra tier that the contrast modifier re-points, adds a
  tier of tokens that every platform would see.
- Colors in a colorset switch with the system and with the SwiftUI environment, which a constant
  `Color(red:green:blue:)` cannot do.
- Keeping the numbers in a module with no SwiftUI lets the pilot's shared code and its WebAssembly build use the same
  values as its SwiftUI views.

## Consequences

- Issue #12 is implemented with the `theme` modifier instead of `appearance` and `contrast`.
- The contrast check covers four themes.
- Adding a platform adds a context to `platform` and, where needed, a file in `tokens/platform/`.
