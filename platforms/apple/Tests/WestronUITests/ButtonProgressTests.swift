import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#else
    import UIKit
#endif

/// The loading indicator takes the icon's place (contract, `description`; decisions/0001, "Loading"): offered the
/// icon's slot, it draws within it, at every size, so it neither covers the gap to the label nor outgrows icon-only's
/// circle, and the button keeps its width. The system's spinner has fixed sizes, 10 pt at mini on macOS and 14 pt at
/// small on iOS, and a frame does not shrink it (#23); the icon at the symbol's small scale is smaller at size s (#85),
/// so the indicator draws the spinner scaled down to the slot. Its own frame is the slot whatever it draws, so the
/// test reads where the spinner is drawn, its scale included (`ButtonProgress.drawn`), in a window.
@Suite("Button progress indicator")
@MainActor
struct ButtonProgressTests {
    /// Where the spinner was drawn, reported by the indicator.
    @MainActor
    final class Drawn {
        var frame: CGRect?
    }

    @Test("The spinner is drawn within the icon's slot", arguments: ButtonSize.allCases)
    func spinnerIsDrawnWithinTheIconSlot(size: ButtonSize) {
        let metrics = ButtonMetrics(size)
        let progress = ButtonTokens(variant: .primary, destructive: false, states: [], highContrast: false).progress
        // The spinner as the system draws it, before it is scaled.
        let natural = fittingSize(ButtonProgress(color: progress).spinner.fixedSize())
        #expect(natural.width > 0 && natural.height > 0)
        var scaled = false
        // The drawn frame snaps to pixels: a pixel at 3x, a third of a point, is the most it may stand past the slot.
        // An unscaled spinner stands out by half a point or more (10 pt in 9 on macOS, 14 in 11 on iOS).
        let pixel: CGFloat = 0.34
        for icon in [Westron.Icon.check, .xmarkCircleFill, .plus] {
            let slot = fittingSize(
                Image(icon).textRole(metrics.iconFont).imageScale(ButtonMetrics.iconScale).fixedSize())
            let drawn = Drawn()
            show(
                Offer(proposal: ProposedViewSize(slot)) {
                    ButtonProgress(color: progress) { drawn.frame = $0 }
                })
            let frame = try? #require(drawn.frame, "size \(size.rawValue): the spinner reported no frame")
            guard let frame else { continue }
            let name = "size \(size.rawValue), \(icon.rawValue): the spinner drawn at \(frame) in the slot \(slot)"
            #expect(frame.minX >= -pixel && frame.maxX <= slot.width + pixel, "\(name) overflows the slot across")
            #expect(frame.minY >= -pixel && frame.maxY <= slot.height + pixel, "\(name) overflows the slot up or down")
            if natural.width > slot.width + 0.5 || natural.height > slot.height + 0.5 {
                scaled = true
                #expect(frame.width < natural.width, "\(name) is not scaled down from \(natural)")
            }
        }
        if size == .s {
            // At size s the slot is smaller than the system's spinner on every platform, so the scaling is exercised.
            #expect(scaled, "the spinner was never larger than the slot at size s")
        }
    }

    @Test("Loading does not change the width of a button with an icon", arguments: ButtonSize.allCases, [false, true])
    func loadingKeepsTheWidth(size: ButtonSize, iconOnly: Bool) {
        func width(loading: Bool) -> CGFloat {
            fittingSize(
                Button {
                } label: {
                    Label("Save", icon: .check)
                }
                .buttonStyle(.secondary, size: size, iconOnly: iconOnly)
                .loading(loading)
            ).width
        }
        let idle = width(loading: false)
        let loading = width(loading: true)
        #expect(idle > 0)
        #expect(abs(idle - loading) < 0.5, "size \(size.rawValue), iconOnly \(iconOnly): \(idle) at rest, \(loading)")
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

    /// Shows a view in a window and lets it lay out twice, so that what it measured in the first pass takes effect.
    private func show(_ view: some View) {
        #if canImport(AppKit)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.titled], backing: .buffered,
                defer: false)
            window.contentView = NSHostingView(rootView: view.frame(width: 200, height: 200, alignment: .topLeading))
            window.orderFront(nil)
            defer { window.orderOut(nil) }
            for _ in 0..<3 {
                window.contentView?.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
        #else
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            window.rootViewController = UIHostingController(
                rootView: view.frame(width: 200, height: 200, alignment: .topLeading))
            window.isHidden = false
            defer { window.isHidden = true }
            for _ in 0..<3 {
                window.layoutIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
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
