// Generated from spec/components/disclosure/disclosure.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Disclosure's vocabulary from its contract: the enums of its options. WestronContract imports nothing, so that a
// product's shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side (decisions/0017).

// Disclosure does not exist on watchOS, whose SwiftUI has no DisclosureGroup (the contract's `platforms` block); its
// vocabulary is there only where the component is.
#if !os(watchOS)
    /// Disclosure's option `variant`, from its contract.
    ///
    /// The chevron; the only variant, so that a call reads .disclosureGroupStyle(.chevron). The system's only style
    /// name, automatic, is not a value: westron's overload would shadow it (decisions/0003). A tree branch and a block
    /// header are not variants: they differ in the label, not in the control (decisions/0001, P3).
    public enum DisclosureVariant: String, CaseIterable, Sendable {
        case chevron
    }
#endif
