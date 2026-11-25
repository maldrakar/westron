<!-- Generated from spec/components/button/button.spec.yaml by `tools/westron generate`. Do not edit: change the source
and generate again (decisions/0016). -->

# Button: details

The prose of westron's contract for `button`, for the cases its card (`button.md`) does not settle. A reference such as
"decisions/0001" or "#120" here points into westron's repository: to the component's own decisions, westron's decisions
or an issue, none of which is in this bundle. Names such as `container.gap` are the contract's bindings of westron's
tokens, how WestronUI draws the component; a product never sets them.

## Accessibility

The label is the accessible name, also when iconOnly hides it, and names the action ("More", not "Ellipsis"). An icon
beside a visible label is decorative and hidden. In loading, assistive technology announces the label and busy; in
disabled, the button is announced as unavailable.

## Behavior

It is the platform's capsule at every variant and size, its ends round at any height, so it stays a capsule when the
text grows (design-language/04); icon-only is a circle. Every fill is flat and opaque, in westron's colors, with no
glass or material, but for one exception, a floating secondary from OS 26 (below). primary is filled with the accent,
secondary with color.background.muted and no outline, tertiary has no fill. Under the pointer and pressed, secondary's
fill moves towards its words, a step each, darker in the light themes and lighter in the dark ones; with the destructive
role it moves only as far as the danger words still read, which is much less (the owner's decision of 2026-11-20). In
the high-contrast themes a secondary button also draws an outline, color.border.strong (color.status.danger.border with
the destructive role) at stroke.thin, over its fill, in every state: the muted fill alone sets it off from the canvas by
about 1.1:1, and a control a person must find meets the non-text target there (design-language/02, 08). The bindings
below cannot say this, since a case has no contrast key, so this description is the contract for it, as Surface's is for
its line. The icon beside the label is the symbol's small scale in the label's text role, its baseline on the label's
first text baseline, not centered on it. Hover and pressed tint the container in motion.fade and motion.press, and a
press also scales it down to 98 %, which Reduce Motion drops (chapter 05). Disabled draws the whole button at
opacity.disabled, with no colors of its own. A disabled or loading button never enters hover or pressed: its fill stays
as at rest and it does not scale, on every platform; container.background's leading cases bind that. Loading puts a
progress indicator in the icon's place, and in icon-only in place of the icon, so the width does not change; when there
is no icon, the indicator goes before the label and the button widens by the indicator and the gap, so the label is
neither truncated nor hidden (the owner's decision of 2026-11-17, decisions/0001, P13). The label stays, presses are not
accepted, and the button does not dim. The button is not meant for a width smaller than its label's longest word: the
label wraps only between words, and the product provides the room, by stacking buttons, giving the button the full
width, a shorter label, or icon-only. In a narrower container the label breaks inside a word; that is unsupported, not a
behavior of this contract (decisions/0001). A floating button stands over content, outside any bar, such as a way back
and a "…" over a list or a round "+" in a screen's corner (decisions/0015). A floating secondary is the one exception to
the flat fills: from iOS 26, macOS 26 and watchOS 26 it stands on the system's glass, regular, in the button's capsule,
with no fill, outline, shadow, hover or pressed tint and no press scale of westron's, since the glass answers the
pointer and the press itself. The glass is laid after the button's content, padding, frame and background, and the
disabled opacity outside it, so a disabled button dims its glass with it. The glass answers a touch or the pointer (it
is interactive) only while the button takes presses: not while disabled or loading. Before those versions it stands on
color.background.surface and casts shadow.overlay, tinted and scaled under the pointer and pressed as the bindings say,
and draws secondary's outline in the high-contrast themes. A floating primary, destructive or not, keeps its opaque
fill, its tints and its scale on every version and casts shadow.overlay. The glass adapts its luminosity to what passes
beneath it and follows Reduce Transparency, Increase Contrast and the person's choice of the glass's look by itself,
while the label's and the icon's colors, westron's, follow the theme, not the glass. So the contract promises no
contrast ratio for text.primary on glass: what lies beneath is the product's content, which tokens do not name. Over
content of the tone opposite to the theme, such as a light photo or map under a floating button in the dark theme, or a
dark one in the light theme, the label can fall below 4.5:1: measured 3.8:1 in the dark theme over a wide light ground
on iOS 26.3. That is a recorded limitation, not a defect: the owner kept westron's colors on glass rather than the
system's adaptive foreground (decisions/0015, Q5, 2026-11-23). Over content whose tone it does not control, a product
uses a floating primary, whose fill is opaque, or keeps the content beneath in the theme's tone. The danger words read
too faintly on glass (measured 2.8 to 4.2:1 over a busy ground in the standard themes, decisions/0015), so a floating
secondary does not take the destructive role. Two combinations are forbidden, each by a constraint below: a floating
tertiary, which has no ground to float on, and a floating destructive secondary. A platform that is given one anyway
draws the button that does not float, the same variant and role in the layout's look, with no warning at run time
(spec/conventions.md, open question 3). A button in a system bar, toolbar or tab bar never floats: the bar draws its own
glass (design-language/09).

## On Apple

role is SwiftUI's own ButtonRole, so no enum is generated for it, which would collide with SwiftUI's: a product writes
Button(role: .destructive), and the style reads configuration.role; any other role draws as default. iconOnly is a
labeled argument of the style, .buttonStyle(.primary, iconOnly: true): the style hides the title, keeps it as the
accessible label and draws the circle. A product's own .labelStyle(.iconOnly) is not the way to it: the style's label
style overrides it, and the style cannot read it to draw the circle (spec/conventions.md). A call without size: takes it
from controlSize (spec/conventions.md). The focus ring is the system's, so the focusRing bindings do not apply. The
shape is SwiftUI's Capsule with its default continuous ends, as the prototype the owner chose drew it; in icon-only's
square frame it draws a circle. The icon beside the label is set to .imageScale(.small) and laid out with the label in
an HStack aligned on .firstTextBaseline; icon-only draws the glyph at the same small scale. The high-contrast outline
follows colorSchemeContrast, as Surface's line does. floating is a labeled argument too, .buttonStyle(.secondary, size:
.l, iconOnly: true, floating: true). A floating secondary's glass is glassEffect(.regular.interactive(isInteractive),
in: Capsule()) inside if #available(iOS 26, macOS 26, watchOS 26, *), isInteractive false while the button is disabled
or loading. It is applied after the content, the padding, the frame and the background, as glassEffect asks, and before
the content shapes and the disabled opacity, which so dims the glass too; the else branch draws the surface, the shadow
and the tints of the bindings. A floating tertiary or destructive secondary, which the constraints forbid, draws as the
same button not floating, silently: no assertionFailure, while spec/conventions.md's open question 3 is open. These two
looks by OS version are one contract: the platforms block has no field for an OS version, so this description is the
record of the difference (decisions/0015). westron adds no GlassEffectContainer, glassEffectID or glassEffectUnion: a
product that sets floating buttons side by side, or morphs one into another, writes the system's own around them from OS
26. The shadow is View.shadow(_:), as Surface's.

### iOS

Hover only with a pointer, on iPad; an iPhone never enters it. The hit area is the system's touch tolerance around the
drawn button, which westron does not grow: measured on iOS 26.3 it reached 16 pt past a 32 pt button (#23), and with no
other control near it reaches 16 to 19 pt past a button of size s or m on iOS 26.3 and 27.0 alike (#102). So a size s
button reaches the full target only where no other control is within about 16 pt of it (the owner's decision of
2026-11-21, decisions/0001). A floating button over content a person presses, a list's rows, gets no tolerance at all:
on iOS 26.3 a press half a point inside its drawn edge reaches it and a press 1 or 4 pt past it, below or beside,
reaches the row, at sizes s, m and l alike. So over pressable content its hit area is what it draws, and only size l, 50
pt, reaches size.target.minimum: use size l for a floating button over pressable content on iOS.

### macOS

Return triggers the default action and Escape the cancel action. The hit area is the drawn button, so size s takes
clicks in its 24 pt, below the recommended 28 (the owner's decision of 2026-11-18, decisions/0001): a click outside the
system button's frame misses, a frame grown with an outset and taken back by a negative padding takes clicks inside a
neighbor closer than 4 pt, and a layout frame of 28 breaks the alignment size s is for. A pointer is precise, and the
system's own small controls take clicks in their frame only. The drawn button is a capsule, so the corners of its frame
outside the capsule take no click: less than the rounded rectangle of radius.control took before 2026-11-20 (on
icon-only at s, a click 3 pt in from two edges misses), which follows from the owner's two decisions and waits for the
owner's confirmation (decisions/0003).

### watchOS

One size, m: the Swift enum keeps every size and the style falls back to m. No pointer, so no hover.
