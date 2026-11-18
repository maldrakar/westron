extension APIParity {
    /// The API of an approved own component (`AppleComponents.Own`): the enums of its enum options, as for a style,
    /// and either the modifier on `View` (`public func surface(_: SurfaceVariant, outlined: Bool = false) -> some
    /// View`) or the view type with its initializer and body (`public struct Rule: View`, `public init(axis: RuleAxis
    /// = .horizontal)`, `public var body: some View`). A contract the conventions derive no such API from is reported,
    /// as generation reports it.
    static func expectOwn(_ item: Contract, into expected: inout Expected) {
        let api: AppleComponents.Own
        do {
            api = try AppleComponents.Own(item.contract, source: item.source)
        } catch {
            expected.problems.append(
                Problem(
                    file: item.source, line: item.line(of: "form"),
                    "the lint cannot derive \(item.component)'s API: \(error.message); generate reports it too"))
            return
        }
        for value in api.enums {
            expected.enums.append(
                ExpectedEnum(contract: item, option: value.option, type: value.type, values: value.values))
        }
        switch api.form {
        case .modifier:
            expected.functions.append(
                ExpectedFunction(
                    what: "\(item.component)'s modifier", contracts: [item], name: api.name,
                    parameters: api.parameters, types: Set(api.enums.map(\.type)),
                    line: (item.source, item.line(of: "form"))))
        case .view:
            expected.views.append(ExpectedView(contract: item, type: api.name, parameters: api.parameters))
        }
    }

    /// Checks each own component's view: a public top-level struct that conforms to `View` alone, its public
    /// initializer with the contract's parameters, and its public `body: some View`. What it finds is accounted for;
    /// any other public member of the type is component API no contract gives, reported by `check`.
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
                        "missing: public struct \(view.type): View, with `public \(view.initializer)` and `public var "
                            + "body: some View`, which \(contract) gives as a view"))
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
            if let exact = initializers.first(where: { declarations[$0].parameters == view.parameters }) {
                accounted.insert(exact)
                expectedCount += 1
                let i = declarations[exact]
                if !i.access.isPublic {
                    problem(i, "\(view.type).\(view.initializer) is \(i.access); \(contract) makes it public")
                }
                reportExtras(i, "\(view.type).\(view.initializer)")
            } else if let near = initializers.first(where: { declarations[$0].access.isPublic }) {
                accounted.insert(near)
                problem(
                    declarations[near],
                    "\(view.type)'s initializer differs from the contract: expected `\(view.initializer)`, found "
                        + "`\(declarations[near].signature)`")
            } else {
                problems.append(
                    Problem(
                        file: view.contract.source, line: line,
                        "missing: `public \(view.initializer)` in \(view.type), which \(contract) gives"))
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
            }
        }
        return problems
    }
}
