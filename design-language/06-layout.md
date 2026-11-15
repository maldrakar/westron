# 06. Layout

Date: 2026-11-15. Status: draft for the owner's approval (#8).

Layout is space, size and how a screen adapts. westron keeps one short ladder of space, makes density a mode rather
than a set of variants, and lets size follow the platform and the person's text size. The values are in
`tokens/semantic/space.tokens.json`; the modes are in [decisions/0010](../decisions/0010-token-structure-and-modes.md).

## The space ladder

- **One ladder for gaps, paddings and insets.** `space.25` to `space.600`. A name is a step on the ladder, and `100`
  is the base unit: `space.200` is twice the base, `space.50` half of it.
- **Names are steps, not sizes.** A density can change what a step is worth without renaming it (below), so a
  component written with `space.150` stays correct in every density. A name like `space.12` would lie as soon as the
  value changed.
- **The ladder is short on purpose.** Its steps cover most of the pilot's spacing (85 % of the declarations), and the
  rest are values used in one place. A short ladder keeps neighboring components in the same rhythm, and it gives an
  agent few enough choices to pick the right one.
- **Off-ladder values belong to a component.** An odd gap used by one component, or a position derived from other
  geometry (a body that starts after a check's hit area, an indent per level of a tree), lives in that component's
  contract, in a component tier when one is needed (decisions/0010). It does not become a new step.
- **Corners use the same ladder** (chapter 04), so a corner and the padding inside it stay in proportion.

## Density is a mode

- **`density` is a modifier with `regular` and `compact`**, resolved at runtime through the environment, like the
  theme. It owns spacing and control sizes, never text sizes (chapter 00, principle 4).
- **Why a mode and not a variant.** A dense table, a log or a long list is dense as a whole, and every component in it
  must agree. One environment value keeps them agreeing; a `compact` option on each component would let them drift.
  SwiftUI cascades `controlSize` the same way.
- **`compact` is empty until it has a consumer.** It gets values with the dense components (#33). The pilot cannot be
  its source: its phone and wide layouts differ by no single factor, so compact values must be designed, not computed
  by scaling.

## Size follows the platform

- **The pilot keys its numbers by width.** It has a phone set for narrow windows and a wide set for the Mac and the
  iPad, chosen by the window's width class.
- **westron keys them by platform.** A value that differs between iOS, macOS and watchOS lives in the `platform`
  modifier, resolved at build time, and only where it differs (decisions/0010). The input decides the size: touch
  needs larger targets than a pointer, whatever the width.
- **Width still decides structure.** Whether a screen shows a sidebar, a stack or columns follows the width class, not
  the device (chapter 09). So an iPad shows the wide layout with touch-sized controls.
- **Hit targets follow chapter 08.** The platform's recommended size is the target, and the hit area may be larger
  than what is drawn. The pilot's iPad uses the Mac's metrics with touch, which puts its rows and checks under the
  touch target; keying sizes by platform fixes that.

## Text size and containers

- **Text scales; containers must make room.** Every role follows Dynamic Type (chapter 03), and so does the spacing
  that belongs to text (`@ScaledMetric` on Apple). A row, a bar or a header must grow with its text.
- **The pilot does not do this yet.** Many of its containers have fixed heights, so its text clips at large sizes,
  while its task rows use a minimum height and grow. westron's rule is the second one: a minimum height, never a fixed
  one, wherever text sits.
- **Screen-level measures belong to the product or the component**: a sidebar's width, the maximum width of readable
  content, a board column's width. They are not steps of the space ladder.

## Open questions

1. **Fixed-height containers.** Moving the pilot's rows, bars, headers and chips from fixed to minimum heights changes
   how they look at large text sizes, and some bars may need to wrap or scroll. Agree to the rule, and to the change in
   the pilot?
2. **The iPad.** westron gives the iPad touch-sized metrics where the pilot uses the Mac's. Its sidebar rows and checks
   get taller. Agree?
3. **A small step.** The pilot's metadata lines use a gap between `space.25` and `space.50` often enough to be a
   candidate step. Add it to the ladder, or keep it in the components that use it?
