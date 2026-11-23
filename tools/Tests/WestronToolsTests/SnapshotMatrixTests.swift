import Foundation
import Testing
import WestronTools

/// A contract with a constraint that forbids, one that advises against, and a watchOS restriction; tests replace parts.
private func matrixYAML(
    status: String = "approved",
    variants: String = "[primary, secondary, tertiary]",
    states: String = "[hover, pressed]",
    constraints: String = """
      - when: { variant: tertiary }
        require: { size: [s, m] }
        severity: error
      - when: { iconOnly: true }
        require: { size: [m, l] }
        severity: warning
    """
) -> String {
    """
    id: badge-button
    status: \(status)
    consumers: [todo-app/list-screen]
    options:
      variant: { type: enum, values: \(variants) }
      size: { type: enum, values: [s, m, l], default: m }
      iconOnly: { type: bool, default: false }
    states: \(states)
    constraints:
    \(constraints)
    accessibility: { role: button }
    platforms:
      apple:
        strategy: style-on-system-control
        base: SwiftUI.Button
        watchos:
          options: { size: [m] }
          fallback: { size: m }
          states: [pressed]
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """
}

private let source = "spec/components/badge-button/badge-button.spec.yaml"

private func matrix(_ yaml: String) throws -> SnapshotMatrix {
    try SnapshotMatrix(ComponentContract(yaml: yaml, source: source), source: source)
}

private let buttonSource = "spec/components/button/button.spec.yaml"

private func buttonContract() throws -> ComponentContract {
    let text = try String(contentsOf: repositoryRoot.appendingPathComponent(buttonSource), encoding: .utf8)
    return try ComponentContract(yaml: text, source: buttonSource)
}

@Suite("Snapshot matrix")
struct SnapshotMatrixTests {
    @Test("reads a contract's constraints: values, lists and booleans, with their severity")
    func constraints() throws {
        let contract = try ComponentContract(yaml: matrixYAML(), source: source)
        #expect(
            contract.constraints == [
                .init(when: ["variant": ["tertiary"]], require: ["size": ["s", "m"]], severity: "error"),
                .init(when: ["iconOnly": ["true"]], require: ["size": ["m", "l"]], severity: "warning"),
            ])
        #expect(contract.constraints[0].isBroken(by: ["variant": "tertiary", "size": "l", "iconOnly": "false"]))
        #expect(!contract.constraints[0].isBroken(by: ["variant": "tertiary", "size": "m", "iconOnly": "false"]))
        #expect(!contract.constraints[0].isBroken(by: ["variant": "primary", "size": "l", "iconOnly": "false"]))
    }

    @Test(
        "an option with nameInMatrixAtDefault false is an axis, named in a sheet's id only away from its default")
    func optionUnnamedAtItsDefault() throws {
        let yaml = matrixYAML().replacingOccurrences(
            of: "  iconOnly: { type: bool, default: false }\n",
            with: "  iconOnly: { type: bool, default: false }\n"
                + "  floating: { type: bool, default: false, nameInMatrixAtDefault: false }\n")
        #expect(yaml != matrixYAML())
        let before = try matrix(matrixYAML())
        let after = try matrix(yaml)
        try #require(after.axes.count == 4)
        #expect(after.axes.map(\.name) == ["variant", "size", "iconOnly", "floating"])
        #expect(after.axes.map(\.unnamed) == [nil, nil, nil, "false"])
        #expect(after.combinations.count == before.combinations.count * 2)
        // The sheets that do not float are the sheets before the option, by id and content; each is followed by its
        // floating twin, named.
        let unnamed = after.sheets.filter { !$0.id.hasSuffix("_floating-true") }
        #expect(unnamed.map(\.id) == before.sheets.map(\.id))
        #expect(unnamed.map(\.columns) == before.sheets.map(\.columns))
        #expect(unnamed.map(\.rows) == before.sheets.map(\.rows))
        #expect(
            after.sheets.map(\.id).filter { $0.hasSuffix("_floating-true") }
                == before.sheets.map { $0.id + "_floating-true" })
        // Without the key an option is named at every value, as every option before it.
        let named = try matrix(yaml.replacingOccurrences(of: ", nameInMatrixAtDefault: false", with: ""))
        #expect(named.axes[3].unnamed == nil)
        #expect(named.sheets.allSatisfy { $0.id.hasSuffix("_floating-false") || $0.id.hasSuffix("_floating-true") })
        let swift = try #require(
            AppleSnapshotMatrix.files(for: [(ComponentContract(yaml: yaml, source: source), source)]).first
        ).contents
        #expect(swift.contains(#"Option("floating", values: ["false", "true"], unnamed: "false")"#))
        #expect(swift.contains(#"Option("iconOnly", values: ["false", "true"])"#))
    }

    /// 3 variants × 3 sizes × 2 roles × 2 iconOnly × 2 floating × (rest + 5 states) = 432, less the 72 of a floating
    /// tertiary and the 36 of a floating destructive secondary, which constraints of severity error leave out.
    @Test("westron's Button: 324 combinations, on 24 sheets")
    func button() throws {
        let matrix = try SnapshotMatrix(try buttonContract(), source: buttonSource)
        #expect(matrix.axes.map(\.name) == ["variant", "size", "role", "iconOnly", "floating"])
        #expect(matrix.axes.map(\.values.count) == [3, 3, 2, 2, 2])
        #expect(matrix.axes[2].systemType == "SwiftUI.ButtonRole", "role is the system's, and still an axis")
        #expect(matrix.axes[3].isBool && matrix.axes[3].values == ["false", "true"])
        #expect(matrix.axes[4].isBool && matrix.axes[4].values == ["false", "true"])
        #expect(matrix.states == ["hover", "focus", "pressed", "disabled", "loading"])
        // Two constraints, of severity error (decisions/0015): a tertiary and a destructive secondary do not float.
        #expect(matrix.advisedAgainst.isEmpty)
        #expect(matrix.excluded.count == 3 * 2 * 2 + 3 * 2, "tertiary × size × role × iconOnly; secondary, destructive")
        #expect(
            matrix.excluded.allSatisfy {
                $0.values[4] == "true"
                    && ($0.values[0] == "tertiary" || ($0.values[0] == "secondary" && $0.values[2] == "destructive"))
            })
        #expect(matrix.combinations.count == 3 * 3 * 2 * 2 * 2 * 6 - 72 - 36)
        #expect(Set(matrix.combinations).count == 324, "each combination once")
        #expect(matrix.combinations.first == .init(["primary", "s", "default", "false", "false"], state: nil))
        #expect(matrix.combinations[1] == .init(["primary", "s", "default", "false", "false"], state: "hover"))
        #expect(matrix.columnAxis == "variant")
        #expect(matrix.sheets.count == 24)
        // floating is named only where it is true (`nameInMatrixAtDefault: false`): the sheets of a button that does
        // not float keep the ids they had before the option.
        #expect(matrix.axes[4].unnamed == "false" && matrix.axes.prefix(4).allSatisfy { $0.unnamed == nil })
        #expect(matrix.sheets[0].id == "size-s_role-default_iconOnly-false")
        #expect(matrix.sheets[1].id == "size-s_role-default_iconOnly-false_floating-true")
        #expect(matrix.sheets[0].columns == ["primary", "secondary", "tertiary"])
        #expect(matrix.sheets[0].rows == [nil, "hover", "focus", "pressed", "disabled", "loading"])
        // The floating sheets keep the tertiary column, whose cells say they are excluded.
        #expect(matrix.sheets.map { $0.columns.count * $0.rows.count }.reduce(0, +) == 432, "every cell on a sheet")
        // iOS and macOS draw everything; a watch draws size m only and never enters hover.
        #expect(matrix.platforms.map(\.os) == ["watchos"])
        #expect(matrix.platforms[0].drawn.map(\.option) == ["size"])
        #expect(matrix.platforms[0].drawn[0].map.map { "\($0.value)→\($0.drawn)" } == ["s→m", "l→m"])
        #expect(matrix.platforms[0].notEntered == ["hover"])
        #expect(matrix.combinations(on: "ios").count == 324)
        #expect(matrix.combinations(on: "macos").count == 324)
        // A watch never enters hover: one state in six of each combination.
        #expect(matrix.combinations(on: "watchos").count == 324 - 54)
    }

    @Test("a constraint of severity error leaves its combinations out with every state; a warning only marks them")
    func constraintsExclude() throws {
        let matrix = try matrix(matrixYAML())
        // tertiary at size l, with and without iconOnly.
        #expect(
            matrix.excluded.map(\.values) == [["tertiary", "l", "false"], ["tertiary", "l", "true"]])
        #expect(matrix.excluded.allSatisfy { $0.constraint == 0 })
        // iconOnly at size s, for each variant.
        #expect(
            matrix.advisedAgainst.map(\.values) == [
                ["primary", "s", "true"], ["secondary", "s", "true"], ["tertiary", "s", "true"],
            ])
        #expect(matrix.optionCombinations == 18)
        #expect(matrix.combinations.count == (18 - 2) * 3)
        #expect(!matrix.combinations.contains { $0.values == ["tertiary", "l", "false"] })
        #expect(matrix.combinations.contains { $0.values == ["tertiary", "s", "true"] }, "advised against stays")
        // The sheets still have a column for tertiary: its cells at size l are the excluded ones.
        #expect(
            matrix.sheets.map(\.id) == [
                "size-s_iconOnly-false", "size-s_iconOnly-true", "size-m_iconOnly-false", "size-m_iconOnly-true",
                "size-l_iconOnly-false", "size-l_iconOnly-true",
            ])
    }

    @Test("a platform restriction marks the fallbacks and drops the states the OS never enters")
    func platformRestriction() throws {
        let matrix = try matrix(matrixYAML())
        #expect(matrix.platforms.count == 1)
        let watch = try #require(matrix.platforms.first)
        #expect(watch.os == "watchos")
        #expect(watch.drawn.map(\.option) == ["size"])
        #expect(watch.drawn[0].map.map { "\($0.value)→\($0.drawn)" } == ["s→m", "l→m"])
        #expect(watch.notEntered == ["hover"])
        #expect(matrix.combinations(on: "ios").count == 48)
        #expect(matrix.combinations(on: "watchos").count == 16 * 2)
        #expect(!matrix.combinations(on: "watchos").contains { $0.state == "hover" })
    }

    @Test("a sheet whose every combination a constraint forbids is left out")
    func emptySheet() throws {
        let matrix = try matrix(
            matrixYAML(
                constraints: """
                      - when: { iconOnly: true }
                        require: { size: [s, m] }
                        severity: error
                    """))
        #expect(!matrix.sheets.contains { $0.id == "size-l_iconOnly-true" })
        #expect(matrix.sheets.count == 5)
        #expect(matrix.combinations.count == (18 - 3) * 3)
    }

    @Test("adding a value to the contract changes the matrix: more combinations, and columns split over sheets")
    func addingAValue() throws {
        let before = try matrix(matrixYAML())
        let after = try matrix(matrixYAML(variants: "[primary, secondary, tertiary, quiet]"))
        #expect(before != after)
        #expect(after.combinations.count == before.combinations.count + 3 * 2 * 3)
        #expect(after.combinations.contains { $0.values == ["quiet", "l", "true"] && $0.state == "pressed" })
        // Four variants do not fit three columns: each sheet splits in two.
        #expect(after.sheets.count == before.sheets.count * 2)
        #expect(
            after.sheets.prefix(2).map(\.id) == ["size-s_iconOnly-false_columns-1", "size-s_iconOnly-false_columns-2"])
        #expect(after.sheets[1].columns == ["quiet"])

        let generated = try AppleSnapshotMatrix.files(
            for: [(ComponentContract(yaml: matrixYAML(), source: source), source)])
        let regenerated = try AppleSnapshotMatrix.files(
            for: [
                (
                    ComponentContract(
                        yaml: matrixYAML(variants: "[primary, secondary, tertiary, quiet]"), source: source),
                    source
                )
            ])
        #expect(generated[0].contents != regenerated[0].contents)
        #expect(regenerated[0].contents.contains(#"Combination(["quiet", "l", "true"], state: "pressed"),"#))
    }

    @Test("a state no token binding names in a case is unbound: it draws as rest")
    func unboundStates() throws {
        let button = try SnapshotMatrix(try buttonContract(), source: buttonSource)
        #expect(button.unboundStates == ["focus"], "the system draws Button's focus ring; no binding names focus")
        let bound = matrixYAML().replacingOccurrences(
            of: "accessibility: { role: button }",
            with: """
                tokens:
                  container.background:
                    cases:
                      - { when: { state: [hover] }, token: color.background.hover }
                      - { when: { variant: primary }, token: color.background.accent }
                accessibility: { role: button }
                """)
        #expect(try matrix(bound).unboundStates == ["pressed"])
        #expect(try matrix(matrixYAML()).unboundStates == ["hover", "pressed"], "no bindings at all")
    }

    @Test("an option added to the contract changes the typed values' tuple, which the hand-written cell destructures")
    func addingAnOption() throws {
        let yaml = matrixYAML().replacingOccurrences(
            of: "  iconOnly: { type: bool, default: false }",
            with: "  iconOnly: { type: bool, default: false }\n  dense: { type: bool, default: false }")
        let files = try AppleSnapshotMatrix.files(for: [(ComponentContract(yaml: yaml, source: source), source)])
        #expect(
            files[0].contents.contains(
                "    typealias Fields = (variant: BadgeButtonVariant, size: BadgeButtonSize, iconOnly: Bool, "
                    + "dense: Bool, state: String?)\n"))
        #expect(files[0].contents.contains("    var fields: Fields { (variant, size, iconOnly, dense, state) }\n"))
    }

    @Test("more states than a sheet's rows split the rows over sheets")
    func rowsSplit() throws {
        let matrix = try matrix(matrixYAML(states: "[hover, focus, pressed, selected, disabled, loading]"))
        #expect(matrix.sheets.count == 6 * 2)
        #expect(matrix.sheets[0].id == "size-s_iconOnly-false_rows-1")
        #expect(matrix.sheets[0].rows == [nil, "hover", "focus", "pressed", "selected", "disabled"])
        #expect(matrix.sheets[1].rows == ["loading"])
    }

    @Test("the generated Swift: the matrix, the typed values, and the registry")
    func generatedSwift() throws {
        let files = try AppleSnapshotMatrix.files(for: [(try buttonContract(), buttonSource)])
        #expect(
            files.map(\.path) == [
                "platforms/apple/Sources/WestronCatalog/Generated/Button+Matrix.swift",
                "platforms/apple/Sources/WestronCatalog/Generated/ComponentMatrix+All.swift",
            ])
        let swift = files[0].contents
        #expect(
            swift.hasPrefix("// Generated from spec/components/button/button.spec.yaml by `tools/westron generate`."))
        #expect(swift.contains("    static let button = ComponentMatrix(\n        component: \"button\",\n"))
        #expect(swift.contains(#"Option("role", values: ["default", "destructive"], system: "SwiftUI.ButtonRole"),"#))
        #expect(
            swift.contains(
                #"platforms: [Platform("watchos", drawn: ["size": ["s": "m", "l": "m"]], notEntered: ["hover"])],"#))
        #expect(swift.components(separatedBy: "\n            Combination(").count - 1 == 324)
        #expect(swift.contains(#"Option("floating", values: ["false", "true"], unnamed: "false"),"#))
        #expect(swift.contains(#"Option("iconOnly", values: ["false", "true"]),"#), "named at every value")
        #expect(swift.components(separatedBy: "\n            Sheet(").count - 1 == 24)
        #expect(swift.contains("    ) { ButtonMatrixCell(ButtonMatrixValues($0)) }\n"))
        #expect(swift.contains("        unbound: [\"focus\"],\n"), "no token binding names focus")
        // The values are private; the cell takes them all through one tuple, whose arity an added option changes.
        #expect(swift.contains("    private let variant: ButtonVariant\n    private let size: ButtonSize\n"))
        #expect(swift.contains("    private let role: String\n"))
        #expect(swift.contains("        iconOnly: Bool,\n        floating: Bool,\n        state: String?\n    )\n"))
        #expect(swift.contains("    var fields: Fields { (variant, size, role, iconOnly, floating, state) }\n"))
        #expect(swift.contains("        self.floating = combination.values[4] == \"true\"\n"))
        #expect(swift.contains("        self.size = ButtonSize(rawValue: combination.values[1])!\n"))
        #expect(swift.contains("        self.iconOnly = combination.values[3] == \"true\"\n"))
        #expect(files[1].contents.contains("    public static let all: [ComponentMatrix] = [.button]\n"))
        // westron's own file on disk is this generation: generate --check holds it too.
        let onDisk = try String(
            contentsOf: repositoryRoot.appendingPathComponent(files[0].path), encoding: .utf8)
        #expect(onDisk == swift)
    }

    @Test("a draft contract has no matrix; the registry is then empty, and the generator owns its directory")
    func draft() throws {
        let files = try AppleSnapshotMatrix.files(
            for: [(ComponentContract(yaml: matrixYAML(status: "draft"), source: source), source)])
        #expect(files.map(\.path) == [AppleSnapshotMatrix.registryFile])
        #expect(files[0].contents.contains("public static let all: [ComponentMatrix] = []\n"))
        #expect(AppleSnapshotMatrix().ownedDirectories == ["platforms/apple/Sources/WestronCatalog/Generated"])
    }

    @Test("a component id in kebab-case names the static member in lowerCamelCase and the types in UpperCamelCase")
    func names() throws {
        let files = try AppleSnapshotMatrix.files(
            for: [(ComponentContract(yaml: matrixYAML(), source: source), source)])
        #expect(files[0].path.hasSuffix("/BadgeButton+Matrix.swift"))
        #expect(files[0].contents.contains("    static let badgeButton = ComponentMatrix("))
        #expect(files[0].contents.contains("struct BadgeButtonMatrixValues {"))
        #expect(files[1].contents.contains("[.badgeButton]"))
    }
}
