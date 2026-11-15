import Foundation
import Testing
import WestronTools

/// A file in `Fixtures/` of the test target.
func fixture(_ path: String) -> URL {
    Bundle.module.url(forResource: "Fixtures", withExtension: nil)!.appendingPathComponent(path)
}

func fixtureData(_ path: String) throws -> Data {
    try Data(contentsOf: fixture(path))
}

/// The repository root, for files outside the test target, such as the vendored DTCG schemas.
let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// The vendored DTCG schemas.
let schemaDirectory = repositoryRoot.appendingPathComponent(TokenSchema.defaultDirectory).path

func officialSchema() throws -> TokenSchema {
    try TokenSchema(directory: schemaDirectory)
}

/// A resolution of files written inline: the resolver at `r.resolver.json`, the token files by their paths.
func resolution(_ files: [String: String], schemas: Bool = false) throws -> Resolution {
    try Resolution(resolverFile: "r.resolver.json", schemaDirectory: schemas ? schemaDirectory : nil) { path in
        guard let text = files[path] else { throw MissingFile() }
        return Data(text.utf8)
    }
}

struct MissingFile: Error {}

/// The errors of loading an inline resolution and, if that passes, of resolving every input.
func resolutionProblems(_ files: [String: String], sourceLocation: SourceLocation = #_sourceLocation) -> [TokenError] {
    do {
        _ = try resolution(files).resolveAll()
        return []
    } catch let errors as TokenErrors {
        return errors.errors
    } catch {
        Issue.record("unexpected error: \(error)", sourceLocation: sourceLocation)
        return []
    }
}

/// A resolver document written inline around its `resolutionOrder` and definitions.
func resolver(_ body: String) -> String {
    #"{ "version": "2025.10", \#(body) }"#
}

/// Loads a token file written inline.
func load(_ json: String, source: String = "test.tokens.json") throws -> TokenTree {
    try TokenTree.load(Data(json.utf8), source: source)
}

/// Loads and resolves a token file written inline; tokens by path.
func resolve(_ json: String) throws -> [TokenPath: ResolvedToken] {
    Dictionary(uniqueKeysWithValues: try load(json).resolve().map { ($0.path, $0) })
}

/// The errors of loading a token file written inline and, if that passes, of resolving it.
func problems(_ json: String, sourceLocation: SourceLocation = #_sourceLocation) -> [TokenError] {
    do {
        _ = try load(json).resolve()
        return []
    } catch let errors as TokenErrors {
        return errors.errors
    } catch {
        Issue.record("unexpected error: \(error)", sourceLocation: sourceLocation)
        return []
    }
}

/// `kind path` of each error, for compact expectations.
func summary(_ errors: [TokenError]) -> [String] {
    errors.map { "\($0.kind.rawValue) \($0.path)" }
}

/// A token with a `$type` and a `$value`, as a JSON document with the token at `t`.
func token(_ type: String, _ value: String) -> String {
    #"{ "t": { "$type": "\#(type)", "$value": \#(value) } }"#
}

/// Shorthands for building expected values.
extension TokenValue.Color {
    static func srgb(_ r: Double, _ g: Double, _ b: Double, alpha: Double = 1) -> Self {
        Self(colorSpace: .srgb, components: [.number(r), .number(g), .number(b)], alpha: alpha)
    }
}

extension TokenValue.Dimension {
    static func px(_ value: Double) -> Self { Self(value, .px) }
}
