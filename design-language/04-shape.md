# 04. Shape

Date: 2026-11-15. Status: draft for the owner's approval (#8).

Shape is corners, lines and shadows: how a thing is outlined and how far it stands off what is under it. westron keeps
all three soft and few, so that content, not frames, holds the eye (chapter 00, principle 4). The values are in
`tokens/semantic/radius.tokens.json`, `stroke.tokens.json` and `shadow.tokens.json`.

## Corners

- **Rounded, never sharp.** Every surface westron draws has round corners: rows, cards, fields, chips, tiles, columns.
  Round corners read as soft and fit beside the system's own controls, which are rounded on every platform westron
  targets.
- **One ladder, shared with space.** `radius.75`, `100`, `125`, `150`, `175` and `225` are steps on the same ladder as
  `space.*` (chapter 06): `radius.100` equals `space.100`. So a corner and the padding inside it are chosen from the
  same scale and stay in proportion.
- **A larger thing has a larger corner.** A small control or a sidebar row takes a low step; a card, a column or an
  empty state's tile takes a high one. A corner that is too small on a large surface looks sharp; one too large on a
  small control turns it into a pill by accident.
- **A capsule is the platform's capsule.** Chips, pills, the phone's search field and the Done strip are capsules:
  fully round ends at any height. They use the platform's capsule shape, never a large radius, so they stay capsules
  when Dynamic Type makes them taller.
- **A shape that scales has its own rule.** A list's tile keeps its corner in proportion to its side. That proportion is
  the tile's own rule, written in its contract, not a step of the ladder.
- **Off-ladder corners belong to one component.** The pilot uses a few odd radii, each in one place. A component that
  needs one keeps it in its own contract (a component tier, decisions/0010), so the ladder stays short.

## Lines

- **Four widths, each with a job.** `stroke.hairline` edges glass and a card on a fill. `stroke.thin` draws rules,
  dividers and tree guides in a sidebar. `stroke.regular` draws guides on a phone, a dashed outline and a small check's
  ring. `stroke.thick` draws a focus ring, a drop indicator and a selection ring.
- **A thicker line means more attention.** The thick width is for things a person must find at once: where focus is,
  where a dragged item will land. Rules and guides stay thin, because space and alignment already show the grouping.
- **Color comes from the border tokens** (`color.border.*`, chapter 02). In the high-contrast themes rules and guides
  gain contrast until they are real boundaries; their widths stay.

## Shadows

Shadows mean depth, and depth means that something is lifted or floats. Content at rest is flat.

| Token | What casts it |
|---|---|
| `shadow.resting` | A card at rest on a fill, such as a card in a board column |
| `shadow.hovered` | The same card under the pointer |
| `shadow.raised` | A control raised off what it stands on, such as a floating button or an open card |
| `shadow.lifted` | Something a drag carries |

- **One layer, black, the same in both themes**, as in the pilot. A shadow is a hint of height, not a decoration, so a
  single soft layer is enough.
- **The order is the height.** Resting is barely there, lifted is unmistakable. A component never mixes two shadows to
  get a height between them.
- **System surfaces bring their own shadow.** Liquid Glass, sheets, popovers and menus cast the system's shadow, and
  westron adds none (chapter 09).
- **Blur is written as CSS writes it.** The token holds the blur as DTCG and CSS define it; the Apple generator halves
  it into SwiftUI's radius, as the pilot does by hand.

## Open questions

1. **The canvas's shadows.** The canvas draws two warm layers in light and much heavier black shadows in dark. The
   pilot collapsed each to one black layer, the same in both themes. Keep the pilot's, or bring back the canvas's
   warmth and a dark-theme variant?
2. **Corner style.** The pilot mixes two corner curves: most of its shapes use circular corners, as the canvas's CSS
   draws them, while its title field, search field, picker tile and drag cards keep SwiftUI's default continuous
   corners. Proposal: one rule for all westron shapes. Which one: circular, as the canvas, or continuous, as the
   system's own controls?
3. **The tile's corner.** The pilot's tile radii fit one proportion of the tile's side, but the canvas does not state
   it as a rule. Adopt the proportion as the tile's rule?
4. **Shadows in high contrast.** An open card differs from the canvas by little more than its shadow, and the
   high-contrast themes keep both surfaces as they are. Should a raised surface get an outline in those themes?
