import Foundation
import Testing
import WestronTools

/// A Rule-shaped own view with a drawn text label (#116): two enum options, the one slot label, and a constraint on
/// the slot that fixes both options for a labelled instance. It follows westron's Rule contract, but it is not that
/// contract.
private let labelledYAML = """
    id: rule
    status: approved
    consumers: [todo-app/lists-screen]
    options:
      axis: { type: enum, values: [horizontal, vertical], default: horizontal }
      purpose: { type: enum, values: [separator, insertion], default: separator }
    slots: [label]
    constraints:
      - { when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, severity: error }
    accessibility: { role: heading, label: optional }
    platforms:
      apple:
        strategy: own-component
        form: view
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let labelledSource = "spec/components/rule/rule.spec.yaml"

private func labelledContract(_ yaml: String = labelledYAML) throws -> ComponentContract {
    try ComponentContract(yaml: yaml, source: labelledSource)
}

private func replacing(_ old: String, with new: String, in text: String = labelledYAML) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

private func specProblems(_ yaml: String) -> [String] {
    ContractCheck.check(yaml: yaml, source: labelledSource, schema: schema, tokens: ContractTokens(everywhere: []))
        .map { "\($0.place): \($0.message)" }
}

/// The hand-written view the contract gives.
private let ruleSwift = """
    import SwiftUI

    public struct Rule: View {
        let axis: RuleAxis
        let purpose: RulePurpose
        let label: Text?

        public init(axis: RuleAxis = .horizontal, purpose: RulePurpose = .separator) {
            self.axis = axis
            self.purpose = purpose
            label = nil
        }

        public init(_ label: LocalizedStringKey) {
            axis = .horizontal
            purpose = .separator
            self.label = Text(label)
        }

        @_disfavoredOverload
        public init<S: StringProtocol>(_ label: S) {
            axis = .horizontal
            purpose = .separator
            self.label = Text(label)
        }

        public var body: some View {
            Rectangle()
        }
    }

    """

private func parity(_ swift: String, yaml: String = labelledYAML) throws -> [String] {
    var sources: [(path: String, text: String)] = []
    if let file = try AppleComponents.file(for: try labelledContract(yaml), source: labelledSource) {
        sources.append(("WestronUI/Generated/Rule+Contract.swift", file.contents))
    }
    sources.append(("WestronUI/Rule/Rule.swift", swift))
    return APIParity.check(
        contracts: [APIParity.Contract(contract: try labelledContract(yaml), source: labelledSource, text: yaml)],
        files: sources, sourceRoot: "WestronUI"
    ).problems.map(\.description)
}

@Suite("An own view with a drawn text label, and a constraint on a slot")
struct LabelledViewTests {
    // MARK: - The constraint on a slot (spec check)

    @Test("the contract is valid, and the constraint reads as a rule on the slot")
    func valid() throws {
        #expect(specProblems(labelledYAML) == [])
        let constraint = try #require(try labelledContract().constraints.first)
        #expect(constraint.slots == ["label"])
        #expect(constraint.when.isEmpty)
        #expect(constraint.require == ["axis": ["horizontal"], "purpose": ["separator"]])
        #expect(constraint.forbids)
        // One slot as a single name reads the same.
        let single = try labelledContract(replacing("slots: [label] }", with: "slots: label }"))
        #expect(single.constraints.first?.slots == ["label"])
    }

    @Test("a combination of options fills no slot, so it never breaks a rule on one")
    func neverBrokenByOptions() throws {
        let constraint = try #require(try labelledContract().constraints.first)
        #expect(!constraint.isBroken(by: ["axis": "vertical", "purpose": "insertion"]))
        #expect(!constraint.isBroken(by: ["axis": "horizontal", "purpose": "separator"]))
        // The matrix keeps every combination: the matrix draws no slot.
        let matrix = try SnapshotMatrix(try labelledContract(), source: labelledSource)
        #expect(matrix.combinations.count == 4)
        #expect(matrix.excluded.isEmpty && matrix.advisedAgainst.isEmpty)
    }

    @Test("a constraint on slots is as narrow as what the conventions derive from it")
    func narrow() {
        #expect(
            specProblems(replacing("slots: [label] }", with: "slots: [icon] }")) == [
                "constraints[0].when.slots[0]: \"icon\" is not one of the slots: label"
            ])
        #expect(
            specProblems(replacing("slots: [label] }", with: "slots: [label], axis: vertical }")) == [
                "constraints[0].when: a constraint on slots names no option in its when: the conventions derive no "
                    + "API from both"
            ])
        #expect(
            specProblems(replacing("severity: error", with: "severity: warning")) == [
                "constraints[0].severity: a constraint on slots forbids (error): the conventions derive no API from "
                    + "advice"
            ])
        #expect(
            specProblems(replacing("axis: horizontal, purpose", with: "axis: [horizontal, vertical], purpose")) == [
                "constraints[0].require.axis: a constraint on slots gives axis one value, which an instance that "
                    + "fills them takes"
            ])
        // The required values are checked as any constraint's are.
        let unknown = specProblems(replacing("purpose: separator }, severity", with: "purpose: other }, severity"))
        #expect(unknown.count == 1)
        #expect(unknown.first?.contains("\"other\" is not one of the values of purpose") == true)
        // A slot is named only in a when.
        #expect(
            specProblems(replacing("purpose: separator }, severity", with: "slots: [label] }, severity")).contains {
                $0.hasPrefix("constraints[0].require.slots:")
            })
        // No slots declared at all.
        #expect(
            specProblems(replacing("slots: [label]\n", with: "")).contains(
                "constraints[0].when.slots[0]: \"label\": the contract declares no slots"))
        // `slots` is the key of a constraint's when: no option takes it.
        #expect(
            specProblems(
                replacing(
                    "  purpose: { type",
                    with: "  slots: { type: enum, values: [a, b], default: a }\n  purpose: { type")
            ).contains(
                "options.slots: \"slots\" names the slots in a constraint's when; give the option another name"))
    }

    @Test("a constraint on a slot is an error on a contract the conventions derive nothing from it for")
    func onlyWhereDerived() {
        let notDerived =
            "constraints[0].when.slots: a constraint on slots is derived only for an Apple own-component of form view "
            + "whose one slot is label, drawn text, with no option whose values are icons (spec/conventions.md, "
            + "\"Own components\"): the conventions derive no API from it on this contract yet"
        // Rule's shape stays valid.
        #expect(!specProblems(labelledYAML).contains(notDerived))
        // A style on a system control.
        #expect(
            specProblems(
                replacing(
                    "strategy: own-component\n    form: view",
                    with: "strategy: style-on-system-control\n    base: SwiftUI.Button")
            ).contains(notDerived))
        // A modifier.
        #expect(specProblems(replacing("form: view", with: "form: modifier")) == [notDerived])
        // An icon's view, whose label is spoken, not drawn.
        #expect(
            specProblems(replacing("options:\n", with: "options:\n  glyph: { type: icons }\n")) == [notDerived])
        // A view with another slot beside label.
        #expect(specProblems(replacing("slots: [label]\n", with: "slots: [label, icon]\n")) == [notDerived])
        // The same view without the constraint on the slot has nothing to report.
        #expect(
            specProblems(
                replacing(
                    "constraints:\n  - { when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, "
                        + "severity: error }\n", with: "", in: replacing("form: view", with: "form: modifier"))
            ) == [])
    }

    // MARK: - The API (generation)

    @Test("its API: every option without a label; the label first, unlabeled, without the options it fixes")
    func api() throws {
        let api = try AppleComponents.Own(try labelledContract(), source: labelledSource)
        #expect(api.form == .view && api.name == "Rule")
        #expect(api.enums.map(\.type) == ["RuleAxis", "RulePurpose"])
        #expect(
            api.initializers.map(\.declaration) == [
                "public init(axis: RuleAxis = .horizontal, purpose: RulePurpose = .separator)",
                "public init(_: LocalizedStringKey)",
                "@_disfavoredOverload public init<S: StringProtocol>(_: S)",
            ])
        #expect(api.signatureName == "Rule.init(axis:purpose:)")
    }

    @Test("an option the slot's constraint does not fix stays in the label's initializers")
    func unfixedOption() throws {
        let api = try AppleComponents.Own(
            try labelledContract(
                replacing("require: { axis: horizontal, purpose: separator }", with: "require: { axis: horizontal }")),
            source: labelledSource)
        #expect(
            api.initializers.map(\.declaration) == [
                "public init(axis: RuleAxis = .horizontal, purpose: RulePurpose = .separator)",
                "public init(_: LocalizedStringKey, purpose: RulePurpose = .separator)",
                "@_disfavoredOverload public init<S: StringProtocol>(_: S, purpose: RulePurpose = .separator)",
            ])
        // Without the constraint, every option.
        let free = try AppleComponents.Own(
            try labelledContract(
                replacing(
                    "constraints:\n  - { when: { slots: [label] }, require: { axis: horizontal, purpose: separator }, "
                        + "severity: error }\n", with: "")),
            source: labelledSource)
        #expect(
            free.initializers[1].declaration
                == "public init(_: LocalizedStringKey, axis: RuleAxis = .horizontal, purpose: RulePurpose = .separator)"
        )
    }

    @Test("a required label leaves out the initializer without one")
    func requiredLabel() throws {
        let api = try AppleComponents.Own(
            try labelledContract(replacing("label: optional", with: "label: required")), source: labelledSource)
        #expect(
            api.initializers.map(\.declaration) == [
                "public init(_: LocalizedStringKey)", "@_disfavoredOverload public init<S: StringProtocol>(_: S)",
            ])
    }

    @Test("the generated file names both enums and the hand-written view")
    func generatedFile() throws {
        let file = try #require(try AppleComponents.file(for: try labelledContract(), source: labelledSource))
        #expect(file.contents.contains("public enum RulePurpose: String, CaseIterable, Sendable {"))
        #expect(file.contents.contains("    case separator\n    case insertion\n}"))
    }

    // MARK: - The API parity lint

    @Test("the lint accepts the view, and reports a label initializer that takes a fixed option")
    func lint() throws {
        #expect(try parity(ruleSwift) == [])

        let withAxis = try parity(
            ruleSwift.replacingOccurrences(
                of: "public init(_ label: LocalizedStringKey) {",
                with: "public init(_ label: LocalizedStringKey, axis: RuleAxis = .horizontal) {"))
        #expect(withAxis.count == 1)
        #expect(
            withAxis.first?.contains(
                "Rule's initializer differs from the contract: expected `init(_: LocalizedStringKey)`") == true)

        let missingVerbatim = try parity(
            ruleSwift.replacingOccurrences(
                of: """
                        @_disfavoredOverload
                        public init<S: StringProtocol>(_ label: S) {
                            axis = .horizontal
                            purpose = .separator
                            self.label = Text(label)
                        }

                    """, with: ""))
        #expect(missingVerbatim.count == 1)
        #expect(
            missingVerbatim.first?.contains(
                "missing: `@_disfavoredOverload public init<S: StringProtocol>(_: S)` in Rule") == true)
    }
}
