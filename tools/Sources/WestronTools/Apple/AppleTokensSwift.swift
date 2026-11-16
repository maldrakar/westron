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
                + "WestronUI. A group of tokens is an enum named after it, so `color.background.canvas` is "
                + "`Westron.Color.background.canvas`, and each token is made on its first use.")

        if !model.colors.isEmpty || model.categories != nil {
            out += ["", "extension Westron.Color {"]
            out += members(
                model.colorTree.roots, indent: 1, noun: "colors", doc: { model.colors[$0].doc },
                value: { colorValue(model.colors[$0], indent: $1) })
            out +=
                [""]
                + doc(Doc(description: "Every semantic color in token order, the list colors included."), indent: 1)
            out.append("    public static let all: [Westron.Color] = [")
            for entry in model.allColors {
                switch entry {
                case .plain(let index): out.append("        \(reference(model.colors[index].members)),")
                case .category(let caseName, let role): out.append("        Westron.Category.\(caseName).\(role),")
                }
            }
            out += ["    ]", "}"]
        }

        if let categories = model.categories {
            out += category(categories)
        }

        if !model.textRoles.isEmpty {
            out += tokenType(
                "Westron.TextRole", model.textRoleTree, noun: "text roles", summary: "Every text role in token order.",
                doc: { model.textRoles[$0].doc }, value: { textRoleValue(model.textRoles[$0], indent: $1) })
        }
        if !model.transitions.isEmpty {
            out += tokenType(
                "Westron.Transition", model.transitionTree, noun: "motions", summary: "Every motion in token order.",
                doc: { model.transitions[$0].doc }, value: { transitionValue(model.transitions[$0], indent: $1) })
        }
        if !model.shadows.isEmpty {
            out += tokenType(
                "Westron.Shadow", model.shadowTree, noun: "shadows", summary: "Every shadow in token order.",
                doc: { model.shadows[$0].doc }, value: { shadowValue(model.shadows[$0], indent: $1) })
        }
        if !model.dimensions.isEmpty {
            out += tokenType(
                "Westron.Dimension", model.dimensionTree, noun: "lengths", summary: "Every dimension in token order.",
                doc: { model.dimensions[$0].doc }, value: { dimensionValue(model.dimensions[$0], indent: $1) })
        }
        return out.joined(separator: "\n") + "\n"
    }

    /// `extension Westron.TextRole { members, all }`.
    static func tokenType(
        _ type: String, _ tree: MemberTree, noun: String, summary: String, doc docOf: (Int) -> Doc,
        value: (Int, Int) -> [String]
    ) -> [String] {
        var out = ["", "extension \(type) {"]
        out += members(tree.roots, indent: 1, noun: noun, doc: docOf, value: value)
        out += [""] + doc(Doc(description: summary), indent: 1) + ["    public static let all: [\(type)] = ["]
        let paths = tree.leafPaths.sorted { $0.item < $1.item }
        out += paths.map { "        \(reference($0.path.split(separator: ".").map(String.init)))," } + ["    ]", "}"]
        return out
    }

    /// A static per token and an enum per group, with its members inside, each with its doc, a blank line between.
    static func members(
        _ nodes: [MemberTree.Node], indent: Int, noun: String, doc docOf: (Int) -> Doc, value: (Int, Int) -> [String]
    ) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        let blocks = nodes.map { node -> [String] in
            switch node {
            case .leaf(let name, let item):
                return doc(docOf(item), indent: indent)
                    + indented(
                        assigned("public static let \(SwiftName.declared(name)) = ", value(item, indent)), indent)
            case .group(let group):
                return doc(groupDoc(group, noun: noun), indent: indent)
                    + [pad + "public enum \(SwiftName.declared(group.name)) {"]
                    + members(group.children, indent: indent + 1, noun: noun, doc: docOf, value: value) + [pad + "}"]
            }
        }
        return blocks.joined(separator: [""]).map { $0 }
    }

    /// The doc of a group's enum: what it holds.
    static func groupDoc(_ group: MemberTree.Group, noun: String) -> Doc {
        Doc(description: "The \(noun) `\(group.path).*`.")
    }

    /// The list colors: `Westron.Category`, its roles as members, and the colors of each.
    static func category(_ categories: AppleTokenModel.Categories) -> [String] {
        var out = ["", "extension Westron {"]
        out += doc(
            Doc(
                description:
                    "The list colors, `\(categories.group).<name>.<role>`. A product keeps a list's color by the "
                    + "case's raw value, its name in the tokens, and reads it back with `init(rawValue:)`."),
            indent: 1)
        out.append("    public enum Category: String, CaseIterable, Sendable {")
        for category in categories.categories {
            let declared = SwiftName.declared(category.caseName)
            out.append(
                category.caseName == category.rawValue
                    ? "        case \(declared)"
                    : "        case \(declared) = \(literal(category.rawValue))")
        }
        for (index, role) in categories.roles.enumerated() {
            out.append("")
            out += doc(role.doc, indent: 2)
            out.append("        public var \(SwiftName.declared(role.name)): Westron.Color {")
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
            "public var colors: [Westron.Color] { [", categories.roles.map { SwiftName.declared($0.name) }, "] }",
            indent: 2)
        for category in categories.categories {
            for (role, color) in zip(categories.roles, category.colors) {
                out.append("")
                out += doc(color.doc, indent: 2)
                out += indented(
                    assigned("private static let \(storage(category, role)) = ", colorValue(color, indent: 2)), 2)
            }
        }
        out += ["    }", "}"]
        return out
    }

    /// The private static that holds a list color: `amberBackground`.
    static func storage(
        _ category: AppleTokenModel.Categories.Category, _ role: AppleTokenModel.Categories.Role
    ) -> String {
        category.caseName + role.name.prefix(1).uppercased() + role.name.dropFirst()
    }

    /// A token by its members, written where the type is `Self`: `background.canvas`, `` `default` ``.
    static func reference(_ members: [SwiftName.Member]) -> String {
        reference(members.map(\.name))
    }

    static func reference(_ names: [String]) -> String {
        ([SwiftName.declared(names[0])] + names.dropFirst()).joined(separator: ".")
    }

    // MARK: Values, as lines relative to the indent of their first line

    static func colorValue(_ color: AppleTokenModel.Color, indent: Int) -> [String] {
        // The backgrounds on one line when they fit, as swift format writes a collection; otherwise a stack per line.
        let pad = String(repeating: "    ", count: indent + 1)
        let stacks = color.backgrounds.map { "[" + $0.map { literal($0.description) }.joined(separator: ", ") + "]" }
        let oneLine = "backgrounds: [" + stacks.joined(separator: ", ") + "]"
        let backgrounds: [[String]] =
            stacks.isEmpty
            ? []
            : pad.count + oneLine.count + 1 <= lineLength
                ? [[oneLine]]
                : [["backgrounds: ["] + stacks.map { "    " + $0 + "," } + ["]"]]
        return callLines(
            "Westron.Color(",
            [["name: \(literal(color.path.description))"]]
                + zip(themeLabels, color.values).map { ["\($0): \(rgb($1))"] } + backgrounds)
    }

    static func textRoleValue(_ role: AppleTokenModel.TextRole, indent: Int) -> [String] {
        callLines(
            "Westron.TextRole(",
            [
                "name: \(literal(role.path.description))", "textStyle: .\(role.textStyle)", "design: .\(role.design)",
                "weight: .\(role.weight)", "font: \(role.font.map(literal) ?? "nil")", "size: \(number(role.size))",
                "lineHeight: \(number(role.lineHeight))", "letterSpacing: \(number(role.letterSpacing))",
            ].map { [$0] })
    }

    static func transitionValue(_ transition: AppleTokenModel.Transition, indent: Int) -> [String] {
        let curve = transition.curve
        let spring = transition.spring.map { "Spring(duration: \(number($0.duration)), bounce: \(number($0.bounce)))" }
        return callLines(
            "Westron.Transition(",
            [
                "name: \(literal(transition.path.description))", "duration: \(number(transition.duration))",
                "delay: \(number(transition.delay))",
                "curve: Curve(x1: \(number(curve.x1)), y1: \(number(curve.y1)), x2: \(number(curve.x2)), "
                    + "y2: \(number(curve.y2)))",
                "spring: \(spring ?? "nil")",
            ].map { [$0] })
    }

    static func shadowValue(_ shadow: AppleTokenModel.Shadow, indent: Int) -> [String] {
        let themes = zip(themeLabels, shadow.layers).map { theme, layers -> [String] in
            guard !layers.isEmpty else { return ["\(theme): []"] }
            return ["\(theme): ["]
                + layers.map { layer in
                    "    Layer(color: \(rgb(layer.color)), x: \(number(layer.x)), y: \(number(layer.y)), "
                        + "blur: \(number(layer.blur)), spread: \(number(layer.spread))),"
                } + ["]"]
        }
        return callLines("Westron.Shadow(", [["name: \(literal(shadow.path.description))"]] + themes)
    }

    static func dimensionValue(_ dimension: AppleTokenModel.Dimension, indent: Int) -> [String] {
        oneLineOrCall(
            "Westron.Dimension(",
            ["name: \(literal(dimension.path.description))", "value: \(number(dimension.value))"], indent: indent,
            relative: true)
    }

    // MARK: Layout

    /// A call with one argument per line, each argument lines of its own, the closing parenthesis after the last.
    static func callLines(_ opening: String, _ arguments: [[String]]) -> [String] {
        guard !arguments.isEmpty else { return [opening + ")"] }
        var lines = [opening]
        for (index, argument) in arguments.enumerated() {
            var argument = argument
            argument[argument.count - 1] += index == arguments.count - 1 ? ")" : ","
            lines += argument.map { "    " + $0 }
        }
        return lines
    }

    /// A call on one line at `indent` when it fits, otherwise one argument per line. The lines are indented unless
    /// `relative`.
    static func oneLineOrCall(_ opening: String, _ arguments: [String], indent: Int, relative: Bool = false) -> [String]
    {
        let pad = String(repeating: "    ", count: indent)
        let line = opening + arguments.joined(separator: ", ") + ")"
        let lines = pad.count + line.count <= lineLength ? [line] : callLines(opening, arguments.map { [$0] })
        return relative ? lines : indented(lines, indent)
    }

    /// `prefix` before the first line.
    static func assigned(_ prefix: String, _ lines: [String]) -> [String] {
        [prefix + lines[0]] + lines.dropFirst()
    }

    static func indented(_ lines: [String], _ level: Int) -> [String] {
        let pad = String(repeating: "    ", count: level)
        return lines.map { $0.isEmpty ? $0 : pad + $0 }
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
            "The public SwiftUI accessors of westron's lengths and motions. Each calls an adapter in "
                + "TokenAdapters.swift with a value from WestronTokens: `CGFloat.radius.card` is "
                + "`CGFloat(Westron.Dimension.radius.card)`. Colors and text roles need none: a view passes "
                + "`Westron.Color` to the overloads in TokenAdapters.swift, `.foregroundStyle(.text.primary)`, and "
                + "a role to `.textRole(.body.strong)`.")
        out += ["", "import SwiftUI", "import WestronTokens"]
        out += swiftUIStatics(
            "Animation", "Westron.Transition", model.transitionTree, noun: "motions",
            converted: "as SwiftUI animations",
            doc: { model.transitions[$0].doc })
        out += swiftUIStatics(
            "CGFloat", "Westron.Dimension", model.dimensionTree, noun: "lengths", converted: "in points",
            doc: { model.dimensions[$0].doc })
        return out.joined(separator: "\n") + "\n"
    }

    /// `extension CGFloat { public static var space100: CGFloat { CGFloat(Westron.Dimension.space100) } … }`, with an
    /// enum per group: `CGFloat.radius.card`.
    static func swiftUIStatics(
        _ type: String, _ tokenType: String, _ tree: MemberTree, noun: String, converted: String,
        doc docOf: (Int) -> Doc
    ) -> [String] {
        guard !tree.roots.isEmpty else { return [] }
        func members(_ nodes: [MemberTree.Node], path: [String], indent: Int) -> [String] {
            let pad = String(repeating: "    ", count: indent)
            let blocks = nodes.map { node -> [String] in
                switch node {
                case .leaf(let name, let item):
                    let token = ([tokenType] + path + [name]).joined(separator: ".")
                    return doc(docOf(item), indent: indent) + [
                        pad + "public static var \(SwiftName.declared(name)): \(type) {",
                        pad + "    \(type)(\(token))",
                        pad + "}",
                    ]
                case .group(let group):
                    return doc(Doc(description: "The \(noun) `\(group.path).*` \(converted)."), indent: indent)
                        + [pad + "public enum \(SwiftName.declared(group.name)) {"]
                        + members(group.children, path: path + [group.name], indent: indent + 1) + [pad + "}"]
                }
            }
            return blocks.joined(separator: [""]).map { $0 }
        }
        return ["", "extension \(type) {"] + members(tree.roots, path: [], indent: 1) + ["}"]
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
