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
    /// `tools/apple/snapshot-matrix.sh` (`matrix_plan`) knows XCTest's messages below too, for its retry.
    static let infrastructurePrefix = "infrastructure: "

    /// Whether a failure is the machinery's, told by how its message starts, never by text further in, where a page's
    /// own labels can appear. Each message is XCTest's for a request to the simulator, which no audit issue and no
    /// assertion of this test produces (those are `describe(_:)`'s issue texts and this file's `XCTFail` messages):
    /// - this test's own (`infrastructurePrefix`): an entry that did not render, an audit that did not complete twice;
    /// - "Failed to terminate dev.westron.catalog:<pid>: …", a terminate: the CI runner (#74; again in run
    ///   44444325775, `testDarkIncreasedContrast`, which passed on its retry);
    /// - "Application 'dev.westron.catalog' does not have a process ID", a launch: the CI runner (#74);
    /// - "Failed to <request>: Timed out while …", a request that timed out: a UI query on the CI runner (#74); a UI
    ///   query, a drag and a screenshot when the local simulator's `testmanagerd` was stopped for minutes;
    /// - "Failed to get background assertion for target app with pid <pid>: Timed out while acquiring background
    ///   assertion.", a launch (`app.launch()` in `launch(_:_:)`) on a stalled simulator: the CI runner, run
    ///   44444325775, `testDefaultSettings` 2/3, in the shard's first entry;
    /// - "Failed to launch <XCUIApplicationImpl: 0x… dev.westron.catalog at …> via Xcode: Timed out while launching
    ///   application via Xcode.", a launch that timed out: the CI runner, run 44444325775, in the snapshot matrix's
    ///   first `app.launch()` (`SnapshotMatrixTests`, removed in #92), the same call as here; between the angle
    ///   brackets is XCTest's description of the app, its address and path. A launch that fails otherwise, an app
    ///   that crashes on an entry, stays a finding.
    /// Every other failure is a finding. A message joins only with evidence that it is the machinery's.
    static func isInfrastructure(_ description: String) -> Bool {
        description.hasPrefix(infrastructurePrefix) || description.hasPrefix("failed - " + infrastructurePrefix)
            || description.hasPrefix("Failed to terminate dev.westron.catalog:")
            || description.hasPrefix("Application 'dev.westron.catalog' does not have a process ID")
            || description.prefixMatch(of: #/Failed to [a-z ]+: Timed out while /#) != nil
            || description.prefixMatch(
                of: #/Failed to get background assertion for target app with pid [0-9]+: Timed out while acquiring /#)
                != nil
            || description.prefixMatch(
                of: #/Failed to launch <XCUIApplicationImpl: [^>]+> via Xcode: Timed out while launching application/#)
                != nil
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
        // An audit now and then gives up ("Audit failed to complete in time", -56): it is run once more. On iOS, one
        // that gives up twice at a screenful is run a third time with the page moved on by a tenth of the screen:
        // measured on 2026-11-22 (ListRow, #119), the contrast audit gave up on every try at one scroll position of
        // `list-row` at accessibility5, and completed in a third of a second with the page 30 pt before it or 60 pt
        // past it. The nudge scrolls a tenth of the screen off its top. From the second screenful on, the screenful
        // before showed that strip, since the screenfuls overlap by more than the nudge (`step`). On the first, screen
        // 1 of `auditScreens` and window 1 of the Dynamic Type pass, nothing did: there the page is dragged back after
        // the nudged audit and audited once more where it was, so that the strip is audited too, or, if that audit
        // gives up again, the entry fails for infrastructure rather than pass with the strip unaudited. When the
        // audit cannot complete, the entry fails for infrastructure (`tools/apple/check.sh a11y` then audits it again
        // in a run of its own), but this run goes on to the next entry.
        do {
            return try performAudit(app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
        } catch {
            print("a11y: retrying the audit of \(entryID), screen \(screen): it did not complete (\(error))")
            do {
                return try performAudit(app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
            } catch {
                #if os(iOS)
                    let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
                    if entry.exists {
                        print(
                            "a11y: auditing \(entryID), screen \(screen) again, the page moved on by a tenth: \(error)")
                        nudge(entry, from: 0.5, to: 0.4)
                        settle(entry, entryID, screen: screen)
                        if let issues = try? performAudit(
                            app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
                        {
                            guard screen == 1 else { return issues }
                            print(
                                "a11y: auditing \(entryID), screen 1 once more, the page moved back, for the strip "
                                    + "the nudge scrolled off its top")
                            nudge(entry, from: 0.4, to: 0.5)
                            settle(entry, entryID, screen: screen)
                            do {
                                let back = try performAudit(
                                    app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
                                return issues + back.filter { !issues.contains($0) }
                            } catch {
                                XCTFail(
                                    "\(Self.infrastructurePrefix)\(entryID), screen 1: the audit completed with the "
                                        + "page moved on by a tenth, but not moved back, so the strip above was not "
                                        + "audited: \(error)")
                                return []
                            }
                        }
                    }
                #endif
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
            // A suppressed issue is not the entry's wherever it is, so it is not deferred to a screenful that may
            // never come (the text field's focus pages, whose last line the keyboard covers).
            if let suppression = Self.suppressions.first(where: {
                $0.matches(issue, entryID: entryID, configuration: configuration)
            }) {
                print("a11y: suppressed in \(entryID): \(Self.describe(issue)) (\(suppression.reason))")
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

    #if os(iOS)
        /// Drags the page slowly between two heights of the entry, as fractions of it, without momentum: from 0.5 to
        /// 0.4 moves it on by a tenth of the screen, from 0.4 to 0.5 back.
        @MainActor
        private func nudge(_ entry: XCUIElement, from start: CGFloat, to end: CGFloat) {
            let from = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: start))
            let to = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: end))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
    #endif

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
        /// Text the issue's `detailedDescription` must contain, if any, such as the class of a system view.
        var detail: String? = nil
        /// Whether the element must reach below the top of the system keyboard, which must be up: an element the
        /// keyboard covers is measured on the keyboard's pixels.
        var underKeyboard = false
        /// Whether a text of the page must reach under the iOS status bar while the issue is reported: the status bar's
        /// own text, the clock, is then drawn over the page's. Never on macOS, which has no status bar over the page.
        var textUnderStatusBar = false
        /// Tells the issue by its element's label; `nil` when the audit names no element.
        let label: @Sendable (String?) -> Bool

        init(
            _ scope: Scope, type: XCUIAccessibilityAuditType, reason: String, description: String? = nil,
            appearance: Configuration.Appearance? = nil, value: String? = nil, enabled: Bool? = nil,
            detail: String? = nil, underKeyboard: Bool = false, textUnderStatusBar: Bool = false,
            label: @escaping @Sendable (String?) -> Bool
        ) {
            self.scope = scope
            self.type = type
            self.reason = reason
            self.description = description
            self.appearance = appearance
            self.value = value
            self.enabled = enabled
            self.detail = detail
            self.underKeyboard = underKeyboard
            self.textUnderStatusBar = textUnderStatusBar
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
            // A value as text: iOS gives a switch's as a string, macOS a checkbox's as a number.
            if let value, issue.element?.value.map({ "\($0)" }) != value { return false }
            if let enabled, issue.element?.isEnabled != enabled { return false }
            if let detail, !issue.detailedDescription.contains(detail) { return false }
            if underKeyboard {
                let keyboard = XCUIApplication().keyboards.firstMatch
                guard keyboard.exists, let frame = issue.element?.frame, !frame.isEmpty,
                    frame.maxY > keyboard.frame.minY
                else { return false }
            }
            if textUnderStatusBar && !Self.pageTextUnderStatusBar() { return false }
            return label(issue.element?.label)
        }

        /// Whether a static text of the catalog reaches under the iOS status bar now; always `false` on macOS.
        @MainActor
        static func pageTextUnderStatusBar() -> Bool {
            #if os(iOS)
                let statusBar = XCUIApplication(bundleIdentifier: "com.apple.springboard").statusBars.firstMatch
                guard statusBar.exists, let page = try? XCUIApplication().snapshot() else { return false }
                let bar = statusBar.frame
                func reaches(_ element: XCUIElementSnapshot) -> Bool {
                    (element.elementType == .staticText && !element.frame.isEmpty && element.frame.intersects(bar))
                        || element.children.contains(where: reaches)
                }
                return reaches(page)
            #else
                return false
            #endif
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
            // Contrast on the disabled buttons of the disabled row, drawn whole at opacity.disabled on purpose: WCAG
            // exempts an inactive control from the contrast minimum (design-language chapter 08). The system
            // disables them (`.disabled(true)`), so only an element that is not enabled matches; the enabled row and
            // the fill samples are audited as usual.
            Suppression(.entry("controls"), type: .contrast, reason: "an inactive control", enabled: false) {
                ["Save", "Delete", "Cancel"].contains($0 ?? "")
            },
        ]
        // Contrast on the disabled Button samples of the state pages, drawn whole at opacity.disabled by the
        // contract: WCAG exempts an inactive control from the contrast minimum (design-language chapter 08). The
        // system disables them (`.disabled(true)`), so only an element that is not enabled matches; the other rows,
        // loading included, are audited as usual.
        suppressions += ["button-states", "button-states-destructive", "button-states-destructive-disabled"].map {
            entryID in
            Suppression(.entry(entryID), type: .contrast, reason: "an inactive control", enabled: false) {
                ["Save", "Delete"].contains($0 ?? "")
            }
        }
        suppressions += [
            // Contrast on the disabled floating samples with a label, drawn whole at opacity.disabled by the contract:
            // WCAG exempts an inactive control (design-language chapter 08). The audit reports a button's text, never
            // an icon-only button, so only the words match (ButtonFloatingID): "Edit", the disabled row on glass of
            // `button-floating-states`, and "Disabled", the disabled row before OS 26 of `button-floating-before-26`.
            Suppression(
                .entry("button-floating-states"), type: .contrast, reason: "an inactive control", enabled: false
            ) { $0 == "Edit" },
            Suppression(
                .entry("button-floating-before-26"), type: .contrast, reason: "an inactive control", enabled: false
            ) { $0 == "Disabled" },
        ]
        // Contrast on the enabled floating secondary "Edit" on the system's glass over the striped ground, which westron
        // does not draw and whose contrast the contract does not promise (decisions/0015). Measured by pixels instead:
        // text.primary on that glass 5.85:1 and more in the dark theme, 8.09:1 at accessibility5 in the light one, where
        // the audit flags it; the audit reports no colors, so what it sampled on the glass cannot be shown. Only "Edit"
        // matches, the samples on glass over the stripes (ButtonFloatingID): at every size, in each state and loading,
        // on the three entries that hold them; the primaries, "New" and "Delete", and the samples before OS 26 are
        // still audited.
        suppressions += ["button-floating-sizes", "button-floating-states", "button-floating-before-26"].map {
            entryID in
            Suppression(
                .entry(entryID), type: .contrast, reason: "a label on glass, measured by pixels", enabled: true
            ) { $0 == "Edit" }
        }
        suppressions += [
            // Contrast on "Open", the floating secondary on glass over the light band in the dark theme: a real
            // failure, text.primary at 3.8:1 on the glass there by pixels (decisions/0015, Q5's test), left to the
            // owner's answer to Q5. Only "Open" in the dark appearance matches; over the band in the other themes the
            // glass turns light or dark against the band and the label passes at 12:1 and more.
            Suppression(
                .entry("button-floating-sizes"), type: .contrast,
                reason: "Q5's failure in the dark theme, for the owner", appearance: .dark, enabled: true
            ) { $0 == "Open" },
            // Contrast on the list rows under the floating buttons of "Over a pressable list": the buttons stand in
            // the rows' frames (size l, 50 pt, reaches into the rows above and below), and the audit samples their
            // glass with the row's title. The rows are ListRow's own, audited without anything over them in
            // list-row. Only those three titles match.
            Suppression(
                .entry("button-floating"), type: .contrast, reason: "a row under floating buttons", enabled: true
            ) { ["Groceries", "Work", "Home"].contains($0 ?? "") },
            // Contrast on the disabled Checkbox sample, drawn whole at opacity.disabled by the contract: WCAG exempts
            // an inactive control (design-language chapter 08). Only an element that is not enabled matches.
            Suppression(.entry("checkbox"), type: .contrast, reason: "an inactive control", enabled: false) {
                ["disabled", "disabled, checked"].contains($0 ?? "")
            },
            // "Contrast nearly passed" on a checked check: the audit measures its disc against the canvas and holds
            // it to text's 4.5:1, while the disc is a graphic, held to the non-text 3:1 (4.5:1 in high contrast,
            // where the audit passes it) by the non-text declarations of color.background.accent and
            // color.category.<name>.control, which `tools/westron tokens contrast` checks in every theme (WCAG
            // 1.4.11; decisions/0012). Only an enabled check that is on, with one of the page's checked labels,
            // matches, and only "nearly passed", which is at least 3:1; the same text.primary labels are audited
            // unsuppressed on the page's unchecked rows.
            Suppression(
                .entry("checkbox"), type: .contrast, reason: "a checked disc, a non-text graphic at 3:1",
                description: "Contrast nearly passed", value: "1", enabled: true
            ) { label in
                [
                    "checked", "pressed, checked", "focus, checked", "Outline the sections", "blue", "sky", "teal",
                    "emerald", "green", "olive", "amber",
                    "orange", "red", "pink", "violet", "indigo",
                ].contains(label ?? "")
            },
            // Contrast on the disabled Chip samples, selectable and pressable, drawn whole at opacity.disabled by the
            // contract: WCAG exempts an inactive control (design-language chapter 08). The system disables them
            // (`.disabled(true)`), so only an element that is not enabled matches; the other states are audited as
            // usual.
            Suppression(.entry("chip"), type: .contrast, reason: "an inactive control", enabled: false) {
                ["disabled", "disabled, on"].contains($0 ?? "")
            },
            // Contrast on the disabled ListRow samples, drawn whole at opacity.disabled by the contract, their slots
            // with them: WCAG exempts an inactive control (design-language chapter 08). Only an element that is not
            // enabled matches: the row's button and the texts under it, its title and its count; the same words in the
            // other states are audited as usual.
            Suppression(.entry("list-row"), type: .contrast, reason: "an inactive row", enabled: false) {
                [
                    "pressable, disabled", "pressable, disabled, 12", "static, disabled", "static, disabled, 12",
                    "Archived", "12",
                ].contains($0 ?? "")
            },
            // No suppression for the checks with no drawn label beside separate titles (the live row here, the rows
            // of `checkbox-in-list`): written with `Toggle(isOn:accessibilityLabel:)`, their label is an `EmptyView`
            // carrying the name, and the audit reports neither contrast nor clipped text on them (measured on
            // iOS 26.3, 2026-11-19, #86). Hidden with `.labelsHidden()` instead, the label was measured as if drawn in
            // the circle's square, and needed three suppressions here.
        ]
        #if os(iOS)
            // "Text clipped", an audit of iOS alone, on the labelled rule whose name is longer than the column: the
            // Rule contract draws a label on one line and truncates it at its end, and design-language/03 allows that
            // when the whole text is still read, which it is: the element's label is the whole name
            // (spec/components/rule, decisions/0002). Only this one label matches; it is `RuleLabelled.longName` in
            // capitals, which this target cannot import.
            suppressions += [
                Suppression(.entry("rule"), type: .textClipped, reason: "a rule's label truncated by its contract") {
                    $0 == "HOUSEHOLD ERRANDS, REPAIRS AND EVERYTHING FOR THE GARDEN"
                },
                // "Text clipped" on the chips with a long label in a narrow place, with an icon or text only, in
                // every form: the Chip contract draws its label
                // on one line and truncates it at its end (spec/components/chip, decisions/0001), and the element's
                // label is the whole name. Only this one label matches; it is `ChipSample.long`, which this target
                // cannot import.
                Suppression(.entry("chip"), type: .textClipped, reason: "a chip's label truncated by its contract") {
                    $0 == "A tag whose name runs much longer than its chip"
                },
                // No suppression for the selected ListRow samples: with the accessibility representation's title laid
                // out in the drawn font, body.strong while selected (decisions/0001, D4), the text clipped audit
                // reports neither the pressable nor the static selected sample, at the default settings or at
                // accessibility5 (measured on iOS 26, 2026-11-22). Before, the representation's regular title was
                // reported on the pressable one.
                // "Text clipped" on the long title of the sample at level 4, which the page sets on one line: the
                // ListRow contract truncates a title the product sets on one line at its end and keeps the whole
                // title as the row's name (spec/components/list-row, decisions/0001, Q3), which it is. Only this one
                // label matches; it is `ListRowSample.long`, which this target cannot import.
                Suppression(
                    .entry("list-row"), type: .textClipped,
                    reason: "a row's title on one line, truncated by its contract"
                ) {
                    $0 == "A list whose name runs much longer than the room its row leaves"
                },
                // "Text clipped" on the pressable chip the catalog holds pressed, in every configuration that runs the
                // text clipped audit (the default settings and accessibility5): the contract draws a pressed chip at
                // 0.98 of its size (`ChipTokens.pressScale`, design-language/05), and the audit reports the scaled
                // text as clipped. Measured on iOS 26.3, 2026-11-22: with the scale set to 1 the finding is gone, and
                // the text is whole in the page's screenshots at the default size and at accessibility5. A real press
                // draws the same scale, only while it lasts, when no audit runs. Two samples on the page carry the
                // label "pressed", both enabled: the pressable chip held pressed, which is reported, and the unlit
                // selectable chip held pressed, which is not, since its text is behind its accessibility
                // representation, the system toggle; the suppression matches both. The lit selectable sample is
                // "pressed, on", and every other chip is audited as usual.
                Suppression(
                    .entry("chip"), type: .textClipped, reason: "a pressed chip drawn at 0.98 of its size",
                    enabled: true
                ) { $0 == "pressed" },
                // "Text clipped" on the floating secondary before OS 26 that the catalog holds pressed, at the default
                // settings and at accessibility5: the contract draws a pressed Button at 0.98 of its size
                // (ButtonTokens.pressScale), and the audit measures the scaled text against its unscaled line; its
                // frame is 0.98 of the unpressed sample's (112.4 of 114.7 points). On glass the press is the glass's
                // own, not drawn scaled. Only that sample says "Pressed" (ButtonFloatingID), as Chip's says "pressed".
                Suppression(
                    .entry("button-floating-before-26"), type: .textClipped,
                    reason: "a pressed button drawn at 0.98 of its size", enabled: true
                ) { $0 == "Pressed" },
                // "Potentially inaccessible text" with no element on `button-floating-before-26` at the default
                // settings, on its second and last screenful, where the page's title and summary lie under the status
                // bar and its clock is drawn over them (the audit's own screenshot of the issue shows it). Measured on
                // iOS 26.3, 2026-11-23: it came in every run of the page (six); with the page's status bar hidden, in
                // neither of two; with only the page's loading section, or only its states, the page ends elsewhere
                // and it came in none of two runs each. It is the status bar's text over the page's, not a sample's:
                // the floating entries with glass did not report it in three runs (decisions/0015, "The catalog page,
                // split in four"). Only an issue with no element, in the light appearance, while a text of the page
                // reaches under the status bar, matches.
                Suppression(
                    .entry("button-floating-before-26"), type: .elementDetection,
                    reason: "the status bar's clock over the page's text", description: "Potentially inaccessible text",
                    appearance: .light, textUnderStatusBar: true
                ) { $0 == nil },
            ]
            // The TextField focus pages focus a field for real, so the system keyboard is up while they are audited
            // (spec/components/text-field). The keyboard's own prediction cells, empty or carrying a suggestion
            // (`“groceries”`, typographic quotes included, on the CI runner, #96), have no description, and at the
            // accessibility text sizes the keyboard covers the page's last line, its "Focused: …" text and its
            // "Clear focus" button, so the audit measures them on the keyboard's pixels. Neither is the entry's: the
            // fields are audited above the keyboard, and the same lines with no keyboard on `text-field-behavior`.
            // A prediction cell is told by its class, which the audit names in its detailed description, not by its
            // label, which is whatever the keyboard suggests; no westron view is a `TUIPredictionViewCell`.
            // The contrast suppression holds only while the keyboard is up and the line reaches below its top; the
            // same line above the keyboard, in any theme or text size, is audited as usual.
            for entryID in ["text-field-focus-framed", "text-field-focus-inline"] {
                suppressions += [
                    Suppression(
                        .entry(entryID), type: .sufficientElementDescription,
                        reason: "the system keyboard's prediction cell", detail: "TUIPredictionViewCell"
                    ) { _ in true },
                    Suppression(
                        .entry(entryID), type: .contrast, reason: "a line under the system keyboard",
                        underKeyboard: true
                    ) {
                        ($0?.hasPrefix("Focused: ") ?? false) || $0 == "Clear focus"
                    },
                ]
            }
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
