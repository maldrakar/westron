# 0013. Typography, space, shape and motion

Date: 2026-11-15. Status: proposed; the owner approves it with the catalog's samples (#11).

## Context

The pilot sets its text with Apple text styles, a weight and a rounded flag, with no point sizes of its own. Its
spacing and radii are numbers inside its components, keyed by window width. Its motions are named by use, and it
draws its springs with no bounce. The inventory of these values is in `research_notes/pilot-inventory.md` and in the chapters
`design-language/03`–`06`.

## Decision

### Text roles

- Fifteen roles, named by the text style they follow and their weight: `typography.heading.large`, `.medium`,
  `.small`, `.overline`, and `body`, `callout`, `subheadline`, `footnote`, `caption` with `regular`, `medium` or `strong`
  (semibold) where the pilot uses them. They cover the pilot's seventeen roles; two pairs of the pilot's roles were the
  same font.
- Each role is a DTCG typography token. Its size and line height are Apple's iOS values for the text style at the
  default text size, so that the web and GNOME have numbers to start from. The family is `font.family.system` or
  `font.family.rounded` (decisions/0011), and `$extensions.dev.westron.apple.textStyle` names the text style.
- On Apple a role is `Font.system(textStyle, design:weight:)`: the size follows the platform and Dynamic Type, so the
  Mac is smaller by itself. No tracking or line spacing is applied yet, as in the pilot.

### Space, radius, stroke

- `space.<step>` and `radius.<step>` are steps on one ladder where 100 is the base unit of 8 px: `space.25` is 2 px,
  `space.150` is 12 px. A step's name does not change when a density changes its value.
- Space: 2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 40, 48 px, which covers 85 % of the pilot's spacing values. Radius: 6, 8,
  10, 12, 14, 18 px. A capsule uses the platform's capsule shape. Odd values (3, 5, 7, 9, 11, 13, 15) stay inside the
  components that use them and move to their contracts.
- Strokes: `stroke.hairline`, `thin`, `regular`, `thick` (0.5, 1, 1.5, 2 px).

### Shadows

Four shadows, `shadow.resting`, `hovered`, `raised`, `lifted`, as the pilot casts them: one black layer, the same in
every theme. `blur` is the CSS blur; on Apple the shadow's radius is half of it.

### Motion

- Each motion is a DTCG `transition` named by what moves: `motion.check`, `motion.fold`, `motion.row-leave`, and so on.
  Curves are primitives in `easing.*`.
- A motion the pilot draws as a spring carries `$extensions.dev.westron.spring` (duration and bounce). Apple uses the
  spring; a platform without springs uses the transition's curve.
- The pilot's two unused motions (push and pop, Quick Entry) are left out: the system draws those.

## Why

- Text styles keep Dynamic Type and the platform's own sizes, which the pilot already relies on.
- Step names let `density` change values without renaming tokens, which value names (`space.8`) would not.
- Naming motions by what moves lets a component pick the right one without knowing durations.

## Consequences

- The spring's bounce is 0, as the pilot draws it, while the curve in the token overshoots, as the canvas draws it.
  Until the owner settles which is right (`design-language/05-motion.md`), that difference between Apple and the other
  platforms is recorded here.
- Component contracts in phases 2–4 bind to these tokens; a value a component needs that is not on a ladder stays in
  its contract.
