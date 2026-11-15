# 0012. Color

Date: 2026-11-15. Status: accepted. The owner chose direction B with the cobalt palette on the direction specimens.

## Context

westron serves several products, everyday and technical, on several platforms. Its look is designed for them, not
taken from the pilot (decisions/0006). The research behind this decision is in `research_notes/color-systems.md`:
how Radix, Material, Atlassian, Spectrum, Carbon, Primer, Fluent, Apple, libadwaita, Linear and Geist build their
palettes, and three palette directions with their anchors.

The owner compared three directions, then six palettes on direction B's shape, on the same samples: a task list, a
table of deployments, settings, a log, a dashboard and notices. The choice is the cobalt palette: cool grays and one
saturated cobalt that also means "info".

Phase 1 ends only when every declared text and background pair passes WCAG 2 in the four themes (decisions/0010).

## Decision

### Ramps, solved for each theme

- **The source is a few anchors.** `tokens/palette.json` holds:
  - the neutral hue and chroma;
  - the lightness of the canvas, raised and sunken surfaces in light and dark;
  - the contrast of steps 2–7;
  - for each of twelve hue ramps, its hue, its chroma, where its solid fill starts and the color of its label;
  - the start colors of the chart series.
- **The generator solves the ramps.** `tools/westron generate` (the `tokens-palette` generator) writes
  `tokens/primitive/color.<theme>.tokens.json`. It solves thirteen ramps of twelve steps each, plus each ramp's label
  color, for each theme. Generated files are not edited.
- **A step has one job in every theme.** It moves away from the canvas the least lightness that meets its targets,
  keeping its hue and chroma:

| Step | Job | Standard target | High-contrast target |
|---|---|---|---|
| 1 | the canvas, or a faint tint of it | the canvas's lightness | same |
| 2 | subtle ground: a status or accent tint | 1.06 on the canvas (dark 1.14) | same |
| 3 | hover; a tag's ground | 1.09 (dark 1.18) | same |
| 4 | a muted fill: a segmented track, a neutral badge | 1.11 (dark 1.23) | same |
| 5 | pressed, selected | 1.16 (dark 1.36) | same |
| 6 | separators | 1.27 (dark 1.45) | 3 on every ground |
| 7 | guides | 1.6 (dark 1.8) | 4.5 on every ground |
| 8 | borders of controls, focus rings, marks | 3 on every ground and every step 5 | 4.5 |
| 9 | solid fill | its label at 4.5 | its label at 7 |
| 10 | solid fill under the pointer | step 9, 0.04 further from its label | same |
| 11 | colored or secondary text | 4.5 on every ground and every step 5 | 7 |
| 12 | primary text | 13 on the canvas, 7 on every step 5 | 16 on the canvas |

  The grounds are the canvas, the raised surface and the sunken one. Steps 1–5 share a contrast with the canvas
  across all ramps, so a step 11 of any hue reads on a step 5 of any hue.
- **Contrast is measured on the 8-bit color.** The generator measures contrast on the 8-bit sRGB value a step
  becomes, as the contrast check does. A color outside sRGB loses chroma at constant lightness and hue. CSS's gamut
  mapping clips instead, which would turn a light blue tint about 20° towards cyan.
- **Dark is solved again, not inverted.** Light themes walk darker from the canvas, dark themes lighter. Raised
  surfaces are lighter than the canvas in every theme, and sunken ones darker.
- **High contrast keeps the canvas and steps 1–5.** It raises steps 6–12. Its token file lists only the colors that
  differ, and the resolver merges it over its base theme.
- **Dark high contrast inverts white-labeled fills.** A white label at 7:1 would sink its fill into the dark canvas.
  So in `dark-hc` such a fill turns light, and its label (`color.<ramp>.contrast`) takes the canvas's color.
  Fills with a dark label, such as amber, keep it.
- **Primitive names.** A primitive is named by ramp and step: `color.blue.9`, `color.neutral.11`. The neutral ramp
  also has `raised` and `sunken`, every ramp has `contrast` (its label), and the chart series are `color.series.1–8`.
  The ramps differ by theme, so the theme contexts merge them in. Every file in `tokens/primitive/` holds primitives,
  whichever set or context uses it, and the platform generators leave them out (decisions/0010).

### The cobalt palette

| Anchor | Value |
|---|---|
| Neutral | hue 258, chroma 0.007 in light and 0.011 in dark; steps 8–12 at 1.6× that chroma |
| Canvas | `#F7FAFF` in light, `#101318` in dark |
| Raised surface | `#FFFFFF` in light, `#181C21` in dark |
| Sunken surface | `#F0F3F8` in light, `#090C10` in dark |
| Accent | blue, hue 262, chroma 0.189: the fill `#2863D7`, white at 5.2:1, in light and dark |
| Danger | red, hue 27: the fill `#A72120`, white at 7:1, so it is dark and stays apart from success |
| Warning | amber, hue 80: the fill `#F3B01D` with a dark label |
| Success | emerald, a bluish green at hue 168: the fill `#018766` |
| Info | the accent's blue, so the screen holds four hues |
| List colors | blue, sky, teal, emerald, green, olive, amber, orange, red, pink, violet, indigo |
| Chart | eight series in order, from `research_notes/color-systems.md` 4.4, each moved until it reaches 3:1 |

### Semantic colors

All semantic colors live in one file, `tokens/semantic/color.tokens.json`, which serves the four themes. Each
semantic color aliases a step. A theme changes the steps, not the semantic colors.

| Group | Tokens and their steps |
|---|---|
| `color.background` | `canvas` n1, `surface` n-raised, `sunken` n-sunken, `muted` n4, `hover` n3, `pressed` n5, `selected` blue 5, `accent-subtle` blue 3, `accent` blue 9, `accent-hover` blue 10 |
| `color.text` | `primary` n12, `secondary` n11, `placeholder` n11, `on-accent` blue contrast, `accent` blue 11 |
| `color.icon` | `tertiary` n8: glyphs that carry no words |
| `color.border` | `default` n6, `strong` n8, `focus` blue 8 |
| `color.status.<name>` | `danger`, `warning`, `success`, `info`, `neutral`, each with `background` 2 (neutral: n4), `border` 8, `icon` 8, `text` 11, `fill` 9, `on-fill` contrast |
| `color.category.<name>` | the twelve list colors, each with `background` 3, `border` 8, `icon` 8, `text` 11, `fill` 9, `on-fill` contrast |
| `color.chart` | `1`–`8`: the series in order |

"n" is the neutral ramp. `text.*` colors serve words and glyphs alike. There is no tertiary text: any ink light enough
to look tertiary fails the text target. A status always shows an icon and a word, never color alone.

### Contrast

Each foreground token lists in `$extensions.dev.westron.contrast` the backgrounds it is drawn on, by kind. A background
written as a list is a stack, top first, and a translucent color is composited in gamma-encoded sRGB.

| Kind | Standard themes | High-contrast themes |
|---|---|---|
| `text` | 4.5 | 7 |
| `large-text` | 3 | 4.5 |
| `non-text`: glyphs, rings and indicators that carry meaning | 3 | 4.5 |
| `separator`: rules and guides | none | 3 |
| `chart`: a series in a chart | 3 | 3 |

High contrast adds direct labels and markers to a chart instead of contrast; eight series darkened to 4.5 would be
hard to tell apart. On 2026-11-15, `tools/westron tokens contrast` measured 254 declared pairs in each of the four
themes, and none failed.

## Why

- **Targets are true by construction.** Solving each step for its contrast makes the targets hold by construction,
  instead of finding and moving failing shades by hand. The same step number keeps the same job in every theme, as
  Spectrum's indices and Radix's steps do.
- **Text reads on every background.** Steps 1–5 share their contrast with the canvas across ramps, so colored text
  reads on any tinted background. Radix's own WCAG results fail exactly there.
- **Dark is solved, not inverted.** An inverted light palette makes dark surfaces too far apart and fills too bright.
- **Dark high contrast inverts fills.** It is the only way a fill reaches 7:1 with its label and still stands out
  from the dark canvas. Material's dark `primary` works the same way: a light fill with a dark label.
- **Success is bluish and danger is dark.** Red and green of the same lightness merge under deuteranopia. A bluish
  green and a darker red keep them apart: ΔE 0.10, against 0.03 for a plain pair (research 4.3).
- **One semantic file.** The descriptions, usage notes and declared pairs are written once. High contrast is data
  in the ramps, not a second set of semantic tokens.

## Consequences

- **The pilot's palette and its table of changes are gone.** The pilot becomes westron's first consumer and takes the
  new look (decisions/0006).
- **Color changes go through the palette.** A color changes in `tokens/palette.json` and is generated. The generator
  fails with the token and the theme when a target cannot be met.
- **The contrast check has a fifth kind, `chart`.**
- **On-fill colors pass.** `on-fill` passes on every fill, so the lit tag chip no longer needs a special rule.
- **Later platforms need their own settings.** GNOME needs the dark `--accent-color` set explicitly, `#5992FF`,
  because its own derivation drifts blue towards cyan. Android maps the tokens to a static `ColorScheme`. Both
  arrive with their phases (research 5.1, 5.2).
- **The catalog shows the colors.** It has a page of statuses and charts (`color-status`). `color-in-use` shows a
  task list, a table of deployments, notices and buttons.
