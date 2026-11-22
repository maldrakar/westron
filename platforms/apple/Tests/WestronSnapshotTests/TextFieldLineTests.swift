// The test of #113: westron's TextField style holds a field to its own lines on macOS while SwiftUI's cache of line
// heights hands it another font's (`TextFieldLine` in WestronUI), as in a product, without the fix of the snapshot
// render (#99, `MeasuredFonts`).
//
// The forcing is #99's (`FieldLineHeightTests`): lay a field out, lay out a field in another font, resolve new fonts
// until SwiftUI's font cache lets that font go, and lay the first field out again; its font, made anew, is often
// allocated where the freed one was and takes its line height. Here the first field is each of the contract's variants
// and sizes on one line, a framed SecureField, and a framed and an inline field of several lines holding one line under
// `lineLimit(1...4)` (where the limit binds; with two lines or no limit SwiftUI does not hold a multi-line field); the
// inline ones in the text role of their context, body.regular, heading.small (Onest) and footnote.regular. The other
// field is in Onest (a line of 17 pt), in footnote.regular (13) or in body.regular (16), so that fields are held both
// taller and shorter than their lines. Every field must come out at its own lines, the height AppKit gives for its cell
// at its width, and its westron field at the size it has in a fresh process.
//
// It runs in a process of its own (an exit test), because the render's fix, which keeps every measured font alive and
// so removes the state, is installed in the test process by any test that shows a picture (`SnapshotRenderer.show`),
// and stays for the process. Without the style's fix the same test must fail, and has in every run so far:
//
//     WESTRON_FIELD_LINE_UNFIXED=1 swift test --filter TextFieldLineTests
//
// With the fix, a pass could also mean that the forcing no longer forces: so it also requires that the style found
// fields at another font's line and made their fonts anew (`TextFieldLineWorkaround.remade`). It does not run in the
// macOS render (WESTRON_SNAPSHOTS), whose process keeps every font and never enters the state.

#if os(macOS)
    import AppKit
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
            let report = String(decoding: result.standardOutputContent, as: UTF8.self)
                .split(separator: "\n").filter { $0.hasPrefix(LineChurn.marker) }
                .map { String($0.dropFirst(LineChurn.marker.count)) }
            print(report.dropFirst().joined(separator: "\n"))
            #expect(report.first == LineChurn.passed, "\(report.dropFirst().joined(separator: " | "))")
        }

        @Test("a field laid out at its own lines is laid out as without the fix, in every text role")
        func unchangedAtItsOwnLines() throws {
            guard #available(macOS 26, *) else { return }
            let window = SnapshotRenderer.FixedScaleWindow(
                contentRect: CGRect(x: -20000, y: -20000, width: 400, height: 300), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            defer {
                window.contentView = nil
                window.close()
            }
            let enabled = TextFieldLineWorkaround.isEnabled
            defer { TextFieldLineWorkaround.isEnabled = enabled }
            /// The window's frames of the field's westron view and of every system field in it.
            func layOut(_ view: some View, fixed: Bool) -> [CGRect] {
                TextFieldLineWorkaround.isEnabled = fixed
                let hosting = NSHostingView(rootView: view.fixedSize())
                hosting.sizingOptions = []
                hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
                window.contentView = hosting
                hosting.layoutSubtreeIfNeeded()
                return [CGRect(origin: .zero, size: hosting.fittingSize)]
                    + SnapshotFieldList.fields(in: hosting).map { $0.convert($0.bounds, to: nil) }
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
            for (name, view) in views {
                let without = layOut(view, fixed: false)
                let with = layOut(view, fixed: true)
                #expect(with == without, "\(name): \(with) with the fix, \(without) without")
            }
        }
    }

    /// The fields the test lays out: the contract's variants and sizes, filled, and in a context's text role.
    enum LineField: CaseIterable {
        case framedS, framedM, framedL, framedEmpty, framedSecure, framedSeveral
        case inlineBody, inlineHeading, inlineFootnote, inlineSeveral

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
            }
        }

        /// A framed field: on one line, or on several holding one line under a limit that binds.
        @MainActor static func framed(_ size: TextFieldSize, axis: Axis) -> some View {
            TextField("Name", text: .constant("Groceries"), axis: axis)
                .textFieldStyle(.framed, size: size)
                .lineLimit(1...4)
        }

        /// An inline field in the text role of its context: on one line, or on several holding one line.
        @MainActor static func inline(_ role: Westron.TextRole, axis: Axis) -> some View {
            TextField("Title", text: .constant("Buy groceries"), axis: axis)
                .textFieldStyle(.inline)
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
        static let attempts = 1500

        /// The report: `passed` first if every field kept its lines and the forcing forced, then what was seen.
        static func run() -> [String] {
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
                    result = (wrong, WeakFont(observer.measured))
                    observer.measured = nil
                    hosting.rootView = Sized(field: nil, size: size)
                    hosting.layoutSubtreeIfNeeded()
                }
                return result
            }

            // Each field's size before any font is freed, which the forcing must not change.
            var sizes: [LineField: CGSize] = [:]
            var wrong: [String] = []
            for field in LineField.allCases {
                wrong += layOut(field).wrong
                sizes[field] = size.size
            }
            let others: [LineField] = [.inlineHeading, .inlineFootnote, .framedM]
            var freed = 0
            let began = Date()
            for attempt in 0..<attempts {
                let field = LineField.allCases[attempt % LineField.allCases.count]
                let other = others[(attempt / LineField.allCases.count) % others.count]
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
            let remade = TextFieldLineWorkaround.remade
            let forced = unfixed || remade > 0
            let summary = String(
                format: "text field lines (#113): %d attempts in %.1f s, %@, the other field's font freed in %d, "
                    + "%d fields off their lines, fonts made anew by the style %d times",
                attempts, Date().timeIntervalSince(began), unfixed ? "without the fix" : "with the fix", freed,
                wrong.count, remade)
            var report = [wrong.isEmpty && forced ? passed : "failed", summary]
            if !forced {
                report.append("the style never found a field at another font's line: the forcing did not force")
            }
            report += wrong.prefix(10)
            return report
        }
    }

    /// The westron field's laid-out size, as it reports it.
    @MainActor
    final class LaidOutSize {
        var size: CGSize?
    }

    /// A `LineField`, reporting its size, or nothing.
    struct Sized: View {
        let field: LineField?
        let size: LaidOutSize

        var body: some View {
            if let field {
                field.view
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
