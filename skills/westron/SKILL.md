---
name: westron
description: The westron design system's components, tokens, icons and rules. Use when writing or changing UI in a product that uses westron (it imports WestronUI or WestronTokens) - a screen, a view, a row, a sheet's content, layout, colors, spacing, text styles, icons or motion - and before building any control or style of the product's own.
---

# westron

westron is the design system this product's UI is built from. On Apple it is `import WestronUI` (SwiftUI) and
`WestronTokens` (plain values). This file holds the rules; `context/` holds the reference, generated from westron's
contracts, tokens and design language. Paths here are relative to this file.

## Reading the reference

1. Read `context/index.md` first, every time: one line per component, token page, the icons and each chapter.
2. Read the card of every component you use, `context/components/<id>.md`, and only those: how it is called, its
   options, states, slots, what accessibility needs from the caller, what not to do, and how Apple differs.
3. Lay out with the token pages, `context/tokens/*.md`; ask for glyphs by `context/icons.md`.
4. `context/swiftui.md` maps a card's concepts to SwiftUI; `context/design-language/` says why westron is as it is.
   Read a chapter when a card points to it or nothing else settles a case.

A call that neither a card nor a token page shows is not westron's API. The reference is the westron version it was
generated with; where the product's pinned WestronUI differs, the package's declarations win.

## Rules

1. **UI only from westron's components and tokens.** In order: a westron component where its card fits the job; a
   system control as it is; a view of the product's own, composed of westron's components and laid out in westron's
   tokens. A product's own row, header or card is such a composition (a `ListRow` with an `IconTile` and a count), not
   a new control drawn from scratch.
2. **No raw values.** No literal color, hex, font, font size, padding, spacing, frame size, corner radius, line
   width, opacity, shadow, duration, curve or spring in UI code. Use the token: `.foregroundStyle(.text.primary)`,
   `.textRole(.body.regular)`, `.padding(.space.card)`, `VStack(spacing: .space.withinGroup)`,
   `RoundedRectangle(cornerRadius: .radius.card, style: .continuous)`, `.opacity(.opacity.disabled)`,
   `.animation(.fade, value: x)`. `0` for no space is fine. Choose a token by its role ("Use for", "Avoid"), not by
   its value.
3. **A system control with westron's style before a custom view.** Write the system control and add westron's style:
   `Button { … } label: { Label("Move", icon: .tray) }.buttonStyle(.secondary)`, `Toggle(…).toggleStyle(.check)`,
   `TextField(…).textFieldStyle(.framed)`. No wrapper types; never redraw a control westron styles, and never restyle
   a westron component from outside (no `.font`, `.foregroundStyle`, `.background` or `.clipShape` on it to change
   what its style draws). What a card leaves to the product, such as a slot's content or a title's text role, is
   the product's.
4. **What the system presents stays the system's.** Navigation stacks and split views, navigation bars, toolbars and
   tab bars, sheets, popovers, alerts and confirmation dialogs, menus and context menus, swipe actions, pickers,
   `.searchable`, `ContentUnavailableView`, scrolling and the system's focus ring. Write them as SwiftUI gives them;
   westron styles what is inside: a sheet's rows are `ListRow`s, a menu's trigger is a westron `Button`, an empty
   state's image is an `IconTile`. No westron surface, shadow or glass on them: the bars take the system's own glass,
   and a control floating over content is `Button`'s `floating` (decisions/0015).
5. **Accessibility is part of the call.** Give each control the label its card requires, an icon-only button too; a
   check beside its own title takes `Toggle(isOn:accessibilityLabel:)`; an icon that means something takes `label:`;
   a heading takes `.accessibilityAddTraits(.isHeader)`. Never fix a height that text must grow out of: text follows
   Dynamic Type.
6. **Follow the card.** Its "Do not" list and its constraints hold: a forbidden combination of options is a bug even
   where it compiles. States the system lacks are westron's modifiers, `.selected(_:)`, `.loading(_:)`,
   `.dropTarget(_:)`; the rest are the system's, such as `.disabled(_:)`.

## When westron lacks something

When no component, option, token or icon does what the screen needs:

- Say so in your answer: what is missing, on which screen, and what you used instead.
- Do not invent a westron component, option, token or icon, and do not imitate one with raw values. Compose from
  what exists where the cards allow it; otherwise use the system control as it is, or leave that part unchanged.
- The gap goes to westron as an issue (https://github.com/maldrakar/westron/issues): the product and screen, what it
  needs and why. Draft the text; open the issue only when the person asks.
- Never edit `context/`: it is generated in westron's repository by `tools/westron generate`.

If westron's repository is at hand, `tools/westron lint raw-values <files or directories>` there finds raw values in
a product's Swift files.
