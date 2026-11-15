import Foundation

/// The semantic tokens as the Apple generator writes them: Swift names, a value per theme for each color and one value
/// for everything else, with the checks that what is written is what every Apple input resolves to.
struct AppleTokenModel: Equatable {
    /// A color as Apple stores it: 8-bit sRGB when it is inside sRGB, so that a hex stays the same byte for byte, and
    /// Display P3 otherwise.
    enum ColorValue: Equatable {
        case sRGB(red: UInt8, green: UInt8, blue: UInt8, alpha: Double)
        case displayP3(red: Double, green: Double, blue: Double, alpha: Double)
    }

    /// What the doc comment of a token's Swift members says.
    struct Doc: Equatable {
        var description: String?
        var usage: WestronExtensions.Usage?
    }

    struct Color: Equatable {
        let path: TokenPath
        let name: String
        let doc: Doc
        /// In the order of `themes`.
        let values: [ColorValue]
        /// The backgrounds the color is declared on for the contrast check, each a stack, top first; each once, in
        /// the order of the declarations.
        let backgrounds: [[TokenPath]]
    }

    /// The list colors (`color.category.<name>.<role>`): every category has the same roles.
    struct Categories: Equatable {
        struct Role: Equatable {
            /// The path below the category, `["background-subtle"]`.
            let segments: [String]
            /// The member of `Westron.Category`, `backgroundSubtle`.
            let name: String
            /// The function on SwiftUI's `Color`, `categoryBackgroundSubtle`.
            let colorFunction: String
            let doc: Doc
        }

        struct Category: Equatable {
            /// The name in the tokens, which is the case's raw value: `amber`.
            let rawValue: String
            /// The enum case, `amber`.
            let caseName: String
            /// One per role, in the order of `roles`.
            let colors: [Color]
        }

        let group: TokenPath
        let roles: [Role]
        let categories: [Category]
    }

    /// A color in `Westron.Color.all`, in token order.
    enum ColorEntry: Equatable {
        /// An index into `colors`.
        case plain(Int)
        case category(caseName: String, role: String)
    }

    struct TextRole: Equatable {
        let path: TokenPath
        let name: String
        let doc: Doc
        /// Cases of `Westron.TextRole.TextStyle`, `.Design`, `.Weight`.
        let textStyle: String
        let design: String
        let weight: String
        let size: Double
        let lineHeight: Double
        let letterSpacing: Double
    }

    struct Transition: Equatable {
        let path: TokenPath
        let name: String
        let doc: Doc
        /// Seconds.
        let duration: Double
        let delay: Double
        let curve: TokenValue.CubicBezier
        let spring: WestronExtensions.Spring?
    }

    struct Shadow: Equatable {
        let path: TokenPath
        let name: String
        let doc: Doc
        let color: ColorValue
        let x: Double
        let y: Double
        let blur: Double
        let spread: Double
    }

    struct Dimension: Equatable {
        let path: TokenPath
        let name: String
        let doc: Doc
        let value: Double
    }

    /// The resolver file, as given: the generated files name it.
    var resolver: String
    var colors: [Color] = []
    var allColors: [ColorEntry] = []
    var categories: Categories?
    var textRoles: [TextRole] = []
    var transitions: [Transition] = []
    var shadows: [Shadow] = []
    var dimensions: [Dimension] = []
}

extension AppleTokenModel {
    /// The modifier whose contexts are the themes, and its contexts in the order of `Westron.Theme`.
    static let themeModifier = "theme"
    static let themes = ["light", "dark", "light-hc", "dark-hc"]
    /// The modifier resolved at build time, and the contexts the Apple generator reads; the first is the one the
    /// values come from.
    static let platformModifier = "platform"
    static let platforms = ["ios", "macos", "watchos"]
    /// The set whose tokens are primitives, which the generator leaves out (decisions/0010).
    static let primitiveSet = "primitive"
    /// The group of the list colors.
    static let categoryGroup: TokenPath = "color.category"

    /// Reads the semantic tokens of a resolution.
    /// - Throws: `AppleTokens.Failure` with every problem: a value that differs by density or platform, a token that
    ///   is not a color and differs by theme, a type or unit Apple has no output for yet, a name that cannot be
    ///   derived or collides.
    init(_ resolution: Resolution) throws {
        self.init(resolver: resolution.document.source)
        var problems: [String] = []

        guard let theme = resolution.modifiers.first(where: { $0.name == Self.themeModifier }),
            Set(theme.contextNames) == Set(Self.themes), theme.contexts.count == Self.themes.count
        else {
            throw AppleTokens.Failure([
                "the resolver needs a `\(Self.themeModifier)` modifier with the contexts "
                    + Self.themes.joined(separator: ", ") + " (decisions/0010)"
            ])
        }
        let platform = resolution.modifiers.first { $0.name == Self.platformModifier }
        if let platform {
            let missing = Self.platforms.filter { !platform.contextNames.contains($0) }
            guard missing.isEmpty else {
                throw AppleTokens.Failure([
                    "the `\(Self.platformModifier)` modifier has no context " + missing.joined(separator: ", ")
                ])
            }
        }

        // The values come from each theme at the default density on the first platform; every other Apple input
        // must resolve to the same values.
        let primitives = Set(
            resolution.document.steps.flatMap { step -> [String] in
                guard case .set(let name, let sources) = step, name == Self.primitiveSet else { return [] }
                return sources.map { $0.name(resolver: resolution.document.source) }
            })
        func semantic(_ input: [String: String]) throws -> [ResolvedToken] {
            try resolution.resolve(input).tokens.filter { !primitives.contains($0.source) }
        }
        func baseInput(_ theme: String) -> [String: String] {
            platform == nil ? [Self.themeModifier: theme] : [Self.themeModifier: theme, Self.platformModifier: "ios"]
        }
        var base: [String: [ResolvedToken]] = [:]
        for name in Self.themes { base[name] = try semantic(baseInput(name)) }

        var reported: Set<TokenPath> = []
        for input in resolution.inputs where platform == nil || Self.platforms.contains(input[Self.platformModifier]!) {
            let themeName = input[Self.themeModifier]!
            let reference = try resolution.document.complete(baseInput(themeName))
            guard input != reference else { continue }
            for path in Self.differences(base[themeName]!, try semantic(input)) where reported.insert(path).inserted {
                problems.append(
                    "\(path): differs between \(resolution.describe(reference)) and \(resolution.describe(input)); "
                        + "values that differ by density or platform are not generated for Apple yet")
            }
        }
        let light = base[Self.themes[0]]!
        for name in Self.themes.dropFirst() {
            let other = base[name]!
            for path in Self.differences(light, other, colorsMayDiffer: true) where reported.insert(path).inserted {
                problems.append(
                    "\(path): differs between theme \(Self.themes[0]) and theme \(name); on Apple only colors switch "
                        + "with the theme")
            }
        }
        guard problems.isEmpty else { throw AppleTokens.Failure(problems) }

        let byTheme = Self.themes.map { name in
            Dictionary(base[name]!.map { ($0.path, $0) }) { first, _ in first }
        }
        var categoryTokens: [ResolvedToken] = []
        // `allColors` in token order: an index into `colors`, or the path of a list color.
        var colorOrder: [(plain: Int?, category: TokenPath?)] = []
        for token in light {
            do {
                switch token.type {
                case .color:
                    if token.path.names.starts(with: Self.categoryGroup.names) {
                        categoryTokens.append(token)
                        colorOrder.append((nil, token.path))
                    } else {
                        let values = try Self.themes.indices.map { index -> ColorValue in
                            guard case .color(let color) = byTheme[index][token.path]!.value else {
                                throw SwiftName.Problem(path: token.path, "is not a color in every theme")
                            }
                            return try Self.colorValue(color, path: token.path, theme: Self.themes[index])
                        }
                        colorOrder.append((colors.count, nil))
                        colors.append(
                            Color(
                                path: token.path, name: try SwiftName.member(token.path, dropping: "color"),
                                doc: Doc(token), values: values, backgrounds: Self.backgrounds(token)))
                    }
                case .typography: textRoles.append(try Self.textRole(token))
                case .transition: transitions.append(try Self.transition(token))
                case .shadow: shadows.append(try Self.shadow(token))
                case .dimension: dimensions.append(try Self.dimension(token))
                case .number, .duration, .cubicBezier, .fontFamily, .fontWeight:
                    problems.append(
                        "\(token.path): a semantic token of type \(token.type.rawValue) is not generated for Apple yet")
                }
            } catch let problem as SwiftName.Problem {
                problems.append(problem.description)
            }
        }
        var categoryEntries: [TokenPath: ColorEntry] = [:]
        if !categoryTokens.isEmpty {
            do {
                let categories = try Self.categories(categoryTokens, byTheme: byTheme)
                self.categories = categories
                for category in categories.categories {
                    for (role, color) in zip(categories.roles, category.colors) {
                        categoryEntries[color.path] = .category(caseName: category.caseName, role: role.name)
                    }
                }
            } catch let failure as AppleTokens.Failure {
                problems += failure.problems
            }
        }
        allColors = colorOrder.compactMap { entry in
            entry.plain.map(ColorEntry.plain) ?? entry.category.flatMap { categoryEntries[$0] }
        }
        problems += collisions()
        guard problems.isEmpty else { throw AppleTokens.Failure(problems) }
    }

    /// The paths whose tokens differ between two resolutions, in order. With `colorsMayDiffer`, two colors at the same
    /// path may hold different values.
    static func differences(
        _ first: [ResolvedToken], _ second: [ResolvedToken], colorsMayDiffer: Bool = false
    ) -> [TokenPath] {
        let other = Dictionary(second.map { ($0.path, $0) }) { first, _ in first }
        let paths = Set(first.map(\.path))
        var result = first.compactMap { token -> TokenPath? in
            guard let match = other[token.path] else { return token.path }
            if colorsMayDiffer && token.type == .color && match.type == .color { return nil }
            let same =
                token.type == match.type && token.value == match.value && token.description == match.description
                && token.westron == match.westron
            return same ? nil : token.path
        }
        result += second.map(\.path).filter { !paths.contains($0) }
        return result
    }

    /// The colors of the list colors: the categories in token order, each with the same roles.
    static func categories(
        _ tokens: [ResolvedToken], byTheme: [[TokenPath: ResolvedToken]]
    ) throws -> Categories {
        let depth = categoryGroup.names.count
        var order: [String] = []
        var byCategory: [String: [ResolvedToken]] = [:]
        var problems: [String] = []
        for token in tokens {
            guard token.path.names.count > depth + 1 else {
                problems.append(
                    "\(token.path): a list color is a group of roles, \(categoryGroup).<name>.<role>, not a color")
                continue
            }
            let name = token.path.names[depth]
            if byCategory[name] == nil { order.append(name) }
            byCategory[name, default: []].append(token)
        }
        guard problems.isEmpty, let first = order.first else { throw AppleTokens.Failure(problems) }
        func roles(_ name: String) -> [[String]] {
            byCategory[name]!.map { Array($0.path.names.dropFirst(depth + 1)) }
        }
        func describe(_ roles: [[String]]) -> String {
            roles.map { $0.joined(separator: ".") }.joined(separator: ", ")
        }
        let roleSegments = roles(first)
        for name in order.dropFirst() where roles(name) != roleSegments {
            problems.append(
                "\(categoryGroup).\(name): its roles (\(describe(roles(name)))) differ from \(categoryGroup).\(first)'s "
                    + "(\(describe(roleSegments))); every list color has the same roles")
        }
        guard problems.isEmpty else { throw AppleTokens.Failure(problems) }

        var roles: [Categories.Role] = []
        var categories: [Categories.Category] = []
        do {
            for (index, segments) in roleSegments.enumerated() {
                let path = categoryGroup.appending("<name>")
                let name = try SwiftName.lowerCamelCase(segments, path: TokenPath(path.names + segments))
                let function = try SwiftName.lowerCamelCase(
                    [categoryGroup.names.last!] + segments, path: TokenPath(path.names + segments))
                let docs = order.map { (name: $0, doc: Doc(byCategory[$0]![index])) }
                roles.append(
                    Categories.Role(
                        segments: segments, name: name, colorFunction: function, doc: Self.commonDoc(docs)))
            }
            for name in order {
                let path = categoryGroup.appending(name)
                let colors = try byCategory[name]!.enumerated().map { index, token in
                    let values = try themes.indices.map { theme -> ColorValue in
                        guard case .color(let color) = byTheme[theme][token.path]!.value else {
                            throw SwiftName.Problem(path: token.path, "is not a color in every theme")
                        }
                        return try colorValue(color, path: token.path, theme: themes[theme])
                    }
                    return Color(
                        path: token.path, name: roles[index].name, doc: Doc(token), values: values,
                        backgrounds: backgrounds(token))
                }
                categories.append(
                    Categories.Category(
                        rawValue: name, caseName: try SwiftName.lowerCamelCase([name], path: path), colors: colors))
            }
        } catch let problem as SwiftName.Problem {
            throw AppleTokens.Failure([problem.description])
        }
        return Categories(group: categoryGroup, roles: roles, categories: categories)
    }

    /// The doc of a role that every category has: the description with the category's name taken out, when that
    /// leaves every category with the same text ("the list color amber, translucent" → "the list color,
    /// translucent"); otherwise each category's description in a list.
    static func commonDoc(_ docs: [(name: String, doc: Doc)]) -> Doc {
        /// The text without each " name" that stands as a whole word.
        func general(_ text: String?, removing name: String) -> String? {
            guard let text else { return nil }
            var result = ""
            var rest = Substring(text)
            while let range = rest.range(of: " " + name) {
                let after = rest[range.upperBound...]
                let next = after.first ?? " "
                result += rest[..<range.lowerBound]
                if next.isLetter || next.isNumber || next == "-" { result += rest[range] }
                rest = after
            }
            return result + rest
        }
        let general = docs.map { Doc(description: general($0.doc.description, removing: $0.name), usage: $0.doc.usage) }
        if general.allSatisfy({ $0 == general[0] }) { return general[0] }
        let list = docs.map { "- `\($0.name)`: \($0.doc.description ?? "")" }.joined(separator: "\n")
        return Doc(description: list, usage: docs[0].doc.usage)
    }

    /// The backgrounds of a color's `dev.westron.contrast` declarations, each once, in order.
    static func backgrounds(_ token: ResolvedToken) -> [[TokenPath]] {
        var result: [[TokenPath]] = []
        for stack in token.westron.contrast.flatMap(\.on) where !result.contains(stack) {
            result.append(stack)
        }
        return result
    }

    static func colorValue(_ color: TokenValue.Color, path: TokenPath, theme: String) throws -> ColorValue {
        guard let p3 = color.mapped(into: .displayP3), let sRGB = color.mapped(into: .sRGB) else {
            throw SwiftName.Problem(
                path: path, "theme \(theme): colors in \(color.colorSpace.rawValue) are not converted for Apple yet")
        }
        // Inside sRGB within half an 8-bit step: written in 8 bits.
        guard p3.converted(to: .sRGB).isInGamut(tolerance: 0.5 / 255) else {
            return .displayP3(red: p3.red, green: p3.green, blue: p3.blue, alpha: color.alpha)
        }
        let opaque = RGB(.sRGB, red: sRGB.red, green: sRGB.green, blue: sRGB.blue)
        if let hex = color.hex, hex.uppercased() != opaque.hex {
            throw SwiftName.Problem(
                path: path,
                "theme \(theme): the components convert to \(opaque.hex), but the hex fallback is \(hex); "
                    + "the 8-bit value would not be the token's")
        }
        let bytes = opaque.bytes
        return .sRGB(red: bytes.red, green: bytes.green, blue: bytes.blue, alpha: color.alpha)
    }

    static func textRole(_ token: ResolvedToken) throws -> TextRole {
        guard case .typography(let value) = token.value else { preconditionFailure("a typography token") }
        guard let textStyle = token.westron.apple?.textStyle else {
            throw SwiftName.Problem(
                path: token.path, "a text role needs $extensions.dev.westron.apple.textStyle (decisions/0013)")
        }
        let designs = [
            "system-ui": "default", "ui-rounded": "rounded", "ui-monospace": "monospaced", "ui-serif": "serif",
        ]
        guard let family = value.fontFamily.first, let design = designs[family] else {
            throw SwiftName.Problem(
                path: token.path,
                "font family \(value.fontFamily.first ?? "none") is not a system design; westron ships no fonts and "
                    + "Apple text roles use the system font (decisions/0011)")
        }
        let weights = [
            100: "ultraLight", 200: "thin", 300: "light", 400: "regular", 500: "medium", 600: "semibold", 700: "bold",
            800: "heavy", 900: "black",
        ]
        guard value.fontWeight.value.rounded() == value.fontWeight.value,
            let weight = weights[Int(value.fontWeight.value)]
        else {
            throw SwiftName.Problem(
                path: token.path, "font weight \(value.fontWeight.value) is not a hundred from 100 to 900")
        }
        return TextRole(
            path: token.path, name: try SwiftName.member(token.path, dropping: "typography"), doc: Doc(token),
            textStyle: textStyle.rawValue, design: design, weight: weight,
            size: try points(value.fontSize, token.path), lineHeight: value.lineHeight,
            letterSpacing: try points(value.letterSpacing, token.path))
    }

    static func transition(_ token: ResolvedToken) throws -> Transition {
        guard case .transition(let value) = token.value else { preconditionFailure("a transition token") }
        return Transition(
            path: token.path, name: try SwiftName.member(token.path, dropping: "motion"), doc: Doc(token),
            duration: value.duration.milliseconds / 1000, delay: value.delay.milliseconds / 1000,
            curve: value.timingFunction, spring: token.westron.spring)
    }

    static func shadow(_ token: ResolvedToken) throws -> Shadow {
        guard case .shadow(let layers) = token.value else { preconditionFailure("a shadow token") }
        guard layers.count == 1, let layer = layers.first, !layer.inset else {
            throw SwiftName.Problem(
                path: token.path, "only a single drop shadow, not inset, is generated for Apple yet")
        }
        let spread = try points(layer.spread, token.path)
        guard spread == 0 else {
            throw SwiftName.Problem(path: token.path, "SwiftUI shadows have no spread; a spread is not generated yet")
        }
        return Shadow(
            path: token.path, name: try SwiftName.member(token.path, dropping: "shadow"), doc: Doc(token),
            color: try colorValue(layer.color, path: token.path, theme: "every"),
            x: try points(layer.offsetX, token.path), y: try points(layer.offsetY, token.path),
            blur: try points(layer.blur, token.path), spread: spread)
    }

    static func dimension(_ token: ResolvedToken) throws -> Dimension {
        guard case .dimension(let value) = token.value else { preconditionFailure("a dimension token") }
        return Dimension(
            path: token.path, name: try SwiftName.member(token.path, dropping: nil), doc: Doc(token),
            value: try points(value, token.path))
    }

    /// A dimension in points: px are points on Apple; rem has no Apple meaning yet.
    static func points(_ dimension: TokenValue.Dimension, _ path: TokenPath) throws -> Double {
        guard dimension.unit == .px else {
            throw SwiftName.Problem(path: path, "\(dimension.unit.rawValue) is not converted for Apple yet; use px")
        }
        return dimension.value
    }

    /// Names that two tokens share on one Swift type, or that the type already has (`SwiftName.Reserved`).
    func collisions() -> [String] {
        var problems: [String] = []
        func check(_ type: String, _ members: [(path: TokenPath, name: String)], reserved: Set<String>) {
            var seen: [String: TokenPath] = [:]
            for member in members {
                if reserved.contains(member.name) {
                    problems.append(
                        "\(member.path): its Swift name \(type).\(member.name) collides with a member the type "
                            + "already has; rename the token")
                } else if let other = seen[member.name] {
                    problems.append("\(member.path) and \(other) have the same Swift name \(type).\(member.name)")
                } else {
                    seen[member.name] = member.path
                }
            }
        }
        let categoryGroup = categories.map { $0.group.appending("<name>") }
        check(
            "Color",
            colors.map { ($0.path, $0.name) }
                + (categories?.roles ?? []).map { (TokenPath(categoryGroup!.names + $0.segments), $0.colorFunction) },
            reserved: SwiftName.Reserved.color)
        check("Font", textRoles.map { ($0.path, $0.name) }, reserved: SwiftName.Reserved.font)
        check("Animation", transitions.map { ($0.path, $0.name) }, reserved: SwiftName.Reserved.animation)
        check("Westron.Shadow", shadows.map { ($0.path, $0.name) }, reserved: SwiftName.Reserved.shadow)
        check("CGFloat", dimensions.map { ($0.path, $0.name) }, reserved: SwiftName.Reserved.cgFloat)
        if let categories {
            let roles = categories.roles.map { (TokenPath(categoryGroup!.names + $0.segments), $0.name) }
            let cases = categories.categories.map { (categories.group.appending($0.rawValue), $0.caseName) }
            check("Westron.Category", roles + cases, reserved: SwiftName.Reserved.category)
        }
        return problems
    }
}

extension AppleTokenModel.Doc {
    /// The token's description and usage. A token without a description of its own (the steps of `space` and
    /// `radius` describe only their group) is described by its path, so that every member has a doc comment.
    init(_ token: ResolvedToken) {
        self.init(description: token.description ?? "The token `\(token.path)`.", usage: token.westron.usage)
    }
}
