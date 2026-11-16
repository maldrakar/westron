/// The rules of a contract that its JSON Schema cannot express. They walk the document leniently: a part of the wrong
/// shape is skipped, since the schema reports it, so the rules run on a contract that fails the schema too.
struct ContractRules {
    let document: JSON
    let source: String
    let tokens: ContractTokens
    /// The unquoted scalars YAML did not read as text, from `ContractYAML.read`.
    let implicit: [ContractYAML.ImplicitScalar]
    private(set) var problems: [(path: DocumentPath, message: String)] = []
    /// The places where an unquoted YAML word is reported: other problems there only restate it.
    private(set) var yamlWords: Set<DocumentPath> = []

    init(
        document: JSON, source: String, tokens: ContractTokens, implicit: [ContractYAML.ImplicitScalar] = []
    ) {
        self.document = document
        self.source = source
        self.tokens = tokens
        self.implicit = implicit
    }

    /// The enum options, by name, with their values.
    private var enumOptions: [String: [String]] {
        var result: [String: [String]] = [:]
        for member in document["options"]?.members ?? [] where member.value["type"] == .string("enum") {
            result[member.key] = member.value["values"]?.elements?.compactMap(\.string) ?? []
        }
        return result
    }

    private var boolOptions: Set<String> {
        Set((document["options"]?.members ?? []).filter { $0.value["type"] == .string("bool") }.map(\.key))
    }

    private var states: [String]? {
        document["states"]?.elements?.compactMap(\.string)
    }

    /// Records a problem, unless an unquoted YAML word is reported at the same place: the problem only restates it.
    private mutating func report(_ path: DocumentPath, _ message: String) {
        guard !yamlWords.contains(path) else { return }
        problems.append((path, message))
    }

    mutating func run() {
        checkYAMLWords()
        checkFileName()
        checkRepeats()
        checkOptions()
        checkSwiftNames()
        checkSystemStyles()
        checkConstraints()
        checkTokens()
        checkPlatforms()
        checkAppleFallbacks()
        checkSystemOptions()
        checkAccessibility()
    }

    /// An unquoted word that YAML 1.1 reads as a boolean, other than `true` and `false`, is a mistake wherever it
    /// stands: as a boolean the contract writes `true` or `false`, and as a name it must be quoted. A mapping key that
    /// YAML reads as a boolean or a number is quoted too: the document keeps it as written, another YAML reader does
    /// not.
    mutating func checkYAMLWords() {
        for scalar in implicit {
            if scalar.isKey {
                guard scalar.kind != .null else { continue }
                report(
                    scalar.path,
                    "YAML reads the key \(scalar.text) as a \(scalar.kind == .bool ? "boolean" : "number"), "
                        + "not a name: quote it, \"\(scalar.text)\"")
            } else if scalar.kind == .bool, scalar.text != "true", scalar.text != "false" {
                let value = ["yes", "true", "on"].contains(scalar.text.lowercased()) ? "true" : "false"
                report(
                    scalar.path,
                    "YAML 1.1 reads \(scalar.text) as the boolean \(value): write a boolean as true or false, and "
                        + "quote a name, \"\(scalar.text)\"")
            } else {
                continue
            }
            yamlWords.insert(scalar.path)
        }
    }

    /// Words that cannot be a case of a generated Swift enum (an option's value, a state), each with the reason; a
    /// Swift keyword is fine, since it is declared in backticks. Probed with Xcode 27.1 (#62).
    static let unusableCases: [String: String] = [
        "init": "Swift reads .init as the enum's initializer, so the generated code does not compile",
        "self": "Swift reads <Type>.self as the type itself, so a qualified reference never names the case",
        "none": "where an optional is expected, such as the size: argument, Swift reads .none as nil, not the case",
    ]

    /// Words that cannot be an option's name, which becomes an argument label of the style overload: `inout` does not
    /// compile there, and `var` and `let` compile only with a warning.
    static let unusableLabels: Set<String> = ["inout", "var", "let"]

    /// Option values, states and option names become Swift names on Apple, the pilot platform: none may be a word
    /// Swift cannot use there.
    mutating func checkSwiftNames() {
        for member in document["options"]?.members ?? [] {
            let path = DocumentPath.root.key("options").key(member.key)
            if Self.unusableLabels.contains(member.key) {
                report(
                    path,
                    "\(member.key) cannot name an option: in Swift it becomes an argument label of the style "
                        + "overload, where \(member.key) is a keyword; choose another name")
            }
            guard member.value["type"] == .string("enum") else { continue }
            for (index, element) in (member.value["values"]?.elements ?? []).enumerated() {
                guard let value = element.string, let reason = Self.unusableCases[value] else { continue }
                report(
                    path.key("values").index(index), "\"\(value)\" cannot be a value: \(reason); choose another name")
            }
        }
        for (index, element) in (document["states"]?.elements ?? []).enumerated() {
            guard let state = element.string, let reason = Self.unusableCases[state] else { continue }
            report(.root.key("states").index(index), "\"\(state)\" cannot be a state: \(reason); choose another name")
        }
    }

    /// The key of a case's `when` that names states; no option may take it.
    static let stateKey = "state"

    /// The contract of `button` is `button/button.spec.yaml`.
    mutating func checkFileName() {
        guard let id = document["id"]?.string else { return }
        let parts = source.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        let file = parts.last ?? ""
        let folder = parts.count > 1 ? parts[parts.count - 2] : ""
        let expected = "\(id)/\(id)\(ContractCheck.fileSuffix)"
        if file != "\(id)\(ContractCheck.fileSuffix)" || folder != id {
            report(.root.key("id"), "the id is \"\(id)\", so the contract must be \(expected), not \(folder)/\(file)")
        }
    }

    /// No list of names repeats a name.
    mutating func checkRepeats() {
        let root = DocumentPath.root
        var lists: [DocumentPath] = [
            root.key("consumers"), root.key("slots"), root.key("states"),
            root.key("accessibility").key("intents"), root.key("accessibility").key("keyboardIntents"),
        ]
        for member in document["options"]?.members ?? [] {
            lists.append(root.key("options").key(member.key).key("values"))
        }
        for (index, constraint) in (document["constraints"]?.elements ?? []).enumerated() {
            for side in ["when", "require"] {
                for member in constraint[side]?.members ?? [] {
                    lists.append(root.key("constraints").index(index).key(side).key(member.key))
                }
            }
        }
        for (platform, path) in restrictions {
            lists.append(path.key("states"))
            lists.append(path.key("keyboardIntents"))
            for member in platform["options"]?.members ?? [] { lists.append(path.key("options").key(member.key)) }
        }
        for member in document["tokens"]?.members ?? [] {
            for (index, item) in (member.value["cases"]?.elements ?? []).enumerated() {
                for condition in item["when"]?.members ?? [] {
                    lists.append(
                        root.key("tokens").key(member.key).key("cases").index(index).key("when").key(condition.key))
                }
            }
        }
        for path in lists {
            guard let elements = value(at: path)?.elements else { continue }
            var seen: Set<String> = []
            for (index, element) in elements.enumerated() {
                guard let name = element.string else { continue }
                if !seen.insert(name).inserted { report(path.index(index), "repeats \"\(name)\"") }
            }
        }
    }

    /// An enum option's default is one of its values; no option takes the name a case gives to states.
    mutating func checkOptions() {
        for member in document["options"]?.members ?? [] where member.key == Self.stateKey {
            report(
                .root.key("options").key(member.key),
                "\"\(Self.stateKey)\" names the states in a case of a token binding; give the option another name")
        }
        for member in document["options"]?.members ?? [] where member.value["type"] == .string("enum") {
            guard let values = member.value["values"]?.elements?.compactMap(\.string),
                let fallback = member.value["default"]?.string
            else { continue }
            if !values.contains(fallback) {
                report(
                    .root.key("options").key(member.key).key("default"),
                    "\"\(fallback)\" is not one of the values of \(member.key): \(values.joined(separator: ", "))")
            }
        }
    }

    /// No option value is the static name of a system style of the Apple base control (decisions/0003).
    mutating func checkSystemStyles() {
        let apple = DocumentPath.root.key("platforms").key("apple")
        guard value(at: apple.key("strategy")) == .string("style-on-system-control"),
            let base = value(at: apple.key("base"))?.string
        else { return }
        guard let styles = SystemStyles.byBase[base]?.styles else {
            report(
                apple.key("base"),
                "the validator does not know the system styles of \(base): add its style modifier and their names "
                    + "to SystemStyles.byBase (tools/Sources/WestronTools/Contracts/SystemStyles.swift, "
                    + "decisions/0003); a control with no style modifier, such as SwiftUI.Slider, takes no style, so "
                    + "its component is an own-component")
            return
        }
        for member in document["options"]?.members ?? [] where member.value["type"] == .string("enum") {
            for (index, element) in (member.value["values"]?.elements ?? []).enumerated() {
                guard let value = element.string, styles.contains(value) else { continue }
                report(
                    .root.key("options").key(member.key).key("values").index(index),
                    "\"\(value)\" is the name of a system style of \(base), so a call such as .\(value) would be "
                        + "ambiguous (decisions/0003); choose another name")
            }
        }
    }

    /// Constraints name options that exist, with values those options have.
    mutating func checkConstraints() {
        for (index, constraint) in (document["constraints"]?.elements ?? []).enumerated() {
            for side in ["when", "require"] {
                checkConditions(
                    constraint[side]?.members ?? [], at: .root.key("constraints").index(index).key(side),
                    states: false)
            }
        }
    }

    /// Conditions such as a constraint's `when`: options that exist, each with a value or values it has, true or
    /// false for a bool option. With `states`, the key `state` names states from `states`.
    private mutating func checkConditions(_ conditions: [JSON.Member], at path: DocumentPath, states: Bool) {
        let enums = enumOptions
        let bools = boolOptions
        for member in conditions {
            let option = member.key
            let place = path.key(option)
            let named: [(DocumentPath, JSON)] =
                if case .array(let elements) = member.value {
                    elements.enumerated().map { (place.index($0.offset), $0.element) }
                } else {
                    [(place, member.value)]
                }
            if states && option == Self.stateKey {
                let declared = self.states ?? []
                for (at, value) in named {
                    guard let name = value.string else {
                        report(at, "name a state, not true or false")
                        continue
                    }
                    if !declared.contains(name) {
                        report(
                            at,
                            declared.isEmpty
                                ? "\"\(name)\": the contract declares no states"
                                : "\"\(name)\" is not one of the states: \(declared.joined(separator: ", "))")
                    }
                }
            } else if bools.contains(option) {
                if case .bool = member.value { continue }
                report(place, "\(option) is a bool option: give true or false")
            } else if let values = enums[option] {
                for (at, value) in named {
                    if case .bool = value {
                        report(at, "\(option) is an enum option: name its values, not true or false")
                    } else if let name = value.string, !values.contains(name) {
                        report(at, unknownValue(name, of: option, values))
                    }
                }
            } else {
                report(place, unknownOption(option) + (states ? ", and the key state names states" : ""))
            }
        }
    }

    /// Token bindings name tokens that exist in every mode and are not primitives; a binding by option value uses
    /// the values of one enum option.
    mutating func checkTokens() {
        let enums = enumOptions
        for member in document["tokens"]?.members ?? [] {
            let path = DocumentPath.root.key("tokens").key(member.key)
            switch member.value {
            case .string(let token):
                checkToken(token, at: path)
            case .object where member.value["cases"] != nil:
                checkCases(member.value, at: path)
            case .object(let byValue):
                let keys = byValue.map(\.key)
                let owners = enums.keys.sorted().filter { option in keys.allSatisfy { enums[option]!.contains($0) } }
                if owners.count > 1 {
                    report(
                        path,
                        "the keys are values of several options (\(owners.joined(separator: ", "))): "
                            + "rename the values so that a binding names one option")
                } else if let owner = owners.first {
                    let missing = enums[owner]!.filter { !keys.contains($0) }
                    if !missing.isEmpty {
                        report(
                            path,
                            "no token for \(missing.joined(separator: ", ")): a binding by value gives every value of "
                                + "\(owner) a token (\(enums[owner]!.joined(separator: ", "))); a binding that leaves "
                                + "values without one is written as cases, with token: null")
                    }
                } else {
                    let known = byValue.filter { key in enums.values.contains { $0.contains(key.key) } }
                    if known.count == byValue.count {
                        report(path, "the keys must all be values of one enum option")
                    }
                    for entry in byValue where !known.contains(entry) {
                        report(path.key(entry.key), "\"\(entry.key)\" is not a value of any enum option")
                    }
                }
                for entry in byValue {
                    if let token = entry.value.string { checkToken(token, at: path.key(entry.key)) }
                }
            default:
                continue
            }
        }
    }

    /// A case binding: each case's `when` names options, values and states that exist, its token can be bound, and
    /// every case is reachable: some combination of options and states matches it before any earlier case (cases
    /// apply first match).
    private mutating func checkCases(_ binding: JSON, at path: DocumentPath) {
        if let token = binding["token"]?.string { checkToken(token, at: path.key("token")) }
        var cases: [(index: Int, when: [String: Set<String>])] = []
        for (index, item) in (binding["cases"]?.elements ?? []).enumerated() {
            let place = path.key("cases").index(index)
            if let token = item["token"]?.string { checkToken(token, at: place.key("token")) }
            guard let conditions = item["when"]?.members else { continue }
            let before = problems.count
            checkConditions(conditions, at: place.key("when"), states: true)
            // A case whose conditions are wrong is reported there; reachability ignores it.
            if problems.count == before, conditions.allSatisfy({ !yamlWords.contains(place.key("when").key($0.key)) }) {
                cases.append((index, Self.conditionSets(conditions)))
            }
        }
        var domains = enumOptions
        for option in boolOptions { domains[option] = ["false", "true"] }
        let reachability = CaseReachability(
            cases: cases.map(\.when), domains: domains, states: states ?? [], stateKey: Self.stateKey)
        guard let unreachable = reachability.unreachable() else {
            report(
                path.key("cases"),
                "the cases name too many option values and states to check every combination "
                    + "(\(reachability.combinations), at most \(CaseReachability.limit))")
            return
        }
        // A case that matches nothing at all has an empty list, which the schema reports.
        for (position, covering) in unreachable where !covering.isEmpty {
            let (index, when) = cases[position]
            let names = covering.map { "cases[\(cases[$0].index)]" }
            let message: String
            if covering.count == 1 {
                message =
                    cases[covering[0]].when == when
                    ? "repeats the when of \(names[0]), so this case is never used"
                    : "\(names[0]) matches everything this case matches, so it is never used: put the narrower "
                        + "case first"
            } else {
                message =
                    "\(names.dropLast().joined(separator: ", ")) and \(names.last!) together match everything this "
                    + "case matches, so it is never used: put it before them, or remove it"
            }
            report(path.key("cases").index(index).key("when"), message)
        }
    }

    /// Conditions as sets of the values each key accepts; `true` and `false` as text.
    private static func conditionSets(_ conditions: [JSON.Member]) -> [String: Set<String>] {
        func text(_ value: JSON) -> String? {
            if case .bool(let flag) = value { return flag ? "true" : "false" }
            return value.string
        }
        var result: [String: Set<String>] = [:]
        for member in conditions {
            result[member.key] = Set((member.value.elements ?? [member.value]).compactMap(text))
        }
        return result
    }

    private mutating func checkToken(_ token: String, at path: DocumentPath) {
        if let problem = tokens.problem(TokenPath(token)) { report(path, problem) }
    }

    /// Each restriction of a platform offers a subset of an enum option's values and enters a subset of the states;
    /// an Apple OS's restriction is a subset of Apple's. An option the platform gives to its system's own API is not
    /// restricted there: its values are the system's.
    mutating func checkPlatforms() {
        let enums = enumOptions
        let declaredStates = states
        let apple = DocumentPath.root.key("platforms").key("apple")
        for (platform, path) in restrictions {
            // platforms.apple.watchos
            let isAppleOS = path.segments.count == 3
            let owner = isAppleOS ? apple : path
            let systemOptions = value(at: owner.key("systemOptions"))?.members ?? []
            for member in platform["options"]?.members ?? [] {
                let option = member.key
                let place = path.key("options").key(option)
                if let api = systemOptions.first(where: { $0.key == option })?.value.string {
                    report(
                        place,
                        "\(option) is a system option here (\(owner.key("systemOptions").key(option)): \(api)), so "
                            + "its values are the system's: the generator makes no type for it, and a restriction or "
                            + "a fallback would be dropped; remove them, or say in the description what the system "
                            + "does")
                    continue
                }
                guard let declared = enums[option] else {
                    report(
                        place,
                        boolOptions.contains(option)
                            ? "\(option) is a bool option: only enum options can be restricted"
                            : unknownOption(option))
                    continue
                }
                let wider =
                    isAppleOS ? value(at: apple.key("options").key(option))?.elements?.compactMap(\.string) : nil
                for (index, element) in (member.value.elements ?? []).enumerated() {
                    guard let name = element.string else { continue }
                    if !declared.contains(name) {
                        report(place.index(index), unknownValue(name, of: option, declared))
                    } else if let wider, !wider.contains(name) {
                        report(place.index(index), "\"\(name)\" is not among the values Apple offers for \(option)")
                    }
                }
            }
            checkFallbacks(platform, at: path, isAppleOS: isAppleOS)
            checkKeyboardIntents(platform, at: path, isAppleOS: isAppleOS)
            guard let restricted = platform["states"]?.elements else { continue }
            let wider = isAppleOS ? value(at: apple.key("states"))?.elements?.compactMap(\.string) : nil
            for (index, element) in restricted.enumerated() {
                guard let name = element.string else { continue }
                if let declaredStates, !declaredStates.contains(name) {
                    report(
                        path.key("states").index(index),
                        "\"\(name)\" is not one of the states: \(declaredStates.joined(separator: ", "))")
                } else if declaredStates == nil {
                    report(path.key("states").index(index), "\"\(name)\": the contract declares no states")
                } else if let wider, !wider.contains(name) {
                    report(path.key("states").index(index), "\"\(name)\" is not among the states Apple enters")
                }
            }
        }
    }

    /// A fallback names an option this place restricts and maps the values it drops to values it keeps. That Apple
    /// gives every dropped value one is `checkAppleFallbacks`.
    private mutating func checkFallbacks(_ platform: JSON, at path: DocumentPath, isAppleOS: Bool) {
        let enums = enumOptions
        let apple = DocumentPath.root.key("platforms").key("apple")
        let fallbacks = platform["fallback"]?.members ?? []
        // The values each restricted option keeps here and drops here, from what reaches this place.
        var restricted: [String: (kept: [String], dropped: [String])] = [:]
        for member in platform["options"]?.members ?? [] {
            guard let declared = enums[member.key] else { continue }
            let available =
                isAppleOS
                ? value(at: apple.key("options").key(member.key))?.elements?.compactMap(\.string) ?? declared
                : declared
            let kept = (member.value.elements ?? []).compactMap(\.string)
            restricted[member.key] = (kept, available.filter { !kept.contains($0) })
        }
        for member in fallbacks {
            let place = path.key("fallback").key(member.key)
            guard let (kept, dropped) = restricted[member.key] else {
                report(place, "\(member.key) is not restricted here: a fallback goes next to the option's restriction")
                continue
            }
            let keptList = kept.joined(separator: ", ")
            switch member.value {
            case .string(let target):
                if !kept.contains(target) {
                    report(place, "\"\(target)\" is not among the values kept here: \(keptList)")
                }
            case .object(let map):
                for entry in map {
                    if !dropped.contains(entry.key) {
                        report(
                            place.key(entry.key),
                            "\"\(entry.key)\" is not a value dropped here; dropped: \(dropped.joined(separator: ", "))")
                    }
                    if let target = entry.value.string, !kept.contains(target) {
                        report(place.key(entry.key), "\"\(target)\" is not among the values kept here: \(keptList)")
                    }
                }
            default:
                continue
            }
        }
    }

    /// On Apple, whose OSes share one generated enum, every declared value of an enum option resolves on every OS to
    /// a value that OS offers. The chain is the generator's (`AppleComponents.API.drawn`): Apple's fallback where all
    /// of Apple drops the value, then the OS's fallback where the OS drops what Apple's leaves. So every value Apple
    /// drops has a fallback on Apple, to a value Apple keeps (`checkFallbacks`), and every value Apple keeps, or
    /// reaches through its fallback, that an OS drops has a fallback on that OS, to a value the OS keeps.
    mutating func checkAppleFallbacks() {
        let apple = DocumentPath.root.key("platforms").key("apple")
        guard let entry = value(at: apple), entry.members != nil else { return }
        let systemOptions = Set((entry["systemOptions"]?.members ?? []).map(\.key))
        let enums = enumOptions
        func fallback(_ place: JSON, _ option: String, _ value: String) -> String? {
            switch place["fallback"]?[option] {
            case .string(let target)?: return target
            case .object(let map)?: return map.first { $0.key == value }?.value.string
            default: return nil
            }
        }
        func message(_ option: String, _ missing: [String]) -> String {
            "on Apple every dropped value needs a fallback, since the OSes share one generated enum: add "
                + "fallback.\(option) for \(missing.joined(separator: ", "))"
        }
        for member in document["options"]?.members ?? [] where !systemOptions.contains(member.key) {
            guard let declared = enums[member.key] else { continue }
            let option = member.key
            let appleKept = entry["options"]?[option]?.elements?.compactMap(\.string) ?? declared
            // By declared value, the value all of Apple draws for it.
            var drawn: [String: String] = [:]
            var missing: [String] = []
            for value in declared {
                if appleKept.contains(value) {
                    drawn[value] = value
                } else if let target = fallback(entry, option, value) {
                    drawn[value] = target
                } else {
                    missing.append(value)
                }
            }
            if !missing.isEmpty { report(apple.key("options").key(option), message(option, missing)) }
            for os in ComponentContract.appleOSes {
                guard let target = entry[os], let osKept = target["options"]?[option]?.elements?.compactMap(\.string)
                else { continue }
                var osMissing: [String] = []
                // By value the OS lacks a fallback for, the declared values Apple's fallback turns into it.
                var through: [String: [String]] = [:]
                for value in declared {
                    // A value Apple's fallback sends where Apple does not keep is reported there.
                    guard let reached = drawn[value], appleKept.contains(reached), !osKept.contains(reached),
                        fallback(target, option, reached) == nil
                    else { continue }
                    if !osMissing.contains(reached) { osMissing.append(reached) }
                    if reached != value { through[reached, default: []].append(value) }
                }
                guard !osMissing.isEmpty else { continue }
                let chains = osMissing.compactMap { reached in
                    through[reached].map { "\($0.joined(separator: ", ")) → \(reached)" }
                }
                report(
                    apple.key(os).key("options").key(option),
                    message(option, osMissing)
                        + (chains.isEmpty
                            ? ""
                            : " (Apple's fallback comes first: \(chains.joined(separator: "; ")), then this OS's)"))
            }
        }
    }

    /// A platform's keyboard intents add to the component's (and an Apple OS's to Apple's): none repeats one.
    private mutating func checkKeyboardIntents(_ platform: JSON, at path: DocumentPath, isAppleOS: Bool) {
        let component = document["accessibility"]?["keyboardIntents"]?.elements?.compactMap(\.string) ?? []
        let apple =
            isAppleOS
            ? value(at: DocumentPath.root.key("platforms").key("apple").key("keyboardIntents"))?.elements?
                .compactMap(\.string) ?? [] : []
        for (index, element) in (platform["keyboardIntents"]?.elements ?? []).enumerated() {
            guard let intent = element.string else { continue }
            if component.contains(intent) {
                report(
                    path.key("keyboardIntents").index(index),
                    "\"\(intent)\" is already in accessibility.keyboardIntents; list here only what this platform adds")
            } else if apple.contains(intent) {
                report(
                    path.key("keyboardIntents").index(index),
                    "\"\(intent)\" is already in Apple's keyboardIntents; list here only what this OS adds")
            }
        }
    }

    /// A platform's `systemOptions` name options of the contract.
    mutating func checkSystemOptions() {
        let names = (document["options"]?.members ?? []).map(\.key)
        for platform in ["apple", "web", "linux", "android"] {
            let path = DocumentPath.root.key("platforms").key(platform).key("systemOptions")
            for member in value(at: path)?.members ?? [] where !names.contains(member.key) {
                report(path.key(member.key), unknownOption(member.key))
            }
        }
    }

    /// The states assistive technology announces are states of the contract.
    mutating func checkAccessibility() {
        let declared = states ?? []
        for member in document["accessibility"]?["states"]?.members ?? [] where !declared.contains(member.key) {
            report(
                .root.key("accessibility").key("states").key(member.key),
                declared.isEmpty
                    ? "\"\(member.key)\": the contract declares no states"
                    : "\"\(member.key)\" is not one of the states: \(declared.joined(separator: ", "))")
        }
    }

    /// Every place that can restrict the contract: each platform, then each Apple OS.
    private var restrictions: [(JSON, DocumentPath)] {
        let platforms = DocumentPath.root.key("platforms")
        var result: [(JSON, DocumentPath)] = []
        for name in ["apple", "web", "linux", "android"] {
            guard let platform = document["platforms"]?[name], platform.members != nil else { continue }
            result.append((platform, platforms.key(name)))
            if name == "apple" {
                for os in ["ios", "macos", "watchos"] {
                    if let target = platform[os], target.members != nil {
                        result.append((target, platforms.key(name).key(os)))
                    }
                }
            }
        }
        return result
    }

    private func unknownOption(_ option: String) -> String {
        let names = (document["options"]?.members ?? []).map(\.key)
        return "no option \(option)" + (names.isEmpty ? "" : "; the options are \(names.joined(separator: ", "))")
    }

    private func unknownValue(_ value: String, of option: String, _ values: [String]) -> String {
        "\"\(value)\" is not one of the values of \(option): \(values.joined(separator: ", "))"
    }

    private func value(at path: DocumentPath) -> JSON? {
        var value: JSON? = document
        for segment in path.segments {
            switch segment {
            case .key(let key): value = value?[key]
            case .index(let index):
                guard let elements = value?.elements, elements.indices.contains(index) else { return nil }
                value = elements[index]
            }
        }
        return value
    }
}

extension JSON {
    var elements: [JSON]? {
        if case .array(let elements) = self { return elements }
        return nil
    }
}
