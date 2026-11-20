import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#else
    import UIKit
#endif

/// The loading indicator takes the icon's place (contract, `description`; decisions/0001, "Loading"): offered the
/// icon's slot, it fits in it, at every size, so it neither covers the gap to the label nor outgrows icon-only's
/// square. The system's spinner has fixed sizes, 10 pt at mini on macOS and 14 pt at small on iOS, and a frame does
/// not shrink it (#23); the icon at the symbol's small scale is smaller at size s (#85), so the indicator draws the
/// spinner scaled down to the slot.
@Suite("Button progress indicator")
@MainActor
struct ButtonProgressTests {
    @Test("The indicator fits the icon's slot", arguments: ButtonSize.allCases)
    func indicatorFitsTheIconSlot(size: ButtonSize) {
        let metrics = ButtonMetrics(size)
        let progress = ButtonTokens(variant: .primary, destructive: false, states: [], highContrast: false).progress
        // The spinner as the system draws it, before it is scaled.
        let natural = fittingSize(ButtonProgress(color: progress).spinner.fixedSize())
        #expect(natural.width > 0 && natural.height > 0)
        for icon in [Westron.Icon.check, .xmarkCircleFill, .plus] {
            let slot = fittingSize(
                Image(icon).textRole(metrics.iconFont).imageScale(ButtonMetrics.iconScale).fixedSize())
            // The indicator takes the slot it is offered, no more.
            let indicator = fittingSize(Offer(proposal: ProposedViewSize(slot)) { ButtonProgress(color: progress) })
            #expect(
                indicator.width <= slot.width + 0.5 && indicator.height <= slot.height + 0.5,
                "size \(size.rawValue): the indicator takes \(indicator) in the slot of \(icon.rawValue), \(slot)")
            // And the spinner it draws, scaled, fits in it, so the gap to the label stays whole.
            let scale = ButtonProgress.fittingScale(natural: natural, slot: slot)
            #expect(scale <= 1)
            #expect(
                natural.width * scale <= slot.width + 0.5 && natural.height * scale <= slot.height + 0.5,
                "size \(size.rawValue): the spinner, \(natural) at \(scale), in the slot of \(icon.rawValue), \(slot)")
        }
    }

    /// The size a view takes, laid out on its own.
    private func fittingSize(_ view: some View) -> CGSize {
        #if canImport(AppKit)
            let host = NSHostingView(rootView: view)
            host.layoutSubtreeIfNeeded()
            return host.fittingSize
        #else
            return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 1000, height: 1000))
        #endif
    }
}

/// Reports the size its one subview takes when offered `proposal`, as the icon's overlay offers it.
private struct Offer: Layout {
    let proposal: ProposedViewSize

    func sizeThatFits(proposal _: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(proposal) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: proposal)
    }
}
