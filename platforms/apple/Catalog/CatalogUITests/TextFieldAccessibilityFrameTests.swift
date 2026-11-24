import XCTest

/// The accessibility frame of TextField's live fields (#135), on the catalog's `text-field-behavior` entry, against the
/// field westron draws. The contract's `platforms.apple` records the difference: on iOS a field's frame is the whole
/// drawn field; on macOS a framed field's is the system field's, the text area, without westron's padding and glyphs,
/// for every framed field, with a glyph or without; an inline field, which has neither, agrees with the room it is
/// laid out in within a point across on both, and on macOS its frames are within two points of its lines up and down.
///
/// The drawn fields come from the page's own geometry, not from a marker, so that the tree under test is the one a
/// product gets: the page (`TokenPage`) holds the fields in one column at its padding from the entry's edges, the
/// small field below the page's summary, each field, the card of the inline fields and the row below the tag field
/// apart by `space.200`, the card's fields at `space.card` inside it and apart by `space.100`. A framed field is as
/// wide as the column and as tall as its size's `size.control` (the contract's `size`). The small field is placed
/// down from the summary, and the three fields at m up from the Clear focus button in the row below them, so no
/// field's own frame places another; the card is what lies between. On macOS these rectangles match the pixels of a
/// screen capture (#135: the fields' fills at 359, 486, 534 and 582 pt, the card's at 399 to 470).
final class TextFieldAccessibilityFrameTests: XCTestCase {
    /// Must match `TextFieldCatalogID` and `CatalogAccessibilityID.entry` in WestronCatalog.
    private enum ID {
        static let entry = "westron.catalog.entry"
        static let small = "text-field.live.small"
        static let title = "text-field.live.title"
        static let notes = "text-field.live.notes"
        static let secure = "text-field.live.secure"
        static let search = "text-field.live.search"
        static let tag = "text-field.live.tag"
        static let focused = "text-field.live.focused"
        static let clearFocus = "text-field.live.clear-focus"
    }

    /// The page's padding (`SampleMetrics.pagePadding`) and the framed heights of sizes s and m (`size.control`).
    #if os(macOS)
        private let pagePadding: CGFloat = 12  // space.150
        private let heightS: CGFloat = 24
        private let heightM: CGFloat = 32
    #else
        private let pagePadding: CGFloat = 16  // space.200
        private let heightS: CGFloat = 28
        private let heightM: CGFloat = 36
    #endif
    /// The column's spacing and the card's padding, `space.200` and `space.card` (16), and the card's spacing,
    /// `space.100`.
    private let columnSpacing: CGFloat = 16
    private let cardPadding: CGFloat = 16
    private let cardSpacing: CGFloat = 8
    /// The framed fields' horizontal padding, `space.200` at s and `space.250` at m, and their gap between a glyph and
    /// the text, `container.gap`, `space.100` at m.
    private let paddingS: CGFloat = 16
    private let paddingM: CGFloat = 20
    private let gapM: CGFloat = 8
    /// How far a frame may be from the drawn field and count as it: a point, as the contract records for inline.
    private let tolerance: CGFloat = 1

    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = true
        app = XCUIApplication()
        // The default text size, whatever the simulator's: the heights below are the fields' at it.
        app.launchArguments = [
            "-WestronEntry", "text-field-behavior", "-WestronAppearance", "light", "-WestronDynamicType", "large",
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts[ID.focused].waitForExistence(timeout: 30), "the entry did not render")
    }

    @MainActor
    override func tearDown() async throws {
        app.terminate()
    }

    @MainActor
    private func field(_ id: String) -> XCUIElement {
        let field = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "no field \(id)")
        return field
    }

    /// The drawn fields and the card, from the page's geometry (see the class's comment).
    private struct Drawn {
        var small, card, secure, search, tag: CGRect
    }

    @MainActor
    private func drawn() -> Drawn {
        let entry = app.descendants(matching: .any)[ID.entry].firstMatch
        XCTAssertTrue(entry.exists, "no entry")
        let left = entry.frame.minX + pagePadding
        let width = entry.frame.width - 2 * pagePadding
        // The column's leading edge, where a text of the column starts: a check that the margins are as read.
        XCTAssertEqual(
            app.staticTexts[ID.focused].frame.minX, left, accuracy: tolerance,
            "the column does not start at the page's padding: \(app.staticTexts[ID.focused].frame), \(entry.frame)")
        let summary = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'Real fields' OR value BEGINSWITH 'Real fields'")
        ).firstMatch
        XCTAssertTrue(summary.exists, "no summary")
        let small = CGRect(x: left, y: summary.frame.maxY + pagePadding, width: width, height: heightS)
        // The row below the tag field: the Clear focus button, at size s the row's tallest, with the text that names
        // the focused field centred on it. The button's frame is its drawn capsule (Button's contract).
        let button = app.buttons[ID.clearFocus]
        let focused = app.staticTexts[ID.focused]
        XCTAssertTrue(button.exists, "no Clear focus button")
        XCTAssertEqual(
            button.frame.height, heightS, accuracy: tolerance, "the button is not at size s: \(button.frame)")
        XCTAssertLessThan(focused.frame.height, button.frame.height, "the button is not the row's tallest")
        XCTAssertEqual(
            focused.frame.midY, button.frame.midY, accuracy: tolerance,
            "the row is not as read: \(focused.frame), \(button.frame)")
        let tag = CGRect(x: left, y: button.frame.minY - columnSpacing - heightM, width: width, height: heightM)
        let search = tag.offsetBy(dx: 0, dy: -(heightM + columnSpacing))
        let secure = search.offsetBy(dx: 0, dy: -(heightM + columnSpacing))
        let cardTop = small.maxY + columnSpacing
        let card = CGRect(x: left, y: cardTop, width: width, height: secure.minY - columnSpacing - cardTop)
        return Drawn(small: small, card: card, secure: secure, search: search, tag: tag)
    }

    private func near(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= tolerance && abs(a.maxX - b.maxX) <= tolerance && abs(a.minY - b.minY) <= tolerance
            && abs(a.maxY - b.maxY) <= tolerance
    }

    /// The inline fields' frames against the room they are laid out in, the card's inside: across within a point on
    /// both platforms, the title's top and the notes' bottom within a point of the inside's top and bottom on iOS and
    /// within two on macOS, where each was measured a point outside (#135). Between the
    /// title and the notes, whose lines are `space.100` apart, the frames are as far apart within a point on iOS; on
    /// macOS they are 2 pt closer, 6 pt apart (measured on macOS 26.7.1 in #135), as the contract's
    /// `platforms.apple.macos` records.
    @MainActor
    func testInlineFieldsReportWhatTheyDraw() {
        let drawn = drawn()
        let inside = drawn.card.insetBy(dx: cardPadding, dy: cardPadding)
        let title = field(ID.title).frame
        let notes = field(ID.notes).frame
        for (name, frame) in [("title", title), ("notes", notes)] {
            XCTAssertEqual(frame.minX, inside.minX, accuracy: tolerance, "\(name): \(frame), card's inside \(inside)")
            XCTAssertEqual(frame.maxX, inside.maxX, accuracy: tolerance, "\(name): \(frame), card's inside \(inside)")
            XCTAssertGreaterThan(frame.height, 10, "\(name): \(frame)")
        }
        // Up and down, macOS measured the title's top a point above the inside's top (414 against 415) and the notes'
        // bottom a point below its bottom (455 against 454) in #135: exactly at a 1 pt tolerance, so a half-point
        // change in AppKit's text view would fail the nightly run. macOS gets 2 pt, iOS keeps 1.
        #if os(macOS)
            let outer: CGFloat = 2
        #else
            let outer = tolerance
        #endif
        let entry = "the contract's platforms.apple entry for the inline fields' frames no longer holds"
        XCTAssertEqual(
            title.minY, inside.minY, accuracy: outer, "title: \(title), card's inside \(inside); \(entry)")
        XCTAssertEqual(
            notes.maxY, inside.maxY, accuracy: outer, "notes: \(notes), card's inside \(inside); \(entry)")
        #if os(macOS)
            let closer: CGFloat = 2
        #else
            let closer: CGFloat = 0
        #endif
        XCTAssertEqual(
            notes.minY - title.maxY, cardSpacing - closer, accuracy: tolerance, "notes: \(notes), title: \(title)")
    }

    /// iOS: every framed field's frame is the drawn field, with a glyph or without.
    /// macOS: it is the system field's (the contract's `platforms.apple.macos`): inside the drawn field, vertically
    /// centred in it and shorter than it, and narrower by the padding at each side without a glyph, and by the padding,
    /// the glyph and its gap at the glyph's side. The system's text area is a point wider than westron's (measured in
    /// #135), so a side without a glyph is inset by the padding within two points.
    @MainActor
    func testFramedFieldsReportThePlatformsFrame() {
        let drawn = drawn()
        // (name, drawn field, padding, a glyph at the start, a glyph at the end)
        let fields: [(String, CGRect, CGFloat, Bool, Bool)] = [
            (ID.small, drawn.small, paddingS, false, false),
            (ID.secure, drawn.secure, paddingM, false, false),
            (ID.search, drawn.search, paddingM, true, false),
            (ID.tag, drawn.tag, paddingM, false, true),
        ]
        for (id, rect, padding, leading, trailing) in fields {
            let frame = field(id).frame
            print("\(id): accessibility frame \(frame), drawn \(rect)")
            #if os(iOS)
                XCTAssertTrue(
                    near(frame, rect), "\(id): its accessibility frame \(frame) is not the drawn field \(rect)")
            #else
                if near(frame, rect) {
                    XCTFail(
                        "\(id): macOS now reports the drawn field \(rect) as the accessibility frame. The difference "
                            + "the contract records (text-field.spec.yaml, platforms.apple.macos, #135) is gone: "
                            + "remove that entry and assert the drawn frame on macOS as on iOS.")
                    continue
                }
                let start = frame.minX - rect.minX
                let end = rect.maxX - frame.maxX
                let message = "\(id): frame \(frame), drawn \(rect), insets \(start) and \(end)"
                for (inset, glyph) in [(start, leading), (end, trailing)] {
                    if glyph {
                        // A glyph is some points wide, at body.regular no wider than its line.
                        XCTAssertGreaterThanOrEqual(inset, padding + gapM + 4 - 2, "the glyph's side: \(message)")
                        XCTAssertLessThanOrEqual(inset, padding + gapM + 24, "the glyph's side: \(message)")
                    } else {
                        XCTAssertEqual(inset, padding, accuracy: 2, "a side without a glyph: \(message)")
                    }
                }
                XCTAssertLessThan(frame.height, rect.height - 2, "not shorter than the drawn field: \(message)")
                XCTAssertGreaterThan(frame.height, 10, "no text area: \(message)")
                XCTAssertEqual(frame.midY, rect.midY, accuracy: tolerance, "not centred in the drawn field: \(message)")
            #endif
        }
    }

    /// What the fields are to assistive technology, with or without glyphs: their role, label, value and prompt, and no
    /// element of a glyph, an image or anything else, inside a field or beside it.
    @MainActor
    func testTheFieldsAndNoGlyphElements() {
        func check(
            _ id: String, _ type: [XCUIElement.ElementType], label: String, value: String?, placeholder: String?,
            line: UInt = #line
        ) {
            let element = field(id)
            XCTAssertTrue(type.contains(element.elementType), "\(id): type \(element.elementType.rawValue)", line: line)
            XCTAssertEqual(element.label, label, "\(id): label", line: line)
            if let value {
                XCTAssertEqual(element.value as? String, value, "\(id): value", line: line)
            }
            if let placeholder {
                XCTAssertEqual(element.placeholderValue, placeholder, "\(id): placeholder", line: line)
            }
            // Nothing a glyph could be: no image, text or control inside the field. A multiline field's own scroll bars
            // are the system's, other elements, and stay.
            let children = element.descendants(matching: .any).allElementsBoundByIndex.filter {
                $0.elementType != .other
            }
            XCTAssertTrue(
                children.isEmpty,
                "\(id): elements inside the field: \(children.map { "\($0.elementType.rawValue) \($0.label)" })",
                line: line)
        }
        check(ID.small, [.textField], label: "List name", value: nil, placeholder: "Untitled")
        check(ID.title, [.textField], label: "Title", value: "Buy groceries", placeholder: "Untitled")
        // A multiline field is a text view on macOS and a text field on iOS.
        check(ID.notes, [.textField, .textView], label: "Notes", value: "Milk, bread and apples", placeholder: nil)
        check(ID.secure, [.secureTextField], label: "Password", value: nil, placeholder: "Required")
        check(ID.search, [.searchField], label: "Search", value: nil, placeholder: "Search")
        check(ID.tag, [.textField], label: "Tag", value: nil, placeholder: "Tag")

        // No image on the page, which draws none but the glyphs; and no element but the field itself inside a framed
        // field's drawn area, its padding and its glyphs included. (The page's scroll bars reach over the fields'
        // ends; they lie inside none.)
        XCTAssertEqual(
            app.images.count, 0, "images: \(app.images.allElementsBoundByIndex.map { "\($0.label) \($0.frame)" })")
        let drawn = drawn()
        let entry = app.descendants(matching: .any)[ID.entry].firstMatch
        let ids = [ID.small, ID.secure, ID.search, ID.tag]
        let elements = entry.descendants(matching: .any).allElementsBoundByIndex
        XCTAssertGreaterThan(elements.count, ids.count, "the entry's elements were not found")
        for element in elements where !ids.contains(element.identifier) {
            for rect in [drawn.small, drawn.secure, drawn.search, drawn.tag] {
                XCTAssertFalse(
                    rect.insetBy(dx: -1, dy: -1).contains(element.frame) && !element.frame.isEmpty,
                    "an element inside a field \(rect): \(element.elementType.rawValue) '\(element.label)' "
                        + "id=\(element.identifier) \(element.frame)")
            }
        }
    }

    /// Typing into the search field changes its value. On macOS, digits, which every keyboard layout types alike:
    /// XCUITest types Latin letters through the current layout, and on a Mac with another layout they arrive as other
    /// characters.
    @MainActor
    func testTypingIntoTheSearchFieldChangesItsValue() {
        let search = field(ID.search)
        #if os(macOS)
            search.click()
        #else
            search.tap()
        #endif
        let focused = app.staticTexts[ID.focused]
        let name = focused.label.isEmpty ? (focused.value as? String ?? "") : focused.label
        XCTAssertEqual(name, "Focused: search")
        search.typeText("42")
        XCTAssertEqual(search.value as? String, "42", "search: \(search.value ?? "nil")")
        XCTAssertEqual(app.images.count, 0, "an image appeared as the field took text")
    }
}
