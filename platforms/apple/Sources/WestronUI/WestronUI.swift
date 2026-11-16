// The westron module of styles and components for SwiftUI.
//
// It re-exports WestronTokens, so `import WestronUI` gives a view both the SwiftUI side of the tokens
// (`.foregroundStyle(.text.secondary)`, `.textRole(.heading.large)`, `Animation.move`, `CGFloat.radius.card`) and the
// plain values it comes from (`Westron.Color`, `Westron.Category`). The module's rules are in .claude/rules/apple.md: tokens only, no raw values;
// styles on top of system controls instead of custom wrappers (decisions/0003).

@_exported import WestronTokens
