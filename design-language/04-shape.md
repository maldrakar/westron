# 04. Shape

Date: 2026-11-15. Status: draft for the owner's approval (#8). It follows
[decisions/0013](../decisions/0013-typography-space-shape-motion.md), which the owner accepted by choosing direction B.

Shape is corners, lines and shadows: how a thing is outlined and how far it stands off what is under it. Direction B
makes all three soft: corners at about a quarter of a control's height, quiet lines, and shadows in two soft layers.
This chapter says why. The values are in decisions/0013 and in `tokens/semantic/radius.tokens.json`,
`stroke.tokens.json`, `shadow.light.tokens.json` and `shadow.dark.tokens.json`.

## Corners

- **About a quarter of the height.** `radius.control` is 8 px on a 32 px control. The ratio of radius to height sets a
  look's character: about 0.15 reads precise, 0.25 soft, 0.5 expressive. At 0.25 westron's controls sit next to
  Apple's and Adwaita's own without looking foreign. libadwaita's buttons and Spectrum 2's controls have about the
  same ratio (`research_notes/space-shape-motion.md`, 2.3).
- **A radius for each kind of shape.** A component takes a role, never a step:

  | Token | For |
  |---|---|
  | `radius.control` | A segmented control westron draws, the focus ring of an inline field; a button and a one-line field are capsules, a multiline field takes `radius.150` |
  | `radius.row` | The highlight of a row under the pointer or selected |
  | `radius.card` | A card or a panel on the canvas |
  | `radius.overlay` | A popover or a menu westron draws; system ones keep their own |
  | `radius.sheet` | A sheet or a dialog westron draws |

- **A larger thing has a larger corner, within limits.** Controls and rows have the smallest corner, cards and overlays
  a larger one, sheets the largest. Container corners stay modest. A large corner pushes content away from the edge,
  and that costs room in a table or a log.
- **The roles sit on one ladder.** `radius.25` to `radius.400` are steps of the space ladder (chapter 06): `radius.100`
  equals `space.100`. So a corner and the padding inside it come from one scale and stay in proportion.
- **A capsule is the platform's capsule.** Buttons, one-line text fields, tags and badges are capsules: fully round
  ends at any height, and an icon-only button is a circle. They use the platform's capsule shape, never a large
  radius, so they stay capsules when Dynamic Type makes them taller (decisions/0013, revision of 2026-11-20). A field
  that grows to several lines is a rounded rectangle, `radius.150`: a capsule's ends would cut into its lines.
- **Nested corners share a center.** A shape that sits within its container's corner, closer to the edge than the
  container's radius, takes `max(outer − inset, 4)`, so the two corners stay concentric and the inner one never turns
  square. Further in, a shape keeps its own role's radius: a row highlight inside a card with 16 px of padding stays
  `radius.row`. So a surface draws its role's radius, and the concentric rule applies only within the corner zone,
  where the product applies it; no nested pair is computed or stored (the Surface contract, #29, 2026-11-18). Apple
  describes its concentric shapes the same way ([WWDC25 356](https://developer.apple.com/videos/play/wwdc2025/356/)). On Apple 26 and later, `ConcentricRectangle`
  applies the rule where westron content meets the edge of the device or the window. Older systems use the radius
  computed from the tokens ([decisions/0008](../decisions/0008-apple-toolchain-and-catalog.md)).
- **Corners are continuous on Apple and circular elsewhere.** Apple's controls and glass have continuous corners, and
  westron's shapes match them. GTK and most browsers cannot draw that curve natively, and on Android it would disagree
  with Material's shapes. The curve is a trait of the platform, so every contract records the same difference in its
  `platforms` block.
- **Off-ladder corners belong to one component.** A shape that needs another radius, or one whose corner scales with
  its own size, keeps its rule in its contract (a component tier,
  [decisions/0010](../decisions/0010-token-structure-and-modes.md)). The ladder stays short.

## Lines

- **Four widths, each with a job.** `stroke.hairline` edges glass and a card on a fill. `stroke.thin` draws rules,
  dividers and tree guides in a sidebar. `stroke.regular` draws guides on a phone, a dashed outline and a small check's
  ring. `stroke.thick` draws a focus ring, a drop indicator and a selection ring.
- **A thicker line means more attention.** The thick width marks what a person must find at once: where focus is,
  where a dragged item will land. Rules and guides stay thin, because space and alignment already show the grouping.
- **A card needs no outline.** In the standard themes a card is set off from the canvas by its tone, and in light also
  by its shadow. A hairline edges it only where tone does not, such as a card on a fill.
- **Color comes from the border tokens** (chapter 02). `color.border.default` draws separators and an unchecked
  check's quiet ring, `border.strong` the outline of a control a person must find in high contrast, and `border.focus`
  the focus ring. In the high-contrast themes lines gain contrast through their color, and their widths stay.
- **A filled control needs no outline, except in high contrast.** A secondary button and a framed text field are set
  off by their muted fill. In the high-contrast themes the fill stays as quiet as in the standard ones, so they also
  draw `border.strong` at `stroke.thin`, as a raised surface draws its line there, and an unchecked check's ring turns
  from `border.default` to `border.strong`. In the standard themes these edges stay below 3:1, a deviation the owner
  accepted (chapter 08).

## Shadows

Depth means that something stands off what is under it. Three kinds of thing do, with one token each. Everything else
is flat: a row, a field or a tag casts no shadow.

| Token | What casts it | Light | Dark |
|---|---|---|---|
| `shadow.raised` | A card or a panel raised off the canvas | Two faint layers | None: the card is lighter |
| `shadow.overlay` | A popover, a menu or a floating button westron draws | Two soft layers | Three times as opaque |
| `shadow.dragged` | Something a drag carries | Two deeper layers | Three times as opaque |

- **Two layers, a close one and a wide one.** The close layer marks where a thing meets its ground, and the wide one
  shows how far it floats. Fluent, Spectrum and libadwaita draw layered shadows too; one black layer for every theme
  was the outlier among the systems surveyed (decisions/0013).
- **The order is the height.** A raised card barely lifts, an overlay floats, and a dragged item is unmistakable. A
  component never stacks two shadows to get a height between them.
- **In dark, tone shows the height.** Higher is lighter in every theme (chapter 02), and a black shadow barely shows on
  a near-black ground. So a raised card casts no shadow in dark. Overlays and dragged items keep theirs, three times as
  opaque as in light, as Spectrum does.
- **Shadows are part of the theme.** The theme modifier merges in `shadow.light` or `shadow.dark`
  ([decisions/0010](../decisions/0010-token-structure-and-modes.md)). On Apple, `.shadow(_:)` picks the layers of the
  environment's theme.
- **In high contrast, every raised surface gets an outline.** The high-contrast themes keep the shadows and outline
  every raised surface in `color.border.default` at `stroke.thin` (decisions/0013), because a shadow alone does not
  mark an edge. On the web, forced
  colors remove shadows altogether ([CSS Color Adjust](https://www.w3.org/TR/css-color-adjust-1/)). For the same
  reason a focus ring is always a line, never a shadow.
- **System surfaces bring their own shadow.** Sheets, popovers, menus and Liquid Glass cast the system's shadow, and
  westron adds none (chapter 09).
- **Blur is written as CSS writes it.** The token holds the blur as DTCG and CSS define it. On Apple a shadow's radius
  is half of it.

## Open questions

The Surface contract (#29) answered questions 1 and 3 on 2026-11-18: nested corners ("Nested corners share a center")
and the width of the high-contrast outline, `stroke.thin` ("In high contrast, every raised surface gets an outline").
Questions 2 and 4 keep their numbers.

2. **The control's corner in compact.** Compact makes controls one 8 px step shorter (chapter 06). Should
   `radius.control` follow, to stay about a quarter of the height? It would be the first radius set by density (#33).
4. **Cards on GNOME.** libadwaita's `.card` class draws a native card with its own shadow, dark variant and
   high-contrast outline. Should a raised surface on GNOME use that class and record the difference, or draw westron's
   tokens (phase 7)?
