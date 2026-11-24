import Foundation

/// The Markdown the agent context is written in (`AgentContext`): wrapped prose, list items, the generated-file
/// header, and the copies of westron's documents with their links rewritten for the bundle.
enum ContextMarkdown {
    /// The longest line of prose, as the repository's documents are wrapped.
    static let width = 120

    /// The first line of a generated Markdown file: an HTML comment, invisible when rendered, that says it is
    /// generated, from what and by which command.
    static func header(_ sources: [String]) -> [String] {
        let text =
            "<!-- Generated from \(list(sources)) by `tools/westron generate`. Do not edit: change the source and "
            + "generate again (decisions/0016). -->"
        return wrap(text)
    }

    /// `a`, `a and b`, `a, b and c`.
    static func list(_ items: [String], conjunction: String = "and") -> String {
        guard items.count > 1 else { return items.first ?? "" }
        return items.dropLast().joined(separator: ", ") + " \(conjunction) " + items.last!
    }

    /// `` `a` ``, or ``` `` `a` `` ``` for a text that holds a backtick, such as a Swift keyword as a name.
    static func code(_ text: String) -> String { text.contains("`") ? "`` \(text) ``" : "`\(text)`" }

    /// Words joined into lines of at most `width` characters, the first line starting with `first` and the others with
    /// `rest`. A code span is never broken, and a word that would start a line and so start a Markdown block there (a
    /// list item, a heading, a quote, a fence) stays on the line before, which may then run longer.
    static func wrap(_ text: String, width: Int = width, first: String = "", rest: String = "") -> [String] {
        var words: [String] = []
        var open = false
        for word in text.split(whereSeparator: { $0 == " " || $0 == "\n" }) {
            if open { words[words.count - 1] += " " + word } else { words.append(String(word)) }
            if word.filter({ $0 == "`" }).count % 2 == 1 { open.toggle() }
        }
        var lines: [String] = []
        var line = first
        var empty = true
        for word in words {
            if empty {
                line += word
                empty = false
            } else if line.count + 1 + word.count <= width || startsBlock(word) {
                line += " " + word
            } else {
                lines.append(line)
                line = rest + word
            }
        }
        if !empty { lines.append(line) }
        return lines
    }

    /// A word that starts a Markdown block when it starts a line, even inside a paragraph.
    static func startsBlock(_ word: String) -> Bool {
        ["-", "*", "+", ">", "|", "1.", "1)"].contains(word) || word.hasPrefix("```") || word.hasPrefix("~~~")
            || (!word.isEmpty && word.allSatisfy { $0 == "#" }) || (!word.isEmpty && word.allSatisfy { $0 == "=" })
    }

    /// A list item, its continuation lines indented under its text.
    static func item(_ text: String) -> [String] { wrap(text, first: "- ", rest: "  ") }

    /// The first sentence of a text, up to and with the first ". ", and the rest; the whole text when it has one
    /// sentence.
    static func firstSentence(_ text: String) -> (first: String, rest: String) {
        guard let end = text.range(of: ". ") else { return (text, "") }
        return (String(text[..<end.lowerBound]) + ".", String(text[end.upperBound...]))
    }

    // MARK: - Links

    /// A Markdown link, `[text](target)`, or an image, `![text](target)`.
    private static let link = try! NSRegularExpression(pattern: #"!?\[([^\]]*)\]\(([^)\s]+)\)"#)

    /// The text with its links made fit for the bundle: a link to another site or to a place in the same file stays;
    /// a link to a file of the repository that the bundle holds a copy or a card of (`map`, by the repository path of
    /// the source, the repository path of the file in the bundle) points to that file, relative to `output`; any
    /// other link to the repository becomes its text, since the bundle stands alone in a product's repository.
    /// - Parameters:
    ///   - source: the repository path of the file the text comes from, which its relative links start from.
    ///   - output: the repository path of the file the text goes to.
    static func rewritingLinks(_ text: String, from source: String, to output: String, map: [String: String])
        -> String
    {
        let ns = NSString(string: text)
        var result = ""
        var last = 0
        for match in link.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            last = match.range.location + match.range.length
            let whole = ns.substring(with: match.range)
            let label = ns.substring(with: match.range(at: 1))
            let target = ns.substring(with: match.range(at: 2))
            if target.contains("://") || target.hasPrefix("mailto:") || target.hasPrefix("#") {
                result += whole
                continue
            }
            let parts = target.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
            let resolved = resolve(String(parts[0]), from: directory(of: source))
            if let resolved, let mapped = map[resolved] {
                let anchor = parts.count > 1 ? "#" + parts[1] : ""
                result += "[\(label)](\(relative(mapped, from: directory(of: output)))\(anchor))"
            } else {
                result += label
            }
        }
        result += ns.substring(from: last)
        return result
    }

    /// The directory of a repository path, empty at the root.
    static func directory(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return "" }
        return String(path[..<slash])
    }

    /// A relative path resolved from a directory to a repository path, or nil when it leaves the repository.
    static func resolve(_ path: String, from directory: String) -> String? {
        var parts = directory.split(separator: "/").map(String.init)
        for part in path.split(separator: "/", omittingEmptySubsequences: true) {
            switch part {
            case ".": continue
            case "..":
                guard !parts.isEmpty else { return nil }
                parts.removeLast()
            default: parts.append(String(part))
            }
        }
        return parts.joined(separator: "/")
    }

    /// A repository path relative to a directory of the repository.
    static func relative(_ path: String, from directory: String) -> String {
        let target = path.split(separator: "/").map(String.init)
        let base = directory.split(separator: "/").map(String.init)
        var common = 0
        while common < base.count, common < target.count - 1, base[common] == target[common] { common += 1 }
        return (Array(repeating: "..", count: base.count - common) + target[common...]).joined(separator: "/")
    }
}
