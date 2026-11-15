# 03. Typography

Date: 2026-11-15. Status: draft for the owner's approval (#8).

westron sets text in the platform's own font and lets the platform size it. The brand shows in the headings' weight
and, on Apple, in their rounded design. The decision behind this is
[decisions/0011](../decisions/0011-icons-and-fonts.md); the values are in `tokens/semantic/typography.tokens.json`.

## Faces

- **Body text is the system font everywhere**: SF Pro on Apple, Adwaita Sans on GNOME, Roboto on Android, `system-ui`
  on the web (`font.family.system`). The system font is drawn for legibility at small sizes, follows the person's
  settings, and costs nothing to license or ship. The HIG suggests "system fonts for body copy and captions"
  ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding)).
- **Headings are heavy and, on Apple, rounded.** `font.family.rounded` is the system's rounded design where the
  platform has one, and the system font elsewhere. Off Apple, the brand holds through weight and size alone. There is
  no free face close enough to SF Pro Rounded to be worth a dependency (decisions/0011).
- **westron ships no font files.**

## Roles

A role is named by the platform text style it follows and by its weight. The style gives the size, so the name says
which size to expect; the weight says how much emphasis. Headings are named by rank instead, because they carry the
brand rather than a system style's purpose.

| Role | What it is for |
|---|---|
| `typography.heading.large` | The title of a screen |
| `typography.heading.medium` | The title of an empty state or a short standalone message |
| `typography.heading.small` | The title of a section or a block inside a screen |
| `typography.heading.overline` | A short label above a group, in capitals the product writes, such as an area's name |
| `typography.body.regular` | Main text: a row's title, a field, a search field |
| `typography.body.strong` | Main text with emphasis: a row with children, the selected row, a card's title |
| `typography.callout.regular` | One step below main text: a nested row, a card in a column |
| `typography.callout.strong` | The same with emphasis |
| `typography.subheadline.regular` | Supporting text: counts, a subtitle, notes, a subtask |
| `typography.subheadline.medium` | A row that adds something, such as "Add task" |
| `typography.subheadline.strong` | A word on a bar, or on a button beside a glyph |
| `typography.footnote.regular` | A hint under a title that says what to do |
| `typography.footnote.medium` | A small label: an area's name, a date, a tag |
| `typography.footnote.strong` | The words on a chip or a pill |
| `typography.caption.medium` | A line of metadata under a title |

The pilot's seventeen roles fold into these fifteen: its search placeholder is main text, and its counts and notes are
the same supporting text.

## Size follows the platform

- **On Apple, the text style decides the size.** A role becomes `Font.system(_:design:weight:)` with its text style
  (decisions/0011). So text scales with Dynamic Type, and the Mac is smaller by itself, because its text styles are.
  The pilot works the same way.
- **The token still holds a size.** `fontSize` is the size at the default text size on iPhone. Platforms without
  Apple's text styles take it as the base and scale it with their own text-size setting (chapter 08).
- **No role has a fixed size.** A product that needs a size the roles do not have asks for a new role.

## Weight

Four weights are in use: regular, medium, semibold and heavy (`font.weight.*`). Heavy belongs to headings. Semibold
marks emphasis in running text and the words on chips, pills and bars. Medium marks small labels, metadata and rows
that add something. Bold appears in the pilot only on glyphs. Few weights, far enough apart, keep the hierarchy
readable at a glance (chapter 00, principle 4).

## Line height and tracking

- **On Apple, nothing is applied beyond the text style.** The style brings its own leading and tracking, and both
  follow Dynamic Type. The pilot applies none either.
- **The tokens carry line heights that match Apple's default leading, and zero tracking.** Other platforms use them so
  that text has the same rhythm there.
- **The canvas does more.** It tightens large titles a little and spaces capital labels apart. Neither reached the
  pilot's code. See the open questions.

## Capitals, numbers and fitting

- **The product writes capitals.** A label in capitals, such as an area's name over a group, is written in capitals
  in the string, not made so by the font or a text transform. Whether capitals are right depends on the language and
  the words, and the product knows both. `heading.overline` is the role for such labels.
- **Digits are proportional**, as in the pilot. Columns of numbers in technical content may need tabular digits
  (open questions).
- **Text is never clipped.** Running text wraps. A one-line label, such as a list's title in a row, may truncate with
  an ellipsis, as long as its full text is reachable: the item opens, and a screen reader reads the whole string.
- **Contrast does not lean on size.** The color tokens hold every word to the text target. The large-text kind exists
  (chapter 02), but no word uses it yet: `heading.small` is heavy and still small, and `heading.medium` is large on the
  iPhone but not on the Mac.

## Open questions

1. **Tracking and line height from the canvas.** Apply the canvas's tighter large titles and spaced capital labels on
   Apple too, or keep the system's own, as the pilot does?
2. **Sizes that differ from the canvas.** The large title and the metadata line follow their text styles rather than
   the canvas, by the owner's choice on the pilot's #151. The pill follows its style too, a half point under the canvas,
   with no recorded choice. Keep all three as the text styles give them?
3. **A monospaced role.** Technical content (code, logs, identifiers) needs one, in the system's monospaced face (SF
   Mono, Adwaita Mono). Add it with the dense components (#33)?
4. **Tabular digits.** Should counts and numbers in tables use tabular digits, as a role or as an option of a role?
5. **The Mac's sizes.** The Mac's text styles make every role smaller than the Mac boards of the canvas. Accept the
   system's sizes, or record Mac values in the `platform` modifier?
