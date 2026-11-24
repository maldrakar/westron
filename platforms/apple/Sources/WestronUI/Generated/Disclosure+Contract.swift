// Generated from spec/components/disclosure/disclosure.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// Disclosure's API from its contract: the overload of `disclosureGroupStyle` that products call, which applies the
// hand-written `DisclosureVariantStyle` (decisions/0001), and the tables that style reads. The enums of its options are
// in WestronContract/Generated/Disclosure+Contract.swift (decisions/0017).

import SwiftUI
import WestronContract

// Disclosure does not exist on watchOS, whose SwiftUI has no DisclosureGroup (the contract's `platforms` block).
#if !os(watchOS)
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
