<!-- Generated from spec/components/disclosure/disclosure.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# Disclosure

`disclosure` · approved · a style on `SwiftUI.DisclosureGroup` · used by todo-app/lists-screen, todo-app/list-screen

The collapse chevron of a group that folds and unfolds: westron's style on the platform's own disclosure group, which
keeps its role, its expanded or collapsed value and its binding.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
DisclosureGroup(…)
    .disclosureGroupStyle(.chevron)
….disclosureAlignsLeaves()
```

What WestronUI declares for it:

```swift
extension View {
    public func disclosureAlignsLeaves(_: Bool = true) -> some View
    public func disclosureGroupStyle(_: DisclosureVariant) -> some View
}
public enum DisclosureVariant: String, CaseIterable, Sendable { case chevron }
```

Not on watchOS: SwiftUI has no base control there, so WestronUI declares all of it under `#if !os(watchOS)`, and a
product's call stands under the same condition.

## Options

- `variant`, `DisclosureVariant`: `.chevron`; no default. The chevron; the only variant, so that a call reads
  .disclosureGroupStyle(.chevron). The system's only style name, automatic, is not a value: westron's overload would
  shadow it (decisions/0003). A tree branch and a block header are not variants: they differ in the label, not in the
  control (decisions/0001, P3).

## Slots

`label` and `content`: through the system control's own initializer and label, never a westron parameter.

## States

- `expanded`: the group's `isExpanded`.
- `hover`: the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it.
- `focus`: the system's keyboard focus.
- `pressed`: the system's, while a press is held.
- `disabled`: `.disabled(_:)`, the system's.

## Context it sets

- `alignsLeaves`, `.disclosureAlignsLeaves(_: Bool = true)`, on an ancestor: Every ListRow below that is no Disclosure's
  label, a leaf of the tree, keeps the chevron's cell empty: the same frame as a branch's cell, size.target.minimum
  across, after the same container.trailingGap, scaled as the row scales it, so that the leaves' trailing slots stand in
  their branches' column, as the pilot's counts do (decisions/0001, "Leaf alignment"). Set once on the tree, where the
  style is set; off by default, so that the rows of a block, under a block header, keep their whole width. A branch's
  label draws its real chevron whether it is set or not. Only a ListRow reads it.

## Accessibility

- Role: `disclosure`. A person can toggle it. Announced: `expanded` as expanded, `disabled` as disabled.
- **Every instance needs an accessible name**: the label the system's own initializer of `DisclosureGroup` takes, its
  title or the view of its `label:`. westron adds no parameter for it. Name what it does or holds, never what it looks
  like.

More: `disclosure.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI
builds it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or
"#120" points into westron's repository, not into this bundle.
