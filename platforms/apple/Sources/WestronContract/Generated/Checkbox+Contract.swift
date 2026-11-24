// Generated from spec/components/checkbox/checkbox.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Checkbox's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a
// product's shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

/// Checkbox's option `variant`, from its contract.
///
/// The round check; the only variant. The system's own style names (automatic, switch, button, checkbox) are not
/// values: westron's overload would shadow them (decisions/0003).
public enum CheckboxVariant: String, CaseIterable, Sendable {
    case check
}
