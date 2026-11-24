<!-- Generated from spec/components/checkbox/checkbox.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# Checkbox

`checkbox` · approved · a style on `SwiftUI.Toggle` · used by todo-app/list-screen

The round check that marks a task or a subtask done: westron's style on the platform's own toggle, which keeps its role,
its value and its keyboard.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Toggle(…)
    .toggleStyle(.check)
Toggle(isOn: $isOn, accessibilityLabel: "…")
    .toggleStyle(.check)
```

What WestronUI declares for it:

```swift
extension Toggle where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier> {
    public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey)
    @_disfavoredOverload public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S)
}
extension View {
    public func toggleStyle(_: CheckboxVariant) -> some View
}
public enum CheckboxVariant: String, CaseIterable, Sendable { case check }
```

## Options

- `variant`, `CheckboxVariant`: `.check`; no default. The round check; the only variant. The system's own style names
  (automatic, switch, button, checkbox) are not values: westron's overload would shadow them (decisions/0003).

## Slots

`label`: through the system control's own initializer and label, never a westron parameter.

## States

- `checked`: the toggle's value, `isOn`.
- `pressed`: the system's, while a press is held.
- `focus`: the system's keyboard focus. Never entered on watchOS.
- `disabled`: `.disabled(_:)`, the system's.

## Accessibility

- Role: `checkbox`. A person can toggle it. Announced: `checked` as checked, `disabled` as disabled.
- **Every instance needs an accessible name**: the label the system's own initializer of `Toggle` takes, its title or
  the view of its `label:`. westron adds no parameter for it. Name what it does or holds, never what it looks like.
- A control beside its own title draws no label: write `Toggle(isOn: …, accessibilityLabel: …)`, which requires the
  name, and hide the title beside it from assistive technology.

More: `checkbox.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI
builds it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or
"#120" points into westron's repository, not into this bundle.
