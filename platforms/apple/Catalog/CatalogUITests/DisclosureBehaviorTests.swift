import XCTest

/// Disclosure's behaviour that a unit test cannot reach, on the catalog's `disclosure` entry: what assistive technology
/// meets (the chevron's cell its own element, named by the label, a disclosure triangle with its expanded value on
/// macOS and a button on iOS, as the system's own DisclosureGroup is on each), a press on the chevron that folds and
/// unfolds the group, a press on the label that runs the label's action and folds nothing, a press on the chevron that
/// never runs the row's action, the hit area around the drawn circle, hover at the circle on macOS, and the keyboard
/// on macOS (decisions/0001, Q1, Q4 and "Measured").
///
/// The entry says what its live samples did in a text, `DisclosureCatalogID.summary` in WestronCatalog: "branch:
/// expanded; block: collapsed; toggles: 0; actions: 0; opened: 0; hover: no".
final class DisclosureBehaviorTests: XCTestCase {
    /// Must match `DisclosureCatalogID` in WestronCatalog.
    private enum ID {
        static let row = "disclosure.live.row"
        static let title = "disclosure.live.title"
        static let summary = "disclosure.live.summary"
        static let branchContent = "disclosure.live.branch-content"
        static let blockContent = "disclosure.live.block-content"
    }

    #if os(macOS)
        /// The cell's hit area, `size.target.minimum`, and its drawn circle, `size.control.s`, on macOS.
        private let target: CGFloat = 28
        private let drawn: CGFloat = 24
    #else
        private let target: CGFloat = 44
        private let drawn: CGFloat = 28
    #endif

    private var app: XCUIApplication!

    @MainActor
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "disclosure"]
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

    /// The live summary: iOS puts a text's string in its label, macOS in its value.
    @MainActor
    private var summary: String {
        let text = app.staticTexts[ID.summary]
        return text.label.isEmpty ? (text.value as? String ?? "") : text.label
    }

    /// Whether the summary starts with `expected` within the timeout: a press on the cell leaves the pointer on it on
    /// macOS, so the tests that press read the summary up to the hover, and the hover test reads it whole.
    @MainActor
    private func reads(_ expected: String, within timeout: TimeInterval = 5) -> Bool {
        let text = app.staticTexts[ID.summary]
        let predicate = NSPredicate(format: "label BEGINSWITH %@ OR value BEGINSWITH %@", expected, expected)
        _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: text)], timeout: timeout)
        // The expectation polls about once a second: the summary as it reads now decides.
        let now = summary
        if !now.hasPrefix(expected) { print("disclosure: summary reads \(now), expected \(expected)") }
        return now.hasPrefix(expected)
    }

    /// The label and the chevron's cell of a live sample: the identifier the catalog sets on the label reaches the
    /// cell too, as it stands inside the row or beside the label. The cell is the narrower of the two, a button on iOS
    /// and a disclosure triangle on macOS, where the label is one too (`testAssistiveTechnologyMeetsTheDisclosure`).
    @MainActor
    private func parts(_ id: String) -> (label: XCUIElement, cell: XCUIElement) {
        let query = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier == %@ AND (elementType == %d OR elementType == %d)", id,
                XCUIElement.ElementType.button.rawValue, XCUIElement.ElementType.disclosureTriangle.rawValue))
        XCTAssertTrue(query.firstMatch.waitForExistence(timeout: 5), "no element \(id)")
        let elements = query.allElementsBoundByIndex.filter { !$0.frame.isEmpty }
        XCTAssertEqual(elements.count, 2, "\(id): not one label and one cell: \(elements.map(\.debugDescription))")
        let sorted = elements.sorted { $0.frame.width < $1.frame.width }
        return (sorted[sorted.count - 1], named(sorted[0]))
    }

    /// The element, or on macOS, where a row's identifier lands on a group around the cell's disclosure triangle, the
    /// triangle inside it.
    @MainActor
    private func named(_ element: XCUIElement) -> XCUIElement {
        guard element.label.isEmpty else { return element }
        let inner = element.descendants(matching: .disclosureTriangle).firstMatch
        return inner.exists ? inner : element
    }

    /// One line of what the hierarchy holds for an element, printed for the report.
    @MainActor
    private func line(_ name: String, _ element: XCUIElement) -> String {
        "disclosure: \(name): type \(element.elementType.rawValue), label \(element.label), "
            + "value \(String(describing: element.value)), enabled \(element.isEnabled), frame \(element.frame)"
    }

    @MainActor
    private func press(_ element: XCUIElement) {
        press(element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
    }

    @MainActor
    private func press(_ coordinate: XCUICoordinate) {
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
    }

    /// Scrolls the page until the element stands wholly inside the window: the live samples are near the entry's end.
    @MainActor
    private func reveal(_ element: XCUIElement) {
        #if os(macOS)
            let margin: CGFloat = 28
        #else
            let margin: CGFloat = 60
        #endif
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: margin)
        for _ in 0..<12 where !(element.isHittable && window.contains(element.frame)) {
            #if os(macOS)
                app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -200)
            #else
                app.swipeUp()
            #endif
        }
        XCTAssertTrue(window.contains(element.frame), "\(element) never came wholly on screen")
    }

    /// Whether the element exists within a short wait, or no longer exists.
    @MainActor
    private func shown(_ id: String) -> Bool {
        app.staticTexts[id].waitForExistence(timeout: 2)
    }

    @MainActor
    private func hidden(_ id: String) -> Bool {
        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: app.staticTexts[id])
        return XCTWaiter().wait(for: [gone], timeout: 5) == .completed
    }

    /// The chevron's cell is its own element, after the label's, named by the label: by a ListRow's title when the row
    /// draws it, by the whole label otherwise. On macOS it is a disclosure triangle whose value is 1 expanded and 0
    /// collapsed, as the system's own DisclosureGroup; on iOS a button, as the system's own is there, valued "Expanded"
    /// or "Collapsed", which SwiftUI gives no public status for. The
    /// chevron's glyph is no element. On macOS the label is a disclosure triangle with the group's value too: the
    /// system gives a DisclosureGroup style's label that role (measured, decisions/0001). The hierarchy is printed and
    /// attached.
    @MainActor
    func testAssistiveTechnologyMeetsTheDisclosure() {
        launch()
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "disclosure-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        for text in app.debugDescription.split(separator: "\n")
        where ["Projects", "Tomorrow", "washers", "plumber", "Work", "'rest'", "Today"].contains(where: text.contains) {
            print("disclosure: hierarchy: \(text.trimmingCharacters(in: .whitespaces))")
        }
        let branch = parts(ID.row)
        let block = parts(ID.title)
        for (name, element) in [
            ("row", branch.label), ("row's cell", branch.cell), ("title", block.label), ("title's cell", block.cell),
        ] {
            print(line(name, element))
        }
        XCTAssertEqual(branch.label.label, "Projects, 5")
        XCTAssertEqual(branch.cell.label, "Projects", "the cell is not named by the row's title")
        XCTAssertEqual(block.label.label, "Tomorrow")
        XCTAssertEqual(block.cell.label, "Tomorrow", "the cell is not named by the label")
        for (label, cell) in [branch, block] {
            XCTAssertGreaterThanOrEqual(cell.frame.minX, label.frame.maxX - 0.5, "the cell is not after the label")
            XCTAssertEqual(cell.descendants(matching: .image).count, 0, "the chevron's glyph is an element")
        }
        #if os(macOS)
            XCTAssertEqual(branch.cell.elementType, .disclosureTriangle)
            XCTAssertEqual(block.cell.elementType, .disclosureTriangle)
            XCTAssertEqual(branch.cell.value as? Int, 1, "the expanded branch's cell does not read expanded")
            XCTAssertEqual(block.cell.value as? Int, 0, "the collapsed block's cell does not read collapsed")
            // The system's own doing: the label of a DisclosureGroup style is a disclosure triangle with the value.
            XCTAssertEqual(branch.label.elementType, .disclosureTriangle)
            XCTAssertEqual(branch.label.value as? Int, 1)
        #else
            XCTAssertEqual(branch.cell.elementType, .button)
            XCTAssertEqual(block.cell.elementType, .button)
            XCTAssertEqual(
                branch.cell.value as? String, "Expanded", "the expanded branch's cell does not read expanded")
            XCTAssertEqual(
                block.cell.value as? String, "Collapsed", "the collapsed block's cell does not read collapsed")
            // The row adds no value of its own: the state is the cell's, read right after it.
            XCTAssertEqual(branch.label.elementType, .button)
            XCTAssertEqual(branch.label.value as? String ?? "", "")
        #endif
    }

    /// A disabled group's cell is announced as unavailable and takes no press: the catalog's disabled sample, collapsed
    /// and expanded.
    @MainActor
    func testDisabledCellIsUnavailable() {
        launch()
        let cells = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "(elementType == %d OR elementType == %d) AND label == %@",
                XCUIElement.ElementType.button.rawValue, XCUIElement.ElementType.disclosureTriangle.rawValue,
                "disabled")
        )
        .allElementsBoundByIndex
        .filter { $0.frame.width <= 48 }
        XCTAssertFalse(cells.isEmpty, "the disabled samples have no cell")
        for cell in cells {
            print(line("disabled cell", cell))
            XCTAssertFalse(cell.isEnabled, "a disabled group's cell is announced as available")
        }
    }

    /// A press on the chevron folds the group and a second unfolds it: the content goes and comes back, and the label's
    /// action does not run.
    @MainActor
    func testChevronFoldsAndUnfolds() {
        launch()
        XCTAssertTrue(reads("branch: expanded; block: collapsed; toggles: 0; actions: 0; opened: 0"))
        let branch = parts(ID.row)
        reveal(branch.cell)
        XCTAssertTrue(shown(ID.branchContent), "the expanded branch shows no content")
        press(parts(ID.row).cell)
        XCTAssertTrue(reads("branch: collapsed; block: collapsed; toggles: 1; actions: 0; opened: 0"))
        XCTAssertTrue(hidden(ID.branchContent), "the folded branch still shows its content")
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        press(parts(ID.row).cell)
        XCTAssertTrue(reads("branch: expanded; block: collapsed; toggles: 2; actions: 0; opened: 0"))
        XCTAssertTrue(shown(ID.branchContent), "the unfolded branch shows no content")
        // The block header's chevron, after a label that is no row.
        XCTAssertFalse(shown(ID.blockContent), "the collapsed block shows its content")
        let block = parts(ID.title)
        reveal(block.cell)
        press(block.cell)
        XCTAssertTrue(reads("branch: expanded; block: expanded; toggles: 3; actions: 0; opened: 0"))
        XCTAssertTrue(shown(ID.blockContent), "the opened block shows no content")
        #if os(macOS)
            XCTAssertEqual(parts(ID.title).cell.value as? Int, 1, "the cell does not read expanded after the press")
        #else
            XCTAssertEqual(
                parts(ID.title).cell.value as? String, "Expanded", "the cell does not read expanded after the press")
        #endif
    }

    /// A press on the label runs the label's action and folds nothing: the row is chosen, the block's title opens the
    /// block, and both groups keep their state.
    @MainActor
    func testLabelKeepsItsAction() {
        launch()
        let branch = parts(ID.row)
        reveal(branch.label)
        press(branch.label)
        XCTAssertTrue(reads("branch: expanded; block: collapsed; toggles: 0; actions: 1; opened: 0"))
        XCTAssertTrue(shown(ID.branchContent), "the row's action folded the branch")
        let block = parts(ID.title)
        reveal(block.label)
        press(block.label)
        XCTAssertTrue(reads("branch: expanded; block: collapsed; toggles: 0; actions: 1; opened: 1"))
        XCTAssertFalse(shown(ID.blockContent), "the title's action unfolded the block")
    }

    /// The cell's hit area is at least `size.target.minimum` high and across, around the drawn circle: a press in its
    /// corner, outside the circle, still folds the group. The frames are printed.
    @MainActor
    func testHitAreaAroundTheCircle() {
        launch()
        let branch = parts(ID.row)
        reveal(branch.cell)
        let cell = parts(ID.row).cell
        print(line("row's cell", cell))
        XCTAssertGreaterThanOrEqual(cell.frame.height, target - 0.5, "the cell is lower than the target")
        XCTAssertGreaterThanOrEqual(cell.frame.width, target - 0.5, "the cell is narrower than the target")
        // 2 pt inside the frame's top leading corner: outside a circle of `drawn` at its middle.
        let corner = cell.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 2, dy: 2))
        press(corner)
        XCTAssertTrue(
            reads("branch: collapsed; block: collapsed; toggles: 1; actions: 0; opened: 0"),
            "a press in the hit area's corner missed the cell")
    }

    /// macOS: hover starts and ends at the drawn circle, not at the hit area laid out around it. The pointer in the
    /// hit area's corner leaves the cell at rest; at the circle's middle it is hovered; back in the corner, at rest.
    @MainActor
    func testHoverAtTheCircle() throws {
        #if os(macOS)
            launch()
            reveal(parts(ID.row).cell)
            let cell = parts(ID.row).cell
            print(line("row's cell", cell))
            let frame = cell.frame
            let origin = cell.coordinate(withNormalizedOffset: .zero)
            let corner = origin.withOffset(CGVector(dx: 1, dy: 1))
            let middle = origin.withOffset(CGVector(dx: frame.width / 2, dy: frame.height / 2))
            app.staticTexts[ID.summary].hover()
            XCTAssertTrue(reads("branch: expanded; block: collapsed; toggles: 0; actions: 0; opened: 0; hover: no"))
            corner.hover()
            XCTAssertTrue(
                reads("branch: expanded; block: collapsed; toggles: 0; actions: 0; opened: 0; hover: no", within: 1),
                "the pointer in the hit area's corner hovers the cell")
            middle.hover()
            XCTAssertTrue(
                reads("branch: expanded; block: collapsed; toggles: 0; actions: 0; opened: 0; hover: yes"),
                "the pointer at the circle's middle does not hover the cell")
            corner.hover()
            XCTAssertTrue(
                reads("branch: expanded; block: collapsed; toggles: 0; actions: 0; opened: 0; hover: no"),
                "hover did not end as the pointer left the circle")
        #else
            throw XCTSkip("a pointer's hover is measured on macOS")
        #endif
    }

    /// macOS, with the system's keyboard navigation on: Tab reaches the chevron's cell, Space toggles it, and Left and
    /// Right collapse and expand it, as an outline's disclosure triangle. With it off, as on a Mac by default, the
    /// test is skipped (`CheckboxBehaviorTests.testKeyboardFocusAndSpace`).
    @MainActor
    func testKeyboard() throws {
        #if os(macOS)
            guard UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode") & 2 != 0 else {
                throw XCTSkip("the system's keyboard navigation is off on this Mac")
            }
            launch()
            app.windows.firstMatch.click()
            let block = parts(ID.title)
            var reached = false
            for _ in 0..<80 {
                app.typeKey(.tab, modifierFlags: [])
                if block.cell.value(forKey: "hasKeyboardFocus") as? Bool ?? false {
                    reached = true
                    break
                }
            }
            XCTAssertTrue(reached, "Tab never moved the keyboard focus to the block's chevron")
            app.typeKey(" ", modifierFlags: [])
            XCTAssertTrue(reads("branch: expanded; block: expanded; toggles: 1; actions: 0; opened: 0"))
            app.typeKey(.leftArrow, modifierFlags: [])
            XCTAssertTrue(reads("branch: expanded; block: collapsed; toggles: 2; actions: 0; opened: 0"))
            app.typeKey(.rightArrow, modifierFlags: [])
            XCTAssertTrue(reads("branch: expanded; block: expanded; toggles: 3; actions: 0; opened: 0"))
        #else
            throw XCTSkip("keyboard focus is measured on macOS")
        #endif
    }
}
