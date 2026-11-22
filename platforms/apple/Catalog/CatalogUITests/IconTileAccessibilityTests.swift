import XCTest

/// What assistive technology gets of IconTile (spec/components/icon-tile), on the catalog's `icon-tile` entry: a
/// decorative tile is no element at all, its hidden measuring line and glyphs included, and a labeled one is a single
/// image with its label. A unit test cannot reach the accessibility hierarchy; the snapshot here is what VoiceOver walks.
final class IconTileAccessibilityTests: XCTestCase {
    /// Must match `IconTilePageID` and `CatalogAccessibilityID.entry` in WestronCatalog.
    private enum ID {
        static let entry = "westron.catalog.entry"
        static let labeled = "westron.catalog.icon-tile.labeled"
    }

    @MainActor
    func testDecorativeTilesAreHiddenAndALabeledOneIsAnImage() {
        let app = XCUIApplication()
        app.launchArguments = ["-WestronEntry", "icon-tile"]
        app.launch()
        defer { app.terminate() }
        let entry = app.descendants(matching: .any)[ID.entry]
        XCTAssertTrue(entry.waitForExistence(timeout: 30), "the entry did not render")

        // The page draws some fifty tiles, every one decorative but one, the empty screen's among them: only that one
        // is an element, and none of a tile's parts is (on iOS the labeled tile's symbol stays an image of its own,
        // named after the symbol, even hidden; IconTile.swift replaces the tile's parts with
        // `.accessibilityRepresentation`).
        let images = entry.descendants(matching: .image)
        XCTAssertEqual(
            images.count, 1,
            "images: \(images.allElementsBoundByIndex.map { "\($0.label) id=\($0.identifier) \($0.frame)" })")
        let labeled = entry.descendants(matching: .image)[ID.labeled]
        XCTAssertTrue(labeled.exists, "IconTile(.folder, label: \"Garden\") is not an image")
        XCTAssertEqual(labeled.label, "Garden")
        // The measuring line is the letter X: no tile adds it as text.
        XCTAssertFalse(entry.staticTexts["X"].exists, "a tile's hidden line is an element")
        // The empty screen reads its own words, not the tile's.
        XCTAssertTrue(entry.staticTexts["No tasks"].exists, "the empty screen's title is not text")
    }
}
