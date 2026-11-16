import XCTest

/// Button's behavior that a unit test cannot reach, on the catalog's `button-behavior` entry: a loading button refuses
/// every press and stays enabled; the hit area of a small button reaches the recommended target.
///
/// The entry counts accepted presses in a text, `ButtonCatalogID.count` in WestronCatalog.
final class ButtonBehaviorTests: XCTestCase {
    /// Must match `ButtonCatalogID` in WestronCatalog.
    private enum ID {
        static let rest = "button.live.rest"
        static let loading = "button.live.loading"
        static let loadingToggle = "button.live.loading-toggle"
        static let accessibilityPress = "button.live.accessibility-press"
        static let small = "button.live.small"
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

    @MainActor
    private var accepted: Int {
        // iOS puts a text's string in its label, macOS in its value.
        let text = app.staticTexts[ID.count]
        let string = text.label.isEmpty ? (text.value as? String ?? "") : text.label
        return Int(string.split(separator: " ").last ?? "") ?? -1
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
    func testRestingButtonAcceptsAPress() {
        XCTAssertEqual(accepted, 0)
        press(button(ID.rest))
        XCTAssertEqual(accepted, 1)
    }

    @MainActor
    func testLoadingButtonRefusesTouchAndPointerAndStaysEnabled() {
        let loading = button(ID.loading)
        // Not announced or treated as unavailable: enabled, with its label and "Loading" as its value.
        XCTAssertTrue(loading.isEnabled)
        XCTAssertEqual(loading.label, "Publish")
        XCTAssertEqual(loading.value as? String, "Loading")
        XCTAssertEqual(button(ID.rest).value as? String ?? "", "")
        press(loading)
        press(loading)
        XCTAssertEqual(accepted, 0, "a loading button accepted a touch or a click")
        // The control: the same input reaches a button at rest.
        press(button(ID.rest))
        XCTAssertEqual(accepted, 1)
    }

    /// Return triggers the window's default action, which the live "Publish" button is
    /// (`.keyboardShortcut(.defaultAction)`): it does at rest, and should not while loading.
    ///
    /// macOS only. On iOS 26.3 in the simulator, `typeKey` reaches no default-action shortcut, not even a system
    /// `.borderedProminent` button's, so the iOS behavior is not measured.
    ///
    /// A known contract gap (#23): on macOS SwiftUI runs a shortcut's button action itself, without the button's
    /// style, so no style can refuse it. The expected failure fails the test once that changes.
    @MainActor
    func testLoadingButtonRefusesItsKeyboardShortcut() throws {
        #if os(macOS)
            app.windows.firstMatch.click()
            app.typeKey(.return, modifierFlags: [])
            let afterLoading = accepted
            XCTExpectFailure("contract gap #23: on macOS a keyboard shortcut runs the action of a loading button") {
                XCTAssertEqual(afterLoading, 0, "Return triggered a loading default button")
            }
            // The control: out of loading, the same key triggers it.
            app.descendants(matching: .any)[ID.loadingToggle].firstMatch.click()
            XCTAssertEqual(button(ID.loading).value as? String ?? "", "", "the button is still loading")
            app.typeKey(.return, modifierFlags: [])
            XCTAssertEqual(accepted, afterLoading + 1, "Return did not trigger the default button at rest")
        #else
            throw XCTSkip("the iOS simulator's typeKey reaches no default-action shortcut")
        #endif
    }

    /// VoiceOver, Switch Control and Voice Control press a button through the accessibility API: AXPress on macOS,
    /// `accessibilityActivate()` on iOS. The runner is not trusted for that API, so the catalog makes the press itself,
    /// on Publish's own accessibility element, when its test control is pressed.
    ///
    /// A known contract gap (#23), on iOS and macOS: SwiftUI runs the action of the product's `Button` for an
    /// accessibility press itself, without the button's style, so the loading button takes it. The expected failure
    /// fails the test once that changes.
    @MainActor
    func testLoadingButtonRefusesTheAccessibilityPress() {
        let trigger = button(ID.accessibilityPress)
        press(trigger)
        XCTAssertNotEqual(
            trigger.value as? String, "not found", "the catalog found no accessibility element for Publish")
        let afterLoading = accepted
        XCTExpectFailure("contract gap #23: an accessibility press runs the action of a loading button") {
            XCTAssertEqual(afterLoading, 0, "an accessibility press triggered a loading button")
        }
        // The control: out of loading, the same press reaches it.
        let toggle = app.descendants(matching: .any)[ID.loadingToggle].firstMatch
        #if os(macOS)
            toggle.click()
        #else
            if toggle.switches.firstMatch.exists { toggle.switches.firstMatch.tap() } else { toggle.tap() }
        #endif
        press(trigger)
        XCTAssertEqual(
            accepted, afterLoading + 1,
            "an accessibility press did not reach the button at rest: \(trigger.value ?? "")")
    }

    /// A size s button is drawn smaller than the recommended target, 32 on iOS and 24 on macOS; a press just outside
    /// what is drawn, inside the target, still reaches it.
    ///
    /// On iOS the system's own touch tolerance reaches farther (about 16 pt below a 32 pt button without westron's
    /// larger content shape, 24 pt with it, measured on iOS 26.3), so there this test cannot fail. On macOS a click
    /// outside the button's frame misses whatever content shape it has: a known contract gap (#23), recorded as an
    /// expected failure.
    @MainActor
    func testSmallButtonHitAreaReachesTheTarget() {
        let small = button(ID.small)
        let frame = small.frame
        #if os(macOS)
            let target: CGFloat = 32  // size.control.m on macOS, above the recommended 28
        #else
            let target: CGFloat = 44
        #endif
        XCTAssertLessThan(frame.height, target, "the small button is drawn at the target already")
        // Just below the drawn edge, inside the extended area.
        let outside = (target - frame.height) / 2 - 1
        let point = small.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(
            CGVector(dx: 0, dy: outside))
        #if os(macOS)
            point.click()
        #else
            point.tap()
        #endif
        let reached = accepted
        #if os(macOS)
            XCTExpectFailure("contract gap #23: macOS does not extend a hit area beyond the frame") {
                XCTAssertEqual(reached, 1, "a click \(outside) pt below the drawn button did not reach it")
            }
        #else
            XCTAssertEqual(reached, 1, "a press \(outside) pt below the drawn button did not reach it")
        #endif
    }
}
