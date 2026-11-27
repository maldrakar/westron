---
id: choice-list-sheet
title: A list of choices in a sheet
status: approved
summary: Pick one place or value from a list or a tree in a system sheet; the current choice checked, one tap takes one.
consumers: [todo-app/lists-screen]
components: [list-row, icon-tile, icon, rule, text]
tokens: [space.page.narrow, space.page.wide, space.within-group, typography.footnote.regular, color.text.secondary,
  color.text.primary]
icons: [check]
gaps: [G3, G4, G5]
---

# A list of choices in a sheet

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
| The current choice | `Icon(.check)`, decorative, in its row's trailing slot, in `text.primary`, and `.chosen(true)` on the row, not `.selected`; no other row has anything at its end | The check alone marks it, the platform's mark for a current value; `.chosen` announces the row as selected and draws nothing (ListRow's decisions/0002, #176). An icon takes its text's color (design-language/07) |
| A section that can be chosen | A pressable `ListRow` whose title is the section's labelled `Rule(name)` | The tree's look, the row's press, height and states |
| A section that is only a heading | A static `ListRow`, no action, whose title is `Rule(name)` | Lines up with the rows' content at every text size; a bare `Rule(name)` between the rows would start at the page margin unless the product repeated the row's padding, which ListRow scales |
| A choice that cannot be taken | `.disabled(true)` on its row | The row dims whole at `opacity.disabled`, its tile with it, and takes no press |

## Rules

1. One tap takes a choice and the product closes the sheet; Cancel closes it with nothing changed. The current choice
   stays enabled: taking it again changes nothing.
2. The current choice is marked by the check alone, decorative, with no label, and its row is `.chosen(_:)`, which
   announces it as selected and draws nothing (ListRow's decisions/0002, #176); its row is not `.selected`. The
   selected highlight, bar and strong title would be a second and a third mark of what the check already says, and
   `.selected` means the row that is open, as in a sidebar, not the current value. The owner first chose `.selected`
   with a decorative check and changed it on seeing it drawn in the catalog's example (2026-11-25); until #176 the
   check carried the label "Current", which brought the selected trait from the system's `checkmark` symbol, and the
   owner approved `.chosen` on 2026-11-27. A label on the check would say the trait again in words, so it has none.
3. Only the current row has a check. With nothing else in the slot, the check stands at the row's end on whichever row
   has it; a hidden check on every other row would keep the titles to one column, but at the accessibility sizes,
   where a trailing slot moves under the title, every row would grow by a hidden line.
4. A place the item cannot go, such as the item itself and what is inside it, is disabled, not left out, so that the
   sheet keeps the shape of the tree a person knows from the screen.
5. The check is a glyph, not a Checkbox: one choice of many is no row's on or off (Checkbox's decisions/0001, P12).
6. The words are the product's: a title that names what moves ("Move “Core” to…", design-language/01), a section's
   label in capitals written by the product (Rule's contract), and drawn words for an unnamed section ("Untitled area"), since a choice needs a name and a line alone would be a button with none
   (G3).
7. On the Mac the product gives the sheet a least size of its own, under `#if os(macOS)` and marked for the
   raw-values lint, until a token exists (G4). `.presentationSizing(.form)` is not used: macOS 14 lacks it, and
   whether it gives a scroll view a height is not measured.
8. A product with views of its own named `Icon` or `Rule` writes `WestronUI.Icon` and `WestronUI.Rule`.

## Accessibility

Measured on the catalog's entry `choice-list-sheet` by its UI test `ChoiceListSheetTests` (2026-11-25, the iOS 26.3
simulator and macOS 26.7; the traits on iOS alone, where the hierarchy holds them, the selected state on both; the
current choice measured again with `.chosen` on 2026-11-27, below). The title and Cancel are the system's; on iOS the
title is the bar's heading. The hint is text. Each choice is one button named by its words, "Inbox, button": the tile
adds no word. The current one is the button "Project", selected, "Project, selected, button": `.chosen` gives the row's
element the selected trait, and no other row has it; the check adds no word (iOS 26.3, 2026-11-27: traits button,
selected and static text, its frame the words' column). On iOS the hierarchy still lists the decorative check under
the row's button, inside its frame, as an image with no label, the identifier `checkmark` and the selected trait, the
system's for that symbol; the audit reports nothing on it, and whether VoiceOver stops on it was not listened to. How
VoiceOver speaks the trait was not listened to. When a press takes another row, the check and the selected state move
to it. An
unavailable one is a button that is not enabled, "Core, dimmed, button". A nested row's level is ListRow's custom
content, "Level, 2", which the hierarchy a UI test reads does not hold; ListRow's unit tests hold it. A
section that can be chosen is one button named by its label as written, "WORK", and on iOS it carries the heading
trait as well as the button's: the Rule's heading trait joins the row's combined element, so it is announced as a
button and a heading at once (G3, #171). One that is only a heading is text with the heading trait, "PERSONAL,
heading", and no button. How VoiceOver speaks the capitals was not listened to: the name is the label as the product
writes it. At the accessibility text sizes the check moves under the title (ListRow's contract; the entry's screenshot
at accessibility3); no row sets one line there. On iOS the hierarchy also lists each decorative tile as an image with
no name beside its row, against IconTile's contract, which the audit's description check does not report (G5, #174);
whether VoiceOver stops on it was not listened to. The accessibility audit fails Cancel's contrast on the CI
runner's iOS 27.0 simulator, in every theme and text size, and not on iOS 26.3, where its pixels are black on white
glass; the button and its ground are the system's, so the catalog suppresses the finding, and a product's audit of its
own sheet on iOS 27 may meet it too.

## Apple

The catalog's entry `choice-list-sheet` runs this code (decisions/0018, stage 2):
`platforms/apple/Sources/WestronCatalog/Patterns/ChoiceListSheet/ChoiceSheet.swift` is this block, character for
character, and `PatternExampleTests` fails when the two differ. On iOS the entry shows the sheet's content alone, on
macOS a real sheet over a page, where it measured 549 × 465 pt with the least size below (macOS 26.7). The iOS entry
draws no sheet's ground, so the contrast its audit and screenshots see there is against the page's ground, not a
sheet's.

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
                        .multilineTextAlignment(.center)
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
            .chosen(choice.isCurrent)
            .disabled(!choice.isAvailable)
        case .section:
            ListRow(level: choice.level, guides: false, action: { choose(choice) }) {
                Rule(choice.title)
            } trailing: {
                check(choice)
            }
            .chosen(choice.isCurrent)
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

- **G3** (#171): a pressable row whose title is a labelled Rule is one element with both the button and the heading
  traits, announced as a heading and a button at once (measured on iOS 26.3, 2026-11-25, "Accessibility" above); and a
  row whose title draws no words, an unnamed section's line, has no accessible name, since no initializer takes
  a label. Issue: "ListRow and Rule: the name and traits of a section that is a choice".
- **G4** (#172): no token for a sheet's least size on the Mac, where a sheet is as large as what it holds and a scroll
  view asks for no height. Issue: "Tokens: a least size for a sheet on macOS".
- **G5** (#174): a decorative IconTile in a ListRow's leading slot is an unnamed image element beside the row on iOS,
  against IconTile's contract; whether VoiceOver stops on it has not been listened to (measured on iOS 26.3,
  2026-11-25, "Accessibility" above; `ChoiceListSheetTests` pins it). Issue: "ListRow and IconTile: a decorative tile
  in a row's leading slot is an unnamed image element on iOS".
