# 02. Color

Date: 2026-11-15. Status: draft for the owner's approval (#8). It follows
[decisions/0012](../decisions/0012-color.md), which the owner accepted by choosing direction B with the cobalt palette.

westron's color is a cool, quiet ground and a few signals. This chapter says why the colors are what they are. The
values, the ramps and the rules that solve them are in decisions/0012; the token layout and the four themes are in
[decisions/0010](../decisions/0010-token-structure-and-modes.md).

## A cool ground with raised cards

- **The ground is a faintly cool white, and cards are white on it.** `color.background.canvas` is off-white with a
  trace of blue in light and a blue-black in dark. `surface` is a card, a sheet or a popover westron draws, raised off
  the canvas. It is white in light and one step lighter than the canvas in dark: higher is lighter in every theme, as
  on every platform. `sunken` is a well below the content: a sidebar, a code block, a log, a table header.
- **The coolness is a choice for many products.** A cool ground sits naturally next to the faintly cool chrome of
  Apple and GNOME. It suits a dense table as well as a calm list. Warm grays read as paper and fit long reading;
  westron's products are mostly tools.
- **Surfaces differ by small steps.** `muted` is a quiet fill inside content: the track of a segmented control, a tag
  or a badge without a color, a secondary button. `hover` and `pressed` follow the pointer; a control filled with
  `muted` darkens to `muted-hover` and `muted-pressed` instead, as far as its words still read on it. Type, space and a soft shadow carry the
  hierarchy (chapter 04), so the surface steps stay small.
- **Two inks for words, one for quiet glyphs.** `color.text.primary` and `text.secondary` serve words and glyphs
  alike. `color.icon.tertiary` serves chevrons, grips and strike-through lines, never words. Any ink light enough to
  look tertiary fails the text target, so words stop at secondary.
- **Lines are quiet, borders of controls are not.** `color.border.default` draws separators. In the standard themes
  it is decoration, since space and alignment also show the grouping. `border.strong` draws the outline of something a
  person must find, such as a field or a checkbox, and it meets 3:1. A secondary button is found by its muted fill,
  and draws the outline only in high contrast (chapter 04).

## One accent: cobalt

- **One saturated blue marks the primary action and the selection.** `background.accent` fills the one primary action
  on a screen, a checked box, a switch that is on, and it meets the non-text contrast on the canvas, the raised
  surface and the sunken one in every theme, where its contrast is declared.
  Its usage note asks agents to avoid large areas and more than one
  filled control on a screen (chapter 00, principle 3; [HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
  `background.selected` and `accent-subtle` lay the accent lightly under a selected row or an empty state's tile.
- **A filled control darkens as it is pressed.** `accent-hover` and `accent-pressed` are the accent fill under the
  pointer and pressed, each one step further from its words, so `text.on-accent` reads on them as on the resting fill.
  In dark high contrast, where the fill is light, they step lighter.
- **The accent also means "info".** A running job, a tip and a link share the blue. So a screen holds four hues at
  most: the accent, and danger, warning and success when something needs them.
- **As a fill, it is the same in light and dark.** White words on `#2863D7` pass in either theme. As text and as a
  focus ring it is lifted in dark, so that it reads on the dark canvas: one hue, with its lightness set by its job.

## Statuses come with an icon and a word

- **Five statuses.**
  - `danger`: something failed, or an action destroys data.
  - `warning`: something needs attention but works.
  - `success`: something finished well.
  - `info`: news, or work in progress.
  - `neutral`: no verdict, such as queued, skipped or cancelled.
- **Six roles each.** `background` is the quiet ground of a badge, a banner or a row. `icon` is its glyph or dot,
  `text` its words, and `border` the outline of a field in error. `fill` is a solid fill, such as a destructive
  button, and `on-fill` the words on it. Danger, which fills a destructive button, also has `fill-hover` and
  `fill-pressed`, a step and two steps further from its words, as the accent has.
- **The hues are chosen to stay apart.** Danger is a dark red, warning a bright amber with dark words on it, and
  success a bluish green. Red and green of the same lightness merge for people with deuteranopia; a darker red and a
  bluer green do not (decisions/0012).
- **Color is never the only signal.** A failed build shows a crossed circle and the word "Failed". Log levels and
  pipeline states map to statuses:

  | Statuses | Log levels | Pipeline states |
  |---|---|---|
  | danger | error | failed |
  | warning | warn | — |
  | info | info | running |
  | success | — | succeeded |
  | neutral | debug | queued, cancelled, skipped |

## List colors are identity

- **Twelve names.** blue, sky, teal, emerald, green, olive, amber, orange, red, pink, violet, indigo.
  `color.category.<name>` belongs to a thing a person names and colors, such as a list, a project or a tag. The
  product stores the name, and each platform owns the shades.
- **Six roles, the same as a status's.** `background` is a tag's ground, `icon` a list's dot, `text` its title in
  color, `border` an outlined tag, `fill` a lit tag, and `on-fill` the words on that fill.
- **Two more for a checked control.** `control` fills a checked control in the list's color, such as the round task
  check, and `on-control` draws its mark. A checked disc is told from the ground only by its fill, so `control` meets
  the non-text contrast on the canvas, the raised surface and the sunken one: 3:1, 4.5:1 in high contrast. Where
  `fill` already does, `control` is `fill`. The bright fills move: amber and olive darken in light, to an ochre and a
  darker olive under the same dark mark, and in light high contrast to a brown and a deep olive with a white mark,
  since no fill holds 4.5:1 to a light ground and 7:1 to a dark mark. Red and indigo lighten a little in dark. Tags,
  tiles and statuses keep `fill`, which stays as bright as before (decisions/0012, revision of 2026-11-18). Separate
  control fills are option B of that revision, chosen by the coordinator under the owner's delegation of 2026-11-18
  and pending the owner's confirmation; the owner decided only that a checked fill meets 3:1, with no ring.
- **They come from the ramps.** Each list color is a ramp, so a new name needs only a hue and a chroma in the
  palette.
- **Identity is not state.** A list color never means danger, success or "today", even when a product would like to
  borrow one. A list also never relies on its color alone: it has an icon and a name too.

## Charts

- **Eight series, in order.** `color.chart.1`–`8`. The first ones differ most, also for people with color
  blindness, so a chart with three series uses the first three.
- **Each series has 3:1 on every ground in every theme.** High contrast adds direct labels and markers to a chart,
  not contrast.
- **More than eight series need labels.** Eight colors are the limit of what a person can match to a legend.
  Beyond that, label the series directly or use a sequential scale.

## Four themes

`light`, `dark`, `light-hc` and `dark-hc`. Every color comes from a ramp of twelve steps that the palette generator
solves for each theme (decisions/0012):

- **The dark themes are solved again, not inverted.** Their surfaces stay close to one another, their text is light
  without glare, and their fills keep the light themes' white words.
- **The high-contrast themes keep the canvas and the surfaces.** They make every quiet thing clear: separators,
  borders, secondary text and colored text move further from the ground. A person who turns on Increase Contrast should
  see the same product, not a different palette.
- **In dark high contrast, solid fills turn light, with dark words on them.** It is the only way a filled button
  reaches 7:1 with its words and still stands out from a dark screen.
- **In high contrast, every raised surface gets a border.** A shadow alone does not mark its edge (chapter 04).

A disabled control has no colors of its own: it is drawn whole at `opacity.disabled`, so it keeps its variant and
reads as unavailable in every theme (chapter 08).

watchOS always shows the dark themes.

## Contrast

Every foreground token lists, in `dev.westron.contrast`, the backgrounds it is drawn on and the kind of contrast it
needs. The contrast check (#15) reads that list and fails the build when a pair misses its target in any theme.

| Kind | What it covers | Standard themes | High-contrast themes |
|---|---|---|---|
| `text` | Words of any size, unless declared large | 4.5:1 | 7:1 |
| `large-text` | Words that are large in WCAG's sense on every platform | 3:1 | 4.5:1 |
| `non-text` | Glyphs, rings and indicators that carry meaning | 3:1 | 4.5:1 |
| `separator` | Rules and guides | none | 3:1 |
| `chart` | A series in a chart | 3:1 | 3:1 |

- **A stack is measured as it is seen.** A translucent color is composited over what is under it, in gamma-encoded
  sRGB as browsers do, and a background can be written as a stack, top first.
- **The targets hold by construction.** The generator solves each step for its job's contrast, and the check proves
  every declared pair. Targets, exemptions and the other checks are in chapter 08.

## Open questions

1. **The accent on system controls.** Should westron set its accent as the app's tint on Apple, so that alerts,
   menus and sheets show cobalt instead of the system blue? The HIG asks to keep tint off most controls. On macOS the
   app's accent applies only when the person has chosen "multicolor".
2. **The person's accent on GNOME.** libadwaita lets a person choose an accent since GNOME 47, and an app that sets its
   own overrides that choice. Does westron override it, or follow the person (phase 7)?
3. **Display P3.** The ramps are sRGB today. Should the accent and the list colors gain P3 chroma on Apple and the
   web, keeping the sRGB values as their fallback?
