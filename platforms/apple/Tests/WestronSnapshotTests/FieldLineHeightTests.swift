// The regression test of #99 (`MeasuredFonts`): it forces the state in which SwiftUI lays out a text field at the line
// height of another font, and requires every field to keep the height AppKit measures for it.
//
// Each attempt lays out a framed field in body.regular (the system font at 13 pt, a line of 16) and an inline one in
// heading.small (Onest SemiBold at 13 pt, a line of 17), with westron's style, one at a time in one window; then
// resolves new fonts in SwiftUI's font cache until it lets the Onest field's font go, which frees it unless something
// keeps it; then lays out the framed field again, which makes its font anew, often at an address a font measured a
// moment ago held. With nothing keeping the fonts, the framed field comes out 17 high in some of the attempts, in every
// run so far: locally (macOS 26.7) and on 4 of 4 runner VMs in run 44941092448, 30 to 311 fields off their line in
// 2000 attempts. With `MeasuredFonts` keeping them, in none.
//
// With the fonts kept, no font is ever freed, so a pass cannot tell "the fix holds" from "the churn no longer makes
// SwiftUI's cache let a font go": the font is freed in 0 attempts either way. What the fixed side does check: that the
// font SwiftUI measures each field's line with (the one `MeasuredFontObserver` sees) is one `MeasuredFonts` keeps, so
// it fails if SwiftUI stops measuring through `-[NSLayoutManager defaultLineHeightForFont:]`. That the forcing still
// forces only the run without the fix shows; run it by hand after an update of Xcode or macOS, and it must fail with
// fields off their line:
//
//     WESTRON_FONT_CHURN_UNFIXED=1 WESTRON_SNAPSHOTS=.build/font-churn swift test --filter fieldsKeepTheirLine
//
// It runs in every macOS render's process (WESTRON_SNAPSHOTS: `--component` renders and the workflow Snapshot
// references too), before or after the matrix in the same serialized suite, where the fonts are kept from before any
// field is laid out: in a process whose fields were laid out before `MeasuredFonts.keep()`, a height measured then may
// still be in the cache. It costs about 8 s of a local render, and 21.3 to 34.8 s of a render of about 190 to 230 s on
// the runner (run 44941092448); the fonts it makes, kept, are a part of the render's footprint (`MeasuredFonts`).

#if os(macOS)
    import AppKit
    import ObjectiveC
    import SwiftUI
    import Testing
    import WestronUI

    @testable import WestronCatalog

    extension SnapshotMatrixRenderTests {
        @Test("a text field keeps the height of its own line while fonts come and go (#99)")
        func fieldsKeepTheirLineThroughFontChurn() throws {
            // The churn resolves fonts with `Font.resolve(in:)`, from macOS 26; the render runs on 26 and later.
            guard #available(macOS 26, *) else { return }
            let unfixed = ProcessInfo.processInfo.environment["WESTRON_FONT_CHURN_UNFIXED"] == "1"
            if !unfixed { MeasuredFonts.keep() }
            let attempts = 2000
            let churn = FontChurn()
            // One window for every attempt: the fields come and go in it, and the churn draws nothing.
            let windowsBefore = NSApplication.shared.windows.count
            let window = SnapshotRenderer.FixedScaleWindow(
                contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 200), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            let hosting = NSHostingView(rootView: ChurnedField(kind: nil))
            hosting.sizingOptions = []
            hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
            window.contentView = hosting
            defer {
                window.contentView = nil
                window.close()
            }
            let observer = MeasuredFontObserver()
            observer.start()
            defer { observer.stop() }

            /// Lays out one field and returns how it disagrees with AppKit, if it does, the font SwiftUI measured, not
            /// retained, and, with the fonts kept, why that font is not one `MeasuredFonts` keeps, if it is not.
            func layOut(_ kind: ChurnedField.Kind) -> (wrong: String?, font: WeakFont, notKept: String?) {
                var result: (String?, WeakFont, String?) = (nil, WeakFont(nil), nil)
                autoreleasepool {
                    observer.measured = nil
                    hosting.rootView = ChurnedField(kind: kind)
                    hosting.layoutSubtreeIfNeeded()
                    let fields = SnapshotFieldList.fields(in: hosting)
                    let wrong = fields.compactMap { field -> String? in
                        let own = field.cell?.cellSize.height ?? 0
                        guard field.frame.height != own else { return nil }
                        return "\(field.font?.fontName ?? "?") field laid out \(field.frame.height) pt high, its line "
                            + "\(own)"
                    }
                    var notKept: String?
                    if !unfixed {
                        if let measured = observer.measured {
                            if !MeasuredFonts.keeps(measured) {
                                notKept = "\(measured.fontName) \(measured.pointSize) measured, not kept"
                            }
                        } else {
                            notKept = "no font seen measured"
                        }
                    }
                    result = (wrong.isEmpty ? nil : wrong.joined(separator: "; "), WeakFont(observer.measured), notKept)
                    observer.measured = nil
                    hosting.rootView = ChurnedField(kind: nil)
                    hosting.layoutSubtreeIfNeeded()
                }
                return result
            }

            var wrong: [String] = []
            var notKept: [String] = []
            var freed = 0
            let began = Date()
            for attempt in 1...attempts {
                let first = layOut(.framed)
                if let why = first.wrong { wrong.append("attempt \(attempt), first: \(why)") }
                if let why = first.notKept { notKept.append("attempt \(attempt), framed: \(why)") }
                let (why, onest, onestNotKept) = layOut(.inline)
                if let why { wrong.append("attempt \(attempt), inline: \(why)") }
                if let why = onestNotKept { notKept.append("attempt \(attempt), inline: \(why)") }
                var steps = 0
                // New fonts until SwiftUI's cache lets the inline field's font go, or 40 of them.
                while onest.font != nil, steps < 40 {
                    steps += 1
                    churn.next()
                }
                if onest.font == nil { freed += 1 }
                let again = layOut(.framed)
                if let why = again.wrong { wrong.append("attempt \(attempt), again: \(why)") }
                if let why = again.notKept { notKept.append("attempt \(attempt), again: \(why)") }
            }
            let windowsAfter = NSApplication.shared.windows.count
            print(
                String(
                    format: "snapshot: font churn (#99): %d attempts in %.1f s, the inline field's font freed in %d, "
                        + "%d fields off their line, %d fonts kept, windows %d before and %d after",
                    attempts, Date().timeIntervalSince(began), freed, wrong.count, MeasuredFonts.count, windowsBefore,
                    windowsAfter))
            #expect(windowsAfter <= windowsBefore + 1, "the test leaves windows behind")
            // The fix holds only while SwiftUI measures each field's line through the selector `MeasuredFonts` swaps.
            #expect(
                notKept.isEmpty,
                """
                \(notKept.count) fields' fonts not kept by MeasuredFonts, so SwiftUI measures otherwise now: \
                \(notKept.prefix(5).joined(separator: " | "))
                """)
            #expect(wrong.isEmpty, "\(wrong.count) fields off their line: \(wrong.prefix(5).joined(separator: " | "))")
        }
    }

    /// A field of the matrix, framed in body.regular or inline in heading.small, or nothing.
    struct ChurnedField: View {
        enum Kind { case framed, inline }
        let kind: Kind?

        var body: some View {
            switch kind {
            case .framed:
                TextFieldSample(variant: .framed, size: .m, filled: true)
            case .inline:
                TextField("Title", text: .constant("Buy groceries"), prompt: Text("Untitled"))
                    .textFieldStyle(.inline)
                    .accessibilityLabel("Title")
                    .textRole(.heading.small)
                    .foregroundStyle(.text.primary)
            case nil:
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }

    /// New fonts resolved in SwiftUI's font cache, one at a time, each a size no other takes.
    @available(macOS 26, *)
    @MainActor
    final class FontChurn {
        private var size = 0
        private let context = EnvironmentValues().fontResolutionContext

        func next() {
            size += 1
            autoreleasepool {
                _ = Font.custom("Helvetica", size: 20 + CGFloat(size) / 100).resolve(in: context).ctFont
            }
        }
    }

    /// A font, not retained.
    final class WeakFont {
        weak var font: NSFont?
        init(_ font: NSFont?) { self.font = font }
    }

    /// The fields in a view tree.
    enum SnapshotFieldList {
        static func fields(in view: NSView) -> [NSTextField] {
            ((view as? NSTextField).map { [$0] } ?? []) + view.subviews.flatMap { fields(in: $0) }
        }
    }

    /// Sees the font SwiftUI measures a field's line with: it asks that font for its leading right after it looks the
    /// line height up. Test only: it swaps `-[NSFont leading]` on the font's class and puts it back.
    @MainActor
    final class MeasuredFontObserver {
        typealias Leading = @convention(c) (NSFont, Selector) -> CGFloat
        /// The last font asked for its leading on the main thread while observing; not retained.
        weak var measured: NSFont?
        private var original: IMP?
        private var method: Method?

        func start() {
            guard let fontClass = object_getClass(NSFont.systemFont(ofSize: 13)),
                let method = class_getInstanceMethod(fontClass, #selector(getter: NSFont.leading))
            else { return }
            let original = method_getImplementation(method)
            let leading = unsafeBitCast(original, to: Leading.self)
            let selector = #selector(getter: NSFont.leading)
            let observing: @convention(block) (NSFont) -> CGFloat = { [weak self] font in
                if Thread.isMainThread { MainActor.assumeIsolated { self?.measured = font } }
                return leading(font, selector)
            }
            method_setImplementation(method, imp_implementationWithBlock(observing))
            self.original = original
            self.method = method
        }

        func stop() {
            if let method, let original { method_setImplementation(method, original) }
            method = nil
            original = nil
        }
    }
#endif
