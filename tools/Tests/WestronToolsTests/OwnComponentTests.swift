import Foundation
import Testing
import WestronTools

/// An own component, Surface-shaped by default: a modifier with a variant without a default and a bool option; tests
/// replace parts.
private func ownYAML(
    id: String = "surface",
    status: String = "approved",
    options: String = """
      variant: { type: enum, values: [raised, dragged, sunken], description: Every use names its kind. }
      outlined: { type: bool, default: false }
    """,
    slots: String = "[content]",
    extra: String = "",
    apple: String = """
        strategy: own-component
        form: modifier
    """
) -> String {
    """
    id: \(id)
    status: \(status)
    consumers: [todo-app/list-screen]
    options:
    \(options)
    slots: \(slots)
    \(extra)
    accessibility: { role: none }
    platforms:
      apple:
    \(apple)
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """
}

/// A Rule-shaped own component: a view with an enum option with a default and no slots.
private func viewYAML(id: String = "rule", status: String = "approved", options: String? = nil) -> String {
    ownYAML(
        id: id, status: status,
        options: options ?? "  axis: { type: enum, values: [horizontal, vertical], default: horizontal }",
        slots: "[]",
        apple: """
                strategy: own-component
                form: view
            """)
}

/// A style on a system control, to put next to an own component.
private func styleYAML(id: String = "button", option: String = "variant", values: String = "[primary, secondary]")
    -> String
{
    """
    id: \(id)
    status: approved
    consumers: [todo-app/list-screen]
    options:
      \(option): { type: enum, values: \(values) }
    accessibility: { role: button }
    platforms:
      apple:
        strategy: style-on-system-control
        base: SwiftUI.Button
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """
}

private func source(_ id: String) -> String { "spec/components/\(id)/\(id).spec.yaml" }

private func contract(_ yaml: String, id: String) throws -> ComponentContract {
    try ComponentContract(yaml: yaml, source: source(id))
}

private func generated(_ yaml: String, id: String = "surface") throws -> GeneratedFile? {
    try AppleComponents.file(for: contract(yaml, id: id), source: source(id))
}

/// The message the generator throws for a contract, nil when it generates.
private func failure(_ yaml: String, id: String = "surface") -> String? {
    do {
        _ = try generated(yaml, id: id)
        return nil
    } catch {
        return "\(error)"
    }
}

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

private func specProblems(_ yaml: String, id: String = "surface") -> [String] {
    ContractCheck.check(yaml: yaml, source: source(id), schema: schema, tokens: ContractTokens(everywhere: []))
        .map { "\($0.place): \($0.message)" }
}

@Suite("Own components")
struct OwnComponentTests {
    // MARK: - The contract's form

    @Test("an own component on Apple names its form, modifier or view; a style or an extension names none")
    func form() throws {
        #expect(specProblems(ownYAML()) == [])
        #expect(specProblems(viewYAML(), id: "rule") == [])
        #expect(
            specProblems(ownYAML(apple: "        strategy: own-component")) == [
                "platforms.apple: Required property 'form' is missing"
            ])
        #expect(!specProblems(ownYAML(apple: "        strategy: own-component\n        form: container")).isEmpty)
        let styled = styleYAML().replacingOccurrences(
            of: "base: SwiftUI.Button", with: "base: SwiftUI.Button\n    form: modifier")
        #expect(!specProblems(styled, id: "button").isEmpty)
        #expect(ComponentContract.Apple(strategy: "own-component", base: nil, form: "view").form == "view")
        #expect(try contract(ownYAML(), id: "surface").apple?.form == "modifier")
        #expect(try contract(ownYAML(), id: "surface").slots == ["content"])
    }

    @Test("an approved own component with a form gives API; a draft or one without a form does not")
    func givesAPI() throws {
        #expect(AppleComponents.givesAPI(try contract(ownYAML(), id: "surface")))
        #expect(AppleComponents.givesAPI(try contract(viewYAML(), id: "rule")))
        #expect(!AppleComponents.givesAPI(try contract(ownYAML(status: "draft"), id: "surface")))
        #expect(
            !AppleComponents.givesAPI(
                try contract(ownYAML(apple: "        strategy: own-component"), id: "surface")))
        // The style path is unchanged: an own component never takes the style's generator.
        #expect(!AppleComponents.generates(try contract(ownYAML(), id: "surface")))
    }

    // MARK: - The generator

    @Test("a modifier: the enum of its variant, and the signature the lint expects")
    func modifier() throws {
        let file = try #require(try generated(ownYAML()))
        #expect(file.path == "platforms/apple/Sources/WestronUI/Generated/Surface+Contract.swift")
        #expect(
            file.contents.hasPrefix(
                "// Generated from spec/components/surface/surface.spec.yaml by `tools/westron generate`. Do not edit:")
        )
        #expect(
            file.contents.replacingOccurrences(of: "\n// ", with: " ").contains(
                "the modifier `surface(_:outlined:)` is hand-written in WestronUI/Surface/"))
        #expect(
            file.contents.contains(
                """
                /// Surface's option `variant`, from its contract.
                ///
                /// Every use names its kind.
                public enum SurfaceVariant: String, CaseIterable, Sendable {
                    case raised
                    case dragged
                    case sunken
                }

                """))
        // Only the enum: no import, no modifier, no type for the bool.
        #expect(!file.contents.contains("import"))
        #expect(!file.contents.contains("func "))
        let api = try AppleComponents.Own(contract(ownYAML(), id: "surface"), source: source("surface"))
        #expect(api.form == .modifier && api.name == "surface")
        #expect(
            api.parameters.map(\.description) == ["_: SurfaceVariant", "outlined: Bool = false"])
    }

    @Test("a view: the enum of its option, and an initializer with every option labeled and its default")
    func view() throws {
        let file = try #require(try generated(viewYAML(), id: "rule"))
        #expect(file.path == "platforms/apple/Sources/WestronUI/Generated/Rule+Contract.swift")
        #expect(
            file.contents.replacingOccurrences(of: "\n// ", with: " ").contains(
                "the view `Rule` and its `Rule.init(axis:)` are hand-written in WestronUI/Rule/"))
        #expect(
            file.contents.contains(
                "public enum RuleAxis: String, CaseIterable, Sendable {\n    case horizontal\n    case vertical\n}\n"))
        let api = try AppleComponents.Own(contract(viewYAML(), id: "rule"), source: source("rule"))
        #expect(api.form == .view && api.name == "Rule")
        #expect(api.parameters.map(\.description) == ["axis: RuleAxis = .horizontal"])
        // Bools and several enums, in the contract's order.
        let more = try AppleComponents.Own(
            contract(
                viewYAML(
                    options: """
                          axis: { type: enum, values: [horizontal, vertical], default: horizontal }
                          strong: { type: bool, default: true }
                          weight: { type: enum, values: [thin, thick] }
                        """), id: "rule"), source: source("rule"))
        #expect(
            more.parameters.map(\.description) == [
                "axis: RuleAxis = .horizontal", "strong: Bool = true", "weight: RuleWeight",
            ])
    }

    @Test("a draft, or one with no enum option, generates no file")
    func noFile() throws {
        #expect(try generated(ownYAML(status: "draft")) == nil)
        #expect(try generated(ownYAML(options: "  outlined: { type: bool, default: false }")) == nil)
    }

    @Test("a shape the conventions do not derive yet fails generation, and says which")
    func notDerivedYet() {
        let notYet = "the conventions do not derive an own-component's API for it yet"
        #expect(
            failure(ownYAML(extra: "states: [hover]"))?.contains("states: an own-component with states: \(notYet)")
                == true)
        #expect(
            failure(ownYAML(options: "  size: { type: enum, values: [s, m], default: m }"))?.contains(
                "options.size: a size option") == true)
        #expect(
            failure(ownYAML(options: "  role: { type: tokens, group: typography }"))?.contains(
                "options.role: an option whose values are tokens: \(notYet)") == true)
        #expect(
            failure(ownYAML(options: "  glyph: { type: icons }"))?.contains(
                "options.glyph: a modifier with an option whose values are icons: \(notYet)") == true)
        #expect(
            failure(ownYAML(slots: "[content, footer]"))?.contains(
                "slots: a modifier's content is the view it modifies") == true)
        #expect(
            failure(
                ownYAML(
                    apple: """
                            strategy: own-component
                            form: modifier
                            watchos:
                              options: { variant: [raised] }
                              fallback: { variant: raised }
                        """))?.contains("platforms.apple.watchos: an own-component that an OS restricts") == true)
        // A system option is the system's own environment modifier: no parameter and no enum (Icon's scale).
        #expect(
            failure(
                ownYAML(
                    apple: """
                            strategy: own-component
                            form: modifier
                            systemOptions: { outlined: SwiftUI.Bool }
                        """)) == nil)
        let viewWithVariant = viewYAML(options: "  variant: { type: enum, values: [quiet, loud] }")
        #expect(failure(viewWithVariant, id: "rule")?.contains("options.variant: a view with a variant") == true)
        // The one slot label is derived (LabelledViewTests); any other slot is not.
        let viewWithSlots = viewYAML().replacingOccurrences(of: "slots: []", with: "slots: [label, detail]")
        #expect(failure(viewWithSlots, id: "rule")?.contains("slots: a view with slots") == true)
        let viewWithContent = viewYAML().replacingOccurrences(of: "slots: []", with: "slots: [content]")
        #expect(failure(viewWithContent, id: "rule")?.contains("slots: a view with slots") == true)
    }

    @Test("a name that would shadow SwiftUI's fails: the view's type or an option's enum")
    func shadowing() {
        #expect(failure(viewYAML(id: "text"), id: "text")?.contains("id: Text would shadow SwiftUI's Text") == true)
        // `Edge` + `Insets`: an option `insets` of an own component `edge`.
        let edge = ownYAML(id: "edge", options: "  insets: { type: enum, values: [small, large] }")
        #expect(failure(edge, id: "edge")?.contains("EdgeInsets would shadow SwiftUI's EdgeInsets") == true)
    }

    @Test("an own component's names collide with each other's and with a style's")
    func collisions() throws {
        // ButtonGroupKind: `button`'s option `groupKind` and `button-group`'s option `kind`.
        let style = (try contract(styleYAML(option: "groupKind", values: "[a, b]"), id: "button"), source("button"))
        let own = (
            try contract(
                ownYAML(id: "button-group", options: "  kind: { type: enum, values: [a, b] }"), id: "button-group"),
            source("button-group")
        )
        #expect(throws: AppleComponents.Problems.self) { try AppleComponents.files(for: [style, own]) }
        do {
            _ = try AppleComponents.files(for: [style, own])
        } catch {
            #expect(
                "\(error)".contains(
                    "options.kind: ButtonGroupKind, for ButtonGroup's option kind, is already the type of Button's "
                        + "option groupKind in spec/components/button/button.spec.yaml"))
        }
        // A view named as a style's enum: `button-variant` is `ButtonVariant`.
        let view = (try contract(viewYAML(id: "button-variant"), id: "button-variant"), source("button-variant"))
        let plainStyle = (try contract(styleYAML(), id: "button"), source("button"))
        #expect(throws: AppleComponents.Problems.self) { try AppleComponents.files(for: [plainStyle, view]) }
        // Without a collision, the style's file and the own component's come in the contracts' order.
        let surface = (try contract(ownYAML(), id: "surface"), source("surface"))
        #expect(
            try AppleComponents.files(for: [plainStyle, surface]).map(\.path) == [
                "platforms/apple/Sources/WestronUI/Generated/Button+Contract.swift",
                "platforms/apple/Sources/WestronUI/Generated/Surface+Contract.swift",
            ])
    }

    // MARK: - The snapshot matrix

    @Test("an own component gets a matrix: its options are the axes, its cell the hand-written one")
    func matrix() throws {
        let surface = (try contract(ownYAML(), id: "surface"), source("surface"))
        let rule = (try contract(viewYAML(), id: "rule"), source("rule"))
        let draft = (try contract(ownYAML(id: "panel", status: "draft"), id: "panel"), source("panel"))
        let files = try AppleSnapshotMatrix.files(for: [rule, surface, draft])
        #expect(
            files.map(\.path) == [
                "platforms/apple/Sources/WestronCatalog/Generated/Rule+Matrix.swift",
                "platforms/apple/Sources/WestronCatalog/Generated/Surface+Matrix.swift",
                AppleSnapshotMatrix.registryFile,
            ])
        let matrix = try SnapshotMatrix(surface.0, source: surface.1)
        #expect(matrix.axes.map(\.name) == ["variant", "outlined"])
        #expect(matrix.combinations.count == 6 && matrix.states.isEmpty)
        #expect(matrix.sheets.map(\.id) == ["outlined-false", "outlined-true"])
        #expect(files[1].contents.contains("    private let variant: SurfaceVariant\n    private let outlined: Bool\n"))
        #expect(files[1].contents.contains(") { SurfaceMatrixCell(SurfaceMatrixValues($0)) }"))
        #expect(files[0].contents.contains("Option(\"axis\", values: [\"horizontal\", \"vertical\"])"))
        #expect(files[2].contents.contains("public static let all: [ComponentMatrix] = [.rule, .surface]"))
        // One sheet: no trailing comma after the lone element, which swift format would take off, and "1 sheet".
        #expect(files[0].contents.contains("                rows: [nil]\n            )\n        ]\n"))
        #expect(files[0].contents.replacingOccurrences(of: "\n    /// ", with: " ").contains("on 1 sheet.\n"))
        #expect(files[1].contents.contains("                rows: [nil]\n            ),\n"))
    }

    // MARK: - The API parity lint

    private static let root = "WestronUI"

    private static func parity(_ yamls: [(yaml: String, id: String)], _ files: [String: String]) throws -> [String] {
        let contracts = try yamls.map { item in
            APIParity.Contract(contract: try contract(item.yaml, id: item.id), source: source(item.id), text: item.yaml)
        }
        var sources: [(path: String, text: String)] = []
        for (yaml, id) in yamls {
            if let file = try generated(yaml, id: id) {
                sources.append(("\(root)/Generated/\(componentTypeName(id))+Contract.swift", file.contents))
            }
        }
        sources += files.sorted { $0.key < $1.key }.map { ("\(root)/\($0.key)", $0.value) }
        return APIParity.check(contracts: contracts, files: sources, sourceRoot: root).problems.map(\.description)
    }

    private static let surfaceSwift = """
        import SwiftUI

        extension View {
            public func surface(_ variant: SurfaceVariant, outlined: Bool = false) -> some View {
                modifier(SurfaceModifier(variant: variant, outlined: outlined))
            }
        }

        struct SurfaceModifier: ViewModifier {
            let variant: SurfaceVariant
            let outlined: Bool
            func body(content: Content) -> some View { content }
        }

        """

    private static let ruleSwift = """
        import SwiftUI

        public struct Rule: View {
            let axis: RuleAxis

            public init(axis: RuleAxis = .horizontal) {
                self.axis = axis
            }

            public var body: some View {
                Rectangle()
            }
        }

        """

    @Test("the lint accepts the hand-written modifier and view that the contracts give")
    func parityPasses() throws {
        #expect(
            try Self.parity(
                [(ownYAML(), "surface"), (viewYAML(), "rule")],
                ["Surface/Surface.swift": Self.surfaceSwift, "Rule/Rule.swift": Self.ruleSwift]) == [])
    }

    @Test("a missing, changed or extra modifier is reported")
    func parityModifier() throws {
        let missing = try Self.parity([(ownYAML(), "surface")], [:])
        #expect(missing.count == 1)
        #expect(
            missing[0].contains(
                "missing: Surface's modifier, `public func surface(_: SurfaceVariant, outlined: Bool = false) -> "
                    + "some View` in extension View"))
        let changed = try Self.parity(
            [(ownYAML(), "surface")],
            ["Surface/Surface.swift": Self.surfaceSwift.replacingOccurrences(of: "= false", with: "= true")])
        #expect(changed.count == 1)
        #expect(changed[0].contains("Surface's modifier differs from the contract"))
        // The modifier is hand-written: generating again changes nothing, so the lint does not advise it.
        #expect(!changed[0].contains("tools/westron generate"))
        let extra = try Self.parity(
            [(ownYAML(), "surface")],
            [
                "Surface/Surface.swift": Self.surfaceSwift
                    + "extension View {\n    public func surfaceTint(_ on: Bool) -> some View { self }\n}\n"
            ])
        #expect(extra.count == 1)
        #expect(
            extra[0].contains(
                "surfaceTint is named as Surface's API, which Surface's contract "
                    + "(spec/components/surface/surface.spec.yaml) does not give"))
    }

    @Test("a missing, changed or widened view is reported")
    func parityView() throws {
        let rule = [(viewYAML(), "rule")]
        let missing = try Self.parity(rule, [:])
        #expect(missing.count == 1)
        #expect(
            missing[0].contains("missing: public struct Rule: View, with `public init(axis: RuleAxis = .horizontal)`"))

        let internalInit = try Self.parity(
            rule,
            ["Rule/Rule.swift": Self.ruleSwift.replacingOccurrences(of: "public init(", with: "init(")])
        #expect(internalInit.count == 1)
        #expect(internalInit[0].contains("Rule.init(axis: RuleAxis = .horizontal) is internal"))

        let changedInit = try Self.parity(
            rule,
            ["Rule/Rule.swift": Self.ruleSwift.replacingOccurrences(of: "= .horizontal", with: "= .vertical")])
        #expect(changedInit.count == 1)
        #expect(changedInit[0].contains("Rule's initializer differs from the contract"))

        let extraInit = try Self.parity(
            rule,
            [
                "Rule/Rule.swift": Self.ruleSwift
                    + "extension Rule {\n    public init(length: Double) { self.init() }\n}\n"
            ])
        #expect(extraInit.count == 1)
        #expect(extraInit[0].contains("Rule.init is a member of Rule's API, which Rule's contract"))

        let widened = try Self.parity(
            rule,
            ["Rule/Rule.swift": Self.ruleSwift.replacingOccurrences(of: "Rule: View", with: "Rule: View, Equatable")])
        #expect(widened.count == 1)
        #expect(widened[0].contains("Rule conforms to View, Equatable"))

        let typedBody = try Self.parity(
            rule,
            [
                "Rule/Rule.swift": Self.ruleSwift.replacingOccurrences(
                    of: "public var body: some View", with: "public var body: Rectangle")
            ])
        #expect(typedBody.count == 1)
        #expect(typedBody[0].contains("Rule.body is Rectangle"))

        let withoutBody = try Self.parity(
            rule,
            [
                "Rule/Rule.swift": Self.ruleSwift.replacingOccurrences(
                    of: "public var body: some View {\n        Rectangle()\n    }", with: "")
            ])
        #expect(withoutBody.count == 1)
        #expect(withoutBody[0].contains("missing: `public var body: some View` in Rule"))

        let missingEnum = APIParity.check(
            contracts: [
                APIParity.Contract(
                    contract: try contract(viewYAML(), id: "rule"), source: source("rule"), text: viewYAML())
            ],
            files: [("\(Self.root)/Rule/Rule.swift", Self.ruleSwift)], sourceRoot: Self.root
        ).problems.map(\.description)
        #expect(missingEnum.count == 1)
        #expect(missingEnum[0].contains("missing: public enum RuleAxis for Rule's option axis"))
    }

    @Test("an own component the lint cannot derive is reported, as generation reports it")
    func parityNotDerived() throws {
        let yaml = ownYAML(extra: "states: [hover]")
        let problems = APIParity.check(
            contracts: [
                APIParity.Contract(contract: try contract(yaml, id: "surface"), source: source("surface"), text: yaml)
            ],
            files: [("\(Self.root)/Surface/Surface.swift", Self.surfaceSwift)], sourceRoot: Self.root
        ).problems.map(\.description)
        #expect(problems.contains { $0.contains("the lint cannot derive Surface's API: an own-component with states") })
    }
}

/// `Surface` for `surface`, `ButtonGroup` for `button-group`.
private func componentTypeName(_ id: String) -> String {
    id.split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
}
