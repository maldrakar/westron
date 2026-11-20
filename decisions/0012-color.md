# 0012. Color

Date: 2026-11-15. Status: accepted. The owner chose direction B with the cobalt palette on the direction specimens.
Revised 2026-11-16: pressed fills. Revised 2026-11-18: the fill of a checked control in a list color, chosen by an
agent on the owner's behalf and pending the owner's confirmation. Revised 2026-11-20: the muted fill under the pointer
and pressed, pending the owner's review.

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

## Revision of 2026-11-16

The Button contract (#22) needs a filled button under the pointer and pressed, in the accent and in danger. The owner
chose fills one step apart, solved by the palette like every other color (#56).

- **A pressed fill on every ramp.** Each ramp gets `fill-pressed`, its solid fill while pressed: step 10 moved one
  more hover step, 0.04 in OKLCH lightness, further from its label, with step 10's chroma. Moving away from the label
  only raises its contrast, so the label reads on steps 10 and `fill-pressed` at least as well as on step 9; the
  solver still measures both on the 8-bit colors and fails with the token and the theme if one misses. The ramp keeps
  its twelve numbered steps: like `contrast`, `fill-pressed` is named for the solid fill it belongs to, so a step
  number keeps its job across systems that count to twelve.
- **New semantic colors.** `color.background.accent-pressed` is blue `fill-pressed`. `color.status.danger.fill-hover`
  is red 10, and `color.status.danger.fill-pressed` red `fill-pressed`. `text.on-accent` and `status.danger.on-fill`
  declare them for the contrast check as `text`.

  | Token | Light, dark | Light HC | Dark HC |
  |---|---|---|---|
  | `background.accent`, `accent-hover`, `accent-pressed` | `#2863D7`, `#1C56C9`, `#0F4ABC` | `#1651C3`, `#0844B6`, `#0038A5` | `#6A9EFF`, `#7EACFF`, `#93B9FF` |
  | `status.danger.fill`, `fill-hover`, `fill-pressed` | `#A72120`, `#990D13`, `#88000A` | as light | `#FE7469`, `#FF8B7F`, `#FFA196` |

  White on the accent reaches 5.44, 6.51 and 7.70 in light and dark; the canvas's color on the inverted dark
  high-contrast fills 7.04, 8.18 and 9.41. On 2026-11-16, `tools/westron tokens contrast` measured 257 declared pairs
  in each of the four themes, and none failed. The Button contract (#22) declared three more the same day, accent
  and danger text on the hover and pressed fills: 260 pairs, none failed.
- **Disabled is not a color.** A disabled control is drawn whole at `opacity.disabled` (decisions/0013), not in
  colors of its own; WCAG exempts it from contrast (chapter 08).

## Revision of 2026-11-18

**Status of this revision: chosen by an agent on the owner's behalf, pending the owner's confirmation.**

Phase 3's checkbox is the round task check (#31). Unchecked it is a ring in `color.border.strong`. Checked it is a
disc in the list's color, or in `background.accent` by default, with the mark on it. A checked disc is told from the
ground only by its fill, so the fill is a non-text indicator in WCAG's sense. Before this revision no fill declared a
contrast against a ground, and the pilot's amber disc measured 2.44:1 (`research_notes/pilot-inventory.md` §2.2, T14).
In the interview the owner chose to require 3:1 from the fills rather than draw a ring around the checked disc,
accepting that the light colors darken.

**The measurement.** `tools/westron tokens contrast --all`, with `non-text` declared for every
`color.category.<name>.fill` and for `background.accent` on `background.canvas`, `surface` and `sunken`. Those grounds
are the ones a check sits on, including a board card in a sunken column. Sixteen pairs failed:

| Fill | Theme | Hex | On canvas / surface / sunken | Target |
|---|---|---|---|---|
| olive | light | `#BFC566` | 1.76 / 1.84 / 1.65 | 3 |
| amber | light | `#F3B01D` | 1.81 / 1.90 / 1.71 | 3 |
| olive | light-hc | `#BFC566` | 1.76 / 1.84 / 1.65 | 4.5 |
| amber | light-hc | `#F3B01D` | 1.81 / 1.90 / 1.71 | 4.5 |
| red | dark | `#A72120` | 2.55 / 2.34 / 2.68 | 3 |
| indigo | dark | `#5A58C2` | 3.19 / 2.94 / 3.36 | 3 |

Everything else passed. The accent passed in every theme: light 4.89–5.44, dark 3.14–3.59, light-hc 6.29–7.00,
dark-hc 6.47–7.41. The other fills passed at 4.04 or more in light, 3.13 in dark and 6.29 in light high contrast, and
every fill passed in dark high contrast.

Raising step 9 in place does more than the owner was told. `status.warning.fill` is amber 9. `status.danger.fill`,
`fill-hover` and `fill-pressed` are red 9, 10 and `fill-pressed`, which Button's destructive variant uses. In light
high contrast a fill at 4.5:1 to the light canvas under a dark label at 7:1 would need 31.5:1 between the canvas and
the label, beyond the 21:1 that WCAG's ratio can reach. So there amber and olive need a white label, and with it they
turn brown.

**The options**, with the values the solver gives:

- **A. Raise step 9 in place.**
  - amber 9: light `#B88300` (dark label 5.40); light-hc `#765200` with a white label (7.05).
  - olive 9: light `#8D9230` (5.40); light-hc `#595D00` with a white label (7.02).
  - red 9 in dark: `#BB3631` (white 5.70), with hover `#AD2825` and pressed `#9F1618`.
  - indigo 9 in dark: `#5B5AC3`.
  - Side effects: the warning fill, the danger fill and its states move, and so does Button's destructive variant in
    dark. Danger in dark loses the 7:1 that keeps it apart from success.
- **B. A separate control fill used only by controls.** `color.category.<name>.control` and `on-control`, solved to
  the same values as A. Tags, tiles, statuses and Button keep every value.
- **C. A ring only around the failing discs.** It is drawn in `category.<name>.border`, step 8, which already meets
  the target on every ground: amber `#AF7C04`, olive `#868A42`, red in dark `#BF564D`, indigo in dark `#6B6FC3`,
  and in light-hc amber `#8A6100` and olive `#696D23`. No color moves, but the owner had decided against a ring.
- **D. Exceptions per color.** The failing fills stay below the target, on the argument that the mark identifies the
  checked state: `on-fill` is at 4.5:1, or 7:1 in high contrast, on its fill.
- **E. A mix.** Fix indigo in place, which is one 8-bit step on a list color alone, and use B, C or D for the rest.

**The choice: B.** The owner was away. The coordinator agent chose it on the owner's behalf, and the pull request
lists it for the owner to confirm. B keeps the owner's decision for the check, 3:1 from the fill with no ring, and
moves no other color.

- **Each ramp gets `control` and `control-contrast`.** The palette generator solves them like `contrast` and
  `fill-pressed`.
  - Where step 9 already meets the non-text target on the canvas and the raised and sunken surfaces, `control` is
    step 9 and `control-contrast` is `contrast`. The target is 3:1, or 4.5:1 in high contrast.
  - Otherwise `control` moves away from the canvas the least lightness that meets the target.
  - If step 9's label no longer reads there at 4.5:1 (7:1 in high contrast), the other label takes over: white for a
    dark ink, the ink for white. `control` then moves on until both targets hold.
  - Hue and chroma stay step 9's, within sRGB: where the moved lightness cannot hold that chroma, the gamut mapping
    lowers it, as it lowers amber's. Nothing is added to `palette.json`: the targets are the non-text and text targets
    above.
- **New semantic colors.** `color.category.<name>.control` and `color.category.<name>.on-control`, for all twelve list
  colors. `control` declares `non-text` on the three grounds, and `on-control` declares `text` on `control`.
  `background.accent` declares `non-text` on the same grounds; its value does not change.
- **The values that differ from the fill**, with their contrast on canvas / surface / sunken and their label's:

  | Color | Theme | `fill` | `control` | On the grounds | `on-control` |
  |---|---|---|---|---|---|
  | olive | light | `#BFC566` | `#8D9230` | 3.19 / 3.34 / 3.00 | dark `#161710`, 5.40 |
  | amber | light | `#F3B01D` | `#B88300` | 3.19 / 3.34 / 3.00 | dark `#191610`, 5.40 |
  | olive | light-hc | `#BFC566` | `#595D00` | 6.71 / 7.02 / 6.31 | white, 7.02 |
  | amber | light-hc | `#F3B01D` | `#765200` | 6.74 / 7.05 / 6.34 | white, 7.05 |
  | red | dark | `#A72120` | `#BB3631` | 3.26 / 3.00 / 3.43 | white, 5.69 |
  | indigo | dark | `#5A58C2` | `#5B5AC3` | 3.27 / 3.01 / 3.44 | white, 5.68 |

  Every other list color's `control` is its `fill`, in every theme.
- **No other value changes.** The 260 pairs declared before keep their ratios in all four themes. With the 51 new
  ones, `tools/westron tokens contrast` measured 311 declared pairs in each theme, and none failed.
- **Visibly**, a checked amber or olive check is an ochre or a darker olive in light. In light high contrast it is a
  brown or a deep olive with a white mark. A checked red check is a little brighter in dark. A lit tag keeps the bright
  fill.

## Revision of 2026-11-20

**Status of this revision: the implementing agent's, pending the owner's review with Button's snapshot matrix (#85).**

The owner's new look for Button fills the secondary button with `color.background.muted` and asks for darker fills
under the pointer and pressed (decisions/0013, revision of 2026-11-20). `background.hover` and `pressed`, steps 3
and 5, sit on either side of the muted step 4 and do not darken it.

- **The neutral ramp gets `muted-hover` and `muted-pressed`.** A muted fill carries words, so it moves the other way
  from a solid fill: away from the canvas, towards its words. `muted-pressed` is step 4 moved up to two hover steps,
  0.08 in OKLCH lightness, but no further than every ramp's step 11 and step 12 still reach the text target on it,
  4.5:1 and 7:1 in high contrast; `muted-hover` is halfway in lightness. Like `fill-pressed`, they are named for the
  step they belong to, and the ramp keeps its twelve numbered steps.
- **New semantic colors.** `color.background.muted-hover` and `muted-pressed` alias them. `text.primary` and
  `status.danger.text` declare them as `text`, `border.strong` and `status.danger.border` as `non-text`, and
  `status.danger.text` declares `background.muted` too, which the destructive secondary button now carries.
- **What the solver gives.** Step 11 of every ramp is solved to just reach its target on every step 5, so the words
  stop the fill there: `muted-pressed` lands on step 5's tone in every theme.

  | Token | Light | Dark | High contrast |
  |---|---|---|---|
  | `background.muted` (n4) | `#EBEEF4` | `#22272D` | as its base theme |
  | `background.muted-hover` | `#E8ECF1` | `#262A31` | as its base theme |
  | `background.muted-pressed` | `#E5E9EE` | `#2A2E35` | as its base theme |

  The red words on `muted-pressed` measure 4.51 in light, 4.54 in dark, 7.05 in both high-contrast themes. With the
  new pairs, `tools/westron tokens contrast` measured 321 declared pairs in each theme, and none failed. A darker press,
  such as the prototype's, would need step 11 solved on a darker ground, which darkens every colored word; that is
  for the owner.

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
- **Later platforms need their own settings.** If westron sets its accent on GNOME (chapter 02 asks whether), the
  dark `--accent-color` must be set explicitly, `#5992FF`, because libadwaita's own derivation drifts blue towards
  cyan. Android maps the tokens to a static `ColorScheme`. Both
  arrive with their phases (research 5.1, 5.2).
- **The catalog shows the colors.** It has a page of statuses and charts (`color-status`). `color-in-use` shows a
  task list, a table of deployments, notices and buttons.
