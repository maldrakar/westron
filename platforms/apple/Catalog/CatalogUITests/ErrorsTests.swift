import XCTest

#if os(iOS)
    import UIKit
#endif

/// The pattern `spec/patterns/errors.md` on the catalog's `errors` entry (decisions/0018, stage 2): what assistive
/// technology meets in its status lines and in the system's alert, measured, and what the pattern promises: the
/// confirmation asks with the product's words, its destructive action does what it names, Cancel and Esc change
/// nothing, a status line's retry loads while it runs and the line stays while the failure does, and a line goes with
/// the person's next action.
final class ErrorsTests: XCTestCase {
    private var app: XCUIApplication!

    /// The samples' words, `ErrorsSample` and `ErrorsPageID` in WestronCatalog.
    private enum Sample {
        static let list = "Groceries"
        static let command = "Delete “Groceries”"
        static let question = "Delete “Groceries”?"
        static let message = "One list inside it goes with it. No task is deleted."
        static let action = "Delete"
        static let notLoaded = "The deployments could not be loaded."
        static let loaded = "3 deployments"
        static let retry = "Try again"
        static let notSaved = "The change could not be saved, so nothing was written."
        static let deleted = "Deleted “Groceries”"
        /// The page's identifier of the line that records the confirmation's action, `ErrorsPageID.last`.
        static let last = "westron.catalog.errors.last"
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
    private func launch(_ arguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "errors"] + arguments
        app.launch()
        XCTAssertTrue(app.buttons[Sample.retry].waitForExistence(timeout: 30), "the entry did not render")
    }

    /// The static texts that read `words`, as their label (iOS) or their value (macOS).
    @MainActor
    private func texts(_ words: String) -> XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", words, words))
    }

    /// The elements labelled `label`, of any type; on macOS a text's words are its value.
    @MainActor
    private func named(_ label: String) -> [XCUIElement] {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR value == %@", label, label))
            .allElementsBoundByIndex
    }

    /// The status line that reads `sentence`, of whatever type the hierarchy gives it.
    @MainActor
    private func line(_ sentence: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@ OR value == %@", sentence, sentence)
        ).firstMatch
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
            (.notEnabled, "notEnabled"), (.updatesFrequently, "updatesFrequently"),
        ]

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
            "errors: \(name): type \(element.elementType.rawValue), label \"\(element.label)\", "
            + "value \(String(describing: element.value)), enabled \(element.isEnabled), frame \(element.frame)"
        #if os(iOS)
            if let traits = traits(element) {
                let names = Self.traitNames.filter { traits & $0.0.rawValue != 0 }.map(\.1)
                text += ", traits \(names.joined(separator: " "))"
            }
        #endif
        return text
    }

    /// Prints and attaches the hierarchy of the app's windows, under `name`.
    @MainActor
    private func record(_ name: String) {
        let windows = app.debugDescription
        let hierarchy = XCTAttachment(string: windows)
        hierarchy.name = "errors-\(name)"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        for text in windows.split(separator: "\n") {
            print("errors: \(name): \(text)")
        }
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "errors-\(name)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    private func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    /// The system's alert that asks `Sample.question`, where it stands in the hierarchy: on iOS an alert; on macOS a
    /// sheet or a dialog, whichever the system makes of it.
    @MainActor
    private var confirmation: XCUIElement {
        #if os(macOS)
            let asks = NSPredicate(format: "label == %@ OR value == %@", Sample.question, Sample.question)
            let holders =
                app.sheets.allElementsBoundByIndex + app.dialogs.allElementsBoundByIndex
                + app.alerts.allElementsBoundByIndex
            return holders.first { $0.descendants(matching: .any).matching(asks).count > 0 }
                ?? app.sheets.firstMatch
        #else
            return app.alerts[Sample.question]
        #endif
    }

    /// Whether the alert is up within the timeout.
    @MainActor
    private func confirmationIsUp(timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if confirmation.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return false
    }

    /// Whether the alert is gone within the timeout.
    @MainActor
    private func confirmationIsGone(timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if !confirmation.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return false
    }

    /// Asks: the command that puts the confirmation up, and the alert up.
    @MainActor
    private func ask() {
        press(app.buttons[Sample.command])
        XCTAssertTrue(confirmationIsUp(), "the command did not put the confirmation up")
    }

    /// Whether the list is still there, and nothing recorded a delete.
    @MainActor
    private func assertNothingChanged(_ after: String) {
        XCTAssertTrue(texts(Sample.list).firstMatch.waitForExistence(timeout: 2), "\(after) took the list away")
        XCTAssertTrue(app.buttons[Sample.command].exists, "\(after) took the command away")
        XCTAssertFalse(app.staticTexts[Sample.last].exists, "\(after) recorded a delete")
    }

    /// Each part as assistive technology meets it: the status lines, their glyphs, the retry, the command that asks;
    /// and the alert, its title, its message and its two buttons. The hierarchies are printed and attached.
    @MainActor
    func testWhatAssistiveTechnologyMeets() {
        launch()
        record("page")
        for label in [Sample.notLoaded, Sample.notSaved, Sample.retry, Sample.command, Sample.list, "Deployments"] {
            for (index, element) in named(label).enumerated() {
                print(line("\(label) #\(index)", element))
            }
        }
        for (index, image) in app.images.allElementsBoundByIndex.enumerated() {
            print(line("image #\(index)", image))
        }

        // Each sentence is one element of its own, its glyph inside it; the glyph adds no element.
        for words in [Sample.notLoaded, Sample.notSaved, Sample.list] {
            XCTAssertEqual(named(words).count, 1, "not one element \"\(words)\"")
        }
        // No glyph is named. In the line inside the scroll view the glyph adds no element; in the line under it, outside
        // the scroll view, the decorative Icon is an unnamed image element on iOS (the pattern's G2, measured on
        // 2026-11-28): pinned, so that this fails when it goes, or when another comes.
        let images = app.images.allElementsBoundByIndex
        XCTAssertTrue(images.allSatisfy { $0.label.isEmpty }, "a glyph is named")
        #if os(iOS)
            XCTAssertEqual(
                images.count, 1, "not one unnamed image, the glyph of the line under the content: G2 changed")
            if let image = images.first {
                let under = line(Sample.notSaved).frame
                XCTAssertTrue(
                    image.frame.midY >= under.minY - 4 && image.frame.midY <= under.maxY,
                    "the unnamed image is not the glyph of the line under the content")
            }
        #else
            print("errors: images on macOS: \(images.count)")
        #endif
        // The retry is one button named by its words, after its sentence; the command names what it does, and to what.
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", Sample.retry)).count, 1)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", Sample.command)).count, 1)
        let sentence = named(Sample.notLoaded)[0].frame
        let retry = app.buttons[Sample.retry].frame
        XCTAssertLessThan(sentence.minX, retry.minX, "the retry does not come after its sentence")
        XCTAssertLessThan(
            named(Sample.notLoaded)[0].frame.maxY, named(Sample.notSaved)[0].frame.minY,
            "the line under the content is not under it")
        #if os(iOS)
            XCTAssertTrue(has(texts("Deployments").firstMatch, .header), "the section's title is not a heading")
            XCTAssertFalse(has(named(Sample.notLoaded)[0], .header), "the sentence is a heading")
            XCTAssertEqual(app.buttons[Sample.retry].frame.height, 36, accuracy: 0.5, "the retry is not size m")
        #endif

        ask()
        record("alert")
        let alert = confirmation
        print(line("the alert", alert))
        for (index, element) in alert.descendants(matching: .any).allElementsBoundByIndex.enumerated() {
            print(line("in the alert #\(index)", element))
        }
        // The title asks and the message says what goes and what stays; the two buttons are the verb and Cancel.
        XCTAssertTrue(
            alert.descendants(matching: .any).matching(
                NSPredicate(format: "label == %@ OR value == %@", Sample.message, Sample.message)
            ).count > 0, "the alert does not say what goes and what stays")
        XCTAssertTrue(alert.buttons[Sample.action].exists, "the alert has no button \(Sample.action)")
        XCTAssertTrue(alert.buttons["Cancel"].exists, "the alert has no button Cancel")
        XCTAssertEqual(alert.buttons.count, 2, "the alert does not hold exactly two buttons")
        press(alert.buttons["Cancel"])
        XCTAssertTrue(confirmationIsGone(), "Cancel did not take the alert away")
    }

    /// Cancel takes the question away and changes nothing.
    @MainActor
    func testCancelChangesNothing() {
        launch()
        ask()
        press(confirmation.buttons["Cancel"])
        XCTAssertTrue(confirmationIsGone(), "Cancel did not take the alert away")
        assertNothingChanged("Cancel")
        // The page still asks again, with the same words.
        ask()
        press(confirmation.buttons["Cancel"])
        XCTAssertTrue(confirmationIsGone())
        assertNothingChanged("a second Cancel")
    }

    /// The destructive action does what it names, once.
    @MainActor
    func testTheActionDoesWhatItNames() {
        launch()
        ask()
        press(confirmation.buttons[Sample.action])
        XCTAssertTrue(confirmationIsGone(), "Delete did not take the alert away")
        let last = app.staticTexts[Sample.last]
        XCTAssertTrue(last.waitForExistence(timeout: 5), "Delete did not run its action")
        XCTAssertEqual((last.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? last.label, Sample.deleted)
        XCTAssertFalse(texts(Sample.list).firstMatch.exists, "the list is still there")
        XCTAssertFalse(app.buttons[Sample.command].exists, "the command is still there")
    }

    #if os(macOS)
        /// The keys of the Mac's alert: Esc is Cancel and changes nothing; Return presses nothing, since the alert has
        /// no default button, so a Return meant for the screen never deletes (measured on macOS 27.2.1, 2026-11-28).
        @MainActor
        func testTheKeysOfTheAlert() {
            launch()
            ask()
            app.typeKey(.escape, modifierFlags: [])
            XCTAssertTrue(confirmationIsGone(), "Esc did not take the alert away")
            assertNothingChanged("Esc")

            ask()
            app.typeKey(.return, modifierFlags: [])
            let gone = confirmationIsGone(timeout: 3)
            let deleted = app.staticTexts[Sample.last].waitForExistence(timeout: 2)
            print("errors: Return in the alert: alert gone \(gone), the list deleted \(deleted)")
            XCTAssertFalse(gone, "Return took the alert away")
            XCTAssertFalse(deleted, "Return in the alert pressed Delete")
            // The alert still answers Esc after it.
            app.typeKey(.escape, modifierFlags: [])
            XCTAssertTrue(confirmationIsGone(), "Esc did not take the alert away after Return")
            assertNothingChanged("Return, then Esc")
        }
    #endif

    /// The retry loads while it runs; a retry that fails again leaves the line, and one that succeeds takes it away.
    @MainActor
    func testTryAgain() {
        launch()
        let retry = app.buttons[Sample.retry]
        press(retry)
        let loading = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Loading"), object: retry)
        XCTAssertEqual(
            XCTWaiter().wait(for: [loading], timeout: 2), .completed, "the retry does not load while it runs")
        print(line("the retry, running", retry))
        // The first try fails again: the line stays, and the button stops loading.
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value != %@", "Loading"), object: retry)
        XCTAssertEqual(XCTWaiter().wait(for: [done], timeout: 6), .completed, "the retry did not end")
        XCTAssertTrue(line(Sample.notLoaded).exists, "a retry that failed took the line away")
        XCTAssertFalse(texts(Sample.loaded).firstMatch.exists)
        // The second succeeds: the content takes the line's place.
        press(retry)
        XCTAssertTrue(texts(Sample.loaded).firstMatch.waitForExistence(timeout: 6), "the retry did not succeed")
        XCTAssertFalse(line(Sample.notLoaded).exists, "the line stays after the retry succeeded")
        XCTAssertFalse(app.buttons[Sample.retry].exists, "the retry stays after it succeeded")
    }

    /// The line under the content stands until the person's next action on the page.
    @MainActor
    func testTheLineGoesWithTheNextAction() {
        launch()
        XCTAssertTrue(line(Sample.notSaved).exists, "the line is not there as the page appears")
        ask()
        press(confirmation.buttons["Cancel"])
        XCTAssertTrue(confirmationIsGone())
        XCTAssertFalse(line(Sample.notSaved).exists, "the next action did not take the line away")
    }
}
