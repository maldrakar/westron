<!-- Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Space, size, radius, stroke and opacity

From westron's semantic tokens, `import WestronUI`. Each entry: the token's path, its Swift member as SwiftUI writes it
after a dot, and what it is for.

A length is a `CGFloat` static in points, named after its path: `space.card` is `.space.card`, the step `space.200` is
`.space200`: `.padding(.space.card)`, `.padding(.horizontal, .space.page.narrow)`,
`VStack(spacing: .space.withinGroup)`, `RoundedRectangle(cornerRadius: .radius.card, style: .continuous)`,
`.frame(minHeight: .size.target.minimum)`, `lineWidth: .stroke.thin`. A role name (`space.card`, `space.within-group`,
`space.between-groups`, `space.page.narrow`, `radius.card`) comes before a step of the ladder, which is for a gap no
role names. A value that differs by platform is the current platform's, chosen when the product builds. Never a number
of the product's own for a padding, a gap, a radius, a line or a size. The design language:
`../design-language/06-layout.md`, `../design-language/04-shape.md`.

## `radius`

- `radius.25` → `.radius25` (2 pt): Step 25 of the radius ladder: 2 px.
- `radius.50` → `.radius50` (4 pt): Step 50 of the radius ladder: 4 px.
- `radius.75` → `.radius75` (6 pt): Step 75 of the radius ladder: 6 px.
- `radius.100` → `.radius100` (8 pt): Step 100 of the radius ladder: 8 px.
- `radius.150` → `.radius150` (12 pt): Step 150 of the radius ladder: 12 px.
- `radius.200` → `.radius200` (16 pt): Step 200 of the radius ladder: 16 px.
- `radius.300` → `.radius300` (24 pt): Step 300 of the radius ladder: 24 px.
- `radius.400` → `.radius400` (32 pt): Step 400 of the radius ladder: 32 px.
- `radius.control` → `.radius.control` (8 pt): A control westron draws with corners: a segmented control, the focus ring
  around an inline text field. 8 px, a quarter of a 32 px control. A button and a one-line framed text field are
  capsules; a multiline framed text field takes radius.150 (decisions/0013, revision of 2026-11-20).
- `radius.row` → `.radius.row` (8 pt): The highlight of a row under the pointer or selected.
- `radius.card` → `.radius.card` (12 pt): A card or a panel on the canvas.
- `radius.overlay` → `.radius.overlay` (12 pt): A popover or a menu westron draws; system ones keep their own.
- `radius.sheet` → `.radius.sheet` (16 pt): A sheet or a dialog westron draws.

## `space`

- `space.25` → `.space25` (2 pt): Step 25 of the space ladder: 2 px.
- `space.50` → `.space50` (4 pt): Step 50 of the space ladder: 4 px.
- `space.75` → `.space75` (6 pt): Step 75 of the space ladder: 6 px.
- `space.100` → `.space100` (8 pt): Step 100 of the space ladder: 8 px.
- `space.125` → `.space125` (10 pt): Step 125 of the space ladder: 10 px.
- `space.150` → `.space150` (12 pt): Step 150 of the space ladder: 12 px.
- `space.200` → `.space200` (16 pt): Step 200 of the space ladder: 16 px.
- `space.250` → `.space250` (20 pt): Step 250 of the space ladder: 20 px.
- `space.300` → `.space300` (24 pt): Step 300 of the space ladder: 24 px.
- `space.400` → `.space400` (32 pt): Step 400 of the space ladder: 32 px.
- `space.500` → `.space500` (40 pt): Step 500 of the space ladder: 40 px.
- `space.600` → `.space600` (48 pt): Step 600 of the space ladder: 48 px.
- `space.800` → `.space800` (64 pt): Step 800 of the space ladder: 64 px.
- `space.card` → `.space.card` (16 pt): A card's padding: the inset between a card's or a panel's edge and its content.
  16 px in the comfortable density. Use for: card padding, panel padding, inset of a grouped block the product draws.
  Avoid: A system List, Form or bar, which keeps its own insets. A gap between elements: use space.within-group or
  space.between-groups.
- `space.within-group` → `.space.withinGroup` (12 pt): The gap between the elements of one group: the fields of a form
  section, the cards of a column, the lines of a block. 12 px in the comfortable density, half the gap between groups,
  so the grouping shows through space. Use for: stack spacing inside a group, gap between cards in a column, gap between
  a heading and its content. Avoid: The gap between two groups: use space.between-groups. A component's own internal
  gap, which its contract gives.
- `space.between-groups` → `.space.betweenGroups` (24 pt): The gap between two groups or sections of a screen. 24 px,
  twice the gap within a group; a density keeps it. Use for: stack spacing between sections, gap between groups of a
  form, gap between blocks of a page. Avoid: The gap inside a group: use space.within-group. A separator line where the
  space already shows the grouping.
- `space.page.narrow` → `.space.page.narrow` (20 pt): The page margin on a narrow window: on Apple, the horizontal size
  class compact. 20 px; a density keeps it. It applies to layout the product builds itself, such as a ScrollView or a
  stack; the system's List, Form and bars keep their own insets. Use for: horizontal margin of a scrolling page on a
  phone, margin of a stack laid out by the product. Avoid: A system List, Form or bar, which keeps its own insets. A
  wide window: use space.page.wide.
- `space.page.wide` → `.space.page.wide` (32 pt): The page margin on a wide window: on Apple, the horizontal size class
  regular, and always on a Mac. 32 px; a density keeps it. It applies to layout the product builds itself, such as a
  ScrollView or a stack; the system's List, Form and bars keep their own insets. Use for: horizontal margin of a page on
  an iPad or a Mac, margin of a stack laid out by the product. Avoid: A system List, Form or bar, which keeps its own
  insets. A narrow window: use space.page.narrow.

## `stroke`

- `stroke.hairline` → `.stroke.hairline` (0.5 pt): The edge of a card on a fill. Glass is the system's and takes no edge
  of westron's (decisions/0015).
- `stroke.thin` → `.stroke.thin` (1 pt): Rules, dividers, tree guides in a sidebar.
- `stroke.regular` → `.stroke.regular` (1.5 pt): Guides on a phone, a dashed outline, a small check's ring.
- `stroke.thick` → `.stroke.thick` (2 pt): A focus ring, a drop indicator, a selection ring.

## `size`

- `size.control.s` → `.size.control.s` (iOS 28 pt, macOS 24 pt, watchOS 32 pt): The height of a control at size s: 24 on
  macOS, 28 on iOS and iPadOS, 32 on watchOS. It is below the recommended target on every platform, so its hit area
  stays size.target.minimum, except where a contract records otherwise (chapter 08). Use for: small button, small field,
  control in a toolbar or a table row. Avoid: The default size: use size.control.m. A row's height: rows have heights of
  their own.
- `size.control.m` → `.size.control.m` (iOS 36 pt, macOS 32 pt, watchOS 44 pt): The height of a control at the default
  size m: a button, a field, a segmented control. 32 on macOS, westron's control (decisions/0013); 36 on iOS and iPadOS,
  beside the system's own 34 (decisions/0013, revision of 2026-11-20); 44 on watchOS. A hit area takes
  size.target.minimum, not this height. Use for: button, field, segmented control. Avoid: A row's height: rows have
  heights of their own. A fixed height where text can grow: the height is a minimum. A hit area: use
  size.target.minimum.
- `size.control.l` → `.size.control.l` (iOS 50 pt, macOS 40 pt, watchOS 52 pt): The height of a control at size l: the
  one prominent action of a form, a sheet or an empty state. 40 on macOS, 50 on iOS and iPadOS, 52 on watchOS. Use for:
  prominent button, call to action. Avoid: Every control on a screen: the large size marks the one action that leads.
- `size.target.minimum` → `.size.target.minimum` (iOS 44 pt, macOS 28 pt, watchOS 44 pt): The least side of the area
  that takes a touch or a click on a control, whatever the control draws: 44 on iOS, iPadOS and watchOS, the recommended
  touch target; 28 on macOS, the recommended target for a pointer (chapter 08). A contract may record a control whose
  hit area is smaller, as Button's size s on macOS. Use for: hit area of a control, hit area of a check. Avoid: A drawn
  size: use size.control.*. A row's height: rows have heights of their own.

## Numbers, `Double`

`Double` statics: `.opacity(.opacity.disabled)`.

- `opacity.disabled` → `.opacity.disabled` (0.4): A disabled control, drawn whole at this opacity: its fill, border,
  label and icon together, so it keeps its shape and its variant but reads as unavailable. It sits between Apple's
  disabled labels (iOS's tertiary label is 30 %) and libadwaita's --disabled-opacity (50 %, 40 % in high contrast). WCAG
  exempts an inactive control from contrast (chapter 08). Use for: disabled button, disabled field, disabled toggle,
  disabled row. Avoid: Colors of its own for the disabled state, or dimming the parts one by one; and something that is
  only secondary, which takes text.secondary and stays readable. A system control that the platform disables keeps the
  platform's look.
