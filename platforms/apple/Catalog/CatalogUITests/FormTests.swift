import XCTest

#if os(iOS)
    import UIKit
#endif

/// The pattern `spec/patterns/form.md` on the catalog's `form` entry (decisions/0018, stage 2): what assistive
/// technology meets in its forms, measured, and what the pattern promises of them: a refused submit shows the field's
/// error under it and gives the field the caret, a keystroke takes the error away, Return moves to the next field and
/// submits from the last, the primary action loads while the product saves, and a form opened to make something new
/// focuses its field.
final class FormTests: XCTestCase {
    private var app: XCUIApplication!

    /// The samples' words, `FormSample` and the example (Forms.swift) in WestronCatalog.
    private enum Sample {
        static let titles = ["New task", "New service"]
        static let emptyTitle = "A title cannot be empty."
        static let notHTTPS = "Enter an address that starts with https://."
        static let repositoryHint = "Deployments build from this address."
        static let branchHint = "Without one, the repository’s default branch."
        static let labels = ["Name", "Repository", "Branch (optional)"]
        /// The page's identifier of the line that records the last action, `FormPageID.last`.
        static let last = "westron.catalog.form.last"
    }

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = true
    }

    @MainActor
    override func tearDown() async throws {
        app?.terminate()
    }

    @MainActor
    private func launch(_ arguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "form"] + arguments
        app.launch()
        XCTAssertTrue(app.buttons["Add"].waitForExistence(timeout: 30), "the entry did not render")
    }

    /// The text fields labelled `label`, top to bottom.
    @MainActor
    private func fields(_ label: String) -> [XCUIElement] {
        app.textFields.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    /// Quick entry's field, the first "Title" on the page; the card's is the second.
    @MainActor
    private var quickEntryTitle: XCUIElement { fields("Title")[0] }

    /// The static texts that read `words`, as their label (iOS) or their value (macOS).
    @MainActor
    private func texts(_ words: String) -> XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", words, words))
    }

    /// Whether the element holds the keyboard focus.
    @MainActor
    private func hasFocus(_ element: XCUIElement) -> Bool {
        element.value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }

    /// Whether the element holds the keyboard focus within the timeout: what a keystroke into it waits for.
    @MainActor
    private func takesFocus(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let focused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: element)
        return XCTWaiter().wait(for: [focused], timeout: timeout) == .completed
    }

    /// The words of the line that records the last action, or nil while there is none.
    @MainActor
    private func lastAction(timeout: TimeInterval = 5) -> String? {
        let line = app.staticTexts[Sample.last]
        guard line.waitForExistence(timeout: timeout) else { return nil }
        return (line.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? line.label
    }

    /// Whether the line that records the last action reads `words` within the timeout.
    @MainActor
    private func lastActionBecomes(_ words: String, timeout: TimeInterval) -> Bool {
        let reads = NSPredicate(format: "label == %@ OR value == %@", words, words)
        let expectation = XCTNSPredicateExpectation(predicate: reads, object: app.staticTexts[Sample.last])
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// The accessibility traits of the element, as the hierarchy's snapshot holds them (iOS); nil where it holds none.
    @MainActor
    private func traits(_ element: XCUIElement) -> UInt64? {
        guard let snapshot = (try? element.snapshot()) as? NSObject,
            snapshot.responds(to: NSSelectorFromString("traits"))
        else { return nil }
        return (snapshot.value(forKey: "traits") as? NSNumber)?.uint64Value
    }

    #if os(iOS)
        /// The UIKit traits named in `traits`, for the log.
        private static let traitNames: [(UIAccessibilityTraits, String)] = [
            (.button, "button"), (.header, "header"), (.staticText, "staticText"), (.image, "image"),
            (.notEnabled, "notEnabled"), (.updatesFrequently, "updatesFrequently"),
        ]

        @MainActor
        private func has(_ element: XCUIElement, _ trait: UIAccessibilityTraits) -> Bool {
            guard let traits = traits(element) else {
                XCTFail("the hierarchy's snapshot holds no traits for \(element): the measure is blind")
                return false
            }
            return traits & trait.rawValue != 0
        }
    #endif

    /// One line of what the hierarchy holds for an element, printed for the report.
    @MainActor
    private func line(_ name: String, _ element: XCUIElement) -> String {
        var text =
            "form: \(name): type \(element.elementType.rawValue), label \"\(element.label)\", "
            + "value \(String(describing: element.value)), placeholder \(String(describing: element.placeholderValue)), "
            + "enabled \(element.isEnabled), frame \(element.frame)"
        #if os(iOS)
            if let traits = traits(element) {
                let names = Self.traitNames.filter { traits & $0.0.rawValue != 0 }.map(\.1)
                text += ", traits \(names.joined(separator: " "))"
            }
        #endif
        return text
    }

    @MainActor
    private func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    /// Each part as assistive technology meets it, in reading order; the hierarchy is printed and attached.
    @MainActor
    func testWhatAssistiveTechnologyMeets() {
        launch()
        let windows = app.windows.allElementsBoundByIndex.map(\.debugDescription).joined(separator: "\n")
        let hierarchy = XCTAttachment(string: windows)
        hierarchy.name = "form-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        for text in windows.split(separator: "\n") {
            print("form: hierarchy: \(text)")
        }
        for (index, field) in app.textFields.allElementsBoundByIndex.enumerated() {
            print(line("text field #\(index)", field))
        }
        for (index, text) in app.staticTexts.allElementsBoundByIndex.enumerated() {
            print(line("text #\(index)", text))
        }
        for (index, button) in app.buttons.allElementsBoundByIndex.enumerated() {
            print(line("button #\(index)", button))
        }
        for (index, image) in app.images.allElementsBoundByIndex.enumerated() {
            print(line("image #\(index)", image))
        }

        // Every field is a text field named by its label's words; the visible labels are not elements of their own.
        XCTAssertEqual(fields("Title").count, 2, "not two fields named Title (quick entry and the card)")
        for label in Sample.labels + ["Notes"] {
            XCTAssertEqual(fields(label).count, 1, "not one field named \(label)")
        }
        for label in Sample.labels {
            XCTAssertEqual(texts(label).count, 0, "the visible label \(label) is an element of its own")
        }
        // Each form's title is a text of its own, and on iOS a heading.
        for title in Sample.titles {
            XCTAssertEqual(texts(title).count, 1, "not one text \(title)")
            #if os(iOS)
                XCTAssertTrue(has(texts(title).firstMatch, .header), "\(title) is not a heading")
            #endif
        }
        // The repository's error stands in its hint's place: a text of its own between its field and the next label's
        // field, and the hint is not there; the branch's hint is a text after its field. The error's glyph is hidden.
        let repository = fields("Repository")[0].frame
        let branch = fields("Branch (optional)")[0].frame
        let error = texts(Sample.notHTTPS)
        XCTAssertEqual(error.count, 1, "the repository's error is not one text")
        XCTAssertGreaterThan(error.firstMatch.frame.minY, repository.maxY, "the error is not under its field")
        XCTAssertLessThan(error.firstMatch.frame.maxY, branch.minY, "the error is not before the next field")
        XCTAssertEqual(texts(Sample.repositoryHint).count, 0, "the hint stands beside the error")
        XCTAssertEqual(texts(Sample.branchHint).count, 1, "the branch's hint is not one text")
        XCTAssertGreaterThan(texts(Sample.branchHint).firstMatch.frame.minY, branch.maxY, "the hint is not under")
        XCTAssertEqual(app.images.count, 0, "an image element stands in the entry")
        // The actions: Cancel and the primary, each one button named by its words, after the fields.
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == 'Cancel'")).count, 2)
        for action in ["Add", "Create"] {
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", action)).count, 1)
        }
        XCTAssertGreaterThan(app.buttons["Add"].frame.minY, quickEntryTitle.frame.maxY)
        XCTAssertGreaterThan(app.buttons["Create"].frame.minY, branch.maxY)
        XCTAssertEqual(app.buttons["Create"].value as? String ?? "", "", "Create is loading before a press")
        // No field holds the focus when the page appears without the flag.
        for field in app.textFields.allElementsBoundByIndex {
            XCTAssertFalse(hasFocus(field), "\(field.label) holds the focus on appear")
        }
    }

    /// Add with an empty title shows the sentence under the field, gives the field the caret, and records nothing; a
    /// keystroke takes the sentence away.
    @MainActor
    func testAnEmptyTitleIsRefusedUnderItsField() {
        launch()
        XCTAssertEqual(texts(Sample.emptyTitle).count, 0, "the error shows before a press")
        press(app.buttons["Add"])
        let error = texts(Sample.emptyTitle).firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5), "an empty Add showed no error")
        let field = quickEntryTitle
        XCTAssertGreaterThan(error.frame.minY, field.frame.maxY, "the error is not under its field")
        XCTAssertLessThan(error.frame.maxY, app.buttons["Add"].frame.minY, "the error is not before the actions")
        XCTAssertTrue(hasFocus(field), "the refused field did not take the caret")
        XCTAssertNil(lastAction(timeout: 1), "an empty title was taken")
        // The same refusal again, with the caret elsewhere: the field takes it back, and the sentence stands once.
        let name = fields("Name")[0]
        press(name)
        XCTAssertTrue(hasFocus(name), "a tap did not focus Name")
        press(app.buttons["Add"])
        XCTAssertTrue(hasFocus(field), "a second refusal did not give the field the caret")
        XCTAssertEqual(texts(Sample.emptyTitle).count, 1, "the second refusal's sentence is not one text")
        field.typeText("B")
        XCTAssertTrue(
            error.waitForNonExistence(timeout: 5), "a keystroke did not take the error away")
    }

    /// Return in quick entry's field submits it: an empty title is refused, a title is taken.
    @MainActor
    func testReturnSubmitsQuickEntry() {
        launch()
        let field = quickEntryTitle
        press(field)
        // A keystroke goes to the field only once it holds the focus.
        XCTAssertTrue(takesFocus(field), "a click did not focus the field")
        field.typeText("\n")
        XCTAssertTrue(texts(Sample.emptyTitle).firstMatch.waitForExistence(timeout: 5), "Return refused nothing")
        press(field)
        XCTAssertTrue(takesFocus(field), "a click did not focus the refused field")
        field.typeText("Water the plants\n")
        XCTAssertEqual(lastAction(), "Added “Water the plants”", "Return did not add the task")
        XCTAssertEqual(texts(Sample.emptyTitle).count, 0, "the error stayed after the title was taken")
    }

    /// Return moves through the service's fields in order and submits from the last; a refused field takes the caret
    /// back with its error, and Create does not load; a draft the product takes loads Create while it saves.
    @MainActor
    func testReturnMovesThroughTheFieldsAndSubmitsFromTheLast() {
        launch()
        let name = fields("Name")[0]
        let repository = fields("Repository")[0]
        let branch = fields("Branch (optional)")[0]
        let create = app.buttons["Create"]
        // The sample opens with the address refused; a change to it, still without https, takes the error away.
        let error = texts(Sample.notHTTPS).firstMatch
        XCTAssertTrue(error.exists, "the sample opened without its error")
        press(repository)
        repository.typeText("/")
        XCTAssertTrue(error.waitForNonExistence(timeout: 5), "a change did not take the error away")
        press(name)
        XCTAssertTrue(hasFocus(name), "a tap did not focus Name")
        name.typeText("\n")
        XCTAssertTrue(hasFocus(repository), "Return in Name did not move to Repository")
        repository.typeText("\n")
        XCTAssertTrue(hasFocus(branch), "Return in Repository did not move to Branch")
        // Return in the last field submits: the address is refused, its error comes back, its field takes the caret,
        // and Create does not load.
        branch.typeText("\n")
        XCTAssertTrue(error.waitForExistence(timeout: 5), "Return in the last field refused nothing")
        XCTAssertTrue(hasFocus(repository), "the field in error did not take the caret")
        XCTAssertEqual(create.value as? String ?? "", "", "a refused draft loads")
        // The page records a save as it begins, and the form loads Create only for a save it begins; the line stays
        // until the next action, so a loading however brief, over by the time of the check above, still shows here.
        XCTAssertNil(lastAction(timeout: 1), "a refused draft began a save, and Create loaded")
        // Typing in the field takes its error away; Return from the last field saves, with Create loading.
        let old = (repository.value as? String) ?? ""
        repository.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count))
        repository.typeText("https://git.example.com/billing")
        XCTAssertTrue(error.waitForNonExistence(timeout: 5), "typing did not take the error away")
        repository.typeText("\n")
        XCTAssertTrue(hasFocus(branch), "Return in Repository did not move to Branch")
        branch.typeText("\n")
        XCTAssertEqual(create.value as? String, "Loading", "Create does not load while it saves")
        XCTAssertTrue(app.buttons["Create"].isEnabled, "Create is not enabled while it loads")
        XCTAssertEqual(lastAction(), "Saving “billing”", "a save that began was not recorded as it began")
        XCTAssertTrue(lastActionBecomes("Created “billing”", timeout: 10), "the draft was not saved")
        XCTAssertEqual(app.buttons["Create"].value as? String ?? "", "", "Create still loads after the save")
    }

    /// Cancel runs its form's action, and nothing is added.
    @MainActor
    func testCancel() {
        launch()
        press(app.buttons.matching(NSPredicate(format: "label == 'Cancel'")).element(boundBy: 0))
        XCTAssertEqual(lastAction(), "Cancelled quick entry")
    }

    /// A form opened to make something new focuses its field when it appears, and the keyboard rises (iOS): here the
    /// form is the window's first content. On macOS the focus is not taken there (spec/patterns/form.md, rule 12).
    @MainActor
    func testQuickEntryFocusesItsFieldOnAppear() throws {
        #if os(macOS)
            throw XCTSkip(
                "macOS 27.2.1, 2026-11-28: a focus set in onAppear of the window's first content is dropped, though the"
                    + " window is key and the app active when the form appears; set one main-queue turn later it holds"
                    + " (spec/patterns/form.md, rule 12). Nothing on the Mac measures that the form's own onAppear focus"
                    + " holds: testQuickEntryInASheetFocusesItsField shows that quick entry in a sheet over an open"
                    + " window ends with its field focused, and testASheetFocusesItsFieldUnasked that the sheet gives"
                    + " that focus by itself.")
        #else
            launch(["-WestronFormFocusOnAppear"])
            XCTAssertTrue(takesFocus(quickEntryTitle), "quick entry did not focus its field on appear")
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "the keyboard did not rise")
        #endif
    }

    /// Opens quick entry in its sheet over the page; the sheet and its field.
    @MainActor
    private func openSheet(_ arguments: [String] = []) -> (sheet: XCUIElement, field: XCUIElement) {
        launch(["-WestronFormSheet"] + arguments)
        press(app.buttons["Open quick entry in a sheet"])
        let sheet = app.descendants(matching: .any)["westron.catalog.form.sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10), "the sheet did not open")
        let field = sheet.textFields.matching(NSPredicate(format: "label == 'Title'")).firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "the sheet holds no field named Title")
        return (sheet, field)
    }

    /// Quick entry presented in a sheet over the open window, as the pilot presents it, ends with its field focused as
    /// it appears, and the keyboard rises (iOS); Return after a title adds it and closes the sheet. Who gives the focus
    /// is `testASheetFocusesItsFieldUnasked`'s question: on macOS the sheet gives it by itself.
    @MainActor
    func testQuickEntryInASheetFocusesItsField() {
        let (sheet, field) = openSheet()
        XCTAssertTrue(takesFocus(field), "quick entry in a sheet did not end with its field focused")
        #if os(iOS)
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "the keyboard did not rise")
        #endif
        field.typeText("Water the plants\n")
        XCTAssertEqual(lastAction(), "Added “Water the plants”", "Return did not add the task")
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "a title taken did not close the sheet")
    }

    /// The control of the sheet's focus: the sheet's quick entry with `focusesOnAppear` false, so that nothing in the
    /// form asks for the focus. On macOS the sheet gives its first text field the keyboard focus by itself, so there
    /// the sheet's case does not show that the form's own focus is what holds (spec/patterns/form.md, rule 12); on iOS
    /// no field takes the focus and no keyboard rises.
    @MainActor
    func testASheetFocusesItsFieldUnasked() {
        let (_, field) = openSheet(["-WestronFormSheetAsksNoFocus"])
        #if os(macOS)
            XCTAssertTrue(takesFocus(field), "the sheet did not focus its field unasked: rule 12's control changed")
        #else
            XCTAssertFalse(takesFocus(field, timeout: 3), "the sheet focused its field unasked")
            XCTAssertFalse(app.keyboards.firstMatch.exists, "the keyboard rose with no field asking for it")
        #endif
    }
}
