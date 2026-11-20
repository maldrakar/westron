# 0013. Typography, space, shape and motion

Date: 2026-11-15. Status: accepted. The owner chose direction B on the direction specimens. Its default density is
comfortable. Revised 2026-11-16: control heights and the disabled opacity. Revised 2026-11-18: the roles of the
spacing rhythm and where the page margin applies. Revised 2026-11-20: buttons are capsules, the iOS control heights,
the minimum hit target.

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

## Revision of 2026-11-16

In the Button interview (#22) the owner chose the control heights and how a disabled control looks; #56 added the
tokens.

- **Control heights come before the dense components.** `size.control.s`, `m` and `l` differ by platform, because
  the input decides the size: 24, 32 and 40 on macOS; 32, 44 and 52 on iOS, iPadOS and watchOS. Size `m` is the 32 px
  control above on a pointer and the 44 pt touch target of chapter 08 on touch. They live in
  `tokens/platform/<platform>.tokens.json` (decisions/0010). Row heights and the compact column still come with #33;
  until then `compact` is empty and both densities take these heights. `radius.control` stays 8, a quarter of 32;
  whether a taller control takes a larger radius is for its contract to say.
- **A disabled control is dimmed whole.** `opacity.disabled` is 0.4, and a disabled control is drawn at it, fill,
  border, label and icon together, instead of in colors of its own. It sits between Apple's disabled ink, about
  25–30 % (iOS's tertiary label is 30 %), and libadwaita's `--disabled-opacity`, 50 % and 40 % in high contrast: dim
  enough that a disabled filled button never reads as the primary action next to an enabled one, and clear enough to
  keep its label and its variant recognizable. One value serves every theme; WCAG exempts an inactive control from
  contrast (chapter 08).

## Revision of 2026-11-18

In the interview for the phase 3 layout primitives (#29) the owner turned B's rhythm into tokens and answered two open
questions of chapter 06. The owner answered three things: five semantic roles for the rhythm, the page margin switching
by horizontal size class, and westron's margins applying only to layout the product builds itself. Two parts below are
not the owner's and wait for the owner's confirmation: the role names, which the implementing agent chose, and "no
Swift helper for the page margin in this phase", which the coordinator decided under the owner's delegation of
2026-11-18.

- **The rhythm gets five semantic roles.** They alias the ladder, as `radius.card` aliases a radius step:

  | Where | Token | Aliases | Apple |
  |---|---|---|---|
  | A card's padding | `space.card` | `space.200`, 16 | `CGFloat.space.card` |
  | The gap inside a group | `space.within-group` | `space.150`, 12 | `CGFloat.space.withinGroup` |
  | The gap between groups | `space.between-groups` | `space.300`, 24 | `CGFloat.space.betweenGroups` |
  | The page margin on a narrow window | `space.page.narrow` | `space.250`, 20 | `CGFloat.space.page.narrow` |
  | The page margin on a wide window | `space.page.wide` | `space.400`, 32 | `CGFloat.space.page.wide` |

  The names `space.card`, `space.within-group`, `space.between-groups`, `space.page.narrow` and `space.page.wide` are
  the implementing agent's, under the owner's delegation of 2026-11-18, pending the owner's confirmation.

  A role names where the space goes, so the compact density (#33) can point a role at another step, such as the gap
  inside a group one step down, without changing the ladder or the code that uses the role. The density's values
  still arrive with #33.
- **Narrow and wide follow the horizontal size class on Apple.** Compact takes `space.page.narrow`, regular takes
  `space.page.wide`, and a Mac is always wide. On the web, GNOME and Android it is a breakpoint, decided in their
  phases. westron adds no Swift helper that picks the margin yet: new public API in WestronUI needs a contract or a
  reviewed adapter, so a product reads the size class itself for now. This is the coordinator's decision under the
  owner's delegation of 2026-11-18, pending the owner's confirmation.
- **westron's margins apply only to layout the product builds itself:** a `ScrollView`, a stack, a grid. The system's
  `List`, `Form` and bars keep their own insets, as a system control keeps its own look (decisions/0003).
- **Left for later.** Nesting guides and the labelled area line belong to a phase 4 component; the values of compact
  come with #33.

## Revision of 2026-11-20

At the second gate of phase 3 the owner found the controls' function and colors right and their look not yet (#85).
The owner compared prototype renders of three button looks with Apple's own buttons on an iPhone 17 and chose one on
2026-11-20. The Button contract records the bindings
(`spec/components/button/decisions/0003-the-look-of-2026-11-20.md`).

**The owner's decisions:**

- **Buttons are capsules.** Every variant and size of a button is the platform's capsule, and an icon-only button a
  circle whose diameter is its height, never a large radius (as chapter 04 already asked of tags). A control westron
  draws as a button no longer takes `radius.control`; fields and the segmented control still do, and `radius.control`
  stays 8. Fills are flat and opaque, in westron's colors, with no glass or material.
- **Secondary is filled, not outlined.** A neutral gray, `color.background.muted`, with its words in
  `color.text.primary` and no border. Its hover and pressed fills are darker steps of that gray, two new tokens. The
  destructive role keeps the gray and writes its words in `color.status.danger.text`.
- **Control heights on iOS and iPadOS are 28, 36 and 50** for `s`, `m` and `l`, where they were 32, 44 and 52. They
  sit beside the system's own buttons, which iOS 26 draws 28, 34 and 50 tall at its small, regular and large sizes, so
  westron's controls no longer stand a size taller than the system's next to them. The change is in the shared tokens,
  `size.control.*`, so it applies to every control drawn at those heights, the text field included. macOS keeps 24, 32
  and 40.
- **Hit areas do not shrink.** A control's height and its hit area are now separate: `size.control.m` is no longer the
  touch target on iOS, so the target is a token of its own, below.
- **Padding and type.** A button's horizontal padding is `space.200`, `space.250` and `space.300` (16, 20, 24) at `s`,
  `m` and `l`, the same on both sides, on every platform. Its words are `footnote.strong`, `subheadline.strong` and
  `body.strong`.
- **The icon sits on the baseline.** Beside a label it is the symbol's small scale in the label's text role, its
  baseline on the label's first text baseline, with a gap of `space.50`, `space.50` and `space.75` (4, 4, 6).
- **watchOS is not decided.** The owner did not see the watch: `tokens/platform/watchos.tokens.json` keeps 32, 44 and
  52, pending the owner's look at it.

**The implementing agent's decisions, pending the owner's review with the snapshot matrix:**

- **`size.target.minimum`.** A platform token for the least side of a control's hit area: 44 on iOS, iPadOS and
  watchOS, the recommended touch target, and 28 on macOS, the recommended pointer target (chapter 08). The text field
  and Button take it where they named "the recommended target"; the check keeps the larger of it and
  `size.control.m`, so its macOS hit area stays 32. Every hit area keeps the size it had, which the catalog's hit-area
  tests measure.
- **The muted fill's states.** `color.background.muted-hover` and `muted-pressed` alias two members the palette
  generator solves for the neutral ramp, `muted-hover` and `muted-pressed`, as it solves `fill-pressed`
  (decisions/0012): step 4 moved towards its words, `muted-pressed` up to two hover steps of 0.04 in OKLCH lightness
  and no further than every ramp's words, steps 11 and 12, still reach the text target on it, and `muted-hover`
  halfway. Colored words are solved to just reach their target on step 5, so the words, not the hover steps, set how
  far the fill darkens: `muted-pressed` lands on step 5's tone (in light `#E5E9EE` against step 5's `#E6E9EF`; the
  red words on it at 4.51:1). That is less than the owner saw in the prototype, which darkened the pressed fill by a
  tenth of its words' color; a darker press would need darker red words, which no chapter allows yet. It is an open
  point for the owner (the Button decision, "Open").
- **The high-contrast outline.** In the high-contrast themes a secondary button keeps an outline, `color.border.strong`
  or `color.status.danger.border` at `stroke.thin`: the muted fill stands about 1.1:1 off the canvas, chapter 02 asks
  that the edge of a control a person must find meets the non-text target, and the high-contrast themes keep steps
  1–5, so no fill alone can mark that edge there.
- **The capsule's ends are circular.** SwiftUI's `Capsule()` with circular ends, as the prototype drew it, so that
  icon-only is a true circle. A continuous capsule draws a square frame as a rounded square.

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
- **Density.** The size tokens for controls and rows, and the compact context, arrive with #33. Compact points the
  rhythm's roles at its own steps there.
- **Reduce Motion.** The rule lives here until a component needs it in tokens. It can then become a westron
  extension, `dev.westron.reducedMotion`.
- **Component contracts.** Contracts in phases 2–4 bind to these tokens. A value a component needs that is not on a
  ladder stays in its contract.
