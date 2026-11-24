// Generated from spec/components/rule/rule.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Rule's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a product's
// shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

/// Rule's option `axis`, from its contract.
///
/// horizontal runs along the width and separates groups stacked one above the other; vertical runs along the height and
/// separates groups side by side. A vertical rule takes no label.
public enum RuleAxis: String, CaseIterable, Sendable {
    case horizontal
    case vertical
}

/// Rule's option `purpose`, from its contract.
///
/// separator divides two groups and is quiet; insertion marks where a dragged item would be dropped, between two items
/// of a list (horizontal) or of a row of items side by side (vertical), and must be found at once. An insertion rule
/// takes no label.
public enum RulePurpose: String, CaseIterable, Sendable {
    case separator
    case insertion
}
