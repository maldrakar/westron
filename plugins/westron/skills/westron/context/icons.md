<!-- Generated from spec/icons/icons.yaml by `tools/westron generate`. Do not edit: change the source and generate again
(decisions/0016). -->

# Icons

westron's icon names: a `Westron.Icon`, `import WestronUI`. A name says what the glyph draws, not what it means on a
screen. A product asks for a glyph by its name, never by an SF Symbol's name:

- `Icon(.tray)`: Icon, decorative, hidden from assistive technology (`components/icon.md`).
- `Icon(.tray, label: "…")`: Icon, a glyph that says something, its `label` the name assistive technology reads
  (`components/icon.md`).
- `IconTile(.tray)`: IconTile, decorative, hidden from assistive technology (`components/icon-tile.md`).
- `IconTile(.tray, label: "…")`: IconTile, a glyph that says something, its `label` the name assistive technology reads
  (`components/icon-tile.md`).
- `.textFieldStyle(.framed, leadingIcon: .tray)`: TextField's `leadingIcon` (`components/text-field.md`).
- `.textFieldStyle(.framed, trailingIcon: .tray)`: TextField's `trailingIcon` (`components/text-field.md`).
- `Label("…", icon: .tray)`: the title and the icon of a control's label, such as a button's.
- `Image(.tray)`: only where nothing but an `Image` fits, as inside `Text` interpolation; it keeps the symbol's spoken
  name, so such a text takes an `.accessibilityLabel`.
- `Westron.Icon(rawValue: name) ?? .fallback`: a name a product stored; a name this version does not know draws
  `.bullets`. `icon.systemName` is the SF Symbol's name, for a system call that takes `systemImage:`.

When no name draws what a screen needs, westron lacks the glyph: say so, and do not draw an SF Symbol or an image of the
product's own in its place. The design language: `design-language/07-icons.md`.

| Name | What it draws | SF Symbol |
|---|---|---|
| `.tray` | An open tray, as for incoming mail. | `tray` |
| `.sun` | The sun with its rays. | `sun.max` |
| `.calendar` | A calendar page. | `calendar` |
| `.week` | A calendar page with a clock badge. | `calendar.badge.clock` |
| `.logbook` | A closed book with lines of text on its cover. | `text.book.closed` |
| `.trash` | A trash can. | `trash` |
| `.briefcase` | A briefcase. | `briefcase` |
| `.house` | A house. | `house` |
| `.hourglass` | An hourglass. | `hourglass` |
| `.pen` | A pencil. | `pencil` |
| `.bag` | A shopping bag. | `bag` |
| `.wrench` | A wrench. | `wrench` |
| `.book` | An open book. | `book` |
| `.folder` | A folder. | `folder` |
| `.list` | Lines of text, each after a round check box, the first one checked. | `checklist` |
| `.bullets` | Lines of text, each after a dot. | `list.bullet` |
| `.ellipsis` | Three dots in a row. | `ellipsis` |
| `.plus` | A plus sign. | `plus` |
| `.check` | A check mark. | `checkmark` |
| `.chevron` | A chevron pointing down. | `chevron.down` |
| `.grip` | Three horizontal lines, one above another. | `line.3.horizontal` |
| `.magnifier` | A magnifying glass. | `magnifyingglass` |
| `.microphone` | A microphone. | `mic` |
| `.newWindow` | A window with a plus badge. | `macwindow.badge.plus` |
| `.checkCircle` | A check mark in a circle. | `checkmark.circle` |
| `.divider` | A rectangle split by a horizontal line into a top and a bottom half. | `rectangle.split.1x2` |
| `.flag` | A flag on a pole. | `flag` |
| `.hash` | A number sign. | `number` |
| `.note` | A note card with lines of text. | `note.text` |
| `.expand` | Two diagonal arrows pointing away from each other. | `arrow.up.left.and.arrow.down.right` |
| `.columns` | A rectangle split into three columns. | `rectangle.split.3x1` |
| `.chevronLeft` | A chevron pointing left. | `chevron.left` |
| `.checkCircleFill` | A check mark cut out of a filled circle. | `checkmark.circle.fill` |
| `.xmarkCircleFill` | An x cut out of a filled circle. | `xmark.circle.fill` |
| `.exclamationTriangleFill` | An exclamation mark cut out of a filled triangle. | `exclamationmark.triangle.fill` |
| `.infoCircleFill` | A lowercase i cut out of a filled circle. | `info.circle.fill` |
