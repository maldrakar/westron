// The snapshot matrix rendered in-process (#24, #92): every sheet of every component's matrix (`ComponentMatrix.all`,
// generated from the contracts) and of its supplements (hand-written, #72) in every capture of the current OS
// (`ComponentMatrix.Capture.all`: the four themes at the default text size and, on iOS, the light theme at the smallest
// and the largest text size), as PNGs and the manifest `matrix.json` that tools/apple/snapshot-pages.swift builds the
// review page from.
//
// It runs only when WESTRON_SNAPSHOTS names the directory to write to (on the iOS simulator, through xcodebuild,
// TEST_RUNNER_WESTRON_SNAPSHOTS), so `swift test` and `tools/apple/check.sh package` skip it; tools/apple/snapshot-matrix.sh
// sets it. WESTRON_SNAPSHOTS_COMPONENT=<id>[,<id>…] takes some components only.
//
// A picture fails, by name, when a cell draws nothing (the sheet reports each cell's frame, `MatrixSheetProbe`), when a
// cell or the sheet runs past the window ("cut off"), or when four draws give no complete picture (SnapshotRenderer).
// Each picture's line in the log has its time, the process's memory and its windows, so that a leak shows as growth;
// a picture that took more than one draw, or a check draw, has a line with each draw's outcome.
//
// On macOS one CI run drew seven text-field pictures otherwise than every other run of the same code (#99, seen on
// pull request #98, run 44885247356), and why is not identified. The process's languages and locale are pinned, as
// xcodebuild pins them on iOS, which removes a proven dependency of AppKit's text metrics but does not explain that
// run. Two checks name such a state if it comes again, rather than prevent it: a picture fails when AppKit measures
// text otherwise than at the start of the run (`SnapshotRenderer.textMetrics`), and each component's first picture in
// each capture is drawn again at the end and must give the same pixels (`checkReproducible`). Either failure prints
// the process's state at that moment (`SnapshotRenderer.state(since:)`, a `snapshot: state` line).

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
    func matrix() async throws {
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

        SnapshotRenderer.pinLanguage()
        let metrics = SnapshotRenderer.textMetrics
        if let metrics { print("snapshot: text metrics at the start: \(metrics)") }
        let start = Date()
        var count = 0
        var bytes = 0
        var times: [(file: String, seconds: TimeInterval)] = []
        // The pictures drawn again at the end (`checksReproducible`): each component's first picture in each capture.
        var again: [(file: String, key: String, capture: ComponentMatrix.Capture)] = []
        for capture in captures {
            for (componentIndex, groups) in components.enumerated() {
                for (groupIndex, matrix) in groups.enumerated() {
                    for (sheetIndex, sheet) in matrix.sheets.enumerated() {
                        for (pictureIndex, picture) in matrix.pictures(of: sheet, at: capture.textSize).enumerated() {
                            let file = matrix.fileName(of: picture, capture: capture)
                            let cells = matrix.drawnCount(in: picture)
                            var image = SnapshotManifest.Image(
                                file: file, part: matrix.partTitle(of: picture), cells: cells)
                            let began = Date()
                            if let metrics, let now = SnapshotRenderer.textMetrics, now != metrics {
                                let why =
                                    "drawn while the process measured text otherwise than at the start of the run, "
                                    + "so it is not comparable: \(now), at the start \(metrics)"
                                Issue.record("\(file): \(why)")
                                SnapshotRenderer.printState(at: file, since: start)
                            }
                            do {
                                let rendered = try await SnapshotRenderer.render(
                                    key: matrix.key(of: picture), capture: capture)
                                bytes += try SnapshotRenderer.write(
                                    rendered.image, to: output.appendingPathComponent(file))
                                image.found = rendered.found
                                image.fits = rendered.fits
                                image.size = [rendered.size.width, rendered.size.height].map(Double.init)
                                image.attempts = rendered.attempts
                                if rendered.found != cells {
                                    Issue.record("\(file): \(rendered.found) of \(cells) cells drew something")
                                }
                                if !rendered.fits {
                                    Issue.record("\(file): cut off: a cell or the sheet runs past the window")
                                }
                                // Every draw beyond the first, and the check draw of a slow one, with its outcome.
                                if rendered.log.count > 1 || rendered.log.first?.contains("same again") == true {
                                    print("snapshot: \(file) draws: " + rendered.log.joined(separator: "; "))
                                }
                                count += 1
                                if groupIndex == 0, sheetIndex == 0, pictureIndex == 0 {
                                    again.append((file, matrix.key(of: picture), capture))
                                }
                            } catch {
                                Issue.record("\(file): \(error)")
                            }
                            let seconds = Date().timeIntervalSince(began)
                            image.seconds = (seconds * 1000).rounded() / 1000
                            times.append((file, seconds))
                            // The memory and the windows the process holds after each picture: a leak shows as growth.
                            print(
                                String(
                                    format: "snapshot: %@ %.3f s, %d MB, %d windows", file, seconds,
                                    SnapshotRenderer.footprint, SnapshotRenderer.liveWindows))
                            // A picture that failed stays in the manifest without results: the page shows it missing.
                            manifest.components[componentIndex].groups[groupIndex].sheets[sheetIndex]
                                .images[capture.name, default: []].append(image)
                        }
                    }
                }
            }
        }
        let total = Date().timeIntervalSince(start)
        if SnapshotRenderer.checksReproducible {
            await checkReproducible(again, in: output, since: start)
        }
        if let metrics, let now = SnapshotRenderer.textMetrics {
            print("snapshot: text metrics at the end: \(now == metrics ? "the same" : now)")
            if now != metrics { SnapshotRenderer.printState(at: "the end", since: start) }
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(to: output.appendingPathComponent("matrix.json"))
        let slowest = times.sorted { $0.seconds > $1.seconds }.prefix(3)
            .map { String(format: "%@ %.2f s", $0.file, $0.seconds) }.joined(separator: ", ")
        print(
            String(
                format:
                    "snapshot: %d images in %.1f s (%.3f s an image), %.1f MB; slowest: %@; memory at the end %d MB",
                count, total, total / Double(max(count, 1)), Double(bytes) / 1_048_576, slowest,
                SnapshotRenderer.footprint))
    }

    /// Reproducible within the run: draws the pictures again, after every other, and fails by name each one that
    /// differs from what it drew the first time by more than a level in a channel (the tolerance of
    /// `tools/apple/snapshot-matrix.sh compare`), and prints the process's state then. A check against the references
    /// holds only if the same code draws the same pictures; in run 44885247356 (#99) seven pictures of one run
    /// differed from every other run's with no change in the code, for a reason not identified. This does not prevent
    /// that: when a drawn-again picture falls in such a state, or its first draw did, it fails here, named as such,
    /// rather than reading as a change to the pull request.
    func checkReproducible(
        _ pictures: [(file: String, key: String, capture: ComponentMatrix.Capture)], in output: URL,
        since start: Date
    ) async {
        let began = Date()
        var differing: [String] = []
        for picture in pictures {
            guard let first = SnapshotRenderer.read(output.appendingPathComponent(picture.file)) else { continue }
            do {
                let again = try await SnapshotRenderer.render(key: picture.key, capture: picture.capture)
                let why: String
                if let pixels = SnapshotRenderer.differingPixels(first, again.image) {
                    guard pixels > 0 else { continue }
                    why = "drawn again, \(pixels) pixels differ by more than a level from the first draw"
                } else {
                    why =
                        "drawn again \(again.image.width) × \(again.image.height) px, the first draw "
                        + "\(first.width) × \(first.height) px"
                }
                differing.append(picture.file)
                Issue.record("\(picture.file): not reproducible within the run: \(why)")
                SnapshotRenderer.printState(at: picture.file + ", drawn again", since: start)
            } catch {
                Issue.record("\(picture.file): drawn again: \(error)")
            }
        }
        print(
            String(
                format: "snapshot: drawn again at the end: %d pictures in %.1f s, %@", pictures.count,
                Date().timeIntervalSince(began),
                differing.isEmpty ? "each the same" : "differing: " + differing.joined(separator: ", ")))
    }
}

/// The manifest the review page reads (tools/apple/snapshot-pages.swift, `Manifest`).
struct SnapshotManifest: Codable {
    #if os(iOS)
        static let platform = "ios"
    #else
        static let platform = "macos"
    #endif
    /// What every picture pins besides its theme and text size: the locale in SwiftUI's environment, and the process's
    /// language and region, on iOS those xcodebuild runs the catalog in (`-testLanguage`, `-testRegion`), on macOS
    /// those the test sets itself (`SnapshotRenderer.pinLanguage`).
    static let pinned =
        ["locale en_US"]
        + (platform == "ios"
            ? ["-testLanguage en", "-testRegion en_US"]
            : ["AppleLanguages (en)", "AppleLocale en_US"])

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
        /// Without a picture (its render failed) these are nil: the cells that drew something, whether they all lie
        /// inside the window, the picture's width and height in points, how many draws it took and how long.
        var found: Int?
        var fits: Bool?
        var size: [Double]?
        var attempts: Int?
        var seconds: Double?
    }
}
