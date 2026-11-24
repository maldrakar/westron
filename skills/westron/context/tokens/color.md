<!-- Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Colors

From westron's semantic tokens, `import WestronUI`. Each entry: the token's path, its Swift member as SwiftUI writes it
after a dot, and what it is for.

A semantic color is a `Westron.Color`, named after its path without `color.`: `color.text.primary` is `.text.primary`.
WestronUI takes one where SwiftUI takes a color: `.foregroundStyle(.text.primary)`, `.background(.background.surface)`,
`.background(.background.muted, in: Capsule())`, `.tint(.text.accent)`, `shape.fill(.background.surface)`,
`shape.stroke(.border.default, lineWidth: .stroke.thin)`, `shape.strokeBorder(…)`, `Text(…).foregroundStyle(…)`, and
`Color(.text.primary)` where only a SwiftUI `Color` fits. Each switches with the light and dark themes and increased
contrast by itself. A color is chosen by its role, which its entry names ("Use for", "Avoid"); never a raw color, a hex
value or an opacity laid on a token to make a new color. The design language: `../design-language/02-color.md`.

## `color.background`

- `color.background.canvas` → `.background.canvas`: The ground of a screen, a list or a table. Use for: screen
  background, list background. Avoid: Cards and sheets: use background.surface.
- `color.background.surface` → `.background.surface`: Something raised off the canvas: a card, a sheet or a popover
  westron draws, a dragged row. White in light; one step lighter than the canvas in dark, where higher is lighter. Use
  for: card, sheet, popover, dragged row. Avoid: A well below the content: use background.sunken.
- `color.background.sunken` → `.background.sunken`: A well below the canvas: a sidebar, a code block, a log, a table
  header. Use for: sidebar, code block, log, table header. Avoid: A control's fill: use background.muted.
- `color.background.muted` → `.background.muted`: A quiet fill inside content: the track of a segmented control, a tag
  or a badge without a color, a secondary button, a framed text field. It stands about 1.1:1 off the canvas, so a
  control found by it alone misses 3:1 for its edge, as the owner accepted for the text field (design-language/08); in
  high contrast such a control also draws border.strong, or status.danger.border on a destructive secondary button. Use
  for: segmented track, neutral tag, neutral badge, secondary button, framed text field. Avoid: A row under the pointer:
  use background.hover.
- `color.background.hover` → `.background.hover`: A row or a control under the pointer.
- `color.background.pressed` → `.background.pressed`: A row or a control while it is pressed.
- `color.background.muted-hover` → `.background.mutedHover`: The muted fill of a control filled with it and labelled in
  text.primary, such as a secondary button, under the pointer: background.muted one hover step towards its words
  (decisions/0012, 0013). Use for: secondary button under the pointer. Avoid: A fill under colored words, such as a
  destructive secondary button: use background.muted-hover-colored. A row or an unfilled control under the pointer: use
  background.hover.
- `color.background.muted-pressed` → `.background.mutedPressed`: The muted fill of a control filled with it and labelled
  in text.primary, such as a secondary button, while it is pressed: background.muted two hover steps towards its words,
  as far as text.primary still reads on it (decisions/0012, 0013). Use for: pressed secondary button. Avoid: A fill
  under colored words, such as a destructive secondary button: use background.muted-pressed-colored. A pressed row or an
  unfilled control: use background.pressed.
- `color.background.muted-hover-colored` → `.background.mutedHoverColored`: The muted fill of a control filled with it
  and labelled in colored words, such as a destructive secondary button, under the pointer: halfway between
  background.muted and muted-pressed-colored. Use for: destructive secondary button under the pointer. Avoid: A fill
  under text.primary: use background.muted-hover, which darkens more.
- `color.background.muted-pressed-colored` → `.background.mutedPressedColored`: The muted fill of a control filled with
  it and labelled in colored words, such as a destructive secondary button, while it is pressed: background.muted moved
  towards its words as far as every colored word, step 11 of every ramp, still reads on it, which is about step 5's tone
  (decisions/0012, 0013). Use for: pressed destructive secondary button. Avoid: A fill under text.primary: use
  background.muted-pressed, which darkens more.
- `color.background.selected` → `.background.selected`: A selected row or item, tinted with the accent. Use for:
  selected row, selected item. Avoid: Color alone: a selected row also shows a mark that is not a color, in every theme,
  such as a check or ListRow's border.focus bar at its leading edge.
- `color.background.accent-subtle` → `.background.accentSubtle`: A quiet accent ground: the tile behind an empty state's
  icon, a highlighted tip.
- `color.background.accent` → `.background.accent`: The fill of the one primary action on a screen, a checked box, a
  switch that is on. Use for: primary button, checked box, switch on. Avoid: Large areas, and more than one filled
  control on a screen. Status: use status.info.fill, even though info is the accent's blue today.
- `color.background.accent-hover` → `.background.accentHover`: The accent fill under the pointer.
- `color.background.accent-pressed` → `.background.accentPressed`: The accent fill while it is pressed: one step beyond
  accent-hover, further from its label, so text.on-accent reads on it as on the resting fill. Use for: pressed primary
  button, pressed checked box. Avoid: A resting or hovered fill: use background.accent or background.accent-hover. A
  pressed row or a quiet control: use background.pressed.

## `color.text`

- `color.text.primary` → `.text.primary`: Main text and glyphs.
- `color.text.secondary` → `.text.secondary`: Text and glyphs that come second: captions, metadata, a row's details,
  timestamps. On background.muted-hover and muted-pressed it is only a glyph, never text: the icon of an unlit chip
  under the pointer or pressed, decorative beside the chip's label (spec/components/chip, decisions/0001), so those
  pairs are non-text, 3:1.
- `color.text.placeholder` → `.text.placeholder`: The placeholder of an empty field. It meets the text target, as all
  words do.
- `color.text.on-accent` → `.text.onAccent`: Text and glyphs on the accent fill, also under the pointer and pressed:
  white, and the canvas's color in dark high contrast, where the fill turns light.
- `color.text.accent` → `.text.accent`: Links and accent text. Use for: link, accent text. Avoid: Status text: use
  status.<name>.text.

## `color.icon`

- `color.icon.tertiary` → `.icon.tertiary`: Glyphs that carry no words and need only 3:1: a chevron, a grip, a
  disclosure triangle. Use for: chevron, grip, disclosure. Avoid: Words: words are text.secondary at least.

## `color.border`

- `color.border.default` → `.border.default`: Separators and the outline of a card: decorative in standard themes, 3:1
  in high contrast, where every raised surface gets one. In the standard themes also the quiet ring of an unchecked
  check, below 3:1 by the deviation design-language/08 records; in high contrast that ring is border.strong.
- `color.border.guide` → `.border.guide`: The guides down the levels of a tree, one under each ancestor level of a
  nested row: decorative in the standard themes, where the indent also shows the nesting, and 3:1 in high contrast on
  every ground a row stands on, its highlights included, which border.default does not reach there. The palette's guides
  step (decisions/0012).
- `color.border.strong` → `.border.strong`: The border of a control that must be seen: a radio ring; and in the
  high-contrast themes a framed text field and a secondary button, where their muted fill alone does not mark their edge
  against the ground, and an unchecked check's ring, which is border.default in the standard themes. The ground is what
  that border is measured on, not the fill inside it.
- `color.border.focus` → `.border.focus`: The focus ring, and the bar or outline that marks a selected item, such as a
  selected ListRow's bar.
- `color.border.insertion` → `.border.insertion`: The line that marks where a dragged item would be dropped: an
  insertion rule; and the ring of a row a dragged item would be dropped onto, on its accent-subtle highlight. The focus
  ring's blue, a token of its own so that each can change without the other.

## `color.status`

- `color.status.danger.background` → `.status.danger.background`: The quiet ground of a badge, a banner or a row in the
  status danger.
- `color.status.danger.border` → `.status.danger.border`: The border of a field or a banner in the status danger, and of
  a destructive secondary button in the high-contrast themes.
- `color.status.danger.icon` → `.status.danger.icon`: The icon or dot of the status danger.
- `color.status.danger.text` → `.status.danger.text`: Text in the status danger.
- `color.status.danger.fill` → `.status.danger.fill`: The solid fill of the status danger: a button or a count badge.
- `color.status.danger.fill-hover` → `.status.danger.fillHover`: The danger fill under the pointer: a destructive filled
  button that is hovered. Use for: hovered destructive button. Avoid: A resting fill or a count badge: use
  status.danger.fill.
- `color.status.danger.fill-pressed` → `.status.danger.fillPressed`: The danger fill while it is pressed: one step
  beyond fill-hover, further from its label, so on-fill reads on it as on the resting fill. Use for: pressed destructive
  button. Avoid: A resting fill or a count badge: use status.danger.fill.
- `color.status.danger.on-fill` → `.status.danger.onFill`: Text and glyphs on the danger fill, also under the pointer
  and pressed.
- `color.status.warning.background` → `.status.warning.background`: The quiet ground of a badge, a banner or a row in
  the status warning.
- `color.status.warning.border` → `.status.warning.border`: The border of a field or a banner in the status warning.
- `color.status.warning.icon` → `.status.warning.icon`: The icon or dot of the status warning.
- `color.status.warning.text` → `.status.warning.text`: Text in the status warning.
- `color.status.warning.fill` → `.status.warning.fill`: The solid fill of the status warning: a button or a count badge.
- `color.status.warning.on-fill` → `.status.warning.onFill`: Text and glyphs on the warning fill.
- `color.status.success.background` → `.status.success.background`: The quiet ground of a badge, a banner or a row in
  the status success.
- `color.status.success.border` → `.status.success.border`: The border of a field or a banner in the status success.
- `color.status.success.icon` → `.status.success.icon`: The icon or dot of the status success.
- `color.status.success.text` → `.status.success.text`: Text in the status success.
- `color.status.success.fill` → `.status.success.fill`: The solid fill of the status success: a button or a count badge.
- `color.status.success.on-fill` → `.status.success.onFill`: Text and glyphs on the success fill.
- `color.status.info.background` → `.status.info.background`: The quiet ground of a badge, a banner or a row in the
  status info.
- `color.status.info.border` → `.status.info.border`: The border of a field or a banner in the status info.
- `color.status.info.icon` → `.status.info.icon`: The icon or dot of the status info.
- `color.status.info.text` → `.status.info.text`: Text in the status info.
- `color.status.info.fill` → `.status.info.fill`: The solid fill of the status info: a button or a count badge.
- `color.status.info.on-fill` → `.status.info.onFill`: Text and glyphs on the info fill.
- `color.status.neutral.background` → `.status.neutral.background`: The quiet ground of a badge, a banner or a row in
  the status neutral.
- `color.status.neutral.border` → `.status.neutral.border`: The border of a field or a banner in the status neutral.
- `color.status.neutral.icon` → `.status.neutral.icon`: The icon or dot of the status neutral.
- `color.status.neutral.text` → `.status.neutral.text`: Text in the status neutral.
- `color.status.neutral.fill` → `.status.neutral.fill`: The solid fill of the status neutral: a button or a count badge.
- `color.status.neutral.on-fill` → `.status.neutral.onFill`: Text and glyphs on the neutral fill.

## `color.chart`

- `color.chart.1` → `.chart1`: Series 1 of a chart.
- `color.chart.2` → `.chart2`: Series 2 of a chart.
- `color.chart.3` → `.chart3`: Series 3 of a chart.
- `color.chart.4` → `.chart4`: Series 4 of a chart.
- `color.chart.5` → `.chart5`: Series 5 of a chart.
- `color.chart.6` → `.chart6`: Series 6 of a chart.
- `color.chart.7` → `.chart7`: Series 7 of a chart.
- `color.chart.8` → `.chart8`: Series 8 of a chart.

## List colors: `color.category`

A list's color is a `Westron.Category`, kept by its name and read back with `Westron.Category(rawValue: list.color)`:
`blue`, `sky`, `teal`, `emerald`, `green`, `olive`, `amber`, `orange`, `red`, `pink`, `violet`, `indigo`.
`.category(_:)` on an ancestor draws the westron controls that take a list's color in it, such as a checked
`.toggleStyle(.check)` and an `IconTile`; nil keeps each control's own default. A product's own drawing reads a role of
the category, a `Westron.Color`: `.foregroundStyle(category.background)`. The roles:

- `.background`: The quiet ground of a tag or a row in the list color.
- `.border`: The border of an outlined tag in the list color.
- `.icon`: A dot or an icon in the list color.
- `.text`: Text in the list color.
- `.fill`: The solid fill of a lit tag in the list color.
- `.onFill`: Text and glyphs on the fill of the list color.
- `.control`: The fill of a checked control in the list color, such as the task check: the solid fill, darkened or
  lightened where it would not stand out from the ground the control sits on (decisions/0012, revision of 2026-11-18).
  Use for: checked task check, checked control in a list color. Avoid: Tags, tiles and statuses: they keep fill, which
  is not held to the non-text contrast on the ground.
- `.onControl`: The mark and any glyph on the control fill of the list color. Use for: check mark on a checked task
  check. Avoid: Text on a lit tag: use on-fill.
