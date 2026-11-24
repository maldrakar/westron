import Foundation
import Testing

@testable import WestronTools

/// A style on the system button with every kind of option a card describes: a variant with no default, a size, a bool,
/// a state the button lacks, a constraint. It is not one of westron's contracts.
private let pillYAML = """
    id: pill
    status: approved
    description: >-
      A small pressable pill. It holds a short label.
    consumers: [todo-app/list-screen]
    options:
      variant:
        type: enum
        values: [solid, quiet]
        description: The fill.
      size: { type: enum, values: [s, m], default: m }
      compact: { type: bool, default: false, description: Less padding. }
    slots: [label, icon]
    states: [hover, pressed, disabled, loading]
    constraints:
      - when: { compact: true }
        require: { size: [s] }
        severity: error
        description: A compact pill is small.
    accessibility:
      role: button
      intents: [activate]
      keyboardIntents: [activate]
      label: required
      states: { disabled: disabled, loading: busy }
      description: The label names the action.
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

private func pillCard() throws -> String {
    let sources = AgentContext.Sources(
        contracts: [(pillYAML, pillSource)],
        icons: IconRegistry(icons: [.init(name: "tray", description: "A tray.", apple: "tray")], fallback: "tray"),
        conventions: "", chapters: [], readme: nil)
    let cards = try AgentContext.cards(sources, textRoles: ["body.regular"])
    try #require(cards.count == 1)
    return cards[0].markdown()
}

/// The generator over this repository's sources.
private func generator() -> AgentContext {
    func path(_ relative: String) -> String { repositoryRoot.appendingPathComponent(relative).path }
    return AgentContext(
        contractsDirectory: path(ContractCheck.defaultDirectory), schemaFile: path(ContractSchema.defaultFile),
        resolverFile: path(TokenCheck.defaultResolver), iconsFile: path(IconRegistry.defaultFile),
        conventionsFile: path(AgentContext.conventionsFile),
        designLanguageDirectory: path(AgentContext.designLanguageDirectory))
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

    @Test("writes inside its owned directory, and llms.txt at the root")
    func paths() throws {
        for file in try generator().run() where file.path != AgentContext.llmsFile {
            #expect(file.path.hasPrefix(AgentContext.outputDirectory + "/"), "\(file.path)")
        }
        #expect(AgentContext().ownedDirectories == [AgentContext.outputDirectory])
    }

    @Test("the index and llms.txt list every contract, each with its card")
    func indexListsEveryContract() throws {
        let files = try generator().run()
        let index = try #require(files.first { $0.path == AgentContext.outputDirectory + "/index.md" })
        let llms = try #require(files.first { $0.path == AgentContext.llmsFile })
        let contracts = try ContractCheck.files(
            in: repositoryRoot.appendingPathComponent(ContractCheck.defaultDirectory).path)
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
        #expect(index.contents.split(separator: "\n").count < 80)
    }

    @Test("a card has the call, the declarations, the options, the states and the constraints")
    func card() throws {
        let card = try pillCard()
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
        // The options, with their values, defaults and descriptions.
        #expect(card.contains("- `variant`, `PillVariant`: `.solid`, `.quiet`; no default. The fill."))
        #expect(card.contains("- `size`, `PillSize?`: `.s`, `.m`; left out, the size comes from `controlSize`"))
        #expect(card.contains("- `compact`, `Bool`: by default `false`. Less padding."))
        // The states: the system's, and the one westron's modifier sets; one an OS never enters.
        #expect(card.contains("- `loading`: `.loading(_:)`, westron's modifier"))
        #expect(card.contains("- `disabled`: `.disabled(_:)`, the system's."))
        // A list item's lines joined, as Markdown reads them.
        let items = card.replacingOccurrences(of: "\n  ", with: " ")
        #expect(
            items.contains(
                "- `hover`: the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it. Never entered on watchOS."
            ))
        // What the caller owes accessibility, and the constraint.
        #expect(card.contains("**The caller gives every instance a label**"))
        #expect(card.contains("The label names the action."))
        #expect(card.contains("- **Never**: `compact: true` with `size` other than `.s`. A compact pill is small."))
        // The rest of the description, and the Apple entry; no token bindings.
        #expect(card.contains("## Behavior\n\nIt holds a short label."))
        #expect(card.contains("## On Apple\n\nA style on the system button."))
        #expect(!card.contains("container."))
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
}
