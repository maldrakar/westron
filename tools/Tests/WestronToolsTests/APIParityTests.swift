import Foundation
import Testing
import WestronTools

/// A Button-like contract: a variant without a default, a size, a system option, a bool option, and states the system
/// has and one it lacks.
private func contractYAML(
    id: String = "button", status: String = "approved", variant: String = "[primary, secondary]",
    iconOnlyDefault: Bool = false, states: String = "[hover, pressed, loading]",
    apple: String = """
        strategy: style-on-system-control
        base: SwiftUI.Button
        systemOptions: { role: SwiftUI.ButtonRole }
    """
) -> String {
    """
    id: \(id)
    status: \(status)
    consumers: [todo-app/list-screen]
    options:
      variant: { type: enum, values: \(variant) }
      size: { type: enum, values: [s, m, l], default: m }
      role: { type: enum, values: [default, destructive], default: default }
      iconOnly: { type: bool, default: \(iconOnlyDefault) }
    states: \(states)
    accessibility: { role: button }
    platforms:
      apple:
    \(apple)
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """
}

private let root = "WestronUI"

private func contract(_ yaml: String, id: String = "button") throws -> APIParity.Contract {
    let source = "spec/components/\(id)/\(id).spec.yaml"
    return APIParity.Contract(contract: try ComponentContract(yaml: yaml, source: source), source: source, text: yaml)
}

/// The generator's file for the fixture contract, as `tools/westron generate` would write it.
private func generatedSwift(_ yaml: String = contractYAML()) throws -> String {
    let source = "spec/components/button/button.spec.yaml"
    return try #require(try AppleComponents.file(for: ComponentContract(yaml: yaml, source: source), source: source))
        .contents
}

private let statesSwift = """
    import SwiftUI

    extension EnvironmentValues {
        @Entry var isLoading = false
    }

    extension View {
        /// Puts the components into loading.
        public func loading(_ isLoading: Bool) -> some View {
            environment(\\.isLoading, isLoading)
        }
    }

    """

private let styleSwift = """
    import SwiftUI

    struct ButtonVariantStyle: ButtonStyle {
        let variant: ButtonVariant
        let size: ButtonSize?
        let iconOnly: Bool

        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }

    """

/// The hand-written adapters, as in TokenAdapters.swift.
private let tokensSwift = """
    import SwiftUI

    extension View {
        public func foregroundStyle(_ color: Westron.Color) -> some View {
            foregroundStyle(Color(color))
        }
    }

    extension Label where Title == Text, Icon == Image {
        public init(_ titleKey: LocalizedStringKey, icon: Westron.Icon) {
            self.init(titleKey, systemImage: icon.systemName)
        }
    }

    extension Westron.Theme {
        public init(colorScheme: ColorScheme, contrast: ColorSchemeContrast) {
            self = .light
        }
    }

    """

/// The generated accessors, as in Generated/Tokens+SwiftUI.swift.
private let generatedTokensSwift = """
    import SwiftUI

    extension CGFloat {
        public enum radius {
            public static var control: CGFloat { CGFloat(Westron.Dimension.radius.control) }
        }
    }

    extension Double {
        public enum opacity {
            public static var disabled: Double { 0 }
        }
    }

    """

/// The fixture module: the generated file, the shared states, the hand-written style, the token files.
private func files(
    generated: String? = nil, states: String = statesSwift, style: String = styleSwift, tokens: String = tokensSwift,
    generatedTokens: String = generatedTokensSwift, extra: [String: String] = [:]
) throws -> [(path: String, text: String)] {
    var files = [
        "\(root)/Generated/Button+Contract.swift": try generated ?? generatedSwift(),
        "\(root)/States.swift": states,
        "\(root)/Button/ButtonVariantStyle.swift": style,
        "\(root)/TokenAdapters.swift": tokens,
        "\(root)/Generated/Tokens+SwiftUI.swift": generatedTokens,
    ]
    for (path, text) in extra { files["\(root)/\(path)"] = text }
    return files.sorted { $0.key < $1.key }.map { (path: $0.key, text: $0.value) }
}

private func problems(_ contracts: [APIParity.Contract], _ files: [(path: String, text: String)]) -> [String] {
    APIParity.check(contracts: contracts, files: files, sourceRoot: root).problems.map(\.description)
}

/// The problems against the fixture contract.
private func problems(_ files: [(path: String, text: String)]) throws -> [String] {
    problems([try contract(contractYAML())], files)
}

/// The real repository's contracts and WestronUI, with the Button contract's text changed.
private func realRepository(changingContract change: (String) -> String) throws -> [String] {
    let directory = repositoryRoot.appendingPathComponent(ContractCheck.defaultDirectory).path
    let sources = repositoryRoot.appendingPathComponent(APIParity.defaultSources).path
    var contracts: [APIParity.Contract] = []
    for file in try ContractCheck.files(in: directory) {
        var text = try String(contentsOfFile: file, encoding: .utf8)
        if file.hasSuffix("button/button.spec.yaml") {
            let changed = change(text)
            #expect(changed != text, "the change applies to the Button contract")
            text = changed
        }
        contracts.append(
            APIParity.Contract(contract: try ComponentContract(yaml: text, source: file), source: file, text: text))
    }
    let report = try APIParity.run(contractsDirectory: directory, sourceRoot: sources)
    #expect(report.problems.isEmpty, "the repository as it is passes")
    let swiftFiles = try FileManager.default.subpathsOfDirectory(atPath: sources).filter { $0.hasSuffix(".swift") }
        .sorted().map { path in
            (path: sources + "/" + path, text: try String(contentsOfFile: sources + "/" + path, encoding: .utf8))
        }
    return APIParity.check(contracts: contracts, files: swiftFiles, sourceRoot: sources).problems.map(\.description)
}

@Suite("API parity lint")
struct APIParityTests {
    // MARK: The repository and the fixture

    @Test("the real repository passes")
    func repository() throws {
        let report = try APIParity.run(
            contractsDirectory: repositoryRoot.appendingPathComponent(ContractCheck.defaultDirectory).path,
            sourceRoot: repositoryRoot.appendingPathComponent(APIParity.defaultSources).path)
        #expect(report.problems.map(\.description) == [])
        #expect(report.contracts >= 1)
        // ButtonVariant and its 3 cases, ButtonSize and its 3, buttonStyle, loading.
        #expect(report.expected >= 10)
    }

    @Test("the generator's output for a contract, with the shared state modifier, passes")
    func fixturePasses() throws {
        #expect(try problems(files()) == [])
    }

    @Test("the Button contract with a value renamed fails against the current generated file")
    func realContractRenamedValue() throws {
        let found = try realRepository {
            $0.replacingOccurrences(
                of: "values: [primary, secondary, tertiary]", with: "values: [primary, secondary, ghost]")
        }
        #expect(found.count == 1)
        #expect(found.first?.contains("Generated/Button+Contract.swift:") == true)
        #expect(found.first?.contains("missing ghost; not in the contract: tertiary") == true)
    }

    @Test("the Button contract with iconOnly's default changed fails against the current generated file")
    func realContractChangedDefault() throws {
        let found = try realRepository {
            $0.replacingOccurrences(of: "type: bool\n    default: false", with: "type: bool\n    default: true")
        }
        #expect(found.count == 1)
        #expect(
            found.first?.contains(
                "expected `buttonStyle(_: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = true) -> some View`")
                == true)
    }

    // MARK: Expected API that is missing or differs

    @Test("a missing enum is reported at the contract's option")
    func missingEnum() throws {
        let generated = try generatedSwift().replacingOccurrences(
            of: "public enum ButtonSize: String, CaseIterable, Sendable {\n    case s\n    case m\n    case l\n}",
            with: "")
        let found = try problems(files(generated: generated))
        #expect(
            found.contains {
                $0.hasPrefix("spec/components/button/button.spec.yaml:6: missing: public enum ButtonSize")
            })
    }

    @Test("a renamed, reordered or extra case, a different raw value or an associated value is reported")
    func cases() throws {
        let generated = try generatedSwift()
        let renamed = try problems(
            files(generated: generated.replacingOccurrences(of: "case secondary", with: "case outlined")))
        #expect(renamed.count == 1)
        #expect(renamed[0].contains("missing secondary; not in the contract: outlined"))

        let reordered = try problems(
            files(generated: generated.replacingOccurrences(of: "case s\n    case m", with: "case m\n    case s")))
        #expect(reordered.count == 1)
        #expect(reordered[0].contains("ButtonSize has the cases m, s, l") && reordered[0].contains("in another order"))

        let raw = try problems(
            files(generated: generated.replacingOccurrences(of: "case m\n", with: "case m = \"medium\"\n")))
        #expect(raw.count == 1)
        #expect(raw[0].contains("ButtonSize.m has the raw value \"medium\""))

        let associated = try problems(
            files(generated: generated.replacingOccurrences(of: "case primary", with: "case primary(Int)")))
        #expect(associated.count == 1)
        #expect(associated[0].contains("ButtonVariant.primary has associated values"))
    }

    @Test("an enum with another access level or other conformances is reported")
    func enumAccessAndConformances() throws {
        let generated = try generatedSwift()
        let internalEnum = try problems(
            files(
                generated: generated.replacingOccurrences(of: "public enum ButtonVariant", with: "enum ButtonVariant")))
        #expect(internalEnum.count == 1)
        #expect(internalEnum[0].contains("ButtonVariant is internal; Button's option variant"))

        let conformances = try problems(
            files(
                generated: generated.replacingOccurrences(
                    of: "ButtonSize: String, CaseIterable, Sendable", with: "ButtonSize: String, Sendable")))
        #expect(conformances.count == 1)
        #expect(conformances[0].contains("ButtonSize conforms to String, Sendable"))
    }

    @Test("a style overload with another signature or access is reported, and a missing one at the contract")
    func overload() throws {
        let generated = try generatedSwift()
        let changed = try problems(
            files(generated: generated.replacingOccurrences(of: "iconOnly: Bool = false", with: "iconOnly: Bool")))
        #expect(changed.count == 1)
        #expect(changed[0].contains("Button+Contract.swift:"))
        #expect(
            changed[0].contains(
                "found `buttonStyle(_: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool) -> some View`"))

        let variantDefault = try problems(
            files(
                generated: generated.replacingOccurrences(
                    of: "_ variant: ButtonVariant,", with: "_ variant: ButtonVariant = .primary,")))
        #expect(variantDefault.count == 1)
        #expect(variantDefault[0].contains("differs from the contract"))

        let internalOverload = try problems(
            files(
                generated: generated.replacingOccurrences(
                    of: "    public func buttonStyle(", with: "    func buttonStyle(")))
        #expect(internalOverload.count == 1)
        #expect(internalOverload[0].contains("is internal; the conventions make it public"))

        let attributed = try problems(
            files(
                generated: generated.replacingOccurrences(
                    of: "    public func buttonStyle(", with: "    @available(iOS 18, *) public func buttonStyle(")))
        #expect(attributed.count == 1)
        #expect(attributed[0].contains("has `@available(iOS 18, *)`, which changes where or how a product calls it"))

        let without =
            generated.components(separatedBy: "extension View {")[0]
            + "extension ButtonSize"
            + generated.components(separatedBy: "extension ButtonSize")[1...].joined(separator: "extension ButtonSize")
        let missing = try problems(files(generated: without))
        #expect(
            missing == [
                "spec/components/button/button.spec.yaml:14: missing: Button's style overload, `public func "
                    + "buttonStyle(_: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false) -> some View` in "
                    + "extension View"
            ])
    }

    @Test("the state modifier: missing, with a default, or a second one per component")
    func stateModifier() throws {
        let missing = try problems(files(states: "import SwiftUI\n"))
        #expect(
            missing == [
                "spec/components/button/button.spec.yaml:9: missing: the state modifier of loading, `public func "
                    + "loading(_: Bool) -> some View` in extension View"
            ])

        let defaulted = try problems(
            files(states: statesSwift.replacingOccurrences(of: "_ isLoading: Bool)", with: "_ isLoading: Bool = true)"))
        )
        #expect(defaulted.count == 1)
        #expect(defaulted[0].contains("the state modifier of loading differs from the contract"))

        let second = try problems(
            files(
                states: statesSwift + """
                    extension View {
                        public func buttonLoading(_ isLoading: Bool) -> some View { loading(isLoading) }
                    }

                    """))
        #expect(second.count == 1)
        #expect(second[0].contains("buttonLoading is named as Button's API"))
    }

    @Test("no state modifier for a state the system control has")
    func systemState() throws {
        let found = try problems(
            files(
                states: statesSwift + """
                    extension View {
                        public func hover(_ isHovered: Bool) -> some View { self }
                    }

                    """))
        #expect(found.count == 1)
        #expect(found[0].contains("sets the state hover, which the system control has"))
    }

    // MARK: Component API that no contract gives

    @Test("a hand-written type named as a component's API is reported once, with its members")
    func handWrittenType() throws {
        let found = try problems(
            files(style: styleSwift + "\npublic enum ButtonShape {\n    case round\n    case square\n}\n"))
        #expect(
            found == [
                "WestronUI/Button/ButtonVariantStyle.swift:13: public enum ButtonShape: component API that no contract "
                    + "accounts for: ButtonShape is named as Button's API, which Button's contract "
                    + "(spec/components/button/button.spec.yaml) does not give through the conventions "
                    + "(spec/conventions.md); for a deliberate exception: // westron-api-parity: allow <reason>"
            ])
    }

    @Test("the hand-written style or the states made public are reported")
    func publicInternals() throws {
        let style = try problems(
            files(
                style: styleSwift.replacingOccurrences(
                    of: "struct ButtonVariantStyle", with: "public struct ButtonVariantStyle")))
        #expect(style.count == 1)
        #expect(style[0].contains("public struct ButtonVariantStyle: component API"))

        let generated = try generatedSwift().replacingOccurrences(
            of: "\nenum ButtonState", with: "\npublic enum ButtonState")
        let states = try problems(files(generated: generated))
        #expect(states.count == 1)
        #expect(states[0].contains("public enum ButtonState: component API"))
    }

    @Test("another overload of the style modifier is reported")
    func secondOverload() throws {
        let found = try problems(
            files(
                style: styleSwift + """

                    extension View {
                        public func buttonStyle(_ variant: ButtonVariant, rounded: Bool) -> some View { self }
                    }

                    """))
        #expect(found.count == 1)
        #expect(
            found[0].contains(
                "buttonStyle(_: ButtonVariant, rounded: Bool) -> some View is an overload of a style modifier"))
        #expect(found[0].contains("Button's contract"))
    }

    @Test("a public member or a conformance added to a generated enum is reported")
    func membersOfEnums() throws {
        let found = try problems(
            files(
                style: styleSwift + """

                    extension ButtonSize {
                        public var points: Double { 0 }
                    }

                    extension ButtonVariant: Identifiable {
                        public var id: String { rawValue }
                    }

                    """))
        #expect(found.count == 3)
        #expect(found.contains { $0.contains("public var ButtonSize.points: component API") })
        #expect(found.contains { $0.contains("extension ButtonVariant: Identifiable: component API") })
        #expect(found.contains { $0.contains("public var ButtonVariant.id: component API") })
    }

    @Test("access is the effective one: a public extension's members are public, an internal type's are not")
    func effectiveAccess() throws {
        let found = try problems(
            files(
                style: styleSwift + """

                    public extension View {
                        func buttonGlow() -> some View { self }
                    }

                    """))
        #expect(found.count == 1)
        #expect(found[0].contains("public func View.buttonGlow"))
        // styleSwift's `public func makeBody` sits in an internal type: not public, not reported.
        #expect(try problems(files()) == [])
    }

    @Test("component API of a draft contract, of an own component, or of no contract is reported with the reason")
    func draftOwnAndAbsent() throws {
        let chip = try contract(
            contractYAML(id: "chip", status: "draft", variant: "[filter, input]", states: "[pressed]"), id: "chip")
        let draft = try problems(
            [try contract(contractYAML()), chip],
            files(extra: ["Chip/Chip.swift": "public enum ChipVariant: String { case filter }\n"]))
        #expect(draft.count == 1)
        #expect(
            draft[0].contains(
                "ChipVariant is named as Chip's API, but its contract (spec/components/chip/chip.spec.yaml) is draft"))

        let banner = try contract(
            contractYAML(id: "banner", variant: "[info, warning]", apple: "    strategy: own-component"), id: "banner")
        let own = try problems(
            [try contract(contractYAML()), banner], files(extra: ["Banner.swift": "public struct Banner {}\n"]))
        #expect(own.count == 1)
        // An own component that names no form (which the schema requires) has no API the lint could derive.
        #expect(
            own[0].contains(
                "is an own-component that names no form (modifier or view) in platforms.apple.form, so the "
                    + "conventions give it no API"))

        // In the token area too: a name that marks component API is never a token accessor.
        let absent = try problems(files(tokens: tokensSwift + "\npublic enum BadgeVariant { case info }\n"))
        #expect(absent.count == 1)
        #expect(absent[0].contains("BadgeVariant is named as component API (…Variant), and no contract gives it"))

        let styled = try problems(
            files(extra: [
                "Pill.swift":
                    "public struct PillLook: ButtonStyle { public func makeBody(configuration: Configuration) -> some View { configuration.label } }\n"
            ]))
        #expect(styled.contains { $0.contains("PillLook is a ButtonStyle, component API, and no contract gives it") })
    }

    @Test("a contract that is draft generates no expectation, so its absence is no problem")
    func draftExpectsNothing() throws {
        let generated = try generatedSwift()
        let draft = try contract(contractYAML(status: "draft"))
        let found = try problems([draft], files(generated: generated, states: "import SwiftUI\n"))
        // The generated enums and overload now belong to a draft contract.
        #expect(found.contains { $0.contains("public enum ButtonVariant: component API") && $0.contains("is draft") })
        #expect(found.contains { $0.contains("overload of a style modifier, but its contract") })
        #expect(!found.contains { $0.contains("missing") })
    }

    // MARK: The boundary

    @Test("public API that no contract gives is reported outside the token files")
    func boundary() throws {
        let outside = try problems(
            files(style: styleSwift + "\npublic struct Palette {\n    public var name = \"\"\n}\n"))
        #expect(outside.count == 1)
        #expect(outside[0].contains("public struct Palette: public API outside the component API"))

        let modifier = try problems(
            files(states: statesSwift + "\nextension View {\n    public func glow() -> some View { self }\n}\n"))
        #expect(modifier.count == 1)
        #expect(modifier[0].contains("public func View.glow: a public modifier on View that no contract gives"))
    }

    @Test("the adapters file holds only the reviewed adapters, each taking a westron value")
    func adapters() throws {
        // A new overload of a listed adapter, on a westron value, is an adapter.
        let accessor = "\nextension View {\n    public func tint(_ color: Westron.Color) -> some View { self }\n}\n"
        #expect(try problems(files(tokens: tokensSwift + accessor)) == [])

        let notWestron = try problems(
            files(tokens: tokensSwift + "\nextension View {\n    public func tint(_ v: Int) -> some View { self }\n}\n")
        )
        #expect(notWestron.count == 1)
        #expect(notWestron[0].contains("public func View.tint: a public modifier on View that no contract gives"))

        let unlisted = try problems(
            files(tokens: tokensSwift + "\nextension Color {\n    public static var brand: Color { .red }\n}\n"))
        #expect(unlisted.count == 1)
        #expect(unlisted[0].contains("public var Color.brand: not one of the reviewed adapters (APIParity.adapters)"))

        let newType = try problems(
            files(tokens: tokensSwift + "\npublic struct Palette {\n    public var name = \"\"\n}\n"))
        #expect(newType.count == 1)
        #expect(newType[0].contains("public struct Palette: not one of the reviewed adapters"))

        // The generated token files declare nested types and statics; a new top-level type there is reported.
        let generated = try problems(files(generatedTokens: generatedTokensSwift + "\npublic enum Spacing {}\n"))
        #expect(generated.count == 1)
        #expect(generated[0].contains("public enum Spacing: a new public top-level type in a generated token file"))
    }

    @Test("a reviewed adapter outside the adapters file is accepted in its own file only, with its own names")
    func otherAdapters() throws {
        let category = """
            extension View {
                public func category(_ category: Westron.Category?) -> some View { self }
            }

            """
        #expect(try problems(files(extra: ["Category.swift": category])) == [])

        // Anywhere else it is a modifier no contract gives.
        let elsewhere = try problems(files(extra: ["Context.swift": category]))
        #expect(elsewhere.count == 1)
        #expect(elsewhere[0].contains("public func View.category: a public modifier on View that no contract gives"))
        // The message names every place a reviewed adapter may live.
        #expect(
            elsewhere[0].contains(
                "a reviewed adapter in TokenAdapters.swift (APIParity.adapters) or in Category.swift "
                    + "(APIParity.otherAdapters)"))

        // The file holds only the names listed for it, each taking a westron value.
        let unlisted = try problems(
            files(extra: [
                "Category.swift": category
                    + "extension View {\n    public func listTint(_ c: Westron.Category?) -> some View { self }\n}\n"
            ]))
        #expect(unlisted.count == 1)
        #expect(unlisted[0].contains("public func View.listTint: a public modifier on View that no contract gives"))
        let notWestron = try problems(
            files(extra: [
                "Category.swift": "extension View {\n    public func category(_ c: String?) -> some View { self }\n}\n"
            ]))
        #expect(notWestron.count == 1)
        #expect(notWestron[0].contains("public func View.category: a public modifier on View that no contract gives"))
    }

    @Test("the token files let no component API through: style protocols, View modifiers, style overloads, new types")
    func tokenFilesBoundary() throws {
        let inputs: [(String, String)] = [
            (
                "extension PrimitiveButtonStyle where Self == BorderedProminentButtonStyle {\n"
                    + "    public static var primary: Self { .borderedProminent }\n}\n",
                "public var PrimitiveButtonStyle.primary: component API that no contract accounts for: "
                    + "PrimitiveButtonStyle.primary extends the style protocol PrimitiveButtonStyle"
            ),
            (
                "extension View {\n    public func primaryAction() -> some View { self }\n}\n",
                "public func View.primaryAction: a public modifier on View that no contract gives"
            ),
            (
                "extension View {\n    public func toggleStyle(_ v: Int) -> some View { self }\n}\n",
                "toggleStyle(_: Int) -> some View is an overload of a style modifier, and no contract gives it"
            ),
            (
                "extension Westron {\n    public enum Foo {\n        case a\n    }\n}\n",
                "public enum Westron.Foo: not one of the reviewed adapters"
            ),
        ]
        for (input, message) in inputs {
            let found = try problems(files(tokens: tokensSwift + "\n" + input))
            #expect(found.count == 1, "\(input)")
            #expect(found.first?.contains(message) == true, "\(found)")
            // Outside the token files too.
            #expect(try problems(files(extra: ["Extra.swift": input])).count == 1, "\(input)")
        }
        // Button's style protocol names Button's contract.
        let primary = try problems(files(tokens: tokensSwift + "\n" + inputs[0].0))
        #expect(primary.first?.contains("which Button's contract (spec/components/button/button.spec.yaml)") == true)
    }

    @Test("a contract named like a SwiftUI type does not claim the adapters on it, only new API")
    func contractNamedLikeSwiftUI() throws {
        let label = try contract(contractYAML(id: "label", status: "draft"), id: "label")
        let contracts = [try contract(contractYAML()), label]
        #expect(problems(contracts, try files()) == [])

        let newType = problems(contracts, try files(extra: ["Tint.swift": "public struct LabelTint {}\n"]))
        #expect(newType.count == 1)
        #expect(newType[0].contains("LabelTint is named as Label's API, but its contract"))

        let overload = problems(
            contracts,
            try files(extra: [
                "Tint.swift": "extension View {\n    public func labelStyle(_ v: Int) -> some View { self }\n}\n"
            ]))
        #expect(overload.count == 1)
        #expect(overload[0].contains("labelStyle(_: Int) -> some View is an overload of a style modifier"))

        let member = problems(
            contracts,
            try files(tokens: tokensSwift + "\nextension Label {\n    public func glow() -> some View { self }\n}\n"))
        #expect(member.count == 1)
        #expect(member[0].contains("public func Label.glow: not one of the reviewed adapters"))
    }

    // MARK: Per-OS differences

    @Test("public declarations under #if are reported, in the token area too")
    func conditions() throws {
        let generated = try generatedSwift().replacingOccurrences(
            of: "    case l\n", with: "    #if !os(watchOS)\n        case l\n    #endif\n")
        let cases = try problems(files(generated: generated))
        #expect(cases.count == 1)
        #expect(cases[0].contains("public API under #if !os(watchOS)"))

        let token = try problems(
            files(
                tokens: tokensSwift + """

                    #if os(macOS)
                        extension View {
                            public func tint(_ color: Westron.Color) -> some View { self }
                        }
                    #else
                        extension Text {
                            public func foregroundStyle(_ color: Westron.Color) -> Text { self }
                        }
                    #endif

                    """))
        #expect(token.count == 2)
        #expect(token[0].contains("public API under #if os(macOS)"))
        #expect(token[1].contains("public API under #else of #if os(macOS)"))

        // Internal code behind #if, as the generated tables have, is not API.
        #expect(
            try problems(
                files(
                    tokens: tokensSwift
                        + "\n#if os(macOS)\n    extension Double {\n        static var x: Double { 0 }\n    }\n#endif\n"
                )) == [])
    }

    // MARK: Exceptions

    @Test("the lint's own marker with a reason excuses unaccounted and per-OS API, never expected API")
    func allowMarker() throws {
        let allowed = try problems(
            files(
                states: statesSwift + """

                    extension View {
                        // westron-api-parity: allow a probe the catalog needs until #23
                        public func glow() -> some View { self }
                        #if os(macOS)
                            public func macGlow() -> some View { self }  // westron-api-parity: allow AppKit only
                        #endif
                    }

                    """))
        #expect(allowed == [])

        let withoutReason = try problems(
            files(
                states: statesSwift
                    + "\nextension View {\n    // westron-api-parity: allow\n    public func glow() -> some View { self }\n}\n"
            ))
        #expect(withoutReason.count == 1)

        let generated = try generatedSwift().replacingOccurrences(
            of: "    case secondary\n", with: "    case outlined  // westron-api-parity: allow renamed\n")
        #expect(try problems(files(generated: generated)).count == 1)
    }

    @Test("the raw-values lint's marker does not excuse public API")
    func rawValuesMarker() throws {
        let marked = """

            extension View {
                // westron-lint: allow the system's own spacing
                public func glow() -> some View { self }
                public func halo() -> some View { padding(4) }  // westron-lint: allow the system's own spacing
            }

            """
        let found = try problems(files(states: statesSwift + marked))
        #expect(found.count == 2)
        #expect(found.allSatisfy { $0.contains("a public modifier on View that no contract gives") })
        // The raw-values lint still takes its marker.
        #expect(RawValues.find(in: marked).isEmpty)
    }

    // MARK: Constraints and attributes on expected API

    @Test("an extension's where clause or availability on expected API is reported")
    func extensionConstraints() throws {
        let generated = try generatedSwift()
        let overload = try problems(
            files(
                generated: generated.replacingOccurrences(
                    of: "extension View {", with: "extension View where Self: Equatable {")))
        #expect(overload.count == 1)
        #expect(overload[0].contains("Button's style overload has `where Self: Equatable`, which changes where or how"))

        let state = try problems(
            files(
                states: statesSwift.replacingOccurrences(
                    of: "extension View {", with: "extension View where Self == Never {")))
        #expect(state.count == 1)
        #expect(state[0].contains("the state modifier of loading has `where Self == Never`"))

        let available = try problems(
            files(
                states: statesSwift.replacingOccurrences(
                    of: "extension View {", with: "@available(iOS 18, *)\nextension View {")))
        #expect(available.count == 1)
        #expect(available[0].contains("has `@available(iOS 18, *)`"))
    }

    @Test("harmless attributes on expected API pass; ones that change the call do not")
    func attributes() throws {
        let generated = try generatedSwift()
        for attribute in ["@MainActor", "nonisolated", "@inlinable", "@ViewBuilder", "@discardableResult"] {
            let marked = try problems(
                files(
                    generated: generated.replacingOccurrences(
                        of: "    public func buttonStyle(", with: "    \(attribute) public func buttonStyle("),
                    states: statesSwift.replacingOccurrences(
                        of: "    public func loading(", with: "    \(attribute) public func loading(")))
            #expect(marked == [], "\(attribute)")
        }
        for attribute in ["@_disfavoredOverload", "@_spi(Catalog)", "@backDeployed(before: iOS 18)"] {
            let marked = try problems(
                files(
                    states: statesSwift.replacingOccurrences(
                        of: "    public func loading(", with: "    \(attribute) public func loading(")))
            #expect(marked.count == 1, "\(attribute)")
        }
        let enumAttribute = try problems(
            files(
                generated: generated.replacingOccurrences(
                    of: "public enum ButtonSize", with: "@available(macOS 15, *) public enum ButtonSize")))
        #expect(enumAttribute.count == 1)
        #expect(enumAttribute[0].contains("ButtonSize has `@available(macOS 15, *)`"))
    }

    // MARK: System states per base control

    @Test("the system states come from the base control; an unknown base is reported")
    func systemStatesPerBase() throws {
        #expect(SystemStyles.byBase["SwiftUI.Button"]?.states == ["pressed", "hover", "focus", "disabled"])

        let picker = try contract(
            contractYAML(
                id: "segments", states: "[pressed, selected]",
                apple: "        strategy: style-on-system-control\n        base: SwiftUI.Picker"), id: "segments")
        let found = problems([try contract(contractYAML()), picker], try files())
        #expect(found.count == 1)
        #expect(
            found[0].hasPrefix(
                "spec/components/segments/segments.spec.yaml:14: no style modifier and no system states are known for "
                    + "SwiftUI.Picker (SystemStyles.byBase)"))
    }

    // MARK: Reading

    @Test("the reader finds cases, signatures, conditions and the effective access")
    func reader() {
        let source = """
            public enum E: String { case a, `default` = "d" }
            struct Hidden { public func f() {} }
            public extension Hidden { func g() {} }
            extension View {
                #if os(iOS)
                    public static func h<T>(_ x: T, y: Int = 1) async throws -> some View where T: View { x }
                #endif
            }
            """
        let declarations = SwiftDeclarations(files: [(path: "a.swift", text: source)]).declarations
        let byName = Dictionary(declarations.map { ($0.qualifiedName, $0) }, uniquingKeysWith: { a, _ in a })
        #expect(byName["E.a"]?.access == .public)
        #expect(byName["E.default"]?.rawValue == "\"d\"")
        #expect(byName["Hidden.f"]?.access == .internal)
        #expect(byName["Hidden.g"]?.access == .internal)
        let h = byName["View.h"]
        #expect(h?.access == .public)
        #expect(h?.isStatic == true)
        #expect(h?.conditions == ["#if os(iOS)"])
        #expect(h?.line == 6)
        #expect(h?.parameters == [.init(label: "_", type: "T"), .init(label: "y", type: "Int", defaultValue: "1")])
        #expect(h?.extras == ["<T>", "where T: View", "async throws"])
    }
}
