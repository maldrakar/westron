import XCTest

/// A screenshot of one catalog entry. It runs from `tools/apple/catalog-screenshot.sh`,
/// which passes parameters through the `TEST_RUNNER_WESTRON_*` environment variables:
///
/// - `WESTRON_ENTRY`: the entry id (required; without it the test is skipped);
/// - `WESTRON_APPEARANCE`: `light` or `dark`;
/// - `WESTRON_DYNAMIC_TYPE`: the font size, as for `-WestronDynamicType`.
///
/// The XCTest runner takes the screenshot, so macOS needs no screen recording permission.
/// The runner writes no file: on macOS it is sandboxed without write access. The PNG goes as an attachment
/// into the test result, and the script extracts it from `.xcresult`.
final class CatalogScreenshotTests: XCTestCase {
    /// Must match `CatalogAccessibilityID` in WestronCatalog.
    private static let entryID = "westron.catalog.entry"
    private static let problemID = "westron.catalog.problem"
    /// The attachment name; the script finds the PNG in `.xcresult` by it.
    private static let attachmentName = "westron-screenshot"
    /// A pause after the entry appears: it lets layout and the first animation finish.
    private static let settleDelay: TimeInterval = 0.6

    @MainActor
    func testScreenshot() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let entryID = environment["WESTRON_ENTRY"] else {
            throw XCTSkip("WESTRON_ENTRY is not set: tools/apple/catalog-screenshot.sh runs this test")
        }

        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", entryID]
        if let appearance = environment["WESTRON_APPEARANCE"] {
            app.launchArguments += ["-WestronAppearance", appearance]
        }
        if let size = environment["WESTRON_DYNAMIC_TYPE"] {
            app.launchArguments += ["-WestronDynamicType", size]
        }
        app.launch()
        defer { app.terminate() }

        let entry = app.descendants(matching: .any)[Self.entryID]
        let problem = app.descendants(matching: .any)[Self.problemID]
        let appeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in entry.exists || problem.exists },
            object: nil
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [appeared], timeout: 30), .completed, "the catalog did not render the entry within 30 s"
        )
        if problem.exists {
            XCTFail(problem.label)
            return
        }
        Thread.sleep(forTimeInterval: Self.settleDelay)

        #if os(macOS)
            let screenshot = app.windows.firstMatch.screenshot()
        #else
            let screenshot = XCUIScreen.main.screenshot()
        #endif
        let attachment = XCTAttachment(data: screenshot.pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = Self.attachmentName
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
