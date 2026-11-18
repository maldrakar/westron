#if canImport(AppKit)
    import AppKit
    import SwiftUI
    import Testing

    @testable import WestronUI

    /// On macOS the hit area is the drawn button (contract, `platforms.apple.macos`): a click anywhere in what is drawn
    /// reaches it, an outlined or unfilled button's empty inside included, and a click past the drawn edge misses. The
    /// clicks are AppKit events sent to a window, so the screen is not used; the catalog's UI test
    /// (ButtonBehaviorTests) clicks the real pointer.
    @Suite("Button hit area on macOS")
    @MainActor
    struct ButtonHitAreaTests {
        /// Counts the actions a button runs, and keeps the button's frame in the hosting view.
        @MainActor
        final class Presses {
            var count = 0
            var frame = CGRect.zero
        }

        /// The button in the middle of a window larger than it.
        struct Sample: View {
            static let space = "host"
            let presses: Presses
            let variant: ButtonVariant
            let size: ButtonSize
            let iconOnly: Bool

            var body: some View {
                Button {
                    presses.count += 1
                } label: {
                    Label("Add", icon: .plus)
                }
                .buttonStyle(variant, size: size, iconOnly: iconOnly)
                .background {
                    GeometryReader { proxy in
                        Color.clear.onAppear { presses.frame = proxy.frame(in: .named(Self.space)) }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The hosting view's own space: `.global` starts above it, at the window's title bar.
                .coordinateSpace(name: Self.space)
            }
        }

        /// Clicks `point`, in the window's coordinates (origin bottom left), and returns whether the button ran.
        private func click(_ window: NSWindow, at point: NSPoint, presses: Presses) -> Bool {
            let before = presses.count
            for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                guard
                    let event = NSEvent.mouseEvent(
                        with: type, location: point, modifierFlags: [],
                        timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                        context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
                else { return false }
                window.sendEvent(event)
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            return presses.count > before
        }

        @Test(
            "a click inside the drawn edge reaches the button, past it misses",
            arguments: ButtonVariant.allCases, [false, true])
        func clicksInsideTheDrawnButton(variant: ButtonVariant, iconOnly: Bool) {
            for size in ButtonSize.allCases {
                let presses = Presses()
                let host = NSHostingView(
                    rootView: Sample(presses: presses, variant: variant, size: size, iconOnly: iconOnly))
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 320, height: 200), styleMask: [.titled],
                    backing: .buffered, defer: false)
                window.contentView = host
                window.makeKeyAndOrderFront(nil)
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.1))
                defer { window.orderOut(nil) }

                // The hosting view is flipped, so the conversion turns its top-left frame into the window's.
                let button = host.convert(presses.frame, to: nil)
                #expect(button.width > 0, "the button's frame was not reported")
                let name = "\(variant), size \(size), iconOnly \(iconOnly)"
                // 1.5 pt in from each edge, at its middle: off the label, which a click on an unfilled button
                // must not need.
                let inside = [
                    ("bottom", NSPoint(x: button.midX, y: button.minY + 1.5)),
                    ("top", NSPoint(x: button.midX, y: button.maxY - 1.5)),
                    ("left", NSPoint(x: button.minX + 1.5, y: button.midY)),
                    ("right", NSPoint(x: button.maxX - 1.5, y: button.midY)),
                ]
                for (edge, point) in inside {
                    #expect(
                        click(window, at: point, presses: presses), "\(name): 1.5 pt inside the \(edge) edge missed")
                }
                let outside = [
                    ("bottom", NSPoint(x: button.midX, y: button.minY - 1.5)),
                    ("right", NSPoint(x: button.maxX + 1.5, y: button.midY)),
                ]
                for (edge, point) in outside {
                    #expect(
                        !click(window, at: point, presses: presses), "\(name): 1.5 pt past the \(edge) edge reached it")
                }
            }
        }
    }
#endif
