// The westron module of styles and components for SwiftUI.
//
// It re-exports WestronTokens, so `import WestronUI` gives a view both the SwiftUI accessors (`Color.textSecondary`,
// `Font.headingLarge`, `Animation.rowLeave`, `CGFloat.space100`) and the plain values they come from (`Westron.Color`,
// `Westron.Category`). The module's rules are in .claude/rules/apple.md: tokens only, no raw values;
// styles on top of system controls instead of custom wrappers (decisions/0003).

@_exported import WestronTokens
