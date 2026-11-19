# 0002. A check with no drawn label, on every OS

Date: 2026-11-19 (#86). Status: decided with the owner's choice of the form on 2026-11-19; the exact API name pending
the owner's confirmation. It amends the approved contract, which stays approved: `accessibility.hiddenLabel` and the
`platforms.apple` description of `checkbox.spec.yaml`, and the open point of decisions/0001 on `.labelsHidden()`.

## Problem

The pilot's task row draws its title as a separate text beside the check, and the check needs the title as its
accessible name (decisions/0001, P11). The contract wrote such a row with SwiftUI's own `.labelsHidden()`:

```swift
HStack {
    Toggle("Buy milk", isOn: $task.isDone)
        .toggleStyle(.check)
        .labelsHidden()
    Text("Buy milk").accessibilityHidden(true)
}
```

A custom `ToggleStyle` learns of `.labelsHidden()` only through `@Environment(\.labelsVisibility)`, which exists from
iOS 18, macOS 15 and watchOS 11. On iOS 17, macOS 14 and watchOS 10, westron's minimum (decisions/0008), the style
draws the label, so the row shows its title twice. decisions/0001 recorded the limit and an unmeasured workaround: an
empty label with `.accessibilityLabel(_:)`.

## The owner's choice

Fix it in westron with an initializer for a check that takes no label view and **requires** the accessible name as an
argument, so that a call cannot leave it out; verified on an iOS 17 simulator; the same on every supported OS. The
owner chose it over a westron modifier that would repeat `.labelsHidden()` under a second name, which a product would
have to remember instead of the system's. `.labelsHidden()` keeps working from iOS 18 on.

## What was measured

A probe page in the catalog put nine shapes of a check beside a separate title (its title hidden from assistive
technology), and a UI test read the accessibility hierarchy as XCUITest sees it (the element's type, label, value and
frame; `app.debugDescription`) and took a screenshot. It ran on iOS 17.5 (21F79, an iPhone 15 simulator) and on
iOS 26.3 (an iPhone 16e simulator), Xcode 27.1. VoiceOver itself was not run. Every row was one `Switch` element, its
value `0`, no button; the table gives its label and its frame's width (each is 44 pt high). Widths of 48 pt are the
44 pt hit area plus the style's 4 pt gap (`space.50`) before a label that draws nothing.

The table is a record, not a test: the probe page and its UI test were temporary, run once on 2026-11-19 on the two
simulators above, and removed before the change was committed, so only the shipped form (E) is still checked, by
`CheckboxStyleTests` and `CheckboxBehaviorTests`.

| | The check's label | iOS 17.5 | iOS 26.3 |
|---|---|---|---|
| A | `Toggle("Buy milk", …)` and `.labelsHidden()` | "Buy milk", 127.7 pt: **the title drawn beside the circle** | "Buy milk", 44 pt |
| B | `Text("").accessibilityLabel(Text("Buy milk"))` | "Buy milk", 48 pt | **no name**, 48 pt |
| C | `Toggle("", …)`, `.accessibilityLabel("Buy milk")` on the toggle | "Buy milk", 48 pt | "Buy milk", 48 pt |
| D | `EmptyView()`, `.accessibilityLabel("Buy milk")` on the toggle | "Buy milk", 44 pt | "Buy milk", 44 pt |
| E | `EmptyView().accessibilityLabel("Buy milk")` | "Buy milk", 44 pt | "Buy milk", 44 pt |
| F | `Color.clear.frame(width: 0, height: 0).accessibilityLabel(…)` | "Buy milk", 48 pt | "Buy milk", 48 pt |
| I | B with `.labelsHidden()` | "Buy milk", 48 pt | **no name**, 44 pt |
| K | a view whose body is E's | "Buy milk", 44 pt | "Buy milk", 44 pt |

With the system's own style instead of `.check`, E's label (J) and K's (L) gave a switch named "Buy milk" with no
label drawn, on both OSes. The screenshots showed what the widths say: only A on iOS 17.5 drew a second title, and
B, C, F and I left a 4 pt gap before the separate title.

So an `EmptyView` carrying the name, inside the label (E, K), is the one form that an initializer can build with the
name as a required argument and that behaves the same on both OSes: the style's `HStack` lays out nothing for an
`EmptyView`, so the check is its hit area alone, as `.labelsHidden()` makes it from iOS 18, and the system `Toggle` of
the style's accessibility representation (decisions/0001, P19) takes its name from the label it is given. D works too,
but its name is a second modifier the product must remember, which is what the owner ruled out. B loses the name on iOS
26.3; C and F leave the gap.

## The choice

An initializer of the system `Toggle` in westron, constrained on the label it builds, with the name required:

```swift
extension Toggle where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier> {
    public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey)
    @_disfavoredOverload
    public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S)
}

HStack {
    Toggle(isOn: $task.isDone, accessibilityLabel: task.title).toggleStyle(.check)
    Text(task.title).accessibilityHidden(true)
}
```

- **The name is a required argument.** There is no initializer without it, and nothing else to remember. What the
  signature guarantees is the argument, not its content: an empty string still compiles and gives a switch with no
  name, as `Toggle("", isOn:)` does.
- **The label type is SwiftUI's,** what `EmptyView().accessibilityLabel(_:)` returns (E), so westron adds no public
  type; a westron view with the same body (K) measured the same and would add one. A product never writes the type.
- **The style does not change.** It needs no flag, no preference and no environment value: the `EmptyView` is
  nothing to lay out, on every OS. A labelled check draws and behaves as before.
- **The name**: `accessibilityLabel:`, as `.accessibilityLabel(_:)` is named, so the call says the text is spoken and
  never drawn; after `isOn:`, as `Icon(_:label:)` and SwiftUI's `Image(_:bundle:label:)` take their spoken label last.
  A localized key and, preferred less, any string, as `Icon(_:label:)` and `Toggle(_:isOn:)` take theirs. The exact
  name is the agent's proposal, pending the owner's confirmation; `Toggle(isOn:hiddenLabel:)` and
  `Toggle(accessibilityLabel:isOn:)` were the alternatives considered.
- **With another toggle style** the initializer still draws no label and gives the name (J, L), so it is not tied to
  `.check`, though the check is what it is for.
- **`.labelsHidden()`** keeps working where the OS tells the style, iOS 18, macOS 15 and watchOS 11 and later, and
  stays the system's; the catalog keeps it on the snapshot matrix's list-colors sheet, captured on OS 26.

## The contract and the tools

- `accessibility.hiddenLabel: true`, a new field of the schema: an instance may draw no label and is then given its
  label as its accessible name alone, where it is created. `spec check` requires `label: required` and the slot
  `label` with it, and on Apple a style on a base whose initializer it derives
  (`SystemStyles.Base.hiddenLabelParameters`, today `SwiftUI.Toggle`'s `isOn: Binding<Bool>`).
- The API parity lint derives the two initializers from it (`AppleComponents.HiddenLabel`,
  `APIParity.checkHiddenLabels`) and reports either one missing, changed, without the extension's `where` clause or not
  public, as it does for an own component's view (spec/conventions.md, "A label that is not drawn"). It is hand-written,
  `WestronUI/Checkbox/Toggle+AccessibilityLabel.swift`: its body is the whole implementation.
- The catalog's live row on `checkbox` and both rows of `checkbox-in-list` use it; `CheckboxBehaviorTests` reads their
  names and values and checks that the row's check is its square alone and that its name is read once;
  `CheckboxStyleTests` checks that its fitting size is the hit area alone, and equal to `.labelsHidden()`'s from
  iOS 18 and macOS 15.

## Not measured

- macOS 14 and watchOS 10: the initializer compiles for them and runs the same code; nothing was run there.
  `CheckboxBehaviorTests` ran with the initializer on iOS 17.5, iOS 26.3 and macOS 26 (2026-11-19): the live row's
  check is one `Switch` (iOS) or `CheckBox` (macOS) named "Call the plumber", value `0`, a 44 pt (iOS) or 32 pt
  (macOS) square, and no other element has that name. The unit tests (`CheckboxStyleTests`) ran on macOS 26 and on
  iOS 17.5.
- The accessibility audit: on iOS 26.3 it reports nothing on the rows written with the initializer, in its five tests
  on `checkbox` and `checkbox-in-list`, so the three suppressions the hidden label needed are removed; without them
  the five tests pass on iOS 17.5 too. The audit on macOS was not run; one of the removed suppressions (the ring's
  "Contrast nearly passed") applied there.
- VoiceOver itself, on any OS: what is measured is the hierarchy XCUITest reads.
