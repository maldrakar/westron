# 01. Tone

Date: 2026-11-15. Status: draft for the owner's approval (#8). Its visual temperament follows
[decisions/0012](../decisions/0012-color.md) and [decisions/0013](../decisions/0013-typography-space-shape-motion.md),
which the owner accepted by choosing direction B.

Tone is how westron speaks and how it holds itself on screen. westron serves everyday products, such as a task list,
and technical ones, such as a table of deployments, a log or a dashboard. One voice and one temperament serve them all.
The examples below come from both kinds of product, with example names filled in. Where a rule is a proposal, it says
so.

## Voice

The interface speaks plainly and exactly, in short sentences, with no persona.

- **Say what happened and what it left.** A failure names what failed and the state the data is in now: "The change
  could not be saved, so nothing was written." "The task could not be moved, so it may have moved only in part." A
  person should never have to guess whether to try again.
- **Never invent a cause.** When the cause is unknown, the message says the general sentence. "“Groceries” is no
  longer there, so the new name was not saved." is right only when the store reports the list missing. For every other
  failure, the message is "The change could not be saved, so nothing was written." A specific sentence that may be
  false is worse than a plain one.
- **No apology, no exclamation marks, no jokes, no "we".** The HIG calls interjections like "oops!" "unnecessary" and
  asks apps to "avoid using *we* altogether"
  ([HIG Writing](https://developer.apple.com/design/human-interface-guidelines/writing)). Calm words suit a tool
  people use for hours.
- **A confirmation asks, then says what goes and what stays.** "Delete “Projects”?", then "One list inside it goes
  with it. No task is deleted." For an area: "Delete the “Work” area?", then "Its lists stay." Knowing what stays is
  what lets a person say yes.
- **An empty screen names its state and says what will fill it.** "Nothing here yet" over "Tasks that match this
  list’s rule will show up here." "No deployments yet" over "Each deployment of this service will show up here." The
  HIG asks empty states to "guide people on actions they can take".
- **A disabled option says how to enable it.** "Columns", with "Group the list in its settings to get columns" under
  it.
- **Labels are verbs for actions and nouns for places.** "Rename", "Delete", "Move to…", "Add task", "Deploy";
  "Inbox", "Today", "Logs". An ellipsis marks a command that asks for more input before it acts, as both the HIG and
  the [GNOME HIG](https://developer.gnome.org/hig/guidelines/writing-style.html) use it.
- **One name for one thing.** A list is always a list and an area always an area, on every screen. The domain words
  are the product's, and westron components never rename them.
- **Numbers and dates are short and exact.** "Due Tue", "Overdue 2 days", "2/4", "Done today · 3". A middle dot joins a
  label to its count or its date.
- **A status says its word.** A status shows a word beside its icon and its color: "Failed", "Running", "Queued"
  (chapter 02). The word is the product's, and it is the same in a badge, a row and a log.
- **Real typography.** Curly quotes (“ ” ’) and the ellipsis character (…), never straight quotes or three dots.
- **A neutral person.** The interface rarely says "you" and never "my". GNOME asks for "a neutral perspective and
  tone" and says "you" and "my" "should generally be avoided". "You" appears only where a sentence would be awkward
  without it.
- **Capitalization by element type, as the platform does it.** The HIG leaves the choice to the app but asks for one
  style per element type. GNOME prescribes header capitalization for headings, buttons and menu items, and sentence
  capitalization for body text and field labels. The words stay the same on every platform; only their case follows
  the platform. On Apple, the proposal is title case for menu commands ("New List", "Open in New Window") and sentence
  case for everything else ("Add task", "Nothing here yet").
- **An accessibility label says what a control does, and to what.** "More", not "Ellipsis"; "Complete: Buy milk";
  "Back to Today". A glyph's name says what it draws; its label says what it does (chapter 07).

## Who writes the words

The product writes them. A westron component takes its titles, messages and labels with its content and does not
choose them. westron owns the rules in this chapter, and review holds copy to them. Proposal; see the open questions.

## Temperament

The look is calm and soft, and dense where the work needs it.

- **Calm.** A faintly cool ground with white cards on it, inks for words, and one cobalt accent used sparingly
  (chapter 02; chapter 00, principle 3). Surfaces differ from each other by small steps of tone, and lines are thin.
  Nothing competes with the content.
- **Soft.** Corners are rounded at about a quarter of a control's height: 8 on a 32 px control, 12 on a card, 16 on a
  sheet. A card is raised by a soft shadow of two layers in light and by a lighter surface in dark (chapter 04).
  Something that floats or is dragged stands higher.
- **Hierarchy from type and space.** Headings are set in Onest, bold or semibold. Body text and controls are set in
  the system font, so they read like the platform, and code is set in Geist Mono
  ([decisions/0011](../decisions/0011-icons-and-fonts.md); chapter 03). Space follows an 8 px rhythm: 16 inside a
  card, 24 between groups (chapter 06).
- **Signals are few and clear.** Color is never decoration, so there are no decorative gradients or textures. A
  status shows an icon and a word as well as its color. A screen holds four hues at most: the accent, and danger,
  warning and success when something needs them.
- **Dense but legible on technical screens.** Comfortable is the default density. A table, a log or a dashboard can
  turn compact through the `density` mode ([decisions/0010](../decisions/0010-token-structure-and-modes.md)): its
  controls and rows get smaller, and its text keeps the person's size. People see more at once and still read at
  their own size.
- **Motion with a light bounce.** Springs move what a person touches, such as a switch, a check or a dropped row, and
  settle with a light bounce. A popping check is the one visible overshoot. Something leaves quicker than it came
  (chapter 05). Motion answers a change; nothing moves for decoration. A change that must be read waits for it. With
  Reduce Motion the change happens without the movement, and the wait stays.

## Open questions

1. **One register for every product.** The voice above serves a task list and a table of deployments alike. Does a
   technical product want terser copy, for example in the cells and badges of a dense table?
2. **Technical detail.** Should a failure offer the underlying detail (an error code, a path, a log line) on request?
   A person in a task list can do nothing with a database error code. A person reading a deployment's log can.
   Proposal: show the detail on request, verbatim, in the code text role.
3. **"You".** Allowed sparingly, as above, or never, as GNOME prefers?
4. **Capitalization on Apple.** Is the proposal (title case for menu commands, sentence case elsewhere) westron's rule
   on Apple?
5. **Illustrations.** Empty states are words today. Does westron have an illustration style, or do empty states stay
   with words and, at most, an icon?
6. **Words westron ships.** Does westron ship any localized strings of its own, such as a default accessibility label
   for a disclosure chevron, or does every word come from the product?
