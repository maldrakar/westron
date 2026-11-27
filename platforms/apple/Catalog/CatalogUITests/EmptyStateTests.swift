import XCTest

#if os(iOS)
    import UIKit
#endif

/// The pattern `spec/patterns/empty-state.md` on the catalog's `empty-state` entry (decisions/0018, stage 2): what
/// assistive technology meets in the system's `ContentUnavailableView` with westron's tile, words and action, measured,
/// and a press on the action.
final class EmptyStateTests: XCTestCase {
    private var app: XCUIApplication!

    /// The samples' words, `EmptyStateSample` in WestronCatalog.
    private enum Sample {
        static let titles = ["Nothing here yet", "No tasks tagged #home", "No deployments yet"]
        static let messages = [
            "Add a task here, or drag one in.", "Clear the filter to see every task.",
            "Each deployment of this service will show up here.",
        ]
        static let action = "Deploy"
        /// The page's identifier of the press count, `EmptyStatePageID.presses`.
        static let presses = "westron.catalog.empty-state.presses"
    }

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = true
    }

    @MainActor
    override func tearDown() async throws {
        app?.terminate()
    }

    @MainActor
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "empty-state"]
        app.launch()
        XCTAssertTrue(app.buttons[Sample.action].waitForExistence(timeout: 30), "the entry did not render")
    }

    /// The elements labelled `label`, of any type, on iOS; on macOS a text's words are its value.
    @MainActor
    private func named(_ label: String) -> [XCUIElement] {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR value == %@", label, label))
            .allElementsBoundByIndex
    }

    /// The accessibility traits of the element, as the hierarchy's snapshot holds them (iOS); nil where it holds none.
    @MainActor
    private func traits(_ element: XCUIElement) -> UInt64? {
        guard let snapshot = (try? element.snapshot()) as? NSObject,
            snapshot.responds(to: NSSelectorFromString("traits"))
        else { return nil }
        return (snapshot.value(forKey: "traits") as? NSNumber)?.uint64Value
    }

    #if os(iOS)
        /// The UIKit traits named in `traits`, for the log.
        private static let traitNames: [(UIAccessibilityTraits, String)] = [
            (.button, "button"), (.header, "header"), (.staticText, "staticText"), (.image, "image"),
            (.notEnabled, "notEnabled"),
        ]

        /// Whether the element's traits hold `trait`.
        @MainActor
        private func has(_ element: XCUIElement, _ trait: UIAccessibilityTraits) -> Bool {
            guard let traits = traits(element) else {
                XCTFail("the hierarchy's snapshot holds no traits for \(element): the measure is blind")
                return false
            }
            return traits & trait.rawValue != 0
        }
    #endif

    /// One line of what the hierarchy holds for an element, printed for the report.
    @MainActor
    private func line(_ name: String, _ element: XCUIElement) -> String {
        var text =
            "empty-state: \(name): type \(element.elementType.rawValue), label \"\(element.label)\", "
            + "value \(String(describing: element.value)), enabled \(element.isEnabled), frame \(element.frame)"
        #if os(iOS)
            if let traits = traits(element) {
                let names = Self.traitNames.filter { traits & $0.0.rawValue != 0 }.map(\.1)
                text += ", traits \(names.joined(separator: " "))"
            }
        #endif
        return text
    }

    /// Each part as assistive technology meets it: the title, the message, the tile, the action. The hierarchy is
    /// printed and attached.
    @MainActor
    func testWhatAssistiveTechnologyMeets() {
        launch()
        let windows = app.windows.allElementsBoundByIndex.map(\.debugDescription).joined(separator: "\n")
        let hierarchy = XCTAttachment(string: windows)
        hierarchy.name = "empty-state-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        for text in windows.split(separator: "\n") {
            print("empty-state: hierarchy: \(text)")
        }
        for label in Sample.titles + Sample.messages + [Sample.action] {
            for (index, element) in named(label).enumerated() {
                print(line("\(label) #\(index)", element))
            }
        }
        for (index, image) in app.images.allElementsBoundByIndex.enumerated() {
            print(line("image #\(index)", image))
        }

        // The title and the message are each a text of their own, in reading order; the action one button named by
        // its words.
        for words in Sample.titles + Sample.messages {
            let texts = app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", words, words))
            XCTAssertEqual(texts.count, 1, "not one text \"\(words)\"")
        }
        let buttons = app.buttons.matching(NSPredicate(format: "label == %@", Sample.action))
        XCTAssertEqual(buttons.count, 1, "not one button \(Sample.action)")
        // The tiles are decorative: no image carries a name.
        XCTAssertEqual(
            app.images.allElementsBoundByIndex.filter { !$0.label.isEmpty }.count, 0, "an image carries a name")
        let firstTitle = app.staticTexts[Sample.titles[0]].frame
        let firstMessage = app.staticTexts[Sample.messages[0]].frame
        XCTAssertLessThan(firstTitle.minY, firstMessage.minY, "the title does not come before the message")
        #if os(iOS)
            for title in Sample.titles {
                print("empty-state: \(title) is a heading: \(has(app.staticTexts[title], .header))")
            }
            XCTAssertTrue(has(buttons.firstMatch, .button))
        #endif
    }

    @MainActor
    private func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    /// A press on the action runs it once.
    @MainActor
    func testThePressRunsTheAction() {
        launch()
        XCTAssertFalse(app.staticTexts[Sample.presses].exists, "the count shows before a press")
        press(app.buttons[Sample.action])
        let count = app.staticTexts[Sample.presses]
        XCTAssertTrue(count.waitForExistence(timeout: 5), "the press did not run the action")
        let words = (count.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? count.label
        XCTAssertEqual(words, "Pressed 1 times")
    }
}
