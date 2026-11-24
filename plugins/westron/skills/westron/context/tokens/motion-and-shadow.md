<!-- Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Motion and shadows

From westron's semantic tokens, `import WestronUI`. Each entry: the token's path, its Swift member as SwiftUI writes it
after a dot, and what it is for.

## Motion, `Animation`

A motion is a SwiftUI `Animation` static, named after its path without `motion.`:
`.animation(.fade, value: isSelected)`, `withAnimation(.move) { … }`. Never a duration, a curve or a spring of the
product's own. The design language: `../design-language/05-motion.md`.

- `motion.fade` → `.fade` (0.2 s): A change of color or opacity: a hover tint, a selection, a fade in or out. It has no
  spring and no bounce.
- `motion.press` → `.press` (0.15 s, a spring): A control answering a press: its tint, and its scale down to 98 %.
- `motion.toggle` → `.toggle` (0.25 s, a spring): A small thing changing place: a switch's thumb, a segmented control's
  selection, a checkbox.
- `motion.check` → `.check` (0.35 s, a spring): A check popping into a done task. The one motion with a visible
  overshoot.
- `motion.move` → `.move` (0.35 s, a spring): Something moving to a new place: a reordered row, a dropped item, a
  section folding or unfolding.
- `motion.enter` → `.enter` (0.35 s, a spring): Something appearing: a popover, a menu, an inserted row.
- `motion.leave` → `.leave` (0.2 s): Something leaving: a deleted row, a closing popover. Leaving is quicker than
  entering and does not bounce.
- `motion.reveal` → `.reveal` (0.5 s, a spring): A large surface appearing: a sheet, a side panel, an opened card.

## Shadows, `Westron.Shadow`

A shadow is a `Westron.Shadow`, named after its path without `shadow.`: `card.shadow(.raised)`. It follows the theme.
Never a `.shadow(color:radius:x:y:)` of the product's own.

- `shadow.raised` → `.raised`: A card or a panel raised off the canvas.
- `shadow.overlay` → `.overlay`: A popover, a menu or a floating button westron draws over the content.
- `shadow.dragged` → `.dragged`: Something a drag carries.
