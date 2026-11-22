import XCTest

/// Chip's behavior that a unit test cannot reach, on the catalog's `chip` entry: what assistive technology meets for
/// each form (the selectable chip the system's own toggle in its button style, selected while on; the pressable chip a
/// button; the static chip its text), a press that toggles or activates, and the hit area laid out around the drawn
/// chip.
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
}
