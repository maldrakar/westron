# 0004. The accessibility frame on macOS

Date: 2026-11-23 (#135). Status: approved on 2026-11-23 by the coordinating agent, to whom the owner delegates the
approval of a contract in phase 4 (decisions/0014, "Process"), pending the owner's confirmation with the second gate.
It amends the approved contract, `text-field.spec.yaml`, whose `platforms.apple.macos` block now records the
difference and whose `platforms.apple.ios` block records the frame there.

## Context

The accessibility audit of TextField's glyphs (#115) found that on macOS a field with a glyph reports to
accessibility a frame narrower than the field westron draws: VoiceOver's cursor is narrower than westron's focus ring,
and VoiceOver's pointer tracking over a glyph finds nothing. On iOS the frame is the whole field. A difference between
the platforms with no entry in the contract's `platforms` block is a bug (AGENTS.md, rule 5), so #135 asked either to
make macOS report the drawn field or to record the difference.

## Measured

On the catalog's `text-field-behavior` page, light, in screen points (x, y, width, height), with Xcode 27.1 on macOS
26.7.1 and on an iPhone 17 with iOS 26.3. On macOS the page's column, where every framed field is drawn, runs from
x 516 to 1212, 696 pt wide.

| Field | macOS frame | macOS drawn |
|---|---|---|
| framed, s, no glyph | (531, 362, 666, 18) | (516, 359, 696, 24) |
| SecureField, framed, m | (535, 493, 658, 18) | (516, 486, 696, 32) |
| search, framed, m, magnifier at the start | (558.5, 541, 634.5, 18) | (516, 534, 696, 32) |
| tag, framed, m, number sign at the end | (535, 589, 635.5, 18) | (516, 582, 696, 32) |

- The frame is the system field's, the text area of AppKit's field under the style, a point wider than westron's text
  at each side: inset by the padding less a point (15 pt at s, 19 at m) at a side without a glyph, and at a glyph's
  side by the padding, the glyph and its gap less a point (42.5 pt beside the magnifier, 41.5 beside the number sign).
  It is 18 pt high, the line, centred in the drawn field.
- So the flaw is not the glyphs': every framed field has it, with a glyph or without. No field has an image child on
  either platform: the glyphs stay hidden.
- An inline field, which has no padding and no glyph, agrees with its text within a point across; down, the card's
  title and notes, drawn `space.100` apart, report frames 6 pt apart, two points closer.
- iOS: every field's frame is the drawn field, the small one (16, 169.7, 370, 28), the fields at m (16, y, 370, 36),
  and the inline fields within a point of their text.

## The approaches tried on macOS, and why none is taken

1. **`.contentShape(.accessibility, …)`**, and **`.contentShape(.interaction, …)`**, on the drawn fill or on the
   system field, at the drawn shape or grown past it: the frame stays as it was. macOS takes a text field's frame from
   AppKit's view, not from SwiftUI's shape.
2. **`.accessibilityElement(children: .combine)`** around the drawn field: the frame is the drawn field, but the
   element is no longer the text field: its placeholder and value are lost, and set on the style, where no product
   trait reaches it, its type becomes other. On iOS the real field and the glyph's image appear as its children (on
   the catalog's search field: an image, the magnifier, and the field itself).
3. **`.accessibilityElement(children: .contain)`** around it: the field leaves the tree.
4. **`.accessibilityRepresentation { … }`** with a plain field: the tree gets a hidden copy of the field at the drawn
   frame, not the field a person types into.
5. **AppKit:** a background view finds the `NSTextField` under the style by its place in SwiftUI's private view tree
   and calls `setAccessibilityFrame(_:)` with the drawn field's rectangle in screen coordinates. It is the only way that
   gave the drawn frame with the field's role, value and placeholder kept. It is rejected as fragile: the frame is a
   fixed screen rectangle, which goes stale when the window moves or the page scrolls until the next layout pass sets
   it again; the field is found by geometry in views SwiftUI does not promise; and it would be westron's code over
   AppKit's accessibility, which no other westron control has.

## Decision

The contract records the difference as the system's behaviour, in `platforms.apple.macos`: a framed field's frame is
the system field's, without westron's padding and glyphs, for every framed field; on iOS it is the whole drawn field;
inline fields agree within a point across on both and on macOS within two points up and down. westron does not work
around it.

The catalog's `TextFieldAccessibilityFrameTests` holds both sides on the `text-field-behavior` page, against the drawn
fields computed from the page's geometry (the page's padding, the fields' heights at their sizes, the column's
spacing), with nothing added to the tree: on iOS that the frame is the drawn field; on macOS that it lies inside it,
centred, lower, and inset by the padding, and at a glyph's side by the glyph and its gap. It fails if westron moves the
frame further and if macOS starts reporting the drawn field; then the contract's entry goes. The test also holds that
no glyph is an element on either platform, the fields' roles, labels, values and placeholders, and that typing into
the search field changes its value. Taken out of the field (`.padding` around the tag field) or combined into one
element (the search field), the test fails on iOS; combined, the search field's frame on macOS becomes the drawn field
and the test fails with the message to remove the entry.

## Not measured

- What VoiceOver speaks and how its cursor and pointer tracking look: the frame is the tree's, read by XCUITest; a
  person with VoiceOver on has not checked it.
- macOS 14 and 15, iOS 17 and 18: only macOS 26.7.1 and iOS 26.3 were run.
