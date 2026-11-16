import Foundation

/// The Swift API generator (#20): from every component contract whose Apple strategy is `style-on-system-control`, it
/// writes `WestronUI/Generated/<Component>+Contract.swift` with what `spec/conventions.md` prescribes, so that the
/// names on Apple are the contract's (AGENTS.md, rule 4):
///
/// - a `public enum <Component><Option>: String, CaseIterable, Sendable` for each enum option, its cases and raw values
///   the contract's values; none for an option that `platforms.apple.systemOptions` gives to the system's own API;
/// - the overload of the base control's style modifier, `buttonStyle(_ variant:size:iconOnly:)`: the variant unlabeled,
///   every other option labeled, a contract default as the argument's default, `size` optional (nil: from
///   `controlSize`). It applies the hand-written `<Component>VariantStyle(<option>: …)` (decisions/0001), so a value
///   renamed, added or removed in the contract fails the build until that style follows it;
/// - the tables a hand-written style would otherwise copy from the contract: the size `controlSize` maps to,
///   `init(_: ControlSize)`; the value each OS draws for each value, `offered`, from the platform restrictions and their
///   fallbacks; the declared states, `<Component>State`, with whether the current OS enters each, `isEntered`.
///
/// Draft contracts are skipped: an API appears once the contract is approved (decisions/0005), so a draft never breaks
/// the build. Own components are skipped too: their API is a view, which conventions question Q2 still leaves open.
/// No drawing is generated: style bodies are written natively (decisions/0001).
public struct AppleComponents: Generator {
    public let name = "components-apple"
    /// The contracts' directory, relative to the repository root.
    public let directory: String
    public let schemaFile: String
    /// The token resolver, for the rules that check bound tokens.
    public let resolverFile: String

    public init(
        directory: String = ContractCheck.defaultDirectory, schemaFile: String = ContractSchema.defaultFile,
        resolverFile: String = TokenCheck.defaultResolver
    ) {
        self.directory = directory
        self.schemaFile = schemaFile
        self.resolverFile = resolverFile
    }

    public static let outputDirectory = "platforms/apple/Sources/WestronUI/Generated"
    public static let strategy = "style-on-system-control"

    public var ownedDirectories: [String] { [Self.outputDirectory] }

    /// Every problem of a contract that cannot be generated from.
    public struct Problems: Error, CustomStringConvertible {
        public let problems: [ContractProblem]

        public var description: String { problems.map(\.description).joined(separator: "\n") }
    }

    /// Generates from every contract, after `spec check`'s schema and rules pass on each: the generator never writes
    /// code from a contract the check rejects (#62).
    public func run() throws -> [GeneratedFile] {
        let schema = try ContractSchema(file: schemaFile)
        let tokens = try ContractTokens(Resolution(resolverFile: resolverFile))
        var contracts: [(contract: ComponentContract, source: String)] = []
        var invalid: [ContractProblem] = []
        for file in try ContractCheck.files(in: directory) {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            let problems = ContractCheck.check(yaml: text, source: file, schema: schema, tokens: tokens)
            guard problems.isEmpty else {
                invalid += problems
                continue
            }
            contracts.append((try ComponentContract(yaml: text, source: file), file))
        }
        guard invalid.isEmpty else { throw Problems(problems: invalid) }
        return try Self.files(for: contracts)
    }

    /// The generated files for contracts that pass `spec check`, in their order, after the checks that span
    /// contracts: no two generate the same Swift name, and the overloads of two on one base control never make a
    /// call ambiguous.
    /// - Throws: `Problems`, with every problem found.
    public static func files(for contracts: [(contract: ComponentContract, source: String)]) throws -> [GeneratedFile] {
        var apis: [API] = []
        var problems: [ContractProblem] = []
        for (contract, source) in contracts {
            guard generates(contract), let apple = contract.apple, let base = apple.base else { continue }
            do {
                apis.append(try API(contract, apple: apple, base: base, source: source))
            } catch {
                problems.append(error)
            }
        }
        problems += collisions(apis) + ambiguities(apis)
        guard problems.isEmpty else { throw Problems(problems: problems) }
        return apis.map {
            GeneratedFile(path: "\(outputDirectory)/\($0.component)+Contract.swift", contents: $0.swift())
        }
    }

    /// Whether the generator writes an API for a contract: approved or later, styled on an Apple system control.
    public static func generates(_ contract: ComponentContract) -> Bool {
        contract.status != "draft" && contract.apple?.strategy == strategy && contract.apple?.base != nil
    }

    /// The generated file for a contract, or nil when the generator skips it. `source` is the contract's path, which
    /// the header names.
    /// - Throws: `ContractProblem` when the contract cannot give the API the conventions prescribe.
    public static func file(for contract: ComponentContract, source: String) throws(ContractProblem) -> GeneratedFile? {
        guard generates(contract), let apple = contract.apple, let base = apple.base else { return nil }
        let api = try API(contract, apple: apple, base: base, source: source)
        return GeneratedFile(path: "\(outputDirectory)/\(api.component)+Contract.swift", contents: api.swift())
    }

    /// The type names that WestronUI declares for components: each generated enum, `<Component>State`, and the
    /// hand-written `<Component>VariantStyle`. One name for two of them does not compile (`invalid redeclaration`),
    /// as with `button`'s option `groupSize` and `button-group`'s option `size`, both `ButtonGroupSize`.
    static func collisions(_ apis: [API]) -> [ContractProblem] {
        var owners: [String: (source: String, what: String)] = [:]
        var problems: [ContractProblem] = []
        for api in apis {
            var names: [(name: String, path: DocumentPath, what: String)] = api.enums.map {
                (
                    $0.type, DocumentPath.root.key("options").key($0.option.name),
                    "\(api.component)'s option \($0.option.name)"
                )
            }
            names.append((api.style, .root.key("id"), "\(api.component)'s hand-written style"))
            if !api.contract.states.isEmpty {
                names.append((api.stateType, .root.key("states"), "\(api.component)'s states"))
            }
            for entry in names {
                if let owner = owners[entry.name] {
                    let place = owner.source == api.source ? "" : " in \(owner.source)"
                    problems.append(
                        ContractProblem(
                            source: api.source, path: entry.path,
                            "\(entry.name), for \(entry.what), is already the type of \(owner.what)\(place): two "
                                + "types of one name do not compile; rename the option or the component"))
                } else {
                    owners[entry.name] = (api.source, entry.what)
                }
            }
        }
        return problems
    }

    /// Components styled on one base control each add an overload of its style modifier, told apart by the variant,
    /// the first argument: `.buttonStyle(.primary)` is ambiguous when two variants have a `primary`, and a call
    /// without a variant when either has none or a default. So each of them needs a variant without a default, and no
    /// two share a value.
    static func ambiguities(_ apis: [API]) -> [ContractProblem] {
        var problems: [ContractProblem] = []
        for (index, api) in apis.enumerated() {
            for earlier in apis[..<index] where earlier.modifier == api.modifier {
                let variants = [earlier, api].map { item in item.enums.first { $0.option.name == "variant" } }
                guard let theirs = variants[0], let ours = variants[1], theirs.defaultValue == nil,
                    ours.defaultValue == nil
                else {
                    problems.append(
                        ContractProblem(
                            source: api.source, path: .root.key("options"),
                            "\(api.component) and \(earlier.component) (\(earlier.source)) both add a "
                                + ".\(api.modifier) overload, which a call tells apart by the variant: each needs an "
                                + "option variant without a default"))
                    continue
                }
                let shared = ours.values.filter(theirs.values.contains)
                if !shared.isEmpty {
                    problems.append(
                        ContractProblem(
                            source: api.source, path: .root.key("options").key("variant"),
                            "\(api.component) and \(earlier.component) (\(earlier.source)) both add a "
                                + ".\(api.modifier) overload and share the variant \(shared.joined(separator: ", ")), "
                                + "so .\(api.modifier)(.\(shared[0])) would be ambiguous; rename it in one of them"))
                }
            }
        }
        return problems
    }

    /// The `ControlSize` cases in SwiftUI's order, with the westron size each maps to by the conventions; `nil` is the
    /// contract's default (spec/conventions.md, "Sizes and controlSize").
    static let controlSizes: [(name: String, size: String?)] = [
        ("mini", "s"), ("small", "s"), ("regular", nil), ("large", "l"), ("extraLarge", "l"),
    ]

    static let osConditions = ["ios": "os(iOS)", "macos": "os(macOS)", "watchos": "os(watchOS)"]
    static let osNames = ["ios": "iOS", "macos": "macOS", "watchos": "watchOS"]

    /// The Swift API of one contract.
    struct API {
        struct Enum {
            let option: ComponentContract.Option
            let type: String
            let values: [String]
            let defaultValue: String?
            /// By OS, the value drawn for each value, where it is not the value itself.
            let offered: [(os: String, map: [(value: String, drawn: String)])]
        }

        let contract: ComponentContract
        let source: String
        /// `Button` for `button`, `ListRow` for `list-row`.
        let component: String
        /// `Button` for `SwiftUI.Button`.
        let control: String
        /// `buttonStyle` for `SwiftUI.Button`.
        let modifier: String
        let enums: [Enum]
        /// The size option, when the contract has one: an enum option named `size`.
        let size: Enum?
        /// By OS, the states it does not enter.
        let skippedStates: [(os: String, states: [String])]

        var style: String { "\(component)VariantStyle" }
        var stateType: String { "\(component)State" }

        init(_ contract: ComponentContract, apple: ComponentContract.Apple, base: String, source: String)
            throws(ContractProblem)
        {
            func problem(_ path: DocumentPath, _ message: String) -> ContractProblem {
                ContractProblem(source: source, path: path, message)
            }
            self.contract = contract
            self.source = source
            component = contract.id.split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
            control = String(base.split(separator: ".").last ?? Substring(base))
            let applePath = DocumentPath.root.key("platforms").key("apple")
            // A control without a style modifier, such as SwiftUI.Slider, cannot take a style (SystemStyles).
            guard let modifier = SystemStyles.byBase[base]?.modifier else {
                throw problem(
                    applePath.key("base"),
                    "no style modifier is known for \(base) (SystemStyles.byBase), so there is no overload to generate")
            }
            self.modifier = modifier
            let optionNames = contract.options.map(\.name)
            for name in apple.systemOptions.keys.sorted() where !optionNames.contains(name) {
                throw problem(applePath.key("systemOptions").key(name), "no option \(name)")
            }
            for (path, restriction) in [(applePath, apple.restriction)]
                + ComponentContract.appleOSes.compactMap({ os in apple.targets[os].map { (applePath.key(os), $0) } })
            {
                for name in restriction.options.keys.sorted() where apple.systemOptions[name] != nil {
                    throw problem(
                        path.key("options").key(name), "\(name) is a system option: its values are the system's")
                }
            }
            for name in contract.states where ContractRules.unusableCases[name] != nil {
                throw problem(.root.key("states"), "\(name) cannot be a state: \(ContractRules.unusableCases[name]!)")
            }
            var enums: [Enum] = []
            for option in contract.options where apple.systemOptions[option.name] == nil {
                guard case .enumeration(let values, let defaultValue) = option.kind else { continue }
                let path = DocumentPath.root.key("options").key(option.name)
                for value in values where ContractRules.unusableCases[value] != nil {
                    throw problem(
                        path.key("values"), "\(value) cannot be a value: \(ContractRules.unusableCases[value]!)")
                }
                let type = component + option.name.prefix(1).uppercased() + option.name.dropFirst()
                if SwiftUITypes.names.contains(type) {
                    throw problem(
                        path,
                        "\(type) would shadow SwiftUI's \(type): if the option is the system's own API on Apple, name "
                            + "it in platforms.apple.systemOptions (spec/conventions.md); otherwise rename the option")
                }
                var offered: [(os: String, map: [(value: String, drawn: String)])] = []
                for os in ComponentContract.appleOSes {
                    var map: [(value: String, drawn: String)] = []
                    for value in values {
                        let drawn = try Self.drawn(
                            value, of: option.name, values: values, apple: apple, os: os, at: applePath,
                            source: source)
                        if drawn != value { map.append((value, drawn)) }
                    }
                    if !map.isEmpty { offered.append((os, map)) }
                }
                if option.name == "size", defaultValue == nil {
                    throw problem(
                        path,
                        "the size needs a default: a call without size: takes the size controlSize maps to, and "
                            + "regular maps to the default (spec/conventions.md)")
                }
                enums.append(
                    Enum(option: option, type: type, values: values, defaultValue: defaultValue, offered: offered))
            }
            self.enums = enums
            let stateType = "\(component)State"
            if !contract.states.isEmpty, SwiftUITypes.names.contains(stateType) {
                throw problem(
                    .root.key("states"),
                    "\(stateType), the type of the states, would shadow SwiftUI's \(stateType): rename the component")
            }
            size = enums.first { $0.option.name == "size" }
            var skipped: [(os: String, states: [String])] = []
            for os in ComponentContract.appleOSes {
                let entered = apple.targets[os]?.states ?? apple.restriction.states ?? contract.states
                let missing = contract.states.filter { !entered.contains($0) }
                if !missing.isEmpty { skipped.append((os, missing)) }
            }
            skippedStates = skipped
        }

        /// The value an OS draws for `value`: Apple's fallback where all of Apple drops it, then the OS's fallback
        /// where the OS drops what remains.
        static func drawn(
            _ value: String, of option: String, values: [String], apple: ComponentContract.Apple, os: String,
            at applePath: DocumentPath, source: String
        ) throws(ContractProblem) -> String {
            func fallback(
                _ value: String, _ restriction: ComponentContract.Restriction, kept: [String], path: DocumentPath
            )
                throws(ContractProblem) -> String
            {
                guard !kept.contains(value) else { return value }
                let target: String?
                switch restriction.fallback[option] {
                case .all(let target)?: return target
                case .byValue(let map)?: target = map[value]
                case nil: target = nil
                }
                guard let target else {
                    throw ContractProblem(
                        source: source, path: path.key("options").key(option),
                        "drops \(value) with no fallback: on Apple every dropped value needs one, since the OSes share "
                            + "one generated enum")
                }
                return target
            }
            let appleKept = apple.restriction.options[option] ?? values
            var drawn = try fallback(value, apple.restriction, kept: appleKept, path: applePath)
            if let target = apple.targets[os] {
                drawn = try fallback(
                    drawn, target, kept: target.options[option] ?? appleKept, path: applePath.key(os))
            }
            return drawn
        }

        // MARK: - Swift

        func swift() -> String {
            let width = AppleTokensSwift.lineLength - 3
            let origin =
                "Generated from \(source) by `tools/westron generate`. Do not edit: change the contract and generate "
                + "again (spec/conventions.md)."
            let purpose =
                "\(component)'s API from its contract: the enums of its options, the overload of `\(modifier)` that "
                + "products call, which applies the hand-written `\(style)` (decisions/0001), and the tables that "
                + "style reads."
            var out =
                AppleTokensSwift.wrap(origin, width: width).map { "// " + $0 } + ["//"]
                + AppleTokensSwift.wrap(purpose, width: width).map { "// " + $0 }
            out += ["", "import SwiftUI"]
            for item in enums {
                out += [""] + enumDeclaration(item)
            }
            out += [""] + overload()
            if let size {
                out += [""] + controlSizeMapping(size)
            }
            for item in enums {
                out += [""] + offered(item)
            }
            if !contract.states.isEmpty {
                out += [""] + states()
            }
            return out.joined(separator: "\n") + "\n"
        }

        private func doc(_ paragraphs: [String], indent: Int) -> [String] {
            AppleIcons.paragraphs(paragraphs, indent: indent)
        }

        private func enumDeclaration(_ item: Enum) -> [String] {
            var paragraphs = ["\(component)'s option `\(item.option.name)`, from its contract."]
            if let description = item.option.description { paragraphs.append(description) }
            if item.option.name == "size" {
                paragraphs.append(
                    "A call without `size:` takes the size from `controlSize`: \(controlSizeSummary(item)). An explicit "
                        + "`size:` wins.")
            }
            var out = doc(paragraphs, indent: 0)
            out.append("public enum \(item.type): String, CaseIterable, Sendable {")
            out += item.values.map { "    case \(SwiftName.declared($0))" }
            out.append("}")
            return out
        }

        /// The variant first and unlabeled, then the other options in the contract's order, labeled.
        private var parameters: [(name: String, declaration: String)] {
            var result: [(name: String, declaration: String, first: Bool)] = []
            for option in contract.options where contract.apple?.systemOptions[option.name] == nil {
                let name = SwiftName.declared(option.name)
                switch option.kind {
                case .bool(let value):
                    result.append((name, "\(option.name): Bool = \(value)", false))
                case .enumeration:
                    guard let item = enums.first(where: { $0.option.name == option.name }) else { continue }
                    if option.name == "size" {
                        result.append((name, "\(option.name): \(item.type)? = nil", false))
                        continue
                    }
                    let defaultValue = item.defaultValue.map { " = .\($0)" } ?? ""
                    if option.name == "variant" {
                        result.append((name, "_ variant: \(item.type)\(defaultValue)", true))
                    } else {
                        result.append((name, "\(option.name): \(item.type)\(defaultValue)", false))
                    }
                }
            }
            return (result.filter(\.first) + result.filter { !$0.first }).map { ($0.name, $0.declaration) }
        }

        /// The text up to and with the first ". ", or all of it.
        static func firstSentence(_ text: String) -> String {
            guard let end = text.range(of: ". ") else { return text }
            return String(text[..<end.lowerBound]) + "."
        }

        /// The arguments of an example call: the first variant and the default size, `.primary, size: .m`.
        private var example: String {
            var parts: [String] = []
            if let variant = enums.first(where: { $0.option.name == "variant" }) {
                parts.append(".\(variant.values[0])")
            }
            if let size, let value = size.defaultValue { parts.append("size: .\(value)") }
            return parts.joined(separator: ", ")
        }

        private func overload() -> [String] {
            var out = ["extension View {"]
            var paragraphs = [
                "Applies westron's \(component) style, from its contract, to the system's `\(control)` in this "
                    + "view: `.\(modifier)(\(example))`."
            ]
            var items: [String] = []
            for option in contract.options where contract.apple?.systemOptions[option.name] == nil {
                let item = enums.first { $0.option.name == option.name }
                switch option.kind {
                case .bool(let value):
                    let summary =
                        option.description.map(Self.firstSentence) ?? "The contract's option `\(option.name)`."
                    items.append("- \(option.name): \(summary) By default `\(value)`.")
                case .enumeration:
                    guard let item else { continue }
                    if option.name == "size" {
                        items.append(
                            "- size: The size; without it, the size comes from `controlSize` "
                                + "(`\(item.type).init(_:)`).")
                    } else if let value = item.defaultValue {
                        items.append("- \(option.name): See `\(item.type)`; by default `.\(value)`.")
                    } else {
                        items.append("- \(option.name): See `\(item.type)`. Every call names one.")
                    }
                }
            }
            for (name, api) in (contract.apple?.systemOptions ?? [:]).sorted(by: { $0.key < $1.key }) {
                paragraphs.append(
                    "The option `\(name)` is the system's own `\(api)`, which the style reads from the control.")
            }
            out += doc(paragraphs, indent: 1)
            if !items.isEmpty {
                out += ["    ///", "    /// - Parameters:"]
                for item in items {
                    let wrapped = AppleTokensSwift.wrap(
                        String(item.dropFirst(2)), width: AppleTokensSwift.lineLength - 11)
                    out += wrapped.enumerated().map { index, line in
                        (index == 0 ? "    ///   - " : "    ///     ") + line
                    }
                }
            }
            let parameters = self.parameters
            let opening = "    public func \(modifier)("
            let closing = ") -> some View {"
            let declarations = parameters.map(\.declaration)
            let line = opening + declarations.joined(separator: ", ") + closing
            if line.count <= AppleTokensSwift.lineLength {
                out.append(line)
            } else {
                let packed = "        " + declarations.joined(separator: ", ")
                out.append(opening)
                if packed.count <= AppleTokensSwift.lineLength {
                    out.append(packed)
                } else {
                    out += declarations.enumerated().map { index, declaration in
                        "        " + declaration + (index == declarations.count - 1 ? "" : ",")
                    }
                }
                out.append("    " + closing)
            }
            let arguments = contract.options.filter { contract.apple?.systemOptions[$0.name] == nil }.map {
                "\($0.name): \(SwiftName.declared($0.name))"
            }
            let call = "        \(modifier)(\(style)(" + arguments.joined(separator: ", ") + "))"
            if call.count <= AppleTokensSwift.lineLength {
                out.append(call)
            } else {
                out += AppleTokensSwift.callLines("let style = \(style)(", arguments.map { [$0] }).map {
                    "        " + $0
                }
                out.append("        return \(modifier)(style)")
            }
            out += ["    }", "}"]
            return out
        }

        private func controlSizeTargets(_ size: Enum) -> [(name: String, value: String)] {
            AppleComponents.controlSizes.map { entry in
                let fallback = size.defaultValue ?? size.values[0]
                guard let wanted = entry.size, size.values.contains(wanted) else { return (entry.name, fallback) }
                return (entry.name, wanted)
            }
        }

        /// `mini and small → s, regular → m, large and extraLarge → l`.
        private func controlSizeSummary(_ size: Enum) -> String {
            var groups: [(names: [String], value: String)] = []
            for target in controlSizeTargets(size) {
                if let last = groups.last, last.value == target.value {
                    groups[groups.count - 1].names.append(target.name)
                } else {
                    groups.append(([target.name], target.value))
                }
            }
            return groups.map { group in
                let names =
                    group.names.count == 1
                    ? group.names[0]
                    : group.names.dropLast().joined(separator: ", ") + " and " + group.names.last!
                return "\(names) → \(group.value)"
            }.joined(separator: ", ")
        }

        private func controlSizeMapping(_ size: Enum) -> [String] {
            var out = ["extension \(size.type) {"]
            out += doc(
                [
                    "The size of a call without `size:`, from the environment's `controlSize`: "
                        + "\(controlSizeSummary(size)) (spec/conventions.md). SwiftUI cannot tell an unset "
                        + "`controlSize` from `regular`, so a call with neither takes the contract's default."
                ], indent: 1)
            out += ["    init(_ controlSize: ControlSize) {", "        switch controlSize {"]
            for target in controlSizeTargets(size) {
                out.append("        case .\(target.name): self = .\(SwiftName.declared(target.value))")
            }
            out.append(
                "        @unknown default: self = .\(SwiftName.declared(size.defaultValue ?? size.values[0]))")
            out += ["        }", "    }", "}"]
            return out
        }

        private func offered(_ item: Enum) -> [String] {
            var out = ["extension \(item.type) {"]
            var summary: String
            if item.offered.isEmpty {
                summary = "Every Apple OS offers every \(item.option.name), so it is the value itself."
            } else {
                summary =
                    item.offered.map { entry in
                        "on \(AppleComponents.osNames[entry.os]!), "
                            + entry.map.map { "\($0.value) → \($0.drawn)" }.joined(separator: ", ")
                    }.joined(separator: "; ") + "."
                summary = "Where an OS does not offer a value, the fallback the contract names: " + summary
            }
            out += doc(
                [
                    "The \(item.option.name) the current OS draws for this one (the contract's `platforms` block). "
                        + summary
                ], indent: 1)
            out.append("    var offered: \(item.type) {")
            out += conditional(
                item.offered.map { entry in
                    (
                        entry.os,
                        ["switch self {"]
                            + item.values.map { value in
                                let drawn = entry.map.first { $0.value == value }?.drawn ?? value
                                return "case .\(value): return .\(SwiftName.declared(drawn))"
                            } + ["}"]
                    )
                }, otherwise: ["return self"], indent: 2)
            out += ["    }", "}"]
            return out
        }

        private func states() -> [String] {
            var paragraphs = [
                "The states of a \(component) in its contract, in its order. The system control has some of them; the "
                    + "others are set through the environment (spec/conventions.md)."
            ]
            if !skippedStates.isEmpty {
                paragraphs.append(
                    "Not entered: "
                        + skippedStates.map {
                            "on \(AppleComponents.osNames[$0.os]!), \($0.states.joined(separator: ", "))"
                        }
                        .joined(separator: "; ") + " (the contract's `platforms` block).")
            }
            var out = doc(paragraphs, indent: 0)
            out.append("enum \(stateType): String, CaseIterable, Sendable {")
            out += contract.states.map { "    case \(SwiftName.declared($0))" }
            out.append("")
            out += doc(["Whether the current OS ever enters the state."], indent: 1)
            out.append("    var isEntered: Bool {")
            out += conditional(
                skippedStates.map { entry in
                    (
                        entry.os,
                        ["switch self {"]
                            + contract.states.map { "case .\($0): return \(!entry.states.contains($0))" } + ["}"]
                    )
                }, otherwise: ["return true"], indent: 2)
            out += ["    }", "}"]
            return out
        }

        /// The lines of each OS behind `#if os(…)`, then the rest behind `#else`; just the rest when no OS differs.
        private func conditional(_ branches: [(os: String, lines: [String])], otherwise: [String], indent: Int)
            -> [String]
        {
            let pad = String(repeating: "    ", count: indent)
            guard !branches.isEmpty else {
                // A single expression needs no return.
                return otherwise.map { pad + ($0.hasPrefix("return ") ? String($0.dropFirst(7)) : $0) }
            }
            var out: [String] = []
            for (index, branch) in branches.enumerated() {
                out.append(pad + (index == 0 ? "#if " : "#elseif ") + AppleComponents.osConditions[branch.os]!)
                out += branch.lines.map { pad + "    " + $0 }
            }
            out.append(pad + "#else")
            out += otherwise.map { pad + "    " + $0 }
            out.append(pad + "#endif")
            return out
        }
    }
}
