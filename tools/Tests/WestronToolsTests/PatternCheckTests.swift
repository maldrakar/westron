import Foundation
import Testing

@testable import WestronTools

private func path(_ relative: String) -> String { repositoryRoot.appendingPathComponent(relative).path }

/// The repository's contracts, tokens, icon registry and API, which the fixtures are checked against.
private let references = try! PatternCheck.references(
    contractsDirectory: path(ContractCheck.defaultDirectory), schemaFile: path(ContractSchema.defaultFile),
    resolverFile: path(TokenCheck.defaultResolver), iconsFile: path(IconRegistry.defaultFile))

/// The path the fixture is checked under.
private let fixtureSource = "spec/patterns/pick-a-list.md"

/// A valid pattern on the real components; tests replace parts of it. It is not one of westron's patterns.
private let patternFixture = """
    ---
    id: pick-a-list
    title: Pick a list
    status: approved
    summary: Pick one list in a sheet.
    consumers: [todo-app/lists-screen]
    components: [list-row, icon-tile, icon]
    tokens: [space.page.narrow, color.text.primary]
    icons: [check]
    gaps: [G1]
    ---

    # Pick a list

    ## When to use

    A person picks one list.

    ## Parts

    | Part | Built from |
    |---|---|
    | A choice | A pressable `ListRow` with `IconTile(icon).category(category)`, `.selected(true)` on the current one |
    | The hint | `footnote.regular` in `text.secondary`, `space.within-group` above the rows |

    ## Rules

    1. One tap takes a choice.

    ## Accessibility

    Each row is one button.

    ## Apple

    ```swift
    ListRow(level: 1, guides: false, action: {}) {
        Text("Inbox")
    } leading: {
        IconTile(.tray).category(.amber)
    } trailing: {
        Icon(.check).foregroundStyle(.text.primary)
    }
    .selected(true)
    .padding(.horizontal, .space.page.narrow)
    .buttonStyle(.plain)
    ```

    ## Not covered

    Several choices at once.

    ## Gaps

    - **G1** (#1): something westron lacks.

    """

/// The problems of a pattern written inline, as `line: message`.
private func patternProblems(_ text: String, source: String = fixtureSource) -> [String] {
    PatternCheck.check(text, source: source, references: references).problems.map {
        "\($0.line.map(String.init) ?? "-"): \($0.message)"
    }
}

/// A text with one part replaced, which must occur in it; the fixture by default.
private func replacing(_ old: String, with new: String, in text: String = patternFixture) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

/// The fixture's line, from 1, of the first line that contains `text`.
private func patternLine(_ text: String) -> Int {
    (patternFixture.split(separator: "\n", omittingEmptySubsequences: false).firstIndex { $0.contains(text) } ?? -1) + 1
}

/// Whether one problem's message contains `text`. Records the problems found when none does.
private func has(_ problems: [String], _ text: String, sourceLocation: SourceLocation = #_sourceLocation) -> Bool {
    let found = problems.contains { $0.contains(text) }
    if !found { Issue.record("problems: \(problems)", sourceLocation: sourceLocation) }
    return found
}

@Suite("Pattern check")
struct PatternCheckTests {
    @Test("the front matter is read into its fields, the body after it")
    func read() throws {
        let (pattern, problems) = Pattern.read(patternFixture, source: fixtureSource)
        #expect(problems == [])
        let read = try #require(pattern)
        #expect(read.id == "pick-a-list")
        #expect(read.title == "Pick a list")
        #expect(read.status == "approved")
        #expect(read.isApproved)
        #expect(read.summary == "Pick one list in a sheet.")
        #expect(read.consumers == ["todo-app/lists-screen"])
        #expect(read.components == ["list-row", "icon-tile", "icon"])
        #expect(read.tokens == ["space.page.narrow", "color.text.primary"])
        #expect(read.icons == ["check"])
        #expect(read.gaps == ["G1"])
        #expect(read.bodyLine == 12)
        #expect(read.keyLines["status"] == 4)
        #expect(read.heading?.title == "Pick a list")
        #expect(read.sections.map(\.title) == PatternCheck.sections)
        #expect(read.blocks(of: "Apple").count == 1)
        #expect(read.blocks(of: "Apple").first?.line == 37)
    }

    @Test("the fixture passes, and so does every pattern of the repository")
    func valid() throws {
        #expect(patternProblems(patternFixture) == [])
        let files = try PatternCheck.files(in: path(PatternCheck.defaultDirectory))
        #expect(files.contains { $0.hasSuffix("/choice-list-sheet.md") })
        for file in files {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            let source = PatternCheck.defaultDirectory + "/" + (file.split(separator: "/").last.map(String.init) ?? "")
            #expect(patternProblems(text, source: source) == [], "\(source)")
        }
    }

    @Test("a file without front matter, or with YAML that does not parse, is reported")
    func frontMatterMissingOrMalformed() {
        #expect(has(patternProblems("# Pick a list\n\n## When to use\n"), "no front matter"))
        #expect(has(patternProblems(replacing("title: Pick a list", with: "title: [Pick a list")), "not valid YAML"))
        #expect(has(patternProblems(replacing("---\n\n# Pick", with: "\n# Pick")), "no front matter"))
        #expect(
            has(patternProblems(replacing("icons: [check]", with: "icons: [check]\nicons: [tray]")), "repeats the key"))
    }

    @Test("every key is required, an unknown one is an error, the types are held")
    func keys() {
        #expect(has(patternProblems(replacing("summary: Pick one list in a sheet.\n", with: "")), "summary is missing"))
        #expect(has(patternProblems(replacing("gaps: [G1]\n", with: "")), "gaps is missing"))
        #expect(
            has(
                patternProblems(replacing("icons: [check]", with: "icons: [check]\nowner: me")), "unknown key \"owner\""
            ))
        #expect(has(patternProblems(replacing("icons: [check]", with: "icons: check")), "icons must be a list"))
        #expect(
            has(
                patternProblems(replacing("components: [list-row, icon-tile, icon]", with: "components: []")),
                "components is empty"))
        #expect(has(patternProblems(replacing("title: Pick a list", with: "title: 12")), "title must be a string"))
        // An empty list of tokens, icons or gaps is fine where the sections agree.
        let none = replacing("icons: [check]", with: "icons: []")
        #expect(patternProblems(none) == [])
    }

    @Test("the id is the file's name, the status one of two, the consumers <product>/<screen>")
    func identity() {
        #expect(
            has(patternProblems(patternFixture, source: "spec/patterns/pick-one.md"), "differs from the file's name"))
        #expect(has(patternProblems(replacing("status: approved", with: "status: draft")), "status \"draft\" is not"))
        #expect(has(patternProblems(replacing("lists-screen]", with: "Lists Screen]")), "is not <product>/<screen>"))
        #expect(has(patternProblems(replacing("# Pick a list\n", with: "# Choose a list\n")), "is not the title"))
        // The line of the key, in the file.
        #expect(patternProblems(replacing("status: approved", with: "status: draft")).first?.hasPrefix("4: ") == true)
    }

    @Test("components, tokens and icons are held to the contracts, the token model and the icon registry")
    func references() {
        #expect(
            has(
                patternProblems(replacing("[list-row, icon-tile", with: "[list-rows, icon-tile")),
                "\"list-rows\" has no contract"))
        #expect(
            has(
                patternProblems(replacing("[space.page.narrow,", with: "[space.page.narow,")),
                "\"space.page.narow\" is not a token"))
        // A Swift member is not a source name.
        #expect(
            has(
                patternProblems(replacing("color.text.primary]", with: "text.primary]")),
                "\"text.primary\" is not a token"))
        #expect(
            has(
                patternProblems(replacing("icons: [check]", with: "icons: [tick]")),
                "\"tick\" is not a name of the icon"))
    }

    @Test("the fixed sections, in order; Questions only while proposed")
    func sections() {
        #expect(
            has(
                patternProblems(replacing("## Rules\n\n1. One tap takes a choice.\n\n", with: "")),
                "no section \"## Rules\""))
        let swapped = replacing(
            "## Rules\n\n1. One tap takes a choice.\n\n## Accessibility\n\nEach row is one button.\n",
            with: "## Accessibility\n\nEach row is one button.\n\n## Rules\n\n1. One tap takes a choice.\n")
        #expect(has(patternProblems(swapped), "out of order"))
        #expect(
            has(patternProblems(replacing("## Not covered", with: "## Out of scope")), "a section \"Out of scope\""))
        let questions = patternFixture + "\n## Questions\n\n1. Which?\n"
        #expect(has(patternProblems(questions), "an approved pattern has no section \"Questions\""))
        #expect(patternProblems(replacing("status: approved", with: "status: proposed", in: questions)) == [])
        #expect(patternProblems(replacing("status: approved", with: "status: proposed")) == [])
        #expect(has(patternProblems(patternFixture + "\n## Gaps\n\nMore.\n"), "comes twice"))
        // A heading inside the example is code, not a section.
        #expect(patternProblems(replacing("Text(\"Inbox\")", with: "Text(\"Inbox\")\n// ## Parts")) == [])
    }

    @Test("Apple holds one Swift example")
    func example() {
        let none = replacing("```swift", with: "```text")
        #expect(has(patternProblems(none), "holds 0 Swift examples"))
    }

    @Test("each gap of the front matter has an entry in Gaps, and each entry is in the front matter")
    func gaps() {
        #expect(
            has(patternProblems(replacing("gaps: [G1]", with: "gaps: [G1, G2]")), "\"G2\" has no entry \"- **G2**\""))
        #expect(
            has(patternProblems(replacing("gaps: [G1]", with: "gaps: []")), "the gap \"G1\" is not in the front matter")
        )
    }

    @Test("the example's westron names are WestronUI's API: tokens, initializers, overloads and values")
    func exampleNames() {
        #expect(
            has(
                patternProblems(replacing(".space.page.narrow)", with: ".space.page.narow)")),
                "`.space.page.narow` is not a token's Swift member"))
        #expect(
            has(
                patternProblems(replacing("guides: false,", with: "guidelines: false,")),
                "`ListRow(level:guidelines:action:) { … } leading: { … } trailing: { … }` matches no initializer"))
        #expect(
            has(patternProblems(replacing("Icon(.check)", with: "Icon(.tick)")), "`.tick` is not a name of the icon"))
        #expect(
            has(
                patternProblems(replacing(".category(.amber)", with: ".category(.ambr)")), "`.ambr` is not a list color"
            ))
        #expect(
            has(
                patternProblems(replacing(".selected(true)", with: ".selected(on: true)")),
                "`.selected(on:)` matches no"))
        #expect(
            has(
                patternProblems(replacing(".selected(true)", with: "Rule(axis: .diagonal)")),
                "`.diagonal` is not a value of `RuleAxis`"))
        #expect(
            has(
                patternProblems(replacing(".selected(true)", with: "Text(\"…\").textRole(.text.primary)")),
                "`.text.primary` is not a text role"))
        // SwiftUI's own style, a variable and a westron value pass; so does `WestronUI.Icon`, and its wrong value not.
        #expect(
            patternProblems(replacing(".selected(true)", with: ".selected(isCurrent).buttonStyle(.bordered)")) == [])
        #expect(has(patternProblems(replacing("Icon(.check)", with: "WestronUI.Icon(.tick)")), "`.tick` is not a name"))
    }

    @Test("a code span of the prose that names a token or calls westron's API is held too")
    func proseNames() {
        #expect(
            has(
                patternProblems(replacing("`footnote.regular`", with: "`footnote.regulr`")),
                "`footnote.regulr` names no token"))
        #expect(
            has(
                patternProblems(replacing("`IconTile(icon)", with: "`IconTile(icon, name: \"x\")")),
                "matches no initializer"))
        // A dotted name that is no token's, such as a file, is not read as one.
        #expect(patternProblems(replacing("Several choices at once.", with: "Not in `index.md`.")) == [])
        // A code span wrapped over two lines is one span, a line break in it a space, reported on its first line.
        let wrapped = patternProblems(
            replacing(
                "Several choices at once.", with: "Several choices, as `IconTile(.tray)\n  .category(.ambr)` in one."))
        #expect(has(wrapped, "`.ambr` is not a list color"))
        #expect(wrapped.first?.hasPrefix("\(patternLine("Several choices")): ") == true, "\(wrapped)")
        // A span does not cross from one list item, table row or paragraph to the next.
        for separator in ["\n- ", "\n| ", "\n\n"] {
            let text = "- One `IconTile(.tray)" + separator + ".category(.ambr)` two."
            #expect(patternProblems(replacing("Several choices at once.", with: text)) == [], "\(separator)")
        }
        #expect(
            has(
                patternProblems(
                    replacing("Several choices at once.", with: "- One `IconTile(.tray)\n.category(.ambr)`")),
                "`.ambr` is not a list color"))
    }

    @Test("the arguments of a call fit an overload: labels in order, defaults left out, a trailing closure")
    func match() {
        let parameters: [SwiftDeclarations.Parameter] = [
            .init(label: "level", type: "Int", defaultValue: "0"),
            .init(label: "action", type: "@escaping () -> Void"),
            .init(label: "title", type: "() -> Title"),
            .init(label: "leading", type: "() -> Leading", defaultValue: "{ EmptyView() }"),
        ]
        func call(_ labels: [String], trailing: Bool = false) -> [PatternNames.Argument] {
            labels.map { PatternNames.Argument(label: $0, expression: nil, isTrailingClosure: false) }
                + (trailing ? [PatternNames.Argument(label: "_", expression: nil, isTrailingClosure: true)] : [])
        }
        #expect(PatternNames.match(call(["action"], trailing: true), parameters) != nil)
        #expect(PatternNames.match(call(["level", "action", "title"]), parameters) != nil)
        #expect(PatternNames.match(call(["action"]), parameters) == nil)
        #expect(PatternNames.match(call(["title", "action"]), parameters) == nil)
        #expect(PatternNames.match(call([], trailing: true), parameters) == nil)
    }

    @Test("a style modifier's lone `.name` is westron's variant unless it names one of the system's styles")
    func styles() {
        let example = { (line: String) in replacing(".buttonStyle(.plain)", with: line) }
        for (call, value) in [
            (".buttonStyle(.primry)", "`.primry` is not a value of `ButtonVariant`"),
            (".textFieldStyle(.framd)", "`.framd` is not a value of `TextFieldVariant`"),
            (".toggleStyle(.chek)", "`.chek` is not a value of"),
            (".disclosureGroupStyle(.chevrn)", "`.chevrn` is not a value of `DisclosureVariant`"),
        ] {
            #expect(has(patternProblems(example(call)), value), "\(call)")
            // In the prose too.
            #expect(
                has(patternProblems(replacing("Several choices at once.", with: "`Button(…)\(call)`")), value),
                "\(call) in prose")
        }
        #expect(
            has(
                patternProblems(example("\nButton(\"Save\", action: {}).buttonStyle(.secondry)")),
                "`.secondry` is not a value of `ButtonVariant`"))
        // A value no overload takes names what each takes: Checkbox's variants and Chip's.
        let toggle = patternProblems(example(".toggleStyle(.primary)"))
        #expect(toggle.count == 1, "\(toggle)")
        #expect(has(toggle, "`.primary` is not a value of `CheckboxVariant`: "))
        #expect(has(toggle, "; nor of `ChipVariant`: "))
        // SwiftUI's own styles, a style of the product's own and westron's variants pass.
        for call in [
            ".buttonStyle(.bordered)", ".buttonStyle(myStyle)", ".buttonStyle(MyStyle())", ".buttonStyle(.secondary)",
            ".toggleStyle(.switch)", ".toggleStyle(.check)", ".textFieldStyle(.roundedBorder)",
        ] {
            #expect(patternProblems(example(call)) == [], "\(call)")
        }
    }

    @Test("a text role of one name is held too; SwiftUI's own two-name members are not tokens")
    func textRolesAndSwiftUIMembers() {
        let example = { (line: String) in replacing(".selected(true)", with: line) }
        #expect(has(patternProblems(example("Text(\"…\").textRole(.bodyy)")), "`.bodyy` is not a text role"))
        #expect(has(patternProblems(example("Text(\"…\").textRole(.body)")), "`.body` is not a text role"))
        #expect(patternProblems(example("Text(\"…\").textRole(.body.regular)")) == [])
        // Reported once where it stands, by the chain's own check: in the example and in the table's `.selected(true)`.
        let typo = patternProblems(example("Text(\"…\").textRole(.footnote.regulr)"))
        #expect(typo.count == 2, "\(typo)")
        #expect(has(typo, "`.footnote.regulr` is not a token's Swift member"))
        for call in [
            "Image(systemName: \"x\").symbolEffect(.bounce.up)",
            "Image(systemName: \"x\").symbolEffect(.variableColor.iterative)",
            "Text(\"…\").foregroundStyle(.tint.secondary)", "Text(\"…\").foregroundStyle(.text.primary.opacity(0.5))",
        ] {
            #expect(patternProblems(example(call)) == [], "\(call)")
        }
        // A chain a method is called on is a chain all the same.
        #expect(
            has(
                patternProblems(example("Text(\"…\").foregroundStyle(.text.primry.opacity(0.5))")),
                "`.text.primry` is not a token's Swift member"))
    }

    @Test("an elided call, as prose writes one, is not held; an `…` in a string or a closure elides nothing")
    func elided() {
        let prose = { (span: String) in replacing("Several choices at once.", with: span) }
        #expect(
            patternProblems(prose("`ListRow(…)` and `ListRow(…) { … }`, `ListRow(level: 1, …)`, `.buttonStyle(…)`"))
                == [])
        #expect(
            patternProblems(
                prose("`ListRow(level: 1, guides: false, action: { … }) { … }`, `Icon(.check, label: \"…\")`")) == [])
        #expect(has(patternProblems(prose("`ListRow(lvl: 1) { … }`")), "matches no initializer"))
        #expect(
            has(patternProblems(prose("`IconTile(.tik, label: \"Move to…\")`")), "`.tik` is not a name of the icon"))
        #expect(has(patternProblems(prose("`Icon(.tick, label: \"More…\")`")), "`.tick` is not a name of the icon"))
        #expect(
            has(
                patternProblems(prose("`ListRow(level: 1, gudes: false, action: { show(\"Move to…\") }) { … }`")),
                "`ListRow(level:gudes:action:) { … }` matches no initializer"))
    }

    @Test("every Swift block is held, not only the example; Apple still holds one")
    func otherBlocks() {
        let rules = replacing(
            "1. One tap takes a choice.\n", with: "1. One tap takes a choice.\n\n```swift\nIcon(.tick)\n```\n")
        let found = patternProblems(rules)
        #expect(has(found, "a Swift block: `.tick` is not a name of the icon registry"))
        #expect(!found.contains { $0.contains("Swift examples") })
        // A block of another language is not Swift.
        #expect(patternProblems(rules.replacingOccurrences(of: "```swift\nIcon", with: "```text\nIcon")) == [])
    }

    @Test("a file with CRLF line ends is read as with LF")
    func crlf() {
        #expect(patternProblems(patternFixture.replacingOccurrences(of: "\n", with: "\r\n")) == [])
    }

    @Test("the sections every pattern has are the fixed ones, none optional yet, in the order a pattern may have")
    func sectionLists() {
        #expect(PatternCheck.requiredSections == PatternCheck.sections)
        #expect(PatternCheck.optionalSections.isSubset(of: Set(PatternCheck.sections)))
        #expect(!PatternCheck.optionalSections.contains(PatternCheck.appleSection))
    }
}
