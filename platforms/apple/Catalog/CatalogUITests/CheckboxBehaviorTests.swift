import XCTest

/// Checkbox's behavior that a unit test cannot reach, on the catalog's `checkbox` entry: what assistive technology meets
/// (the system toggle's role and its on or off value, never a button), a press and its hit area, disabled, and on
/// macOS the keyboard: Tab reaches the check with keyboard navigation on, and Space toggles it.
///
/// The entry says which live checks are on in a text, `CheckboxCatalogID.summary` in WestronCatalog.
final class CheckboxBehaviorTests: XCTestCase {
    /// Must match `CheckboxCatalogID` in WestronCatalog.
    private enum ID {
        static let task = "checkbox.live.task"
        static let subtask = "checkbox.live.subtask"
        static let listColor = "checkbox.live.list-color"
        static let row = "checkbox.live.row"
        static let summary = "checkbox.live.summary"
    }

    private var app: XCUIApplication!

    @MainActor
    private func launch(_ arguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "checkbox"] + arguments
        app.launch()
        XCTAssertTrue(app.staticTexts[ID.summary].waitForExistence(timeout: 30), "the entry did not render")
    }

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
    }

    @MainActor
    override func tearDown() async throws {
        app?.terminate()
    }

    /// A text's string: iOS puts it in the label, macOS in the value.
    @MainActor
    private var summary: String {
        let text = app.staticTexts[ID.summary]
        return text.label.isEmpty ? (text.value as? String ?? "") : text.label
    }

    /// The live check with the identifier, as the system's toggle: a switch on iOS, a checkbox on macOS.
    @MainActor
    private func check(_ id: String) -> XCUIElement {
        #if os(macOS)
            let element = app.checkBoxes[id]
        #else
            let element = app.switches[id]
        #endif
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no toggle \(id)")
        return element
    }

    /// The toggle's value as assistive technology reads it: on or off.
    @MainActor
    private func isOn(_ element: XCUIElement) -> Bool {
        switch element.value {
        case let number as NSNumber: number.boolValue
        case let string as String: string == "1"
        default: false
        }
    }

    @MainActor
    private func press(_ coordinate: XCUICoordinate) {
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
    }

    /// The check is the system toggle for assistive technology: its role (a switch on iOS, a checkbox on macOS), its
    /// label, its value, and no button in its place, which the style draws with.
    @MainActor
    func testAssistiveTechnologyMeetsTheSystemToggle() {
        launch()
        for (id, label, on) in [
            (ID.task, "Write the report", false), (ID.subtask, "Outline the sections", true),
            (ID.listColor, "Water the plants", false),
            // Its label hidden, beside a separate title: the label is still its name.
            (ID.row, "Call the plumber", false),
        ] {
            let toggle = check(id)
            XCTAssertEqual(toggle.label, label)
            XCTAssertEqual(isOn(toggle), on, "\(label) is announced with the wrong value")
            XCTAssertTrue(toggle.isEnabled)
            XCTAssertFalse(app.buttons[id].exists, "\(label) is also a button")
        }
        // The disabled sample is announced as unavailable.
        #if os(macOS)
            let disabled = app.checkBoxes["disabled"]
        #else
            let disabled = app.switches["disabled"]
        #endif
        XCTAssertTrue(disabled.waitForExistence(timeout: 5))
        XCTAssertFalse(disabled.isEnabled, "the disabled check is not announced as unavailable")
    }

    /// A press toggles the value, both ways, and the toggle's value follows.
    @MainActor
    func testPressToggles() {
        launch()
        XCTAssertEqual(summary, "on: subtask")
        let task = check(ID.task)
        press(task.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: task, subtask")
        XCTAssertTrue(isOn(check(ID.task)))
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        press(check(ID.task).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: subtask")
        XCTAssertFalse(isOn(check(ID.task)))
    }

    /// The hit area is at least the platform's target around the circle: the toggle's frame starts with a square of
    /// at least 44 pt on iOS (28 on macOS) that holds the circle, and a press in its corner, off the circle, toggles.
    @MainActor
    func testHitAreaAroundTheCircle() {
        launch()
        let task = check(ID.task)
        #if os(macOS)
            let target: CGFloat = 28
        #else
            let target: CGFloat = 44
        #endif
        XCTAssertGreaterThanOrEqual(task.frame.height, target)
        // 2 pt inside the top-left corner of the hit area: outside the circle, which is centered in it.
        press(task.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 2, dy: 2)))
        XCTAssertEqual(summary, "on: task, subtask", "a press in the hit area's corner did not toggle")
    }

    /// In a system `List` row, as the pilot's task rows are, a check whose label is hidden beside a separate title.
    /// On iOS the List gives the toggle's accessibility element the whole row (measured on iOS 26.3: 370 × 74 pt on a
    /// 402 pt screen), on macOS the check's own 32 pt square (macOS 26), so the check is pressed in the middle of the
    /// element's leading square, where the circle is drawn on both. A press on the check
    /// toggles it; a press on the title, inside the same row, does not: the row does not take the check's press. The
    /// screenshot attached after both shows the rows.
    @MainActor
    func testCheckInAListRow() {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "checkbox-in-list"]
        app.launch()
        let summary = app.staticTexts["checkbox.list.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 30), "the entry did not render")
        func text() -> String { summary.label.isEmpty ? (summary.value as? String ?? "") : summary.label }
        XCTAssertEqual(text(), "on: second")
        let first = check("checkbox.list.first")
        XCTAssertEqual(first.label, "Call the plumber")
        let row = first.frame
        print("checkbox-in-list: the toggle's element \(row) in a window \(app.windows.firstMatch.frame)")
        let origin = first.coordinate(withNormalizedOffset: .zero)
        // The circle: the middle of the row's leading square.
        press(origin.withOffset(CGVector(dx: row.height / 2, dy: row.height / 2)))
        XCTAssertEqual(text(), "on: first, second", "a press on the check in a List row did not toggle it")
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        // The title: 120 pt past the row's leading square, on the title's text.
        press(origin.withOffset(CGVector(dx: row.height + 120, dy: row.height / 2)))
        XCTAssertEqual(text(), "on: first, second", "a press on the row's title toggled the check")
        let rows = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        rows.name = "checkbox-in-list"
        rows.lifetime = .keepAlways
        add(rows)
    }

    /// macOS, with the system's keyboard navigation on (System Settings, Keyboard, "Keyboard navigation"): Tab moves the
    /// focus to the check, and Space toggles it. The screenshot attached shows the system's focus ring on it.
    ///
    /// The setting is the person's, global, and a test does not change it: with it off, as on a Mac by default, a Mac
    /// gives neither a system checkbox nor westron's check keyboard focus, and the test is skipped. Passing
    /// `-AppleKeyboardUIMode 2` to the app does not turn it on, nor does replacing `isFullKeyboardAccessEnabled` in the
    /// app (measured 2026-11-18, macOS 26, Xcode 27.1).
    @MainActor
    func testKeyboardFocusAndSpace() throws {
        #if os(macOS)
            // Bit 1 of the global AppleKeyboardUIMode is keyboard navigation (2 or 3 when on).
            guard UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode") & 2 != 0 else {
                throw XCTSkip("the system's keyboard navigation is off on this Mac")
            }
            launch()
            app.windows.firstMatch.click()
            XCTAssertEqual(summary, "on: subtask")
            // Tab through the page until Space toggles the task: the checks before it are the states' samples.
            var reached = false
            for _ in 0..<12 {
                app.typeKey(.tab, modifierFlags: [])
                let focused = app.checkBoxes[ID.task].value(forKey: "hasKeyboardFocus") as? Bool ?? false
                if focused {
                    reached = true
                    break
                }
            }
            XCTAssertTrue(reached, "Tab never moved the keyboard focus to the check")
            let ring = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            ring.name = "checkbox-keyboard-focus"
            ring.lifetime = .keepAlways
            add(ring)
            app.typeKey(" ", modifierFlags: [])
            XCTAssertEqual(summary, "on: task, subtask", "Space did not toggle the focused check")
            app.typeKey(" ", modifierFlags: [])
            XCTAssertEqual(summary, "on: subtask", "Space did not toggle the focused check back")
        #else
            throw XCTSkip("keyboard focus is measured on macOS")
        #endif
    }
}
