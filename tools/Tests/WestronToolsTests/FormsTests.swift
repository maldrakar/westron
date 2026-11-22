import Foundation
import Testing
import WestronTools

/// westron's Chip contract, the first with forms (#117): one look in three forms, each on its own base control
/// (`forms`, `platforms.<platform>.bases`), and cases that require several states at once (`state: { all: [...] }`).
/// Tests replace parts of it.
private let chipSource = "spec/components/chip/chip.spec.yaml"
private let chipFixture = try! String(
    contentsOf: repositoryRoot.appendingPathComponent(chipSource), encoding: .utf8)

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)
private let tokens = try! ContractTokens(
    Resolution(resolverFile: repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path))

/// The problems of a contract, as `place: message`.
private func chipProblems(_ yaml: String, source: String = chipSource) -> [String] {
    ContractCheck.check(yaml: yaml, source: source, schema: schema, tokens: tokens).map { "\($0.place): \($0.message)" }
}

/// A text with one part replaced, which must occur in it; the Chip contract by default.
private func replacing(_ old: String, with new: String, in text: String = chipFixture) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

/// Whether one problem is at `place` and its message contains `text`. Records the problems found when none is.
private func has(
    _ found: [String], _ place: String, _ text: String, sourceLocation: SourceLocation = #_sourceLocation
) -> Bool {
    let match = found.contains { $0.hasPrefix("\(place): ") && $0.contains(text) }
    if !match { Issue.record("problems: \(found)", sourceLocation: sourceLocation) }
    return match
}

/// The contract with `container.background`'s cases replaced by these lines.
private func backgroundCases(_ cases: String) -> String {
    let start = chipFixture.range(of: "  container.background:\n")!
    let end = chipFixture.range(of: "  container.opacity:\n")!
    return chipFixture.replacingCharacters(
        in: start.lowerBound..<end.lowerBound,
        with: "  container.background:\n    token: color.background.muted\n    cases:\n" + cases)
}

/// The generator's files for contracts by id, each in `<directory>/<id>/<id>.spec.yaml` of a fresh directory; or the
/// problems it throws.
private func generate(_ contracts: [String: String]) throws -> Result<[GeneratedFile], AppleComponents.Problems> {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("westron-forms-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    for (id, yaml) in contracts {
        let folder = directory.appendingPathComponent(id)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try yaml.write(to: folder.appendingPathComponent("\(id).spec.yaml"), atomically: true, encoding: .utf8)
    }
    let generator = AppleComponents(
        directory: directory.path,
        schemaFile: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path,
        resolverFile: repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path)
    do {
        return .success(try generator.run())
    } catch let error as AppleComponents.Problems {
        return .failure(error)
    }
}

private func contract(_ id: String) throws -> String {
    try String(
        contentsOf: repositoryRoot.appendingPathComponent("spec/components/\(id)/\(id).spec.yaml"), encoding: .utf8)
}

@Suite("Forms and cases over several states")
struct FormsTests {
    // MARK: - spec check

    @Test("westron's Chip contract, with forms, bases and cases over two states, is valid")
    func valid() {
        #expect(chipProblems(chipFixture) == [])
    }

    @Test("rule: a form enters only declared states, and every declared state is entered by some form")
    func formStates() {
        let unknown = chipProblems(
            replacing(
                "states: [hover, focus, pressed, disabled]\n    accessibility:",
                with: "states: [hover, focus, pressed, disabled, loading]\n    accessibility:"))
        #expect(has(unknown, "forms.pressable.states[4]", "\"loading\" is not one of the states"))
        let unentered = chipProblems(
            replacing(
                "    states: [checked, hover, focus, pressed, disabled]\n",
                with: "    states: [checked, hover, pressed, disabled]\n",
                in: replacing(
                    "states: [hover, focus, pressed, disabled]\n    accessibility:",
                    with: "states: [hover, pressed, disabled]\n    accessibility:")))
        #expect(has(unentered, "states[2]", "no form enters focus"))
    }

    @Test("rule: a form's accessibility, the contract's with the form's fields in their place, follows its rules")
    func formAccessibility() {
        // The static form without its own intents takes the contract's, [toggle], with a role of none.
        let intents = chipProblems(replacing("      role: none\n      intents: []\n", with: "      role: none\n"))
        #expect(has(intents, "accessibility.intents", "in this form the role is none"))
        // The pressable form without its own announced states takes the contract's, and does not enter checked.
        let announced = chipProblems(replacing("      states: { disabled: disabled }\n", with: ""))
        #expect(
            has(announced, "accessibility.states.checked", "\"checked\" is announced, and this form does not enter it"))
        // A form's own announced state it does not enter is reported at the form.
        let own = chipProblems(
            replacing("      states: { disabled: disabled }\n", with: "      states: { checked: selected }\n"))
        #expect(has(own, "forms.pressable.accessibility.states.checked", "this form does not enter it"))
    }

    @Test("rule: each platform names a base for every form and for no other, and no single base")
    func bases() {
        let missing = chipProblems(replacing("      static: SwiftUI.Label\n", with: ""))
        #expect(has(missing, "platforms.apple.bases", "no base for the form static"))
        let extra = chipProblems(
            replacing("      static: span\n", with: "      static: span\n      dismissible: button\n"))
        #expect(has(extra, "platforms.web.bases.dismissible", "\"dismissible\" is not one of the forms"))
        let both = chipProblems(
            replacing(
                "    strategy: style-on-system-control\n    bases:\n      selectable: SwiftUI.Toggle",
                with:
                    "    strategy: style-on-system-control\n    base: SwiftUI.Toggle\n    bases:\n      selectable: SwiftUI.Toggle"
            ))
        #expect(has(both, "platforms.apple.base", "the contract has forms, so each has its base in bases"))
    }

    @Test("rule: bases in a contract without forms is an error; a single base still works there")
    func basesWithoutForms() throws {
        let checkbox = try contract("checkbox")
        #expect(chipProblems(checkbox, source: "spec/components/checkbox/checkbox.spec.yaml") == [])
        let withBases = checkbox.replacingOccurrences(
            of: "    base: SwiftUI.Toggle\n", with: "    bases:\n      on: SwiftUI.Toggle\n      off: SwiftUI.Toggle\n")
        #expect(withBases != checkbox)
        let found = chipProblems(withBases, source: "spec/components/checkbox/checkbox.spec.yaml")
        #expect(has(found, "platforms.apple.bases", "the contract has no forms"))
    }

    @Test("rule: each form's base is checked as base is: known, and no option value a system style of it")
    func basesAreChecked() {
        let unknown = chipProblems(replacing("      static: SwiftUI.Label\n", with: "      static: SwiftUI.Badge\n"))
        #expect(
            has(
                unknown, "platforms.apple.bases.static",
                "the validator does not know the system styles of SwiftUI.Badge"))
        let shadowing = chipProblems(replacing("    values: [chip]\n", with: "    values: [chip, titleOnly]\n"))
        #expect(
            has(shadowing, "options.variant.values[1]", "\"titleOnly\" is the name of a system style of SwiftUI.Label"))
    }

    @Test("rule: on Apple the conventions derive forms only for a style on system controls")
    func formsNeedStyles() {
        let found = chipProblems(
            replacing(
                "  apple:\n    strategy: style-on-system-control\n",
                with: "  apple:\n    strategy: extension-on-system-control\n"))
        #expect(
            has(
                found, "platforms.apple.strategy",
                "the conventions derive forms on Apple only for a style-on-system-control"))
    }

    // MARK: - Cases over several states

    @Test("rule: a case over two states after a case over one of them is never used; before it, it is")
    func allStatesReachability() {
        #expect(
            chipProblems(
                backgroundCases(
                    """
                          - { when: { state: checked }, token: color.background.accent }
                          - { when: { state: { all: [checked, pressed] } }, token: color.background.accent-pressed }

                    """)) == [
                    "tokens.container.background.cases[1].when: cases[0] matches everything this case matches, so it "
                        + "is never used: put the narrower case first"
                ])
        // The narrower case first is reachable, and so is the wider one after it.
        #expect(
            chipProblems(
                backgroundCases(
                    """
                          - { when: { state: { all: [checked, pressed] } }, token: color.background.accent-pressed }
                          - { when: { state: checked }, token: color.background.accent }

                    """)) == [])
        // A case over any of two states covers a case over both at once.
        #expect(
            chipProblems(
                backgroundCases(
                    """
                          - { when: { state: [checked, pressed] }, token: color.background.accent }
                          - { when: { state: { all: [checked, pressed] } }, token: color.background.accent-pressed }

                    """)) == [
                    "tokens.container.background.cases[1].when: cases[0] matches everything this case matches, so it "
                        + "is never used: put the narrower case first"
                ])
        // Two cases over two states each do not cover a case over one of them: the chip in that state alone escapes.
        #expect(
            chipProblems(
                backgroundCases(
                    """
                          - { when: { state: { all: [checked, pressed] } }, token: color.background.accent-pressed }
                          - { when: { state: { all: [checked, hover] } }, token: color.background.accent-hover }
                          - { when: { state: checked }, token: color.background.accent }

                    """)) == [])
    }

    @Test("rule: a case over several states names declared states, two or more")
    func allStatesNames() {
        let unknown = chipProblems(
            backgroundCases(
                """
                      - { when: { state: { all: [checked, loading] } }, token: color.background.accent }

                """))
        #expect(has(unknown, "tokens.container.background.cases[0].when.state.all[1]", "loading"))
        let single = chipProblems(
            backgroundCases(
                """
                      - { when: { state: { all: [checked] } }, token: color.background.accent }

                """))
        #expect(single.contains { $0.hasPrefix("tokens.container.background.cases[0].when.state.all") }, "\(single)")
    }

    @Test("rule: a case over several states enumerates every set of the named states, held to the limit")
    func allStatesLimit() {
        // 15 more states, all named: 2^18 sets of states, past the limit of 20 000.
        let extra = (1...15).map { "s\($0)" }
        let yaml = replacing(
            "states: [checked, hover, focus, pressed, disabled]\n",
            with: "states: [checked, hover, focus, pressed, disabled, \(extra.joined(separator: ", "))]\n",
            in: replacing(
                "    states: [checked, hover, focus, pressed, disabled]\n    description: A filter",
                with: "    states: [checked, hover, focus, pressed, disabled, \(extra.joined(separator: ", "))]\n"
                    + "    description: A filter",
                in: backgroundCases(
                    """
                          - { when: { state: { all: [checked, \(extra.joined(separator: ", "))] } }, token: color.background.accent }
                          - { when: { state: [pressed, hover] }, token: color.background.muted-pressed }

                    """)))
        #expect(
            chipProblems(yaml) == [
                "tokens.container.background.cases: the cases name too many combinations of option values and sets "
                    + "of states to check that each is used (262144, at most 20000)"
            ])
    }

    // MARK: - The generators

    @Test("Chip generates one overload per form's base, each applying its own style, and the forms' type")
    func api() throws {
        let file = try #require(
            try AppleComponents.file(for: ComponentContract(yaml: chipFixture, source: chipSource), source: chipSource))
        let swift = file.contents
        #expect(file.path.hasSuffix("/Chip+Contract.swift"))
        #expect(
            swift.contains(
                "    public func toggleStyle(_ variant: ChipVariant) -> some View {\n"
                    + "        toggleStyle(ChipToggleStyle(variant: variant))\n"))
        #expect(
            swift.contains(
                "    public func buttonStyle(_ variant: ChipVariant) -> some View {\n"
                    + "        buttonStyle(ChipButtonStyle(variant: variant))\n"))
        #expect(
            swift.contains(
                "    public func labelStyle(_ variant: ChipVariant) -> some View {\n"
                    + "        labelStyle(ChipLabelStyle(variant: variant))\n"))
        #expect(
            swift.contains(
                "package enum ChipForm: String, CaseIterable, Sendable {\n    case selectable\n"
                    + "    case pressable\n    case `static`\n"))
        #expect(swift.contains("        case .pressable: [.hover, .focus, .pressed, .disabled]\n"))
        #expect(swift.contains("        case .static: []\n"))
        #expect(!swift.contains("ChipVariantStyle"))
    }

    @Test("Chip generates beside Button and Checkbox, whose modifiers it shares; a shared variant value fails")
    func sharedModifiers() throws {
        let contracts = ["chip": chipFixture, "button": try contract("button"), "checkbox": try contract("checkbox")]
        guard case .success(let files) = try generate(contracts) else {
            Issue.record("generation failed")
            return
        }
        #expect(files.map { $0.path.split(separator: "/").last ?? "" }.contains("Chip+Contract.swift"))
        let clash = chipFixture.replacingOccurrences(of: "    values: [chip]\n", with: "    values: [chip, primary]\n")
        guard case .failure(let error) = try generate(["chip": clash, "button": try contract("button")]) else {
            Issue.record("a variant Chip shares with Button generated")
            return
        }
        #expect(error.problems.map(\.message).contains { $0.contains(".buttonStyle(.primary) would be ambiguous") })
    }

    @Test("two forms on bases of one style modifier fail generation: their overloads would have one signature")
    func twoFormsOneModifier() throws {
        let twice = replacing("      pressable: SwiftUI.Button\n", with: "      pressable: SwiftUI.Toggle\n")
        guard case .failure(let error) = try generate(["chip": twice]) else {
            Issue.record("two forms on one modifier generated")
            return
        }
        #expect(
            error.problems.map(\.message).contains {
                $0.contains("two forms of Chip are on bases styled by .toggleStyle")
            })
    }

    @Test("Chip's matrix: the form first, each form a sheet of rest and the states it enters")
    func matrix() throws {
        let matrix = try SnapshotMatrix(ComponentContract(yaml: chipFixture, source: chipSource), source: chipSource)
        #expect(matrix.axes.map(\.name) == ["form", "variant"])
        #expect(matrix.axes[0].isForm && matrix.axes[0].values == ["selectable", "pressable", "static"])
        #expect(matrix.columnAxis == "variant")
        #expect(matrix.combinations.count == 6 + 5 + 1)
        #expect(matrix.sheets.map(\.id) == ["form-selectable", "form-pressable", "form-static"])
        #expect(
            matrix.sheets.map(\.rows) == [
                [nil, "checked", "hover", "focus", "pressed", "disabled"],
                [nil, "hover", "focus", "pressed", "disabled"],
                [nil],
            ])
        #expect(!matrix.combinations.contains { $0.values[0] == "static" && $0.state != nil })
        #expect(matrix.unboundStates == ["focus"])
        // An option named like the forms' axis would make two axes of one name.
        let named = replacing(
            "slots: [label, icon]\n", with: "slots: [label, icon]\n",
            in: replacing(
                "options:\n", with: "options:\n  form:\n    type: enum\n    values: [a, b]\n"))
        #expect(throws: ContractProblem.self) {
            try SnapshotMatrix(ComponentContract(yaml: named, source: chipSource), source: chipSource)
        }
    }

    @Test("the API parity lint expects Chip's three overloads and no state modifier, every state being its base's")
    func apiParity() throws {
        let directory = repositoryRoot.appendingPathComponent(ContractCheck.defaultDirectory).path
        let sources = repositoryRoot.appendingPathComponent(APIParity.defaultSources).path
        let report = try APIParity.run(contractsDirectory: directory, sourceRoot: sources)
        #expect(report.problems.isEmpty, "\(report.problems)")
        // Without the generated label style overload, the lint reports the static form's.
        let item = APIParity.Contract(
            contract: try ComponentContract(yaml: chipFixture, source: chipSource), source: chipSource,
            text: chipFixture)
        let generated = try #require(
            try AppleComponents.file(for: item.contract, source: chipSource)
        ).contents
        let withoutLabel = generated.replacingOccurrences(
            of: "    public func labelStyle(_ variant: ChipVariant) -> some View {\n"
                + "        labelStyle(ChipLabelStyle(variant: variant))\n    }\n", with: "")
        #expect(withoutLabel != generated)
        let found = APIParity.check(
            contracts: [item], files: [(path: "\(sources)/Generated/Chip+Contract.swift", text: withoutLabel)],
            sourceRoot: sources
        ).problems.map(\.description)
        #expect(found.contains { $0.contains("Chip's style overload for its form static") }, "\(found)")
        #expect(!found.contains { $0.contains("the state modifier of") }, "\(found)")
    }
}
