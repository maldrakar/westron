/// A problem in a token file or a resolver file: the file, the token or group path, and what is wrong.
public struct TokenError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Kind: String, Sendable {
        /// The file is not valid JSON, or cannot be read.
        case syntax
        /// The file fails the official DTCG JSON Schema.
        case schema
        /// The resolver document is invalid, or a token file is not used by it.
        case resolver
        /// An input that does not match the resolver's modifiers.
        case input
        /// Two modifiers set the same token (decisions/0010).
        case modifierOverlap
        /// A token or group name breaks the DTCG name rules.
        case invalidName
        /// A `$`-property DTCG does not define, or a member a value cannot have.
        case unknownProperty
        /// Valid DTCG that westron does not support (`README.md` next to this file).
        case unsupported
        /// A value that does not match its type.
        case invalidValue
        /// A token whose type cannot be determined.
        case missingType
        /// A reference to a token that does not exist, or to a group.
        case unknownReference
        /// References that form a cycle.
        case circularReference
        /// A reference to a token of another type than expected.
        case typeMismatch
        /// A token and a group at the same path in merged files.
        case conflict
    }

    public let kind: Kind
    /// The file, as given to the reader (a path relative to the repository root).
    public let source: String
    /// The token or group the problem is in; the root for problems of the file as a whole.
    public let path: TokenPath
    public let message: String

    public init(_ kind: Kind, source: String, path: TokenPath, _ message: String) {
        self.kind = kind
        self.source = source
        self.path = path
        self.message = message
    }

    /// `tokens/color.tokens.json: color.text.primary: message`.
    public var description: String {
        path.isRoot ? "\(source): \(message)" : "\(source): \(path): \(message)"
    }
}

/// All problems found in one step (loading a file, merging, resolving), in the order they were found.
public struct TokenErrors: Error, Equatable, Sendable, CustomStringConvertible {
    public let errors: [TokenError]

    public init(_ errors: [TokenError]) {
        self.errors = errors
    }

    public var description: String { errors.map(\.description).joined(separator: "\n") }
}
