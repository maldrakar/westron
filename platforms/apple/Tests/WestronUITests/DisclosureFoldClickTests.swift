#if canImport(AppKit)
    import AppKit
    import SwiftUI
    import Testing

    @testable import WestronUI

    /// The fold of a branch whose row is disabled, pressed (the contracts' disabled, ListRow's and Disclosure's): a
    /// disabled row is not pressable, but its chevron takes its state from its DisclosureGroup, so a click on it folds
    /// the branch whether the row is pressable, static or enabled; a click on the disabled row's title runs nothing; a
    /// disabled group's chevron folds nothing. The clicks are AppKit events sent to a window, as in ButtonHitAreaTests,
    /// so the screen is not used.
    @Suite("Disclosure: the fold of a disabled row, clicked")
    @MainActor
    struct DisclosureFoldClickTests {
        /// What the branch's binding and the row's action saw, and the row's and its title's frames.
        @MainActor
        final class Box {
            var expanded = false
            var actions = 0
            var row = CGRect.zero
            var title = CGRect.zero
        }

        enum RowForm {
            case pressable, `static`
        }

        static let space = "host"

        /// A branch whose label is a ListRow, the row or the group disabled as asked, at the top of a window.
        struct Sample: View {
            let box: Box
            let form: RowForm
            let rowDisabled: Bool
            let groupDisabled: Bool

            var body: some View {
                DisclosureGroup(isExpanded: Binding(get: { box.expanded }, set: { box.expanded = $0 })) {
                    Text(verbatim: "Child")
                } label: {
                    row.disabled(rowDisabled).recording { box.row = $0 }
                }
                .disclosureGroupStyle(.chevron)
                .disabled(groupDisabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // The hosting view's own space, its origin at its top left.
                .coordinateSpace(name: DisclosureFoldClickTests.space)
            }

            @ViewBuilder private var row: some View {
                switch form {
                case .pressable:
                    ListRow(action: { box.actions += 1 }) { title }
                case .static:
                    ListRow { title }
                }
            }

            private var title: some View {
                Text(verbatim: "Work").recording { box.title = $0 }
            }
        }

        /// The outcome of a click on the chevron and of a click on the title, each from the branch collapsed.
        struct Outcome {
            var chevronFolds: Bool
            var titleActions: Int
        }

        func clicks(_ form: RowForm, rowDisabled: Bool = false, groupDisabled: Bool = false) throws -> Outcome {
            let box = Box()
            let host = NSHostingView(
                rootView: Sample(box: box, form: form, rowDisabled: rowDisabled, groupDisabled: groupDisabled))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 200), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.contentView = host
            window.orderFront(nil)
            defer { window.orderOut(nil) }
            for _ in 0..<4 {
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
            // The hosting view is flipped, so the conversion turns its top-left frames into the window's.
            let row = host.convert(box.row, to: nil)
            let title = host.convert(box.title, to: nil)
            try #require(row.width > 0 && title.width > 0, "the row's frames were not reported")
            // The chevron's cell is the last item at the row's end, inside its padding (ListRow's contract).
            let side = DisclosureMetrics.minimumHitSide
            let chevron = NSPoint(x: row.maxX - CGFloat(ListRowMetrics.paddingHorizontal) - side / 2, y: row.midY)

            box.expanded = false
            click(window, at: chevron)
            let folds = box.expanded
            box.expanded = false
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let actionsBefore = box.actions
            click(window, at: NSPoint(x: title.midX, y: title.midY))
            #expect(!box.expanded, "a click on the title folded the branch")
            return Outcome(chevronFolds: folds, titleActions: box.actions - actionsBefore)
        }

        /// Clicks `point`, in the window's coordinates (origin bottom left).
        private func click(_ window: NSWindow, at point: NSPoint) {
            for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                guard
                    let event = NSEvent.mouseEvent(
                        with: type, location: point, modifierFlags: [],
                        timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                        context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
                else { return }
                window.sendEvent(event)
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }

        @Test("a click on the chevron of an enabled row folds the branch, and on its title runs the row's action")
        func enabledRow() throws {
            let outcome = try clicks(.pressable)
            #expect(outcome.chevronFolds)
            #expect(outcome.titleActions == 1)
        }

        @Test("a click on the chevron of a disabled pressable row folds the branch; on its title runs nothing")
        func disabledPressableRow() throws {
            let outcome = try clicks(.pressable, rowDisabled: true)
            #expect(outcome.chevronFolds, "the chevron of a row disabled alone did not fold the branch")
            #expect(outcome.titleActions == 0)
        }

        @Test("a click on the chevron of a disabled static row folds the branch")
        func disabledStaticRow() throws {
            #expect(try clicks(.static, rowDisabled: true).chevronFolds)
        }

        @Test("a disabled group's chevron folds nothing")
        func disabledGroup() throws {
            let outcome = try clicks(.pressable, groupDisabled: true)
            #expect(!outcome.chevronFolds)
            #expect(outcome.titleActions == 0)
        }
    }

    extension View {
        /// Tells `frame` the view's frame in the test's host space, as it lays out.
        fileprivate func recording(_ frame: @escaping @MainActor (CGRect) -> Void) -> some View {
            onGeometryChange(for: CGRect.self) {
                $0.frame(in: .named(DisclosureFoldClickTests.space))
            } action: {
                frame($0)
            }
        }
    }
#endif
