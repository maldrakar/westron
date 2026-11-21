// The review pages of the snapshot matrix (#24, #92), for tools/apple/snapshot-matrix.sh, which compiles and runs it:
//
//   snapshot-pages index <dir>      index.html over a render: <dir>/matrix.json and its PNGs
//   snapshot-pages compare <dirA> <dirB> <out> [--tolerance <n>] [--labels <a>,<b>]
//                                   compares two directories of PNGs pixel by pixel, writes <out>/index.html
//   snapshot-pages sync <render> <references> [--tolerance <n>]
//                                   makes the references hold the render's images (`snapshot-matrix.sh record`)
//
// index exits 1 when an image the manifest expects is missing or a sheet failed its checks; compare exits 0 when every
// image is the same within the tolerance (a pixel whose every channel differs by at most <n> levels, 1 by default), 1
// when one changed, was added or was removed. All exit 2 on bad input. The pages are self-contained: inline styles,
// relative image links, nothing from the network. Apple-only (ImageIO, CoreGraphics), so it lives in tools/apple/ and
// not in the tools package, which builds on Linux (decisions/0009).

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - The manifest the snapshot tests write (platforms/apple/Tests/WestronSnapshotTests)

struct Manifest: Codable {
    var platform: String
    var os: String
    var device: String
    var scale: Double
    var pinned: [String]
    /// In order: the four themes at the default text size, then each other text size the OS is captured at.
    var captures: [Capture]
    /// Why the OS is captured at fewer text sizes; nil when it takes them all.
    var textSizeNote: String?
    var components: [Component]
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
    /// The matrix generated from the contract, then the supplements, hand-written for what is not a contract option.
    var groups: [Group]
}

struct Group: Codable {
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
    var fixed: [[String]]
    var cells: Int
    /// By capture: the sheet's picture, or its parts at a text size where it does not fit whole.
    var images: [String: [Image]]
}

struct Image: Codable {
    var file: String
    var part: String?
    var cells: Int
    var found: Int?
    var fits: Bool?
    var size: [Double]?
}

// MARK: - Output

func fail(_ message: String, status: Int32 = 2) -> Never {
    FileHandle.standardError.write(Data(("snapshot-pages: " + message + "\n").utf8))
    exit(status)
}

func html(_ text: String) -> String {
    text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
}

/// A path segment for a link: every byte outside unreserved characters escaped.
func link(_ path: String) -> String {
    path.split(separator: "/", omittingEmptySubsequences: false).map {
        String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(["?", "#", ";"])) ?? ""
    }.joined(separator: "/")
}

let style = """
    :root { color-scheme: light dark; --bg: #faf7f2; --fg: #1f1e1b; --muted: #6b665e; --line: #ddd6cb; --card: #ffffff;
      --bad: #b3261e; --good: #1e6b3a; --accent: #2f55d4; --warn: #8a5a00; }
    @media (prefers-color-scheme: dark) { :root { --bg: #1a1917; --fg: #f2ede5; --muted: #a8a196; --line: #3a3732;
      --card: #24221f; --bad: #ff8a80; --good: #7fd49b; --accent: #8fa8ff; --warn: #f0c060; } }
    * { box-sizing: border-box; }
    body { margin: 0; padding: 24px 16px 48px; background: var(--bg); color: var(--fg);
      font: 14px/1.45 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif; }
    h1 { font-size: 22px; margin: 0 0 4px; } h2 { font-size: 18px; margin: 32px 0 8px; }
    h3 { font-size: 15px; margin: 0; }
    p, li { color: var(--muted); } code { font: 12px ui-monospace, Menlo, monospace; }
    dl { display: grid; grid-template-columns: max-content 1fr; gap: 2px 12px; margin: 12px 0; }
    dt { color: var(--muted); } dd { margin: 0; }
    .table { overflow-x: auto; }
    table { border-collapse: collapse; }
    th, td { border-top: 1px solid var(--line); padding: 8px; vertical-align: top; text-align: left; }
    th { font-weight: 600; white-space: nowrap; }
    td img { display: block; width: 180px; height: auto; border: 1px solid var(--line); background: var(--card); }
    th.size { text-align: center; border-top: 2px solid var(--fg); }
    td.first, th.first { border-left: 2px solid var(--line); }
    .parts { display: flex; gap: 6px; } .parts img { width: 88px; }
    .parts figure { margin: 0; } .parts figcaption { font-size: 11px; color: var(--muted); max-width: 88px; }
    .supplement { border-left: 4px solid var(--warn); padding: 4px 0 4px 12px; margin: 24px 0 8px; }
    .mark { display: inline-block; font-size: 12px; font-weight: 600; color: var(--warn); border: 1px solid var(--warn);
      border-radius: 999px; padding: 1px 8px; margin-right: 8px; }
    .bad { color: var(--bad); font-weight: 600; } .good { color: var(--good); }
    .meta { font-size: 12px; color: var(--muted); }
    .pair { display: flex; flex-wrap: wrap; gap: 12px; margin: 8px 0 24px; }
    .pair figure { margin: 0; } .pair img { display: block; width: 260px; height: auto; border: 1px solid var(--line); }
    .pair figcaption { font-size: 12px; color: var(--muted); }
    a { color: var(--accent); }
    """

func page(title: String, body: String) -> String {
    """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>\(html(title))</title>
    <style>
    \(style)
    </style>
    </head>
    <body>
    \(body)
    </body>
    </html>

    """
}

// MARK: - index

func index(_ directory: URL) -> Int32 {
    let manifestURL = directory.appendingPathComponent("matrix.json")
    guard let data = try? Data(contentsOf: manifestURL) else { fail("no manifest \(manifestURL.path)") }
    let manifest: Manifest
    do {
        manifest = try JSONDecoder().decode(Manifest.self, from: data)
    } catch {
        fail("\(manifestURL.path): \(error)")
    }
    var problems: [String] = []
    var images = 0
    var expected = 0
    var body = ""
    let platformName = manifest.platform == "ios" ? "iOS" : "macOS"
    // The captures grouped by text size, in the manifest's order: the default first, with its four themes.
    var textSizes: [(size: String, captures: [Capture])] = []
    for capture in manifest.captures {
        if let index = textSizes.firstIndex(where: { $0.size == capture.textSize }) {
            textSizes[index].captures.append(capture)
        } else {
            textSizes.append((capture.textSize, [capture]))
        }
    }
    body += "<h1>Snapshot matrix · \(html(platformName))</h1>\n"
    body +=
        "<p>Every combination each component's contract declares, at rest and in each state alone: in the four themes "
        + "at the default text size, and in the light theme at the other text sizes. Rendered in-process by "
        + "<code>tools/apple/snapshot-matrix.sh</code> (#24, #72, #92). Sheets marked <span class=\"mark\">Not a "
        + "contract option</span> are hand-written in the catalog for what no contract option sets, on the contract's "
        + "axes. <code>tools/apple/snapshot-matrix.sh check</code> compares a render with the references, made on the "
        + "CI runner, and <code>compare</code> two renders; only renders from the same environment compare "
        + "(decisions/0008).</p>\n"
    let contract = manifest.components.flatMap { $0.groups.filter { !$0.supplement } }.map(\.combinations)
        .reduce(0, +)
    let supplementary = manifest.components.flatMap { $0.groups.filter(\.supplement) }.map(\.combinations)
        .reduce(0, +)
    body += "<dl>"
    body += "<dt>Platform</dt><dd>\(html(manifest.os)), \(html(manifest.device))</dd>"
    body += "<dt>Scale</dt><dd>\(String(format: "%g", manifest.scale))×</dd>"
    body += "<dt>Environment</dt><dd>\(html(environmentLine(directory)))</dd>"
    body += "<dt>Pinned</dt><dd><code>\(html(manifest.pinned.joined(separator: " ")))</code></dd>"
    body +=
        "<dt>Captures</dt><dd>"
        + textSizes.map { "text size \(html($0.size)): \(html($0.captures.map(\.theme).joined(separator: ", ")))" }
        .joined(separator: "; ") + "</dd>"
    if let note = manifest.textSizeNote { body += "<dt>Text sizes</dt><dd>\(html(note))</dd>" }
    body +=
        "<dt>Combinations</dt><dd>\(contract) from the contracts and \(supplementary) not a contract option, in each "
        + "capture</dd>"
    body += "</dl>\n"
    for component in manifest.components {
        body += "<h2>\(html(component.component))</h2>\n"
        if !component.notes.isEmpty {
            body += "<ul>" + component.notes.map { "<li>\(html($0))</li>" }.joined() + "</ul>\n"
        }
        for group in component.groups {
            let cells = group.sheets.map(\.cells).reduce(0, +)
            if cells != group.combinations {
                problems.append(
                    "\(component.component), \(group.id): the sheets hold \(cells) cells, the matrix "
                        + "\(group.combinations)")
            }
            let summary =
                "\(group.combinations) combinations on \(group.sheets.count) sheets; on each sheet the columns are "
                + "<code>\(html(component.columns))</code> and the rows "
                + (component.rows.map { "<code>\(html($0))</code>." } ?? "rest and each state.")
            if group.supplement {
                body +=
                    "<div class=\"supplement\"><h3><span class=\"mark\">Not a contract option</span>"
                    + "\(html(group.title))</h3><p>\(html(group.note ?? "")) Hand-written in the catalog "
                    + "(<code>ComponentMatrix.Supplement</code>) on the generated sheets; \(summary)</p></div>\n"
            } else {
                body += "<p>From the contract: \(summary)</p>\n"
            }
            body += table(component: component, group: group, textSizes: textSizes, directory: directory) {
                images += $0
                expected += $1
                problems += $2
            }
        }
    }
    if !problems.isEmpty {
        body =
            "<p class=\"bad\">Problems: " + problems.map(html).joined(separator: "; ") + "</p>\n" + body
    }
    let out = directory.appendingPathComponent("index.html")
    do {
        try Data(page(title: "Snapshot matrix · \(platformName)", body: body).utf8).write(to: out)
    } catch {
        fail("cannot write \(out.path): \(error)")
    }
    print(
        "snapshot-matrix: \(contract) combinations from the contracts and \(supplementary) supplementary, in "
            + "\(manifest.captures.count) captures; \(images) of \(expected) images")
    for problem in problems { FileHandle.standardError.write(Data(("snapshot-matrix: " + problem + "\n").utf8)) }
    return problems.isEmpty ? 0 : 1
}

/// A group's table: its sheets down; across, each text size with its themes. A cell holds the sheet's picture, or its
/// parts side by side where it does not fit whole at that size. Reports the images found, those expected and the
/// problems.
func table(
    component: Component, group: Group, textSizes: [(size: String, captures: [Capture])], directory: URL,
    report: (Int, Int, [String]) -> Void
) -> String {
    var images = 0
    var expected = 0
    var problems: [String] = []
    var body = "<div class=\"table\"><table>\n<tr><th rowspan=\"2\">Sheet</th>"
    body +=
        textSizes.map { "<th class=\"size first\" colspan=\"\($0.captures.count)\">Text size \(html($0.size))</th>" }
        .joined() + "</tr>\n<tr>"
    body +=
        textSizes.flatMap { size in
            size.captures.enumerated().map {
                "<th\($0.offset == 0 ? " class=\"first\"" : "")>\(html($0.element.theme))</th>"
            }
        }.joined() + "</tr>\n"
    for sheet in group.sheets {
        body +=
            "<tr><th><h3>\(html(sheet.title))</h3><div class=\"meta\">\(sheet.cells) cells<br>"
            + "<code>\(html(sheet.id))</code></div></th>"
        for size in textSizes {
            for (index, capture) in size.captures.enumerated() {
                body += index == 0 ? "<td class=\"first\">" : "<td>"
                let pictures = sheet.images[capture.name] ?? []
                if pictures.isEmpty {
                    problems.append("\(component.component).\(sheet.id): nothing in \(capture.name)")
                    body += "<span class=\"bad\">missing</span>"
                }
                let cells = pictures.map(\.cells).reduce(0, +)
                if !pictures.isEmpty && cells != sheet.cells {
                    problems.append(
                        "\(component.component).\(sheet.id) \(capture.name): the pictures hold \(cells) cells, the "
                            + "sheet \(sheet.cells)")
                }
                if pictures.count > 1 { body += "<div class=\"parts\">" }
                for picture in pictures {
                    expected += 1
                    let name = picture.file
                    if pictures.count > 1 { body += "<figure>" }
                    if picture.found != nil,
                        FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path)
                    {
                        images += 1
                        body +=
                            "<a href=\"\(link(name))\"><img src=\"\(link(name))\" alt=\"\(html(component.component)), "
                            + "\(html(sheet.title)), \(html(capture.name))\(picture.part.map { ", " + html($0) } ?? "")"
                            + "\" loading=\"lazy\"></a>"
                    } else {
                        problems.append("missing \(name)")
                        body += "<span class=\"bad\">missing</span>"
                    }
                    var meta: [String] = []
                    if let part = picture.part {
                        meta.append(String(part.prefix { $0 != ":" }))
                    }
                    if let size = picture.size, size.count == 2 {
                        meta.append("\(Int(size[0])) × \(Int(size[1])) pt")
                    }
                    if !meta.isEmpty {
                        body += "<div class=\"meta\">\(html(meta.joined(separator: ", ")))</div>"
                    }
                    var marks: [String] = []
                    if let found = picture.found, found != picture.cells {
                        marks.append("\(found) of \(picture.cells) cells drawn")
                        problems.append("\(name): \(found) of \(picture.cells) cells drawn")
                    }
                    if picture.fits == false {
                        marks.append("cut off")
                        problems.append("\(name): a cell is not wholly inside the window")
                    }
                    if !marks.isEmpty {
                        body += "<div class=\"bad\">\(html(marks.joined(separator: "; ")))</div>"
                    }
                    if pictures.count > 1 { body += "</figure>" }
                }
                if pictures.count > 1 { body += "</div>" }
                body += "</td>"
            }
        }
        body += "</tr>\n"
    }
    body += "</table></div>\n"
    report(images, expected, problems)
    return body
}

// MARK: - compare and sync

struct Bitmap {
    let width: Int
    let height: Int
    var bytes: [UInt8]
}

/// An image as 8-bit sRGB RGBA, top row first; nil when the file is not an image (an LFS pointer that was not pulled).
func bitmap(_ url: URL) -> Bitmap? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
        let space = CGColorSpace(name: CGColorSpace.sRGB)
    else { return nil }
    var result = Bitmap(
        width: image.width, height: image.height, bytes: [UInt8](repeating: 0, count: image.width * image.height * 4))
    let drawn = result.bytes.withUnsafeMutableBytes { buffer -> Bool in
        guard
            let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return true
    }
    return drawn ? result : nil
}

func writePNG(_ bitmap: Bitmap, to url: URL) {
    var bytes = bitmap.bytes
    bytes.withUnsafeMutableBytes { buffer in
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: buffer.baseAddress, width: bitmap.width, height: bitmap.height, bitsPerComponent: 8,
                bytesPerRow: bitmap.width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            let image = context.makeImage(),
            let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}

/// How two images of one name compare.
enum Verdict {
    /// The files are the same bytes.
    case identical
    /// Every pixel is the same, the files are not (another encoder, metadata).
    case samePixels
    /// Some pixels differ, none in any channel by more than the tolerance.
    case withinTolerance(pixels: Int, maxDelta: Int)
    /// Some pixels differ by more than the tolerance: their number, the box around them, the largest delta and a
    /// picture of them.
    case changed(pixels: Int, area: String, maxDelta: Int, picture: Bitmap)
    case sizeChanged(String)
    case unreadable(String)
}

/// Compares two image files: the new image faded in the picture, the pixels beyond the tolerance in red and those
/// within it in amber.
func verdict(_ a: URL, _ b: URL, tolerance: Int) -> Verdict {
    if let first = try? Data(contentsOf: a), let second = try? Data(contentsOf: b), first == second {
        return .identical
    }
    guard let before = bitmap(a) else { return .unreadable(a.path) }
    guard let after = bitmap(b) else { return .unreadable(b.path) }
    if before.width != after.width || before.height != after.height {
        return .sizeChanged("\(before.width) × \(before.height) → \(after.width) × \(after.height)")
    }
    var picture = after
    var beyond = 0
    var within = 0
    var maxDelta = 0
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in 0..<after.height {
        for x in 0..<after.width {
            let offset = (y * after.width + x) * 4
            var delta = 0
            for channel in 0..<4 {
                delta = max(delta, abs(Int(before.bytes[offset + channel]) - Int(after.bytes[offset + channel])))
            }
            maxDelta = max(maxDelta, delta)
            if delta == 0 {
                for channel in 0..<3 {
                    picture.bytes[offset + channel] = UInt8((Int(after.bytes[offset + channel]) + 3 * 255) / 4)
                }
            } else if delta <= tolerance {
                within += 1
                picture.bytes.replaceSubrange(offset..<offset + 3, with: [240, 160, 0])
            } else {
                beyond += 1
                picture.bytes.replaceSubrange(offset..<offset + 3, with: [230, 0, 0])
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
            picture.bytes[offset + 3] = 255
        }
    }
    if beyond > 0 {
        return .changed(
            pixels: beyond, area: "\(minX), \(minY), \(maxX - minX + 1) × \(maxY - minY + 1)", maxDelta: maxDelta,
            picture: picture)
    }
    return within > 0 ? .withinTolerance(pixels: within, maxDelta: maxDelta) : .samePixels
}

func pngs(in directory: URL) -> [String] {
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
        fail("no directory \(directory.path)")
    }
    return names.filter { $0.hasSuffix(".png") }.sorted()
}

func copy(_ source: URL, to destination: URL) {
    try? FileManager.default.removeItem(at: destination)
    do {
        try FileManager.default.copyItem(at: source, to: destination)
    } catch {
        fail("cannot copy \(source.path): \(error)")
    }
}

/// What a directory says of the environment its images were made in: `environment.json`, which
/// tools/apple/snapshot-matrix.sh writes beside every render and every reference set, or the manifest's few fields.
func environmentLine(_ directory: URL) -> String {
    if let data = try? Data(contentsOf: directory.appendingPathComponent("environment.json")),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
        if object["recorded"] as? Bool == false { return "no references recorded yet" }
        let keys = ["macos", "machine", "xcode", "runtime", "device", "scale"]
        return keys.compactMap { key in object[key].map { "\(key) \($0)" } }.joined(separator: ", ")
    }
    if let data = try? Data(contentsOf: directory.appendingPathComponent("matrix.json")),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
        return "\(object["os"] ?? "?"), \(object["device"] ?? "?"), \(object["scale"] ?? "?")×"
    }
    return "environment unknown"
}

/// The component of an image: its name up to the first dot.
func component(of name: String) -> String { String(name.prefix { $0 != "." }) }

/// `button (12), text-field (3)`: the components of the names, with how many of each.
func components(_ names: [String]) -> String {
    var counts: [String: Int] = [:]
    for name in names { counts[component(of: name), default: 0] += 1 }
    return counts.keys.sorted().map { "\($0) (\(counts[$0]!))" }.joined(separator: ", ")
}

struct Change {
    let name: String
    let what: String
    let diff: Bool
}

func compare(_ before: URL, _ after: URL, out: URL, tolerance: Int, labels: (String, String)) -> Int32 {
    let beforeNames = pngs(in: before)
    let afterNames = pngs(in: after)
    if beforeNames.isEmpty && afterNames.isEmpty { fail("no PNG in \(before.path) or \(after.path)") }
    let manager = FileManager.default
    for folder in ["before", "after", "diff"] {
        let url = out.appendingPathComponent(folder)
        try? manager.removeItem(at: url)
        do {
            try manager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            fail("cannot create \(url.path): \(error)")
        }
    }
    let afterSet = Set(afterNames)
    let beforeSet = Set(beforeNames)
    let removed = beforeNames.filter { !afterSet.contains($0) }
    let added = afterNames.filter { !beforeSet.contains($0) }
    var changed: [Change] = []
    var unchanged: [String] = []
    var identical = 0
    var samePixels = 0
    var withinTolerance: [(name: String, pixels: Int, maxDelta: Int)] = []
    for name in beforeNames where afterSet.contains(name) {
        let a = before.appendingPathComponent(name)
        let b = after.appendingPathComponent(name)
        switch verdict(a, b, tolerance: tolerance) {
        case .identical:
            identical += 1
            unchanged.append(name)
            continue
        case .samePixels:
            samePixels += 1
            unchanged.append(name)
            continue
        case .withinTolerance(let pixels, let maxDelta):
            withinTolerance.append((name, pixels, maxDelta))
            unchanged.append(name)
            continue
        case .changed(let pixels, let area, let maxDelta, let picture):
            writePNG(picture, to: out.appendingPathComponent("diff").appendingPathComponent(name))
            changed.append(
                Change(
                    name: name,
                    what: "\(pixels) pixels differ by more than \(tolerance), in \(area), up to "
                        + "\(maxDelta) levels", diff: true))
        case .sizeChanged(let size):
            changed.append(Change(name: name, what: "the size changed: \(size)", diff: false))
        case .unreadable(let path):
            changed.append(Change(name: name, what: "not an image: \(path) (an LFS pointer not pulled?)", diff: false))
        }
        copy(a, to: out.appendingPathComponent("before").appendingPathComponent(name))
        copy(b, to: out.appendingPathComponent("after").appendingPathComponent(name))
    }
    for name in removed { copy(before.appendingPathComponent(name), to: out.appendingPathComponent("before/" + name)) }
    for name in added { copy(after.appendingPathComponent(name), to: out.appendingPathComponent("after/" + name)) }

    let (beforeLabel, afterLabel) = labels
    var body = "<h1>Snapshot diff</h1>\n"
    body +=
        "<dl><dt>\(html(beforeLabel.capitalized))</dt><dd><code>\(html(before.path))</code> · "
        + "\(html(environmentLine(before)))</dd>"
    body +=
        "<dt>\(html(afterLabel.capitalized))</dt><dd><code>\(html(after.path))</code> · "
        + "\(html(environmentLine(after)))</dd>"
    body +=
        "<dt>Result</dt><dd>\(changed.count) changed, \(added.count) added, \(removed.count) removed, "
        + "\(unchanged.count) unchanged</dd>"
    if !changed.isEmpty || !added.isEmpty || !removed.isEmpty {
        body +=
            "<dt>Components</dt><dd>\(html(components(changed.map(\.name) + added + removed)))</dd>"
    }
    body += "</dl>\n"
    body +=
        "<p>Images compare pixel by pixel. A pixel whose every channel differs by at most \(tolerance) "
        + "level\(tolerance == 1 ? "" : "s") counts as the same: renders in one environment drift by one level in a few "
        + "pixels of a shadow or an edge from run to run. In each diff the pixels beyond that are red and those within "
        + "it amber, over the \(html(afterLabel)) image, faded. Only images from the same environment compare "
        + "(decisions/0008).</p>\n"
    body += "<h2>Changed (\(changed.count))</h2>\n"
    for change in changed {
        body += "<h3>\(html(change.name))</h3><p class=\"bad\">\(html(change.what))</p><div class=\"pair\">"
        body += figure("before/" + change.name, caption: beforeLabel)
        body += figure("after/" + change.name, caption: afterLabel)
        if change.diff { body += figure("diff/" + change.name, caption: "difference") }
        body += "</div>\n"
    }
    body += "<h2>Added (\(added.count))</h2>\n<div class=\"pair\">"
    body += added.map { figure("after/" + $0, caption: $0) }.joined() + "</div>\n"
    body += "<h2>Removed (\(removed.count))</h2>\n<div class=\"pair\">"
    body += removed.map { figure("before/" + $0, caption: $0) }.joined() + "</div>\n"
    body +=
        "<h2>Unchanged (\(unchanged.count))</h2>\n<p class=\"meta\">\(identical) identical files, \(samePixels) with "
        + "the same pixels in other bytes, \(withinTolerance.count) within the tolerance.</p>"
        + "<details><summary>List</summary><ul>"
    let tolerated = Dictionary(uniqueKeysWithValues: withinTolerance.map { ($0.name, $0) })
    body +=
        unchanged.map { name in
            let note = tolerated[name].map { " · \($0.pixels) pixels differ by up to \($0.maxDelta)" }
            return "<li><code>\(html(name))</code>\(note ?? "")</li>"
        }.joined() + "</ul></details>\n"
    let page = page(title: "Snapshot diff", body: body)
    do {
        try Data(page.utf8).write(to: out.appendingPathComponent("index.html"))
    } catch {
        fail("cannot write the report: \(error)")
    }
    for change in changed { print("changed: \(change.name) (\(change.what))") }
    for name in added { print("added: \(name)") }
    for name in removed { print("removed: \(name)") }
    print(
        "snapshot-matrix compare: \(changed.count) changed, \(added.count) added, \(removed.count) removed, "
            + "\(unchanged.count) unchanged (\(identical) identical files, \(samePixels) the same pixels in other "
            + "bytes, \(withinTolerance.count) within the tolerance of \(tolerance), up to "
            + "\(withinTolerance.map(\.pixels).max() ?? 0) pixels in one image)")
    if !changed.isEmpty || !added.isEmpty || !removed.isEmpty {
        print("snapshot-matrix compare: components: \(components(changed.map(\.name) + added + removed))")
    }
    return changed.isEmpty && added.isEmpty && removed.isEmpty ? 0 : 1
}

/// Makes `references` hold the images of `render`: copies each image that is new or differs beyond the tolerance (or
/// whose reference is not an image, an LFS pointer that was not pulled), keeps a reference within the tolerance as it
/// is, so that a run-to-run drift of one level does not rewrite it, and deletes a reference the render no longer has.
func sync(_ render: URL, _ references: URL, tolerance: Int) -> Int32 {
    let names = pngs(in: render)
    if names.isEmpty { fail("no PNG in \(render.path)") }
    let kept = Set(names)
    var added = 0
    var replaced = 0
    var same = 0
    var removed = 0
    for name in names {
        let source = render.appendingPathComponent(name)
        let target = references.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: target.path) {
            added += 1
        } else {
            switch verdict(target, source, tolerance: tolerance) {
            case .identical, .samePixels, .withinTolerance:
                same += 1
                continue
            case .changed, .sizeChanged, .unreadable:
                replaced += 1
            }
        }
        copy(source, to: target)
    }
    for name in pngs(in: references) where !kept.contains(name) {
        try? FileManager.default.removeItem(at: references.appendingPathComponent(name))
        removed += 1
    }
    print(
        "snapshot-matrix record: \(added) added, \(replaced) replaced, \(removed) removed, \(same) kept as they were "
            + "(within the tolerance of \(tolerance))")
    return 0
}

func figure(_ path: String, caption: String) -> String {
    "<figure><a href=\"\(link(path))\"><img src=\"\(link(path))\" alt=\"\(html(caption))\" loading=\"lazy\"></a>"
        + "<figcaption>\(html(caption))</figcaption></figure>"
}

// MARK: - Main

func url(_ path: String) -> URL { URL(fileURLWithPath: path).standardizedFileURL }

/// The arguments after the positional ones: `--tolerance <n>` and `--labels <before>,<after>`.
func options(_ arguments: ArraySlice<String>) -> (tolerance: Int, labels: (String, String)) {
    var tolerance = 1
    var labels = ("before", "after")
    var rest = arguments
    while let flag = rest.popFirst() {
        guard let value = rest.popFirst() else { fail("\(flag): no value") }
        switch flag {
        case "--tolerance":
            guard let parsed = Int(value), (0...255).contains(parsed) else { fail("--tolerance: 0 to 255") }
            tolerance = parsed
        case "--labels":
            let parts = value.split(separator: ",").map(String.init)
            guard parts.count == 2 else { fail("--labels: two names, comma-separated") }
            labels = (parts[0], parts[1])
        default: fail("unknown option \(flag)")
        }
    }
    return (tolerance, labels)
}

let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
case "index" where arguments.count == 2:
    exit(index(url(arguments[1])))
case "compare" where arguments.count >= 4:
    let (tolerance, labels) = options(arguments[4...])
    exit(compare(url(arguments[1]), url(arguments[2]), out: url(arguments[3]), tolerance: tolerance, labels: labels))
case "sync" where arguments.count >= 3:
    exit(sync(url(arguments[1]), url(arguments[2]), tolerance: options(arguments[3...]).tolerance))
default:
    fail(
        "usage: snapshot-pages index <dir> | snapshot-pages compare <dirA> <dirB> <out> [--tolerance <n>] "
            + "[--labels <a>,<b>] | snapshot-pages sync <render> <references> [--tolerance <n>]")
}
