/// What the API generators read from a component contract: its options, its states and the Apple entry of its
/// `platforms` block, typed. Reading assumes a contract that passes the schema; what the generators need and do not
/// find throws a `ContractProblem` instead of producing code from a guess.
public struct ComponentContract: Equatable, Sendable {
    public struct Option: Equatable, Sendable {
        public enum Kind: Equatable, Sendable {
            /// The values in the contract's order; `default` is nil when every use must name a value.
            case enumeration(values: [String], default: String?)
            case bool(default: Bool)
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
        /// `style-on-system-control` or `own-component`.
        public let strategy: String
        /// The system control, such as `SwiftUI.Button`; nil for an own component.
        public let base: String?
        /// By option name, the system API that carries the option on Apple, such as `role: SwiftUI.ButtonRole`: no
        /// type is generated for it.
        public let systemOptions: [String: String]
        /// What all of Apple keeps.
        public let restriction: Restriction
        /// What each OS keeps of Apple's, by `ios`, `macos`, `watchos`.
        public let targets: [String: Restriction]

        public init(
            strategy: String, base: String?, systemOptions: [String: String] = [:],
            restriction: Restriction = Restriction(), targets: [String: Restriction] = [:]
        ) {
            self.strategy = strategy
            self.base = base
            self.systemOptions = systemOptions
            self.restriction = restriction
            self.targets = targets
        }
    }

    public static let appleOSes = ["ios", "macos", "watchos"]

    public let id: String
    public let status: String
    /// In the contract's order.
    public let options: [Option]
    /// In the contract's order.
    public let states: [String]
    /// nil when Apple is planned.
    public let apple: Apple?

    public init(id: String, status: String, options: [Option], states: [String], apple: Apple?) {
        self.id = id
        self.status = status
        self.options = options
        self.states = states
        self.apple = apple
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
            default:
                throw problem(path.key("type"), "must be enum or bool")
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
            apple = Apple(
                strategy: strategy, base: entry["base"]?.string, systemOptions: systemOptions,
                restriction: try Self.restriction(entry, at: applePath, source: source), targets: targets)
        } else {
            apple = nil
        }
        self.init(id: id, status: status, options: options, states: states, apple: apple)
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
