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

    @Test("westron's Button: 3 variants × 3 sizes × 2 roles × 2 iconOnly × (rest + 5 states) = 216, on 12 sheets")
    func button() throws {
        let matrix = try SnapshotMatrix(try buttonContract(), source: buttonSource)
        #expect(matrix.axes.map(\.name) == ["variant", "size", "role", "iconOnly"])
        #expect(matrix.axes.map(\.values.count) == [3, 3, 2, 2])
        #expect(matrix.axes[2].systemType == "SwiftUI.ButtonRole", "role is the system's, and still an axis")
        #expect(matrix.axes[3].isBool && matrix.axes[3].values == ["false", "true"])
        #expect(matrix.states == ["hover", "focus", "pressed", "disabled", "loading"])
        #expect(matrix.excluded.isEmpty && matrix.advisedAgainst.isEmpty, "Button has no constraints")
        #expect(matrix.combinations.count == 3 * 3 * 2 * 2 * 6)
        #expect(Set(matrix.combinations).count == 216, "each combination once")
        #expect(matrix.combinations.first == .init(["primary", "s", "default", "false"], state: nil))
        #expect(matrix.combinations[1] == .init(["primary", "s", "default", "false"], state: "hover"))
        #expect(matrix.columnAxis == "variant")
        #expect(matrix.sheets.count == 12)
        #expect(matrix.sheets[0].id == "size-s_role-default_iconOnly-false")
        #expect(matrix.sheets[0].columns == ["primary", "secondary", "tertiary"])
        #expect(matrix.sheets[0].rows == [nil, "hover", "focus", "pressed", "disabled", "loading"])
        #expect(matrix.sheets.map { $0.columns.count * $0.rows.count }.reduce(0, +) == 216, "every cell on a sheet")
        // iOS and macOS draw everything; a watch draws size m only and never enters hover.
        #expect(matrix.platforms.map(\.os) == ["watchos"])
        #expect(matrix.platforms[0].drawn.map(\.option) == ["size"])
        #expect(matrix.platforms[0].drawn[0].map.map { "\($0.value)→\($0.drawn)" } == ["s→m", "l→m"])
        #expect(matrix.platforms[0].notEntered == ["hover"])
        #expect(matrix.combinations(on: "ios").count == 216)
        #expect(matrix.combinations(on: "macos").count == 216)
        #expect(matrix.combinations(on: "watchos").count == 216 - 36)
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
        #expect(swift.components(separatedBy: "\n            Combination(").count - 1 == 216)
        #expect(swift.components(separatedBy: "\n            Sheet(").count - 1 == 12)
        #expect(swift.contains("    ) { ButtonMatrixCell(ButtonMatrixValues($0)) }\n"))
        #expect(swift.contains("    let variant: ButtonVariant\n    let size: ButtonSize\n"))
        #expect(swift.contains("    let role: String\n"))
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
