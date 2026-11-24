<!-- Generated from spec/components/text/text.spec.yaml by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Text: details

The prose of westron's contract for `text`, for the cases its card (`text.md`) does not settle. A reference such as
"decisions/0001" or "#120" here points into westron's repository: to the component's own decisions, westron's decisions
or an issue, none of which is in this bundle. Names such as `container.gap` are the contract's bindings of westron's
tokens, how WestronUI draws the component; a product never sets them.

## Accessibility

The text is its own accessible label; a role adds no trait. A heading role does not make the text a heading for
assistive technology: the product marks a heading where the screen's structure has one, on Apple with
.accessibilityAddTraits(.isHeader). The text scales with the person's text size and never drops below the contrast
target, whatever its size (design-language/02, 08).

## Behavior

A role sets the font and the tracking and nothing else; the product sets the color with a color role, and the heading
semantics itself. The roles are the typography tokens, all seventeen, named as the tokens are (design-language/03). On
Apple a role follows its text style, so it scales with Dynamic Type and takes the Mac's sizes on macOS. Tracking is a
percentage of the size the font is drawn at, on every platform and at every text size: headings are tracked in by 1 %,
the overline out by 6 %, each the token's letterSpacing over its fontSize. With the system's Bold Text setting on, a
role in Onest or Geist Mono draws heavier, as the system font does by itself: Onest SemiBold to Bold and Bold to
ExtraBold, Geist Mono Regular to SemiBold and SemiBold to Bold. Line height comes from the font. The component has no
states. Running text wraps; a one-line label may truncate with an ellipsis when its full text is reachable, and the line
limit is the platform's own (design-language/03, "Capitals, numbers and fitting").

## On Apple

The role is the token accessor Westron.TextRole, whose names already follow the tokens, so the call is
.textRole(.heading.large) on any view. Text.textRole(_:) returns a Text, so that a part of a text keeps its own role and
tracking: inside Text interpolation, Text("\(name) \(Text(count).textRole(.footnote.medium))"), and in Text + Text,
which OS 26 deprecates for interpolation. The twin cannot read the environment: its size follows Dynamic Type, but its
tracking is the role's share of a size it reads without the environment (on iOS the size at the default Dynamic Type
size, on macOS the Mac's size, which is the drawn size, on watchOS the size the system gives the text style now) and,
under Bold Text, a role in Onest or Geist Mono keeps its own weight; .textRole(_:) on a view follows all three. Inside
interpolation, a role in a variable or written in full takes the View modifier and prints a debug description, with a
compiler warning, unless the part is typed as Text first; an untyped let part = Text(…).textRole(…) is no way out, since
it takes the View modifier however the role is spelled (decisions/0001, "P2 at implementation"). Font(.body.regular)
gives the face without the tracking, where only a font fits. A role in Onest or Geist Mono is
Font.custom(_:size:relativeTo:) at its text style's size on that OS, the system font's roles
Font.system(_:design:weight:); the tracking is recomputed from the size Dynamic Type draws. Under Bold Text
(legibilityWeight .bold) a role in Onest or Geist Mono takes the heavier weight the description names; the system font
does so by itself. Line height is the font's own (design-language/03, "Tracking and line height"). The line limit and
truncation are SwiftUI's .lineLimit and .truncationMode.

### watchOS

Every role is drawn in the system font, in its text style at the watch's sizes, with the role's weight; the code roles
in the system's monospaced design. Onest and Geist Mono are not used on the watch, as the research suggests for its
screen size (research_notes/type-and-icons.md, 3.1). The tracking still applies, as a percentage of the size the watch
draws.
