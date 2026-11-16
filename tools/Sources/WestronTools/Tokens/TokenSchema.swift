import Foundation
import JSONSchema

/// Validation of token files and resolver files against the official DTCG 2025.10 JSON Schemas, vendored in
/// `tools/Schemas/dtcg-2025.10/` (its README says where from), with swift-json-schema.
///
/// The fit, checked against the DTCG test suite in `TokenSchemaTests` and `ResolverTests`:
/// - The DTCG schemas are draft-07; swift-json-schema 0.15 implements draft 2020-12 only and reads them as 2020-12.
/// - The single-file bundle on designtokens.org cannot be used: it embeds the schemas under `definitions`, where
///   2020-12 does not look for `$id`, so no reference in it resolves and every file fails. The split source files
///   work: each is registered under its `$id`.
/// - One draft-07 keyword is lost: tuple `items` (an array of schemas). So the schema does not check the range of
///   each color component or cubic Bézier coordinate, nor that they are numbers. `TokenTree.load` checks both.
/// - `format` is only an annotation in 2020-12, so the JSON Pointer syntax of `$ref` is not checked. westron rejects
///   every `$ref` in token files anyway, and `ResolverDocument` checks the references of a resolver file itself.
public struct TokenSchema: Sendable {
    /// Where the schemas are, relative to the repository root.
    public static let defaultDirectory = "tools/Schemas/dtcg-2025.10"
    /// The root schema for token files.
    public static let formatID = "https://www.designtokens.org/schemas/2025.10/format.json"
    /// The root schema for resolver files.
    public static let resolverID = "https://www.designtokens.org/schemas/2025.10/resolver.json"

    /// A place where a document fails the schema.
    public struct Violation: Equatable, Sendable, CustomStringConvertible {
        /// A JSON Pointer into the document, such as `/color/bg/$value/unit`; empty for the root.
        public let instanceLocation: String
        public let message: String

        public var description: String {
            "\(instanceLocation.isEmpty ? "(root)" : instanceLocation): \(message)"
        }
    }

    public struct LoadError: Error, CustomStringConvertible {
        public let description: String
    }

    private let schema: Schema
    private let rootID: String

    /// Loads every `*.json` schema under a directory, registered by its `$id`, and validates against the one with
    /// `rootID`: the format schema for token files, the resolver schema for resolver files.
    public init(directory: String = Self.defaultDirectory, rootID: String = Self.formatID) throws {
        self.rootID = rootID
        var schemas: [String: JSONValue] = [:]
        let files: [URL]
        do {
            files = try Self.jsonFiles(in: URL(fileURLWithPath: directory))
        } catch {
            throw LoadError(
                description: "\(directory): cannot read the schema directory (run from the repository root)")
        }
        for file in files {
            let value: JSONValue
            do {
                value = try JSONValue.parse(Data(contentsOf: file))
            } catch {
                throw LoadError(description: "\(file.path): not a JSON schema: \(error)")
            }
            guard let id = value.object?["$id"]?.string else {
                throw LoadError(description: "\(file.path): the schema has no $id")
            }
            schemas[id] = value
        }
        guard let root = schemas[rootID], let baseURI = URL(string: rootID) else {
            throw LoadError(description: "\(directory): no schema with $id \(rootID)")
        }
        schema = try Schema(
            rawSchema: root, context: Context(dialect: .draft2020_12, remoteSchema: schemas), baseURI: baseURI)
    }

    /// Validates one file. Returns nothing when it passes.
    ///
    /// Of the nested errors a failing `oneOf` produces, only the deepest ones are kept: they point at the actual
    /// value, the shallower ones at the alternatives it did not match.
    /// - Throws: if the file is not JSON.
    public func validate(_ data: Data) throws -> [Violation] {
        let result = schema.validate(try JSONValue.parse(data), at: JSONPointer())
        guard !result.isValid else { return [] }
        var leaves: [Violation] = []
        func collect(_ errors: [ValidationError]) {
            for error in errors {
                if let nested = error.errors, !nested.isEmpty {
                    collect(nested)
                } else {
                    // A `false` schema (such as `additionalProperties: false`) fails with an empty message.
                    let message = error.message.isEmpty ? "not allowed here (\(error.keyword))" : error.message
                    leaves.append(
                        Violation(instanceLocation: error.instanceLocation.jsonPointerString, message: message))
                }
            }
        }
        collect(result.evaluationErrors ?? [])
        collect(result.errors ?? [])
        let deepest = leaves.filter { leaf in
            !leaves.contains { other in
                other.instanceLocation.count > leaf.instanceLocation.count
                    && other.instanceLocation.hasPrefix(leaf.instanceLocation + "/")
            }
        }
        var seen: Set<String> = []
        let unique = deepest.filter { seen.insert($0.description).inserted }
        return unique.isEmpty
            ? [Violation(instanceLocation: "", message: "the file does not match the DTCG schema \(rootID)")] : unique
    }

    /// The `*.json` files under a directory, in a stable order.
    private static func jsonFiles(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted().flatMap { name -> [URL] in
            let url = directory.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            if isDirectory.boolValue { return try jsonFiles(in: url) }
            return name.hasSuffix(".json") ? [url] : []
        }
    }
}
