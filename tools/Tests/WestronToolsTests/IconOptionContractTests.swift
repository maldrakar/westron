import Foundation
import Testing
import WestronTools

/// A valid Icon-shaped contract: an option whose values are the icon registry's names, beside a system option, on an
/// extension of `SwiftUI.Image`. It follows the draft Icon contract (#28), but it is not westron's Icon contract.
private let iconFixture = """
    id: icon
    status: draft
    consumers: [todo-app/list-screen]
    options:
      glyph: { type: icons }
      scale: { type: enum, values: [small, medium, large], default: medium }
    slots: [label]
    accessibility: { role: image, label: optional }
    platforms:
      apple:
        strategy: extension-on-system-control
        base: SwiftUI.Image
        systemOptions: { scale: SwiftUI.Image.Scale }
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let iconSource = "spec/components/icon/icon.spec.yaml"

/// A component that adds no role of its own, as a surface or a rule does.
private let noRoleFixture = """
    id: rule
    status: draft
    consumers: [todo-app/list-screen]
    options:
      axis: { type: enum, values: [horizontal, vertical], default: horizontal }
    accessibility: { role: none }
    platforms:
      apple: { strategy: own-component, form: view }
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """

private let noRoleSource = "spec/components/rule/rule.spec.yaml"

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

private let tokens = ContractTokens(everywhere: ["color.border.default", "stroke.thin"])

private func problems(_ yaml: String, source: String) -> [String] {
    ContractCheck.check(yaml: yaml, source: source, schema: schema, tokens: tokens).map { "\($0.place): \($0.message)" }
}

private func replacing(_ old: String, with new: String, in text: String) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

@Suite("Icon-registry options")
struct IconOptionContractTests {
    private func iconProblems(_ old: String, _ new: String) -> [String] {
        problems(replacing(old, with: new, in: iconFixture), source: iconSource)
    }

    @Test("the Icon-shaped fixture is valid, on SwiftUI.Image, which takes no style")
    func valid() {
        #expect(problems(iconFixture, source: iconSource) == [])
        #expect(
            iconProblems("    strategy: extension-on-system-control\n", "    strategy: style-on-system-control\n") == [
                "platforms.apple.strategy: SwiftUI.Image has no style modifier, so a style cannot go on it: its "
                    + "component is an extension-on-system-control, which adds a modifier to it (decisions/0003)"
            ])
    }

    @Test("schema: an icons option lists no values and has no default")
    func schemaShape() {
        let withDefault = iconProblems("glyph: { type: icons }", "glyph: { type: icons, default: tray }")
        #expect(withDefault.count == 1)
        #expect(withDefault.first?.hasPrefix("options.glyph") == true)
        let withValues = iconProblems("glyph: { type: icons }", "glyph: { type: icons, values: [tray] }")
        #expect(withValues.count == 1)
        #expect(withValues.first?.hasPrefix("options.glyph") == true)
        #expect(iconProblems("glyph: { type: icons }", "glyph: { type: icon }").count == 1)
    }

    @Test("rule: constraints, cases, platform restrictions and systemOptions do not name an icons option")
    func notNamedYet() {
        let flag = replacing(
            "  scale: { type: enum",
            with: "  filled: { type: bool, default: false }\n  scale: { type: enum", in: iconFixture)
        #expect(
            problems(
                replacing(
                    "slots: [label]\n",
                    with: "slots: [label]\nconstraints:\n"
                        + "  - { when: { glyph: tray }, require: { filled: false }, severity: warning }\n", in: flag),
                source: iconSource)
                == [
                    "constraints[0].when.glyph: glyph takes its values from the icon registry (spec/icons/icons.yaml), "
                        + "and constraints do not name such an option yet"
                ])
        #expect(
            problems(
                replacing(
                    "slots: [label]\n",
                    with: "slots: [label]\ntokens:\n  glyph.color:\n    cases:\n"
                        + "      - { when: { glyph: tray }, token: color.border.default }\n", in: flag),
                source: iconSource)
                == [
                    "tokens.glyph.color.cases[0].when.glyph: glyph takes its values from the icon registry "
                        + "(spec/icons/icons.yaml), and cases do not name such an option yet"
                ])
        #expect(
            iconProblems(
                "    systemOptions: { scale: SwiftUI.Image.Scale }\n",
                "    systemOptions: { scale: SwiftUI.Image.Scale }\n    watchos: { options: { glyph: [tray] } }\n")
                == [
                    "platforms.apple.watchos.options.glyph: glyph takes its values from the icon registry "
                        + "(spec/icons/icons.yaml), and platform restrictions do not name such an option yet"
                ])
        #expect(
            iconProblems(
                "systemOptions: { scale: SwiftUI.Image.Scale }",
                "systemOptions: { scale: SwiftUI.Image.Scale, glyph: SwiftUI.Image }")
                == [
                    "platforms.apple.systemOptions.glyph: glyph takes its values from westron's icon registry "
                        + "(spec/icons/icons.yaml), not from a system type: remove it here"
                ])
    }

    @Test("reading: an icons option is read as such")
    func reading() throws {
        let contract = try ComponentContract(yaml: iconFixture, source: iconSource)
        #expect(
            contract.options == [
                .init(name: "glyph", kind: .icons(optional: false)),
                .init(name: "scale", kind: .enumeration(values: ["small", "medium", "large"], default: "medium")),
            ])
        #expect(contract.apple?.systemOptions == ["scale": "SwiftUI.Image.Scale"])
    }

    @Test("generation: a draft generates nothing; an approved one is reported as not supported yet")
    func generation() throws {
        let draft = try ComponentContract(yaml: iconFixture, source: iconSource)
        #expect(try AppleComponents.files(for: [(draft, iconSource)]) == [])
        #expect(
            try AppleSnapshotMatrix.files(for: [(draft, iconSource)]).map(\.path) == [
                AppleSnapshotMatrix.registryFile
            ])
        let approved = try ComponentContract(
            yaml: replacing("status: draft", with: "status: approved", in: iconFixture), source: iconSource)
        let unsupported =
            "\(iconSource): options.glyph: glyph takes its values from the icon registry: the conventions give an "
            + "extension-on-system-control no API for such an option yet, so the generator and the API parity lint "
            + "do not support it yet"
        do {
            _ = try AppleComponents.files(for: [(approved, iconSource)])
            Issue.record("an approved icons option generated")
        } catch let error as AppleComponents.Problems {
            #expect(error.problems.map(\.description) == [unsupported])
        }
        do {
            _ = try SnapshotMatrix(approved, source: iconSource)
            Issue.record("the matrix took an icons option without the registry's names")
        } catch {
            #expect(
                error.description
                    == "\(iconSource): options.glyph: glyph takes its values from the icon registry: the matrix needs "
                    + "its names")
        }
        let lint = APIParity.check(
            contracts: [
                APIParity.Contract(contract: approved, source: iconSource, text: iconFixture)
            ], files: [], sourceRoot: "WestronUI"
        ).problems.map(\.description)
        #expect(lint.count == 1)
        #expect(lint.first?.contains("the lint cannot derive Icon's API: glyph takes its values from the icon") == true)
    }

    @Test("generation: a style does not take an icons option every use names yet; an optional one, see below")
    func styleWithIconOption() throws {
        let yaml = """
            id: button
            status: approved
            consumers: [todo-app/list-screen]
            options:
              variant: { type: enum, values: [primary] }
              glyph: { type: icons }
            accessibility: { role: button }
            platforms:
              apple: { strategy: style-on-system-control, base: SwiftUI.Button }
              web: { status: planned }
              linux: { status: planned }
              android: { status: planned }

            """
        let source = "spec/components/button/button.spec.yaml"
        #expect(problems(yaml, source: source) == [])
        let contract = try ComponentContract(yaml: yaml, source: source)
        do {
            _ = try AppleComponents.file(for: contract, source: source)
            Issue.record("a style took an icons option")
        } catch {
            #expect(
                error.description
                    == "\(source): options.glyph: glyph takes its values from the icon registry and every use names "
                    + "one: the generator gives a style only an optional such option, optional: true, yet")
        }
        // The lint does not skip it: it says it cannot derive the overload, rather than expect one without it.
        let lint = APIParity.check(
            contracts: [APIParity.Contract(contract: contract, source: source, text: yaml)], files: [],
            sourceRoot: "WestronUI"
        ).problems.map(\.description)
        #expect(
            lint.contains {
                $0.contains(
                    "the lint cannot derive Button's style overload: the conventions give a style no argument for "
                        + "glyph, whose values are tokens or icons every use names")
            }, "\(lint)")
        #expect(!lint.contains { $0.contains("buttonStyle") }, "no overload is expected without the glyph: \(lint)")
    }
}

@Suite("Components with no role of their own")
struct NoRoleContractTests {
    private func noRoleProblems(_ old: String, _ new: String) -> [String] {
        problems(replacing(old, with: new, in: noRoleFixture), source: noRoleSource)
    }

    @Test("a component with role none and nothing for assistive technology to act on is valid")
    func valid() {
        #expect(problems(noRoleFixture, source: noRoleSource) == [])
        #expect(noRoleProblems("{ role: none }", "{ role: none, label: optional }") == [])
    }

    @Test("rule: role none takes no intents, keyboard intents, announced states or required label")
    func nothingToAnnounce() {
        let why = "the role is none: the component adds no role of its own, so assistive technology"
        #expect(
            noRoleProblems("{ role: none }", "{ role: none, intents: [activate] }") == [
                "accessibility.intents: \(why) has nothing to do with it; remove them, or give it its role"
            ])
        #expect(
            noRoleProblems("{ role: none }", "{ role: none, keyboardIntents: [activate] }") == [
                "accessibility.keyboardIntents: \(why) has nothing to do with it; remove them, or give it its role"
            ])
        #expect(
            noRoleProblems("{ role: none }", "{ role: none, label: required }") == [
                "accessibility.label: \(why) reads no label of it: a label is required only of a component with a "
                    + "role; make it optional, or give it its role"
            ])
        let withState = replacing(
            "accessibility: { role: none }",
            with: "states: [disabled]\naccessibility: { role: none, states: { disabled: disabled } }",
            in: noRoleFixture)
        #expect(
            problems(withState, source: noRoleSource) == [
                "accessibility.states: \(why) announces no state of it; remove them, or give it its role"
            ])
        #expect(
            noRoleProblems(
                "apple: { strategy: own-component, form: view }",
                "apple: { strategy: own-component, form: view, keyboardIntents: [x] }")
                == [
                    "platforms.apple.keyboardIntents: \(why) has nothing to do with it; remove them, or give it its "
                        + "role"
                ])
        // Another role is not held to it.
        #expect(noRoleProblems("{ role: none }", "{ role: separator, intents: [activate], label: required }") == [])
    }
}

@Suite("System styles of TextField and Toggle")
struct TextFieldAndToggleStylesTests {
    private let fieldFixture = """
        id: text-field
        status: draft
        consumers: [todo-app/list-screen]
        options:
          variant: { type: enum, values: [framed, inline] }
        accessibility: { role: textField }
        platforms:
          apple: { strategy: style-on-system-control, base: SwiftUI.TextField }
          web: { status: planned }
          linux: { status: planned }
          android: { status: planned }

        """

    @Test("a value named as a system style of TextField or Toggle is reported; westron's names pass")
    func styleNames() {
        let source = "spec/components/text-field/text-field.spec.yaml"
        #expect(problems(fieldFixture, source: source) == [])
        for style in ["automatic", "bordered", "plain", "roundedBorder", "squareBorder"] {
            let found = problems(
                replacing("[framed, inline]", with: "[framed, \(style)]", in: fieldFixture), source: source)
            #expect(
                found == [
                    "options.variant.values[1]: \"\(style)\" is the name of a system style of SwiftUI.TextField, so a "
                        + "call such as .\(style) would silently take westron's style instead of the system's "
                        + "(decisions/0003); choose another name"
                ], "\(style)")
        }
        let toggle = replacing(
            "base: SwiftUI.TextField", with: "base: SwiftUI.Toggle",
            in: replacing("id: text-field", with: "id: checkbox", in: fieldFixture))
        let toggleSource = "spec/components/checkbox/checkbox.spec.yaml"
        #expect(problems(replacing("[framed, inline]", with: "[check]", in: toggle), source: toggleSource) == [])
        for style in ["automatic", "button", "checkbox", "switch"] {
            let found = problems(
                replacing("[framed, inline]", with: "[check, \(style)]", in: toggle), source: toggleSource)
            #expect(found.count == 1, "\(style)")
            #expect(found.first?.contains("is the name of a system style of SwiftUI.Toggle") == true, "\(style)")
        }
    }

    @Test("the states TextField and Toggle carry themselves; checked is the Toggle's isOn")
    func states() {
        #expect(SystemStyles.byBase["SwiftUI.TextField"]?.states == ["focus", "hover", "disabled"])
        #expect(
            SystemStyles.byBase["SwiftUI.Toggle"]?.states == [
                "checked", "mixed", "pressed", "hover", "focus", "disabled",
            ])
    }
}
