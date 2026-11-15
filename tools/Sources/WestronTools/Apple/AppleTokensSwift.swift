/// The Swift sources of the Apple tokens: the values in WestronTokens and the SwiftUI statics in WestronUI. The code is
/// written in the layout `swift format` keeps, so `tools/apple/check.sh format` passes on it.
enum AppleTokensSwift {
    /// The first lines of a generated Swift file: what generated it from what, then what it holds.
    static func header(_ resolver: String, _ purpose: String) -> [String] {
        let origin =
            "Generated from \(resolver) by `tools/westron generate`. Do not edit: change the tokens and generate "
            + "again (decisions/0010)."
        return wrap(origin, width: lineLength - 3).map { "// " + $0 } + ["//"]
            + wrap(purpose, width: lineLength - 3).map { "// " + $0 }
    }

    static let lineLength = 120
    static let themeLabels = ["light", "dark", "lightHighContrast", "darkHighContrast"]

    // MARK: - WestronTokens

    static func tokens(_ model: AppleTokenModel) -> String {
        var out = header(
            model.resolver,
            "The values of westron's semantic tokens as plain Swift, with no imports, so that shared code and its "
                + "WebAssembly build can use them; their types are in Westron.swift, their SwiftUI accessors in "
                + "WestronUI.")

        if !model.colors.isEmpty || model.categories != nil {
            out += ["", "extension Westron.Color {"]
            for color in model.colors {
                out += doc(color.doc, indent: 1)
                out += colorDeclaration(color, name: color.name, access: "public", indent: 1)
                out.append("")
            }
            out += doc(Doc(description: "Every semantic color in token order, the list colors included."), indent: 1)
            out.append("    public static let all: [Westron.Color] = [")
            for entry in model.allColors {
                switch entry {
                case .plain(let index): out.append("        \(model.colors[index].name),")
                case .category(let caseName, let role): out.append("        Westron.Category.\(caseName).\(role),")
                }
            }
            out += ["    ]", "}"]
        }

        if let categories = model.categories {
            out += ["", "extension Westron {"]
            out += doc(
                Doc(
                    description:
                        "The list colors, `\(categories.group).<name>.<role>`. A product keeps a list's color by the "
                        + "case's raw value, its name in the tokens, and reads it back with `init(rawValue:)`."),
                indent: 1)
            out.append("    public enum Category: String, CaseIterable, Sendable {")
            for category in categories.categories {
                out.append(
                    category.caseName == category.rawValue
                        ? "        case \(category.caseName)"
                        : "        case \(category.caseName) = \(literal(category.rawValue))")
            }
            for (index, role) in categories.roles.enumerated() {
                out.append("")
                out += doc(role.doc, indent: 2)
                out.append("        public var \(role.name): Westron.Color {")
                out.append("            switch self {")
                for category in categories.categories {
                    out.append(
                        "            case .\(category.caseName): Self.\(storage(category, categories.roles[index]))")
                }
                out += ["            }", "        }"]
            }
            out.append("")
            out += doc(Doc(description: "The colors of the category, one per role, in token order."), indent: 2)
            out += wrapList(
                "public var colors: [Westron.Color] { [", categories.roles.map(\.name), "] }", indent: 2)
            for category in categories.categories {
                for (role, color) in zip(categories.roles, category.colors) {
                    out.append("")
                    out += doc(color.doc, indent: 2)
                    out += colorDeclaration(color, name: storage(category, role), access: "private", indent: 2)
                }
            }
            out += ["    }", "}"]
        }

        if !model.textRoles.isEmpty {
            out += ["", "extension Westron.TextRole {"]
            for role in model.textRoles {
                out += doc(role.doc, indent: 1)
                out += call(
                    "public static let \(role.name) = Westron.TextRole(",
                    [
                        "name: \(literal(role.path.description))", "textStyle: .\(role.textStyle)",
                        "design: .\(role.design)", "weight: .\(role.weight)", "size: \(number(role.size))",
                        "lineHeight: \(number(role.lineHeight))", "letterSpacing: \(number(role.letterSpacing))",
                    ], indent: 1)
                out.append("")
            }
            out += allList("Westron.TextRole", "Every text role in token order.", model.textRoles.map(\.name))
        }

        if !model.transitions.isEmpty {
            out += ["", "extension Westron.Transition {"]
            for transition in model.transitions {
                let curve = transition.curve
                let spring = transition.spring.map {
                    "Spring(duration: \(number($0.duration)), bounce: \(number($0.bounce)))"
                }
                out += doc(transition.doc, indent: 1)
                out += call(
                    "public static let \(transition.name) = Westron.Transition(",
                    [
                        "name: \(literal(transition.path.description))", "duration: \(number(transition.duration))",
                        "delay: \(number(transition.delay))",
                        "curve: Curve(x1: \(number(curve.x1)), y1: \(number(curve.y1)), x2: \(number(curve.x2)), "
                            + "y2: \(number(curve.y2)))",
                        "spring: \(spring ?? "nil")",
                    ], indent: 1)
                out.append("")
            }
            out += allList("Westron.Transition", "Every motion in token order.", model.transitions.map(\.name))
        }

        if !model.shadows.isEmpty {
            out += ["", "extension Westron.Shadow {"]
            for shadow in model.shadows {
                out += doc(shadow.doc, indent: 1)
                out += call(
                    "public static let \(shadow.name) = Westron.Shadow(",
                    [
                        "name: \(literal(shadow.path.description))", "color: \(rgb(shadow.color))",
                        "x: \(number(shadow.x))", "y: \(number(shadow.y))", "blur: \(number(shadow.blur))",
                        "spread: \(number(shadow.spread))",
                    ], indent: 1)
                out.append("")
            }
            out += allList("Westron.Shadow", "Every shadow in token order.", model.shadows.map(\.name))
        }

        if !model.dimensions.isEmpty {
            out += ["", "extension Westron.Dimension {"]
            for dimension in model.dimensions {
                out += doc(dimension.doc, indent: 1)
                out.append(
                    "    public static let \(dimension.name) = Westron.Dimension(name: "
                        + "\(literal(dimension.path.description)), value: \(number(dimension.value)))")
                out.append("")
            }
            out += allList("Westron.Dimension", "Every dimension in token order.", model.dimensions.map(\.name))
        }
        return out.joined(separator: "\n") + "\n"
    }

    /// The private static that holds a list color: `amberBackground`.
    static func storage(
        _ category: AppleTokenModel.Categories.Category, _ role: AppleTokenModel.Categories.Role
    ) -> String {
        category.caseName + role.name.prefix(1).uppercased() + role.name.dropFirst()
    }

    static func colorDeclaration(_ color: AppleTokenModel.Color, name: String, access: String, indent: Int) -> [String]
    {
        // One line when it fits, as swift format writes a collection; otherwise a stack per line.
        let pad = String(repeating: "    ", count: indent + 1)
        let stacks = color.backgrounds.map { "[" + $0.map { literal($0.description) }.joined(separator: ", ") + "]" }
        let oneLine = "backgrounds: [" + stacks.joined(separator: ", ") + "]"
        let backgrounds =
            stacks.isEmpty
            ? []
            : pad.count + oneLine.count + 1 <= lineLength
                ? [oneLine]
                : [(["backgrounds: ["] + stacks.map { pad + "    " + $0 + "," } + [pad + "]"]).joined(separator: "\n")]
        return call(
            "\(access) static let \(name) = Westron.Color(",
            ["name: \(literal(color.path.description))"]
                + zip(themeLabels, color.values).map { "\($0): \(rgb($1))" } + backgrounds,
            indent: indent)
    }

    /// An initializer call with one argument per line, the closing parenthesis after the last.
    static func call(_ opening: String, _ arguments: [String], indent: Int) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        return [pad + opening]
            + arguments.enumerated().map { index, argument in
                pad + "    " + argument + (index == arguments.count - 1 ? ")" : ",")
            }
    }

    /// `public static let all: [Type] = [...]` and the closing brace of the extension.
    static func allList(_ type: String, _ summary: String, _ names: [String]) -> [String] {
        doc(Doc(description: summary), indent: 1) + ["    public static let all: [\(type)] = ["]
            + names.map { "        \($0)," } + ["    ]", "}"]
    }

    /// `opening` + the items joined by ", " + `closing` on one line when it fits, otherwise one item per line.
    static func wrapList(_ opening: String, _ items: [String], _ closing: String, indent: Int) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        let line = pad + opening + items.joined(separator: ", ") + closing
        if line.count <= lineLength { return [line] }
        let open = opening.hasSuffix(" [") ? String(opening.dropLast()) : opening
        return [pad + open] + items.map { pad + "    " + $0 + "," } + [pad + closing.trimmingPrefix(" ")]
    }

    /// `Westron.RGB(hex: 0x3653C9)`, `Westron.RGB(hex: 0x1F1D1A, opacity: 0.05)`,
    /// `Westron.RGB(.displayP3, red: 0.1, green: 0.9, blue: 0.2)`.
    static func rgb(_ value: AppleTokenModel.ColorValue) -> String {
        switch value {
        case .sRGB(let red, let green, let blue, let alpha):
            let hex = [red, green, blue].map(hexByte).joined()
            return "Westron.RGB(hex: 0x\(hex)\(alpha == 1 ? "" : ", opacity: \(number(alpha))"))"
        case .displayP3(let red, let green, let blue, let alpha):
            let channels = "red: \(channel(red)), green: \(channel(green)), blue: \(channel(blue))"
            return "Westron.RGB(.displayP3, \(channels)\(alpha == 1 ? "" : ", opacity: \(number(alpha))"))"
        }
    }

    // MARK: - WestronUI

    static func swiftUI(_ model: AppleTokenModel) -> String {
        var out = header(
            model.resolver,
            "The public SwiftUI accessors of westron's semantic tokens. Each calls an adapter in TokenAdapters.swift "
                + "with a value from WestronTokens: `Color.textSecondary` is `Color(Westron.Color.textSecondary)`, "
                + "the colorset of that name.")
        out += ["", "import SwiftUI", "import WestronTokens"]

        if !model.colors.isEmpty || model.categories != nil {
            for type in ["Color", "ShapeStyle where Self == Color"] {
                out += ["", "extension \(type) {"]
                var members: [[String]] = model.colors.map { color in
                    doc(color.doc, indent: 1) + [
                        "    public static var \(color.name): Color {",
                        "        Color(Westron.Color.\(color.name))",
                        "    }",
                    ]
                }
                for role in model.categories?.roles ?? [] {
                    members.append(
                        doc(role.doc, indent: 1) + [
                            "    public static func \(role.colorFunction)(_ category: Westron.Category) -> Color {",
                            "        Color(category.\(role.name))",
                            "    }",
                        ])
                }
                out += members.joined(separator: [""])
                out.append("}")
            }
        }
        out += statics("Font", "Westron.TextRole", model.textRoles.map { ($0.name, $0.doc) })
        out += statics("Animation", "Westron.Transition", model.transitions.map { ($0.name, $0.doc) })
        out += statics("CGFloat", "Westron.Dimension", model.dimensions.map { ($0.name, $0.doc) })
        return out.joined(separator: "\n") + "\n"
    }

    /// `extension Font { public static var headingLarge: Font { Font(Westron.TextRole.headingLarge) } … }`.
    static func statics(
        _ type: String, _ tokenType: String, _ members: [(name: String, doc: AppleTokenModel.Doc)]
    ) -> [String] {
        guard !members.isEmpty else { return [] }
        let body = members.map { member in
            doc(member.doc, indent: 1) + [
                "    public static var \(member.name): \(type) {",
                "        \(type)(\(tokenType).\(member.name))",
                "    }",
            ]
        }
        return ["", "extension \(type) {"] + body.joined(separator: [""]) + ["}"]
    }

    // MARK: - Text

    typealias Doc = AppleTokenModel.Doc

    /// A doc comment: the description, then where to use the token and where not, wrapped to the line length. A
    /// description line that starts with "- " is a list item; its continuation lines are indented under it.
    static func doc(_ doc: Doc, indent: Int) -> [String] {
        let pad = String(repeating: "    ", count: indent) + "///"
        let width = lineLength - pad.count - 1
        var paragraphs = (doc.description ?? "").split(separator: "\n", omittingEmptySubsequences: true).map(
            String.init)
        if let usage = doc.usage {
            paragraphs.append("")
            paragraphs.append("Use for: \(usage.use.joined(separator: ", ")). Avoid: \(usage.avoid)")
        }
        guard !paragraphs.isEmpty else { return [] }
        var lines: [String] = []
        for paragraph in paragraphs {
            if paragraph.isEmpty {
                lines.append(pad)
            } else if paragraph.hasPrefix("- ") {
                let wrapped = wrap(String(paragraph.dropFirst(2)), width: width - 2)
                lines += wrapped.enumerated().map { index, line in pad + (index == 0 ? " - " : "   ") + line }
            } else {
                lines += wrap(paragraph, width: width).map { pad + " " + $0 }
            }
        }
        return lines
    }

    /// Words joined into lines of at most `width` characters; a longer word stands on a line of its own.
    static func wrap(_ text: String, width: Int) -> [String] {
        var lines: [String] = []
        var line = ""
        for word in text.split(separator: " ") {
            if line.isEmpty {
                line = String(word)
            } else if line.count + 1 + word.count <= width {
                line += " " + word
            } else {
                lines.append(line)
                line = String(word)
            }
        }
        if !line.isEmpty { lines.append(line) }
        return lines
    }

    /// A Swift string literal.
    static func literal(_ text: String) -> String {
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

    /// A number as written in generated code: up to 9 decimals, no trailing zeros, the same on every machine.
    static func number(_ value: Double) -> String {
        DecimalFormat.fixed(value, decimals: 9, trimmingZeros: true)
    }

    /// A Display P3 channel: 6 decimals, far finer than a 10-bit display step.
    static func channel(_ value: Double) -> String {
        DecimalFormat.fixed(value, decimals: 6, trimmingZeros: true)
    }

    static func hexByte(_ byte: UInt8) -> String {
        let digits = String(byte, radix: 16, uppercase: true)
        return digits.count == 1 ? "0" + digits : digits
    }
}
