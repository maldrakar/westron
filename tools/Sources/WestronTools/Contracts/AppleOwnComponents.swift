import Foundation

extension AppleComponents {
    /// The Apple strategy of a component westron builds itself, where the platform has no control for it.
    public static let ownStrategy = "own-component"

    /// The API of an own component (`own-component`, spec/conventions.md, "Own components"), as the conventions derive
    /// it from the contract and its `platforms.apple.form`:
    ///
    /// - `modifier`: a modifier on `View` named after the component in lowerCamelCase, the variant first and
    ///   unlabeled, every other option labeled, a contract default as the argument's default, returning `some View`:
    ///   `public func surface(_ variant: SurfaceVariant, outlined: Bool = false) -> some View`. The view it modifies is
    ///   the content, so the contract has at most one slot.
    /// - `view`: a `public struct` named after the component in UpperCamelCase that conforms to `View`, with one
    ///   public initializer whose parameters are the options, labeled, in the contract's order, with the contract's
    ///   defaults, and `public var body: some View`: `public init(axis: RuleAxis = .horizontal)`. It has no slots and no
    ///   variant yet: the conventions do not derive their initializers yet.
    ///
    /// The generator writes the enums of the enum options, `<Component><Option>`, into
    /// `WestronUI/Generated/<Component>+Contract.swift`, by the naming rules of a style. The modifier or the view is
    /// hand-written, since its body is the whole implementation; the API parity lint holds its signature to this.
    /// Every other shape fails generation and the lint as not derived yet: an option whose values are tokens or icons,
    /// an option named `size` (whose default comes from `controlSize` on a style), states, system options and
    /// restrictions of Apple or an Apple OS, since the generated file has no tables a hand-written body could read.
    public struct Own: Equatable, Sendable {
        public enum Form: String, Equatable, Sendable {
            case modifier
            case view
        }

        public struct Enum: Equatable, Sendable {
            /// The contract's option, `variant`.
            public let option: String
            /// `SurfaceVariant`.
            public let type: String
            public let values: [String]
            public let description: String?
        }

        /// `Surface` for `surface`.
        public let component: String
        public let form: Form
        /// What a product calls: the modifier, `surface`, or the view type, `Rule`.
        public let name: String
        /// The enums of the enum options, in the contract's order.
        public let enums: [Enum]
        /// The modifier's or the initializer's parameters, as the lint compares them.
        public let parameters: [SwiftDeclarations.Parameter]

        /// `surface(_:outlined:)`, `Rule.init(axis:)`.
        public var signatureName: String {
            let labels = parameters.map { "\($0.label):" }.joined()
            return form == .modifier ? "\(name)(\(labels))" : "\(name).init(\(labels))"
        }

        /// - Throws: `ContractProblem` when the contract is not an own component with a form, or has a shape the
        ///   conventions do not derive an API from yet.
        public init(_ contract: ComponentContract, source: String) throws(ContractProblem) {
            func problem(_ path: DocumentPath, _ message: String) -> ContractProblem {
                ContractProblem(source: source, path: path, message)
            }
            let applePath = DocumentPath.root.key("platforms").key("apple")
            guard let apple = contract.apple, apple.strategy == AppleComponents.ownStrategy else {
                throw problem(applePath, "not an \(AppleComponents.ownStrategy)")
            }
            guard let formName = apple.form, let form = Form(rawValue: formName) else {
                throw problem(
                    applePath.key("form"), "an \(AppleComponents.ownStrategy) names its form: modifier or view")
            }
            let notYet = "the conventions do not derive an \(AppleComponents.ownStrategy)'s API for it yet"
            if !contract.states.isEmpty {
                throw problem(.root.key("states"), "an \(AppleComponents.ownStrategy) with states: \(notYet)")
            }
            if let name = apple.systemOptions.keys.sorted().first {
                throw problem(
                    applePath.key("systemOptions").key(name),
                    "an \(AppleComponents.ownStrategy) has no system control to carry an option")
            }
            let restrictions =
                [(applePath, apple.restriction)]
                + ComponentContract.appleOSes.compactMap { os in apple.targets[os].map { (applePath.key(os), $0) } }
            for (path, restriction) in restrictions
            where !restriction.options.isEmpty || !restriction.fallback.isEmpty || restriction.states != nil {
                throw problem(path, "an \(AppleComponents.ownStrategy) that an OS restricts: \(notYet)")
            }
            let component = AppleComponents.typeName(contract.id)
            var enums: [Enum] = []
            var first: [SwiftDeclarations.Parameter] = []
            var rest: [SwiftDeclarations.Parameter] = []
            for option in contract.options {
                let path = DocumentPath.root.key("options").key(option.name)
                switch option.kind {
                case .tokenGroup, .icons:
                    throw problem(path, "an option whose values are tokens or icons: \(notYet)")
                case .bool(let value):
                    rest.append(.init(label: option.name, type: "Bool", defaultValue: "\(value)"))
                case .enumeration(let values, let defaultValue):
                    if option.name == "size" {
                        throw problem(path, "a size option: \(notYet)")
                    }
                    if form == .view, option.name == "variant" {
                        throw problem(path, "a view with a variant: \(notYet)")
                    }
                    let type = component + option.name.prefix(1).uppercased() + option.name.dropFirst()
                    if SwiftUITypes.names.contains(type) {
                        throw problem(path, "\(type) would shadow SwiftUI's \(type): rename the option")
                    }
                    enums.append(Enum(option: option.name, type: type, values: values, description: option.description))
                    let defaultValue = defaultValue.map { ".\($0)" }
                    if option.name == "variant" {
                        first.append(.init(label: "_", type: type, defaultValue: defaultValue))
                    } else {
                        rest.append(.init(label: option.name, type: type, defaultValue: defaultValue))
                    }
                }
            }
            switch form {
            case .modifier:
                if contract.slots.count > 1 {
                    throw problem(
                        .root.key("slots"),
                        "a modifier's content is the view it modifies, so it has one slot at most: \(notYet)")
                }
                name = component.prefix(1).lowercased() + component.dropFirst()
            case .view:
                if !contract.slots.isEmpty {
                    throw problem(.root.key("slots"), "a view with slots: \(notYet)")
                }
                if SwiftUITypes.names.contains(component) {
                    throw problem(
                        .root.key("id"),
                        "\(component) would shadow SwiftUI's \(component) in every file that imports SwiftUI "
                            + "(decisions/0003, point 3): rename the component")
                }
                name = component
            }
            self.component = component
            self.form = form
            self.enums = enums
            parameters = first + rest
        }

        /// The generated file, the enums of the options, or nil when the contract has no enum option.
        func file(source: String) -> GeneratedFile? {
            guard !enums.isEmpty else { return nil }
            let width = AppleTokensSwift.lineLength - 3
            let origin =
                "Generated from \(source) by `tools/westron generate`. Do not edit: change the contract and generate "
                + "again (spec/conventions.md)."
            let entry =
                form == .modifier
                ? "the modifier `\(signatureName)` is" : "the view `\(name)` and its `\(signatureName)` are"
            let purpose =
                "\(component)'s API from its contract: the enums of its options. It is an own component, and "
                + "\(entry) hand-written in WestronUI/\(component)/; the API parity lint holds the signature to the "
                + "contract (spec/conventions.md, \"Own components\")."
            var out =
                AppleTokensSwift.wrap(origin, width: width).map { "// " + $0 } + ["//"]
                + AppleTokensSwift.wrap(purpose, width: width).map { "// " + $0 }
            for item in enums {
                out.append("")
                var paragraphs = ["\(component)'s option `\(item.option)`, from its contract."]
                if let description = item.description { paragraphs.append(description) }
                out += AppleIcons.paragraphs(paragraphs, indent: 0)
                out.append("public enum \(item.type): String, CaseIterable, Sendable {")
                out += item.values.map { "    case \(SwiftName.declared($0))" }
                out.append("}")
            }
            return GeneratedFile(
                path: "\(AppleComponents.outputDirectory)/\(component)+Contract.swift",
                contents: out.joined(separator: "\n") + "\n")
        }
    }

    /// The type names own components declare, each generated enum and a view's type, against each other and the
    /// names the styles declare (`collisions`): one name for two of them does not compile.
    static func ownCollisions(_ owns: [(api: Own, source: String)], apis: [API]) -> [ContractProblem] {
        var owners: [String: (source: String, what: String)] = [:]
        for api in apis {
            for item in api.enums { owners[item.type] = (api.source, "\(api.component)'s option \(item.option.name)") }
            owners[api.style] = (api.source, "\(api.component)'s hand-written style")
            if !api.contract.states.isEmpty { owners[api.stateType] = (api.source, "\(api.component)'s states") }
        }
        var problems: [ContractProblem] = []
        for (own, source) in owns {
            var names: [(name: String, path: DocumentPath, what: String)] = own.enums.map {
                ($0.type, .root.key("options").key($0.option), "\(own.component)'s option \($0.option)")
            }
            if own.form == .view { names.append((own.name, .root.key("id"), "\(own.component)'s view")) }
            for entry in names {
                if let owner = owners[entry.name] {
                    let place = owner.source == source ? "" : " in \(owner.source)"
                    problems.append(
                        ContractProblem(
                            source: source, path: entry.path,
                            "\(entry.name), for \(entry.what), is already the type of \(owner.what)\(place): two "
                                + "types of one name do not compile; rename the option or the component"))
                } else {
                    owners[entry.name] = (source, entry.what)
                }
            }
        }
        return problems
    }
}
