import Foundation
import Yams

/// A place in a contract: keys and list indices from the root, written `options.variant.values[1]`.
public struct DocumentPath: Hashable, Sendable, CustomStringConvertible {
    public enum Segment: Hashable, Sendable {
        case key(String)
        case index(Int)
    }

    public let segments: [Segment]

    public init(_ segments: [Segment] = []) {
        self.segments = segments
    }

    public static let root = DocumentPath()

    public func key(_ key: String) -> DocumentPath { DocumentPath(segments + [.key(key)]) }
    public func index(_ index: Int) -> DocumentPath { DocumentPath(segments + [.index(index)]) }

    /// `options.variant.values[1]`; `(root)` for the document itself.
    public var description: String {
        guard !segments.isEmpty else { return "(root)" }
        var text = ""
        for segment in segments {
            switch segment {
            case .key(let key): text += text.isEmpty ? key : ".\(key)"
            case .index(let index): text += "[\(index)]"
            }
        }
        return text
    }

    /// The place a JSON Pointer into `document` names: a reference token is a list index where the value it steps
    /// into is a list.
    init(pointer: String, in document: JSON) {
        var segments: [Segment] = []
        var value: JSON? = document
        let tokens = pointer.split(separator: "/", omittingEmptySubsequences: false).dropFirst()
            .map { $0.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~") }
        for token in tokens {
            if case .array(let elements) = value, let index = Int(token) {
                segments.append(.index(index))
                value = elements.indices.contains(index) ? elements[index] : nil
            } else {
                segments.append(.key(token))
                value = value?[token]
            }
        }
        self.segments = segments
    }
}

/// A problem in a contract: the file, the place in it, and what is wrong.
public struct ContractProblem: Error, Equatable, Sendable, CustomStringConvertible {
    public let source: String
    /// The place in the document, such as `options.variant.default`; `(root)` for the document, or `line 3` for a
    /// file that is not valid YAML.
    public let place: String
    public let message: String

    public init(source: String, place: String, _ message: String) {
        self.source = source
        self.place = place
        self.message = message
    }

    public init(source: String, path: DocumentPath, _ message: String) {
        self.init(source: source, place: path.description, message)
    }

    /// `spec/components/button/button.spec.yaml: options.variant.default: message`.
    public var description: String { "\(source): \(place): \(message)" }
}

/// Reading a contract's YAML into JSON, which the schema validates and the rules walk.
enum ContractYAML {
    /// The document as JSON. A scalar takes the type YAML gives it: `true` is a boolean, `12` a number, `null` null,
    /// anything else a string. A mapping key is taken as written. An empty file is null.
    /// - Throws: `ContractProblem` for text that is not valid YAML or a mapping that repeats a key.
    static func parse(_ text: String, source: String) throws(ContractProblem) -> JSON {
        let root: Node?
        do {
            root = try Yams.compose(yaml: text)
        } catch let error as YamlError {
            throw problem(error, source: source)
        } catch {
            throw ContractProblem(source: source, place: "(root)", "invalid YAML: \(error)")
        }
        return root.map(json) ?? .null
    }

    private static func json(_ node: Node) -> JSON {
        switch node {
        case .scalar:
            switch node.tag.rawValue {
            case Tag.Name.bool.rawValue: return node.bool.map(JSON.bool) ?? .string(node.string ?? "")
            case Tag.Name.int.rawValue: return node.int.map { .number(Double($0)) } ?? .string(node.string ?? "")
            case Tag.Name.float.rawValue: return node.float.map(JSON.number) ?? .string(node.string ?? "")
            case Tag.Name.null.rawValue: return .null
            default: return .string(node.string ?? "")
            }
        case .mapping(let mapping):
            return .object(mapping.map { JSON.Member($0.key.string ?? "\($0.key)", json($0.value)) })
        case .sequence(let sequence):
            return .array(sequence.map(json))
        case .alias(let alias):
            return .string(alias.anchor.rawValue)
        }
    }

    private static func problem(_ error: YamlError, source: String) -> ContractProblem {
        switch error {
        case .scanner(let context, let problem, let mark, _), .parser(let context, let problem, let mark, _),
            .composer(let context, let problem, let mark, _):
            let text = [context?.text, problem].compactMap { $0 }.joined(separator: ": ")
            return ContractProblem(source: source, place: "line \(mark.line)", "invalid YAML: \(text)")
        case .duplicatedKeysInMapping(let duplicates, let context):
            let keys = duplicates.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
            return ContractProblem(
                source: source, place: "line \(context.mark.line)", "a mapping repeats the key \(keys)")
        default:
            return ContractProblem(source: source, place: "(root)", "invalid YAML: \(error)")
        }
    }
}

extension JSON {
    /// The document as JSON text, for the schema validator.
    var text: String {
        switch self {
        case .null: return "null"
        case .bool(let value): return value ? "true" : "false"
        case .number(let value):
            if value == value.rounded(), abs(value) < 1e15 { return String(Int64(value)) }
            return value.isFinite ? String(value) : "null"
        case .string(let value): return Self.quoted(value)
        case .array(let elements): return "[" + elements.map(\.text).joined(separator: ",") + "]"
        case .object(let members):
            return "{" + members.map { Self.quoted($0.key) + ":" + $0.value.text }.joined(separator: ",") + "}"
        }
    }

    private static func quoted(_ string: String) -> String {
        var result = "\""
        for scalar in string.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case _ where scalar.value < 0x20:
                let hex = String(scalar.value, radix: 16)
                result += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result + "\""
    }
}
