import Foundation

/// `tools/westron patterns check`: each pattern, `spec/patterns/<id>.md` (decisions/0018), has its front matter, its
/// fixed sections in order and the references a check can hold. Every problem of every pattern is reported.
///
/// - The front matter: every key, `id` the file's name, `status` `proposed` or `approved`, `consumers` as a contract's;
///   the first heading is the `title`.
/// - Each id of `components` has a contract, each name of `tokens` is in the token model, each of `icons` in the icon
///   registry.
/// - The sections "When to use", "Parts", "Rules", "Accessibility", "Apple", "Not covered" and "Gaps", in this order,
///   and "Questions" last only while the pattern is proposed; "Apple" holds one Swift example. A section of a later
///   platform goes in `sections` after "Apple" and in `optionalSections`, so that a pattern may lack it.
/// - Each id of `gaps` has an entry in "Gaps", `- **G3** …`, and each entry is in `gaps`.
/// - The westron names every Swift block and the prose write are WestronUI's reviewed API (`PatternNames`).
public enum PatternCheck {
    /// The patterns' directory, relative to the repository root.
    public static let defaultDirectory = "spec/patterns"
    public static let fileSuffix = ".md"

    /// The sections a pattern may have, in their fixed order (decisions/0018, point 2). A later platform adds its
    /// section after "Apple", and to `optionalSections` until every pattern has it.
    public static let sections = ["When to use", "Parts", "Rules", "Accessibility", "Apple", "Not covered", "Gaps"]
    /// The sections of `sections` a pattern may leave out: a later platform's, while patterns gain it one by one.
    public static let optionalSections: Set<String> = []
    /// The sections every pattern has.
    public static var requiredSections: [String] { sections.filter { !optionalSections.contains($0) } }
    /// The section only a proposed pattern has, last.
    public static let questions = "Questions"
    /// The section that holds the one complete example in Swift.
    public static let appleSection = "Apple"
    public static let gapsSection = "Gaps"

    /// What a pattern's references are held to.
    struct References {
        /// The contracts' ids.
        let components: Set<String>
        let names: PatternNames
    }

    /// The patterns under a directory, `<directory>/*.md` but a README, sorted; none if it does not exist.
    public static func files(in directory: String) throws -> [String] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory), isDirectory.boolValue
        else { return [] }
        let prefix = directory.hasSuffix("/") ? directory : directory + "/"
        return try FileManager.default.contentsOfDirectory(atPath: directory).sorted()
            .filter { $0.hasSuffix(fileSuffix) && $0 != "README.md" }.map { prefix + $0 }
    }

    /// Every problem found in the patterns.
    public struct Problems: Error, CustomStringConvertible {
        public let problems: [PatternProblem]

        public var description: String {
            problems.map(\.description).joined(separator: "\n") + "\n(tools/westron patterns check, decisions/0018)"
        }
    }

    /// Checks pattern files against the repository's contracts, tokens, icon registry and API.
    /// - Throws: `AppleComponents.Problems` when a contract fails `spec check`, `TokenErrors` when the tokens do not
    ///   load, `IconRegistry.Problems` when the registry does not.
    public static func run(
        files: [String], contractsDirectory: String = ContractCheck.defaultDirectory,
        schemaFile: String = ContractSchema.defaultFile, resolverFile: String = TokenCheck.defaultResolver,
        iconsFile: String = IconRegistry.defaultFile
    ) throws -> [PatternProblem] {
        let references = try Self.references(
            contractsDirectory: contractsDirectory, schemaFile: schemaFile, resolverFile: resolverFile,
            iconsFile: iconsFile)
        return files.flatMap { file -> [PatternProblem] in
            guard let text = try? String(contentsOfFile: file, encoding: .utf8) else {
                return [PatternProblem(source: file, line: nil, "cannot be read as UTF-8 text")]
            }
            return check(text, source: file, references: references).problems
        }
    }

    /// The repository's references: the contracts that pass `spec check`, the API the parity lint derives from them,
    /// the token model and the icon registry.
    static func references(contractsDirectory: String, schemaFile: String, resolverFile: String, iconsFile: String)
        throws -> References
    {
        let checked = try AppleComponents.checkedContracts(
            directory: contractsDirectory, schemaFile: schemaFile, resolverFile: resolverFile)
        let contracts = try checked.contracts.map { entry in
            APIParity.Contract(
                contract: entry.contract, source: entry.source,
                text: try String(contentsOfFile: entry.source, encoding: .utf8))
        }
        let expected = APIParity.expected(contracts)
        let model = try AppleTokenModel(Resolution(resolverFile: resolverFile))
        let icons = try IconRegistry.load(file: iconsFile)
        return References(
            components: Set(contracts.map(\.contract.id)),
            names: PatternNames(
                expected: expected, names: ContextNames(model: model, functions: Set(expected.functions.map(\.name))),
                icons: Set(icons.icons.map(\.name))))
    }

    /// The pattern a text holds and every problem of it.
    static func check(_ text: String, source: String, references: References) -> (
        pattern: Pattern?, problems: [PatternProblem]
    ) {
        let (read, readProblems) = Pattern.read(text, source: source)
        guard let pattern = read else { return (nil, readProblems) }
        var problems = readProblems
        func report(_ line: Int?, _ message: String) {
            problems.append(PatternProblem(source: source, line: line, message))
        }
        func line(_ key: String) -> Int { pattern.keyLines[key] ?? 2 }

        // The front matter.
        let name = String((source.split(separator: "/").last ?? "").dropLast(fileSuffix.count))
        if !pattern.id.isEmpty {
            if pattern.id.range(of: #"^[a-z][a-z0-9]*(-[a-z0-9]+)*$"#, options: .regularExpression) == nil {
                report(line("id"), "id \"\(pattern.id)\" is not kebab-case, such as choice-list-sheet")
            }
            if pattern.id != name {
                report(line("id"), "id \"\(pattern.id)\" differs from the file's name, \(name)\(fileSuffix)")
            }
        }
        if !pattern.status.isEmpty, !Pattern.statuses.contains(pattern.status) {
            report(
                line("status"),
                "status \"\(pattern.status)\" is not \(Pattern.statuses.map { "\"\($0)\"" }.joined(separator: " or "))")
        }
        for consumer in pattern.consumers
        where consumer.range(of: #"^[a-z0-9]+(-[a-z0-9]+)*/[a-z0-9]+(-[a-z0-9]+)*$"#, options: .regularExpression)
            == nil
        {
            report(
                line("consumers"), "consumers: \"\(consumer)\" is not <product>/<screen>, such as todo-app/list-screen")
        }
        for id in pattern.components where !references.components.contains(id) {
            report(line("components"), "components: \"\(id)\" has no contract in \(ContractCheck.defaultDirectory)/")
        }
        for token in pattern.tokens where references.names.names.tokens[token] == nil {
            report(
                line("tokens"),
                "tokens: \"\(token)\" is not a token of the model; write its source name, such as space.page.narrow")
        }
        for icon in pattern.icons where !references.names.icons.contains(icon) {
            report(line("icons"), "icons: \"\(icon)\" is not a name of the icon registry (\(IconRegistry.defaultFile))")
        }

        // The title.
        if let heading = pattern.heading {
            if !pattern.title.isEmpty, heading.title != pattern.title {
                report(heading.line, "the first heading \"\(heading.title)\" is not the title \"\(pattern.title)\"")
            }
        } else {
            report(pattern.bodyLine, "no heading \"# \(pattern.title)\" after the front matter")
        }

        // The sections.
        let found = pattern.sections
        let allowed = sections + (pattern.status == Pattern.proposed ? [questions] : [])
        var seen: Set<String> = []
        for section in found {
            if !seen.insert(section.title).inserted {
                report(section.line, "the section \"\(section.title)\" comes twice")
            } else if section.title == questions, pattern.isApproved {
                report(
                    section.line, "an approved pattern has no section \"\(questions)\": it is only for a proposed one")
            } else if !allowed.contains(section.title) {
                report(
                    section.line,
                    "a section \"\(section.title)\" that a pattern does not have; its sections are "
                        + allowed.map { "\"\($0)\"" }.joined(separator: ", "))
            }
        }
        let missing = requiredSections.filter { !seen.contains($0) }
        for section in missing {
            report(
                nil,
                "no section \"## \(section)\"; every pattern has "
                    + requiredSections.map { "\"\($0)\"" }.joined(separator: ", "))
        }
        let order = found.map(\.title).filter { allowed.contains($0) }
        var unique: [String] = []
        for title in order where !unique.contains(title) { unique.append(title) }
        if unique != allowed.filter(unique.contains) {
            report(
                found.first?.line,
                "the sections are out of order: " + unique.map { "\"\($0)\"" }.joined(separator: ", ")
                    + "; the order is "
                    + allowed.map { "\"\($0)\"" }.joined(separator: ", "))
        }

        // The example.
        let examples = pattern.blocks(of: appleSection).filter { $0.info.split(separator: " ").first == "swift" }
        if seen.contains(appleSection), examples.count != 1 {
            report(
                found.first { $0.title == appleSection }?.line,
                "the section \"\(appleSection)\" holds \(examples.count) Swift examples; a pattern has one complete "
                    + "example, a fenced block ```swift")
        }
        // Every Swift block's names, the example's and any other's.
        for block in pattern.markdown.blocks where block.info.split(separator: " ").first == "swift" {
            let what = examples.contains { $0.line == block.line } ? "the example" : "a Swift block"
            for problem in references.names.problems(swift: block.code) {
                report(block.line + problem.line - 1, "\(what): " + problem.message)
            }
        }

        // The gaps.
        var entries: [(id: String, line: Int)] = []
        for line in pattern.lines(of: gapsSection) {
            if let match = line.text.range(of: #"^- \*\*[^*]+\*\*"#, options: .regularExpression) {
                entries.append((String(line.text[match].dropFirst(4).dropLast(2)), line.line))
            }
        }
        for gap in pattern.gaps where !entries.contains(where: { $0.id == gap }) {
            report(line("gaps"), "gaps: \"\(gap)\" has no entry \"- **\(gap)**\" in the section \"\(gapsSection)\"")
        }
        for entry in entries where !pattern.gaps.contains(entry.id) {
            report(entry.line, "the gap \"\(entry.id)\" is not in the front matter's gaps")
        }

        // The names the prose writes.
        for line in pattern.markdown.prose {
            for span in PatternNames.spans(line.text) {
                for message in references.names.problems(span: span) { report(line.line, message) }
            }
        }
        return (pattern, problems)
    }
}
