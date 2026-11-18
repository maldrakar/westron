// The review pages of the snapshot matrix (#24), for tools/apple/snapshot-matrix.sh, which compiles and runs it:
//
//   snapshot-pages index <dir>                   index.html over a matrix capture: <dir>/matrix.json and its PNGs
//   snapshot-pages compare <dirA> <dirB> <out>   compares two captures pixel by pixel, writes <out>/index.html
//
// index exits 1 when an image the manifest expects is missing or a sheet failed its checks; compare exits 0 when every
// image is the same, 1 when one changed, was added or was removed. Both exit 2 on bad input. The pages are
// self-contained: inline styles, relative image links, nothing from the network. Apple-only (ImageIO, CoreGraphics),
// so it lives in tools/apple/ and not in the tools package, which builds on Linux (decisions/0009).

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - The manifest the UI test writes (CatalogUITests/SnapshotMatrixTests.swift)

struct Manifest: Codable {
    var platform: String
    var os: String
    var device: String
    var scale: Double
    var pinned: [String]
    var themes: [String]
    var components: [Component]
}

struct Component: Codable {
    var component: String
    var columns: String
    var combinations: Int
    var notes: [String]
    var sheets: [Sheet]
}

struct Sheet: Codable {
    var id: String
    var title: String
    var fixed: [[String]]
    var cells: Int
    var images: [String: String]
    var found: [String: Int]
    var fits: [String: Bool]
    var settled: [String: Bool]
    var sizes: [String: [Double]]?
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
      --bad: #b3261e; --good: #1e6b3a; --accent: #2f55d4; }
    @media (prefers-color-scheme: dark) { :root { --bg: #1a1917; --fg: #f2ede5; --muted: #a8a196; --line: #3a3732;
      --card: #24221f; --bad: #ff8a80; --good: #7fd49b; --accent: #8fa8ff; } }
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
    var body = ""
    let platformName = manifest.platform == "ios" ? "iOS" : "macOS"
    body += "<h1>Snapshot matrix · \(html(platformName))</h1>\n"
    body +=
        "<p>Every combination each component's contract declares, at rest and in each state alone, in the four themes. "
        + "Generated by <code>tools/apple/snapshot-matrix.sh</code> (#24). Compare two captures with "
        + "<code>tools/apple/snapshot-matrix.sh compare</code>; only captures from the same environment compare "
        + "(decisions/0008).</p>\n"
    let combinations = manifest.components.map(\.combinations).reduce(0, +)
    body += "<dl>"
    body += "<dt>Platform</dt><dd>\(html(manifest.os)), \(html(manifest.device))</dd>"
    body += "<dt>Scale</dt><dd>\(String(format: "%g", manifest.scale))×</dd>"
    body += "<dt>Pinned</dt><dd><code>\(html(manifest.pinned.joined(separator: " ")))</code></dd>"
    body += "<dt>Themes</dt><dd>\(html(manifest.themes.joined(separator: ", ")))</dd>"
    body += "<dt>Combinations</dt><dd>\(combinations) per theme</dd>"
    body += "</dl>\n"
    for component in manifest.components {
        let cells = component.sheets.map(\.cells).reduce(0, +)
        body += "<h2>\(html(component.component))</h2>\n"
        body +=
            "<p>\(component.combinations) combinations on \(component.sheets.count) sheets; on each sheet the columns "
            + "are <code>\(html(component.columns))</code> and the rows rest and each state.</p>\n"
        if cells != component.combinations {
            problems.append(
                "\(component.component): the sheets hold \(cells) cells, the matrix \(component.combinations)")
        }
        if !component.notes.isEmpty {
            body += "<ul>" + component.notes.map { "<li>\(html($0))</li>" }.joined() + "</ul>\n"
        }
        body += "<div class=\"table\"><table>\n<tr><th>Sheet</th>"
        body += manifest.themes.map { "<th>\(html($0))</th>" }.joined() + "</tr>\n"
        for sheet in component.sheets {
            body +=
                "<tr><th><h3>\(html(sheet.title))</h3><div class=\"meta\">\(sheet.cells) cells<br>"
                + "<code>\(html(sheet.id))</code></div></th>"
            for theme in manifest.themes {
                body += "<td>"
                let name = "\(component.component).\(sheet.id).\(theme).png"
                if sheet.images[theme] != nil,
                    FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path)
                {
                    images += 1
                    body +=
                        "<a href=\"\(link(name))\"><img src=\"\(link(name))\" alt=\"\(html(component.component)), "
                        + "\(html(sheet.title)), \(html(theme))\" loading=\"lazy\"></a>"
                } else {
                    problems.append("missing \(name)")
                    body += "<span class=\"bad\">missing</span>"
                }
                if let size = sheet.sizes?[theme], size.count == 2 {
                    body += "<div class=\"meta\">\(Int(size[0])) × \(Int(size[1])) pt</div>"
                }
                var marks: [String] = []
                if let found = sheet.found[theme], found != sheet.cells {
                    marks.append("\(found) of \(sheet.cells) cells on screen")
                    problems.append("\(name): \(found) of \(sheet.cells) cells on screen")
                }
                if sheet.fits[theme] == false {
                    marks.append("cut off")
                    problems.append("\(name): a cell is not wholly inside the window")
                }
                if sheet.settled[theme] == false { marks.append("still changing when taken") }
                if !marks.isEmpty {
                    body += "<div class=\"bad\">\(html(marks.joined(separator: "; ")))</div>"
                }
                body += "</td>"
            }
            body += "</tr>\n"
        }
        body += "</table></div>\n"
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
    print("snapshot-matrix: \(combinations) combinations per theme, \(images) images")
    for problem in problems { FileHandle.standardError.write(Data(("snapshot-matrix: " + problem + "\n").utf8)) }
    return problems.isEmpty ? 0 : 1
}

// MARK: - compare

struct Bitmap {
    let width: Int
    let height: Int
    var bytes: [UInt8]
}

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
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            let image = context.makeImage(),
            let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}

struct Change {
    let name: String
    /// nil: the sizes differ.
    let pixels: Int?
    let size: String
    /// The changed area in pixels, `x, y, w × h`.
    let area: String
}

/// The number of pixels that differ and a picture of them: the new image faded, the changed pixels in red.
func difference(_ before: Bitmap, _ after: Bitmap) -> (pixels: Int, area: String, picture: Bitmap) {
    var picture = after
    var pixels = 0
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in 0..<after.height {
        for x in 0..<after.width {
            let offset = (y * after.width + x) * 4
            let same =
                before.bytes[offset] == after.bytes[offset] && before.bytes[offset + 1] == after.bytes[offset + 1]
                && before.bytes[offset + 2] == after.bytes[offset + 2]
                && before.bytes[offset + 3] == after.bytes[offset + 3]
            if same {
                for channel in 0..<3 {
                    picture.bytes[offset + channel] = UInt8((Int(after.bytes[offset + channel]) + 3 * 255) / 4)
                }
                picture.bytes[offset + 3] = 255
            } else {
                pixels += 1
                picture.bytes[offset] = 230
                picture.bytes[offset + 1] = 0
                picture.bytes[offset + 2] = 0
                picture.bytes[offset + 3] = 255
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }
    let area = pixels == 0 ? "" : "\(minX), \(minY), \(maxX - minX + 1) × \(maxY - minY + 1)"
    return (pixels, area, picture)
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

func manifestLine(_ directory: URL) -> String {
    guard let data = try? Data(contentsOf: directory.appendingPathComponent("matrix.json")),
        let manifest = try? JSONDecoder().decode(Manifest.self, from: data)
    else { return "no manifest" }
    return "\(manifest.os), \(manifest.device), \(String(format: "%g", manifest.scale))×"
}

func compare(_ before: URL, _ after: URL, out: URL) -> Int32 {
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
    let removed = beforeNames.filter { !afterNames.contains($0) }
    let added = afterNames.filter { !beforeNames.contains($0) }
    var changed: [Change] = []
    var unchanged: [String] = []
    for name in beforeNames where afterNames.contains(name) {
        let a = before.appendingPathComponent(name)
        let b = after.appendingPathComponent(name)
        if let first = try? Data(contentsOf: a), let second = try? Data(contentsOf: b), first == second {
            unchanged.append(name)
            continue
        }
        guard let left = bitmap(a), let right = bitmap(b) else { fail("cannot read \(name)") }
        if left.width != right.width || left.height != right.height {
            changed.append(
                Change(
                    name: name, pixels: nil, size: "\(left.width) × \(left.height) → \(right.width) × \(right.height)",
                    area: ""))
        } else {
            let result = difference(left, right)
            if result.pixels == 0 {
                unchanged.append(name)
                continue
            }
            writePNG(result.picture, to: out.appendingPathComponent("diff").appendingPathComponent(name))
            changed.append(
                Change(name: name, pixels: result.pixels, size: "\(right.width) × \(right.height)", area: result.area))
        }
        copy(a, to: out.appendingPathComponent("before").appendingPathComponent(name))
        copy(b, to: out.appendingPathComponent("after").appendingPathComponent(name))
    }
    for name in removed { copy(before.appendingPathComponent(name), to: out.appendingPathComponent("before/" + name)) }
    for name in added { copy(after.appendingPathComponent(name), to: out.appendingPathComponent("after/" + name)) }

    var body = "<h1>Snapshot diff</h1>\n"
    body += "<dl><dt>Before</dt><dd><code>\(html(before.path))</code> · \(html(manifestLine(before)))</dd>"
    body += "<dt>After</dt><dd><code>\(html(after.path))</code> · \(html(manifestLine(after)))</dd>"
    body +=
        "<dt>Result</dt><dd>\(changed.count) changed, \(added.count) added, \(removed.count) removed, "
        + "\(unchanged.count) unchanged</dd></dl>\n"
    body +=
        "<p>Images compare pixel by pixel; only captures from the same environment compare (decisions/0008). In each "
        + "diff the changed pixels are red over the new image, faded.</p>\n"
    body += "<h2>Changed (\(changed.count))</h2>\n"
    for change in changed {
        let what =
            change.pixels.map { "\($0) pixels differ, in \(change.area) of \(change.size)" }
            ?? "the size changed: \(change.size)"
        body += "<h3>\(html(change.name))</h3><p class=\"bad\">\(html(what))</p><div class=\"pair\">"
        body += figure("before/" + change.name, caption: "before")
        body += figure("after/" + change.name, caption: "after")
        if change.pixels != nil { body += figure("diff/" + change.name, caption: "difference") }
        body += "</div>\n"
    }
    body += "<h2>Added (\(added.count))</h2>\n<div class=\"pair\">"
    body += added.map { figure("after/" + $0, caption: $0) }.joined() + "</div>\n"
    body += "<h2>Removed (\(removed.count))</h2>\n<div class=\"pair\">"
    body += removed.map { figure("before/" + $0, caption: $0) }.joined() + "</div>\n"
    body += "<h2>Unchanged (\(unchanged.count))</h2>\n<details><summary>List</summary><ul>"
    body += unchanged.map { "<li><code>\(html($0))</code></li>" }.joined() + "</ul></details>\n"
    let page = page(title: "Snapshot diff", body: body)
    do {
        try Data(page.utf8).write(to: out.appendingPathComponent("index.html"))
    } catch {
        fail("cannot write the report: \(error)")
    }
    for change in changed {
        print("changed: \(change.name) (\(change.pixels.map { "\($0) pixels" } ?? "size \(change.size)"))")
    }
    for name in added { print("added: \(name)") }
    for name in removed { print("removed: \(name)") }
    print(
        "snapshot-matrix compare: \(changed.count) changed, \(added.count) added, \(removed.count) removed, "
            + "\(unchanged.count) unchanged")
    return changed.isEmpty && added.isEmpty && removed.isEmpty ? 0 : 1
}

func figure(_ path: String, caption: String) -> String {
    "<figure><a href=\"\(link(path))\"><img src=\"\(link(path))\" alt=\"\(html(caption))\" loading=\"lazy\"></a>"
        + "<figcaption>\(html(caption))</figcaption></figure>"
}

// MARK: - Main

let arguments = Array(CommandLine.arguments.dropFirst())
func url(_ path: String) -> URL { URL(fileURLWithPath: path).standardizedFileURL }
switch arguments.first {
case "index" where arguments.count == 2:
    exit(index(url(arguments[1])))
case "compare" where arguments.count == 4:
    exit(compare(url(arguments[1]), url(arguments[2]), out: url(arguments[3])))
default:
    fail("usage: snapshot-pages index <dir> | snapshot-pages compare <dirA> <dirB> <out>")
}
