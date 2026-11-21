// The check that names the state of #99 (`FieldHeights`): it finds a field laid out at a height other than AppKit's
// own for it, in either direction, and finds nothing in SwiftUI's fields laid out normally. Unlike the matrix, these
// run in every `swift test`, but not in the matrix's render (WESTRON_SNAPSHOTS), where their windows would be laid out
// between its draws.
#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing
    import WestronUI

    @Suite("The check of #99: text fields laid out at AppKit's own heights", .enabled(if: snapshotOutput == nil))
    @MainActor
    struct FieldHeightsTests {

        /// A view tree as the probe on the runner saw it: one field laid out at its own height, and one, inside a
        /// container, `offset` points off it.
        func tree(offset: CGFloat) -> (root: NSView, forced: NSTextField) {
            let root = NSView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
            let container = NSView(frame: CGRect(x: 0, y: 100, width: 400, height: 100))
            root.addSubview(container)
            let normal = NSTextField(string: "Groceries")
            normal.frame = CGRect(x: 20, y: 20, width: 164, height: normal.intrinsicContentSize.height)
            root.addSubview(normal)
            let forced = NSTextField(string: "")
            forced.placeholderString = "Untitled"
            forced.frame = CGRect(x: 96, y: 30, width: 164, height: forced.intrinsicContentSize.height + offset)
            container.addSubview(forced)
            return (root, forced)
        }

        @Test("a field laid out a point off AppKit's height is named as the state of #99", arguments: [1, -1])
        func forced(offset: CGFloat) throws {
            let (root, forced) = tree(offset: offset)
            let report = FieldHeights.check(root)
            #expect(report.checked == 2)
            #expect(report.findings.count == 1)
            let issue = report.issue(file: "text-field.size-m_lines-single.dark-hc.png", picture: 171, seconds: 12.5)
            #expect(issue.hasPrefix("text-field.size-m_lines-single.dark-hc.png: the render was in the state of #99: "))
            #expect(issue.contains("1 of 2 AppKit text fields laid out at a height other than AppKit's own"))
            #expect(issue.contains("picture 171 of the run, 12.5 s into it"))
            let height = forced.intrinsicContentSize.height
            let described = try #require(report.findings.first)
            #expect(issue.hasSuffix(described))
            #expect(described.contains(String(format: "laid out 164.000 × %.3f at (96.000, 130.000)", height + offset)))
            #expect(described.contains(String(format: "× %.3f, cell.cellSize ", height)))
            #expect(described.contains("font \(forced.font?.fontName ?? "?") "))
            #expect(described.contains("ascender"))
            #expect(described.contains("text \"\", placeholder \"Untitled\""))
        }

        @Test(
            "a wrapping field is measured at its width: laid out at its lines' height it passes, a point off it fails",
            arguments: [0, 1])
        func wrapping(offset: CGFloat) {
            let root = NSView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
            let field = NSTextField(wrappingLabelWithString: "Milk, bread and a long list of other things to buy")
            field.frame = CGRect(x: 20, y: 20, width: 120, height: 100)
            let height = FieldHeights.lines(of: field).height
            // Two lines or more at this width; `intrinsicContentSize` and `cellSize` give one.
            #expect(height > field.cell!.cellSize.height)
            field.frame.size.height = height + offset
            root.addSubview(field)
            #expect(FieldHeights.check(root).findings.count == (offset == 0 ? 0 : 1))
        }

        @Test("half a pixel off is SwiftUI's rounding, not a finding")
        func rounding() {
            let (root, _) = tree(offset: 0.25)
            #expect(FieldHeights.check(root).findings.isEmpty)
        }

        @Test("SwiftUI's fields laid out normally: one-line, empty with a prompt, secure, multi-line; no finding")
        func normal() async throws {
            let view = VStack {
                TextField("Title", text: .constant("Groceries"))
                TextField("Title", text: .constant(""), prompt: Text("Untitled"))
                    .textFieldStyle(.framed, size: .m)
                SecureField("Password", text: .constant("secret"), prompt: Text("Required"))
                    .textFieldStyle(.framed, size: .s)
                TextField(
                    "Notes", text: .constant("Milk, bread and a long list of other things to buy on the way home"),
                    axis: .vertical
                )
                .textFieldStyle(.inline, size: .l)
                .lineLimit(1...4)
            }
            .frame(width: 240)
            let window = try SnapshotRenderer.show(view, dark: false)
            defer { SnapshotRenderer.hide(window) }
            await SnapshotRenderer.pause(0.05)
            let hosting = try #require(window.contentView)
            hosting.layoutSubtreeIfNeeded()
            let report = FieldHeights.check(hosting)
            #expect(report.checked == 4)
            #expect(report.findings == [])
        }
    }
#endif
