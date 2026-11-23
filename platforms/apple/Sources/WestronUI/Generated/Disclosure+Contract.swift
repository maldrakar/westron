// Generated from spec/components/disclosure/disclosure.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Disclosure's API from its contract: the enums of its options, the overload of `disclosureGroupStyle` that products
// call, which applies the hand-written `DisclosureVariantStyle` (decisions/0001), and the tables that style reads.

import SwiftUI

// Disclosure does not exist on watchOS, whose SwiftUI has no DisclosureGroup (the contract's `platforms` block).
#if !os(watchOS)
    /// Disclosure's option `variant`, from its contract.
    ///
    /// The chevron; the only variant, so that a call reads .disclosureGroupStyle(.chevron). The system's only style
    /// name, automatic, is not a value: westron's overload would shadow it (decisions/0003). A tree branch and a block
    /// header are not variants: they differ in the label, not in the control (decisions/0001, P3).
    public enum DisclosureVariant: String, CaseIterable, Sendable {
        case chevron
    }

    extension View {
        /// Applies westron's Disclosure style, from its contract, to the system's `DisclosureGroup` in this view:
        /// `.disclosureGroupStyle(.chevron)`.
        ///
        /// - Parameters:
        ///   - variant: See `DisclosureVariant`. Every call names one.
        public func disclosureGroupStyle(_ variant: DisclosureVariant) -> some View {
            disclosureGroupStyle(DisclosureVariantStyle(variant: variant))
        }
    }

    extension DisclosureVariant {
        /// The variant the current OS draws for this one (the contract's `platforms` block). Every Apple OS offers
        /// every variant, so it is the value itself.
        var offered: DisclosureVariant {
            self
        }
    }

    /// The states of a Disclosure in its contract, in its order. The system control has some of them; the others are
    /// set through the environment (spec/conventions.md).
    enum DisclosureState: String, CaseIterable, Sendable {
        case expanded
        case hover
        case focus
        case pressed
        case disabled

        /// Whether the current OS ever enters the state.
        var isEntered: Bool {
            true
        }
    }
#endif
