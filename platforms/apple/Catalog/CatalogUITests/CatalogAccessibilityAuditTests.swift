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
        // An audit now and then gives up ("Audit failed to complete in time", -56): it is run once more, for a stalled
        // simulator. One that gives up twice is moved by a few points (`auditMoved`): the contrast audit gives up at
        // some scroll positions every time, and a point away from one it completes (#127).
        do {
            return try performAudit(app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
        } catch {
            print("a11y: retrying the audit of \(entryID), screen \(screen): it did not complete (\(error))")
            do {
                return try performAudit(app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag)
            } catch {
                #if os(iOS)
                    return auditMoved(
                        app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag, error: error)
                #else
                    XCTFail(
                        "\(Self.infrastructurePrefix)\(entryID), screen \(screen): the audit did not complete: \(error)"
                    )
                    return []
                #endif
            }
        }
    }

    #if os(iOS)
        /// How far `auditMoved` asks a drag to move the page. A slow drag moves it about 10 pt less (the touch slop):
        /// measured on 2026-11-24, 17.5 pt asked moved it 7.3 pt. Far enough to leave a position where the audit gives
        /// up (about a point wide, #127), and short of the page's margin (`space.200`, 16 pt) and of `dragMargin`.
        private static let moveDistance: CGFloat = 20
        /// The least move that counts: a drag that moved the page less did not leave the position.
        private static let leastMove: CGFloat = 1

        /// Audits a screenful whose audit gave up twice where the page is, at position P, with the page moved by a few
        /// points: on 2026-11-24 the contrast audit of `list-row` at accessibility5 gave up at screen 14 on every try,
        /// and completed in 0.36 s with the page 7 pt further; a page of its rows alone gave up with one row's top at
        /// 15 pt on screen and completed at 14 and 16 pt, even with every row transparent, so the position decides,
        /// not the pixels (#127).
        ///
        /// A moved audit sees the screenful less a strip at one edge, so the test works out which of the elements that
        /// P showed whole it did not see whole, and the screenful passes only when every one of them is seen whole by
        /// another audit:
        /// - the page is first moved on by f points (`moveDistance`, measured), which scrolls a strip of f points off
        ///   the top. An element that P showed whole is seen whole moved on unless it starts in that strip;
        /// - an element in the strip was seen whole on the screenful before, when there is one (the drags of
        ///   `auditScreens`, from screen 2) and it showed the element whole: the drag between them is `nextDrag`, give
        ///   or take `dragMargin`, and since f is less than `dragMargin`, no element in the strip was deferred to this
        ///   screenful (`cutByBottom`). Screen 1, and every window of the Dynamic Type pass, has none;
        /// - for what is still not seen whole, the page is moved back to b points before P, which scrolls a strip of b
        ///   points off the bottom: an element is seen whole there unless it ends in that strip.
        /// The elements are the page's, from one snapshot of the tree at P (`pageElements`), less those that stay put
        /// when the page moves (`moving`).
        /// Elements the edges of P cut are judged as on any screenful: the one before showed the ones at the top whole,
        /// and the ones at the bottom are deferred to the next. The issues deferred to the next screenful are the last
        /// audit's, which the next drag starts from. When the moved audits do not see every element whole (the top of
        /// a page whose first element starts within f points of it, the bottom of the last screenful, an audit that
        /// gives up again), the entry fails for infrastructure, naming the elements; `tools/apple/check.sh a11y` then
        /// audits it again in a run of its own, and the run goes on to the next entry.
        @MainActor
        private func auditMoved(
            _ app: XCUIApplication, _ entryID: String, _ configuration: Configuration,
            types: XCUIAccessibilityAuditType, screen: Int, nextDrag: CGFloat?, error: Error
        ) -> [String] {
            let place = "\(entryID), screen \(screen)"
            let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
            guard entry.exists else {
                XCTFail("\(Self.infrastructurePrefix)\(place): the audit did not complete: \(error)")
                return []
            }
            let visible = visibleArea(app)
            let atP = pageElements(entry)
            // The elements P showed whole, which some audit must see whole.
            var unseen = atP.filter { $0.frame.minY >= visible.minY && $0.frame.maxY <= visible.maxY }
            var deferred: [String]?
            var tried: [String] = []

            // Moved on: a strip of f points off the top.
            nudge(entry, by: Self.moveDistance)
            settle(entry, entryID, screen: screen)
            let afterForward = pageElements(entry)
            let forward = Self.shift(from: atP, to: afterForward)
            unseen = Self.moving(unseen, after: afterForward, shift: forward)
            let whole = unseen.count
            var seenBefore = 0
            if forward >= Self.leastMove {
                let label = String(format: "moved on by %.1f pt", forward)
                if let issues = try? performAudit(
                    app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag, moved: label)
                {
                    deferred = issues
                    unseen.removeAll { $0.frame.minY - forward >= visible.minY }
                    tried.append("\(label): completed")
                    if let nextDrag, screen > 1, forward < Self.dragMargin {
                        let count = unseen.count
                        unseen.removeAll { $0.frame.maxY + nextDrag + Self.dragMargin <= visible.maxY }
                        seenBefore = count - unseen.count
                    }
                } else {
                    tried.append("\(label): gave up again")
                }
            } else {
                tried.append(String(format: "moved on by %.1f pt: the page did not move", forward))
            }

            // Moved back: a strip of b points off the bottom, for what is still not seen whole.
            if !unseen.isEmpty {
                nudge(entry, by: -(max(forward, 0) + Self.moveDistance))
                settle(entry, entryID, screen: screen)
                let afterBackward = pageElements(entry)
                let backward = -Self.shift(from: atP, to: afterBackward)
                unseen = Self.moving(unseen, after: afterBackward, shift: backward)
                let label = String(format: "moved back by %.1f pt", backward)
                if backward >= Self.leastMove {
                    if let issues = try? performAudit(
                        app, entryID, configuration, types: types, screen: screen, nextDrag: nextDrag, moved: label)
                    {
                        deferred = issues
                        unseen.removeAll { $0.frame.maxY + backward <= visible.maxY }
                        tried.append("\(label): completed")
                    } else {
                        tried.append("\(label): gave up again")
                    }
                } else {
                    tried.append(String(format: "moved back by %.1f pt: the page did not move", backward))
                }
            }

            guard unseen.isEmpty, let deferred else {
                let names = unseen.map(\.description).joined(separator: "; ")
                XCTFail(
                    "\(Self.infrastructurePrefix)\(place): the audit did not complete (\(error)), and moved, it did "
                        + "not see the whole screenful (\(tried.joined(separator: ", "))); not audited: "
                        + (names.isEmpty ? "the screenful" : names))
                return []
            }
            print(
                "a11y: \(place): audited whole with the page moved (\(tried.joined(separator: ", "))): of the "
                    + "\(whole) elements it showed whole, \(whole - seenBefore) were seen whole by a moved audit and "
                    + "\(seenBefore) at the top by the screenful before")
            return deferred
        }

        /// An element of the page, for `auditMoved`: what tells it apart, and its frame.
        struct PageElement: CustomStringConvertible {
            let type: XCUIElement.ElementType
            let label: String
            let identifier: String
            let frame: CGRect

            /// The same element after a move: everything but where it is.
            var key: String { "\(type.rawValue)|\(label)|\(identifier)|\(frame.minX)|\(frame.width)|\(frame.height)" }
            var description: String { "\(type.rawValue) \"\(label)\" [\(identifier)] at \(frame)" }
        }

        /// The kinds of element that only hold others: the audit judges what is in them.
        private static let containerTypes: Set<XCUIElement.ElementType> = [
            .any, .application, .window, .scrollView, .table, .collectionView, .group,
        ]

        /// The page's elements that the audit judges, from one snapshot of the entry's tree: every element with a
        /// frame, a control with its texts as well as the texts, but not a container, nor an `other` with no label
        /// (a stack's group, a guide's line).
        @MainActor
        private func pageElements(_ entry: XCUIElement) -> [PageElement] {
            guard let root = try? entry.snapshot() else { return [] }
            var elements: [PageElement] = []
            func walk(_ snapshot: XCUIElementSnapshot) {
                if !snapshot.frame.isEmpty, !Self.containerTypes.contains(snapshot.elementType),
                    snapshot.elementType != .other || !snapshot.label.isEmpty
                {
                    elements.append(
                        PageElement(
                            type: snapshot.elementType, label: snapshot.label, identifier: snapshot.identifier,
                            frame: snapshot.frame))
                }
                snapshot.children.forEach(walk)
            }
            root.children.forEach(walk)
            return elements
        }

        /// The elements that moved with the page between two snapshots, by `shift` points: not the system's scroll
        /// indicator, which stays where it is, and is not the page's to audit.
        static func moving(_ elements: [PageElement], after: [PageElement], shift: CGFloat) -> [PageElement] {
            guard abs(shift) >= leastMove else { return elements }
            let stationary = Set(after.map { "\($0.key)|\($0.frame.minY)" })
            return elements.filter { !stationary.contains("\($0.key)|\($0.frame.minY)") }
        }

        /// How far the page moved on between two snapshots, in points (negative when it moved back): the move most of
        /// the elements found in both made, so that an element that moved by itself or came and went does not count.
        static func shift(from before: [PageElement], to after: [PageElement]) -> CGFloat {
            let afterByKey = Dictionary(after.map { ($0.key, [$0]) }, uniquingKeysWith: +)
            var moves: [CGFloat: Int] = [:]
            for element in before {
                guard let match = afterByKey[element.key], match.count == 1 else { continue }
                // To a third of a point, the iPhone's pixel.
                let move = ((element.frame.minY - match[0].frame.minY) * 3).rounded() / 3
                moves[move, default: 0] += 1
            }
            return moves.max { $0.value < $1.value || ($0.value == $1.value && abs($0.key) > abs($1.key)) }?.key ?? 0
        }
    #endif

    @MainActor
    private func performAudit(
        _ app: XCUIApplication, _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType,
        screen: Int, nextDrag: CGFloat?, moved: String? = nil
    ) throws -> [String] {
        let visible = visibleArea(app)
        var deferred: [String] = []
        // Each audit's time, for the audits that give up (#127): one that completes takes 0.2–3.5 s, one that gives
        // up 15 s.
        let started = Date()
        var outcome = "gave up"
        defer {
            print(
                "a11y: \(entryID), screen \(screen)\(moved.map { ", \($0)" } ?? ""): audit \(outcome) in "
                    + String(format: "%.2f s", Date().timeIntervalSince(started)))
        }
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
        outcome = "completed"
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
        /// Drags the page slowly by `distance` points from the middle of the entry, without momentum: up for a positive
        /// distance, which moves the page on, down for a negative one. The page moves by less (`moveDistance`).
        @MainActor
        private func nudge(_ entry: XCUIElement, by distance: CGFloat) {
            let height = max(entry.frame.height, 1)
            let from = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let to = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5 - distance / height))
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
        /// The element's type it must have, if any.
        var elementType: XCUIElement.ElementType? = nil
        /// The widest the element's frame may be, if that matters: a control's cell, not a row with the same name.
        var maxWidth: CGFloat? = nil
        /// Tells the issue by its element's label; `nil` when the audit names no element.
        let label: @Sendable (String?) -> Bool

        init(
            _ scope: Scope, type: XCUIAccessibilityAuditType, reason: String, description: String? = nil,
            appearance: Configuration.Appearance? = nil, value: String? = nil, enabled: Bool? = nil,
            detail: String? = nil, underKeyboard: Bool = false, elementType: XCUIElement.ElementType? = nil,
            maxWidth: CGFloat? = nil, label: @escaping @Sendable (String?) -> Bool
        ) {
            self.elementType = elementType
            self.maxWidth = maxWidth
            self.scope = scope
            self.type = type
            self.reason = reason
            self.description = description
            self.appearance = appearance
            self.value = value
            self.enabled = enabled
            self.detail = detail
            self.underKeyboard = underKeyboard
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
            if let elementType, issue.element?.elementType != elementType { return false }
            if let maxWidth, (issue.element?.frame.width ?? .infinity) > maxWidth { return false }
            if underKeyboard {
                let keyboard = XCUIApplication().keyboards.firstMatch
                guard keyboard.exists, let frame = issue.element?.frame, !frame.isEmpty,
                    frame.maxY > keyboard.frame.minY
                else { return false }
            }
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
            // The Disclosure chevron's cell (#120) on iOS: its accessibility representation is the system's Button on
            // the group's label, named by the label's words or a ListRow's title, laid out in the cell's frame, which
            // is what the system's own disclosure group is on iOS (spec/components/disclosure, decisions/0001,
            // "Measured"). Those words are drawn beside the cell, in the label; in the cell's frame only the chevron
            // is drawn. So the audit reports the button's text as clipped, and measures the chevron, a non-text glyph
            // held to 3:1 by color.icon.tertiary's declared pairs on the canvas and the hover and pressed tints
            // (`tools/westron tokens contrast`), as text held to 4.5:1. Only a button no wider than the cell (44 pt,
            // 44.3 at accessibility5) with one of the pages' cell names matches: the rows and labels with the same
            // words are a StaticText, or a Button as wide as the row, and are audited as usual.
            for (entryID, names) in [
                ("disclosure", ["rest", "hover", "focus", "pressed", "disabled", "Work", "Projects", "Archive"]),
                ("list-row", ["Work", "Projects"]),
            ] {
                suppressions += [
                    Suppression(
                        .entry(entryID), type: .contrast, reason: "the chevron's cell, a glyph named by its label",
                        elementType: .button, maxWidth: 48
                    ) { names.contains($0 ?? "") },
                    Suppression(
                        .entry(entryID), type: .textClipped,
                        reason: "the chevron's cell, named by words drawn beside it",
                        elementType: .button, maxWidth: 48
                    ) { names.contains($0 ?? "") },
                ]
            }
            // "Dynamic Type font sizes are partially unsupported" on a leaf's title, "Someday", in the tree that the
            // disclosure page puts in a system List: the Disclosure contract promises nothing inside a List
            // (decisions/0001, Q5), and the same row outside the List, "Home" on the same page, passes. The List's
            // tree names that leaf apart (`DisclosureNode.listTree`), so that nothing outside the List is suppressed.
            suppressions += [
                Suppression(
                    .entry("disclosure"), type: .dynamicType, reason: "a row in a system List, which Q5 leaves out"
                ) { $0 == "Someday" }
            ]
        #endif
        return suppressions
    }()
}
