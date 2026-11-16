import WestronCatalog
import XCTest

/// The accessibility audit of every catalog entry (issue #25). It runs from `tools/apple/check.sh a11y`.
///
/// Each test is one configuration: it opens every entry of `Catalog.entries` in isolation, with that configuration's
/// launch arguments, and runs `performAccessibilityAudit` with the configuration's audit types. Every issue the audit
/// reports fails the test, except the ones in `suppressions`, each with its reason. A new entry is audited without
/// any change here.
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
        try audit(Configuration(arguments: ["-WestronAppearance", "light"], types: Configuration.allTypes))
    }

    /// The largest accessibility font size. Every audit type runs except `dynamicType`: the catalog pins this size in
    /// the view tree (`-WestronDynamicType`), so a text cannot follow the system size the audit sets, and the audit
    /// would report every text. `testDefaultSettings` runs the `dynamicType` audit with the system's size.
    @MainActor
    func testAccessibilityDynamicType() throws {
        try audit(
            Configuration(
                arguments: ["-WestronAppearance", "light", "-WestronDynamicType", "accessibility5"],
                types: Configuration.typesWithoutDynamicType))
    }

    /// Increased contrast, the `-hc` themes: only colors change, so the contrast audit runs.
    @MainActor
    func testIncreasedContrast() throws {
        try audit(
            Configuration(arguments: ["-WestronAppearance", "light", "-WestronContrast", "high"], types: .contrast))
    }

    /// The dark theme: only colors change, so the contrast audit runs.
    @MainActor
    func testDarkAppearance() throws {
        try audit(Configuration(arguments: ["-WestronAppearance", "dark"], types: .contrast))
    }

    /// The dark theme with increased contrast.
    @MainActor
    func testDarkIncreasedContrast() throws {
        try audit(
            Configuration(arguments: ["-WestronAppearance", "dark", "-WestronContrast", "high"], types: .contrast))
    }

    // MARK: - Running the audit

    struct Configuration {
        let arguments: [String]
        let types: XCUIAccessibilityAuditType

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

    @MainActor
    private func audit(entryID: String, _ configuration: Configuration) throws {
        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", entryID] + configuration.arguments
        app.launch()
        defer { app.terminate() }

        let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
        let problem = app.descendants(matching: .any)[CatalogAccessibilityID.problem]
        let appeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in entry.exists || problem.exists },
            object: nil
        )
        guard XCTWaiter.wait(for: [appeared], timeout: 30) == .completed else {
            XCTFail("\(entryID): the catalog did not render the entry within 30 s")
            return
        }
        if problem.exists {
            XCTFail("\(entryID): \(problem.label)")
            return
        }

        try app.performAccessibilityAudit(for: configuration.types) { issue in
            if let suppression = Self.suppressions.first(where: { $0.matches(issue, entryID: entryID) }) {
                print("a11y: suppressed in \(entryID): \(Self.describe(issue)) (\(suppression.reason))")
                return true
            }
            print("a11y: issue in \(entryID): \(Self.describe(issue))")
            return false
        }
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
        /// The entry it applies to; `nil` for every entry.
        let entryID: String?
        let type: XCUIAccessibilityAuditType
        let reason: String
        /// Tells the issue by its element's label; `nil` when the audit names no element.
        let label: @Sendable (String?) -> Bool

        func matches(_ issue: XCUIAccessibilityAuditIssue, entryID: String) -> Bool {
            guard self.entryID == nil || self.entryID == entryID, issue.auditType == type else { return false }
            return label(issue.element?.label)
        }
    }

    static let suppressions: [Suppression] = {
        var suppressions = [
            // "Label not human-readable" on a token name (`space.100`, `text.on-accent`, `color.background.*`).
            // The page shows the token by its name, and the label is the visible text, as it must be for Voice
            // Control; a spoken paraphrase would no longer match what is on screen.
            Suppression(entryID: nil, type: .sufficientElementDescription, reason: "a token name shown as written") {
                $0?.wholeMatch(of: #/[a-z][a-z0-9-]*(\.([a-z0-9-]+|\*))+/#) != nil
            },
            // "Contrast failed" on the layers of a shadow sample (`y 4 pt, blur 12 pt`): the sample casts its
            // shadow on its own caption, and that shadow is the token being shown. The caption's colors,
            // text.secondary on background.canvas, pass on their own (`tools/westron tokens contrast`).
            Suppression(entryID: "shape", type: .contrast, reason: "a shadow sample's caption under its own shadow") {
                $0?.wholeMatch(of: #/y [0-9.]+ pt, blur [0-9.]+ pt/#) != nil
            },
            // "Contrast nearly passed" with no element on the environment page, in the light themes: its four
            // section headers. The page is a system Form in the system's colors, not westron's; it is a utility
            // page that reports the launch conditions.
            Suppression(entryID: "environment", type: .contrast, reason: "a system Form in system colors") {
                $0 == nil
            },
            // "Contrast nearly passed" on the dash that stands for no delay in the motion table, in the light
            // themes. It is text.primary on background.canvas, the pair with the most contrast westron has; the
            // audit measures the pixels of a glyph that is a single thin stroke.
            Suppression(entryID: "motion", type: .contrast, reason: "a dash, a single thin stroke") { $0 == "–" },
        ]
        #if os(iOS)
            suppressions += [
                // "Dynamic Type font sizes are partially unsupported" on a row of the environment page. The page
                // is a system Form, a lazy list: when the audit changes the text size, the list makes its rows
                // again and the audit loses the row it measured. Every row is a LabeledContent in the system
                // font. The sample pages had the same issue in LazyVGrid and now lay out eagerly (AdaptiveGrid);
                // the utility page keeps the system Form.
                Suppression(entryID: "environment", type: .dynamicType, reason: "a row of a lazy system Form") {
                    _ in true
                },
                // "Text clipped" with no element on the background colors. It appeared when the page got its
                // layout for accessibility sizes, which puts a name on a line above its cells. The audit names no
                // element, so there is nothing to fix by; the same page at accessibility5 passes the text clipped
                // audit with an element for each text (testAccessibilityDynamicType), and its screenshot at
                // accessibility3 shows every label whole.
                Suppression(entryID: "color-backgrounds", type: .textClipped, reason: "an issue with no element") {
                    $0 == nil
                },
            ]
        #endif
        return suppressions
    }()
}
