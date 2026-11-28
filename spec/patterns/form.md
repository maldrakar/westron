---
id: form
title: A form
status: approved
summary: Fields a person fills and the product keeps; framed fields with a label above, an error or a hint under each, Cancel and one primary Button at the end, or inline fields kept as they are typed.
consumers: [todo-app/quick-entry, todo-app/lists-screen, todo-app/list-screen]
components: [text-field, button, text, icon]
tokens: [typography.heading.medium, typography.heading.small, typography.subheadline.regular,
  typography.footnote.medium, typography.footnote.regular, color.text.primary, color.text.secondary,
  color.text.placeholder, color.status.danger.text, color.status.danger.icon, space.50, space.75, space.100,
  space.within-group, space.between-groups, space.page.narrow, space.page.wide]
icons: [xmarkCircleFill]
gaps: [G1, G2]
---

# A form

Approved by the coordinating agent on 2026-11-27 under the owner's delegation of that day (decisions/0018). The third
pattern of #35 (decisions/0018, point 6).

## When to use

A person types one or more values and the product keeps them. There are two kinds, and a screen uses one of them:

- **A form that is submitted.** Nothing is kept until the person says so, with the form's one primary action; Cancel
  leaves with nothing kept. The pilot's quick entry (todo-app, `QuickEntryView`, `docs/specs/navigation.md`, section
  5): a sheet with the title of a new task, Cancel and Add, and the sentence "A title cannot be empty." when Add comes
  with nothing typed. Quick entry is not one of the two screens decisions/0006 names; it is the pilot's one form that
  is submitted (navigation.md, section 5), and so this kind's consumer. A technical product's "New service": a name, a
  repository's address, an optional branch.
- **Fields kept in place.** The fields stand in what they belong to and what is typed is kept as it is typed, with no
  button: the pilot's open task card, its title and its notes (todo-app's list screen, section 3), and a list's or an
  area's name typed in its row (the lists screen, sections 2 and 6).

Not for:

- **Search.** A search field is TextField's own case (its contract: framed, `magnifier` at its start, the search
  trait), or the system's `.searchable`.
- **A choice.** One of many is the pattern `choice-list-sheet`, a menu, or the system's `Picker`; on or off is a
  Checkbox or the system's `Toggle`.
- **A screen of settings**, a system `Form` of toggles and pickers, which the pattern `settings` will cover when a
  product has one (decisions/0018, point 6).
- **An error that is no field's**: a save that failed, a lost connection, a confirmation. They are the pattern
  `errors`; a field's error is this pattern's.

## Parts

| Part | Built from | Why |
|---|---|---|
| The container | The product's `ScrollView` and a `VStack(alignment: .leading)`, padded `space.page.narrow` in the compact horizontal size class and `space.page.wide` otherwise and on the Mac; in a system `.sheet` for a form that is submitted | Not a SwiftUI `Form` or `List` (rule 1). The scroll view keeps the focused field above the keyboard and every field reachable at the largest text sizes |
| The form's title | `Text` in `heading.medium`, `text.primary`, with the header trait, the form's first line | Names what the form makes ("New task"), so a field needs no label of its own where the form has one field (rule 4). `heading.medium` is the role of a card's or a section's title (design-language/03) |
| A field that stands on its own | `TextField(…).textFieldStyle(.framed)`, its prompt `Text(…).foregroundStyle(.text.placeholder)`, named with `.accessibilityLabel(_:)` | TextField's contract: framed is the field that stands on its own, the name typed in a row too (decisions/0014). The system field's title is no accessible name on iOS and outside a `Form` on macOS (TextField's decisions/0001, I2), so the product names it. The prompt's color is the product's to set (I1) |
| A field set into what it belongs to | `TextField(…).textFieldStyle(.inline)` in the text role and color of the text it stands in: a card's title in `heading.small` and `text.primary`, its notes in `subheadline.regular` and `text.secondary`, `axis: .vertical` | TextField's contract: inline is a card's title and notes; the roles are design-language/03's for a block's title and for notes |
| A field's label | `Text` above the field in `footnote.medium` and `text.secondary`, `space.75` above it, hidden from assistive technology; the field carries the same words as its name | `footnote.medium` is the role of a small label (design-language/03); the words are read once, as the field's name, where VoiceOver stops on the field (rule 4) |
| A field's hint | `Text` under the field in `footnote.regular` and `text.secondary`, `space.75` below it | `footnote.regular` is the role of a hint (design-language/03), as in `choice-list-sheet`; it stays while the person types, which a prompt does not |
| A field's error | An `HStack(alignment: .firstTextBaseline, spacing: .space50)` under the field, in the hint's place: `Icon(.xmarkCircleFill)` in `status.danger.icon`, decorative, and the product's sentence in `footnote.regular` and `status.danger.text` | danger is a failure's status, and a status shows its glyph and its words (design-language/02, 07: `xmarkCircleFill` is danger's); the words carry the error, so color is not its only signal (design-language/08). The field itself draws no state of error: TextField has none (G1) |
| The actions | Cancel, a `Button` with `.buttonStyle(.secondary, size: .m)` and `.keyboardShortcut(.cancelAction)`, then the primary, `.buttonStyle(.primary, size: .m)` with `.loading(_:)`, in the form, at its end and its trailing edge, not in the sheet's bar; on one line, and one under the other, in the same order and each the form's width, at the accessibility text sizes (`AnyLayout`) | primary is "the one main action on a screen" (Button's contract); secondary sits beside it without a second accent. Rules 7 to 9 |
| The space | `space.75` inside a field's group (label, field, message); `space.within-group` between fields; the actions `space.between-groups` below the last field (`space.within-group` and as much padding) | A field and its words read as one group, the fields as items of one, and the actions as the next group (design-language/06: twice the gap inside a group). A focused field's ring, drawn outside it at `stroke.thick`, fits in each gap |

## Rules

1. **Not the system's `Form`.** A form westron styles stands in the product's scroll view, not in a SwiftUI `Form` or
   `List`. On iOS a `Form` sets each field in a grouped cell of the system's own ground, so a framed field's fill would
   stand in a second ground with the cell's insets around it; on macOS it lays its labels out in a column of its own
   and makes the field's title its label (TextField's decisions/0001, I2), which a westron label above the field would
   repeat; and westron's focus ring is drawn outside the field, in room that no clipping parent may take (TextField's
   contract), which a system row's insets are not made to leave (not measured in a `Form`). The page margins
   are for layout the product builds, and a system `Form` keeps its own insets (design-language/06), so a screen that
   is a system `Form` keeps the system's fields and look: that is the pattern `settings`, not this one.
2. **The sheet and its keyboard stay the system's.** A form that is submitted stands in a system `.sheet`
   (decisions/0014, "What stays the system's"); its swipe down is the same as Cancel. westron draws nothing over the
   sheet: no surface, shadow, glass or style of its own. Unlike `choice-list-sheet`, the form puts no
   `NavigationStack` in the sheet: its title is its own first line, not `.navigationTitle`, and Cancel stands with the
   primary action at the form's end, not in the system's bar at `.cancellationAction` (rule 7 says why). The
   keyboard, its Return key and its text input stay the system's: a field says what it holds with the system's
   `.submitLabel(_:)`, `.keyboardType(_:)`, `.textContentType(_:)`, `.textInputAutocapitalization(_:)` and
   `.autocorrectionDisabled()` (an address takes the URL keyboard, no capitals and no correction). On the Mac the sheet
   needs a least size of its own, as `choice-list-sheet`'s rule 7 and its G4 (#172) say, since a scroll view asks for
   no height.
3. **Framed or inline.** A form's fields, and a name typed in a row, are framed: each stands on its own, filled. A
   thing's own text typed where it is shown, a card's title and notes, is inline, in the role and color of that text
   (TextField's contract). The pilot's row being renamed is replaced, for that time, by the product's framed field at
   size `s` where the row's title stood (ListRow's contract: a row's title holds no control; the pilot's row field is
   about `s`, TextField's decisions/0001). One form never mixes the two.
4. **Every field has a name; the label above it is drawn where the form has more than one field.** A field of a form
   with two fields or more has its label above it, in words that name what it holds, in sentence case with no colon:
   "Name", "Repository". A prompt is not a label, since it goes as the person types (TextField's contract). The one
   field of a form whose title names it, "New task", has no drawn label: the title names it, and its prompt is an
   example, "Buy milk" (rule 5). An inline field is named by its place, the card's title at its top and its notes
   under it, and its prompt stands in for its text while it is empty ("New task", "Notes", the pilot's words). Every
   field, drawn label or not, is named with `.accessibilityLabel(_:)`: in the drawn label's words, or, where there is
   none, in a word for what it holds, "Title", "Notes"; a drawn label is hidden from assistive technology, so that its
   words are read once, as the field's name, where the field is. Labels stand above their fields at every text size,
   never beside them, so nothing moves to another line at the largest sizes.
5. **The prompt is an example, in `text.placeholder`.** A framed field's prompt shows what to type, an example of its
   form ("Buy milk", "https://git.example.com/billing") or its default ("main"), and never an instruction a person
   still needs once they type: that is the hint. An inline field's prompt stands in for its text (rule 4). Every
   prompt is written `Text("…").foregroundStyle(.text.placeholder)`: the system's own placeholder gray measures 1.72:1
   on the canvas on iOS, `text.placeholder` 5.27:1 (TextField's decisions/0001, I1); macOS ignores the color and draws
   the system's (TextField's contract).
6. **Optional fields say so; required ones say nothing.** Most fields of a form are required, so the few that are not
   carry "(optional)" in their label and their name: "Branch (optional)". No asterisk: a symbol needs a legend, and
   VoiceOver reads it as "star". A field that is optional says in its hint what its empty value means ("Without one,
   the repository’s default branch.").
7. **Cancel and the primary action end the form, in the form, not in the sheet's bar.** Cancel, secondary, then the
   primary, at the form's trailing edge under its last field: read and reached by Tab after the fields, as the focus
   order follows the reading order (design-language/08), and the same in a sheet, a popover or a page. The primary's
   label is a verb for what the form does, "Add", "Create" (design-language/01). This is where the pilot's quick entry
   has them: `HStack { Spacer(); Button("Cancel"); Button("Add") }` in the sheet's content, under the field (todo-app,
   `Apps/Apple/Sources/TodoAppleUI/QuickEntryView.swift`).

   It differs from `choice-list-sheet`, which sets its title in `.navigationTitle` and Cancel in the system's bar at
   `.cancellationAction`, and from the iOS convention: Apple's own sheets that make something new, such as a new event
   in Calendar, put Cancel and the confirming action in the navigation bar, at `.cancellationAction` and
   `.confirmationAction`. A choice sheet has no primary action, one tap on a row commits, and Cancel is its one control
   besides the rows, which the bar holds well. A form has a primary action that comes after its fields and loads while
   the product saves (rule 9). A bar's items are the system's buttons: bars and toolbars stay the system's and westron
   does not restyle them (decisions/0015, design-language/09), so a primary action there would not be westron's Button
   and would have no `.loading(_:)`. On iOS the bar also stands before the content, so VoiceOver would reach the
   action before the fields it acts on (not measured). On macOS the system is held to place `.cancellationAction` and
   `.confirmationAction` at the sheet's bottom-trailing edge, where this pattern puts them anyway (not measured). The
   cost is plain: a product with both sheets, the pilot with Move to… and quick entry, has Cancel in two places, in
   the bar's leading corner of one sheet and at the end of the other's form. No case is argued here for a form that
   takes the bar instead ("Not covered").

   The actions stand on one line, and at the accessibility text sizes one under the other, in the same order, each the
   form's width: there two labels may not fit a phone's width side by side, and Button's contract leaves the room to
   the product, by stacking the buttons or giving them the full width; two buttons of one width read as one pair, and
   each is as easy to reach. The two layouts are one `AnyLayout` around the same buttons, so the buttons keep their
   identity as the text size changes: with `ViewThatFits`, which holds each layout's own copy of the buttons, the
   audit reported "Dynamic Type font sizes are partially unsupported" on all four buttons of the catalog's entry, and
   with `AnyLayout` it does not (iOS 26.3, 2026-11-27; the cause was not established).
8. **The primary action is never disabled for what the fields hold.** A press, or Return in the last field, with a
   value the product refuses shows the error under that field (rule 10) and keeps what was typed. A disabled button
   cannot say why it is disabled, which design-language/01 asks of a disabled option, is drawn at `opacity.disabled`
   below the text contrast, and would leave Return doing nothing. The pilot's quick entry does the same: Add stays
   enabled and an empty title is refused with its sentence (todo-app, `QuickEntry.add()`).
9. **While the product saves, the primary action loads.** `.loading(isSaving)` on the primary button for a save that
   waits: it keeps its label, takes no press and announces "Loading" (Button's contract), and the form ignores Return
   until the save ends. A draft the product refuses never loads: the form asks for the product's check first and saves
   only a draft the check took. A save that does not wait, the pilot's quick entry, sets nothing. What the screen says
   about a save that takes long, and what Cancel does during one, are the pattern `loading`'s; a save that fails is
   `errors`'.
10. **A field's error stands under the field, in the hint's place, from the submit until the field changes.** The
    product checks the fields when the form is submitted, not as the person types, since an address is not wrong
    while it is half typed. A field it refuses shows the product's sentence under it, the hint gone while it stands,
    and the first field in error, in the form's order, takes the caret; the sentence is posted as an announcement, so
    that VoiceOver says it even where the caret already was. The product's check returns its sentences, and the form
    shows, announces and focuses from what it returns, not from what a binding reads back right after: a binding over
    a model the view holds as a value (the pilot's `private let model`, changed through a synchronous `send`) reads
    the value of the last update until the next one, and the first refusal would then announce nothing and move no
    caret. The person's next change to that field takes the sentence
    away (the pilot's rule: "a keystroke clears it"). The sentence says what the field needs, in the product's words,
    with a period: "A title cannot be empty.", "Enter an address that starts with https://."; no "Error:", no
    "invalid", no exclamation mark (design-language/01). The same holds for a field in place: a list's refused name
    stands under the row's field, where the pilot's lists screen today shows it at the bottom of the screen, which is
    read last and far from the field.
11. **Return moves on, and submits from the last field.** In a form that is submitted, Return in a field moves the
    caret to the next field (`.submitLabel(.next)`), and in the last field submits (`.submitLabel(.done)`), so a person
    fills the form without leaving the keyboard; Esc, where there is one, is Cancel
    (`.keyboardShortcut(.cancelAction)`). The primary button takes no `.keyboardShortcut(.defaultAction)`: Return is
    the field's, and a default action could take it from every field and submit from the first (inferred: without one,
    Return moves from field to field on the Mac as on iOS, "Accessibility"; with one, not measured). In place, Return
    keeps what was typed and ends the editing (the pilot's card's title and a row's name); a card's notes,
    `axis: .vertical`, take Return as the system's field of several lines does (not measured here).
12. **A form opened to make something new focuses its first field; one opened on what exists does not.** Quick entry
    and "New service" open with the caret in their first field, the keyboard up, since they open to be typed in: the
    form sets its focus in `.onAppear`, as the pilot's quick entry does. In a sheet over a window already open, the
    pattern's case (rule 2), the focus holds on iOS and on macOS; as a window's first content it holds on iOS and not
    on macOS ("Accessibility"). There a focus set in `.onAppear` or in `.task`, or given with `.defaultFocus(_:_:)`,
    was dropped, though the window was key and the app active when the form appeared, and one set a turn of the main
    queue later, from `DispatchQueue.main.async` in `.onAppear`, held (macOS 27.2.1, 2026-11-28, the catalog's entry
    with a diagnostic build; the cause was not established). A product whose form is the first content of a Mac
    window, a window of its own for a new thing rather than a sheet, meets that. A stored task's card opens with no
    caret, so that its whole is seen before the keyboard covers half of it; a task just added opens its card with the
    caret in its empty title (the pilot's `focusesOnAppear: model.title.text.isEmpty`; not measured here, the
    catalog's card opens on a stored task).
13. **Every text size.** The fields grow with their text (TextField's contract), the labels, hints and errors wrap,
    and the form scrolls. Nothing in the form is set beside a field, so nothing reflows but the actions (rule 7).

## Accessibility

Measured on the catalog's entry `form` by its UI test `FormTests` and the accessibility audit (2026-11-27, the iOS 26.3
simulator, iPhone 17; macOS 27.2.1 on 2026-11-28: see below). Each form reads in its order: the title, a heading
("New task, heading"), then each field, the words under it, and the actions. A field is one text field named by the
words of its label, or by a word for what it holds where it has none: "Title", "Name", "Repository", "Branch
(optional)", "Notes"; its value is its text, and an empty field's value is its prompt ("Buy milk", "main"). A drawn
label is no element of its own, so its words are read once, on the field. An error is a text of its own right after
its field, "Enter an address that starts with https://.", 6 pt under the field's frame and before the next field's;
its glyph adds no element (the entry has no image element), and the hint it stands in for is not there. A hint is a
text after its field, "Without one, the repository’s default branch.". The actions are buttons named by their words,
"Cancel" and "Add", "Cancel" and "Create", 36 pt high at `size: .m`, after the last field. No field holds the focus
when the page appears; with the quick entry's `focusesOnAppear` true, its field does, and the keyboard rises, both as
the page's first content and in a `.sheet` the page presents from a button (launched with `-WestronFormSheet`), where
Return after a title adds it and closes the sheet.

What the pattern promises, measured by the same test: Add with an empty title shows "A title cannot be empty." under
the field and above the actions, the field takes the caret, and nothing is added; Add again, with the caret moved to
another field, gives it back to the title, the sentence still one text; a keystroke takes the sentence away. Return in
the empty field refuses it the same way, and Return after a title adds it. "New service" opens with its address
refused, and a change to the address takes the sentence away. Then Return moves the caret from Name to Repository to
Branch, and from Branch submits: the address, still without https, is refused, its sentence comes back, Repository
takes the caret, Create does not load, and no save begins: the page records a save as it begins, the one moment
Create starts to load, so a loading however brief would leave its line. With the address typed again with https,
Return moves on to Branch and submits from it: Create, still enabled, has the value "Loading" while the product
saves, and none after.
Cancel runs its form's action and nothing is added. Not measured: what VoiceOver says when the sentence is announced
(`AccessibilityNotification.Announcement`), since a UI test hears nothing; whether VoiceOver's cursor follows the
caret to the field in error; and Esc on Cancel, which needs a hardware keyboard.

The audit passes its five tests (the default settings, the dark and both high-contrast themes, the accessibility text
sizes) with one finding suppressed: "Text clipped" on the field "Repository", "Text of this UITextField may be clipped
at larger Dynamic Type sizes", at the default size and the accessibility sizes. The message is a forecast: at the
default size the sample's address takes about 60% of the field's width and shows whole; at accessibility3 it is cut
short, "http://git.exam…", and a field of one line scrolls a longer text sideways while it is edited (TextField's
contract, `lines`); a product whose values are often longer than a phone's field meets the same finding. With the
actions in a `ViewThatFits`, the audit also reported "Dynamic Type font sizes are partially unsupported" on all four
buttons; with `AnyLayout` (rule 7) it does not, and the cause was not established.

On macOS (27.2.1, 2026-11-28, the catalog's window at 720 × 540 pt) what assistive technology meets is as above, and
Add refused under the field with the caret given back, Return moving from Name to Repository to Branch and submitting
from Branch, a refused draft not loading and no save begun, Create loading while the product saves, and Cancel hold
(`FormTests`, two runs). Quick entry as the window's first content does not take the focus (rule 12): with
`focusesOnAppear` true its field held no focus within 5 s, in three runs; the test that measures that case is skipped
on macOS, with this reason in its message. In the sheet the page presents over its open window, the pilot's case, the
field takes the focus as the form appears. Return in quick entry's empty field right after the launch once refused
nothing (one run of two), and it was typed with no wait for the field's focus; the test now waits for the focus before
it types, and with the wait Return refused it in the one run measured, whose typing of letters is not measured: the
Mac's keyboard layout was Russian then, and XCTest timed out typing Latin letters into every field. Esc on Cancel is
not measured. The macOS audit reports three findings, none on the form's elements:
"Contrast failed" on the catalog window's title, "Westron Catalog", and "Element has no description" on the window's
group and on the menu bar, in four of its five tests (the dark high-contrast theme passes); the entry `environment`
gets the same three on this Mac. They are the catalog window's and the system's, and are not suppressed: the macOS
audit is not triaged yet, and CI runs the audit on iOS alone (platforms/apple/README.md, "Accessibility audit").

## Apple

The catalog's entry `form` runs this code (decisions/0018, stage 2):
`platforms/apple/Sources/WestronCatalog/Patterns/Form/Forms.swift` is this block, character for character, and
`PatternExampleTests` fails when the two differ. The entry shows three samples one under the other on the canvas, at
the page margin, as a sheet's content stands, with no sheet around them: the pilot's quick entry, live; "New service",
opened with its repository's error showing; and the pilot's card's title and notes, inline, without the card's ground,
the pilot's raised Surface (decisions/0014). That ground is left out for the catalog's sake alone: drawn in the entry,
Surface would put it in the pull-request audit of every change to Surface, which already selects 5 entries, the limit
(`fan_out_limit` in `tools/apple/audit-scope.sh`), and would go past it. A product sets the fields on its card as the
pilot does. A product presents a form that is submitted in its sheet as the pilot presents quick entry:
`.sheet(isPresented: $isAdding) { ScrollView { TaskEntryForm(title: $draft, problem: $problem, add: add, cancel: {
isAdding = false }).padding(.space.page.narrow) } }`, where `add` keeps the task, closes the sheet and returns nil, or
returns its sentence; with `space.page.wide` in the regular size class and on the Mac, where the sheet also takes its
least size (rule 2). The pilot's view sends its gestures through a `send` that returns nothing (`QuickEntryView`'s
`send: (QuickEntry.UserAction) -> Void`), so its `add` would check first and send after, returning the module's
sentence for a title that trims to nothing, "A title cannot be empty.", or nil and then sending `.addButtonTapped`.
"New service" splits the product's part in two, `check`, which returns the sentences by field,
and `save`, which runs only for a draft `check` took (rules 9 and 10).

```swift
import SwiftUI
import WestronUI

/// A framed field with what stands around it: its visible label above it, and under it its error, or its hint.
struct FormField<Field: View>: View {
    var label: LocalizedStringKey? = nil  // nil where the form's title names its one field
    var hint: LocalizedStringKey? = nil  // what a person needs to fill it, kept while they type
    // The product's sentence refusing what it holds; stands in the hint's place. A String, not a key: the product's
    // check makes it at run time, in the person's language, and the form shows it as it comes.
    var error: String? = nil
    @ViewBuilder let field: Field  // the TextField, named with the label's words

    var body: some View {
        VStack(alignment: .leading, spacing: .space75) {
            if let label {
                Text(label)
                    .textRole(.footnote.medium)
                    .foregroundStyle(.text.secondary)
                    .accessibilityHidden(true)  // the field carries the same words as its name
            }
            field
            if let error {
                HStack(alignment: .firstTextBaseline, spacing: .space50) {
                    Icon(.xmarkCircleFill).foregroundStyle(.status.danger.icon)
                    Text(error).foregroundStyle(.status.danger.text)
                }
                .textRole(.footnote.regular)
            } else if let hint {
                Text(hint)
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
            }
        }
    }
}

/// The end of a form that is submitted: Cancel, then its one primary action; one under the other, each the form's
/// width, at the accessibility text sizes.
struct FormActions: View {
    let primary: LocalizedStringKey  // a verb for what the form does: "Add", "Create"
    var isLoading = false  // while the product saves
    let submit: () -> Void
    let cancel: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        // One layout or the other around the same buttons, so that they keep their identity as the text size changes.
        let stacked = textSize.isAccessibilitySize
        let layout =
            stacked
            ? AnyLayout(VStackLayout(spacing: .space.withinGroup))
            : AnyLayout(HStackLayout(spacing: .space.withinGroup))
        layout {
            Button(action: cancel) { label("Cancel", wide: stacked) }
                .buttonStyle(.secondary, size: .m)
                #if !os(watchOS)
                    .keyboardShortcut(.cancelAction)  // Esc
                #endif
            Button(action: submit) { label(primary, wide: stacked) }
                .buttonStyle(.primary, size: .m)
                .loading(isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    /// A button's words; stacked, they take the form's width, and the button with them.
    private func label(_ words: LocalizedStringKey, wide: Bool) -> some View {
        Text(words).frame(maxWidth: wide ? .infinity : nil)
    }
}

/// The form's title, the first thing it reads.
struct FormTitle: View {
    let text: LocalizedStringKey  // what the form makes: "New task"

    var body: some View {
        Text(text)
            .textRole(.heading.medium)
            .foregroundStyle(.text.primary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The pilot's quick entry: one field that names a new task, and Add.
struct TaskEntryForm: View {
    @Binding var title: String
    @Binding var problem: String?  // shown under the field: what `add` last refused the title with
    var focusesOnAppear = true  // it opens to be typed in
    let add: () -> String?  // keeps the task and closes the sheet; or returns why not: "A title cannot be empty."
    let cancel: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .space.withinGroup) {
            FormTitle(text: "New task")
            FormField(error: problem) {
                TextField("Title", text: $title, prompt: Text("Buy milk").foregroundStyle(.text.placeholder))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Title")
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(submit)
            }
            FormActions(primary: "Add", submit: submit, cancel: cancel)
                .padding(.top, .space.withinGroup)
        }
        .onChange(of: title) { problem = nil }  // a keystroke takes the sentence away
        .onAppear { if focusesOnAppear { focused = true } }
    }

    private func submit() {
        // What `add` returns, not what the binding reads back, which a product's model may not show until its next
        // update.
        let refusal = add()
        problem = refusal
        if let refusal {
            AccessibilityNotification.Announcement(refusal).post()
            focused = true
        }
    }
}

/// A technical product's form of several fields: a label on each, a hint, an optional field, and a save that waits.
struct ServiceDraft {
    enum Field: CaseIterable { case name, repository, branch }  // in the form's order
    var name = ""
    var repository = ""
    var branch = ""  // optional: the repository's default branch when empty
}

struct ServiceForm: View {
    @Binding var draft: ServiceDraft
    @Binding var errors: [ServiceDraft.Field: String]  // shown under the fields: what `check` last refused, by field
    var focusesOnAppear = true
    let check: () -> [ServiceDraft.Field: String]  // the product's sentences refusing fields; none where it takes them
    let save: () async -> Void  // keeps the draft `check` took and closes the sheet
    let cancel: () -> Void
    @State private var isSaving = false
    @FocusState private var focused: ServiceDraft.Field?

    var body: some View {
        VStack(alignment: .leading, spacing: .space.withinGroup) {
            FormTitle(text: "New service")
            FormField(label: "Name", error: errors[.name]) {
                TextField("Name", text: $draft.name, prompt: Text("billing").foregroundStyle(.text.placeholder))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Name")
                    .focused($focused, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focused = .repository }
            }
            FormField(label: "Repository", hint: "Deployments build from this address.", error: errors[.repository]) {
                TextField(
                    "Repository", text: $draft.repository,
                    prompt: Text("https://git.example.com/billing").foregroundStyle(.text.placeholder)
                )
                .textFieldStyle(.framed)
                .accessibilityLabel("Repository")
                #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .focused($focused, equals: .repository)
                .submitLabel(.next)
                .onSubmit { focused = .branch }
            }
            FormField(label: "Branch (optional)", hint: "Without one, the repository’s default branch.") {
                TextField("Branch", text: $draft.branch, prompt: Text("main").foregroundStyle(.text.placeholder))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Branch (optional)")
                    .autocorrectionDisabled()
                    .focused($focused, equals: .branch)
                    .submitLabel(.done)
                    .onSubmit(submit)
            }
            FormActions(primary: "Create", isLoading: isSaving, submit: submit, cancel: cancel)
                .padding(.top, .space.withinGroup)
        }
        .onChange(of: draft.name) { errors[.name] = nil }
        .onChange(of: draft.repository) { errors[.repository] = nil }
        .onAppear { if focusesOnAppear { focused = .name } }
    }

    private func submit() {
        guard !isSaving else { return }  // Return while it saves
        // What `check` returns, not what the binding reads back, which a product's model may not show until its next
        // update.
        let refusals = check()
        errors = refusals
        // The first field in error takes the caret, and its sentence is announced; a refused draft does not load.
        if let field = ServiceDraft.Field.allCases.first(where: { refusals[$0] != nil }), let error = refusals[field] {
            AccessibilityNotification.Announcement(error).post()
            focused = field
            return
        }
        isSaving = true
        Task {
            await save()
            isSaving = false
        }
    }
}

/// The pilot's task card: the task's own title and notes, typed where they stand and kept as they are typed.
struct TaskCardFields: View {
    @Binding var title: String
    @Binding var notes: String
    var isNew = false  // a task just added: its empty title takes the caret
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .space100) {
            TextField("Title", text: $title, prompt: Text("New task").foregroundStyle(.text.placeholder))
                .textFieldStyle(.inline)
                .accessibilityLabel("Title")
                .textRole(.heading.small)
                .foregroundStyle(.text.primary)
                .focused($titleFocused)
            TextField(
                "Notes", text: $notes, prompt: Text("Notes").foregroundStyle(.text.placeholder), axis: .vertical
            )
            .textFieldStyle(.inline)
            .accessibilityLabel("Notes")
            .textRole(.subheadline.regular)
            .foregroundStyle(.text.secondary)
        }
        .onAppear { if isNew { titleFocused = true } }
    }
}
```

## Not covered

Errors that are no field's, a save that failed and a confirmation (the pattern `errors`); what a screen shows while a
save takes long (the pattern `loading`); a screen of settings in a system `Form` (the pattern `settings`); checking a
field as it is typed; a field with a control in it, a clear mark or a button that shows a password (TextField's
contract has no slot for a control); a form of several steps or pages; dates, pickers and choices in a form; asking
before a sheet with typed text is swiped away (`.interactiveDismissDisabled(_:)`, the system's); a form whose Cancel and
primary action stand in the sheet's navigation bar, as on iOS Apple's own sheets that make something new have them
(rule 7: no case for it is argued here); the macOS sheet's own
size (`choice-list-sheet`'s G4); watchOS (#34), where a field opens the system's text input; the web, with phase 6.

## Gaps

None is an issue yet: a gap becomes one only at the owner's word (decisions/0018, "Consequences").

- **G1**: TextField has no state of error. Its contract left it for a consumer ("There is no error state, hint or
  message in this version: no pilot screen shows one"), and the pilot shows one: quick entry's and the lists screen's
  "A title cannot be empty." So a field in error looks as it did, and nothing ties the sentence to the field for
  assistive technology: VoiceOver on the field does not say it. Meanwhile the product puts the sentence under the
  field as text of its own, read after the field, announces it when it appears and gives the field the caret (rule
  10), with tokens and components only. The sentence is not also the field's `.accessibilityHint(_:)`: VoiceOver
  would read it twice, on the field and as the text under it, unless that text were hidden from it, and hidden it
  would be left to a hint, which a person can turn off in VoiceOver's settings; a text under the field is read in its
  order by every reader (not measured). Issue, if the owner opens one: "TextField: a field in error, its sentence
  joined to the field and announced".
- **G2**: a field's drawn label is not its accessible name. On Apple the system field's title names nothing outside a
  `Form` (TextField's decisions/0001, I2), and westron has no label of a field's own, so a product writes the label's
  words twice, once drawn and hidden, once in `.accessibilityLabel(_:)`, and a hint is a text beside the field rather
  than the field's own description; it is not the field's `.accessibilityHint(_:)` either, for G1's reasons. Issue,
  if the owner opens one: "TextField: a label and a hint that are the field's
  own".
