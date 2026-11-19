extension APIParity {
    /// Checks the initializers of each control with no drawn label (`AppleComponents.HiddenLabel`): in an extension of
    /// the base control with the `where` clause the conventions give, public, with the contract's parameters and the
    /// extras of the twin, each reported when missing or different. What it finds is accounted for; any other public
    /// initializer of the control is API no contract gives, reported by `check`.
    static func checkHiddenLabels(
        _ items: [ExpectedHiddenLabel], declarations: [SwiftDeclarations.Declaration], accounted: inout Set<Int>,
        expectedCount: inout Int
    ) -> [Problem] {
        var problems: [Problem] = []
        for item in items {
            let api = item.api
            let contract = "\(item.contract.component)'s contract (\(item.contract.source))"
            let containers: Set<String> = [api.control, "SwiftUI." + api.control]
            let candidates = declarations.indices.filter {
                declarations[$0].kind == .initializer && declarations[$0].inExtension
                    && containers.contains(declarations[$0].container)
            }
            /// What a declaration carries beyond the harmless extras, the extension's `where` clause included.
            func extras(_ d: SwiftDeclarations.Declaration) -> Set<String> {
                Set(d.extras.filter { !harmlessExtras.contains($0) })
            }
            var unmatched: [AppleComponents.Own.Initializer] = []
            for initializer in api.initializers {
                let wanted = Set([api.requirement] + initializer.extras)
                guard
                    let exact = candidates.first(where: {
                        !accounted.contains($0) && declarations[$0].parameters == initializer.parameters
                            && extras(declarations[$0]) == wanted
                    })
                else {
                    unmatched.append(initializer)
                    continue
                }
                accounted.insert(exact)
                expectedCount += 1
                let d = declarations[exact]
                if !d.access.isPublic {
                    problems.append(
                        Problem(
                            file: d.file, line: d.line,
                            "\(api.control).\(initializer), which \(contract) gives for a label that is not drawn, "
                                + "is \(d.access); the conventions make it public"))
                }
            }
            for initializer in unmatched {
                let declaration = "extension \(api.control) \(api.requirement) { \(initializer.declaration) }"
                // A changed one: the same parameters, in another extension or with other attributes or generics.
                if let near = candidates.first(where: {
                    !accounted.contains($0) && declarations[$0].parameters == initializer.parameters
                }) {
                    accounted.insert(near)
                    let d = declarations[near]
                    problems.append(
                        Problem(
                            file: d.file, line: d.line,
                            "\(api.control)'s initializer for a label that is not drawn differs from the contract: "
                                + "expected `\(declaration)`, found `\(d.signature)`"))
                } else {
                    problems.append(
                        Problem(
                            file: item.contract.source, line: item.contract.line(of: "hiddenLabel"),
                            "missing: `\(declaration)`, which \(contract) gives for a label that is not drawn "
                                + "(spec/conventions.md, \"A label that is not drawn\")"))
                }
            }
        }
        return problems
    }
}
