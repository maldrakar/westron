import XCTest

/// Chip's behavior that a unit test cannot reach, on the catalog's `chip` entry: what assistive technology meets for
/// each form (the selectable chip the system's own toggle, the style's accessibility representation: a switch on iOS, a
/// checkbox on macOS, with its value on or off; the pressable chip a button; the static chip its text), a press that
/// toggles or activates, the hit area laid out around the drawn chip, keyboard focus and Space on macOS, and a label
/// that is only text.
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

    /// Must match `ChipSample.long` in WestronCatalog.
    private static let long = "A tag whose name runs much longer than its chip"

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

    /// The system's toggles: switches on iOS, checkboxes on macOS.
    @MainActor
    private var toggles: XCUIElementQuery {
        #if os(macOS)
            app.checkBoxes
        #else
            app.switches
        #endif
    }

    /// The type of the system's toggle on this OS.
    private var toggleType: XCUIElement.ElementType {
        #if os(macOS)
            .checkBox
        #else
            .switch
        #endif
    }

    /// The selectable chip with the identifier, as the system's toggle.
    @MainActor
    private func toggle(_ id: String) -> XCUIElement {
        let element = toggles[id]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no toggle \(id)")
        return element
    }

    /// The element with the identifier, whatever its type.
    @MainActor
    private func element(_ id: String) -> XCUIElement {
        let element = app.descendants(matching: .any)[id]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no element \(id)")
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

    /// The elements whose label is `label`, of any type.
    @MainActor
    private func named(_ label: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
    }

    /// One line of what the hierarchy holds for an element, printed and attached for the report.
    @MainActor
    private func line(_ name: String, _ element: XCUIElement) -> String {
        "chip: \(name): type \(element.elementType.rawValue), label \(element.label), "
            + "value \(String(describing: element.value)), selected \(element.isSelected), "
            + "enabled \(element.isEnabled), frame \(element.frame)"
    }

    @MainActor
    private func press(_ coordinate: XCUICoordinate) {
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
    }

    /// The selectable chip is the system's toggle for assistive technology (a switch on iOS, a checkbox on macOS),
    /// labelled with its words, its value on or off, never selected, and no button beside it, which the style draws
    /// with; the pressable chip is a button, never selected; the static chip its text alone. Each name is read once and
    /// no icon is an element: the icon and the check are decorative and hidden. A truncated label is the whole name,
    /// and a disabled chip is announced as unavailable. The hierarchy measured is printed and attached.
    @MainActor
    func testAssistiveTechnologyMeetsEachForm() {
        launch()
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "chip-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        for (id, label, on) in [(ID.work, "Work", false), (ID.home, "Home", true), (ID.errands, "Errands", false)] {
            let chip = toggle(id)
            print(line(id, chip))
            XCTAssertEqual(chip.elementType, toggleType, "\(label) is a \(chip.elementType.rawValue), not the toggle")
            XCTAssertEqual(chip.label, label)
            XCTAssertEqual(isOn(chip), on, "\(label) is announced with the wrong value")
            XCTAssertFalse(chip.isSelected, "\(label) is also announced as selected: its state would be said twice")
            XCTAssertTrue(chip.isEnabled)
            XCTAssertFalse(app.buttons[id].exists, "\(label) is also a button")
            // The icon and the check are decorative: the chip's name is its words alone, read once.
            XCTAssertEqual(named(label).count, 1, "\(label) is read more than once")
            XCTAssertEqual(chip.descendants(matching: .image).count, 0, "\(label)'s icon is an element of its own")
        }
        let day = app.buttons[ID.day]
        XCTAssertTrue(day.waitForExistence(timeout: 5), "the pressable chip is not a button")
        print(line(ID.day, day))
        for (index, element) in day.descendants(matching: .any).allElementsBoundByIndex.enumerated() {
            print(line("\(ID.day) child \(index)", element))
        }
        XCTAssertEqual(day.label, "Tue")
        XCTAssertFalse(day.isSelected)
        // On iOS XCUITest also lists the button's own words under it as a text, as it does under a westron Button with
        // a Label; the name is read once outside the button. The icon and the check under it are no image: under a
        // westron Button with a Label the icon is an image named after its symbol, the check with the trait selected
        // (measured on iOS 26.3, 2026-11-22). The chip's glyphs give an empty representation (`ChipDecorative`), and
        // XCUITest still lists each as an element of type other with no label, no value and no trait; nothing in them
        // is read.
        let inside = day.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Tue")).count
        XCTAssertEqual(named("Tue").count - inside, 1, "the pressable chip's name is read more than once")
        XCTAssertEqual(day.descendants(matching: .image).count, 0, "the pressable chip's icon is an element of its own")
        XCTAssertEqual(
            day.descendants(matching: .any).matching(NSPredicate(format: "label != %@ AND label != %@", "Tue", ""))
                .count, 0, "the pressable chip holds an element named other than with its words")
        XCTAssertEqual(
            day.descendants(matching: .any).matching(NSPredicate(format: "selected == true")).count, 0,
            "an element under the pressable chip is announced as selected")
        // The static chips are text: their words, once, and no control.
        for word in ["Garden", "Groceries"] {
            let still = app.staticTexts[word]
            XCTAssertTrue(still.exists, "the static chip's words are not read as text")
            print(line(word, still))
            XCTAssertEqual(named(word).count, 1, "the static chip \(word) is read more than once")
        }
        // The long label, truncated on screen, is the whole name of each form's chip.
        let long = NSPredicate(format: "label == %@", Self.long)
        XCTAssertTrue(
            toggles.matching(long).firstMatch.exists, "the truncated selectable chip is not named with its whole label")
        XCTAssertTrue(
            app.buttons.matching(long).firstMatch.exists,
            "the truncated pressable chip is not named with its whole label")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", Self.long, Self.long))
                .firstMatch.exists, "the truncated static chip is not read with its whole label")
        // The disabled samples are announced as unavailable: the selectable one off and on, and the pressable one.
        for name in ["disabled", "disabled, on"] {
            let disabled = toggles[name]
            XCTAssertTrue(disabled.waitForExistence(timeout: 5), "no disabled toggle \(name)")
            print(line(name, disabled))
            XCTAssertFalse(disabled.isEnabled, "the disabled chip \(name) is not announced as unavailable")
        }
        let disabledButton = app.buttons["disabled"]
        XCTAssertTrue(disabledButton.waitForExistence(timeout: 5), "no disabled pressable chip")
        print(line("disabled button", disabledButton))
        XCTAssertFalse(disabledButton.isEnabled, "the disabled pressable chip is not announced as unavailable")
    }

    /// A press toggles a selectable chip, both ways, and what assistive technology reads follows; a press on the
    /// pressable chip runs its action once.
    @MainActor
    func testPressTogglesAndActivates() {
        launch()
        XCTAssertEqual(summary, "on: home; pressed: 0")
        press(toggle(ID.work).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: work, home; pressed: 0")
        XCTAssertTrue(isOn(toggle(ID.work)), "the lit chip is not announced as on")
        XCTAssertFalse(toggle(ID.work).isSelected)
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        press(toggle(ID.work).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: home; pressed: 0")
        XCTAssertFalse(isOn(toggle(ID.work)))
        press(element(ID.day).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(summary, "on: home; pressed: 1")
    }

    /// The hit area is at least the platform's target high, laid out around the drawn chip: a press where only the hit
    /// area is, above the drawn capsule, toggles. The element's frame is measured and printed.
    @MainActor
    func testHitAreaAroundTheChip() {
        launch()
        let work = toggle(ID.work)
        #if os(macOS)
            let target: CGFloat = 28
            let drawn: CGFloat = 24
        #else
            let target: CGFloat = 44
            let drawn: CGFloat = 28
        #endif
        print(line(ID.work, work))
        let frame = work.frame
        // How far above the element's top edge the press lands: inside the hit area, outside the drawn capsule.
        let above: CGFloat
        if frame.height >= target - 0.5 {
            // The element's frame is the hit area: 1 pt inside its top edge, above the capsule.
            above = -1
        } else {
            // The element's frame is the drawn capsule, centred in the hit area, which reaches (target - drawn) / 2
            // above it: half that far above the capsule's top.
            XCTAssertEqual(frame.height, drawn, accuracy: 1, "the element is neither the hit area nor the chip")
            above = (target - drawn) / 4
        }
        press(work.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).withOffset(CGVector(dx: 0, dy: -above)))
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
    /// `Label`, the system's toggle labelled with its words, its value on while lit, never selected; the button never
    /// selected. The check before the lit words is decorative: the name is read once.
    @MainActor
    func testTextOnlyLabel() {
        launch()
        let reading = toggles["Reading"]
        XCTAssertTrue(reading.waitForExistence(timeout: 5), "no toggle Reading")
        print(line("Reading", reading))
        XCTAssertTrue(isOn(reading))
        XCTAssertFalse(reading.isSelected)
        XCTAssertEqual(named("Reading").count, 1, "Reading is read more than once")
        XCTAssertFalse(isOn(toggles["Music"]))
        XCTAssertTrue(app.buttons["Wed"].exists)
        XCTAssertFalse(app.buttons["Wed"].isSelected)
    }
}
