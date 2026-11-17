import SwiftUI
import Testing

@testable import WestronUI

#if canImport(AppKit)
    import AppKit
#else
    import UIKit
#endif

/// A loading button puts the indicator in its icon's place, and before a label without an icon (contract,
/// `description`; P13). Which of the two applies must follow the label in the same update: a label that changes between
/// `Text` and `Label` while the button loads never shows two indicators or none. The width tells: a `Text` label is
/// wider by the indicator and the gap while loading, and a `Label` with a second indicator would be too.
///
/// `ImageRenderer` draws a single update, with no second one for state set during it, which is where a choice that lags
/// an update shows; a hosting view settles before it reports its size, so it gives the width expected.
@Suite("Button label kind")
@MainActor
struct ButtonLabelKindTests {
    /// A loading button whose label is a `Label` with an icon or a `Text`, with the same title.
    struct Sample: View {
        var withIcon: Bool
        var isLoading = true

        var body: some View {
            Button {
            } label: {
                if withIcon {
                    Label("Publish", icon: .check)
                } else {
                    Text("Publish")
                }
            }
            .buttonStyle(.primary)
            .loading(isLoading)
        }
    }

    @Test("one update draws the indicator for the label the button has", arguments: [true, false])
    func oneUpdateFollowsTheLabel(startsWithIcon: Bool) throws {
        let renderer = ImageRenderer(content: Sample(withIcon: startsWithIcon))
        let appeared = try width(renderer)
        #expect(abs(appeared - settledWidth(withIcon: startsWithIcon)) < 1, "as it appears: \(appeared)")
        // The same button, its label changed, then changed back.
        for withIcon in [!startsWithIcon, startsWithIcon] {
            renderer.content = Sample(withIcon: withIcon)
            let changed = try width(renderer)
            #expect(
                abs(changed - settledWidth(withIcon: withIcon)) < 1,
                "the label became \(withIcon ? "a Label" : "a Text"): \(changed)")
        }
    }

    /// A control for the test above: a hosted button settles before it reports its size, so on macOS this passed with
    /// the lagging state too, and it is not a regression test for the lag there. On the iOS simulator, an off-window
    /// `UIHostingController` did not settle, and with the lagging state a loading `Text` label did not widen.
    @Test("a hosted button's width follows its label's kind while loading", arguments: [true, false])
    func hostedWidthFollowsTheLabel(startsWithIcon: Bool) {
        #if canImport(AppKit)
            let host = NSHostingView(rootView: Sample(withIcon: startsWithIcon))
        #else
            let host = UIHostingController(rootView: Sample(withIcon: startsWithIcon))
        #endif
        let withoutIcon = settledWidth(withIcon: false)
        let withIcon = settledWidth(withIcon: true)
        // A Text label widens by the indicator and the gap, which together are wider than 10 pt at any size.
        let atRest = settledWidth(withIcon: false, isLoading: false)
        #expect(withoutIcon - atRest > 10, "a Text label did not widen: \(withoutIcon) against \(atRest) at rest")
        for kind in [!startsWithIcon, startsWithIcon] {
            host.rootView = Sample(withIcon: kind)
            #expect(fittingSize(host).width == (kind ? withIcon : withoutIcon))
        }
    }

    /// The width of the image the renderer draws, in points: whole pixels, so up to one pixel wider than the view.
    private func width(_ renderer: ImageRenderer<Sample>) throws -> CGFloat {
        let image = try #require(renderer.cgImage)
        return CGFloat(image.width) / renderer.scale
    }

    /// The width of a button with this label, hosted on its own once it has settled.
    private func settledWidth(withIcon: Bool, isLoading: Bool = true) -> CGFloat {
        let sample = Sample(withIcon: withIcon, isLoading: isLoading)
        #if canImport(AppKit)
            return fittingSize(NSHostingView(rootView: sample)).width
        #else
            return fittingSize(UIHostingController(rootView: sample)).width
        #endif
    }

    #if canImport(AppKit)
        private func fittingSize(_ host: NSHostingView<Sample>) -> CGSize {
            host.layoutSubtreeIfNeeded()
            return host.fittingSize
        }
    #else
        private func fittingSize(_ host: UIHostingController<Sample>) -> CGSize {
            host.sizeThatFits(in: CGSize(width: 1000, height: 1000))
        }
    #endif
}
