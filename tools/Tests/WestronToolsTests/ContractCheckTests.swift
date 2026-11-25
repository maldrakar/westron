import Foundation
import Testing
import WestronTools

/// A valid Button-shaped contract; tests replace parts of it. It follows the owner's Button decisions, but it is not
/// westron's Button contract (#22).
let contractFixture = try! String(contentsOf: fixture("contracts/button/button.spec.yaml"), encoding: .utf8)

/// The fixture with constraints, which the Button decisions do not have.
private let constrainedFixture =
    contractFixture + """

        constraints:
          - when: { variant: tertiary }
            require: { size: [s, m] }
            severity: error
          - when: { iconOnly: true }
            require: { role: default }
            severity: warning

        """

/// The path the fixture is checked under.
private let contractSource = "spec/components/button/button.spec.yaml"

private let contractSchema = try! ContractSchema(
    file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

/// The tokens the fixture binds, one that exists in some modes only, and one primitive.
private let contractTokens = ContractTokens(
    everywhere: [
        "color.background.muted", "color.background.accent", "color.background.accent-hover",
        "color.background.hover", "color.background.pressed", "color.status.danger.fill",
        "color.status.danger.on-fill", "color.status.danger.text", "color.text.primary", "color.text.placeholder",
        "color.text.on-accent", "color.text.accent", "radius.control", "typography.body.strong", "color.cobalt.9",
    ],
    somewhere: ["shadow.mode": ["theme=dark, density=regular, platform=ios"]],
    primitive: ["color.cobalt.9"])

/// The problems of a contract written inline, as `place: message`.
private func contractProblems(_ yaml: String, source: String = contractSource) -> [String] {
    ContractCheck.check(yaml: yaml, source: source, schema: contractSchema, tokens: contractTokens)
        .map { "\($0.place): \($0.message)" }
}

/// A text with one part replaced, which must occur in it; the fixture by default.
private func replacing(_ old: String, with new: String, in text: String = contractFixture) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
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

/// The fixture with `container.background`'s cases replaced by these lines.
private func backgroundCases(_ cases: String) -> String {
    let start = contractFixture.range(of: "  container.background:\n")!
    let end = contractFixture.range(of: "  label.color:\n")!
    return contractFixture.replacingCharacters(
        in: start.lowerBound..<end.lowerBound, with: "  container.background:\n" + cases)
}

@Suite("Component contracts")
struct ContractCheckTests {
    @Test("the Button-shaped fixture is valid, with constraints too")
    func valid() {
        #expect(contractProblems(contractFixture) == [])
        #expect(contractProblems(constrainedFixture) == [])
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
        #expect(
            found == [
                "\(directory)/button/button.spec.yaml", "\(directory)/invalid/invalid.spec.yaml",
                "\(directory)/invalid-cases/invalid-cases.spec.yaml",
            ])
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
    }

    @Test("the second invalid fixture passes the schema and breaks each rule of cases, fallbacks and accessibility")
    func invalidCasesFixture() {
        let file = fixture("contracts/invalid-cases/invalid-cases.spec.yaml").path
        let found = ContractCheck.check(file: file, schema: contractSchema, tokens: contractTokens)
            .map { "\($0.place): \($0.message)" }
        #expect(found.count == 12)
        #expect(has(found, "options.state", "names the states in a case"))
        #expect(has(found, "tokens.container.background.cases[0].when.state", "\"selected\" is not one of the states"))
        #expect(has(found, "tokens.container.background.cases[3].when", "cases[2] matches everything"))
        #expect(has(found, "tokens.container.background.cases[4].when", "repeats the when of cases[2]"))
        #expect(has(found, "platforms.apple.watchos.options.size", "add fallback.size for l"))
        #expect(has(found, "platforms.linux.fallback.variant", "not restricted here"))
        #expect(has(found, "accessibility.states.loading", "not one of the states"))
        #expect(has(found, "platforms.apple.macos.keyboardIntents[0]", "already in accessibility.keyboardIntents"))
    }

    // MARK: The schema

    @Test("the schema requires consumers, at least one, as <product>/<screen>")
    func consumers() {
        let list = "[todo-app/list-screen, todo-app/lists-screen]"
        #expect(
            has(
                contractProblems(replacing("consumers: \(list)\n", with: "")), "(root)", "'consumers' is missing"))
        #expect(has(contractProblems(replacing(list, with: "[]")), "consumers", ""))
        #expect(has(contractProblems(replacing(list, with: "[pilot-app]")), "consumers[0]", ""))
    }

    @Test("the schema rejects unknown keys, statuses and ids that are not lowercase words")
    func strict() {
        #expect(has(contractProblems(replacing("slots:", with: "slot:")), "slot", "unknown key"))
        #expect(
            has(contractProblems(replacing("status: draft", with: "status: released")), "status", "allowed values"))
        #expect(has(contractProblems(replacing("id: button", with: "id: WButton")), "id", ""))
        #expect(
            has(
                contractProblems(replacing("default: secondary }", with: "default: secondary, defualt: m }")),
                "options.variant.defualt", "unknown key"))
    }

    @Test("the schema checks the context a component reads: a shared value's name, what it draws with it and without")
    func reads() throws {
        func reading(_ entry: String) -> String {
            replacing("\naccessibility:", with: "\nreads:\n" + entry + "accessibility:")
        }
        let valid = reading(
            "  category:\n    description: In a list's color, the fill is the list's.\n    unset: the accent.\n")
        #expect(contractProblems(valid) == [])
        #expect(try ComponentContract(yaml: valid, source: contractSource).reads == ["category"])
        // Only a value of westron's shared context, which its one shared modifier sets.
        #expect(
            has(
                contractProblems(reading("  alignsLeaves:\n    description: A leaf.\n    unset: no cell.\n")),
                "reads.alignsLeaves", "is not one of the allowed values: \"category\""))
        // What it draws without the value is required, and nothing else is allowed.
        #expect(
            has(
                contractProblems(reading("  category:\n    description: In a list's color.\n")), "reads.category",
                "'unset' is missing"))
        #expect(
            has(
                contractProblems(
                    reading("  category:\n    description: In a list's color.\n    unset: the accent.\n    from: x\n")),
                "reads.category.from", "unknown key"))
        // An empty block says nothing.
        #expect(has(contractProblems(replacing("\naccessibility:", with: "\nreads: {}\naccessibility:")), "reads", ""))
    }

    @Test("the schema checks options: an enum has values and may have a default name, a bool a boolean default")
    func optionShapes() {
        // Without a default, every use names a value, as the SwiftUI variant does (spec/conventions.md).
        #expect(contractProblems(replacing("tertiary], default: secondary }", with: "tertiary] }")) == [])
        #expect(
            has(
                contractProblems(replacing("type: bool\n    default: false", with: "type: bool\n    default: no-no")),
                "options.iconOnly.default", ""))
        #expect(
            has(
                contractProblems(replacing("    values: [s, m, l]\n", with: "")), "options.size",
                "'values' is missing"))
        #expect(
            has(
                contractProblems(
                    replacing("type: enum\n    values: [s, m, l]", with: "type: list\n    values: [s, m, l]")),
                "options.size.type", "allowed values"))
        #expect(
            has(
                contractProblems(replacing("values: [s, m, l]", with: "values: [s, M, l]")), "options.size.values[1]",
                ""))
    }

    @Test("the schema checks constraints, token bindings and accessibility")
    func otherShapes() {
        #expect(
            has(
                contractProblems(replacing("severity: error", with: "severity: fatal", in: constrainedFixture)),
                "constraints[0].severity", ""))
        #expect(
            has(
                contractProblems(replacing("    severity: warning\n", with: "", in: constrainedFixture)),
                "constraints[1]", "'severity' is missing"))
        #expect(
            has(contractProblems(replacing("container.radius:", with: "radius:")), "tokens.radius", "pattern"))
        #expect(
            has(
                contractProblems(replacing("radius.control", with: "\"{radius.control}\"")), "tokens.container.radius",
                "pattern"))
        #expect(
            has(
                contractProblems(replacing("token: color.text.primary", with: "default: color.text.primary")),
                "tokens.label.color.default", "unknown key"))
        #expect(
            has(
                contractProblems(replacing("{ variant: tertiary }, token: null", with: "{ variant: tertiary }")),
                "tokens.container.background.cases[9]", "'token' is missing"))
        #expect(has(contractProblems(replacing("  role: button\n", with: "")), "accessibility", "'role' is missing"))
        #expect(
            has(contractProblems(replacing("label: required", with: "label: always")), "accessibility.label", ""))
    }

    @Test("the schema checks platforms: all four, planned or a strategy, a base only for a system control")
    func platformShapes() {
        #expect(
            has(
                contractProblems(replacing("  android:\n    status: planned\n", with: "")), "platforms",
                "'android' is missing"))
        #expect(
            has(
                contractProblems(
                    replacing(
                        "  android:\n    status: planned",
                        with: "  android:\n    status: planned\n    strategy: own-component")),
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
                contractProblems(replacing("slots: [label, icon]", with: "slots: [label, icon")), "line 26",
                "invalid YAML"))
        #expect(
            has(
                contractProblems(replacing("slots: [label, icon]", with: "slots: [label]\nslots: [icon]")), "line 25",
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
            contractProblems(replacing("  intents: [activate]", with: "  intents: [activate, activate]"))
                == ["accessibility.intents[1]: repeats \"activate\""])
        #expect(
            contractProblems(replacing("state: [hover, pressed]", with: "state: [hover, hover]")) == [
                "tokens.container.background.cases[2].when.state[1]: repeats \"hover\""
            ])
    }

    @Test("rule: an enum option's default is one of its values")
    func defaultValue() {
        #expect(
            contractProblems(replacing("default: secondary", with: "default: ghost")) == [
                "options.variant.default: \"ghost\" is not one of the values of variant: primary, secondary, tertiary"
            ])
    }

    @Test("rule: no option value is the name of a system style of SwiftUI.Button (decisions/0003)")
    func systemStyles() {
        for name in [
            "plain", "bordered", "borderedProminent", "borderless", "automatic", "link", "glass", "glassProminent",
        ] {
            let found = contractProblems(
                replacing("[primary, secondary, tertiary]", with: "[primary, secondary, tertiary, \(name)]"))
            #expect(
                found.contains {
                    $0.hasPrefix(
                        "options.variant.values[3]: \"\(name)\" is the name of a system style of SwiftUI.Button")
                }, "\(name)")
        }
        // Every enum option is checked, not only the variant.
        #expect(
            contractProblems(replacing("values: [default, destructive]", with: "values: [default, destructive, link]"))
                == [
                    "options.role.values[2]: \"link\" is the name of a system style of SwiftUI.Button, so a call "
                        + "such as .link would silently take westron's style instead of the system's (decisions/0003); "
                        + "choose another name"
                ])
    }

    @Test("rule: a base control the validator has no system styles for is an error; own components are not checked")
    func unknownBase() {
        #expect(
            has(
                contractProblems(replacing("base: SwiftUI.Button", with: "base: SwiftUI.Picker")),
                "platforms.apple.base", "does not know the system styles of SwiftUI.Picker"))
        let own = replacing(
            "    strategy: style-on-system-control\n    base: SwiftUI.Button",
            with: "    strategy: own-component\n    form: view")
        #expect(contractProblems(own.replacingOccurrences(of: "tertiary", with: "plain")) == [])
    }

    @Test("rule: constraints name options and values that exist")
    func constraints() {
        func problems(_ old: String, _ new: String) -> [String] {
            contractProblems(replacing(old, with: new, in: constrainedFixture))
        }
        #expect(
            problems("- when: { variant: tertiary }", "- when: { kind: tertiary }") == [
                "constraints[0].when.kind: no option kind; the options are variant, size, role, iconOnly"
            ])
        #expect(
            problems("require: { size: [s, m] }", "require: { size: [s, xl] }") == [
                "constraints[0].require.size[1]: \"xl\" is not one of the values of size: s, m, l"
            ])
        #expect(
            problems("when: { iconOnly: true }", "when: { iconOnly: maybe }") == [
                "constraints[1].when.iconOnly: iconOnly is a bool option: give true or false"
            ])
        #expect(
            problems("- when: { variant: tertiary }", "- when: { variant: true }") == [
                "constraints[0].when.variant: variant is an enum option: name its values, not true or false"
            ])
        #expect(
            problems("- when: { variant: tertiary }", "- when: { state: hover }") == [
                "constraints[0].when.state: no option state; the options are variant, size, role, iconOnly"
            ])
    }

    @Test(
        "rule: a binding by value uses values of one enum option and tokens that exist, in every mode, not primitives")
    func tokens() {
        let radius = "  container.radius: radius.control"
        func byValue(_ map: String) -> [String] {
            contractProblems(replacing(radius, with: "  container.radius: { \(map) }"))
        }
        #expect(byValue("s: radius.control, m: radius.control, l: radius.control") == [])
        #expect(
            byValue("s: radius.control, xl: radius.control") == [
                "tokens.container.radius.xl: \"xl\" is not a value of any enum option"
            ])
        #expect(
            byValue("s: radius.control, primary: radius.control") == [
                "tokens.container.radius: the keys must all be values of one enum option"
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
            byValue("s: radius.control, m: color.background.nothing, l: radius.control") == [
                "tokens.container.radius.m: no token color.background.nothing in tokens/"
            ])
    }

    @Test("rule: a part's shape binds capsule, a shape no radius draws, and only a shape binds it")
    func shapes() {
        let radius = "  container.radius: radius.control"
        #expect(contractProblems(replacing(radius, with: "  container.shape: capsule")) == [])
        #expect(
            contractProblems(replacing(radius, with: "  container.radius: capsule")) == [
                "tokens.container.radius: capsule is a shape: bind it to a part's shape, such as container.shape"
            ])
        #expect(
            contractProblems(replacing(radius, with: "  container.shape: radius.control")) == [
                "tokens.container.shape: a part's shape is one of capsule, not a token"
            ])
        #expect(
            contractProblems(replacing(radius, with: "  container.shape: { s: capsule, m: capsule, l: capsule }"))
                .contains { $0.hasPrefix("tokens.container.shape") })
    }

    @Test("rule: a part's shape may be bound in cases, each case a shape; a shape in another binding's cases is not")
    func shapesInCases() {
        let radius = "  container.radius: radius.control"
        let cases = """
              container.shape:
                cases:
                  - { when: { size: s }, token: capsule }
            """
        #expect(contractProblems(replacing(radius, with: cases)) == [])
        #expect(
            contractProblems(
                replacing(radius, with: cases.replacingOccurrences(of: "token: capsule", with: "token: radius.control"))
            ) == ["tokens.container.shape.cases[0].token: a part's shape is one of capsule, not a token"])
        #expect(
            contractProblems(
                replacing(radius, with: cases.replacingOccurrences(of: "container.shape", with: "container.radius"))
            ) == [
                "tokens.container.radius.cases[0].token: capsule is a shape: bind it to a part's shape, such as "
                    + "container.shape"
            ])
    }

    @Test("rule: a binding by value gives every value of its option a token; a partial binding is written as cases")
    func partialBinding() {
        let radius = "  container.radius: radius.control"
        #expect(
            contractProblems(replacing(radius, with: "  container.radius: { s: radius.control, m: radius.control }"))
                == [
                    "tokens.container.radius: no token for l: a binding by value gives every value of size a token "
                        + "(s, m, l); a binding that leaves values without one is written as cases, with token: null"
                ])
        #expect(
            has(
                contractProblems(replacing(radius, with: "  container.radius: { m: radius.control }")),
                "tokens.container.radius", "no token for s, l"))
        // The same binding as cases, with no value for l, is valid.
        #expect(
            contractProblems(
                replacing(
                    radius,
                    with: """
                          container.radius:
                            token: radius.control
                            cases:
                              - { when: { size: l }, token: null }
                        """)) == [])
    }

    @Test("rule: a binding by value names one option; values shared by two options are ambiguous")
    func ambiguousBinding() {
        let shared = replacing(
            "    values: [s, m, l]\n    default: m", with: "    values: [primary, tertiary]\n    default: primary"
        )
        .replacingOccurrences(of: "options: { size: [m] }", with: "options: { size: [primary] }")
        .replacingOccurrences(of: "fallback: { size: m }", with: "fallback: { size: primary }")
        .replacingOccurrences(
            of: "  container.radius: radius.control",
            with: "  container.radius: { primary: radius.control, tertiary: radius.control }")
        #expect(
            contractProblems(shared) == [
                "tokens.container.radius: the keys are values of several options (size, variant): "
                    + "rename the values so that a binding names one option"
            ])
    }

    @Test("rule: a case names options, values and states that exist, and binds tokens that can be bound")
    func caseConditions() {
        #expect(
            contractProblems(
                backgroundCases("    cases:\n      - { when: { kind: primary }, token: radius.control }\n"))
                == [
                    "tokens.container.background.cases[0].when.kind: no option kind; the options are variant, size, "
                        + "role, iconOnly, and the key state names states"
                ])
        #expect(
            contractProblems(backgroundCases("    cases:\n      - { when: { role: danger }, token: radius.control }\n"))
                == [
                    "tokens.container.background.cases[0].when.role: \"danger\" is not one of the values of role: "
                        + "default, destructive"
                ])
        #expect(
            contractProblems(
                backgroundCases("    cases:\n      - { when: { state: [hover, selected] }, token: radius.control }\n"))
                == [
                    "tokens.container.background.cases[0].when.state[1]: \"selected\" is not one of the states: "
                        + "hover, focus, pressed, disabled, loading"
                ])
        #expect(
            contractProblems(
                backgroundCases("    cases:\n      - { when: { iconOnly: true }, token: radius.control }\n"))
                == [])
        #expect(
            contractProblems(
                backgroundCases(
                    "    token: color.cobalt.9\n    cases:\n      - { when: { iconOnly: true }, token: radius.nothing }\n"
                )) == [
                    "tokens.container.background.token: color.cobalt.9 is a primitive token; bind a semantic one "
                        + "(tokens/README.md)",
                    "tokens.container.background.cases[0].token: no token radius.nothing in tokens/",
                ])
    }

    @Test("rule: no case repeats or is shadowed by an earlier case, since the first match applies")
    func caseShadowing() {
        #expect(
            contractProblems(
                backgroundCases(
                    """
                        cases:
                          - { when: { variant: primary, state: hover }, token: radius.control }
                          - { when: { state: hover, variant: primary }, token: radius.control }

                    """)) == [
                    "tokens.container.background.cases[1].when: repeats the when of cases[0], so this case is never used"
                ])
        #expect(
            contractProblems(
                backgroundCases(
                    """
                        cases:
                          - { when: { variant: [primary, secondary] }, token: radius.control }
                          - { when: { variant: primary, role: destructive }, token: radius.control }

                    """)) == [
                    "tokens.container.background.cases[1].when: cases[0] matches everything this case matches, "
                        + "so it is never used: put the narrower case first"
                ])
        // The narrower case first is fine, and so are cases that overlap without one covering the other.
        #expect(
            contractProblems(
                backgroundCases(
                    """
                        cases:
                          - { when: { variant: primary, role: destructive }, token: radius.control }
                          - { when: { variant: [primary, secondary] }, token: radius.control }
                          - { when: { role: destructive }, token: radius.control }

                    """)) == [])
    }

    @Test("rule: a case that earlier cases cover together is never used, and the check names them")
    func caseReachability() {
        func problems(_ cases: String) -> [String] {
            contractProblems(backgroundCases("    cases:\n" + cases))
        }
        // An earlier case that lists every value of an option matches everything for it.
        #expect(
            problems(
                """
                      - { when: { variant: [primary, secondary, tertiary] }, token: radius.control }
                      - { when: { role: destructive }, token: radius.control }

                """) == [
                    "tokens.container.background.cases[1].when: cases[0] matches everything this case matches, so it "
                        + "is never used: put the narrower case first"
                ])
        // Two earlier cases together: hover, then pressed, cover hover or pressed.
        #expect(
            problems(
                """
                      - { when: { state: hover }, token: radius.control }
                      - { when: { state: pressed }, token: radius.control }
                      - { when: { state: [hover, pressed] }, token: radius.control }

                """) == [
                    "tokens.container.background.cases[2].when: cases[0] and cases[1] together match everything this "
                        + "case matches, so it is never used: put it before them, or remove it"
                ])
        // true and false of a bool option together match everything; the check names the cases that cover it, none
        // of them needless: cases[1] takes some of its combinations, but cases[0] and cases[2] cover it without.
        #expect(
            problems(
                """
                      - { when: { iconOnly: true }, token: radius.control }
                      - { when: { variant: primary }, token: radius.control }
                      - { when: { iconOnly: false }, token: radius.control }
                      - { when: { role: destructive }, token: radius.control }

                """) == [
                    "tokens.container.background.cases[3].when: cases[0] and cases[2] together match everything this "
                        + "case matches, so it is never used: put it before them, or remove it"
                ])
        // Three cases over two options: primary, the rest by role, then any destructive is covered.
        #expect(
            has(
                problems(
                    """
                          - { when: { variant: primary }, token: radius.control }
                          - { when: { variant: [secondary, tertiary], role: default }, token: radius.control }
                          - { when: { variant: [secondary, tertiary], role: destructive }, token: radius.control }
                          - { when: { role: destructive, iconOnly: true }, token: radius.control }

                    """), "tokens.container.background.cases[3].when", "cases[0] and cases[2] together"))
    }

    @Test("rule: a component can be in several states at once, or in none, and a case without state matches every set")
    func caseStates() {
        func problems(_ cases: String) -> [String] {
            contractProblems(backgroundCases("    cases:\n" + cases))
        }
        // hover alone does not cover hover or pressed: pressed alone still reaches the second case.
        #expect(
            problems(
                """
                      - { when: { state: hover }, token: radius.control }
                      - { when: { state: [hover, pressed] }, token: radius.control }

                """) == [])
        // hover or pressed covers hover, in any set of states.
        #expect(
            problems(
                """
                      - { when: { state: [hover, pressed] }, token: radius.control }
                      - { when: { state: hover }, token: radius.control }

                """) == [
                    "tokens.container.background.cases[1].when: cases[0] matches everything this case matches, so it "
                        + "is never used: put the narrower case first"
                ])
        // Every state named still leaves the component in no state, so a case without state is reached.
        #expect(
            problems(
                """
                      - { when: { state: [hover, focus, pressed, disabled, loading] }, token: radius.control }
                      - { when: { variant: primary }, token: radius.control }

                """) == [])
        // A state that excludes others goes first: a component in disabled and hover draws disabled, and hover alone
        // still reaches the second case.
        #expect(
            problems(
                """
                      - { when: { state: disabled }, token: radius.control }
                      - { when: { state: hover }, token: radius.control }
                      - { when: { variant: primary }, token: radius.control }

                """) == [])
        // A case whose conditions are wrong is reported there and not counted as covering anything.
        #expect(
            problems(
                """
                      - { when: { state: selected }, token: radius.control }
                      - { when: { state: hover }, token: radius.control }

                """) == [
                    "tokens.container.background.cases[0].when.state: \"selected\" is not one of the states: hover, "
                        + "focus, pressed, disabled, loading"
                ])
    }

    /// The fixture with more options, inserted before `iconOnly`, and `container.background`'s cases replaced.
    private func withOptions(_ options: [String], states: String? = nil, cases: String) -> String {
        var yaml = replacing(
            "  iconOnly:\n", with: options.map { "  \($0)\n" }.joined() + "  iconOnly:\n", in: backgroundCases(cases))
        if let states {
            yaml = replacing("states: [hover, focus, pressed, disabled, loading]", with: "states: \(states)", in: yaml)
        }
        return yaml
    }

    @Test("rule: cases with too many combinations of option values are reported, not checked for minutes")
    func caseLimit() {
        // 5 options of 8 values: 32 768 combinations.
        let options = (1...5).map { option in
            "o\(option): { type: enum, values: [\((1...8).map { "o\(option)v\($0)" }.joined(separator: ", "))] }"
        }
        let named = (1...5).map { "o\($0): o\($0)v1" }.joined(separator: ", ")
        #expect(
            contractProblems(
                withOptions(options, cases: "    cases:\n      - { when: { \(named) }, token: radius.control }\n")) == [
                    "tokens.container.background.cases: the cases name too many combinations of option values to "
                        + "check that each is used (32768, at most 20000)"
                ])
        // 10 options of 100 values: more than Int.max, which must not overflow into a small number.
        let huge = (1...10).map { option in
            "h\(option): { type: enum, values: [\((1...100).map { "h\(option)v\($0)" }.joined(separator: ", "))] }"
        }
        let all = (1...10).map { "h\($0): h\($0)v1" }.joined(separator: ", ")
        #expect(
            contractProblems(
                withOptions(huge, cases: "    cases:\n      - { when: { \(all) }, token: radius.control }\n")) == [
                    "tokens.container.background.cases: the cases name too many combinations of option values to "
                        + "check that each is used (more than \(Int.max), at most 20000)"
                ])
    }

    @Test("rule: states are not enumerated, so many states take no time and cannot overflow")
    func manyStates() {
        // 61 states and two bool options named together (4 × 2^61 combinations of states, if they were enumerated).
        let states = (1...61).map { "s\($0)" }
        let yaml = withOptions(
            ["b1: { type: bool, default: false }", "b2: { type: bool, default: false }"],
            states: "[hover, focus, pressed, disabled, loading, \(states.joined(separator: ", "))]",
            cases: """
                    cases:
                      - { when: { b1: true, b2: false, state: [\(states.joined(separator: ", "))] }, token: radius.control }
                      - { when: { b1: true, b2: false, state: s61 }, token: radius.control }

                """)
        #expect(
            contractProblems(yaml) == [
                "tokens.container.background.cases[1].when: cases[0] matches everything this case matches, so it is "
                    + "never used: put the narrower case first"
            ])
    }

    @Test("rule: an option without values, or a case with an empty list, is reported, never trapped on")
    func emptyConditions() {
        for values in ["[]", "[on, off]"] {
            let yaml = withOptions(
                ["tone: { type: enum, values: \(values) }"],
                cases: """
                        cases:
                          - { when: { tone: [] }, token: radius.control }
                          - { when: { variant: primary }, token: radius.control }

                    """)
            let problems = contractProblems(yaml)
            #expect(problems.contains { $0.hasPrefix("tokens.container.background.cases[0].when.tone: ") }, "\(values)")
            #expect(!problems.contains { $0.contains("never used") }, "\(values)")
        }
    }

    @Test("rule: a binding's token that the cases leave no room for is never used, and the check names those cases")
    func deadBaseToken() {
        #expect(
            contractProblems(
                backgroundCases(
                    """
                        token: radius.control
                        cases:
                          - { when: { iconOnly: true }, token: radius.control }
                          - { when: { variant: primary }, token: radius.control }
                          - { when: { iconOnly: false }, token: radius.control }

                    """)) == [
                    "tokens.container.background.token: cases[0] and cases[2] together match every combination, so "
                        + "this token is never used: remove it"
                ])
        // Cases that name states leave the component in no state to the token.
        #expect(
            contractProblems(
                backgroundCases(
                    """
                        token: radius.control
                        cases:
                          - { when: { state: [hover, focus, pressed, disabled, loading] }, token: radius.control }

                    """)) == [])
        // A case left out of the check, here for an unknown value, could be what leaves room: nothing is claimed.
        #expect(
            contractProblems(
                backgroundCases(
                    """
                        token: radius.control
                        cases:
                          - { when: { iconOnly: true }, token: radius.control }
                          - { when: { variant: ghost }, token: radius.control }
                          - { when: { iconOnly: false }, token: radius.control }

                    """)
            ).count == 1)
    }

    @Test("rule: no option is named state, the key a case gives to states")
    func reservedStateName() {
        #expect(
            contractProblems(replacing("  iconOnly:\n", with: "  state:\n")) == [
                "options.state: \"state\" names the states in a case of a token binding; give the option another name"
            ])
    }

    @Test("rule: a platform's restrictions are subsets of the declared values and states, an OS's of Apple's")
    func platformSubsets() {
        #expect(
            contractProblems(replacing("options: { size: [m] }", with: "options: { size: [m, xl] }")) == [
                "platforms.apple.watchos.options.size[1]: \"xl\" is not one of the values of size: s, m, l"
            ])
        #expect(
            has(
                contractProblems(replacing("options: { size: [m] }", with: "options: { sizes: [m] }")),
                "platforms.apple.watchos.options.sizes", "no option sizes"))
        #expect(
            has(
                contractProblems(replacing("options: { size: [m] }", with: "options: { size: [m], iconOnly: [m] }")),
                "platforms.apple.watchos.options.iconOnly", "only enum options can be restricted"))
        #expect(
            contractProblems(replacing("states: [pressed, disabled, loading]", with: "states: [pressed, selected]"))
                == [
                    "platforms.apple.watchos.states[1]: \"selected\" is not one of the states: hover, focus, pressed, "
                        + "disabled, loading"
                ])
        #expect(
            contractProblems(
                replacing(
                    "    base: SwiftUI.Button\n",
                    with: "    base: SwiftUI.Button\n    options: { size: [s, m] }\n    fallback: { size: m }\n"))
                == [])
        #expect(
            contractProblems(
                replacing(
                    "    base: SwiftUI.Button\n",
                    with: "    base: SwiftUI.Button\n    options: { size: [s, l] }\n    fallback: { size: s }\n"))
                == ["platforms.apple.watchos.options.size[0]: \"m\" is not among the values Apple offers for size"])
        #expect(
            contractProblems(
                replacing("    base: GtkButton\n", with: "    base: GtkButton\n    states: [hover, hover]\n"))
                == ["platforms.linux.states[1]: repeats \"hover\""])
    }

    @Test("rule: a fallback maps values a platform drops to values it keeps; on Apple every dropped value has one")
    func fallbacks() {
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: { s: m, l: m } }")) == [])
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: l }")) == [
                "platforms.apple.watchos.fallback.size: \"l\" is not among the values kept here: m"
            ])
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: { s: m, m: m, l: m } }")) == [
                "platforms.apple.watchos.fallback.size.m: \"m\" is not a value dropped here; dropped: s, l"
            ])
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: { s: m } }")) == [
                "platforms.apple.watchos.options.size: on Apple every dropped value needs a fallback, since the OSes "
                    + "share one generated enum: add fallback.size for l"
            ])
        #expect(
            contractProblems(replacing("      fallback: { size: m }\n", with: "")) == [
                "platforms.apple.watchos.options.size: on Apple every dropped value needs a fallback, since the OSes "
                    + "share one generated enum: add fallback.size for s, l"
            ])
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: m, variant: primary }")) == [
                "platforms.apple.watchos.fallback.variant: variant is not restricted here: a fallback goes next to "
                    + "the option's restriction"
            ])
        // Outside Apple a fallback is optional, and checked when given.
        let linux = "    base: GtkButton\n"
        #expect(contractProblems(replacing(linux, with: linux + "    options: { size: [m, l] }\n")) == [])
        #expect(
            contractProblems(
                replacing(linux, with: linux + "    options: { size: [m, l] }\n    fallback: { size: s }\n"))
                == ["platforms.linux.fallback.size: \"s\" is not among the values kept here: m, l"])
    }

    @Test("rule: on Apple, Apple's fallback comes first, then the OS's, and every value reaches one the OS offers")
    func fallbackChains() {
        let apple = "    base: SwiftUI.Button\n"
        let chained = replacing(apple, with: apple + "    options: { size: [m, l] }\n    fallback: { size: l }\n")
        // s falls back to l on Apple, and l to m on watchOS: s draws m there.
        #expect(contractProblems(chained) == [])
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: { l: m } }", in: chained))
                == [])
        #expect(
            contractProblems(replacing("      fallback: { size: m }\n", with: "", in: chained)) == [
                "platforms.apple.watchos.options.size: on Apple every dropped value needs a fallback, since the OSes "
                    + "share one generated enum: add fallback.size for l (Apple's fallback comes first: s → l, then "
                    + "this OS's)"
            ])
        // The OS maps what Apple keeps; a value Apple already dropped is not the OS's to map.
        #expect(
            contractProblems(replacing("fallback: { size: m }", with: "fallback: { size: { s: m } }", in: chained)) == [
                "platforms.apple.watchos.fallback.size.s: \"s\" is not a value dropped here; dropped: l",
                "platforms.apple.watchos.options.size: on Apple every dropped value needs a fallback, since the OSes "
                    + "share one generated enum: add fallback.size for l (Apple's fallback comes first: s → l, then "
                    + "this OS's)",
            ])
    }

    @Test(
        "rule: an unquoted YAML 1.1 boolean word is reported by name, and true, false or a number where a name is meant"
    )
    func yamlWords() {
        #expect(
            contractProblems(
                replacing("when: { iconOnly: true }", with: "when: { iconOnly: yes }", in: constrainedFixture))
                == [
                    "constraints[1].when.iconOnly: YAML 1.1 reads yes as the boolean true: write a boolean as true or "
                        + "false, and quote a name, \"yes\""
                ])
        #expect(
            contractProblems(backgroundCases("    cases:\n      - { when: { iconOnly: On }, token: radius.control }\n"))
                == [
                    "tokens.container.background.cases[0].when.iconOnly: YAML 1.1 reads On as the boolean true: write a "
                        + "boolean as true or false, and quote a name, \"On\""
                ])
        #expect(
            contractProblems(replacing("type: bool\n    default: false", with: "type: bool\n    default: off")) == [
                "options.iconOnly.default: YAML 1.1 reads off as the boolean false: write a boolean as true or false, "
                    + "and quote a name, \"off\""
            ])
        #expect(
            contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, on]")) == [
                "options.size.values[2]: YAML 1.1 reads on as the boolean true: write a boolean as true or false, and "
                    + "quote a name, \"on\""
            ])
        #expect(contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, \"on\"]")) == [])
        #expect(
            contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, true]")) == [
                "options.size.values[2]: YAML reads true as a boolean, but text is expected here: quote it, \"true\""
            ])
        #expect(
            contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, 12]")) == [
                "options.size.values[2]: YAML reads 12 as a number, but text is expected here: quote it, \"12\""
            ])
        // Where the schema does not expect text, its own message stays: quoting would be the wrong advice.
        let numericDefault = contractProblems(
            replacing("type: bool\n    default: false", with: "type: bool\n    default: 1"))
        #expect(numericDefault.count == 1)
        #expect(numericDefault.first?.hasPrefix("options.iconOnly.default: Expected type") == true, "\(numericDefault)")
        #expect(
            contractProblems(replacing("slots: [label, icon]", with: "slots: [label, no]")) == [
                "slots[1]: YAML 1.1 reads no as the boolean false: write a boolean as true or false, and quote a name, "
                    + "\"no\""
            ])
    }

    @Test("rule: a key YAML reads as a boolean is reported, and the value under it is still checked")
    func yamlKeys() {
        func radius(_ map: String) -> [String] {
            contractProblems(replacing("  container.radius: radius.control", with: "  container.radius: { \(map) }"))
        }
        let keyProblems = [
            "tokens.container.radius.off: YAML reads the key off as a boolean, not a name: quote it, \"off\"",
            "tokens.container.radius.off: \"off\" is not a value of any enum option",
        ]
        #expect(radius("s: radius.control, m: radius.control, l: radius.control, off: radius.control") == keyProblems)
        #expect(
            radius("s: radius.control, m: radius.control, l: radius.control, off: radius.nothing")
                == keyProblems + ["tokens.container.radius.off: no token radius.nothing in tokens/"])
        let number = radius("s: radius.control, m: radius.control, l: radius.control, off: 12")
        #expect(
            number.contains(
                "tokens.container.radius.off: YAML reads 12 as a number, but text is expected here: quote it, \"12\""),
            "\(number)")
        #expect(number.contains(keyProblems[0]))
    }

    @Test("rule: an option the platform gives to its system's API cannot be restricted there, on Apple or an Apple OS")
    func restrictedSystemOption() {
        let apple = "    base: SwiftUI.Button\n"
        let system = replacing(apple, with: apple + "    systemOptions: { role: SwiftUI.ButtonRole }\n")
        #expect(contractProblems(system) == [])
        #expect(
            contractProblems(
                replacing(
                    "options: { size: [m] }\n      fallback: { size: m }",
                    with: "options: { size: [m], role: [default] }\n      fallback: { size: m, role: default }",
                    in: system)) == [
                    "platforms.apple.watchos.options.role: role is a system option here "
                        + "(platforms.apple.systemOptions.role: SwiftUI.ButtonRole), so its values are the "
                        + "system's: the generator makes no type for it, and a restriction or a fallback would be "
                        + "dropped; remove them, or say in the description what the system does"
                ])
        #expect(
            has(
                contractProblems(
                    replacing(
                        "    systemOptions: { role: SwiftUI.ButtonRole }\n",
                        with: "    systemOptions: { role: SwiftUI.ButtonRole }\n    options: { role: [default] }\n"
                            + "    fallback: { role: default }\n", in: system)),
                "platforms.apple.options.role", "role is a system option here"))
    }

    @Test("rule: no option value or state is a word Swift cannot use as a case, and no option an argument label")
    func swiftNames() {
        let variants = "[primary, secondary, tertiary]"
        #expect(
            contractProblems(replacing(variants, with: "[primary, secondary, tertiary, init]")) == [
                "options.variant.values[3]: \"init\" cannot be a value: Swift reads .init as the enum's initializer, so "
                    + "the generated code does not compile; choose another name"
            ])
        #expect(
            has(
                contractProblems(replacing(variants, with: "[primary, secondary, tertiary, self]")),
                "options.variant.values[3]", "Swift reads <Type>.self as the type itself"))
        #expect(
            has(
                contractProblems(replacing("values: [s, m, l]", with: "values: [s, m, l, none]")),
                "options.size.values[3]", "Swift reads .none as nil"))
        #expect(
            has(
                contractProblems(
                    replacing("states: [hover, focus, pressed, disabled, loading]", with: "states: [hover, init]")),
                "states[1]", "\"init\" cannot be a state"))
        #expect(
            contractProblems(replacing("  iconOnly:\n", with: "  inout:\n")) == [
                "options.inout: inout cannot name an option: in Swift it becomes an argument label of the style "
                    + "overload, where inout is a keyword; choose another name"
            ])
        // A keyword is declared in backticks, and some is not Optional's: both compile (probed with Xcode 27.1).
        #expect(contractProblems(replacing(variants, with: "[primary, secondary, tertiary, some, in]")) == [])
    }

    @Test("rule: the states assistive technology announces are states of the contract")
    func accessibilityStates() {
        #expect(
            contractProblems(replacing("loading: busy }", with: "loading: busy, selected: selected }")) == [
                "accessibility.states.selected: \"selected\" is not one of the states: hover, focus, pressed, "
                    + "disabled, loading"
            ])
    }

    @Test("rule: a platform's systemOptions name options of the contract, each with the system API that carries it")
    func systemOptions() {
        let apple = "    base: SwiftUI.Button\n    description: The focus ring is the system's.\n    ios:"
        func with(_ field: String) -> String {
            replacing(
                apple,
                with:
                    "    base: SwiftUI.Button\n    \(field)\n    description: The focus ring is the system's.\n    ios:"
            )
        }
        #expect(contractProblems(with("systemOptions: { role: SwiftUI.ButtonRole }")) == [])
        #expect(
            contractProblems(with("systemOptions: { kind: SwiftUI.ButtonRole }")) == [
                "platforms.apple.systemOptions.kind: no option kind; the options are variant, size, role, iconOnly"
            ])
        #expect(
            contractProblems(with("systemOptions: { role: 'not a type' }")).contains {
                $0.hasPrefix("platforms.apple.systemOptions.role: ")
            })
        #expect(
            contractProblems(with("systemOptions: {}")).contains { $0.hasPrefix("platforms.apple.systemOptions: ") })
    }

    @Test("rule: a platform's keyboard intents add to the component's, an OS's to Apple's")
    func platformKeyboardIntents() {
        #expect(
            contractProblems(replacing("[defaultAction, cancelAction]", with: "[defaultAction, activate]")) == [
                "platforms.apple.macos.keyboardIntents[1]: \"activate\" is already in accessibility.keyboardIntents; "
                    + "list here only what this platform adds"
            ])
        #expect(
            contractProblems(
                replacing(
                    "    description: The focus ring is the system's.\n    ios:",
                    with:
                        "    keyboardIntents: [cancelAction]\n    description: The focus ring is the system's.\n    ios:"
                ))
                == [
                    "platforms.apple.macos.keyboardIntents[1]: \"cancelAction\" is already in Apple's keyboardIntents; "
                        + "list here only what this OS adds"
                ])
        #expect(
            contractProblems(replacing("[defaultAction, cancelAction]", with: "[defaultAction, defaultAction]")) == [
                "platforms.apple.macos.keyboardIntents[1]: repeats \"defaultAction\""
            ])
    }
}
