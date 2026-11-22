# 0003. Icons at the start and the end

Date: 2026-11-22. Status: approved on 2026-11-22 (#115) by the coordinating agent, to whom the owner delegates the
approval of a contract in phase 4 (decisions/0014, "Process"), with one answer other than the proposal: the glyphs are
no axis of the generated snapshot matrix (below, "The approver's answers", 10). The revision is in
`text-field.spec.yaml`. There was no one to interview: the agent answered the questions of the `new-component`
interview from the sources, and names the source of each answer; every answer it had to guess was a question for the
approver, with a recommendation, and the approver's answer follows each below. The implementation's measurements are
under "Measured at implementation".

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
  to the field's text style (on Apple an inline field's gap scales on body's curve, since a style cannot read its
  context's text style: below, "The review's findings"). Considered: a tighter inset for the glyph than for the text, such as `space.100`,
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
  left. Whether a glyph itself mirrors is the system's, per symbol; neither `magnifyingglass` nor `mic` was measured
  (the magnifier was later: it does not mirror, below, "The review's findings").

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

Checked on a copy of the proposed contract before the approval: `tools/westron spec check` on it reported only
`optional`, "unknown key: the schema does not allow it here", and with `optional` taken out it passed (the new
bindings, their cases and their tokens are valid). Put into the repository with `optional` taken out, `tools/westron
generate --check` failed with "leadingIcon takes its values from the icon registry: the generator does not give a style
such an option yet", while `tools/westron lint api-parity` passed, since it skipped such an option on a style instead
of expecting it. What the implementation changed:

1. **Schema** (`spec/schema/component.schema.json`, `iconOption`): `optional`, a boolean, false when left out.
2. **The contract model** (`ComponentContract.swift`): the icons kind carries whether it is optional,
   `.icons(optional:)`.
3. **The checker** (`ContractRules.checkIconOptions`): `optional: true` only on a contract whose Apple strategy is a
   style on a system control; an own view's icons option, Icon's glyph, stays required, and an extension takes none.
   The ban on naming an icons option in a constraint, a case, a restriction or `systemOptions` stays.
4. **The generator** (`AppleComponents.swift`, the style's options): an optional icons option is a labeled argument
   `<name>: Westron.Icon? = nil`, in the contract's order after the other options, passed to `<Component>VariantStyle`;
   one every use names stays unsupported on a style, and an optional one on an own view is reported as not derived.
5. **The parity lint** (`APIParity.swift`): it expects the same parameters, so a missing or changed argument fails; an
   option of a style that the conventions give no argument (tokens, or icons every use names) is now reported as one
   the lint cannot derive, where it used to be skipped (`OptionalIconOptionTests`, `IconOptionContractTests`).
6. **The snapshot matrix** (`SnapshotMatrix.swift`, `AppleSnapshotMatrix.swift`): an optional icons option is no axis;
   the generated matrix draws every combination without the glyph, and the registry is read only for an icons option
   that is one. The component draws the glyphs on hand-written supplementary sheets (the approver's answer 10, below).
7. **The conventions and the README** (`spec/conventions.md`, `spec/components/README.md`): the rows "Option whose values
   are icons" and "Slots" give a style its optional icons arguments; a note on `.searchable` beside the paragraph on
   what the system presents.

Nothing in the icon registry: `magnifier` and `microphone` exist.

## What the tokens need

Nothing new. `space.75`, `space.100`, `typography.body.regular` and `color.text.secondary` exist, and
`color.text.secondary` has declared text pairs on `background.muted`, `canvas`, `surface` and `sunken`. Missing, and
not added:

- no `color.icon.*` role for a glyph that comes second; `color.text.secondary`'s usage covers glyphs, so none is needed;
- no pair for anything on glass: the pilot's bar stands its capsule on the bar's glass, which is #121's; a framed field
  there keeps its muted fill, and what it measures against glass is #121's to say.

## How the revision was held

The contract was approved and generated WestronUI's API, its matrix and its parity expectations, so its YAML could not
change before the tools followed: with `optional`, `spec check` failed on the schema; without it, `generate` failed on
an icons option of a style; and `status: draft` would have deleted the generated API that the catalog and the tests
build on. So the first version of this record carried the proposed contract in full, checked as far as the tools could,
and the contract carried a comment that pointed here. On approval the revision moved into `text-field.spec.yaml` with
the tool changes, the comment and the copy here went, and the checks hold the contract and the code together.

## The approver's answers

Approved on 2026-11-22 by the coordinating agent under the owner's delegation of the phase's contracts
(decisions/0014, "Process"). The questions, each with the agent's recommendation as proposed, and the answer:

1. **The API shape** (point 1): arguments of the generated overload, `leadingIcon:` and `trailingIcon:`,
   `Westron.Icon? = nil`. **Approved.**
2. **The concept in the contract** (point 2): options of type `icons` with `optional: true`. **Approved**, allowed only
   where the generator derives it, a style on a system control; Icon's and IconTile's `glyph` stay required. The
   api-parity lint's gap, which skipped an icons option on a style rather than expect it, is closed, with a test.
3. **Search on Apple** (point 3): both, the styled field where the product places its search and `.searchable` where
   the system places it, unstyled. **Approved**; the note on `.searchable` goes into `spec/conventions.md` beside the
   paragraph on the system's presentations. Whether the pilot adopts the field before its search epic stays the
   pilot's; the recommendation was that it adopts the field with that epic.
4. **The glyph at the end is decoration only** (point 4). **Approved.**
5. **Variants and lines** (point 5): the glyphs on both variants and both values of `lines`. **Approved.**
6. **The glyph's inset and the gap** (point 5): the glyph at the field's horizontal padding; `container.gap` of
   `space.75` at `s` and `space.100` otherwise. **Approved.**
7. **The glyph's color** (point 6): `color.text.secondary` in every state. **Approved.**
8. **The glyph's size** (point 7): the text's own scale. **Approved**, and revised the same day: up to xxxLarge, not at
   the accessibility sizes (below, "Revision: the glyphs stop at xxxLarge").
9. **The search field's announcement** (point 8): the product adds the search-field trait. **Approved.**
10. **The snapshot matrix** (tools, item 6). Proposed: each optional icons option an axis of two values, 144
    combinations on 24 sheets. **Not approved**: that would quadruple the field's references for a decoration. An
    optional icons option is no axis of the generated matrix, which stays as it was, drawn with no glyph; the tools
    make that their rule. The glyphs get hand-written supplementary sheets, marked "not a contract option": leading,
    trailing and both, for framed at `s`, `m` and `l` and for inline, single and multiple lines, at rest, focused,
    disabled and with text entered, plus a long text that reaches the trailing glyph, right to left, and a large text
    size.
11. **watchOS** (point 10): no glyph on the watch until #34, said in the contract's words. **Approved.**

## Measured at implementation

With Xcode 27.1, on macOS 26.7.1 and the iPhone 17 simulator of iOS 26.3, on 2026-11-22:

- **The row.** The style gives each glyph its width and `container.gap` of the field's own room, inside its horizontal
  padding, and draws the glyph there as an overlay aligned on the field's first text baseline, within the fill,
  outline, ring and hit area; with no glyph the field's view is the one it was. A first version set the glyphs beside
  the field in an `HStack(alignment: .firstTextBaseline)`: it drew the same, but on iOS it added a pixel to a multi-line
  field whose microphone reaches higher than its first line, and the overlays leave the system field the only view of
  the row's height. A glyph stands at the field's padding and the field `container.gap` from it, at every
  size of both variants, and right to left the start is at the right (`TextFieldGlyphTests`, within 0.05 pt). The
  overlays are superseded: the second revision (below, "The room is measured in the same layout pass") sets the glyphs
  beside the field in one `Layout`, which draws the same, file for file on macOS.
- **The baseline.** The system field gives its first line's baseline, not its bottom, on one line and on several, on
  macOS and iOS: a glyph's baseline is the field's first baseline, within half a point, the pixel it is rounded to
  (`TextFieldGlyphTests`). The glyphs change neither the field's height nor where its text stands (within 0.05 pt). On macOS the
  baseline also reaches the row through the hold of #113: in the state that hands a field another font's line height,
  every glyph keeps its place (below).
- **The hold of #113 beside a trailing glyph** (`TextFieldLineTests`, 1500 attempts each): framed fields at `s` and
  `m` on one line and on several, a SecureField and inline fields of one line and of several, each with the microphone
  at its end, kept their lines, their sizes and their glyph rows, with fonts made anew 23 times; a field that stays on
  screen kept its lines, its frame and its glyph's place at 2x (fonts made anew 64 times), at 1x left to right (45)
  and at 1x right to left (70); the same fields laid out with the hold and without it, in a process where the state
  cannot arise, were laid out the same. Without the hold (`WESTRON_FIELD_LINE_UNFIXED=1`) the same tests fail: fields
  163 to 347 times off their lines, and the glyph row moving with them, a point up beside a field laid out 17 pt high.
  The second revision (below) put a number sign where the microphone was, and the framed field on several lines was
  at `m` only until the review's findings added one at `s` (below, with the runs since).
- **A tap or a click on a glyph** focuses the field, through the style's hit area (the catalog's
  `TextFieldBehaviorTests`, `testATouchOrClickOnAGlyphFocusesTheField`, 6 pt into each glyph; passed on iOS and on
  macOS). On macOS the class's `testMultilineAndSecureFieldsEdit` fails on this Mac, the text typed into the inline
  notes never arriving, and fails the same on `main`'s code, with no glyph anywhere: it is not this revision's.
- **Assistive technology.** The glyphs are hidden: the catalog's live page, with a search field, exposes no image,
  and the search field is a search field, named "Search", by the product's trait and label (`TextFieldBehaviorTests`;
  a package test's window exposes no accessibility elements, so this is checked in the app).
- **Pixels.** A render of every component's matrix on macOS before the change and after it: 256 images the same file
  for file, and 88 added, the text field's supplementary sheets of glyphs (`glyph-leading`, `glyph-trailing`,
  `glyphs-both` on every generated sheet, `glyphs-long-text` and `glyphs-right-to-left` at `m`).
- **The accessibility audit on iOS** reports "Text clipped" on the single-line fields with a glyph at the end: at
  accessibility5, where the glyphs and the padding leave the text too little room and "Search" and "Groceries" scroll
  in the field; and at the default size on the search field, with the detail "may be clipped at larger Dynamic Type
  sizes", which it does not report with the magnifier alone (measured with the trait removed and with text entered: the
  same; with the microphone removed: none). The approver took it for a defect; the revision below removed it, with no
  suppression.
- **At the largest text size on a phone**, the glyphs scale with the text, as approved, and so does the padding: a
  framed field at `l` with both glyphs, alone across an iPhone 17 at accessibility5, leaves its text about a third of
  the field's width, and "Milk" and "Apples" break inside the word (the supplement `glyphs-both`, size `l`, lines
  `multiple`, accessibility5). A field of one line scrolls its text instead. The approver took this for a defect, not
  the scale's cost: below, "Revision: the glyphs stop at xxxLarge".

## Revision: the glyphs stop at xxxLarge

Decided on 2026-11-22 (#115) by the coordinating agent under the owner's delegation of the phase's contracts
(decisions/0014), after the sheets at accessibility5: in `glyphs-both`, size `m`, one line, "Groceries" read "Gr…"
between two glyphs as large as its letters. Answer 8 above, the text's own scale, stands up to the largest text size
that is not an accessibility size, and no further:

- **What changes.** A glyph and its gap grow with the person's text size up to xxxLarge. At accessibility1 to 5 the
  glyph, its gap and the room the field leaves them are what they are at xxxLarge; the field's text grows on, and it
  still stands on the first line's baseline. The field's own horizontal padding is not this revision's: it grows as it
  did, as TextField's has since #30.
- **Why.** The glyph is decoration, and inside a field the width is what the person types into: at the accessibility
  sizes every point a glyph takes is a point less of what they read and write, and the field already tells what it is
  by its label and its text. design-language/07 says an icon next to text takes that text's role and scales with it;
  this is a named exception to that rule, recorded there in one sentence that points here.
- **On Apple.** Each glyph and its gap are one view (`TextFieldGlyph`) under `.dynamicTypeSize(...xxxLarge)`, set on
  them and not on the field, and the field reserves the width that view measures. macOS has no Dynamic Type, so
  nothing changes there: a render of every component's matrix on macOS before the revision and after it is the same
  file for file in TextField's sheets.
- **Tests.** `TextFieldGlyphTests` lays a field out at large, xxxLarge and accessibility1, 3 and 5, on both variants
  and both values of `lines`: at the accessibility sizes each glyph's size and the room beside the text equal
  xxxLarge's within 0.05 pt, and on iOS the field's lines are higher than at xxxLarge, while up to xxxLarge the glyph
  grows.
- **What the text gets at accessibility5** (iPhone 17, the supplements `glyphs-both` and `glyph-leading`): a glyph and
  its gap take about 36 pt beside the text, as at xxxLarge. A framed field at `l` on several lines
  with both glyphs draws "Milk" and "Apples" whole, a word to a line. A framed field at `m` on one line, 366 pt
  across, leaves its text about 180 pt with both glyphs, 216 with one, 249 with none: "Groceries", about 213 pt there,
  reads "Groce…" with both and "Groceri…" with the magnifier alone, at rest, and scrolls while it is edited, as a field
  without glyphs does with a longer word. Most of what the text loses there is the field's own horizontal padding,
  about 59 pt a side at accessibility5, which this revision leaves as it is.
- **The accessibility audit** on iOS, the five tests over `text-field`, `text-field-glyphs`, `text-field-behavior`,
  `text-field-focus-framed` and `text-field-focus-inline`, passes with no "Text clipped" and no suppression added, at the
  default size and at accessibility5.
- **The glyphs' catalog page.** The glyph samples left the `text-field` entry for an entry of their own,
  `text-field-glyphs`. On the iPhone's screenful that showed both "multiple lines" and the glyphs' samples, six
  multi-line fields at once, the audit's contrast analysis did not complete ("Audit failed to complete in time", -56)
  in any theme, twice in a row each time, after the simulator was restarted too. Measured on that screenful: four
  multi-line fields are audited in 0.3 s; with one or two more it gives up at 15 s, whether they draw glyphs, draw
  none, or hold another text, low on the screenful or in its middle. The cause, as with Button's `trash` (#23), is not found.
- **Right to left on macOS.** A multi-line field puts its second line at the left, and a long single line shows its
  end; the same fields drawn without glyphs do the same (the `glyphs-right-to-left` sheets rendered with no glyph), so
  it is the system field's, not the glyphs'.
- **Editing beside a glyph** (`TextFieldLineTests`, `anEditedFieldWithAGlyphKeepsItsEditing`, 1500 attempts): the two
  long-lived fields with the microphone at their end (a number sign since the second revision, below), each edited in turn with text selected and then while an input
  method composes, kept their text, selection, marked text and lines, with their own fonts made anew 40 and 13 times
  while edited and no runtime warning of SwiftUI's but the canary's. Without the hold, 140 times off their lines.

## Second revision: what a glyph draws, and where

Decided on 2026-11-22 (#115) by the coordinating agent under the owner's delegation of the phase's contracts
(decisions/0014), after the review and the accessibility audit of the first revision. It changes answers 3, 4 and 8
above and the revision before it where they say otherwise; the record above stays as it was asked and answered.

- **A glyph names what the field is for, never an action.** The magnifier of a search field, a calendar on a date's
  field, a number sign on a tag's name: decoration that says what the field holds. A glyph that draws an action the
  person could expect to perform is not this option: a microphone, a clear mark, a chevron. An inert microphone beside
  the keyboard's own dictation key tells the person they can press it, and Voice Control, which shows the names of
  what can be pressed, cannot act on it. Such a glyph waits for a slot for a control, which this revision does not
  add. So the pilot's search field is the magnifier alone in westron; its microphone, inert in the pilot too (above,
  "What the pilot draws and does"), stays the pilot's until that slot exists (decisions/0014's row, changed to say
  so). The contract's example of `trailingIcon` is a number sign at the end of a tag's field (`hash`, the registry's
  "A number sign"); the catalog's samples and supplements, the package tests and `TextFieldLineTests` draw it where
  they drew the microphone, and the live page's click on a glyph at the end is on a tag field's number sign.
- **A search field's prompt is in `color.text.placeholder`.** A search field's only visible name is its placeholder,
  and the system's placeholder color, which a TextFieldStyle cannot change (the contract's `platforms.apple`),
  measured 1.69:1 against the field's fill in light and 2.43:1 in dark on iOS. The recipe, in the contract, the
  catalog and `.claude/rules/apple.md`, now colors the prompt itself: `prompt:
  Text("Search").foregroundStyle(.text.placeholder)`. Measured from the catalog's `text-field-glyphs` page on the
  iPhone 17 simulator of iOS 26.3, the darkest pixel of "Search" against the fill: 4.74:1 in light, 7.43:1 in light
  high contrast, 5.03:1 in dark and 7.78:1 in dark high contrast (the search field is drawn on that page, not in the
  snapshot matrix, whose fields keep the prompt as a product leaves it). macOS ignores a prompt's color (the
  contract's `platforms.macos`), so there the placeholder stays the system's, the open point of the contract's
  decisions/0001.
- **At the accessibility sizes a glyph is centred on the first line.** Held at xxxLarge (the revision before this),
  a glyph is smaller than its text at accessibility1 to 5, and on the baseline it sat low beside the line, like a
  subscript (the `glyphs-both` sheets at accessibility5). There it is now centred on the box of a line of the field's
  text role at the text's size, set on the field's first baseline; up to xxxLarge it stands on the baseline as before.
  On Apple the row places a hidden line of that role beside the field at those sizes only, and macOS, which has no
  Dynamic Type, never centres. Measured: an iOS render of TextField's sheets with the style before this revision and
  after it differs in 132 sheets, every one a glyph supplement at accessibility5, each only where its glyphs are; the
  other 184, those sheets at every other size and theme among them, are the same files. On several lines the glyphs
  stay centred on the first line (`glyphs-long-text`, `lines: multiple`, at accessibility5). `TextFieldGlyphTests`
  checks both variants on one line and on several at large, xxxLarge and accessibility1, 3 and 5: centred within half a
  point of the line's middle at the accessibility sizes, higher than the baseline would set it, and on the baseline
  below them.
- **One field whether there are glyphs or not.** The style drew the field in one view without glyphs and in another
  with them, so a product that added the first glyph or removed the last one while the person typed made SwiftUI build
  a new system field, and the person lost the field mid-word (the review's probe on macOS: from no glyph to one, a new
  field and no first responder). The row is now one layout in every case, the system field always its first view,
  with no room and no glyph when there is none. `TextFieldGlyphIdentityTests` focuses a field and changes its glyphs,
  none to leading, leading to none, none to both, both to none and leading to both: the same `NSTextField` on macOS
  and `UITextField` on iOS, still the first responder. With the style before this revision four of the five fail on
  both platforms (leading to both passed).
- **The room is measured in the same layout pass.** The field's room for each glyph was a width the glyph reported
  after it was laid out, a round trip through state. The row is now a `Layout` that measures each glyph and offers the
  field the rest in one pass, sizes the row by the field alone (so a glyph that reaches above the first line adds no
  height, as the overlays it replaces did not), and gives the row the field's baselines. No frame of a field under
  its glyph was observed with the old round trip either: after a single layout pass, before the run loop turned, the
  field already stood past its glyph on macOS and iOS (`TextFieldGlyphIdentityTests`, the first layout, passes with
  both styles), so the change removes a dependency on SwiftUI applying that state before it draws, not an observed
  defect. A render of every component's matrix on macOS with the overlays and with the row is the same, file for file.

## The review's findings

Applied on 2026-11-22 (#115) after the review of the second revision, contract text first. With Xcode 27.1, on macOS
26.7.1 and the iPhone 17 simulator of iOS 26.3:

- **How the row is described.** The contract and the comments said a glyph was drawn "over the system field's own
  room", the overlays the second revision replaced. They now say what the code does: the glyphs stand beside the
  system field in one layout that offers the field the row's width less each glyph and its gap, sizes the row by the
  field alone and stands each glyph on the field's first text baseline, inside the fill.
- **The glyph's image scale is fixed.** `TextFieldGlyph` set none, so a context's `.imageScale(.large)` resized the
  glyph and the room the field leaves it. It now sets `.imageScale(.medium)`, the text's own scale, as Button and Chip
  set their icons'; the contract says a context's scale does not change the glyph. `TextFieldGlyphTests`
  (`imageScaleIsFixed`) lays both variants out under `.imageScale(.small)` and `.large` against a field under none:
  the same glyphs, field and room within 0.05 pt; with the line taken out it fails in every case.
- **The gap itself is tested.** `glyphsStopAtTheLargestTextSize` measured each glyph's room, its width and gap
  together, so a gap that never scaled would have passed. It now also asserts the gap, the field's edge less the
  glyph's: equal to xxxLarge's at accessibility1, 3 and 5 on both platforms, and on iOS more than a point wider at
  xxxLarge than at large.
- **The gap on inline.** A `TextFieldStyle` cannot read its context's text style: SwiftUI's font in the environment is
  opaque, and `.textRole(_:)` sets no value of its own. So on Apple an inline field's gap scales on body's curve, the
  style's fallback, not on its context's (point 5 said "the field's text style"); the contract's `platforms.apple`
  says so. The glyph itself is in the context's role.
- **Mirroring.** Whether a glyph mirrors right to left is the platform's, per symbol, as for any icon: in the
  `glyphs-right-to-left` sheets the magnifier's handle is at the lower right in both directions, on macOS and on iOS.
  The contract says so.
- **The cap, platform-neutral.** The contract names the cap as the largest text size that is not an accessibility
  size, the sizes a platform sets apart above its standard ones for large text, with Apple's mapping (xxxLarge, and
  accessibility1 to 5); a platform without such sizes caps nothing.
- **A glyph taller than its line.** Measured over the whole registry in `body.regular` at medium scale, at large and at
  xxxLarge (`TextFieldGlyphTests`, `aGlyphTallerThanItsLine`): on macOS, beside a line of 16 pt, the trash is 16.5 pt
  and the wrench 18, the rest no taller than the line. The field does not grow for such a glyph: the row is the
  field's height on both variants, at every size, on one line and on several, and on framed the glyph stays inside the
  field, in its padding. On inline, which has no padding, it reaches past the field's frame by what it exceeds. The
  contract says so rather than that no glyph is taller.
- **A search field's prompt in the references.** A supplement, `search-prompt`, draws the contract's search recipe
  empty, its prompt in `text.placeholder`, on iOS only (`onlyOn`), since macOS ignores a prompt's color: the
  references now hold the prompt's color, which until now only the catalog page showed.
- **The generated doc comment.** The generator copies an option's first sentence into the overload's documentation, so
  both options' first sentences now say that a glyph names what the field is for, never an action.
- **The hold beside a glyph at `s`.** `TextFieldLineTests` had a framed field of several lines with a glyph only at
  `m`; one at `s` is added, so the contract's sentence on framed fields at `s` and `m`, on one line and on several,
  holds. The runs with it, 1500 attempts each: the fields with a glyph kept their lines, sizes and glyph rows with
  fonts made anew 42 times; a field that stays on screen at 2x (74), at 1x left to right (103) and right to left (45);
  without the hold, 100 times off their lines.
