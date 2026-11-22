# 05. Motion

Date: 2026-11-15. Status: draft for the owner's approval (#8). It follows
[decisions/0013](../decisions/0013-typography-space-shape-motion.md), which the owner accepted by choosing direction B.

Motion explains a change and then gets out of the way (chapter 00, principle 3). Every westron motion answers "what
changed, and where did it go?". Direction B moves on springs with a light bounce: a thing arrives quickly and settles
with a short tail, and only a check visibly overshoots. This chapter says why. The values are in decisions/0013,
`tokens/primitive/easing.tokens.json` and `tokens/semantic/motion.tokens.json`.

## What is westron's and what is the system's

Navigation motion belongs to the system: push and pop, sheets, popovers, menus, and Liquid Glass changing shape
(chapter 09). westron's motions cover what westron draws: the content layer, and a surface the platform leaves to the
app, such as a popover on the web. A system sheet keeps the system's motion, even though `motion.reveal` names sheets.

## Eight motions, named by what moves

| Token | What moves | Spring |
|---|---|---|
| `motion.fade` | A color or an opacity: a hover tint, a selection, a fade in or out | None |
| `motion.press` | A control answering a press: its tint, and its scale down to 98 % | No bounce |
| `motion.toggle` | A small thing changing place: a switch's thumb, a segmented selection | A light bounce |
| `motion.check` | A check popping into a done task | The one visible overshoot |
| `motion.move` | Something moving to a new place: a reordered row, a drop, a section folding | A light bounce |
| `motion.enter` | Something appearing: a popover, a menu, an inserted row | A light bounce |
| `motion.leave` | Something leaving: a deleted row, a closing popover | None |
| `motion.reveal` | A large surface appearing: a sheet, a side panel, an opened card | A light bounce |

- **A name says what kind of change it is.** A row and a card that move both take `motion.move`, so the same change
  looks the same in every component. An agent has eight names to choose from, and each says when it applies.
- **Feedback is quickest, a large surface slowest.** `press` answers at once and `toggle` takes a little longer.
  `check`, `move` and `enter` take long enough for the eye to follow, and `reveal` is the longest. A motion is never
  longer than it needs to be understood.
- **Leaving is quicker than arriving.** `leave` takes less time than `enter` and does not bounce. A person watches what
  arrives; what leaves only needs to be seen going.
- **Color does not bounce.** `fade` has no spring, because a tint or an opacity has no place to overshoot.

## Springs

- **A spring is a duration and a bounce.** A motion that moves something carries `dev.westron.spring`, because DTCG
  has no type for springs ([decisions/0010](../decisions/0010-token-structure-and-modes.md)). A platform with springs
  uses the spring. A platform without them uses the token's curve and duration.
- **Springs stay smooth under a person's hand.** A spring that is interrupted, by a second tap or by a drag that
  changes direction, continues from its current speed instead of starting over. Apple: "Springs are the only type of
  animation that maintains continuity both for static cases and cases with an initial velocity"
  ([WWDC23 10158](https://developer.apple.com/videos/play/wwdc2023/10158/)). SwiftUI uses springs as its default
  animation.
- **The bounce is light.** Most of westron's springs land with a short tail and no visible wobble. Apple describes a
  small bounce, "like around 15%", as one that "doesn't feel very bouncy yet, but the long tail feels a little more
  brisk" (WWDC23). `press` has no bounce at all, so a control answers without a wobble.
- **Only a check overshoots.** `motion.check` has the largest bounce, and a check is the one thing that visibly pops
  past its size and back. It marks that a task is done. Everything else settles calmly (chapter 01).
- **One spring for every platform.** SwiftUI takes `spring(duration:bounce:)`. libadwaita and Compose take stiffness
  `(2π / duration)²` and damping ratio `1 − bounce`. CSS samples the spring into `linear()` at build time. So all four
  overshoot by the same amount. The mapping is exact: it reproduces Apple's own worked example
  (`research_notes/space-shape-motion.md`, 4.7).
- **Where no spring can run, the curve does.** GTK CSS transitions do not take `linear()`, so there a spring motion
  uses its cubic curve and duration and does not overshoot. A contract records such a difference in its `platforms`
  block (chapter 09).

## Curves

The curves are primitives ([decisions/0010](../decisions/0010-token-structure-and-modes.md)). A component takes a
motion, never a curve.

- `easing.standard`: quick out, slow to settle. Something moving on screen, where the platform has no spring.
- `easing.enter`: decelerates to rest. Something arriving; `motion.enter` uses it.
- `easing.exit`: accelerates away. Something leaving, which the eye does not need to follow; `motion.leave` uses it.
- `easing.ease`: CSS's `ease`, and libadwaita's. Fades of color and opacity; `motion.fade` uses it.

No curve overshoots. Overshoot comes only from a spring's bounce, so it is the same on every platform. A hand-made
overshooting curve would differ on each (decisions/0013).

## Delays

- **A delay lets a person read first.** Every westron motion starts at once. A wait belongs to the component or the
  product that knows what must be read. In the pilot, a done row waits before it leaves, so that its check can be seen.
  The wait is the product's; the motions it uses are westron's (decisions/0013).
- **A motion that waits for no reason feels slow.** A wait needs something to read.

## Shapes belong to components

The tokens give timing: a duration, a curve and a spring. What moves, and how far, belongs to the component's
contract: a check's pop in scale, a card's entrance in fade and offset, a row's exit. The same timing can drive
different shapes, and a shape changes with its component, never with the motion tokens. One shape is fixed for every
control: a press scales it down to 98 %, which is part of direction B's character. A list's row is the exception:
it tints on a press and does not scale, since a full-width row shrinking would pull its edges off the column
(spec/components/list-row, decisions/0001, Q6).

## Reduce Motion

- **A spring loses its bounce.**
- **Travel becomes a fade** of at most 150 ms. Nothing slides.
- **Scale and depth changes are dropped.** A press keeps its tint and loses its scale.
- **Color fades stay.** A fade moves nothing, and it still shows what changed. The HIG suggests "replacing transitions
  in x-, y-, and z-axes with fades"
  ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)), and libadwaita
  1.9 does the same in its own widgets.
- **A pause that lets a person read stays.** A platform must keep the delay even when the motion has no length. The
  pilot found that a motion of no length dropped its wait too, and a done task vanished at the tap.
- **Off means instant.** When GNOME's `gtk-enable-animations` is false or Android's animator scale is 0, westron draws
  every change at once.
- **Each platform has its setting.** Reduce Motion on Apple, `prefers-reduced-motion` on the web,
  `gtk-interface-reduced-motion` on GNOME. Android has only the switch that removes animations
  (`research_notes/space-shape-motion.md`, 4.6).
- **Nothing loops and nothing moves on its own.** Nothing flashes more than three times a second (chapter 08).

## Open questions

1. **Reduce Motion in the tokens.** The rule lives in decisions/0013 until a component needs it per motion. Then each
   motion could carry `dev.westron.reducedMotion`: a fade, instant or kept, and whether its delay survives. Which
   component comes first, and does the list of keys in decisions/0010 grow with it?
2. **A token for a reading pause.** Today a wait is the product's. Should westron name one, so that every product
   gives a person the same time to read a change?
3. **Springs on GNOME.** Should every spring motion on GNOME run in code with `AdwSpringAnimation`, so that it
   overshoots like the other platforms? Or should style changes keep GTK CSS's curve and record the difference
   (phase 7)?
