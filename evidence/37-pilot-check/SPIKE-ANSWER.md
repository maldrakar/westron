# Spike: the "Move to…" picker on westron

Date: 2026-11-24. Size: spike (throwaway code, the answer written down). Westron: the package at
`westron-design-system/.claude/worktrees/spike-westron`, by local path; the skill and its `context/` from the plugin
cache.

## 1. Verdict

**Yes. The picker is on westron, and every check passes.** The sheet's content is westron's `ListRow`, `IconTile`,
`Icon`, `Rule` and `Text.textRole`, laid out in westron's tokens. The sheet, its navigation bar, the title and Cancel
are still the system's. The picker's model is new and in westron's vocabulary: an icon, a list colour, a nesting level,
disabled, checked, the action, the words. It holds no size, colour, font or gap. The Lists tree and its models and
views are untouched and their tests pass.

- Core: `swift build` and `swift test` on the host (824 tests) and on wasm32 under WasmKit (823; one test is host-only
  already) pass. `scripts/wasm-size.sh` passes too, but with 11,685 bytes of headroom left (section 7).
- Apple: `swift build` and `swift test` in `Apps/Apple` pass (151 tests, the project-file tests included).
- A new UI walk on a fresh iPhone 17 simulator opened the picker, kept a screenshot and closed it with Cancel
  (`move-picker-westron.png`, section 8).

What does not work, or is worse than before:

- **A rose list loses its colour.** westron has no `rose` (and no `stone`), so the built-in **Upcoming** list draws
  westron's neutral grey tile in the picker (visible in the screenshot). Stone lists (Trash and every list with no
  colour) were grey before and still are.
- **Linking WestronUI broke one todo-app test until I qualified it.** `Animation(.check)` became ambiguous between
  todo-app's `Animation(_: DesignSystem.Animation)` and westron's `Animation(_: Westron.Transition)`. todo-app's own
  `Icon` and `Rule` views also shadow westron's, so the sheet has to write `WestronUI.Icon` and `WestronUI.Rule`.
- **WestronTokens costs about 165 KiB gzipped** in the wasm probe (+168,614 bytes) for two enums.
- **The picker no longer looks like the old one or like the tree behind it.** Each difference follows from westron
  (section 4):
  - the check is in the text colour, not the accent;
  - titles are all body regular, with no emphasis on lists that have lists inside them;
  - an area's label is in capitals on the phone;
  - the hint scrolls with the rows instead of staying pinned under the title;
  - rows are at least 44 pt and disabled rows are drawn at 40 % opacity.
- The Mac's sheet was not looked at: there is no unattended Mac route, and I was asked not to drive the Mac's screen.

## 2. What changed

Every file changed, against `todo-app-before`:

| File | Change |
|---|---|
| `Package.swift` | `dependencies: [.package(name: "Westron", path: …)]`; product `WestronTokens` added to `TaskViewListFeature` and `TaskViewListFeatureTests` |
| `Apps/Apple/Package.swift` | the same package (same name, so SwiftPM resolves it once); product `WestronUI` added to `TodoAppleUI` |
| `Sources/Features/TaskViewList/TaskViewList+Model.swift` | `Model.movePicker` is now `MovePicker?`; the new types `TaskViewList.Model.MovePicker`, `.Option` and `.Option.Kind` |
| `Sources/Features/TaskViewList/TaskViewList+Components.swift` | new `movePicker(moving:among:)`, which takes no width any more; private `ReadRow.category` and `ReadRow.glyph` read the store's names as westron's; removed `enum Picker` (the check, its cell, `endGap`, `checkInNeed`, the paper background, `rowEnd`, `lineEnd`) and `Metrics.topLevelGlyphSize` / `minimumOptionHeight` with their values |
| `Sources/Features/TaskViewList/TaskViewList.swift` | the state's `movePicker` uses the new builder |
| `Sources/DesignSystemComponents/PickerModel.swift`, `OptionPickerStyle.swift`, `PickerTopLevelStyle.swift` | **deleted**: they had no other caller |
| `Sources/WasmSizeProbe/main.swift` | `pickerLine` reads the new model |
| `Apps/Apple/Sources/TodoAppleUI/ListsScreen/MovePickerSheet.swift` | rewritten on westron |
| `Apps/Apple/Sources/TodoAppleUI/ListsScreen/ListsDialogs.swift` | the picker closure takes `TaskViewList.Model.MovePicker` |
| `Tests/TaskViewListFeatureTests/TaskViewListComponentsTests.swift` | `thePickerWhole` expects the new model; new `aListsColourAndIconInThePickerAreWestronsByName`; `thePickerInAWideWindow` became `thePickerIsTheSameInEveryWidth` |
| `Tests/TaskViewListFeatureTests/TaskViewListEditsTests.swift` | an option is known by its action; "offers the rows" now compares the place of each row (id, depth, line or list, a list's title), not the tree's look; new check that an unnamed area's line stays alone in edit mode |
| `Tests/DesignSystemComponentsTests/ClassModelEqualityTests.swift` | `PickerModel`'s equality test and its fixtures removed |
| `Apps/Apple/Tests/TodoAppleUITests/DesignSystemRenderersTests.swift` | `Animation(.check)` written as `Animation(DesignSystem.Animation.check)` (section 7) |
| `Apps/Apple/UITests/PickerWalks.swift`, `Apps/Apple/Todo.xcodeproj/project.xcproj` | a throwaway walk that opens the picker and keeps a screenshot |

Test-first: the module's tests were changed first and failed to compile ("'MovePicker' is not a member type of struct
'TaskViewList.Model'"); then the model and the builder made them pass.

### The new models (shared code, `import WestronTokens`)

```swift
extension TaskViewList.Model {
    public struct MovePicker: Equatable, Sendable {
        public struct Option: Equatable, Sendable {
            public enum Kind: Equatable, Sendable {
                case tile(Westron.Icon, Westron.Category?)  // a list, or the top level (.divider, nil = neutral tile)
                case line                                   // an area's line
            }
            public let kind: Kind
            public let title: String          // a list's name; an area's in capitals; "" for an unnamed area
            public let level: Int             // the drawn depth, as ListRow's `level`
            public let isDisabled: Bool
            public let isChecked: Bool
            public let action: TaskViewList.UserAction
        }
        public let title: String              // "Move “Home” to…"
        public let hint: String               // "Choose where it goes."
        public let currentLabel: String       // "Current", what the check is read as
        public let cancel: ChoiceModel<TaskViewList.UserAction>
        public let topLevel: Option
        public let options: [Option]
    }
}
```

`MovePicker` is a struct, not a class. It holds no 500-byte row models, so ADR-0007's class rule (amendment of
2026-10-30) does not apply. A list's colour is `Westron.Category(rawValue: color.rawValue)` and its icon is
`Westron.Icon(rawValue:) ?? .fallback`. Nothing depends on the window's width any more.

### How the view is composed

| Part | Before | Now |
|---|---|---|
| Sheet, `NavigationStack`, inline title, Cancel | the system's | the system's; `.presentationBackground(Color(.paper))` removed, so the sheet stands on the system's background |
| Hint | pinned under the bar in a `safeAreaInset` on the paper, todo-app's `.hint` font in ink2 | `Text(hint).textRole(.footnote.regular).foregroundStyle(.text.secondary)`, the first item of the scroll content, `.space.withinGroup` below it |
| "Top level" | a hand-made `HStack` with todo-app's `Icon` on a fill-coloured rect, plus `Accessories` | `ListRow(level: 0, guides: false, action:) { Text } leading: { IconTile(.divider).category(nil) } trailing: { check }` |
| A list | `ListRowView` + `ListRowView.End` | `ListRow(level:, guides: false, action:) { Text(title) } leading: { IconTile(icon).category(category) } trailing: { check }` |
| An area | `AreaLine` | `ListRow(level:, guides: false, action:) { WestronUI.Rule(title) } trailing: { check }` |
| The check | todo-app's accessory, 15 pt bold accent, hidden in its room on other rows | `WestronUI.Icon(.check, label: model.currentLabel)` on the present parent; `WestronUI.Icon(.check).hidden()` on every other row, so the rows end in one column |
| A disabled option | `.disabled` plus `.opacity(0.35)` | `.disabled(option.isDisabled)`; ListRow dims itself at `opacity.disabled` |
| Least height | the model's `minimumOptionHeight`, 36 or 30 | ListRow's own `size.target.minimum`: 44 on iOS, 28 on macOS |
| Horizontal layout | numbers per width in the models | `.padding(.horizontal, pageMargin)`: `.space.page.narrow` in a compact size class, `.space.page.wide` otherwise and on the Mac; the rows pad themselves |

There is one switch over `option.kind`, which picks the row.

## 3. The reading log

Before the spike, the harness had already loaded westron's `AGENTS.md` into my context: it was the working
directory's project instructions, which I did not choose to read. It overlaps the skill almost entirely (no prefixes,
styles on system controls, tokens only). The one thing I used from it that the skill does not say is the
raw-value-lint marker `// westron-lint: allow <reason>`. I wrote it once and removed it (section 4, Q15). Apart from that,
everything below came from the skill or from the package's public declarations.

First I listed the plugin's files with `find`, without opening any. Then I opened these skill files, in this order:

| # | File | Why I opened it | Did it answer? |
|---|---|---|---|
| 1 | `skills/westron/SKILL.md` | The brief said to start here. | **Yes, the most of any file.** Rule 4 names this exact case: "a 'Move to…' picker is `ListRow`s with `IconTile`s and a check `Icon` on the chosen one", and the sheet stays the system's. Rule 7 says the model keeps westron's vocabulary from `WestronContract`/`WestronTokens` and no size, colour or font. Rule 2 gives the token idioms. |
| 2 | `context/index.md` | SKILL step 1: "first, every time". | Yes. Which component does what, and that shared code imports `WestronContract` and `WestronTokens` (`Westron.Icon`, `Westron.Category`). |
| 3 | `context/components/list-row.md` | Card of the row SKILL rule 4 names. | Mostly. The API (`level`, `guides`, `action`, slots), "`guides` … a picker … as the pilot's 'Move to…' sheet does, may leave them out", and that disabled is the system's `.disabled`. It did not say whether the present choice is `.selected` (Q3). |
| 4 | `context/components/icon-tile.md` | Card of the list's tile. | Partly. `IconTile(_:)`, and that without a label it is decorative. It says "in the list's color", but its only argument is the icon, and the card never says how the colour gets in (Q1). |
| 5 | `context/components/icon.md` | Card of the check. | Partly. `Icon(.check, label:)`, and to label an icon that means something. Not the check's colour (Q5). |
| 6 | `context/components/icon-tile.details.md` | The card did not settle the colour; the card points here. | **Yes.** The colour comes from the environment, `.category(Westron.Category(rawValue: list.color))`, and nil gives the neutral tile, which fits "Top level". |
| 7 | `context/icons.md` | Glyph names for the check and "Top level", and how to read a stored name. | Yes. `.check`, `.divider`, `Westron.Icon(rawValue:) ?? .fallback`, and that every one of todo-app's 32 icon names exists. |
| 8 | `context/components/rule.md` | The tree draws an area as a labelled line, so I needed westron's line. | Partly. `Rule("…")` with a label, which is a heading. It does not say whether a Rule may be the title of a pressable row (Q2). |
| 9 | `context/components/rule.details.md` | The card did not settle Q2. | Partly. The label is `heading.overline`; an empty label means the line alone (exactly the unnamed area); it names "an area's line across the Lists screen's tree". Still nothing on a Rule as a choice. |
| 10 | `context/components/list-row.details.md` | Q2 and Q3 were still open; the card points here. | Partly. It confirms "the rows of the 'Move to…' sheet are each a ListRow with other westron components in its slots"; the 44/28 pt least height (which replaces `minimumOptionHeight`); that a disabled row dims whole; that the trailing slot's words join the row's name; that a row draws no background at rest; and that the product places rows in its page margin. Neither Q2 nor Q3. |
| 11 | `context/tokens/layout.md` | SKILL step 3. | Yes for the page margin (`space.page.narrow`/`wide` by size class) and `space.withinGroup`. No token for a sheet's size (Q9). |
| 12 | `context/tokens/typography.md` | The hint's role, and the overline label. | Yes. `footnote.regular` is literally "a hint". `heading.overline` is "written in capitals by the product" (Q7). |
| 13 | `context/tokens/color.md` | The hint's colour, and list colours. | Yes. `.text.secondary`; `Westron.Category`'s 12 names read by raw value; `.category(_:)` again. This is how I found the `rose`/`stone` gap. |
| 14 | `context/components/icon.details.md` | The Icon card did not give the check's colour. | Partly. An icon has no colour of its own and takes one of "the roles chapter 07 lists"; it pointed me to chapter 07. |
| 15 | `context/design-language/07-icons.md` | Pointed to by #14. | Yes. "An icon takes the color of the text it goes with", so no accent and no `foregroundStyle`. |
| 16 | `context/swiftui.md` | To settle Q3 (selection or a check) and confirm what stays the system's. | No for Q3. It confirmed the sheet takes no westron surface and that `.category(_:)` is a context modifier. |
| 17 | `context/components/text.md` | **Late, during self-review.** I had used `.textRole` on the hint without reading Text's card, which SKILL step 2 requires for every component used. | Yes, and it matched what I had written. It also says "every use names its role", while ListRow's own example writes `Text(list.title)` with no role (section 4). |

Not opened: the cards and details of Button, Checkbox, Chip, Disclosure, Surface and TextField; `text.details.md`;
`tokens/motion-and-shadow.md`; design-language chapters 00–06, 08 and 09; `plugin.json`.

From the westron package I read only what a dependency shows: `Package.swift`, `WestronTokens/Westron.swift`, and the
`public` lines of `Icons.swift` and `Tokens.swift` (`Icon.fallback`, `enum Category: String`, the `TextRole` statics),
`WestronContract.swift` with `ListRow+Contract.swift` and `Rule+Contract.swift`, and the `public` declarations of
WestronUI's `Category.swift`, `States.swift`, `IconTile.swift`, `Icon.swift`, `ListRow.swift`, `InsertionMark.swift`,
`Rule.swift`, `WestronUI.swift` (`@_exported import`), `TokenAdapters.swift` (`textRole`) and
`Generated/Tokens+SwiftUI.swift` (how `.space.page.*` is declared).

## 4. Questions the skill did not answer

| # | Question | Where I looked | What I chose, and why | How sure I am westron means it |
|---|---|---|---|---|
| Q1 | How does a list's colour reach an `IconTile`? | icon-tile card (silent), its details, color.md | `IconTile(icon).category(category)`, and `nil` for "Top level". | **High.** But the answer is only in the details file and on the colour page, not on the card, whose initializer cannot express it. |
| Q2 | How is an area drawn as a *choice*: a labelled line you can tap? | rule card and details, list-row details | `ListRow(action:) { WestronUI.Rule(title) }`. It keeps the tree's look of a labelled line, an empty name gives the line alone, and ListRow supplies the tap, the 44 pt target and the dimming. | **Low to medium.** A labelled Rule is a heading. Inside the row's combined element it may add a heading trait to a button, and an unnamed area's row has no accessible name at all. VoiceOver was not checked. |
| Q3 | Is the present parent `.selected(true)` or only the check? | list-row card and details, swiftui.md, States.swift | The check only: `Icon(.check, label: "Current")`, no `.selected`. SKILL rule 4 names only "a check Icon on the chosen one", and `selected` draws an accent highlight and a bar, which here would repeat the check. | **Medium-low.** The old view added the `isSelected` trait; now VoiceOver hears "Project, Current, button" instead of "selected". |
| Q4 | Do the other rows keep the check's room, so the rows end in one column? | list-row details (Disclosure's `alignsLeaves` keeps a leaf's empty cell; nothing for a slot) | `WestronUI.Icon(.check).hidden()` on every other row. It keeps the owner's earlier ruling (r4431052930) and needs no raw value. | **Medium.** |
| Q5 | What colour is the check? | icon card and details, chapter 07 | The context's, i.e. the text colour. Chapter 07 lists no accent for a mark. | **Medium-high.** Before, the check was accent bold. SKILL rule 3 says never put `.foregroundStyle` on a component, while `icon.details.md` says an Icon is coloured by "the context's foregroundStyle". The two read as contradictory to a product engineer. |
| Q6 | Which text role do the titles take, and may a model carry one? | list-row details ("may set … `callout.regular` for a nested row … `body.strong` for a row with children"), SKILL rule 7 | ListRow's default role for every title, and no role in the model. Rule 7 forbids "a font" in a model, and `Westron.TextRole` is a font token even though it lives in `WestronTokens`. | **Medium.** The tree's emphasis on lists with lists inside them is gone from the picker. |
| Q7 | Should an area's label be in capitals? | typography.md, `heading.overline`: "written in capitals by the product" | The module writes `title.uppercased()`, since todo-app finishes every string in the module. | **Medium-high.** The phone's tree writes the name as typed, so the picker and the tree now differ. |
| Q8 | Which page margin, and who picks it? | layout.md | The view picks `.space.page.narrow` or `.wide` by `horizontalSizeClass`, and always `.wide` on the Mac. | **High** that this is westron's rule. It strains todo-app's rule that a view decides nothing by width (section 7). |
| Q9 | How big is the sheet on the Mac, where a scroll view in a sheet asks for no height? | layout.md (no sheet size), SKILL rule 4 (the sheet is the system's) | Kept `.frame(minWidth: 320, minHeight: 400)` under `#if os(macOS)`. | No answer in the skill. |
| Q10 | Where does a hint go under a system navigation bar? | SKILL rule 4, swiftui.md | The first item of the scroll content. A pinned strip needs a background, and the sheet's background is now the system's. | Role and colour **high**; the placement is the product's. |
| Q11 | What happens to stored colours westron does not have (`rose`, `stone`)? | color.md ("kept by its name … `Westron.Category(rawValue:)`") | Read by raw value, as the page says, so both become nil, the neutral tile. A new test pins this. | **High** for the reading. The loss of rose is a gap (section 5). |
| Q12 | westron's names are unprefixed. What about a product that has views of the same names? | SKILL ("no prefixes"), swiftui.md | Wrote `WestronUI.Icon` and `WestronUI.Rule`, and qualified one ambiguous `Animation(.check)` in a todo-app test. | No answer in the skill. Found only by compiling. |
| Q13 | Where does a product's own composite model live? | SKILL rule 7 ("a model in shared code") | Nested in the feature's `Model` (`TaskViewList.Model.MovePicker`), not in `DesignSystemComponents`, which would then depend on westron. | A todo-app question (section 7). |
| Q14 | Whose word is the check's label? | icon card ("an icon that means something takes `label:`"), todo-app's `docs/style.md` | The model's: `currentLabel = "Current"`, finished in the module like every other word. | **Medium** on the word itself. |
| Q15 | How does a product check itself for raw values, and how does it mark an exception? | SKILL ("If westron's repository is at hand, `tools/westron lint raw-values`") | Not run: it would build inside westron's checkout, which this spike must not touch. Checked by eye instead. I first wrote westron's `// westron-lint: allow` marker, which I knew only from the AGENTS.md the harness loaded, and removed it. | The skill never says how a product marks a deliberate raw value. |

Found only in WestronUI's declarations or the compiler, not in the skill:

- The name collisions of Q12, and the ambiguous `Animation(.check)`.
- A local path dependency on westron prints westron's own Swift warnings in todo-app's build: `@Entry` closures in
  the catalog-support files and `ListRow.swift`, and a main-actor static (`slotSpace`) referenced from a Sendable
  closure in `ButtonVariantStyle.swift`.
- That `.category(_:)` cascades like `.tint(_:)` and that `nil` resets it. The skill does say this, but only in
  `color.md` and `icon-tile.details.md`, not on the IconTile card.

Where the skill contradicts the declarations or itself:

- SKILL rule 3 forbids `.foregroundStyle` on a component, yet `icon.details.md` says that is how an Icon is coloured
  (Q5).
- `text.md` says "every use names its role", yet `list-row.details.md`'s own example puts `Text(list.title)` with no
  role in a row's title.
- The IconTile card promises "the list's color" with an initializer that cannot take one.
- I found nothing in the declarations that contradicts the skill.

## 5. What westron lacks for this screen

| Missing | What I did instead |
|---|---|
| A list colour for todo-app's `rose` (Upcoming); `stone` exists only as the neutral tile | Read by raw value, so rose draws neutral. Issue to draft: todo-app / Lists screen and picker / the 11 stored colours do not all have westron names. |
| A token, or the system's way, for a sheet's least size on the Mac | Kept todo-app's 320 × 400. |
| A pattern for a section line that is also a choice (an area in a picker) | `ListRow { Rule(name) }`, with the accessibility doubts of Q2. |
| Guidance on the current value of a picker: a check, `selected`, or both | A labelled check (Q3). |
| A way to keep a trailing slot's room when its content is absent, outside Disclosure's `alignsLeaves` | A hidden `Icon`. |
| A hint or subtitle under a system sheet's title | A `Text` at the top of the scroll content. |

No icon was missing: `.check`, `.divider` and all 32 of todo-app's list icons exist.

## 6. Raw values left

- `MovePickerSheet.swift`: `.frame(minWidth: 320, minHeight: 400)` on macOS only. This is the system sheet's size,
  westron has no token for it (Q9), and the comment says so.
- `LazyVStack(spacing: 0)`: SKILL rule 2 allows 0.
- The models hold no raw values: words, an `Int` level that is ListRow's own option, Bools, westron's enums and the
  action.
- Left untouched on purpose, so that the tree stays as it was: the tree's builders still carry branches and doc
  comments that served only the old picker. These are `listRow(guides: [Double]?)`'s `nil` path, the `background:`
  parameter, and docs mentioning `Picker.rowEnd` / `Picker.lineEnd` / `Picker.background` / "the picker's
  'Top level'". `AccessoryModel.hidden` and `DesignSystem.Font.hint` now have no caller either. A real PR would remove
  them all (`docs/style.md`, "No API without a caller").

## 7. For todo-app

**What an amendment to ADR-0007 would have to say.** A screen, or a part of one, that moves to westron leaves
todo-app's design system:

- Its models hold content, actions, words and westron's vocabulary only: `WestronContract`'s option enums,
  `Westron.Icon`, `Westron.Category`, a nesting level and states. They hold no size, colour, font, radius, gap, motion
  or style. So the amendments of 2026-10-26, 2026-10-30 ("a component's model holds every value its platform needs")
  and 2026-11-06 ("a component's visual values are … its style") no longer bind it.
- The model of a product's own composition of westron's components belongs to the feature that builds it, nested in
  its `Model`. It depends on the width only where its content does.
- A feature that builds such a model depends on `WestronTokens`, and on `WestronContract` once it names an option.
  Neither imports anything, so the core still builds on the host and on wasm32. This widens what a feature may
  import, as the amendment of 2026-10-26 did for `DesignSystem`.
- `Apps/Apple` depends on `WestronUI`. Its views lay out in westron's tokens, including the page margin by size class.
- The store's names of a list's colour and icon are read as westron's by raw value in the feature. The amendment must
  decide what to do with a stored colour westron lacks (`rose`): migrate the store, map it in the feature, or ask
  westron for a colour.
- `DesignSystem` and `DesignSystemComponents` shrink screen by screen. Until the last screen moves, the two systems
  live side by side in the same app.

**What adopting westron for real would touch beyond this picker:**

- **The core's `Package.swift`.** A URL dependency on westron pinned to a release instead of the local path. Every
  CI job that resolves the root package (Linux, wasm32, macOS) then fetches westron, so the repository must be public
  or the jobs need a token.
  - **Linux:** `WestronTokens` imports nothing and should build there, but I did not build on Linux.
  - **wasm32:** the tests pass. But the release probe grew from 7,487,413 to 7,656,027 bytes gzipped (+168,614, about
    +2.3 %) just for `Westron.Icon` and `Westron.Category`, and the budget now has 11,685 bytes of 180,299 left. The
    next step will exceed it, so either the budget moves or westron makes the tokens strip better.
- **`Apps/Apple/Package.swift`.** `WestronUI`, whose resource bundle (fonts, asset catalog, strings) the app now
  carries.
- **The Xcode project.** It needs no edit. It takes westron through the `TodoAppleUI` product: the walk's
  `xcodebuild build-for-testing` built the iOS app with WestronUI and ran it on the simulator.
  - Not checked here: the watchOS compile check from CI, the Mac app through `swift run todo-mac`, and the Mac's sheet.
  - `Apps/Apple/Package.resolved` did not change, since path dependencies are not pinned.
- **Name collisions.**
  - `TodoAppleUI` has its own `Icon` and `Rule`, which shadow westron's in that module.
  - todo-app's `Animation(_:)`, `Color(_:)` and `Font(_:)` adapters share implicit-member syntax with westron's.
    `Animation(.check)` broke in a test file that never imports WestronUI: it reaches WestronUI's extensions through
    `@testable import TodoAppleUI`.
  - Every screen that moves will meet more of these. The fixes are the upcoming feature `MemberImportVisibility`
    (SE-0444), or retiring todo-app's own views as each screen moves.
- **Specs and process.**
  - `docs/specs/lists-screen.md` section 6 describes the picker from the canvas (`Phone.dc.html`); with westron the
    look is westron's.
  - A screen half on westron (the picker) over a tree on the old look is a mixed screen until the tree moves.
  - No walk covered the picker before; a real PR would keep one, like `PickerWalks`.
- **The walk's runtime warning.** It recorded "Adding '_UIReparentingView' as a subview of UIHostingController.view
  is not supported". It most likely comes from the context menu over the tree, not from the sheet, but I have no
  baseline run to compare against.

**What this strains in todo-app's own rules:**

- *"A component's look is its style"* (`docs/style.md`, PR #191) and the 2026-10-30/11-06 amendments. They are
  inverted for westron screens: the model no longer holds the look, westron and the view do.
- *"A view reports the width of its window and decides nothing by it"*. westron's page margin is chosen by size class
  in the view (Q8). The alternative is the module handing the view a width class only for this, which the owner's
  2026-11-24 decision ("layout is the platform view's") argues against.
- *"A view may switch over three enums of its model…"*. `MovePicker.Option.Kind` is a new enum. I counted it as "the
  kind of a row"; a strict reading makes it a fourth permission.
- *"No API without a caller"*. Kept, except the leftovers listed in section 6, which keep the tree's code unchanged.
- *"A name the core exports is a name its consumers lose"*. The same problem now runs the other way: westron's
  exported names cost todo-app's own UI names (Q12).
- *"A view holds no condition over a domain value"*. Held. The view's `if`s are over `isChecked` and the size class,
  and its one switch dispatches over `kind`.

## 8. Check outputs

All commands ran with `DEVELOPER_DIR=/Applications/Xcode_27_1.app/Contents/Developer` and swiftly's Swift 6.4 from
`.swift-version`.

**Core, at the root of the copy:**

```
$ swift build
Build complete! (0,61 secs)

$ swift test                                   # exit 0
✔ Test run with 246 tests in 0 suites passed after 1.307 seconds.
✔ Test run with 15 tests … 117 … 7 … 243 … 23 … 13 … 31 … 3 … 31 … 16 …
✔ Test run with 79 tests in 0 suites passed after 0.086 seconds.       # 824 tests in 12 runs
```

The line `error: sqlite(… "unable to open database file")` in that log is a CLI test's expected stderr; its run of 15
tests passed.

**wasm32.** The SDK is installed: `swift sdk list` shows `swift-6.4.0-RELEASE_wasm`.

```
$ swift test --swift-sdk swift-6.4.0-RELEASE_wasm --disable-xctest   # exit 0
✔ Test run with 245 tests in 0 suites passed after 182.913 seconds.
✔ Test run with 15 … 117 … 7 … 243 … 23 … 13 … 31 … 3 … 31 … 16 …
✔ Test run with 79 tests in 0 suites passed after 17.694 seconds.      # 823 tests
```

The one host-only test is under `#if !arch(wasm32)` in `TreePerformanceTests.swift`, as before.

```
$ scripts/wasm-size.sh                         # exit 0
wasm-size-probe.wasm: 26337788 bytes raw, 7656027 bytes after gzip -9, budget 7667712 bytes (Apple gzip 479.0.0.700.1)
under budget by 11685 bytes
# todo-app-before, same build into the scratchpad: 25642427 raw, 7487413 after gzip -9
```

**Apple, in `Apps/Apple`:**

```
$ swift build
Build complete! (1,68 secs)                    # Swift warnings only from WestronUI's own sources

$ swift test                                   # exit 0
✔ Test run with 143 tests in 0 suites passed after 1.278 seconds.
✔ Test everyWalkFileIsASourceOfTheUITestBundle() passed after 0.007 seconds.
✔ Test theProjectFileIsCanonical() passed after 0.007 seconds.
✔ Test run with 8 tests in 0 suites passed after 0.007 seconds.
```

**The walk.** `scripts/ui-walks.sh` makes its own device and deletes it afterwards.

```
$ scripts/ui-walks.sh PickerWalks
ui-walks: walking PickerWalks
'-[TodoUITests.PickerWalks testMovePickerOnWestron]' passed (25.434 seconds).
ui-walks: 1 passed, 0 failed, 0 skipped
ui-walks: deleted the device 72AF2C35-8D0D-4EEF-921D-C76B569AC57C
```

**The screenshot.** `move-picker-westron.png` at the root of the copy, iPhone 17 in light mode, exported from the
walk's result bundle. The walk added an area "Work" through "+" and opened Move to… on **Core**, a list inside
**Project**. What I see:

- The sheet is the system's: white background, Cancel as the system's glass capsule at the top left, and the title
  "Move “Core” to…" inline in the bar.
- Under the title, "Choose where it goes." is centred, in grey footnote type.
- "Top level" has a neutral grey tile with the divider glyph.
- Inbox (blue), Today (amber) and Logbook (green) have coloured tiles. **Upcoming is grey: its rose was lost.** Trash
  and Project are grey, as before.
- **Project carries a black check at the far right**: Core's present parent.
- Core, Design, Ops, Docs, Either and Weekly are indented one level, with no guides. **Core is dimmed**, as the list
  being moved.
- Spare is back at the root.
- Last comes the area: "WORK" in small grey capitals, with a hairline that stops where the check's column begins.
- Rows are evenly spaced at about 44 pt, in the system font, at westron's page margin.

The walk then pressed Cancel and the sheet went away. The Mac's sheet was not seen.
