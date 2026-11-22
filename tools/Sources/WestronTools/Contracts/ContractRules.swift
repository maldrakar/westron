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

    /// The options of type `tokens`, by name, with their token group.
    private var tokenOptions: [String: String] {
        var result: [String: String] = [:]
        for member in document["options"]?.members ?? [] where member.value["type"] == .string("tokens") {
            if let group = member.value["group"]?.string { result[member.key] = group }
        }
        return result
    }

    /// The options of type `icons`, by name.
    private var iconOptions: Set<String> {
        Set((document["options"]?.members ?? []).filter { $0.value["type"] == .string("icons") }.map(\.key))
    }

    /// Why an option of type `tokens` cannot be named at a place, for a message.
    private func tokenOptionNamed(_ option: String, _ group: String, in place: String) -> String {
        "\(option) takes its values from the tokens of \(group), and \(place) do not name such an option yet"
    }

    /// Why an option of type `icons` cannot be named at a place, for a message.
    private func iconOptionNamed(_ option: String, in place: String) -> String {
        "\(option) takes its values from the icon registry (\(IconRegistry.defaultFile)), and \(place) do not name "
            + "such an option yet"
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
        checkTokenOptions()
        checkIconOptions()
        checkSwiftNames()
        checkSystemStyles()
        checkConstraints()
        checkTokens()
        checkPlatforms()
        checkAppleFallbacks()
        checkSystemOptions()
        checkAccessibility()
        checkForms()
    }

    /// A contract with forms (`forms`): each form enters states the contract declares, and every declared state is
    /// entered by some form, or nothing would draw it; each form's accessibility, the contract's with the fields the
    /// form names in their place, follows the rules of `accessibility`, its announced states among the form's states;
    /// each platform that implements it names a base for every form in `bases` and none other, and no `base`; on Apple
    /// the conventions derive forms only for a style on system controls (spec/conventions.md, "Forms"). A contract
    /// without forms names no `bases`.
    mutating func checkForms() {
        let root = DocumentPath.root
        let platforms = ["apple", "web", "linux", "android"]
        guard let forms = document["forms"]?.members else {
            for platform in platforms where value(at: root.key("platforms").key(platform).key("bases")) != nil {
                report(
                    root.key("platforms").key(platform).key("bases"),
                    "bases names a base per form, and the contract has no forms: name one base in base")
            }
            return
        }
        let declared = states ?? []
        var entered: Set<String> = []
        for form in forms {
            let path = root.key("forms").key(form.key)
            let formStates = form.value["states"]?.elements?.compactMap(\.string) ?? []
            for (index, state) in formStates.enumerated() {
                if declared.contains(state) {
                    entered.insert(state)
                } else {
                    report(
                        path.key("states").index(index),
                        declared.isEmpty
                            ? "\"\(state)\": the contract declares no states"
                            : "\"\(state)\" is not one of the states: \(declared.joined(separator: ", "))")
                }
            }
            checkFormAccessibility(form.value, states: formStates, at: path.key("accessibility"))
        }
        for (index, state) in declared.enumerated() where !entered.contains(state) {
            report(root.key("states").index(index), "no form enters \(state): add it to a form's states, or remove it")
        }
        let names = forms.map(\.key)
        for platform in platforms {
            let path = root.key("platforms").key(platform)
            guard let entry = value(at: path), entry["strategy"] != nil else { continue }
            if entry["base"] != nil {
                report(
                    path.key("base"),
                    "the contract has forms, so each has its base in bases (\(names.joined(separator: ", "))), "
                        + "not one base")
            }
            guard let bases = entry["bases"]?.members else { continue }
            let missing = names.filter { name in !bases.contains { $0.key == name } }
            if !missing.isEmpty {
                report(path.key("bases"), "no base for the form \(missing.joined(separator: ", "))")
            }
            for member in bases where !names.contains(member.key) {
                report(
                    path.key("bases").key(member.key),
                    "\"\(member.key)\" is not one of the forms: \(names.joined(separator: ", "))")
            }
            if platform == "apple", let strategy = entry["strategy"]?.string, strategy != AppleComponents.strategy {
                report(
                    path.key("strategy"),
                    "the conventions derive forms on Apple only for a \(AppleComponents.strategy), each form a style "
                        + "on its base (spec/conventions.md, \"Forms\"), not for an \(strategy)")
            }
        }
    }

    /// One form's accessibility, the contract's with the fields the form names in their place, as `checkAccessibility`
    /// checks the contract's: a role of none has nothing to act on, announce or require; announced states are the
    /// form's.
    private mutating func checkFormAccessibility(_ form: JSON, states: [String], at path: DocumentPath) {
        let own = form["accessibility"]
        let shared = document["accessibility"]
        func field(_ key: String) -> (JSON?, DocumentPath) {
            if let value = own?[key] { return (value, path.key(key)) }
            return (shared?[key], DocumentPath.root.key("accessibility").key(key))
        }
        let why = "in this form the role is \(Self.noRole): it adds no role of its own, so assistive technology"
        if field("role").0?.string == Self.noRole {
            for key in ["intents", "keyboardIntents"] {
                let (value, place) = field(key)
                if !(value?.elements ?? []).isEmpty {
                    report(place, "\(why) has nothing to do with it; give the form \(key): [], or its role")
                }
            }
            let (announced, place) = field("states")
            if !(announced?.members ?? []).isEmpty {
                report(place, "\(why) announces no state of it; give the form states: {}, or its role")
            }
            let (label, labelPlace) = field("label")
            if label?.string == "required" {
                report(labelPlace, "\(why) reads no label of it: give the form label: optional, or its role")
            }
        }
        let (announced, place) = field("states")
        for member in announced?.members ?? [] where !states.contains(member.key) {
            report(
                place.key(member.key),
                "\"\(member.key)\" is announced, and this form does not enter it"
                    + (states.isEmpty ? "" : ": \(states.joined(separator: ", "))"))
        }
    }

    /// An unquoted word that YAML 1.1 reads as a boolean, other than `true` and `false`, is a mistake wherever it
    /// stands: as a boolean the contract writes `true` or `false`, and as a name it must be quoted. Other problems of
    /// that value only restate it, so they are dropped. A mapping key that YAML reads as a boolean or a number is
    /// quoted too: the document keeps it as written, another YAML reader does not. The value under such a key is
    /// still checked as usual, and so is the key as a name.
    mutating func checkYAMLWords() {
        for scalar in implicit {
            if scalar.isKey {
                guard scalar.kind != .null else { continue }
                report(
                    scalar.path,
                    "YAML reads the key \(scalar.text) as a \(scalar.kind == .bool ? "boolean" : "number"), "
                        + "not a name: quote it, \"\(scalar.text)\"")
                continue
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

    /// Option values, states, forms and option names become Swift names on Apple, the pilot platform: none may be a
    /// word Swift cannot use there.
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
        // A form is a case of the generated `<Component>Form` too.
        for form in document["forms"]?.members ?? [] {
            guard let reason = Self.unusableCases[form.key] else { continue }
            report(.root.key("forms").key(form.key), "\"\(form.key)\" cannot be a form: \(reason); choose another name")
        }
    }

    /// The key of a case's `when` that names states; no option may take it.
    static let stateKey = "state"

    /// The key of a constraint's `when` that names slots an instance fills; no option may take it.
    static let slotsKey = "slots"

    /// The key under a case's `state` that names states which must all hold at once: `state: {all: [checked,
    /// pressed]}`.
    static let allStatesKey = "all"

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
                    let path = root.key("tokens").key(member.key).key("cases").index(index).key("when")
                    lists.append(path.key(condition.key))
                    if condition.key == Self.stateKey { lists.append(path.key(condition.key).key(Self.allStatesKey)) }
                }
            }
        }
        for member in document["forms"]?.members ?? [] {
            let path = root.key("forms").key(member.key)
            lists += [
                path.key("states"), path.key("accessibility").key("intents"),
                path.key("accessibility").key("keyboardIntents"),
            ]
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

    /// An enum option's default is one of its values; no option takes the name a case gives to states or the name a
    /// constraint gives to slots.
    mutating func checkOptions() {
        for member in document["options"]?.members ?? [] where member.key == Self.stateKey {
            report(
                .root.key("options").key(member.key),
                "\"\(Self.stateKey)\" names the states in a case of a token binding; give the option another name")
        }
        for member in document["options"]?.members ?? [] where member.key == Self.slotsKey {
            report(
                .root.key("options").key(member.key),
                "\"\(Self.slotsKey)\" names the slots in a constraint's when; give the option another name")
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

    /// An option of type `tokens` takes its values from a group of tokens/ that holds semantic tokens of one type,
    /// each in every mode; its default, when it has one, is one of them.
    mutating func checkTokenOptions() {
        for member in document["options"]?.members ?? [] where member.value["type"] == .string("tokens") {
            let path = DocumentPath.root.key("options").key(member.key)
            guard let group = member.value["group"]?.string, !group.isEmpty else { continue }
            let (values, problems) = tokens.group(TokenPath(group))
            for problem in problems { report(path.key("group"), problem) }
            guard !values.isEmpty, let fallback = member.value["default"]?.string, !values.contains(fallback)
            else { continue }
            report(
                path.key("default"),
                "\"\(fallback)\" is not a token of \(group): \(values.joined(separator: ", "))")
        }
    }

    /// An optional option whose values are icons (`optional: true`) is derived only for a style on a system control,
    /// as a labeled `Westron.Icon? = nil` of its overload (spec/conventions.md, "Option whose values are icons"); an
    /// own view's glyph, Icon's, is always named, and an extension takes no such option.
    mutating func checkIconOptions() {
        let strategy = document["platforms"]?["apple"]?["strategy"]?.string
        for member in document["options"]?.members ?? []
        where member.value["type"] == .string("icons") && member.value["optional"] == .bool(true) {
            guard strategy != AppleComponents.strategy else { continue }
            report(
                .root.key("options").key(member.key).key("optional"),
                "an optional glyph is derived only for a \(AppleComponents.strategy), as an argument of its overload "
                    + "that defaults to none (spec/conventions.md); "
                    + (strategy.map { "an \($0) names its glyph in every use" } ?? "the Apple entry has no strategy")
                    + ": remove optional")
        }
    }

    /// The Apple strategy fits its base: a style goes on a control that has a style modifier, and an extension on a
    /// control or view that has none (`SystemStyles`). No option value is the static name of a system style of the
    /// Apple base control, which westron's overload would shadow (decisions/0003).
    mutating func checkSystemStyles() {
        let apple = DocumentPath.root.key("platforms").key("apple")
        guard let strategy = value(at: apple.key("strategy"))?.string else { return }
        if let base = value(at: apple.key("base"))?.string {
            checkSystemStyles(of: base, at: apple.key("base"), strategy: strategy)
        }
        // A contract with forms: each form's base, as `base` is checked.
        for member in value(at: apple.key("bases"))?.members ?? [] {
            guard let base = member.value.string else { continue }
            checkSystemStyles(of: base, at: apple.key("bases").key(member.key), strategy: strategy)
        }
    }

    private mutating func checkSystemStyles(of base: String, at basePath: DocumentPath, strategy: String) {
        let apple = DocumentPath.root.key("platforms").key("apple")
        if strategy == SystemStyles.extensionStrategy {
            if let styled = SystemStyles.byBase[base] {
                report(
                    apple.key("strategy"),
                    "\(base) takes a style (\(styled.modifier)), so westron gives it one: its component is a "
                        + "style-on-system-control (decisions/0003)")
            } else if !SystemStyles.withoutStyle.contains(base) {
                report(
                    basePath,
                    "the validator does not know \(base): add it to SystemStyles.withoutStyle "
                        + "(tools/Sources/WestronTools/Contracts/SystemStyles.swift) once it is checked that SwiftUI "
                        + "gives it no style modifier, or, if it has one, to SystemStyles.byBase and make the component "
                        + "a style-on-system-control")
            }
            return
        }
        guard strategy == AppleComponents.strategy else { return }
        if SystemStyles.withoutStyle.contains(base) {
            report(
                apple.key("strategy"),
                "\(base) has no style modifier, so a style cannot go on it: its component is an "
                    + "\(SystemStyles.extensionStrategy), which adds a modifier to it (decisions/0003)")
            return
        }
        guard let styles = SystemStyles.byBase[base]?.styles else {
            report(
                basePath,
                "the validator does not know the system styles of \(base): add its style modifier and their names "
                    + "to SystemStyles.byBase (tools/Sources/WestronTools/Contracts/SystemStyles.swift, "
                    + "decisions/0003); a control with no style modifier, such as SwiftUI.Slider, takes no style, so "
                    + "its component is an extension-on-system-control or an own-component")
            return
        }
        for member in document["options"]?.members ?? [] where member.value["type"] == .string("enum") {
            for (index, element) in (member.value["values"]?.elements ?? []).enumerated() {
                guard let value = element.string, styles.contains(value) else { continue }
                report(
                    .root.key("options").key(member.key).key("values").index(index),
                    "\"\(value)\" is the name of a system style of \(base), so a call such as .\(value) would "
                        + "silently take westron's style instead of the system's (decisions/0003); choose another name")
            }
        }
    }

    /// Constraints name options that exist, with values those options have. A constraint's `when` may instead name
    /// slots under `slots`, the slots an instance fills: then, as narrow as what the conventions derive from it
    /// (spec/conventions.md, "Own components"), it names slots the contract declares and no option, forbids (severity
    /// `error`), and its `require` gives enum options one value each, which an instance that fills the slots takes.
    /// The conventions derive that only for an Apple `own-component` of form `view` whose one slot is `label`, drawn
    /// text, with no option whose values are icons (`AppleComponents.Own`), so a constraint on a slot is an error on
    /// any other contract: nothing would enforce it.
    mutating func checkConstraints() {
        let enums = enumOptions
        let declaredSlots = document["slots"]?.elements?.compactMap(\.string) ?? []
        let apple = DocumentPath.root.key("platforms").key("apple")
        let derived =
            value(at: apple.key("strategy"))?.string == AppleComponents.ownStrategy
            && value(at: apple.key("form"))?.string == AppleComponents.Own.Form.view.rawValue
            && declaredSlots == ["label"] && iconOptions.isEmpty
        for (index, constraint) in (document["constraints"]?.elements ?? []).enumerated() {
            let path = DocumentPath.root.key("constraints").index(index)
            var when = constraint["when"]?.members ?? []
            if let slots = when.first(where: { $0.key == Self.slotsKey }) {
                when.removeAll { $0.key == Self.slotsKey }
                let place = path.key("when").key(Self.slotsKey)
                if !derived {
                    report(
                        place,
                        "a constraint on slots is derived only for an Apple \(AppleComponents.ownStrategy) of form "
                            + "view whose one slot is label, drawn text, with no option whose values are icons "
                            + "(spec/conventions.md, \"Own components\"): the conventions derive no API from it on "
                            + "this contract yet")
                }
                let named: [(DocumentPath, JSON)] =
                    if case .array(let elements) = slots.value {
                        elements.enumerated().map { (place.index($0.offset), $0.element) }
                    } else {
                        [(place, slots.value)]
                    }
                for (at, value) in named {
                    guard let name = value.string else {
                        report(at, "name a slot, not true or false")
                        continue
                    }
                    if !declaredSlots.contains(name) {
                        report(
                            at,
                            declaredSlots.isEmpty
                                ? "\"\(name)\": the contract declares no slots"
                                : "\"\(name)\" is not one of the slots: \(declaredSlots.joined(separator: ", "))")
                    }
                }
                if !when.isEmpty {
                    report(
                        path.key("when"),
                        "a constraint on slots names no option in its when: the conventions derive no API from both")
                }
                if constraint["severity"]?.string != "error" {
                    report(
                        path.key("severity"),
                        "a constraint on slots forbids (error): the conventions derive no API from advice")
                }
                for member in constraint["require"]?.members ?? [] {
                    let one: Bool =
                        if case .array(let elements) = member.value { elements.count == 1 } else { true }
                    if enums[member.key] != nil, !one {
                        report(
                            path.key("require").key(member.key),
                            "a constraint on slots gives \(member.key) one value, which an instance that fills them "
                                + "takes")
                    } else if enums[member.key] == nil, boolOptions.contains(member.key) {
                        report(
                            path.key("require").key(member.key),
                            "a constraint on slots requires enum options only: the conventions derive no API for a "
                                + "bool option yet")
                    }
                }
            }
            checkConditions(when, at: path.key("when"), states: false)
            checkConditions(constraint["require"]?.members ?? [], at: path.key("require"), states: false)
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
            var named: [(DocumentPath, JSON)] =
                if case .array(let elements) = member.value {
                    elements.enumerated().map { (place.index($0.offset), $0.element) }
                } else {
                    [(place, member.value)]
                }
            // `state: {all: [checked, pressed]}`: every one of the states at once; the schema checks its shape.
            if states, option == Self.stateKey, case .object = member.value {
                guard let all = member.value[Self.allStatesKey]?.elements else { continue }
                named = all.enumerated().map { (place.key(Self.allStatesKey).index($0.offset), $0.element) }
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
            } else if let group = tokenOptions[option] {
                report(place, tokenOptionNamed(option, group, in: states ? "cases" : "constraints"))
            } else if iconOptions.contains(option) {
                report(place, iconOptionNamed(option, in: states ? "cases" : "constraints"))
            } else {
                report(place, unknownOption(option) + (states ? ", and the key state names states" : ""))
            }
        }
    }

    /// The shapes a part's `shape` binds instead of a token, which no radius can draw: `capsule`, the platform's own
    /// capsule, fully round ends at any height (design-language/04, "A capsule is the platform's capsule").
    static let shapes = ["capsule"]

    /// Token bindings name tokens that exist in every mode and are not primitives; a binding by option value uses
    /// the values of one enum option. A part's `shape` binds one of `shapes`, alone or in cases (a text field is a
    /// capsule on one line only), and only a `shape` does.
    mutating func checkTokens() {
        let enums = enumOptions
        for member in document["tokens"]?.members ?? [] {
            let path = DocumentPath.root.key("tokens").key(member.key)
            let isShape = member.key.hasSuffix(".shape")
            let isCases = member.value["cases"] != nil
            if isShape && !isCases && !Self.shapes.contains(member.value.string ?? "") {
                report(path, "a part's shape is one of \(Self.shapes.joined(separator: ", ")), not a token")
                continue
            }
            switch member.value {
            case .string(let shape) where Self.shapes.contains(shape):
                if !isShape { report(path, "\(shape) is a shape: bind it to a part's shape, such as container.shape") }
            case .string(let token):
                checkToken(token, at: path)
            case .object where isCases:
                checkCases(member.value, at: path, shape: isShape)
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
                } else if let (option, group) = tokenOptions.sorted(by: { $0.key < $1.key }).first(where: { _, group in
                    let values = tokens.group(TokenPath(group)).values
                    return keys.allSatisfy(values.contains)
                }) {
                    report(path, tokenOptionNamed(option, group, in: "bindings by value"))
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

    /// A case binding: each case's `when` names options, values and states that exist, its token can be bound, every
    /// case is reachable (some combination of options and states matches it before any earlier case, since cases
    /// apply first match), and so is the binding's `token`, which applies where no case matches. In the cases of a
    /// part's `shape` (`shape`), each token is one of `shapes` instead.
    private mutating func checkCases(_ binding: JSON, at path: DocumentPath, shape: Bool = false) {
        func checkToken(_ token: String, at place: DocumentPath) {
            switch (shape, Self.shapes.contains(token)) {
            case (true, true): break
            case (true, false):
                report(place, "a part's shape is one of \(Self.shapes.joined(separator: ", ")), not a token")
            case (false, true):
                report(place, "\(token) is a shape: bind it to a part's shape, such as container.shape")
            case (false, false): self.checkToken(token, at: place)
            }
        }
        if let token = binding["token"]?.string { checkToken(token, at: path.key("token")) }
        var domains = enumOptions
        for option in boolOptions { domains[option] = ["false", "true"] }
        var cases: [(index: Int, when: CaseReachability.Case)] = []
        var complete = true
        for (index, item) in (binding["cases"]?.elements ?? []).enumerated() {
            let place = path.key("cases").index(index)
            if let token = item["token"]?.string { checkToken(token, at: place.key("token")) }
            guard let conditions = item["when"]?.members else {
                complete = false
                continue
            }
            let before = problems.count
            checkConditions(conditions, at: place.key("when"), states: true)
            // A case whose conditions are wrong is reported there, or by the schema (an empty list, a value that is
            // not text, an option without values); reachability leaves it out.
            let when = place.key("when").segments
            let misread = yamlWords.contains { Array($0.segments.prefix(when.count)) == when }
            if problems.count == before, !misread, let when = Self.reachabilityCase(conditions, domains: domains) {
                cases.append((index, when))
            } else {
                complete = false
            }
        }
        let reachability = CaseReachability(cases: cases.map(\.when), domains: domains)
        guard let result = reachability.check() else {
            let count = reachability.combinations == .max ? "more than \(Int.max)" : "\(reachability.combinations)"
            let what = reachability.countsStates ? "option values and sets of states" : "option values"
            report(
                path.key("cases"),
                "the cases name too many combinations of \(what) to check that each is used (\(count), at "
                    + "most \(CaseReachability.limit))")
            return
        }
        func names(_ covering: [Int]) -> String {
            let names = covering.map { "cases[\(cases[$0].index)]" }
            return names.count == 1 ? names[0] : names.dropLast().joined(separator: ", ") + " and " + names.last!
        }
        for (position, covering) in result.unreachable where !covering.isEmpty {
            let (index, when) = cases[position]
            let message: String
            if covering.count == 1 {
                message =
                    cases[covering[0]].when == when
                    ? "repeats the when of \(names(covering)), so this case is never used"
                    : "\(names(covering)) matches everything this case matches, so it is never used: put the "
                        + "narrower case first"
            } else {
                message =
                    "\(names(covering)) together match everything this case matches, so it is never used: put it "
                    + "before them, or remove it"
            }
            report(path.key("cases").index(index).key("when"), message)
        }
        // Only when every case was checked: one left out could be the one that leaves room for the token.
        if complete, binding["token"] != nil, let covering = result.coverAll, !covering.isEmpty {
            report(
                path.key("token"),
                "\(names(covering)) \(covering.count == 1 ? "matches" : "together match") every combination, so this "
                    + "token is never used: remove it")
        }
    }

    /// A case's conditions for the reachability check, or nil when one names no value or a value that is not text,
    /// or an option with no values.
    private static func reachabilityCase(_ conditions: [JSON.Member], domains: [String: [String]])
        -> CaseReachability.Case?
    {
        var options: [String: Set<String>] = [:]
        var states: Set<String>?
        var allStates: Set<String>?
        if let state = conditions.first(where: { $0.key == stateKey })?.value, case .object = state {
            guard let all = state[allStatesKey]?.elements?.compactMap(\.string), all.count >= 2 else { return nil }
            allStates = Set(all)
        }
        for (key, values) in conditionSets(conditions.filter { !($0.key == stateKey && allStates != nil) }) {
            guard let values, !values.isEmpty else { return nil }
            if key == stateKey {
                states = values
            } else {
                guard domains[key]?.isEmpty == false else { return nil }
                options[key] = values
            }
        }
        return CaseReachability.Case(options: options, states: states, allStates: allStates)
    }

    /// Conditions as sets of the values each key accepts, `true` and `false` as text; nil for a key with a value
    /// that is neither text nor a boolean.
    private static func conditionSets(_ conditions: [JSON.Member]) -> [String: Set<String>?] {
        func text(_ value: JSON) -> String? {
            if case .bool(let flag) = value { return flag ? "true" : "false" }
            return value.string
        }
        var result: [String: Set<String>?] = [:]
        for member in conditions {
            let values = member.value.elements ?? [member.value]
            let texts = values.compactMap(text)
            result[member.key] = texts.count == values.count ? Set(texts) : nil
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
                    if let group = tokenOptions[option] {
                        report(place, tokenOptionNamed(option, group, in: "platform restrictions"))
                    } else if iconOptions.contains(option) {
                        report(place, iconOptionNamed(option, in: "platform restrictions"))
                    } else {
                        report(
                            place,
                            boolOptions.contains(option)
                                ? "\(option) is a bool option: only enum options can be restricted"
                                : unknownOption(option))
                    }
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

    /// A platform's `systemOptions` name options of the contract, none of whose values are westron's tokens.
    mutating func checkSystemOptions() {
        let names = (document["options"]?.members ?? []).map(\.key)
        let tokenOptions = tokenOptions
        for platform in ["apple", "web", "linux", "android"] {
            let path = DocumentPath.root.key("platforms").key(platform).key("systemOptions")
            for member in value(at: path)?.members ?? [] {
                if let group = tokenOptions[member.key] {
                    report(
                        path.key(member.key),
                        "\(member.key) takes its values from the tokens of \(group), which are westron's, not the "
                            + "system's: a system option's values are its system type's; remove it here")
                } else if iconOptions.contains(member.key) {
                    report(
                        path.key(member.key),
                        "\(member.key) takes its values from westron's icon registry (\(IconRegistry.defaultFile)), "
                            + "not from a system type: remove it here")
                } else if !names.contains(member.key) {
                    report(path.key(member.key), unknownOption(member.key))
                }
            }
        }
    }

    /// The abstract role of a component that adds no role of its own: assistive technology reads its content as if
    /// the component were not there (ARIA's `none`).
    static let noRole = "none"

    /// The states assistive technology announces are states of the contract. A component whose role is `none` gives
    /// assistive technology nothing to act on or announce: no intents, no keyboard intents, its own or a platform's,
    /// no announced states, and no required label.
    mutating func checkAccessibility() {
        let accessibility = DocumentPath.root.key("accessibility")
        if document["accessibility"]?["role"]?.string == Self.noRole {
            let why = "the role is \(Self.noRole): the component adds no role of its own, so assistive technology"
            for key in ["intents", "keyboardIntents"] where !(document["accessibility"]?[key]?.elements ?? []).isEmpty {
                report(accessibility.key(key), "\(why) has nothing to do with it; remove them, or give it its role")
            }
            if !(document["accessibility"]?["states"]?.members ?? []).isEmpty {
                report(accessibility.key("states"), "\(why) announces no state of it; remove them, or give it its role")
            }
            if document["accessibility"]?["label"]?.string == "required" {
                report(
                    accessibility.key("label"),
                    "\(why) reads no label of it: a label is required only of a component with a role; make it "
                        + "optional, or give it its role")
            }
            for (platform, path) in restrictions where !(platform["keyboardIntents"]?.elements ?? []).isEmpty {
                report(
                    path.key("keyboardIntents"), "\(why) has nothing to do with it; remove them, or give it its role")
            }
        }
        checkHiddenLabel()
        let declared = states ?? []
        for member in document["accessibility"]?["states"]?.members ?? [] where !declared.contains(member.key) {
            report(
                .root.key("accessibility").key("states").key(member.key),
                declared.isEmpty
                    ? "\"\(member.key)\": the contract declares no states"
                    : "\"\(member.key)\" is not one of the states: \(declared.joined(separator: ", "))")
        }
    }

    /// A label that is not drawn (`accessibility.hiddenLabel`) is still the accessible name, so it is required, and it
    /// is the contract's `label` slot. On Apple the conventions derive its initializer only for a style on a base
    /// whose parameters `SystemStyles.Base.hiddenLabelParameters` gives (spec/conventions.md, "A label that is not
    /// drawn").
    mutating func checkHiddenLabel() {
        let path = DocumentPath.root.key("accessibility").key("hiddenLabel")
        guard document["accessibility"]?["hiddenLabel"] == .bool(true) else { return }
        if document["accessibility"]?["label"]?.string != "required" {
            report(
                path,
                "a label that is not drawn is still the component's accessible name, so every instance has one: make "
                    + "accessibility.label required")
        }
        if !(document["slots"]?.elements?.compactMap(\.string).contains("label") ?? false) {
            report(path, "a label that is not drawn is the contract's label slot, and it has none: add label to slots")
        }
        let apple = DocumentPath.root.key("platforms").key("apple")
        guard let strategy = value(at: apple.key("strategy"))?.string else { return }
        let base = value(at: apple.key("base"))?.string
        if strategy != AppleComponents.strategy
            || base.flatMap({ SystemStyles.byBase[$0]?.hiddenLabelParameters }) == nil
        {
            report(path, AppleComponents.HiddenLabel.notDerived(strategy: strategy, base: base))
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
