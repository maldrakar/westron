/// The DTCG 2025.10 token types westron supports. The subset and its reasons: `README.md` next to this file.
public enum TokenType: String, CaseIterable, Sendable {
    case color
    case dimension
    case number
    case duration
    case cubicBezier
    case fontFamily
    case fontWeight
    case typography
    case shadow
    case transition

    /// Composite types: their sub-values may be references to other tokens (Format, 9).
    public var isComposite: Bool { self == .typography || self == .shadow || self == .transition }
}

/// What westron reads differently from the full DTCG 2025.10 format: the features it rejects, with the reason that
/// goes into the error. The list is mirrored in `README.md` next to this file.
enum Unsupported {
    /// DTCG types outside the subset.
    static let types: Set<String> = ["strokeStyle", "border", "gradient"]

    static func type(_ name: String) -> String {
        "type \(name) is not in westron's subset yet: add it to the reader and to Tokens/README.md when a component "
            + "needs it"
    }

    static let extends = "$extends (group inheritance) is not supported: write the tokens out, or alias them"
    static let root = "$root tokens are not supported: give the token a name"
    static let pointer =
        "JSON Pointer references ($ref) are not supported: use a curly-brace reference to a whole token"
}

/// `$deprecated` on a token or a group (Format, 5.2.4).
public enum Deprecation: Equatable, Sendable {
    /// `$deprecated: false`: not deprecated, even if a parent group is.
    case notDeprecated
    /// `$deprecated: true`, or a string with the reason.
    case deprecated(reason: String?)

    public var isDeprecated: Bool {
        if case .deprecated = self { return true }
        return false
    }
}
