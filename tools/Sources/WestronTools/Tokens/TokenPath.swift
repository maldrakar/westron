/// The path of a token or group: names from the root of the file, as in `{color.text.primary}`.
public struct TokenPath: Hashable, Comparable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let names: [String]

    public init(_ names: [String]) {
        self.names = names
    }

    /// A dotted path such as `color.text.primary`; the empty string is the root.
    public init(_ dotted: String) {
        self.names =
            dotted.isEmpty ? [] : dotted.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public static let root = TokenPath([String]())

    public var isRoot: Bool { names.isEmpty }

    public func appending(_ name: String) -> TokenPath {
        TokenPath(names + [name])
    }

    /// The path as in a reference, without braces: `color.text.primary`.
    public var description: String { names.joined(separator: ".") }

    /// Name by name, so that a group's tokens sort together: `a.b` < `a.b.c` < `a.c`.
    public static func < (lhs: TokenPath, rhs: TokenPath) -> Bool {
        lhs.names.lexicographicallyPrecedes(rhs.names) { $0.utf8.lexicographicallyPrecedes($1.utf8) }
    }

    /// Names are equal when their code points are: JSON names are sequences of code points, so `é` written as one
    /// code point and as `e` with a combining accent are two names, which Swift's `String` equality would merge.
    public static func == (lhs: TokenPath, rhs: TokenPath) -> Bool {
        lhs.names.count == rhs.names.count
            && zip(lhs.names, rhs.names).allSatisfy { $0.utf8.elementsEqual($1.utf8) }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(names.count)
        for name in names { hasher.combine(Array(name.utf8)) }
    }
}

/// The DTCG 2025.10 rules for token and group names (Format, 5.1.1).
enum TokenName {
    /// Why a name is invalid, or nil if it is valid. Names starting with `$` are properties and are checked apart.
    static func problem(_ name: String) -> String? {
        if name.isEmpty { return "a token or group name cannot be empty" }
        // By code point: a `.` followed by a combining mark is one Swift `Character` that is not ".".
        if name.unicodeScalars.contains(where: { "{}.".unicodeScalars.contains($0) }) {
            return "a token or group name cannot contain '{', '}' or '.'"
        }
        return nil
    }
}

/// A curly-brace reference to a whole token, `{group.token}` (Format, 7.1.1).
enum Reference {
    enum Problem: Error, Equatable {
        /// Looks like a reference but is not a well-formed one.
        case malformed(String)
        /// A well-formed reference to a `$`-name such as `$root`, which westron does not support.
        case unsupported(String)

        func failure(at location: String) -> ValueFailure {
            switch self {
            case .malformed(let message): ValueFailure(.invalidValue, "\(location): \(message)")
            case .unsupported(let message): ValueFailure(.unsupported, "\(location): \(message)")
            }
        }
    }

    /// The path a string refers to, or nil if the string is not meant as a reference.
    ///
    /// A string that starts with `{` or ends with `}` is meant as one and must be well-formed: `{name(.name)*}`,
    /// with names that follow the name rules.
    static func parse(_ string: String) throws(Problem) -> TokenPath? {
        guard string.hasPrefix("{") || string.hasSuffix("}") else { return nil }
        guard string.count >= 2, string.hasPrefix("{"), string.hasSuffix("}") else {
            throw .malformed("a reference must start with '{' and end with '}': \"\(string)\"")
        }
        let inner = string.dropFirst().dropLast()
        let names = inner.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        for name in names {
            if name.hasPrefix("$") {
                throw .unsupported("references to \(name) are not supported: \"\(string)\" (\(Unsupported.root))")
            }
            if let problem = TokenName.problem(name) {
                throw .malformed("malformed reference \"\(string)\": \(problem)")
            }
        }
        return TokenPath(names)
    }
}
