import Foundation
import Testing
import WestronTools

/// A valid Button-shaped contract; tests replace parts of it. It is not westron's Button contract (#22).
let contractFixture = try! String(contentsOf: fixture("contracts/button/button.spec.yaml"), encoding: .utf8)

/// The path the fixture is checked under.
private let contractSource = "spec/components/button/button.spec.yaml"

private let contractSchema = try! ContractSchema(
    file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

/// The tokens the fixture binds, one that exists in some modes only, and one primitive.
private let contractTokens = ContractTokens(
    everywhere: [
        "color.background.accent", "color.background.muted", "color.status.danger.fill", "radius.control",
        "typography.body.strong", "color.cobalt.9",
    ],
    somewhere: ["shadow.mode": ["theme=dark, density=regular, platform=ios"]],
    primitive: ["color.cobalt.9"])

/// The problems of a contract written inline, as `place: message`.
private func contractProblems(_ yaml: String, source: String = contractSource) -> [String] {
    ContractCheck.check(yaml: yaml, source: source, schema: contractSchema, tokens: contractTokens)
        .map { "\($0.place): \($0.message)" }
}

/// The fixture with one text replaced, which must occur in it.
private func replacing(_ old: String, with new: String) -> String {
    precondition(contractFixture.contains(old), old)
    return contractFixture.replacingOccurrences(of: old, with: new)
}

/// Whether one problem is at `place` and its message contains `text` (any message when `text` is empty). Records the
/// problems found when none is.
private func has(
    _ problems: [String], _ place: String, _ text: String, sourceLocation: SourceLocation = #_sourceLocation
) -> Bool {
    let found = problems.contains { $0.hasPrefix("\(place): ") && (text.isEmpty || $0.contains(text)) }
    if !found { Issue.record("problems: \(problems)", sourceLocation: sourceLocation) }
    return found
}

@Suite("Component contracts")
struct ContractCheckTests {
    @Test("the Button-shaped fixture is valid")
    func valid() {
        #expect(contractProblems(contractFixture) == [])
    }

    @Test("the fixture's tokens exist in westron's tokens, in every mode, and are semantic")
    func realTokens() throws {
        let resolver = repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path
        let tokens = try ContractTokens(Resolution(resolverFile: resolver))
        let found = ContractCheck.check(
            yaml: contractFixture, source: contractSource, schema: contractSchema, tokens: tokens)
        #expect(found == [])
        let primitive = ContractCheck.check(
            yaml: replacing("radius.control", with: "font.family.system"), source: contractSource,
            schema: contractSchema, tokens: tokens)
        #expect(
            primitive.map(\.message) == [
                "font.family.system is a primitive token; bind a semantic one (tokens/README.md)"
            ])
    }

    @Test("finds the contracts one folder down, sorted")
    func files() throws {
        let directory = fixture("contracts").path
        let found = try ContractCheck.files(in: directory)
        #expect(found == ["\(directory)/button/button.spec.yaml", "\(directory)/invalid/invalid.spec.yaml"])
        #expect(try ContractCheck.files(in: directory + "/nothing") == [])
    }

    @Test("westron's contracts are valid")
    func realContracts() throws {
        let directory = repositoryRoot.appendingPathComponent(ContractCheck.defaultDirectory).path
        let files = try ContractCheck.files(in: directory)
        let resolver = repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path
        let tokens = try ContractTokens(Resolution(resolverFile: resolver))
        for file in files {
            let found = ContractCheck.check(file: file, schema: contractSchema, tokens: tokens)
            #expect(found == [], "\(file)")
        }
    }

    @Test("the invalid fixture reports its schema errors and the system style name together")
    func invalidFixture() {
        let file = fixture("contracts/invalid/invalid.spec.yaml").path
        let found = ContractCheck.check(file: file, schema: contractSchema, tokens: contractTokens)
            .map { "\($0.place): \($0.message)" }
        #expect(has(found, "(root)", "'consumers' is missing"))
        #expect(has(found, "status", "not one of the allowed values"))
        #expect(has(found, "options.variant.defualt", "unknown key"))
        #expect(has(found, "options.variant.values[0]", "\"plain\" is the name of a system style of SwiftUI.Button"))
        #expect(has(found, "options.size.default", "\"xl\" is not one of the values of size"))
        #expect(has(found, "tokens.container.background", "no token color.background.nothing"))
        #expect(found.allSatisfy { !$0.isEmpty })
    }

    // MARK: The schema

    @Test("the schema requires consumers, at least one, as <product>/<screen>")
    func consumers() {
        #expect(
            has(
                contractProblems(replacing("consumers: [todo-app/list-screen, todo-app/lists-screen]\n", with: "")),
                "(root)", "'consumers' is missing"))
        #expect(
            has(
                contractProblems(replacing("[todo-app/list-screen, todo-app/lists-screen]", with: "[]")), "consumers",
                ""))
        #expect(
            has(
                contractProblems(replacing("[todo-app/list-screen, todo-app/lists-screen]", with: "[pilot-app]")),
                "consumers[0]", ""))
    }

    @Test("the schema rejects unknown keys, statuses and ids that are not lowercase words")
    func strict() {
        #expect(has(contractProblems(replacing("slots:", with: "slot:")), "slot", "unknown key"))
        #expect(has(contractProblems(replacing("status: draft", with: "status: released")), "status", "allowed values"))
        #expect(has(contractProblems(replacing("id: button", with: "id: WButton")), "id", ""))
        #expect(
            has(
                contractProblems(replacing("default: secondary }", with: "default: secondary, defualt: m }")),
                "options.variant.defualt", "unknown key"))
    }

    @Test("the schema checks options: an enum has values and a default name, a bool a boolean default")
    func optionShapes() {
        #expect(
            has(
                contractProblems(replacing("type: bool, default: false }", with: "type: bool, default: no-no }")),
                "options.disabled.default", ""))
        #expect(
            has(
                contractProblems(replacing("values: [s, m, l], default: m", with: "default: m")), "options.size",
                "'values' is missing"))
        #expect(
            has(
                contractProblems(replacing("type: enum, values: [s, m, l]", with: "type: list, values: [s, m, l]")),
                "options.size.type", "allowed values"))
        #expect(
            has(
                contractProblems(replacing("values: [s, m, l]", with: "values: [s, M, l]")), "options.size.values[1]",
                ""))
    }

    @Test("the schema checks constraints, token bindings and accessibility")
    func otherShapes() {
        #expect(
            has(contractProblems(replacing("severity: error", with: "severity: fatal")), "constraints[0].severity", ""))
        #expect(
            has(
                contractProblems(replacing("    severity: warning\n", with: "")), "constraints[1]",
                "'severity' is missing"))
        #expect(has(contractProblems(replacing("container.radius:", with: "radius:")), "tokens.radius", "pattern"))
        #expect(
            has(
                contractProblems(replacing("radius.control", with: "\"{radius.control}\"")), "tokens.container.radius",
                "pattern"))
        #expect(has(contractProblems(replacing("  role: button\n", with: "")), "accessibility", "'role' is missing"))
    }

    @Test("the schema checks platforms: all four, planned or a strategy, a base only for a system control")
    func platformShapes() {
        #expect(
            has(
                contractProblems(replacing("  android:\n    status: planned\n", with: "")), "platforms",
                "'android' is missing")
        )
        #expect(
            has(
                contractProblems(
                    replacing("    status: planned", with: "    status: planned\n    strategy: own-component")),
                "platforms.android.strategy", "unknown key"))
        #expect(
            has(contractProblems(replacing("    base: GtkButton\n", with: "")), "platforms.linux", "'base' is missing"))
        let linux = "    strategy: style-on-system-control\n    base: GtkButton"
        #expect(contractProblems(replacing(linux, with: "    strategy: own-component")) == [])
        #expect(
            has(
                contractProblems(replacing(linux, with: "    strategy: own-component\n    base: GtkButton")),
                "platforms.linux.base", "is not allowed here"))
        #expect(
            has(contractProblems(replacing("    watchos:", with: "    tvos:")), "platforms.apple.tvos", "unknown key"))
    }

    @Test("an invalid YAML file and a repeated key are reported with their line")
    func yaml() {
        #expect(
            has(
                contractProblems(replacing("slots: [label, icon]", with: "slots: [label, icon")), "line 15",
                "invalid YAML"))
        #expect(
            has(
                contractProblems(replacing("slots: [label, icon]", with: "slots: [label]\nslots: [icon]")), "line 14",
                "repeats the key \"slots\""))
    }

    // MARK: The rules

    @Test("rule: the file is <id>/<id>.spec.yaml")
    func fileName() {
        #expect(contractProblems(contractFixture, source: "button/button.spec.yaml") == [])
        #expect(
            contractProblems(contractFixture, source: "spec/components/buttons/button.spec.yaml") == [
                "id: the id is \"button\", so the contract must be button/button.spec.yaml, not buttons/button.spec.yaml"
            ])
        #expect(
            has(
                contractProblems(contractFixture, source: "spec/components/button/Button.spec.yaml"), "id",
                "button/button.spec.yaml"))
        #expect(has(contractProblems(contractFixture, source: "button.spec.yaml"), "id", "button/button.spec.yaml"))
    }

    @Test("rule: an enum option's values are unique, and so are the names in every list")
    func repeats() {
        #expect(
            contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, m, l]")) == [
                "options.size.values[2]: repeats \"m\""
            ])
        #expect(
            contractProblems(replacing("slots: [label, icon]", with: "slots: [label, icon, label]")) == [
                "slots[2]: repeats \"label\""
            ])
        #expect(
            contractProblems(replacing("intents: [activate]", with: "intents: [activate, activate]"))
                == ["accessibility.intents[1]: repeats \"activate\""])
    }

    @Test("rule: an enum option's default is one of its values")
    func defaultValue() {
        #expect(
            contractProblems(replacing("default: secondary", with: "default: ghost")) == [
                "options.variant.default: \"ghost\" is not one of the values of variant: primary, secondary, tertiary, danger"
            ])
    }

    @Test("rule: no option value is the name of a system style of SwiftUI.Button (decisions/0003)")
    func systemStyles() {
        for name in [
            "plain", "bordered", "borderedProminent", "borderless", "automatic", "link", "glass", "glassProminent",
        ] {
            let found = contractProblems(
                replacing("[primary, secondary, tertiary, danger]", with: "[primary, secondary, \(name), danger]"))
            #expect(
                found.contains {
                    $0.hasPrefix(
                        "options.variant.values[2]: \"\(name)\" is the name of a system style of SwiftUI.Button")
                }, "\(name)")
        }
        // Every enum option is checked, not only the variant.
        #expect(
            contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, link]")) == [
                "options.size.values[2]: \"link\" is the name of a system style of SwiftUI.Button, so a call such as "
                    + ".link would be ambiguous (decisions/0003); choose another name"
            ])
    }

    @Test("rule: a base control the validator has no system styles for is an error; own components are not checked")
    func unknownBase() {
        #expect(
            has(
                contractProblems(replacing("base: SwiftUI.Button", with: "base: SwiftUI.Toggle")),
                "platforms.apple.base",
                "does not know the system styles of SwiftUI.Toggle"))
        let own = replacing(
            "    strategy: style-on-system-control\n    base: SwiftUI.Button", with: "    strategy: own-component")
        #expect(contractProblems(own.replacingOccurrences(of: "tertiary", with: "plain")) == [])
    }

    @Test("rule: constraints name options and values that exist")
    func constraints() {
        #expect(
            contractProblems(replacing("when: { variant: tertiary }", with: "when: { kind: tertiary }")) == [
                "constraints[0].when.kind: no option kind; the options are variant, size, disabled, loading"
            ])
        #expect(
            contractProblems(replacing("require: { size: [s, m] }", with: "require: { size: [s, xl] }")) == [
                "constraints[0].require.size[1]: \"xl\" is not one of the values of size: s, m, l"
            ])
        #expect(
            contractProblems(replacing("when: { loading: true }", with: "when: { loading: maybe }")) == [
                "constraints[1].when.loading: loading is a bool option: give true or false"
            ])
        #expect(
            contractProblems(replacing("when: { variant: tertiary }", with: "when: { variant: true }")) == [
                "constraints[0].when.variant: variant is an enum option: name its values, not true or false"
            ])
    }

    @Test("rule: token bindings use values of one enum option and tokens that exist, in every mode, not primitives")
    func tokens() {
        #expect(
            contractProblems(replacing("danger: color.status.danger.fill", with: "ghost: color.status.danger.fill"))
                == [
                    "tokens.container.background.ghost: \"ghost\" is not a value of any enum option"
                ])
        #expect(
            contractProblems(replacing("danger: color.status.danger.fill", with: "s: color.status.danger.fill")) == [
                "tokens.container.background: the keys must all be values of one enum option"
            ])
        #expect(
            contractProblems(replacing("radius.control", with: "radius.nothing")) == [
                "tokens.container.radius: no token radius.nothing in tokens/"
            ])
        #expect(
            contractProblems(replacing("radius.control", with: "shadow.mode")) == [
                "tokens.container.radius: the token shadow.mode does not exist in every mode: it is missing from "
                    + "theme=dark, density=regular, platform=ios"
            ])
        #expect(
            contractProblems(replacing("radius.control", with: "color.cobalt.9")) == [
                "tokens.container.radius: color.cobalt.9 is a primitive token; bind a semantic one (tokens/README.md)"
            ])
        #expect(
            contractProblems(replacing("color.background.muted", with: "color.background.nothing")) == [
                "tokens.container.background.secondary: no token color.background.nothing in tokens/"
            ])
    }

    @Test("rule: a binding by value names one option; values shared by two options are ambiguous")
    func ambiguousBinding() {
        let shared = replacing("values: [s, m, l], default: m", with: "values: [primary, danger], default: primary")
            .replacingOccurrences(of: "size: [s, m]", with: "size: [primary]")
            .replacingOccurrences(of: "options: { size: [m] }", with: "options: { size: [danger] }")
            .replacingOccurrences(of: "    secondary: color.background.muted\n", with: "")
        #expect(
            contractProblems(shared) == [
                "tokens.container.background: the keys are values of several options (size, variant): "
                    + "rename the values so that a binding names one option"
            ])
    }

    @Test("rule: a platform's restrictions are subsets of the declared values and states, an OS's of Apple's")
    func platformSubsets() {
        #expect(
            contractProblems(replacing("options: { size: [m] }", with: "options: { size: [m, xl] }")) == [
                "platforms.apple.watchos.options.size[1]: \"xl\" is not one of the values of size: s, m, l"
            ])
        #expect(
            contractProblems(replacing("options: { size: [m] }", with: "options: { sizes: [m] }")) == [
                "platforms.apple.watchos.options.sizes: no option sizes; the options are variant, size, disabled, loading"
            ])
        #expect(
            contractProblems(replacing("options: { size: [m] }", with: "options: { loading: [m] }")) == [
                "platforms.apple.watchos.options.loading: loading is a bool option: only enum options can be restricted"
            ])
        #expect(
            contractProblems(replacing("states: [pressed, disabled, loading]", with: "states: [pressed, selected]"))
                == [
                    "platforms.apple.watchos.states[1]: \"selected\" is not one of the states: hover, focus, pressed, disabled, loading"
                ])
        #expect(
            contractProblems(
                replacing(
                    "    base: SwiftUI.Button\n", with: "    base: SwiftUI.Button\n    options: { size: [s, l] }\n"))
                == ["platforms.apple.watchos.options.size[0]: \"m\" is not among the values Apple offers for size"])
        #expect(
            contractProblems(
                replacing("    base: GtkButton\n", with: "    base: GtkButton\n    states: [hover, hover]\n"))
                == ["platforms.linux.states[1]: repeats \"hover\""])
    }
}
