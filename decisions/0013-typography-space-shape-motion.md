# 0013. Typography, space, shape and motion

Date: 2026-11-15. Status: accepted. The owner chose direction B on the direction specimens. Its default density is
comfortable.

## Context

westron's look is its own, not the pilot's (decisions/0006). The research is in
`research_notes/space-shape-motion.md`. It covers:

- how Primer, Carbon, Spectrum, Fluent, Atlassian, Material, Apple and libadwaita build spacing, density, radii,
  elevation and motion;
- three directions, A precise, B soft and C expressive, and the knobs that set each one apart.

The owner chose B: the soft shape and its rhythm, with the cobalt palette (decisions/0012) and Onest for headings
(decisions/0011). Its kin are libadwaita, Apple's grouped lists and Spectrum 2.

## Decision

### Text roles

- **Seventeen roles, named by the text style they follow and their weight.**
  - Headings: `typography.heading.large`, `medium`, `small` and `overline`, in Onest.
  - Text: `body`, `callout`, `subheadline`, `footnote` and `caption`, with `regular`, `medium` or `strong`
    (semibold), in the system font.
  - Code: `code.regular` and `code.strong`, in Geist Mono at the subheadline size, a step below body text, as in the
    specimen the owner chose. The footnote size would make code 10 pt on the Mac.
- **Each role is a DTCG typography token.** Its size and line height are Apple's iOS values for the text style at the
  default text size, so the web and GNOME have numbers to start from. `$extensions.dev.westron.apple.textStyle` names
  the text style.
- **Heading weights and tracking.**
  - Large and medium are Bold, small and overline SemiBold.
  - Headings are tracked in by 1 % of their size.
  - The overline is written in capitals by the product and tracked out by 6 %.
  - On Apple the font cannot carry tracking, so a view sets a heading with `.textRole(.heading.large)`, which
    applies the font and the token's `letterSpacing`. `Font(.heading.large)` alone sets the face without the
    tracking.
- **On Apple a role scales with Dynamic Type.** A heading or code role is `Font.custom(_:size:relativeTo:)` with its
  text style, at the size the platform gives that text style, as the system font takes it: the Mac's sizes are
  smaller than iOS's. watchOS has no API for that size, so there the token's size, which is iOS's, is used. A text
  role is `Font.system(_:design:weight:)`.

### Space and rhythm

- **The ladder.** `space.<step>` is a 4 px grid with an 8 px base, where 100 is 8 px: 2, 4, 6, 8, 10, 12, 16, 20, 24,
  32, 40, 48, 64. The names say steps, not values: `space.150` is 12 px.
- **B's rhythm.** It is generous, on the 8 px base:

  | Where | Comfortable | Token |
  |---|---|---|
  | A card's padding | 16 | `space.200` |
  | The gap inside a group | 12 | `space.150` |
  | The gap between groups | 24 | `space.300` |
  | The page margin, narrow / wide | 20 / 32 | `space.250` / `space.400` |
  | A web control / list row / table row | 32 / 44 / 36 | |

  Rows on touch platforms keep the platform's recommended hit target: 44 pt on iOS, 48 dp on Android
  (research_notes/space-shape-motion.md 6.3, 6.4).
- **Density.** Density changes the sizes and insets of components, never the ladder, the text size, the page margins
  or the gaps between sections. Compact makes controls and rows one 8 px step smaller, halves cell insets and moves
  gaps inside a group one step down. Comfortable, the `regular` context of the `density` modifier, is the default for
  every product. The tokens for control and row
  sizes come with the dense components (#33): the platform supplies both columns and the density picks one, so no
  token is set by two modifiers (decisions/0010).

### Shape

- **Radius ladder.** `radius.<step>` is on the space ladder: 2, 4, 6, 8, 12, 16, 24 and 32 px. A capsule uses the
  platform's capsule shape, not a radius.
- **Radius by kind of shape.**

  | Token | Radius | For |
  |---|---|---|
  | `radius.control` | 8 | a button, a field, a segmented control westron draws |
  | `radius.row` | 8 | the highlight of a row under the pointer or selected |
  | `radius.card` | 12 | a card or a panel on the canvas |
  | `radius.overlay` | 12 | a popover or a menu westron draws |
  | `radius.sheet` | 16 | a sheet or a dialog westron draws |

  Tags and badges are capsules. Controls are rounded at about a quarter of their height: 8 on 32.
- **Nesting.** A shape that sits within its container's corner, closer to the edge than the container's radius,
  takes `max(outer − inset, 4)`, so the corners stay concentric. Further in, a shape keeps its own role's radius: a
  row highlight inside a card with 16 px of padding stays `radius.row`. On Apple 26 and
  later, `ConcentricRectangle` does this where westron content meets the edge of the device or the window.
- **Corners.** Corners are continuous on Apple, as the system's are, and circular on the web, GNOME and Android.
- **Strokes.** `stroke.hairline`, `thin`, `regular` and `thick` are 0.5, 1, 1.5 and 2 px.

### Shadows

- **Three shadows, each in two layers.** Each has a close key layer and a wide ambient one. `blur` is the CSS blur;
  on Apple the shadow's radius is half of it.

  | Token | Light | Dark |
  |---|---|---|
  | `shadow.raised` | `0 1 2` 6 %, `0 1 3` 10 % | none: the raised surface is lighter than the canvas |
  | `shadow.overlay` | `0 4 12` 8 %, `0 12 32` 12 % | three times as opaque |
  | `shadow.dragged` | `0 8 16` 10 %, `0 16 40` 16 % | three times as opaque |

- **High contrast.** The high-contrast themes keep the shadows and outline every raised surface in
  `color.border.default` at `stroke.thin`, because a shadow alone does not mark an edge.
- **Shadows are part of the theme.** The theme modifier merges them in (`semantic/shadow.<light|dark>.tokens.json`),
  and on Apple `View.shadow(_:)` picks the layers of the environment's theme.
- **Never shadow what the system draws:** a sheet, a popover, a menu, glass.

### Motion

- **A motion is named by what moves.** Each is a DTCG `transition`. Where a motion has
  `$extensions.dev.westron.spring` (duration and bounce), platforms with springs use the spring; the others use its
  curve and duration.

  | Token | Spring (duration, bounce) | Curve | For |
  |---|---|---|---|
  | `motion.fade` | — | 200 ms, `ease` | color and opacity |
  | `motion.press` | 0.15 s, 0 | `standard` | a control's tint and its scale down to 98 % |
  | `motion.toggle` | 0.25 s, 0.1 | `standard` | a switch's thumb, a segmented selection |
  | `motion.check` | 0.35 s, 0.2 | `standard` | a check popping: the one visible overshoot |
  | `motion.move` | 0.35 s, 0.15 | `standard` | a reordered row, a drop, a section folding |
  | `motion.enter` | 0.35 s, 0.15 | `enter` | a popover, a menu, an inserted row |
  | `motion.leave` | — | 200 ms, `exit` | something leaving, quicker than it came |
  | `motion.reveal` | 0.5 s, 0.1 | `standard` | a sheet, a side panel, an opened card |

- **Easing.** The curves are primitives: `easing.standard` `[0.2, 0, 0, 1]`, `enter` `[0, 0, 0, 1]`, `exit`
  `[0.3, 0, 1, 1]`, and `ease`, CSS's and libadwaita's.
- **One spring for every platform.** SwiftUI takes `spring(duration:bounce:)`. libadwaita and Compose take stiffness
  `(2π / duration)²` and damping ratio `1 − bounce`. CSS samples the spring into `linear()` at build time. So all four
  overshoot by the same amount.
- **Reduce Motion.**
  - A spring loses its bounce.
  - Travel becomes a fade of at most 150 ms.
  - Scale and depth changes are dropped.
  - Color fades stay, and so does a pause that lets a person read.
  - "Off" (`gtk-enable-animations = false`, an animator scale of 0) means instant.

## Why

- **Text styles.** They keep Dynamic Type and each platform's own sizes. The brand lives in the heading face and
  its weight.
- **The 4 px grid with an 8 px base.** It is Atlassian's naming with Carbon's and Spectrum's values, and Primer and
  Fluent sit on the same grid. libadwaita works in 6 px steps, and Apple publishes no grid.
- **Density changes components, not the ladder.** No surveyed system rescales its ladder, and page margins should not
  shrink in a dense view.
- **The radius ratio.** It sets the character: about 0.15 of the height reads precise, 0.25 soft, 0.5 expressive.
  B's 0.25 sits next to Apple's and Adwaita's own controls without looking foreign.
- **Shadows by theme.** Two layers are what Fluent, Spectrum and libadwaita draw, and all of them change shadows by
  theme. One black layer for both themes was the outlier. In dark, a lighter surface shows the height better than a
  shadow.
- **One spring model.** A duration and a bounce map exactly onto every platform's springs. A hand-made overshooting
  curve would differ on each.

## Consequences

- **Motion.** The pilot's motions, such as a done row lingering 0.7 s before it leaves, become the product's
  behavior. They are built on these tokens.
- **Density.** The size tokens for controls and rows, and the compact context, arrive with #33.
- **Reduce Motion.** The rule lives here until a component needs it in tokens. It can then become a westron
  extension, `dev.westron.reducedMotion`.
- **Component contracts.** Contracts in phases 2–4 bind to these tokens. A value a component needs that is not on a
  ladder stays in its contract.
