---
id: empty-state
title: An empty state
status: proposed
summary: What a screen shows when it has nothing; the system's ContentUnavailableView with the thing's IconTile, a title, a line that says what fills it and at most one action.
consumers: [todo-app/list-screen]
components: [icon-tile, text, button]
tokens: [typography.heading.medium, typography.subheadline.regular, color.text.primary, color.text.secondary]
icons: [list, tray, magnifier]
gaps: [G1]
---

# An empty state

Proposed by an agent on 2026-11-26 (#35, decisions/0018, point 6: the second pattern). Not approved: its questions
are open.

## When to use

A screen, or the whole content of a pane, has nothing to show, and that is its state, not a failure and not a wait:
the pilot's list with no task in it (todo-app's list screen, `TaskList.emptyWords`: "Nothing here yet" over "Add a
task here, or drag one in."; Trash's "Trash is empty"; Logbook's "Nothing done yet"; a new list's "A new list"), a
service with no deployments yet. The screen keeps its own header and bars; the empty state stands where its content
would.

Not for:

- **Content that is still loading.** A read that has not finished is not empty: the screen shows the system's
  `ProgressView` until it has (the pattern `loading`, decisions/0018, point 6), and only an answer of nothing shows an
  empty state. "Nothing here yet" before the read ends would be a false sentence (design-language/01, "Never invent a
  cause").
- **A failure.** A read that failed says what failed and what state the data is in (design-language/01, "Say what
  happened and what it left"), in the pattern `errors`; an empty state would hide it.
- **An empty section of a list.** A block, a group or a column with nothing in it keeps its header and the row that
  adds to it, as the pilot's empty blocks keep "+ Add task" so that a list just added has a place to put a task. A
  tile and a title there would be a screen's state drawn inside one part of a screen, and would push the sections
  after it down by a screenful.
- **A search or a filter that leaves nothing.** Undecided: Q3.

## Parts

| Part | Built from | Why |
|---|---|---|
| The container | The system's `ContentUnavailableView`, its label, description and actions | The system's (decisions/0014, "What stays the system's"; chapter 09): it centres its parts, spaces them and sets their reading order. westron gives it its content, not a style: SwiftUI has no style for it |
| The mark | `IconTile(icon)` in the label's icon, decorative, in the `.category(_:)` of the empty thing; `.imageScale(.large)` on it | The tile is the empty thing's own mark, the one its rows and header show (IconTile's contract names the empty screen). In the icon slot it takes the font the system gives that icon: at `medium` it measured 39 pt at the default text size, at `large` 52 (G1) |
| The title | `Text` in the label's title, `.textRole(.heading.medium)` and `.foregroundStyle(.text.primary)` | `heading.medium` is the role of "the title of … an empty state" (design-language/03). The system sets its own font and color on the slot; the role and the color written on the `Text` are what hold |
| The message | `Text` in the description, `.textRole(.subheadline.regular)` and `.foregroundStyle(.text.secondary)` | `subheadline.regular` is supporting text (design-language/03), the pilot's notes font under its empty title; `text.secondary` meets the text contrast on the canvas, which the system's own gray for the slot is not held to |
| The action, where there is one | A `Button` in the actions, `.buttonStyle(.primary, size: .m)` | The one thing that fills the screen is its main action, and primary is "the one main action on a screen". The system sets a small control size in the slot, which drew size `s` (28 pt on iOS); the size written holds `m` (Q2) |

## Rules

1. **The screen keeps what it has.** The empty state takes the content's place, not the screen's: the header, the
   bars and the floating buttons stay. In the pilot it stands under the list's header in the same scroll view, where
   the blocks would be, and on the board above the columns, as the pilot draws it; over a `List` that has no rows it
   is the list's `.overlay`, so the list keeps its bars. It is laid out in the room it is given and centred there.
2. **The tile is the thing's own, and decorative.** A list's empty screen shows the list's tile in the list's color,
   `IconTile(list.icon).category(Westron.Category(rawValue: list.color))`. A screen that is no list's has the neutral
   tile, `.category(nil)`, with the glyph of what would fill it (`tray` for a service's deployments). The tile carries
   no label: the title names the state and the screen's header names the thing, so a label would only repeat them
   (IconTile's contract). Never the accent, and never a symbol of the system's spelled out: the glyph is a name of the
   registry.
3. **The words are the product's, and say two things** (design-language/01, "An empty screen names its state and
   says what will fill it"). The title names the state in a few words, in sentence case, with no period: "Nothing
   here yet", "Trash is empty", "No deployments yet". The message says what fills the screen, in one or two
   sentences that end with a period, naming what a person does or what will arrive: "Add a task here, or drag one
   in.", "Tasks that match this list’s rule will show up here.", "Each deployment of this service will show up here."
   No apology, no exclamation mark, no "we", and "you" only where the sentence needs it; curly quotes and apostrophes.
   A message about what a person can do names the control they will use as it is labelled on the screen.
4. **At most one action, and only where the screen offers no other way.** The pilot's list has none: its "+" floats
   over the screen and "+ Add task" ends every block, so a button in the empty state would be a second primary
   action doing the same thing. A screen whose only way to be filled would otherwise be a menu or another screen
   gives that one action here, labelled with a verb (design-language/01, "Labels are verbs for actions"): "Deploy",
   "Add task", "New list". A command that asks for more before it acts ends with an ellipsis, "Import…". Two actions,
   or a link to help beside the action, are not covered.
5. **Every `Text` writes its role and its color.** The system styles the label's title and the description itself;
   westron reaches into a system view only through what the product puts in its slots (decisions/0014). Leave out
   `.textRole(_:)` or `.foregroundStyle(_:)` and the slot draws the system's own font or gray. The button writes its
   variant and its size for the same reason.
6. **Every text size.** The tile, the title and the message grow with Dynamic Type, and the system wraps the words;
   at the accessibility sizes a tile and three lines fill a phone's screen, so the empty state stands in a scroll
   view, as the pilot's list does, or over a `List`, which scrolls.
7. **The empty state goes when content comes.** The product shows it when its read answers nothing and removes it on
   the first row; it is never shown beside rows.

## Accessibility

Measured on the catalog's entry `empty-state` by its UI test `EmptyStateTests` and the accessibility audit
(2026-11-26, the iOS 26.3 simulator; macOS: see below). The empty state is read in its order, title, message, action.
The label is one text element named by the title, "Nothing here yet": its frame holds the tile and the title, and the
tile adds no word; no image element stands beside it, so the decorative tile is hidden here, unlike beside a row's
title (the first pattern's G5, #174). The title has the static text trait and no heading trait: the screen's own
title is its heading, and the system gives the empty state's title none (Q4). The message is a text of its own,
"Add a task here, or drag one in.". The action is one button named by its words, "Deploy, button", 90 × 36 pt at
`size: .m` (76 × 28 pt with no size, Q2), and a press runs it once. The accessibility audit of the entry passes its
five tests (the default settings, the dark and both high-contrast themes, the accessibility text sizes) with one
finding suppressed: "Contrast failed" on the label of the sample with the neutral tile, "No deployments yet", in the
four themes at the default text size. The label's element is named by the title and its frame holds the tile, and
the finding goes when the same tile takes a list color (teal, a probe), and never comes on the first sample's teal
tile; so the audit is taken to measure the neutral tile's ground, `background.muted` on the canvas, which IconTile's
contract holds to no contrast minimum, while the title is `text.primary` on the canvas. A product's own audit of an
empty state with the neutral tile may meet the same finding.

On macOS the entry was not measured: on 2026-11-26 the Mac's catalog rendered no entry for its screenshot UI test,
this one or any other (the screen was not free), so the Mac's reading, the macOS audit and the Mac's screenshots are
still to be taken.

## Apple

The catalog's entry `empty-state` runs this code (decisions/0018, stage 2):
`platforms/apple/Sources/WestronCatalog/Patterns/EmptyState/EmptyState.swift` is this block, character for
character, and `PatternExampleTests` fails when the two differ. The entry shows two samples one under the other on
the canvas: the pilot's empty list, with its tile in teal and no action, and a technical product's screen of
deployments, with the neutral tile and the action "Deploy". A product calls it in place of its content, as the pilot
does under its header: `if tasks.isEmpty { EmptyState(icon: list.icon, category: list.color, title: words.title,
message: words.text) }`.

```swift
import SwiftUI
import WestronUI

struct EmptyAction {  // the one action that fills the screen, where the screen shows no other way to
    let title: String  // a verb: "Add task", "Deploy"
    let run: () -> Void
}

struct EmptyState: View {
    let icon: Westron.Icon  // the empty thing's own glyph, as the product stores it
    let category: Westron.Category?  // its list color; nil draws the neutral tile
    let title: String  // names the state: "Nothing here yet"
    let message: String  // says what will fill it
    var action: EmptyAction? = nil

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
                    .textRole(.heading.medium)
                    .foregroundStyle(.text.primary)
            } icon: {
                IconTile(icon)
                    .imageScale(.large)
                    .category(category)
            }
        } description: {
            Text(message)
                .textRole(.subheadline.regular)
                .foregroundStyle(.text.secondary)
        } actions: {
            if let action {
                Button(action.title, action: action.run)
                    .buttonStyle(.primary, size: .m)
            }
        }
    }
}
```

## Not covered

Loading (the pattern `loading`) and failures (the pattern `errors`); an empty section of a list, which keeps its
header and its add row ("When to use"); two actions, or help beside the action; an illustration in the tile's place,
which design-language/01 leaves open (its question 5); an empty sidebar, menu or picker; watchOS (#34); the web, with
phase 6.

## Gaps

None is an issue yet: a gap becomes one only at the owner's word (decisions/0018, "Consequences").

- **G1**: IconTile has no size of its own, only the relative scale against the text role around it, and in
  `ContentUnavailableView`'s icon slot it takes the font the system gives that icon: 39 pt at `medium` and 52 pt at
  `large` at the default text size on the iOS 26.3 simulator, measured on the entry's screenshots, where the pilot's
  canvas draws its empty screen's tile at 64 pt (todo-app, `TaskList.Metrics`, "the tile 64 across"). No option or
  token gives an empty screen's tile the pilot's size. Meanwhile a product writes `.imageScale(.large)` on the tile
  (Q1). Issue, if the owner opens one: "IconTile: the size of an empty screen's tile".

## Questions

1. **How large is the tile?** (a) `.imageScale(.large)`, 52 pt at the default text size, as the example writes: the
   nearest the contract's relative scale comes to the pilot's 64 pt, and it keeps the tile larger than the title
   below it, as the pilot's canvas does. (b) The slot's own size, `medium`, 39 pt: no call, and the size the system
   chose for its icon, but a tile not much taller than two lines of the title. (c) The pilot's 64 pt, through a
   revision of IconTile's contract or a token (G1): the first gate, not this pattern. Recommended: (a).
2. **Which size is the action?** (a) `size: .m`, written, 36 pt on iOS, as the example writes: the size westron's
   buttons take by default elsewhere, so the action matches the screen's other buttons. (b) No size: the system's slot
   sets a small control size, and the button drew `s`, 28 pt on iOS, smaller than the title above it; its hit area
   stays the platform's. Recommended: (a).
3. **What does a search or a filter that leaves nothing show?** The pilot's list shows its empty state when the tag
   bar's filter leaves no row, with the words of an empty list; its search is not built yet. (a) This pattern, with
   words that name what was searched or filtered and say how to widen it ("No tasks tagged #home", "Clear the filter
   to see every task."), the neutral tile with `magnifier`, and the action that clears the filter where the screen
   shows no other way: one look for every empty state, westron's colors and roles. (b) For a search, the system's
   `ContentUnavailableView.search(text:)` as it is: localized words for nothing, but the system's font and gray, which
   are not held to westron's contrast on the canvas, beside empty states in westron's look. (c) Neither here: the
   search and the filter decide it in a pattern of their own. Recommended: (a).
4. **Is the title a heading?** The system gives it no heading trait (measured, "Accessibility"). (a) Leave it so: the
   screen's own title is its heading, and the empty state is its content, read in order after it. (b)
   `.accessibilityAddTraits(.isHeader)` on the title, so that a person moving by headings lands on the state: but a
   screen with a header then has two headings for one thing. Recommended: (a).
