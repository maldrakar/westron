/// Swift names of tokens, derived mechanically from their paths (decisions/0010, "Apple API").
///
/// Each path segment is lowercase kebab-case, and the segments join in lowerCamelCase: `color.text.on-accent` is
/// `textOnAccent`. The first segment is dropped where the Swift type already says it (`Color.textSecondary`,
/// `Font.headingLarge`, `Animation.rowLeave`) and kept where it does not (`CGFloat.space100`, `CGFloat.strokeThin`).
public enum SwiftName {
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
    /// - Throws: `Problem` when a segment is not lowercase kebab-case, when the name would start with a digit, or when
    ///   it is a Swift keyword.
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
        guard !keywords.contains(name) else {
            throw Problem(path: path, "the Swift name \(name) is a Swift keyword")
        }
        return name
    }

    /// The name of a token on a Swift type: its path in lowerCamelCase, without the first segment when that is
    /// `dropping` (the group the type already names).
    public static func member(_ path: TokenPath, dropping group: String?) throws -> String {
        let segments = group != nil && path.names.first == group ? Array(path.names.dropFirst()) : path.names
        return try lowerCamelCase(segments, path: path)
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
    /// members of westron's own types. A token whose Swift name is one of them fails generation: the call would be
    /// ambiguous or would shadow the system's (as `buttonStyle(.plain)` would, decisions/0003).
    ///
    /// The lists hold what SwiftUI declared on 2026-11-15 (Xcode 27.1), the deprecated members included; a member
    /// added to SwiftUI later fails the build of the generated code instead.
    public enum Reserved {
        /// `Color` statics, and `ShapeStyle` statics that `.foregroundStyle(.name)` could also mean.
        public static let color: Set<String> = [
            // Color
            "accentColor", "black", "blue", "brown", "clear", "cyan", "gray", "green", "indigo", "mint", "orange",
            "pink", "primary", "purple", "red", "secondary", "teal", "white", "yellow", "init",
            // ShapeStyle
            "foreground", "background", "selection", "separator", "tint", "placeholder", "link", "fill",
            "windowBackground", "tertiary", "quaternary", "quinary", "ultraThinMaterial", "thinMaterial",
            "regularMaterial", "thickMaterial", "ultraThickMaterial", "bar", "image", "linearGradient",
            "radialGradient", "angularGradient", "conicGradient", "ellipticalGradient", "hierarchical", "shadow",
            "opacity", "blendMode", "palette", "multicolor", "monochrome", "rect", "scale", "resolve",
            // Westron.Color
            "name", "light", "dark", "lightHighContrast", "darkHighContrast", "all",
        ]

        /// `Font` statics.
        public static let font: Set<String> = [
            "largeTitle", "title", "title2", "title3", "headline", "subheadline", "body", "callout", "footnote",
            "caption", "caption2", "extraLargeTitle", "extraLargeTitle2", "system", "custom", "init",
            // Westron.TextRole
            "name", "textStyle", "design", "weight", "size", "lineHeight", "letterSpacing", "all",
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
            "rawValue", "allCases", "colors", "hashValue", "init",
        ]

        /// The members of `Westron.Icon` and of its WestronUI extension, which its cases cannot be.
        public static let icon: Set<String> = [
            "rawValue", "allCases", "fallback", "systemName", "hashValue", "init",
        ]
    }
}
