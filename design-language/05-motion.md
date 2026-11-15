# 05. Motion

Date: 2026-11-15. Status: draft for the owner's approval (#8).

Motion explains a change and then gets out of the way (chapter 00, principle 3). Every westron motion answers "what
changed, and where did it go?". The values are in `tokens/primitive/easing.tokens.json` and
`tokens/semantic/motion.tokens.json`.

## What is westron's and what is the system's

Navigation motion belongs to the system: push and pop, sheets, popovers, menus, and Liquid Glass changing shape
(chapter 09). westron's motion tokens cover only what westron draws in the content layer. The pilot had its own push,
pop and quick-entry motions and never used them, because the system drew those transitions; westron has no tokens for
them.

## What each motion is for

**Feedback to what a person did.** Quick, so that the interface feels like it answered at once.

- `motion.check`: a check pops as a task is done. `check-fill` changes its ring and fill; `check-mark` draws the mark
  after the colors start; `title-fade` dims the task's title.
- `motion.chip-toggle`: a chip lights and goes out.
- `motion.hover-tint` and `hover-shadow`: a control's tint, or a card's deeper shadow, under the pointer.
- `motion.drop-highlight`: a drop target tints under a drag, and the dragged item dims.

**Something moves to a new place.** Long enough for the eye to follow it.

- `motion.card-open`: a card opens in place of its row.
- `motion.swipe`: a row slides aside for its actions, and back.
- `motion.drop`: something lands where it was dropped.
- `motion.popover`: a small element appears or moves into place: a row, a chevron, a dragged item.
- `motion.row-leave`: a done row leaves, after a wait long enough to read its check. `row-delete`: a deleted row leaves
  at once; there is nothing to read.

**A state that changes over time.**

- `motion.fold`: a chevron turns as a section folds or opens.
- `motion.highlight-fade`: the tint under something just moved fades out, slowly enough to show where it landed.

## Duration and delay

- **The shortest motions answer a touch**, the middle ones carry something across the screen, and the longest is a
  fade that marks a place. A motion is never longer than it needs to be understood.
- **A delay means "read this first".** Only two motions wait: a done row, so that its check can be seen, and a check's
  mark, which follows its colors. A motion that waits for no reason feels slow.

## Curves

- `easing.standard`: small fades of color and turns of a chevron. It is CSS's `ease`.
- `easing.settle`: quick, then slow. A card, a row or a screen settles into place, the way a person puts something
  down.
- `easing.accelerate`: something leaving the screen. It speeds up as it goes, since the eye does not need to follow it.
- `easing.overshoot` and `overshoot-soft`: a pop or a landing that passes its mark a little and settles back.

## Springs

- **Three motions are also springs**: `check`, `popover` and `drop` carry `dev.westron.spring`, a duration and a
  bounce, because DTCG has no type for springs ([decisions/0010](../decisions/0010-token-structure-and-modes.md)). A
  platform with springs uses the spring; a platform without them, such as CSS, uses the token's cubic curve.
- **Why springs on Apple.** SwiftUI builds its animation on springs. A spring that is interrupted, by a second tap or a
  drag that changes direction, continues from its current speed instead of starting over, so the motion stays smooth
  under a person's hand.
- **The two forms do not match yet.** The pilot renders its springs with no bounce, so on Apple a drop and a popover
  do not overshoot. The canvas's curves do overshoot, and the token's curve keeps the canvas's shape. The pilot
  rebuilds the check's pop and the Done strip's bump with keyframes, so those two overshoot on Apple too. See the open
  questions: a difference between platforms that is not recorded is a bug.

## Shapes belong to components

The tokens give timing: a duration, a delay and a curve or a spring. What moves, and how far, belongs to the
component's contract: a check's pop in scale, a card's entrance in fade, scale and offset, a done row's fade and sink.
The same timing can drive different shapes, and a shape changes with its component, not with the motion scale.

## Reduce Motion

- **The view draws the change at once.** Nothing slides, scales, turns or bounces; the new state appears. The pilot
  does this in every view that animates.
- **A wait that lets a person read stays.** A done row still waits before it leaves, and then leaves without moving.
  A platform must keep the delay even when the duration is zero: the pilot found that a motion of no length dropped
  the wait as well, and the task vanished at the tap.
- **On other platforms** the same rule follows the platform's setting: `prefers-reduced-motion` on the web, the reduced
  motion setting on GNOME and on Android (chapter 08).

## Open questions

1. **Overshoot or not.** Should springs bounce on Apple, so that drops and popovers overshoot as on the canvas, or
   should the curves lose their overshoot, so that every platform looks like the pilot? Today the tokens give the web an
   overshoot that Apple does not have.
2. **Fades under Reduce Motion.** The HIG suggests "replacing transitions … with fades". The pilot also drops color
   fades and the highlight under a row that just landed. Keep the fades, or draw everything at once, as the pilot does?
3. **Canvas motions left out.** The canvas lifts a dragged card with an overshoot and lets it bob while held. The pilot
   left out both, and the bob loops, which chapter 01 rules out. Drop them for good?
