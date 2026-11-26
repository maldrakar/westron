import Foundation

/// The patterns in the agent context (decisions/0018, point 5): each approved pattern copied to
/// `patterns/<id>.md`, its links rewritten as the chapters' are, a line per pattern in the index and in llms.txt, and a
/// line on each card of a component a pattern uses. A proposed pattern is checked but not copied: only an approved one
/// reaches agents (decisions/0018, point 3).
extension AgentContext {
    /// A pattern's path inside the bundle.
    static func patternPath(_ id: String) -> String { "patterns/\(id).md" }

    /// The repository path of a pattern read from any path, `spec/patterns/<file>`, which its header names and its
    /// relative links start from.
    static func patternSource(_ source: String) -> String { PatternCheck.defaultDirectory + "/" + fileName(source) }

    /// The approved patterns, after `patterns check` passes on every pattern, approved or not, against the cards'
    /// contracts, the token model, the icon registry and the API: no pattern is copied from a rejected one.
    /// - Throws: `PatternCheck.Problems`.
    static func checkedPatterns(_ sources: Sources, cards: [ComponentCard], names: ContextNames) throws -> [Pattern] {
        let references = PatternCheck.References(
            components: Set(cards.map(\.contract.id)),
            names: PatternNames(
                expected: cards.first?.expected ?? APIParity.Expected(), names: names,
                icons: Set(sources.icons.icons.map(\.name))))
        var patterns: [Pattern] = []
        var problems: [PatternProblem] = []
        for entry in sources.patterns {
            let result = PatternCheck.check(entry.text, source: patternSource(entry.source), references: references)
            problems += result.problems
            if let pattern = result.pattern { patterns.append(pattern) }
        }
        guard problems.isEmpty else { throw PatternCheck.Problems(problems: problems) }
        return patterns.filter(\.isApproved)
    }

    /// What the index and llms.txt say of the patterns before their lines.
    static let patternsIntro =
        "A pattern composes westron's components, the system's containers and tokens for one job on a screen: which "
        + "component takes which part, with which options, what stays the system's, what assistive technology hears, "
        + "and one complete SwiftUI example. It is rules and an example, not an API: its calls are the cards'. Read the "
        + "pattern for a job before composing its screen."

    /// The pattern's copy in the bundle: the generated header, then its Markdown without the front matter, a line of
    /// what the front matter says under its title, and its links fit for the bundle.
    static func pattern(_ pattern: Pattern, cards: [ComponentCard], map: [String: String]) -> String {
        let output = outputDirectory + "/" + patternPath(pattern.id)
        var out = ContextMarkdown.header([pattern.source])
        out += ContextMarkdown.wrap(
            "<!-- One of westron's patterns, copied without its front matter. Links to the rest of westron's repository "
                + "are left as their text, and a reference such as \"decisions/0014\", \"design-language/06\" or \"#171\" "
                + "points into westron's repository; the chapters are in `../design-language/`, the cards in "
                + "`../components/`. -->")
        let components = pattern.components.compactMap { id in cards.first { $0.contract.id == id } }.map {
            "[\($0.component)](../\(ComponentCard.path($0.contract.id)))"
        }
        var meta = ["`\(pattern.id)`", pattern.status]
        if !pattern.consumers.isEmpty { meta.append("used by " + pattern.consumers.joined(separator: ", ")) }
        if !components.isEmpty { meta.append("composes " + ContextMarkdown.list(components)) }
        let body = ContextMarkdown.rewritingLinksOutsideCode(
            pattern.body, from: pattern.source, to: output, map: map)
        var lines = body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        while lines.first?.trimmingCharacters(in: .whitespaces) == "" { lines.removeFirst() }
        while lines.last?.trimmingCharacters(in: .whitespaces) == "" { lines.removeLast() }
        if let title = lines.firstIndex(where: { $0.hasPrefix("# ") }) {
            lines.insert(contentsOf: [""] + ContextMarkdown.wrap(meta.joined(separator: " · ")), at: title + 1)
        }
        return (out + [""] + lines).joined(separator: "\n") + "\n"
    }

    /// The index's or llms.txt's lines of the patterns, each linked with `base` before its path.
    static func patternLines(_ patterns: [Pattern], base: String = "") -> [String] {
        patterns.map { "- [\($0.title)](\(base)\(patternPath($0.id))): \($0.summary)" }
    }
}
