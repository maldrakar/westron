import Foundation
import Testing
import WestronTools

/// A ListRow-shaped own view (#119): an integer option and a bool, four slots, states of its own and of the shared
/// environment modifiers, two forms with and without an action, a mark with an enum and an integer parameter, and a
/// watchOS that enters fewer states. It follows westron's ListRow contract, but it is not that contract.
private let rowYAML = """
    id: list-row
    status: approved
    consumers: [todo-app/lists-screen]
    options:
      level: { type: integer, default: 0, minimum: 0 }
      guides: { type: bool, default: true }
    slots: [title, subtitle, leading, trailing]
    states: [hover, focus, pressed, selected, disabled, dropTarget]
    forms:
      pressable:
        states: [hover, focus, pressed, selected, disabled, dropTarget]
      static:
        states: [selected, disabled, dropTarget]
        accessibility: { role: none, intents: [], keyboardIntents: [], label: optional, states: {} }
    marks:
      insertion:
        parameters:
          edge: { type: enum, values: [top, bottom] }
          level: { type: integer, default: 0, minimum: 0 }
    accessibility:
      role: button
      intents: [activate]
      keyboardIntents: [activate]
      label: required
      states: { selected: selected, disabled: disabled }
    platforms:
      apple:
        strategy: own-component
        form: view
        watchos:
          states: [pressed, selected, disabled]
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let rowSource = "spec/components/list-row/list-row.spec.yaml"

private func replacing(_ old: String, with new: String, in text: String = rowYAML) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

private func rowContract(_ yaml: String = rowYAML) throws -> ComponentContract {
    try ComponentContract(yaml: yaml, source: rowSource)
}

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

private func specProblems(_ yaml: String) -> [String] {
    ContractCheck.check(yaml: yaml, source: rowSource, schema: schema, tokens: ContractTokens(everywhere: []))
        .map { "\($0.place): \($0.message)" }
}

private func failure(_ yaml: String) -> String? {
    do {
        _ = try AppleComponents.Own(try rowContract(yaml), source: rowSource)
        return nil
    } catch {
        return "\(error)"
    }
}

/// The hand-written view and modifiers the contract gives.
private let rowSwift = """
    import SwiftUI

    public struct ListRow: View {
        public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
            level: Int = 0, guides: Bool = true, action: @escaping () -> Void, @ViewBuilder title: () -> Title,
            @ViewBuilder subtitle: () -> Subtitle = { EmptyView() }, @ViewBuilder leading: () -> Leading = { EmptyView() },
            @ViewBuilder trailing: () -> Trailing = { EmptyView() }
        ) {}

        public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
            level: Int = 0, guides: Bool = true, @ViewBuilder title: () -> Title,
            @ViewBuilder subtitle: () -> Subtitle = { EmptyView() }, @ViewBuilder leading: () -> Leading = { EmptyView() },
            @ViewBuilder trailing: () -> Trailing = { EmptyView() }
        ) {}

        public var body: some View { EmptyView() }
    }

    extension View {
        public func insertionMark(_ edge: ListRowInsertionEdge?, level: Int = 0) -> some View { self }
        public func selected(_ isSelected: Bool) -> some View { self }
        public func dropTarget(_ isDropTarget: Bool) -> some View { self }
    }

    """

private let root = "/westron/WestronUI"

private func parity(_ swift: String = rowSwift, yaml: String = rowYAML) throws -> [String] {
    let generated = try generatedSources(try rowContract(yaml), source: rowSource, prefix: "/westron/")
    return APIParity.check(
        contracts: [APIParity.Contract(contract: try rowContract(yaml), source: rowSource, text: yaml)],
        files: [("\(root)/ListRow/ListRow.swift", swift)] + generated,
        sourceRoot: root, contractRoot: "/westron/WestronContract"
    ).problems.map(\.description)
}

@Suite("An own view with slots, forms, states, an integer option and a mark")
struct OwnViewSlotsTests {
    // MARK: - The contract

    @Test("an integer option and a mark parse, with their defaults and minimums")
    func parses() throws {
        let contract = try rowContract()
        #expect(contract.options.first?.kind == .integer(default: 0, minimum: 0))
        #expect(contract.marks.map(\.name) == ["insertion"])
        #expect(contract.marks[0].parameters.map(\.name) == ["edge", "level"])
        #expect(contract.marks[0].parameters[1].kind == .integer(default: 0, minimum: 0))
        #expect(contract.forms.map(\.activates) == [true, false])
        #expect(specProblems(rowYAML) == [])
    }

    @Test("an integer option is no axis of the matrix, and the forms are the initializers the cell calls")
    func matrix() throws {
        let matrix = try SnapshotMatrix(try rowContract(), source: rowSource)
        #expect(matrix.axes.map(\.name) == ["form", "guides"])
        #expect(matrix.ownForms)
        let files = try AppleSnapshotMatrix.files(for: [(try rowContract(), rowSource)])
        #expect(files.contains { $0.contents.contains("the initializer the cell calls") })
    }

    @Test("an integer option is no value a case, a constraint, a restriction or a system option can name")
    func integerRules() {
        let inCase = replacing(
            "states: [hover, focus, pressed, selected, disabled, dropTarget]\nforms:",
            with: "states: [hover, focus, pressed, selected, disabled, dropTarget]\n"
                + "constraints:\n  - { when: { level: 1 }, require: { guides: true }, severity: error }\nforms:")
        #expect(
            specProblems(inCase).contains { $0.contains("level") && $0.contains("integer") }, "\(specProblems(inCase))")
        let below = replacing(
            "level: { type: integer, default: 0, minimum: 0 }\n  guides",
            with: "level: { type: integer, default: -1, minimum: 0 }\n  guides")
        #expect(
            specProblems(below).contains { $0.contains("options.level") && $0.contains("minimum") },
            "\(specProblems(below))")
    }

    @Test("a mark's rules: a default among its values, and an integer's default at its minimum or above")
    func markRules() {
        let badDefault = replacing(
            "edge: { type: enum, values: [top, bottom] }",
            with: "edge: { type: enum, values: [top, bottom], default: middle }")
        #expect(specProblems(badDefault).contains { $0.contains("marks.insertion") }, "\(specProblems(badDefault))")
        let repeated = replacing("values: [top, bottom]", with: "values: [top, top]")
        #expect(specProblems(repeated).contains { $0.contains("marks.insertion") }, "\(specProblems(repeated))")
        let markBelow = replacing(
            "      level: { type: integer, default: 0, minimum: 0 }",
            with: "      level: { type: integer, default: -1, minimum: 0 }")
        #expect(specProblems(markBelow).contains { $0.contains("marks.insertion") }, "\(specProblems(markBelow))")
    }

    @Test("an own component's forms name no bases, and only an own view has forms")
    func formsWithoutBases() {
        #expect(specProblems(rowYAML) == [])
        let based = replacing(
            "    form: view\n",
            with: "    form: view\n    bases: { pressable: SwiftUI.Button, static: SwiftUI.Button }\n")
        #expect(
            specProblems(based).contains { $0.contains("has no base control") }, "\(specProblems(based))")
        let modifier = replacing("    form: view\n", with: "    form: modifier\n")
        #expect(
            specProblems(modifier).contains { $0.contains("only of form view") }, "\(specProblems(modifier))")
    }

    // MARK: - The API

    @Test("each form is an initializer: the options, an action for the form that activates, then every slot")
    func initializers() throws {
        let own = try AppleComponents.Own(try rowContract(), source: rowSource)
        let generics = ["<Title: View, Subtitle: View, Leading: View, Trailing: View>"]
        let slots =
            "title: () -> Title, subtitle: () -> Subtitle = { EmptyView() }, leading: () -> Leading = { "
            + "EmptyView() }, trailing: () -> Trailing = { EmptyView() }"
        #expect(own.initializers.count == 2)
        #expect(own.initializers.allSatisfy { $0.extras == generics })
        #expect(
            own.initializers[0].description
                == "init\(generics[0])(level: Int = 0, guides: Bool = true, action: @escaping () -> Void, \(slots))")
        #expect(own.initializers[1].description == "init\(generics[0])(level: Int = 0, guides: Bool = true, \(slots))")
    }

    @Test("the states: the view's own, the shared modifiers', and those watchOS never enters")
    func states() throws {
        let own = try AppleComponents.Own(try rowContract(), source: rowSource)
        #expect(own.modifierStates == ["selected", "dropTarget"])
        #expect(own.skippedStates.map(\.os) == ["watchos"])
        #expect(own.skippedStates.map(\.states) == [["hover", "focus", "dropTarget"]])
        let file = try #require(try AppleComponents.file(for: try rowContract(), source: rowSource))
        #expect(file.contents.contains("enum ListRowState: String, CaseIterable, Sendable"))
        #expect(file.contents.contains("#if os(watchOS)"))
        #expect(file.contents.contains("case .dropTarget: return false"))
        #expect(file.contents.contains("package enum ListRowForm: String, CaseIterable, Sendable"))
        #expect(file.contents.contains("case .static: [.selected, .disabled, .dropTarget]"))
    }

    @Test("a mark is a modifier: its first parameter an optional enum, nil drawing none, then the others")
    func mark() throws {
        let own = try AppleComponents.Own(try rowContract(), source: rowSource)
        #expect(own.marks.map(\.name) == ["insertionMark"])
        #expect(own.marks[0].enums.map(\.type) == ["ListRowInsertionEdge"])
        #expect(own.marks[0].parameters.map(\.description) == ["_: ListRowInsertionEdge?", "level: Int = 0"])
        let file = try #require(try AppleComponents.contractFile(for: try rowContract(), source: rowSource))
        #expect(file.contents.contains("public enum ListRowInsertionEdge: String, CaseIterable, Sendable"))
        let noEnum = replacing(
            "      edge: { type: enum, values: [top, bottom] }\n", with: "")
        #expect(failure(noEnum)?.contains("a mark's first parameter is an enum") == true)
    }

    // An OS that restricts an own component's options stays out (OwnComponentTests, "a shape the conventions do not
    // derive yet"); one that restricts only its states is derived (`states`, above).
    @Test("forms on a view with fewer than two slots stay out")
    func notDerived() {
        #expect(
            failure(replacing("slots: [title, subtitle, leading, trailing]", with: "slots: [label]"))?.contains(
                "forms: a view with forms and fewer than two slots") == true)
    }

    // MARK: - The lint

    @Test("the lint accepts the view's initializers, the mark's modifier and the shared state modifiers")
    func lintPasses() throws {
        #expect(try parity() == [])
    }

    @Test("a missing form, a changed mark or a missing state modifier is reported")
    func lintReports() throws {
        let noStatic = rowSwift.replacingOccurrences(
            of: """
                    public init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
                        level: Int = 0, guides: Bool = true, @ViewBuilder title: () -> Title,
                """,
            with: """
                    init<Title: View, Subtitle: View, Leading: View, Trailing: View>(
                        level: Int = 0, guides: Bool = true, @ViewBuilder title: () -> Title,
                """)
        #expect(noStatic != rowSwift)
        #expect(try parity(noStatic).contains { $0.contains("ListRow.init") && $0.contains("is internal") })
        let changedMark = rowSwift.replacingOccurrences(
            of: "insertionMark(_ edge: ListRowInsertionEdge?, level: Int = 0)",
            with: "insertionMark(_ edge: ListRowInsertionEdge, level: Int = 0)")
        #expect(try parity(changedMark).contains { $0.contains("insertionMark") })
        let noDropTarget = rowSwift.replacingOccurrences(
            of: "    public func dropTarget(_ isDropTarget: Bool) -> some View { self }\n", with: "")
        #expect(try parity(noDropTarget).contains { $0.contains("dropTarget") })
    }
}
