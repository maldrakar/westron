import XCTest

/// What assistive technology gets of Icon (spec/components/icon), on the catalog's `icon` entry: a decorative icon is
/// no element at all, a labeled one is an image with its label, and a `Label`'s icon is hidden beside its title. A unit
/// test cannot reach the accessibility hierarchy; the snapshot here is what VoiceOver walks.
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

        // The page draws some forty icons, every one decorative but one: only that one is an element.
        let images = entry.descendants(matching: .image)
        XCTAssertEqual(images.count, 1, "images: \(images.allElementsBoundByIndex.map(\.label))")
        let labeled = images[ID.labeled]
        XCTAssertTrue(labeled.exists, "Icon(.sun, label: \"Today\") is not an image")
        XCTAssertEqual(labeled.label, "Today")

        // Label("Rename", icon: .pen): its title alone.
        let label = entry.descendants(matching: .any).matching(identifier: ID.label)
        XCTAssertEqual(label.count, 1, "\(label.allElementsBoundByIndex.map { "\($0.elementType): \($0.label)" })")
        XCTAssertEqual(label.firstMatch.elementType, .staticText)
        // A text's string: iOS puts it in the label, macOS in the value.
        let title = label.firstMatch
        XCTAssertEqual(title.label.isEmpty ? title.value as? String : title.label, "Rename")
    }
}
