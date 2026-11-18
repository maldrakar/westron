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
        // A binding by value keyed by the option's tokens: the schema rejects the dotted keys as names, and the rule
        // says why the option cannot be named there.
        let byValue = textProblems(
            replacing(
                "slots: [label]\n",
                with: "slots: [label]\ntokens:\n  label.font: { heading.large: typography.heading.large, "
                    + "body.regular: typography.body.regular, body.strong: typography.body.strong }\n"))
        #expect(
            byValue.contains(
                "tokens.label.font: role takes its values from the tokens of typography, and bindings by value do not "
                    + "name such an option yet"))
        #expect(!byValue.contains { $0.contains("is not a value of any enum option") })
    }

    @Test("rule: a token-group option is never a system option: its values are westron's tokens")
    func notSystemOption() {
        #expect(
            textProblems(
                replacing(
                    "    base: SwiftUI.Text\n",
                    with: "    base: SwiftUI.Text\n    systemOptions: { role: SwiftUI.Font }\n"))
                == [
                    "platforms.apple.systemOptions.role: role takes its values from the tokens of typography, which "
                        + "are westron's, not the system's: a system option's values are its system type's; remove it "
                        + "here"
                ])
        #expect(
            textProblems(
                replacing(
                    "{ strategy: style-on-system-control, base: GtkLabel }",
                    with: "{ strategy: style-on-system-control, base: GtkLabel, systemOptions: { role: GtkLabel } }")
            )
            .count == 1)
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

    @Test("generation: an extension gives API once approved, and the generator writes no file for it")
    func generation() throws {
        let draft = try ComponentContract(yaml: textFixture, source: textSource)
        #expect(!AppleComponents.generates(draft))
        #expect(!AppleComponents.givesAPI(draft))
        #expect(try AppleComponents.files(for: [(draft, textSource)]) == [])
        let approved = try ComponentContract(
            yaml: replacing("status: draft", with: "status: approved"), source: textSource)
        #expect(!AppleComponents.generates(approved), "no Swift file: the modifier is hand-written")
        #expect(AppleComponents.givesAPI(approved))
        #expect(try AppleComponents.files(for: [(approved, textSource)]) == [])
        #expect(try AppleComponents.file(for: approved, source: textSource) == nil)
    }

    @Test("generation: the extension's API comes from the option's token accessor: .textRole(_: Westron.TextRole)")
    func extensionAPI() throws {
        let approved = replacing("status: draft", with: "status: approved")
        let api = try AppleComponents.Extension(
            ComponentContract(yaml: approved, source: textSource), source: textSource)
        #expect(api.component == "Text")
        #expect(api.base == "SwiftUI.Text")
        #expect(api.control == "Text")
        #expect(api.modifier == "textRole")
        #expect(api.option == "role")
        #expect(api.argumentType == "Westron.TextRole")
        #expect(api.defaultValue == nil)
        #expect(api.onBase, "Text's own modifiers return Text, so it gets the twin")
        #expect(AppleComponents.tokenAccessors == ["typography": "Westron.TextRole"])
        let withDefault = try AppleComponents.Extension(
            ComponentContract(
                yaml: replacing(
                    "{ type: tokens, group: typography }",
                    with: "{ type: tokens, group: typography, default: body.regular }",
                    in: approved), source: textSource), source: textSource)
        #expect(withDefault.defaultValue == ".body.regular")
    }

    @Test("generation: an extension of another shape fails, naming the place")
    func extensionShapes() throws {
        let approved = replacing("status: draft", with: "status: approved")
        func problems(_ yaml: String) throws -> [String] {
            do {
                _ = try AppleComponents.files(for: [(ComponentContract(yaml: yaml, source: textSource), textSource)])
                return []
            } catch let error as AppleComponents.Problems {
                return error.problems.map { "\($0.place): \($0.message)" }
            }
        }
        let shape =
            "an extension-on-system-control takes one option, whose values are tokens, as the argument of its "
            + "modifier, and no states: the conventions give it no other API yet (spec/conventions.md, \"Extensions "
            + "of a system view\")"
        #expect(
            try problems(
                replacing(
                    "  role: { type: tokens, group: typography }\n",
                    with: "  role: { type: tokens, group: typography }\n  wraps: { type: bool, default: true }\n",
                    in: approved)) == ["options: " + shape])
        #expect(
            try problems(replacing("slots: [label]\n", with: "states: [hover]\nslots: [label]\n", in: approved)) == [
                "states: " + shape
            ])
        let other = try problems(replacing("group: typography", with: "group: color.text", in: approved))
        #expect(other.count == 1)
        #expect(
            other.first?.hasPrefix(
                "options.role.group: color.text has no token accessor of its own on Apple (typography: "
                    + "Westron.TextRole)") == true)
        // Two extensions that both add .textRole(_:) would not compile.
        let twice = replacing("id: text", with: "id: label", in: approved)
        do {
            _ = try AppleComponents.files(for: [
                (ComponentContract(yaml: approved, source: textSource), textSource),
                (ComponentContract(yaml: twice, source: "spec/components/label/label.spec.yaml"), "label.yaml"),
            ])
            Issue.record("two .textRole(_:) modifiers generated")
        } catch let error as AppleComponents.Problems {
            #expect(
                error.problems.map(\.message) == [
                    "Label and Text (\(textSource)) both add .textRole(_:): two modifiers of one signature do not compile"
                ])
        }
    }

    @Test("generation: a style does not take a token-group option yet; the matrix takes one only with an accessor")
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
            _ = try SnapshotMatrix(contract, source: source, tokens: tokens)
            Issue.record("the matrix took a token-group option without an accessor")
        } catch {
            #expect(
                error.description
                    == "\(source): options.ink.group: ink takes its values from the tokens of color.text, which have "
                    + "no accessor of their own on Apple for a matrix cell to take them as "
                    + "(AppleComponents.tokenAccessors)")
        }
    }

    @Test("matrix: a token option's axis is its group's tokens, in token order; without the tokens it fails")
    func matrixOfTokens() throws {
        let contract = try ComponentContract(
            yaml: replacing("status: draft", with: "status: approved"), source: textSource)
        let ordered = ContractTokens(
            everywhere: tokens.everywhere, somewhere: tokens.somewhere, primitive: tokens.primitive,
            types: tokens.types,
            order: ["typography.heading.large", "typography.body.regular", "typography.body.strong"])
        let matrix = try SnapshotMatrix(contract, source: textSource, tokens: ordered)
        #expect(matrix.axes.map(\.name) == ["role"])
        #expect(matrix.axes.first?.values == ["heading.large", "body.regular", "body.strong"])
        #expect(matrix.axes.first?.tokenGroup == "typography")
        #expect(matrix.axes.first?.accessor == "Westron.TextRole")
        #expect(matrix.axes.first?.isBool == false && matrix.axes.first?.systemType == nil)
        #expect(matrix.states == [])
        #expect(matrix.columnAxis == "role")
        #expect(matrix.combinations.map(\.values) == [["heading.large"], ["body.regular"], ["body.strong"]])
        #expect(matrix.combinations.allSatisfy { $0.state == nil })
        #expect(matrix.platforms == [], "a token option has no platform restriction")
        #expect(matrix.sheets.map(\.id) == ["all"])
        // Without an order, the values are sorted.
        #expect(
            try SnapshotMatrix(contract, source: textSource, tokens: tokens).axes[0].values == [
                "body.regular", "body.strong", "heading.large",
            ])
        do {
            _ = try SnapshotMatrix(contract, source: textSource)
            Issue.record("the matrix took a token option without the tokens")
        } catch {
            #expect(
                error.description
                    == "\(textSource): options.role: role takes its values from the tokens of typography: the matrix "
                    + "needs the tokens")
        }
    }

    @Test("matrix: westron's Text contract, approved, is the seventeen roles in token order, on six sheets")
    func textMatrix() throws {
        let resolver = repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path
        let real = try ContractTokens(Resolution(resolverFile: resolver))
        let text = try String(contentsOf: repositoryRoot.appendingPathComponent(textSource), encoding: .utf8)
        let contract = try ComponentContract(yaml: text, source: textSource)
        #expect(contract.status == "approved")
        let matrix = try SnapshotMatrix(contract, source: textSource, tokens: real)
        #expect(
            matrix.axes.first?.values == [
                "heading.large", "heading.medium", "heading.small", "heading.overline", "body.regular", "body.strong",
                "callout.regular", "callout.strong", "subheadline.regular", "subheadline.medium", "subheadline.strong",
                "footnote.regular", "footnote.medium", "footnote.strong", "caption.medium", "code.regular",
                "code.strong",
            ])
        #expect(matrix.combinations.count == 17)
        #expect(matrix.sheets.map(\.columns.count) == [3, 3, 3, 3, 3, 2])
        #expect(matrix.sheets.first?.id == "all_columns-1")
        #expect(matrix.sheets.allSatisfy { $0.rows == [nil] })

        let files = try AppleSnapshotMatrix.files(for: [(contract, textSource)], tokens: real)
        #expect(
            files.map(\.path) == [
                "platforms/apple/Sources/WestronCatalog/Generated/Text+Matrix.swift",
                AppleSnapshotMatrix.registryFile,
            ])
        let swift = files[0].contents
        #expect(swift.contains("    /// Text's matrix: 17 role at rest (the contract has no states) = 17 combinations"))
        #expect(swift.contains("    ) { TextMatrixCell(TextMatrixValues($0)) }\n"))
        #expect(swift.contains("    private let role: Westron.TextRole\n"))
        #expect(swift.contains("    typealias Fields = (role: Westron.TextRole, state: String?)\n"))
        #expect(swift.contains("        self.role = Self.roleTokens[combination.values[0]]!\n"))
        #expect(swift.contains("    private static let roleTokens: [String: Westron.TextRole] = [\n"))
        #expect(swift.contains("        \"heading.large\": .heading.large,\n"))
        #expect(swift.contains("        \"code.strong\": .code.strong,\n"))
        #expect(files[1].contents.contains("    public static let all: [ComponentMatrix] = [.text]\n"))
        // westron's own file on disk is this generation: generate --check holds it too.
        let onDisk = try String(contentsOf: repositoryRoot.appendingPathComponent(files[0].path), encoding: .utf8)
        #expect(onDisk == swift)
    }

    @Test("ContractTokens keeps the resolver's token order for a group's values")
    func tokenOrder() throws {
        let resolver = repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path
        let real = try ContractTokens(Resolution(resolverFile: resolver))
        let typography = real.order.filter { $0.names.first == "typography" }.map(\.description)
        #expect(typography.first == "typography.heading.large")
        #expect(typography.last == "typography.code.strong")
        #expect(typography.count == 17)
    }

    @Test("API parity: an approved extension's modifier is expected from the contract; its twin when declared")
    func apiParity() throws {
        let root = "WestronUI"
        let modifier = """
            import SwiftUI
            import WestronTokens

            extension View {
                public func textRole(_ role: Westron.TextRole) -> some View { self }
            }

            """
        let twin = """
            extension Text {
                public func textRole(_ role: Westron.TextRole) -> Text { self }
            }

            """
        func check(
            _ status: String, adapters: String = modifier, extra: String = "", pending: Set<String> = ["SwiftUI.Text"]
        ) throws -> [String] {
            let yaml = replacing("status: draft", with: "status: \(status)")
            let contract = APIParity.Contract(
                contract: try ComponentContract(yaml: yaml, source: textSource), source: textSource, text: yaml)
            var files = [(path: "\(root)/TokenAdapters.swift", text: adapters)]
            if !extra.isEmpty { files.append((path: "\(root)/Text.swift", text: extra)) }
            return APIParity.check(contracts: [contract], files: files, sourceRoot: root, pendingTwins: pending)
                .problems.map(\.description)
        }
        // Approved: the modifier is expected; the twin is pending, so it passes with and without it.
        #expect(try check("approved") == [])
        #expect(try check("approved", adapters: modifier + twin) == [])
        // Once the twin is no longer pending, a missing one is reported.
        #expect(try check("approved", adapters: modifier + twin, pending: []) == [])
        #expect(
            try check("approved", pending: []) == [
                "\(textSource):11: missing: Text's modifier on Text, `public func textRole(_: Westron.TextRole) -> "
                    + "Text` in extension Text"
            ])
        // A missing or changed modifier is reported; so is a changed twin.
        #expect(
            try check("approved", adapters: "import SwiftUI\n") == [
                "\(textSource):11: missing: Text's modifier, `public func textRole(_: Westron.TextRole) -> some View` "
                    + "in extension View"
            ])
        let changed = try check(
            "approved",
            adapters: modifier.replacingOccurrences(of: "(_ role: Westron.TextRole)", with: "(_ role: Westron.Color)"))
        #expect(changed.count == 1)
        #expect(changed.first?.contains("Text's modifier differs from the contract") == true)
        let changedTwin = try check(
            "approved", adapters: modifier + twin.replacingOccurrences(of: "-> Text", with: "-> some View"))
        #expect(changedTwin.count == 1)
        #expect(changedTwin.first?.contains("Text's modifier on Text differs from the contract") == true)
        // It is no longer an adapter: under a draft contract it is reported as component API without a contract.
        let draft = try check("draft")
        #expect(draft.count == 1)
        #expect(draft.first?.contains("its contract (\(textSource)) is draft, and a draft has no API") == true)
        // Other API named as Text's is reported, with the reason.
        let approved = try check("approved", extra: "public enum TextRoleName { case body }\n")
        #expect(approved.count == 1)
        #expect(
            approved.first?.contains(
                "TextRoleName is named as Text's API, which Text's contract (\(textSource)) does not give through the "
                    + "conventions") == true)
    }
}
