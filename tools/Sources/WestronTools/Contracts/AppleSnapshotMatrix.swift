import Foundation

/// The snapshot matrix generator (#24): from every contract the Swift API generator generates from (approved or later,
/// styled on an Apple system control, `AppleComponents.generates`), it writes the component's `SnapshotMatrix` into the
/// catalog, `WestronCatalog/Generated/<Component>+Matrix.swift`, and the registry of every matrix,
/// `ComponentMatrix+All.swift`:
///
/// - `ComponentMatrix.<component>`: the axes, the states and those no token binding names, every combination, what a
///   constraint excludes or advises against, what each Apple OS draws differently and the sheets, for the catalog to
///   draw and `tools/apple/snapshot-matrix.sh` to capture. Each cell is drawn by the hand-written
///   `<Component>MatrixCell`, the way a style body is hand-written (decisions/0001), so a new contract fails the
///   catalog's build until its cell exists;
/// - `<Component>MatrixValues`: one combination typed for that cell: the generated enum of each enum option, `Bool` for
///   a bool option, and the contract's value of an option that is the system's own API. Its values are private and the
///   cell takes them through one tuple, `fields`, so an option added to an existing contract changes the tuple and
///   fails the cell's build where it destructures `fields`, until the cell draws the new option. A new value of an
///   existing option still builds; it reaches the cell through the generated enum.
///
/// The catalog is not public API of WestronUI, so the parity lint does not see these files.
public struct AppleSnapshotMatrix: Generator {
    public let name = "matrix-apple"
    public let directory: String
    public let schemaFile: String
    public let resolverFile: String

    public init(
        directory: String = ContractCheck.defaultDirectory, schemaFile: String = ContractSchema.defaultFile,
        resolverFile: String = TokenCheck.defaultResolver
    ) {
        self.directory = directory
        self.schemaFile = schemaFile
        self.resolverFile = resolverFile
    }

    public static let outputDirectory = "platforms/apple/Sources/WestronCatalog/Generated"
    public static let registryFile = "\(outputDirectory)/ComponentMatrix+All.swift"

    public var ownedDirectories: [String] { [Self.outputDirectory] }

    public func run() throws -> [GeneratedFile] {
        try Self.files(
            for: AppleComponents.checkedContracts(
                directory: directory, schemaFile: schemaFile, resolverFile: resolverFile))
    }

    /// The matrix files of the contracts that generate an API, then the registry.
    public static func files(for contracts: [(contract: ComponentContract, source: String)]) throws -> [GeneratedFile] {
        var files: [GeneratedFile] = []
        var registered: [String] = []
        for (contract, source) in contracts where AppleComponents.generates(contract) {
            let matrix = try SnapshotMatrix(contract, source: source)
            let component = AppleComponents.typeName(contract.id)
            files.append(
                GeneratedFile(
                    path: "\(outputDirectory)/\(component)+Matrix.swift",
                    contents: swift(matrix, component: component, source: source)))
            registered.append(memberName(contract.id))
        }
        files.append(GeneratedFile(path: registryFile, contents: registry(registered)))
        return files
    }

    /// `button` for `button`, `listRow` for `list-row`.
    static func memberName(_ id: String) -> String {
        let name = AppleComponents.typeName(id)
        return SwiftName.declared(name.prefix(1).lowercased() + name.dropFirst())
    }

    private static func header(_ origin: String, _ purpose: String) -> [String] {
        let width = AppleTokensSwift.lineLength - 3
        return AppleTokensSwift.wrap(origin, width: width).map { "// " + $0 } + ["//"]
            + AppleTokensSwift.wrap(purpose, width: width).map { "// " + $0 }
    }

    private static func doc(_ paragraphs: [String], indent: Int) -> [String] {
        AppleIcons.paragraphs(paragraphs, indent: indent)
    }

    private static func literal(_ text: String?) -> String {
        text.map(AppleTokensSwift.literal) ?? "nil"
    }

    private static func list(_ items: [String]) -> String {
        "[" + items.joined(separator: ", ") + "]"
    }

    /// `name: [items]` on one line when it fits in `indent`, otherwise one item per line.
    private static func argument(_ label: String, _ items: [String], indent: Int, last: Bool = false) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        let prefix = label.isEmpty ? "" : "\(label): "
        let comma = last ? "" : ","
        if items.isEmpty { return [pad + prefix + "[]" + comma] }
        let line = pad + prefix + list(items) + comma
        if line.count <= AppleTokensSwift.lineLength { return [line] }
        return [pad + prefix + "["] + items.map { pad + "    " + $0 + "," } + [pad + "]" + comma]
    }

    static func swift(_ matrix: SnapshotMatrix, component: String, source: String) -> String {
        let member = memberName(matrix.component)
        let values = "\(component)MatrixValues"
        let cell = "\(component)MatrixCell"
        var out = header(
            "Generated from \(source) by `tools/westron generate`. Do not edit: change the contract and generate "
                + "again (spec/conventions.md).",
            "\(component)'s snapshot matrix (#24): its options, its states, the combinations its constraints allow, "
                + "what each Apple OS draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. "
                + "The hand-written `\(cell)` draws each cell.")
        out += ["", "import WestronUI", ""]

        let sizes = matrix.axes.map { "\($0.values.count) \($0.name)" } + ["\(matrix.states.count + 1) states"]
        var summary =
            "\(component)'s matrix: " + sizes.joined(separator: " × ") + " (rest and each state alone) = "
            + "\(matrix.optionCombinations * (matrix.states.count + 1)) combinations"
        if matrix.excluded.isEmpty {
            summary += ", none forbidden by a constraint"
        } else {
            summary +=
                "; constraints forbid \(matrix.excluded.count * (matrix.states.count + 1)) of them, so the matrix "
                + "has \(matrix.combinations.count)"
        }
        summary += ", on \(matrix.sheets.count) sheets."
        out += ["extension ComponentMatrix {"]
        out += doc([summary], indent: 1)
        out += ["    static let \(member) = ComponentMatrix("]
        out += ["        component: \(literal(matrix.component)),"]
        out += argument(
            "options",
            matrix.axes.map { axis in
                let system = axis.systemType.map { ", system: \(literal($0))" } ?? ""
                return "Option(\(literal(axis.name)), values: \(list(axis.values.map(literal)))\(system))"
            }, indent: 2)
        out += argument("states", matrix.states.map(literal), indent: 2)
        out += argument("unbound", matrix.unboundStates.map(literal), indent: 2)
        out += ["        columns: \(literal(matrix.columnAxis)),"]
        let platforms = matrix.platforms.map { platform in
            let drawn =
                platform.drawn.isEmpty
                ? "[:]"
                : "["
                    + platform.drawn.map { entry in
                        "\(literal(entry.option)): ["
                            + entry.map.map { "\(literal($0.value)): \(literal($0.drawn))" }.joined(separator: ", ")
                            + "]"
                    }.joined(separator: ", ") + "]"
            return "Platform(\(literal(platform.os)), drawn: \(drawn), notEntered: "
                + "\(list(platform.notEntered.map(literal))))"
        }
        // One line per platform, or, for a platform too long for a line, its call over several.
        let platformLines = argument("platforms", platforms, indent: 2)
        if platformLines.count == 1 || platforms.allSatisfy({ $0.count + 13 <= AppleTokensSwift.lineLength }) {
            out += platformLines
        } else {
            out += ["        platforms: ["]
            for platform in platforms {
                let opening = "Platform("
                out += [
                    "            " + opening,
                    "                " + platform.dropFirst(opening.count).dropLast(),
                    "            ),",
                ]
            }
            out += ["        ],"]
        }
        for (label, exclusions) in [("excluded", matrix.excluded), ("advisedAgainst", matrix.advisedAgainst)] {
            out += argument(
                label, exclusions.map { "Exclusion(\(list($0.values.map(literal))), constraint: \($0.constraint))" },
                indent: 2)
        }
        out += ["        combinations: ["]
        out += matrix.combinations.map {
            "            Combination(\(list($0.values.map(literal))), state: \(literal($0.state))),"
        }
        out += ["        ],"]
        out += ["        sheets: ["]
        for sheet in matrix.sheets {
            out += [
                "            Sheet(",
                "                \(literal(sheet.id)),",
                "                fixed: \(list(sheet.fixed.map(literal))),",
                "                columns: \(list(sheet.columns.map(literal))),",
                "                rows: \(list(sheet.rows.map(literal)))",
                "            ),",
            ]
        }
        out += ["        ]"]
        out += ["    ) { \(cell)(\(values)($0)) }", "}", ""]

        out += doc(
            [
                "One combination of \(component)'s matrix, typed for `\(cell)`: the generated enum of each enum "
                    + "option, `Bool` for a bool option, and the contract's value of an option that is the "
                    + "system's own API.",
                "The values are private: a cell takes them all at once from `fields`, so an option added to the "
                    + "contract changes the tuple and fails the cell's build until it draws the option too.",
            ], indent: 0)
        out += ["struct \(values) {"]
        var elements: [String] = []
        for axis in matrix.axes {
            let name = SwiftName.declared(axis.name)
            let type: String
            if let system = axis.systemType {
                out += doc(["The contract's value of `\(axis.name)`, which is the system's `\(system)`."], indent: 1)
                type = "String"
            } else if axis.isBool {
                type = "Bool"
            } else {
                type = "\(component)\(axis.name.prefix(1).uppercased() + axis.name.dropFirst())"
            }
            out += ["    private let \(name): \(type)"]
            elements.append("\(name): \(type)")
        }
        out += doc(["The state; nil at rest."], indent: 1)
        out += ["    private let state: String?", ""]
        elements.append("state: String?")
        out += doc(["Every value, in the contract's order of the options, then the state."], indent: 1)
        let fields = "    typealias Fields = (" + elements.joined(separator: ", ") + ")"
        if fields.count <= AppleTokensSwift.lineLength {
            out.append(fields)
        } else {
            out += ["    typealias Fields = ("]
            out += elements.enumerated().map { index, element in
                "        " + element + (index == elements.count - 1 ? "" : ",")
            }
            out += ["    )"]
        }
        let names = matrix.axes.map { SwiftName.declared($0.name) } + ["state"]
        out += ["", "    var fields: Fields { (" + names.joined(separator: ", ") + ") }", ""]
        out += ["    init(_ combination: ComponentMatrix.Combination) {"]
        for (index, axis) in matrix.axes.enumerated() {
            let value = "combination.values[\(index)]"
            let name = "self.\(axis.name)"
            if axis.systemType != nil {
                out += ["        \(name) = \(value)"]
            } else if axis.isBool {
                out += ["        \(name) = \(value) == \"true\""]
            } else {
                let type = "\(component)\(axis.name.prefix(1).uppercased() + axis.name.dropFirst())"
                out += ["        \(name) = \(type)(rawValue: \(value))!"]
            }
        }
        out += ["        self.state = combination.state", "    }", "}"]
        return out.joined(separator: "\n") + "\n"
    }

    static func registry(_ members: [String]) -> String {
        var out = header(
            "Generated from the contracts in \(ContractCheck.defaultDirectory) by `tools/westron generate`. Do not "
                + "edit: change the contracts and generate again (spec/conventions.md).",
            "Every component's snapshot matrix (#24), which `tools/apple/snapshot-matrix.sh` captures.")
        out += ["", "extension ComponentMatrix {"]
        out += doc(["Every component's snapshot matrix, in the order of the contracts' ids."], indent: 1)
        let items = members.map { "." + $0 }
        let line = "    public static let all: [ComponentMatrix] = " + list(items)
        if line.count <= AppleTokensSwift.lineLength {
            out.append(line)
        } else {
            out += ["    public static let all: [ComponentMatrix] = ["] + items.map { "        \($0)," } + ["    ]"]
        }
        out += ["}"]
        return out.joined(separator: "\n") + "\n"
    }
}
