import Foundation

/// The context bundle for agents that write UI in a product that uses westron (#37, decisions/0016): from the
/// contracts, the tokens, the icon registry, `spec/conventions.md` and the design language it writes the `context/`
/// directory of the skill in westron's Claude Code plugin (`plugins/westron/`, listed by the repository's
/// `.claude-plugin/marketplace.json`), which the hand-written `SKILL.md` beside it points into, and `llms.txt` at the
/// root, for agents outside the Claude family.
///
/// - `index.md`: one line per component, token page, the icons, the SwiftUI page and chapter, with its file;
/// - `components/<id>.md`: one card per contract (`ComponentCard`), what a call needs; `components/<id>.details.md`:
///   the contract's prose on behavior, accessibility and Apple;
/// - `tokens/*.md`: the semantic tokens by kind (`ContextTokens`); `icons.md`: the icon registry;
/// - `swiftui.md`: how a contract's concepts become SwiftUI, from spec/conventions.md;
/// - `design-language/`: the chapters 00–09, copied, their links to the rest of the repository turned into text.
///
/// Paths inside the bundle are relative, so it works copied or linked into another repository. The bundle's directory
/// is owned: a file in it that the generator no longer writes is stale.
public struct AgentContext: Generator {
    public let name = "agent-context"
    public let contractsDirectory: String
    public let schemaFile: String
    public let resolverFile: String
    public let iconsFile: String
    public let conventionsFile: String
    public let designLanguageDirectory: String

    public init(
        contractsDirectory: String = ContractCheck.defaultDirectory, schemaFile: String = ContractSchema.defaultFile,
        resolverFile: String = TokenCheck.defaultResolver, iconsFile: String = IconRegistry.defaultFile,
        conventionsFile: String = AgentContext.conventionsFile,
        designLanguageDirectory: String = AgentContext.designLanguageDirectory
    ) {
        self.contractsDirectory = contractsDirectory
        self.schemaFile = schemaFile
        self.resolverFile = resolverFile
        self.iconsFile = iconsFile
        self.conventionsFile = conventionsFile
        self.designLanguageDirectory = designLanguageDirectory
    }

    /// The Claude Code plugin's root: an installed plugin is this directory copied, so the skill and its context live
    /// inside it.
    public static let pluginDirectory = "plugins/westron"
    /// The skill's directory, relative to the repository root; its `SKILL.md` is hand-written.
    public static let skillDirectory = pluginDirectory + "/skills/westron"
    /// The generated bundle.
    public static let outputDirectory = skillDirectory + "/context"
    public static let llmsFile = "llms.txt"
    public static let conventionsFile = "spec/conventions.md"
    public static let designLanguageDirectory = "design-language"

    public var ownedDirectories: [String] { [Self.outputDirectory] }

    /// The inputs, read.
    public struct Sources {
        /// Each contract's text and its repository path, sorted by path.
        public var contracts: [(text: String, source: String)]
        public var icons: IconRegistry
        public var conventions: String
        /// The chapters `NN-*.md`, each with its repository path, sorted.
        public var chapters: [(text: String, source: String)]
        /// The design language's README, whose table says what each chapter settles; nil without one.
        public var readme: String?

        public init(
            contracts: [(text: String, source: String)], icons: IconRegistry, conventions: String,
            chapters: [(text: String, source: String)], readme: String?
        ) {
            self.contracts = contracts
            self.icons = icons
            self.conventions = conventions
            self.chapters = chapters
            self.readme = readme
        }
    }

    public func run() throws -> [GeneratedFile] {
        // The contracts pass `spec check` first, as for the API generator: no card is written from a rejected one.
        let checked = try AppleComponents.checkedContracts(
            directory: contractsDirectory, schemaFile: schemaFile, resolverFile: resolverFile)
        let contracts = try checked.contracts.map { entry in
            (text: try String(contentsOfFile: entry.source, encoding: .utf8), source: entry.source)
        }
        let manager = FileManager.default
        let chapters = try manager.contentsOfDirectory(atPath: designLanguageDirectory).sorted()
            .filter { $0.hasSuffix(".md") && $0.prefix(2).allSatisfy(\.isNumber) }
            .map { name in
                let path = designLanguageDirectory + "/" + name
                return (text: try String(contentsOfFile: path, encoding: .utf8), source: path)
            }
        let readme = try? String(contentsOfFile: designLanguageDirectory + "/README.md", encoding: .utf8)
        let sources = Sources(
            contracts: contracts, icons: try IconRegistry.load(file: iconsFile),
            conventions: try String(contentsOfFile: conventionsFile, encoding: .utf8), chapters: chapters,
            readme: readme)
        return try Self.files(
            sources, tokens: try AppleTokenModel(Resolution(resolverFile: resolverFile)),
            conventionsSource: conventionsFile)
    }

    /// The bundle's files from read sources, in a fixed order.
    /// - Parameter conventionsSource: the repository path of spec/conventions.md, which the SwiftUI page names.
    static func files(_ sources: Sources, tokens: AppleTokenModel, conventionsSource: String = conventionsFile) throws
        -> [GeneratedFile]
    {
        let cards = try Self.cards(sources, textRoles: tokens.textRoles.map { AppleTokensSwift.reference($0.members) })
        let names = ContextNames(model: tokens, functions: Set(cards.first?.expected.functions.map(\.name) ?? []))
        let tokenPages = try ContextTokens.pages(tokens, names: names)
        var map: [String: String] = [:]
        for card in cards { map[card.source] = Self.outputDirectory + "/" + ComponentCard.path(card.contract.id) }
        for chapter in sources.chapters {
            map[chapter.source] = Self.outputDirectory + "/" + Self.chapterPath(chapter.source)
        }
        map[conventionsSource] = Self.outputDirectory + "/" + Self.swiftUIPath
        map[IconRegistry.defaultFile] = Self.outputDirectory + "/" + Self.iconsPath

        var files: [GeneratedFile] = []
        func add(_ path: String, _ contents: String) {
            files.append(GeneratedFile(path: Self.outputDirectory + "/" + path, contents: contents))
        }
        let chapters = sources.chapters.map { chapter in
            (
                chapter: chapter, title: Self.title(chapter.text) ?? chapter.source,
                summary: Self.chapterSummaries(sources.readme)[Self.fileName(chapter.source)]
            )
        }
        add(
            Self.indexPath,
            Self.index(
                cards: cards, tokens: tokenPages, icons: sources.icons,
                chapters: chapters.map { (Self.chapterPath($0.chapter.source), $0.title, $0.summary) },
                sources: [
                    ContractCheck.defaultDirectory, tokens.resolver, IconRegistry.defaultFile,
                    conventionsSource, Self.designLanguageDirectory,
                ]))
        for card in cards {
            add(ComponentCard.path(card.contract.id), card.markdown())
            if let details = card.details() { add(ComponentCard.detailsPath(card.contract.id), details) }
        }
        for page in tokenPages { add(page.path, page.contents) }
        add(Self.iconsPath, try Self.icons(sources.icons, cards: cards, names: names))
        add(
            Self.swiftUIPath,
            try Self.swiftUI(
                sources.conventions, source: conventionsSource, map: map,
                components: Set(cards.map(\.contract.id))))
        for chapter in sources.chapters {
            let output = Self.outputDirectory + "/" + Self.chapterPath(chapter.source)
            let header =
                ContextMarkdown.header([chapter.source])
                + ContextMarkdown.wrap(
                    "<!-- The design language is distributed under CC BY 4.0, "
                        + "https://creativecommons.org/licenses/by/4.0/ (westron's design-language/LICENSE). Links to "
                        + "the rest of westron's repository are left as their text. -->")
            let text = ContextMarkdown.rewritingLinks(chapter.text, from: chapter.source, to: output, map: map)
            files.append(GeneratedFile(path: output, contents: header.joined(separator: "\n") + "\n\n" + text))
        }
        files.append(
            GeneratedFile(
                path: Self.llmsFile,
                contents: Self.llms(
                    cards: cards, tokens: tokenPages,
                    chapters: chapters.map { (Self.chapterPath($0.chapter.source), $0.title, $0.summary) },
                    sources: [
                        ContractCheck.defaultDirectory, tokens.resolver, IconRegistry.defaultFile,
                        conventionsSource, Self.designLanguageDirectory,
                    ])))
        return files
    }

    static let indexPath = "index.md"
    static let iconsPath = "icons.md"
    static let swiftUIPath = "swiftui.md"

    /// `design-language/06-layout.md` for a chapter.
    static func chapterPath(_ source: String) -> String { "design-language/" + fileName(source) }

    static func fileName(_ path: String) -> String { String(path.split(separator: "/").last ?? "") }

    /// A Markdown file's first heading, `06. Layout`.
    static func title(_ text: String) -> String? {
        text.split(separator: "\n").first { $0.hasPrefix("# ") }.map { String($0.dropFirst(2)) }
    }

    /// What each chapter settles, from the README's table, by the chapter's file name.
    static func chapterSummaries(_ readme: String?) -> [String: String] {
        var result: [String: String] = [:]
        for line in (readme ?? "").split(separator: "\n") where line.hasPrefix("| [") {
            let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard cells.count >= 2, let open = cells[0].firstIndex(of: "("), let close = cells[0].lastIndex(of: ")")
            else { continue }
            result[String(cells[0][cells[0].index(after: open)..<close])] = cells[1]
        }
        return result
    }

    /// The card of each contract, after the API parity lint's derivation of every contract's API at once: the state
    /// modifiers are shared.
    /// The text role an example call names, where the model has it.
    static let exampleTextRole = "body.regular"

    /// - Parameter textRoles: the text roles' members, `body.regular`, for examples.
    static func cards(_ sources: Sources, textRoles: [String]) throws -> [ComponentCard] {
        var lint: [APIParity.Contract] = []
        var documents: [JSON] = []
        for entry in sources.contracts {
            lint.append(
                APIParity.Contract(
                    contract: try ComponentContract(yaml: entry.text, source: entry.source), source: entry.source,
                    text: entry.text))
            documents.append(try ContractYAML.parse(entry.text, source: entry.source))
        }
        let expected = APIParity.expected(lint)
        let icon = sources.icons.icons.first?.name ?? sources.icons.fallback
        let role = textRoles.contains(Self.exampleTextRole) ? Self.exampleTextRole : textRoles.first ?? ""
        return zip(lint, documents).map { item, document in
            ComponentCard(
                contract: item.contract, document: document, source: item.source, expected: expected,
                exampleIcon: icon, exampleTextRole: role)
        }
    }

    // MARK: - The index

    static func index(
        cards: [ComponentCard], tokens: [ContextTokens.Page], icons: IconRegistry,
        chapters: [(path: String, title: String, summary: String?)], sources: [String]
    ) -> String {
        var out = ContextMarkdown.header(sources)
        out += ["", "# westron: index", ""]
        out += ContextMarkdown.wrap(
            "westron is a design system: tokens, component contracts, a design language, and on Apple the SwiftUI "
                + "library WestronUI. Read this file first, then only the files the task needs. Paths are relative to "
                + "this file; the rules for using westron are in `../SKILL.md`.")
        out += [
            "", "## Components", "",
            "`import WestronUI`. Each line: the card, the shortest call, what the component is. A card ends with a",
            "pointer to its details file, the contract's prose, for cases the card does not settle.", "",
        ]
        let someEnums = cards.flatMap(\.enums).prefix(2).map { "`\($0.type)`, " }.joined()
        out += ContextMarkdown.wrap(
            "The option enums the cards list (\(someEnums)…) are in `WestronContract`, which "
                + "`WestronUI` re-exports. A product's shared code, which cannot import SwiftUI, imports "
                + "`WestronContract` instead, and `WestronTokens` for `Westron.Icon` and `Westron.Category`; neither "
                + "imports anything.")
        out.append("")
        for card in cards {
            let call = card.shortestCall.map(ContextMarkdown.code)
            let styled = card.targets.map { "`.\($0.modifier)(…)`" }
            let what = styled.isEmpty ? call : ContextMarkdown.list(styled, conjunction: "or")
            out.append(
                "- [\(card.component)](\(ComponentCard.path(card.contract.id)))"
                    + (what.map { ", \($0)" } ?? "") + ": " + card.summary)
        }
        out += ["", "## Tokens", ""]
        for page in tokens { out.append("- [\(page.title)](\(page.path)): \(page.summary)") }
        out += [
            "", "## Icons", "",
            "- [Icons](\(iconsPath)): \(icons.icons.count) names, `Westron.Icon`: `Icon(.\(icons.icons.first?.name ?? ""))`, "
                + "what each draws and its SF Symbol",
            "", "## SwiftUI", "",
            "- [westron in SwiftUI](\(swiftUIPath)): how a contract's options, states, slots and accessibility become "
                + "SwiftUI API, and what stays the system's",
            "", "## Design language", "",
            "Why westron looks and behaves as it does; read a chapter when a card or a token points to it.", "",
        ]
        for chapter in chapters {
            out.append("- [\(chapter.title)](\(chapter.path))" + (chapter.summary.map { ": \($0)" } ?? ""))
        }
        return out.joined(separator: "\n") + "\n"
    }

    // MARK: - Icons

    static func icons(_ registry: IconRegistry, cards: [ComponentCard], names: ContextNames) throws -> String {
        var out = ContextMarkdown.header([IconRegistry.defaultFile])
        out += ["", "# Icons", ""]
        let first = registry.icons.first?.name ?? registry.fallback
        out += ContextMarkdown.wrap(
            "westron's icon names: a `Westron.Icon`, `import WestronUI`. A name says what the glyph draws, not what it "
                + "means on a screen. A product asks for a glyph by its name, never by an SF Symbol's name:")
        out.append("")
        for card in cards {
            for view in card.views {
                for initializer in view.initializers
                where initializer.parameters.first?.type == AppleIcons.iconType
                    && !initializer.extras.contains("@_disfavoredOverload")
                {
                    let arguments = card.requiredArguments(initializer.parameters).joined(separator: ", ")
                    let what =
                        initializer.parameters.contains { $0.label == "label" }
                        ? "a glyph that says something, its `label` the name assistive technology reads"
                        : "decorative, hidden from assistive technology"
                    out += ContextMarkdown.item(
                        "`\(view.type)(\(arguments))`: \(card.component), \(what) "
                            + "(`\(ComponentCard.path(card.contract.id))`).")
                }
            }
            for target in card.targets {
                guard let overload = card.styleOverload(target.modifier) else { continue }
                for parameter in overload.parameters where parameter.type == AppleIcons.iconType + "?" {
                    let arguments = card.requiredArguments(overload.parameters) + ["\(parameter.label): .\(first)"]
                    out += ContextMarkdown.item(
                        "`.\(target.modifier)(\(arguments.joined(separator: ", ")))`: \(card.component)'s "
                            + "`\(parameter.label)` (`\(ComponentCard.path(card.contract.id))`).")
                }
            }
        }
        out += ContextMarkdown.item(
            try names.fill(
                "`Label(\"…\", icon: .\(first))`{!adapter:Label.init}: the title and the icon of a control's label, "
                    + "such as a button's."))
        out += ContextMarkdown.item(
            try names.fill(
                "`Image(.\(first))`{!adapter:Image.init}: only where nothing but an `Image` fits, as inside `Text` "
                    + "interpolation; it keeps the symbol's spoken name, so such a text takes an "
                    + "`.accessibilityLabel`."))
        out += ContextMarkdown.item(
            try names.fill(
                "`Westron.Icon(rawValue: name) ?? .{icon:fallback}`: a name a product stored; a name this version does "
                    + "not know draws `.\(registry.fallback)`. `icon.{icon:systemName}` is the SF Symbol's name, for a "
                    + "system call that takes `systemImage:`."))
        out +=
            [""]
            + ContextMarkdown.wrap(
                "When no name draws what a screen needs, westron lacks the glyph: say so, and do not draw an SF Symbol "
                    + "or an image of the product's own in its place. The design language: "
                    + "`design-language/07-icons.md`.")
        out += ["", "| Name | What it draws | SF Symbol |", "|---|---|---|"]
        for icon in registry.icons {
            out.append("| `.\(icon.name)` | \(icon.description) | `\(icon.apple)` |")
        }
        return out.joined(separator: "\n") + "\n"
    }

    // MARK: - SwiftUI

    /// The section of spec/conventions.md on the system's controls, and the SwiftUI column of its table.
    static let systemSection = "### A style on the system control, not a wrapper"
    static let tableSection = "## The table"

    /// The SwiftUI page from spec/conventions.md.
    /// - Throws: `ConventionsProblem` when the section or the table is not where the page reads it.
    /// A pointer to a section of spec/conventions.md, `(below, "Own components")`: the page copies only one section,
    /// so the pointers go.
    private static let pointer = try! NSRegularExpression(
        pattern: #"(\s?\((?:below|above)(?:, "[^"]*")?\)|, (?:below|above), "[^"]*")"#)
    /// An example of an id and the type it gives, `` `empty-state` → `EmptyState` ``, after a comma.
    private static let idExample = try! NSRegularExpression(pattern: #",\s*`([a-z][a-z-]*)` → `[^`]*`"#)

    /// A line of the conventions as the page writes it: its links fit for the bundle, without pointers to sections it
    /// does not copy, and without examples that name a component westron does not have.
    static func swiftUILine(
        _ line: String, source: String, output: String, map: [String: String], components: Set<String>
    ) -> String {
        var text = ContextMarkdown.rewritingLinks(line, from: source, to: output, map: map)
        text = pointer.stringByReplacingMatches(
            in: text, range: NSRange(location: 0, length: NSString(string: text).length), withTemplate: "")
        let ns = NSString(string: text)
        var result = ""
        var last = 0
        for match in idExample.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            guard !components.contains(ns.substring(with: match.range(at: 1))) else { continue }
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            last = match.range.location + match.range.length
        }
        return result + ns.substring(from: last)
    }

    static func swiftUI(
        _ conventions: String, source: String, map: [String: String], components: Set<String>
    ) throws -> String {
        let output = outputDirectory + "/" + swiftUIPath
        func line(_ text: String) -> String {
            swiftUILine(text, source: source, output: output, map: map, components: components)
        }
        let lines = conventions.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let start = lines.firstIndex(of: systemSection) else {
            throw ConventionsProblem(source: source, "no section \"\(systemSection)\"")
        }
        let end = lines[(start + 1)...].firstIndex { $0.hasPrefix("## ") || $0.hasPrefix("### ") } ?? lines.count
        guard let table = lines.firstIndex(of: tableSection) else {
            throw ConventionsProblem(source: source, "no section \"\(tableSection)\"")
        }
        var rows: [(concept: String, swiftUI: String)] = []
        for line in lines[(table + 1)...] {
            if line.hasPrefix("## ") { break }
            guard line.hasPrefix("| **") else { continue }
            let cells = line.dropFirst(2).dropLast(2).components(separatedBy: " | ")
            guard cells.count == 5 else {
                throw ConventionsProblem(source: source, "a row of the table without five cells: \(line.prefix(60))…")
            }
            rows.append((cells[0].replacingOccurrences(of: "**", with: ""), cells[1]))
        }
        guard !rows.isEmpty else { throw ConventionsProblem(source: source, "the table has no rows") }
        var out = ContextMarkdown.header([source])
        out += ["", "# westron in SwiftUI", ""]
        out += ContextMarkdown.wrap(
            "How each concept of a component contract becomes SwiftUI API, and what stays the system's: from westron's "
                + "platform conventions. A card names these concepts; this page says what each means in code. A "
                + "reference such as \"decisions/0003\" or \"#33\" points into westron's repository and is not in this "
                + "bundle.")
        out += ["", "## " + systemSection.dropFirst(4)]
        out += lines[(start + 1)..<end].map(line)
        while out.last == "" { out.removeLast() }
        out += ["", "## The concepts in SwiftUI"]
        for row in rows {
            out += ["", "### \(row.concept)", ""]
            out += ContextMarkdown.wrap(ContextMarkdown.withoutTooling(line(row.swiftUI)))
        }
        return out.joined(separator: "\n") + "\n"
    }

    public struct ConventionsProblem: Error, CustomStringConvertible {
        public let source: String
        public let message: String

        init(source: String, _ message: String) {
            self.source = source
            self.message = message
        }

        public var description: String { "\(source): \(message); the agent context reads it (AgentContext)" }
    }

    // MARK: - llms.txt

    static func llms(
        cards: [ComponentCard], tokens: [ContextTokens.Page],
        chapters: [(path: String, title: String, summary: String?)], sources: [String]
    ) -> String {
        let base = outputDirectory + "/"
        var out = ContextMarkdown.header(sources)
        out += ["", "# westron", ""]
        out += ContextMarkdown.wrap(
            "A design system for several products: design tokens, component contracts, a design language and a native "
                + "library on each platform; on Apple, the SwiftUI library WestronUI. These files tell an agent which "
                + "component to use, how to call it, which tokens to lay a screen out with, and what not to do.",
            first: "> ", rest: "> ")
        out.append("")
        out += ContextMarkdown.wrap(
            "Read `\(AgentContext.skillDirectory)/SKILL.md` for the rules, then the index, then only the cards a task "
                + "needs. In Claude Code the same files come as the plugin `westron` from the marketplace in this "
                + "repository, `.claude-plugin/marketplace.json`.")
        out += [
            "", "## Docs", "",
            "- [Index](\(base)\(indexPath)): every component, token page, the icons and the design language, one line each",
            "- [Rules for agents](\(AgentContext.skillDirectory)/SKILL.md): how to build UI with westron and what not to do",
            "- [westron in SwiftUI](\(base)\(swiftUIPath)): how a contract's concepts become SwiftUI API",
            "- [Icons](\(base)\(iconsPath)): the icon names and how a glyph is asked for",
        ]
        for page in tokens { out.append("- [\(page.title)](\(base)\(page.path)): \(page.summary)") }
        out += ["", "## Components", ""]
        for card in cards {
            out.append("- [\(card.component)](\(base)\(ComponentCard.path(card.contract.id))): \(card.summary)")
        }
        out += ["", "## Optional", ""]
        for chapter in chapters {
            out.append("- [\(chapter.title)](\(base)\(chapter.path))" + (chapter.summary.map { ": \($0)" } ?? ""))
        }
        return out.joined(separator: "\n") + "\n"
    }
}
