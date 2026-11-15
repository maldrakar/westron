# 02. Color

Date: 2026-11-15. Status: draft for the owner's approval (#8). The palette itself is proposed in
[decisions/0012](../decisions/0012-color.md) and is approved on the catalog's samples (#10).

westron's color is a quiet ground and a few signals. This chapter says why the colors are what they are. The values,
and the table of every change from the pilot, are in decisions/0012; the token layout and the four themes are in
[decisions/0010](../decisions/0010-token-structure-and-modes.md).

## Warm neutrals

- **The ground is paper, not gray.** `color.background.canvas`, `surface`, `sidebar` and `muted` are the pilot's warm
  neutrals: off-white with a trace of yellow in light, warm near-black in dark. That warmth is the most visible part of
  the pilot's look, and it lives entirely in the content layer (chapter 00, principle 1).
- **Surfaces differ by small steps.** `surface` is something raised off the canvas: a card, a field, a dragged item.
  `muted` is a quiet fill inside content: a chip, a pill, a column, a highlighted row on a phone. `sidebar` is the
  sidebar's own ground. The steps are small on purpose; type, space and a shadow carry the hierarchy (chapter 04).
- **Two levels of ink for words, one for quiet glyphs.** `color.text.primary` and `text.secondary` serve words and
  glyphs alike. `color.icon.tertiary` serves grips and strike-through lines and never words. The pilot had a third ink
  for words too, but any ink light enough to look tertiary fails the text target, so words stop at secondary.
- **Lines are quiet.** `color.border.default` draws rules and dividers, `border.guide` the guides down a tree.
  In the standard themes they are decoration, since space and alignment also show the grouping.
- **Overlays work on any ground.** `background.hover`, `pressed` and `highlight` are translucent and laid over whatever
  is under them. `background.selected` and `accent-subtle` are mixed opaque, as in the pilot, so nothing behind a
  selected row or a drop slot shows through.

## One accent, used sparingly

- **One blue marks the primary action and the selection.** `background.accent` fills the primary action, such as the
  floating "+" or Done. Its usage note asks agents to avoid large areas and more than one filled control on a screen
  (chapter 00, principle 3; [HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
  `background.selected` and `accent-subtle` lay the accent lightly under a selected row or a drop slot.
- **As a fill, it is the same in both themes.** The pilot uses one blue in light and dark, and westron keeps it
  (decisions/0012). A fill carries white words, and white on that blue passes in either theme.
- **As text and as a border, it is lifted in dark.** `text.accent` and `border.accent` sit on the canvas, not under
  white words. On the dark canvas the fill's blue fails both as a word and as a focus ring, so in dark these two tokens
  are a lighter blue of the same hue. The rule is one hue, with its lightness set by its job.

## Red only for warnings

- **Red warns and nothing else.** `text.danger` is for words that warn, such as a due deadline; `background.danger` is
  the fill of a destructive action, such as a swipe's Delete. Red never decorates and never stands for identity.
- **It splits like the accent.** In dark, red as text is light so that it reads on the canvas, and red as a fill is
  darker so that white words read on it.
- **It always comes with words.** A due task is red and says "Overdue 2 days" (chapter 08).

## List colors are identity

- **Eleven names: blue, amber, rose, green, stone, indigo, teal, pink, orange, violet, sky.** `color.category.<name>`
  belongs to a thing a person names and colors, such as a list. The product stores the name, and each platform owns
  the shades, as in the pilot. A missing or unknown name draws stone.
- **Six roles come from one base, by the pilot's rule.** `background` is the tile under a list's glyph: the base,
  translucent. `background-subtle` is the fainter tint of a column a dragged item would drop into. `text` is the glyph
  on the tile and the section title: the base moved toward ink in light and toward white in dark. `border` is the ring
  of an open check. `fill` is a done check's disc and a lit chip: the base itself, lifted a little in dark. `on-fill` is
  the mark on that fill: white, or the light ink where white stands out too little, which is only amber.
- **Why a rule.** Eleven colors in six roles and four themes are too many to choose by hand and keep consistent. A rule
  keeps them one family, and a twelfth color would need only its base. Where a derived shade misses its target, only
  its lightness moves (below).
- **Identity is not state.** A list color never means danger, success or "today". A meaning gets its own semantic
  token, even when a product would like to borrow a list color for it. Color is also never a list's only identity:
  every list has an icon and a name too.

## Four themes

`light`, `dark`, `light-hc` and `dark-hc`. The high-contrast files hold only what changes
([decisions/0010](../decisions/0010-token-structure-and-modes.md)):

- secondary text, placeholders and tertiary glyphs move further from the ground;
- the accent and red, as text and as borders, move further from the ground;
- rules and guides become real boundaries, at a contrast they do not need in the standard themes;
- the accent and red fills, and some list colors' text, borders and fills, move a little.

The canvas, the surfaces and the primary text stay as they are. A person who turns on Increase Contrast should see the
same product with every quiet thing made clear, not a different palette. watchOS always shows the dark themes.

## Contrast

Every foreground token lists, in `dev.westron.contrast`, the backgrounds it is drawn on and the kind of contrast it
needs. The contrast check (#15) reads that list and fails the build when a pair misses its target in any theme.

| Kind | What it covers | Standard themes | High-contrast themes |
|---|---|---|---|
| `text` | Words of any size, unless declared large | 4.5:1 | 7:1 |
| `large-text` | Words that are large in WCAG's sense on every platform | 3:1 | 4.5:1 |
| `non-text` | Glyphs, rings and indicators that carry meaning | 3:1 | 4.5:1 |
| `separator` | Rules and guides | none | 3:1 |

- **A stack is measured as it is seen.** A translucent color is composited over what is under it, in gamma-encoded
  sRGB as browsers and the pilot do, and a background can be written as a stack, top first.
- **A failing color moves only its lightness**, by the least distance that passes, keeping its hue and chroma. A white
  mark moves its fill instead, and a translucent color first becomes more opaque. This keeps the look as close to the
  pilot as contrast allows. The changes this made to the pilot are listed in decisions/0012.
- Targets, exemptions and the other checks are in chapter 08.

## Open questions

1. **The changes to the pilot.** decisions/0012 lists every shade that moved to pass contrast. They are approved on
   the catalog's samples (#10).
2. **The lit tag chip.** Its words in `on-fill` on a list color's `fill` stay under the text target for most colors.
   0012 leaves this to the chip's contract (#32). Should the lit chip change its look, for example to `text` on
   `background`, or keep the pilot's look with larger or heavier words?
3. **The accent on system controls.** The pilot sets no app accent, so its alerts, menus and sheets show the system
   blue, not westron's. Should westron set its accent as the app's tint, knowing the HIG asks to minimize it on
   controls?
4. **Status colors.** The pilot has red and nothing else. Technical products need success, warning and information
   states (#33). Add them with the dense components?
5. **One accent or a choice.** The canvas offers the accent as a setting with four options. Is the blue westron's
   only accent, or may a product choose another?
