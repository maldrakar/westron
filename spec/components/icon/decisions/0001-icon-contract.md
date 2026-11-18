# 0001. The Icon contract

Date: 2026-11-18. Status: draft for approval (#28). The owner answered the interview on 2026-11-18. This record keeps
three things apart: what the owner answered, what the documents had already decided, and what the agent proposes on
top of both, which is still to confirm.

## Context

Both pilot screens draw icons (decisions/0006): the lists' glyphs, chevrons and the bar's glyphs on
`todo-app/lists-screen`, the status, meta and card glyphs on `todo-app/list-screen` (`research_notes/pilot-inventory.md`,
section 7). westron already has the names, the registry and their Apple spelling: `spec/icons/icons.yaml`,
`Westron.Icon` generated from it, and `Image(_: Westron.Icon)` and `Label(_:icon:)` in
`platforms/apple/Sources/WestronUI/TokenAdapters.swift`, which the parity lint lists as reviewed adapters. Button binds
its icon's typography to its label's role (`icon.font`). What is missing is a contract, so that the web and GTK have
something to be checked against and icons a snapshot matrix.

## What the owner answered

### Weight

- Considered: (a) the icon takes its size and its weight from the text role beside it; (b) one weight for every chrome
  glyph; (c) by role, except glyphs in tiles, always medium.
- **Chosen: (a).** This answers design-language/07's open question 4. Without text, the icon takes its control's label
  role, as chapter 07 already says.

### Screen readers

- Considered: (a) a bare `Image(icon)` is decorative and hidden, and a meaningful standalone icon is made with a label,
  `Image(icon, label: …)`; (b) the system's default label for the symbol; (c) a label always required.
- **Chosen: (a).** `accessibility.label` is `optional`, and the description says when an icon has one.

### Scale

- **Chosen: the platform's relative scale, small, medium or large, recorded as a system option.** On Apple it is
  SwiftUI's `Image.Scale` (`.imageScale(_:)`), so `platforms.apple.systemOptions` names it and no westron enum is
  generated.

### Color

- **Chosen: no option.** The icon takes the context's color (`foregroundStyle` on Apple). The contract lists the
  roles an icon may take, from design-language/07:94–99: the color of the text it goes with,
  `color.status.<name>.icon`, `color.category.<name>.icon`, `color.icon.tertiary`, and the on-fill color of a solid
  fill.

## Already decided by the documents

These are not decided again here; the contract states them and cites the source.

| What | Source |
|---|---|
| Names say what the glyph draws; a released name is never renamed or removed; an unknown name draws the default, `bullets` | design-language/07:28–41, decisions/0011:50–54 |
| The registry is the only place a name is spelled; the Apple generator writes `Westron.Icon` from it | 07:39–41, decisions/0011:53–54 |
| Standard actions take the platform's glyphs, domain icons westron's own set; SF Symbols stay on Apple | 07:10–26, 07:59–79, decisions/0011:45–57 |
| Next to text an icon takes the text's role; without text, its control's role; it never has a size of its own; the relative scale is the only size choice | 07:104–118 |
| One color, outline at rest, a filled form marks a state | 07:92–100 |
| An icon is never the only signal; a decorative icon beside its own label is hidden | 07:101–102, 08:92–93 |
| A status glyph takes `color.status.<name>.icon`, or `on-fill` on a solid fill | 07:43–57 |

## Proposed, to confirm

The answers and the documents left these points open. Each is the agent's proposal, with its reason.

| # | Proposal | Reason |
|---|---|---|
| P1 | Strategy `extension-on-system-control` with `base: SwiftUI.Image` | SwiftUI's `Image` has no style modifier (no `imageStyle`; a macOS test holds this), and westron adds initializers to it, not a type (decisions/0003, point 1) |
| P2 | The glyph is an option, `glyph: { type: icons }`, whose values are the registry's names (below, "The schema") | The names are a closed set that must be the same on every platform (AGENTS.md, rule 4), and the registry already holds them |
| P3 | `glyph` has no default | Every use names its glyph; the registry's `default` is what draws for an unknown name, not what a use without a name draws |
| P4 | `scale` is an enum option with the values `small`, `medium`, `large` and the default `medium`, which Apple names as `SwiftUI.Image.Scale` | A system option must be an option of the contract; its values follow chapter 07's words and `Image.Scale`'s cases; `medium` is the text's own size |
| P5 | The accessible label is the slot `label`; with one, the role is `image` | The schema requires a role; `image` is what the icon is announced as when it has a label |
| P6 | On Apple the glyphs stay SF Symbols now; westron's own glyphs become custom symbols with phase 6, when chapter 07's open question 1 is answered | No pilot screen needs a domain glyph that SF Symbols lacks; the SwiftDraw spike waits for one (07:68–70) |
| P7 | Deferred for lack of a pilot consumer (AGENTS.md, rule 6): the neutral status glyph (07, question 2), smaller masters (question 3), and the license of westron's glyphs (question 5) | No pilot screen draws them |
| P8 | The list's tile, an icon inside a shape, is a phase-4 component, not an option of this one | It is a shape with its own size and colors (07:113–114) |
| P9 | watchOS draws icons as the other OSes do | Nothing in the documents or the pilot differs there |
| P10 | Web, provisional: westron's glyph as an inline SVG at 1em in `currentColor`; GTK, provisional: a stock `GtkImage` with a symbolic icon | They take the size and color of the context as SF Symbols do, which is what the owner chose for Apple |
| P11 | `Image(_: Westron.Icon)` becomes decorative (hidden), and `Image(_:label:)` is added, at implementation | The owner's screen-reader answer; today's adapter keeps the symbol's default label |

## Open points

- **What the implementation must show before the second gate:** whether an SF Symbol takes the weight of a custom
  font's role, `heading.*` in Onest through `Font.custom(_:size:relativeTo:)`, as it takes the system font's weight.
  If it does not, an icon beside a heading needs its weight set from the role, and the contract records how.

- **chapter 07's open question 1** (which names are domain icons) stays open; P6 keeps Apple's glyphs as they are.
- **The API shape.** The tools do not derive an initializer-shaped API from a contract yet (below), so the parity lint
  keeps checking `Image(_:)` and `Label(_:icon:)` as reviewed adapters until they do.

## The schema

- **An option whose values are the icon registry's names,** `glyph: { type: icons }`.
  - Considered: (a) a registry-valued option, in the spirit of the token-valued one; (b) an enum listing the 36 names,
    which would drift from the registry and be a second spelling of every name, which chapter 07 forbids ("Nothing
    else spells a name"); (c) no option, the glyph being the icon's content like a text's string, which would leave
    the names out of the contract and give the snapshot matrix no axis; (d) `type: tokens` with a group, which is
    wrong: the registry is not a token group, and its names are not tokens.
  - **Proposed: (a), with no field beside the type.** There is one registry, `spec/icons/icons.yaml`, so the option
    names none; and since it has no default (P3), `spec check` needs no registry to check it: `tools/westron icons
    check` validates the registry itself. Like a token option, it is not named by constraints, cases, bindings by
    value, platform restrictions or `systemOptions` yet.
- **`SwiftUI.Image` in `SystemStyles.withoutStyle`,** checked on macOS against SwiftUI's interface: no `imageStyle`.
- An approved contract with such an option is reported as not supported by the generator, the snapshot matrix and the
  parity lint, with the place and the reason, rather than generating something wrong.

## What the tools need before an approved Icon is generated

- **The conventions** (`spec/conventions.md`): the API of an extension whose option is `icons` is initializers of the
  base, `Image(_: Westron.Icon)` and `Image(_: Westron.Icon, label:)`, not a modifier; `scale` stays the system's
  `.imageScale(_:)`.
- **`AppleComponents.Extension`** (`tools/Sources/WestronTools/Contracts/AppleComponents.swift`): a second shape for
  an extension, initializers taking `Westron.Icon` (the type `AppleIcons` generates), with the system option allowed
  beside it; today it requires one token option and throws for `icons`.
- **The parity lint** (`APIParity.expected`): expect those initializers on `Image` from the contract, and move
  `Image.init(_:)` out of `APIParity.adapters` once the contract owns it (`Label.init(_:icon:)` can stay an adapter).
- **The snapshot matrix** (`SnapshotMatrix`, `AppleSnapshotMatrix`): an axis of the registry's names in its order, read
  with `IconRegistry.load`, its cell typed `Westron.Icon`; `scale` as a system-option axis; and a hand-written
  `IconMatrixCell` in the catalog.
