import XCTest

/// Скриншот одной записи каталога. Запускается из `tools/apple/catalog-screenshot.sh`,
/// который передаёт параметры через переменные окружения `TEST_RUNNER_WESTRON_*`:
///
/// - `WESTRON_OUTPUT` — путь к PNG (обязателен; без него тест пропускается);
/// - `WESTRON_ENTRY` — id записи, по умолчанию `environment`;
/// - `WESTRON_APPEARANCE` — `light` или `dark`;
/// - `WESTRON_DYNAMIC_TYPE` — размер шрифта, как у `-WestronDynamicType`.
///
/// Скриншот снимает раннер XCTest, поэтому на macOS не нужно разрешение на запись экрана.
final class CatalogScreenshotTests: XCTestCase {
    /// Должно совпадать с `CatalogAccessibilityID` в WestronCatalog.
    private static let entryID = "westron.catalog.entry"
    private static let problemID = "westron.catalog.problem"
    /// Пауза после появления записи: даёт завершиться раскладке и первой анимации.
    private static let settleDelay: TimeInterval = 0.6

    @MainActor
    func testScreenshot() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let output = environment["WESTRON_OUTPUT"] else {
            throw XCTSkip("WESTRON_OUTPUT не задан: тест запускает tools/apple/catalog-screenshot.sh")
        }

        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", environment["WESTRON_ENTRY"] ?? "environment"]
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
        XCTAssertEqual(XCTWaiter.wait(for: [appeared], timeout: 30), .completed, "каталог не отрисовал запись за 30 с")
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
        let url = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try screenshot.pngRepresentation.write(to: url)
    }
}
