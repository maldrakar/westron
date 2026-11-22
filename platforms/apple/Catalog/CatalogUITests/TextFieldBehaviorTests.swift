import XCTest

#if os(iOS)
    import UIKit
#endif

/// TextField's behavior that a unit test cannot reach, on the catalog's `text-field-behavior` entry, in the real app,
/// whose window holds the keyboard focus (a package test's window is never key, so SwiftUI moves no focus there): a
/// framed field at size s takes a touch or a click on its padding and within the platform's recommended target around
/// what it draws, 44 pt on iOS and 28 pt on macOS (chapter 08; the contract's `size`); on macOS none farther out, while
/// on iOS the system's touch tolerance reaches farther by itself (TextFieldVariantStyle); a multiline field and a
/// SecureField edit through the style.
///
/// The entry names the focused field in a text, `TextFieldCatalogID.focused` in WestronCatalog.
final class TextFieldBehaviorTests: XCTestCase {
    /// Must match `TextFieldCatalogID` in WestronCatalog.
    private enum ID {
        static let small = "text-field.live.small"
        static let notes = "text-field.live.notes"
        static let secure = "text-field.live.secure"
        static let search = "text-field.live.search"
        static let focused = "text-field.live.focused"
        static let clearFocus = "text-field.live.clear-focus"
    }

    /// The small field's drawn height, `size.control.s`, its padding at the default text size, `space.200` since the
    /// capsule of 2026-11-20 (the contract's decisions/0002), and the platform's recommended target (chapter 08).
    #if os(macOS)
        private let drawnHeight: CGFloat = 24
        private let target: CGFloat = 28
    #else
        private let drawnHeight: CGFloat = 28
        private let target: CGFloat = 44
    #endif
    private let padding: CGFloat = 16

    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "text-field-behavior", "-WestronAppearance", "light"]
        app.launch()
        XCTAssertTrue(app.staticTexts[ID.focused].waitForExistence(timeout: 30), "the entry did not render")
    }

    @MainActor
    override func tearDown() async throws {
        app.terminate()
    }

    /// A text's string: iOS puts it in the label, macOS in the value.
    @MainActor
    private var focusedName: String {
        let text = app.staticTexts[ID.focused]
        return text.label.isEmpty ? (text.value as? String ?? "") : text.label
    }

    @MainActor
    private func field(_ id: String) -> XCUIElement {
        let field = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "no field \(id)")
        return field
    }

    /// The styled fields keep the system field's role and its prompt, and take the label the product gives them. With
    /// a prompt, the system field exposes no accessibility label from its title on iOS 26.3 and macOS 26.7, with
    /// westron's style or without it (measured against an unstyled field in #30), so the product names the field with
    /// `.accessibilityLabel(_:)`, as every catalog field does (the contract's `platforms.apple`; decisions/0001, I2).
    /// Here that label reaches the styled field.
    @MainActor
    func testFieldsKeepTheirRoleAndLabel() {
        let small = app.textFields[ID.small]
        XCTAssertTrue(small.waitForExistence(timeout: 5), "the framed field is not a text field")
        XCTAssertEqual(small.placeholderValue, "Untitled")
        let secure = app.secureTextFields[ID.secure]
        XCTAssertTrue(secure.waitForExistence(timeout: 5), "the SecureField is not a secure text field")
        XCTAssertEqual(secure.placeholderValue, "Required")
        let notes = field(ID.notes)
        // A multiline field is a text view on macOS and a text field on iOS.
        XCTAssertTrue([.textField, .textView].contains(notes.elementType), "notes: \(notes.elementType.rawValue)")

        XCTAssertEqual(small.label, "List name")
        XCTAssertEqual(secure.label, "Password")
        XCTAssertEqual(notes.label, "Notes")
    }

    /// Taps or clicks a point in the app's coordinates, after taking the focus from every field.
    @MainActor
    private func press(at point: CGPoint) -> String {
        let clear = app.buttons[ID.clearFocus]
        #if os(macOS)
            clear.click()
        #else
            clear.tap()
        #endif
        XCTAssertEqual(focusedName, "Focused: none")
        // Element frames are in screen coordinates; the app's own frame is unbounded on macOS, so the offset is taken
        // from the window's origin.
        let window = app.windows.firstMatch
        let coordinate = window.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x - window.frame.minX, dy: point.y - window.frame.minY))
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
        _ = app.staticTexts[ID.focused].waitForExistence(timeout: 1)
        return focusedName
    }

    /// The small field's drawn frame, from the system field's own frame: the field is centered in its drawn height and
    /// inset by its padding.
    @MainActor
    private var drawnSmallField: CGRect {
        let frame = field(ID.small).frame
        return CGRect(
            x: frame.minX - padding, y: frame.midY - drawnHeight / 2, width: frame.width + 2 * padding,
            height: drawnHeight)
    }

    @MainActor
    func testATouchOrClickOnThePaddingFocusesTheField() {
        let drawn = drawnSmallField
        XCTAssertEqual(press(at: CGPoint(x: drawn.minX + padding / 2, y: drawn.midY)), "Focused: small")
        XCTAssertEqual(press(at: CGPoint(x: drawn.maxX - padding / 2, y: drawn.midY)), "Focused: small")
        XCTAssertEqual(press(at: CGPoint(x: drawn.midX, y: drawn.midY)), "Focused: small")
    }

    /// The search field's glyphs (the contract's decisions/0003, #115) stand at its padding, `space.250` at size m, and
    /// `container.gap`, `space.100`, from its text: a touch or a click on either focuses the field, as one on the
    /// padding does (the style's hit area takes the whole field). The glyphs are about 17 to 20 pt wide at body.regular;
    /// the points are 6 pt into each.
    @MainActor
    func testATouchOrClickOnAGlyphFocusesTheField() {
        let frame = field(ID.search).frame
        let into: CGFloat = 6
        #if os(iOS)
            // On iOS the element's frame is the drawn field, padding included (measured: the small field's is the
            // page's width less its margins), so a glyph starts at the padding.
            let padding: CGFloat = 20
            let start = frame.minX + padding + into
            let end = frame.maxX - padding - into
        #else
            // On macOS it is the system field's, between the glyphs, so a glyph ends at the gap before it.
            let gap: CGFloat = 8
            let start = frame.minX - gap - into
            let end = frame.maxX + gap + into
        #endif
        XCTAssertEqual(
            press(at: CGPoint(x: start, y: frame.midY)), "Focused: search", "the magnifier at the start, in \(frame)")
        XCTAssertEqual(
            press(at: CGPoint(x: end, y: frame.midY)), "Focused: search", "the microphone at the end, in \(frame)")
    }

    /// The search field is one: the product gives it the trait, and its label. Its glyphs are decoration, hidden from
    /// assistive technology: the page exposes no image.
    @MainActor
    func testTheSearchFieldIsOneAndItsGlyphsAreHidden() {
        let search = field(ID.search)
        XCTAssertEqual(search.label, "Search")
        #if os(iOS)
            XCTAssertTrue(app.searchFields[ID.search].exists, "not a search field: \(search.elementType.rawValue)")
        #else
            XCTAssertTrue(
                [.searchField, .textField].contains(search.elementType), "macOS: \(search.elementType.rawValue)")
        #endif
        XCTAssertEqual(app.images.count, 0, "images on the page: \(app.images.allElementsBoundByIndex.map(\.label))")
    }

    @MainActor
    func testTheSmallFieldTakesTheTargetAroundWhatItDraws() {
        let drawn = drawnSmallField
        // How far the target reaches past the drawn edge: 8 pt on iOS, 2 pt on macOS.
        let reach = (target - drawnHeight) / 2
        let x = drawn.midX
        #if os(macOS)
            // Inside the 28 pt target, 1 pt short of its edge; a click lands only where a view is, so no farther.
            XCTAssertEqual(
                press(at: CGPoint(x: x, y: drawn.minY - reach + 1)), "Focused: small", "within the target above")
            XCTAssertEqual(
                press(at: CGPoint(x: x, y: drawn.maxY + reach - 1)), "Focused: small", "within the target below")
            XCTAssertEqual(
                press(at: CGPoint(x: x, y: drawn.minY - reach - 3)), "Focused: none", "past the target above")
        #else
            // At the edge of the 44 pt target, 8 pt past the drawn edge, above and below; the touch tolerance gives
            // up well before 24 pt. A one-off probe of #30 found it reaching 16 pt and not 18 pt.
            XCTAssertEqual(press(at: CGPoint(x: x, y: drawn.minY - reach)), "Focused: small", "the target's top edge")
            XCTAssertEqual(
                press(at: CGPoint(x: x, y: drawn.maxY + reach)), "Focused: small", "the target's bottom edge")
            XCTAssertEqual(press(at: CGPoint(x: x, y: drawn.minY - 24)), "Focused: none", "24 pt above the field")
        #endif
    }

    /// Size m is drawn 36 pt tall on iOS (#85), below the 44 pt target: a tap 4 pt past its drawn edge, above and
    /// below, at the target's edge, focuses the field, as at size s. The secure field is the page's framed field at m.
    /// macOS draws m at 32 pt, above its target of 28.
    @MainActor
    func testTheMediumFieldTakesTheTargetAroundWhatItDraws() throws {
        #if os(macOS)
            throw XCTSkip("macOS draws size m above its target")
        #else
            let drawnHeight: CGFloat = 36
            let frame = field(ID.secure).frame
            let reach = (target - drawnHeight) / 2
            XCTAssertEqual(reach, 4, accuracy: 0.01)
            let top = frame.midY - drawnHeight / 2
            let bottom = frame.midY + drawnHeight / 2
            XCTAssertEqual(
                press(at: CGPoint(x: frame.midX, y: top - reach)), "Focused: secure", "the target's top edge")
            XCTAssertEqual(
                press(at: CGPoint(x: frame.midX, y: bottom + reach)), "Focused: secure", "the target's bottom edge")
        #endif
    }

    /// The system field's own touches and clicks through the style. iOS: a double tap selects a word, with the
    /// selection's handles and the edit menu; a long press on a focused field shows the edit menu; a long press on an
    /// empty field shows it with Paste, how a person pastes into an empty field. macOS: a right click shows the field's
    /// context menu. A bisect in #30 found the styled fields behaving as an unstyled field with the same modifiers in
    /// every case, with each piece of the style removed in turn, and on macOS the same context menus for styled and
    /// unstyled fields; a long press on an unfocused field with text shows no menu on either, the system's behavior.
    /// A long press right after the tap that focuses a field, or after a selection was dismissed, also showed none;
    /// the test waits a second between them and presses before it selects. Menus are found by their items' type, not
    /// their labels, which follow the simulator's language.
    @MainActor
    func testTheFieldKeepsItsOwnTouches() {
        #if os(iOS)
            UIPasteboard.general.string = "pasted"
            // Taking the focus away dismisses a menu and a selection. A tap on the page's title first closes a menu
            // that covers the Clear focus button: with the iOS control heights of #85 the secure field's AutoFill
            // menu opens over it, and the tap opened its submenu instead.
            func clearFocus() {
                app.staticTexts["TextField · live"].tap()
                app.buttons[ID.clearFocus].tap()
                _ = app.menuItems.firstMatch.waitForNonExistence(timeout: 5)
            }
            // An empty field, unfocused: Paste.
            clearFocus()
            field(ID.small).press(forDuration: 1.2)
            XCTAssertTrue(
                app.menuItems.firstMatch.waitForExistence(timeout: 5), "a long press on an empty field showed no menu")
            for id in [ID.small, ID.secure, ID.notes] {
                let field = field(id)
                clearFocus()
                field.tap()
                sleep(1)
                field.press(forDuration: 1.2)
                XCTAssertTrue(
                    app.menuItems.firstMatch.waitForExistence(timeout: 5), "\(id): a long press showed no edit menu")
            }
            clearFocus()
            field(ID.notes).doubleTap()
            let selection = app.otherElements["_UITextSelectionRangeAdjustmentContainerView"]
            XCTAssertTrue(selection.waitForExistence(timeout: 5), "a double tap selected no word")
            XCTAssertTrue(app.menuItems.firstMatch.waitForExistence(timeout: 5), "a double tap showed no edit menu")
        #else
            // The menu bar's items are menu items too, so a context menu shows as more of them. Only a multiline
            // field's context menu reaches the accessibility tree: on a single-line field, styled or unstyled alike, a
            // right click adds no items there (measured against unstyled fields in #30), so it is not asserted.
            let menuBarItems = app.menuItems.count
            field(ID.notes).rightClick()
            let opened = NSPredicate { _, _ in self.app.menuItems.count > menuBarItems }
            XCTAssertEqual(
                XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: opened, object: nil)], timeout: 5),
                .completed, "a right click showed no context menu")
            app.typeKey(.escape, modifierFlags: [])
        #endif
    }

    @MainActor
    func testMultilineAndSecureFieldsEdit() {
        let notes = field(ID.notes)
        #if os(macOS)
            notes.click()
        #else
            notes.tap()
        #endif
        XCTAssertEqual(focusedName, "Focused: notes")
        notes.typeText(" eggs ")
        XCTAssertTrue((notes.value as? String ?? "").contains(" eggs "), "notes: \(notes.value ?? "nil")")

        let secure = field(ID.secure)
        #if os(macOS)
            secure.click()
        #else
            secure.tap()
        #endif
        XCTAssertEqual(focusedName, "Focused: secure")
        secure.typeText("abc")
        XCTAssertEqual((secure.value as? String ?? "").count, 3, "secure: \(secure.value ?? "nil")")
    }
}
