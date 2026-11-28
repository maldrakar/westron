# 0002. A current value announced as selected, without the selected look

Date: 2026-11-26 (#176). Status: accepted by the owner on 2026-11-27, the first gate (decisions/0005), every question
answered as recommended ("The owner's answers", below). It amends the approved contract, `list-row.spec.yaml`, which
now carries the state `chosen`, and the pattern `spec/patterns/choice-list-sheet.md`, whose gap G1 it closes. It rests
on the owner's decision of 2026-11-25: in a list of choices the check alone marks the current one, and the row draws
nothing of the selected look.

## Context

The pattern `spec/patterns/choice-list-sheet.md` marks the row that holds the current value of a choice with the
platform's check. `.selected(true)` is the only way ListRow has to announce a row as selected, and it also draws the
selected look: the tint `color.background.selected`, the bar at the leading edge and the title in `body.strong`. That
look means "this row is open, its content is shown beside it", as in a sidebar; in a sheet of choices it is a second and
third mark of what the check says, and the owner decided against it after seeing the catalog's entry drawn (#175). The
pattern's stopgap marks the current choice with `Icon(.check, label: "Current")` and no `.selected` (its rule 2 and gap
G1). The issue asks, contract first, how a product tells ListRow that a row holds the current value, so that assistive
technology hears "selected" and nothing of the selected look is drawn, and names three candidates, none measured: a
documented `.accessibilityAddTraits(.isSelected)` on the row, a separate state modifier, an argument of `.selected(_:)`.

## Measured

On 2026-11-26, Xcode 27.1, on the iPhone 17 simulator with iOS 26.3 (its languages `en-RU`, `ru-RU`) and on macOS
26.7.1 (25G241). A throwaway catalog entry, `list-row-current-probe`, drew the rows below, each a pressable
`ListRow(level: 1, guides: false, action: {})` built as the pattern builds a choice (a title, `IconTile(.folder)
.category(.violet)` at the start, the check at the end in `text.primary`), except where the row says otherwise; two
throwaway prototypes in WestronUI gave candidates c and d; a throwaway UI test, `CurrentValueProbeTests`, read XCUITest's
hierarchy as `ChoiceListSheetTests` does (label, value, `isSelected`, and on iOS the traits from the element's snapshot,
which macOS does not hold). None of it is committed; the class was added to `behavior_tests` in `tools/apple/check.sh`
for the run only.

```sh
tools/apple/check.sh behavior ios CurrentValueProbeTests     # Executed 1 test, with 0 failures; exit 0
tools/apple/check.sh behavior macos CurrentValueProbeTests   # Executed 1 test, with 0 failures; exit 0
tools/apple/catalog-screenshot.sh ios --entry list-row-current-probe
```

The rows, the candidate each stands for, and what was written:

| Row | Candidate | Written |
|---|---|---|
| Alpha | a, today's stopgap | trailing `Icon(.check, label: "Current")`, no state |
| Bravo | baseline | no trailing slot |
| Charlie | baseline | trailing `Icon(.check)`, decorative, no state |
| Delta | b | decorative check; `.accessibilityAddTraits(.isSelected)` on the ListRow |
| Echo | b, with a named element at the start | as Delta, the start `Icon(.sun, label: "Today")` instead of the tile |
| Foxtrot | b, with a control at the start | as Delta, the start `Toggle(isOn:accessibilityLabel: "Task foxtrot").toggleStyle(.check)` |
| Golf | b, the static form | as Delta, `ListRow(level: 1, guides: false)` without an action |
| Hotel | c, a separate state | decorative check; `.chosen(true)`: a Bool in the environment that the representation reads as selected and the highlight does not read |
| India | d, an argument of `.selected` | decorative check; `.selected(true, drawn: false)`: `isSelected` set, the highlight and the title's role told not to draw it |
| Juliet | reference | decorative check; `.selected(true)`, today's |
| Kilo | b, on the check | `Icon(.check).accessibilityAddTraits(.isSelected)` in the trailing slot |
| Lima | the system's symbol | trailing `Image(Westron.Icon.check)`, the adapter that keeps the symbol's own name |
| Mike | c, with a named element at the start | as Hotel, the start `Icon(.sun, label: "Today")` |
| Sierra, Tango, Uniform | where the trait comes from | trailing `Icon(.check, label: "Chosen")`, `Icon(.flag, label: "Flagged")`, `Icon(.checkCircle, label: "Done")` |
| November, Oscar | the system's choice list | `Form { Picker("Fruit", selection:) { … }.pickerStyle(.inline) }`, November chosen |
| Papa, Quebec | UIKit's choice list (iOS) | a `UITableView` whose first cell has `accessoryType = .checkmark` |

### The rows' elements

The row's element, as the probe printed it (`probe: <row> #0: …`), abridged: the empty value, `enabled true` on every
line, the raw trait bits and some frames left out, and the notes in parentheses added. iOS, from
`.build/logs/behavior-ios-CurrentValueProbeTests.log` (frames x, y, width, height in points):

```
probe: Alpha #0: type 9, label "Alpha, Current", selected true, frame (56.0, 77.7, 314.0, 44.0), traits [button selected staticText]
probe: Bravo #0: type 9, label "Bravo", selected false, frame (56.0, 121.7, 314.0, 44.0), traits [button staticText]
probe: Charlie #0: type 9, label "Charlie", selected false, frame (56.0, 165.7, 314.0, 44.0), traits [button staticText]
probe: Delta #0: type 9, label "Delta", selected true, frame (20.0, 209.7, 362.0, 44.0), traits [button selected staticText]
probe: Echo #0: type 9, label "Echo", selected true, frame (88.7, 253.7, 281.3, 44.0), traits [button selected staticText]
probe: Foxtrot #0: type 9, label "Foxtrot", selected true, frame (112.0, 297.7, 258.0, 44.0), traits [button selected staticText]
probe: Golf #0: type 48, label "Golf", selected true, frame (20.0, 341.7, 362.0, 44.0), traits [selected staticText]
probe: Hotel #0: type 9, label "Hotel", selected true, frame (56.0, 385.7, 314.0, 44.0), traits [button selected staticText]
probe: India #0: type 9, label "India", selected true, frame (56.0, 429.7, 314.0, 44.0), traits [button selected staticText]
probe: Juliet #0: type 9, label "Juliet", selected true, frame (56.0, 473.7, 314.0, 44.0), traits [button selected staticText]
probe: Kilo #0: type 9, label "Kilo", selected false, frame (56.0, 517.7, 314.0, 44.0), traits [button staticText]
probe: Lima #0: type 9, label "Lima", selected true, frame (56.0, 561.7, 314.0, 44.0), traits [button selected staticText]
probe: Mike #0: type 9, label "Mike", selected true, frame (88.7, 605.7, 281.3, 44.0), traits [button selected staticText]
probe: Sierra #0: type 9, label "Sierra, Chosen", selected true, traits [button selected staticText]
probe: Tango #0: type 9, label "Tango, Flagged", selected false, traits [button staticText]
probe: Uniform #0: type 9, label "Uniform, Done", selected true, traits [button selected staticText]
probe: Today #0: type 43, label "Today", selected true, frame (57.3, 266.7, 18.0, 18.3), traits [selected image]     (Echo's start)
probe: Task #0: type 40, label "Task foxtrot", value Optional(0), selected true, traits [button selected toggleButton] (Foxtrot's start)
probe: Today #1: type 43, label "Today", selected false, frame (57.3, 618.7, 18.0, 18.3), traits [image]            (Mike's start)
probe: November #0: type 9, label "November", selected true, traits [button selected]
probe: Oscar #0: type 9, label "Oscar", selected false, traits [button]
probe: cell #3: type 75, label "", selected true, frame (20.0, 1041.7, 362.0, 53.0), traits [selected]                (Papa)
probe: cell #4: type 75, label "", selected false, frame (20.0, 1094.7, 362.0, 53.0), traits []                       (Quebec)
```

The value of every ListRow element was empty, on both platforms. Under each row's button XCUITest also lists its words
and, where the check is, the check's image: `Image, identifier: 'checkmark', label: 'Current', Selected` under Alpha;
`Image, identifier: 'checkmark', Selected`, with no label, under every row with a decorative check (Charlie and Kilo
included, whose buttons are not selected); `Image, identifier: 'checkmark', label: 'Выбрано', Selected` under Lima.

macOS, from `.build/logs/behavior-macos-CurrentValueProbeTests.log` (screen points):

```
probe: Alpha #0: type 9, label "Alpha, Current", selected true, frame (560.0, 303.0, 632.0, 28.0)
probe: Bravo #0: type 9, label "Bravo", selected false, frame (560.0, 331.0, 632.0, 28.0)
probe: Charlie #0: type 9, label "Charlie", selected false, frame (560.0, 359.0, 632.0, 28.0)
probe: Delta #0: type 9, label "Delta", selected true, frame (524.0, 387.0, 680.0, 28.0)
probe: Echo #0: type 9, label "Echo", selected true, frame (588.0, 415.0, 604.0, 28.0)
probe: Foxtrot #0: type 9, label "Foxtrot", selected true, frame (604.0, 445.0, 588.0, 28.0)
probe: Golf #0: type 48, label "", value Optional(Golf), selected true, frame (524.0, 475.0, 680.0, 28.0)
probe: Hotel #0: type 9, label "Hotel", selected true, frame (560.0, 503.0, 632.0, 28.0)
probe: India #0: type 9, label "India", selected true, frame (560.0, 531.0, 632.0, 28.0)
probe: Juliet #0: type 9, label "Juliet", selected true, frame (560.0, 559.0, 632.0, 28.0)
probe: Kilo #0: type 9, label "Kilo", selected false, frame (560.0, 587.0, 632.0, 28.0)
probe: Lima #0: type 9, label "Lima", selected true, frame (560.0, 615.0, 632.0, 28.0)
probe: Mike #0: type 9, label "Mike", selected true, frame (588.0, 643.0, 604.0, 28.0)
probe: Sierra #0: type 9, label "Sierra, Chosen", selected true
probe: Tango #0: type 9, label "Tango, Flagged", selected false
probe: Uniform #0: type 9, label "Uniform, Done", selected true
probe: Today #0: type 43, label "Today", selected true, frame (561.0, 422.5, 14.0, 14.0)    (Echo's start)
probe: Task #0: type 12, label "Task foxtrot", value Optional(0), selected true            (Foxtrot's start, a CheckBox)
probe: Today #1: type 43, label "Today", selected false, frame (561.0, 650.5, 14.0, 14.0)   (Mike's start)
probe: November #0: type 10, label "November", value Optional(1), selected true            (a RadioButton in a RadioGroup)
probe: Oscar #0: type 10, label "Oscar", value Optional(0), selected false
```

On macOS no image is listed under a row's button, and the hierarchy holds no traits, only the type, the label, the value
and the selected state.

### The candidates, side by side

| Candidate | iOS 26.3 | macOS 26.7.1 | Drawn |
|---|---|---|---|
| a, stopgap: `Icon(.check, label: "Current")` | Button "Alpha, Current", value empty, traits button, selected | Button "Alpha, Current", selected | the check only |
| baseline: decorative check, no state | Button "Charlie", button, not selected | Button "Charlie", not selected | the check only |
| b: `.accessibilityAddTraits(.isSelected)` on the row | Button "Delta", button, selected; its frame the whole row (20, 362 wide) instead of the words' column (56, 314) | Button "Delta", selected; frame the whole row (524, 680 wide) instead of (560, 632) | the check only |
| b, a named Icon at the start | Button "Echo", selected, and the Icon "Today" selected too | the same | the check only |
| b, a Checkbox at the start | Button "Foxtrot", selected, and the Switch "Task foxtrot" selected too | Button selected, and the CheckBox "Task foxtrot" selected too | the check only |
| b, static form | StaticText "Golf", selected, frame the whole row | StaticText, value "Golf", selected, frame the whole row | the check only |
| b, on the check in the slot | Button "Kilo", not selected | Button "Kilo", not selected | the check only |
| c: `.chosen(true)` (prototype) | Button "Hotel", button, selected, words' column | Button "Hotel", selected, words' column | the check only |
| c, a named Icon at the start | Button "Mike", selected; the Icon "Today" not selected | the same | the check only |
| d: `.selected(true, drawn: false)` (prototype) | Button "India", button, selected, words' column | Button "India", selected, words' column | the check only |
| reference: `.selected(true)` | Button "Juliet", button, selected | Button "Juliet", selected | tint, bar, `body.strong` |
| system: inline `Picker` in a `Form` | the chosen option a Button, selected | a RadioButton, value 1, selected | the system's |
| UIKit: a `.checkmark` cell | the Cell, selected | — | the system's |

"Drawn" is from the screenshot of the probe (`.build/screenshots/ios-list-row-current-probe.png`, dark): Delta, Golf,
Hotel and India draw their check on no highlight, no bar and a regular title, as Charlie does; Juliet alone draws the
tint, the bar and the strong title. macOS draws from the same code and was not captured.

### What the measurements say

1. **The stopgap already announces selected** (a, confirmed on both platforms, as the pattern says). The trait is the
   system's, not ListRow's: an SF Symbol of the check family that is not hidden carries the selected trait, and the
   row's combined element takes it. `checkmark` and `checkmark.circle` carry it (Alpha, Sierra, Lima, Uniform);
   `flag` does not (Tango). The system's own spoken name for `checkmark` on this simulator is "Выбрано", Russian for
   "Selected" (Lima's image); in English it was not read. A decorative `Icon(.check)` is hidden, and the row does not
   take the trait from it (Charlie), nor from a trait written on it (Kilo). So the label "Current" is what unhides the
   check, and the trait comes with it. The label is then redundant, the same fact said twice, "Current" and
   "selected"; it is harmful in two ways: the product has to localize a word that only repeats the trait, and the
   trait hangs on an implementation detail no contract states, the SF Symbol behind `Westron.Icon.check` (a registry
   change to another glyph, or a product's own check, would silently drop it). How VoiceOver speaks the two together
   was not listened to.
2. **b works, and leaks.** Written on the row, the trait reaches the row's element on both platforms and in both
   forms, but SwiftUI applies it to every element of the row's representation: a named Icon at the start (Echo) and
   the Checkbox at the start (Foxtrot), which then announces "selected" on a task's check that has nothing to do with
   the choice. It also moves the element's frame from the words' column, which the contract gives, to the whole row,
   where nothing at the start is an element (Delta, Golf). The contract could not state it either: a system modifier
   on a westron view is no state of the contract, so nothing would carry it to the web, GTK or Android.
3. **c and d give the same tree** (Hotel, India), the same as today's `.selected` (Juliet) without the look, and leave a
   named element at the start alone (Mike against Echo). They differ in what they mean and what they cost (below).
4. **"Selected" is what Apple's own choice lists say on iOS.** SwiftUI's inline `Picker` marks the chosen option with
   the selected trait, and so does UIKit's checkmark cell. UIKit's header defines the trait so:
   `UIAccessibilityTraitSelected`: "Used when the element is selected. For example, a selected row in a table or a
   selected button within a segmented control." (`UIAccessibilityConstants.h`, the iOS SDK in Xcode 27.1). On the Mac
   the system's choice list is not a list of selected buttons but a radio group: the inline `Picker` is a `RadioGroup`
   whose chosen `RadioButton` has the value 1. A ListRow is a button there, so on the Mac a current value announced as
   selected is the iOS idiom carried over, not the Mac's; a radio role would be a role per platform, a larger change
   (question 3).

Not measured: what VoiceOver speaks and in what order, on either platform (the hierarchy is XCUITest's, not
VoiceOver's); whether VoiceOver stops on the decorative check's image that iOS lists under a row's button with no
label (it is a child of the combined element, not beside it as the tile of G5 is); iOS 17 and 18, macOS 14 and 15;
watchOS.

## Decision

A new state of ListRow, **`chosen`**: the row holds the current value of a single choice, such as the destination a
list stands in now in "Move to…". It draws nothing: no token binds it, so the row is drawn as at rest, and the product
draws the mark, the check in the trailing slot, decorative. It is announced as selected, as `selected` is. Both forms
enter it. On Apple it is the shared state modifier `.chosen(_:)`, a Bool through the environment, cascading as
`.selected(_:)` does (spec/conventions.md, "States the system control lacks"). A row both chosen and selected is drawn
selected and announced as selected once.

The product writes, in the pattern's `row(_:)`:

```swift
ListRow(level: choice.level, guides: false, action: { choose(choice) }) {
    Text(choice.title)
} leading: {
    IconTile(icon).category(category)
} trailing: {
    if choice.isCurrent { Icon(.check).foregroundStyle(.text.primary) }
}
.chosen(choice.isCurrent)
.disabled(!choice.isAvailable)
```

The two meanings stay two states. `selected` is the row that is open, its content shown beside it, as in a sidebar,
and draws its look; `chosen` is the current value among choices, and the check draws it. This is the reading of the
owner's decision of 2026-11-25 that keeps `.selected` meaning one thing.

### The contract's diff

```diff
@@ description (the sentence after the static form) @@
-  and enters no hover, focus or pressed. selected, disabled and dropTarget are set on either form by the product,
-  which knows the selection and the drag.
+  and enters no hover, focus or pressed. selected, chosen, disabled and dropTarget are set on either form by the
+  product, which knows the selection, the choice and the drag. chosen is the row that holds the current value of a
+  single choice, such as the destination a list stands in now in a "Move to…" sheet: it draws nothing of its own, the
+  row drawn as at rest, and the product marks it with the platform's check, decorative, in the trailing slot
+  (spec/patterns/choice-list-sheet.md); it is announced as selected is. selected is the row that is open, its content
+  shown beside it, as in a sidebar, and draws the look below; a row both selected and chosen is drawn selected.
@@ states @@
-states: [hover, focus, pressed, selected, disabled, dropTarget]
+states: [hover, focus, pressed, selected, chosen, disabled, dropTarget]
@@ forms @@
   pressable:
-    states: [hover, focus, pressed, selected, disabled, dropTarget]
+    states: [hover, focus, pressed, selected, chosen, disabled, dropTarget]
   static:
-    states: [selected, disabled, dropTarget]
+    states: [selected, chosen, disabled, dropTarget]
     accessibility:
-      states: { selected: selected, disabled: disabled }
+      states: { selected: selected, chosen: selected, disabled: disabled }
@@ accessibility @@
-  states: { selected: selected, disabled: disabled }
+  states: { selected: selected, chosen: selected, disabled: disabled }
   description: >-
-    … It is announced as selected while selected, and as unavailable while disabled.
+    … It is announced as selected while selected or chosen, and as unavailable while disabled; chosen adds no word of
+    its own, so the check that marks it is decorative and carries no label (decisions/0002).
@@ platforms.apple.description @@
-  … selected and dropTarget, which the system does not carry, are shared state modifiers through the environment,
-  named as the states: .selected(_:) and .dropTarget(_:), each a Bool, …
+  … selected, chosen and dropTarget, which the system does not carry, are shared state modifiers through the
+  environment, named as the states: .selected(_:), .chosen(_:) and .dropTarget(_:), each a Bool, …; the
+  representation's words carry isSelected while the row is selected or chosen, and only selected reaches the drawing.
@@ platforms.apple.watchos @@
-      states: [pressed, selected, disabled]
+      states: [pressed, selected, chosen, disabled]
@@ platforms.web.description @@
-  … aria-selected or aria-current for selected, decided with the library's shape.
+  … for selected, the open row, aria-current; for chosen, the current value of a choice, aria-selected on an option
+  of a listbox or aria-checked on a radio, decided with the library's shape (decisions/0002).
```

No `tokens` entry: `chosen` binds none, which is how it draws nothing.

### What each candidate costs in the tools (measured on a scratch copy of the tree)

- **c** is expressible today with no change to the tools. With the diff above, `tools/westron spec check` printed
  "contracts: 11, all valid"; `tools/westron generate` wrote 3 files: `WestronUI/Generated/ListRow+Contract.swift`
  (the case `ListRowState.chosen` and both forms' sets), `WestronCatalog/Generated/ListRow+Matrix.swift` (4 more
  combinations, 26 instead of 22, `chosen` listed as `unbound` beside `focus`, and the pressable form's rows
  re-paginated: `disabled` moves from the first sheet to the second), and the agent context's
  `context/components/list-row.md` (`….chosen(isChosen)`, `public func chosen(_: Bool) -> some View`, and the state's
  line). `tools/westron lint api-parity` then reported one problem, "missing: the state modifier of chosen, `public
  func chosen(_: Bool) -> some View` in extension View", and with that modifier written, "no problems";
  `generate --check` "all match"; `patterns check` "all valid".
- **d** has no place in the conventions. The prototype's `selected(_:drawn:)` failed the lint in this worktree:
  "public func View.selected: component API that no contract accounts for: selected(_: Bool, drawn: Bool) -> some View
  is named as the state selected, which ListRow's contract … does not give through the conventions". A state modifier
  is one Bool, named as the state (`APIParity.swift`, the state modifiers' expected functions); an argument needs the
  schema to say what a state's modifier takes, the lint and the agent context's card to follow, and conventions for
  the other platforms. And `.selected(_:)` is shared: an argument about ListRow's look would ride on every component
  that later takes `selected`.
- **b** costs nothing in the tools and gives nothing the contract can hold (above, 2).
- The prototype of c (`.chosen(_:)`) also failed the lint until the contract gave it, as it should: "public func
  View.chosen: a public modifier on View that no contract gives".

### The name

`chosen`, as the product's model already says it (`isCurrent` in the pattern's `Choice` would become the argument).
Against `current`: on the web `aria-current` is the attribute of the open item in a navigation, which is ListRow's
existing `selected` (the sidebar's row), so a state named `current` would point the web at the wrong attribute.
Against `checked`: Checkbox and Chip have `checked` as their Toggle's on, a system state carried by `isOn`; a shared
`.checked(_:)` modifier would compile on a westron Toggle and do nothing there. No SwiftUI style or modifier is named
`chosen`, so it shadows nothing (`.claude/rules/apple.md`; `SystemStyles.swift` holds no such name).

In the contract's platform-neutral vocabulary the concept is the current value of a single choice, which ARIA calls a
checked radio or a selected option of a listbox, and which Apple's iOS lists announce as selected (above, 4). The
contract maps `chosen` to the abstract accessible state `selected`, the one Apple announces; the web's attribute is
decided in phase 6 with the library's shape (the diff's `platforms.web`).

## Considered and rejected

- **Keep the stopgap** (a). It announces selected today, but by a property of one SF Symbol no contract states, and it
  makes the product say "Current" in words the trait already says.
- **A documented `.accessibilityAddTraits(.isSelected)` on the row** (b). Measured: the trait reaches the row and also
  every other element of the row, the Checkbox at a task row's start included, and the row's frame changes; and the
  contract cannot carry a system modifier to the other platforms.
- **The trait on the check** (b, Kilo). A decorative Icon is hidden, and the row does not take the trait from it.
- **An argument of `.selected(_:)`** (d). It draws the same tree as c, but says that a current value is the open row
  drawn differently, which is the reading the owner turned down; and it needs the schema, the lint and the
  conventions to give a state modifier arguments.
- **A role of its own, a radio button on the Mac** (the system's inline Picker). Question 3; not proposed now, since it
  changes the row's role per platform and the pilot's rows act on a press, as buttons do.

## Consequences

- A product marks a current value with `.chosen(_:)` and a decorative check; it never writes an accessibility trait
  on a westron row, and never labels the check.
- The selected trait no longer depends on the glyph behind `Westron.Icon.check`.
- Seen on the way, outside this decision: any labelled Icon of the check family in a row's trailing slot makes the row
  announced as selected (Uniform, `Icon(.checkCircle, label: "Done")`), whatever the product meant, because the
  system gives those symbols the trait and the row's element combines it. A task row with a "done" glyph at its end
  would be announced selected. This is Icon's, not ListRow's (a labelled `Icon` keeps the symbol's traits); it is
  reported, not decided here.

## What changes with the approval

For the implementation stage, one pull request (decisions/0005):

1. **The contract** `spec/components/list-row/list-row.spec.yaml`: the diff above, its header comment naming this
   decision; this decision's status set to accepted with the answers.
2. **Generated**: `tools/westron generate` (ListRow's states and forms in `WestronUI/Generated/ListRow+Contract.swift`,
   the matrix in `WestronCatalog/Generated/ListRow+Matrix.swift`, the agent context's card and index).
3. **WestronUI**: `States.swift`, `@Entry var isChosen` and `public func chosen(_:)` beside `.selected(_:)`, documented;
   `ListRow/ListRow.swift`, the representation's words selected while `isSelected || isChosen`, the highlight and the
   title's role reading `isSelected` alone; the type's documentation comment; the forced states of
   `ListRowCatalogSupport.swift` take `chosen` so that the matrix cell can set it.
4. **Catalog**: `ListRowMatrixCell` sets `chosen` for its combinations; the `list-row` entry gets a live chosen row; the
   pressable sheets' references change by the re-pagination and the new rows (recorded on CI by the label
   `record-snapshots`; the second gate's review of the matrix).
5. **Tests**: a unit test that `ListRowTokens` for `[.chosen]` equals at rest in both forms; `ListRowBehaviorTests`,
   the chosen row a Button selected on iOS and macOS, with a frame the words' column, and a named element at its
   start not selected.
6. **The pattern** `spec/patterns/choice-list-sheet.md` and its catalog copy `Patterns/ChoiceListSheet/ChoiceSheet.swift`
   (held equal by `PatternExampleTests`): `check(_:)` becomes `Icon(.check)` with no label and the rows get
   `.chosen(choice.isCurrent)`; the Parts row "The current choice" loses the label; rule 2 says the check marks it and
   `.chosen` announces it, and loses the stopgap; rule 6 loses "the check's label"; "Accessibility" reads "Project,
   button" selected, its trait ListRow's, and drops the paragraph on the symbol's trait; G1 leaves the front matter's
   `gaps` and the Gaps list. `ChoiceListSheetTests` follows: `Sample.mark` goes, the current row is found by its title,
   and the selected trait is asserted from ListRow, not the check's image.
7. **Documents**: `.claude/rules/apple.md` lists `.chosen(_:)` with ListRow's modifiers; the hand-written
   `plugins/westron/skills/westron/SKILL.md`, whose step on the states the system lacks names `.selected(_:)`, names
   `.chosen(_:)` beside it; the agent context regenerated (`tools/westron generate --check` holds it); the pattern
   check finds `.chosen(_:)` in WestronUI's declared API by itself (`PatternNames.swift`).
8. **Checks** for the pull request: `tools/check.sh`, `tools/apple/check.sh all`, `behavior ios|macos
   ListRowBehaviorTests ChoiceListSheetTests`, the audit of `list-row` and `choice-list-sheet`.

## The owner's answers

On 2026-11-27 the owner answered each question with its letter, "as recommended", and gave no reasons of his own. The
reasons under each answer are the proposal's, why it recommended that letter, kept here so that the record says what
was weighed:

1. **How a product says the row holds the current value: A**, a separate state `chosen`, `.chosen(_:)`, which draws
   nothing and is announced as selected. The proposal's reasons: not an argument of `.selected(_:)` (B), which would
   give one state two meanings and teach the schema, the lint and the conventions arguments on a state modifier; not a
   documented `.accessibilityAddTraits(.isSelected)` on the row (C), which leaks the trait to the Checkbox and any named
   element at the start and changes the row's frame; not the stopgap (D), the check labelled "Current", whose trait
   comes from the SF Symbol and whose word repeats it.
2. **The name: A**, `chosen`. The proposal's reasons: it says what the row is, and it points no platform at the wrong
   attribute; not `current` (B), whose web attribute `aria-current` belongs to the open row, `selected`; not `checked`
   (C), Checkbox's and Chip's Toggle on, whose shared modifier would compile on a Toggle and do nothing.
3. **What a chosen row is on the Mac: A**, a button announced as selected, as on iOS. The proposal's reasons: the row
   keeps one role on every Apple OS, and a press takes the choice and closes the sheet, as a button does; not a radio
   button with a value (B), the Mac's inline Picker's idiom, which would be a role per platform and a row whose press
   commits.
