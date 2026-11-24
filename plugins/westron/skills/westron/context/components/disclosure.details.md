<!-- Generated from spec/components/disclosure/disclosure.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# Disclosure: details

The prose of westron's contract for `disclosure`, for the cases its card (`disclosure.md`) does not settle. A reference
such as "decisions/0001" or "#120" here points into westron's repository: to the component's own decisions, westron's
decisions or an issue, none of which is in this bundle. Names such as `container.gap` are the contract's bindings of
westron's tokens, how WestronUI draws the component; a product never sets them.

## Accessibility

The platform's own disclosure: one element, the chevron, in the cell's frame, with the role the platform's own
disclosure control has and its value, expanded or collapsed, where the platform gives one, in the platform's words;
named by the label's text, or by the row's title when the label is a list's row; activating it toggles the group. On a
platform whose own disclosure control is a button that SwiftUI gives no value (iOS, measured), the chevron is that
button and its value is the state in words, "Expanded" or "Collapsed", localized, as Button's loading is
(decisions/0001, "Measured"). The chevron is never named after its glyph or its action ("Expand", "Fold"): the role and
the value say what it does, as the system's own disclosure triangle does. The label stays its own element or elements,
with its own action if it has one, read before the chevron, so the label's words are read twice in a row, once for the
label and once as the chevron's name (decisions/0001, Q4, kept). The glyph itself is decorative and hidden. The content
is read only while the group is expanded. In disabled, the chevron is announced as unavailable.

## Behavior

The group is a header and the content under it; the header is the product's label and, at its trailing end, the chevron.
Only the chevron folds and unfolds the group: the label is the product's and keeps whatever it does, such as a list's
row that opens the list or a block's title that opens the block as a screen (decisions/0001, Q1). The chevron is the
icon registry's chevron glyph in color.icon.tertiary, sized and weighted by the text role that reaches the style, at the
platform's small symbol scale: a role the label sets inside itself does not reach it, a ListRow label gives it the row's
slot role, and a product sizes it by a heading label by setting that role on the group rather than inside the label;
sitting on the label's first text baseline as a letter does (design-language/07, "Size relative to text"). It points
down while the group is expanded and to the trailing side while it is collapsed, right in a left-to-right layout and
left in a right-to-left one, and it turns a quarter between them, away from the trailing side as the group opens: its
direction is the cue of the state, never its color. Its cell stands after the label, at the header's trailing edge, the
only placement (decisions/0001, Q3). Where the label is a ListRow (#119) the cell is the row's last trailing item,
inside the row, container.trailingGap after the trailing slot, so that the row's background, hover, selection and
sideways pinning run under it (decisions/0001, Q2); where the label is anything else, the style places the cell after
the label itself, at the header's trailing edge, on the label's first text baseline. A tree branch and a block header
differ only in the label the product passes (decisions/0001, P3). The content stands directly under the header, flush
with its leading edge, with no indentation and no gap of the style's own: a branch's child rows are indented by their
own nesting level, a block's rows are not indented at all. The cell is a laid-out frame at least size.target.minimum
high and across, 44 pt on iOS and 28 pt on macOS, the glyph centred in it, so that it never hands its presses to the
label beside it, nor takes the label's. Under the pointer the cell shows a circle of size.control.s, growing with the
glyph up to the xxxLarge text size as a ListRow's horizontal structure does, in color.background.hover; the hover begins
and ends at the drawn circle, not at the hit area around it. Pressed, the circle is color.background.pressed and the
chevron scales down to 98 %, in motion.press; the hover tint changes in motion.fade. A toggle by the chevron or the
keyboard moves in motion.move, the motion of a section folding (design-language/05): the chevron's turn, the content's
reveal, in which the content fades in where it stands while the group's height grows from the header's bottom edge, and
whatever stands after the group, which moves with it. Folding runs the same in reverse. A change of the binding made by
the product moves as the product's own transaction says. Under Reduce Motion motion.move takes its reduced form
(decisions/0013): the chevron points its new way at once, with no turn, the group's height and whatever stands after it
change at once, and the content fades in or out where it stands in motion.fade, the fade westron has; chapter 05's cap
of 150 ms for travel's reduced fade has no token yet (chapter 05, open question 1; decisions/0001, "Open"); the press
keeps its tint and loses its scale. Disabled draws the chevron and its cell at opacity.disabled, with no hover or press;
the group keeps its expansion, and the label and the content are the product's, which .disabled reaches as it reaches
any view. Disabled is the group's: the cell takes its enabled state and its look from the group, not from its label, so
a label disabled alone, a ListRow or any other, leaves the chevron enabled, drawn whole and folding the group, the same
whatever the label is; a disabled row is not pressable, but folding is navigation (the ListRow contract). A ListRow that
draws the cell does not dim it with the rest of a disabled row, so a disabled group's chevron is drawn at
opacity.disabled once, by itself, whatever its label. The chevron meets 3:1 as a non-text glyph on the canvas, the
surface, the sunken ground, the hover and pressed tints and a selected row, 4.5:1 in high contrast
(color.icon.tertiary's declared pairs). A leaf in a tree, a row with nothing to fold, lines up with the branches beside
it when the product sets the context alignsLeaves on the tree (`context`).

## On Apple

.disclosureGroupStyle(.chevron), a DisclosureGroupStyle (iOS 16 and macOS 13, so on westron's minimum iOS 17 and macOS
14 without availability checks); expanded is configuration.isExpanded, the system's binding, which the product passes as
DisclosureGroup(isExpanded:) or leaves to the group's own state. The style draws the header, the chevron's cell and the
content's placement and reveal; the label, the content, the binding and the role stay the system's. The chevron's cell
is a system Button that toggles configuration.isExpanded in motion.move (under Reduce Motion with no animation, the
content fading on its own), drawn by a ButtonStyle that sees isPressed, its focus the system's and its hover followed
with onContinuousHover against the drawn circle, as Chip's is; the glyph is Image(.chevron) at imageScale(.small),
hidden from assistive technology. For assistive technology the Button is represented by what the system's own
DisclosureGroup is on each OS (accessibilityRepresentation), laid out in the cell's frame and named by the label, or by
the row's title when a ListRow draws the cell: on macOS the system's DisclosureGroup on the same binding in its
automatic style, a disclosure triangle whose value is 1 expanded and 0 collapsed, one element with its label merged in,
whose press (AXPress) is the cell's own toggle, in its motion, as the system's press is lost when a ListRow draws the
cell again in its own representation (measured); on iOS the system's Button on the label, as the system's
DisclosureGroup is a button with no value there and loses its button inside a representation, with accessibilityValue
"Expanded" or "Collapsed" from WestronUI's string catalog (decisions/0001, "Measured"). On macOS the system also gives
the label of any DisclosureGroup style the disclosure role and the group's value, so a ListRow label reads as a
disclosure triangle; on iOS it stays a button. The style passes itself to the content's groups, which SwiftUI would
otherwise draw in the automatic style again. The style hands the cell to its label through ListRow's package-internal
environment value; a ListRow that draws it says so through a preference, and for any other label the style lays the cell
out after the label itself. The focus ring is the system's, on macOS on the circle (contentShape .focusEffect), so the
focusRing bindings do not apply, as for Button, Chip and ListRow; on iOS, where only Full Keyboard Access focuses, the
system draws its own around the cell. The context alignsLeaves is .disclosureAlignsLeaves(_: Bool = true), set through
the environment and cascading; a ListRow reads it and draws the hidden cell. The style applies to every DisclosureGroup
under the modifier, OutlineGroup's included; inside a List the contract does not promise westron's look (decisions/0001,
Q5, and "Measured": what a List does with it on iOS and macOS). The pilot's tree is recursive DisclosureGroups in a lazy
stack.

### iOS

Hover only with a pointer, on an iPad; an iPhone never enters it. Focus only with a hardware keyboard and Full Keyboard
Access or the iPad's keyboard navigation. The chevron's cell is at least 44 pt high and across.

### macOS

The cell is at least 28 pt high and across. With the Mac's keyboard navigation on, Tab reaches the chevron and Space
toggles it, as the system button's activation; with the chevron focused the Right and Left arrows expand and collapse
it, mirrored right to left, as an outline's disclosure triangle does (onMoveCommand). With keyboard navigation off, the
chevron takes no focus, as a system button takes none, and the behaviour tests skip the keyboard (decisions/0001,
"Measured").

### watchOS

Unavailable. SwiftUI has no DisclosureGroup and no DisclosureGroupStyle on watchOS (both @available(watchOS,
unavailable) in the SwiftUI interface of Xcode 27.1), so the component does not exist there: nothing of it is generated
or compiled for watchOS. #34 decides the watch's subset, and a product folds there by other means.
