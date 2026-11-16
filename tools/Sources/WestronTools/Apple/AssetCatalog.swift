/// The asset catalog of the Apple tokens: a colorset per semantic color, in the JSON layout Xcode writes.
///
/// A colorset holds the four themes for every device, and one entry of the watch's own: watchOS is always dark, and its
/// asset catalogs take no appearances (actool reports a watch child with one as unassigned and drops it, Xcode 27.1,
/// 2026-11-15), so the watch gets the dark theme alone (decisions/0010). JSON has no comments, so the note that the
/// file is generated is the first member, in `info`.
enum AssetCatalog {
    /// The catalog's own `Contents.json`.
    static func root(_ resolver: String) -> String {
        object([("info", info(resolver))], indent: 0) + "\n"
    }

    static func colorset(_ color: AppleTokenModel.Color, resolver: String) -> String {
        let (light, dark, lightHC, darkHC) = (color.values[0], color.values[1], color.values[2], color.values[3])
        let luminosityDark = [("appearance", string("luminosity")), ("value", string("dark"))]
        let contrastHigh = [("appearance", string("contrast")), ("value", string("high"))]
        let entries: [(appearances: [[(String, String)]], color: AppleTokenModel.ColorValue, idiom: String)] = [
            ([], light, "universal"),
            ([luminosityDark], dark, "universal"),
            ([contrastHigh], lightHC, "universal"),
            ([luminosityDark, contrastHigh], darkHC, "universal"),
            ([], dark, "watch"),
        ]
        let colors = entries.map { entry in
            var members: [(String, String)] = []
            if !entry.appearances.isEmpty {
                members.append(("appearances", array(entry.appearances.map { object($0, indent: 4) }, indent: 3)))
            }
            members.append(("color", value(entry.color)))
            members.append(("idiom", string(entry.idiom)))
            return object(members, indent: 2)
        }
        return object([("info", info(resolver)), ("colors", array(colors, indent: 1))], indent: 0) + "\n"
    }

    static func info(_ resolver: String) -> String {
        object(
            [
                ("author", string("westron")),
                ("comment", string("Generated from \(resolver) by tools/westron generate. Do not edit.")),
                ("version", "1"),
            ], indent: 1)
    }

    /// `{"color-space": …, "components": {…}}`: 8-bit sRGB as Xcode writes hex (`0x36`), Display P3 as decimals.
    static func value(_ color: AppleTokenModel.ColorValue) -> String {
        let space: String
        let channels: [String]
        let alpha: Double
        switch color {
        case .sRGB(let red, let green, let blue, let opacity):
            space = "srgb"
            channels = [red, green, blue].map { "0x" + AppleTokensSwift.hexByte($0) }
            alpha = opacity
        case .displayP3(let red, let green, let blue, let opacity):
            space = "display-p3"
            channels = [red, green, blue].map { decimal(Double(AppleTokensSwift.channel($0))!) }
            alpha = opacity
        }
        let components = object(
            [
                ("alpha", string(decimal(alpha))), ("blue", string(channels[2])), ("green", string(channels[1])),
                ("red", string(channels[0])),
            ], indent: 4)
        return object([("color-space", string(space)), ("components", components)], indent: 3)
    }

    /// A number with at least three decimals, as Xcode writes them: `1.000`, `0.050`, `0.7254`.
    static func decimal(_ value: Double) -> String {
        var text = AppleTokensSwift.channel(value)
        if !text.contains(".") { text += "." }
        let decimals = text.distance(from: text.firstIndex(of: ".")!, to: text.endIndex) - 1
        return text + String(repeating: "0", count: max(0, 3 - decimals))
    }

    // MARK: - JSON in Xcode's layout: two spaces, " : " between a key and its value

    static func object(_ members: [(String, String)], indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        let lines = members.map { "\(pad)  \(string($0.0)) : \($0.1)" }
        return "{\n" + lines.joined(separator: ",\n") + "\n\(pad)}"
    }

    static func array(_ elements: [String], indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        return "[\n" + elements.map { "\(pad)  \($0)" }.joined(separator: ",\n") + "\n\(pad)]"
    }

    static func string(_ text: String) -> String {
        var result = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result + "\""
    }
}
