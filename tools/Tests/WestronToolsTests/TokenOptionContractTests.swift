import Foundation
import Testing
import WestronTools

/// A valid Text-shaped contract: an option whose values are the tokens of a group, on an extension of a system view.
/// It follows the draft Text contract (#27), but it is not westron's Text contract.
private let textFixture = """
    id: text
    status: draft
    consumers: [todo-app/list-screen]
    options:
      role: { type: tokens, group: typography }
    slots: [label]
    accessibility: { role: text }
    platforms:
      apple:
        strategy: extension-on-system-control
        base: SwiftUI.Text
        watchos: { description: The system font. }
      web: { status: planned }
      linux: { strategy: style-on-system-control, base: GtkLabel }
      android: { status: planned }

    """

private let textSource = "spec/components/text/text.spec.yaml"

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)

/// Typography roles; a group whose tokens differ in type, one with a primitive, one with a token missing from a mode.
private let tokens = ContractTokens(
    everywhere: [
        "typography.heading.large", "typography.body.regular", "typography.body.strong", "mixed.size", "mixed.ink",
        "font.weight.bold", "ladder.semantic", "ladder.primitive",
    ],
    somewhere: ["partial.dark": ["theme=dark, density=regular, platform=ios"], "partial.light": []],
    primitive: ["font.weight.bold", "ladder.primitive"],
    types: [
        "typography.heading.large": .typography, "typography.body.regular": .typography,
        "typography.body.strong": .typography, "mixed.size": .dimension, "mixed.ink": .color,
    ])

private func textProblems(_ yaml: String, source: String = textSource) -> [String] {
    ContractCheck.check(yaml: yaml, source: source, schema: schema, tokens: tokens)
        .map { "\($0.place): \($0.message)" }
}

private func replacing(_ old: String, with new: String, in text: String = textFixture) -> String {
    precondition(text.contains(old), old)
    return text.replacingOccurrences(of: old, with: new)
}

@Suite("Token-group options and extensions of system views")
struct TokenOptionContractTests {
    @Test("the Text-shaped fixture is valid, and so is a default among the group's tokens")
    func valid() {
        #expect(textProblems(textFixture) == [])
        #expect(
            textProblems(
                replacing(
                    "{ type: tokens, group: typography }",
                    with: "{ type: tokens, group: typography, default: body.regular }"))
                == [])
    }

    @Test("westron's typography is a valid group: the real tokens, in every mode, semantic, of one type")
    func realTokens() throws {
        let resolver = repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path
        let real = try ContractTokens(Resolution(resolverFile: resolver))
        #expect(ContractCheck.check(yaml: textFixture, source: textSource, schema: schema, tokens: real) == [])
        let primitive = ContractCheck.check(
            yaml: replacing("group: typography", with: "group: font.family"), source: textSource, schema: schema,
            tokens: real)
        #expect(
            primitive.map(\.message) == [
                "font.family holds primitive tokens (font.family.heading, font.family.mono, font.family.system): an "
                    + "option takes its values from semantic tokens (tokens/README.md)"
            ])
    }

    @Test("rule: the group exists, is a group, and holds semantic tokens of one type in every mode")
    func group() {
        func at(_ group: String) -> [String] { textProblems(replacing("group: typography", with: "group: \(group)")) }
        #expect(at("typograhy") == ["options.role.group: no token group typograhy in tokens/"])
        #expect(
            at("typography.heading.large.x") == [
                "options.role.group: no token group typography.heading.large.x in tokens/"
            ])
        #expect(
            at("typography.body.regular") == [
                "options.role.group: typography.body.regular is a token, not a group: name the group whose tokens "
                    + "are the option's values"
            ])
        #expect(
            at("font.weight") == [
                "options.role.group: font.weight holds primitive tokens (font.weight.bold): an option takes its values "
                    + "from semantic tokens (tokens/README.md)"
            ])
        #expect(
            at("ladder") == [
                "options.role.group: ladder holds primitive tokens (ladder.primitive): an option takes its values from "
                    + "semantic tokens (tokens/README.md)"
            ])
        #expect(
            at("mixed") == [
                "options.role.group: the tokens of mixed are of more than one type (color: mixed.ink; dimension: "
                    + "mixed.size): an option's values are tokens of one type; name a narrower group"
            ])
        let partial = at("partial")
        #expect(partial.count == 2)
        #expect(
            partial.first == "options.role.group: the token partial.dark does not exist in every mode: it is missing "
                + "from theme=dark, density=regular, platform=ios")
        // A group of one path segment is a path too; the schema rejects one that is not a token path.
        #expect(at("Typography").contains { $0.hasPrefix("options.role.group: ") })
        #expect(
            textProblems(replacing("{ type: tokens, group: typography }", with: "{ type: tokens }")) == [
                "options.role: Required property 'group' is missing"
            ])
    }

    @Test("rule: a default is one of the group's tokens, by its path after the group")
    func defaultValue() {
        #expect(
            textProblems(
                replacing(
                    "{ type: tokens, group: typography }",
                    with: "{ type: tokens, group: typography, default: body.medium }"))
                == [
                    "options.role.default: \"body.medium\" is not a token of typography: body.regular, body.strong, "
                        + "heading.large"
                ])
        // The full path is not a value: the values are paths after the group.
        #expect(
            textProblems(
                replacing(
                    "{ type: tokens, group: typography }",
                    with: "{ type: tokens, group: typography, default: typography.body.regular }")
            ).count == 1)
        // A token option lists no values.
        #expect(
            textProblems(
                replacing(
                    "{ type: tokens, group: typography }", with: "{ type: tokens, group: typography, values: [a] }")
            ).contains { $0.hasPrefix("options.role.values: ") || $0.hasPrefix("options.role: ") })
    }

    @Test("rule: constraints, cases and platform restrictions do not name a token-group option yet")
    func notNamedYet() {
        let flag = replacing(
            "  role: { type: tokens, group: typography }\n",
            with: "  role: { type: tokens, group: typography }\n  wraps: { type: bool, default: true }\n")
        #expect(
            textProblems(
                replacing(
                    "slots: [label]\n",
                    with: "slots: [label]\nconstraints:\n"
                        + "  - { when: { role: body }, require: { wraps: true }, severity: warning }\n", in: flag))
                == [
                    "constraints[0].when.role: role takes its values from the tokens of typography, and constraints "
                        + "do not name such an option yet"
                ])
        #expect(
            textProblems(
                replacing(
                    "slots: [label]\n",
                    with: "slots: [label]\ntokens:\n  label.color:\n    cases:\n"
                        + "      - { when: { role: body }, token: typography.body.regular }\n", in: flag))
                == [
                    "tokens.label.color.cases[0].when.role: role takes its values from the tokens of typography, and "
                        + "cases do not name such an option yet"
                ])
        #expect(
            textProblems(
                replacing(
                    "    watchos: { description: The system font. }\n",
                    with: "    watchos: { options: { role: [body] } }\n"))
                == [
                    "platforms.apple.watchos.options.role: role takes its values from the tokens of typography, and "
                        + "platform restrictions do not name such an option yet"
                ])
    }

    @Test("rule: the Apple strategy fits its base")
    func strategyAndBase() {
        let extensionEntry = "    strategy: extension-on-system-control\n    base: SwiftUI.Text\n"
        #expect(
            textProblems(
                replacing(extensionEntry, with: "    strategy: extension-on-system-control\n    base: SwiftUI.Button\n")
            )
                == [
                    "platforms.apple.strategy: SwiftUI.Button takes a style (buttonStyle), so westron gives it one: "
                        + "its component is a style-on-system-control (decisions/0003)"
                ])
        #expect(
            textProblems(
                replacing(extensionEntry, with: "    strategy: style-on-system-control\n    base: SwiftUI.Text\n"))
                == [
                    "platforms.apple.strategy: SwiftUI.Text has no style modifier, so a style cannot go on it: its "
                        + "component is an extension-on-system-control, which adds a modifier to it (decisions/0003)"
                ])
        let unknown = textProblems(
            replacing(extensionEntry, with: "    strategy: extension-on-system-control\n    base: SwiftUI.Slider\n"))
        #expect(unknown.count == 1)
        #expect(unknown.first?.hasPrefix("platforms.apple.base: the validator does not know SwiftUI.Slider: ") == true)
        #expect(
            textProblems(replacing(extensionEntry, with: "    strategy: extension-on-system-control\n"))
                == ["platforms.apple: Required property 'base' is missing"])
        // Off Apple the check knows no bases; the schema still wants one.
        #expect(
            textProblems(
                replacing(
                    "{ strategy: style-on-system-control, base: GtkLabel }",
                    with: "{ strategy: extension-on-system-control }"))
                == ["platforms.linux: Required property 'base' is missing"])
        #expect(
            textProblems(
                replacing(
                    "{ strategy: style-on-system-control, base: GtkLabel }",
                    with: "{ strategy: extension-on-system-control, base: GtkLabel }"))
                == [])
    }

    @Test("SystemStyles: a base without a style is not also a base with one")
    func systemStyles() {
        #expect(SystemStyles.withoutStyle.isDisjoint(with: SystemStyles.byBase.keys))
        #expect(SystemStyles.withoutStyle.contains("SwiftUI.Text"))
    }

    @Test("reading: a token-group option keeps its group and default")
    func reading() throws {
        let contract = try ComponentContract(yaml: textFixture, source: textSource)
        #expect(contract.options == [.init(name: "role", kind: .tokenGroup("typography", default: nil))])
        #expect(contract.apple?.strategy == "extension-on-system-control")
        #expect(contract.apple?.base == "SwiftUI.Text")
    }

    @Test("generation: a draft extension generates nothing; an approved one is not supported yet")
    func generation() throws {
        let draft = try ComponentContract(yaml: textFixture, source: textSource)
        #expect(!AppleComponents.generates(draft))
        #expect(try AppleComponents.files(for: [(draft, textSource)]) == [])
        let approved = try ComponentContract(
            yaml: replacing("status: draft", with: "status: approved"), source: textSource)
        do {
            _ = try AppleComponents.files(for: [(approved, textSource)])
            Issue.record("an approved extension-on-system-control generated")
        } catch let error as AppleComponents.Problems {
            #expect(
                error.problems.map(\.description) == [
                    "\(textSource): platforms.apple.strategy: the generator does not support "
                        + "extension-on-system-control yet: a contract of it stays draft until the generator, the API "
                        + "parity lint and the snapshot matrix give it API (spec/conventions.md)"
                ])
        }
    }

    @Test("generation: a style does not take a token-group option yet, nor does the snapshot matrix")
    func styleWithTokenOption() throws {
        let yaml = """
            id: button
            status: approved
            consumers: [todo-app/list-screen]
            options:
              variant: { type: enum, values: [primary] }
              ink: { type: tokens, group: color.text }
            accessibility: { role: button }
            platforms:
              apple: { strategy: style-on-system-control, base: SwiftUI.Button }
              web: { status: planned }
              linux: { status: planned }
              android: { status: planned }

            """
        let source = "spec/components/button/button.spec.yaml"
        let contract = try ComponentContract(yaml: yaml, source: source)
        #expect(throws: ContractProblem.self) { try AppleComponents.file(for: contract, source: source) }
        do {
            _ = try SnapshotMatrix(contract, source: source)
            Issue.record("the matrix took a token-group option")
        } catch {
            #expect(
                error.description
                    == "\(source): options.ink: ink takes its values from the tokens of color.text: the snapshot "
                    + "matrix does not support such an option yet")
        }
    }

    @Test("API parity: the text-role adapters stay reviewed adapters; other Text API is reported with the reason")
    func apiParity() throws {
        let root = "WestronUI"
        let adapters = """
            import SwiftUI
            import WestronTokens

            extension View {
                public func textRole(_ role: Westron.TextRole) -> some View { self }
            }

            """
        func check(_ status: String, extra: String = "") throws -> [String] {
            let yaml = replacing("status: draft", with: "status: \(status)")
            let contract = APIParity.Contract(
                contract: try ComponentContract(yaml: yaml, source: textSource), source: textSource, text: yaml)
            var files = [(path: "\(root)/TokenAdapters.swift", text: adapters)]
            if !extra.isEmpty { files.append((path: "\(root)/Text.swift", text: extra)) }
            return APIParity.check(contracts: [contract], files: files, sourceRoot: root).problems.map(\.description)
        }
        #expect(try check("draft") == [])
        #expect(try check("approved") == [])
        let draft = try check("draft", extra: "public enum TextRoleName { case body }\n")
        #expect(draft.count == 1)
        #expect(draft.first?.contains("its contract (\(textSource)) is draft, and a draft has no API") == true)
        let approved = try check("approved", extra: "public enum TextRoleName { case body }\n")
        #expect(approved.count == 1)
        #expect(
            approved.first?.contains(
                "its contract (\(textSource)) is an extension-on-system-control, whose API the generator does not give "
                    + "yet") == true)
    }
}
