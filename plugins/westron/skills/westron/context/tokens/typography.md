<!-- Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Text roles

From westron's semantic tokens, `import WestronUI`. Each entry: the token's path, its Swift member as SwiftUI writes it
after a dot, and what it is for.

A text role is a `Westron.TextRole`, named after its path without `typography.`: `typography.body.regular` is
`.body.regular`. It sets a text's font and its tracking: `.textRole(.heading.medium)` on any view, and on a part of a
text inside interpolation, `Text("\(title) \(Text(count).textRole(.footnote.medium))")`. `Font(.body.regular)` is its
font alone, without the tracking. Each role follows Dynamic Type through its text style, named in its entry with the
font it draws. A role is chosen by what the text is, never by its size; no `.font(.system(size:))` and no font of the
product's own. A heading role does not make a heading for assistive technology: add `.accessibilityAddTraits(.isHeader)`
where the screen has one. The design language: `../design-language/03-typography.md`.

## `typography.heading`

- `typography.heading.large` → `.heading.large` (largeTitle, Onest-Bold): The title of a screen. Onest Bold at the size
  of the largeTitle text style, tracked in by 1 % of its size.
- `typography.heading.medium` → `.heading.medium` (title3, Onest-Bold): The title of a card, a section of a screen or an
  empty state. Onest Bold at the size of the title3 text style.
- `typography.heading.small` → `.heading.small` (headline, Onest-SemiBold): The title of a block inside a card or a
  list. Onest SemiBold at the size of the headline text style.
- `typography.heading.overline` → `.heading.overline` (caption, Onest-SemiBold): A short label above a group, written in
  capitals by the product, such as a sidebar section. Onest SemiBold at the size of the caption text style, tracked out
  by 6 % of its size.

## `typography.body`

- `typography.body.regular` → `.body.regular` (body, the system font): Main text: a row's title, a field's text, a
  paragraph. The size follows the body text style.
- `typography.body.strong` → `.body.strong` (body, the system font): Main text that needs emphasis: the selected row, a
  row with children. The size follows the body text style.

## `typography.callout`

- `typography.callout.regular` → `.callout.regular` (callout, the system font): Text one step below the main text: a
  nested row's title, a card in a column. The size follows the callout text style.
- `typography.callout.strong` → `.callout.strong` (callout, the system font): `callout.regular` with emphasis. The size
  follows the callout text style.

## `typography.subheadline`

- `typography.subheadline.regular` → `.subheadline.regular` (subheadline, the system font): Supporting text: a subtitle,
  notes, a count. The size follows the subheadline text style.
- `typography.subheadline.medium` → `.subheadline.medium` (subheadline, the system font): A row that adds something,
  such as "Add task". The size follows the subheadline text style.
- `typography.subheadline.strong` → `.subheadline.strong` (subheadline, the system font): The label of a button or of a
  bar item. The size follows the subheadline text style.

## `typography.footnote`

- `typography.footnote.regular` → `.footnote.regular` (footnote, the system font): Secondary detail: a hint, a cell in a
  dense table, a line under a title. The size follows the footnote text style.
- `typography.footnote.medium` → `.footnote.medium` (footnote, the system font): A small label: a column header, a date,
  a tag's name. The size follows the footnote text style.
- `typography.footnote.strong` → `.footnote.strong` (footnote, the system font): The words on a chip, a pill or a small
  button. The size follows the footnote text style.

## `typography.caption`

- `typography.caption.medium` → `.caption.medium` (caption, the system font): Metadata and badges: a status badge, a
  line of metadata under a title. The size follows the caption text style.

## `typography.code`

- `typography.code.regular` → `.code.regular` (subheadline, GeistMono-Regular): Code, logs, identifiers and hashes:
  Geist Mono at the size of the subheadline text style, a step below body text.
- `typography.code.strong` → `.code.strong` (subheadline, GeistMono-SemiBold): Emphasis inside code or a log: a keyword,
  a level. Geist Mono SemiBold at the size of the subheadline text style.
