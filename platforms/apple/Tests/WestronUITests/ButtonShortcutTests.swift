#if canImport(AppKit)
    import AppKit
    import SwiftUI
    import Testing

    @testable import WestronUI

    /// A loading button accepts no presses (contract, `description`), a keyboard shortcut's included. SwiftUI runs a
    /// shortcut's action itself, around the button's style, so `.loading(_:)` takes the shortcut away while loading
    /// (States.swift). The window gets the key as AppKit hands it a key equivalent; the catalog's UI test
    /// (ButtonBehaviorTests) presses the real key.
    @Suite("Button keyboard shortcuts")
    @MainActor
    struct ButtonShortcutTests {
        /// Counts the actions a button runs.
        @MainActor
        final class Presses {
            var count = 0
        }

        /// A window that shows `view`, sends it the key equivalent `key` with `modifiers` and returns whether the
        /// window handled it.
        @MainActor
        final class Host<Content: View> {
            let window: NSWindow
            let host: NSHostingView<Content>

            init(_ view: Content) {
                window = NSWindow(
                    contentRect: NSRect(origin: .zero, size: NSSize(width: 320, height: 160)), styleMask: [.titled],
                    backing: .buffered, defer: false)
                host = NSHostingView(rootView: view)
                window.contentView = host
                window.makeKeyAndOrderFront(nil)
                settle()
            }

            var rootView: Content {
                get { host.rootView }
                set {
                    host.rootView = newValue
                    settle()
                }
            }

            @discardableResult
            func press(_ key: String, modifiers: NSEvent.ModifierFlags = [], keyCode: UInt16) -> Bool {
                let event = NSEvent.keyEvent(
                    with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0,
                    windowNumber: window.windowNumber, context: nil, characters: key, charactersIgnoringModifiers: key,
                    isARepeat: false, keyCode: keyCode)
                var handled = false
                if let event { handled = window.performKeyEquivalent(with: event) }
                settle()
                return handled
            }

            func pressReturn() { press("\r", keyCode: 36) }
            func pressCommandE() { press("e", modifiers: .command, keyCode: 14) }

            func close() { window.orderOut(nil) }

            private func settle() {
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            }
        }

        /// The spelling `.loading(_:)` documents: the state on the button, then its shortcut.
        struct Sample: View {
            let presses: Presses
            var isLoading: Bool
            var shortcut: KeyboardShortcut

            var body: some View {
                Button("Publish") { presses.count += 1 }
                    .buttonStyle(.primary)
                    .loading(isLoading)
                    .keyboardShortcut(shortcut)
            }
        }

        @Test(
            "a loading button refuses its shortcut and takes it again at rest",
            arguments: [("Return", KeyboardShortcut.defaultAction), ("⌘E", KeyboardShortcut("e", modifiers: .command))])
        func loadingRefusesTheShortcut(name: String, shortcut: KeyboardShortcut) {
            let presses = Presses()
            let host = Host(Sample(presses: presses, isLoading: true, shortcut: shortcut))
            defer { host.close() }
            func press() { shortcut == .defaultAction ? host.pressReturn() : host.pressCommandE() }

            press()
            #expect(presses.count == 0, "\(name) triggered a loading button")
            // The same button, out of loading: the shortcut is back.
            host.rootView.isLoading = false
            press()
            #expect(presses.count == 1, "\(name) did not trigger the button at rest")
            // And into loading again.
            host.rootView.isLoading = true
            press()
            #expect(presses.count == 1, "\(name) triggered the button once it was loading again")
        }

        /// A shortcut applied before `.loading(_:)`, closer to the button, is the one the button takes: `.loading(_:)`
        /// cannot remove it, and SwiftUI runs it. `.loading(_:)` documents the order.
        @Test("a shortcut applied inside .loading(_:) still triggers the button")
        func shortcutInsideLoadingWins() {
            let presses = Presses()
            let host = Host(
                Button("Publish") { presses.count += 1 }
                    .buttonStyle(.primary)
                    .keyboardShortcut(.defaultAction)
                    .loading(true))
            defer { host.close() }
            host.pressReturn()
            withKnownIssue("a shortcut closer to the button than .loading(_:) wins over it") {
                #expect(presses.count == 0)
            }
        }

        /// `.loading(_:)` on a container takes the shortcut set outside it away from every control inside while it
        /// loads, a system button that knows nothing of loading included (the caveat on `.loading(_:)`).
        @Test("on a container, loading takes the outer shortcut from a system button inside")
        func containerTakesTheShortcutFromSystemControls() {
            // At rest the shortcut reaches the system button: the control.
            for isLoading in [false, true] {
                let presses = Presses()
                let host = Host(
                    VStack {
                        Button("Publish") { presses.count += 1 }
                    }
                    .loading(isLoading)
                    .keyboardShortcut(.defaultAction))
                host.pressReturn()
                host.close()
                #expect(presses.count == (isLoading ? 0 : 1), "loading: \(isLoading)")
            }
        }
    }
#endif
