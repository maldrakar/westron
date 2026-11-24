// Generated from spec/components/chip/chip.spec.yaml by `tools/westron generate`. Do not edit: change the contract and
// generate again (spec/conventions.md).
//
// Chip's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a product's
// shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

/// Chip's option `variant`, from its contract.
///
/// The chip; the only variant, so that a call reads .toggleStyle(.chip), .buttonStyle(.chip) and .labelStyle(.chip). No
/// system style of the three bases is named chip, and neither is a value of Button's or Checkbox's variant, which share
/// two of the modifiers (decisions/0003; decisions/0001, P3).
public enum ChipVariant: String, CaseIterable, Sendable {
    case chip
}
