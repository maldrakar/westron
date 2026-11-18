// Generated from spec/components/rule/rule.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Rule's API from its contract: the enums of its options. It is an own component, and the view `Rule` and its
// `Rule.init(axis:)` are hand-written in WestronUI/Rule/; the API parity lint holds the signature to the contract
// (spec/conventions.md, "Own components").

/// Rule's option `axis`, from its contract.
///
/// horizontal runs along the width and separates groups stacked one above the other; vertical runs along the height and
/// separates groups side by side.
public enum RuleAxis: String, CaseIterable, Sendable {
    case horizontal
    case vertical
}
