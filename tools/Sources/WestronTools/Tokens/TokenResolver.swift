/// A token with every reference resolved.
public struct ResolvedToken: Equatable, Sendable {
    public let path: TokenPath
    public let type: TokenType
    public let value: TokenValue
    /// The token this one is an alias of, when its whole `$value` is a reference; nil for a value written out
    /// (which may still use references in composite sub-values). Generators can emit the alias as a reference.
    public let aliasOf: TokenPath?
    public let description: String?
    /// `$deprecated`, or else the closest group's in the token's file.
    public let deprecated: Deprecation?
    /// `$extensions` as written, other vendors' keys included.
    public let extensions: JSON?
    /// westron's keys of `$extensions`, read and checked against the other tokens.
    public let westron: WestronExtensions
    /// The file the token comes from.
    public let source: String

    public init(
        path: TokenPath, type: TokenType, value: TokenValue, aliasOf: TokenPath? = nil, description: String? = nil,
        deprecated: Deprecation? = nil, extensions: JSON? = nil, westron: WestronExtensions = WestronExtensions(),
        source: String
    ) {
        self.path = path
        self.type = type
        self.value = value
        self.aliasOf = aliasOf
        self.description = description
        self.deprecated = deprecated
        self.extensions = extensions
        self.westron = westron
        self.source = source
    }
}

extension TokenTree {
    /// Resolves every reference in the tree (Format, 7.2): chains are followed to a value; a reference to a missing
    /// token or to a group, a cycle, and a referenced token of another type than expected are errors.
    ///
    /// The type a reference expects: the referring token's type (`$type`, or its group's in the same file) for a
    /// whole-value reference, the sub-value's type inside a composite. A reference token with no type of its own
    /// takes the type of its target.
    ///
    /// Then westron's `$extensions` keys are checked against the resolved tokens: `dev.westron.spring` only on a
    /// transition, `dev.westron.contrast` only on a color and with color tokens of this tree as backgrounds,
    /// `dev.westron.apple.textStyle` only on typography.
    /// - Returns: every token, in tree order.
    /// - Throws: `TokenErrors`. A token that fails because a token it refers to failed is not reported again.
    public func resolve() throws -> [ResolvedToken] {
        let resolver = ReferenceResolver(self)
        var result: [ResolvedToken] = []
        for (path, token) in tokens {
            guard let resolved = resolver.resolve(path) else { continue }
            result.append(
                ResolvedToken(
                    path: path, type: resolved.value.type, value: resolved.value, aliasOf: resolved.aliasOf,
                    description: token.description, deprecated: token.deprecated, extensions: token.extensions,
                    westron: token.westron, source: token.source))
        }
        var errors = resolver.errors
        if errors.isEmpty {
            let types = Dictionary(uniqueKeysWithValues: result.map { ($0.path, $0.type) })
            for token in result {
                errors += Self.check(token, types: types)
            }
        }
        guard errors.isEmpty else { throw TokenErrors(errors) }
        return result
    }

    /// The problems of a token's westron keys that depend on its type and on the other tokens.
    private static func check(_ token: ResolvedToken, types: [TokenPath: TokenType]) -> [TokenError] {
        var problems: [(TokenError.Kind, String)] = []
        let westron = token.westron
        if westron.spring != nil, token.type != .transition {
            problems.append(
                (.typeMismatch, "$extensions.dev.westron.spring is only for transition tokens, this is a \(token.type)")
            )
        }
        if westron.apple?.textStyle != nil, token.type != .typography {
            problems.append(
                (
                    .typeMismatch,
                    "$extensions.dev.westron.apple.textStyle is only for typography tokens, this is a \(token.type)"
                ))
        }
        if !westron.contrast.isEmpty, token.type != .color {
            problems.append(
                (.typeMismatch, "$extensions.dev.westron.contrast is only for color tokens, this is a \(token.type)"))
        }
        for (index, entry) in westron.contrast.enumerated() where token.type == .color {
            for (backgroundIndex, stack) in entry.on.enumerated() {
                for (layerIndex, path) in stack.enumerated() {
                    let location =
                        "$extensions.dev.westron.contrast[\(index)].on[\(backgroundIndex)]"
                        + (stack.count > 1 ? "[\(layerIndex)]" : "")
                    switch types[path] {
                    case .color?: break
                    case let other?:
                        problems.append((.typeMismatch, "\(location): \(path) is a \(other) token, not a color"))
                    case nil:
                        problems.append(
                            (.unknownReference, "\(location): \(path) does not exist (a background is a whole path)"))
                    }
                }
            }
        }
        return problems.map { TokenError($0.0, source: token.source, path: token.path, $0.1) }
    }
}

/// Resolution with memoization: each token is resolved once, depth first; the stack of tokens being resolved finds
/// cycles.
private final class ReferenceResolver {
    struct Resolved {
        let value: TokenValue
        let aliasOf: TokenPath?
    }

    let tokens: [TokenPath: Token]
    let groups: Set<TokenPath>
    var done: [TokenPath: Resolved] = [:]
    var failed: Set<TokenPath> = []
    var stack: [TokenPath] = []
    var errors: [TokenError] = []

    init(_ tree: TokenTree) {
        var tokens: [TokenPath: Token] = [:]
        var groups: Set<TokenPath> = []
        func walk(_ group: TokenGroup, _ path: TokenPath) {
            groups.insert(path)
            for child in group.children {
                switch child.node {
                case .token(let token): tokens[path.appending(child.name)] = token
                case .group(let group): walk(group, path.appending(child.name))
                }
            }
        }
        walk(tree.root, .root)
        self.tokens = tokens
        self.groups = groups
    }

    /// The resolved value of a token, or nil if it failed (the reason is in `errors`, once).
    func resolve(_ path: TokenPath) -> Resolved? {
        if let resolved = done[path] { return resolved }
        if failed.contains(path) { return nil }
        guard let token = tokens[path] else { return nil }
        if let start = stack.firstIndex(of: path) {
            // Reported once, at the token where the cycle was entered; every token in it fails.
            let cycle = stack[start...] + [path]
            report(
                .circularReference, at: stack[start],
                "circular reference: " + cycle.map { "{\($0)}" }.joined(separator: " → "))
            failed.formUnion(stack[start...])
            return nil
        }
        stack.append(path)
        defer { stack.removeLast() }

        let resolved: Resolved?
        switch token.value {
        case .reference(let target):
            resolved = alias(path, token, target)
        case .literal(let json):
            resolved = literal(path, token, json)
        }
        if let resolved {
            done[path] = resolved
        } else {
            failed.insert(path)
        }
        return resolved
    }

    private func alias(_ path: TokenPath, _ token: Token, _ target: TokenPath) -> Resolved? {
        do {
            let value = try referencedValue(target, expected: token.type, at: "$value")
            return Resolved(value: value, aliasOf: target)
        } catch {
            report(error, at: path)
            return nil
        }
    }

    private func literal(_ path: TokenPath, _ token: Token, _ json: JSON) -> Resolved? {
        guard let type = token.type else {
            report(.missingType, at: path, "the token has no $type")
            return nil
        }
        let decoder = ValueDecoder { reference, expected, location in
            try self.referencedValue(reference, expected: expected, at: location)
        }
        do {
            return Resolved(value: try decoder.decode(json, as: type), aliasOf: nil)
        } catch {
            report(error, at: path)
            return nil
        }
    }

    /// The value of the token a reference points to, checked against the expected type if there is one.
    private func referencedValue(_ target: TokenPath, expected: TokenType?, at location: String) throws -> TokenValue {
        guard tokens[target] != nil else {
            if groups.contains(target) {
                throw ValueFailure(.unknownReference, "\(location): {\(target)} is a group, not a token")
            }
            let names = target.names
            if let token = (1..<max(names.count, 1)).lazy.map({ TokenPath(Array(names.prefix($0))) })
                .first(where: { self.tokens[$0] != nil })
            {
                throw ValueFailure(
                    .unknownReference,
                    "\(location): {\(target)} points inside the token {\(token)}; a reference names a whole token")
            }
            throw ValueFailure(.unknownReference, "\(location): {\(target)} does not exist")
        }
        guard let resolved = resolve(target) else { throw ValueFailure(nil, "") }
        let type = resolved.value.type
        if let expected, type != expected {
            throw ValueFailure(
                .typeMismatch, "\(location): {\(target)} is a \(type.rawValue) token, expected \(expected.rawValue)")
        }
        return resolved.value
    }

    private func report(_ error: any Error, at path: TokenPath) {
        guard let failure = error as? ValueFailure else {
            report(.invalidValue, at: path, "\(error)")
            return
        }
        guard let kind = failure.kind else { return }
        report(kind, at: path, failure.message)
    }

    private func report(_ kind: TokenError.Kind, at path: TokenPath, _ message: String) {
        errors.append(TokenError(kind, source: tokens[path]?.source ?? "", path: path, message))
    }
}
