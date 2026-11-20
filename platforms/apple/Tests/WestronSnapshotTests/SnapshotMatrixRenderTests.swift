// The snapshot matrix rendered in-process (#24, #92): every sheet of every component's matrix (`ComponentMatrix.all`,
// generated from the contracts) and of its supplements (hand-written, #72) in every capture of the current OS
// (`ComponentMatrix.Capture.all`: the four themes at the default text size and, on iOS, the light theme at the smallest
// and the largest text size), as PNGs and the manifest `matrix.json` that tools/apple/snapshot-pages.swift builds the
// review page from.
//
// It runs only when WESTRON_SNAPSHOTS names the directory to write to (on the iOS simulator, through xcodebuild,
// TEST_RUNNER_WESTRON_SNAPSHOTS), so `swift test` and `tools/apple/check.sh package` skip it; tools/apple/snapshot-matrix.sh
// sets it. WESTRON_SNAPSHOTS_COMPONENT=<id>[,<id>…] takes some components only.

import Foundation
import SwiftUI
import Testing

@testable import WestronCatalog

/// Where the pictures go: WESTRON_SNAPSHOTS; nil when it is not set, and the suite is skipped.
let snapshotOutput: URL? = ProcessInfo.processInfo.environment["WESTRON_SNAPSHOTS"].flatMap {
    $0.isEmpty ? nil : URL(fileURLWithPath: $0)
}

@Suite("Snapshot matrix, rendered in-process", .enabled(if: snapshotOutput != nil), .serialized)
@MainActor
struct SnapshotMatrixRenderTests {

    @Test("every sheet in every capture")
    func matrix() throws {
        let output = try #require(snapshotOutput)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var matrices = ComponentMatrix.all
        // One component or several, comma-separated; the matrices stay in the registry's order.
        if let list = ProcessInfo.processInfo.environment["WESTRON_SNAPSHOTS_COMPONENT"], !list.isEmpty {
            let wanted = Set(list.split(separator: ",").map(String.init))
            matrices = matrices.filter { wanted.contains($0.component) }
            let known = ComponentMatrix.all.map(\.component)
            for component in wanted.subtracting(known).sorted() {
                Issue.record("no snapshot matrix \"\(component)\"; the matrices: \(known.joined(separator: ", "))")
            }
        }
        // By component: its generated matrix, then its supplements.
        let components = matrices.map { [$0] + $0.supplements }
        let captures = ComponentMatrix.Capture.all
        let environment = SnapshotRenderer.environment
        var manifest = SnapshotManifest(
            platform: SnapshotManifest.platform, os: environment.os, device: environment.device,
            scale: environment.scale, pinned: SnapshotManifest.pinned,
            captures: captures.map {
                .init(
                    name: $0.name, theme: $0.theme.rawValue, textSize: $0.textSize.rawValue,
                    arguments: $0.launchArguments)
            },
            textSizeNote: ComponentMatrix.TextSize.notCapturedNote,
            components: components.map { groups in
                .init(
                    component: groups[0].component, columns: groups[0].columnName, rows: groups[0].rowOption,
                    notes: groups[0].notes,
                    groups: groups.map { matrix in
                        .init(
                            id: matrix.supplement?.id ?? "contract",
                            title: matrix.supplement?.title ?? "from the contract",
                            supplement: matrix.supplement != nil, note: matrix.supplement?.note,
                            combinations: matrix.drawnCombinations.count,
                            sheets: matrix.sheets.map { sheet in
                                .init(
                                    id: sheet.id, title: matrix.title(of: sheet),
                                    fixed: matrix.fixedValues(of: sheet).map { [$0.option, $0.value] },
                                    cells: matrix.drawnCount(in: sheet))
                            })
                    })
            })

        let start = Date()
        var count = 0
        var bytes = 0
        var times: [(file: String, seconds: TimeInterval)] = []
        for capture in captures {
            for (componentIndex, groups) in components.enumerated() {
                for (groupIndex, matrix) in groups.enumerated() {
                    for (sheetIndex, sheet) in matrix.sheets.enumerated() {
                        for picture in matrix.pictures(of: sheet, at: capture.textSize) {
                            let file = matrix.fileName(of: picture, capture: capture)
                            let cells = matrix.drawnCount(in: picture)
                            var image = SnapshotManifest.Image(
                                file: file, part: matrix.partTitle(of: picture), cells: cells)
                            let began = Date()
                            do {
                                let rendered = try SnapshotRenderer.render(
                                    key: matrix.key(of: picture), capture: capture)
                                bytes += try SnapshotRenderer.write(
                                    rendered.image, to: output.appendingPathComponent(file))
                                // The cells are the matrix's own views, drawn by construction: the UI test counted
                                // them on screen; here what can go wrong is the sheet running off the window.
                                image.found = cells
                                image.fits = rendered.fits
                                image.size = [rendered.size.width, rendered.size.height].map(Double.init)
                                image.attempts = rendered.attempts
                                if !rendered.fits {
                                    Issue.record(
                                        "\(file): the sheet does not fit the window; its last cells are cut off")
                                }
                                if rendered.attempts > 1 {
                                    print("snapshot: \(file) came back blank, drawn \(rendered.attempts) times")
                                }
                                count += 1
                            } catch {
                                Issue.record("\(file): \(error)")
                            }
                            let seconds = Date().timeIntervalSince(began)
                            image.seconds = (seconds * 1000).rounded() / 1000
                            times.append((file, seconds))
                            print(String(format: "snapshot: %@ %.3f s", file, seconds))
                            // A picture that failed stays in the manifest without results: the page shows it missing.
                            manifest.components[componentIndex].groups[groupIndex].sheets[sheetIndex]
                                .images[capture.name, default: []].append(image)
                        }
                    }
                }
            }
        }
        let total = Date().timeIntervalSince(start)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(to: output.appendingPathComponent("matrix.json"))
        let slowest = times.sorted { $0.seconds > $1.seconds }.prefix(3)
            .map { String(format: "%@ %.2f s", $0.file, $0.seconds) }.joined(separator: ", ")
        print(
            String(
                format: "snapshot: %d images in %.1f s (%.3f s an image), %.1f MB; slowest: %@", count, total,
                total / Double(max(count, 1)), Double(bytes) / 1_048_576, slowest))
    }
}

/// The manifest the review page reads (tools/apple/snapshot-pages.swift, `Manifest`).
struct SnapshotManifest: Codable {
    #if os(iOS)
        static let platform = "ios"
    #else
        static let platform = "macos"
    #endif
    /// What every picture pins besides its theme and text size: the locale in SwiftUI's environment, and on iOS the
    /// language and region xcodebuild runs the catalog in (`-testLanguage`, `-testRegion`).
    static let pinned = ["locale en_US"] + (platform == "ios" ? ["-testLanguage en", "-testRegion en_US"] : [])

    var platform: String
    var os: String
    var device: String
    var scale: Double
    var pinned: [String]
    var captures: [Capture]
    var textSizeNote: String?
    var components: [Component]

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
        var groups: [Group]
    }

    struct Group: Codable {
        /// `contract` for the generated matrix, the supplement's id otherwise.
        var id: String
        var title: String
        var supplement: Bool
        var note: String?
        var combinations: Int
        var sheets: [Sheet]
    }

    struct Sheet: Codable {
        var id: String
        var title: String
        /// Pairs of option and value.
        var fixed: [[String]]
        var cells: Int
        /// By capture, its pictures: the sheet, or its parts at a text size where it does not fit whole.
        var images: [String: [Image]] = [:]
    }

    struct Image: Codable {
        var file: String
        /// What part of the sheet it holds; nil for the whole sheet.
        var part: String?
        var cells: Int
        /// Without a picture (its render failed) these are nil: the cells drawn, whether they all lie inside the
        /// window, the picture's width and height in points, how many renders it took and how long it took.
        var found: Int?
        var fits: Bool?
        var size: [Double]?
        var attempts: Int?
        var seconds: Double?
    }
}
