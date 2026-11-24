import Foundation
import Testing
import WestronTools

/// A Checkbox-shaped contract with a label that may not be drawn: a style on `SwiftUI.Toggle`, a required label, the
/// slot `label`.
private let checkFixture = """
    id: check
    status: approved
    consumers: [todo-app/list-screen]
    options:
      variant: { type: enum, values: [round] }
    slots: [label]
    states: [checked]
    accessibility:
      role: checkbox
      label: required
      hiddenLabel: true
    platforms:
      apple: { strategy: style-on-system-control, base: SwiftUI.Toggle }
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let checkSource = "spec/components/check/check.spec.yaml"

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

private func problems(_ yaml: String) -> [String] {
    ContractCheck.check(yaml: yaml, source: checkSource, schema: schema, tokens: ContractTokens(everywhere: []))
        .map { "\($0.place): \($0.message)" }
}

private func replacing(_ old: String, with new: String, in text: String = checkFixture) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

private let root = "WestronUI"

/// The fixture module: the generated file of the fixture contract, and the hand-written initializers.
private func lint(_ initializers: String, yaml: String = checkFixture) throws -> [String] {
    let contract = try ComponentContract(yaml: yaml, source: checkSource)
    let files =
        try generatedSources(contract, source: checkSource)
        + [(path: "\(root)/Check/Toggle+AccessibilityLabel.swift", text: initializers)]
    let item = APIParity.Contract(contract: contract, source: checkSource, text: yaml)
    return APIParity.check(contracts: [item], files: files, sourceRoot: root, contractRoot: "WestronContract").problems
        .map(\.description)
}

/// What WestronUI declares for Checkbox's check with no drawn label.
private let initializersSwift = """
    import SwiftUI

    extension Toggle where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier> {
        public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey) {
            self.init(isOn: isOn) { EmptyView().accessibilityLabel(Text(accessibilityLabel)) }
        }

        @_disfavoredOverload
        public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S) {
            self.init(isOn: isOn) { EmptyView().accessibilityLabel(Text(accessibilityLabel)) }
        }
    }

    """

private func changing(_ old: String, _ new: String) -> String {
    replacing(old, with: new, in: initializersSwift)
}

@Suite("A label that is not drawn")
struct HiddenLabelTests {
    @Test("the model reads accessibility.hiddenLabel, false when absent")
    func model() throws {
        #expect(try ComponentContract(yaml: checkFixture, source: checkSource).hiddenLabel)
        let without = replacing("  hiddenLabel: true\n", with: "")
        #expect(try !ComponentContract(yaml: without, source: checkSource).hiddenLabel)
        #expect(
            try AppleComponents.HiddenLabel(ComponentContract(yaml: without, source: checkSource), source: "") == nil)
    }

    @Test("a hidden label on a Toggle style with a required label and the slot label is valid")
    func valid() {
        #expect(problems(checkFixture) == [])
    }

    @Test("rule: a hidden label needs a required label, the slot label, and on Apple a base the conventions derive")
    func rules() {
        #expect(
            problems(replacing("label: required\n", with: "label: optional\n")) == [
                "accessibility.hiddenLabel: a label that is not drawn is still the component's accessible name, so "
                    + "every instance has one: make accessibility.label required"
            ])
        #expect(
            problems(replacing("slots: [label]\n", with: "")) == [
                "accessibility.hiddenLabel: a label that is not drawn is the contract's label slot, and it has none: "
                    + "add label to slots"
            ])
        let button = replacing("base: SwiftUI.Toggle", with: "base: SwiftUI.Button")
        #expect(
            problems(button).contains(
                "accessibility.hiddenLabel: the conventions derive the initializer of a control with no drawn label "
                    + "only for a style-on-system-control on a base with its parameters in "
                    + "SystemStyles.Base.hiddenLabelParameters (today SwiftUI.Toggle), not for SwiftUI.Button yet "
                    + "(spec/conventions.md, \"A label that is not drawn\")"))
        // Apple planned: nothing to derive there.
        #expect(
            problems(
                replacing(
                    "apple: { strategy: style-on-system-control, base: SwiftUI.Toggle }",
                    with: "apple: { status: planned }"))
                == [])
        // Not a boolean: the schema.
        #expect(!problems(replacing("hiddenLabel: true", with: "hiddenLabel: yes please")).isEmpty)
    }

    @Test("the conventions derive Toggle's two initializers")
    func derivation() throws {
        let api = try #require(
            try AppleComponents.HiddenLabel(ComponentContract(yaml: checkFixture, source: checkSource), source: ""))
        #expect(api.control == "Toggle")
        #expect(api.requirement == "where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier>")
        #expect(
            api.initializers.map(\.declaration) == [
                "public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey)",
                "@_disfavoredOverload public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S)",
            ])
    }

    @Test("the lint accepts the initializers as the conventions give them")
    func lintPasses() throws {
        #expect(try lint(initializersSwift) == [])
    }

    @Test("the lint reports an initializer missing, changed, unconstrained, preferred equally or internal")
    func lintReports() throws {
        let file = "\(root)/Check/Toggle+AccessibilityLabel.swift"
        let missing = try lint("import SwiftUI\n")
        #expect(missing.count == 2)
        let expectedMissing: String =
            "\(checkSource):11: missing: `extension Toggle where Label == ModifiedContent<EmptyView, "
            + "AccessibilityAttachmentModifier> { public init(isOn: Binding<Bool>, accessibilityLabel: "
            + "LocalizedStringKey) }`, which Check's contract (\(checkSource)) gives for a label that is not drawn "
            + "(spec/conventions.md, \"A label that is not drawn\")"
        #expect(missing.contains(expectedMissing))

        let renamed = try lint(changing("accessibilityLabel: LocalizedStringKey)", "label: LocalizedStringKey)"))
        #expect(renamed.count == 2, "\(renamed)")
        #expect(renamed.contains { $0.hasPrefix("\(checkSource):11: missing: ") && $0.contains("LocalizedStringKey") })
        #expect(renamed.contains { $0.hasPrefix("\(file):4: public init Toggle.init: public API outside") })

        let otherLabel = try lint(
            changing(
                "where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier>", "where Label == Text"))
        #expect(otherLabel.count == 2)
        #expect(otherLabel.allSatisfy { $0.contains("differs from the contract") })

        let preferred = try lint(changing("    @_disfavoredOverload\n", ""))
        #expect(preferred.count == 1)
        #expect(preferred[0].hasPrefix("\(file):8: Toggle's initializer for a label that is not drawn differs"))

        let internalInit = try lint(
            changing(
                "    public init(isOn: Binding<Bool>, accessibilityLabel: L",
                "    init(isOn: Binding<Bool>, accessibilityLabel: L"))
        #expect(
            internalInit == [
                "\(file):4: Toggle.init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey), which Check's "
                    + "contract (\(checkSource)) gives for a label that is not drawn, is internal; the conventions make "
                    + "it public"
            ])

        // A third public initializer on Toggle is API no contract gives.
        let third = try lint(
            initializersSwift
                + "extension Toggle where Label == Text {\n    public init(isOn: Binding<Bool>, hidden: String) {\n"
                + "        self.init(hidden, isOn: isOn)\n    }\n}\n")
        #expect(third.count == 1)
        #expect(third[0].contains("public init Toggle.init: public API outside"))
    }

    @Test("without hiddenLabel the initializers are API no contract gives")
    func withoutTheField() throws {
        let found = try lint(initializersSwift, yaml: replacing("  hiddenLabel: true\n", with: ""))
        #expect(found.count == 2)
        #expect(found.allSatisfy { $0.contains("public init Toggle.init: public API outside") })
    }
}
