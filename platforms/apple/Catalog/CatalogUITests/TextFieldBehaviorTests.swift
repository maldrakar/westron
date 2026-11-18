import XCTest

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
        static let focused = "text-field.live.focused"
        static let clearFocus = "text-field.live.clear-focus"
    }

    /// The small field's drawn height, `size.control.s`, its padding at the default text size, `space.100`, and the
    /// platform's recommended target (chapter 08).
    #if os(macOS)
        private let drawnHeight: CGFloat = 24
        private let target: CGFloat = 28
    #else
        private let drawnHeight: CGFloat = 32
        private let target: CGFloat = 44
    #endif
    private let padding: CGFloat = 8

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

    @MainActor
    func testTheSmallFieldTakesTheTargetAroundWhatItDraws() {
        let drawn = drawnSmallField
        // How far the target reaches past the drawn edge: 6 pt on iOS, 2 pt on macOS.
        let reach = (target - drawnHeight) / 2
        let x = drawn.midX
        XCTAssertEqual(press(at: CGPoint(x: x, y: drawn.minY - reach + 1)), "Focused: small", "within the target above")
        XCTAssertEqual(press(at: CGPoint(x: x, y: drawn.maxY + reach - 1)), "Focused: small", "within the target below")
        #if os(macOS)
            // A click lands only where a view is: no farther than the target.
            XCTAssertEqual(
                press(at: CGPoint(x: x, y: drawn.minY - reach - 3)), "Focused: none", "past the target above")
        #else
            // The system's touch tolerance reaches about 16 pt past the drawn edge (measured without westron's own
            // reach, which iOS therefore does not add), and gives up well before 24 pt.
            XCTAssertEqual(press(at: CGPoint(x: x, y: drawn.minY - 24)), "Focused: none", "24 pt above the field")
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
