import Foundation
import Yams

/// westron's icon registry, `spec/icons/icons.yaml` (decisions/0011): every icon's name, what its glyph draws and its
/// SF Symbol, in order, and the icon drawn for a name the registry does not know.
///
/// The reader is strict: an unknown key, a missing or empty value, a name that is not a lowerCamelCase Swift identifier
/// or that repeats, a symbol that is not an SF Symbol name or that another icon already draws, and a `default` that
/// names no icon are all errors, and every one is reported. `tools/westron icons check` runs it.
public struct IconRegistry: Equatable, Sendable {
    public struct Icon: Equatable, Sendable {
        /// The westron name, which products store: `newWindow`. It is also the Swift case and its raw value.
        public let name: String
        /// One line on what the glyph draws.
        public let description: String
        /// The SF Symbol: `macwindow.badge.plus`.
        public let apple: String

        public init(name: String, description: String, apple: String) {
            self.name = name
            self.description = description
            self.apple = apple
        }
    }

    /// The registry, relative to the repository root.
    public static let defaultFile = "spec/icons/icons.yaml"

    /// In the registry's order.
    public let icons: [Icon]
    /// The name of the icon drawn for a name the registry does not know (`default` in the file).
    public let fallback: String

    public init(icons: [Icon], fallback: String) {
        self.icons = icons
        self.fallback = fallback
    }

    /// A problem in the registry: the file, the line when it is known, and what is wrong.
    public struct Problem: Error, Equatable, Sendable, CustomStringConvertible {
        public let source: String
        public let line: Int?
        public let message: String

        public init(source: String, line: Int?, _ message: String) {
            self.source = source
            self.line = line
            self.message = message
        }

        /// `spec/icons/icons.yaml:12: message`.
        public var description: String { "\(source)\(line.map { ":\($0)" } ?? ""): \(message)" }
    }

    /// Every problem found in the registry, in the order of the file.
    public struct Problems: Error, Equatable, Sendable, CustomStringConvertible {
        public let problems: [Problem]

        public init(_ problems: [Problem]) {
            self.problems = problems
        }

        public var description: String { problems.map(\.description).joined(separator: "\n") }
    }

    /// Reads the registry at a path relative to the working directory.
    /// - Throws: `Problems`.
    public static func load(file: String) throws -> IconRegistry {
        let text: String
        do {
            text = try String(contentsOfFile: file, encoding: .utf8)
        } catch {
            throw Problems([Problem(source: file, line: nil, "cannot be read as UTF-8 text")])
        }
        return try IconRegistry(yaml: text, source: file)
    }

    /// Reads a registry from its text; `source` names it in the problems.
    /// - Throws: `Problems` with every problem found.
    public init(yaml: String, source: String) throws {
        var reader = Reader(source: source)
        let root: Node?
        do {
            root = try Yams.compose(yaml: yaml)
        } catch let error as YamlError {
            throw Problems([reader.problem(error)])
        }
        guard let registry = reader.registry(root), reader.problems.isEmpty else {
            // In the order of the file; a problem of the file as a whole first.
            let sorted = reader.problems.enumerated().sorted {
                ($0.element.line ?? 0, $0.offset) < ($1.element.line ?? 0, $1.offset)
            }
            throw Problems(sorted.map(\.element))
        }
        self = registry
    }

    /// The key words of the file.
    static let topKeys = ["default", "icons"]
    static let iconKeys = ["name", "description", "apple"]

    /// Whether a name is a lowerCamelCase Swift identifier: an ASCII lowercase letter, then ASCII letters and digits.
    static func isIdentifier(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first, ("a"..."z").contains(first) else { return false }
        return name.unicodeScalars.allSatisfy {
            ("a"..."z").contains($0) || ("A"..."Z").contains($0) || ("0"..."9").contains($0)
        }
    }

    /// Whether a name has the form of an SF Symbol's: lowercase ASCII words and digits joined by dots, as every symbol
    /// in SF Symbols 7 is (`rectangle.split.1x2`). Whether the symbol exists is checked on Apple, by the root
    /// package's tests.
    static func isSymbolName(_ name: String) -> Bool {
        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        return parts.allSatisfy { part in
            !part.isEmpty && part.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) }
        }
    }
}

extension IconRegistry {
    /// Walks the YAML tree and collects every problem.
    private struct Reader {
        let source: String
        var problems: [Problem] = []

        init(source: String) {
            self.source = source
        }

        mutating func report(_ node: Node?, _ message: String) {
            problems.append(Problem(source: source, line: node?.mark?.line, message))
        }

        func problem(_ error: YamlError) -> Problem {
            switch error {
            case .scanner(let context, let problem, let mark, _), .parser(let context, let problem, let mark, _),
                .composer(let context, let problem, let mark, _):
                let text = [context?.text, problem].compactMap { $0 }.joined(separator: ": ")
                return Problem(source: source, line: mark.line, "invalid YAML: \(text)")
            case .duplicatedKeysInMapping(let duplicates, let context):
                let keys = duplicates.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
                return Problem(source: source, line: context.mark.line, "a mapping repeats the key \(keys)")
            default:
                return Problem(source: source, line: nil, "invalid YAML: \(error)")
            }
        }

        /// The value of a key that holds text: a non-empty string scalar. A plain `true`, `12` or `null` is not one.
        mutating func string(_ node: Node, _ what: String) -> String? {
            guard case .scalar(let scalar) = node, node.tag.rawValue == Tag.Name.str.rawValue else {
                report(node, "\(what) must be a string; quote it if YAML reads it as another type")
                return nil
            }
            guard !scalar.string.trimmingCharacters(in: .whitespaces).isEmpty else {
                report(node, "\(what) is empty")
                return nil
            }
            return scalar.string
        }

        /// The values of a mapping's known keys, by key; an unknown key, a key that is not a string and a missing key
        /// are reported.
        mutating func fields(_ mapping: Node.Mapping, of node: Node, keys: [String], in what: String) -> [String: Node]
        {
            var fields: [String: Node] = [:]
            for (key, value) in mapping {
                guard case .scalar(let scalar) = key, keys.contains(scalar.string) else {
                    let name = key.scalar?.string ?? "\(key)"
                    report(key, "\(what): unknown key \"\(name)\"; the keys are \(keys.joined(separator: ", "))")
                    continue
                }
                fields[scalar.string] = value
            }
            for key in keys where fields[key] == nil {
                report(node, "\(what): \(key) is missing")
            }
            return fields
        }

        mutating func registry(_ root: Node?) -> IconRegistry? {
            guard let root, case .mapping(let mapping) = root else {
                report(
                    root, "the registry must be a mapping with the keys \(IconRegistry.topKeys.joined(separator: ", "))"
                )
                return nil
            }
            let fields = fields(mapping, of: root, keys: IconRegistry.topKeys, in: "the registry")
            let fallback = fields["default"].flatMap { string($0, "default") }
            var icons: [Icon] = []
            if let list = fields["icons"] {
                if case .sequence(let sequence) = list, !sequence.isEmpty {
                    icons = self.icons(sequence)
                } else {
                    report(list, "icons must be a non-empty list")
                }
            }
            if let fallback, let node = fields["default"], !icons.isEmpty,
                !icons.contains(where: { $0.name == fallback })
            {
                report(node, "default names \"\(fallback)\", which is no icon of the registry")
            }
            guard let fallback else { return nil }
            return IconRegistry(icons: icons, fallback: fallback)
        }

        mutating func icons(_ sequence: Node.Sequence) -> [Icon] {
            var icons: [Icon] = []
            var names: [String: Int] = [:]
            var symbols: [String: String] = [:]
            for (index, node) in sequence.enumerated() {
                guard case .mapping(let mapping) = node else {
                    report(
                        node,
                        "icon \(index + 1): must be a mapping with the keys \(IconRegistry.iconKeys.joined(separator: ", "))"
                    )
                    continue
                }
                let label = mapping["name"]?.scalar.map { "icon \"\($0.string)\"" } ?? "icon \(index + 1)"
                let fields = fields(mapping, of: node, keys: IconRegistry.iconKeys, in: label)
                let name = fields["name"].flatMap { string($0, "\(label): name") }
                let description = fields["description"].flatMap { string($0, "\(label): description") }
                let apple = fields["apple"].flatMap { string($0, "\(label): apple") }

                if let name, let node = fields["name"] {
                    if !IconRegistry.isIdentifier(name) {
                        report(
                            node,
                            "\(label): the name must be a lowerCamelCase Swift identifier (ASCII letters and digits, a lowercase letter first)"
                        )
                    } else if SwiftName.keywords.contains(name) || SwiftName.Reserved.icon.contains(name) {
                        report(node, "\(label): the name is a Swift keyword or a member of Westron.Icon")
                    } else if let first = names[name] {
                        report(node, "\(label): the name repeats icon \(first)")
                    } else {
                        names[name] = index + 1
                    }
                }
                if let description, let node = fields["description"], description.contains(where: \.isNewline) {
                    report(node, "\(label): the description must be one line")
                }
                if let apple, let node = fields["apple"] {
                    if !IconRegistry.isSymbolName(apple) {
                        report(
                            node,
                            "\(label): \"\(apple)\" is not an SF Symbol name (lowercase words and digits joined by dots)"
                        )
                    } else if let other = symbols[apple] {
                        report(node, "\(label): the symbol \(apple) is already drawn by icon \"\(other)\"")
                    } else if let name {
                        symbols[apple] = name
                    }
                }
                if let name, let description, let apple {
                    icons.append(Icon(name: name, description: description, apple: apple))
                }
            }
            return icons
        }
    }
}
