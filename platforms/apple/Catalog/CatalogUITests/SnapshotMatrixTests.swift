import WestronCatalog
import XCTest

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// The snapshot matrix (#24): every sheet of every component's matrix (`ComponentMatrix.all`, generated from the
/// contracts) in the four themes, for the owner's review. It runs from `tools/apple/snapshot-matrix.sh`, which sets
/// `TEST_RUNNER_WESTRON_MATRIX=1` (without it the test is skipped, so a plain test run does not take it) and, to take
/// one component, `TEST_RUNNER_WESTRON_MATRIX_COMPONENT=<id>`.
///
/// One launch of the catalog per sheet and theme. The capture pins what it can: the theme and the contrast, the text
/// size (`large`, the default), the language and the locale; on macOS the sheet sets the window's size itself. The
/// picture is the screen on iOS and the sheet alone on macOS. Before each screenshot the test waits until two pictures
/// in a row are the same, counts the sheet's cells against the matrix, and checks that each cell lies inside the
/// picture, so a sheet that is cut off fails. Each PNG is attached as `westron-matrix-<file>`, and
/// a manifest, `westron-matrix-manifest`, says what was captured where; the script builds the review page from it. The
/// runner writes no files: on macOS it is sandboxed (decisions/0008).
final class SnapshotMatrixTests: XCTestCase {
    static let attachmentPrefix = "westron-matrix-"
    static let manifestName = "westron-matrix-manifest"
    /// What the capture pins besides the theme.
    static let pinnedArguments = [
        "-WestronDynamicType", "large", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
        "-ApplePersistenceIgnoreState", "YES",
    ]
    /// How long a sheet has to stay still to count as settled, and how long it may take.
    static let stillInterval: TimeInterval = 0.3
    static let settleTimeout: TimeInterval = 8

    struct Manifest: Codable {
        var platform: String
        var os: String
        var device: String
        var scale: Double = 0
        var pinned: [String]
        var themes: [String]
        var components: [Component] = []
    }

    struct Component: Codable {
        var component: String
        var columns: String
        /// The combinations this OS draws.
        var combinations: Int
        var notes: [String]
        var sheets: [Sheet] = []
    }

    struct Sheet: Codable {
        var id: String
        var title: String
        /// Pairs of option and value.
        var fixed: [[String]]
        /// The cells the matrix draws on the sheet.
        var cells: Int
        /// By theme: the file, the cells found on screen, whether every one lay inside the window, whether the sheet
        /// stood still before the screenshot.
        var images: [String: String] = [:]
        var found: [String: Int] = [:]
        var fits: [String: Bool] = [:]
        var settled: [String: Bool] = [:]
        /// By theme, the picture's width and height in points: the screen on iOS, the sheet's content on macOS.
        var sizes: [String: [Double]] = [:]
    }

    @MainActor
    func testMatrix() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["WESTRON_MATRIX"] == "1" else {
            throw XCTSkip("WESTRON_MATRIX is not set: tools/apple/snapshot-matrix.sh runs this test")
        }
        continueAfterFailure = true
        var matrices = ComponentMatrix.all
        if let component = environment["WESTRON_MATRIX_COMPONENT"], !component.isEmpty {
            matrices = matrices.filter { $0.component == component }
            let known = ComponentMatrix.all.map(\.component).joined(separator: ", ")
            XCTAssertFalse(matrices.isEmpty, "no snapshot matrix \"\(component)\"; the matrices: \(known)")
        }

        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #if os(iOS)
            let platform = "ios"
            let os = "iOS \(osVersion)"
            let device = environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
        #else
            let platform = "macos"
            let os = "macOS \(osVersion)"
            let device = "Mac"
        #endif
        var manifest = Manifest(
            platform: platform, os: os, device: device, pinned: Self.pinnedArguments,
            themes: ComponentMatrix.Theme.allCases.map(\.rawValue))
        manifest.components = matrices.map { matrix in
            Component(
                component: matrix.component, columns: matrix.columnName,
                combinations: matrix.drawnCombinations.count, notes: matrix.notes,
                sheets: matrix.sheets.map { sheet in
                    Sheet(
                        id: sheet.id, title: matrix.title(of: sheet),
                        fixed: matrix.fixedValues(of: sheet).map { [$0.option, $0.value] },
                        cells: matrix.drawnCount(in: sheet))
                })
        }

        for theme in ComponentMatrix.Theme.allCases {
            for (componentIndex, matrix) in matrices.enumerated() {
                for (sheetIndex, sheet) in matrix.sheets.enumerated() {
                    let file = matrix.fileName(of: sheet, theme: theme)
                    XCTContext.runActivity(named: file) { _ in
                        guard let result = capture(matrix, sheet, theme: theme, manifest: &manifest) else { return }
                        var entry = manifest.components[componentIndex].sheets[sheetIndex]
                        entry.images[theme.rawValue] = file
                        entry.found[theme.rawValue] = result.found
                        entry.fits[theme.rawValue] = result.fits
                        entry.settled[theme.rawValue] = result.settled
                        entry.sizes[theme.rawValue] = [result.size.width, result.size.height].map(Double.init)
                        manifest.components[componentIndex].sheets[sheetIndex] = entry
                        let attachment = XCTAttachment(data: result.png, uniformTypeIdentifier: "public.png")
                        attachment.name = Self.attachmentPrefix + file
                        attachment.lifetime = .keepAlways
                        add(attachment)
                    }
                }
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let attachment = XCTAttachment(data: try encoder.encode(manifest), uniformTypeIdentifier: "public.json")
        attachment.name = Self.manifestName
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Launches the catalog on one sheet in one theme and takes its screenshot; nil after a failure.
    @MainActor
    private func capture(
        _ matrix: ComponentMatrix, _ sheet: ComponentMatrix.Sheet, theme: ComponentMatrix.Theme,
        manifest: inout Manifest
    ) -> (png: Data, found: Int, fits: Bool, settled: Bool, size: CGSize)? {
        let key = matrix.key(of: sheet)
        let app = XCUIApplication()
        app.launchArguments = ["-WestronMatrixSheet", key] + theme.launchArguments + Self.pinnedArguments
        app.launch()
        defer { app.terminate() }

        let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
        let problem = app.descendants(matching: .any)[CatalogAccessibilityID.problem]
        let appeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in entry.exists || problem.exists }, object: nil)
        guard XCTWaiter.wait(for: [appeared], timeout: 30) == .completed else {
            XCTFail("\(key) \(theme.rawValue): the catalog did not render the sheet within 30 s")
            return nil
        }
        if problem.exists {
            XCTFail("\(key): \(problem.label)")
            return nil
        }

        let window = app.windows.firstMatch
        let settled = settle(window)
        if !settled {
            print("matrix: \(key) \(theme.rawValue) was still changing after \(Int(Self.settleTimeout)) s")
        }

        let bounds = window.frame
        let cells = app.descendants(matching: .any).matching(identifier: CatalogAccessibilityID.matrixCell)
            .allElementsBoundByIndex
        let outside = cells.filter { !bounds.contains($0.frame) }
        let expected = matrix.drawnCount(in: sheet)
        XCTAssertEqual(cells.count, expected, "\(key) \(theme.rawValue): cells on screen")
        XCTAssertTrue(
            outside.isEmpty,
            "\(key) \(theme.rawValue): \(outside.count) cells are not wholly inside the window \(bounds): "
                + outside.map { "\($0.frame)" }.joined(separator: ", "))

        // The picture: on iOS the screen, its status bar pinned by the script; on macOS the sheet's content with a
        // margin, cut from the window's picture without the title bar and the rounded corners, where the desktop
        // behind shows through.
        #if os(macOS)
            let content = app.descendants(matching: .any)[CatalogAccessibilityID.matrixSheet].frame
            guard let cut = Self.crop(window.screenshot(), of: bounds, to: content) else {
                XCTFail("\(key) \(theme.rawValue): the window's picture could not be cut to the sheet")
                return nil
            }
            let (png, scale, size) = cut
        #else
            let screenshot = XCUIScreen.main.screenshot()
            let png = screenshot.pngRepresentation
            let scale = Double(screenshot.image.scale)
            let size = bounds.size
        #endif
        manifest.scale = scale
        return (png, cells.count, outside.isEmpty, settled, size)
    }

    #if os(macOS)
        /// The space kept around the sheet's content in the macOS picture, in points: less than the sheet's padding,
        /// so neither the title bar nor the window's edge shows.
        static let margin: CGFloat = 8

        /// The part of a window's screenshot around `content`, with `margin`, inside the window; as PNG, with the
        /// scale and the size in points.
        static func crop(_ screenshot: XCUIScreenshot, of window: CGRect, to content: CGRect)
            -> (png: Data, scale: Double, size: CGSize)?
        {
            guard let image = screenshot.image.cgImage(forProposedRect: nil, context: nil, hints: nil),
                window.width > 0
            else { return nil }
            let scale = CGFloat(image.width) / window.width
            let area = content.insetBy(dx: -margin, dy: -margin).intersection(window.insetBy(dx: 1, dy: 1))
            let pixels = CGRect(
                x: (area.minX - window.minX) * scale, y: (area.minY - window.minY) * scale,
                width: area.width * scale, height: area.height * scale
            ).integral
            guard !area.isNull, let cropped = image.cropping(to: pixels),
                let png = NSBitmapImageRep(cgImage: cropped).representation(using: .png, properties: [:])
            else { return nil }
            return (png, Double(scale), area.size)
        }
    #endif

    /// Waits until two pictures of an element in a row are the same; false when it is still changing at the timeout.
    @MainActor
    private func settle(_ window: XCUIElement) -> Bool {
        var previous = window.screenshot().pngRepresentation
        let deadline = Date().addingTimeInterval(Self.settleTimeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: Self.stillInterval)
            let current = window.screenshot().pngRepresentation
            if current == previous { return true }
            previous = current
        }
        return false
    }
}
