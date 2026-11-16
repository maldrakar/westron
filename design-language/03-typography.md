# 03. Typography

Date: 2026-11-15. Status: draft for the owner's approval (#8). It follows
[decisions/0011](../decisions/0011-icons-and-fonts.md) and
[decisions/0013](../decisions/0013-typography-space-shape-motion.md), which the owner accepted by choosing direction B.

westron sets headings in its own face, Onest, body text and controls in the platform's font, and code in Geist Mono.
Every role follows a platform text style, so the platform and the person decide the size. This chapter says why. The
fonts are in decisions/0011, the roles in decisions/0013, and the values in `tokens/semantic/typography.tokens.json`
and `tokens/primitive/font.tokens.json`.

## Three faces

- **Headings are Onest.** `font.family.heading` is a friendly grotesque, between geometric and humanist, with full
  Cyrillic, which the owner's products need. Headings are where the brand shows in type, so they get a face of their
  own. The owner chose Onest on the direction specimens (decisions/0011).
- **Body text and controls are the system font.** `font.family.system` is SF Pro on Apple, Adwaita Sans on GNOME,
  Roboto on Android and `system-ui` on the web. It is drawn for legibility at small sizes and follows the person's
  settings, and a westron button or field reads like the platform's own. The HIG suggests this split: "use a custom
  font for headlines and subheadings while using system fonts for body copy and captions"
  ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
- **Code, logs and identifiers are Geist Mono.** `font.family.mono` has Cyrillic and box-drawing characters, which logs
  and text trees need. Its ligatures are off by default, so `->` and `!=` stay as typed in data. Its x-height matches
  Onest's, so the two faces sit well on one screen (`research_notes/type-and-icons.md`, 2.2 and 2.3).
- **westron ships its two fonts.** It ships static instances of the weights its roles use: Onest SemiBold and Bold,
  Geist Mono Regular and SemiBold, each with its license. On Apple they are registered the first time a role needs
  one, so a product sets up nothing (decisions/0011).
- **A missing font falls back to the system's.** Each family token names its fallback: `system-ui` after Onest,
  `ui-monospace` after Geist Mono. If registration fails on Apple, every role uses the system font. A test checks that
  every font a role names is registered and draws Cyrillic.

## Roles

Seventeen roles in three groups (decisions/0013). A text role is named by the text style it follows and by its weight,
so the name says which size to expect and how much emphasis. Headings are named by rank, because they carry the
brand's face; each still follows a text style. Code is named by its job. The table leaves out the `typography.`
prefix.

| Role | Face and weight | Text style | What it is for |
|---|---|---|---|
| `heading.large` | Onest Bold | `largeTitle` | The title of a screen |
| `heading.medium` | Onest Bold | `title3` | The title of a card, a section of a screen or an empty state |
| `heading.small` | Onest SemiBold | `headline` | The title of a block inside a card or a list |
| `heading.overline` | Onest SemiBold | `caption` | A short label in capitals above a group: a sidebar section |
| `body.regular` | System Regular | `body` | Main text: a row's title, a field's text, a paragraph |
| `body.strong` | System SemiBold | `body` | Main text with emphasis: the selected row, a row with children |
| `callout.regular` | System Regular | `callout` | One step below main text: a nested row's title, a card in a column |
| `callout.strong` | System SemiBold | `callout` | The same with emphasis |
| `subheadline.regular` | System Regular | `subheadline` | Supporting text: a subtitle, notes, a count |
| `subheadline.medium` | System Medium | `subheadline` | A row that adds something, such as "Add task" |
| `subheadline.strong` | System SemiBold | `subheadline` | The label of a button or of a bar item |
| `footnote.regular` | System Regular | `footnote` | Secondary detail: a hint, a cell in a dense table |
| `footnote.medium` | System Medium | `footnote` | A small label: a column header, a date, a tag's name |
| `footnote.strong` | System SemiBold | `footnote` | The words on a chip, a pill or a small button |
| `caption.medium` | System Medium | `caption` | Metadata and badges: a status badge, a line of metadata |
| `code.regular` | Geist Mono Regular | `subheadline` | Code, logs, identifiers and hashes |
| `code.strong` | Geist Mono SemiBold | `subheadline` | Emphasis inside code or a log: a keyword, a level |

- **A role is chosen by what the text is.** A component asks for a role, never for a size. A product that needs a size
  the roles do not have asks for a new role.
- **Density never changes a role.** A dense table picks a smaller role for its cells, such as `footnote.regular`, and
  body text keeps its size (chapter 06). So a person's text size holds in every density.

## Weight

- **Four weights, far apart.** `font.weight.regular`, `medium`, `semibold` and `bold`. Few weights, far enough apart,
  keep the hierarchy readable at a glance (chapter 00, principle 4).
- **Each weight has its jobs.** Bold is for the two large headings. SemiBold marks the small heading and the overline,
  emphasis in running text and in code, and the words on buttons, chips and pills. Medium marks small labels, metadata
  and rows that add something. Everything else is regular.
- **A new weight in Onest or Geist Mono costs a file.** westron ships only the instances its roles use, so such a
  weight means cutting a new one with the command in decisions/0011.

## Size follows the platform

- **On Apple, a role scales with Dynamic Type.** A text role becomes `Font.system(_:design:weight:)` with its text
  style. A heading or code role becomes `Font.custom(_:size:relativeTo:)` with its text style, so Onest and Geist Mono
  grow with the person's text size as the system font does (decisions/0013).
- **The token holds the size at the default text size on iOS.** Platforms without Apple's text styles take it as the
  base and scale it with their own setting: the text scale on GNOME, the font scale on Android, zoom and the default
  font size on the web (chapter 08).
- **The Mac's text styles are smaller and fixed.** "macOS doesn't support Dynamic Type"
  ([HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)). A text role takes the
  Mac's sizes from its text style by itself. A heading or code role asks the platform for its text style's size, so
  it takes the Mac's sizes too and keeps its proportion to the text around it. The watch has no API for that size,
  so there a heading takes the token's size, which is iOS's.
- **Off Apple, the split holds.** A heading role sets Onest, and body text stays in the platform's font. How the roles
  map to libadwaita's title classes and to Material's type roles is decided in those platforms' phases (chapter 09).

## Tracking and line height

- **Headings are tracked in by 1 % of their size.** Spacing that suits text looks loose at a heading's size, so
  headings are drawn a little tighter.
- **The overline is tracked out by 6 %.** Capitals at text spacing crowd each other. Spaced apart, a short label in
  capitals reads at a glance.
- **On Apple, `.textRole(_:)` applies the tracking.** A SwiftUI font cannot carry tracking, so a view sets a heading
  with `.textRole(.heading.large)`, which applies the font and the token's `letterSpacing` together (decisions/0013).
  `Font(.heading.large)` alone gives the face without the tracking.
- **On Apple, line height comes from the font.** The system font takes its leading from the text style; Onest and
  Geist Mono take theirs from their own metrics. Both follow Dynamic Type. The tokens carry the line heights of Apple's
  iOS text styles, so that the web and GNOME have numbers to start from.

## Capitals, numbers and fitting

- **The product writes capitals.** A label in capitals, such as a section's name over a group, is written in capitals
  in the string. The font and a text transform never make it so. Whether capitals are right depends on the language
  and the words, and the product knows both. `heading.overline` is the role for such labels.
- **Digits are proportional by default.** Geist Mono's digits are all one width by design. Columns of numbers in other
  roles may need tabular digits (open questions).
- **Text is never clipped.** Running text wraps. A one-line label, such as a list's title in a row, may truncate with
  an ellipsis, as long as its full text is reachable: the item opens, and a screen reader reads the whole string.
- **Contrast does not lean on size.** Every word meets the text target, whatever its size (chapter 02). The large-text
  kind exists, but no token uses it: a heading shares its color with smaller text, and a role that is large on one
  platform can be small on another.

## Open questions

1. **Tracking under Dynamic Type.** The tracking is a fixed number of points from the token. Should it grow with
   Dynamic Type, as the font does?
2. **Bold Text.** The HIG asks a custom font to honor Bold Text, and SwiftUI does not do that for one. Should a
   SemiBold heading turn Bold under the setting, and should westron ship a heavier Onest for the Bold headings?
3. **Tabular digits.** Should counts, times and numbers in tables use tabular digits, as a role, as an option of a
   role, or as a property of every role that shows numbers? Onest has them, and SwiftUI's `monospacedDigit()` gives
   them for the system font.
4. **The watch.** Onest headings on watchOS, or the system font for every role on the watch, as the research suggests
   (`research_notes/type-and-icons.md`, 3.1)?
