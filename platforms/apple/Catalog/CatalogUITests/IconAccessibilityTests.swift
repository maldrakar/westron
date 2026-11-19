import XCTest

/// What assistive technology gets of Icon (spec/components/icon), on the catalog's `icon` entry: a decorative icon is
/// no element at all, a labeled one is an image with its label. `Label(_:icon:)` stays the system's, with its
/// title (the contract's `platforms.apple`). A unit test cannot reach the accessibility hierarchy; the snapshot here is
/// what VoiceOver walks.
final class IconAccessibilityTests: XCTestCase {
    /// Must match `IconPageID` and `CatalogAccessibilityID.entry` in WestronCatalog.
    private enum ID {
        static let entry = "westron.catalog.entry"
        static let labeled = "westron.catalog.icon.labeled"
        static let label = "westron.catalog.icon.label"
        static let menu = "westron.catalog.icon.menu"
    }

    @MainActor
    func testDecorativeIconsAreHiddenAndALabeledOneIsAnImage() {
        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "icon"]
        app.launch()
        defer { app.terminate() }
        let entry = app.descendants(matching: .any)[ID.entry]
        XCTAssertTrue(entry.waitForExistence(timeout: 30), "the entry did not render")

        // The page draws some forty icons with Icon, every one decorative but one: only that one is an element. The
        // system Label's image is the other image on the page.
        let images = entry.descendants(matching: .image).matching(NSPredicate(format: "identifier != %@", ID.label))
        XCTAssertEqual(images.count, 1, "images: \(images.allElementsBoundByIndex.map(\.label))")
        let labeled = entry.descendants(matching: .image)[ID.labeled]
        XCTAssertTrue(labeled.exists, "Icon(.sun, label: \"Today\") is not an image")
        XCTAssertEqual(labeled.label, "Today")

        // Label("Rename", icon: .pen) is the system's: its title is there, and whether its symbol's image is an element
        // of its own is the system's choice (the contract's platforms.apple), so it is not held here.
        let label = entry.descendants(matching: .any).matching(identifier: ID.label)
        let texts = label.allElementsBoundByIndex.filter { $0.elementType == .staticText }
        XCTAssertEqual(
            texts.map { $0.label.isEmpty ? $0.value as? String ?? "" : $0.label }, ["Rename"],
            "\(label.allElementsBoundByIndex.map { "\($0.elementType.rawValue) \($0.label)" })")
    }

    /// A system menu built from labels: `Label("Rename", icon: .pen)` as westron ships it, and
    /// `Label { Text("Delete") } icon: { Icon(.trash) }`, the alternative decisions/0001 tested for the owner. Both
    /// icons are drawn (the screenshot attached), but only the first item is a button: an item whose icon is hidden is
    /// left without one on iOS 26.3, so VoiceOver cannot reach it. The test holds both, so that a system that changes
    /// either is noticed.
    @MainActor
    func testMenuItemsBuiltFromLabels() throws {
        #if os(iOS)
            let app = XCUIApplication()
            app.launchArguments = ["-WestronEntry", "icon"]
            app.launch()
            defer { app.terminate() }
            let menu = app.descendants(matching: .any)[ID.menu]
            XCTAssertTrue(menu.waitForExistence(timeout: 30), "no menu on the entry")
            menu.tap()
            let rename = app.buttons["Rename"]
            XCTAssertTrue(rename.waitForExistence(timeout: 5), "the menu item Rename is not a button")
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "icon-menu"
            shot.lifetime = .keepAlways
            add(shot)
            // Rename's button holds the system's image of its symbol, with the symbol's own name.
            XCTAssertEqual(rename.descendants(matching: .image).count, 1)
            // Delete is drawn, but its item has no button and no text: assistive technology cannot reach it.
            XCTAssertFalse(app.buttons["Delete"].exists, "the item with a hidden icon became a button")
            XCTAssertFalse(app.staticTexts["Delete"].exists, "the item with a hidden icon became reachable")
        #else
            throw XCTSkip("the menu is checked on iOS, where SwiftUI builds a UIMenu")
        #endif
    }
}
