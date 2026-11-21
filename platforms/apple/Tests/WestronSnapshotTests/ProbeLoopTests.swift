// PROBE ONLY (#99): draws the text-field sheets again and again for WESTRON_PROBE_LOOP seconds, the way the matrix
// does, and names every picture whose AppKit text fields are laid out otherwise than the first time.
#if os(macOS)
    import AppKit
    import Foundation
    import SwiftUI
    import Testing

    @testable import WestronCatalog

    let probeLoopSeconds: Double? = ProcessInfo.processInfo.environment["WESTRON_PROBE_LOOP"].flatMap(Double.init)

    @MainActor
    final class NotificationLog {
        static let shared = NotificationLog()
        var observers: [Any] = []
        let start = Date()

        func stamp() -> String {
            String(format: "t=%.3f uptime=%.1f", Date().timeIntervalSince(start), ProcessInfo.processInfo.systemUptime)
        }

        func begin() {
            let distributed = DistributedNotificationCenter.default()
            observers.append(
                distributed.addObserver(forName: nil, object: nil, queue: .main) { note in
                    let line =
                        "probe-note: distributed \(note.name.rawValue) object \(String(describing: note.object).prefix(80)) userInfo \(String(describing: note.userInfo).prefix(300))"
                    MainActor.assumeIsolated { print("\(NotificationLog.shared.stamp()) " + line) }
                })
            observers.append(
                NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) { note in
                    let name = note.name.rawValue
                    // The local center is busy with view and window notifications; keep what is global.
                    let keep = [
                        "Font", "font", "Locale", "Color", "Screen", "Appearance", "Theme", "Accessibility",
                        "Defaults", "Language", "Display", "Memory", "Preferred", "Contrast", "Size",
                    ]
                    guard keep.contains(where: name.contains), !name.hasPrefix("NSView"),
                        !name.hasPrefix("_NSDisplayLink"), !name.hasPrefix("NSWindowDid")
                    else { return }
                    let line = "probe-note: local \(name) object \(String(describing: note.object).prefix(80))"
                    if Thread.isMainThread {
                        MainActor.assumeIsolated { print("\(NotificationLog.shared.stamp()) " + line) }
                    } else {
                        print("t=? (thread) " + line)
                    }
                })
            observers.append(
                NSWorkspace.shared.notificationCenter.addObserver(forName: nil, object: nil, queue: .main) { note in
                    let line = "probe-note: workspace \(note.name.rawValue)"
                    MainActor.assumeIsolated {
                        print("\(NotificationLog.shared.stamp()) " + line + " now " + NotificationLog.flags())
                        print("probe-note:   universalaccess " + NotificationLog.universalAccess())
                    }
                })
            print("probe-note: at start " + NotificationLog.flags())
            print("probe-note:   universalaccess " + NotificationLog.universalAccess())
            let screens = NSScreen.screens.map { "\($0.localizedName) \($0.frame) scale \($0.backingScaleFactor)" }
            print("probe-note:   screens \(screens)")
        }

        static func flags() -> String {
            let w = NSWorkspace.shared
            return
                "IC\(w.accessibilityDisplayShouldIncreaseContrast ? 1 : 0) RT\(w.accessibilityDisplayShouldReduceTransparency ? 1 : 0) "
                + "DWC\(w.accessibilityDisplayShouldDifferentiateWithoutColor ? 1 : 0) RM\(w.accessibilityDisplayShouldReduceMotion ? 1 : 0) "
                + "INV\(w.accessibilityDisplayShouldInvertColors ? 1 : 0) app \(NSApplication.shared.effectiveAppearance.name.rawValue) "
                + "screens \(NSScreen.screens.count)"
        }

        static func universalAccess() -> String {
            let values =
                CFPreferencesCopyMultiple(
                    nil, "com.apple.universalaccess" as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
                as NSDictionary as? [String: Any] ?? [:]
            return values.sorted { $0.key < $1.key }.map { "\($0.key)=\(String(describing: $0.value).replacingOccurrences(of: "\n", with: " ").prefix(60))" }
                .joined(separator: " ")
        }
    }

    @Suite("Probe loop (#99)", .enabled(if: probeLoopSeconds != nil), .serialized)
    @MainActor
    struct ProbeLoopTests {
        struct Field: Equatable {
            let height: CGFloat
            let width: CGFloat
            let font: String
        }

        static func measure(_ root: NSView) -> [Field] {
            FieldProbe.fields(root).map { field in
                let frame = field.convert(field.bounds, to: nil)
                return Field(height: frame.height, width: frame.width, font: field.font?.fontName ?? "nil")
            }
        }

        static func environmentState(_ window: NSWindow) -> String {
            let screens = NSScreen.screens.map {
                "\($0.localizedName) \($0.frame) scale \($0.backingScaleFactor)"
            }
            let workspace = NSWorkspace.shared
            return
                "screens [\(screens.joined(separator: "; "))], window.screen \(window.screen?.localizedName ?? "nil"), "
                + "app appearance \(NSApplication.shared.effectiveAppearance.name.rawValue), increase contrast "
                + "\(workspace.accessibilityDisplayShouldIncreaseContrast), languages \(Locale.preferredLanguages), "
                + "AppleLanguages \(UserDefaults.standard.object(forKey: "AppleLanguages") ?? "nil"), "
                + "text metrics \(SnapshotRenderer.textMetrics ?? "nil"), memory \(SnapshotRenderer.footprint) MB"
        }

        static func dump(_ root: NSView, window: NSWindow, why: String) {
            print("probe-dump: \(NotificationLog.shared.stamp()) \(why)")
            print("probe-dump:   state \(environmentState(window))")
            for line in FieldProbe.report(root) { print("probe-dump:   " + line) }
            for field in FieldProbe.fields(root) {
                guard let font = field.font else { continue }
                let fresh = NSTextField(string: field.stringValue)
                fresh.font = font
                fresh.isBezeled = false
                fresh.isBordered = false
                var chain: [String] = []
                var view: NSView? = field
                for _ in 0..<4 {
                    guard let current = view else { break }
                    chain.append("\(String(describing: type(of: current)).prefix(40)) \(current.frame)")
                    view = current.superview
                }
                print("probe-dump:   chain " + chain.joined(separator: " < "))
                let descriptor = CTFontCopyFontDescriptor(font as CTFont)
                let attributes = CTFontDescriptorCopyAttributes(descriptor) as NSDictionary
                print(
                    "probe-dump:   field \(Unmanaged.passUnretained(field).toOpaque()) cell \(field.cell.map { String(describing: Unmanaged.passUnretained($0).toOpaque()) } ?? "nil") \"\(field.stringValue.prefix(20))\" now: intrinsic \(field.intrinsicContentSize) "
                        + "cellSize \(field.cell?.cellSize ?? .zero) needsLayout \(field.needsLayout) "
                        + "fresh field with its font: intrinsic \(fresh.intrinsicContentSize); font object "
                        + "\(Unmanaged.passUnretained(font).toOpaque()) descriptor \(attributes.description.replacingOccurrences(of: "\n", with: " ").prefix(600))"
                )
            }
            let body = NSFont.preferredFont(forTextStyle: .body)
            print("probe-dump:   fresh preferred body: \(FieldProbe.font(body))")
        }

        @Test("text-field sheets, again and again")
        func loop() async throws {
            let seconds = try #require(probeLoopSeconds)
            NotificationLog.shared.begin()
            if ProcessInfo.processInfo.environment["WESTRON_PROBE_TRACE"] == "1" { SizeTrace.install() }
            SnapshotRenderer.pinLanguage()
            let matrix = ComponentMatrix.textField
            let groups = [matrix] + matrix.supplements
            let captures = ComponentMatrix.Capture.all
            var baseline: [String: [Field]] = [:]
            var hashes: [String: Data] = [:]
            let deadline = Date().addingTimeInterval(seconds)
            var round = 0
            var pictures = 0
            var deviations = 0
            print("probe: start \(NotificationLog.shared.stamp())")
            while Date() < deadline {
                round += 1
                for capture in captures {
                    for group in groups {
                        for sheet in group.sheets {
                            for picture in group.pictures(of: sheet, at: capture.textSize, columns: sheet.columns.count)
                            {
                                let key = group.key(of: picture)
                                let id = "\(key).\(capture.name)"
                                await SnapshotRenderer.pause(0)
                                SizeTrace.lines.removeAll(keepingCapacity: true)
                                let probe = MatrixSheetProbe()
                                let began = Date()
                                let window = try autoreleasepool {
                                    try SnapshotRenderer.show(
                                        try SnapshotRenderer.view(key: key, capture: capture, probe: probe),
                                        dark: capture.theme.isDark)
                                }
                                await SnapshotRenderer.pause(SnapshotRenderer.settle(attempt: 0))
                                let drawn: Result<SnapshotDraw, SnapshotMiss>
                                if ProcessInfo.processInfo.environment["WESTRON_PROBE_DRAW"] == "0" {
                                    window.contentView!.layoutSubtreeIfNeeded()
                                    drawn = .failure(.drawFailed)
                                } else {
                                    drawn = try autoreleasepool { try SnapshotRenderer.draw(window, probe: probe) }
                                }
                                let root = window.contentView!
                                let fields = Self.measure(root)
                                pictures += 1
                                let heights = fields.map { String(format: "%g", $0.height) }.joined(separator: ",")
                                print(
                                    String(
                                        format: "probe-pic: %@ round %d %@ %.3f s heights [%@] %@",
                                        NotificationLog.shared.stamp(), round, id, Date().timeIntervalSince(began),
                                        heights, NotificationLog.flags()))
                                if round <= 2, id == ProcessInfo.processInfo.environment["WESTRON_PROBE_TRACE_ID"] {
                                    for line in SizeTrace.lines { print("probe-trace-normal: " + line) }
                                }
                                if let first = baseline[id] {
                                    if first != fields {
                                        deviations += 1
                                        if deviations <= 12 {
                                            for line in SizeTrace.lines { print("probe-trace:   " + line) }
                                        }
                                        Self.dump(
                                            root, window: window,
                                            why: "\(id) round \(round): fields differ from round 1: now [\(heights)], "
                                                + "then [\(first.map { String(format: "%g", $0.height) }.joined(separator: ","))]"
                                        )
                                        // How long the state lasts: measure the same window again after a while.
                                        for wait in [0.05, 0.3, 1.0] {
                                            await SnapshotRenderer.pause(wait)
                                            root.layoutSubtreeIfNeeded()
                                            let again = Self.measure(root)
                                            print(
                                                "probe-dump:   after \(wait) s more: "
                                                    + again.map { String(format: "%g", $0.height) }.joined(
                                                        separator: ","))
                                        }
                                    }
                                } else {
                                    baseline[id] = fields
                                }
                                if case .success(let draw) = drawn, let pixels = SnapshotRenderer.pixels(of: draw.image)
                                {
                                    if let earlier = hashes[id], earlier != pixels {
                                        print("probe-pic: \(id) round \(round): pixels differ from round 1")
                                    } else if hashes[id] == nil {
                                        hashes[id] = pixels
                                    }
                                }
                                autoreleasepool { SnapshotRenderer.hide(window) }
                            }
                        }
                    }
                }
            }
            print(
                "probe: end \(NotificationLog.shared.stamp()) rounds \(round) pictures \(pictures) deviations \(deviations)"
            )
        }
    }
#endif
