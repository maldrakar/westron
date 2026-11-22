# 0003. Icons at the start and the end

Date: 2026-11-22. Status: proposed (#115), for the first gate. In phase 4 the owner delegates the approval of a
contract to the coordinating agent (decisions/0014, "Process"). Until it is approved, the contract
`text-field.spec.yaml` is unchanged and stays approved as it was: the proposed revision is the YAML at the end of this
record (below, "How the revision is held"). There was no one to interview: the agent answered the questions of the
`new-component` interview from the sources, and names the source of each answer; every answer it had to guess is an
open question for the approver, with a recommendation (below, "Open questions").

## Context

decisions/0014 keeps westron's core small: a search field is not a component of its own, it is westron's TextField,
framed, with a glyph at its start, and one at its end where the product has one (the owner, 2026-11-22; #115). The
contract has no place for a glyph: its slots are the label and the placeholder, and on Apple the style draws the
system field alone.

### What the pilot draws and does

Read in todo-app at commit `0162887`, as decisions/0014 read it:

- **It is not a field yet, and not `.searchable`.** The search capsule is a drawn view: a magnifier, the word "Search"
  as a `Text`, and a glyph at the end, on the bar's glass (`Apps/Apple/Sources/TodoAppleUI/DesignSystem/Bar.swift`,
  `searchField(_:)`, "a view and not a control, since its model holds no action"). The model holds no action
  (`Sources/DesignSystemComponents/SearchFieldModel.swift`). No file of the app calls `.searchable`. The spec makes
  search a non-goal of the screen: "The capsule is drawn and a tap on it opens nothing until the search epic (owner)"
  (`docs/specs/lists-screen.md`, "Goals and non-goals"); on the Mac "the search field, inert as the capsule" (the same
  spec, the Mac's section).
- **The glyph at the end is decoration.** On the phone it is the microphone, 17 pt in the secondary ink in a 36 pt
  cell, and nothing answers a press on it (`Sources/Features/TaskViewList/TaskViewList+Components.swift`,
  `Metrics.phone.searchTrailingGlyph`). On the iPad's sidebar the capsule ends in no glyph, so that "Search" reads
  whole in the 280 pt column (`Metrics.sidebar`, the controller's ruling on #149). The Mac's field at the bottom of the
  sidebar has no glyph at its end either, and no ⌘F hint (`filledSearchField`).
- **Its numbers**, which are the pilot's look and not westron's (decisions/0006): on the phone a capsule 48 high on the
  bar's glass, the magnifier 17 pt 15 in from the start, 8 before the word, 6 from the end to the microphone's cell;
  on the Mac a field 30 high with corners of 8 on the fill color, the magnifier 15 pt 9 in, 6 before the word. Both
  glyphs are in the same secondary ink as the placeholder.

So the pilot needs: a leading glyph and an optional trailing one, both decoration, on a single-line field, at one size
per platform. It does not need a glyph that acts, a multiline search field, or an inline field with a glyph.

## The interview, answered from the sources

| Question | Answer | Source |
|---|---|---|
| Purpose, where it sits | The search capsule in the bottom bar of the Lists screen (iPhone), the search field at the bottom of the sidebar (Mac, iPad) | lists-screen.md; `TaskViewList+Components.swift` |
| System control | `TextField`, which westron already styles; `.searchable` is the system's search, placed by the system (point 3) | decisions/0003; the contract |
| Options | A glyph at the start, a glyph at the end, each optional | the pilot's model; #115 |
| States | Unchanged: focus, disabled; the glyphs have none of their own | the contract; the pilot's glyphs have no states |
| Slots | Label and placeholder unchanged; the glyphs are names of the icon registry (point 2) | `spec/icons/icons.yaml` has `magnifier` and `microphone` |
| Constraints | None the pilot needs; none can be written yet (point 5) | `spec/components/README.md` |
| Accessibility | The glyphs hidden; the label required; a search field announced as one (point 8) | Icon's contract; chapter 08 |
| Platform differences | watchOS draws no glyph; web needs an element around the input; GTK and Compose have icon slots of their own (point 10) | the platforms' APIs |

## The points, with the options considered

### 1. How a glyph reaches the style on Apple

A `TextFieldStyle` is given the field alone, `_body(configuration:)`, and the field's label is its title: its
accessible name where the platform takes it, and inside a macOS `Form` a visible title. So:

- (a) **Arguments of the generated overload**: `.textFieldStyle(.framed, leadingIcon: .magnifier, trailingIcon:
  .microphone)`, each `Westron.Icon?` with `nil` as its default. The style is initialized with them, as Button's style
  is with `iconOnly`. One call says the whole look of the field; the parity lint can derive it from the contract; no
  new kind of modifier.
- (b) **westron modifiers that set the environment**, `.leadingIcon(.magnifier)` or `.textFieldIcons(leading:trailing:)`
  on the field, which the style reads. A second modifier to remember, a new kind of API that the conventions give
  only to states and to the context (`.loading(_:)`, `.category(_:)`), and a reviewed adapter for the parity lint
  instead of an API derived from the contract. It cascades over a container as (a) does, so it buys nothing there.
- (c) **The field's label**, `TextField(text:prompt:label:)` with `Label("Search", icon: .magnifier)`, as Button
  carries its icon. The style cannot read the parts of the label (no public API; reflection, as for the axis, would
  have to find a view, not a name), the label is the field's title on macOS, and it would put the glyph into the
  accessible name.
- (d) **The product composes**: an `HStack` of an `Icon` and the field. The glyph then stands outside the field's fill,
  focus ring and hit area: it cannot draw a search field, which is why #115 exists.

**Proposed: (a).** It is what decisions/0003 gives a style ("an overload … that takes the generated enums"), with the
values the icon generator already writes.

### 2. What the glyphs are in the contract

- (a) **Options whose values are icons**, `leadingIcon` and `trailingIcon`, `type: icons`, each with a new
  `optional: true`: a use may leave it out, and then there is no glyph. Icon's `glyph` set the precedent: a glyph
  chosen by name is an option of type `icons`, its values the registry's names, which the contract does not repeat.
  GTK's `GtkEntry` names its icons the same way (`primary-icon-name`), and Compose takes them as slots
  (`leadingIcon`, `trailingIcon`), whose names these follow.
- (b) **Slots**, `slots: [label, placeholder, leadingIcon, trailingIcon]`. A slot of a style is the control's own label
  in the conventions ("Slots"), which (1c) rules out, and a slot names no kind of content, so the generator could not
  tell an icon from a view without a new schema concept.

**Proposed: (a).** The schema has no optional icons option today (an icons option "has no default: every use names its
glyph"), so the tools need `optional` (below, "What the tools need"). No value `none` stands for the absence: Swift
cannot use `none` as a case, and it would be a registry name.

### 3. The search case, and decisions/0003

decisions/0003 binds a contract to the system control where one exists. The system's search is `.searchable`: a
modifier on a navigation container that puts the system's search field where the system places it (the navigation
bar's drawer on iOS 17 to 25, the toolbar on macOS, the top of a sidebar, from iOS 26 a bottom toolbar), with its own
magnifier, dictation, Cancel, scopes and suggestions. SwiftUI has no style for it (the SwiftUI interfaces of Xcode
27.1 for iOS and macOS declare no `SearchFieldStyle`; the search in a toolbar, `ToolbarDefaultItemKind.search`, is iOS
26 and macOS 26; the trait `AccessibilityTraits.isSearchField` exists from iOS 13 and macOS 10.15), so westron could
not style it; and
it cannot stand where the pilot puts its search, in a bar of the product's own before iOS 26, or at the bottom of a
Mac sidebar.

- (a) **A styled `TextField` only.** Misses the system's search where the system places it, which a product should
  keep.
- (b) **`.searchable` only.** Cannot draw the pilot's bar on iOS 17 to 25 or its sidebar on the Mac.
- (c) **Both, each where it belongs**: the styled `TextField` where the product places its search itself, in a bar or
  a pane of its own; `.searchable` where the system places it, left to the system as a menu or an alert is
  (decisions/0014, "What stays the system's"), with no westron style.

**Proposed: (c)**, recorded in the contract's `platforms.apple`. Where a product moves from one to the other, such as
the pilot's bar to a bottom toolbar's search from iOS 26, is the product's choice.

### 4. A glyph that is pressed

- (a) **Decoration only**: both glyphs are hidden from assistive technology, a touch or a click on them is one on the
  field, which focuses it (the style's existing `TextFieldHitArea` covers the whole field), and they add nothing to
  the focus order.
- (b) **The trailing place takes a control**, a westron Button, iconOnly, tertiary: a clear button or dictation. It
  needs an argument that takes a view, which the conventions derive for no style; a hit area of 44 pt on iOS inside a
  field drawn 28 or 36 pt high, overlapping the field's own; a place in the focus order after the field; an action
  for dictation that SwiftUI does not offer (the keyboard has its own dictation key).
- (c) **A clear button built in**, as UIKit's `clearButtonMode`: SwiftUI's field has none, and the pilot draws none.

**Proposed: (a).** The pilot's glyph at the end acts on nothing (above); AGENTS.md, rule 6, keeps the contract to the
pilot's need. A control at the end is a later revision, with its consumer.

### 5. Variants, lines and sizes

- **Both variants draw the glyphs.** `framed` is what the pilot needs. An `inline` field could leave them out, but an
  argument the style silently drops is a trap, and no constraint can forbid it: the checker rejects any constraint
  that names an option whose values are icons. Drawn on `inline`, a glyph stands in the context's text role, as a
  letter of that text would.
- **Both values of `lines`.** On a field of several lines the glyph stands beside the first line, on its baseline;
  forbidding it needs the same constraint. The pilot draws single only.
- **Every size.** The glyph takes the text's size, `body.regular` at every size of `framed` (P3 of decisions/0001), so
  the size changes the field's height and padding around it, not the glyph.
- **The glyph's place**: at the field's horizontal padding from its edge (`container.paddingHorizontal`, unchanged),
  and `container.gap` from the text: `space.75` (6) at `s`, `space.100` (8) at `m` and `l` and on `inline`. The pilot's
  gaps are 8 on the phone and 6 on the Mac; Button's gap, 4 and 6, sits between an icon and a strong label, and a
  magnifier before a placeholder reads apart at 6 to 8. The gap scales with Dynamic Type as the padding does, relative
  to the field's text style. Considered: a tighter inset for the glyph than for the text, such as `space.100`,
  `space.150` and `space.200`, which would sit it in the capsule's round end as the system's search fields do (the
  pilot's is 15 in at 48 high); it adds a binding per glyph and moves the text of a search field off the text of the
  fields stacked with it. Open question 6.

### 6. The glyph's color in each state

| State | Glyph | Text beside it |
|---|---|---|
| placeholder shown | `color.text.secondary` | the placeholder, `color.text.placeholder` (on Apple the system's, I1 of decisions/0001) |
| text entered | `color.text.secondary` | `color.text.primary` (framed) |
| focus | `color.text.secondary` | unchanged; the ring is drawn around the whole field |
| disabled | `color.text.secondary`, the whole field at `opacity.disabled` | the same |

One color in every state, as the system's search fields keep their magnifier, and as the pilot draws both glyphs in
the placeholder's ink. `color.text.secondary` is "text and glyphs that come second" in its usage, the same step of the
neutral ramp as `text.placeholder`, and its declared text pairs include `background.muted`, the framed fill, and the
canvas, surface and sunken grounds an inline field stands on. From `tools/westron tokens contrast --all`: on
`background.muted` 4.74:1 in light, 5.02 in dark, 7.43 in light-hc, 7.78 in dark-hc; on `background.canvas` 5.27, 6.22,
8.25 and 9.62. A decorative glyph needs no contrast under WCAG, so this is more than it must meet. `color.icon.tertiary`
(3:1, for a chevron or a grip) was considered: it has no declared pair on `background.muted`, and the magnifier is
nearer to the placeholder's words than to a chevron. Considered too: `text.primary` once text is entered, a glyph that
changes with the text, which nothing asks for.

On Apple the glyph will be darker than the system's placeholder beside it (1.72:1 against the canvas on iOS in light,
I1): the two differ in color until westron draws its own prompt, the open point I1 left for the owner. Open question 7.

### 7. Size, Dynamic Type and right to left

- The glyph is sized by the field's text: framed's `body.regular`, inline's context, at the text's own scale
  (`.imageScale(.medium)`, Icon's default), so it grows with the person's text size and sits on the line as Icon's
  contract asks of an icon next to text. Button's icon is a scale smaller, beside a strong label; the pilot's glyph is
  the size of its word (17 pt beside 17 pt). Open question 8.
- Start and end follow the layout direction: right to left, the magnifier is at the right and the microphone at the
  left. Whether a glyph itself mirrors is the system's, per symbol; neither `magnifyingglass` nor `mic` was measured.

### 8. Accessibility

- The glyphs are decorative and hidden, as `Icon(_:)` without a label is: the system's names of the symbols
  ("magnifying glass", "microphone") would only add noise before the field's name, and would describe the drawing, not
  the field.
- The label stays required, and a magnifier does not name the field: the product names it for what it searches
  ("Search", "Search lists"), with `.accessibilityLabel(_:)` on Apple, as the contract already asks (I2).
- A search field is announced as one where the platform has the role: on Apple the product adds
  `.accessibilityAddTraits(.isSearchField)`, on the web `<input type="search">` gives the `searchbox` role, on GTK the
  search entry's role. westron's style does not add it, since it cannot tell from a glyph what a field is for; an
  option for the field's purpose was considered and set aside, as one more option for what the product already says
  in one line. What VoiceOver reads for a styled field with the trait was not measured: the implementation measures it
  on iOS and macOS. Open question 9.

### 9. The hold of #113 on macOS, beside the glyphs

`TextFieldLine` holds the system field to its own lines from macOS 26: it pins a single-line field to its line's
height, makes the field's font anew, and offers the field a width more, up to 31/2048 of a point, at its right edge.
With glyphs:

- **The glyphs keep their places.** The hold is a modifier on the system field, inside the row the style lays the
  glyphs out in. The width it offers more is taken back outside the field (a negative padding reports the field's
  width less that much), so the row sees the same width and puts the glyphs where it did; the field draws at most
  1/64 pt into the gap, which is 6 pt or more. The font made anew is the field's, set below the text role the style
  gives the row; the glyphs keep theirs.
- **The height.** A single-line field is pinned to its line; the row is as high as the taller of the field's line and
  the glyph. At the default text size the minimum heights, 24, 32 and 40 on macOS, are more than either, so the field's
  height does not change. The glyph aligns on the field's first text baseline, which a frame around a view passes on
  from it; that the hold's frame does so for the system field is to be measured with the rest below.
- **What must be measured.** The hold keeps a held field's frame at 1x and 2x because a right edge at a half point
  rounds the same way with the width added (`TextFieldLineTests`). Beside a trailing glyph, the field's right edge
  stands where the glyph's width puts it, at any part of a point, so an edge just below a rounding boundary could move
  a pixel at 1x. The field draws no bezel, so a pixel there would show only where its scrolling text is clipped. The
  implementation adds fields with glyphs to `TextFieldLineTests` and says what it finds. Whether the glyphs' own symbol
  fonts change how often SwiftUI's font cache misreads a field is not known; the same tests would show it.

### 10. The platforms

- **watchOS**: the field is the system's as it is, so the glyphs compile and draw nothing there. The contract cannot
  restrict an option whose values are icons on a platform (the checker rejects it), so `platforms.apple.watchos` says it
  in words; #34 decides the watch's subset.
- **Web**, provisional: an `<input>` takes no children, so a field with a glyph is an element around it that draws the
  fill, the glyphs as inline SVGs with `aria-hidden`, and the ring on `:focus-within`; a search field is
  `<input type="search">`. This differs from the base `input` alone, and the web entry says so.
- **GTK**, provisional: `GtkEntry`'s own primary and secondary icons, by symbolic name, not activatable;
  `GtkSearchEntry`, which draws the magnifier itself, is phase 7's to weigh.
- **Android**, planned: Material3's `TextField`, whose `leadingIcon` and `trailingIcon` slots take the glyph with no
  content description. The entry stays `status: planned`, with a description, as Icon's web entry has.

## What the tools need

Checked on a copy of the proposed contract: `tools/westron spec check` on it reports only `optional`, "unknown key: the
schema does not allow it here", and with `optional` taken out it passes (the new bindings, their cases and their
tokens are valid). Put into the repository with `optional` taken out, `tools/westron generate --check` fails with
"leadingIcon takes its values from the icon registry: the generator does not give a style such an option yet", while
`tools/westron lint api-parity` passes, since it skips such an option on a style instead of expecting it. So:

1. **Schema** (`spec/schema/component.schema.json`, `iconOption`): `optional`, a boolean, default false. The README's
   "Options whose values are icons" and the schema's description say what it means.
2. **The contract model** (`ComponentContract.swift`): the icons kind carries whether it is optional.
3. **The checker** (`ContractRules.swift`): `optional` only where the conventions derive it, a style on a system control
   for now; an own view's icons option, Icon's glyph, stays required. The ban on naming an icons option in a
   constraint, a case, a restriction or `systemOptions` stays.
4. **The generator** (`AppleComponents.swift`, the style's options): an optional icons option becomes a labeled
   argument `<name>: Westron.Icon? = nil`, in the contract's order after the other options, passed to
   `<Component>VariantStyle`; a required one on a style stays unsupported.
5. **The parity lint** (`APIParity.swift`): expect the same parameters instead of skipping the option, so a missing or
   changed argument fails.
6. **The snapshot matrix** (`SnapshotMatrix.swift`, `AppleSnapshotMatrix.swift`): an icons option runs the registry's
   names down the rows only in a contract without states. An optional icons option on a style becomes an axis of two
   values, without and with a glyph, and the hand-written `TextFieldMatrixCell` chooses the glyph (`magnifier` at the
   start, `microphone` at the end). TextField's matrix goes from 36 combinations on 6 sheets to 144 on 24. Considered:
   leaving the glyphs out of the generated matrix and drawing them on a hand-written supplement, which the README keeps
   for what no contract option sets; this is a contract option. Open question 10.
7. **The conventions** (`spec/conventions.md`): the rows "Option whose values are icons" and "Slots" give a style its
   optional icons arguments; "A search field" goes beside "What the system presents" (point 3).

Nothing in the icon registry: `magnifier` and `microphone` exist.

## What the tokens need

Nothing new. `space.75`, `space.100`, `typography.body.regular` and `color.text.secondary` exist, and
`color.text.secondary` has declared text pairs on `background.muted`, `canvas`, `surface` and `sunken`. Missing, and
not added now:

- no `color.icon.*` role for a glyph that comes second; `color.text.secondary`'s usage covers glyphs, so none is needed;
- no pair for anything on glass: the pilot's bar stands its capsule on the bar's glass, which is #121's; a framed field
  there keeps its muted fill, and what it measures against glass is #121's to say.

## How the revision is held

The contract is approved and generates WestronUI's API, its matrix and its parity expectations, so its YAML cannot
change before the tools follow: with `optional`, `spec check` fails on the schema; without it, `generate` fails on an
icons option of a style; and `status: draft` would delete the generated API that the catalog and the tests build on.
So this record carries the proposed contract in full (below), checked as far as today's tools can (above), and the
contract has a comment under its header that points here and says nothing in it has changed. Once it is approved, the
implementation moves this YAML into the contract with the tool changes in the same pull request, takes the comment
out, and the checks hold the two together from then on.

## Open questions for the approver

Each with the agent's recommendation; each is a guess where no source decided it.

1. **The API shape** (point 1). Recommended: arguments of the generated overload, `leadingIcon:` and `trailingIcon:`,
   `Westron.Icon?`, nil by default; not westron modifiers through the environment.
2. **The concept in the contract** (point 2). Recommended: options of type `icons` with a new `optional: true`, rather
   than slots; and the keyword's name `optional`.
3. **Search on Apple** (point 3). Recommended: both, the styled field where the product places its search and
   `.searchable` where the system places it, unstyled. Whether the pilot adopts the field before its search epic is
   the pilot's: today its capsule is inert and a real field would open the keyboard on a tap. Recommended: it adopts
   the field with its search epic and keeps its inert drawing until then.
4. **The glyph at the end is decoration only** (point 4). Recommended: yes; a control at the end, a clear button or
   dictation, waits for a consumer. Whether the pilot keeps drawing a microphone that starts nothing is the pilot's
   choice; westron draws it as the owner described the field (decisions/0014).
5. **Variants and lines** (point 5). Recommended: the glyphs on both variants and both values of `lines`, since
   nothing can forbid them and a dropped argument is a trap; the pilot needs `framed` and `single`.
6. **The glyph's inset and the gap** (point 5). Recommended: the glyph at the field's horizontal padding, unchanged, and
   `container.gap` of `space.75` at `s` and `space.100` at `m`, `l` and on `inline`. The alternative is a tighter inset
   for the glyph, `space.100`, `space.150`, `space.200` by size.
7. **The glyph's color** (point 6). Recommended: `color.text.secondary` in every state. The alternative on Apple is the
   system's placeholder color, which would match the system's prompt beside it and miss chapter 08's text target as
   that prompt does.
8. **The glyph's size** (point 7). Recommended: the field's text at its own scale (`medium`), not Button's `small`.
9. **The search field's announcement** (point 8). Recommended: the product adds the platform's search-field role, as it
   gives the label; westron adds no option for the field's purpose.
10. **The snapshot matrix** (tools, item 6). Recommended: each optional icons option an axis of two values, the cell
    choosing the glyph, 144 combinations on 24 sheets.
11. **watchOS** (point 10). Recommended: no glyph on the watch until #34, said in the contract's words.

## The proposed contract in full

The approved contract with this revision, as it would replace `text-field.spec.yaml`. What changes: the header
comment; a paragraph of the description; the options `leadingIcon` and `trailingIcon`; the bindings `container.gap`,
`leadingIcon.font`, `leadingIcon.color`, `trailingIcon.font` and `trailingIcon.color`; the accessibility description;
and the `platforms` descriptions of Apple, iOS, macOS, watchOS, the web, Linux and Android.

```yaml
# westron's TextField contract (#30), approved on 2026-11-18 under the owner's delegation of that day:
# decisions/0001-text-field-contract.md records the owner's answers of 2026-11-18, what the documents already decide,
# and the proposals approved on top of them, the ones the agent decided under the delegation marked as such. Revised on
# 2026-11-20 (#85): the look the owner chose, a muted fill with no outline, a capsule on one line and a rounded
# rectangle on several, and the option lines (decisions/0002-the-look-of-2026-11-20.md). Revised on 2026-11-22
# (#115): a glyph at the field's start and at its end, the options leadingIcon and trailingIcon, so that a search field
# is this field (decisions/0003-icons-at-the-start-and-the-end.md).
id: text-field
status: approved
description: >-
  A field a person types text into: westron's style on the platform's own text field, which keeps editing,
  selection, input methods, the keyboard and the system's text input. framed is a field that stands on its own, such
  as the name field in a list's row: filled with color.background.muted, the secondary button's fill, with no
  outline; on one line it is the platform's capsule, its ends round at any height, and on several lines a rounded
  rectangle, since a capsule's ends would cut into its lines (option lines). The fill stands about 1.1:1 off the
  canvas in light and 1.2:1 in dark, below the 3:1 that WCAG 1.4.11 asks of a component's boundary: a deviation the
  owner accepted on 2026-11-20 for the standard themes, which design-language/08 records with the measured values
  (decisions/0002). In the high-contrast themes a framed field also draws an outline, color.border.strong at
  stroke.thin, over its fill, in every state, as the secondary button does: the fill stays as quiet there, and a
  control a person must find meets the non-text target in high contrast. The bindings below cannot say this, since a
  case has no contrast key, so this description is the contract for it, as Button's is for its outline. inline is a
  field set into a text it belongs to, such as the title and the notes inside an open task card: no fill, no outline
  and no padding, in the text role and the text color of its context. Focus is westron's ring, color.border.focus at
  stroke.thick, around the field in both variants, on iOS, on macOS and on the web; around a framed field it lies
  against the field's edge, outside it with no gap, and follows the field's shape, the capsule or the rounded
  rectangle; the system's own focus ring is turned off where it has one.
  watchOS enters no focus. Disabled draws the whole field at opacity.disabled, with no colors of its own
  (design-language/08). The placeholder is in color.text.placeholder. A field may carry a glyph of the icon registry
  at its start, at its end or at both (leadingIcon, trailingIcon). A glyph is decoration, never a control: it is
  hidden from assistive technology, a touch or a click on it is one on the field, which it focuses, and it adds
  nothing to the focus order. It stands inside the field, on its fill and inside its focus ring: at the field's
  horizontal padding from the field's edge and container.gap from the text, beside the first line of a field of
  several lines, on that line's baseline, as a letter of it would; start and end follow the layout direction, so
  right to left the leading glyph is at the right. It takes its size from the field's text, framed's body.regular or
  inline's context, at the text's own scale, so it grows with the person's text size, and it draws in
  color.text.secondary in every state, with the placeholder shown or text entered, focused or not; disabled dims it
  with the rest of the field. A search field is no component of its own (decisions/0014): it is a framed field with
  the magnifier at its start, and a glyph at its end where the product has one. There is no error state, hint or message in
  this version: no pilot screen shows one, and a field marked only by a danger border would tell an error by color
  alone (design-language/08, "Color is never the only signal"). The text, and with it a framed field's height,
  follows the person's text size (design-language/08, "Settings the person chooses"). A field is never drawn lower
  than its text needs, in either variant: its height is that of its lines and its padding, or its minimum height,
  whichever is more, and a layout that offers it less height does not squeeze it; a multiline field has as many lines
  as its text and the product's line limit give, and scrolls past them.
consumers: [todo-app/lists-screen, todo-app/list-screen]

options:
  variant:
    type: enum
    values: [framed, inline]
    description: >-
      No default: every use names its variant. The system's own style names (automatic, plain, roundedBorder,
      squareBorder, bordered) are not values: westron's overload would shadow them (decisions/0003).
  size:
    type: enum
    values: [s, m, l]
    default: m
    description: >-
      framed: the height is size.control.s, m or l, 24, 32 and 40 with a pointer (macOS), 28, 36 and 50 on iOS and
      iPadOS, 44 on watchOS, as a minimum, so the field grows with its text; its padding follows the size, and its
      text is body.regular at every size. A field drawn below size.target.minimum, the platform's recommended target,
      28 pt on macOS and 44 pt on iOS, keeps a hit area of that height (design-language/08): at s on macOS, at s and
      m on iOS. inline takes its height and its text role from its context, so the size changes nothing on it.
  lines:
    type: enum
    values: [single, multiple]
    default: single
    description: >-
      single is a field of one line, whose text scrolls sideways, such as a list's name; multiple is a field whose
      text wraps and which grows a line at a time, such as a card's notes. framed draws single as a capsule and
      multiple as a rounded rectangle of radius.150, its lines held off its top and bottom edges by a padding that,
      at the default text size, makes a field of one line as tall as a single one of its size, and that does not grow
      with the text, as the minimum heights do not; inline draws both alike. On Apple it is the
      system field's own axis (platforms.apple.systemOptions).
  leadingIcon:
    type: icons
    optional: true
    description: >-
      The glyph at the field's start, a name of the icon registry, or none: a use that leaves it out draws no glyph
      there and gives the text that room. A search field's magnifier. It is decoration and says nothing to assistive
      technology, so the field's label still names the field.
  trailingIcon:
    type: icons
    optional: true
    description: >-
      The glyph at the field's end, or none, such as the microphone at the end of the pilot's search field.
      Decoration, as the leading one: a glyph that acts when it is pressed, such as a clear button or one that starts
      dictation, is not this option (decisions/0003-icons-at-the-start-and-the-end.md).

slots: [label, placeholder]
states: [focus, disabled]

tokens:
  container.height:
    cases:
      - { when: { variant: framed, size: s }, token: size.control.s }
      - { when: { variant: framed, size: m }, token: size.control.m }
      - { when: { variant: framed, size: l }, token: size.control.l }
  container.shape:
    cases:
      - { when: { variant: framed, lines: single }, token: capsule }
  container.radius:
    cases:
      - { when: { variant: framed, lines: multiple }, token: radius.150 }
  container.paddingHorizontal:
    cases:
      - { when: { variant: framed, size: s }, token: space.200 }
      - { when: { variant: framed, size: m }, token: space.250 }
      - { when: { variant: framed, size: l }, token: space.300 }
  container.paddingVertical:
    cases:
      - { when: { variant: framed, lines: multiple, size: s }, token: space.50 }
      - { when: { variant: framed, lines: multiple, size: m }, token: space.100 }
      - { when: { variant: framed, lines: multiple, size: l }, token: space.150 }
  container.background:
    cases:
      - { when: { variant: framed }, token: color.background.muted }
  container.opacity:
    cases:
      - { when: { state: disabled }, token: opacity.disabled }
  text.font:
    cases:
      - { when: { variant: framed }, token: typography.body.regular }
  text.color:
    cases:
      - { when: { variant: framed }, token: color.text.primary }
  placeholder.color: color.text.placeholder
  container.gap:
    token: space.100
    cases:
      - { when: { variant: framed, size: s }, token: space.75 }
  leadingIcon.font:
    cases:
      - { when: { variant: framed }, token: typography.body.regular }
  leadingIcon.color: color.text.secondary
  trailingIcon.font:
    cases:
      - { when: { variant: framed }, token: typography.body.regular }
  trailingIcon.color: color.text.secondary
  focusRing.color:
    cases:
      - { when: { state: focus }, token: color.border.focus }
  focusRing.width:
    cases:
      - { when: { state: focus }, token: stroke.thick }

accessibility:
  role: textField
  intents: [edit]
  keyboardIntents: [edit]
  label: required
  states: { disabled: disabled }
  description: >-
    Every field has an accessible label that names what it holds ("List name"), also where no label is visible; a
    placeholder is not a label, since it disappears as the person types. The text is the field's value. In
    disabled, the field is announced as unavailable. A glyph at the start or the end is decorative and hidden: it
    never names the field, and a magnifier does not make it a search field. A field a person searches with is
    named for what it searches ("Search", "Search lists") and announced as a search field wherever the platform has
    that role: the product says so, as it gives the label, since westron cannot tell from a glyph what a field is
    for (platforms).

platforms:
  apple:
    strategy: style-on-system-control
    base: SwiftUI.TextField
    systemOptions: { lines: SwiftUI.Axis }
    description: >-
      .textFieldStyle(.framed, size: .s) on the system TextField, and on SecureField, which takes the same modifier.
      lines is the system field's own axis, so no enum is generated for it and the overload takes no lines: argument:
      TextField(_:text:axis:) with .vertical is multiple, any other field single. A TextFieldStyle has no public way
      to read the axis, so the style reads it from the field it is given, the configuration, whose stored axis
      reflection (Mirror) finds, measured with Xcode 27.1 on iOS 17.5, iOS 26.3 and macOS 26.7 (TextFieldStyleTests);
      where reflection finds no axis, the style draws single (decisions/0002, pending the owner's confirmation). The
      shapes are SwiftUI's Capsule and a RoundedRectangle, both with continuous corners, and the high-contrast outline
      follows colorSchemeContrast, as Button's does. The style fixes the field's vertical size, so that it keeps its
      height: without it, offered 8 pt at accessibility5 on iOS 26.3, a framed field of one line took 36 pt for its
      65, a framed multiline one 36 for 142 and an inline multiline one 8 for 126 (TextFieldStyleTests). So a
      multiline field takes its text's height, and a product's fixed-height frame does not squeeze it into scrolling:
      the field spills past the frame. A product bounds a multiline field with lineLimit, not with a fixed-height
      frame; here westron's field differs from the system's, which scrolls inside such a frame.
      The style is a TextFieldStyle, which SwiftUI declares with only the underscored requirement
      _body(configuration:). The probe of #30 with Xcode 27.1, run on iOS 26.3 and macOS 26.7 and compiled for iOS 17,
      macOS 14 and watchOS 10 (no older runtime and no watch runtime to run on): the requirement is not isolated to the
      main actor, so the conformance is @preconcurrency with a main-actor witness, and the style applies; the
      configuration is the system field, drawn inside the style in the system's plain style, which has no bezel and no
      focus ring of its own; focus is read with a @FocusState the style binds to the field, since
      @Environment(\.isFocused) in the style describes the field's ancestors and stays false, and a product's own
      .focused(_:) on the field keeps working beside it. A tap or a click on a framed field's padding focuses it. A call
      without size: takes it from controlSize (spec/conventions.md). The placeholder is the system field's own prompt,
      and so is a multiline field, TextField(_:text:axis:) with .vertical, such as a card's notes. The label: on iOS
      26.3, and on macOS 26.7 outside a Form, the system field with a prompt exposes no accessibility label from its
      title, with westron's style or without it, and the prompt is only its placeholder value (measured in #30; inside
      a macOS Form the title becomes a static text and the field's title element in the accessibility tree), so the
      product gives the field its name itself: TextField("List name", text: $name, prompt: Text("Untitled")).accessibilityLabel("List
      name"). The placeholder's color differs from the contract on Apple: a TextFieldStyle cannot set the prompt's
      color (neither foregroundStyle at any level nor tint reaches it), so the prompt is drawn in the system's
      placeholder color, not color.text.placeholder, which stays bound for the platforms that can apply it. Against
      background.canvas it measures 1.72:1 on iOS in light and 2.42:1 in dark, and about 3.9:1 on macOS in light,
      where color.text.placeholder gives 5.27:1 and 6.22:1: on Apple the placeholder misses chapter 08's contrast
      target for text. Decided on 2026-11-19 under the owner's delegation of 2026-11-18, pending the owner's
      confirmation, as is the label above; westron
      drawing its own prompt, an API change, stays open for the owner (decisions/0001). westron's focus ring is drawn
      outside the field's laid out frame, so a focused field needs room around it that no clipping parent and no
      close neighbor takes: on framed stroke.thick beyond the field's edge on every side, the ring touching the edge
      with no gap (the owner's decision of 2026-11-20, decisions/0002), on inline
      space.100 across and space.50 up and down beyond the field (a proposal of the implementation, decisions/0001,
      I4). Corners are continuous.
      leadingIcon and trailingIcon are labeled arguments of the overload, Westron.Icon? with nil as their default:
      .textFieldStyle(.framed, leadingIcon: .magnifier, trailingIcon: .microphone). They cannot come through the
      field's label, as Button's icon does: a TextFieldStyle is given the field alone, whose label is its title, and
      has no public way to read the label's parts. Like the variant and the size they reach every field the modifier
      is set on, in a container too. The style draws each glyph as Icon draws a decorative one, hidden from
      assistive technology, in a row with the system field aligned on its first text baseline, inside the fill, the
      high-contrast outline, the focus ring and the area that focuses the field on a tap or a click. A search field
      on Apple is this field where the product places its search itself, in a bar or a pane of its own, named and
      given the system's trait for a search field by the product: TextField("Search", text: $query, prompt:
      Text("Search")).textFieldStyle(.framed, leadingIcon: .magnifier).accessibilityLabel("Search")
      .accessibilityAddTraits(.isSearchField). Where the system places the search, SwiftUI's .searchable (the
      navigation bar, the toolbar, the top of a sidebar, and from iOS 26 a bottom toolbar), the field is the
      system's, with its own magnifier, dictation and Cancel, and takes no westron style: SwiftUI has no style for it,
      and westron leaves it to the system as it leaves a menu or an alert (decisions/0014).
    ios:
      description: >-
        Focus is the field being edited, with the keyboard up. There is no pointer to hover with on an iPhone, and
        the field shows nothing on hover on an iPad either. At s, drawn 28 pt high, a tap 8 pt past the drawn edge,
        at the 44 pt target, focuses the field, and one 24 pt past it does not; at m, drawn 36 pt high, a tap 4 pt
        past either edge, at the same target, focuses it (the catalog's TextFieldBehaviorTests);
        a one-off probe of #30 found the reach ending between 16 and 18 pt. The style's tap gesture, which focuses a
        field from its padding, is what takes these touches: with it removed, a tap on the padding and one at the
        target missed. A tap on a glyph is taken by the same gesture and focuses the field. The style grows no frame
        of its own on iOS. A product reaches color.text.placeholder by
        coloring its prompt itself: prompt: Text("Untitled").foregroundStyle(.text.placeholder).
    macos:
      description: >-
        westron's focus ring replaces the system's, so focus is drawn in color.border.focus rather than in the accent
        color the person chose in System Settings. The system draws no ring because the style draws the field in the
        system's plain style, which has none; focusEffectDisabled() does not turn off the ring of the default,
        bezeled field (the probe of #30). This is the owner's decision for this component (its decisions/0001);
        design-language/08 ("Keyboard and focus"), 09 ("What stays with the system", macOS) and spec/conventions.md
        ("States the system control has") record the exception. At s the field takes clicks in at least 28 pt around
        its drawn 24 pt, as chapter 08 asks, with no exception like Button's. macOS 26 ignores a color the product
        sets on its prompt, so there the placeholder is always the system's. A disabled field's text is dimmed twice:
        the system field draws it in its own disabled text color under westron's opacity.disabled, (57, 60, 66)
        against background.canvas (17, 19, 24) in dark where text.primary at opacity.disabled alone would be (96, 101,
        108); the fill, westron's, is at opacity.disabled alone. Recorded on 2026-11-19 under the owner's
        delegation of 2026-11-18, pending the owner's confirmation.
        A defect of SwiftUI on macOS (#99, #113) can lay the system field out at another font's line height: SwiftUI
        takes a field's line height from a cache of the three fonts it measured last, keyed by the font object's
        address, so a font made where a freed one was takes that one's height, and a field of one line, or of several
        lines held by its line limit (one line under lineLimit(1...4)), comes out a point or more taller or shorter
        than its lines; shorter cuts off the bottom of its text. SwiftUI holds the system field to that height whatever
        it is offered, and the font object it measures is its own, which no public API returns. From macOS 26 the style
        holds a field of one line to its line, and a field of several lines to a whole number of its lines: it
        measures its font's line itself (AppKit's default line height of the font Font.resolve(in:) gives), gives a
        field of one line exactly that height with the system field at its top, and where SwiftUI has laid the field
        out at another height it gives the field the same font with leading(.standard) added once more, which draws
        the same pixels and which SwiftUI resolves and measures anew, and offers it a width more by a part of a pixel
        at its right edge, so that SwiftUI sizes it anew; up to eight times in a row, and again each time the field
        has been back at its lines, so a field on screen for long is held each time. A field laid out at its own lines
        is unchanged, in layout and in pixels; a field it held keeps its frame, at 1x and 2x, left to right and right
        to left; and editing in a field it holds keeps its text, its selection and an input method's marked text. Not
        covered: a field of several lines held at another font's height that is a whole number of its own lines,
        which the style takes for a field of that many lines (a framed body.regular field holding one line under
        lineLimit(1...4) laid out 32 pt high, two of its lines, in 1 to 26 of 750 layouts while plain fields in
        largeTitle and in Helvetica at 6 pt came and went); macOS 14 and 15, which have no API to resolve a font; a field whose axis the style cannot read, which it leaves as SwiftUI lays it out; and a field
        with no font in its context, which the system draws in its control size's font. Measured with Xcode 27.1 on
        macOS 26.7.1 (TextFieldLineTests); the owner decided on 2026-11-22 that westron works around the defect
        (#113). The hold is on the system field alone, inside the row of glyphs: the font it makes anew is the
        field's, not a glyph's, and the width it offers the field more is taken back outside the field, so the
        glyphs keep their places while it holds the field. Beside a trailing glyph the field's right edge stands
        where the glyph's width puts it, at any part of a point, so that the field keeps its frame there at 1x and
        2x is measured with the glyphs (TextFieldLineTests, #115).
    watchos:
      options: { size: [m] }
      fallback: { size: m }
      states: [disabled]
      description: >-
        The watch's field is the system's as it is: a tap opens the system's text input, there is no focus to draw,
        and roundedBorder, like westron's fill and capsule, has no place there. Both variants and both values of lines
        draw the system field; the Swift enum keeps every size and the style falls back to m. leadingIcon and
        trailingIcon compile on the watch and draw nothing there, a difference the contract cannot restrict, since
        no platform restriction names an option whose values are icons; #34 decides the watch's subset.
  web:
    strategy: style-on-system-control
    base: input
    description: >-
      Provisional until phase 6 (#40): a native <input> with westron's CSS, lines multiple a <textarea>. The
      focus ring is an outline in focusRing.color and focusRing.width on :focus-visible, at outline-offset 0 on
      framed, so it touches the field's edge. Corners are circular; the
      capsule is a border-radius of half the height or more, so its ends stay round as the field grows. The
      high-contrast outline applies under prefers-contrast: more. An <input> takes no children, so a field with a
      glyph is an element around it that draws the fill, the glyphs as inline SVGs hidden with aria-hidden, and the
      ring on :focus-within, the input inside with no frame of its own; a search field is <input type="search">,
      the searchbox role.
  linux:
    strategy: style-on-system-control
    base: GtkEntry
    description: >-
      Provisional until phase 7: the stock GtkEntry with westron's style classes for the variants and the sizes, and
      for lines multiple a GtkTextView with the same classes; the focus ring there is decided with the GNOME library.
      Corners are circular; the capsule is a border-radius of half the height or more, as on the web. The glyphs are
      GtkEntry's own primary and secondary icons, by their symbolic names, not activatable; whether a search field
      is GtkSearchEntry, which draws the magnifier itself, is decided in phase 7.
  android:
    status: planned
    description: >-
      Provisional until phase 8: Material3's TextField, whose leadingIcon and trailingIcon slots take westron's glyph
      with no content description.
```
