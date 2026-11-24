---
id: choice-list-sheet
title: A list of choices in a sheet
status: proposed
summary: Pick one place or value from a list or a tree in a system sheet; the current choice checked, one tap takes one.
consumers: [todo-app/lists-screen]
components: [list-row, icon-tile, icon, rule, text]
tokens: [space.page.narrow, space.page.wide, space.within-group, typography.footnote.regular, color.text.secondary,
  color.text.primary]
icons: [check]
gaps: [G1, G2, G3, G4]
---

# A list of choices in a sheet

Status: a proposal for the owner, in the format decisions/0018 proposes (#35, stage 1). The rules follow the
recommendations (A) of the questions at the end, which are the owner's.

## When to use

A person picks one destination or value out of a list or a tree, more than a menu holds, and one tap takes it: the
pilot's "Move to…" sheet (todo-app's lists screen), a list's parent, a task's list. Not a SwiftUI `Picker`, which
stays where the system draws its own control, a menu or a wheel (the skill's rule 4).

## Parts

| Part | Built from | Why |
|---|---|---|
| The container | `.sheet`, a `NavigationStack`, `.navigationTitle`, the title inline on iOS, Cancel a system `Button` with `role: .cancel` at `.cancellationAction` | The system's (decisions/0014, 0015; chapter 09): no westron surface, shadow, glass or button style on the sheet or its bar |
| The rows' container | `ScrollView` and `LazyVStack(alignment: .leading, spacing: 0)`, padded `space.page.narrow` in the compact horizontal size class and `space.page.wide` otherwise and on the Mac (Q6) | The page margin is the product's (design-language/06); a row pads its own content and is at least `size.target.minimum` high |
| The hint | `Text` in `footnote.regular` and `text.secondary`, the first item of the scrolling content, centred, `space.within-group` above the rows (Q5) | `footnote.regular` is the role for a hint |
| A choice | A pressable `ListRow` at the item's `level`, `guides: false`; `IconTile(icon).category(category)` at the start; the name the title, in the row's own role | ListRow's `guides` names this case: the indent shows where a choice stands, and nothing folds here |
| The option that stands apart | The same row, first, at level 0: a neutral `IconTile` (`.category(nil)`) with the product's glyph (the pilot: `divider`) and words ("Top level") (Q7) | A list without a color gets the neutral tile (IconTile's decisions/0001) |
| The current choice | `.selected(true)` on its row and `Icon(.check)` in its trailing slot, in `text.primary`; no other row has anything at its end (Q1, Q2) | The platform's mark and trait for a current value; an icon takes its text's color (design-language/07) |
| A section that can be chosen | A pressable `ListRow` whose title is the section's labelled `Rule(name)` (Q3) | The tree's look, the row's press, height and states |
| A section that is only a heading | A static `ListRow`, no action, whose title is `Rule(name)` (Q4) | Lines up with the rows' content at every text size |
| A choice that cannot be taken | `.disabled(true)` on its row | The row dims whole at `opacity.disabled`, its tile with it, and takes no press |

## Rules

1. One tap takes a choice and the product closes the sheet; Cancel closes it with nothing changed. The current choice
   stays enabled: taking it again changes nothing.
2. A place the item cannot go, such as the item itself and what is inside it, is disabled, not left out, so that the
   sheet keeps the shape of the tree a person knows from the screen.
3. The check is a glyph, not a Checkbox: one choice of many is no row's on or off (Checkbox's decisions/0001, P12).
4. The words are the product's: a title that names what moves ("Move “Core” to…", design-language/01), a section's
   label in capitals written by the product (Rule's contract), a name for an unnamed section (Q3).
5. A product with views of its own named `Icon` or `Rule` writes `WestronUI.Icon` and `WestronUI.Rule`.

## Accessibility

What VoiceOver is meant to read: the title and Cancel, the system's; the hint, as text; each row as one button named
by its words, "Inbox, button"; the current one "Project, selected, button", its check decorative; an unavailable one
"Core, dimmed, button"; a nested row's level as more content, "Level, 2" (ListRow's contract). A section that can be
chosen should read "WORK, button" and one that is only a heading "WORK, heading": whether the Rule's heading trait
joins the row's combined element, and how capitals are spoken, is not measured (G3). At the accessibility text sizes
the check moves under the title (ListRow's contract); no row sets one line there.

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
        // westron-lint: allow the Mac sheet's least size, which no token gives (spec/patterns/choice-list-sheet, G4)
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

Each would be an issue against westron if the owner wants it; none is designed here.

- **G1** (only with Q1 (B)): ListRow cannot carry `isSelected` to assistive technology without drawing the selection.
  Issue: "ListRow: a current choice announced as selected without the selected highlight".
- **G2** (only with Q2 (B)): no way to keep a trailing slot's room without content that stacks under the title at the
  accessibility sizes. Issue: "ListRow: an empty trailing slot that keeps its width and adds no height".
- **G3**: a pressable row whose title is a labelled Rule may be read as a heading inside a button, unmeasured; and a row
  whose title draws no words, an unnamed section's line, has no accessible name, since no initializer takes a label.
  Issue: "ListRow and Rule: the name and traits of a section that is a choice".
- **G4**: no token for a sheet's least size on the Mac, where a sheet is as large as what it holds and a scroll view
  asks for no height. Issue: "Tokens: a least size for a sheet on macOS".

## Questions

- **Q1. The current choice.** (A, recommended) `.selected(true)` and a decorative check: it is announced "selected", as
  the platform's current value is, and the check is the platform's mark; the tint, the bar and the strong title come
  with it, a look the pilot's sheet did not have. (B) A check labelled "Current", no `.selected`: quiet, the spike's;
  read "Project, Current, button", without the trait (G1). (C) `.selected(true)` alone: no check, the platform's mark
  lost.
- **Q2. The rows' end.** (A, recommended) The check on the current row only: with nothing else in the slot it stands at
  the row's end on whichever row has it. (B) A hidden check on every other row (`Icon(.check).hidden()`), the owner's
  ruling for the pilot's own sheet (cited by the spike as "#163's thread r4431052930"): titles truncate at one column,
  but at the accessibility sizes every row grows by a hidden line (G2).
- **Q3. A section that can be chosen.** (A, recommended) A pressable row with `Rule(name)`, and an unnamed section
  given drawn words by the product ("Untitled area"), since a choice needs a name. (B) The same, an unnamed section the
  line alone: a button with no name until G3 closes. (C) A plain row with the name as `Text`: no line, so the sheet no
  longer echoes the tree.
- **Q4. A section that is only a heading.** (A, recommended) A static `ListRow { Rule(name) }`. (B) A bare `Rule(name)`
  between the rows: its label starts at the page margin, not with the rows' content, unless the product repeats the
  row's padding, which ListRow scales and stops at xxxLarge.
- **Q5. The hint.** (A, recommended) The first item of the scrolling content: it scrolls away, and needs no ground
  over the system's sheet. (B) Pinned in `.safeAreaInset(edge: .top)`: it needs a ground, westron's canvas against the
  system's sheet or a material westron does not draw. (C) The bar's own `.navigationSubtitle(_:)` (iOS 26, macOS 11 in
  the SDK), with (A) before iOS 26: the system's, but how a sheet's bar shows it is not verified.
- **Q6. The rows' container.** (A, recommended) `ScrollView` and `LazyVStack`: the rows as ListRow draws them, westron's
  margin; no arrow keys between rows on the Mac, only Tab with keyboard navigation on. (B) A `List`, the row given
  `.listRowInsets(EdgeInsets())`, `.listRowBackground(Color.clear)` and `.listRowSeparator(.hidden)` and no List
  selection (ListRow's contract): the Mac's arrow keys, but iOS sets the rows 8 pt apart (measured, ListRow's
  decisions/0001) and the margin goes into the insets.
- **Q7. "Top level".** (A, recommended) The first row at level 0, set apart by its neutral tile and its place.
  (B) A `Rule()` under it as well. (C) The tree one level under it, as its children: every row 24 pt further in.
- **Q8. The Mac's sheet size.** (A, recommended) The product's numbers under `#if os(macOS)` with the lint's
  `// westron-lint: allow <reason>` naming G4, as above. (B) `.presentationSizing(.form)` (macOS 15, iOS 18), with
  (A) on macOS 14; whether it gives a scroll view a height is not measured. (C) A token, after G4's issue.
