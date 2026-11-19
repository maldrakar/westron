import WestronCatalog
import XCTest

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// The snapshot matrix (#24): every sheet of every component's matrix (`ComponentMatrix.all`, generated from the
/// contracts) and of its supplements (`ComponentMatrix.supplements`, hand-written, #72) in every capture of the current
/// OS (`ComponentMatrix.Capture.all`: the four themes at the default text size and, on iOS, the light theme at the
/// smallest and the largest text size), for the owner's review. It runs from `tools/apple/snapshot-matrix.sh`, which
/// sets `TEST_RUNNER_WESTRON_MATRIX=1` (without it the test is skipped, so a plain test run does not take it) and, to
/// take one component, `TEST_RUNNER_WESTRON_MATRIX_COMPONENT=<id>`.
///
/// One launch of the catalog per picture: a sheet, or a part of a sheet at a text size where the whole does not fit
/// (`ComponentMatrix.pictures(of:at:)`), in one capture. The capture pins what it can: the theme, the contrast, the text
/// size, the language and the locale; on macOS the sheet sets the window's size itself. The picture is the screen on
/// iOS and the sheet alone on macOS. Before each screenshot the test waits until two pictures in a row are the same,
/// counts the picture's cells against the matrix, and checks that each cell lies inside the picture, so a sheet that is
/// cut off fails. Each PNG is attached as `westron-matrix-<file>`, and a manifest, `westron-matrix-manifest`, says what
/// was captured where; the script builds the review page from it. The runner writes no files: on macOS it is sandboxed
/// (decisions/0008).
final class SnapshotMatrixTests: XCTestCase {
    static let attachmentPrefix = "westron-matrix-"
    static let manifestName = "westron-matrix-manifest"
    /// What every capture pins besides its theme and text size.
    static let pinnedArguments = [
        "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ApplePersistenceIgnoreState", "YES",
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
        /// The captures, in order.
        var captures: [Capture]
        /// Why this OS is captured at fewer text sizes; nil when it takes them all.
        var textSizeNote: String?
        var components: [Component] = []
    }

    struct Capture: Codable {
        /// `dark-hc`, `light.accessibility5`: the end of the file names.
        var name: String
        var theme: String
        var textSize: String
        var arguments: [String]
    }

    struct Component: Codable {
        var component: String
        var columns: String
        /// The option down the rows in place of the states (Icon's glyphs); nil for rest and each state.
        var rows: String?
        var notes: [String]
        /// The matrix generated from the contract first, then each supplement.
        var groups: [Group] = []
    }

    struct Group: Codable {
        /// `contract` for the generated matrix, the supplement's id otherwise.
        var id: String
        var title: String
        /// Whether its sheets are hand-written for what is not a contract option.
        var supplement: Bool
        /// The supplement's note; nil for the generated matrix.
        var note: String?
        /// The combinations this OS draws.
        var combinations: Int
        var sheets: [Sheet] = []
    }

    struct Sheet: Codable {
        var id: String
        var title: String
        /// Pairs of option and value.
        var fixed: [[String]]
        /// The cells the matrix draws on the sheet.
        var cells: Int
        /// By capture, its pictures: the sheet, or its parts at a text size where it does not fit whole.
        var images: [String: [Image]] = [:]
    }

    struct Image: Codable {
        var file: String
        /// What part of the sheet it holds; nil for the whole sheet.
        var part: String?
        /// The cells the matrix draws in the picture.
        var cells: Int
        /// Without a picture (its capture failed) these are nil: the cells found on screen, whether every one lay
        /// inside the window, whether the sheet stood still before the screenshot, and the picture's width and height
        /// in points (the screen on iOS, the sheet's content on macOS).
        var found: Int?
        var fits: Bool?
        var settled: Bool?
        var size: [Double]?
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
        // By component: its generated matrix, then its supplements.
        let components = matrices.map { [$0] + $0.supplements }

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
        let captures = ComponentMatrix.Capture.all
        var manifest = Manifest(
            platform: platform, os: os, device: device, pinned: Self.pinnedArguments,
            captures: captures.map {
                Capture(
                    name: $0.name, theme: $0.theme.rawValue, textSize: $0.textSize.rawValue,
                    arguments: $0.launchArguments)
            },
            textSizeNote: ComponentMatrix.TextSize.notCapturedNote)
        manifest.components = components.map { groups in
            Component(
                component: groups[0].component, columns: groups[0].columnName, rows: groups[0].rowOption,
                notes: groups[0].notes,
                groups: groups.map { matrix in
                    Group(
                        id: matrix.supplement?.id ?? "contract",
                        title: matrix.supplement?.title ?? "from the contract",
                        supplement: matrix.supplement != nil, note: matrix.supplement?.note,
                        combinations: matrix.drawnCombinations.count,
                        sheets: matrix.sheets.map { sheet in
                            Sheet(
                                id: sheet.id, title: matrix.title(of: sheet),
                                fixed: matrix.fixedValues(of: sheet).map { [$0.option, $0.value] },
                                cells: matrix.drawnCount(in: sheet))
                        })
                })
        }

        for capture in captures {
            for (componentIndex, groups) in components.enumerated() {
                for (groupIndex, matrix) in groups.enumerated() {
                    for (sheetIndex, sheet) in matrix.sheets.enumerated() {
                        for picture in matrix.pictures(of: sheet, at: capture.textSize) {
                            let file = matrix.fileName(of: picture, capture: capture)
                            var image = Image(
                                file: file, part: matrix.partTitle(of: picture), cells: matrix.drawnCount(in: picture))
                            XCTContext.runActivity(named: file) { _ in
                                guard let result = take(matrix, picture, capture) else { return }
                                manifest.scale = result.scale
                                image.found = result.found
                                image.fits = result.fits
                                image.settled = result.settled
                                image.size = [result.size.width, result.size.height].map(Double.init)
                                let attachment = XCTAttachment(data: result.png, uniformTypeIdentifier: "public.png")
                                attachment.name = Self.attachmentPrefix + file
                                attachment.lifetime = .keepAlways
                                add(attachment)
                            }
                            // A picture whose capture failed stays in the manifest without results: the page shows it
                            // as missing.
                            manifest.components[componentIndex].groups[groupIndex].sheets[sheetIndex]
                                .images[capture.name, default: []].append(image)
                        }
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

    /// Launches the catalog on one picture of a sheet in one capture and takes its screenshot; nil after a failure.
    @MainActor
    private func take(
        _ matrix: ComponentMatrix, _ sheet: ComponentMatrix.Sheet, _ capture: ComponentMatrix.Capture
    ) -> (png: Data, scale: Double, found: Int, fits: Bool, settled: Bool, size: CGSize)? {
        let key = matrix.key(of: sheet)
        let name = "\(key) \(capture.name)"
        let app = XCUIApplication()
        app.launchArguments = ["-WestronMatrixSheet", key] + capture.launchArguments + Self.pinnedArguments
        app.launch()
        defer { app.terminate() }

        let entry = app.descendants(matching: .any)[CatalogAccessibilityID.entry]
        let problem = app.descendants(matching: .any)[CatalogAccessibilityID.problem]
        let appeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in entry.exists || problem.exists }, object: nil)
        guard XCTWaiter.wait(for: [appeared], timeout: 30) == .completed else {
            XCTFail("\(name): the catalog did not render the sheet within 30 s")
            return nil
        }
        if problem.exists {
            XCTFail("\(key): \(problem.label)")
            return nil
        }

        let window = app.windows.firstMatch
        let settled = settle(window)
        if !settled {
            print("matrix: \(name) was still changing after \(Int(Self.settleTimeout)) s")
        }

        let bounds = window.frame
        let cells = app.descendants(matching: .any).matching(identifier: CatalogAccessibilityID.matrixCell)
            .allElementsBoundByIndex
        let outside = cells.filter { !bounds.contains($0.frame) }
        let expected = matrix.drawnCount(in: sheet)
        XCTAssertEqual(cells.count, expected, "\(name): cells on screen")
        XCTAssertTrue(
            outside.isEmpty,
            "\(name): \(outside.count) cells are not wholly inside the window \(bounds): "
                + outside.map { "\($0.frame)" }.joined(separator: ", "))

        // The picture: on iOS the screen, its status bar pinned by the script; on macOS the sheet's content with a
        // margin, cut from the window's picture without the title bar and the rounded corners, where the desktop
        // behind shows through.
        #if os(macOS)
            let content = app.descendants(matching: .any)[CatalogAccessibilityID.matrixSheet].frame
            guard let cut = Self.crop(window.screenshot(), of: bounds, to: content) else {
                XCTFail("\(name): the window's picture could not be cut to the sheet")
                return nil
            }
            let (png, scale, size) = cut
        #else
            let screenshot = XCUIScreen.main.screenshot()
            let png = screenshot.pngRepresentation
            let scale = Double(screenshot.image.scale)
            let size = bounds.size
        #endif
        return (png, scale, cells.count, outside.isEmpty, settled, size)
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
