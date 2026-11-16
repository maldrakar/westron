import Foundation
import JSONSchema

/// The JSON Schema of component contracts, `spec/schema/component.schema.json` (draft 2020-12), with
/// swift-json-schema.
///
/// The schema has no `oneOf` or `anyOf`: alternatives are written with `if`/`then`/`else` and with a list of types,
/// so every error it reports points at the value that is wrong, and every one is kept.
public struct ContractSchema: Sendable {
    /// The schema, relative to the repository root.
    public static let defaultFile = "spec/schema/component.schema.json"

    public struct LoadError: Error, CustomStringConvertible {
        public let description: String
    }

    private let schema: Schema

    /// Loads the schema at a path relative to the working directory.
    public init(file: String = Self.defaultFile) throws {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: file))
        } catch {
            throw LoadError(description: "\(file): cannot read the contract schema (run from the repository root)")
        }
        let value: JSONValue
        do {
            value = try JSONValue.parse(data)
        } catch {
            throw LoadError(description: "\(file): not a JSON schema: \(error)")
        }
        // Local `$ref`s resolve only against a registered document, so the schema is registered under its own URI.
        let uri = URL(fileURLWithPath: file).absoluteURL
        schema = try Schema(
            rawSchema: value, context: Context(dialect: .draft2020_12, remoteSchema: [uri.absoluteString: value]),
            baseURI: uri)
    }

    /// Where a document fails the schema, in document order of the schema's evaluation, each place and message once.
    func validate(_ document: JSON) -> [(path: DocumentPath, message: String)] {
        guard let value = try? JSONValue.parse(document.text) else {
            return [(.root, "the document cannot be read as JSON")]
        }
        let result = schema.validate(value, at: JSONPointer())
        guard !result.isValid else { return [] }
        var leaves: [(path: DocumentPath, message: String)] = []
        var seen: Set<String> = []
        func collect(_ errors: [ValidationError]) {
            for error in errors {
                if let nested = error.errors, !nested.isEmpty {
                    collect(nested)
                    continue
                }
                let path = DocumentPath(pointer: error.instanceLocation.jsonPointerString, in: document)
                // A `false` schema fails with an empty message: an unknown key, or `base` where no base is allowed.
                let message =
                    error.message.isEmpty
                    ? (error.keywordLocation.jsonPointerString.hasSuffix("/additionalProperties")
                        ? "unknown key: the schema does not allow it here" : "is not allowed here")
                    : error.message.replacingOccurrences(of: "OrderedJSON.JSONType.", with: "")
                if seen.insert("\(path): \(message)").inserted { leaves.append((path, message)) }
            }
        }
        collect(result.evaluationErrors ?? [])
        collect(result.errors ?? [])
        return leaves.isEmpty ? [(.root, "the contract does not match \(Self.defaultFile)")] : leaves
    }
}
