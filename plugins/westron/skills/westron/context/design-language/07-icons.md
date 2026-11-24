<!-- Generated from design-language/07-icons.md by `tools/westron generate`. Do not edit: change the source and generate
again (decisions/0016). -->
<!-- The design language is distributed under CC BY 4.0, https://creativecommons.org/licenses/by/4.0/ (westron's
design-language/LICENSE). Links to the rest of westron's repository are left as their text. -->

# 07. Icons

Date: 2026-11-15. Status: draft for the owner's approval (#8). It follows
decisions/0011, which the owner accepted on the direction specimens.

westron icons have names of their own. Behind a name is the platform's glyph for a standard action or a state, and
westron's own glyph for a thing from a product's domain. This chapter says how icons are named, where their glyphs come
from, how they are drawn and how they are sized. The names and their glyphs are in `spec/icons/icons.yaml`.

## Two sources

- **Standard actions and states take the platform's icons.** Add, delete, search, share, close and the statuses are
  SF Symbols on Apple, Adwaita icons on GNOME and Material Symbols on Android. People recognize them, and they follow
  the platform's weight and size. The HIG asks apps to "use standard symbols to represent common actions"
  ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
- **Domain icons are westron's own set.** They draw the things of a product's own domain. That is where a product's
  character shows, and no system set has them.
- **The domain set starts from Lucide, with Tabler for its gaps.** Lucide (ISC) has the most precise public design
  guide, accepts new icons and releases often. Tabler (MIT) draws on the same grid with the same stroke, so a glyph
  taken from it sits beside Lucide's. A Tabler glyph is checked against westron's rules before it joins the set
  (`research_notes/type-and-icons.md` 5.3). Their license notices stay with westron's set.
- **Remix Icon is out.** Since January 2026 its license forbids building a competing icon library on it.
- **On the web, westron's set covers standard actions too.** The web has no platform icon set, and Lucide already has
  the standard actions (research 5.2).
- **On GNOME, the Adwaita icons are copies.** The Adwaita icon theme is private to GNOME's core apps. An app copies the
  standard icons it needs from GNOME's Icon Library into its own resources (research 5.2).

## Names

- **A name says what the glyph draws**, not what it means on a screen: `tray`, `sun`, `chevron`, `magnifier`. One
  glyph serves several meanings: `sun` can be the Today list in a task app and the day on a task. The meaning belongs
  to the words next to the icon or to its accessibility label (chapter 01). A name that describes the drawing also
  survives a change of glyph.
- **A released name is never renamed or removed.** Products store names. The pilot keeps a list's icon by its name in
  its database and syncs it between devices, so a renamed icon would be a migration in every product. The pilot's 32
  names stay as they are, byte for byte.
- **An unknown name draws the default glyph.** A name written by a newer version of a product, which this version does
  not know, never leaves a blank. The registry's default is `bullets`.
- **The registry is a source.** `spec/icons/icons.yaml` lists every name, a line on what its glyph draws, and its
  glyph on each platform. `tools/westron icons check` validates it, and `tools/westron generate` writes the icon
  enumeration and its SwiftUI adapter from it. Nothing else spells a name. A new icon goes at the end.

## Status glyphs

A status always shows its glyph beside its word, never color alone (chapter 02). Four statuses have a glyph in the
registry, each a filled shape with its mark cut out:

| Status | Name | SF Symbol |
|---|---|---|
| success | `checkCircleFill` | `checkmark.circle.fill` |
| danger | `xmarkCircleFill` | `xmark.circle.fill` |
| warning | `exclamationTriangleFill` | `exclamationmark.triangle.fill` |
| info | `infoCircleFill` | `info.circle.fill` |

- **The shape tells them apart.** A circle with a check, a circle with an x, a triangle and a circle with an i differ
  without their color, so a person who cannot tell the hues apart still reads the status.
- **The glyph takes its status's color.** It draws in `color.status.<name>.icon`, or in `on-fill` on a solid fill.

## Glyphs on each platform

| Platform | Standard actions and states | Domain icons |
|---|---|---|
| Apple | SF Symbols that exist on iOS 17, macOS 14 and watchOS 10 | westron's glyph as a custom symbol |
| GNOME | Adwaita icons, copied into the app | westron's glyph as a symbolic icon |
| Android | Material Symbols | westron's glyph as a vector drawable |
| Web | westron's set | westron's glyph as an inline SVG |

- **Apple comes first.** Every name in the registry maps to an SF Symbol today. A domain icon from westron's set
  becomes a custom symbol. Converting the masters with SwiftDraw needs a spike first, with the first domain icon a
  product needs.
- **SF Symbols stay on Apple.** They are licensed for Apple platforms only and are never exported as images or SVG for
  another platform (decisions/0007).
- **Every mapped symbol must exist.** A symbol name that does not exist draws nothing and says nothing. A test asks the
  system for every symbol, and another looks each one up in the system's availability list (`name_availability.plist`)
  for iOS 17, macOS 14 and watchOS 10.
- **The platform phases map the names.** Phase 6 (web) maps them to westron's own set, phase 7 (GNOME) to Adwaita
  icons, phase 8 (Android) to Material Symbols. The first of them draws the domain icons on westron's grid. The
  formats in the table are the research's proposal (5.3); each platform settles its own.
- **The names do not change with the platform.** Each platform maps the same names to its own glyphs.

## Drawing

- **One grid for westron's set.** It is Lucide's: a 24 px canvas with 1 px of padding, a circle of 20 and a square of
  18 with a radius of 2 as keylines, a 2 px centered stroke, round caps and joins, a corner radius of 2, and at least
  2 px between elements (research 5.1, 5.3).
- **One source, every format.** Each domain icon has a master drawn with strokes on this grid, and every platform's
  glyph is generated from it. A weight is then a stroke width, not another drawing (research 5.3).
- **A domain glyph matches the system's.** It sits on the same screen as system glyphs, so it matches them in weight,
  size and alignment. On Apple its regular stroke is matched against SF Symbols' `circle`, as Apple suggests for
  custom symbols. A custom symbol is built from a variable template, so it gets the weights, scales and text alignment
  of the system's symbols.
- **Outline at rest.** A filled form marks a state: a selected tab, where the platform fills it by itself, and a
  status, whose glyph is filled.
- **One color.** An icon takes the color of the text it goes with, or the color its role gives it (chapter 02):
  - a status glyph takes `color.status.<name>.icon`;
  - a list's glyph or dot takes `color.category.<name>.icon`;
  - a chevron or a grip takes `color.icon.tertiary`;
  - a glyph on a solid fill takes the fill's `on-fill`.

  Multicolor and palette rendering appear only where a contract asks for them.
- **Never the only signal.** An icon-only control has an accessibility label, and a status icon comes with a word or a
  value. A decorative icon next to its own label is hidden from screen readers (chapter 08).

## Size relative to text

An icon is sized by text, not by a number of its own. Its size comes from a text role (chapter 03).

- **Next to text, an icon takes that text's role.** It gets the role's size and weight, so it sits on the line like a
  letter and scales with Dynamic Type together with the text. An SF Symbol does this when it takes the role's font; a
  custom symbol does it because it is built from a template. Chrome glyphs share no weight of their own: each follows
  the weight of its text (the Icon contract, #28, 2026-11-18). One named exception: a decorative glyph inside a text
  field stops growing at the largest text size that is not an accessibility size, since there the width is what the
  person types into (`spec/components/text-field/decisions/0003-icons-at-the-start-and-the-end.md`, #115).
- **Without text, an icon takes its control's text role.** The glyph of an icon-only button is sized as that button's
  label would be. So a glyph in a larger control is larger, and every glyph grows with the person's text size.
- **Inside a shape, an icon is sized by the shape.** A glyph in a check box or on a badge keeps its proportion to the
  shape, and the shape scales with the text beside it.
- **A relative scale is the only size choice.** Where an icon must be smaller or larger than its text, it takes the
  platform's relative scale (small, medium, large), never a fixed size.
- **The hit target does not shrink with the glyph.** An icon-only control keeps the hit target of chapter 08 even when
  its glyph is smaller.

## Open questions

The Icon contract (#28) answered question 4 on 2026-11-18: an icon takes its size and its weight from the text role
beside it ("Size relative to text"). The other questions keep their numbers.

1. **Which names are domain icons.** All 36 names map to SF Symbols on Apple. The pilot's list glyphs, such as
   `tray`, `logbook` or `briefcase`, are icons a person picks for a list. Do they take the platform's glyph wherever
   one exists, or westron's glyph on every platform, Apple included, so that a list's icon looks the same everywhere?
2. **The neutral status.** It covers queued, cancelled and skipped, and it has no glyph yet. Does it get one glyph, or
   one glyph for each state, and which?
3. **Smaller masters.** Lucide's 2 px stroke scaled to 16 px is 1.33 px, lighter than Adwaita's 2 px. The research
   proposes a 20 px master with a 1.5 px stroke for macOS sidebars and dense tables, and a 16 px master redrawn with
   a 2 px stroke for GNOME. Are they drawn with the first domain icon, or with the platform that needs them?
5. **License of westron's glyphs.** The masters derive from Lucide (ISC) and Tabler (MIT), whose notices stay. Do
   westron's own masters go under MIT, with the tokens and the registry, or CC BY 4.0, with the design language?
