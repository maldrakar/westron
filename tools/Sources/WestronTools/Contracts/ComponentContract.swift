/// What the API generators read from a component contract: its options, its states and the Apple entry of its
/// `platforms` block, typed. Reading assumes a contract that passes the schema; what the generators need and do not
/// find throws a `ContractProblem` instead of producing code from a guess.
public struct ComponentContract: Equatable, Sendable {
    public struct Option: Equatable, Sendable {
        public enum Kind: Equatable, Sendable {
            /// The values in the contract's order; `default` is nil when every use must name a value.
            case enumeration(values: [String], default: String?)
            case bool(default: Bool)
            /// The tokens under a token group, `typography`, whose paths after it are the values; `default` is nil
            /// when every use must name one. The values are in tokens/, not in the contract.
            case tokenGroup(String, default: String?)
            /// The names of the icon registry, `spec/icons/icons.yaml`, in its order: the values are in the registry,
            /// not in the contract. There is no default: every use names its glyph.
            case icons
        }

        public let name: String
        public let kind: Kind
        public let description: String?

        public init(name: String, kind: Kind, description: String? = nil) {
            self.name = name
            self.kind = kind
            self.description = description
        }
    }

    /// What the values a platform drops become there: one value for every dropped one, or one per dropped value.
    public enum Fallback: Equatable, Sendable {
        case all(String)
        case byValue([String: String])
    }

    /// What a platform, or one Apple OS, keeps of the contract.
    public struct Restriction: Equatable, Sendable {
        /// By enum option, the values offered; an option not named is offered whole.
        public var options: [String: [String]]
        public var fallback: [String: Fallback]
        /// The states entered; nil: every state the level above enters.
        public var states: [String]?

        public init(options: [String: [String]] = [:], fallback: [String: Fallback] = [:], states: [String]? = nil) {
            self.options = options
            self.fallback = fallback
            self.states = states
        }
    }

    /// The Apple entry of `platforms`, when it is not planned.
    public struct Apple: Equatable, Sendable {
        /// `style-on-system-control`, `extension-on-system-control` or `own-component`.
        public let strategy: String
        /// The system control or view, such as `SwiftUI.Button`; nil for an own component and for a contract with forms,
        /// which names a base per form in `bases`.
        public let base: String?
        /// In a contract with forms, the base of each form, in the order of `bases`: `(selectable, SwiftUI.Toggle)`.
        /// Empty for a contract without forms.
        public let bases: [FormBase]
        /// The shape of an own component's API, `modifier` or `view` (spec/conventions.md, "Own components"); nil for
        /// a style or an extension.
        public let form: String?
        /// By option name, the system API that carries the option on Apple, such as `role: SwiftUI.ButtonRole`: no
        /// type is generated for it.
        public let systemOptions: [String: String]
        /// What all of Apple keeps.
        public let restriction: Restriction
        /// What each OS keeps of Apple's, by `ios`, `macos`, `watchos`.
        public let targets: [String: Restriction]

        public init(
            strategy: String, base: String?, form: String? = nil, systemOptions: [String: String] = [:],
            restriction: Restriction = Restriction(), targets: [String: Restriction] = [:], bases: [FormBase] = []
        ) {
            self.strategy = strategy
            self.base = base
            self.bases = bases
            self.form = form
            self.systemOptions = systemOptions
            self.restriction = restriction
            self.targets = targets
        }

        /// The bases its styles go on, each with its form: the one `base`, with no form, or each form's base.
        public var styledBases: [FormBase] {
            if let base { return [FormBase(form: nil, base: base)] }
            return bases
        }
    }

    /// A base control on a platform, and the form it is the base of; nil in a contract without forms.
    public struct FormBase: Equatable, Sendable {
        public let form: String?
        public let base: String

        public init(form: String?, base: String) {
            self.form = form
            self.base = base
        }
    }

    /// One form of a contract with forms (`forms`): the same look on its own base control, which the product picks by
    /// the control it writes (Chip: selectable, pressable, static).
    public struct Form: Equatable, Sendable {
        public let name: String
        /// The states it enters, in the contract's order of `states`.
        public let states: [String]

        public init(name: String, states: [String]) {
            self.name = name
            self.states = states
        }
    }

    /// A rule between options: when the options have the values in `when`, they must have the values in `require`.
    /// A rule on a slot names it under the key `slots` of `when` (`ContractRules.slotsKey`): when an instance fills
    /// that slot, the options must have the values in `require` (Rule: a labelled rule is a horizontal separator).
    public struct Constraint: Equatable, Sendable {
        /// By option name, the values that match: an enum option's values, or `true` or `false` for a bool option.
        public let when: [String: [String]]
        public let require: [String: [String]]
        /// `error`: the combination is not allowed; `warning`: allowed, but advised against.
        public let severity: String
        /// The slots `when` names, which an instance fills for the rule to apply; empty for a rule between options.
        public let slots: [String]

        public init(when: [String: [String]], require: [String: [String]], severity: String, slots: [String] = []) {
            self.when = when
            self.require = require
            self.severity = severity
            self.slots = slots
        }

        /// Whether the constraint forbids what breaks it, rather than advising against it.
        public var forbids: Bool { severity == "error" }

        /// Whether a combination, by option name its value (`true` or `false` for a bool option), breaks the rule: it
        /// matches every condition of `when` and misses one of `require`. A combination of options fills no slot, so
        /// it never breaks a rule on a slot.
        public func isBroken(by values: [String: String]) -> Bool {
            guard slots.isEmpty else { return false }
            func matches(_ conditions: [String: [String]]) -> Bool {
                conditions.allSatisfy { option, allowed in values[option].map(allowed.contains) ?? false }
            }
            return matches(when) && !matches(require)
        }
    }

    public static let appleOSes = ["ios", "macos", "watchos"]

    public let id: String
    public let status: String
    /// In the contract's order.
    public let options: [Option]
    /// In the contract's order.
    public let states: [String]
    /// In the contract's order.
    public let slots: [String]
    /// nil when Apple is planned.
    public let apple: Apple?
    /// In the contract's order; empty for a contract without forms.
    public let forms: [Form]
    /// In the contract's order.
    public let constraints: [Constraint]
    /// The states some case of a token binding names in its `when` (`state: pressed`), in the contract's order of
    /// `states`. A state none names changes no token: it draws as rest, and only what the platform adds itself, such
    /// as the system's focus ring, tells it apart.
    public let boundStates: [String]
    /// `accessibility.label`: `required` or `optional`; nil when the contract gives none.
    public let accessibilityLabel: String?
    /// `accessibility.hiddenLabel`: an instance may draw no label and be given its label as its accessible name alone
    /// (spec/conventions.md, "A label that is not drawn"); false when the contract gives none.
    public let hiddenLabel: Bool

    public init(
        id: String, status: String, options: [Option], states: [String], apple: Apple?,
        constraints: [Constraint] = [], boundStates: [String]? = nil, slots: [String] = [],
        accessibilityLabel: String? = nil, hiddenLabel: Bool = false, forms: [Form] = []
    ) {
        self.forms = forms
        self.accessibilityLabel = accessibilityLabel
        self.hiddenLabel = hiddenLabel
        self.id = id
        self.status = status
        self.options = options
        self.states = states
        self.slots = slots
        self.apple = apple
        self.constraints = constraints
        self.boundStates = boundStates ?? states
    }

    /// Reads a contract's YAML text; `source` is its path, for messages.
    /// - Throws: `ContractProblem` for invalid YAML or a part the generators need that is missing or malformed.
    public init(yaml: String, source: String) throws {
        try self.init(document: try ContractYAML.parse(yaml, source: source), source: source)
    }

    init(document: JSON, source: String) throws(ContractProblem) {
        func problem(_ path: DocumentPath, _ message: String) -> ContractProblem {
            ContractProblem(source: source, path: path, message)
        }
        let root = DocumentPath.root
        guard let id = document["id"]?.string else { throw problem(root.key("id"), "missing") }
        guard let status = document["status"]?.string else { throw problem(root.key("status"), "missing") }
        var options: [Option] = []
        for member in document["options"]?.members ?? [] {
            let path = root.key("options").key(member.key)
            let description = member.value["description"]?.string
            switch member.value["type"]?.string {
            case "enum":
                guard let values = member.value["values"]?.elements?.compactMap(\.string), !values.isEmpty else {
                    throw problem(path.key("values"), "an enum option needs its values")
                }
                options.append(
                    Option(
                        name: member.key, kind: .enumeration(values: values, default: member.value["default"]?.string),
                        description: description))
            case "bool":
                guard case .bool(let value) = member.value["default"] else {
                    throw problem(path.key("default"), "a bool option needs true or false as its default")
                }
                options.append(Option(name: member.key, kind: .bool(default: value), description: description))
            case "tokens":
                guard let group = member.value["group"]?.string else {
                    throw problem(path.key("group"), "an option of type tokens needs its token group")
                }
                options.append(
                    Option(
                        name: member.key, kind: .tokenGroup(group, default: member.value["default"]?.string),
                        description: description))
            case "icons":
                options.append(Option(name: member.key, kind: .icons, description: description))
            default:
                throw problem(path.key("type"), "must be enum, bool, tokens or icons")
            }
        }
        let states = document["states"]?.elements?.compactMap(\.string) ?? []
        let applePath = root.key("platforms").key("apple")
        let apple: Apple?
        if let entry = document["platforms"]?["apple"], entry["status"] == nil {
            guard let strategy = entry["strategy"]?.string else { throw problem(applePath.key("strategy"), "missing") }
            var systemOptions: [String: String] = [:]
            for member in entry["systemOptions"]?.members ?? [] {
                guard let api = member.value.string else {
                    throw problem(applePath.key("systemOptions").key(member.key), "name the system API")
                }
                systemOptions[member.key] = api
            }
            var targets: [String: Restriction] = [:]
            for os in Self.appleOSes {
                if let target = entry[os] {
                    targets[os] = try Self.restriction(target, at: applePath.key(os), source: source)
                }
            }
            var bases: [FormBase] = []
            for member in entry["bases"]?.members ?? [] {
                guard let base = member.value.string else {
                    throw problem(applePath.key("bases").key(member.key), "name the base control")
                }
                bases.append(FormBase(form: member.key, base: base))
            }
            apple = Apple(
                strategy: strategy, base: entry["base"]?.string, form: entry["form"]?.string,
                systemOptions: systemOptions,
                restriction: try Self.restriction(entry, at: applePath, source: source), targets: targets, bases: bases)
        } else {
            apple = nil
        }
        var constraints: [Constraint] = []
        for (index, entry) in (document["constraints"]?.elements ?? []).enumerated() {
            let path = root.key("constraints").index(index)
            guard let severity = entry["severity"]?.string else { throw problem(path.key("severity"), "missing") }
            var when = try Self.conditions(entry["when"], at: path.key("when"), source: source)
            let slots = when.removeValue(forKey: ContractRules.slotsKey) ?? []
            constraints.append(
                Constraint(
                    when: when,
                    require: try Self.conditions(entry["require"], at: path.key("require"), source: source),
                    severity: severity, slots: slots))
        }
        var named: Set<String> = []
        for binding in document["tokens"]?.members ?? [] {
            for entry in binding.value["cases"]?.elements ?? [] {
                switch entry["when"]?["state"] {
                case .string(let state)?: named.insert(state)
                case .array(let list)?: named.formUnion(list.compactMap(\.string))
                case .object?: named.formUnion(entry["when"]?["state"]?["all"]?.elements?.compactMap(\.string) ?? [])
                default: break
                }
            }
        }
        var forms: [Form] = []
        for member in document["forms"]?.members ?? [] {
            let entered = Set(member.value["states"]?.elements?.compactMap(\.string) ?? [])
            forms.append(Form(name: member.key, states: states.filter(entered.contains)))
        }
        self.init(
            id: id, status: status, options: options, states: states, apple: apple, constraints: constraints,
            boundStates: states.filter(named.contains),
            slots: document["slots"]?.elements?.compactMap(\.string) ?? [],
            accessibilityLabel: document["accessibility"]?["label"]?.string,
            hiddenLabel: document["accessibility"]?["hiddenLabel"] == .bool(true), forms: forms)
    }

    /// A constraint's `when` or `require`: by option name, a value, a list of values, or `true` or `false`.
    private static func conditions(_ entry: JSON?, at path: DocumentPath, source: String) throws(ContractProblem)
        -> [String: [String]]
    {
        var conditions: [String: [String]] = [:]
        for member in entry?.members ?? [] {
            switch member.value {
            case .string(let value): conditions[member.key] = [value]
            case .bool(let value): conditions[member.key] = [String(value)]
            case .array(let values) where values.allSatisfy({ $0.string != nil }):
                conditions[member.key] = values.compactMap(\.string)
            default:
                throw ContractProblem(
                    source: source, path: path.key(member.key), "name a value, a list of values, or true or false")
            }
        }
        return conditions
    }

    private static func restriction(_ entry: JSON, at path: DocumentPath, source: String) throws(ContractProblem)
        -> Restriction
    {
        var restriction = Restriction()
        for member in entry["options"]?.members ?? [] {
            restriction.options[member.key] = member.value.elements?.compactMap(\.string) ?? []
        }
        for member in entry["fallback"]?.members ?? [] {
            switch member.value {
            case .string(let value):
                restriction.fallback[member.key] = .all(value)
            case .object(let map):
                var byValue: [String: String] = [:]
                for entry in map {
                    guard let value = entry.value.string else {
                        throw ContractProblem(
                            source: source, path: path.key("fallback").key(member.key).key(entry.key), "name a value")
                    }
                    byValue[entry.key] = value
                }
                restriction.fallback[member.key] = .byValue(byValue)
            default:
                throw ContractProblem(
                    source: source, path: path.key("fallback").key(member.key), "name a value or map values to values")
            }
        }
        restriction.states = entry["states"]?.elements?.compactMap(\.string)
        return restriction
    }
}
