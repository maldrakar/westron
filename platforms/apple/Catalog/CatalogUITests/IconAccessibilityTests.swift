import XCTest

/// What assistive technology gets of Icon (spec/components/icon), on the catalog's `icon` entry: a decorative icon is
/// no element at all, a labeled one is an image with its label. `Label(_:icon:)` stays the system's, an image and its
/// title (the contract's `platforms.apple`). A unit test cannot reach the accessibility hierarchy; the snapshot here is
/// what VoiceOver walks.
final class IconAccessibilityTests: XCTestCase {
    /// Must match `IconPageID` and `CatalogAccessibilityID.entry` in WestronCatalog.
    private enum ID {
        static let entry = "westron.catalog.entry"
        static let labeled = "westron.catalog.icon.labeled"
        static let label = "westron.catalog.icon.label"
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

        // Label("Rename", icon: .pen): the system's, its title and its symbol's image.
        let label = entry.descendants(matching: .any).matching(identifier: ID.label)
        let kinds = label.allElementsBoundByIndex.map(\.elementType)
        XCTAssertEqual(Set(kinds), [.staticText, .image], "\(kinds)")
    }
}
