import Foundation

/// The snapshot matrix generator (#24): from every contract that gives API on Apple (approved or later, styled on a
/// system control, extending a system view or an own component with its form, `AppleComponents.givesAPI`), it writes
/// the component's `SnapshotMatrix` into the catalog, `WestronCatalog/Generated/<Component>+Matrix.swift`, and the
/// registry of every matrix, `ComponentMatrix+All.swift`:
///
/// - `ComponentMatrix.<component>`: the axes, the states and those no token binding names, every combination, what a
///   constraint excludes or advises against, what each Apple OS draws differently and the sheets, for the catalog to
///   draw and `tools/apple/snapshot-matrix.sh` to capture. Each cell is drawn by the hand-written
///   `<Component>MatrixCell`, the way a style body is hand-written (decisions/0001), so a new contract fails the
///   catalog's build until its cell exists;
/// - `<Component>MatrixValues`: one combination typed for that cell: the generated enum of each enum option, `Bool` for
///   a bool option, the contract's value of an option that is the system's own API, the token itself, as its
///   accessor (`Westron.TextRole`), for an option whose values are tokens, and the icon (`Westron.Icon`) for one whose
///   values are the icon registry's names. Its values are private and the
///   cell takes them through one tuple, `fields`, so an option added to an existing contract changes the tuple and
///   fails the cell's build where it destructures `fields`, until the cell draws the new option. A new value of an
///   existing option still builds; it reaches the cell through the generated enum.
///
/// The catalog is not public API of WestronUI, so the parity lint does not see these files. The text sizes, the parts
/// of a sheet at a text size where it does not fit, and the supplementary sheets for what no contract option sets are
/// the catalog's, hand-written outside `Generated/` (#72; `SnapshotMatrix`): these files hold the contract's matrix
/// alone.
public struct AppleSnapshotMatrix: Generator {
    public let name = "matrix-apple"
    public let directory: String
    public let schemaFile: String
    public let resolverFile: String
    /// The icon registry, for an option whose values are its names.
    public let registryFile: String

    public init(
        directory: String = ContractCheck.defaultDirectory, schemaFile: String = ContractSchema.defaultFile,
        resolverFile: String = TokenCheck.defaultResolver, registryFile: String = IconRegistry.defaultFile
    ) {
        self.directory = directory
        self.schemaFile = schemaFile
        self.resolverFile = resolverFile
        self.registryFile = registryFile
    }

    public static let outputDirectory = "platforms/apple/Sources/WestronCatalog/Generated"
    public static let registryFile = "\(outputDirectory)/ComponentMatrix+All.swift"

    public var ownedDirectories: [String] { [Self.outputDirectory] }

    public func run() throws -> [GeneratedFile] {
        let checked = try AppleComponents.checkedContracts(
            directory: directory, schemaFile: schemaFile, resolverFile: resolverFile)
        // The registry is read only when a contract that gives API runs its names along an axis: an optional glyph is
        // no axis (SnapshotMatrix).
        let needsIcons = checked.contracts.contains { item in
            AppleComponents.givesAPI(item.contract)
                && item.contract.options.contains { $0.kind == .icons(optional: false) }
        }
        let icons = needsIcons ? try IconRegistry.load(file: registryFile).icons.map(\.name) : nil
        return try Self.files(for: checked.contracts, tokens: checked.tokens, icons: icons)
    }

    /// The matrix files of the contracts that give API on Apple, then the registry. `tokens` gives the values of an
    /// option whose values are tokens, `icons` the icon registry's names, in its order.
    public static func files(
        for contracts: [(contract: ComponentContract, source: String)], tokens: ContractTokens? = nil,
        icons: [String]? = nil
    ) throws -> [GeneratedFile] {
        var files: [GeneratedFile] = []
        var registered: [(name: String, condition: String?)] = []
        for (contract, source) in contracts where AppleComponents.givesAPI(contract) {
            let matrix = try SnapshotMatrix(contract, source: source, tokens: tokens, icons: icons)
            let component = AppleComponents.typeName(contract.id)
            files.append(
                GeneratedFile(
                    path: "\(outputDirectory)/\(component)+Matrix.swift",
                    contents: try swift(matrix, component: component, source: source)))
            registered.append((memberName(contract.id), matrix.availabilityCondition))
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

    /// `label: [items]` on one line when it fits; otherwise the items packed into lines one level in, each line ending
    /// with a comma, as swift format lays out a long array (Icon's rows of glyph names).
    private static func packed(_ label: String, _ items: [String], indent: Int, comma: Bool) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        let end = comma ? "," : ""
        let line = pad + "\(label): " + list(items) + end
        if line.count <= AppleTokensSwift.lineLength { return [line] }
        var out = [pad + "\(label): ["]
        var current = ""
        for item in items {
            let next = current.isEmpty ? item + "," : current + " " + item + ","
            if (pad + "    " + next).count > AppleTokensSwift.lineLength, !current.isEmpty {
                out.append(pad + "    " + current)
                current = item + ","
            } else {
                current = next
            }
        }
        if !current.isEmpty { out.append(pad + "    " + current) }
        out.append(pad + "]" + end)
        return out
    }

    static func swift(_ matrix: SnapshotMatrix, component: String, source: String) throws -> String {
        let cell = "\(component)MatrixCell"
        var out = header(
            "Generated from \(source) by `tools/westron generate`. Do not edit: change the contract and generate "
                + "again (spec/conventions.md).",
            "\(component)'s snapshot matrix (#24): its options, its states, the combinations its constraints allow, "
                + "what each Apple OS draws differently, and the sheets `tools/apple/snapshot-matrix.sh` captures. "
                + "The hand-written `\(cell)` draws each cell.")
        out += ["", "import WestronUI", ""]
        guard let condition = matrix.availabilityCondition else {
            return (out + (try declarations(matrix, component: component))).joined(separator: "\n") + "\n"
        }
        // Where the component does not exist, neither does its matrix (the contract's `platforms` block).
        let body = try AppleTokensSwift.$nesting.withValue(4) { try declarations(matrix, component: component) }
        out += AppleTokensSwift.conditional(condition, body)
        return out.joined(separator: "\n") + "\n"
    }

    /// The matrix's declarations, the extension of `ComponentMatrix` first.
    private static func declarations(_ matrix: SnapshotMatrix, component: String) throws -> [String] {
        let member = memberName(matrix.component)
        let values = "\(component)MatrixValues"
        let cell = "\(component)MatrixCell"
        var out: [String] = []

        let hasForms = matrix.axes.contains(where: \.isForm)
        let sizes =
            matrix.axes.map { "\($0.values.count) \($0.name)" }
            + (matrix.states.isEmpty || hasForms ? [] : ["\(matrix.states.count + 1) states"])
        let rows =
            hasForms
            ? ", each form at rest and in each state it enters alone"
            : matrix.states.isEmpty
                ? " at rest (the contract has no states" + (matrix.rowAxis.map { "; \($0) runs down the rows" } ?? "")
                    + ")"
                : " (rest and each state alone)"
        var summary =
            "\(component)'s matrix: " + sizes.joined(separator: " × ") + rows + " = "
            + "\(hasForms ? matrix.combinations.count : matrix.optionCombinations * (matrix.states.count + 1)) "
            + "combinations"
        if hasForms, !matrix.excluded.isEmpty {
            summary += ", less those of the option values constraints forbid"
        } else if matrix.excluded.isEmpty {
            summary += ", none forbidden by a constraint"
        } else {
            summary +=
                "; constraints forbid \(matrix.excluded.count * (matrix.states.count + 1)) of them, so the matrix "
                + "has \(matrix.combinations.count)"
        }
        summary += ", on \(matrix.sheets.count) sheet\(matrix.sheets.count == 1 ? "" : "s")."
        out += ["extension ComponentMatrix {"]
        out += doc([summary], indent: 1)
        out += ["    static let \(member) = ComponentMatrix("]
        out += ["        component: \(literal(matrix.component)),"]
        let options = matrix.axes.map { axis in
            let system = axis.systemType.map { ", system: \(literal($0))" } ?? ""
            return "Option(\(literal(axis.name)), values: \(list(axis.values.map(literal)))\(system))"
        }
        if options.allSatisfy({ $0.count + 13 <= AppleTokensSwift.lineLength }) {
            out += argument("options", options, indent: 2)
        } else {
            // An option with more values than a line holds, such as the seventeen text roles: its values one per line.
            out += ["        options: ["]
            for (axis, line) in zip(matrix.axes, options) {
                if line.count + 13 <= AppleTokensSwift.lineLength {
                    out.append("            \(line),")
                    continue
                }
                let system = axis.systemType.map { ", system: \(literal($0))" } ?? ""
                out += ["            Option(", "                \(literal(axis.name)),", "                values: ["]
                out += axis.values.map { "                    \(literal($0))," }
                // swift format takes the comma off a lone element that spans lines.
                out += ["                ]\(system)", "            )" + (matrix.axes.count == 1 ? "" : ",")]
            }
            out += ["        ],"]
        }
        out += argument("states", matrix.states.map(literal), indent: 2)
        out += argument("unbound", matrix.unboundStates.map(literal), indent: 2)
        out += ["        columns: \(literal(matrix.columnAxis)),"]
        // Only a matrix with a row axis names it, so every other matrix's file stays as it was.
        if let rowAxis = matrix.rowAxis { out += ["        rows: \(literal(rowAxis)),"] }
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
            out += ["            Sheet(", "                \(literal(sheet.id)),"]
            out += packed("fixed", sheet.fixed.map(literal), indent: 4, comma: true)
            out += packed("columns", sheet.columns.map(literal), indent: 4, comma: true)
            out += packed("rows", sheet.rows.map(literal), indent: 4, comma: false)
            // swift format takes the comma off a lone element that spans lines.
            out += ["            )" + (matrix.sheets.count == 1 ? "" : ",")]
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
            ]
                + (matrix.axes.contains { $0.tokenGroup != nil }
                    ? [
                        "An option whose values are tokens is the token itself, as its accessor: the cell applies it "
                            + "as a product does."
                    ] : [])
                + (matrix.axes.contains(where: \.isIcons)
                    ? ["An option whose values are icons is the icon itself, as `\(AppleIcons.iconType)`."] : []),
            indent: 0)
        out += ["struct \(values) {"]
        var elements: [String] = []
        for axis in matrix.axes {
            let name = SwiftName.declared(axis.name)
            let type: String
            if let system = axis.systemType {
                out += doc(["The contract's value of `\(axis.name)`, which is the system's `\(system)`."], indent: 1)
                type = "String"
            } else if let accessor = axis.accessor {
                type = accessor
            } else if axis.isBool {
                type = "Bool"
            } else if axis.isForm {
                out += doc(
                    [
                        matrix.ownForms
                            ? "The form: the initializer the cell calls (the contract's `forms`)."
                            : "The form: the system control the cell styles (the contract's `forms`)."
                    ], indent: 1)
                type = "\(component)Form"
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
            } else if axis.isIcons, let accessor = axis.accessor {
                out += ["        \(name) = \(accessor)(rawValue: \(value))!"]
            } else if axis.accessor != nil {
                out += ["        \(name) = Self.\(axis.name)Tokens[\(value)]!"]
            } else if axis.isForm {
                // The forms' type is generated with the component's API (`AppleComponents.API.formType`).
                out += ["        \(name) = \(component)Form(rawValue: \(value))!"]
            } else if axis.isBool {
                out += ["        \(name) = \(value) == \"true\""]
            } else {
                let type = "\(component)\(axis.name.prefix(1).uppercased() + axis.name.dropFirst())"
                out += ["        \(name) = \(type)(rawValue: \(value))!"]
            }
        }
        out += ["        self.state = combination.state", "    }"]
        for axis in matrix.axes {
            guard let accessor = axis.accessor, let group = axis.tokenGroup else { continue }
            out += [""]
            out += doc(["The token of each value of `\(axis.name)`, by its path after `\(group)`."], indent: 1)
            out += ["    private static let \(axis.name)Tokens: [String: \(accessor)] = ["]
            for value in axis.values {
                out.append("        \(literal(value)): .\(try AppleComponents.member(value, of: group)),")
            }
            out += ["    ]"]
        }
        out += ["}"]
        return out
    }

    /// The registry of `members`, each with the condition it compiles under (nil: every Apple OS). With no condition,
    /// one array literal; otherwise, since an array literal cannot hold `#if`, the array built in order, each run of
    /// members under one condition appended inside its `#if`.
    static func registry(_ members: [(name: String, condition: String?)]) -> String {
        var out = header(
            "Generated from the contracts in \(ContractCheck.defaultDirectory) by `tools/westron generate`. Do not "
                + "edit: change the contracts and generate again (spec/conventions.md).",
            "Every component's snapshot matrix (#24), which `tools/apple/snapshot-matrix.sh` captures.")
        out += ["", "extension ComponentMatrix {"]
        let declaration = "    public static let all: [ComponentMatrix]"
        guard members.contains(where: { $0.condition != nil }) else {
            out += doc(["Every component's snapshot matrix, in the order of the contracts' ids."], indent: 1)
            let items = members.map { "." + $0.name }
            let line = declaration + " = " + list(items)
            if line.count <= AppleTokensSwift.lineLength {
                out.append(line)
            } else {
                out += [declaration + " = ["] + items.map { "        \($0)," } + ["    ]"]
            }
            out += ["}"]
            return out.joined(separator: "\n") + "\n"
        }
        out += doc(
            [
                "Every component's snapshot matrix on the current OS, in the order of the contracts' ids: a component "
                    + "an OS lacks has no matrix there."
            ], indent: 1)
        out += [declaration + " = {", "        var all: [ComponentMatrix] = []"]
        var runs: [(condition: String?, names: [String])] = []
        for member in members {
            if let last = runs.last, last.condition == member.condition {
                runs[runs.count - 1].names.append(member.name)
            } else {
                runs.append((member.condition, [member.name]))
            }
        }
        for run in runs {
            let items = run.names.map { "." + $0 }
            let indent = run.condition == nil ? 2 : 3
            let pad = String(repeating: "    ", count: indent)
            var lines: [String]
            if items.count == 1 {
                lines = [pad + "all.append(\(items[0]))"]
            } else {
                // `all += [.icon, …]` does not type-check: `+=` takes the implicit members for a stride.
                let line = pad + "all.append(contentsOf: " + list(items) + ")"
                lines =
                    line.count <= AppleTokensSwift.lineLength
                    ? [line]
                    : [pad + "all.append(contentsOf: ["] + items.map { pad + "    " + $0 + "," } + [pad + "])"]
            }
            if let condition = run.condition {
                out += ["        #if \(condition)"] + lines + ["        #endif"]
            } else {
                out += lines
            }
        }
        out += ["        return all", "    }()", "}"]
        return out.joined(separator: "\n") + "\n"
    }
}
