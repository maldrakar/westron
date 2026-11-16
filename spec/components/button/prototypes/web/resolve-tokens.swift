// Prototype only (#26): resolves the tokens the Button contract binds into CSS custom properties, so that the web
// prototype draws the real values without hand-copied hex. It is not the CSS token generator, which is #39.
//
//   source tools/apple/xcode-env.sh
//   swift spec/components/button/prototypes/web/resolve-tokens.swift > spec/components/button/prototypes/web/tokens.css
//   swift spec/components/button/prototypes/web/resolve-tokens.swift --gtk > spec/components/button/prototypes/gtk/tokens.css
//
// --gtk writes the same values for GTK 4.20 CSS: custom properties on :root, the themes through media queries only
// (GTK has no attribute selectors), the curve and duration instead of a sampled spring (no linear() in GTK's
// documentation), and no font family where the token says system-ui, so the widget keeps GNOME's font.
//
// Run from the repository root. Foundation only. It reads tokens/westron.resolver.json, merges the sets and the
// contexts in its resolution order, resolves aliases, and keeps the tokens named in the `tokens:` block of
// spec/components/button/button.spec.yaml. The resolver has no `web` platform context yet, so the pointer heights
// come from `macos` and the touch heights from `ios`.
import Foundation

let gtk = CommandLine.arguments.contains("--gtk")
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let tokensDir = root.appendingPathComponent("tokens")
let specPath = root.appendingPathComponent("spec/components/button/button.spec.yaml")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("resolve-tokens: \(message)\n".utf8))
    exit(1)
}

func readJSON(_ url: URL) -> [String: Any] {
    guard let data = try? Data(contentsOf: url),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { fail("cannot read \(url.path)") }
    return object
}

// A token: its inherited $type and its raw $value.
struct Token {
    var type: String?
    var value: Any
    var spring: [String: Any]?
}

/// Merges a token file into a flat map path → token, inheriting $type from the groups.
func merge(_ node: [String: Any], path: [String], inheritedType: String?, into tokens: inout [String: Token]) {
    let type = node["$type"] as? String ?? inheritedType
    if let value = node["$value"] {
        let extensions = node["$extensions"] as? [String: Any]
        tokens[path.joined(separator: ".")] = Token(
            type: type, value: value, spring: extensions?["dev.westron.spring"] as? [String: Any])
        return
    }
    for (key, child) in node where !key.hasPrefix("$") {
        if let group = child as? [String: Any] {
            merge(group, path: path + [key], inheritedType: type, into: &tokens)
        }
    }
}

let resolver = readJSON(tokensDir.appendingPathComponent("westron.resolver.json"))
let sets = resolver["sets"] as? [String: Any] ?? [:]
let modifiers = resolver["modifiers"] as? [String: Any] ?? [:]
let order = (resolver["resolutionOrder"] as? [[String: Any]] ?? []).compactMap { $0["$ref"] as? String }

func sources(_ list: Any?) -> [String] {
    (list as? [[String: Any]] ?? []).compactMap { $0["$ref"] as? String }
}

/// Every token in one combination of contexts, aliases unresolved.
func tokens(contexts: [String: String]) -> [String: Token] {
    var result: [String: Token] = [:]
    for ref in order {
        let parts = ref.split(separator: "/").map(String.init)  // "#", "sets"|"modifiers", name
        guard parts.count == 3 else { fail("unexpected $ref \(ref)") }
        let files: [String]
        if parts[1] == "sets" {
            files = sources((sets[parts[2]] as? [String: Any])?["sources"])
        } else {
            let modifier = modifiers[parts[2]] as? [String: Any] ?? [:]
            guard let context = contexts[parts[2]] ?? modifier["default"] as? String else {
                fail("no context for modifier \(parts[2])")
            }
            files = sources((modifier["contexts"] as? [String: Any])?[context])
        }
        for file in files {
            merge(readJSON(tokensDir.appendingPathComponent(file)), path: [], inheritedType: nil, into: &result)
        }
    }
    return result
}

/// Replaces every "{a.b.c}" alias, also inside composite values, with the value it points to.
func resolve(_ value: Any, in tokens: [String: Token], depth: Int = 0) -> Any {
    if depth > 20 { fail("alias cycle") }
    if let string = value as? String, string.hasPrefix("{"), string.hasSuffix("}") {
        let target = String(string.dropFirst().dropLast())
        guard let token = tokens[target] else { fail("unknown alias \(string)") }
        return resolve(token.value, in: tokens, depth: depth + 1)
    }
    if let object = value as? [String: Any] {
        return object.mapValues { resolve($0, in: tokens, depth: depth + 1) }
    }
    return value
}

// The tokens the contract binds: every token path in its `tokens:` block.
guard let spec = try? String(contentsOf: specPath, encoding: .utf8) else { fail("cannot read \(specPath.path)") }
let tokensBlock: Substring = {
    guard let start = spec.range(of: "\ntokens:\n"), let end = spec.range(of: "\naccessibility:") else {
        fail("no tokens: block in the contract")
    }
    return spec[start.upperBound..<end.lowerBound]
}()
let pathPattern = try NSRegularExpression(
    pattern: #"\b(?:color|space|size|radius|stroke|opacity|motion|typography)\.[a-z0-9.-]*[a-z0-9]"#)
let block = String(tokensBlock)
// The prototype page's own ground and captions, which the contract does not bind.
let pageTokens = ["color.background.canvas", "color.text.secondary", "color.border.default"]
let bound = Set(
    pathPattern.matches(in: block, range: NSRange(block.startIndex..., in: block)).map {
        String(block[Range($0.range, in: block)!])
    } + pageTokens
).sorted()

// CSS output.
func number(_ value: Any) -> String {
    let double = (value as? NSNumber)?.doubleValue ?? 0
    if double == double.rounded() { return String(Int(double)) }
    var text = String(format: "%.4f", double)
    while text.hasSuffix("0") { text.removeLast() }
    return text
}

func name(_ path: String) -> String { "--westron-" + path.replacingOccurrences(of: ".", with: "-") }

func dimension(_ value: Any, rem: Bool = false) -> String {
    guard let object = value as? [String: Any], let amount = object["value"], let unit = object["unit"] as? String
    else { fail("not a dimension: \(value)") }
    if rem && unit == "px" {
        // Text follows the person's default font size on the web (chapter 08), so font sizes are rem of 16 px.
        return number(NSNumber(value: ((amount as? NSNumber)?.doubleValue ?? 0) / 16)) + "rem"
    }
    return number(amount) + unit
}

func cubicBezier(_ value: Any) -> String {
    let points = (value as? [Any] ?? []).map(number)
    return "cubic-bezier(\(points.joined(separator: ", ")))"
}

/// Samples the spring of `dev.westron.spring` into CSS `linear()`, with SwiftUI's mapping from duration and bounce
/// to stiffness (2π / duration)² and damping ratio 1 − bounce (chapter 05). Returns the stops and the time it takes to
/// settle within 0.1 % of its target, which the transition's duration must be.
func springLinear(duration: Double, bounce: Double) -> (String, Double) {
    let omega = 2 * Double.pi / duration
    let zeta = 1 - bounce
    func position(_ t: Double) -> Double {
        if abs(zeta - 1) < 1e-9 { return 1 - (1 + omega * t) * exp(-omega * t) }
        let damped = omega * (1 - zeta * zeta).squareRoot()
        return 1 - exp(-zeta * omega * t) * (cos(damped * t) + zeta * omega / damped * sin(damped * t))
    }
    var settle = 0.0
    var t = 0.0
    while t < 5 {
        if abs(1 - position(t)) > 0.001 { settle = t }
        t += 0.001
    }
    settle += 0.001
    let steps = 24
    let stops = (0...steps).map { step -> String in
        step == steps ? "1" : number(NSNumber(value: position(settle * Double(step) / Double(steps))))
    }
    return ("linear(\(stops.joined(separator: ", ")))", settle)
}

/// The declarations of one token: one custom property, or one per field of a composite.
func declarations(_ path: String, _ token: Token, in tokens: [String: Token]) -> [String] {
    let value = resolve(token.value, in: tokens)
    let property = name(path)
    switch token.type {
    case "color":
        guard let color = value as? [String: Any], let hex = color["hex"] as? String else { fail("\(path): no hex") }
        if let alpha = color["alpha"] as? NSNumber, alpha.doubleValue < 1 {
            return [
                "\(property): color-mix(in srgb, \(hex) \(number(NSNumber(value: alpha.doubleValue * 100)))%, transparent);"
            ]
        }
        return ["\(property): \(hex);"]
    case "dimension":
        return ["\(property): \(dimension(value));"]
    case "number":
        return ["\(property): \(number(value));"]
    case "typography":
        guard let type = value as? [String: Any] else { fail("\(path): not a typography value") }
        let families = (type["fontFamily"] as? [String] ?? [type["fontFamily"] as? String ?? "system-ui"])
            .map { $0.contains(" ") ? "\"\($0)\"" : $0 }
        let family =
            gtk && families == ["system-ui"] ? [] : ["\(property)-font-family: \(families.joined(separator: ", "));"]
        return family + [
            "\(property)-font-size: \(dimension(type["fontSize"]!, rem: true));",
            "\(property)-font-weight: \(number(type["fontWeight"]!));",
            "\(property)-line-height: \(number(type["lineHeight"]!));",
            "\(property)-letter-spacing: \(dimension(type["letterSpacing"]!));",
        ]
    case "transition":
        guard let transition = value as? [String: Any] else { fail("\(path): not a transition") }
        var lines = [
            "\(property)-duration: \(dimension(transition["duration"]!));",
            "\(property)-easing: \(cubicBezier(transition["timingFunction"]!));",
        ]
        if !gtk, let spring = token.spring,
            let duration = (spring["duration"] as? NSNumber)?.doubleValue,
            let bounce = (spring["bounce"] as? NSNumber)?.doubleValue
        {
            let (stops, settle) = springLinear(duration: duration, bounce: bounce)
            lines.append("\(property)-spring-duration: \(Int((settle * 1000).rounded()))ms;")
            lines.append("\(property)-spring: \(stops);")
        }
        return lines
    default:
        fail("\(path): unsupported $type \(token.type ?? "none")")
    }
}

func block(_ selector: String, _ paths: [String], _ tokens: [String: Token], indent: String = "") -> String {
    var lines = ["\(indent)\(selector) {"]
    for path in paths {
        guard let token = tokens[path] else { fail("the contract binds \(path), which the tokens lack") }
        lines += declarations(path, token, in: tokens).map { "\(indent)  \($0)" }
    }
    lines.append("\(indent)}")
    return lines.joined(separator: "\n")
}

let themes = ["light", "dark", "light-hc", "dark-hc"]
let pointer = Dictionary(
    uniqueKeysWithValues: themes.map { ($0, tokens(contexts: ["theme": $0, "platform": "macos"])) })
let touch = tokens(contexts: ["theme": "light", "platform": "ios"])
let colors = bound.filter { pointer["light"]![$0]?.type == "color" }
let others = bound.filter { !colors.contains($0) }
let sizes = others.filter { $0.hasPrefix("size.") }
for path in others
where declarations(path, pointer["dark"]![path]!, in: pointer["dark"]!)
    != declarations(path, pointer["light"]![path]!, in: pointer["light"]!)
{
    fail("\(path) differs by theme, which this script does not expect")
}

/// What the media queries select, and the same theme forced by `data-theme` on <html> for screenshots.
let themeQueries = [
    ("dark", "(prefers-color-scheme: dark)"),
    ("light-hc", "(prefers-contrast: more)"),
    ("dark-hc", "(prefers-color-scheme: dark) and (prefers-contrast: more)"),
]

if gtk {
    var css = """
        /* Generated by spec/components/button/prototypes/web/resolve-tokens.swift --gtk from tokens/ and the tokens:
           block of spec/components/button/button.spec.yaml. Do not edit by hand; run from the repository root:
             source tools/apple/xcode-env.sh
             swift spec/components/button/prototypes/web/resolve-tokens.swift --gtk > spec/components/button/prototypes/gtk/tokens.css
           Prototype only (#26). GTK 4.20 or later: custom properties (4.16) and media queries (4.20).
           Sizes: the resolver has no gnome context; the pointer heights come from `macos`. Font sizes are rem. */

        """
    css += block(":root", others, pointer["light"]!) + "\n\n"
    css += block(":root", colors, pointer["light"]!) + "\n\n"
    for (theme, query) in themeQueries {
        css += "@media \(query) {\n" + block(":root", colors, pointer[theme]!, indent: "  ") + "\n}\n\n"
    }
    print(css, terminator: "")
    exit(0)
}

var css = """
    /* Generated by spec/components/button/prototypes/web/resolve-tokens.swift from tokens/ and the tokens: block of
       spec/components/button/button.spec.yaml. Do not edit by hand; run from the repository root:
         source tools/apple/xcode-env.sh
         swift spec/components/button/prototypes/web/resolve-tokens.swift > spec/components/button/prototypes/web/tokens.css
       Prototype only (#26); the CSS token generator is #39. Only the tokens the Button contract binds are here,
       plus the page's canvas, caption and rule colors.
       Themes: the media queries select them; data-theme on <html> forces one, for screenshots.
       Sizes: the resolver has no web context; the pointer heights come from `macos`, the touch heights from `ios`
       under (pointer: coarse), which is a proposal of this prototype. Font sizes are rem of 16 px. */

    """
css += block(":root", others, pointer["light"]!) + "\n\n"
css +=
    "/* Touch heights where the primary pointer is coarse (proposal, see decisions/0002-portability-to-web-and-gtk.md). */\n"
css += "@media (pointer: coarse) {\n" + block(":root", sizes, touch, indent: "  ") + "\n}\n\n"
css += block(":root,\n:root[data-theme=\"light\"]", colors, pointer["light"]!) + "\n\n"
for (theme, query) in themeQueries {
    css += "@media \(query) {\n" + block(":root:not([data-theme])", colors, pointer[theme]!, indent: "  ") + "\n}\n\n"
}
for (theme, _) in themeQueries {
    css += block(":root[data-theme=\"\(theme)\"]", colors, pointer[theme]!) + "\n\n"
}
print(css, terminator: "")
