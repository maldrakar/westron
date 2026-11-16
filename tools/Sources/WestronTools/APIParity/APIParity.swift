import Foundation

/// The API parity lint (#21): the public API of `WestronUI` holds exactly the component API that the contracts give
/// through `spec/conventions.md`, so hand-written code cannot quietly add, rename or drop it (AGENTS.md, rules 4
/// and 5). The generator (#20) makes the names equal by construction; this lint checks the result independently, from
/// the sources, with Swift's own parser.
///
/// **What it expects** from each contract that is approved or later and styled on an Apple system control:
/// - `public enum <Component><Option>: String, CaseIterable, Sendable` for each enum option that
///   `platforms.apple.systemOptions` does not give to the system, with the contract's values as its cases, in order,
///   their raw values the values as written, and no other public member;
/// - the overload of the base control's style modifier in `extension View`: the variant first and unlabeled, then the
///   other options in the contract's order, labeled; a contract default as the argument's default (none for the
///   variant when the contract has none), `size: <Component>Size? = nil`, a bool option `<name>: Bool = <default>`;
///   no attributes, generics or effects; `-> some View`;
/// - for each state that is not one of the system control's (`systemStates`), the one shared state modifier named as
///   the state in `extension View`: `public func loading(_: Bool) -> some View`.
///
/// **What it reports**, as `file:line: message`:
/// - expected API that is missing, or differs in access, signature, values, order or default;
/// - component API that no contract gives: a type named after a component (`ButtonShape`, a public `ButtonVariantStyle`
///   or `ButtonState`), a public member or conformance of a component's type, an overload of a style modifier, a
///   function named after a component (`buttonLoading`) or after a contract's state; for a contract that is draft, or
///   whose Apple strategy gives no API yet, with that reason. A type named like component API (`…Variant`, `…State`,
///   `…Style`, or conforming to a `…Style` protocol) of no contract is component API too;
/// - any other public declaration outside the token area (`tokenArea`): token accessors, adapters and icons live
///   there, and nothing else in `WestronUI` may be public without a contract. The token area only extends existing
///   types, so a new public top-level type there is reported too;
/// - any public declaration under `#if`: a component's public API is the same on every Apple OS, and the contract's
///   `platforms.apple.<os>` entries act through the style's fallbacks, not through the API (spec/conventions.md).
///
/// A declaration marked `// westron-lint: allow <reason>`, on its line or a comment line just above, is a deliberate
/// exception to the last three; expected API is always checked.
public enum APIParity {
    /// The sources it reads, relative to the repository root.
    public static let defaultSources = "platforms/apple/Sources/WestronUI"

    /// The token area, relative to `defaultSources`: the files whose public API is the tokens' accessors and adapters
    /// and the icons, which this lint does not compare with contracts (`tools/README.md`).
    public static let tokenArea: Set<String> = [
        "TokenAdapters.swift", "Generated/Tokens+SwiftUI.swift", "Generated/Icons+SwiftUI.swift",
    ]

    /// The states the system controls carry themselves, so the style reads them and no westron modifier sets them
    /// (spec/conventions.md, "States the system control has"). A contract does not mark them; the conventions name
    /// them for every control.
    public static let systemStates: Set<String> = ["pressed", "hover", "focus", "disabled"]

    /// What an enum generated from a contract conforms to.
    static let enumConformances: Set<String> = ["String", "CaseIterable", "Sendable"]

    /// The types a style overload or a state modifier extends.
    static let viewTypes: Set<String> = ["View", "SwiftUI.View"]

    /// Suffixes of a type name that make it component API even without a contract: `BadgeVariant`, `ChipState`,
    /// `PrimaryButtonStyle`.
    static let componentSuffixes = ["VariantStyle", "Variant", "State", "Style"]

    public struct Problem: Equatable, Sendable, CustomStringConvertible {
        public let file: String
        public let line: Int
        public let message: String

        public init(file: String, line: Int, _ message: String) {
            self.file = file
            self.line = line
            self.message = message
        }

        public var description: String { "\(file):\(line): \(message)" }
    }

    public struct Report: Sendable {
        public let problems: [Problem]
        public let contracts: Int
        public let files: Int
        /// Public declarations read.
        public let publicDeclarations: Int
        /// Of those, the ones the contracts account for.
        public let expected: Int
    }

    /// A contract as the lint reads it: its text too, for the line numbers of what is missing.
    public struct Contract: Sendable {
        public let contract: ComponentContract
        public let source: String
        public let text: String

        public init(contract: ComponentContract, source: String, text: String) {
            self.contract = contract
            self.source = source
            self.text = text
        }

        /// `Button` for `button`, `ListRow` for `list-row`.
        var component: String {
            contract.id.split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        }

        /// `button`, `listRow`: how a function named after the component starts.
        var lowerComponent: String { component.prefix(1).lowercased() + component.dropFirst() }

        /// Whether the conventions give it API on Apple: as the generator decides (spec/conventions.md).
        var hasAPI: Bool { AppleComponents.generates(contract) }

        /// Why it has no API, when it has none.
        var noAPIReason: String {
            if contract.status == "draft" { return "its contract (\(source)) is draft, and a draft has no API" }
            guard let apple = contract.apple else {
                return "its contract (\(source)) plans Apple, so it has no API there yet"
            }
            if apple.strategy != AppleComponents.strategy {
                return "its contract (\(source)) is an \(apple.strategy), whose API the conventions leave open (Q2)"
            }
            return "its contract (\(source)) names no base control"
        }

        /// The line of the first `key:` in the contract, 1 when it has none.
        func line(of key: String) -> Int {
            let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            for (index, line) in lines.enumerated() {
                let trimmed = line.drop { $0 == " " }
                if trimmed.hasPrefix(key + ":") { return index + 1 }
            }
            return 1
        }
    }

    // MARK: - Expected API

    struct ExpectedEnum {
        let contract: Contract
        let option: String
        let type: String
        let values: [String]
    }

    struct ExpectedFunction {
        /// `Button's style overload`, `the state loading`.
        let what: String
        let contracts: [Contract]
        let name: String
        let parameters: [SwiftDeclarations.Parameter]
        /// The component types its parameters name, to tell a changed overload from another one.
        let types: Set<String>
        let line: (source: String, line: Int)

        var signature: String {
            "\(name)(" + parameters.map(\.description).joined(separator: ", ") + ") -> some View"
        }
    }

    struct Expected {
        var enums: [ExpectedEnum] = []
        var functions: [ExpectedFunction] = []
    }

    /// The API the conventions derive from the contracts.
    static func expected(_ contracts: [Contract]) -> Expected {
        var expected = Expected()
        var stateOwners: [(state: String, contracts: [Contract])] = []
        for item in contracts where item.hasAPI {
            guard let apple = item.contract.apple, let base = apple.base,
                let modifier = SystemStyles.byBase[base]?.modifier
            else { continue }
            var first: [SwiftDeclarations.Parameter] = []
            var rest: [SwiftDeclarations.Parameter] = []
            var types: Set<String> = []
            for option in item.contract.options where apple.systemOptions[option.name] == nil {
                switch option.kind {
                case .bool(let value):
                    rest.append(.init(label: option.name, type: "Bool", defaultValue: "\(value)"))
                case .enumeration(let values, let defaultValue):
                    let type = item.component + option.name.prefix(1).uppercased() + option.name.dropFirst()
                    expected.enums.append(ExpectedEnum(contract: item, option: option.name, type: type, values: values))
                    types.insert(type)
                    if option.name == "size" {
                        rest.append(.init(label: "size", type: type + "?", defaultValue: "nil"))
                    } else if option.name == "variant" {
                        first.append(.init(label: "_", type: type, defaultValue: defaultValue.map { ".\($0)" }))
                    } else {
                        rest.append(.init(label: option.name, type: type, defaultValue: defaultValue.map { ".\($0)" }))
                    }
                }
            }
            expected.functions.append(
                ExpectedFunction(
                    what: "\(item.component)'s style overload", contracts: [item], name: modifier,
                    parameters: first + rest, types: types, line: (item.source, item.line(of: "base"))))
            for state in item.contract.states where !systemStates.contains(state) {
                if let index = stateOwners.firstIndex(where: { $0.state == state }) {
                    stateOwners[index].contracts.append(item)
                } else {
                    stateOwners.append((state, [item]))
                }
            }
        }
        for (state, owners) in stateOwners {
            expected.functions.append(
                ExpectedFunction(
                    what: "the state modifier of \(state)", contracts: owners, name: state,
                    parameters: [.init(label: "_", type: "Bool")], types: [],
                    line: (owners[0].source, owners[0].line(of: "states"))))
        }
        return expected
    }

    // MARK: - Check

    /// Compares the declarations of `files` with the contracts. `sourceRoot` is the directory the files are in, as it
    /// prefixes their paths; the token area is relative to it.
    public static func check(contracts: [Contract], files: [(path: String, text: String)], sourceRoot: String)
        -> Report
    {
        let declarations = SwiftDeclarations(files: files).declarations
        let expected = expected(contracts)
        var problems: [Problem] = []
        /// Indexes of declarations that expected API accounts for, or that a problem already names.
        var accounted: Set<Int> = []
        var expectedCount = 0
        func problem(_ d: SwiftDeclarations.Declaration, _ message: String) {
            problems.append(Problem(file: d.file, line: d.line, message))
        }

        // Enums of options.
        for item in expected.enums {
            let found = declarations.indices.filter {
                declarations[$0].kind.isType && declarations[$0].container.isEmpty
                    && declarations[$0].name == item.type
            }
            let contract = "\(item.contract.component)'s option \(item.option) (\(item.contract.source))"
            guard let index = found.first else {
                problems.append(
                    Problem(
                        file: item.contract.source, line: item.contract.line(of: item.option),
                        "missing: public enum \(item.type) for \(item.contract.component)'s option \(item.option); "
                            + "run tools/westron generate"))
                continue
            }
            for extra in found.dropFirst() {
                problem(declarations[extra], "\(item.type) is declared again; the one for \(contract) is generated")
                accounted.insert(extra)
            }
            accounted.insert(index)
            expectedCount += 1
            let d = declarations[index]
            if d.kind != .enum {
                problem(d, "\(item.type) is a \(d.kind.rawValue); \(contract) makes it a public enum")
            }
            if !d.access.isPublic {
                problem(d, "\(item.type) is \(d.access); \(contract) makes it public")
            }
            if Set(d.inheritance) != enumConformances || d.inheritance.count != enumConformances.count {
                problem(
                    d,
                    "\(item.type) conforms to \(d.inheritance.joined(separator: ", ")); \(contract) makes it "
                        + "String, CaseIterable, Sendable")
            }
            let cases = declarations.indices.filter {
                declarations[$0].kind == .case && declarations[$0].container == item.type
            }
            accounted.formUnion(cases)
            expectedCount += cases.count
            let names = cases.map { declarations[$0].name }
            if names != item.values {
                let missing = item.values.filter { !names.contains($0) }
                let extra = names.filter { !item.values.contains($0) }
                var parts: [String] = []
                if !missing.isEmpty { parts.append("missing \(missing.joined(separator: ", "))") }
                if !extra.isEmpty { parts.append("not in the contract: \(extra.joined(separator: ", "))") }
                if missing.isEmpty, extra.isEmpty { parts.append("in another order") }
                problem(
                    d,
                    "\(item.type) has the cases \(names.joined(separator: ", ")); \(contract) has the values "
                        + "\(item.values.joined(separator: ", ")) (\(parts.joined(separator: "; ")))")
            }
            for index in cases {
                let c = declarations[index]
                if c.hasAssociatedValues {
                    problem(c, "\(item.type).\(c.name) has associated values; a contract's value has none")
                }
                if let raw = c.rawValue, raw != "\"\(c.name)\"" {
                    problem(
                        c,
                        "\(item.type).\(c.name) has the raw value \(raw); its raw value is the contract's value as "
                            + "written, \"\(c.name)\"")
                }
            }
        }

        // The style overloads and the state modifiers.
        let candidates = declarations.indices.filter {
            declarations[$0].kind == .func && viewTypes.contains(declarations[$0].container)
                && declarations[$0].inExtension
        }
        var unmatched: [ExpectedFunction] = []
        for item in expected.functions {
            let exact = candidates.first { index in
                let d = declarations[index]
                return !accounted.contains(index) && d.name == item.name && d.parameters == item.parameters
                    && d.resultType == "some View" && d.extras.isEmpty && !d.isStatic
            }
            guard let index = exact else {
                unmatched.append(item)
                continue
            }
            accounted.insert(index)
            expectedCount += 1
            let d = declarations[index]
            if !d.access.isPublic {
                problem(d, "\(item.what), \(d.signature), is \(d.access); the conventions make it public")
            }
        }
        for item in unmatched {
            // A changed overload: same name, and it names the component's types or has the same first parameter.
            let near = candidates.first { index in
                let d = declarations[index]
                guard !accounted.contains(index), d.name == item.name else { return false }
                if item.types.isEmpty { return true }
                return d.parameters.contains { p in item.types.contains { p.type.contains($0) } }
            }
            if let near {
                accounted.insert(near)
                problem(
                    declarations[near],
                    "\(item.what) differs from the contract: expected `\(item.signature)`, found "
                        + "`\(declarations[near].signature)`"
                        + (item.types.isEmpty ? "" : "; run tools/westron generate"))
            } else {
                problems.append(
                    Problem(
                        file: item.line.source, line: item.line.line,
                        "missing: \(item.what), `public func \(item.signature)` in extension View"))
            }
        }

        // Public API that no contract accounts for.
        let components = contracts.sorted { $0.component.count > $1.component.count }
        let styleModifiers = Set(SystemStyles.byBase.values.map(\.modifier))
        let contractStates = Set(contracts.flatMap(\.contract.states))
        func startsWith(_ name: String, _ prefix: String) -> Bool {
            guard name.hasPrefix(prefix) else { return false }
            let rest = name.dropFirst(prefix.count)
            return rest.first.map { $0.isUppercase || $0.isNumber || $0 == "_" } ?? true
        }
        /// The contract whose component a type name belongs to.
        func owner(ofType name: String) -> Contract? {
            components.first { startsWith(name, $0.component) }
        }
        /// Why a public declaration is component API, nil when it is not.
        func componentReason(_ d: SwiftDeclarations.Declaration) -> String? {
            func because(_ contract: Contract?, _ what: String) -> String {
                guard let contract else { return what + ", and no contract gives it" }
                if contract.hasAPI {
                    return what + ", which \(contract.component)'s contract (\(contract.source)) does not give "
                        + "through the conventions (spec/conventions.md)"
                }
                return what + ", but " + contract.noAPIReason
            }
            let top = d.container.split(separator: ".").first.map(String.init) ?? ""
            if d.kind == .extension {
                guard !d.inheritance.isEmpty, let contract = owner(ofType: d.qualifiedName) ?? owner(ofType: top)
                else { return nil }
                return because(
                    contract,
                    "a conformance of \(contract.component)'s API (\(d.inheritance.joined(separator: ", ")))")
            }
            if d.kind.isType || d.kind == .typealias {
                if d.container.isEmpty || !viewTypes.contains(d.container) {
                    if let contract = owner(ofType: d.name) {
                        return because(contract, "\(d.name) is named as \(contract.component)'s API")
                    }
                }
            }
            if !top.isEmpty, let contract = owner(ofType: top) {
                return because(contract, "\(d.qualifiedName) is a member of \(contract.component)'s API")
            }
            if d.kind.isType || d.kind == .typealias {
                for suffix in componentSuffixes where d.name.hasSuffix(suffix) && d.name.count > suffix.count {
                    return because(nil, "\(d.name) is named as component API (…\(suffix))")
                }
                if let style = d.inheritance.first(where: { $0.hasSuffix("Style") }) {
                    return because(nil, "\(d.name) is a \(style), component API")
                }
            }
            if d.kind == .func || d.kind == .var {
                if styleModifiers.contains(d.name) {
                    let match = components.first { item in
                        d.parameters.contains { p in startsWith(p.type, item.component) }
                    }
                    return because(match, "\(d.signature) is an overload of a style modifier")
                }
                if let contract = components.first(where: { startsWith(d.name, $0.lowerComponent) }) {
                    return because(contract, "\(d.name) is named as \(contract.component)'s API")
                }
                // A modifier is an instance function; `Double.opacity.disabled` is a token.
                if d.kind == .func, !d.isStatic, contractStates.contains(d.name) {
                    let owners = contracts.filter { $0.contract.states.contains(d.name) }
                    let withAPI = owners.first { $0.hasAPI && !systemStates.contains(d.name) }
                    if systemStates.contains(d.name) {
                        return "\(d.signature) sets the state \(d.name), which the system control has: the style "
                            + "reads it from the system, and westron adds no modifier for it (spec/conventions.md)"
                    }
                    return because(
                        withAPI ?? owners.first, "\(d.signature) is named as the state \(d.name)")
                }
            }
            return nil
        }

        let root = sourceRoot.hasSuffix("/") ? sourceRoot : sourceRoot + "/"
        func inTokenArea(_ file: String) -> Bool {
            tokenArea.contains(file.hasPrefix(root) ? String(file.dropFirst(root.count)) : file)
        }
        let allow = "for a deliberate exception: // \(RawValues.allowMarker) <reason>"
        /// Types already reported, whose members are not reported again.
        var reportedTypes: Set<String> = []
        var publicCount = 0
        for (index, d) in declarations.enumerated() {
            let isPublic =
                d.kind == .extension ? !d.inheritance.isEmpty && isPublicType(d, in: declarations) : d.access.isPublic
            guard isPublic else { continue }
            if d.kind != .extension { publicCount += 1 }
            if !d.conditions.isEmpty, !d.allowed {
                problem(
                    d,
                    "public API under \(d.conditions.joined(separator: ", ")): a component's public API is the same "
                        + "on every Apple OS, and a contract's platforms.apple.<os> entries act through the style's "
                        + "fallbacks, never through the API (spec/conventions.md); \(allow)")
            }
            guard !accounted.contains(index), !d.allowed else { continue }
            if reportedTypes.contains(where: { d.container == $0 || d.container.hasPrefix($0 + ".") }) { continue }
            let what =
                d.kind == .extension
                ? "extension \(d.qualifiedName): \(d.inheritance.joined(separator: ", "))"
                : "public \(d.kind.rawValue) \(d.qualifiedName)"
            if let reason = componentReason(d) {
                problem(d, "\(what): component API that no contract accounts for: \(reason); \(allow)")
            } else if inTokenArea(d.file) {
                guard d.kind.isType || d.kind == .typealias, d.container.isEmpty else { continue }
                problem(
                    d,
                    "\(what): a new public type in the token area, which only extends existing types with token "
                        + "accessors and adapters; \(allow)")
            } else {
                problem(
                    d,
                    "\(what): public API outside the component API the contracts give and outside the token area "
                        + "(\(tokenArea.sorted().joined(separator: ", "))); \(allow)")
            }
            if d.kind.isType { reportedTypes.insert(d.qualifiedName) }
        }
        problems.sort { ($0.file, $0.line, $0.message) < ($1.file, $1.line, $1.message) }
        return Report(
            problems: problems, contracts: contracts.count, files: files.count, publicDeclarations: publicCount,
            expected: expectedCount)
    }

    /// Whether an extension's type is public: declared public here, or declared elsewhere.
    static func isPublicType(_ ext: SwiftDeclarations.Declaration, in declarations: [SwiftDeclarations.Declaration])
        -> Bool
    {
        guard let type = declarations.first(where: { $0.kind.isType && $0.qualifiedName == ext.qualifiedName }) else {
            return true
        }
        return type.access.isPublic
    }

    // MARK: - Files

    /// Reads every contract in `contractsDirectory` and every `.swift` file under `sourceRoot`, and checks them.
    /// Paths in the report start as the arguments do.
    /// - Throws: `ContractProblem` for a contract that cannot be read; a file system error.
    public static func run(
        contractsDirectory: String = ContractCheck.defaultDirectory, sourceRoot: String = defaultSources
    ) throws -> Report {
        var contracts: [Contract] = []
        for file in try ContractCheck.files(in: contractsDirectory) {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            contracts.append(
                Contract(contract: try ComponentContract(yaml: text, source: file), source: file, text: text))
        }
        let files = try swiftFiles(in: sourceRoot).map {
            (path: $0, text: try String(contentsOfFile: $0, encoding: .utf8))
        }
        return check(contracts: contracts, files: files, sourceRoot: sourceRoot)
    }

    /// The `.swift` files under a directory, sorted, so that the report does not depend on traversal order.
    static func swiftFiles(in directory: String) throws -> [String] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: directory])
        }
        guard isDirectory.boolValue else { return directory.hasSuffix(".swift") ? [directory] : [] }
        let prefix = directory.hasSuffix("/") ? directory : directory + "/"
        return try FileManager.default.contentsOfDirectory(atPath: directory).sorted().flatMap {
            try swiftFiles(in: prefix + $0)
        }
    }
}
