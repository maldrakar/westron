// PROBE ONLY (#99, second probe): lays out the text-field sheets again and again for WESTRON_PROBE_LOOP seconds, as
// the matrix does (layout only), with the line-height trace from the first layout on, and dumps every picture whose
// fields are laid out otherwise than AppKit measures them or than in round 1: the fields, SwiftUI's limits on them, and
// which font objects were looked up and what was last measured at their addresses.
#if os(macOS)
    import AppKit
    import Foundation
    import SwiftUI
    import Testing

    @testable import WestronCatalog

    let probeLoopSeconds: Double? = ProcessInfo.processInfo.environment["WESTRON_PROBE_LOOP"].flatMap(Double.init)

    @Suite("Probe loop (#99)", .enabled(if: probeLoopSeconds != nil), .serialized)
    @MainActor
    struct ProbeLoopTests {
        static func fields(_ view: NSView) -> [NSTextField] {
            ((view as? NSTextField).map { [$0] } ?? []) + view.subviews.flatMap { fields($0) }
        }

        @Test("text-field sheets, again and again")
        func loop() async throws {
            let seconds = try #require(probeLoopSeconds)
            let start = Date()
            let uptime = ProcessInfo.processInfo.systemUptime
            if ProcessInfo.processInfo.environment["WESTRON_PROBE_TRACE"] != "0" { LineHeightTrace.install() }
            SnapshotRenderer.pinLanguage()
            print(
                "probe: start uptime \(uptime), keep \(ProcessInfo.processInfo.environment["WESTRON_PROBE_NO_KEEP"] != "1")"
            )
            let matrix = ComponentMatrix.textField
            let groups = [matrix] + matrix.supplements
            var baseline: [String: [CGFloat]] = [:]
            var round = 0
            var pictures = 0
            var deviations = 0
            var dumps = 0
            let deadline = start.addingTimeInterval(seconds)
            while Date() < deadline {
                round += 1
                for capture in ComponentMatrix.Capture.all {
                    for group in groups {
                        for sheet in group.sheets {
                            for picture in group.pictures(of: sheet, at: capture.textSize, columns: sheet.columns.count)
                            {
                                let key = group.key(of: picture)
                                let id = "\(key).\(capture.name)"
                                await SnapshotRenderer.pause(0)
                                LineHeightTrace.mark()
                                let probe = MatrixSheetProbe()
                                let window = try autoreleasepool {
                                    try SnapshotRenderer.show(
                                        try SnapshotRenderer.view(key: key, capture: capture, probe: probe),
                                        dark: capture.theme.isDark)
                                }
                                await SnapshotRenderer.pause(SnapshotRenderer.settle(attempt: 0))
                                let root = window.contentView!
                                root.layoutSubtreeIfNeeded()
                                let found = Self.fields(root)
                                let heights = found.map { $0.frame.height }
                                pictures += 1
                                // A field on one line is laid out at its cell's height; one of several, wrapping, is
                                // compared with round 1 only.
                                let offLine = found.filter { field in
                                    !(field.cell?.wraps ?? false) && field.frame.height != field.cell?.cellSize.height
                                }
                                let changed = baseline[id].map { $0 != heights } ?? false
                                if baseline[id] == nil { baseline[id] = heights }
                                let text = heights.map { String(format: "%g", $0) }.joined(separator: ",")
                                let dumpAnyway =
                                    pictures <= 1
                                    && ProcessInfo.processInfo.environment["WESTRON_PROBE_DUMP_FIRST"] == "1"
                                if !offLine.isEmpty || changed || dumpAnyway {
                                    deviations += 1
                                    print(
                                        String(
                                            format:
                                                "probe-dev: t=%.1f uptime=%.1f round %d %@ heights [%@] off-line %d changed %@",
                                            Date().timeIntervalSince(start), ProcessInfo.processInfo.systemUptime,
                                            round,
                                            id, text, offLine.count, changed ? "yes" : "no"))
                                    if dumps < 16 {
                                        dumps += 1
                                        for field in found {
                                            let frame = field.convert(field.bounds, to: nil)
                                            print(
                                                "probe-dump:   \(type(of: field)) \(frame) cell \(field.cell?.cellSize ?? .zero) "
                                                    + "font \(field.font?.fontName ?? "nil") \(field.font?.pointSize ?? 0) "
                                                    + "object \(field.font.map { Unmanaged.passUnretained($0).toOpaque() }.map(String.init(describing:)) ?? "nil") "
                                                    + "wraps \(field.cell?.wraps ?? false) \(LineHeightTrace.limits(field))"
                                            )
                                        }
                                        for line in LineHeightTrace.report() { print("probe-dump:   " + line) }
                                    }
                                } else if round == 1 || pictures % 200 == 0 {
                                    print(
                                        String(
                                            format: "probe-pic: t=%.1f round %d %@ heights [%@]",
                                            Date().timeIntervalSince(start), round, id, text))
                                }
                                autoreleasepool { SnapshotRenderer.hide(window) }
                            }
                        }
                    }
                }
            }
            print(
                "probe: end t=\(Date().timeIntervalSince(start)) rounds \(round) pictures \(pictures) deviations "
                    + "\(deviations) fonts kept \(MeasuredFonts.count) measured addresses \(LineHeightTrace.misses.count)"
            )
        }
    }
#endif
