// The westron module of styles and components for SwiftUI.
//
// It re-exports WestronTokens, so `import WestronUI` gives a view both the SwiftUI side of the tokens
// (`.foregroundStyle(.text.secondary)`, `.textRole(.heading.large)`, `Animation.move`, `CGFloat.radius.card`) and the
// plain values it comes from (`Westron.Color`, `Westron.Category`). It re-exports WestronContract, the contracts'
// vocabulary, so the same import gives the option enums its styles and views take (`ButtonVariant`, `RuleAxis`), which
// a product's shared code imports alone, without SwiftUI (decisions/0017). The module's rules are in
// .claude/rules/apple.md: tokens only, no raw values; styles on top of system controls instead of custom wrappers
// (decisions/0003).

@_exported import WestronContract
@_exported import WestronTokens
