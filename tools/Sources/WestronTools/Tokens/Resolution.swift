import Foundation

/// The tokens of one input: a context for every modifier (DTCG Resolver 2025.10, 6).
public struct ResolvedTokens: Equatable, Sendable {
    /// The input with a context for every modifier, the defaults filled in.
    public let input: [String: String]
    /// Every token, in tree order.
    public let tokens: [ResolvedToken]
    private let index: [TokenPath: Int]

    public init(input: [String: String], tokens: [ResolvedToken]) {
        self.input = input
        self.tokens = tokens
        self.index = Dictionary(tokens.enumerated().map { ($1.path, $0) }) { first, _ in first }
    }

    public subscript(path: TokenPath) -> ResolvedToken? {
        index[path].map { tokens[$0] }
    }
}

/// A resolver file with its token files loaded: it resolves any input into tokens (DTCG Resolver 2025.10).
///
/// Loading reads the resolver and each token file it uses once, and checks that no two modifiers set the same
/// token (decisions/0010), so the order of the modifiers never changes a result. Given a schema directory, it also
/// validates the resolver file and every token file against the official DTCG schemas.
public struct Resolution: Sendable {
    public let document: ResolverDocument
    private let trees: [ResolverDocument.Source: TokenTree]

    /// Loads a resolver file and the token files it uses.
    /// - Parameters:
    ///   - resolverFile: a path relative to the current directory, which for `tools/westron` is the repository root;
    ///     the token files are relative to the resolver's directory.
    ///   - schemaDirectory: the vendored DTCG schemas (`TokenSchema.defaultDirectory`); nil skips the schemas, the
    ///     reader's own checks always run.
    /// - Throws: `TokenErrors` with every problem of the resolver and the token files, or with every overlap of two
    ///   modifiers.
    public init(resolverFile: String, schemaDirectory: String? = nil) throws {
        try self.init(resolverFile: resolverFile, schemaDirectory: schemaDirectory) {
            try Data(contentsOf: URL(fileURLWithPath: $0))
        }
    }

    /// Loads a resolver file and the token files it uses, read by `read` from their paths.
    public init(resolverFile: String, schemaDirectory: String? = nil, read: (String) throws -> Data) throws {
        let resolverData: Data
        do {
            resolverData = try read(resolverFile)
        } catch {
            throw TokenErrors([
                TokenError(.resolver, source: resolverFile, path: .root, "cannot read the resolver file")
            ])
        }
        let document = try ResolverDocument.load(resolverData, source: resolverFile)
        let formatSchema = try schemaDirectory.map { try TokenSchema(directory: $0) }
        let resolverSchema = try schemaDirectory.map { try TokenSchema(directory: $0, rootID: TokenSchema.resolverID) }

        var errors: [TokenError] = []
        var trees: [ResolverDocument.Source: TokenTree] = [:]
        for source in document.sources {
            switch source {
            case .file(let path):
                guard let data = try? read(path) else {
                    errors.append(
                        TokenError(.resolver, source: resolverFile, path: .root, "cannot read \(path), which it uses"))
                    continue
                }
                do {
                    trees[source] = try TokenTree.load(data, source: path)
                } catch let fileErrors as TokenErrors {
                    // The reader's messages are more precise than the schema's for the same problems.
                    errors += fileErrors.errors
                    continue
                }
                if let formatSchema { errors += try Self.violations(formatSchema.validate(data), source: path) }
            case .inline(let pointer):
                do {
                    trees[source] = try TokenTree.load(
                        document.inlineTokens[pointer]!, source: source.name(resolver: resolverFile))
                } catch let inlineErrors as TokenErrors {
                    errors += inlineErrors.errors
                }
            }
        }
        if errors.isEmpty, let resolverSchema {
            // The resolver schema also checks inline tokens against the format schema.
            errors += try Self.violations(resolverSchema.validate(resolverData), source: resolverFile)
        }
        guard errors.isEmpty else { throw TokenErrors(errors) }
        let overlaps = Self.overlaps(document, trees)
        guard overlaps.isEmpty else { throw TokenErrors(overlaps) }
        self.document = document
        self.trees = trees
    }

    /// The modifiers, in resolution order; each input names a context of each (or takes its default).
    public var modifiers: [ResolverDocument.Modifier] { document.modifiers }

    /// The token files the resolver uses, in the order of first use.
    public var files: [String] {
        document.sources.compactMap {
            if case .file(let path) = $0 { path } else { nil }
        }
    }

    /// Every input: each combination of the modifiers' contexts, the first modifier varying slowest.
    public var inputs: [[String: String]] { document.allInputs }

    /// An input as `theme=dark, density=regular, platform=ios`, in the order of the modifiers.
    public func describe(_ input: [String: String]) -> String {
        document.describe(input)
    }

    /// The tokens of one input: the sources of the sets and of each modifier's context, merged in resolution order
    /// (`TokenTree.merge`), then resolved (`TokenTree.resolve`). A modifier the input does not name takes its default.
    /// - Throws: `TokenErrors` for an invalid input, a merge conflict, or a token that does not resolve.
    public func resolve(_ input: [String: String]) throws -> ResolvedTokens {
        let complete = try document.complete(input)
        let sources = try document.sources(for: complete)
        let merged = try TokenTree.merge(sources.map { trees[$0]! })
        return ResolvedTokens(input: complete, tokens: try merged.resolve())
    }

    /// The tokens of every input, in the order of `inputs`.
    /// - Throws: `TokenErrors` with every problem once. A problem found in some inputs only says in which.
    public func resolveAll() throws -> [ResolvedTokens] {
        var results: [ResolvedTokens] = []
        var problems: [(error: TokenError, inputs: [[String: String]])] = []
        var indexByDescription: [String: Int] = [:]
        let inputs = inputs
        for input in inputs {
            do {
                results.append(try resolve(input))
            } catch let errors as TokenErrors {
                for error in errors.errors {
                    if let index = indexByDescription[error.description] {
                        problems[index].inputs.append(input)
                    } else {
                        indexByDescription[error.description] = problems.count
                        problems.append((error, [input]))
                    }
                }
            }
        }
        guard problems.isEmpty else {
            throw TokenErrors(
                problems.map { problem in
                    guard problem.inputs.count < inputs.count else { return problem.error }
                    let error = problem.error
                    return TokenError(
                        error.kind, source: error.source, path: error.path,
                        "\(error.message) (in \(describe(found: problem.inputs)))")
                })
        }
        return results
    }

    /// The inputs a problem was found in, as briefly as is exact: `theme=dark` when it is every input with that
    /// context, otherwise a list.
    private func describe(found: [[String: String]]) -> String {
        let narrowed = modifiers.compactMap { modifier -> (String, [String])? in
            let contexts = modifier.contextNames.filter { context in found.contains { $0[modifier.name] == context } }
            return contexts.count < modifier.contexts.count ? (modifier.name, contexts) : nil
        }
        let product =
            narrowed.reduce(1) { $0 * $1.1.count }
            * modifiers.filter { modifier in !narrowed.contains { $0.0 == modifier.name } }
            .reduce(1) { $0 * $1.contexts.count }
        if product == found.count {
            return narrowed.map { "\($0.0)=\($0.1.joined(separator: " or "))" }.joined(separator: "; ")
        }
        let listed = found.prefix(3).map(describe).joined(separator: "; ")
        return found.count > 3 ? "\(listed); and \(found.count - 3) more" : listed
    }

    /// Token paths that two modifiers set (decisions/0010), one error each, in modifier order and then by path.
    private static func overlaps(
        _ document: ResolverDocument, _ trees: [ResolverDocument.Source: TokenTree]
    ) -> [TokenError] {
        struct Setter {
            let modifier: String
            let context: String
            let source: String
        }
        var first: [TokenPath: Setter] = [:]
        var errors: [TokenError] = []
        for modifier in document.modifiers {
            var own: [TokenPath: Setter] = [:]
            for context in modifier.contexts {
                for source in context.sources {
                    for (path, _) in trees[source]?.tokens ?? [] where own[path] == nil {
                        own[path] = Setter(
                            modifier: modifier.name, context: context.name,
                            source: source.name(resolver: document.source))
                    }
                }
            }
            for (path, setter) in own.sorted(by: { $0.key < $1.key }) {
                guard let earlier = first[path] else {
                    first[path] = setter
                    continue
                }
                errors.append(
                    TokenError(
                        .modifierOverlap, source: document.source, path: path,
                        "set by modifier \(earlier.modifier) (context \(earlier.context), \(earlier.source)) and by "
                            + "modifier \(setter.modifier) (context \(setter.context), \(setter.source)); two "
                            + "modifiers must not set the same token, or their order would matter (decisions/0010)"))
            }
        }
        return errors
    }

    private static func violations(_ violations: [TokenSchema.Violation], source: String) -> [TokenError] {
        violations.map {
            TokenError(.schema, source: source, path: TokenPath(pointer: $0.instanceLocation), "DTCG schema: \($0)")
        }
    }
}
