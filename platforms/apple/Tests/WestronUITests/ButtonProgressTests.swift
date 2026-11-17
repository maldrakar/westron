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
/// square. On macOS the system's spinner is 16 pt at the small control size, larger than a button's icon, and a frame
/// does not shrink it (#23).
@Suite("Button progress indicator")
@MainActor
struct ButtonProgressTests {
    @Test("The indicator fits the icon's slot", arguments: ButtonSize.allCases)
    func indicatorFitsTheIconSlot(size: ButtonSize) {
        let metrics = ButtonMetrics(size)
        let progress = ButtonTokens(variant: .primary, destructive: false, states: []).progress
        for icon in [Westron.Icon.check, .xmarkCircleFill, .plus] {
            let slot = fittingSize(Image(icon).textRole(metrics.iconFont).fixedSize())
            let indicator = fittingSize(Offer(proposal: ProposedViewSize(slot)) { ButtonProgress(color: progress) })
            // No wider than the slot, so the gap to the label stays whole, and within a square of the slot's longer
            // side: on iOS the 14 pt spinner is 1 pt taller than `plus` at size s, a wide glyph, and that is fine.
            let side = max(slot.width, slot.height)
            #expect(
                indicator.width <= slot.width + 0.5 && max(indicator.width, indicator.height) <= side + 0.5,
                "size \(size.rawValue): the indicator takes \(indicator) in the slot of \(icon.rawValue), \(slot)")
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
