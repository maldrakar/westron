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
- A label is optional: read below what an instance without one is.

A rule without a label is decorative, whatever its purpose: it is hidden from assistive technology, which already reads
the groups it separates by their own content, and learns of a drop's place from the drag, not from the line. A labelled
rule names the group under it, so its label is announced as a heading with that text, and a person can move from one
group to the next by headings; the line itself is not announced. The label is read whole, also where it is truncated on
screen.

## Do not

- **Never**: a filled `label` slot with `axis` other than `.horizontal` or `purpose` other than `.separator`. Only a
  horizontal separator takes a label: no consumer has a vertical one, which in a bar is about as tall as one line of
  text, and an insertion rule marks a place, it names nothing.

## Behavior

A separator is color.border.default at stroke.thin; in the standard themes it is decoration, since space and alignment
also show the grouping, and in the high-contrast themes its color reaches 3:1 and its width stays (design-language/02,
04). A horizontal separator may carry a label at its leading end, the name of the group under it, such as an area's line
across the Lists screen's tree: the label on one line, then the line across the rest. An insertion rule marks the point
where a dragged row would be dropped, at stroke.thick in color.border.insertion, which a person finds at once
(design-language/04, "Lines"); where it stands, and when, is the list's or the product's, which follows the drag. A
horizontal rule spans the width it is given, a vertical one the height; the product gives it that length and the space
around it with its stack and spacing tokens. Only straight rules: a tree's nesting guides go with ListRow (#119), and
the slot a dragged row opens on a phone, a dashed outline, is not a Rule. It has no states.

## On Apple

A view named Rule: Rule(), Rule(axis: .vertical), Rule(purpose: .insertion), and Rule("Work") with a label, or
Rule(area.name) for a label that is not localized, as Text and Label take their titles. The initializers with a label
take no axis and no purpose, so a labelled rule is a horizontal separator by construction. A type named Divider would
collide with SwiftUI.Divider in every file that imports SwiftUI (decisions/0003, point 3). The line is a filled
rectangle across its axis, rounded as a Capsule for an insertion rule, that fills the length it is offered along it, so
it needs no stack to orient it, unlike the system Divider. A label is a Text in .textRole(.heading.overline), on one
line, truncated at its end with an ellipsis when the rule is narrower than it, carrying the trait isHeader;
container.gap after it, a @ScaledMetric relative to the label's text style so that it keeps its proportion at every text
size, the line fills the rest, centred across the label's line, and draws nothing when no length is left (a truncated
label may leave it a few points). The heading has no level. An empty label that is not localized, such as an unnamed
area's empty name, is no label: the rule is drawn alone. An unlabelled rule is hidden from accessibility. On watchOS a
rule is drawn as on the other OSes.
