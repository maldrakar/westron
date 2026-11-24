import XCTest

/// Button's behavior that a unit test cannot reach, on the catalog's `button-behavior` entry: a loading button refuses
/// presses and stays enabled; an icon-only button reads as its title; the hit area of a small button; hover at the
/// drawn shape on macOS.
///
/// The entry counts accepted presses in a text, `ButtonCatalogID.count` in WestronCatalog, and says which buttons the
/// style draws under the pointer in another, `ButtonCatalogID.hover`.
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
        static let large = "button.live.large"
        static let hover = "button.live.hover"
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

    /// Size m is drawn 36 pt tall on iOS (#85), below size.target.minimum, 44: a tap 4 pt below what is drawn, at the
    /// target's edge, must reach it, through the system's touch tolerance as at size s. The button below it in the
    /// page is loading and refuses presses, so a press counted is this button's. macOS draws m at 32 pt, above its
    /// target, and takes clicks in what it draws (testSmallButtonHitArea).
    @MainActor
    func testMediumButtonHitAreaOnTouch() throws {
        #if os(macOS)
            throw XCTSkip("macOS draws size m above its target")
        #else
            let rest = button(ID.rest)
            XCTAssertEqual(rest.frame.height, 36, accuracy: 0.5)
            press(rest.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: 4)))
            XCTAssertEqual(
                accepted, 1, "a tap 4 pt below the drawn size m button, at the target's edge, did not reach it")
        #endif
    }

    /// Publish has an icon, which the indicator replaces; "Publish now" has a label and no icon, which stays whole after
    /// the indicator while the button widens (P13).
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

    /// A label without an icon gets the indicator before it while loading, and the button widens by the indicator and
    /// the gap (P13); a label with an icon keeps its width, the indicator in the icon's place.
    @MainActor
    func testLoadingWithoutAnIconWidensTheButton() {
        let withoutIcon = button(ID.loadingWithoutIcon).frame.width
        let withIcon = button(ID.loading).frame.width
        stopLoading()
        let restWithoutIcon = button(ID.loadingWithoutIcon).frame.width
        // The indicator alone is wider than this, at any text size.
        XCTAssertGreaterThan(withoutIcon - restWithoutIcon, 10, "Publish now did not widen while loading")
        XCTAssertEqual(button(ID.loading).frame.width, withIcon, accuracy: 0.5, "Publish changed its width")
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
    /// (`.keyboardShortcut(.defaultAction)`, set outside `.loading(_:)`): it does at rest, and does not while loading,
    /// since `.loading(_:)` takes the shortcut away. ⌘E triggers Export, whose shortcut the catalog drops while it
    /// loads itself, the way a product may.
    ///
    /// macOS only. In the iOS 26.3 simulator `typeKey` reaches no shortcut, not even a system `.borderedProminent`
    /// button's default action, so the iOS (iPad hardware keyboard) behavior is not measured.
    @MainActor
    func testKeyboardShortcutsWhileLoading() throws {
        #if os(macOS)
            app.windows.firstMatch.click()
            app.typeKey(.return, modifierFlags: [])
            XCTAssertEqual(accepted, 0, "Return triggered a loading default button")
            // A product that drops the shortcut while loading: ⌘E does nothing.
            app.typeKey("e", modifierFlags: .command)
            XCTAssertEqual(accepted, 0, "⌘E triggered Export while its shortcut is dropped")
            // The control: out of loading, both keys trigger their buttons.
            stopLoading()
            app.typeKey(.return, modifierFlags: [])
            XCTAssertEqual(accepted, 1, "Return did not trigger the default button at rest")
            app.typeKey("e", modifierFlags: .command)
            XCTAssertEqual(accepted, 2, "⌘E did not trigger Export at rest")
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

    /// A size s button is drawn smaller than the recommended target, size.target.minimum: 28 pt tall on iOS (target
    /// 44, 8 pt past each edge; 32 pt before #85), 24 on macOS (target 28). The hit area the contract gives it differs
    /// by platform.
    ///
    /// iOS: a tap 8 pt below what is drawn, at the target's edge, must reach it. The hit area is the system's touch
    /// tolerance, which westron does not grow (ButtonVariantStyle.swift), and the test fails if the platform ever covers
    /// less than the target. With no other control near, the tolerance reached 16 to 19 pt past a button of size s or m
    /// on both iOS 26.3 and 27.0 (#102). A control closer than about 16 pt shares the gap with the button, which gets
    /// only part of it: in the measured cases 10 pt of a 20 pt gap, 7 of 16, and 8 (iOS 26.3) or 7.67 (27.0) of the
    /// 12 pt gap to the page's Toggle row, then below "Add". This tap sat on the boundary between the button's share and
    /// the row's, one pixel nearer the button on 27.0, and failed there. The page now keeps every other control clear of
    /// the tap ("Add" is the last button, the Toggle row above the buttons), so the test measures the system's
    /// tolerance, not the arbitration with a neighbor, and the first assertion guards that: no other control within
    /// 16 pt of the tap.
    ///
    /// macOS: the hit area is the drawn button, 24 pt, not the target (the contract's `platforms.apple.macos`, the
    /// owner's decision of 2026-11-18, #75). A click 1.5 pt inside its bottom edge, off the label of this secondary
    /// button, reaches it; a click 1.5 pt below it, inside what the target would cover, and one 3 pt below, past the
    /// target, miss. Every variant, size and icon-only is clicked the same way in ButtonHitAreaTests.
    @MainActor
    func testSmallButtonHitArea() throws {
        let small = button(ID.small)
        func pressBelow(_ below: CGFloat) {
            press(
                small.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: below)))
        }
        #if os(macOS)
            // The element's frame is the drawn button's, which the clicks are measured from.
            XCTAssertEqual(small.frame.height, 24, accuracy: 0.5)
            pressBelow(-1.5)
            XCTAssertEqual(accepted, 1, "a click 1.5 pt inside the drawn button's bottom edge did not reach it")
            // Past the double-click interval, so the next click is not taken as the second of a pair.
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
            pressBelow(1.5)
            XCTAssertEqual(accepted, 1, "a click 1.5 pt below the drawn button reached it")
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
            pressBelow(3)
            XCTAssertEqual(accepted, 1, "a click 3 pt below the drawn button reached it")
        #else
            XCTAssertEqual(small.frame.height, 28, accuracy: 0.5)
            // The precondition: no other control within 16 pt of the tap, or the tap measures the neighbor's share.
            let tap = CGPoint(x: small.frame.midX, y: small.frame.maxY + 8)
            let controls: Set<XCUIElement.ElementType> = [
                .button, .switch, .toggle, .textField, .secureTextField, .slider, .stepper, .link, .segmentedControl,
            ]
            func near(_ element: XCUIElementSnapshot) -> [String] {
                let frame = element.frame
                let dx = max(frame.minX - tap.x, 0, tap.x - frame.maxX)
                let dy = max(frame.minY - tap.y, 0, tap.y - frame.maxY)
                let isNear =
                    controls.contains(element.elementType) && element.identifier != ID.small
                    && (dx * dx + dy * dy).squareRoot() < 16
                return (isNear ? ["\(element.identifier) \(element.frame)"] : []) + element.children.flatMap(near)
            }
            let crowding = try near(app.snapshot())
            XCTAssertEqual(crowding, [], "a control within 16 pt of the tap 8 pt below \"Add\" shares its tolerance")
            pressBelow(8)
            XCTAssertEqual(accepted, 1, "a tap 8 pt below the drawn button, at the target's edge, did not reach it")
        #endif
    }

    // MARK: - Hover at the drawn shape (#130)

    /// Where the pointer went over one button, and what the hover readout said there.
    private struct HoverOutcome {
        let place: String
        let expected: Bool
        let readout: String
    }

    /// Moves the pointer to `place` and waits on the readout `id`: when `expected`, until it reads "hover: `name`",
    /// within 5 s; otherwise for 1 s, in which it must never read so. Returns what it reads after the wait.
    @MainActor
    private func hover(_ place: XCUICoordinate, readout id: String, name: String, expected: Bool) -> String {
        place.hover()
        let hovered = "hover: \(name)"
        let predicate = NSPredicate(format: "label == %@ OR value == %@", hovered, hovered)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.staticTexts[id])
        expectation.isInverted = !expected
        _ = XCTWaiter().wait(for: [expectation], timeout: expected ? 5 : 1)
        return text(id)
    }

    /// Hovers one button, `element`, named `name` in the readout `id`, with the pointer: away from it (on `away`); in
    /// its frame's top-left and bottom-right corners, 2 pt in from the side and 1 pt in from the top or bottom, outside
    /// the drawn shape's round end; 1.5 pt inside the round end, on the diagonal toward the top-left corner; back in a
    /// corner; in its middle; in the other corner; away. Every shape Button draws is a capsule of radius half its
    /// height, a circle when icon-only, so each corner point lies outside it at every size. Prints each outcome,
    /// `MEASURE hover: …`, and returns them.
    @MainActor
    private func measureHover(_ element: XCUIElement, name: String, readout id: String, away: XCUIElement)
        -> [HoverOutcome]
    {
        let frame = element.frame
        let radius = frame.height / 2
        let origin = element.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate { origin.withOffset(CGVector(dx: x, dy: y)) }
        let inRoundEnd = radius - (radius - 1.5) / 2.squareRoot()
        let awayPoint = away.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let places: [(String, XCUICoordinate, Bool)] = [
            ("away", awayPoint, false),
            ("in the top-left corner", point(2, 1), false),
            ("in the bottom-right corner", point(frame.width - 2, frame.height - 1), false),
            ("inside the round end", point(inRoundEnd, inRoundEnd), true),
            ("back in the top-left corner", point(2, 1), false),
            ("in the middle", point(frame.width / 2, frame.height / 2), true),
            ("back in the bottom-right corner", point(frame.width - 2, frame.height - 1), false),
            ("away again", awayPoint, false),
        ]
        return places.map { place, coordinate, expected in
            let now = hover(coordinate, readout: id, name: name, expected: expected)
            print("MEASURE hover: \(name), frame \(frame), pointer \(place): \(now)")
            return HoverOutcome(place: place, expected: expected, readout: now)
        }
    }

    /// Fails for each outcome that differs from what is expected: "hover: `name`" inside the drawn shape, "hover:
    /// none" outside it.
    private func assertHover(_ outcomes: [(name: String, outcomes: [HoverOutcome])]) {
        for (name, list) in outcomes {
            for outcome in list {
                XCTAssertEqual(
                    outcome.readout, outcome.expected ? "hover: \(name)" : "hover: none",
                    "\(name), the pointer \(outcome.place)")
            }
        }
    }

    /// macOS: hover starts and ends at the drawn shape, not at the corners of its frame (#130). The pointer in the
    /// frame's corner, outside the capsule's round end, leaves the button at rest; 1.5 pt inside the round end, and in
    /// the middle, it is hovered. Sizes s, m and l with a label, and icon-only, a circle, at s and m. Each outcome is
    /// measured before any is asserted, and printed (`measureHover`). A guard of behaviour that held before #130 too:
    /// with `onHover` in place of `ShapeHover`, these buttons, whose interaction shape on macOS is the capsule, read no
    /// hover in their frames' corners, and this test passed (the review of #146). The test that fails without the fix
    /// is `testFloatingHoverAtTheDrawnShape`.
    @MainActor
    func testHoverAtTheDrawnShape() throws {
        #if os(macOS)
            let away = app.staticTexts[ID.count]
            XCTAssertEqual(text(ID.hover), "hover: none", "a button is hovered with the pointer away")
            var outcomes: [(name: String, outcomes: [HoverOutcome])] = []
            for (id, name) in [
                (ID.small, "small"), (ID.rest, "rest"), (ID.large, "large"), (ID.firstNeighbor, "neighbor-first"),
                (ID.iconOnly, "icon-only"),
            ] {
                let element = button(id)
                XCTAssertTrue(element.isHittable, "\(name) is not on screen")
                outcomes.append((name, measureHover(element, name: name, readout: ID.hover, away: away)))
            }
            for id in [ID.firstNeighbor, ID.iconOnly] {
                XCTAssertEqual(button(id).frame.width, button(id).frame.height, accuracy: 0.5, "\(id) is not a circle")
            }
            assertHover(outcomes)
        #else
            throw XCTSkip("a pointer's hover is measured on macOS")
        #endif
    }

    // MARK: - Floating (#121, decisions/0015), on the `button-floating` entry

    /// Must match `ButtonFloatingID` in WestronCatalog.
    private enum FloatingID {
        static let back = "button.floating.live.back"
        static let more = "button.floating.live.more"
        static let add = "button.floating.live.add"
        static let disabled = "button.floating.live.disabled"
        static let count = "button.floating.live.count"
        static func overList(_ size: String) -> String { "button.floating.over-list.\(size)" }
        static let overListRow = "button.floating.over-list.row"
        static let overListCount = "button.floating.over-list.count"
        static let hover = "button.floating.live.hover"
    }

    /// Relaunches the catalog on the `button-floating` entry.
    @MainActor
    private func launchFloating() {
        app.terminate()
        app.launchArguments = ["-WestronEntry", "button-floating"]
        app.launch()
        XCTAssertTrue(app.staticTexts[FloatingID.count].waitForExistence(timeout: 30), "the entry did not render")
    }

    @MainActor
    private var acceptedFloating: Int {
        Int(text(FloatingID.count).split(separator: " ").last ?? "") ?? -1
    }

    /// A floating button is a button with its name, on glass (secondary) and on its fill (primary): icon-only, it
    /// reads as its title and nothing else, and a press reaches it.
    @MainActor
    func testFloatingButtonsAreButtonsWithTheirNames() {
        launchFloating()
        for (id, name, count) in [
            (FloatingID.back, "Back", 1), (FloatingID.more, "More", 2), (FloatingID.add, "Add", 3),
        ] {
            let floating = button(id)
            XCTAssertEqual(floating.label, name)
            XCTAssertEqual(floating.elementType, .button)
            XCTAssertTrue(floating.isEnabled, "\(name) is not enabled")
            XCTAssertEqual(floating.value as? String ?? "", "")
            press(floating)
            XCTAssertEqual(acceptedFloating, count, "a press on the floating \(name) did not reach it")
        }
    }

    /// macOS: a floating button's hover starts and ends at its drawn capsule too, as `testHoverAtTheDrawnShape`
    /// measures: Back, icon-only at size m, and the buttons over a list at s, m and l, on the system's glass from OS 26,
    /// and Add, a floating primary on its fill. The glass is interactive and answers the pointer itself
    /// (decisions/0015): Back's own pixels are compared, the pointer away, in the frame's corner and in the middle, and
    /// what changed is printed, `MEASURE glass: …`, not asserted, since the response is the system's.
    @MainActor
    func testFloatingHoverAtTheDrawnShape() throws {
        #if os(macOS)
            launchFloating()
            let away = app.staticTexts[FloatingID.count]
            XCTAssertEqual(text(FloatingID.hover), "hover: none", "a button is hovered with the pointer away")
            var outcomes: [(name: String, outcomes: [HoverOutcome])] = []
            for (id, name) in [
                (FloatingID.back, "back"), (FloatingID.add, "add"), (FloatingID.overList("s"), "over-list-s"),
                (FloatingID.overList("m"), "over-list-m"), (FloatingID.overList("l"), "over-list-l"),
            ] {
                let element = button(id)
                XCTAssertTrue(element.isHittable, "\(name) is not on screen")
                outcomes.append((name, measureHover(element, name: name, readout: FloatingID.hover, away: away)))
            }
            // The glass's own answer to the pointer, on Back.
            let back = button(FloatingID.back)
            let awayPoint = away.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            func shot(_ place: XCUICoordinate, _ name: String) -> NSImage {
                place.hover()
                // The glass's response, and westron's fade if any, settle.
                Thread.sleep(forTimeInterval: 1)
                let image = back.screenshot().image
                let attachment = XCTAttachment(image: image)
                attachment.name = "Back, the pointer \(name)"
                attachment.lifetime = .keepAlways
                add(attachment)
                return image
            }
            let rest = shot(awayPoint, "away")
            let corner = shot(
                back.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: 2, dy: 1)),
                "in the corner")
            let middle = shot(back.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)), "in the middle")
            let restAgain = shot(awayPoint, "away again")
            for (name, image) in [("away again", restAgain), ("in the corner", corner), ("in the middle", middle)] {
                print("MEASURE glass: Back, the pointer \(name), against away: \(PixelDifference(rest, image))")
            }
            assertHover(outcomes)
        #else
            throw XCTSkip("a pointer's hover is measured on macOS")
        #endif
    }

    /// A disabled floating button on glass is announced as unavailable and takes no press.
    @MainActor
    func testDisabledFloatingButtonRefusesPresses() {
        launchFloating()
        let disabled = button(FloatingID.disabled)
        XCTAssertEqual(disabled.label, "Share")
        XCTAssertFalse(disabled.isEnabled, "the disabled floating button is enabled")
        press(disabled)
        XCTAssertEqual(acceptedFloating, 0, "a disabled floating button accepted a press")
    }

    /// A floating button keeps Button's hit area. On iOS, Back, size m icon-only on glass, is drawn 36 pt, below
    /// size.target.minimum: a tap 4 pt below what is drawn, at the target's edge, reaches it through the system's touch
    /// tolerance, as for any Button (testMediumButtonHitAreaOnTouch). On macOS the hit area is the drawn button: a
    /// click 1.5 pt inside its bottom edge reaches it, one 1.5 pt below misses (ButtonHitAreaTests clicks every size,
    /// variant and the look before OS 26).
    @MainActor
    func testFloatingButtonHitArea() {
        launchFloating()
        let back = button(FloatingID.back)
        func pressBelow(_ below: CGFloat) {
            press(
                back.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: below)))
        }
        #if os(macOS)
            XCTAssertEqual(back.frame.height, 32, accuracy: 0.5)
            pressBelow(-1.5)
            XCTAssertEqual(acceptedFloating, 1, "a click 1.5 pt inside the floating button's bottom edge missed it")
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
            pressBelow(1.5)
            XCTAssertEqual(acceptedFloating, 1, "a click 1.5 pt below the floating button reached it")
        #else
            XCTAssertEqual(back.frame.height, 36, accuracy: 0.5)
            XCTAssertEqual(back.frame.width, 36, accuracy: 0.5)
            pressBelow(4)
            XCTAssertEqual(acceptedFloating, 1, "a tap 4 pt below the floating button, at the target's edge, missed it")
        #endif
    }

    /// A floating secondary of each size on glass over a list a product presses: where a press at and a few points
    /// outside the drawn button goes, to the button or to the row beneath it (decisions/0015, the contract's
    /// `platforms.apple.ios`). Each outcome is printed, `MEASURE over a list: …`. Measured on iOS 26.3: a press 2 pt
    /// inside and half a point inside the drawn edge reaches the button at every size; 1 pt and 4 pt past it, below or
    /// beside, the row takes it at every size: over a pressable row the system's touch tolerance gives the button
    /// nothing past what it draws, so only size l, 50 pt, reaches size.target.minimum. The test holds the presses
    /// inside to the button and only prints the others, which are the system's to change.
    @MainActor
    func testFloatingButtonOverAPressableList() {
        launchFloating()
        let count = app.staticTexts[FloatingID.overListCount]
        XCTAssertTrue(count.waitForExistence(timeout: 10), "no list under floating buttons")
        func counts() -> (rows: Int, floating: Int) {
            let numbers = text(FloatingID.overListCount).split(whereSeparator: { !$0.isNumber })
            return (Int(numbers.first ?? "") ?? -1, Int(numbers.last ?? "") ?? -1)
        }
        var outcomes: [String: String] = [:]
        for size in ["s", "m", "l"] {
            let floating = button(FloatingID.overList(size))
            for (side, offset) in [
                ("inside", CGVector(dx: 0, dy: -2)), ("at the edge", CGVector(dx: 0, dy: -0.5)),
                ("just below", CGVector(dx: 0, dy: 1)), ("below", CGVector(dx: 0, dy: 4)),
                ("beside", CGVector(dx: 4, dy: 0)),
            ] {
                #if os(macOS)
                    Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
                #endif
                let before = counts()
                let edge = side == "beside" ? CGVector(dx: 1, dy: 0.5) : CGVector(dx: 0.5, dy: 1)
                press(floating.coordinate(withNormalizedOffset: edge).withOffset(offset))
                let after = counts()
                let outcome =
                    after.floating > before.floating ? "button" : after.rows > before.rows ? "row" : "nothing"
                outcomes["\(size) \(side)"] = outcome
                print("MEASURE over a list: size \(size), \(side) \(offset): \(outcome), frame \(floating.frame)")
            }
        }
        for size in ["s", "m", "l"] {
            XCTAssertEqual(outcomes["\(size) inside"], "button", "a press inside the floating \(size) missed it")
            XCTAssertEqual(
                outcomes["\(size) at the edge"], "button", "a press at the floating \(size)'s drawn edge missed it")
        }
    }

    /// Two size s icon-only buttons 8 pt apart: a press inside a button's drawn frame reaches it, and on iOS a tap in
    /// the gap reaches the closer one (the system's touch tolerance decides; westron adds no hit area that would hand
    /// the gap to the later sibling). On macOS a click in the gap reaches neither.
    ///
    /// On macOS the clicks are further apart than the double-click interval: a click on the second button within it of
    /// one on the first was lost now and then (3 of 8 such pairs in one run, none of 5 pairs spaced past the interval),
    /// which made this test flaky.
    @MainActor
    func testCloseNeighbors() {
        let first = button(ID.firstNeighbor)
        let second = button(ID.secondNeighbor)
        let gap = second.frame.minX - first.frame.maxX
        XCTAssertEqual(gap, 8, accuracy: 0.5)

        func tap(_ element: XCUIElement, edge: CGFloat, offset: CGFloat) -> String {
            #if os(macOS)
                Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
            #endif
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

#if os(macOS)
    /// How many pixels of two screenshots of one element differ by more than two levels in any channel, of how many,
    /// and by how much at most.
    private struct PixelDifference: CustomStringConvertible {
        let changed: Int
        let total: Int
        let largest: Int

        init(_ a: NSImage, _ b: NSImage) {
            let first = Self.pixels(a)
            let second = Self.pixels(b)
            guard first.width == second.width, first.height == second.height, !first.bytes.isEmpty else {
                changed = -1
                total = 0
                largest = 0
                return
            }
            var changed = 0
            var largest = 0
            for index in stride(from: 0, to: first.bytes.count, by: 4) {
                var most = 0
                for channel in 0..<4 {
                    most = max(most, abs(Int(first.bytes[index + channel]) - Int(second.bytes[index + channel])))
                }
                if most > 2 { changed += 1 }
                largest = max(largest, most)
            }
            self.changed = changed
            self.total = first.width * first.height
            self.largest = largest
        }

        var description: String {
            changed < 0 ? "not comparable" : "\(changed) of \(total) px differ, by up to \(largest) levels"
        }

        private static func pixels(_ image: NSImage) -> (width: Int, height: Int, bytes: [UInt8]) {
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return (0, 0, []) }
            let width = cgImage.width
            let height = cgImage.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(
                    data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            return (width, height, bytes)
        }
    }
#endif
