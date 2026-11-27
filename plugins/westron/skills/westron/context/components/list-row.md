<!-- Generated from spec/components/list-row/list-row.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# ListRow

`list-row` · approved · westron's own view · used by todo-app/lists-screen, todo-app/list-screen

The core row of a list or a tree: a title, a second line under it, a leading slot and a trailing slot, at a nesting
level with guide lines, on a highlight that shows hover, pressed, selected and a drop onto it.

Patterns that use it: [A list of choices in a sheet](../patterns/choice-list-sheet.md).

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
ListRow(action: { … }) { … }
ListRow(action: { … }) { … } subtitle: { … } leading: { … } trailing: { … }
ListRow { … }
ListRow { … } subtitle: { … } leading: { … } trailing: { … }
….insertionMark(.top)
….selected(isSelected)
….chosen(isChosen)
….dropTarget(isDropTarget)
```

What WestronUI declares for it:

```swift
public struct ListRow: View {
    public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
        level: Int = 0,
        guides: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle = { EmptyView() },
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    )
    public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
        level: Int = 0,
        guides: Bool = true,
        @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle = { EmptyView() },
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    )
    public var body: some View
}
extension View {
    public func insertionMark(_: ListRowInsertionEdge?, level: Int = 0) -> some View
    public func selected(_: Bool) -> some View
    public func chosen(_: Bool) -> some View
    public func dropTarget(_: Bool) -> some View
}
```

Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. A product's shared
code, which cannot import SwiftUI, imports `WestronContract` instead, and its models keep these values, never a size, a
color or a font:

```swift
public enum ListRowInsertionEdge: String, CaseIterable, Sendable { case top, bottom }
```

## Options

- `level`, `Int`: a whole number, at least 0; by default `0`. The row's nesting level: 0 at the top of a tree, one more
  for each level below. The row is indented for each level and, with guides on, draws one guide per level above it.
- `guides`, `Bool`: by default `true`. Whether a row at level 1 or deeper draws its guides. A tree draws them; a picker
  that indents its rows by level to show where a choice stands, as the pilot's "Move to…" sheet does, may leave them
  out. A row at level 0 draws none either way.

## Slots

`title`, `subtitle`, `leading` and `trailing`: each a `@ViewBuilder` closure named after it; `title` is the content
every instance has, the others default to nothing. What a product puts in them takes the text role the component draws
there, with no `.textRole(_:)`; content that sets another role with `.textRole(_:)` keeps it there.

## States

- `hover`: the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it. Never entered on
  watchOS.
- `focus`: the system's keyboard focus. Never entered on watchOS.
- `pressed`: the system's, while a press is held.
- `selected`: `.selected(_:)`, westron's modifier, on the component: the product passes its own state.
- `chosen`: `.chosen(_:)`, westron's modifier, on the component: the product passes its own state.
- `disabled`: `.disabled(_:)`, the system's.
- `dropTarget`: `.dropTarget(_:)`, westron's modifier, on the component: the product passes its own state. Never entered
  on watchOS.

## Forms

The same look in several forms; the product picks one by what it writes.

- `pressable`: the initializer with `action:`. A row with an action, such as opening a list or a task, or choosing a
  list in a picker: a button to assistive technology, named by its words. In a picker the row that holds the current
  value is chosen, announced as selected, and chosen draws nothing: the product draws the check at the row's end,
  decorative, with no label. States: `hover`, `focus`, `pressed`, `selected`, `chosen`, `disabled`, `dropTarget`.
- `static`: the initializer without `action:`. A row without an action, such as a subtask's row, whose check at the
  start is its only control: its words are read as text, in one element, announced as selected while selected or chosen
  and as unavailable while disabled. chosen draws nothing here either: the product draws the check that marks it.
  States: `selected`, `chosen`, `disabled`, `dropTarget`.

## Marks

- `insertion`, `.insertionMark(_: ListRowInsertionEdge?, level: Int = 0)`: Where a dragged row would land beside this
  one: Rule(purpose: insertion) over the row's top or bottom edge, at the level the drop would take. None by default.
  `edge`: The edge of the row the mark is drawn over. `level`: The level the dropped row would take, which may differ
  from this row's: the mark starts at the leading edge of that level's leading slot.

## Accessibility

- Role: `button`. A person can activate it. Announced: `selected` as selected, `chosen` as selected, `disabled` as
  disabled.
- **The accessible name comes from the component's content**: no initializer takes a label, and the caller adds no
  `.accessibilityLabel` of its own, which would replace that name. Which parts are read, and in what order, is in the
  details file.

More: `list-row.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI
builds it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or
"#120" points into westron's repository, not into this bundle.
