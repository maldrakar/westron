<!-- Generated from spec/components/rule/rule.spec.yaml by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Rule

`rule` · approved · westron's own view · used by todo-app/lists-screen, todo-app/list-screen

A straight line that separates two groups, or marks where a dragged item would land: westron's own line, the same on
every platform, rather than the system's separator, whose thickness and color the system fixes.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Rule()
Rule("…")
```

What WestronUI declares for it:

```swift
public struct Rule: View {
    public init(axis: RuleAxis = .horizontal, purpose: RulePurpose = .separator)
    public init(_: LocalizedStringKey)
    @_disfavoredOverload public init<S: StringProtocol>(_: S)
    public var body: some View
}
```

Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. A product's shared
code, which cannot import SwiftUI, imports `WestronContract` instead, and its models keep these values, never a size, a
color or a font:

```swift
public enum RuleAxis: String, CaseIterable, Sendable { case horizontal, vertical }
public enum RulePurpose: String, CaseIterable, Sendable { case separator, insertion }
```

## Options

- `axis`, `RuleAxis`: `.horizontal`, `.vertical`; by default `.horizontal`. horizontal runs along the width and
  separates groups stacked one above the other; vertical runs along the height and separates groups side by side. A
  vertical rule takes no label.
- `purpose`, `RulePurpose`: `.separator`, `.insertion`; by default `.separator`. separator divides two groups and is
  quiet; insertion marks where a dragged item would be dropped, between two items of a list (horizontal) or of a row of
  items side by side (vertical), and must be found at once. An insertion rule takes no label.

## Slots

`label`: drawn text, the initializer's first, unlabeled argument.

## Accessibility

- Role: `heading`.
- The accessible name is the drawn text, the initializer's first argument; an instance without it has none.

## Do not

- **Never**: a filled `label` slot with `axis` other than `.horizontal` or `purpose` other than `.separator`. Only a
  horizontal separator takes a label: no consumer has a vertical one, which in a bar is about as tall as one line of
  text, and an insertion rule marks a place, it names nothing.

More: `rule.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI builds
it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or "#120"
points into westron's repository, not into this bundle.
