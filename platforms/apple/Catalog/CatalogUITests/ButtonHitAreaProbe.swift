import XCTest

#if os(iOS)
    /// SPIKE for #102, not for merging: measures how far past each edge of a button a tap still reaches it, on the
    /// catalog's `button-behavior` entry that ButtonBehaviorTests uses, and prints one line per tap. It records and never
    /// fails on a miss. It is not one of the behaviour classes of tools/apple/check.sh, so only the spike's workflow
    /// (`.github/workflows/spike-ios27-hit-area.yml`) and an explicit `-only-testing:CatalogUITests/ButtonHitAreaProbe`
    /// run it.
    ///
    /// Lines, each greppable by its prefix:
    /// - `probe-env:` the device, the OS, the screen;
    /// - `probe-element:` every element of the page at the start of a test, with its frame (the neighbours);
    /// - `probe:` one tap of a sweep: the button, the edge, the offset past it in points (negative inside), whether the
    ///   press reached it, the button's frame and the tap's point at the time, what else changed, and the elements
    ///   whose frames hold the point (`on=`);
    /// - `probe-exact:` the tap of `testSmallButtonHitArea`, repeated from a fresh launch;
    /// - `probe-note:` anything out of the ordinary (a tap that left the page, a reset).
    final class ButtonHitAreaProbe: XCTestCase {
        /// Must match `ButtonCatalogID` in WestronCatalog.
        private enum ID {
            static let rest = "button.live.rest"
            static let small = "button.live.small"
            static let firstNeighbor = "button.live.neighbor-first"
            static let secondNeighbor = "button.live.neighbor-second"
            static let neighbors = "button.live.neighbors"
            static let accessibilityPress = "button.live.accessibility-press"
            static let loadingToggle = "button.live.loading-toggle"
            static let count = "button.live.count"
        }

        private enum Edge: String, CaseIterable {
            case bottom, top, left, right

            /// The point on the edge's middle, in the element's normalized coordinates.
            var anchor: CGVector {
                switch self {
                case .bottom: CGVector(dx: 0.5, dy: 1)
                case .top: CGVector(dx: 0.5, dy: 0)
                case .left: CGVector(dx: 0, dy: 0.5)
                case .right: CGVector(dx: 1, dy: 0.5)
                }
            }

            /// `offset` points outward from the edge (negative: inside).
            func outward(_ offset: CGFloat) -> CGVector {
                switch self {
                case .bottom: CGVector(dx: 0, dy: offset)
                case .top: CGVector(dx: 0, dy: -offset)
                case .left: CGVector(dx: -offset, dy: 0)
                case .right: CGVector(dx: offset, dy: 0)
                }
            }
        }

        /// A few inside, then every point from the edge out to 20 pt.
        private let offsets: [CGFloat] = [-4, -1] + (0...20).map { CGFloat($0) }
        /// Between taps: well past a double tap's interval, so no tap is taken for the second of a pair.
        private let pause: TimeInterval = 0.6

        private var app: XCUIApplication!

        @MainActor
        override func setUp() async throws {
            continueAfterFailure = true
            app = XCUIApplication()
            app.launchArguments = ["-WestronEntry", "button-behavior"]
            launch()
        }

        @MainActor
        override func tearDown() async throws {
            app.terminate()
        }

        @MainActor
        private func launch() {
            app.launch()
            XCTAssertTrue(app.staticTexts[ID.count].waitForExistence(timeout: 30), "the entry did not render")
        }

        // MARK: The page's state, from one snapshot

        private struct Element {
            let type: String
            let identifier: String
            let label: String
            let value: String
            let frame: CGRect
        }

        private struct Page {
            let elements: [Element]

            func first(_ identifier: String) -> Element? { elements.first { $0.identifier == identifier } }
            func text(_ identifier: String) -> String {
                guard let element = first(identifier) else { return "<missing>" }
                return element.label.isEmpty ? element.value : element.label
            }
            var exists: Bool { first(ID.count) != nil }
            var accepted: Int { Int(text(ID.count).split(separator: " ").last ?? "") ?? -1 }
            var neighbors: String { text(ID.neighbors) }
            /// Counts of the two neighbours, from "first 1, second 0".
            var neighborCounts: (first: Int, second: Int) {
                let numbers = neighbors.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
                return numbers.count == 2 ? (numbers[0], numbers[1]) : (-1, -1)
            }
            /// The loading toggle's switch: "1" while loading.
            var loading: String { elements.first { $0.type == "switch" }?.value ?? "<missing>" }
            var accessibilityPress: String { first(ID.accessibilityPress)?.value ?? "<missing>" }
            var window: CGRect { elements.first { $0.type == "window" }?.frame ?? .null }

            /// The elements whose frames hold the point: controls, texts and anything with an identifier.
            func at(_ point: CGPoint) -> String {
                let hits = elements.filter {
                    $0.frame.contains(point)
                        && (["button", "switch", "staticText", "image", "navigationBar"].contains($0.type)
                            || !$0.identifier.isEmpty)
                }
                guard !hits.isEmpty else { return "none" }
                return hits.map { "\($0.type):\($0.identifier.isEmpty ? $0.label : $0.identifier)" }
                    .map { $0.replacingOccurrences(of: " ", with: "_") }.joined(separator: ",")
            }
        }

        private static func name(_ type: XCUIElement.ElementType) -> String {
            switch type {
            case .application: "application"
            case .window: "window"
            case .navigationBar: "navigationBar"
            case .scrollView: "scrollView"
            case .button: "button"
            case .switch: "switch"
            case .staticText: "staticText"
            case .image: "image"
            case .other: "other"
            case .toggle: "toggle"
            default: "type\(type.rawValue)"
            }
        }

        @MainActor
        private func page() -> Page {
            var elements: [Element] = []
            func walk(_ snapshot: XCUIElementSnapshot) {
                elements.append(
                    Element(
                        type: Self.name(snapshot.elementType), identifier: snapshot.identifier, label: snapshot.label,
                        value: snapshot.value.map { "\($0)" } ?? "", frame: snapshot.frame))
                for child in snapshot.children { walk(child) }
            }
            do {
                walk(try app.snapshot())
            } catch {
                print("probe-note: snapshot failed: \(error)")
            }
            return Page(elements: elements)
        }

        private static func format(_ rect: CGRect) -> String {
            rect.isNull ? "(null)" : "(\(n(rect.minX)),\(n(rect.minY)),\(n(rect.width)),\(n(rect.height)))"
        }

        private static func format(_ point: CGPoint) -> String { "(\(n(point.x)),\(n(point.y)))" }

        private static func n(_ value: CGFloat) -> String {
            value == value.rounded() ? "\(Int(value))" : String(format: "%.2f", Double(value))
        }

        // MARK: What is logged once per test

        @MainActor
        private func logEnvironment(_ test: String) {
            let environment = ProcessInfo.processInfo.environment
            let screenshot = XCUIScreen.main.screenshot()
            let device = UIDevice.current
            print(
                "probe-env: test=\(test) device=\(environment["SIMULATOR_DEVICE_NAME"] ?? device.name)"
                    + " model=\(environment["SIMULATOR_MODEL_IDENTIFIER"] ?? device.model)"
                    + " os=\(device.systemName)_\(device.systemVersion)"
                    + " runtime=\(environment["SIMULATOR_RUNTIME_VERSION"] ?? "?")"
                    + "_\(environment["SIMULATOR_RUNTIME_BUILD_VERSION"] ?? "?")"
                    + " scale=\(Self.n(screenshot.image.scale))"
                    + " screenshot=\(Self.n(screenshot.image.size.width))x\(Self.n(screenshot.image.size.height))"
                    + " orientation=\(XCUIDevice.shared.orientation.rawValue)")
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "\(test) page"
            attachment.lifetime = .keepAlways
            add(attachment)
            for element in page().elements where element.type != "other" || !element.identifier.isEmpty {
                print(
                    "probe-element: test=\(test) type=\(element.type) id=\(element.identifier.isEmpty ? "-" : element.identifier)"
                        + " frame=\(Self.format(element.frame)) label=\"\(element.label)\" value=\"\(element.value)\"")
            }
        }

        // MARK: Sweeps

        /// What a tap reached on the target: `accepted` for the live buttons, the neighbours' own count for those.
        private enum Counter {
            case accepted, firstNeighbor, secondNeighbor

            func read(_ page: Page) -> Int {
                switch self {
                case .accepted: page.accepted
                case .firstNeighbor: page.neighborCounts.first
                case .secondNeighbor: page.neighborCounts.second
                }
            }
        }

        /// Taps past each edge of the button `identifier`, at each offset, and prints a line per tap.
        @MainActor
        private func sweep(
            _ size: String, _ identifier: String, counter: Counter, edges: [Edge] = Edge.allCases,
            offsets: [CGFloat]? = nil
        ) {
            let element = app.buttons[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: 5), "no button \(identifier)")
            var before = page()
            for edge in edges {
                for offset in offsets ?? self.offsets {
                    before = tap(
                        size, identifier, element, edge: edge, offset: offset, counter: counter, before: before)
                }
            }
        }

        /// One tap: returns the page after it, put back in the loading state if the tap turned it off.
        @MainActor
        private func tap(
            _ size: String, _ identifier: String, _ element: XCUIElement, edge: Edge, offset: CGFloat, counter: Counter,
            before: Page
        ) -> Page {
            let frame = before.first(identifier)?.frame ?? .null
            let coordinate = element.coordinate(withNormalizedOffset: edge.anchor).withOffset(edge.outward(offset))
            let point = coordinate.screenPoint
            let prefix =
                "probe: size=\(size) id=\(identifier) edge=\(edge.rawValue) offset=\(Self.n(offset))"
            let window = before.window
            if !window.isNull && !window.insetBy(dx: 0.5, dy: 0.5).contains(point) {
                print(
                    "\(prefix) reached=skip frame=\(Self.format(frame)) point=\(Self.format(point)) why=offscreen")
                return before
            }
            Thread.sleep(forTimeInterval: pause)
            coordinate.tap()
            var after = page()
            if !after.exists {
                print("probe-note: after \(prefix): the page is gone; relaunching")
                app.terminate()
                launch()
                after = page()
                print(
                    "\(prefix) reached=lost frame=\(Self.format(frame)) point=\(Self.format(point))"
                        + " on=\(before.at(point))")
                return after
            }
            let reached = counter.read(after) - counter.read(before)
            var changes: [String] = []
            if after.accepted != before.accepted { changes.append("accepted=\(before.accepted)->\(after.accepted)") }
            if after.neighbors != before.neighbors {
                changes.append(
                    "neighbors=\(before.neighbors)->\(after.neighbors)".replacingOccurrences(of: " ", with: "_"))
            }
            if after.loading != before.loading { changes.append("loading=\(before.loading)->\(after.loading)") }
            if after.accessibilityPress != before.accessibilityPress {
                changes.append("a11ypress=changed")
            }
            let moved = after.first(identifier)?.frame ?? .null
            if moved != frame { changes.append("frameAfter=\(Self.format(moved))") }
            print(
                "\(prefix) reached=\(reached) frame=\(Self.format(frame)) point=\(Self.format(point))"
                    + " on=\(before.at(point)) changed=\(changes.isEmpty ? "-" : changes.joined(separator: ";"))")
            if after.loading != before.loading {
                // The tap turned the loading toggle; it goes back, so the next tap sees the same page.
                print("probe-note: after \(prefix): the loading toggle changed; setting it back")
                Thread.sleep(forTimeInterval: pause)
                let toggle = app.descendants(matching: .any)[ID.loadingToggle].firstMatch
                if toggle.switches.firstMatch.exists { toggle.switches.firstMatch.tap() } else { toggle.tap() }
                after = page()
                print("probe-note: loading is now \(after.loading)")
            }
            return after
        }

        // MARK: Tests, run in this order (XCTest sorts them by name)

        /// The exact tap of `ButtonBehaviorTests.testSmallButtonHitArea`, from a fresh launch, three times; then a sweep
        /// below size s from 5 to 11 pt in steps of a third of a point, a pixel at 3x, around that tap's 8 pt (on iOS
        /// 26.3 the reach below "Add" ends between 8 and 9 pt), as `size=s-fine`.
        @MainActor
        func test1ExactSmallButtonTap() {
            logEnvironment("exact")
            for run in 1...3 {
                if run > 1 {
                    app.terminate()
                    launch()
                }
                let small = app.buttons[ID.small]
                XCTAssertTrue(small.waitForExistence(timeout: 5), "no button \(ID.small)")
                let frame = small.frame
                let coordinate = small.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(
                    CGVector(dx: 0, dy: 8))
                let before = page()
                coordinate.tap()
                let after = page()
                print(
                    "probe-exact: run=\(run) reached=\(after.accepted - before.accepted)"
                        + " frame=\(Self.format(frame)) point=\(Self.format(coordinate.screenPoint))"
                        + " on=\(before.at(coordinate.screenPoint)) loading=\(before.loading)->\(after.loading)"
                        + " neighbors=\"\(after.neighbors)\"")
            }
            let fine = (15...33).map { CGFloat($0) / 3 }
            sweep("s-fine", ID.small, counter: .accepted, edges: [.bottom], offsets: fine)
        }

        /// Size s, "Add": 28 pt tall on iOS. Bottom first, the edge the failing test taps.
        @MainActor
        func test2SmallButtonSweep() {
            logEnvironment("s")
            sweep("s", ID.small, counter: .accepted)
        }

        /// Size m, "Save": 36 pt tall on iOS.
        @MainActor
        func test3MediumButtonSweep() {
            logEnvironment("m")
            sweep("m", ID.rest, counter: .accepted)
        }

        /// Size s icon-only, the first of the close neighbours: its right edge is the 8 pt gap to the second, so the
        /// sweep's right edge is the gap's sweep too (the second's own count shows a tap the second took).
        @MainActor
        func test4IconOnlySmallButtonSweep() {
            logEnvironment("s-icon-only")
            sweep("s-icon-only", ID.firstNeighbor, counter: .firstNeighbor)
            // The gap from the second's side: a tap left of it, which the right sweep above reached from the first's.
            sweep("s-icon-only", ID.secondNeighbor, counter: .secondNeighbor, edges: [.left])
        }
    }
#endif
