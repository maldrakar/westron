import Foundation
import Testing

@testable import WestronTools

/// A style on the system button with every kind of option a card describes: a variant with no default, a size, a bool,
/// a state the button lacks, a constraint, a binding the card leaves out. It is not one of westron's contracts.
private let pillYAML = """
    id: pill
    status: approved
    description: >-
      A small pressable pill. It holds a short label. Its padding is container.padding at every size.
    consumers: [todo-app/list-screen]
    options:
      variant:
        type: enum
        values: [solid, quiet]
        description: The fill.
      size: { type: enum, values: [s, m], default: m }
      compact:
        type: bool
        default: false
        description: Less padding. The padding is container.padding halved.
    slots: [label, icon]
    states: [hover, pressed, disabled, loading]
    constraints:
      - when: { compact: true }
        require: { size: [s] }
        severity: error
        description: A compact pill is small.
    tokens:
      container.padding: space.100
    accessibility:
      role: button
      intents: [activate]
      keyboardIntents: [activate]
      label: required
      states: { disabled: disabled, loading: busy }
      description: The label names the action. The catalog's PillBehaviorTests measured it.
    platforms:
      apple:
        strategy: style-on-system-control
        base: SwiftUI.Button
        description: A style on the system button.
        watchos:
          states: [pressed, disabled, loading]
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let pillSource = "spec/components/pill/pill.spec.yaml"

private func pill() throws -> ComponentCard {
    let sources = AgentContext.Sources(
        contracts: [(pillYAML, pillSource)],
        icons: IconRegistry(icons: [.init(name: "tray", description: "A tray.", apple: "tray")], fallback: "tray"),
        conventions: "", chapters: [], readme: nil)
    let cards = try AgentContext.cards(sources, textRoles: ["body.regular"])
    try #require(cards.count == 1)
    return cards[0]
}

private func path(_ relative: String) -> String { repositoryRoot.appendingPathComponent(relative).path }

/// The generator over this repository's sources.
private func generator() -> AgentContext {
    AgentContext(
        contractsDirectory: path(ContractCheck.defaultDirectory), schemaFile: path(ContractSchema.defaultFile),
        resolverFile: path(TokenCheck.defaultResolver), iconsFile: path(IconRegistry.defaultFile),
        conventionsFile: path(AgentContext.conventionsFile),
        designLanguageDirectory: path(AgentContext.designLanguageDirectory))
}

/// The real cards, with the names the generator's prose may use.
private func realCards() throws -> (cards: [ComponentCard], names: ContextNames) {
    let directory = path(ContractCheck.defaultDirectory)
    let contracts = try ContractCheck.files(in: directory).map { file in
        (text: try String(contentsOfFile: file, encoding: .utf8), source: file)
    }
    let model = try AppleTokenModel(Resolution(resolverFile: path(TokenCheck.defaultResolver)))
    let sources = AgentContext.Sources(
        contracts: contracts, icons: try IconRegistry.load(file: path(IconRegistry.defaultFile)), conventions: "",
        chapters: [], readme: nil)
    let cards = try AgentContext.cards(
        sources, textRoles: model.textRoles.map { AppleTokensSwift.reference($0.members) })
    return (cards, ContextNames(model: model, functions: Set(cards.first?.expected.functions.map(\.name) ?? [])))
}

@Suite("Agent context")
struct AgentContextTests {
    @Test("the same sources give the same bytes")
    func deterministic() throws {
        let first = try generator().run()
        let second = try generator().run()
        #expect(first == second)
        #expect(Set(first.map(\.path)).count == first.count)
    }

    @Test("writes inside its owned directory in the plugin, and llms.txt at the root")
    func paths() throws {
        for file in try generator().run() where file.path != AgentContext.llmsFile {
            #expect(file.path.hasPrefix(AgentContext.outputDirectory + "/"), "\(file.path)")
        }
        #expect(AgentContext().ownedDirectories == [AgentContext.outputDirectory])
        #expect(AgentContext.outputDirectory.hasPrefix(AgentContext.pluginDirectory + "/skills/"))
        let skill = path(AgentContext.skillDirectory + "/SKILL.md")
        #expect(FileManager.default.fileExists(atPath: skill))
        #expect(
            FileManager.default.fileExists(atPath: path(AgentContext.pluginDirectory + "/.claude-plugin/plugin.json")))
    }

    @Test("the index and llms.txt list every contract's card, and not its details")
    func indexListsEveryContract() throws {
        let files = try generator().run()
        let index = try #require(files.first { $0.path == AgentContext.outputDirectory + "/index.md" })
        let llms = try #require(files.first { $0.path == AgentContext.llmsFile })
        let contracts = try ContractCheck.files(in: path(ContractCheck.defaultDirectory))
        #expect(contracts.count > 0)
        for contract in contracts {
            let id = contract.split(separator: "/").last!.replacingOccurrences(of: ".spec.yaml", with: "")
            let name = AppleComponents.typeName(id)
            #expect(index.contents.contains("\n- [\(name)](components/\(id).md)"), "\(id) in index.md")
            #expect(
                llms.contents.contains("\n- [\(name)](\(AgentContext.outputDirectory)/components/\(id).md)"),
                "\(id) in llms.txt")
            #expect(files.contains { $0.path == AgentContext.outputDirectory + "/components/\(id).md" }, "\(id)'s card")
        }
        #expect(!index.contents.contains(".details.md"))
        #expect(!llms.contents.contains(".details.md"))
        #expect(index.contents.split(separator: "\n").count < 80)
        // Where the option enums come from, for views and for shared code (decisions/0017).
        let indexText = index.contents.replacingOccurrences(of: "\n", with: " ")
        #expect(indexText.contains("are in `WestronContract`, which `WestronUI` re-exports"))
        #expect(indexText.contains("`WestronTokens` for `Westron.Icon` and `Westron.Category`"))
    }

    @Test("a card has the call, the declarations, the options, the states, the name and the constraints")
    func card() throws {
        let card = try pill().markdown()
        #expect(card.hasPrefix("<!-- Generated from \(pillSource) by `tools/westron generate`."))
        #expect(card.contains("\n# Pill\n"))
        #expect(card.contains("\nA small pressable pill.\n"))
        // The shortest call, and the API the parity lint holds WestronUI to.
        #expect(card.contains("```swift\nButton(…)\n    .buttonStyle(.solid)\n….loading(isLoading)\n```"))
        #expect(
            card.contains(
                "    public func buttonStyle(_: PillVariant, size: PillSize? = nil, compact: Bool = false) -> some View"
            ))
        #expect(card.contains("    public func loading(_: Bool) -> some View"))
        #expect(card.contains("public enum PillVariant: String, CaseIterable, Sendable { case solid, quiet }"))
        // The enums apart from WestronUI's API: they are WestronContract's, which shared code imports alone.
        let joined = card.replacingOccurrences(of: "\n", with: " ")
        #expect(joined.contains("Its enums are in `WestronContract`, which `WestronUI` re-exports"))
        #expect(joined.contains("imports `WestronContract` instead"))
        let vocabulary = try #require(card.range(of: "Its enums are in `WestronContract`"))
        #expect(card[vocabulary.upperBound...].contains("public enum PillVariant"))
        #expect(!card[..<vocabulary.lowerBound].contains("public enum PillVariant"))
        // The options, with their values, defaults and descriptions; a sentence naming a binding is left out.
        #expect(card.contains("- `variant`, `PillVariant`: `.solid`, `.quiet`; no default. The fill."))
        #expect(card.contains("- `size`, `PillSize?`: `.s`, `.m`; left out, the size comes from `controlSize`"))
        #expect(card.contains("- `compact`, `Bool`: by default `false`. Less padding.\n"))
        #expect(!card.contains("container."))
        // The states: the system's, and the one westron's modifier sets; one an OS never enters.
        #expect(card.contains("- `loading`: `.loading(_:)`, westron's modifier"))
        #expect(card.contains("- `disabled`: `.disabled(_:)`, the system's."))
        // A list item's lines joined, as Markdown reads them.
        let items = card.replacingOccurrences(of: "\n  ", with: " ")
        #expect(
            items.contains(
                "- `hover`: the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it. "
                    + "Never entered on watchOS."))
        // Where the name comes from: the system control's own label, which westron adds no parameter for.
        #expect(
            items.contains(
                "**Every instance needs an accessible name**: the label the system's own initializer of `Button` "
                    + "takes, its title or the view of its `label:`, such as a `Label`"))
        #expect(card.contains("- **Never**: `compact: true` with `size` other than `.s`. A compact pill is small."))
        // The prose is the details file's; the card points to it last.
        #expect(!card.contains("## Behavior"))
        #expect(!card.contains("The label names the action."))
        #expect(items.contains("More: `pill.details.md` holds "))
    }

    @Test("the details hold the contract's prose, without westron's tooling")
    func details() throws {
        let details = try #require(try pill().details())
        #expect(details.contains("\n# Pill: details\n"))
        #expect(details.contains("points into westron's repository"))
        #expect(details.contains("## Accessibility\n\nThe label names the action.\n"))
        #expect(!details.contains("PillBehaviorTests"))
        #expect(
            details.contains("## Behavior\n\nIt holds a short label. Its padding is container.padding at every size."))
        #expect(details.contains("## On Apple\n\nA style on the system button."))
    }

    @Test("every real card fits its budget and names no binding and no tooling of westron's")
    func realCardsStayShort() throws {
        for card in try realCards().cards {
            // Past the header comment, which names `tools/westron generate`.
            let text = card.markdown().components(separatedBy: "-->").dropFirst().joined(separator: "-->")
            let id = card.contract.id
            #expect(text.split(separator: "\n", omittingEmptySubsequences: false).count <= 150, "\(id)")
            for binding in card.bindings {
                #expect(!ContextMarkdown.names(text, binding), "\(id) names its binding \(binding)")
            }
            for mark in ContextMarkdown.toolingMarks {
                #expect(!text.lowercased().contains(mark), "\(id) names \(mark)")
            }
            #expect(card.details() != nil, "\(id) has details")
        }
    }

    @Test("a view with several slots shows the full call; a twin keeps its attribute")
    func realAPI() throws {
        let cards = try realCards().cards
        let row = try #require(cards.first { $0.contract.id == "list-row" }).markdown()
        #expect(row.contains("\nListRow(action: { … }) { … } subtitle: { … } leading: { … } trailing: { … }\n"))
        #expect(row.contains("**The accessible name comes from the component's content**"))
        #expect(!row.contains("needs an accessible name"))
        let text = try #require(cards.first { $0.contract.id == "text" }).markdown()
        #expect(text.contains("    @_disfavoredOverload public func textRole(_: Westron.TextRole) -> Text"))
        let disclosure = try #require(cards.first { $0.contract.id == "disclosure" }).markdown()
        #expect(disclosure.contains("`.disclosureAlignsLeaves(_: Bool = true)`, on an ancestor"))
    }

    @Test("a name the prose writes is looked up, and an unknown one fails")
    func names() throws {
        let names = try realCards().names
        #expect(
            try names.fill("`.{adapter:View.foregroundStyle}(.{token:color.text.primary})`")
                == "`.foregroundStyle(.text.primary)`")
        #expect(
            try names.fill("`.{token:space.within-group}` and { … }{!adapter:Color.init}")
                == "`.space.withinGroup` and { … }")
        #expect(throws: ContextNames.Missing.self) { try names.fill("{token:color.text.nonexistent}") }
        #expect(throws: ContextNames.Missing.self) { try names.fill("{adapter:View.glow}") }
        #expect(throws: ContextNames.Missing.self) { try names.fill("{api:glow}") }
    }

    /// The hand-written SKILL.md names westron's API; each name it writes is here, looked up, so that a rename in
    /// WestronUI fails this test until the skill follows.
    @Test("the skill names only what WestronUI declares")
    func skillNames() throws {
        let skill = try String(contentsOfFile: path(AgentContext.skillDirectory + "/SKILL.md"), encoding: .utf8)
        let (cards, names) = try realCards()
        for template in [
            "`.{adapter:View.foregroundStyle}(.{token:color.text.primary})`",
            "`.{api:textRole}(.{token:typography.body.regular})`", "`.padding(.{token:space.card})`",
            "`VStack(spacing: .{token:space.within-group})`",
            "`RoundedRectangle(cornerRadius: .{token:radius.card}, style: .continuous)`",
            "`.opacity(.{token:opacity.disabled})`", "`.animation(.{token:motion.fade}, value: x)`",
            "`.{api:selected}(_:)`", "`.{api:loading}(_:)`", "`.{api:dropTarget}(_:)`",
        ] {
            let text = try names.fill(template)
            #expect(skill.contains(text), "SKILL.md writes \(text)")
        }
        let enums = cards.flatMap(\.enums)
        func value(_ type: String, _ name: String) -> Bool {
            enums.contains { $0.type == type && $0.values.contains(name) }
        }
        #expect(skill.contains(".buttonStyle(.secondary)`") && value("ButtonVariant", "secondary"))
        #expect(skill.contains("`Toggle(…).toggleStyle(.check)`") && value("CheckboxVariant", "check"))
        #expect(skill.contains("`TextField(…).textFieldStyle(.framed)`") && value("TextFieldVariant", "framed"))
        #expect(
            skill.contains("`Toggle(isOn:accessibilityLabel:)`")
                && cards.flatMap(\.hiddenLabels).contains { label in
                    label.api.initializers.contains { $0.parameters.map(\.label) == ["isOn", "accessibilityLabel"] }
                })
        let icons = try IconRegistry.load(file: path(IconRegistry.defaultFile)).icons.map(\.name)
        #expect(skill.contains("Label(\"Move\", icon: .tray)") && icons.contains("tray"))
        #expect(skill.contains("check `Icon`") && icons.contains("check"))
        let views = Set(cards.flatMap(\.views).map(\.type))
        for view in ["ListRow", "IconTile", "Icon"] {
            #expect(skill.contains("`\(view)`") && views.contains(view), "\(view)")
        }
        let button = try #require(cards.first { $0.contract.id == "button" })
        #expect(skill.contains("`Button`'s `floating`") && button.contract.options.contains { $0.name == "floating" })
    }

    @Test("the SwiftUI page drops pointers to sections it does not copy, and components westron lacks")
    func swiftUILine() {
        let line = AgentContext.swiftUILine(
            "A `View` (`rule` → `Rule()`, `empty-state` → `EmptyState`) (below, \"Own components\"); the rest, "
                + "below, \"Forms\", and more (below).",
            source: "spec/conventions.md", output: "x/swiftui.md", map: [:], components: ["rule"])
        #expect(line == "A `View` (`rule` → `Rule()`); the rest, and more.")
    }

    @Test("a link into the bundle points to the copy; a link to the rest of the repository becomes its text")
    func links() {
        let map = [
            "design-language/08-accessibility.md": "skills/westron/context/design-language/08-accessibility.md",
            "spec/components/rule/rule.spec.yaml": "skills/westron/context/components/rule.md",
        ]
        let text =
            "See [chapter 08](08-accessibility.md#targets), [decisions/0013](../decisions/0013-x.md), "
            + "[Rule](../spec/components/rule/rule.spec.yaml) and [the HIG](https://example.com/hig)."
        #expect(
            ContextMarkdown.rewritingLinks(
                text, from: "design-language/06-layout.md", to: "skills/westron/context/design-language/06-layout.md",
                map: map)
                == "See [chapter 08](08-accessibility.md#targets), decisions/0013, [Rule](../components/rule.md) and "
                + "[the HIG](https://example.com/hig).")
    }

    @Test("wrapped prose never starts a Markdown block and never breaks a code span")
    func wrap() {
        let lines = ContextMarkdown.wrap("aaaa - bbbb `c d` e", width: 6)
        #expect(lines == ["aaaa -", "bbbb", "`c d`", "e"])
        #expect(ContextMarkdown.wrap("one two", first: "- ", rest: "  ") == ["- one two"])
    }

    @Test("sentences end at a full stop before a capital, and a name counts only whole")
    func sentences() {
        #expect(
            ContextMarkdown.sentences("One. e.g. two. Three (x). `Four`.") == [
                "One. e.g. two.", "Three (x).", "`Four`.",
            ])
        #expect(ContextMarkdown.names("by container.gap.", "container.gap"))
        #expect(!ContextMarkdown.names("by container.gapX", "container.gap"))
        #expect(!ContextMarkdown.names("by subcontainer.gap", "container.gap"))
    }
}
