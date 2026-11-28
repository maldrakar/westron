---
id: errors
title: Errors beyond a field
status: approved
summary: How a screen says that something failed, or asks before what cannot be undone; the system's alert with a destructive action and Cancel for a confirmation, a status line in place, with a retry where one can mend it, for a failure.
consumers: [todo-app/lists-screen, todo-app/list-screen, todo-app/quick-entry]
components: [icon, text, button]
tokens: [typography.body.regular, color.status.danger.icon, color.status.danger.text, color.status.danger.background,
  color.status.danger.border, space.100, space.within-group, space.card, radius.card, stroke.thin]
icons: [xmarkCircleFill]
gaps: [G1, G2]
---

# Errors beyond a field

Approved by the coordinating agent on 2026-11-28 under the owner's delegation of 2026-11-27 (decisions/0018). The
fourth pattern of #35 (decisions/0018, point 6: "`errors` beyond a field: an alert, a confirmation, a status line, the
pilot's delete confirmation").

## When to use

Something the person did, or a screen's read, did not happen as asked, or the person is about to do what cannot be
undone. There are three ways to say it, and each job takes one:

- **A confirmation**, before an act that cannot be undone: the system's alert, which asks with the product's words and
  offers the act and Cancel. The pilot's delete of a list or an area (todo-app's lists screen, `ListsDialogs`,
  `docs/specs/lists-screen.md`, section 6): "Delete “Groceries”?" over "One list inside it goes with it. No task is
  deleted.", Delete and Cancel.
- **A status line**, for a failure: a band in the screen, where the failure happened, with the product's sentence and,
  where trying again can mend it, the action that does. The pilot says its failures this way, as a sentence under the
  screen's content (todo-app's list and lists screens, `TaskList.Problem` and the lists' `problem`): "The change could
  not be saved, so nothing was written.", "The task could not be moved, so it may have moved only in part."; its quick
  entry says "The task could not be saved." in its form. The pilot has no retry anywhere; a technical product's screen
  whose read failed, "The deployments could not be loaded." with "Try again", is this pattern's example of one.
- **An alert for a failure**, only where no screen is left to hold the line (rule 9). The pilot has none, and the
  pattern's example shows none.

Not for:

- **A field's error.** A value the product refuses stands under its field: the pattern `form`, rule 10. A form's save
  that failed is this pattern's (rule 8).
- **An empty screen.** A read that answered nothing is the pattern `empty-state`; a read that failed is this one's,
  and never shows an empty state, which would say something false (design-language/01, "Never invent a cause").
- **A wait.** A read or a save still running is the pattern `loading`; the retry's own loading is rule 6.
- **A delete that can be undone.** It does not ask (rule 2).

## Parts

| Part | Built from | Why |
|---|---|---|
| The confirmation | The system's `.alert(_:isPresented:presenting:actions:message:)`: the title, the message as a `Text`, a `Button` with `role: .destructive` named by the act's verb, then a `Button("Cancel", role: .cancel)` | The system's (decisions/0014, "What stays the system's"; design-language/09): it centres itself, takes the focus, dims the screen, orders and sets apart its buttons, and gives Esc to Cancel. westron styles nothing in it (rule 1) |
| The command that asks | The product's own: a menu item, a swipe action or a westron `Button`, each with `role: .destructive`, named by the same verb, with no ellipsis | The verb the person chose is the verb the alert offers, so they see they are about to do what they asked for. It asks no more input, only a yes, so no ellipsis (design-language/01) |
| The status line | An `HStack(alignment: .firstTextBaseline, spacing: .space100)`: `Icon(.xmarkCircleFill)` in `status.danger.icon`, decorative, and the product's sentence in `status.danger.text`, both in `body.regular`; padded `space.card`, on `status.danger.background` in a `RoundedRectangle` of `radius.card`, outlined in `status.danger.border` at `stroke.thin` | A failure is danger's status, and a status shows its glyph and its words (design-language/02, 07); the words carry it, so color is not its only signal (design-language/08). The quiet ground is "the ground of a banner" and the border "of a banner" (the tokens' own words); the text and the glyph on that ground, and the border on the canvas, are declared contrast pairs in every theme (`tools/westron tokens contrast`). `body.regular` is main text, the pilot's own size for its sentence; `space.card` and `radius.card` are a panel's |
| The retry, where there is one | A `Button` beside the sentence, `.buttonStyle(.secondary, size: .m)` with `.loading(_:)`, named by a verb, "Try again"; under the sentence at the accessibility text sizes (`AnyLayout`) | secondary sits beside the screen's own primary action without a second accent; `m` is the size westron's buttons take elsewhere. Loading keeps its label and takes no second press (Button's contract) |
| Where the line stands | Where the failed thing is: in the content's place when the screen has nothing else to show; under the screen's content, above its bars, when the screen still shows what it showed; in a form, above its actions (rules 4, 5 and 8) | A person reads a failure where it happened, and the content that stays keeps its place |

## Rules

1. **System containers stay the system's.** The confirmation is SwiftUI's `.alert`, as the pilot's is: no westron
   style, surface, color or font goes in it, and none could: on iOS an alert takes only buttons whose labels are text,
   and draws them itself. The destructive action takes the system's red and Cancel the system's look, on iOS and on the
   Mac, and westron's colors do not reach them (design-language/09: whether westron's accent becomes the app's tint, so
   that alerts show it, is open). westron styles what stands in the product's own views: the command that asks and the
   status line.
2. **Ask only before what cannot be undone, and always before it.** A delete that a person can take back, the pilot's
   task, which goes to the Trash and comes back from it, does not ask (todo-app, `docs/specs/list-screen.md`, section
   6, the owner's decision of 2026-11-01): a question before every delete teaches a person to press yes without
   reading. One that cannot be taken back, the pilot's list and area, whose lists go with them, always asks (the
   owner's decision, `docs/specs/lists-screen.md`, section 6).
3. **A confirmation is the system's alert, with the product's words.** Its title asks, in a few words, naming the
   thing with curly quotes: "Delete “Groceries”?", "Delete the “Home” area?". Its message says what goes and what
   stays, which is what lets a person say yes (design-language/01): "One list inside it goes with it. No task is
   deleted.", "Its lists stay.". No "Are you sure?", no "This cannot be undone.": the question is only ever put before
   what cannot be undone (rule 2), so it says so by being there, and its words go to what goes and what stays. The act
   is named by its verb, the command's own, "Delete", never "OK" or "Yes", with `role: .destructive`; Cancel is
   "Cancel", with `role: .cancel`. The alert has these two buttons and no third.

   It is the alert and not `.confirmationDialog`. The pilot's is an alert (its lists screen, section 6), and an alert
   shows its title and its message on the phone, the iPad and the Mac alike. A dialog's title is hidden on iOS unless
   the product asks for it (`titleVisibility`), and on the iPad's regular width it is a popover from the control that
   opened it (Apple's documentation of `confirmationDialog`; neither measured here). A dialog is for a choice among
   several acts a person started, a choice this pattern does not cover ("Not covered").
4. **Nothing changes until the act is pressed, and every other way out is Cancel.** The product puts the question up
   and does nothing else; the act runs only from its button. Cancel, and Esc on the Mac and on a keyboard, take the
   question away and change nothing. iOS has no tap outside an alert. Return presses neither button on the Mac: the
   system gives the alert no default button, so a Return meant for the screen never deletes ("Accessibility"); on iOS
   with a keyboard, not measured. A product sets no `.keyboardShortcut(.defaultAction)` on the act.
5. **A failure is a status line, where it happened.** The product's sentence says what failed and what it left
   (design-language/01): "The change could not be saved, so nothing was written.", "The tasks could not be read, so
   this list may be out of date.". The general sentence where the cause is not known, never a cause it may not be; no
   "Error:", no codes, no apology, no exclamation mark. When the screen still shows what it showed, a write that failed
   or a read that could not bring it up to date, the line stands under the screen's content, above its bars, the
   pilot's place: the content keeps its place and ends above the line, which a scroll does not take away. When the
   screen has nothing else to show, its first read failed, the line stands in the content's place, under the
   screen's header, and the screen shows no empty state.
6. **A retry only where trying again can mend it.** "Try again" stands in the line where the product can make the same
   request again as it was: a read, or a write it still holds. The pilot's lines have none: its module keeps no change
   that failed ("so nothing was written"), so there is nothing to try again, and the person's next action is the way
   on. While the retry runs, its button loads and takes no second press; one that succeeds takes the line away, and
   the content takes its place; one that fails again leaves the line, with the product's sentence, old or new.
7. **The line stays until the failure is mended or the person acts again.** It does not go by itself after a time: a
   person who reads slowly, or who hears the screen, would lose it (WCAG 2.2.1). It has no close button: the pilot's
   sentence goes with the person's next action on the screen, which the pilot's module answers by clearing it
   (`TaskList`, `state.problem = nil`), and so does the line. A line that appears, and a retry that fails again, are
   announced with the sentence (`AccessibilityNotification.Announcement`), so that a person on another part of the
   screen hears it.
8. **A form's save that failed is the form's line, above its actions.** The draft stays as typed, the line stands under
   the last field and above Cancel and the primary action, and the primary action is the retry: the line has no "Try
   again" of its own. No field is wrong, so the sentence stands under none of them; the pilot's quick entry today puts
   "The task could not be saved." under its field, where a refusal of the title stands. Not in this pattern's example
   and not measured.
9. **An alert for a failure only where no screen is left to hold the line.** A failure that comes after the screen
   that started it has gone, such as a save that failed as its window closed, has nowhere to stand: then the system's
   alert, its title the product's sentence, and its one button the system's own OK (an empty `actions`), or the verb
   that tries again beside Cancel. Anywhere a screen can hold the line, the line it is: an alert stops the person, and
   a failure they can do nothing about this instant does not need to. The pilot has no such case; not measured.
10. **Every text size.** The sentence wraps and never shortens: the line under the content takes the height its words
    need and the content above it gives way, so at accessibility5 the pilot's sentence, seven lines, takes about half
    an iPhone's screen. The retry moves under the sentence at the accessibility sizes, as the form's actions do, in one
    `AnyLayout`. Keep the sentence to one sentence.

## Accessibility

Measured on the catalog's entry `errors` by its UI test `ErrorsTests` and the accessibility audit (the iOS 26.3
simulator, iPhone 17, and macOS 27.2.1, 2026-11-28).

On iOS each line's sentence is one static text, "The deployments could not be loaded.", read after the section's
heading, "Deployments, heading"; the retry is one button after it, "Try again", 36 pt high at `size: .m`, and while it
runs its value is "Loading". The command is one button named by what it does and to what, "Delete “Groceries”". The
glyph of the line inside the scroll view adds no element; the glyph of the line under the content, outside the scroll
view, is an unnamed image element, though Icon hides a decorative glyph (G2; with an action in that line, a probe, the
same). The alert is an alert named by its title, "Delete “Groceries”?", with its message as a text and two buttons,
"Cancel" and "Delete", Cancel at the leading side. On macOS the sentences are texts whose value is the words, the alert
is a dialog in the window's centre with the same title, message and two buttons in the same order, the act drawn in the
system's red and neither button blue, and the glyphs add no element.

What the pattern promises, measured by the same test on both platforms: the command puts the alert up and changes
nothing; Cancel takes it away and the list stays, twice in a row; Delete takes it away and deletes the list once. On
the Mac, Esc is Cancel and changes nothing, and Return presses nothing: the alert stays up for 3 s and the list stays,
and Esc then takes it away. The retry loads while it runs; the page's first try fails again, and the line stays and
the retry ends; the second succeeds, and the deployments take the line's place. The line under the content goes with
the person's next action on the page. Not measured: what VoiceOver says of the announcement, since a UI test hears
nothing; whether VoiceOver stops on G2's image; Return in an iOS alert with a keyboard; a form's line (rule 8) and an
alert for a failure (rule 9).

The iOS audit passes its five tests (the default settings, the dark and both high-contrast themes, the accessibility
text sizes) with no suppression. Before the sentence took the height its words need (rule 10), it reported "Text
clipped" on the line under the content at the default and the accessibility sizes, and at accessibility5 the line
showed "so nothin…"; and with the command beside "Groceries" at accessibility5, the command's word broke letter by
letter, so the page stacks the two there. The macOS audit reports the three findings it reports on every entry of this
Mac, none on the entry's elements: "Contrast failed" on the window's title, "Westron Catalog", and "Element has no
description" on the window's group and on the menu bar, in three of its five tests (both dark themes pass); they are
the catalog window's and the system's, and are not suppressed (the pattern `form`, "Accessibility").

## Apple

The catalog's entry `errors` runs this code (decisions/0018, stage 2):
`platforms/apple/Sources/WestronCatalog/Patterns/Errors/Errors.swift` is this block, character for character, and
`PatternExampleTests` fails when the two differ. The entry shows three samples on the canvas, at the page margin: the
pilot's list "Groceries" with a destructive Button, "Delete", that asks, in the place of the pilot's menu item, so that
a UI test presses it; a technical product's deployments whose read failed, the line in the content's place with "Try
again"; and the pilot's write that failed, its line under the page's scroll view. No Rule parts them, as on the other
pattern entries: drawn here, Rule would put the entry in the pull-request audit of every change to Rule, which already
selects 4 entries, and take the last place under the limit (`fan_out_limit` in `tools/apple/audit-scope.sh`).

A product asks as the pilot does from its menu: `.contextMenu { Button("Delete", role: .destructive) { confirmation =
Confirmation(title: "Delete “\(list.title)”?", message: words, action: "Delete") { delete(list) } } }`, and once on the
screen, `.confirmation($confirmation)`. It lays the line under its content in the screen's own stack, `VStack(spacing:
0) { ScrollView { … }; if let problem { StatusLine(sentence: problem).padding(.horizontal, .space.page.narrow) } }`,
and in the content's place where it has nothing else to show, `StatusLine(sentence: problem, action:
StatusAction(title: "Try again") { await reload() })`, where `reload` clears the problem when the read succeeds.

```swift
import SwiftUI
import WestronUI

/// The question a product asks before something that cannot be undone, in its own words (design-language/01).
struct Confirmation {
    let title: String  // asks, and names the thing: "Delete “Groceries”?"
    let message: String  // what goes and what stays: "One list inside it goes with it. No task is deleted."
    let action: String  // the verb of what it does, the command's own word: "Delete"
    let confirm: () -> Void  // does it; Cancel, and every other way out of the alert, does nothing
}

extension View {
    /// The system's alert while `confirmation` holds a question: its title and message, the destructive action, then
    /// Cancel. Either button, or Esc, takes the question away.
    func confirmation(_ confirmation: Binding<Confirmation?>) -> some View {
        alert(
            confirmation.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { confirmation.wrappedValue != nil },
                set: { isUp in if !isUp { confirmation.wrappedValue = nil } }),
            presenting: confirmation.wrappedValue
        ) { asked in
            Button(asked.action, role: .destructive, action: asked.confirm)
            Button("Cancel", role: .cancel) {}  // the system sets it apart, and presses it for Esc
        } message: { asked in
            Text(asked.message)
        }
    }
}

/// The one action that can mend a failure, where there is one: the same request again.
struct StatusAction {
    let title: LocalizedStringKey  // a verb: "Try again"
    let run: () async -> Void  // asks again; the product takes the line away when it succeeds
}

/// A failure told where it happened: its glyph, the product's sentence and, where one makes sense, the action that
/// mends it; beside the sentence, and under it at the accessibility text sizes.
struct StatusLine: View {
    // What failed and what it left, in the product's words: "The change could not be saved, so nothing was written."
    // A String, not a key: the product makes it at run time, in the person's language.
    let sentence: String
    var action: StatusAction? = nil
    @State private var isRunning = false
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        // One layout or the other around the same views, so that they keep their identity as the text size changes.
        let layout =
            textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: .space.withinGroup))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: .space.withinGroup))
        layout {
            HStack(alignment: .firstTextBaseline, spacing: .space100) {
                Icon(.xmarkCircleFill).foregroundStyle(.status.danger.icon)
                Text(sentence)
                    .foregroundStyle(.status.danger.text)
                    .fixedSize(horizontal: false, vertical: true)  // every word, though the room above gives way
            }
            .textRole(.body.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let action {
                Button(action.title) {
                    guard !isRunning else { return }
                    isRunning = true
                    Task {
                        await action.run()
                        isRunning = false
                    }
                }
                .buttonStyle(.secondary, size: .m)
                .loading(isRunning)
            }
        }
        .padding(.space.card)
        .background(.status.danger.background, in: RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .radius.card, style: .continuous)
                .strokeBorder(.status.danger.border, lineWidth: .stroke.thin)
        }
        .onAppear(perform: announce)
        .onChange(of: sentence) { announce() }
        // An action that ended with the line still standing failed again: say so, though the words may be the same.
        .onChange(of: isRunning) { _, running in if !running { announce() } }
    }

    private func announce() {
        AccessibilityNotification.Announcement(sentence).post()
    }
}
```

## Not covered

A confirmation with more than one way forward ("Delete the list only" or "with its tasks"), or a choice among acts,
the system's `.confirmationDialog`; asking before a sheet with typed text is swiped away; an undo after an act, a toast
or a snackbar; warnings, successes and news, the other statuses, in a line of their own; the detail of a failure, a
code or a log line, on request (design-language/01, its question 2); a failure of the whole app, at launch, before any
screen; watchOS (#34); the web, with phase 6.

## Gaps

None is an issue yet: a gap becomes one only at the owner's word (decisions/0018, "Consequences").

- **G1**: westron has no status line of its own. The pilot asks for one: its lists screen draws its sentence "whose
  look no component's model holds yet" (todo-app, `ListsScreen.swift`), and each screen of it draws the sentence its
  own way, a material strip under the window and a strip on the screen's paper. Meanwhile a product composes the line
  as this pattern does, from Icon, Text, Button and the danger tokens, and posts its announcement itself, so each
  product repeats the layout at the accessibility sizes and the announcement, and may forget either. Issue, if the
  owner opens one: "A status line: a failure's sentence with its glyph and an action, announced".
- **G2**: a decorative `Icon` beside its words outside a scroll view is an unnamed image element on iOS, against Icon's
  contract, which hides a decorative glyph: the line under the content shows one, the same line inside the scroll view
  none (measured on the iOS 26.3 simulator, 2026-11-28; `ErrorsTests` pins it). The audit reports nothing on it, and
  whether VoiceOver stops on it has not been listened to. It looks like the first pattern's G5 (#174), a decorative
  tile in a row. Meanwhile a product does nothing more: the glyph is hidden as the contract says, and the sentence
  carries the failure. Issue, if the owner opens one: "Icon: a decorative glyph outside a scroll view is an unnamed
  image element on iOS".
