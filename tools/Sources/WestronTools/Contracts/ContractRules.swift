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
    }

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
            for member in platform["options"]?.members ?? [] { lists.append(path.key("options").key(member.key)) }
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

    /// An enum option's default is one of its values.
    mutating func checkOptions() {
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
        let enums = enumOptions
        let bools = boolOptions
        for (index, constraint) in (document["constraints"]?.elements ?? []).enumerated() {
            for side in ["when", "require"] {
                let path = DocumentPath.root.key("constraints").index(index).key(side)
                for member in constraint[side]?.members ?? [] {
                    let option = member.key
                    let place = path.key(option)
                    if bools.contains(option) {
                        if case .bool = member.value { continue }
                        report(place, "\(option) is a bool option: give true or false")
                    } else if let values = enums[option] {
                        let named: [(DocumentPath, JSON)] =
                            if case .array(let elements) = member.value {
                                elements.enumerated().map { (place.index($0.offset), $0.element) }
                            } else {
                                [(place, member.value)]
                            }
                        for (at, value) in named {
                            if case .bool = value {
                                report(at, "\(option) is an enum option: name its values, not true or false")
                            } else if let name = value.string, !values.contains(name) {
                                report(at, unknownValue(name, of: option, values))
                            }
                        }
                    } else {
                        report(place, unknownOption(option))
                    }
                }
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
