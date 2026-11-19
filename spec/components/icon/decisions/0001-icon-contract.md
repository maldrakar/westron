# 0001. The Icon contract

Date: 2026-11-18. Status: approved on 2026-11-19 under the owner's delegation of 2026-11-18 (#28), pending the owner's
confirmation. The owner answered the interview on 2026-11-18. This record keeps apart what the owner answered, what the
documents had already decided, what the agent proposed, and what the coordinator decided under the delegation when the
implementation showed the draft's Apple API could not be built ("The Apple view"). Every proposal and every decision
under the delegation stays marked as such, for the owner to confirm.

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
| P1 | ~~Strategy `extension-on-system-control` with `base: SwiftUI.Image`~~ **Superseded at implementation** by an own view, `own-component`, `form: view` ("The Apple view") | SwiftUI's `Image` has no style modifier (no `imageStyle`; a macOS test holds this), so westron would add initializers to it, not a type (decisions/0003, point 1); but no initializer of an `Image` of a symbol can hide it or name it |
| P2 | The glyph is an option, `glyph: { type: icons }`, whose values are the registry's names (below, "The schema") | The names are a closed set that must be the same on every platform (AGENTS.md, rule 4), and the registry already holds them |
| P3 | `glyph` has no default | Every use names its glyph; the registry's `default` is what draws for an unknown name, not what a use without a name draws |
| P4 | `scale` is an enum option with the values `small`, `medium`, `large` and the default `medium`, which Apple names as `SwiftUI.Image.Scale` | A system option must be an option of the contract; its values follow chapter 07's words and `Image.Scale`'s cases; `medium` is the text's own size |
| P5 | The accessible label is the slot `label`; with one, the role is `image` | The schema requires a role; `image` is what the icon is announced as when it has a label |
| P6 | On Apple the glyphs stay SF Symbols now; westron's own glyphs become custom symbols with phase 6, when chapter 07's open question 1 is answered | No pilot screen needs a domain glyph that SF Symbols lacks; the SwiftDraw spike waits for one (07:68–70) |
| P7 | Deferred for lack of a pilot consumer (AGENTS.md, rule 6): the neutral status glyph (07, question 2), smaller masters (question 3), and the license of westron's glyphs (question 5) | No pilot screen draws them |
| P8 | The list's tile, an icon inside a shape, is a phase-4 component, not an option of this one | It is a shape with its own size and colors (07:113–114) |
| P9 | watchOS draws icons as the other OSes do | Nothing in the documents or the pilot differs there |
| P10 | Web, provisional: westron's glyph as an inline SVG at 1em in `currentColor`; GTK, provisional: a stock `GtkImage` with a symbolic icon | They take the size and color of the context as SF Symbols do, which is what the owner chose for Apple |
| P11 | ~~`Image(_: Westron.Icon)` becomes decorative (hidden), and `Image(_:label:)` is added, at implementation~~ **Superseded at implementation**: `Icon(.tray)` is decorative and `Icon(.sun, label: "Today")` labeled; `Image(_: Westron.Icon)` stays an adapter that keeps the system's name ("The Apple view") | The owner's screen-reader answer; an `Image` cannot carry it |

## The Apple view (decided at implementation, under the delegation)

**What the implementation showed** (2026-11-19, Xcode 27.1). The draft's Apple API, `Image(.tray)` hidden and
`Image(.sun, label: "Today")` labeled, both initializers of `SwiftUI.Image`, cannot be built while the glyphs are SF
Symbols:

- **The SDK.** In SwiftUI's interface only `Image(_:bundle:label:)` and `Image(decorative:bundle:)` carry a label or
  hide an image, and both look an image up by name in an asset catalog; `Image(systemName:)` takes no label. Every
  `accessibilityLabel` and `accessibilityHidden` on an `Image` returns `ModifiedContent`, not an `Image`.
- **A probe on macOS.** A symbol's name given to the named initializers is not found: `Image(decorative: "tray",
  bundle: nil)` and `Image("tray", bundle: nil, label:)` draw nothing (0 × 0), and `NSImage(named: "tray")` is nil. A
  platform image of the symbol does not take the font: `Image(nsImage:)` of `tray` stays 18 × 13 pt at `.largeTitle`,
  where `Image(systemName:)` grows to 36 × 26. Only `Image(systemName:)` follows the text, and it keeps the system's
  name.
- **What VoiceOver gets today.** The accessibility hierarchy of the catalog on an iPhone 17 simulator, iOS 26.3, which
  ran in Russian (the English meaning in brackets): a bare `Image(.tray)` is an image "Ящик Входящие" (Inbox tray),
  `Image(.sun)` an image "Повысить Яркость" (Increase Brightness), `Image(.pen)` an image "Изменить" (Edit); `Image`
  beside `Text("Inbox")` in a stack is two elements; `Label("Rename", icon: .pen)` is an image "Изменить" and the text
  "Rename". The system's name says what a symbol draws, or what Apple uses it for, never what it means on the screen.

**Options.**

- (A) westron's glyphs as custom symbols in WestronUI's asset catalog, so that `Image(decorative:bundle:)` and
  `Image(_:bundle:label:)` take them: the draft's API unchanged. It needs the glyphs exported from SF Symbols as
  templates, a licence decision on that, and a manual export with no command-line tool: phase 6 work (chapter 07's
  open question 1) that nobody approved now.
- (B) **An own view, `Icon`**, around `Image(systemName:)`: `Icon(.tray)` hidden, `Icon(.sun, label: "Today")` an image
  with that label. It gives the owner's answer now, and it survives a move to custom symbols unchanged: the view's
  body changes, and `Image` initializers with a label could be added then.
- (C) The initializers stay, and the product writes `.accessibilityHidden(true)` or `.accessibilityLabel(…)` itself:
  a bare icon then says the system's name, which is the owner's rejected option (b) of "Screen readers", and nothing
  can lint for it.

**Decided: (B)**, by the coordinator under the owner's delegation of 2026-11-18, pending the owner's confirmation. The
owner's answer was about behaviour, a bare icon hidden and a meaningful one labeled, and the evidence shows SwiftUI
cannot give that to an `Image` of an SF Symbol. **The trade-off:** decisions/0003 prefers extensions on the system view
to a westron type, and Icon is a westron view type where the system has an `Image`. It holds the system's `Image`
inside, as a style holds the system's control, and adds only what the `Image` cannot carry.

**What follows, decided with it under the delegation:**

- `platforms.apple`: `strategy: own-component`, `form: view`. The name `Icon` shadows no SwiftUI type
  (`SwiftUITypes`), and reads beside its argument's type, `Westron.Icon`. Inside an extension of SwiftUI's `Label`,
  whose generic parameter is named `Icon`, the name means the parameter; a product does not write such an extension.
- **The label** (proposed by the agent, decided under the delegation): `LocalizedStringKey`, as `Label(_:icon:)` takes
  its title, so `Icon(.sun, label: "Today")` localizes, and a second, `@_disfavoredOverload` initializer with
  `<S: StringProtocol>` for a label that is not localized, as `Label(_:icon:)` has: `Icon(.folder, label:
  list.title)`. SwiftUI's own `Image(_:bundle:label:)` takes a `Text`, which would make the contract's example need
  `Text("Today")`.
- **`Image(_: Westron.Icon)` stays a reviewed adapter**, not this component, for where only an `Image` fits, such as
  `Text` interpolation; its documentation says it keeps the system's name.
- **`Label(_:icon:)` stays as the system makes it** (tried and left, under the coordinator's instruction to hide its
  icon only if that was contained). design-language/07:101–102 and 08:92–93 say a decorative icon beside its own
  label is hidden. On its own a system `Label` was read as the symbol's system name and then its title in one stack
  (the snapshot above), and as its title alone on the catalog's `icon` entry (`IconAccessibilityTests`): the system
  decides. Making the adapter's icon a hidden `Image` (`Icon == ModifiedContent<Image,
  AccessibilityAttachmentModifier>`) compiled, kept every call site and drew the icon in a `Menu`, but the
  accessibility hierarchy of that menu on iOS 26.3 lost the items built from it: "Rename" and "Delete" were cells
  with no button, where the same menu's `Label("Plain", systemImage: "pencil")` kept its button. The pilot's Rename
  and Delete menus are built so, so the adapter keeps `Label(_:systemImage:)`, and the contract records the
  difference. **For the owner:** a `Label` outside a control could take `Icon` for its icon by hand,
  `Label { Text("Rename") } icon: { Icon(.pen) }`, which the menu case would need checking for too; or westron accepts
  the system's reading of a lone label.
- **`scale`** (proposed by the agent, decided under the delegation): it stays a contract option and an Apple system
  option, `SwiftUI.Image.Scale`. On an own component a system option is the system's environment modifier, which the
  product writes on the component and the symbol inside reads: `Icon(.chevron).imageScale(.small)`. So `Icon` takes no
  `scale` argument and no enum is generated, as the owner chose; the tools allow `systemOptions` on an own component
  for that (`spec/conventions.md`, "Own components"). The alternative, `scale` in the description without an option,
  would leave the snapshot matrix no scale axis.
- **The snapshot matrix** (proposed by the agent, decided under the delegation): with no states, the registry's names
  run down the rows, six to a sheet, and `scale` across: six sheets, not thirty-six of three glyphs each.

## Open points

- **The weight under Bold Text, for the owner.** Measured as the symbol's frame at 60 pt and beside the roles, on iOS
  26.3 (XCUITest frames) and macOS (a unit probe), which agree:
  - **At rest a symbol takes the weight of its font**, custom fonts included: Onest SemiBold and Bold, Geist Mono
    Regular and SemiBold draw the symbol at those weights, and `textRole(.heading.large)` gives the same symbol as
    `.system(.largeTitle, weight: .bold)` (40.3 × 30.3 pt on iOS). Onest ExtraBold reads as regular (50.3 pt high at
    60 pt, as the system's regular), but no role draws it at rest.
  - **Under Bold Text a symbol takes its font's weight and then the system's Bold Text step** (regular → semibold,
    semibold → heavy, bold → black: 52.0, 55.0 and 56.3 pt high at 60 pt). Beside a system-font role, text and icon
    take that step together. A role in Onest or Geist Mono has already taken the heavier instance
    (`Weight.boldTextStep`), so its icon steps twice and draws heavier than its text: beside `heading.large` (Onest
    ExtraBold) the icon is black (41.0 × 32.0 pt, as `.largeTitle` black), beside `heading.small` (Onest Bold) black,
    beside `code.regular` (Geist Mono SemiBold) heavy, beside `code.strong` (Geist Mono Bold) black.
  - The contract records it as a platform difference. **To make it follow** (not done: it touches the role modifier
    and nested text): under Bold Text, for a role in a font westron ships, the role modifier could set
    `.fontWeight(<the role's Bold Text weight>)` for the symbols and keep the system's step from them, for example by
    setting `legibilityWeight` back to regular inside the role; that also reaches text nested in the role's subtree
    that takes its own role, so it needs the owner's call and a test of nested roles.
- **chapter 07's open question 1** (which names are domain icons) stays open; P6 keeps Apple's glyphs as they are.

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

**Superseded by "How the tools settled it" below**: this is what the agent proposed for the draft's `Image`
initializers, before the Apple API became an own view. Kept as the record of the proposal.

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

**How the tools settled it (#28, with the implementation).** Icon is an own view, so the generator and the lint take
the `own-component` path that Surface and Rule made, with what an icon adds (`spec/conventions.md`, "Own components"):
an option whose values are icons is the view's first, unlabeled argument, typed as `AppleIcons.iconType`
(`Westron.Icon`), as a token option takes `AppleTokenModel.textRoleType`; the slot `label` with `accessibility.label:
optional` gives the decorative, the localized and the verbatim initializer; `systemOptions` on an own component are
the system's environment modifiers, no parameter and no enum. No contract-format field was added: the option's `type`
and the existing `form` say the shape. The generator writes no file for Icon (no enum); the API parity lint holds the
hand-written `Icon`, its three initializers and its `body` to the contract; `Image.init(_:)` and `Label.init(_:icon:)`
stay in `APIParity.adapters`. The snapshot matrix reads the registry's names with `IconRegistry.load` and runs them
down the rows (`SnapshotMatrix.rowAxis`); the catalog draws each cell with the hand-written `IconMatrixCell`, and two
supplements, of six glyphs each, show the icon beside text in four roles and in the color roles. An extension or a
style with an icons option, and an own modifier with one, are still reported as not derived.
