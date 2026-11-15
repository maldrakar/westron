# 01. Tone

Date: 2026-11-15. Status: draft for the owner's approval (#8).

Tone is how westron speaks and how it holds itself on screen. Both are read from the pilot, todo-app: its copy and
the canvas "Todo — дизайн" that the owner approved ([decisions/0006](../decisions/0006-pilot-product.md)). The quotes
below are the pilot's own strings, with example names filled in. Where the pilot is silent, this chapter leans
toward plain and exact, because westron is for technical products, and it marks those places as proposals.

## Voice

The interface speaks plainly and exactly, in short sentences, with no persona.

- **Say what happened and what it left.** A failure names what failed and the state the data is in now: "The change
  could not be saved, so nothing was written." "The task could not be moved, so it may have moved only in part." A
  person should never have to guess whether to try again.
- **Never invent a cause.** When the cause is unknown, the message says the general sentence. The pilot says
  "“Groceries” is no longer there, so the new name was not saved." only when its store reports the list missing, and
  "The change could not be saved, so nothing was written." for every other failure. A specific sentence that may be
  false is worse than a plain one.
- **No apology, no exclamation marks, no jokes, no "we".** The pilot has none of these. The HIG calls interjections
  like "oops!" "unnecessary" and asks apps to "avoid using *we* altogether"
  ([HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)). Calm words suit a tool
  people use for hours.
- **A confirmation asks, then says what goes and what stays.** "Delete “Projects”?", then "One list inside it goes
  with it. No task is deleted." For an area: "Delete the “Work” area?", then "Its lists stay." Knowing what stays is
  what lets a person say yes.
- **An empty screen names its state and says what will fill it.** "Nothing here yet" over "Tasks that match this
  list’s rule will show up here." "Trash is empty" over "Deleted tasks wait here until you empty it." The HIG asks
  empty states to "guide people on actions they can take".
- **A disabled option says how to enable it.** "Columns", with "Group the list in its settings to get columns" under it.
- **Labels are verbs for actions and nouns for places.** "Rename", "Delete", "Move to…", "Add task"; "Inbox", "Today".
  An ellipsis marks a command that asks for more input before it acts, as both the HIG and the
  [GNOME HIG](https://developer.gnome.org/hig/guidelines/writing-style.html) use it.
- **One name for one thing.** A list is always a list and an area always an area, on every screen. The domain words
  are the product's, and westron components never rename them.
- **Numbers and dates are short and exact.** "Due Tue", "Overdue 2 days", "2/4", "Done today · 3". A middle dot joins a
  label to its count or its date.
- **Real typography.** Curly quotes (“ ” ’) and the ellipsis character (…), never straight quotes or three dots.
- **A neutral person.** The pilot rarely says "you" and never "my". GNOME asks for "a neutral perspective and tone" and
  says "you" and "my" "should generally be avoided". "You" appears only where a sentence would be awkward without it.
- **Capitalization by element type, as the platform does it.** The pilot uses title case for menu commands ("New List",
  "Open in New Window", "Delete Area") and sentence case for everything else ("Add task", "Nothing here yet"). The HIG
  leaves the choice to the app but asks for one style per element type. GNOME prescribes header capitalization for
  headings, buttons and menu items, and sentence capitalization for body text and field labels. The words stay the
  same on every platform; only their case follows the platform.
- **An accessibility label says what a control does, and to what.** "More", not "Ellipsis"; "Complete: Buy milk";
  "Back to Today". A glyph's name says what it draws; its label says what it does (chapter 07).

## Who writes the words

The product writes them. In the pilot, a component's model carries its own words, and the screen's module chooses
them. westron components work the same way: titles, messages and labels arrive with the content. westron owns the rules
in this chapter, and review holds copy to them. Proposal; see the open questions.

## Temperament

The look is calm, quiet and, where the work needs it, dense.

- **Calm.** Warm paper neutrals, ink for text, and one accent used sparingly (chapter 00, principle 3). Surfaces
  differ from each other by small steps of tone, and lines are thin. Nothing competes with the content.
- **Quiet.** Hierarchy comes from type and space. Headings are heavy and set in the system's rounded design; body text
  is regular and set in the system font ([decisions/0011](../decisions/0011-icons-and-fonts.md)). Shadows appear only
  under something lifted or floating. The pilot has no decorative gradients, textures or illustrations.
- **Dense where the work is.** Data views can tighten through the `density` mode
  ([decisions/0010](../decisions/0010-token-structure-and-modes.md)) without making text smaller, so people see more at
  once and still read at their own size.
- **Motion that settles.** A movement starts quickly and settles slowly. Springs move what a person touches, such as
  a check or a dropped card; in the pilot most of them come to rest without bouncing (chapter 05). A change that must
  be read waits for it: a done row stays long enough for its check to be seen, then leaves. Nothing moves on its own,
  and nothing loops. With Reduce Motion the change happens without the movement, and the wait stays.

## Open questions

1. **westron's voice or the pilot's?** Everything above is read from a task app. A tool for developers may want terser
   copy or a more technical register.
2. **Technical detail.** Should a failure offer the underlying detail (an error code, a path, a log line) on request?
   The pilot keeps its store's errors off the screen: they name SQLite codes, "which is what a bug report is made of and
   not what a person can do anything about". A technical product's users may be able to. Proposal: show the detail on
   request, verbatim, in a monospaced text role.
3. **"You".** Allowed sparingly, as the pilot does, or never, as GNOME prefers?
4. **Capitalization on Apple.** Is the pilot's rule (title case for menu commands, sentence case elsewhere) westron's
   rule on Apple?
5. **Illustrations.** The pilot has none, and its empty states are words only. Does westron have an illustration style?
6. **Words westron ships.** Does westron ship any localized strings of its own, such as a default accessibility label
   for a disclosure chevron, or does every word come from the product?
