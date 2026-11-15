# 0012. Color

Date: 2026-11-15. Status: proposed; the owner approves the palette on the catalog's samples (#10).

## Context

westron takes its colors from the pilot (decisions/0006): warm paper neutrals, one blue accent `#3653C9` that is the
same in light and dark, red for warnings, and eleven list colors with a rule that derives each list color's shades.
The pilot has no high-contrast colors. Phase 1 ends only when every "text/background" pair passes WCAG 2 in all four
themes (decisions/0010), and some of the pilot's pairs do not.

## Decision

### Primitive colors

- The palette is the pilot's own colors, in OKLCH with the pilot's sRGB hex as the `hex` fallback, so that each hex
  stays byte for byte the pilot's. Components are written with 4, 5 and 2 decimals (L, C, H): the least precision at
  which every 8-bit sRGB color converts back to the same hex.
- A primitive is named by its hue family and its OKLCH lightness in permille: `color.neutral.977` is the paper,
  `color.blue.493` is the accent. The name says how light a color is and leaves room for new shades.

### Semantic colors

| Group | Tokens |
|---|---|
| `color.background` | `canvas`, `surface`, `sidebar`, `muted`, `selected`, `hover`, `pressed`, `highlight`, `accent-subtle`, `glass`, `accent`, `danger` |
| `color.text` | `primary`, `secondary`, `placeholder`, `on-accent`, `on-danger`, `accent`, `danger` |
| `color.icon` | `tertiary`: glyphs and decorations that need 3:1 and must not carry words |
| `color.border` | `default`, `guide`, `glass`, `accent` |
| `color.category.<name>` | `background`, `background-subtle`, `text`, `border`, `fill`, `on-fill` for the eleven list colors: blue, amber, rose, green, stone, indigo, teal, pink, orange, violet, sky |

- A semantic color aliases a primitive when its value is a palette color. A derived value, that is a mix, a
  translucent layer or a shade moved to meet a contrast target, is written in the semantic token itself, in OKLCH with
  a hex fallback.
- `text.*` colors serve words and glyphs alike, as the pilot uses them. `icon.tertiary` exists because a grip and a
  strike-through line may be lighter than any color that words can use.
- The pilot's `ink3` as text (the sidebar's area caption) has no semantic token: words that light fail 4.5:1. The pilot
  moves that caption to `text.secondary`.

### Contrast

Each foreground token lists in `$extensions.dev.westron.contrast` the backgrounds it is drawn on, by kind. A background
written as a list is a stack, top first: `["color.background.hover", "color.background.canvas"]`. Translucent colors are
composited in gamma-encoded sRGB, as browsers and the pilot do.

| Kind | Standard themes | High-contrast themes |
|---|---|---|
| `text` | 4.5 | 7 |
| `large-text` | 3 | 4.5 |
| `non-text`: glyphs, rings and indicators that carry meaning | 3 | 4.5 |
| `separator`: rules and guides | none | 3 |

Where a pilot pair fails, the foreground's OKLCH lightness moves the least distance that passes, keeping its hue and
chroma; a white mark on a fill moves the fill instead. A translucent color first becomes more opaque. The
high-contrast themes start from their theme and move every color that misses the stricter target the same way.

### Changes to the pilot's look, for the owner to approve

Standard themes:

| Token | Theme | Pilot | westron | Why |
|---|---|---|---|---|
| `text.placeholder` | light | `ink2` at 80 % | `ink2` at 87 % | 3.93 on the canvas, 4.11 on the surface |
| `icon.tertiary` | light | `#A39C90` | `#80796E` | 2.55 on the canvas, 1.91 on the selected row |
| `icon.tertiary` | dark | `#6F6A62` | `#847F76` | 2.62 on the muted fill |
| `category.amber.text` | light | `#B07C0C` | `#8E6200` | a section title at 3.42 on the canvas |
| `category.green`, `stone`, `orange` `.text` | light | | slightly darker | under 4.5 on the muted fill |
| `text.accent` | dark | `#3653C9` | `#6488FF` | 2.71 on the canvas |
| `border.accent` | dark | `#3653C9` | `#5377F0` | the focus ring at 1.85 on the selected row |
| `background.danger` | dark | `#F07468` | `#C75046` | white "Delete" at 2.84 |

The accent fill (`background.accent`) stays `#3653C9` in both themes. The lit tag chip draws text in `on-fill` on a
list color's fill, which stays under 4.5:1 for most colors; that is the chip's to solve in its contract (#32).

## Why

- Keeping the pilot's hex values exact lets the pilot replace its `DesignSystem` without a visible change, apart from
  the table above.
- Moving only lightness keeps each color's hue, so the look changes as little as contrast allows.
- One semantic name per role, with its backgrounds declared next to it, makes the contrast check (#15) a property of
  the tokens, not a list kept somewhere else.

## Consequences

- The contrast check reads `dev.westron.contrast` and fails the build when a pair misses its target in any theme.
- The pilot changes its area caption to `text.secondary` and its grips to `icon.tertiary`.
- Values not yet in code but on the pilot's canvas (scrim, toast, badge, press) arrive when a component needs them;
  `background.pressed` is already here for the Button (#22).
