<!-- Generated from spec/components/text/text.spec.yaml by `tools/westron generate`. Do not edit: change the source and
generate again (decisions/0016). -->

# Text

`text` · approved · an extension of `SwiftUI.Text` · used by todo-app/lists-screen, todo-app/list-screen

A text role on the platform's own text view: westron adds no text type of its own, only the role.

## In SwiftUI

`import WestronUI`. A call writes at least:

```swift
Text("…")
    .textRole(.body.regular)
```

What WestronUI declares for it:

```swift
extension View {
    public func textRole(_: Westron.TextRole) -> some View
}
extension Text {
    @_disfavoredOverload public func textRole(_: Westron.TextRole) -> Text
}
```

## Options

- `role`, `Westron.TextRole`: a token of `typography` (`../tokens/typography.md`); no default. No default: every use
  names its role. The values are the tokens under typography, by their path after it, heading.large to code.strong, so
  the contract and the tokens cannot drift. A role is chosen by what the text is, never by its size; a product that
  needs a size the roles do not have asks for a new role (design-language/03). What a product puts in a slot that a
  westron component draws in a role of its own, a text or an icon, takes that role with no `.textRole(_:)`: the `label`
  and `icon` of `Button`, the `label` and `icon` of `Chip`, the `title` and `subtitle` of `ListRow` and the `label` of
  `Rule`; a call sets another role there only where that component's card allows it.

## Slots

`label`: the `Text` itself.

## Accessibility

- Role: `text`.

More: `text.details.md` holds how assistive technology reads it; how it behaves, sizes and draws; how WestronUI builds
it on Apple and each OS. Read it when this card does not settle a case. A reference such as "decisions/0001" or "#120"
points into westron's repository, not into this bundle.
