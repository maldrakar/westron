import WestronCatalog
import XCTest

/// The accessibility audit of every catalog entry (issue #25). It runs from `tools/apple/check.sh a11y`.
///
/// Each test is one configuration: it opens every entry of `Catalog.entries` in isolation, with that configuration's
/// launch arguments, and runs `performAccessibilityAudit` with the configuration's audit types on every screenful of
/// the page, scrolling down to its end. Every issue the audit reports fails the test, except the ones in
/// `suppressions`, each with its reason. A new entry is audited without any change here.
///
/// The Dynamic Type and text clipped audits enlarge the text of the page they look at, and a dragged scroll view goes
/// back to its top when its content grows. Where the system's size reaches the page (`testDefaultSettings`), they run
/// in a pass of their own: one launch per window of the page, held in view by the catalog's scroll anchor
/// (`-WestronScrollAnchor`) from the top of the page to its bottom (see `audit(entryID:_:)`).
///
/// Failures of the machinery, not of a page, are told apart from the audit's findings (#74). On the CI runner the
/// simulator now and then stalls for a minute or more, and whatever the test asks of it then fails: terminating or
/// launching the catalog, a UI query, the audit itself ("Audit failed to complete in time", -56), or the entry does
/// not render. XCTest stops the test method at a failed terminate, launch, query or drag, so the rest of the entries go
/// unaudited. Withholding such a failure from XCTest (not passing it on in `record(_:)`) keeps the method going, but on
/// an app in an unknown state; so the test records every failure as it comes and only reports, one line per event (see
/// `record(_:)`): which entries it audits, when each starts and finishes, and each failure with its kind,
/// `infrastructure` (`isInfrastructure(_:)`) or `finding` (everything else, the audit's issues first). `tools/apple/check.sh a11y` reads those lines and runs the test once more for the entries the first run did
/// not finish or that failed for infrastructure alone, with "a11y: retrying …" in its output; an entry with a finding
/// is never audited again, so a finding that shows once still fails the run.
final class CatalogAccessibilityAuditTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // One entry's issues must not hide the next entry's.
        continueAfterFailure = true
    }

    /// Reports every failure with the entry it belongs to and its kind, for `tools/apple/check.sh a11y`, which retries
    /// the entries that failed for infrastructure alone; then records it as usual: nothing is dropped here.
    override func record(_ issue: XCTIssue) {
        let description = issue.compactDescription.replacingOccurrences(of: "\n", with: " ")
        let kind = Self.isInfrastructure(description) ? "infrastructure" : "finding"
        let place = currentEntry.map { "in \($0)" } ?? "outside an entry"
        print("a11y: \(currentTest): failure \(place) (\(kind)): \(description)")
        super.record(issue)
    }

    /// Starts the messages of this test's own infrastructure failures: an entry that did not render, an audit that did
    /// not complete twice, the `WESTRON_A11Y_FAIL_ONCE` hook. XCTest puts "failed - " before an `XCTFail` message.
    static let infrastructurePrefix = "infrastructure: "

    /// Whether a failure is the machinery's, told by how its message starts, never by text further in, where a page's
    /// own labels can appear: XCTest's messages for a terminate and a launch seen on the CI runner (#74), its timeouts
    /// of a request to the simulator, "Failed to <request>: Timed out while …" (a UI query on the CI runner; a UI
    /// query, a drag and a screenshot when the local simulator's `testmanagerd` was stopped for minutes), and this
    /// test's own (`infrastructurePrefix`). Every other failure is a finding. A message joins only with evidence that
    /// it is the machinery's.
    static func isInfrastructure(_ description: String) -> Bool {
        description.hasPrefix(infrastructurePrefix) || description.hasPrefix("failed - " + infrastructurePrefix)
            || description.hasPrefix("Failed to terminate dev.westron.catalog:")
            || description.hasPrefix("Application 'dev.westron.catalog' does not have a process ID")
            || description.prefixMatch(of: #/Failed to [a-z ]+: Timed out while /#) != nil
    }

    /// The test method and the entry being audited, for `record(_:)`.
    private var currentTest = "?"
    private var currentEntry: String?

    /// The default: the system's font size, the light theme, standard contrast. Every audit type runs. The theme is
    /// set, not left to the simulator, so the run does not depend on the machine.
    @MainActor
    func testDefaultSettings() {
        audit(Configuration(appearance: .light, types: Configuration.allTypes), test: "testDefaultSettings")
    }

    /// The largest accessibility font size. Every audit type runs except `dynamicType`: the catalog pins this size in
    /// the view tree (`-WestronDynamicType`), so a text cannot follow the system size the audit sets, and the audit
    /// would report every text. `testDefaultSettings` runs the `dynamicType` audit with the system's size.
    @MainActor
    func testAccessibilityDynamicType() {
        audit(
            Configuration(
                appearance: .light, dynamicType: "accessibility5", types: Configuration.typesWithoutDynamicType),
            test: "testAccessibilityDynamicType")
    }

    /// Increased contrast, the `-hc` themes: only colors change, so the contrast audit runs.
    @MainActor
    func testIncreasedContrast() {
        audit(
            Configuration(appearance: .light, increasedContrast: true, types: .contrast), test: "testIncreasedContrast")
    }

    /// The dark theme: only colors change, so the contrast audit runs.
    @MainActor
    func testDarkAppearance() {
        audit(Configuration(appearance: .dark, types: .contrast), test: "testDarkAppearance")
    }

    /// The dark theme with increased contrast.
    @MainActor
    func testDarkIncreasedContrast() {
        audit(
            Configuration(appearance: .dark, increasedContrast: true, types: .contrast),
            test: "testDarkIncreasedContrast")
    }

    // MARK: - Running the audit

    struct Configuration: Sendable {
        enum Appearance: String, Sendable {
            case light, dark
        }

        let appearance: Appearance
        var increasedContrast = false
        /// A `-WestronDynamicType` size; `nil` follows the system's.
        var dynamicType: String? = nil
        let types: XCUIAccessibilityAuditType

        var arguments: [String] {
            var arguments = ["-WestronAppearance", appearance.rawValue]
            if increasedContrast { arguments += ["-WestronContrast", "high"] }
            if let dynamicType { arguments += ["-WestronDynamicType", dynamicType] }
            return arguments
        }

        #if os(iOS)
            static let allTypes: XCUIAccessibilityAuditType = [
                .contrast, .elementDetection, .hitRegion, .sufficientElementDescription, .dynamicType, .textClipped,
                .trait,
            ]
            static let typesWithoutDynamicType = allTypes.subtracting(.dynamicType)
        #else
            static let allTypes: XCUIAccessibilityAuditType = [
                .contrast, .elementDetection, .hitRegion, .sufficientElementDescription, .action, .parentChild,
            ]
            /// macOS has no Dynamic Type audit.
            static let typesWithoutDynamicType = allTypes
        #endif
    }

    /// The audit types that change the system's text size to see how the page follows it.
    #if os(iOS)
        private static let sizeChangingTypes: XCUIAccessibilityAuditType = [.dynamicType, .textClipped]
    #else
        private static let sizeChangingTypes: XCUIAccessibilityAuditType = []
    #endif
    /// How far a drag moves the page: most of a screen, so that consecutive screenfuls overlap.
    private static let step = 0.65
    /// The most screenfuls a page is audited in; a page that does not end by then fails.
    private static let maxScreens = 30
    /// How long a page has to stay still to count as settled, and how long it may take.
    private static let stillInterval: TimeInterval = 0.25
    private static let settleTimeout: TimeInterval = 5
    /// The entries that did not stop moving within `settleTimeout`: later waits on them are short, so that a page
    /// with a running animation costs one timeout, not one per screenful.
    private var restlessEntries: Set<String> = []
    /// Where the iOS status bar ends, once looked up.
    private var statusBarBottom: CGFloat?

    @MainActor
    private func audit(_ configuration: Configuration, test: String) {
        currentTest = test
        // WESTRON_ENTRY=<id>[,<id>…] narrows the run to those entries: to fix an entry's issues, or to split a run.
        let environment = ProcessInfo.processInfo.environment
        var entries =
            environment["WESTRON_ENTRY"].map { $0.split(separator: ",").map(String.init) }
            ?? Catalog.entries.map(\.id)
        XCTAssertFalse(entries.isEmpty, "the catalog registry has no entries")
        // WESTRON_ENTRY_SHARD=<i>/<n> then takes every n-th of them from the i-th: parallel jobs split a run with it.
        if let text = environment["WESTRON_ENTRY_SHARD"] {
            do throws(CatalogShard.ParseError) {
                let shard = try CatalogShard(text)
                entries = shard.select(entries)
                print("a11y: shard \(shard): \(entries.joined(separator: ", "))")
            } catch {
                XCTFail("\(error)")
                return
            }
            XCTAssertFalse(entries.isEmpty, "WESTRON_ENTRY_SHARD=\(text) selects no entry")
        }
        // A test hook (#74): WESTRON_A11Y_FAIL_ONCE=<id> fails that entry for infrastructure before it is audited, as a
        // stalled simulator would. `tools/apple/check.sh a11y` passes it to the first run only, so its retry shows.
        let failOnce = environment["WESTRON_A11Y_FAIL_ONCE"]
        print("a11y: \(test): entries \(entries.joined(separator: ","))")
        for entryID in entries {
            currentEntry = entryID
            print("a11y: \(test): started \(entryID)")
            XCTContext.runActivity(named: "\(entryID) \(configuration.arguments.joined(separator: " "))") { _ in
                if entryID == failOnce {
                    XCTFail("\(Self.infrastructurePrefix)\(entryID): injected by WESTRON_A11Y_FAIL_ONCE")
                    return
                }
                audit(entryID: entryID, configuration)
            }
            print("a11y: \(test): finished \(entryID)")
            currentEntry = nil
        }
    }

    /// Audits an entry a screenful at a time, down to the end of the page: the audit sees only what is on screen.
    ///
    /// The Dynamic Type and text clipped audits enlarge the page's text, and a scroll view that the drags moved goes
    /// back to its top when its content grows: they would measure the top of the page on every screenful. And after
    /// them, the page's accessibility tree and its pixels disagree for a while, so that an audit of another type reads
    /// every text as failing contrast. So where the system's size reaches the page (`testDefaultSettings`), they run
    /// in a pass of their own, with no drags: a fresh launch per window of the page, each held in view by the
    /// catalog's scroll anchor (`-WestronScrollAnchor`), from the top of the page to its bottom. Where the catalog
    /// pins the size, the enlarging does not reach the page, and they run with the rest.
    @MainActor
    private func audit(entryID: String, _ configuration: Configuration) {
        let separate =
            configuration.dynamicType == nil ? configuration.types.intersection(Self.sizeChangingTypes) : []
        guard let screens = auditScreens(entryID, configuration, types: configuration.types.subtracting(separate))
        else { return }
        guard !separate.isEmpty else { return }
        // One window more than the screenfuls, from the top to the bottom, so that the windows overlap; a page of one
        // screenful gets its top and its bottom, which the enlarged text pushes below the screen.
        let windows = screens + 1
        for window in 0..<windows {
            let anchor = Double(window) / Double(windows - 1)
            guard
                let (app, entry) = launch(
                    entryID, configuration.arguments + ["-WestronScrollAnchor", String(format: "%.3f", anchor)])
            else { return }
            settle(entry, entryID, screen: window + 1)
            auditScreen(app, entryID, configuration, types: separate, screen: window + 1, nextDrag: nil)
            app.terminate()
        }
    }

    /// Launches the catalog on the entry; `nil` after a failure when it does not show.
    @MainActor
    private func launch(_ entryID: String, _ arguments: [String]) -> (XCUIApplication, XCUIElement)? {
        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", entryID] + arguments
        app.launch()

        let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
        let problem = app.descendants(matching: .any)[CatalogAccessibilityID.problem]
        let appeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in entry.exists || problem.exists },
            object: nil
        )
        guard XCTWaiter.wait(for: [appeared], timeout: 30) == .completed else {
            XCTFail("\(Self.infrastructurePrefix)\(entryID): the catalog did not render the entry within 30 s")
            app.terminate()
            return nil
        }
        if problem.exists {
            XCTFail("\(entryID): \(problem.label)")
            app.terminate()
            return nil
        }
        return (app, entry)
    }

    /// Audits every screenful of the page with the types given, on one launch, and returns how many screenfuls the
    /// page has; `nil` when the entry did not show.
    @MainActor
    @discardableResult
    private func auditScreens(
        _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType
    ) -> Int? {
        guard let (app, entry) = launch(entryID, configuration.arguments) else { return nil }
        defer { app.terminate() }
        var position = scrollPosition(entry)
        for screen in 1...Self.maxScreens {
            settle(entry, entryID, screen: screen)
            let deferred = auditScreen(
                app, entryID, configuration, types: types, screen: screen, nextDrag: entry.frame.height * Self.step)
            // The end is where a drag no longer moves the page. It is told by where the page's first text is after
            // each drag (an audit may move the page a little), not by a picture: the scroll indicator shows after
            // every drag, at the end of the page too.
            scrollDown(entry)
            settle(entry, entryID, screen: screen)
            let next = scrollPosition(entry)
            if next == position {
                // No screenful follows to show the deferred elements whole, so they count here.
                for issue in deferred {
                    XCTFail("\(entryID), screen \(screen): \(issue) (cut by the bottom of the last screenful)")
                }
                #if os(macOS)
                    if screen == 1 {
                        // Not verified that the scroll event reaches the page on macOS: a longer page that does not
                        // move is audited on its first screenful only.
                        print("a11y: \(entryID) did not move when scrolled; on macOS only its first screenful is sure")
                    }
                #endif
                return screen
            }
            position = next
        }
        XCTFail("\(entryID): the page did not end within \(Self.maxScreens) screenfuls")
        return Self.maxScreens
    }

    /// Audits what is on screen with the types given. `nextDrag` is how far the drag after this screenful moves the
    /// page, `nil` when none follows. Returns the contrast issues deferred to the next screenful (`performAudit`).
    @MainActor
    @discardableResult
    private func auditScreen(
        _ app: XCUIApplication, _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType,
        screen: Int, nextDrag: CGFloat?
    ) -> [String] {
        guard !types.isEmpty else { return [] }
        // An audit now and then gives up ("Audit failed to complete in time", -56): it is run once more, and if it
        // fails again the entry fails for infrastructure (`tools/apple/check.sh a11y` then audits it again in a run
        // of its own), but this run goes on to the next entry.
        do {
            return try performAudit(app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
        } catch {
            print("a11y: retrying the audit of \(entryID), screen \(screen): it did not complete (\(error))")
            do {
                return try performAudit(app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
            } catch {
                XCTFail(
                    "\(Self.infrastructurePrefix)\(entryID), screen \(screen): the audit did not complete: \(error)")
                return []
            }
        }
    }

    @MainActor
    private func performAudit(
        _ app: XCUIApplication, _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType,
        screen: Int, nextDrag: CGFloat?
    ) throws -> [String] {
        let visible = visibleArea(app)
        var deferred: [String] = []
        try app.performAccessibilityAudit(for: types) { issue in
            // After a drag, the contrast audit also reports an element off the screen or under the status bar,
            // measured on pixels that are not its own (the clock over a line of text). Such an element is judged on
            // the screenful before, which showed it whole: a drag moves the page by two thirds of the screen.
            if issue.auditType == .contrast, let element = issue.element, !element.frame.isEmpty,
                element.frame.minY < visible.minY || !element.frame.intersects(visible)
            {
                print(
                    "a11y: suppressed in \(entryID): \(Self.describe(issue)) (off the screen or under the status bar)")
                return true
            }
            // The same at the bottom: an element the bottom of the screen cuts is measured on the strip that shows,
            // under the home indicator, whose color changes with the page beneath it. On the CI runner "Report not
            // sent" on color-in-use, 18 pt of it on screen, failed contrast once and passed on the rerun (#74). It is
            // judged on the next screenful, but only if the next drag brings it whole into view; if no screenful
            // follows after all (the page ends), it counts (`auditScreens`).
            if issue.auditType == .contrast, let element = issue.element, let nextDrag,
                Self.cutByBottom(element.frame, visible: visible, nextDrag: nextDrag)
            {
                let description = Self.describe(issue)
                print(
                    "a11y: deferred in \(entryID), screen \(screen): \(description) (cut by the bottom of the screen; "
                        + "the next screenful shows it whole)")
                deferred.append(description)
                return true
            }
            if let suppression = Self.suppressions.first(where: {
                $0.matches(issue, entryID: entryID, configuration: configuration)
            }) {
                print("a11y: suppressed in \(entryID): \(Self.describe(issue)) (\(suppression.reason))")
                return true
            }
            print("a11y: issue in \(entryID), screen \(screen): \(Self.describe(issue))")
            return false
        }
        return deferred
    }

    /// How far inside the screenful an element must lie after the drag to count as whole: a drag's distance varies by
    /// a few points.
    private static let dragMargin: CGFloat = 24

    /// Whether the bottom of the screen cuts the element, and the drag of `nextDrag` points up brings it whole into
    /// view, below the status bar.
    static func cutByBottom(_ frame: CGRect, visible: CGRect, nextDrag: CGFloat) -> Bool {
        frame.maxY > visible.maxY && frame.minY < visible.maxY
            && frame.minY - nextDrag >= visible.minY + dragMargin
            && frame.maxY - nextDrag <= visible.maxY - dragMargin
    }

    /// The part of the screen the page shows itself on: below the status bar on iOS. Looked up once per run.
    @MainActor
    private func visibleArea(_ app: XCUIApplication) -> CGRect {
        let window = app.windows.firstMatch.frame
        #if os(iOS)
            if statusBarBottom == nil {
                let statusBar = XCUIApplication(bundleIdentifier: "com.apple.springboard").statusBars.firstMatch
                statusBarBottom = statusBar.exists ? statusBar.frame.maxY : 0
            }
            let top = statusBarBottom ?? 0
            return CGRect(x: window.minX, y: top, width: window.width, height: max(window.maxY - top, 0))
        #else
            return window
        #endif
    }

    /// Waits until two pictures of the entry in a row are the same: the layout and its animations have finished, the
    /// scroll has stopped. A page that is still moving after `settleTimeout` is audited as it is, with a line in the
    /// log, and is not waited for again.
    @MainActor
    private func settle(_ entry: XCUIElement, _ entryID: String, screen: Int) {
        guard !restlessEntries.contains(entryID) else {
            Thread.sleep(forTimeInterval: Self.stillInterval)
            return
        }
        var previous = entry.screenshot().pngRepresentation
        let deadline = Date().addingTimeInterval(Self.settleTimeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: Self.stillInterval)
            let current = entry.screenshot().pngRepresentation
            if current == previous { return }
            previous = current
        }
        restlessEntries.insert(entryID)
        print(
            "a11y: \(entryID), screen \(screen): the page was still moving after \(Int(Self.settleTimeout)) s; it is "
                + "audited as it is, and not waited for again")
    }

    /// Where the page's first text is on screen: it moves when the page scrolls.
    @MainActor
    private func scrollPosition(_ entry: XCUIElement) -> CGRect {
        entry.descendants(matching: .staticText).firstMatch.frame
    }

    /// Scrolls the page up by most of a screen, so that consecutive screenfuls overlap, without momentum.
    @MainActor
    private func scrollDown(_ entry: XCUIElement) {
        #if os(iOS)
            let start = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15 + Self.step))
            let end = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.2)
        #else
            entry.scroll(byDeltaX: 0, deltaY: -entry.frame.height * Self.step)
        #endif
    }

    private static func describe(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let element =
            issue.element.map { "\($0.elementType.rawValue) \"\($0.label)\" [\($0.identifier)] at \($0.frame)" }
            ?? "no element"
        return
            "\(issue.compactDescription) (type \(issue.auditType.rawValue)); \(element); \(issue.detailedDescription)"
    }

    // MARK: - Suppressions

    /// An issue the audit reports that is not a problem of the entry, or that the catalog cannot fix. Each has its
    /// reason; an audit type is never ignored as a whole.
    struct Suppression: Sendable {
        enum Scope: Sendable {
            /// One entry by its id.
            case entry(String)
            /// Every entry of a catalog section.
            case section(CatalogEntry.Section)
        }

        let scope: Scope
        let type: XCUIAccessibilityAuditType
        let reason: String
        /// The issue's `compactDescription` it must have, if any.
        var description: String? = nil
        /// The configuration's theme it applies in; `nil` for both.
        var appearance: Configuration.Appearance? = nil
        /// The element's accessibility value it must have, if any.
        var value: String? = nil
        /// Whether the element must be enabled, if that matters: `false` for a disabled control's.
        var enabled: Bool? = nil
        /// Tells the issue by its element's label; `nil` when the audit names no element.
        let label: @Sendable (String?) -> Bool

        init(
            _ scope: Scope, type: XCUIAccessibilityAuditType, reason: String, description: String? = nil,
            appearance: Configuration.Appearance? = nil, value: String? = nil, enabled: Bool? = nil,
            label: @escaping @Sendable (String?) -> Bool
        ) {
            self.scope = scope
            self.type = type
            self.reason = reason
            self.description = description
            self.appearance = appearance
            self.value = value
            self.enabled = enabled
            self.label = label
        }

        @MainActor
        func matches(_ issue: XCUIAccessibilityAuditIssue, entryID: String, configuration: Configuration) -> Bool {
            switch scope {
            case .entry(let id): guard id == entryID else { return false }
            case .section(let section): guard Catalog.entry(id: entryID)?.section == section else { return false }
            }
            guard issue.auditType == type else { return false }
            if let description, issue.compactDescription != description { return false }
            if let appearance, configuration.appearance != appearance { return false }
            if let value, issue.element?.value as? String != value { return false }
            if let enabled, issue.element?.isEnabled != enabled { return false }
            return label(issue.element?.label)
        }
    }

    static let suppressions: [Suppression] = {
        var suppressions = [
            // "Label not human-readable" on a token name (`space.100`, `text.on-accent`, `color.background.*`) on
            // a foundation page. The page shows the token by its name, and the label is the visible text, as it
            // must be for Voice Control; a spoken paraphrase would no longer match what is on screen. A component
            // entry gets no such pass.
            Suppression(
                .section(.foundations), type: .sufficientElementDescription, reason: "a token name shown as written",
                description: "Label not human-readable"
            ) {
                $0?.wholeMatch(of: #/[a-z][a-z0-9-]*(\.([a-z0-9-]+|\*))+/#) != nil
            },
            // "Contrast failed" on the layers of a shadow sample (`y 4 pt, blur 12 pt`): the sample casts its
            // shadow on its own caption, and that shadow is the token being shown. The caption's colors,
            // text.secondary on background.canvas, pass on their own (`tools/westron tokens contrast`).
            Suppression(.entry("shape"), type: .contrast, reason: "a shadow sample's caption under its own shadow") {
                $0?.wholeMatch(of: #/y [0-9.]+ pt, blur [0-9.]+ pt/#) != nil
            },
            // "Contrast nearly passed" on the dash that stands for no delay in the motion table, in the light
            // themes. It is text.primary on background.canvas, the pair with the most contrast westron has; the
            // audit measures the pixels of a glyph that is a single thin stroke.
            Suppression(
                .entry("motion"), type: .contrast, reason: "a dash, a single thin stroke",
                description: "Contrast nearly passed", appearance: .light
            ) { $0 == "–" },
            // Contrast on the disabled control samples, drawn at opacity.disabled on purpose: WCAG exempts an
            // inactive control from the contrast minimum (design-language chapter 08). The page announces them as
            // disabled, and only an element with that value matches; the enabled samples are audited as usual.
            Suppression(.entry("controls"), type: .contrast, reason: "an inactive control", value: "disabled") {
                ["Save", "Delete", "Cancel"].contains($0 ?? "")
            },
        ]
        // Contrast on the disabled Button samples of the state pages, drawn whole at opacity.disabled by the
        // contract: WCAG exempts an inactive control from the contrast minimum (design-language chapter 08). The
        // system disables them (`.disabled(true)`), so only an element that is not enabled matches; the other rows,
        // loading included, are audited as usual.
        suppressions += ["button-states", "button-states-destructive"].map { entryID in
            Suppression(.entry(entryID), type: .contrast, reason: "an inactive control", enabled: false) {
                ["Save", "Delete"].contains($0 ?? "")
            }
        }
        #if os(iOS)
            suppressions += [
                // "Text clipped" with no element on the background colors. It appeared when the page got its
                // layout for accessibility sizes, which puts a name on a line above its cells. The audit names no
                // element, so there is nothing to fix by; the same page at accessibility5 passes the text clipped
                // audit with an element for each text (testAccessibilityDynamicType), and its screenshot at
                // accessibility3 shows every label whole.
                Suppression(.entry("color-backgrounds"), type: .textClipped, reason: "an issue with no element") {
                    $0 == nil
                }
            ]
        #endif
        return suppressions
    }()
}
