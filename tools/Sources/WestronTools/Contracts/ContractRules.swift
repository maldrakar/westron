/// The rules of a contract that its JSON Schema cannot express. They walk the document leniently: a part of the wrong
/// shape is skipped, since the schema reports it, so the rules run on a contract that fails the schema too.
struct ContractRules {
    let document: JSON
    let source: String
    let tokens: ContractTokens
    private(set) var problems: [(path: DocumentPath, message: String)] = []

    init(document: JSON, source: String, tokens: ContractTokens) {
        self.document = document
        self.source = source
        self.tokens = tokens
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

    private mutating func report(_ path: DocumentPath, _ message: String) {
        problems.append((path, message))
    }

    mutating func run() {
        checkFileName()
        checkRepeats()
        checkOptions()
        checkSystemStyles()
        checkConstraints()
        checkTokens()
        checkPlatforms()
        checkSystemOptions()
        checkAccessibility()
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
        guard let styles = SystemStyles.byBase[base] else {
            report(
                apple.key("base"),
                "the validator does not know the system styles of \(base): add their names to SystemStyles.byBase "
                    + "(tools/Sources/WestronTools/Contracts/SystemStyles.swift, decisions/0003)")
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
                } else if owners.isEmpty {
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
    /// no case is shadowed by an earlier one, which would match everything it matches (cases apply first match).
    private mutating func checkCases(_ binding: JSON, at path: DocumentPath) {
        if let token = binding["token"]?.string { checkToken(token, at: path.key("token")) }
        var earlier: [(index: Int, when: [String: Set<String>])] = []
        for (index, item) in (binding["cases"]?.elements ?? []).enumerated() {
            let place = path.key("cases").index(index)
            if let token = item["token"]?.string { checkToken(token, at: place.key("token")) }
            guard let conditions = item["when"]?.members else { continue }
            checkConditions(conditions, at: place.key("when"), states: true)
            let when = Self.conditionSets(conditions)
            if let shadow = earlier.first(where: { Self.covers($0.when, when) }) {
                report(
                    place.key("when"),
                    shadow.when == when
                        ? "repeats the when of cases[\(shadow.index)], so this case is never used"
                        : "cases[\(shadow.index)] matches everything this case matches, so it is never used: "
                            + "put the narrower case first")
            }
            earlier.append((index, when))
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

    /// Whether every combination `narrow` matches is also matched by `wide`.
    private static func covers(_ wide: [String: Set<String>], _ narrow: [String: Set<String>]) -> Bool {
        wide.allSatisfy { key, values in narrow[key].map { $0.isSubset(of: values) } ?? false }
    }

    private mutating func checkToken(_ token: String, at path: DocumentPath) {
        if let problem = tokens.problem(TokenPath(token)) { report(path, problem) }
    }

    /// Each restriction of a platform offers a subset of an enum option's values and enters a subset of the states;
    /// an Apple OS's restriction is a subset of Apple's.
    mutating func checkPlatforms() {
        let enums = enumOptions
        let declaredStates = states
        let apple = DocumentPath.root.key("platforms").key("apple")
        for (platform, path) in restrictions {
            // platforms.apple.watchos
            let isAppleOS = path.segments.count == 3
            for member in platform["options"]?.members ?? [] {
                let option = member.key
                let place = path.key("options").key(option)
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

    /// A fallback names an option this place restricts and maps the values it drops to values it keeps. On Apple,
    /// whose OSes share one generated enum, every dropped value has one.
    private mutating func checkFallbacks(_ platform: JSON, at path: DocumentPath, isAppleOS: Bool) {
        let enums = enumOptions
        let apple = DocumentPath.root.key("platforms").key("apple")
        let onApple = path.segments.count >= 2 && path.segments[1] == .key("apple")
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
        guard onApple else { return }
        for (option, values) in restricted.sorted(by: { $0.key < $1.key }) where !values.dropped.isEmpty {
            let fallback = fallbacks.first { $0.key == option }?.value
            let missing: [String]
            switch fallback {
            case .string?: missing = []
            case .object(let map)?: missing = values.dropped.filter { value in !map.contains { $0.key == value } }
            default: missing = values.dropped
            }
            if !missing.isEmpty {
                report(
                    path.key("options").key(option),
                    "on Apple every dropped value needs a fallback, since the OSes share one generated enum: "
                        + "add fallback.\(option) for \(missing.joined(separator: ", "))")
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
