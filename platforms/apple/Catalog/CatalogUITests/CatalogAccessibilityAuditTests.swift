import WestronCatalog
import XCTest

/// The accessibility audit of every catalog entry (issue #25). It runs from `tools/apple/check.sh a11y`.
///
/// Each test is one configuration: it opens every entry of `Catalog.entries` in isolation, with that configuration's
/// launch arguments, and runs `performAccessibilityAudit` with the configuration's audit types on every screenful of
/// the page, scrolling down to its end. Every issue the audit reports fails the test, except the ones in
/// `suppressions`, each with its reason. A new entry is audited without any change here.
final class CatalogAccessibilityAuditTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // One entry's issues must not hide the next entry's.
        continueAfterFailure = true
    }

    /// The default: the system's font size, the light theme, standard contrast. Every audit type runs. The theme is
    /// set, not left to the simulator, so the run does not depend on the machine.
    @MainActor
    func testDefaultSettings() throws {
        try audit(Configuration(appearance: .light, types: Configuration.allTypes, scrolls: true))
    }

    /// The largest accessibility font size. Every audit type runs except `dynamicType`: the catalog pins this size in
    /// the view tree (`-WestronDynamicType`), so a text cannot follow the system size the audit sets, and the audit
    /// would report every text. `testDefaultSettings` runs the `dynamicType` audit with the system's size.
    @MainActor
    func testAccessibilityDynamicType() throws {
        try audit(
            Configuration(
                appearance: .light, dynamicType: "accessibility5", types: Configuration.typesWithoutDynamicType,
                scrolls: true))
    }

    /// Increased contrast, the `-hc` themes: only colors change, so the contrast audit runs. Like the other theme
    /// tests, it audits the first screenful only: the pages are laid out to fit one at the default text size, and
    /// scrolling every page in every theme would make the run longer than its worth.
    @MainActor
    func testIncreasedContrast() throws {
        try audit(Configuration(appearance: .light, increasedContrast: true, types: .contrast))
    }

    /// The dark theme: only colors change, so the contrast audit runs.
    @MainActor
    func testDarkAppearance() throws {
        try audit(Configuration(appearance: .dark, types: .contrast))
    }

    /// The dark theme with increased contrast.
    @MainActor
    func testDarkIncreasedContrast() throws {
        try audit(Configuration(appearance: .dark, increasedContrast: true, types: .contrast))
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
        /// Whether the page is audited down to its end, a screenful at a time, or on its first screenful only.
        var scrolls = false

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

    /// The most screenfuls a page is audited in; a page that does not end by then fails.
    private static let maxScreens = 30
    /// How long a page has to stay still to count as settled, and how long it may take.
    private static let stillInterval: TimeInterval = 0.25
    private static let settleTimeout: TimeInterval = 5

    @MainActor
    private func audit(_ configuration: Configuration) throws {
        // WESTRON_ENTRY narrows the run to one entry while its issues are being fixed.
        let entries = ProcessInfo.processInfo.environment["WESTRON_ENTRY"].map { [$0] } ?? Catalog.entries.map(\.id)
        XCTAssertFalse(entries.isEmpty, "the catalog registry has no entries")
        for entryID in entries {
            try XCTContext.runActivity(named: "\(entryID) \(configuration.arguments.joined(separator: " "))") { _ in
                try audit(entryID: entryID, configuration)
            }
        }
    }

    /// The audit types that change the system's text size to see how the page follows it. After them the page's
    /// accessibility tree and its pixels disagree for a while, so they run on a fresh launch, last (see below).
    #if os(iOS)
        private static let sizeChangingTypes: XCUIAccessibilityAuditType = [.dynamicType, .textClipped]
    #else
        private static let sizeChangingTypes: XCUIAccessibilityAuditType = []
    #endif

    /// Audits an entry a screenful at a time, down to the end of the page: the audit sees only what is on screen.
    ///
    /// The audit types that change the text size go in a pass of their own when the configuration lets the system's
    /// size reach the page (`testDefaultSettings`): one fresh launch per screenful, scrolled to it. Where the catalog
    /// pins the size, they do not move the page and run with the rest.
    @MainActor
    private func audit(entryID: String, _ configuration: Configuration) throws {
        let separate =
            configuration.dynamicType == nil ? configuration.types.intersection(Self.sizeChangingTypes) : []
        guard let screens = try auditScreens(entryID, configuration, types: configuration.types.subtracting(separate))
        else { return }
        guard !separate.isEmpty else { return }
        for screen in 1...screens {
            guard let (app, entry) = launch(entryID, configuration) else { return }
            defer { app.terminate() }
            for _ in 1..<screen {
                scrollDown(entry)
                settle(entry)
            }
            try auditScreen(app, entryID, configuration, types: separate, screen: screen)
        }
    }

    /// Launches the catalog on the entry; `nil` after a failure when it does not show.
    @MainActor
    private func launch(_ entryID: String, _ configuration: Configuration) -> (XCUIApplication, XCUIElement)? {
        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", entryID] + configuration.arguments
        app.launch()

        let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
        let problem = app.descendants(matching: .any)[CatalogAccessibilityID.problem]
        let appeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in entry.exists || problem.exists },
            object: nil
        )
        guard XCTWaiter.wait(for: [appeared], timeout: 30) == .completed else {
            XCTFail("\(entryID): the catalog did not render the entry within 30 s")
            app.terminate()
            return nil
        }
        if problem.exists {
            XCTFail("\(entryID): \(problem.label)")
            app.terminate()
            return nil
        }
        settle(entry)
        return (app, entry)
    }

    /// Audits every screenful of the page with the types given, and returns how many screenfuls the page has.
    @MainActor
    private func auditScreens(
        _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType
    ) throws -> Int? {
        guard let (app, entry) = launch(entryID, configuration) else { return nil }
        defer { app.terminate() }
        for screen in 1...Self.maxScreens {
            try auditScreen(app, entryID, configuration, types: types, screen: screen)
            guard configuration.scrolls else { return 1 }
            // The end is where a scroll no longer moves the page. It is told by where the page's first text is, not
            // by a picture: the scroll indicator shows after every drag, at the end of the page too.
            let before = scrollPosition(entry)
            scrollDown(entry)
            settle(entry)
            if scrollPosition(entry) == before { return screen }
        }
        XCTFail("\(entryID): the page did not end within \(Self.maxScreens) screenfuls")
        return Self.maxScreens
    }

    @MainActor
    private func auditScreen(
        _ app: XCUIApplication, _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType,
        screen: Int
    ) throws {
        guard !types.isEmpty else { return }
        // An audit now and then gives up ("Audit failed to complete in time"): it is run once more, and if it fails
        // again the entry fails, but the run goes on to the next entry.
        do {
            try performAudit(app, entryID, configuration, types: types, screen: screen)
        } catch {
            print("a11y: audit of \(entryID), screen \(screen) did not complete (\(error)); running it again")
            do {
                try performAudit(app, entryID, configuration, types: types, screen: screen)
            } catch {
                XCTFail("\(entryID), screen \(screen): the audit did not complete: \(error)")
            }
        }
    }

    @MainActor
    private func performAudit(
        _ app: XCUIApplication, _ entryID: String, _ configuration: Configuration, types: XCUIAccessibilityAuditType,
        screen: Int
    ) throws {
        try app.performAccessibilityAudit(for: types) { issue in
            if let suppression = Self.suppressions.first(where: {
                $0.matches(issue, entryID: entryID, configuration: configuration)
            }) {
                print("a11y: suppressed in \(entryID): \(Self.describe(issue)) (\(suppression.reason))")
                return true
            }
            print("a11y: issue in \(entryID), screen \(screen): \(Self.describe(issue))")
            return false
        }
    }

    /// Waits until two pictures of the entry in a row are the same: the layout and its animations have finished, the
    /// scroll has stopped. Returns the last picture.
    @MainActor
    @discardableResult
    private func settle(_ entry: XCUIElement) -> Data {
        var previous = entry.screenshot().pngRepresentation
        let deadline = Date().addingTimeInterval(Self.settleTimeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: Self.stillInterval)
            let current = entry.screenshot().pngRepresentation
            if current == previous { return current }
            previous = current
        }
        return previous
    }

    /// Where the page's first text is on screen: it moves when the page scrolls.
    @MainActor
    private func scrollPosition(_ entry: XCUIElement) -> CGRect {
        entry.descendants(matching: .staticText).firstMatch.frame
    }

    /// Scrolls the page by most of a screen, so that consecutive screenfuls overlap, without momentum.
    @MainActor
    private func scrollDown(_ entry: XCUIElement) {
        #if os(iOS)
            let start = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            let end = entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.2)
        #else
            entry.scroll(byDeltaX: 0, deltaY: -entry.frame.height * 0.65)
        #endif
    }

    private static func describe(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let element =
            issue.element.map { "\($0.elementType.rawValue) \"\($0.label)\" [\($0.identifier)]" } ?? "no element"
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
        /// Tells the issue by its element's label; `nil` when the audit names no element.
        let label: @Sendable (String?) -> Bool

        init(
            _ scope: Scope, type: XCUIAccessibilityAuditType, reason: String, description: String? = nil,
            appearance: Configuration.Appearance? = nil, value: String? = nil,
            label: @escaping @Sendable (String?) -> Bool
        ) {
            self.scope = scope
            self.type = type
            self.reason = reason
            self.description = description
            self.appearance = appearance
            self.value = value
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
