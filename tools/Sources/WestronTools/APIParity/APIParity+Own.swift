extension APIParity {
    /// The API of an approved own component (`AppleComponents.Own`): the enums of its enum options, as for a style,
    /// and either the modifier on `View` (`public func surface(_: SurfaceVariant, outlined: Bool = false) -> some
    /// View`) or the view type with its initializer and body (`public struct Rule: View`, `public init(axis: RuleAxis
    /// = .horizontal)`, `public var body: some View`). A contract the conventions derive no such API from is reported,
    /// as generation reports it. Each mark adds its modifier on `View` and the enums of its enum parameters; the shared
    /// modifiers of its states the caller expects with the styles' (`AppleComponents.Own.modifierStates`).
    @discardableResult
    static func expectOwn(_ item: Contract, into expected: inout Expected) -> AppleComponents.Own? {
        let api: AppleComponents.Own
        do {
            api = try AppleComponents.Own(item.contract, source: item.source)
        } catch {
            expected.problems.append(
                Problem(
                    file: item.source, line: item.line(of: "form"),
                    "the lint cannot derive \(item.component)'s API: \(error.message); generate reports it too"))
            return nil
        }
        for value in api.enums {
            expected.enums.append(
                ExpectedEnum(contract: item, option: value.option, type: value.type, values: value.values))
        }
        for mark in api.marks {
            for value in mark.enums {
                expected.enums.append(
                    ExpectedEnum(contract: item, option: value.option, type: value.type, values: value.values))
            }
            expected.functions.append(
                ExpectedFunction(
                    what: "\(item.component)'s mark \(mark.mark)", contracts: [item], name: mark.name,
                    parameters: mark.parameters, types: Set(mark.enums.map(\.type)),
                    line: (item.source, item.line(of: "marks"))))
        }
        switch api.form {
        case .modifier:
            expected.functions.append(
                ExpectedFunction(
                    what: "\(item.component)'s modifier", contracts: [item], name: api.name,
                    parameters: api.parameters, types: Set(api.enums.map(\.type)),
                    line: (item.source, item.line(of: "form"))))
        case .view:
            expected.views.append(ExpectedView(contract: item, type: api.name, initializers: api.initializers))
        }
        return api
    }

    /// Checks each own component's view: a public top-level struct that conforms to `View` alone, its public
    /// initializers with the contract's parameters (and the extras an icon's verbatim label takes), and its public
    /// `body: some View`, each reported when missing or
    /// different. What it finds is accounted for; any other public member of the type is component API no contract
    /// gives, reported by `check`.
    static func checkViews(
        _ views: [ExpectedView], declarations: [SwiftDeclarations.Declaration], accounted: inout Set<Int>,
        expectedCount: inout Int
    ) -> [Problem] {
        var problems: [Problem] = []
        func problem(_ d: SwiftDeclarations.Declaration, _ message: String) {
            problems.append(Problem(file: d.file, line: d.line, message))
        }
        func reportExtras(_ d: SwiftDeclarations.Declaration, _ what: String) {
            let changing = d.extras.filter { !harmlessExtras.contains($0) }
            guard !changing.isEmpty else { return }
            problem(
                d,
                "\(what) has \(changing.map { "`\($0)`" }.joined(separator: ", ")), which changes where or how a "
                    + "product calls it; the conventions give it none (harmless: "
                    + "\(harmlessExtras.sorted().joined(separator: ", ")))")
        }
        for view in views {
            let contract = "\(view.contract.component)'s contract (\(view.contract.source))"
            let line = view.contract.line(of: "form")
            let found = declarations.indices.filter {
                declarations[$0].kind.isType && declarations[$0].container.isEmpty && declarations[$0].name == view.type
            }
            guard let index = found.first else {
                problems.append(
                    Problem(
                        file: view.contract.source, line: line,
                        "missing: public struct \(view.type): View, with "
                            + view.initializers.map { "`\($0.declaration)`" }.joined(separator: ", ")
                            + " and `public var body: some View`, which \(contract) gives as a view"))
                continue
            }
            for extra in found.dropFirst() {
                problem(declarations[extra], "\(view.type) is declared again; \(contract) gives one view")
                accounted.insert(extra)
            }
            accounted.insert(index)
            expectedCount += 1
            let d = declarations[index]
            if d.kind != .struct {
                problem(d, "\(view.type) is a \(d.kind.rawValue); \(contract) makes it a public struct")
            }
            if !d.access.isPublic {
                problem(d, "\(view.type) is \(d.access); \(contract) makes it public")
            }
            if d.inheritance != ["View"], d.inheritance != ["SwiftUI.View"] {
                problem(
                    d,
                    "\(view.type) conforms to \(d.inheritance.joined(separator: ", ")); \(contract) makes it a View "
                        + "and nothing else")
            }
            reportExtras(d, view.type)
            let members = declarations.indices.filter { declarations[$0].container == view.type }
            let initializers = members.filter { declarations[$0].kind == .initializer && !accounted.contains($0) }
            var unmatched: [AppleComponents.Own.Initializer] = []
            for expectedInit in view.initializers {
                guard
                    let exact = initializers.first(where: {
                        !accounted.contains($0) && declarations[$0].parameters == expectedInit.parameters
                    })
                else {
                    unmatched.append(expectedInit)
                    continue
                }
                accounted.insert(exact)
                expectedCount += 1
                let i = declarations[exact]
                let what = "\(view.type).\(expectedInit)"
                if !i.access.isPublic {
                    problem(i, "\(what) is \(i.access); \(contract) makes it public")
                }
                if expectedInit.extras.isEmpty {
                    reportExtras(i, what)
                } else if Set(i.extras.filter { !harmlessExtras.contains($0) }) != Set(expectedInit.extras) {
                    problem(
                        i,
                        "\(view.type)'s initializer differs from the contract: expected `\(expectedInit)`, found "
                            + "`\(i.signature)`")
                }
            }
            for expectedInit in unmatched {
                if let near = initializers.first(where: {
                    !accounted.contains($0) && declarations[$0].access.isPublic
                }) {
                    accounted.insert(near)
                    problem(
                        declarations[near],
                        "\(view.type)'s initializer differs from the contract: expected `\(expectedInit)`, found "
                            + "`\(declarations[near].signature)`")
                } else {
                    problems.append(
                        Problem(
                            file: view.contract.source, line: line,
                            "missing: `\(expectedInit.declaration)` in \(view.type), which \(contract) gives"))
                }
            }
            if let body = members.first(where: {
                declarations[$0].kind == .var && declarations[$0].name == "body" && !declarations[$0].isStatic
            }) {
                accounted.insert(body)
                expectedCount += 1
                let b = declarations[body]
                if !b.access.isPublic {
                    problem(b, "\(view.type).body is \(b.access); a public View's body is public")
                }
                if b.resultType != "some View" {
                    problem(
                        b,
                        "\(view.type).body is \(b.resultType ?? "untyped"); \(contract) gives `some View`, so the "
                            + "type of the drawing stays out of the API")
                }
            } else {
                // The compiler reports a View without a body too; the lint says what the contract gives.
                problem(d, "missing: `public var body: some View` in \(view.type), which \(contract) gives as a view")
            }
        }
        return problems
    }
}
