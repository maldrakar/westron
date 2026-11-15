# 07. Icons

Date: 2026-11-15. Status: draft for the owner's approval (#8).

westron icons have names of their own and take their glyphs from each platform. This chapter says how icons are named,
mapped, drawn and sized. The decision behind it is [decisions/0011](../decisions/0011-icons-and-fonts.md).

## Names

- **A name says what the glyph draws**, not what it means on a screen: `tray`, `sun`, `chevron`, `magnifier`. One
  glyph serves several meanings: the pilot's `sun` is the Today list and the day on a task's pill. The meaning
  belongs to the words next to the icon or to its accessibility label (chapter 01). A name that describes the drawing
  also survives a change of icon set.
- **A released name is never renamed or removed.** Products store names. The pilot keeps a list's icon by its name in
  its database and syncs it between devices, so a renamed icon would be a migration in every product. The names are
  the pilot's own, kept as they are ([decisions/0011](../decisions/0011-icons-and-fonts.md)).
- **An unknown name draws the default glyph.** A name written by a newer version of a product, which this version does
  not know, never leaves a blank. The pilot draws `bullets` in that case.
- **The registry is a source.** The names and their Apple glyphs live in one westron file, `spec/icons/icons.yaml`. The Apple generator produces
  the icon enumeration and its SwiftUI adapter from it, so a name is spelled once.

## Glyphs on each platform

| Platform | Glyphs | When no glyph fits |
|---|---|---|
| Apple | SF Symbols that exist on iOS 17, macOS 14 and watchOS 10 | A custom symbol drawn from an SF Symbols template |
| Web, GNOME, Android | One open set, chosen with the first of these platforms (phase 6): Lucide (ISC), Phosphor (MIT), Tabler (MIT), or westron's own SVG masters on one grid | A glyph drawn in that set's style and on its grid |

- **SF Symbols stay on Apple.** They are licensed for Apple platforms only and are never exported as images or SVG for
  another platform ([decisions/0007](../decisions/0007-license.md)).
- **Every mapped symbol must exist.** A symbol name that does not exist draws nothing and says nothing. The pilot looked
  each of its symbols up in the system's availability list (`name_availability.plist`) for the minimum OS versions,
  and a test asks the system for each one. westron keeps both checks for its registry.
- **A custom symbol is the last resort.** It is drawn only when SF Symbols has no fitting glyph. Drawn from a template,
  it gets the weights, scales and text alignment of the system's symbols, so it does not stand out next to them.
- **Standard actions use standard glyphs.** The HIG asks apps to "use standard symbols to represent common actions"
  ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)). On Apple, these are SF
  Symbols already. Off Apple, phase 6 decides whether share, back and close come from the platform's own icons or
  from the chosen set.
- **The names do not change with the set.** Each platform maps the same names to its own glyphs.

## Drawing

- **One family per screen.** Icons on one screen come from one set in one style. A custom glyph matches the system's
  glyphs around it in stroke, corners and optical size.
- **Outline at rest.** The pilot's glyphs are outlines. A filled form marks a state, such as a selected tab, where the
  platform does that by itself.
- **One color.** An icon takes the color of the text it goes with, or the color its role gives it: a glyph on a list's
  tile takes `color.category.<name>.text`, and a grip takes `color.icon.tertiary` (chapter 02). Multicolor and palette
  rendering appear only where a contract asks for them.
- **Never the only signal.** An icon-only control has an accessibility label, and a status icon comes with a word or a
  value. A decorative icon next to its own label is hidden from screen readers (chapter 08).

## Size relative to text

An icon is sized by text, not by a number of its own. The numbers live in the text roles and in the size tokens (#11).

- **Next to text, an icon takes that text's role.** It gets the role's size and weight, so it sits on the line like a
  letter and scales with Dynamic Type together with the text. An SF Symbol does this when it takes the role's font; a
  custom symbol does it because it is drawn from a template.
- **Without text, an icon takes its control's text role.** The glyph of an icon-only button is sized as that button's
  label would be. So a glyph in a larger control is larger, and every glyph grows with the person's text size.
- **Inside a shape, an icon is sized by the shape.** A glyph on a tile or in a check keeps its proportion to the shape,
  and the shape scales with the text beside it.
- **A relative scale is the only size choice.** Where an icon must be smaller or larger than its text, it takes the
  platform's relative scale (small, medium, large), never a fixed size.
- **The hit target does not shrink with the glyph.** An icon-only control keeps the hit target of chapter 08 even when
  its glyph is smaller.

## Open questions

1. **Icons that scale with text.** The pilot draws its icons at fixed point sizes that stay the same at every text
   size. This chapter has them scale with text instead, which changes the pilot's look at large text sizes. Agree?
2. **Weight.** Should an icon follow the weight of its text, as proposed, or should all chrome glyphs share one weight?
3. **Default glyph.** Is the glyph for an unknown name a rule of the westron registry (proposal: `bullets`, as in the
   pilot), or each product's choice?
4. **License of custom glyphs.** westron's own glyphs, if any are drawn: MIT, with the tokens and the registry, or
   CC BY 4.0, with the design language?
