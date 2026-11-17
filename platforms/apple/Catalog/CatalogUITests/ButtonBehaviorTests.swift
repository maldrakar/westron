import XCTest

/// Button's behavior that a unit test cannot reach, on the catalog's `button-behavior` entry: a loading button refuses
/// presses and stays enabled; an icon-only button reads as its title; the hit area of a small button.
///
/// The entry counts accepted presses in a text, `ButtonCatalogID.count` in WestronCatalog.
final class ButtonBehaviorTests: XCTestCase {
    /// Must match `ButtonCatalogID` in WestronCatalog.
    private enum ID {
        static let rest = "button.live.rest"
        static let loading = "button.live.loading"
        static let loadingWithoutIcon = "button.live.loading-without-icon"
        static let loadingToggle = "button.live.loading-toggle"
        static let accessibilityPress = "button.live.accessibility-press"
        static let export = "button.live.export"
        static let small = "button.live.small"
        static let iconOnly = "button.live.icon-only"
        static let firstNeighbor = "button.live.neighbor-first"
        static let secondNeighbor = "button.live.neighbor-second"
        static let neighbors = "button.live.neighbors"
        static let count = "button.live.count"
    }

    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "button-behavior"]
        app.launch()
        XCTAssertTrue(app.staticTexts[ID.count].waitForExistence(timeout: 30), "the entry did not render")
    }

    @MainActor
    override func tearDown() async throws {
        app.terminate()
    }

    /// A text's string: iOS puts it in the label, macOS in the value.
    @MainActor
    private func text(_ id: String) -> String {
        let text = app.staticTexts[id]
        return text.label.isEmpty ? (text.value as? String ?? "") : text.label
    }

    @MainActor
    private var accepted: Int {
        Int(text(ID.count).split(separator: " ").last ?? "") ?? -1
    }

    @MainActor
    private func button(_ id: String) -> XCUIElement {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "no button \(id)")
        return button
    }

    @MainActor
    private func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    @MainActor
    private func press(_ coordinate: XCUICoordinate) {
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
    }

    /// Takes Publish, "Publish now" and Export out of loading.
    @MainActor
    private func stopLoading() {
        let toggle = app.descendants(matching: .any)[ID.loadingToggle].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        #if os(macOS)
            toggle.click()
        #else
            if toggle.switches.firstMatch.exists { toggle.switches.firstMatch.tap() } else { toggle.tap() }
        #endif
        XCTAssertEqual(button(ID.loading).value as? String ?? "", "", "the button is still loading")
    }

    @MainActor
    func testRestingButtonAcceptsAPress() {
        XCTAssertEqual(accepted, 0)
        press(button(ID.rest))
        XCTAssertEqual(accepted, 1)
    }

    /// Publish has an icon, which the indicator replaces; "Publish now" has a label and no icon, which today's loading
    /// layout truncates while the button keeps its whole name.
    @MainActor
    func testLoadingButtonRefusesTouchAndPointerAndStaysEnabled() {
        // Not announced or treated as unavailable: enabled, with its whole label and "Loading" as its value.
        for (id, label) in [(ID.loading, "Publish"), (ID.loadingWithoutIcon, "Publish now")] {
            let loading = button(id)
            XCTAssertTrue(loading.isEnabled, "\(label) is not enabled")
            XCTAssertEqual(loading.label, label)
            XCTAssertEqual(loading.value as? String, "Loading", "\(label) is not announced as loading")
            press(loading)
            press(loading)
            XCTAssertEqual(accepted, 0, "\(label), loading, accepted a touch or a click")
        }
        XCTAssertEqual(button(ID.rest).value as? String ?? "", "")
        // The control: the same input reaches a button at rest.
        press(button(ID.rest))
        XCTAssertEqual(accepted, 1)
    }

    /// VoiceOver, Switch Control and Voice Control press a button through the accessibility API: AXPress on macOS,
    /// `accessibilityActivate()` on iOS. The runner is not trusted for that API, so the catalog makes the press itself,
    /// on the own accessibility elements of Publish (with an icon) and "Publish now" (without one), when its test
    /// control is pressed. `.loading(_:)` refuses it.
    @MainActor
    func testLoadingButtonRefusesTheAccessibilityPress() {
        let trigger = button(ID.accessibilityPress)
        press(trigger)
        XCTAssertEqual(
            trigger.value as? String, "pressed, pressed",
            "the catalog did not find both buttons' accessibility elements")
        press(trigger)
        XCTAssertEqual(accepted, 0, "an accessibility press triggered a loading button")
        // The control: out of loading, the same press reaches both.
        stopLoading()
        press(trigger)
        XCTAssertEqual(accepted, 2, "an accessibility press did not reach the buttons at rest: \(trigger.value ?? "")")
    }

    /// Return triggers the window's default action, which the live "Publish" button is
    /// (`.keyboardShortcut(.defaultAction)`): it does at rest, and should not while loading. ⌘E triggers Export, whose
    /// shortcut the catalog drops while it loads, as `.loading(_:)` tells a product to.
    ///
    /// macOS only. In the iOS 26.3 simulator `typeKey` reaches no shortcut, not even a system `.borderedProminent`
    /// button's default action, so the iOS (iPad hardware keyboard) behavior is not measured.
    ///
    /// A known contract gap (#23): on macOS SwiftUI runs a shortcut's button action itself, around the button's style
    /// and modifiers, so westron cannot refuse it. The expected failure fails the test once that changes.
    @MainActor
    func testKeyboardShortcutsWhileLoading() throws {
        #if os(macOS)
            app.windows.firstMatch.click()
            app.typeKey(.return, modifierFlags: [])
            let afterReturn = accepted
            XCTExpectFailure("contract gap #23: on macOS a keyboard shortcut runs the action of a loading button") {
                XCTAssertEqual(afterReturn, 0, "Return triggered a loading default button")
            }
            // A product that drops the shortcut while loading: ⌘E does nothing.
            app.typeKey("e", modifierFlags: .command)
            XCTAssertEqual(accepted, afterReturn, "⌘E triggered Export while its shortcut is dropped")
            // The control: out of loading, both keys trigger their buttons.
            stopLoading()
            app.typeKey(.return, modifierFlags: [])
            XCTAssertEqual(accepted, afterReturn + 1, "Return did not trigger the default button at rest")
            app.typeKey("e", modifierFlags: .command)
            XCTAssertEqual(accepted, afterReturn + 2, "⌘E did not trigger Export at rest")
        #else
            throw XCTSkip("the iOS simulator's typeKey reaches no keyboard shortcut")
        #endif
    }

    /// An icon-only button reads as its title, a button and nothing else: the checkmark symbol's own trait does not
    /// leak ("Selected").
    @MainActor
    func testIconOnlyButtonReadsAsItsTitle() {
        let iconOnly = button(ID.iconOnly)
        XCTAssertEqual(iconOnly.label, "Save")
        XCTAssertEqual(iconOnly.elementType, .button)
        XCTAssertFalse(iconOnly.isSelected, "the icon-only button reads as selected")
        XCTAssertEqual(iconOnly.value as? String ?? "", "")
        press(iconOnly)
        XCTAssertEqual(accepted, 1)
    }

    /// A size s button is drawn smaller than the recommended target: 32 pt tall on iOS (target 44), 24 on macOS
    /// (target 28). A press 5 pt below what is drawn, inside the target on iOS, must reach it. The hit area there is the
    /// system's touch tolerance, which westron does not grow (ButtonVariantStyle.swift): measured on iOS 26.3 it reaches
    /// 16 pt below such a button, and the test fails if the platform ever covers less than the target.
    ///
    /// macOS has no such tolerance and ignores a hit area larger than the frame, so a click 2 pt below the 24 pt button,
    /// inside its 28 pt target, misses: a known contract gap (#23), recorded as an expected failure there.
    @MainActor
    func testSmallButtonHitAreaReachesTheTarget() {
        let small = button(ID.small)
        #if os(macOS)
            let below: CGFloat = 2
        #else
            let below: CGFloat = 5
        #endif
        press(small.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: below)))
        let reached = accepted
        #if os(macOS)
            XCTExpectFailure("contract gap #23: macOS does not extend a hit area beyond the frame") {
                XCTAssertEqual(reached, 1, "a click \(below) pt below the drawn button did not reach it")
            }
        #else
            XCTAssertEqual(reached, 1, "a tap \(below) pt below the drawn button did not reach it")
        #endif
    }

    /// Two size s icon-only buttons 8 pt apart: a press inside a button's drawn frame reaches it, and on iOS a tap in
    /// the gap reaches the closer one (the system's touch tolerance decides; westron adds no hit area that would hand
    /// the gap to the later sibling). On macOS a click in the gap reaches neither.
    @MainActor
    func testCloseNeighbors() {
        let first = button(ID.firstNeighbor)
        let second = button(ID.secondNeighbor)
        let gap = second.frame.minX - first.frame.maxX
        XCTAssertEqual(gap, 8, accuracy: 0.5)

        func tap(_ element: XCUIElement, edge: CGFloat, offset: CGFloat) -> String {
            press(
                element.coordinate(withNormalizedOffset: CGVector(dx: edge, dy: 0.5)).withOffset(
                    CGVector(dx: offset, dy: 0)))
            return text(ID.neighbors)
        }
        // Inside each drawn frame, 1 pt from the edge that faces the other.
        XCTAssertEqual(tap(first, edge: 1, offset: -1), "first 1, second 0")
        XCTAssertEqual(tap(second, edge: 0, offset: 1), "first 1, second 1")
        #if os(macOS)
            XCTAssertEqual(tap(first, edge: 1, offset: 3), "first 1, second 1", "a click in the gap reached a button")
        #else
            // In the gap: 3 pt from the first (5 from the second), then 5 pt from the first (3 from the second).
            XCTAssertEqual(tap(first, edge: 1, offset: 3), "first 2, second 1", "a tap closer to the first missed it")
            XCTAssertEqual(tap(first, edge: 1, offset: 5), "first 2, second 2", "a tap closer to the second missed it")
        #endif
    }
}
