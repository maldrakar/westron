import XCTest

/// ListRow's behaviour that a unit test cannot reach, on the catalog's `list-row` and `list-row-in-list` entries: what
/// assistive technology meets (the pressable row a button named by its words, selected or not, unavailable when
/// disabled; the static row one text element, selected; a chosen row announced as selected; the check at the start and
/// the chevron's cell their own elements), a press anywhere on the row that runs its action, a press on the check or on the chevron's cell that
/// neither runs nor presses the row, a row inside a system `List` with its swipe actions, and keyboard focus and Space
/// on macOS (decisions/0001, Q2, "Revision of Q1 at implementation" and "Measured").
///
/// Each entry says what its rows did in a text, `ListRowCatalogID.summary` and `ListRowCatalogID.listSummary` in
/// WestronCatalog.
final class ListRowBehaviorTests: XCTestCase {
    /// Must match `ListRowCatalogID` in WestronCatalog.
    private enum ID {
        static let check = "list-row.live.check"
        static let branch = "list-row.live.branch"
        static let summary = "list-row.live.summary"
        static let listCheck = "list-row.list.check"
        static let listSummary = "list-row.list.summary"
        static let choiceSummary = "list-row.choice.summary"
    }

    private var app: XCUIApplication!

    @MainActor
    private func launch(_ entry: String = "list-row", summary: String = ID.summary) {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", entry]
        app.launch()
        XCTAssertTrue(app.staticTexts[summary].waitForExistence(timeout: 30), "the entry did not render")
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
    private func text(_ id: String) -> String {
        let text = app.staticTexts[id]
        return text.label.isEmpty ? (text.value as? String ?? "") : text.label
    }

    /// The live summary without its count of presses: "selected: inbox; actions: 0; done: no; cell: 0".
    @MainActor
    private func state() -> String {
        let summary = text(ID.summary)
        return summary.range(of: "; presses: ").map { String(summary[..<$0.lowerBound]) } ?? summary
    }

    /// How many presses the live rows' system Buttons began.
    @MainActor
    private func presses() -> Int {
        let summary = text(ID.summary)
        return summary.range(of: "; presses: ").flatMap { Int(summary[$0.upperBound...]) } ?? -1
    }

    /// The check of a task's row: a switch on iOS, a checkbox on macOS (`CheckboxBehaviorTests`).
    @MainActor
    private func check(_ id: String) -> XCUIElement {
        #if os(macOS)
            let element = app.checkBoxes[id]
        #else
            let element = app.switches[id]
        #endif
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no check \(id)")
        return element
    }

    /// The row's button, the last whose label starts with `title`: the live rows stand at the end of the entry, after
    /// the samples of the states, the tree and the drag, which repeat their words.
    @MainActor
    private func row(_ title: String) -> XCUIElement {
        let matches = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title))
        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 5), "no row button \(title)")
        return matches.element(boundBy: matches.count - 1)
    }

    /// The live branch, Projects, and the Disclosure chevron's cell at its end (#120): the row's identifier reaches the
    /// cell inside it. The cell is the narrower, a button on iOS and a disclosure triangle on macOS, where the row is
    /// one too, as the system gives a DisclosureGroup style's label that role (`DisclosureBehaviorTests`).
    @MainActor
    private func branch() -> (row: XCUIElement, cell: XCUIElement) {
        let query = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier == %@ AND (elementType == %d OR elementType == %d)", ID.branch,
                XCUIElement.ElementType.button.rawValue, XCUIElement.ElementType.disclosureTriangle.rawValue))
        XCTAssertTrue(query.firstMatch.waitForExistence(timeout: 5), "no branch")
        let elements = query.allElementsBoundByIndex.filter { !$0.frame.isEmpty }.sorted {
            $0.frame.width < $1.frame.width
        }
        XCTAssertEqual(elements.count, 2, "the branch is not one row and one cell")
        // On macOS the identifier lands on a group around the cell's disclosure triangle: the triangle inside it.
        let cell = elements[0]
        let inner = cell.descendants(matching: .disclosureTriangle).firstMatch
        return (elements[elements.count - 1], cell.label.isEmpty && inner.exists ? inner : cell)
    }

    /// The elements whose label is `label`, of any type.
    @MainActor
    private func named(_ label: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
    }

    /// One line of what the hierarchy holds for an element, printed for the report.
    @MainActor
    private func line(_ name: String, _ element: XCUIElement) -> String {
        "list-row: \(name): type \(element.elementType.rawValue), label \(element.label), "
            + "value \(String(describing: element.value)), selected \(element.isSelected), "
            + "enabled \(element.isEnabled), frame \(element.frame)"
    }

    @MainActor
    private func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    /// Holds a press on the element long enough for a system Button under it to report its press.
    @MainActor
    private func hold(_ element: XCUIElement) {
        element.press(forDuration: 0.6)
    }

    @MainActor
    private func press(_ coordinate: XCUICoordinate) {
        #if os(macOS)
            coordinate.click()
        #else
            coordinate.tap()
        #endif
    }

    /// Scrolls the page until the element is on screen: the live rows stand at the end of the entry.
    @MainActor
    private func reveal(_ element: XCUIElement) {
        // Hittable is not enough: an element half under the window's bottom edge is hittable at its visible part, and a
        // press at its middle lands outside. It is revealed when its whole frame stands inside the window: on iOS below
        // the status bar and above the home indicator, on macOS below the title bar.
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

    /// The pressable row is a button named by its title, its second line and the words of its trailing slot, in that
    /// order; the selected row is announced as selected; a disabled row as unavailable. The check at the start is its own
    /// element before the row's, keeping its role, value and name, the chevron's cell its own element after it, and
    /// the row's leading icon is no element. The static row is one element of text, no button, announced as selected.
    /// The hierarchy measured is printed and attached.
    @MainActor
    func testAssistiveTechnologyMeetsTheRow() {
        launch()
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "list-row-hierarchy"
        // The live rows' part of the hierarchy, in the log for the report.
        for text in app.debugDescription.split(separator: "\n")
        where ["Inbox", "Today", "plumber", "Archived", "Tomorrow", "Projects", "washers"].contains(
            where: text.contains)
        {
            print("list-row: hierarchy: \(text.trimmingCharacters(in: .whitespaces))")
        }
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        let inbox = row("Inbox, 12")
        print(line("inbox", inbox))
        XCTAssertEqual(inbox.label, "Inbox, 12")
        XCTAssertTrue(inbox.isSelected, "the selected row is not announced as selected")
        XCTAssertTrue(inbox.isEnabled)
        XCTAssertEqual(inbox.descendants(matching: .image).count, 0, "the row's icon is an element of its own")
        let today = row("Today")
        print(line("today", today))
        XCTAssertEqual(today.label, "Today")
        XCTAssertFalse(today.isSelected)
        let task = row("Call the plumber")
        print(line("task", task))
        XCTAssertEqual(task.label, "Call the plumber, Tomorrow")
        let done = check(ID.check)
        print(line("check", done))
        XCTAssertEqual(done.label, "Call the plumber")
        XCTAssertFalse(done.isSelected)
        XCTAssertLessThan(done.frame.minX, task.frame.minX, "the check does not stand before the row's words")
        let archived = row("Archived")
        print(line("archived", archived))
        XCTAssertFalse(archived.isEnabled, "the disabled row is not announced as unavailable")
        // Each row's words are read once, as the row's name: no text outside the button repeats them. XCUITest lists the
        // words under the button as texts too, which are the button's; under a westron Button, since #131, it lists
        // nothing (ButtonBehaviorTests' `testIconIsNoElement`).
        // The samples above the live rows repeat Inbox, so only the words that are the live rows' alone are counted.
        for name in ["Today", "Call the plumber, Tomorrow"] {
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", name)).count, 1, "\(name) twice")
        }
        for (title, inside) in [("Today", row("Today")), ("Tomorrow", task)] {
            let all = named(title).count
            let under = inside.descendants(matching: .any).matching(NSPredicate(format: "label == %@", title)).count
            XCTAssertEqual(all - under, inside.label == title ? 1 : 0, "\(title) is read outside its row")
        }
        // Of the live rows, the selected one alone is announced as selected; the check is not.
        XCTAssertFalse(task.isSelected)
        XCTAssertFalse(archived.isSelected)
        // The branch's chevron cell, the real Disclosure's, is its own element after the row's, named by its title.
        let (projects, cell) = branch()
        print(line("projects", projects))
        print(line("cell", cell))
        XCTAssertEqual(projects.label, "Projects")
        XCTAssertEqual(cell.label, "Projects")
        XCTAssertGreaterThanOrEqual(cell.frame.minX, projects.frame.maxX - 0.5, "the cell is not after the row's words")
        // The static row: one element of its words, no button, announced as selected.
        // A text's string is its label on iOS and its value on macOS.
        let washers = app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR value == %@", "Buy washers", "Buy washers"))
        XCTAssertEqual(washers.count, 1, "the static row's words are not one element")
        XCTAssertEqual(
            app.buttons.matching(NSPredicate(format: "label == %@", "Buy washers")).count, 0,
            "the static row is announced as a button")
        let still = washers.firstMatch
        print(line("static", still))
        XCTAssertTrue(still.isSelected, "the selected static row is not announced as selected")
    }

    /// A press on a row runs its action and chooses it; a press on the check at its start toggles the check and leaves
    /// the row's action alone.
    @MainActor
    func testRowActionAndTheCheckKeepsItsPress() {
        launch()
        XCTAssertEqual(state(), "selected: inbox; actions: 0; done: no; cell: 0")
        let today = row("Today")
        reveal(today)
        press(today)
        XCTAssertEqual(state(), "selected: today; actions: 1; done: no; cell: 0")
        XCTAssertTrue(row("Today").isSelected, "the selected row is not announced as selected")
        let done = check(ID.check)
        reveal(done)
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        press(done)
        XCTAssertEqual(state(), "selected: today; actions: 1; done: yes; cell: 0", "the check's press ran the row")
        // The disabled row takes no press, though its action counts.
        let archived = row("Archived")
        reveal(archived)
        press(archived.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertEqual(state(), "selected: today; actions: 1; done: yes; cell: 0", "the disabled row ran its action")
    }

    /// A chosen row, the current value of a choice (decisions/0002): a button named by its words alone, announced as
    /// selected, though it draws nothing of the selected look, which a UI test cannot see (the unit tests and the
    /// snapshot matrix hold it); the decorative check at its end adds no word; the named Icon at its start stays its own
    /// element and is not selected; a press on the other row moves chosen, and the selected state with it. The elements
    /// are printed.
    @MainActor
    func testChosenRowIsAnnouncedAsSelected() {
        launch()
        let kitchen = row("Kitchen")
        reveal(kitchen)
        let library = row("Library")
        reveal(library)
        let flag = named("Flagged").firstMatch
        XCTAssertTrue(flag.exists, "the named Icon at the chosen row's start is no element")
        print(line("chosen kitchen", kitchen))
        print(line("chosen library", library))
        print(line("chosen flag", flag))
        for (index, image) in app.images.allElementsBoundByIndex.enumerated()
        where kitchen.frame.insetBy(dx: -60, dy: 0).intersects(image.frame) {
            print(line("chosen image #\(index)", image))
        }
        XCTAssertEqual(text(ID.choiceSummary), "chosen: kitchen")
        XCTAssertEqual(kitchen.label, "Kitchen", "the check or chosen adds a word to the row's name")
        XCTAssertTrue(kitchen.isSelected, "the chosen row is not announced as selected")
        XCTAssertEqual(library.label, "Library")
        XCTAssertFalse(library.isSelected, "a row that is not chosen is announced as selected")
        XCTAssertFalse(flag.isSelected, "chosen reached the named Icon at the row's start")
        // The row's element is the words' column, after the named element at its start, as a selected row's is. (A row
        // whose start is a decorative Icon, Library, chosen or not, has an element that also covers the hidden Icon:
        // measured on iOS 26.3, the same at rest, so not chosen's.)
        XCTAssertGreaterThanOrEqual(kitchen.frame.minX, flag.frame.maxX - 0.5, "the row's element covers its start")
        press(library)
        XCTAssertEqual(text(ID.choiceSummary), "chosen: library", "the press did not choose Library")
        XCTAssertTrue(row("Library").isSelected, "the row chosen by a press is not announced as selected")
        XCTAssertEqual(row("Library").label, "Library")
        XCTAssertFalse(row("Kitchen").isSelected, "the row no longer chosen is still announced as selected")
        XCTAssertFalse(named("Flagged").firstMatch.isSelected)
    }

    /// The chevron's cell takes its own press: it folds the branch and never runs the row's action.
    @MainActor
    func testChevronCellKeepsItsPress() {
        launch()
        reveal(branch().cell)
        press(branch().cell)
        XCTAssertEqual(state(), "selected: inbox; actions: 0; done: no; cell: 1", "the cell's press ran the row")
        // The row beside it still runs its action.
        press(branch().row)
        XCTAssertEqual(state(), "selected: projects; actions: 1; done: no; cell: 1")
    }

    /// A press held on the check at the start never presses the row: the row's system Button begins no press, so the
    /// row does not tint as pressed; a press held on the row does. The counts of begun presses are printed.
    @MainActor
    func testPressOnTheCheckDoesNotPressTheRow() {
        launch()
        let done = check(ID.check)
        reveal(done)
        let before = presses()
        hold(done)
        print("list-row: presses after holding the check: \(presses() - before)")
        XCTAssertEqual(presses(), before, "a press on the check pressed the row")
        XCTAssertEqual(state(), "selected: inbox; actions: 0; done: yes; cell: 0")
        reveal(branch().cell)
        let cell = branch().cell
        hold(cell)
        print("list-row: presses after holding the cell: \(presses() - before)")
        XCTAssertEqual(presses(), before, "a press on the chevron's cell pressed the row")
        let today = row("Today")
        reveal(today)
        hold(today)
        print("list-row: presses after holding the row: \(presses() - before)")
        XCTAssertGreaterThan(presses(), before, "a press held on the row began no press: the measure is blind")
    }

    /// The row's whole frame is its hit area: a press at the row's far end, past its words and its trailing slot, where
    /// nothing is drawn, runs its action. The frames are printed.
    @MainActor
    func testHitAreaIsTheWholeRow() {
        launch()
        let today = row("Today")
        reveal(today)
        let window = app.windows.firstMatch.frame
        print(line("today", today))
        print("list-row: window frame \(window)")
        // At the row's height, 4 pt inside the window's trailing edge and the page's margin: the row's highlight, past
        // the words.
        let end = app.windows.firstMatch.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: today.frame.maxX - 4 - window.minX, dy: today.frame.midY - window.minY))
        press(end)
        XCTAssertEqual(state(), "selected: today; actions: 1; done: no; cell: 0", "a press at the row's end missed it")
        // Below the words, inside the row's padding: the row's frame is at least the platform's target high.
        #if os(macOS)
            let target: CGFloat = 28
        #else
            let target: CGFloat = 44
        #endif
        let inbox = row("Inbox, 12")
        print(line("inbox", inbox))
        XCTAssertGreaterThanOrEqual(inbox.frame.height, target - 0.5, "the row's element is lower than the target")
        // Inbox stands right above Today: 3 pt above Today's top edge is the bottom of Inbox's row, in its padding.
        let low = app.windows.firstMatch.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: today.frame.maxX - 4 - window.minX, dy: today.frame.minY - 3 - window.minY))
        press(low)
        XCTAssertEqual(state(), "selected: inbox; actions: 2; done: no; cell: 0", "a press low in the row missed it")
    }

    /// Rows in a system List: a row's action runs, the check at the start of the first keeps its own press, and on iOS
    /// the List's swipe action deletes a row (decisions/0001, Q2: promised inside a List on this measurement). On macOS
    /// the swipe is a trackpad's gesture, which XCUITest cannot make; it is not measured there.
    @MainActor
    func testRowsInAList() {
        launch("list-row-in-list", summary: ID.listSummary)
        XCTAssertEqual(text(ID.listSummary), "actions: 0; done: no; deleted: none")
        let first = row("Call the plumber")
        print(line("list row", first))
        XCTAssertEqual(first.label, "Call the plumber")
        press(first.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)))
        XCTAssertEqual(text(ID.listSummary), "actions: 1; done: no; deleted: none", "the row's action did not run")
        let done = check(ID.listCheck)
        print(line("list check", done))
        #if os(macOS)
            Thread.sleep(forTimeInterval: NSEvent.doubleClickInterval)
        #endif
        press(done)
        XCTAssertEqual(text(ID.listSummary), "actions: 1; done: yes; deleted: none", "the check's press ran the row")
        #if os(iOS)
            let rent = row("Pay the rent")
            rent.swipeLeft()
            let delete = app.buttons["Delete"]
            XCTAssertTrue(delete.waitForExistence(timeout: 5), "the List's swipe action did not appear")
            delete.tap()
            XCTAssertEqual(
                text(ID.listSummary), "actions: 1; done: yes; deleted: Pay the rent", "the swipe action did not run")
        #endif
    }

    /// Whether the element has the keyboard focus.
    @MainActor
    private func hasFocus(_ element: XCUIElement) -> Bool {
        element.value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }

    /// macOS, with the system's keyboard navigation on: Tab reaches a row's action and the check nested in a row, and
    /// Space runs the row, as the system's buttons are; skipped with the setting off, as
    /// `ChipBehaviorTests.testKeyboardFocusAndSpace` is.
    @MainActor
    func testKeyboardFocusAndSpace() throws {
        #if os(macOS)
            guard UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode") & 2 != 0 else {
                throw XCTSkip("the system's keyboard navigation is off on this Mac")
            }
            launch()
            app.windows.firstMatch.click()
            // The check nested in the task's row is reached as its own control.
            let done = check(ID.check)
            var reachedCheck = false
            for _ in 0..<80 {
                app.typeKey(.tab, modifierFlags: [])
                if hasFocus(done) {
                    reachedCheck = true
                    break
                }
            }
            XCTAssertTrue(reachedCheck, "Tab never moved the keyboard focus to the check nested in the row")
            let today = row("Today")
            var reached = false
            for _ in 0..<80 {
                app.typeKey(.tab, modifierFlags: [])
                if hasFocus(today) {
                    reached = true
                    break
                }
            }
            XCTAssertTrue(reached, "Tab never moved the keyboard focus to the row")
            let ring = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            ring.name = "list-row-keyboard-focus"
            ring.lifetime = .keepAlways
            add(ring)
            app.typeKey(" ", modifierFlags: [])
            XCTAssertEqual(state(), "selected: today; actions: 1; done: no; cell: 0", "Space did not run the row")
        #else
            throw XCTSkip("keyboard focus is measured on macOS")
        #endif
    }
}
