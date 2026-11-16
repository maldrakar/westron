/// Swift names of tokens, derived mechanically from their paths (decisions/0010, "Apple API").
///
/// A token's Swift name follows its path, segment by segment: `color.text.on-accent` is `Color.text.onAccent`. Each
/// segment is lowercase kebab-case and becomes one member in lowerCamelCase. The first segment is dropped where the
/// Swift type already says it (`Color.text.secondary`, `Westron.TextRole.heading.large`, `Animation.rowLeave`) and
/// kept where it does not (`CGFloat.stroke.thin`). A segment that starts with a digit joins the one before it, as a
/// Swift name cannot start with a digit: `space.100` is `CGFloat.space100`.
public enum SwiftName {
    /// One member of a token's Swift name, and the token path up to it: `status` of `color.status`.
    public struct Member: Equatable, Sendable {
        public let name: String
        public let path: TokenPath
    }

    /// The members of a token's Swift name: `color.status.danger.on-fill` dropping `color` is `status`, `danger`,
    /// `onFill`; `space.100` is `space100`.
    /// - Throws: `Problem` when a segment is not lowercase kebab-case, when the name would start with a digit, or when
    ///   a member is a word Swift cannot use as one (`self`, `init`, `Type`).
    public static func members(_ path: TokenPath, dropping group: String?) throws -> [Member] {
        let skipped = group != nil && path.names.first == group ? 1 : 0
        let segments = Array(path.names.dropFirst(skipped))
        guard !segments.isEmpty else { throw Problem(path: path, "no name is left after the group the type names") }
        var members: [(segments: [String], end: Int)] = []
        for (index, segment) in segments.enumerated() {
            if let first = segment.unicodeScalars.first, ("0"..."9").contains(first), !members.isEmpty {
                members[members.count - 1].segments.append(segment)
                members[members.count - 1].end = index
            } else {
                members.append(([segment], index))
            }
        }
        return try members.map { member in
            let name = try lowerCamelCase(member.segments, path: path)
            guard !unusable.contains(name) else {
                throw Problem(path: path, "the Swift name \(name) cannot be a member")
            }
            return Member(name: name, path: TokenPath(Array(path.names.prefix(skipped + member.end + 1))))
        }
    }

    /// A member as declared: in backticks when it is a Swift keyword, `` `default` ``. After a dot it needs none.
    public static func declared(_ name: String) -> String {
        keywords.contains(name) ? "`\(name)`" : name
    }

    /// The type of a group of tokens: its members in UpperCamelCase, `status`, `danger` → `StatusDanger`.
    public static func typeName(_ members: [String]) -> String {
        members.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }

    /// Words that cannot name a member even in backticks, because `x.self`, `x.init` and `x.Type` mean something else.
    static let unusable: Set<String> = ["self", "Self", "init", "Type", "Protocol"]
    /// A name that cannot be derived, or that collides.
    public struct Problem: Error, Equatable, CustomStringConvertible {
        public let path: TokenPath
        public let message: String

        public init(path: TokenPath, _ message: String) {
            self.path = path
            self.message = message
        }

        public var description: String { "\(path): \(message)" }
    }

    /// `row-leave` → `rowLeave`, `100` → `100`; nil when a segment is not lowercase kebab-case
    /// (`[a-z0-9]+(-[a-z0-9]+)*`).
    static func words(_ segment: String) -> [String]? {
        let words = segment.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        let valid = words.allSatisfy { word in
            !word.isEmpty && word.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) }
        }
        return valid ? words : nil
    }

    /// The lowerCamelCase name of path segments: `["text", "on-accent"]` → `textOnAccent`.
    /// - Throws: `Problem` when a segment is not lowercase kebab-case or when the name would start with a digit.
    public static func lowerCamelCase(_ segments: [String], path: TokenPath) throws -> String {
        guard !segments.isEmpty else { throw Problem(path: path, "no name is left after the group the type names") }
        var words: [String] = []
        for segment in segments {
            guard let parts = Self.words(segment) else {
                throw Problem(path: path, "\"\(segment)\" is not a lowercase kebab-case name (decisions/0010)")
            }
            words += parts
        }
        let name =
            words[0] + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        guard let first = name.unicodeScalars.first, ("a"..."z").contains(first) else {
            throw Problem(path: path, "the Swift name \(name) would start with a digit")
        }
        return name
    }

    /// The Swift keywords a member name cannot be without backticks.
    static let keywords: Set<String> = [
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout",
        "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public", "rethrows",
        "static", "struct", "subscript", "typealias", "var", "break", "case", "catch", "continue", "default", "defer",
        "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw", "switch", "where",
        "while", "as", "false", "is", "nil", "self", "super", "throws", "true", "try", "await", "async", "any", "some",
        "consume", "copy", "discard", "each", "borrowing", "consuming", "Type", "Self", "Any",
    ]
}

extension SwiftName {
    /// Static members that SwiftUI and the standard library already declare on a type the generator extends, and the
    /// members of westron's own types. A token whose first member is one of them fails generation: the call would be
    /// ambiguous or would shadow the system's (as `buttonStyle(.plain)` would, decisions/0003).
    ///
    /// The lists hold what SwiftUI declared on 2026-11-15 (Xcode 27.1), the deprecated members included; a member
    /// added to SwiftUI later fails the build of the generated code instead.
    public enum Reserved {
        /// `Color` statics and the members of `Westron.Color`. No color and no group of colors can take one: an
        /// explicit `Color.primary` would be ambiguous.
        public static let color: Set<String> = [
            // Color
            "accentColor", "black", "blue", "brown", "clear", "cyan", "gray", "green", "indigo", "mint", "orange",
            "pink", "primary", "purple", "red", "secondary", "teal", "white", "yellow", "init",
            // Westron.Color
            "name", "light", "dark", "lightHighContrast", "darkHighContrast", "all", "category",
        ]

        /// `ShapeStyle` statics of other styles, which `.foregroundStyle(.name)` could also mean. A color cannot take
        /// one, but a group of colors can: its static is a group, not a style, so `.background` stays SwiftUI's and
        /// `.background.canvas` is westron's (probe, Xcode 27.1, 2026-11-16).
        public static let shapeStyle: Set<String> = [
            "foreground", "background", "selection", "separator", "tint", "placeholder", "link", "fill",
            "windowBackground", "tertiary", "quaternary", "quinary", "ultraThinMaterial", "thinMaterial",
            "regularMaterial", "thickMaterial", "ultraThickMaterial", "bar", "image", "linearGradient",
            "radialGradient", "angularGradient", "conicGradient", "ellipticalGradient", "hierarchical", "shadow",
            "opacity", "blendMode", "palette", "multicolor", "monochrome", "rect", "scale", "resolve",
        ]

        /// The members of `Westron.TextRole`. Text roles have no statics on SwiftUI's `Font`: a group `body` there
        /// would make `Font.body` ambiguous, so a role is `.textRole(.body.strong)` or `Font(.body.strong)`.
        public static let textRole: Set<String> = [
            "name", "textStyle", "design", "weight", "font", "size", "lineHeight", "letterSpacing", "platformSize",
            "all", "init",
        ]

        /// `Animation` statics.
        public static let animation: Set<String> = [
            "default", "linear", "easeIn", "easeOut", "easeInOut", "spring", "interactiveSpring",
            "interpolatingSpring", "bouncy", "smooth", "snappy", "timingCurve", "init",
            // Westron.Transition
            "name", "duration", "delay", "curve", "all",
        ]

        /// `CGFloat` statics.
        public static let cgFloat: Set<String> = [
            "pi", "infinity", "nan", "signalingNaN", "zero", "greatestFiniteMagnitude", "leastNormalMagnitude",
            "leastNonzeroMagnitude", "ulpOfOne", "radix", "exponentBitCount", "significandBitCount", "random",
            "minimum", "maximum", "init",
            // Westron.Dimension
            "name", "value", "all",
        ]

        /// The members of `Westron.Shadow`; shadows have no SwiftUI statics (`.shadow(.raised)` takes the token).
        public static let shadow: Set<String> = [
            "name", "color", "x", "y", "blur", "spread", "radius", "all", "init",
        ]

        /// The members of `Westron.Category`, which its cases and its roles cannot be.
        public static let category: Set<String> = [
            "rawValue", "allCases", "colors", "roles", "hashValue", "init", "map",
        ]

        /// The members of a group's type, which the tokens in the group cannot be.
        public static let group: Set<String> = ["map"]

        /// The types nested in westron's token types and the generic parameters of a group's type, which no group's
        /// type can be.
        public static let types: Set<String> = [
            "TextStyle", "Design", "Weight", "Curve", "Spring", "Layer", "Space", "Roles", "Value", "T",
        ]

        /// The members of `Westron.Icon` and of its WestronUI extension, which its cases cannot be.
        public static let icon: Set<String> = [
            "rawValue", "allCases", "fallback", "systemName", "hashValue", "init",
        ]
    }
}
