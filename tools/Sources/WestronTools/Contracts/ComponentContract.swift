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
            /// not in the contract. There is no default: every use names its glyph, unless the option is `optional`, and
            /// then a use that names none draws no glyph (a style's `Westron.Icon? = nil`, spec/conventions.md).
            case icons(optional: Bool)
            /// A whole number, such as a nesting level, at least `minimum` when the contract gives one. It is a quantity,
            /// not a choice: the matrix draws its default, and no constraint, case or restriction names it.
            case integer(default: Int, minimum: Int?)

            /// Whether the values are the icon registry's names, optional or not.
            public var isIcons: Bool {
                if case .icons = self { return true }
                return false
            }
        }

        public let name: String
        public let kind: Kind
        public let description: String?
        /// Whether the snapshot matrix names the option in a sheet's id and title at its default too; false for a bool
        /// option added to a contract whose sheets were reviewed without it (`nameInMatrixAtDefault: false`), so that
        /// those sheets keep their ids, titles and pictures and only its other value gets sheets with its name.
        public let namedInMatrixAtDefault: Bool

        public init(name: String, kind: Kind, description: String? = nil, namedInMatrixAtDefault: Bool = true) {
            self.name = name
            self.kind = kind
            self.description = description
            self.namedInMatrixAtDefault = namedInMatrixAtDefault
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
        /// What each OS keeps of Apple's, by `ios`, `macos`, `watchos`; an OS where the component is unavailable has
        /// none.
        public let targets: [String: Restriction]
        /// The OSes where the component does not exist (`platforms.apple.<os>.status: unavailable`), in `appleOSes`
        /// order: the system control is not there, so nothing of the component is compiled for them.
        public let unavailable: [String]

        public init(
            strategy: String, base: String?, form: String? = nil, systemOptions: [String: String] = [:],
            restriction: Restriction = Restriction(), targets: [String: Restriction] = [:], bases: [FormBase] = [],
            unavailable: [String] = []
        ) {
            self.unavailable = unavailable
            self.strategy = strategy
            self.base = base
            self.bases = bases
            self.form = form
            self.systemOptions = systemOptions
            self.restriction = restriction
            self.targets = targets
        }

        /// The OSes where the component exists, in `appleOSes` order.
        public var availableOSes: [String] { ComponentContract.appleOSes.filter { !unavailable.contains($0) } }

        /// The Swift condition every declaration of the component stands under, `!os(watchOS)`; nil where it exists
        /// on every Apple OS.
        public var availabilityCondition: String? {
            guard !unavailable.isEmpty else { return nil }
            return unavailable.compactMap { AppleComponents.osConditions[$0].map { "!" + $0 } }
                .joined(separator: " && ")
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

        /// Whether a person acts on this form (its accessibility intents, or the contract's, hold `activate`): an own
        /// view's form that takes an action (spec/conventions.md, "Own components").
        public let activates: Bool

        public init(name: String, states: [String], activates: Bool = false) {
            self.name = name
            self.states = states
            self.activates = activates
        }
    }

    /// A mark drawn around an instance that is no state of it, set per instance with its parameters (ListRow's
    /// `insertion`, where a dragged row would land): `.insertionMark(_:level:)` on Apple.
    public struct Mark: Equatable, Sendable {
        public let name: String
        /// Its parameters, in the contract's order: the first, an enum, says where the mark stands, none drawing it.
        public let parameters: [Option]
        public let description: String?

        public init(name: String, parameters: [Option], description: String? = nil) {
            self.name = name
            self.parameters = parameters
            self.description = description
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

    /// The status of an Apple OS where the component does not exist: `platforms.apple.watchos.status: unavailable`.
    public static let unavailableStatus = "unavailable"

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
    /// In the contract's order.
    public let marks: [Mark]
    /// The names of its context settings, bools a product sets on an ancestor (`context`), in the contract's order.
    public let context: [String]
    /// The values of westron's shared context it reads (`reads`), each set by the shared modifier named after it, in
    /// the contract's order: `category`, a list's color (spec/conventions.md, "Context a style reads").
    public let reads: [String]
    /// `accessibility.intents`: what a person does with the component.
    public let intents: [String]
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
        accessibilityLabel: String? = nil, hiddenLabel: Bool = false, forms: [Form] = [], marks: [Mark] = [],
        intents: [String] = [], context: [String] = [], reads: [String] = []
    ) {
        self.context = context
        self.reads = reads
        self.forms = forms
        self.marks = marks
        self.intents = intents
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
            options.append(
                try Self.option(member.key, member.value, at: root.key("options").key(member.key), source: source))
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
            var unavailable: [String] = []
            for os in Self.appleOSes {
                if let target = entry[os] {
                    if target["status"]?.string == Self.unavailableStatus {
                        unavailable.append(os)
                        continue
                    }
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
                restriction: try Self.restriction(entry, at: applePath, source: source), targets: targets, bases: bases,
                unavailable: unavailable)
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
        let intents = document["accessibility"]?["intents"]?.elements?.compactMap(\.string) ?? []
        var forms: [Form] = []
        for member in document["forms"]?.members ?? [] {
            let entered = Set(member.value["states"]?.elements?.compactMap(\.string) ?? [])
            let formIntents = member.value["accessibility"]?["intents"]?.elements?.compactMap(\.string) ?? intents
            forms.append(
                Form(
                    name: member.key, states: states.filter(entered.contains),
                    activates: formIntents.contains("activate")))
        }
        var marks: [Mark] = []
        for member in document["marks"]?.members ?? [] {
            let path = root.key("marks").key(member.key)
            var parameters: [Option] = []
            for parameter in member.value["parameters"]?.members ?? [] {
                parameters.append(
                    try Self.option(
                        parameter.key, parameter.value, at: path.key("parameters").key(parameter.key), source: source))
            }
            marks.append(
                Mark(name: member.key, parameters: parameters, description: member.value["description"]?.string))
        }
        self.init(
            id: id, status: status, options: options, states: states, apple: apple, constraints: constraints,
            boundStates: states.filter(named.contains),
            slots: document["slots"]?.elements?.compactMap(\.string) ?? [],
            accessibilityLabel: document["accessibility"]?["label"]?.string,
            hiddenLabel: document["accessibility"]?["hiddenLabel"] == .bool(true), forms: forms, marks: marks,
            intents: intents, context: (document["context"]?.members ?? []).map(\.key),
            reads: (document["reads"]?.members ?? []).map(\.key))
    }

    /// One option, or one parameter of a mark, which takes an option's shape.
    private static func option(_ name: String, _ entry: JSON, at path: DocumentPath, source: String)
        throws(ContractProblem) -> Option
    {
        func problem(_ path: DocumentPath, _ message: String) -> ContractProblem {
            ContractProblem(source: source, path: path, message)
        }
        let description = entry["description"]?.string
        switch entry["type"]?.string {
        case "enum":
            guard let values = entry["values"]?.elements?.compactMap(\.string), !values.isEmpty else {
                throw problem(path.key("values"), "an enum option needs its values")
            }
            return Option(
                name: name, kind: .enumeration(values: values, default: entry["default"]?.string),
                description: description)
        case "bool":
            guard case .bool(let value) = entry["default"] else {
                throw problem(path.key("default"), "a bool option needs true or false as its default")
            }
            return Option(
                name: name, kind: .bool(default: value), description: description,
                namedInMatrixAtDefault: entry["nameInMatrixAtDefault"] != .bool(false))
        case "tokens":
            guard let group = entry["group"]?.string else {
                throw problem(path.key("group"), "an option of type tokens needs its token group")
            }
            return Option(
                name: name, kind: .tokenGroup(group, default: entry["default"]?.string), description: description)
        case "icons":
            let optional = entry["optional"] == .bool(true)
            return Option(name: name, kind: .icons(optional: optional), description: description)
        case "integer":
            guard let value = entry["default"]?.integer else {
                throw problem(path.key("default"), "an integer option needs a whole number as its default")
            }
            return Option(
                name: name, kind: .integer(default: value, minimum: entry["minimum"]?.integer),
                description: description)
        default:
            throw problem(path.key("type"), "must be enum, bool, tokens, icons or integer")
        }
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
