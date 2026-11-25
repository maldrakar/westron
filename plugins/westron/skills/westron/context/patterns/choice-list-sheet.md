<!-- Generated from spec/patterns/choice-list-sheet.md by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->
<!-- One of westron's patterns, copied without its front matter. Links to the rest of westron's repository are left as
their text, and a reference such as "decisions/0014", "design-language/06" or "#171" points into westron's repository;
the chapters are in `../design-language/`, the cards in `../components/`. -->

# A list of choices in a sheet

`choice-list-sheet` · approved · used by todo-app/lists-screen · composes [ListRow](../components/list-row.md),
[IconTile](../components/icon-tile.md), [Icon](../components/icon.md), [Rule](../components/rule.md) and
[Text](../components/text.md)

Approved by the owner on 2026-11-25, with decisions/0018 (#35, stage 1).

## When to use

A person picks one destination or value out of a list or a tree, more than a menu holds, and one tap takes it: the
pilot's "Move to…" sheet (todo-app's lists screen), a list's parent, a task's list. Not a SwiftUI `Picker`, which
stays where the system draws its own control, a menu or a wheel (the skill's rule 4).

## Parts

| Part | Built from | Why |
|---|---|---|
| The container | `.sheet`, a `NavigationStack`, `.navigationTitle`, the title inline on iOS, Cancel a system `Button` with `role: .cancel` at `.cancellationAction` | The system's (decisions/0014, 0015; chapter 09): no westron surface, shadow, glass or button style on the sheet or its bar |
| The rows' container | `ScrollView` and `LazyVStack(alignment: .leading, spacing: 0)`, padded `space.page.narrow` in the compact horizontal size class and `space.page.wide` otherwise and on the Mac | The rows as ListRow draws them and the page margin the product's (design-language/06); a row pads its own content and is at least `size.target.minimum` high. Not a `List`: iOS sets its rows 8 pt apart (ListRow's decisions/0001) and the margin would go into its insets; the cost is that the Mac moves between rows with Tab when keyboard navigation is on, not with the arrow keys |
| The hint | `Text` in `footnote.regular` and `text.secondary`, the first item of the scrolling content, centred, `space.within-group` above the rows | `footnote.regular` is the role for a hint. It scrolls away, so it needs no ground over the system's sheet; pinned above the rows it would need one, which westron does not draw |
| A choice | A pressable `ListRow` at the item's `level`, `guides: false`; `IconTile(icon).category(category)` at the start; the name the title, in the row's own role | ListRow's `guides` names this case: the indent shows where a choice stands, and nothing folds here |
| The option that stands apart | The same row, first, at level 0: a neutral `IconTile` (`.category(nil)`) with the product's glyph (the pilot: `divider`) and words ("Top level") | A list without a color gets the neutral tile (IconTile's decisions/0001). Its tile and its place set it apart: no Rule under it, and the tree keeps its own levels rather than becoming its children, every row a level further in |
| The current choice | `.selected(true)` on its row and `Icon(.check)` in its trailing slot, in `text.primary`; no other row has anything at its end | The platform's mark and trait for a current value; an icon takes its text's color (design-language/07) |
| A section that can be chosen | A pressable `ListRow` whose title is the section's labelled `Rule(name)` | The tree's look, the row's press, height and states |
| A section that is only a heading | A static `ListRow`, no action, whose title is `Rule(name)` | Lines up with the rows' content at every text size; a bare `Rule(name)` between the rows would start at the page margin unless the product repeated the row's padding, which ListRow scales |
| A choice that cannot be taken | `.disabled(true)` on its row | The row dims whole at `opacity.disabled`, its tile with it, and takes no press |

## Rules

1. One tap takes a choice and the product closes the sheet; Cancel closes it with nothing changed. The current choice
   stays enabled: taking it again changes nothing.
2. The current choice is `.selected(true)` with a decorative check, so it is announced "selected", as the platform's
   current value is, and keeps the platform's mark. The selected highlight, bar and strong title come with it, a look
   the pilot's sheet did not have; the owner chose it knowing that, before seeing it drawn, and looks at it in the
   catalog example of stage 2, at the second gate.
3. Only the current row has a check. With nothing else in the slot, the check stands at the row's end on whichever row
   has it; a hidden check on every other row would keep the titles to one column, but at the accessibility sizes,
   where a trailing slot moves under the title, every row would grow by a hidden line.
4. A place the item cannot go, such as the item itself and what is inside it, is disabled, not left out, so that the
   sheet keeps the shape of the tree a person knows from the screen.
5. The check is a glyph, not a Checkbox: one choice of many is no row's on or off (Checkbox's decisions/0001, P12).
6. The words are the product's: a title that names what moves ("Move “Core” to…", design-language/01), a section's
   label in capitals written by the product (Rule's contract), and drawn words for an unnamed section ("Untitled
   area"), since a choice needs a name and a line alone would be a button with none (G3).
7. On the Mac the product gives the sheet a least size of its own, under `#if os(macOS)` and marked for the
   raw-values lint, until a token exists (G4). `.presentationSizing(.form)` is not used: macOS 14 lacks it, and
   whether it gives a scroll view a height is not measured.
8. A product with views of its own named `Icon` or `Rule` writes `WestronUI.Icon` and `WestronUI.Rule`.

## Accessibility

What VoiceOver is meant to read: the title and Cancel, the system's; the hint, as text; each row as one button named
by its words, "Inbox, button"; the current one "Project, selected, button", its check decorative; an unavailable one
"Core, dimmed, button"; a nested row's level as more content, "Level, 2" (ListRow's contract). A section that can be
chosen should read "WORK, button" and one that is only a heading "WORK, heading": whether the Rule's heading trait
joins the row's combined element, and how capitals are spoken, is not measured (G3, #171). At the accessibility text
sizes the check moves under the title (ListRow's contract); no row sets one line there.

## Apple

Compiled on 2026-11-24 against westron at `9f91fa1` from a scratch package, for macOS and the iOS simulator; not run.

```swift
import SwiftUI
import WestronUI

struct Choice: Identifiable {  // the product's model: words, a level and westron's vocabulary
    enum Kind { case item(Westron.Icon, Westron.Category?), section, heading }
    let id: String
    let kind: Kind
    let title: String  // a section's in capitals
    var level = 0
    var isCurrent = false
    var isAvailable = true
}

struct ChoiceSheet: View {
    let title: String
    let hint: String
    let choices: [Choice]  // "Top level" first, then the tree in order
    let choose: (Choice) -> Void
    let cancel: () -> Void
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text(hint)
                        .textRole(.footnote.regular)
                        .foregroundStyle(.text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, .space.withinGroup)
                    ForEach(choices) { row($0) }
                }
                .padding(.horizontal, pageMargin)
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", role: .cancel, action: cancel) }
            }
        }
        #if os(macOS)
        // westron-lint: allow the Mac sheet's least size, no token yet (spec/patterns/choice-list-sheet, G4, #172)
        .frame(minWidth: 320, minHeight: 400)
        #endif
    }

    @ViewBuilder private func row(_ choice: Choice) -> some View {
        switch choice.kind {
        case .item(let icon, let category):
            ListRow(level: choice.level, guides: false, action: { choose(choice) }) {
                Text(choice.title)
            } leading: {
                IconTile(icon).category(category)
            } trailing: {
                check(choice)
            }
            .selected(choice.isCurrent)
            .disabled(!choice.isAvailable)
        case .section:
            ListRow(level: choice.level, guides: false, action: { choose(choice) }) {
                Rule(choice.title)
            } trailing: {
                check(choice)
            }
            .selected(choice.isCurrent)
            .disabled(!choice.isAvailable)
        case .heading:
            ListRow(level: choice.level, guides: false) { Rule(choice.title) }
        }
    }

    @ViewBuilder private func check(_ choice: Choice) -> some View {
        if choice.isCurrent { Icon(.check).foregroundStyle(.text.primary) }
    }

    private var pageMargin: CGFloat {
        #if os(iOS)
        sizeClass == .compact ? .space.page.narrow : .space.page.wide
        #else
        .space.page.wide
        #endif
    }
}
```

## Not covered

Several choices at once, or choices confirmed with Done; search in the sheet (`.searchable`, the system's); a list
short enough for a `Menu`; making a new destination from the sheet; a popover instead of a sheet; watchOS (#34); the
web, with phase 6.

## Gaps

Each is an issue against westron, opened at the owner's word on 2026-11-25; none is designed here.

- **G3** (#171): a pressable row whose title is a labelled Rule may be read as a heading inside a button, unmeasured;
  and a row whose title draws no words, an unnamed section's line, has no accessible name, since no initializer takes
  a label. Issue: "ListRow and Rule: the name and traits of a section that is a choice".
- **G4** (#172): no token for a sheet's least size on the Mac, where a sheet is as large as what it holds and a scroll
  view asks for no height. Issue: "Tokens: a least size for a sheet on macOS".
