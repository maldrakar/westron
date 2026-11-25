import Foundation
import Yams

/// A pattern, `spec/patterns/<id>.md` (decisions/0018): a composition of westron's components, the system's containers
/// and tokens for one job a person does on a screen, written as Markdown with YAML front matter.
///
/// The front matter is read strictly, as the icon registry is: every key below is required, an unknown key is an error,
/// the texts are non-empty strings and the lists are lists of strings. `PatternCheck` holds the rest.
public struct Pattern: Equatable, Sendable {
    /// The file's path, as it was read.
    public let source: String
    /// kebab-case, the job: `choice-list-sheet`; the file's name.
    public var id = ""
    /// The first heading's text.
    public var title = ""
    /// `proposed` or `approved`: only an approved pattern enters the agent context (decisions/0018, point 3).
    public var status = ""
    /// One line, for the bundle's index.
    public var summary = ""
    /// The product screens, as a contract's: `todo-app/lists-screen`.
    public var consumers: [String] = []
    /// Contract ids.
    public var components: [String] = []
    /// Token source names, `space.page.narrow`.
    public var tokens: [String] = []
    /// Names of the icon registry.
    public var icons: [String] = []
    /// The ids of the gaps it records, each an entry of its section "Gaps".
    public var gaps: [String] = []
    /// The Markdown after the front matter.
    public var body = ""
    /// The line of the file the body's first line is.
    public var bodyLine = 1
    /// The line of each key of the front matter.
    public var keyLines: [String: Int] = [:]

    public init(source: String) {
        self.source = source
    }

    /// The front matter's keys, in the order decisions/0018 lists them.
    public static let textKeys = ["id", "title", "status", "summary"]
    public static let listKeys = ["consumers", "components", "tokens", "icons", "gaps"]
    public static var keys: [String] { textKeys + listKeys }
    /// The lists that may be empty: a pattern may use no token or icon of its own and record no gap.
    static let emptyLists: Set<String> = ["tokens", "icons", "gaps"]

    public static let statuses = ["proposed", "approved"]
    public static let approved = "approved"
    public static let proposed = "proposed"
    public var isApproved: Bool { status == Self.approved }

    /// The front matter's opening and closing line.
    static let fence = "---"

    /// Reads a pattern's text; `source` names it in the problems. Nil when there is no front matter to read, with the
    /// problem; otherwise the pattern with what could be read, and a problem for each key that could not.
    public static func read(_ text: String, source: String) -> (pattern: Pattern?, problems: [PatternProblem]) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        func problem(_ line: Int?, _ message: String) -> PatternProblem {
            PatternProblem(source: source, line: line, message)
        }
        guard lines.first == fence, let close = lines.dropFirst().firstIndex(of: fence) else {
            return (
                nil,
                [
                    problem(
                        1,
                        "no front matter: a pattern starts with a line \"---\", the YAML of its keys ("
                            + keys.joined(separator: ", ") + ") and a line \"---\" (decisions/0018, point 2)")
                ]
            )
        }
        var pattern = Pattern(source: source)
        pattern.body = lines[(close + 1)...].joined(separator: "\n")
        pattern.bodyLine = close + 2
        // A line of the YAML is the file's line after the opening fence.
        let yaml = lines[1..<close].joined(separator: "\n")
        let root: Node?
        do {
            root = try Yams.compose(yaml: yaml)
        } catch let error as YamlError {
            return (nil, [yamlProblem(error, source: source)])
        } catch {
            return (nil, [problem(2, "the front matter is not valid YAML: \(error)")])
        }
        guard let root, case .mapping(let mapping) = root else {
            return (
                nil,
                [
                    problem(
                        root?.mark.map { $0.line + 1 } ?? 2,
                        "the front matter must be a mapping of the keys "
                            + keys.joined(separator: ", "))
                ]
            )
        }
        var problems: [PatternProblem] = []
        func line(_ node: Node) -> Int? { node.mark.map { $0.line + 1 } }
        var seen: Set<String> = []
        for (key, value) in mapping {
            guard case .scalar(let scalar) = key, keys.contains(scalar.string) else {
                problems.append(
                    problem(
                        line(key),
                        "the front matter: unknown key \"\(key.scalar?.string ?? "\(key)")\"; the keys are "
                            + keys.joined(separator: ", ")))
                continue
            }
            let name = scalar.string
            seen.insert(name)
            pattern.keyLines[name] = line(key)
            if textKeys.contains(name) {
                guard case .scalar(let text) = value, value.tag.rawValue == Tag.Name.str.rawValue else {
                    problems.append(
                        problem(line(value), "\(name) must be a string; quote it if YAML reads it as another type"))
                    continue
                }
                let trimmed = text.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    problems.append(problem(line(value), "\(name) is empty"))
                    continue
                }
                switch name {
                case "id": pattern.id = trimmed
                case "title": pattern.title = trimmed
                case "status": pattern.status = trimmed
                default: pattern.summary = trimmed
                }
            } else {
                guard case .sequence(let sequence) = value else {
                    problems.append(problem(line(value), "\(name) must be a list, such as [a, b], or [] for none"))
                    continue
                }
                var items: [String] = []
                for item in sequence {
                    guard case .scalar(let text) = item, item.tag.rawValue == Tag.Name.str.rawValue,
                        !text.string.isEmpty
                    else {
                        problems.append(problem(line(item), "\(name): every item must be a non-empty string"))
                        continue
                    }
                    items.append(text.string)
                }
                if items.isEmpty, sequence.isEmpty, !emptyLists.contains(name) {
                    problems.append(problem(line(value), "\(name) is empty: a pattern names at least one"))
                }
                switch name {
                case "consumers": pattern.consumers = items
                case "components": pattern.components = items
                case "tokens": pattern.tokens = items
                case "icons": pattern.icons = items
                default: pattern.gaps = items
                }
            }
        }
        for key in keys where !seen.contains(key) {
            problems.append(problem(2, "the front matter: \(key) is missing"))
        }
        return (pattern, problems)
    }

    static func yamlProblem(_ error: YamlError, source: String) -> PatternProblem {
        switch error {
        case .scanner(let context, let problem, let mark, _), .parser(let context, let problem, let mark, _),
            .composer(let context, let problem, let mark, _):
            let text = [context?.text, problem].compactMap { $0 }.joined(separator: ": ")
            return PatternProblem(source: source, line: mark.line + 1, "the front matter is not valid YAML: \(text)")
        case .duplicatedKeysInMapping(let duplicates, let context):
            let keys = duplicates.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
            return PatternProblem(
                source: source, line: context.mark.line + 1, "the front matter repeats the key \(keys)")
        default:
            return PatternProblem(source: source, line: 2, "the front matter is not valid YAML: \(error)")
        }
    }

    // MARK: - The body

    /// A line of the body outside its fenced code blocks, with its line in the file.
    struct Line {
        let text: String
        let line: Int
    }

    /// The body's lines outside fenced code blocks, and each fenced block with its info string, its lines and the
    /// file's line of its first line of code.
    var markdown: (prose: [Line], blocks: [(info: String, code: String, line: Int)]) {
        var prose: [Line] = []
        var blocks: [(info: String, code: String, line: Int)] = []
        var open: (fence: String, info: String, lines: [String], line: Int)?
        for (index, text) in body.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = bodyLine + index
            let trimmed = text.drop { $0 == " " }
            if var current = open {
                if trimmed.hasPrefix(current.fence), trimmed.allSatisfy({ $0 == current.fence.first }) {
                    blocks.append((current.info, current.lines.joined(separator: "\n"), current.line))
                    open = nil
                } else {
                    current.lines.append(String(text))
                    open = current
                }
                continue
            }
            if let fence = ["```", "~~~"].first(where: { trimmed.hasPrefix($0) }) {
                let run = String(trimmed.prefix { $0 == fence.first })
                let info = trimmed.dropFirst(run.count).trimmingCharacters(in: .whitespaces)
                open = (run, info, [], line + 1)
                continue
            }
            prose.append(Line(text: String(text), line: line))
        }
        return (prose, blocks)
    }

    /// The level-two headings, `## Rules`, in order, each with its line.
    var sections: [(title: String, line: Int)] {
        markdown.prose.filter { $0.text.hasPrefix("## ") }.map {
            (String($0.text.dropFirst(3)).trimmingCharacters(in: .whitespaces), $0.line)
        }
    }

    /// The lines of one section outside code, up to the next level-two heading.
    func lines(of section: String) -> [Line] {
        var out: [Line] = []
        var inside = false
        for line in markdown.prose {
            if line.text.hasPrefix("## ") {
                inside = line.text.dropFirst(3).trimmingCharacters(in: .whitespaces) == section
                continue
            }
            if inside { out.append(line) }
        }
        return out
    }

    /// The fenced blocks inside one section.
    func blocks(of section: String) -> [(info: String, code: String, line: Int)] {
        let headings = sections
        guard let start = headings.first(where: { $0.title == section })?.line else { return [] }
        let end = headings.first { $0.line > start }?.line ?? Int.max
        return markdown.blocks.filter { $0.line > start && $0.line < end }
    }

    /// The first level-one heading's text, `# A list of choices in a sheet`.
    var heading: (title: String, line: Int)? {
        markdown.prose.first { $0.text.hasPrefix("# ") }.map {
            (String($0.text.dropFirst(2)).trimmingCharacters(in: .whitespaces), $0.line)
        }
    }
}

/// A problem of a pattern: the file, the line when it is known, and what is wrong.
public struct PatternProblem: Error, Equatable, Sendable, CustomStringConvertible {
    public let source: String
    public let line: Int?
    public let message: String

    public init(source: String, line: Int?, _ message: String) {
        self.source = source
        self.line = line
        self.message = message
    }

    /// `spec/patterns/choice-list-sheet.md:12: message`.
    public var description: String { "\(source)\(line.map { ":\($0)" } ?? ""): \(message)" }
}
