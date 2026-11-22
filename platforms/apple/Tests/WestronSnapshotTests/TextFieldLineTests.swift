// The tests of #113: westron's TextField style holds a field to its own lines on macOS while SwiftUI's cache of line
// heights hands it another font's (`TextFieldLine` in WestronUI), as in a product, without the fix of the snapshot
// render (#99, `MeasuredFonts`).
//
// The forcing is #99's (`FieldLineHeightTests`): lay a field out, lay out a field in another font, resolve new fonts
// until SwiftUI's font cache lets that font go, and lay the first field out again; its font, made anew, is often
// allocated where the freed one was and takes its line height. The other field is in Onest (a line of 17 pt), in
// footnote.regular (13) or in body.regular (16), so that fields are held both taller and shorter than their lines.
// - `fieldsKeepTheirLines`: the first field, made anew at each attempt, is each of the contract's variants and sizes on
//   one line, a framed SecureField, and a framed and an inline field of several lines holding one line under
//   `lineLimit(1...4)` (where the limit binds; with two lines or no limit SwiftUI does not hold a multi-line field); the
//   inline ones in the text role of their context, body.regular, heading.small (Onest) and footnote.regular;
// - `aLongLivedFieldKeepsItsLines`: a framed field of one line and one of several stay on screen, as a product's do,
//   their text and width changing at each attempt, and the product's own fields come and go in another window: the
//   state comes back to the same fields again and again; at 2x, and at 1x left to right and right to left
//   (`…At1x`, `…At1xRightToLeft`), where the frames of fields the style held must keep every pixel too;
// - `anEditedFieldKeepsItsEditing`: the same fields, each in turn being edited in a key window, with text selected and
//   then in the middle of an input method's composition, only the width changing: the field editor, its text, its
//   selection and its marked text must stay, each field's own font must have been made anew while it was edited, and
//   SwiftUI must log no runtime warning (the child reads its own log, where a canary shows the warnings are seen);
// - `unchangedAtItsOwnLines`: every text role's and every size's field, laid out with the fix and without it, in a
//   process that keeps every measured font, where the state cannot arise: the same size and frames;
// - with a glyph at the field's end (#115), where the hold widens the field: `fieldsWithAGlyphKeepTheirLines` over
//   framed fields at s and m, on one line and on several, a SecureField and inline fields, and
//   `aLongLivedFieldWithAGlyphKeepsItsLines…` at 2x, and at 1x left to right and right to left; besides their lines
//   and frames, each glyph and the field beside it must keep their place, which they keep only if the field's first
//   baseline reaches the glyph row through the hold's frame (`RecordingGlyphs`); `anEditedFieldWithAGlyphKeepsItsEditing`
//   edits the long-lived fields with their glyphs as `anEditedFieldKeepsItsEditing` edits them without; and
//   `unchangedAtItsOwnLines` lays the same fields out too.
// Every field must come out at its own lines, the height AppKit gives for its cell at its width, and at the size it has
// before any font is freed.
//
// Each runs in a process of its own (an exit test), because the render's fix, which keeps every measured font alive and
// so removes the state, is installed in the test process by any test that shows a picture (`SnapshotRenderer.show`),
// and stays for the process. Without the style's fix the forcing tests must fail, and have in every run so far:
//
//     WESTRON_FIELD_LINE_UNFIXED=1 swift test --filter TextFieldLineTests
//
// With the fix, a pass could also mean that the forcing no longer forces: so they also require that the style found
// fields at another font's line and made their fonts anew (`TextFieldLineWorkaround.remade`). WESTRON_FIELD_LINE_ATTEMPTS
// sets how many attempts each makes (1500). They do not run in the macOS render (WESTRON_SNAPSHOTS), whose process
// keeps every font and never enters the state.

#if os(macOS)
    import AppKit
    import OSLog
    import SwiftUI
    import Testing
    @testable import WestronUI

    @testable import WestronCatalog

    @Suite("TextField keeps its own lines while fonts come and go (#113)", .enabled(if: snapshotOutput == nil))
    @MainActor
    struct TextFieldLineTests {
        @Test("in the state that hands a field another font's line height, every field keeps its own lines")
        func fieldsKeepTheirLines() async throws {
            guard #available(macOS 26, *) else { return }
            // The process exits normally whatever it found, so that its report reaches this one; a crash fails here.
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.run() }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("a field that stays on screen keeps its own lines each time the state comes back")
        func aLongLivedFieldKeepsItsLines() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.runLongLived(scale: 2) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("on a display of 1x, a field that stays on screen keeps its lines and, once held, its width")
        func aLongLivedFieldKeepsItsLinesAt1x() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.runLongLived(scale: 1) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("on a display of 1x, right to left, a field that stays on screen keeps its lines and its width")
        func aLongLivedFieldKeepsItsLinesAt1xRightToLeft() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.runLongLived(scale: 1, direction: .rightToLeft) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("in the same state, every field with a glyph at its end keeps its own lines (#115)")
        func fieldsWithAGlyphKeepTheirLines() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.run(fields: LineField.withGlyphs) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("with a glyph at its end, a field that stays on screen keeps its lines and its glyph's place (#115)")
        func aLongLivedFieldWithAGlyphKeepsItsLines() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.runLongLived(scale: 2, glyphs: true) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("on a display of 1x, with a glyph at its end, a field keeps its lines, its width and its glyph's place")
        func aLongLivedFieldWithAGlyphKeepsItsLinesAt1x() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.runLongLived(scale: 1, glyphs: true) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test(
            "on a display of 1x, right to left, with a glyph at its end, a field keeps its lines and its glyph's place")
        func aLongLivedFieldWithAGlyphKeepsItsLinesAt1xRightToLeft() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run {
                    LineChurn.runLongLived(scale: 1, direction: .rightToLeft, glyphs: true)
                }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }

        @Test("a field being edited keeps its text, its selection and its marked text while it is held to its lines")
        func anEditedFieldKeepsItsEditing() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let (report, warnings) = await MainActor.run { LineEditing.run() }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
                for warning in warnings { print(LineEditing.warningMarker + warning) }
            }
            Self.expectEditingKept(result)
        }

        @Test("with a glyph at its end, a field being edited keeps its text, its selection and its marked text (#115)")
        func anEditedFieldWithAGlyphKeepsItsEditing() async throws {
            guard #available(macOS 26, *) else { return }
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let (report, warnings) = await MainActor.run { LineEditing.run(glyphs: true) }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
                for warning in warnings { print(LineEditing.warningMarker + warning) }
            }
            Self.expectEditingKept(result)
        }

        /// That the editing child passed and logged no runtime warning of SwiftUI's but its canary's.
        @available(macOS 26, *)
        static func expectEditingKept(_ result: ExitTest.Result) {
            LineChurn.expectPassed(result)
            // SwiftUI's runtime warnings in the child's own log, where the child's canary shows they are seen.
            let warnings = String(decoding: result.standardOutputContent, as: UTF8.self).split(separator: "\n")
                .filter { $0.hasPrefix(LineEditing.warningMarker) }
            let canary = warnings.filter { $0.contains(LineEditing.canaryWarning) }
            print("runtime warnings in the child: \(warnings.count), of them the canary's \(canary.count)")
            #expect(!canary.isEmpty, "the canary's warning was not in the child's log: warnings would not be seen")
            #expect(
                warnings.count == canary.count,
                "\(warnings.filter { !$0.contains(LineEditing.canaryWarning) }.prefix(5).joined(separator: " | "))")
        }

        @Test("a field laid out at its own lines is laid out as without the fix, in every text role")
        func unchangedAtItsOwnLines() async throws {
            guard #available(macOS 26, *) else { return }
            // In a process of its own that keeps every measured font from before its first field, so that the state of
            // #113 cannot arise in it and neither side of the comparison is laid out at another font's line.
            let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                let report = await MainActor.run { LineChurn.runUnchanged() }
                print(LineChurn.marker + report.joined(separator: "\n" + LineChurn.marker))
            }
            LineChurn.expectPassed(result)
        }
    }

    /// The fields the test lays out: the contract's variants and sizes, filled, and in a context's text role; and
    /// fields with a glyph at their end (#115), which `fieldsWithAGlyphKeepTheirLines` lays out apart, so that the
    /// other fields are forced as often as before.
    enum LineField: CaseIterable {
        case framedS, framedM, framedL, framedEmpty, framedSecure, framedSeveral
        case inlineBody, inlineHeading, inlineFootnote, inlineSeveral
        case framedSGlyph, framedMGlyph, framedSeveralGlyph, framedSecureGlyph, inlineBodyGlyph, inlineSeveralGlyph

        /// The fields without a glyph, laid out as before #115.
        static let plain: [LineField] = [
            .framedS, .framedM, .framedL, .framedEmpty, .framedSecure, .framedSeveral, .inlineBody, .inlineHeading,
            .inlineFootnote, .inlineSeveral,
        ]
        /// The fields with a glyph at their end, the side where the hold widens the field (#115).
        static let withGlyphs: [LineField] = [
            .framedSGlyph, .framedMGlyph, .framedSeveralGlyph, .framedSecureGlyph, .inlineBodyGlyph,
            .inlineSeveralGlyph,
        ]

        @MainActor @ViewBuilder var view: some View {
            switch self {
            case .framedS: Self.framed(.s, axis: .horizontal)
            case .framedM: Self.framed(.m, axis: .horizontal)
            case .framedL: Self.framed(.l, axis: .horizontal)
            case .framedEmpty:
                TextField("List name", text: .constant(""), prompt: Text("Untitled")).textFieldStyle(.framed, size: .m)
            case .framedSecure:
                SecureField("Password", text: .constant("secret")).textFieldStyle(.framed, size: .m)
            case .framedSeveral: Self.framed(.m, axis: .vertical)
            case .inlineBody: Self.inline(.body.regular, axis: .horizontal)
            case .inlineHeading: Self.inline(.heading.small, axis: .horizontal)
            case .inlineFootnote: Self.inline(.footnote.regular, axis: .horizontal)
            case .inlineSeveral: Self.inline(.body.regular, axis: .vertical)
            case .framedSGlyph: Self.framed(.s, axis: .horizontal, trailingIcon: .hash)
            case .framedMGlyph: Self.framed(.m, axis: .horizontal, trailingIcon: .hash)
            case .framedSeveralGlyph: Self.framed(.m, axis: .vertical, trailingIcon: .hash)
            case .framedSecureGlyph:
                SecureField("Password", text: .constant("secret"))
                    .textFieldStyle(.framed, size: .m, trailingIcon: .hash)
            case .inlineBodyGlyph: Self.inline(.body.regular, axis: .horizontal, trailingIcon: .hash)
            case .inlineSeveralGlyph: Self.inline(.body.regular, axis: .vertical, trailingIcon: .hash)
            }
        }

        /// A framed field: on one line, or on several holding one line under a limit that binds.
        @MainActor static func framed(
            _ size: TextFieldSize, axis: Axis, trailingIcon: Westron.Icon? = nil
        ) -> some View {
            TextField("Name", text: .constant("Groceries"), axis: axis)
                .textFieldStyle(.framed, size: size, trailingIcon: trailingIcon)
                .lineLimit(1...4)
        }

        /// An inline field in the text role of its context: on one line, or on several holding one line.
        @MainActor static func inline(
            _ role: Westron.TextRole, axis: Axis, trailingIcon: Westron.Icon? = nil
        ) -> some View {
            TextField("Title", text: .constant("Buy groceries"), axis: axis)
                .textFieldStyle(.inline, trailingIcon: trailingIcon)
                .lineLimit(1...4)
                .textRole(role)
                .foregroundStyle(.text.primary)
        }
    }

    /// #99's forcing over every `LineField`, in the process it runs in.
    @available(macOS 26, *)
    @MainActor
    enum LineChurn {
        nonisolated static let passed = "passed"
        /// What starts each line of the report in the exit test's output.
        nonisolated static let marker = "text-field-line: "
        /// How many attempts a run makes: 1500, or WESTRON_FIELD_LINE_ATTEMPTS.
        static var attempts: Int {
            ProcessInfo.processInfo.environment["WESTRON_FIELD_LINE_ATTEMPTS"].flatMap { Int($0) } ?? 1500
        }

        /// Lays a view out as a product's run loop does after a change: layout, the run loop's turn, which commits what
        /// SwiftUI and the style scheduled for it, and layout again, twice.
        static func settle(_ view: NSView) {
            view.layoutSubtreeIfNeeded()
            for _ in 0..<2 {
                SnapshotRenderer.turnRunLoop(0)
                view.layoutSubtreeIfNeeded()
            }
        }

        /// Prints an exit test's report and expects it to have passed.
        nonisolated static func expectPassed(
            _ result: ExitTest.Result, sourceLocation: SourceLocation = #_sourceLocation
        ) {
            let report = String(decoding: result.standardOutputContent, as: UTF8.self)
                .split(separator: "\n").filter { $0.hasPrefix(marker) }
                .map { String($0.dropFirst(marker.count)) }
            print(report.dropFirst().joined(separator: "\n"))
            #expect(
                report.first == passed, "\(report.dropFirst().joined(separator: " | "))", sourceLocation: sourceLocation
            )
        }

        /// The report's first lines: `passed` if no field was off its lines and the forcing forced, then a summary.
        static func report(
            _ name: String, attempts: Int, since began: Date, freed: Int, wrong: [String], unfixed: Bool
        ) -> [String] {
            let remade = TextFieldLineWorkaround.remade
            let forced = unfixed || remade > 0
            let summary = String(
                format: "%@ (#113): %d attempts in %.1f s, %@, the other field's font freed in %d, %d off their "
                    + "lines, fonts made anew by the style %d times",
                name, attempts, Date().timeIntervalSince(began), unfixed ? "without the fix" : "with the fix", freed,
                wrong.count, remade)
            var report = [wrong.isEmpty && forced ? passed : "failed", summary]
            if !forced {
                report.append("the style never found a field at another font's line: the forcing did not force")
            }
            return report + wrong.prefix(10)
        }

        /// Every text role's inline field and every size's framed field, on one line and on several, laid out without
        /// the fix and with it: the westron field's size and every system field's frame in the window must be the same,
        /// and the style must make no font anew.
        static func runUnchanged() -> [String] {
            MeasuredFonts.keep()
            let window = SnapshotRenderer.FixedScaleWindow(
                contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 300), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            defer {
                window.contentView = nil
                window.close()
            }
            let size = LaidOutSize()
            func layOut(_ view: AnyView, fixed: Bool) -> [CGRect] {
                TextFieldLineWorkaround.isEnabled = fixed
                size.size = nil
                size.glyphs = [:]
                let hosting = NSHostingView(rootView: Sized(view: view, size: size))
                hosting.sizingOptions = []
                hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
                window.contentView = hosting
                hosting.layoutSubtreeIfNeeded()
                return [CGRect(origin: .zero, size: size.size ?? .zero)]
                    + SnapshotFieldList.fields(in: hosting).map { $0.convert($0.bounds, to: nil) } + size.glyphRows
            }
            var views: [(String, AnyView)] = []
            for role in Westron.TextRole.all {
                let name = "\(role.textStyle) \(role.weight) \(role.font ?? "system")"
                views.append(("inline, one line, \(name)", AnyView(LineField.inline(role, axis: .horizontal))))
                views.append(("inline, several lines, \(name)", AnyView(LineField.inline(role, axis: .vertical))))
            }
            for size in TextFieldSize.allCases {
                for axis in [Axis.horizontal, .vertical] {
                    views.append(("framed \(size) \(axis)", AnyView(LineField.framed(size, axis: axis))))
                }
            }
            // With a glyph at the end (#115), whose row must be laid out the same too.
            for field in LineField.withGlyphs {
                views.append(("\(field)", AnyView(field.view.modifier(RecordingGlyphs(size: size, key: 0)))))
            }
            var wrong: [String] = []
            for (name, view) in views {
                let without = layOut(view, fixed: false)
                let with = layOut(view, fixed: true)
                if with != without || without.first?.size.height ?? .zero <= .zero || without.count < 2 {
                    wrong.append("\(name): \(with) with the fix, \(without) without")
                }
            }
            let remade = TextFieldLineWorkaround.remade
            if remade > 0 { wrong.append("the style made fonts anew \(remade) times") }
            let summary =
                "unchanged at their own lines (#113): \(views.count) fields, \(wrong.count) laid out otherwise"
            return [wrong.isEmpty ? passed : "failed", summary] + wrong.prefix(10)
        }

        /// The forcing on one framed field that stays on screen, as a product's does: its text and width change at
        /// each attempt, and between attempts the product lays out fields of its own, not westron's, in Onest, in
        /// footnote.regular and in body.regular in another window, whose fonts SwiftUI's cache then lets go. Every
        /// attempt must find the field at its own line and its westron field at its size in a fresh process. With
        /// `glyphs`, each field has a glyph at its end, which must keep its place too (#115).
        static func runLongLived(
            scale: CGFloat, direction: LayoutDirection = .leftToRight, glyphs: Bool = false
        ) -> [String] {
            ScaledWindow.scale = scale
            let unfixed = ProcessInfo.processInfo.environment["WESTRON_FIELD_LINE_UNFIXED"] == "1"
            TextFieldLineWorkaround.isEnabled = !unfixed
            let churn = FontChurn()
            let model = LongLivedModel()
            let size = LaidOutSize()
            func window(_ view: some View) -> (NSWindow, NSHostingView<AnyView>) {
                let window = ScaledWindow(
                    contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 200), styleMask: [.borderless],
                    backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                let hosting = NSHostingView(rootView: AnyView(view))
                hosting.sizingOptions = []
                hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
                window.contentView = hosting
                return (window, hosting)
            }
            let (fieldWindow, field) = window(
                LongLivedField(model: model, size: size, glyphs: glyphs).environment(\.layoutDirection, direction))
            let (otherWindow, other) = window(ProductField(font: nil))
            defer {
                for window in [fieldWindow, otherWindow] {
                    window.contentView = nil
                    window.close()
                }
            }
            let observer = MeasuredFontObserver()
            observer.start()
            defer { observer.stop() }
            /// Lets the main run loop turn, as between a product's events.
            func turn() { SnapshotRenderer.turnRunLoop(0) }

            /// Lays the field out at the attempt's text and width, and returns what it laid out: its westron fields'
            /// size, every system field's frame in the window and, with glyphs, each field's glyph row.
            func layOut(_ attempt: Int) -> [CGRect] {
                autoreleasepool {
                    model.text = "Groceries \(attempt)"
                    model.note = "Note \(attempt)"
                    model.width = attempt.isMultiple(of: 2) ? 240 : 239
                    LineChurn.settle(field)
                }
                return [CGRect(origin: .zero, size: size.size ?? .zero)]
                    + SnapshotFieldList.fields(in: field).map { $0.convert($0.bounds, to: nil) } + size.glyphRows
            }

            // What the field lays out at each width before any font is freed, which the forcing must not change.
            let expected = [layOut(0), layOut(1)]
            let fonts: [Font] = [Font(.heading.small), Font(.footnote.regular), Font(.body.regular)]
            var wrong: [String] = []
            // Two fields, each its glyph row of the glyph and the field: 4 frames.
            if glyphs, size.glyphRows.count != 4 { wrong.append("glyph rows: \(size.glyphRows)") }
            var freed = 0
            let began = Date()
            for attempt in 0..<attempts {
                var font = WeakFont(nil)
                autoreleasepool {
                    observer.measured = nil
                    other.rootView = AnyView(ProductField(font: fonts[attempt % fonts.count]))
                    other.layoutSubtreeIfNeeded()
                    font = WeakFont(observer.measured)
                    other.rootView = AnyView(ProductField(font: nil))
                    other.layoutSubtreeIfNeeded()
                }
                var steps = 0
                // New fonts until SwiftUI's cache lets the product field's font go, or 40 of them.
                while font.font != nil, steps < 40 {
                    steps += 1
                    churn.next()
                }
                if font.font == nil { freed += 1 }
                let laidOut = layOut(attempt)
                for system in SnapshotFieldList.fields(in: field) {
                    let own = FieldHeights.lines(of: system).height
                    if abs(system.frame.height - own) > FieldHeights.tolerance {
                        wrong.append(
                            "attempt \(attempt): field laid out \(system.frame.height) pt high, its lines \(own)")
                    }
                }
                if laidOut != expected[attempt % 2] {
                    wrong.append("attempt \(attempt): laid out \(laidOut), before \(expected[attempt % 2])")
                }
            }
            return report(
                "a long-lived text field's line\(glyphs ? " with a glyph at its end" : "") at \(Int(scale))x, \(direction == .rightToLeft ? "right to left" : "left to right")",
                attempts: attempts, since: began, freed: freed, wrong: wrong,
                unfixed: unfixed)
        }

        /// The report: `passed` first if every field kept its lines and the forcing forced, then what was seen. A field
        /// with glyphs must also keep its glyph row where it was in a fresh process (#115).
        static func run(fields: [LineField] = LineField.plain) -> [String] {
            let unfixed = ProcessInfo.processInfo.environment["WESTRON_FIELD_LINE_UNFIXED"] == "1"
            TextFieldLineWorkaround.isEnabled = !unfixed
            let churn = FontChurn()
            let window = SnapshotRenderer.FixedScaleWindow(
                contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 200), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            let size = LaidOutSize()
            let hosting = NSHostingView(rootView: Sized(field: nil, size: size))
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

            /// Lays a field out, and says how it is off its lines or its size, if it is; returns the font SwiftUI
            /// measured last, not retained.
            func layOut(_ field: LineField) -> (wrong: [String], font: WeakFont) {
                var result: ([String], WeakFont) = ([], WeakFont(nil))
                autoreleasepool {
                    observer.measured = nil
                    size.size = nil
                    size.glyphs = [:]
                    hosting.rootView = Sized(field: field, size: size)
                    hosting.layoutSubtreeIfNeeded()
                    var wrong = SnapshotFieldList.fields(in: hosting).compactMap { system -> String? in
                        let own = FieldHeights.lines(of: system).height
                        guard abs(system.frame.height - own) > FieldHeights.tolerance else { return nil }
                        return "\(field): \(system.font?.fontName ?? "?") field laid out \(system.frame.height) pt "
                            + "high, its lines \(own)"
                    }
                    if let expected = sizes[field], let laidOut = size.size, laidOut != expected {
                        wrong.append("\(field): laid out \(laidOut), in a fresh process \(expected)")
                    }
                    if let expected = rows[field], size.glyphRows != expected {
                        wrong.append("\(field): glyph row \(size.glyphRows), in a fresh process \(expected)")
                    }
                    result = (wrong, WeakFont(observer.measured))
                    observer.measured = nil
                    hosting.rootView = Sized(field: nil, size: size)
                    hosting.layoutSubtreeIfNeeded()
                }
                return result
            }

            // Each field's size, and glyph row, before any font is freed, which the forcing must not change.
            var sizes: [LineField: CGSize] = [:]
            var rows: [LineField: [CGRect]] = [:]
            var wrong: [String] = []
            for field in fields {
                wrong += layOut(field).wrong
                sizes[field] = size.size
                rows[field] = size.glyphRows
                if LineField.withGlyphs.contains(field), size.glyphRows.count != 2 {
                    wrong.append("\(field): glyph row \(size.glyphRows)")
                }
            }
            let others: [LineField] = [.inlineHeading, .inlineFootnote, .framedM]
            var freed = 0
            let began = Date()
            for attempt in 0..<attempts {
                let field = fields[attempt % fields.count]
                let other = others[(attempt / fields.count) % others.count]
                wrong += layOut(field).wrong.map { "attempt \(attempt), first: \($0)" }
                let (otherWrong, font) = layOut(other)
                wrong += otherWrong.map { "attempt \(attempt), other: \($0)" }
                var steps = 0
                // New fonts until SwiftUI's cache lets the other field's font go, or 40 of them.
                while font.font != nil, steps < 40 {
                    steps += 1
                    churn.next()
                }
                if font.font == nil { freed += 1 }
                wrong += layOut(field).wrong.map { "attempt \(attempt), again: \($0)" }
            }
            let name = fields == LineField.plain ? "text field lines" : "text field lines with a glyph at their end"
            return report(name, attempts: attempts, since: began, freed: freed, wrong: wrong, unfixed: unfixed)
        }
    }

    /// What the long-lived fields show: their texts and their width.
    @Observable @MainActor
    final class LongLivedModel {
        var text = "Groceries"
        var note = "Groceries"
        var width: CGFloat = 240
    }

    /// Framed fields that stay on screen, one on a single line and one of several lines holding one, reporting their
    /// size; with `glyphs`, each with a glyph at its end, reporting where it drew it (#115).
    struct LongLivedField: View {
        let model: LongLivedModel
        let size: LaidOutSize
        var glyphs = false

        var body: some View {
            VStack(spacing: .zero) {
                if glyphs {
                    TextField("Name", text: Binding(get: { model.text }, set: { model.text = $0 }))
                        .textFieldStyle(.framed, size: .m, trailingIcon: .hash)
                        .modifier(RecordingGlyphs(size: size, key: 0))
                    TextField("Note", text: Binding(get: { model.note }, set: { model.note = $0 }), axis: .vertical)
                        .textFieldStyle(.framed, size: .m, trailingIcon: .hash)
                        .lineLimit(1...4)
                        .modifier(RecordingGlyphs(size: size, key: 1))
                } else {
                    TextField("Name", text: Binding(get: { model.text }, set: { model.text = $0 }))
                        .textFieldStyle(.framed, size: .m)
                    TextField("Note", text: Binding(get: { model.note }, set: { model.note = $0 }), axis: .vertical)
                        .textFieldStyle(.framed, size: .m)
                        .lineLimit(1...4)
                }
            }
            .frame(width: model.width)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                size.size = $0
            }
        }
    }

    /// A product's own field, in the system's plain style, in a font; or nothing.
    struct ProductField: View {
        let font: Font?

        var body: some View {
            if let font {
                TextField("Title", text: .constant("Buy groceries")).textFieldStyle(.plain).font(font)
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }

    /// The westron field's laid-out size, as it reports it; and where fields with glyphs drew them.
    @MainActor
    final class LaidOutSize {
        var size: CGSize?
        /// The bounds of each field's glyphs and of the system field between them (`TextFieldGlyphAnchors`), in the
        /// hosting view's coordinates, by the field's place in its view.
        var glyphs: [Int: [CGRect]] = [:]

        /// Every field's glyph row, in the order of the fields.
        var glyphRows: [CGRect] { glyphs.keys.sorted().flatMap { glyphs[$0] ?? [] } }
    }

    /// Records where a westron field with glyphs drew them and its system field between them (#115), so that a test
    /// sees a glyph keep its place, which it keeps only if the field's first baseline reaches the glyph row through the
    /// hold's frame (`TextFieldLine`).
    struct RecordingGlyphs: ViewModifier {
        let size: LaidOutSize
        let key: Int

        func body(content: Content) -> some View {
            content.overlayPreferenceValue(TextFieldGlyphAnchors.self) { anchors in
                GeometryReader { proxy in
                    let origin = proxy.frame(in: .global).origin
                    let parts: [TextFieldGlyphAnchors.Part] = [.leading, .field, .trailing]
                    let _ =
                        (size.glyphs[key] = parts.compactMap { part in
                            anchors[part].map { proxy[$0].offsetBy(dx: origin.x, dy: origin.y) }
                        })
                    Color.clear
                }
            }
        }
    }

    /// The forcing on fields being edited in a key window: the single-line and the multi-line field of `LongLivedField`,
    /// each first with text selected, then in the middle of an input method's composition (marked text). Between
    /// attempts only the width changes, as when a window is resized, and fonts come and go in another window. At every
    /// attempt the field must still be edited in the same field editor, with the same text, selection and marked text,
    /// and at its own lines.
    @available(macOS 26, *)
    @MainActor
    enum LineEditing {
        /// What starts each runtime warning of SwiftUI's the test looks for in standard error.
        nonisolated static let warnings = [
            "Modifying state during view update", "AttributeGraph: cycle", "tried to update multiple times per frame",
            "Bound preference", "layout loop",
        ]
        /// What starts each runtime warning in the exit test's output.
        nonisolated static let warningMarker = "text-field-warning: "
        /// The warning the canary causes on purpose.
        nonisolated static let canaryWarning = "Modifying state during view update"

        /// What the field editor shows: everything editing must keep.
        struct Editing: Equatable, CustomStringConvertible {
            var editing: Bool
            var string: String
            var selected: NSRange
            var marked: NSRange?
            var text: String

            var description: String {
                "editing \(editing), \"\(string)\", selected \(selected), marked \(marked.map { "\($0)" } ?? "none"), "
                    + "bound \"\(text)\""
            }
        }

        /// The report, and every runtime warning of SwiftUI's this process logged meanwhile. `glyphs`: the fields each
        /// with a glyph at their end (#115).
        static func run(glyphs: Bool = false) -> (report: [String], warnings: [String]) {
            let unfixed = ProcessInfo.processInfo.environment["WESTRON_FIELD_LINE_UNFIXED"] == "1"
            TextFieldLineWorkaround.isEnabled = !unfixed
            // SwiftUI logs its runtime warnings; this process reads its own log at the end.
            let log = try? OSLogStore(scope: .currentProcessIdentifier)
            let logged = log?.position(date: Date())
            _ = NSApplication.shared
            let churn = FontChurn()
            let model = LongLivedModel()
            let size = LaidOutSize()
            let window = KeyWindow(
                contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 200), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            let hosting = NSHostingView(rootView: AnyView(LongLivedField(model: model, size: size, glyphs: glyphs)))
            hosting.sizingOptions = []
            hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
            window.contentView = hosting
            window.makeKeyAndOrderFront(nil)
            // A test process is not an active application, so no window of its becomes key by itself: the window says
            // it is key and is told it became key, which is what AppKit and SwiftUI read of it.
            window.becomeKey()
            let otherWindow = SnapshotRenderer.FixedScaleWindow(
                contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 200), styleMask: [.borderless],
                backing: .buffered, defer: false)
            otherWindow.isReleasedWhenClosed = false
            let other = NSHostingView(rootView: AnyView(ProductField(font: nil)))
            other.sizingOptions = []
            other.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
            otherWindow.contentView = other
            defer {
                for window in [window, otherWindow] {
                    window.contentView = nil
                    window.close()
                }
            }
            let observer = MeasuredFontObserver()
            observer.start()
            defer { observer.stop() }
            func turn() { SnapshotRenderer.turnRunLoop(0) }

            // The canary: a view that modifies its state during an update, so that the parent sees SwiftUI's runtime
            // warnings reach standard error.
            let canary = NSHostingView(rootView: Canary())
            canary.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            canary.layoutSubtreeIfNeeded()
            turn()

            hosting.layoutSubtreeIfNeeded()
            turn()
            var wrong: [String] = []
            let key = window.isKeyWindow
            if !key { wrong.append("the window is not key") }
            var offEdited = 0
            var offOther = 0
            let fonts: [Font] = [Font(.heading.small), Font(.footnote.regular), Font(.body.regular)]
            let fields = SnapshotFieldList.fields(in: hosting)
            let perPhase = max(LineChurn.attempts / 4, 1)
            var freed = 0
            var remadeEditing = 0
            // How many times each field's own font was made anew while it was the one edited.
            var remadeEdited = Array(repeating: 0, count: fields.count)
            var attempt = 0
            let began = Date()
            for (index, system) in fields.enumerated() {
                for marked in [false, true] {
                    let phase = "field \(index + 1) of \(fields.count), \(marked ? "composing" : "text selected")"
                    guard window.makeFirstResponder(system), let editor = system.currentEditor() as? NSTextView else {
                        wrong.append("\(phase): the field could not be edited")
                        continue
                    }
                    editor.selectAll(nil)
                    editor.insertText("Buy milk", replacementRange: NSRange(location: NSNotFound, length: 0))
                    if marked {
                        editor.setSelectedRange(NSRange(location: 4, length: 0))
                        editor.setMarkedText(
                            "かな", selectedRange: NSRange(location: 1, length: 0),
                            replacementRange: NSRange(location: NSNotFound, length: 0))
                    } else {
                        editor.setSelectedRange(NSRange(location: 4, length: 4))
                    }
                    hosting.layoutSubtreeIfNeeded()
                    turn()
                    func editing() -> Editing {
                        Editing(
                            editing: window.firstResponder === editor && system.currentEditor() === editor,
                            string: editor.string, selected: editor.selectedRange(),
                            marked: editor.hasMarkedText() ? editor.markedRange() : nil,
                            text: index == 0 ? model.text : model.note)
                    }
                    let expected = editing()
                    let remadeBefore = TextFieldLineWorkaround.remade
                    let axis: Axis = index == 0 ? .horizontal : .vertical
                    let remadeOwnBefore = TextFieldLineWorkaround.remadeOnAxis[axis, default: 0]
                    // The field's last phase goes on, up to four times as long, until its own font has been made anew
                    // while it was edited, which a multi-line field's is less often.
                    var phaseAttempts = 0
                    while phaseAttempts < perPhase
                        || (marked && !unfixed && phaseAttempts < 4 * perPhase
                            && remadeEdited[index] + TextFieldLineWorkaround.remadeOnAxis[axis, default: 0]
                                - remadeOwnBefore == 0)
                    {
                        phaseAttempts += 1
                        attempt += 1
                        var font = WeakFont(nil)
                        autoreleasepool {
                            observer.measured = nil
                            other.rootView = AnyView(ProductField(font: fonts[attempt % fonts.count]))
                            other.layoutSubtreeIfNeeded()
                            font = WeakFont(observer.measured)
                            other.rootView = AnyView(ProductField(font: nil))
                            other.layoutSubtreeIfNeeded()
                        }
                        var steps = 0
                        while font.font != nil, steps < 40 {
                            steps += 1
                            churn.next()
                        }
                        if font.font == nil { freed += 1 }
                        autoreleasepool {
                            model.width = attempt.isMultiple(of: 2) ? 240 : 239
                            LineChurn.settle(hosting)
                        }
                        let now = editing()
                        if now != expected {
                            wrong.append("\(phase), attempt \(attempt): \(now), before \(expected)")
                        }
                        for (other, field) in fields.enumerated() {
                            let own = FieldHeights.lines(of: field).height
                            if abs(field.frame.height - own) > FieldHeights.tolerance {
                                if other == index { offEdited += 1 } else { offOther += 1 }
                                wrong.append(
                                    "\(phase), attempt \(attempt): field \(other + 1)\(other == index ? ", edited," : "") "
                                        + "laid out \(field.frame.height) pt high, its lines \(own)")
                            }
                        }
                    }
                    remadeEditing += TextFieldLineWorkaround.remade - remadeBefore
                    remadeEdited[index] += TextFieldLineWorkaround.remadeOnAxis[axis, default: 0] - remadeOwnBefore
                    if marked { editor.unmarkText() }
                    window.makeFirstResponder(nil)
                }
            }
            var report = LineChurn.report(
                glyphs ? "text fields with a glyph being edited" : "text fields being edited", attempts: attempt,
                since: began, freed: freed, wrong: wrong,
                unfixed: unfixed)
            report.insert(
                "the window key: \(key); fonts made anew while a field was edited: \(remadeEditing), of the field edited "
                    + "\(remadeEdited.map(String.init).joined(separator: " and ")); off its lines, "
                    + "the field being edited \(offEdited) times, the other field \(offOther)", at: 2)
            if !unfixed, remadeEdited.contains(0) {
                report[0] = "failed"
                report.append("a field's own font was never made anew while it was edited: the forcing did not force")
            }
            var warnings: [String] = []
            if let log, let logged, let entries = try? log.getEntries(at: logged) {
                for case let entry as OSLogEntryLog in entries
                where Self.warnings.contains(where: { entry.composedMessage.contains($0) }) {
                    warnings.append("\(entry.subsystem) \(entry.category): \(entry.composedMessage)")
                }
            } else {
                report[0] = "failed"
                report.append("the process's log could not be read")
            }
            return (report, warnings)
        }

        /// A window that becomes key, borderless and off screen, at the render's scale.
        final class KeyWindow: NSWindow {
            override var canBecomeKey: Bool { true }
            override var canBecomeMain: Bool { true }
            override var isKeyWindow: Bool { true }
            override var backingScaleFactor: CGFloat { SnapshotRenderer.scale }
        }

        /// A view that modifies its state while SwiftUI updates it.
        struct Canary: View {
            @State private var updates = 0

            var body: some View {
                let _ = { updates += 1 }()
                Color.clear
            }
        }
    }

    /// A borderless window off screen at a scale the test sets, for every window of its process.
    final class ScaledWindow: NSWindow {
        nonisolated(unsafe) static var scale: CGFloat = 2
        override var backingScaleFactor: CGFloat { Self.scale }
    }

    /// A `LineField`, or a view, reporting its size; or nothing.
    struct Sized: View {
        let view: AnyView?
        let size: LaidOutSize

        /// A field with glyphs also reports where it drew them (`RecordingGlyphs`); the others are laid out as before.
        init(field: LineField?, size: LaidOutSize) {
            self.view = field.map { field in
                LineField.withGlyphs.contains(field)
                    ? AnyView(field.view.modifier(RecordingGlyphs(size: size, key: 0))) : AnyView(field.view)
            }
            self.size = size
        }

        init(view: AnyView, size: LaidOutSize) {
            self.view = view
            self.size = size
        }

        var body: some View {
            if let view {
                view
                    .onGeometryChange(for: CGSize.self) {
                        $0.size
                    } action: {
                        size.size = $0
                    }
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }
#endif
