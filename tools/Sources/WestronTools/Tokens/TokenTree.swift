import Foundation

/// The groups and tokens of one DTCG 2025.10 file (`load`), or of several merged in order (`merge`), in document
/// order. References are not resolved yet (`resolve`).
public struct TokenTree: Equatable, Sendable {
    public var root: TokenGroup
    /// The files in this tree, in merge order.
    public var sources: [String]

    public init(root: TokenGroup = TokenGroup(), sources: [String] = []) {
        self.root = root
        self.sources = sources
    }

    /// The token or group at a path; the root group for the root path.
    public func node(at path: TokenPath) -> TokenNode? {
        var node = TokenNode.group(root)
        for name in path.names {
            guard case .group(let group) = node,
                let child = group.children.first(where: { $0.name.utf8.elementsEqual(name.utf8) })
            else {
                return nil
            }
            node = child.node
        }
        return node
    }

    /// Every token, depth first in tree order.
    public var tokens: [(path: TokenPath, token: Token)] {
        var result: [(path: TokenPath, token: Token)] = []
        func walk(_ group: TokenGroup, _ path: TokenPath) {
            for child in group.children {
                switch child.node {
                case .token(let token): result.append((path.appending(child.name), token))
                case .group(let group): walk(group, path.appending(child.name))
                }
            }
        }
        walk(root, .root)
        return result
    }
}

/// A group: its properties and its children in document order (Format, 6).
public struct TokenGroup: Equatable, Sendable {
    public struct Child: Equatable, Sendable {
        public var name: String
        public var node: TokenNode

        public init(_ name: String, _ node: TokenNode) {
            self.name = name
            self.node = node
        }
    }

    /// `$type`: the type of the tokens inside that do not set their own.
    public var type: TokenType?
    public var description: String?
    /// `$deprecated` as written.
    public var deprecated: Deprecation?
    /// `$extensions` as written; westron's keys start with `dev.westron.` (decisions/0004).
    public var extensions: JSON?
    public var children: [Child]

    public init(
        type: TokenType? = nil, description: String? = nil, deprecated: Deprecation? = nil, extensions: JSON? = nil,
        children: [Child] = []
    ) {
        self.type = type
        self.description = description
        self.deprecated = deprecated
        self.extensions = extensions
        self.children = children
    }
}

public enum TokenNode: Equatable, Sendable {
    case group(TokenGroup)
    case token(Token)
}

/// A token as written, before its references are resolved.
///
/// What a token inherits from its groups, `$type` and `$deprecated`, is settled when its file is loaded, from the
/// groups of that file: merging another file never changes the type of a token.
public struct Token: Equatable, Sendable {
    public enum Value: Equatable, Sendable {
        /// The whole `$value` is a reference, `{group.token}`: the token is an alias.
        case reference(TokenPath)
        /// A value of the token's type; it may contain references in composite sub-values.
        case literal(JSON)
    }

    /// `$type`, or else the closest group's `$type` in the same file. Nil only for a reference: it then takes the
    /// type of the token it refers to.
    public var type: TokenType?
    public var value: Value
    public var description: String?
    /// `$deprecated`, or else the closest group's in the same file.
    public var deprecated: Deprecation?
    /// `$extensions` as written, other vendors' keys included.
    public var extensions: JSON?
    /// westron's keys of `$extensions`, read.
    public var westron: WestronExtensions
    /// The file the token comes from.
    public var source: String

    public init(
        type: TokenType?, value: Value, description: String? = nil, deprecated: Deprecation? = nil,
        extensions: JSON? = nil, westron: WestronExtensions = WestronExtensions(), source: String
    ) {
        self.type = type
        self.value = value
        self.description = description
        self.deprecated = deprecated
        self.extensions = extensions
        self.westron = westron
        self.source = source
    }
}

// MARK: - Loading

extension TokenTree {
    /// Reads one DTCG 2025.10 token file. `source` names the file in errors, as a path relative to the repository
    /// root.
    ///
    /// Checks names, properties and the syntax of every value, including references; whether the referenced tokens
    /// exist and have the right type is checked by `resolve`. DTCG features outside westron's subset are errors,
    /// never skipped (`README.md` next to this file).
    /// - Throws: `TokenErrors` with every problem found in the file.
    public static func load(_ data: Data, source: String) throws -> TokenTree {
        let json: JSON
        do {
            json = try JSON.parse(data)
        } catch let error as JSON.SyntaxError {
            throw TokenErrors([TokenError(.syntax, source: source, path: .root, "invalid JSON at \(error)")])
        }
        return try load(json, source: source)
    }

    /// Reads one DTCG 2025.10 token file that is already parsed; see `load(_:source:)`.
    public static func load(_ json: JSON, source: String) throws -> TokenTree {
        var loader = Loader(source: source)
        let root = loader.group(json, at: .root, inherited: Loader.Inherited())
        guard loader.errors.isEmpty, let root else { throw TokenErrors(loader.errors) }
        return TokenTree(root: root, sources: [source])
    }
}

private struct Loader {
    /// What a group passes down to its children.
    struct Inherited {
        var type: TokenType?
        /// The type a group above would give is unknown: its `$type` is invalid, or it uses `$extends`. That is
        /// already reported, so a missing type below is not reported again.
        var typeUnknown = false
        var deprecated: Deprecation?
    }

    let source: String
    var errors: [TokenError] = []

    init(source: String) {
        self.source = source
    }

    mutating func group(_ json: JSON, at path: TokenPath, inherited: Inherited) -> TokenGroup? {
        guard case .object(let members) = json else {
            report(.invalidValue, path, "a group must be an object, found \(json.typeName)")
            return nil
        }
        var group = TokenGroup()
        var inherited = inherited
        // Properties first: a group's $type and $deprecated apply to its children wherever they are written.
        for member in members where member.key.hasPrefix("$") {
            switch member.key {
            case "$type":
                group.type = type(member.value, at: path)
                if group.type == nil { inherited.typeUnknown = true }
            case "$description": group.description = description(member.value, at: path)
            case "$deprecated": group.deprecated = deprecation(member.value, at: path)
            case "$extensions":
                group.extensions = extensions(member.value, at: path)
                if let key = WestronExtensions.groupKey(group.extensions) {
                    report(.unknownProperty, path, "$extensions.\(key): westron's keys go on tokens, not on groups")
                }
            case "$schema" where path.isRoot:
                if member.value.string == nil { report(.invalidValue, path, "$schema must be a string") }
            case "$extends":
                report(.unsupported, path, Unsupported.extends)
                inherited.typeUnknown = true
            case "$root": report(.unsupported, path.appending("$root"), Unsupported.root)
            case "$value": report(.unknownProperty, path, "the root of a token file is a group, it cannot have $value")
            default:
                report(
                    .unknownProperty, path,
                    "unknown property \(member.key); a group has $type, $description, $deprecated and $extensions"
                        + (path.isRoot ? ", the root also $schema" : "")
                        + " (token and group names cannot start with $)")
            }
        }
        if let type = group.type { inherited.type = type }
        if let deprecated = group.deprecated { inherited.deprecated = deprecated }

        for member in members where !member.key.hasPrefix("$") {
            let childPath = path.appending(member.key)
            if let problem = TokenName.problem(member.key) {
                report(.invalidName, childPath, problem)
                continue
            }
            guard case .object(let childMembers) = member.value else {
                report(.invalidValue, childPath, "a token or group must be an object, found \(member.value.typeName)")
                continue
            }
            // An object with $value is a token (Format, 6.1); with $ref instead, a JSON Pointer token.
            if childMembers.contains(where: { $0.key == "$value" || $0.key == "$ref" }) {
                if let token = token(childMembers, at: childPath, inherited: inherited) {
                    group.children.append(TokenGroup.Child(member.key, .token(token)))
                }
            } else if let child = self.group(member.value, at: childPath, inherited: inherited) {
                group.children.append(TokenGroup.Child(member.key, .group(child)))
            }
        }
        return group
    }

    mutating func token(_ members: [JSON.Member], at path: TokenPath, inherited: Inherited) -> Token? {
        var ownType: TokenType?
        var description: String?
        var deprecated: Deprecation?
        var extensions: JSON?
        var valueJSON: JSON?
        var valid = true
        for member in members {
            switch member.key {
            case "$value": valueJSON = member.value
            case "$type":
                ownType = type(member.value, at: path)
                if ownType == nil { valid = false }
            case "$description":
                description = self.description(member.value, at: path)
            case "$deprecated":
                deprecated = deprecation(member.value, at: path)
            case "$extensions":
                extensions = self.extensions(member.value, at: path)
            case "$ref":
                report(.unsupported, path, Unsupported.pointer)
                valid = false
            case let key where key.hasPrefix("$"):
                report(
                    .unknownProperty, path,
                    "unknown property \(key); a token has $value, $type, $description, $deprecated and $extensions")
                valid = false
            case let key:
                report(
                    .unknownProperty, path,
                    "a token cannot contain tokens or groups, found \"\(key)\" (an object with $value is a token)")
                valid = false
            }
        }
        guard valid, let valueJSON else { return nil }
        let westron: WestronExtensions
        do {
            westron = try WestronExtensions.parse(extensions)
        } catch let failure as ValueFailure {
            report(failure.kind ?? .invalidValue, path, failure.message)
            return nil
        } catch {
            report(.invalidValue, path, "\(error)")
            return nil
        }

        let type = ownType ?? inherited.type
        let deprecation = deprecated ?? inherited.deprecated
        func make(_ value: Token.Value) -> Token {
            Token(
                type: type, value: value, description: description, deprecated: deprecation, extensions: extensions,
                westron: westron, source: source)
        }

        if case .string(let text) = valueJSON {
            do throws(Reference.Problem) {
                if let target = try Reference.parse(text) { return make(.reference(target)) }
            } catch {
                let failure = error.failure(at: "$value")
                report(failure.kind ?? .invalidValue, path, failure.message)
                return nil
            }
        }
        if valueJSON == .null {
            report(.invalidValue, path, "$value cannot be null")
            return nil
        }
        guard let type else {
            if !inherited.typeUnknown {
                report(
                    .missingType, path,
                    "the token has no $type and no group above it in this file has one; DTCG does not infer types "
                        + "from values")
            }
            return nil
        }
        do {
            _ = try ValueDecoder.syntaxOnly.decode(valueJSON, as: type)
        } catch let failure as ValueFailure {
            report(failure.kind ?? .invalidValue, path, failure.message)
            return nil
        } catch {
            report(.invalidValue, path, "\(error)")
            return nil
        }
        return make(.literal(valueJSON))
    }

    /// The type a `$type` names, or nil after reporting why it cannot be used.
    mutating func type(_ json: JSON, at path: TokenPath) -> TokenType? {
        guard let name = json.string else {
            report(.invalidValue, path, "$type must be a string, found \(json.typeName)")
            return nil
        }
        if let type = TokenType(rawValue: name) { return type }
        if Unsupported.types.contains(name) {
            report(.unsupported, path, Unsupported.type(name))
        } else {
            report(
                .invalidValue, path,
                "unknown $type \"\(name)\"; westron supports "
                    + TokenType.allCases.map(\.rawValue).joined(separator: ", "))
        }
        return nil
    }

    mutating func description(_ json: JSON, at path: TokenPath) -> String? {
        guard let text = json.string else {
            report(.invalidValue, path, "$description must be a string, found \(json.typeName)")
            return nil
        }
        return text
    }

    mutating func deprecation(_ json: JSON, at path: TokenPath) -> Deprecation? {
        switch json {
        case .bool(true): return .deprecated(reason: nil)
        case .bool(false): return .notDeprecated
        case .string(let reason): return .deprecated(reason: reason)
        default:
            report(.invalidValue, path, "$deprecated must be true, false or a string, found \(json.typeName)")
            return nil
        }
    }

    mutating func extensions(_ json: JSON, at path: TokenPath) -> JSON? {
        guard case .object = json else {
            report(.invalidValue, path, "$extensions must be an object, found \(json.typeName)")
            return nil
        }
        return json
    }

    mutating func report(_ kind: TokenError.Kind, _ path: TokenPath, _ message: String) {
        errors.append(TokenError(kind, source: source, path: path, message))
    }
}

// MARK: - Merging

extension TokenTree {
    /// Merges trees in order, the way the DTCG Resolver module (2025.10, 6.2) combines the sources of a set: the
    /// result behaves as one source, and on a conflict the later occurrence wins.
    ///
    /// - A token replaces an earlier token at the same path whole: value, type, description, deprecation,
    ///   extensions.
    /// - Groups at the same path merge name by name; a group property the later group sets replaces the earlier one.
    /// - Order: a name keeps the position of its first occurrence; new names follow in the later tree's order.
    /// - A token and a group at the same path is an error. The Resolver module does not define this case, and
    ///   silently dropping a whole group or a token is never what an author wants.
    /// - Throws: `TokenErrors` with every conflict.
    public static func merge(_ trees: [TokenTree]) throws -> TokenTree {
        guard var result = trees.first else { return TokenTree() }
        for tree in trees.dropFirst() {
            result = try result.merging(tree)
        }
        return result
    }

    /// This tree with a later one merged on top; see `merge(_:)`.
    public func merging(_ later: TokenTree) throws -> TokenTree {
        var errors: [TokenError] = []
        let root = Self.merge(
            root, later.root, at: .root, earlierSources: sources, laterSources: later.sources, &errors)
        guard errors.isEmpty else { throw TokenErrors(errors) }
        return TokenTree(root: root, sources: sources + later.sources)
    }

    private static func merge(
        _ earlier: TokenGroup, _ later: TokenGroup, at path: TokenPath, earlierSources: [String],
        laterSources: [String], _ errors: inout [TokenError]
    ) -> TokenGroup {
        var result = earlier
        result.type = later.type ?? earlier.type
        result.description = later.description ?? earlier.description
        result.deprecated = later.deprecated ?? earlier.deprecated
        result.extensions = later.extensions ?? earlier.extensions
        for child in later.children {
            let childPath = path.appending(child.name)
            guard let index = result.children.firstIndex(where: { $0.name.utf8.elementsEqual(child.name.utf8) }) else {
                result.children.append(child)
                continue
            }
            switch (result.children[index].node, child.node) {
            case (.group(let a), .group(let b)):
                result.children[index].node = .group(
                    merge(a, b, at: childPath, earlierSources: earlierSources, laterSources: laterSources, &errors))
            case (.token, .token):
                result.children[index].node = child.node
            case (.token(let token), .group):
                errors.append(
                    TokenError(
                        .conflict, source: laterSources.joined(separator: ", "), path: childPath,
                        "a group here, but a token in \(token.source)"))
            case (.group, .token(let token)):
                errors.append(
                    TokenError(
                        .conflict, source: token.source, path: childPath,
                        "a token here, but a group in \(earlierSources.joined(separator: ", "))"))
            }
        }
        return result
    }
}
