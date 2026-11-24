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
    ///   defaults, and `public var body: some View`: `public init(axis: RuleAxis = .horizontal)`. An option whose values
    ///   are the icon registry's names is the glyph the view draws: the first, unlabeled parameter, typed as the icon
    ///   generator's `Westron.Icon` (`AppleIcons.iconType`), with no default. Such a view may have the one slot `label`,
    ///   its spoken label: then it has three initializers, `init(_ icon: Westron.Icon)` (decorative; left out when
    ///   `accessibility.label` is `required`), `init(_ icon: Westron.Icon, label: LocalizedStringKey)`, and, for a label
    ///   that is not localized, `@_disfavoredOverload init<S: StringProtocol>(_ icon: Westron.Icon, label: S)`, as
    ///   `Label(_:icon:)` takes its title (`labelInitializers`). A view without such an option may have the one slot
    ///   `label` as drawn text: then it has `init(<options>)` (left out when the label is `required`),
    ///   `init(_ label: LocalizedStringKey, <options>)` and `@_disfavoredOverload init<S: StringProtocol>(_ label: S,
    ///   <options>)`, as `Text` and `Label` take their titles; the label's initializers leave out the options a
    ///   constraint on the slot fixes (`when: { slots: [label] }`, `ContractRules.slotsKey`), so Rule's take no axis
    ///   and no purpose (`textLabelInitializers`). A view with several slots takes each as a `@ViewBuilder` closure
    ///   named after it, of a generic type named after it in UpperCamelCase: the first slot is its content, which every
    ///   instance fills, and each other slot defaults to `{ EmptyView() }`, so an instance leaves it out (SE-0347).
    ///   Such a view has one initializer per form (`forms`), or one: the options, labeled, then, for a form a person
    ///   acts on (`ComponentContract.Form.activates`, or the contract's intents without forms), `action: @escaping ()
    ///   -> Void`, then the slots (`slotInitializer`): `ListRow(level: 1, action: open) { Text(title) } trailing: {
    ///   … }` and `ListRow { Text(title) }`. A variant on a view is not derived yet.
    ///
    /// An own view's states: it carries `hover`, `focus`, `pressed` and `disabled` itself (`systemStates`: the
    /// pointer, the keyboard's focus, the press of the system button inside it, `.disabled(_:)`); every other state gets
    /// the shared state modifier named after it, as a style's does (`modifierStates`). A restriction of an OS may name
    /// the states it enters; its options and fallbacks are not derived yet. The generated file adds `<Component>State`
    /// with `isEntered` per OS, and with forms `<Component>Form` with whether each takes an action and its states.
    ///
    /// A mark (`marks`) is a modifier on `View` named `<mark>Mark`: its first parameter, an enum, unlabeled and
    /// optional, nil drawing no mark, then the others labeled, with their defaults: `.insertionMark(_ edge:
    /// ListRowInsertionEdge?, level: Int = 0)`. Each enum parameter gets the enum `<Component><Mark><Parameter>`.
    ///
    /// The generator writes the enums of the enum options, `<Component><Option>`, into
    /// `WestronUI/Generated/<Component>+Contract.swift`, by the naming rules of a style. The modifier or the view is
    /// hand-written, since its body is the whole implementation; the API parity lint holds its signature to this.
    /// An option in `platforms.apple.systemOptions` is the system's own environment modifier, which a product writes
    /// on the component and the system views inside it read (Icon's `scale`, `.imageScale(_:)`): it is no parameter
    /// and gets no enum. An integer option is `<name>: Int = <default>`. Every other shape fails generation and the
    /// lint as not derived yet: an option whose values are tokens, icons on a modifier, an option named `size` (whose
    /// default comes from `controlSize` on a style), states or forms on a modifier, and restrictions of options by
    /// Apple or an Apple OS, since the generated file has no tables a hand-written body could read.
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
        /// One initializer of a view.
        public struct Initializer: Equatable, Sendable, CustomStringConvertible {
            public let parameters: [SwiftDeclarations.Parameter]
            /// What the declaration carries beyond the lint's harmless extras, as Swift's parser reads it: the
            /// attribute and the generic clause of the one that takes a label that is not localized.
            public let extras: [String]

            public init(parameters: [SwiftDeclarations.Parameter], extras: [String] = []) {
                self.parameters = parameters
                self.extras = extras
            }

            /// `init(axis: RuleAxis = .horizontal)`, `@_disfavoredOverload init<S: StringProtocol>(_: Westron.Icon,
            /// label: S)`.
            public var description: String { signature(access: "") }

            /// The declaration a product sees: `@_disfavoredOverload public init<S: StringProtocol>(…)`.
            public var declaration: String { signature(access: "public ") }

            private func signature(access: String) -> String {
                let attributes = extras.filter { $0.hasPrefix("@") }.map { $0 + " " }.joined()
                let generics = extras.filter { $0.hasPrefix("<") }.joined()
                return attributes + access + "init" + generics + "("
                    + parameters.map(\.description).joined(separator: ", ") + ")"
            }
        }

        /// The type of a localized label, as `Label(_:icon:)` takes its title.
        public static let labelType = "LocalizedStringKey"
        /// A label that is not localized: a generic `StringProtocol`, preferred less than the localized one, as
        /// `Label(_:icon:)` takes its title.
        public static let verbatimLabel = (type: "S", extras: ["@_disfavoredOverload", "<S: StringProtocol>"])

        /// The modifier's parameters, or a view's first initializer's, as the lint compares them.
        public let parameters: [SwiftDeclarations.Parameter]
        /// The states an own view carries itself, from the system: the pointer, the keyboard's focus, the press of the
        /// system button inside it, and `.disabled(_:)`.
        public static let systemStates: Set<String> = ["hover", "focus", "pressed", "disabled"]
        /// The contract's states, in its order.
        public let states: [String]
        /// The states the shared state modifiers set (`.selected(_:)`), in the contract's order.
        public var modifierStates: [String] { states.filter { !Self.systemStates.contains($0) } }
        /// By OS, the states it does not enter.
        public let skippedStates: [SkippedStates]
        /// The contract's forms.
        public let forms: [ComponentContract.Form]
        /// `ListRowState`.
        public var stateType: String { "\(component)State" }
        /// `ListRowForm`.
        public var formType: String { "\(component)Form" }

        /// The states one OS never enters.
        public struct SkippedStates: Equatable, Sendable {
            public let os: String
            public let states: [String]
        }

        /// One mark's modifier: `insertionMark`, its parameters and the enums of its enum parameters.
        public struct MarkModifier: Equatable, Sendable {
            /// The contract's mark, `insertion`.
            public let mark: String
            /// `insertionMark`.
            public let name: String
            public let parameters: [SwiftDeclarations.Parameter]
            public let enums: [Enum]
        }

        /// The modifiers of the contract's marks, in its order.
        public let marks: [MarkModifier]
        /// A view's initializers, in order; empty for a modifier.
        public let initializers: [Initializer]

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
            if form == .modifier, !contract.states.isEmpty {
                throw problem(.root.key("states"), "a modifier with states: \(notYet)")
            }
            if form == .modifier, !contract.forms.isEmpty {
                throw problem(.root.key("forms"), "a modifier with forms: \(notYet)")
            }
            let restrictions =
                [(applePath, apple.restriction)]
                + ComponentContract.appleOSes.compactMap { os in apple.targets[os].map { (applePath.key(os), $0) } }
            for (path, restriction) in restrictions where !restriction.options.isEmpty || !restriction.fallback.isEmpty
            {
                throw problem(path, "an \(AppleComponents.ownStrategy) whose options an OS restricts: \(notYet)")
            }
            let component = AppleComponents.typeName(contract.id)
            if !contract.states.isEmpty, SwiftUITypes.names.contains("\(component)State") {
                throw problem(.root.key("states"), "\(component)State would shadow SwiftUI's: rename the component")
            }
            states = contract.states
            forms = contract.forms
            var skipped: [SkippedStates] = []
            for os in ComponentContract.appleOSes {
                let entered = apple.targets[os]?.states ?? apple.restriction.states ?? contract.states
                let missing = contract.states.filter { !entered.contains($0) }
                if !missing.isEmpty { skipped.append(SkippedStates(os: os, states: missing)) }
            }
            skippedStates = skipped
            var enums: [Enum] = []
            var first: [SwiftDeclarations.Parameter] = []
            var rest: [SwiftDeclarations.Parameter] = []
            var glyph: String?
            for option in contract.options where apple.systemOptions[option.name] == nil {
                let path = DocumentPath.root.key("options").key(option.name)
                switch option.kind {
                case .tokenGroup:
                    throw problem(path, "an option whose values are tokens: \(notYet)")
                case .icons(optional: true):
                    throw problem(
                        path,
                        "an optional option whose values are icons: an own view's glyph is always named; \(notYet)")
                case .icons(optional: false):
                    guard form == .view else {
                        throw problem(path, "a modifier with an option whose values are icons: \(notYet)")
                    }
                    guard glyph == nil else {
                        throw problem(path, "a second option whose values are icons: \(notYet)")
                    }
                    glyph = option.name
                    first.append(.init(label: "_", type: AppleIcons.iconType))
                case .bool(let value):
                    rest.append(.init(label: option.name, type: "Bool", defaultValue: "\(value)"))
                case .integer(let value, _):
                    rest.append(.init(label: option.name, type: "Int", defaultValue: "\(value)"))
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
                if contract.slots.count == 1, contract.slots != ["label"] {
                    throw problem(
                        .root.key("slots"),
                        "a view whose one slot is not label, an icon's spoken label or a drawn text label: \(notYet)")
                }
                if contract.slots.count > 1, glyph != nil {
                    throw problem(.root.key("slots"), "a glyph's view with several slots: \(notYet)")
                }
                if contract.slots.count < 2, !contract.forms.isEmpty {
                    throw problem(.root.key("forms"), "a view with forms and fewer than two slots: \(notYet)")
                }
                if SwiftUITypes.names.contains(component) {
                    throw problem(
                        .root.key("id"),
                        "\(component) would shadow SwiftUI's \(component) in every file that imports SwiftUI "
                            + "(decisions/0003, point 3): rename the component")
                }
                name = component
            }
            var marks: [MarkModifier] = []
            for mark in contract.marks {
                let path = DocumentPath.root.key("marks").key(mark.name)
                var markEnums: [Enum] = []
                var markParameters: [SwiftDeclarations.Parameter] = []
                for (index, parameter) in mark.parameters.enumerated() {
                    let at = path.key("parameters").key(parameter.name)
                    switch parameter.kind {
                    case .enumeration(let values, let defaultValue):
                        let type =
                            component + Self.upper(mark.name) + Self.upper(parameter.name)
                        markEnums.append(
                            Enum(option: parameter.name, type: type, values: values, description: parameter.description)
                        )
                        markParameters.append(
                            index == 0
                                ? .init(label: "_", type: type + "?")
                                : .init(label: parameter.name, type: type, defaultValue: defaultValue.map { ".\($0)" }))
                    case .integer(let value, _) where index > 0:
                        markParameters.append(.init(label: parameter.name, type: "Int", defaultValue: "\(value)"))
                    case .bool(let value) where index > 0:
                        markParameters.append(.init(label: parameter.name, type: "Bool", defaultValue: "\(value)"))
                    default:
                        throw problem(
                            at,
                            index == 0
                                ? "a mark's first parameter is an enum, where it stands, nil drawing none: \(notYet)"
                                : "a mark's parameter of this type: \(notYet)")
                    }
                }
                guard !markParameters.isEmpty else { throw problem(path, "a mark with no parameters: \(notYet)") }
                marks.append(
                    MarkModifier(
                        mark: mark.name, name: mark.name + "Mark", parameters: markParameters, enums: markEnums))
            }
            self.marks = marks
            self.component = component
            self.form = form
            self.enums = enums
            parameters = first + rest
            if form == .view, contract.slots.count > 1 {
                let actions =
                    contract.forms.isEmpty ? [contract.intents.contains("activate")] : contract.forms.map(\.activates)
                initializers = actions.map {
                    Self.slotInitializer(options: first + rest, slots: contract.slots, action: $0)
                }
            } else if form == .view, glyph != nil, contract.slots == ["label"] {
                initializers = Self.labelInitializers(
                    first + rest, decorative: contract.accessibilityLabel != "required")
            } else if form == .view, contract.slots == ["label"] {
                // The options a constraint on the label fixes to one value are what a labelled instance takes, so
                // the label's initializers leave them out (Rule: a labelled rule is a horizontal separator).
                let fixed = Set(
                    contract.constraints.filter { $0.forbids && $0.slots == ["label"] }.flatMap(\.require.keys))
                initializers = Self.textLabelInitializers(
                    options: first + rest, labelled: (first + rest).filter { !fixed.contains($0.label) },
                    unlabelled: contract.accessibilityLabel != "required")
            } else {
                initializers = form == .view ? [Initializer(parameters: first + rest)] : []
            }
        }

        /// The type of a view's action: the closure a system `Button` takes.
        public static let actionType = "@escaping () -> Void"
        /// The default of a slot an instance may leave out.
        public static let emptySlot = "{ EmptyView() }"

        /// `Insertion` for `insertion`.
        static func upper(_ name: String) -> String { name.prefix(1).uppercased() + name.dropFirst() }

        /// The initializer of a view with several slots, for one form: the options, the action where a person acts
        /// on the form, then each slot as a closure of its own generic type, the first required and the others
        /// defaulting to an empty view.
        static func slotInitializer(options: [SwiftDeclarations.Parameter], slots: [String], action: Bool)
            -> Initializer
        {
            var parameters = options
            if action { parameters.append(.init(label: "action", type: actionType)) }
            for (index, slot) in slots.enumerated() {
                parameters.append(
                    .init(label: slot, type: "() -> \(upper(slot))", defaultValue: index == 0 ? nil : emptySlot))
            }
            let generics = "<" + slots.map { "\(upper($0)): View" }.joined(separator: ", ") + ">"
            return Initializer(parameters: parameters, extras: [generics])
        }

        /// The initializers of an icon's view with a spoken label: without one, decorative, unless the label is
        /// required; with a localized label; with one that is not localized.
        static func labelInitializers(_ parameters: [SwiftDeclarations.Parameter], decorative: Bool) -> [Initializer] {
            var result: [Initializer] = []
            if decorative { result.append(Initializer(parameters: parameters)) }
            result.append(Initializer(parameters: parameters + [.init(label: "label", type: labelType)]))
            result.append(
                Initializer(
                    parameters: parameters + [.init(label: "label", type: verbatimLabel.type)],
                    extras: verbatimLabel.extras))
            return result
        }

        /// The initializers of a view whose slot `label` is drawn text, as `Text` and `Label` take their titles: without
        /// a label, with every option, unless the label is required; with a localized label, first and unlabeled,
        /// then the options a labelled instance still chooses; and the same with a label that is not localized.
        static func textLabelInitializers(
            options: [SwiftDeclarations.Parameter], labelled: [SwiftDeclarations.Parameter], unlabelled: Bool
        ) -> [Initializer] {
            var result: [Initializer] = []
            if unlabelled { result.append(Initializer(parameters: options)) }
            result.append(Initializer(parameters: [.init(label: "_", type: labelType)] + labelled))
            result.append(
                Initializer(
                    parameters: [.init(label: "_", type: verbatimLabel.type)] + labelled,
                    extras: verbatimLabel.extras))
            return result
        }

        /// The vocabulary, `WestronContract/Generated/<Component>+Contract.swift`: the enums of the options and of the
        /// marks' parameters; nil when the contract has none.
        func vocabularyFile(source: String, contract: ComponentContract) -> GeneratedFile? {
            var vocabulary: [VocabularyEnum] = enums.map { item in
                VocabularyEnum(
                    paragraphs: ["\(component)'s option `\(item.option)`, from its contract."]
                        + (item.description.map { [$0] } ?? []),
                    type: item.type, values: item.values)
            }
            for mark in marks {
                for item in mark.enums {
                    vocabulary.append(
                        VocabularyEnum(
                            paragraphs: [
                                "The parameter `\(item.option)` of \(component)'s mark `\(mark.mark)`, from its "
                                    + "contract: `.\(mark.name)(…)`, hand-written in WestronUI/\(component)/."
                            ] + (item.description.map { [$0] } ?? []),
                            type: item.type, values: item.values))
                }
            }
            let missing = (contract.apple?.unavailable ?? []).compactMap { AppleComponents.osNames[$0] }
            return AppleComponents.vocabularyFile(
                component: component, source: source, enums: vocabulary,
                ofMarks: marks.contains { !$0.enums.isEmpty }, condition: contract.apple?.availabilityCondition,
                absence: "\(component) does not exist on \(missing.joined(separator: " and ")) (the contract's "
                    + "`platforms` block); its vocabulary is there only where the component is.")
        }

        /// The generated SwiftUI side, the states and the forms, or nil when the contract has neither: its enums are
        /// in `vocabularyFile`.
        func file(source: String) -> GeneratedFile? {
            guard !states.isEmpty || !forms.isEmpty else { return nil }
            let width = AppleTokensSwift.lineLength - 3
            let origin =
                "Generated from \(source) by `tools/westron generate`. Do not edit: change the contract and generate "
                + "again (spec/conventions.md)."
            var parts: [String] = []
            if !states.isEmpty { parts.append("its states") }
            if !forms.isEmpty { parts.append("its forms") }
            let list = parts.joined(separator: " and ")
            let hand =
                [form == .modifier ? "the modifier `\(name)`" : "the view `\(name)` and its initializers"]
                + marks.map { "the modifier `\($0.name)`" } + modifierStates.map { "the state modifier `\($0)`" }
            let handList = hand.count > 1 ? hand.dropLast().joined(separator: ", ") + " and " + hand.last! : hand[0]
            var purpose =
                "\(component)'s API from its contract: \(list). It is an own component, and \(handList) "
                + (hand.count > 1 ? "are" : "is") + " hand-written in WestronUI/; the API parity lint holds "
                + (hand.count > 1 ? "their signatures" : "its signature") + " to the contract (spec/conventions.md, "
                + "\"Own components\")."
            var vocabulary: [String] = []
            if !enums.isEmpty { vocabulary.append("its options") }
            if marks.contains(where: { !$0.enums.isEmpty }) { vocabulary.append("its marks' parameters") }
            if !vocabulary.isEmpty {
                purpose +=
                    " The enums of \(vocabulary.joined(separator: " and of ")) are in "
                    + "WestronContract/Generated/\(component)+Contract.swift (decisions/0017)."
            }
            var out =
                AppleTokensSwift.wrap(origin, width: width).map { "// " + $0 } + ["//"]
                + AppleTokensSwift.wrap(purpose, width: width).map { "// " + $0 }
            if !states.isEmpty { out += [""] + stateLines() }
            if !forms.isEmpty { out += [""] + formLines() }
            return GeneratedFile(
                path: "\(AppleComponents.outputDirectory)/\(component)+Contract.swift",
                contents: out.joined(separator: "\n") + "\n")
        }

        /// `<Component>State`: the contract's states and whether the current OS enters each.
        private func stateLines() -> [String] {
            let carried = states.filter(Self.systemStates.contains)
            var paragraphs = [
                "The states of a \(component) in its contract, in its order. "
                    + (carried.isEmpty ? "" : "The view carries \(carried.joined(separator: ", ")) itself; ")
                    + "the others are set through the environment (spec/conventions.md)."
            ]
            if !skippedStates.isEmpty {
                paragraphs.append(
                    "Not entered: "
                        + skippedStates.map {
                            "on \(AppleComponents.osNames[$0.os]!), \($0.states.joined(separator: ", "))"
                        }
                        .joined(separator: "; ") + " (the contract's `platforms` block).")
            }
            var out = AppleIcons.paragraphs(paragraphs, indent: 0)
            out.append("enum \(stateType): String, CaseIterable, Sendable {")
            out += states.map { "    case \(SwiftName.declared($0))" }
            out.append("")
            out += AppleIcons.paragraphs(["Whether the current OS ever enters the state."], indent: 1)
            out.append("    var isEntered: Bool {")
            if skippedStates.isEmpty {
                out.append("        true")
            } else {
                for (index, entry) in skippedStates.enumerated() {
                    out.append(
                        "        " + (index == 0 ? "#if " : "#elseif ") + AppleComponents.osConditions[entry.os]!)
                    out.append("            switch self {")
                    out += states.map {
                        "            case .\(SwiftName.declared($0)): return \(!entry.states.contains($0))"
                    }
                    out.append("            }")
                }
                out += ["        #else", "            return true", "        #endif"]
            }
            out += ["    }", "}"]
            return out
        }

        /// `<Component>Form`: `package`, so the catalog's generated matrix can name a cell's form, and never public.
        private func formLines() -> [String] {
            var out = AppleIcons.paragraphs(
                [
                    "The forms of a \(component) in its contract, in its order, each an initializer of the view "
                        + "(spec/conventions.md, \"Own components\"): "
                        + forms.map { "\($0.name), \($0.activates ? "with an action" : "without one")" }
                        .joined(separator: "; ") + "."
                ], indent: 0)
            out.append("package enum \(formType): String, CaseIterable, Sendable {")
            out += forms.map { "    case \(SwiftName.declared($0.name))" }
            out.append("")
            out += AppleIcons.paragraphs(
                ["Whether a person acts on the form: its initializer takes `action`."], indent: 1)
            out.append("    var takesAction: Bool {")
            out.append("        switch self {")
            out += forms.map { "        case .\($0.name): \($0.activates)" }
            out += ["        }", "    }"]
            if !states.isEmpty {
                out.append("")
                out += AppleIcons.paragraphs(["The states the form enters (the contract's `forms`)."], indent: 1)
                out.append("    var states: Set<\(stateType)> {")
                out.append("        switch self {")
                out += forms.map {
                    "        case .\($0.name): [\($0.states.map { "." + $0 }.joined(separator: ", "))]"
                }
                out += ["        }", "    }"]
            }
            out.append("}")
            return out
        }
    }

    /// The type names own components declare, each generated enum and a view's type, against each other and the
    /// names the styles declare (`collisions`): one name for two of them does not compile.
    static func ownCollisions(_ owns: [(api: Own, source: String)], apis: [API]) -> [ContractProblem] {
        var owners: [String: (source: String, what: String)] = [:]
        for api in apis {
            for item in api.enums { owners[item.type] = (api.source, "\(api.component)'s option \(item.option.name)") }
            for target in api.targets { owners[target.style] = (api.source, "\(api.component)'s hand-written style") }
            if !api.contract.states.isEmpty { owners[api.stateType] = (api.source, "\(api.component)'s states") }
            if !api.contract.forms.isEmpty { owners[api.formType] = (api.source, "\(api.component)'s forms") }
        }
        var problems: [ContractProblem] = []
        for (own, source) in owns {
            var names: [(name: String, path: DocumentPath, what: String)] = own.enums.map {
                ($0.type, .root.key("options").key($0.option), "\(own.component)'s option \($0.option)")
            }
            for mark in own.marks {
                names += mark.enums.map {
                    ($0.type, .root.key("marks").key(mark.mark), "\(own.component)'s mark \(mark.mark)")
                }
            }
            if !own.states.isEmpty { names.append((own.stateType, .root.key("states"), "\(own.component)'s states")) }
            if !own.forms.isEmpty { names.append((own.formType, .root.key("forms"), "\(own.component)'s forms")) }
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
