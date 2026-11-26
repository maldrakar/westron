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

    /// The text's sentences, each with its full stop: a sentence ends at ". " before anything but a lowercase letter.
    static func sentences(_ text: String) -> [String] {
        var out: [String] = []
        var current = ""
        var characters = text.makeIterator()
        var pending: Character? = characters.next()
        while let character = pending {
            pending = characters.next()
            current.append(character)
            if character == ".", pending == " " {
                let afterSpace = characters.next()
                if let afterSpace, !afterSpace.isLowercase {
                    out.append(current)
                    current = ""
                    pending = afterSpace
                } else {
                    current.append(" ")
                    pending = afterSpace
                }
            }
        }
        let last = current.trimmingCharacters(in: .whitespaces)
        if !last.isEmpty { out.append(last) }
        return out
    }

    /// What a sentence about westron's own testing and tooling names, in any case; a product agent has none of it.
    /// "The catalog" is westron's catalog app; WestronUI's "string catalog" is not.
    static let toolingMarks = ["snapshot matrix", "the matrix", "the catalog", "tools/"]
    /// A parenthesis that names a test or a tool of westron's, `(CatalogUITests/ChipBehaviorTests)`,
    /// `(TextFieldLineTests, #115)`: it goes, and the sentence around it stays. A test is a name that ends in `Tests`.
    private static let toolingAside = try! NSRegularExpression(
        pattern: #"\s?\([^()]*(?:[A-Z]\w*Tests\b|tools/)[^()]*\)"#)

    /// The prose without the asides and the sentences on westron's own testing and tooling: the snapshot matrix, the
    /// catalog app, the tools. A sentence whose clause after "; " is about them keeps its other clauses.
    static func withoutTooling(_ text: String) -> String {
        let text = toolingAside.stringByReplacingMatches(
            in: text, range: NSRange(location: 0, length: NSString(string: text).length), withTemplate: "")
        return sentences(text).compactMap { sentence in
            withoutClauses(sentence) { clause in
                let lowered = clause.lowercased()
                return toolingMarks.contains { lowered.contains($0) }
            }
        }.joined(separator: " ")
    }

    /// A sentence without its clauses that `drop` matches, the clauses split at "; " outside parentheses and code
    /// spans; nil when the first goes, since the others lean on it. A sentence the cut shortens ends as it did, or
    /// with a period where it had none, as a table cell's last sentence.
    static func withoutClauses(_ sentence: String, drop: (String) -> Bool) -> String? {
        var clauses: [String] = []
        var current = ""
        var depth = 0
        var code = false
        let characters = Array(sentence)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "`" { code.toggle() }
            if !code, character == "(" { depth += 1 }
            if !code, character == ")" { depth = max(0, depth - 1) }
            if !code, depth == 0, character == ";", index + 1 < characters.count, characters[index + 1] == " " {
                clauses.append(current)
                current = ""
                index += 2
                continue
            }
            current.append(character)
            index += 1
        }
        clauses.append(current)
        guard let first = clauses.first, !drop(first) else { return nil }
        let kept = clauses.filter { !drop($0) }
        guard kept.count < clauses.count else { return sentence }
        var out = kept.joined(separator: "; ").trimmingCharacters(in: .whitespaces)
        if let last = out.last, !".!?".contains(last) {
            let ending = sentence.trimmingCharacters(in: .whitespaces).last
            out.append(ending.map { ".!?".contains($0) } == true ? ending! : ".")
        }
        return out
    }

    /// The prepositions of a phrase that names a token binding, which a sentence reads as well without: "indented by
    /// container.indent", "drawn in ring.color".
    static let bindingPrepositions = ["by", "in", "at", "with", "from", "to"]

    /// The text without each phrase "<preposition> <name>", with or without backticks around the name: the fact stays
    /// and the name goes. A name the text holds otherwise is left for the caller.
    static func removingPhrases(naming name: String, in text: String) -> String {
        var out = text
        for preposition in bindingPrepositions {
            for written in [name, "`\(name)`"] {
                let phrase = " \(preposition) \(written)"
                var search = out.startIndex..<out.endIndex
                while let range = out.range(of: phrase, range: search) {
                    let after = range.upperBound == out.endIndex ? nil : out[range.upperBound]
                    // A longer name that starts with this one, `container.indentX`, is another binding.
                    if after.map({ $0.isLetter || $0.isNumber }) ?? false {
                        search = range.upperBound..<out.endIndex
                        continue
                    }
                    out.removeSubrange(range)
                    search = range.lowerBound..<out.endIndex
                }
            }
        }
        return out
    }

    /// Whether the text names `name` as a whole: not as part of a longer name, `container.gapX` or `xcontainer.gap`.
    static func names(_ text: String, _ name: String) -> Bool {
        var search = text.startIndex..<text.endIndex
        while let range = text.range(of: name, range: search) {
            let before = range.lowerBound == text.startIndex ? nil : text[text.index(before: range.lowerBound)]
            let after = range.upperBound == text.endIndex ? nil : text[range.upperBound]
            let part: (Character?) -> Bool = { $0.map { $0.isLetter || $0.isNumber || $0 == "." } ?? false }
            if !part(before), !(after.map { $0.isLetter || $0.isNumber } ?? false) { return true }
            search = range.upperBound..<text.endIndex
        }
        return false
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
    ///   - skippingCode: leave a link inside a code span, `` `[a](b)` ``, as it is.
    static func rewritingLinks(
        _ text: String, from source: String, to output: String, map: [String: String], skippingCode: Bool = false
    ) -> String {
        let ns = NSString(string: text)
        let code = skippingCode ? codeSpans(text) : []
        var result = ""
        var last = 0
        for match in link.matches(in: text, range: NSRange(location: 0, length: ns.length))
        where !code.contains(where: { NSLocationInRange(match.range.location, $0) }) {
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            last = match.range.location + match.range.length
            let whole = ns.substring(with: match.range)
            let label = ns.substring(with: match.range(at: 1))
            let target = ns.substring(with: match.range(at: 2))
            if target.contains("://") || target.hasPrefix("mailto:") || target.hasPrefix("#") {
                result += whole
            } else if let rewritten = rewrittenTarget(target, from: source, to: output, map: map) {
                result += "[\(label)](\(rewritten))"
            } else {
                result += label
            }
        }
        result += ns.substring(from: last)
        return result
    }

    /// A relative target as the bundle writes it, relative to `output` with its anchor kept, when the bundle holds the
    /// file; nil for any other file of the repository.
    static func rewrittenTarget(_ target: String, from source: String, to output: String, map: [String: String])
        -> String?
    {
        let parts = target.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        guard let resolved = resolve(String(parts[0]), from: directory(of: source)), let mapped = map[resolved]
        else { return nil }
        return relative(mapped, from: directory(of: output)) + (parts.count > 1 ? "#" + parts[1] : "")
    }

    /// A code span, `` `a` `` or ``` `` a ` b `` ```, inside one paragraph.
    private static let codeSpan = try! NSRegularExpression(pattern: #"(`+)(?:[^\n]|\n(?!\n))*?\1"#)

    /// The ranges of a text's code spans.
    static func codeSpans(_ text: String) -> [NSRange] {
        codeSpan.matches(in: text, range: NSRange(location: 0, length: NSString(string: text).length)).map(\.range)
    }

    /// A link reference definition, `[label]: target "title"`, on a line of its own.
    private static let definition = try! NSRegularExpression(pattern: #"^ {0,3}\[([^\]]+)\]:[ \t]*(\S+)(.*)$"#)
    /// A full or collapsed reference link, `[text][label]` or `[label][]`.
    private static let referenceLink = try! NSRegularExpression(pattern: #"\[([^\]]*)\]\[([^\]]*)\]"#)

    /// `rewritingLinks` on the text outside its fenced code blocks and code spans, which it leaves as they are: in
    /// Swift, `[Choice](…)` is no link. A reference definition, `[ch]: ../design-language/06-layout.md`, follows the
    /// same rule: its target is rewritten where the bundle holds the file; otherwise the definition goes, and each
    /// full or collapsed link to it, `[the chapter][ch]`, becomes its text.
    static func rewritingLinksOutsideCode(
        _ text: String, from source: String, to output: String, map: [String: String]
    ) -> String {
        // The lines outside fenced blocks, with the reference definitions rewritten or dropped.
        var lines: [(text: String, fenced: Bool)] = []
        var dropped: Set<String> = []
        var fence: String?
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            let trimmed = line.drop { $0 == " " }
            if let open = fence {
                lines.append((line, true))
                if trimmed.hasPrefix(open), trimmed.allSatisfy({ $0 == open.first }) { fence = nil }
                continue
            }
            if let mark = ["```", "~~~"].first(where: { trimmed.hasPrefix($0) }) {
                lines.append((line, true))
                fence = String(trimmed.prefix { $0 == mark.first })
                continue
            }
            let ns = NSString(string: line)
            guard let match = definition.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else {
                lines.append((line, false))
                continue
            }
            let label = ns.substring(with: match.range(at: 1))
            let target = ns.substring(with: match.range(at: 2))
            if target.contains("://") || target.hasPrefix("mailto:") || target.hasPrefix("#") {
                lines.append((line, true))
            } else if let rewritten = rewrittenTarget(target, from: source, to: output, map: map) {
                lines.append(("[\(label)]: \(rewritten)" + ns.substring(with: match.range(at: 3)), true))
            } else {
                dropped.insert(label.lowercased())
            }
        }
        var out: [String] = []
        var prose: [String] = []
        func flush() {
            guard !prose.isEmpty else { return }
            let chunk = rewritingLinks(
                prose.joined(separator: "\n"), from: source, to: output, map: map, skippingCode: true)
            out.append(withoutReferences(chunk, to: dropped))
            prose = []
        }
        for line in lines {
            if line.fenced {
                flush()
                out.append(line.text)
            } else {
                prose.append(line.text)
            }
        }
        flush()
        return out.joined(separator: "\n")
    }

    /// The text with each full or collapsed reference link to one of `labels`, outside code spans, made its text.
    static func withoutReferences(_ text: String, to labels: Set<String>) -> String {
        guard !labels.isEmpty else { return text }
        let ns = NSString(string: text)
        let code = codeSpans(text)
        var result = ""
        var last = 0
        for match in referenceLink.matches(in: text, range: NSRange(location: 0, length: ns.length))
        where !code.contains(where: { NSLocationInRange(match.range.location, $0) }) {
            let words = ns.substring(with: match.range(at: 1))
            let label = ns.substring(with: match.range(at: 2))
            guard labels.contains((label.isEmpty ? words : label).lowercased()) else { continue }
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last)) + words
            last = match.range.location + match.range.length
        }
        return result + ns.substring(from: last)
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
