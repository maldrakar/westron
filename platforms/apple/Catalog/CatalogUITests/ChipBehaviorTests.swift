import XCTest

/// Chip's behavior that a unit test cannot reach, on the catalog's `chip` entry: what assistive technology meets for
/// each form (the selectable chip a system Button selected while on, `.isSelected`, the style's accessibility
/// representation; the pressable chip a button; the static chip its text), a press that toggles or activates, the hit
/// area laid out around the drawn chip, keyboard focus and Space on macOS, and a label that is only text.
///
/// The entry says which live chips are on, and how often the pressable one was pressed, in a text,
/// `ChipCatalogID.summary` in WestronCatalog.
final class ChipBehaviorTests: XCTestCase {
    /// Must match `ChipCatalogID` in WestronCatalog.
    private enum ID {
        static let work = "chip.live.work"
        static let home = "chip.live.home"
        static let errands = "chip.live.errands"
        static let day = "chip.live.day"
        static let summary = "chip.live.summary"
    }

    private var app: XCUIApplication!

    @MainActor
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "chip"]
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

    /// The element with the identifier, whatever its type.
    @MainActor
    private func element(_ id: String) -> XCUIElement {
        let element = app.descendants(matching: .any)[id]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no element \(id)")
        return element
    }

    /// Whether assistive technology meets the selectable chip as on: a selected button (the contract's
    /// `checked: selected`).
    @MainActor
    private func isOn(_ element: XCUIElement) -> Bool {
        element.isSelected
    }

    @MainActor
    private func press(_ coordinate: XCUICoordinate) {
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
    }

    /// The selectable chip is a button for assistive technology, selected while it is lit, labelled with its words, and
    /// never a second element beside it; the pressable chip is a button, never selected; the static chip its text
    /// alone. The system's toggle in its button style, as the style's accessibility representation, was measured
    /// first (iOS 26.3, 2026-11-22): a switch with the value 0 or 1, never selected, so the style is the button with
    /// `.isSelected` (the contract's decisions/0001, Q6). The hierarchy measured is printed and attached.
    @MainActor
    func testAssistiveTechnologyMeetsEachForm() {
        launch()
        for (id, label, on) in [(ID.work, "Work", false), (ID.home, "Home", true), (ID.errands, "Errands", false)] {
            let chip = element(id)
            print(
                "chip: \(id): type \(chip.elementType.rawValue), label \(chip.label), "
                    + "value \(String(describing: chip.value)), selected \(chip.isSelected)")
            XCTAssertEqual(chip.elementType, .button, "\(label) is a \(chip.elementType.rawValue), not a button")
            XCTAssertEqual(chip.label, label)
            XCTAssertEqual(isOn(chip), on, "\(label) is announced with the wrong state")
            XCTAssertTrue(chip.isEnabled)
            // The icon is decorative: the chip's name is its words alone, read once.
            let named = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
            XCTAssertEqual(named.count, 1, "\(label) is read more than once")
        }
        let day = element(ID.day)
        print("chip: \(ID.day): type \(day.elementType.rawValue), label \(day.label), selected \(day.isSelected)")
        XCTAssertEqual(day.elementType, .button)
        XCTAssertEqual(day.label, "Tue")
        XCTAssertFalse(day.isSelected)
        // The static chips are text: their words, and no control.
        let still = app.staticTexts["Garden"]
        XCTAssertTrue(still.exists, "the static chip's words are not read as text")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "chip-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    /// A press toggles a selectable chip, both ways, and what assistive technology reads follows; a press on the
    /// pressable chip runs its action once.
    @MainActor
    func testPressTogglesAndActivates() {
        launch()
        XCTAssertEqual(summary, "on: home; pressed: 0")
        press(element(ID.work).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: work, home; pressed: 0")
        XCTAssertTrue(isOn(element(ID.work)), "the lit chip is not announced as on")
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        press(element(ID.work).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: home; pressed: 0")
        XCTAssertFalse(isOn(element(ID.work)))
        press(element(ID.day).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: home; pressed: 1")
    }

    /// The hit area is at least the platform's target high, laid out around the lower drawn chip: the element is at
    /// least 44 pt high on iOS (28 on macOS), and a press 2 pt inside its top edge, above the drawn capsule, toggles.
    @MainActor
    func testHitAreaAroundTheChip() {
        launch()
        let work = element(ID.work)
        #if os(macOS)
            let target: CGFloat = 28
        #else
            let target: CGFloat = 44
        #endif
        XCTAssertGreaterThanOrEqual(work.frame.height, target)
        press(work.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).withOffset(CGVector(dx: 0, dy: 2)))
        XCTAssertEqual(summary, "on: work, home; pressed: 0", "a press in the hit area above the chip did not toggle")
    }

    /// Whether the element with the identifier has the keyboard focus.
    @MainActor
    private func hasFocus(_ id: String) -> Bool {
        app.descendants(matching: .any)[id].value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }

    /// macOS, with the system's keyboard navigation on (System Settings, Keyboard, "Keyboard navigation"): Tab moves the
    /// focus to the selectable chip, Space toggles it both ways, and the chip is one focus stop, not two (the system
    /// button the style draws and the toggle around it): the next Tab goes to the next chip. The screenshot attached
    /// shows the system's focus ring.
    ///
    /// The setting is the person's, global, and a test does not change it: with it off, as on a Mac by default, the
    /// test is skipped, as `CheckboxBehaviorTests.testKeyboardFocusAndSpace` is.
    @MainActor
    func testKeyboardFocusAndSpace() throws {
        #if os(macOS)
            // Bit 1 of the global AppleKeyboardUIMode is keyboard navigation (2 or 3 when on).
            guard UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode") & 2 != 0 else {
                throw XCTSkip("the system's keyboard navigation is off on this Mac")
            }
            launch()
            app.windows.firstMatch.click()
            XCTAssertEqual(summary, "on: home; pressed: 0")
            // Tab through the page until the focus reaches Work: the chips before it are the states' samples.
            var reached = false
            for _ in 0..<40 {
                app.typeKey(.tab, modifierFlags: [])
                if hasFocus(ID.work) {
                    reached = true
                    break
                }
            }
            XCTAssertTrue(reached, "Tab never moved the keyboard focus to the chip")
            let ring = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            ring.name = "chip-keyboard-focus"
            ring.lifetime = .keepAlways
            add(ring)
            app.typeKey(" ", modifierFlags: [])
            XCTAssertEqual(summary, "on: work, home; pressed: 0", "Space did not toggle the focused chip")
            app.typeKey(" ", modifierFlags: [])
            XCTAssertEqual(summary, "on: home; pressed: 0", "Space did not toggle the focused chip back")
            // One stop: the next Tab leaves Work for Home, the next chip, not for a second element of Work.
            app.typeKey(.tab, modifierFlags: [])
            XCTAssertFalse(hasFocus(ID.work), "the chip kept the focus after a Tab: it is two focus stops")
            XCTAssertTrue(hasFocus(ID.home), "the Tab after the chip did not reach the next chip")
        #else
            throw XCTSkip("keyboard focus is measured on macOS")
        #endif
    }

    /// A chip whose label is only text, `Toggle("Reading", isOn:)` and `Button("Wed")`: the same element as one with a
    /// `Label`, a button labelled with its words, selected while on.
    @MainActor
    func testTextOnlyLabel() {
        launch()
        let reading = app.buttons["Reading"]
        XCTAssertTrue(reading.waitForExistence(timeout: 5), "no button Reading")
        XCTAssertTrue(reading.isSelected)
        XCTAssertFalse(app.buttons["Music"].isSelected)
        XCTAssertFalse(app.buttons["Wed"].isSelected)
        print("chip: text only: Reading value \(String(describing: reading.value)), selected \(reading.isSelected)")
    }
}
