import XCTest

#if os(iOS)
    import UIKit
#endif

/// The pattern `spec/patterns/choice-list-sheet.md` on the catalog's `choice-list-sheet` entry (decisions/0018, stage
/// 2): what assistive technology meets in the sheet, measured, and a press on each kind of row.
final class ChoiceListSheetTests: XCTestCase {
    private var app: XCUIApplication!

    /// The sample's words, `ChoiceListSheetSample` in WestronCatalog.
    private enum Sample {
        static let title = "Move “Core” to…"
        static let hint = "Choose where the list goes. It cannot go inside itself."
        static let choices = ["Top level", "Inbox", "Project", "Core", "Website", "Clients", "Home", "Reading"]
        static let current = "Project"
        static let unavailable = "Core"
        static let section = "WORK"
        static let heading = "PERSONAL"
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
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "choice-list-sheet"]
        app.launch()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 30), "the entry did not render")
    }

    /// The elements labelled `label`, of any type, on iOS; on macOS a text's words are its value.
    @MainActor
    private func named(_ label: String) -> [XCUIElement] {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR value == %@", label, label))
            .allElementsBoundByIndex
    }

    /// The one button labelled `label`.
    @MainActor
    private func button(_ label: String) -> XCUIElement {
        let buttons = app.buttons.matching(NSPredicate(format: "label == %@", label))
        XCTAssertEqual(buttons.count, 1, "not one button \(label)")
        return buttons.firstMatch
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
            (.button, "button"), (.header, "header"), (.selected, "selected"), (.notEnabled, "notEnabled"),
            (.staticText, "staticText"), (.image, "image"),
        ]

        /// Whether the element's traits hold `trait`.
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
            "choice-list-sheet: \(name): type \(element.elementType.rawValue), label \"\(element.label)\", "
            + "value \(String(describing: element.value)), selected \(element.isSelected), "
            + "enabled \(element.isEnabled), frame \(element.frame)"
        #if os(iOS)
            if let traits = traits(element) {
                let names = Self.traitNames.filter { traits & $0.0.rawValue != 0 }.map(\.1)
                text += ", traits \(names.joined(separator: " "))"
            }
        #endif
        return text
    }

    /// Each kind of row as assistive technology meets it: a choice, the current choice, an unavailable one, a nested
    /// one, a section that can be chosen, a section that is only a heading; the hint and the sheet's bar. The
    /// hierarchy is printed and attached.
    @MainActor
    func testWhatAssistiveTechnologyMeets() {
        launch()
        // The windows' part of the hierarchy: on macOS the application's also holds the menu bar, with the Mac's
        // recent items.
        let windows = app.windows.allElementsBoundByIndex.map(\.debugDescription).joined(separator: "\n")
        let hierarchy = XCTAttachment(string: windows)
        hierarchy.name = "choice-list-sheet-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        for text in windows.split(separator: "\n") {
            print("choice-list-sheet: hierarchy: \(text)")
        }
        for label in [Sample.title, "Cancel", Sample.hint, Sample.section, Sample.heading] + Sample.choices {
            for (index, element) in named(label).enumerated() {
                print(line("\(label) #\(index)", element))
            }
        }
        for (index, image) in app.images.allElementsBoundByIndex.enumerated() {
            print(line("image #\(index)", image))
        }

        // Each choice is one button named by its words alone; the tile and the check add none.
        for title in Sample.choices {
            let row = button(title)
            XCTAssertEqual(row.isSelected, title == Sample.current, "\(title): selected is \(row.isSelected)")
            XCTAssertEqual(row.isEnabled, title != Sample.unavailable, "\(title): enabled is \(row.isEnabled)")
        }
        // The section that can be chosen: one button named by its label.
        let section = button(Sample.section)
        XCTAssertFalse(section.isSelected)
        // The section that is only a heading: its words, no button.
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", Sample.heading)).count, 0)
        let heading = named(Sample.heading).first { $0.elementType == .staticText } ?? app.staticTexts[Sample.heading]
        XCTAssertTrue(heading.exists, "the heading's words are not text")
        // The hint is text; the bar's Cancel a button.
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", Sample.hint, Sample.hint))
                .firstMatch.exists, "the hint is not text")
        XCTAssertTrue(app.buttons["Cancel"].exists)

        // The traits VoiceOver speaks after the words, on iOS (measured 2026-11-25, iOS 26.3 simulator). On macOS the
        // hierarchy holds no traits: a heading is not told from other text there, and only the types above are held.
        // The level of a nested row is ListRow's custom content ("Level", "2"), which the hierarchy does not hold on
        // either platform; ListRow's unit tests hold it (`ListRowLevelContent`).
        #if os(iOS)
            for title in Sample.choices {
                let row = button(title)
                XCTAssertTrue(has(row, .button), "\(title) is no button")
                XCTAssertFalse(has(row, .header), "\(title) is a heading")
                XCTAssertEqual(has(row, .selected), title == Sample.current, "\(title): the selected trait")
                XCTAssertEqual(has(row, .notEnabled), title == Sample.unavailable, "\(title): the dimmed trait")
            }
            // A section that is a choice: the Rule's heading trait joins the row's one element, a button and a heading
            // at once (G3, #171).
            XCTAssertTrue(has(section, .button), "the section that can be chosen is no button")
            XCTAssertTrue(has(section, .header), "the section that can be chosen is no heading")
            // A section that is only a heading: a heading, no button.
            XCTAssertTrue(has(heading, .header), "the heading is no heading")
            XCTAssertFalse(has(heading, .button))
            // The sheet's title is the bar's heading, the system's.
            let title = app.navigationBars.staticTexts[Sample.title]
            XCTAssertTrue(title.exists, "the title is not in the bar")
            XCTAssertTrue(has(title, .header), "the bar's title is no heading")
            // The state measured today, pinned so that it is seen when it changes: beside each row with a tile, an
            // image element with no label in the row's leading half, the decorative IconTile, which its contract
            // hides (G5, #174). The leading half leaves out the current row's check, at its end.
            let unnamedImages = app.images.allElementsBoundByIndex.filter { $0.label.isEmpty }.map(\.frame)
            for title in Sample.choices {
                let row = button(title).frame
                XCTAssertTrue(
                    unnamedImages.contains { (row.minY...row.maxY).contains($0.midY) && $0.midX < row.midX },
                    "\(title): no unnamed image beside the row: issue #174 is fixed: update the pattern's "
                        + "Accessibility section and remove this pin")
            }
        #endif
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

    /// One press takes a choice: here the current mark moves to it, where a product closes the sheet. The unavailable
    /// row takes no press; a section that can be chosen takes one; Cancel puts the first choice back.
    @MainActor
    func testOnePressTakesAChoice() {
        launch()
        press(button("Inbox"))
        XCTAssertTrue(button("Inbox").isSelected, "the press did not take Inbox")
        XCTAssertFalse(button(Sample.current).isSelected, "two rows are current")
        press(button(Sample.unavailable).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertFalse(button(Sample.unavailable).isSelected, "the unavailable row took a press")
        XCTAssertTrue(button("Inbox").isSelected, "the unavailable row's press moved the current mark")
        press(button(Sample.section))
        XCTAssertTrue(button(Sample.section).isSelected, "the press did not take the section")
        XCTAssertFalse(button("Inbox").isSelected)
        press(app.buttons["Cancel"])
        #if os(macOS)
            // The entry presents a real sheet on macOS: Cancel closes it, and the page's button opens it again.
            XCTAssertTrue(app.buttons["Cancel"].waitForNonExistence(timeout: 5), "Cancel did not close the sheet")
            press(app.buttons["Open the sheet"])
            XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5), "the sheet did not open again")
        #endif
        XCTAssertTrue(button(Sample.current).isSelected, "Cancel did not put the first choice back")
        XCTAssertFalse(button(Sample.section).isSelected)
    }
}
