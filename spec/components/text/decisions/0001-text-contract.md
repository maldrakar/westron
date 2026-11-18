# 0001. The Text contract

Date: 2026-11-18. Status: accepted. The owner answered the interview and, on 2026-11-18, approved the contract (#27):
P1–P6 as proposed, Geist Mono Bold for `code.strong` under Bold Text, and the Bold Text weights as a rule of the Apple
adapter rather than tokens. Whether the `Text` twin follows Dynamic Type and Bold Text is left to the implementation
to show (below, "Open points").

## Context

Both pilot screens set every word in a text role (decisions/0006): `todo-app/lists-screen` and
`todo-app/list-screen`. The pilot has seventeen roles of its own (`research_notes/pilot-inventory.md`, section 3), and
it cannot delete them until westron covers each one (decisions/0006, "Consequences").

westron already has the roles and their Apple spelling. The seventeen tokens are in
`tokens/semantic/typography.tokens.json` (decisions/0013), `.textRole(.heading.large)` and `Font(.body.regular)` are
in `platforms/apple/Sources/WestronUI/TokenAdapters.swift` (decisions/0011, `.claude/rules/apple.md`), and the
parity lint lists them as reviewed adapters. What is missing is a contract. Without one, the web and GTK have
nothing to be checked against, and text has no snapshot matrix. Chapter 03 of the design language also left four
open questions, three of which this contract answers.

SwiftUI's `Text` has no style protocol and no style modifier, so neither of the schema's two strategies described
it. This contract adds a third, `extension-on-system-control`, and an option whose values are the tokens of a group,
so that the roles are not listed twice (below, "The schema").

## Decisions

### The API shape

- Considered:
  - a contract over the accepted spelling, `.textRole(.heading.large)` and `Font(.body.regular)`;
  - a generated flat enum, `.textRole(.headingLarge)`;
  - no contract, the roles staying tokens and adapters only;
  - westron's own `Text` type.
- **Chosen: a contract over the accepted spelling.** The role is `Westron.TextRole`, the accessor the token
  generator already writes, so its names are the tokens' on every platform.
- The flat enum was rejected: it would be a second set of names beside the tokens', and it would revise
  decisions/0011 and 0013. No contract was rejected: the web and GTK would have nothing to be checked against, and
  text would have no snapshot matrix. An own `Text` type is ruled out by decisions/0003: the system view exists.

### Color

- Considered: the role sets font and tracking only; an `ink:` argument; the role setting `color.text.primary`.
- **Chosen: the role sets font and tracking only.** The product sets the color with a color role,
  `.foregroundStyle(.text.secondary)`, as it does for any view. A role that set a color would fight the product's
  own `.foregroundStyle`, and an `ink:` argument would repeat the color roles in a second API.

### Tracking

- Considered: a percentage of the size the font is drawn at; fixed points from the token, as today.
- **Chosen: a percentage of the actual size, on every platform and at every text size.** This answers chapter 03's
  open question 1. The percentage is the token's `letterSpacing` over its `fontSize`: −1 % for `heading.large`,
  `heading.medium` and `heading.small` (−0.34 of 34, −0.2 of 20, −0.17 of 17), +6 % for `heading.overline` (0.72 of
  12), 0 for the rest. So the tokens do not change: DTCG 2025.10 has no `em` for a dimension, and the base size and
  its tracking stay the reference.
- Fixed points were rejected: at accessibility5 a heading's −0.34 pt is a fraction of what it is at the default size,
  and on the Mac's smaller sizes it is relatively larger, so the face would not look the same at every size.

### Bold Text

- Considered: a role in Onest or Geist Mono moves up one weight, westron adding the weights that needs; only the
  weights already shipped; ignoring Bold Text.
- **Chosen: one weight up, with the fonts it needs.** This answers chapter 03's open question 2. With the system's
  Bold Text on (`legibilityWeight == .bold` on Apple):

  | Role | Weight | Under Bold Text | Font file |
  |---|---|---|---|
  | `heading.large`, `heading.medium` | Onest Bold | Onest ExtraBold | **new**: `Onest-ExtraBold.ttf` |
  | `heading.small`, `heading.overline` | Onest SemiBold | Onest Bold | shipped |
  | `code.regular` | Geist Mono Regular | Geist Mono SemiBold | shipped |
  | `code.strong` | Geist Mono SemiBold | Geist Mono Bold | **new**: `GeistMono-Bold.ttf` |
  | the system font's eleven roles | their weight | the system's own heavier weight | none: the system font does it |

- The owner named these steps: Onest SemiBold → Bold, Bold → ExtraBold, and Geist Mono Regular → SemiBold, which
  skips Medium and needs no file. The owner named one new font, Onest ExtraBold.
- **`code.strong` under Bold Text draws Geist Mono Bold,** the owner's answer at approval.
  - Considered: (a) Geist Mono Bold, one step up, as Onest SemiBold goes to Bold, at the cost of a second new font
    file, `GeistMono-Bold.ttf`, about 100 KB; (b) Geist Mono SemiBold, as without the setting, with no second file.
  - **Chosen: (a).** The agent's reason, given with the options, for the owner's choice: the two code roles stay one
    weight apart under Bold Text, `code.regular` in SemiBold and `code.strong` in Bold. With (b) they would draw the
    same weight, since `code.regular` moves up to SemiBold, and emphasis inside code would show only by its color, if
    the product gave it one.
- **The steps are a rule of the Apple adapter, not tokens,** the owner's answer at approval: a role in Onest or Geist
  Mono moves one weight up under Bold Text, as the table lists, as the system font does by itself.
  - Considered: the rule in the adapter; a primitive `font.weight.extrabold` and a Bold Text weight token per role.
  - **Chosen: the rule.** The agent's reasons, given with the options, for the owner's choice: `font.weight` keeps
    its four weights (regular, medium, semibold, bold), so Onest ExtraBold has no token, and no role gets a second
    weight. Bold Text is an Apple setting; the web has no counterpart (`platforms.web`).
- **Today the package ships four instances:** Onest SemiBold and Bold, Geist Mono Regular and SemiBold
  (`platforms/apple/Sources/WestronUI/Fonts`, about 100 KB each). The implementation adds Onest ExtraBold (800) and
  Geist Mono Bold (700), cut as the others are, from the variable font with fontTools (decisions/0011). Both weights
  exist: Google Fonts serves both families at every weight from 100 to 900 (checked on 2026-11-18). The SIL OFL 1.1
  of each allows the instance, and neither license reserves a font name (decisions/0011), so a new instance keeps its
  name, `Onest-ExtraBold` or `GeistMono-Bold`.
- This implies a revision of decisions/0011 when the fonts are added: six instances instead of four, about 200 KB
  more. It is made with the fonts, not now.
- Only the shipped weights was rejected: the Bold headings would not move, and the HIG asks a custom font to honor
  Bold Text. Ignoring the setting was rejected for the same reason.

### watchOS

- Considered: every role in the system font, in the system text styles; Onest and Geist Mono at the token's size, as
  today.
- **Chosen: the system font for every role on the watch,** as the research suggests for the watch's screen
  (`research_notes/type-and-icons.md`, 3.1). This answers chapter 03's open question 4. The contract records it in
  `platforms.apple.watchos`.

### Heading semantics

- Considered: the product marks headings; a `heading.*` role adding the header trait.
- **Chosen: the product.** A role never adds `.isHeader`, and `accessibility.role` is `text`. A heading role is a
  look, and a screen's structure is the product's: the title of a card in a list may be `heading.medium` without
  being a heading a screen reader jumps to, and an `<h2>` on the web may be set in another role.

### Tabular digits

- Considered: a role, an option of a role, a property of every role that shows numbers; nothing now.
- **Chosen: nothing now.** No pilot screen needs them (AGENTS.md, rule 6): the pilot's counts are proportional
  (`research_notes/pilot-inventory.md`, section 3). A product that needs them uses the system's `.monospacedDigit()`.
  **Chapter 03's open question 3 stays open.**

### The roles

- Considered: all seventeen roles of the tokens; only the fifteen the pilot uses.
- **Chosen: all seventeen, one name set with the tokens.** The contract does not list them: its option `role`
  takes its values from the token group `typography` (below), so a role added to or removed from the tokens is added
  to or removed from the contract with it. Today they are `heading.large`, `heading.medium`, `heading.small`,
  `heading.overline`, `body.regular`, `body.strong`, `callout.regular`, `callout.strong`, `subheadline.regular`,
  `subheadline.medium`, `subheadline.strong`, `footnote.regular`, `footnote.medium`, `footnote.strong`,
  `caption.medium`, `code.regular` and `code.strong`.
- Only the fifteen was rejected: the two code roles would be tokens without a contract, and westron serves technical
  products too (decisions/0011).

## Proposed and confirmed

The answers above left these points open. The agent proposed each one, with its reason and its source, and the owner
confirmed P1–P6 as proposed on 2026-11-18, when approving the contract.

| # | Proposal | Reason | Source |
|---|---|---|---|
| P1 | No states. Truncation and line limits are the platform's own (`.lineLimit`, `.truncationMode` on Apple); chapter 03's rules stay: running text wraps, a one-line label may truncate with an ellipsis when its full text is reachable | A text does not react to input; the rules on fitting are already the design language's | design-language/03, "Capitals, numbers and fitting" |
| P2 | Beside the `View` modifier, the implementation adds `Text.textRole(_:) -> Text`, so that a part of a text keeps its own role and tracking: inside Text interpolation, `Text("\(title) \(Text(count).textRole(.footnote.medium))")`, and in `Text + Text`, which OS 26 deprecates for interpolation | A `View` modifier returns `some View`, which cannot go inside another `Text`; SwiftUI's own `font(_:)` and `tracking(_:)` have a `Text` twin for this | the SwiftUI interface of Xcode 27.1 |
| P3 | Line height on Apple comes from the font: the system font's from its text style, Onest's and Geist Mono's from their metrics, all following Dynamic Type | Already decided in chapter 03; the tokens' line heights are for the web and GNOME | design-language/03:99-101 |
| P4 | The web is planned, with a provisional direction: a CSS class per role on the native element the product chooses, `letter-spacing` in `em`. GTK is a style class per role on `GtkLabel`, provisional until phase 7 | The product picks the element, so that a heading can be an `<h1>`; no single element is the web's base, so its strategy waits for #40. On GTK a class on the stock widget is how Button is styled too | decisions/0003, the Button contract's web and GTK entries |
| P5 | On watchOS a role keeps its weight in the system font, the code roles take the system's monospaced design, and the tracking still applies as a percentage of the watch's size | The owner chose the system font; weight and tracking are what is left of a role's look, and code needs a monospaced face | the owner's watchOS answer |
| P6 | The text is its only slot, `label`, and the contract requires no accessible label beyond it | A text reads itself | chapter 08 |

## Open points

- **P2 and the environment.** A function that returns `Text` cannot read the environment, so `Text.textRole(_:)`
  cannot see the Dynamic Type size or the Bold Text setting by itself: `Font.custom(_:size:relativeTo:)` still scales
  the font, but the tracking in points and the heavier instance are chosen when the `Text` is built. The
  implementation must show, in the catalog at accessibility5 and with Bold Text on, whether the `Text` twin follows
  both. The contract was approved before it showed it, so if the twin does not follow both, the contract is changed
  first, as decisions/0005 asks: it records the difference in `platforms.apple`, or P2 is dropped.
- **Tabular digits** stay open (chapter 03, question 3).
- **Headings on GNOME** stay open for phase 7 (design-language/09, question 4): whether a heading role keeps or
  replaces libadwaita's title classes.

## The pilot's roles in westron's

For the pilot's move, not a requirement of this contract: each of the pilot's roles (`DS/Font.swift`, the inventory's
section 3) and the westron role with the same text style and weight. The pilot's heavy rounded titles become Onest,
at westron's weight.

| Pilot role | Text style, weight | westron role |
|---|---|---|
| `largeTitle` | largeTitle, heavy, rounded | `heading.large` |
| `emptyScreenTitle` | title3, heavy, rounded | `heading.medium` |
| `sectionTitle` | headline, heavy, rounded | `heading.small` |
| `areaCaption` | caption, heavy, rounded, capitals | `heading.overline` |
| `rowTitle`, `search` | body, regular | `body.regular` |
| `rowTitleEmphasized` | body, semibold | `body.strong` |
| `nestedRowTitle` | callout, regular | `callout.regular` |
| `nestedRowTitleEmphasized` | callout, semibold | `callout.strong` |
| `count`, `notes` | subheadline, regular | `subheadline.regular` |
| `addRow` | subheadline, medium | `subheadline.medium` |
| `barLabel` | subheadline, semibold | `subheadline.strong` |
| `hint` | footnote, regular | `footnote.regular` |
| `areaLabel` | footnote, medium | `footnote.medium` |
| `pill` | footnote, semibold | `footnote.strong` |
| `meta` | caption, medium | `caption.medium` |

Seventeen pilot roles become fifteen westron roles: `rowTitle` and `search` share `body.regular`, `count` and `notes`
share `subheadline.regular`. The pilot uses neither code role.

## The schema

- **A third strategy, `extension-on-system-control`.** The base, `SwiftUI.Text`, is a system view with no style
  modifier (SwiftUI declares no `textStyle`), so westron adds extensions to it and no type (decisions/0003, point 1).
  `own-component` would claim a type westron does not build, and `style-on-system-control` a style that cannot go on
  `Text`. `spec check` holds the strategy to its base: on Apple the base is one of `SystemStyles.withoutStyle`, a base
  with a style modifier takes a style, and a style never goes on a base of `withoutStyle`.
- **An option whose values are tokens,** `role: { type: tokens, group: typography }`. Its values are the group's
  tokens by their path after it, the names `.textRole(.heading.large)` already uses. `spec check` reads them from
  `tokens/`: the group exists and is a group, its tokens are semantic, exist in every mode and are of one type, and a
  default is one of them.
  - Considered: an enum listing the seventeen names, which could drift from the tokens and cannot spell
    `heading.large`, since a name has no dot; an enum with camelCase names and a binding by value to the tokens, which
    is the flat enum the owner rejected.
- **At approval: the API hand-written and held to the contract, the matrix generated** (spec/conventions.md,
  "Extensions of a system view"). No API is generated. The modifier stays hand-written:
  its name and its argument come from the option's token accessor, `Westron.TextRole` → `.textRole(_:)`, so the
  contract names neither. The API parity lint expects it from the contract, on `View` and as the `Text` twin, and the
  snapshot matrix enumerates the seventeen roles from `tokens/` (`WestronCatalog/Generated/Text+Matrix.swift`).
  - Considered: generating the signature into `WestronUI/Generated/`, which would forward to a hand-written body and
    declare the `Text` twin a second time; naming the modifier and the accessor in the contract, which repeats what
    the token accessor already says.

## Consequences

- At approval, design-language/03 takes the answers to its open questions 1, 2 and 4, and keeps 3 open.
- At implementation, decisions/0011 is revised for the two new font instances, Onest ExtraBold and Geist Mono Bold,
  and `.textRole(_:)` computes the tracking from the drawn size and picks the heavier instance under Bold Text.
- The parity lint expects `.textRole(_:)` from the contract, no longer as a reviewed adapter; `Font.init(_:)` stays
  one, since it turns a token into a font and adds no modifier. The `Text` twin is checked once it is declared, and
  required once it is in WestronUI (`APIParity.pendingTwins`).
