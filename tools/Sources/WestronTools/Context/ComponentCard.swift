import Foundation

/// One component's card in the agent context (`AgentContext`, decisions/0016): what a product agent needs to use the
/// component in SwiftUI, from its contract. The API is the one the API parity lint holds WestronUI to
/// (`APIParity.expected`, from spec/conventions.md through `AppleComponents`), so a card cannot name a call WestronUI
/// does not declare. The contract's token bindings, its snapshot matrix and its other platforms are left out: they are
/// how westron draws the component, not how a product uses it.
struct ComponentCard {
    let contract: ComponentContract
    /// The contract as a document, for the prose the typed contract does not keep.
    let document: JSON
    /// The contract's repository path.
    let source: String
    /// The API every contract gives, of which the card takes this one's.
    let expected: APIParity.Expected
    /// A name of the icon registry, for examples of a glyph.
    let exampleIcon: String
    /// A text role's member, `body.regular`, for examples of a role.
    let exampleTextRole: String
    /// A list color's case, `amber`, for examples of `Westron.Category`; empty where the tokens have none.
    var exampleCategory = ""
    /// The other components that draw a slot of theirs in a text role their contract binds there, each with those
    /// slots in the contract's order: the text a product puts there takes that role with no call.
    var textRoleSlots: [(component: String, slots: [String])] = []

    /// `ListRow` for `list-row`.
    var component: String { AppleComponents.typeName(contract.id) }

    /// The card's path inside the bundle.
    static func path(_ id: String) -> String { "components/\(id).md" }

    /// What the component is, the first sentence of its description.
    var summary: String { ContextMarkdown.firstSentence(document["description"]?.string ?? "").first }

    // MARK: - The API

    private func ownsAPI(_ contracts: [APIParity.Contract]) -> Bool {
        contracts.contains { $0.contract.id == contract.id }
    }

    var functions: [APIParity.ExpectedFunction] { expected.functions.filter { ownsAPI($0.contracts) } }
    var enums: [APIParity.ExpectedEnum] { expected.enums.filter { $0.contract.contract.id == contract.id } }
    var views: [APIParity.ExpectedView] { expected.views.filter { $0.contract.contract.id == contract.id } }
    var hiddenLabels: [APIParity.ExpectedHiddenLabel] {
        expected.hiddenLabels.filter { $0.contract.contract.id == contract.id }
    }
    var problems: [APIParity.Problem] { expected.problems.filter { $0.file == source } }

    /// The shared modifier of a state the system does not carry, `.selected(_:)`, when the contract has one.
    func stateModifier(_ state: String) -> APIParity.ExpectedFunction? {
        functions.first {
            $0.name == state && $0.extends == "View" && $0.parameters == [.init(label: "_", type: "Bool")]
        }
    }

    /// The style modifier's overload for a base control, `.buttonStyle(_:size:…)`.
    func styleOverload(_ modifier: String) -> APIParity.ExpectedFunction? {
        functions.first { $0.name == modifier && $0.extends == "View" && stateModifier($0.name) == nil }
    }

    /// The base controls a style goes on, each with its form, control and modifier.
    var targets: [(form: String?, control: String, modifier: String)] {
        guard let apple = contract.apple, apple.strategy == AppleComponents.strategy else { return [] }
        return apple.styledBases.compactMap { entry in
            guard let modifier = SystemStyles.byBase[entry.base]?.modifier else { return nil }
            return (entry.form, String(entry.base.split(separator: ".").last ?? ""), modifier)
        }
    }

    /// One line of Swift per parameter list, or one parameter per line where the line would run past the width.
    static func signature(
        _ opening: String, _ parameters: [String], _ closing: String, indent: String
    ) -> [String] {
        let line = indent + opening + parameters.joined(separator: ", ") + closing
        guard line.count > ContextMarkdown.width, !parameters.isEmpty else { return [line] }
        return [indent + opening]
            + parameters.enumerated().map { index, parameter in
                indent + "    " + parameter + (index == parameters.count - 1 ? "" : ",")
            } + [indent + closing.drop { $0 == " " }]
    }

    /// Whether a parameter is a slot's closure, as a view with several slots takes them.
    func isSlotClosure(_ parameter: SwiftDeclarations.Parameter) -> Bool {
        contract.slots.contains(parameter.label) && parameter.type.hasPrefix("() -> ")
    }

    /// A parameter as a declaration writes it: `level: Int = 0`, `_: ButtonVariant`; a slot's closure is a view
    /// builder, as spec/conventions.md gives it.
    func parameter(_ parameter: SwiftDeclarations.Parameter) -> String {
        (isSlotClosure(parameter) ? "@ViewBuilder " : "") + parameter.description
    }

    /// The public declarations, as a Swift interface.
    func declarations() -> [String] {
        var out: [String] = []
        var byExtension: [(extends: String, lines: [String])] = []
        for function in functions {
            // A twin on the base carries the attribute the lint allows it, `@_disfavoredOverload`, as declared.
            let attributes = function.allowedExtras.sorted().map { $0 + " " }.joined()
            let lines = Self.signature(
                attributes + "public func \(function.name)(", function.parameters.map(parameter),
                ") -> \(function.result)", indent: "    ")
            if let index = byExtension.firstIndex(where: { $0.extends == function.extends }) {
                byExtension[index].lines += lines
            } else {
                byExtension.append((function.extends, lines))
            }
        }
        for view in views {
            out.append("public struct \(view.type): View {")
            for initializer in view.initializers {
                let attributes = initializer.extras.filter { $0.hasPrefix("@") }.map { $0 + " " }.joined()
                let generics = initializer.extras.filter { $0.hasPrefix("<") }.joined()
                out += Self.signature(
                    attributes + "public init\(generics)(", initializer.parameters.map(parameter), ")",
                    indent: "    ")
            }
            out += ["    public var body: some View", "}"]
        }
        for label in hiddenLabels {
            out.append("extension \(label.api.control) \(label.api.requirement) {")
            for initializer in label.api.initializers {
                let attributes = initializer.extras.filter { $0.hasPrefix("@") }.map { $0 + " " }.joined()
                let generics = initializer.extras.filter { $0.hasPrefix("<") }.joined()
                out += Self.signature(
                    attributes + "public init\(generics)(", initializer.parameters.map(\.description), ")",
                    indent: "    ")
            }
            out.append("}")
        }
        for entry in byExtension {
            out += ["extension \(entry.extends) {"] + entry.lines + ["}"]
        }
        return out
    }

    /// The enums of its options and marks, as WestronContract declares them (decisions/0017).
    func vocabularyDeclarations() -> [String] {
        enums.map { item in
            let cases = item.values.map(SwiftName.declared).joined(separator: ", ")
            return "public enum \(item.type): String, CaseIterable, Sendable { case \(cases) }"
        }
    }

    /// A placeholder argument of a type, for an example call: the first value of a westron enum, a name of the icon
    /// registry, a string, a closure.
    func example(_ parameter: SwiftDeclarations.Parameter) -> String {
        if let item = enums.first(where: { $0.type == parameter.type || $0.type + "?" == parameter.type }) {
            return "." + SwiftName.declared(item.values[0])
        }
        switch parameter.type {
        case AppleIcons.iconType, AppleIcons.iconType + "?": return "." + exampleIcon
        case AppleComponents.Own.labelType, AppleComponents.Own.verbatimLabel.type: return "\"…\""
        case AppleComponents.Own.actionType: return "{ … }"
        case "Binding<Bool>": return "$isOn"
        case AppleTokenModel.textRoleType: return "." + exampleTextRole
        case AppleComponents.contextValues["category"]?.type ?? "" where !exampleCategory.isEmpty:
            return "." + exampleCategory
        case "Bool": return "true"
        default: return "…"
        }
    }

    /// The arguments a call must write: the parameters without a default, `label: value`, or the value alone.
    func requiredArguments(_ parameters: [SwiftDeclarations.Parameter]) -> [String] {
        parameters.filter { $0.defaultValue == nil }.map { parameter in
            (parameter.label == "_" ? "" : parameter.label + ": ") + example(parameter)
        }
    }

    /// Example calls, the shortest each declaration allows, each as its lines.
    func examples() -> [[String]] {
        var out: [[String]] = []
        for target in targets {
            guard let overload = styleOverload(target.modifier) else { continue }
            let style = "    .\(target.modifier)(\(requiredArguments(overload.parameters).joined(separator: ", ")))"
            out.append(["\(target.control)(…)", style])
            // A control with no drawn label, beside its own title (`accessibility.hiddenLabel`).
            for label in hiddenLabels where target.form == nil && label.api.control == target.control {
                let arguments = requiredArguments(label.api.initializers[0].parameters)
                out.append(["\(target.control)(\(arguments.joined(separator: ", ")))", style])
            }
        }
        if let apple = contract.apple, apple.strategy == SystemStyles.extensionStrategy,
            let control = apple.base?.split(separator: ".").last
        {
            for function in functions
            where function.extends == "View" && stateModifier(function.name) == nil
                && !readModifiers.contains(where: { $0.name == function.name })
            {
                let arguments = function.parameters.map { $0.defaultValue ?? example($0) }
                out.append(["\(control)(\"…\")", "    .\(function.name)(\(arguments.joined(separator: ", ")))"])
            }
        }
        if let apple = contract.apple, apple.strategy == AppleComponents.ownStrategy, apple.form == "modifier" {
            for function in functions where function.name == ownName {
                out.append([
                    "content",
                    "    .\(function.name)(\(requiredArguments(function.parameters).joined(separator: ", ")))",
                ])
            }
        }
        for view in views {
            for initializer in view.initializers where !initializer.extras.contains("@_disfavoredOverload") {
                let slots = initializer.parameters.filter { isSlotClosure($0) }
                let rest = initializer.parameters.filter { !isSlotClosure($0) }
                var call = view.type
                let arguments = requiredArguments(rest)
                if !arguments.isEmpty || slots.isEmpty { call += "(" + arguments.joined(separator: ", ") + ")" }
                // The first slot is the trailing closure; a slot with a default is left out, then shown in the full
                // form, each as a labeled trailing closure in the initializer's order.
                if let first = slots.first(where: { $0.defaultValue == nil }) {
                    call += " { … }"
                    out.append([call])
                    let others = slots.filter { $0.label != first.label }
                    if !others.isEmpty {
                        out.append([call + others.map { " \($0.label): { … }" }.joined()])
                    }
                } else {
                    out.append([call])
                }
            }
        }
        // The context it reads, on the first call: `IconTile(.tray).category(.amber)`.
        if let call = out.first {
            for modifier in readModifiers {
                out.append(call + ["    .\(modifier.name)(\(requiredArguments(modifier.parameters).joined()))"])
            }
        }
        for mark in markModifiers {
            out.append(["….\(mark.name)(\(requiredArguments(mark.parameters).joined(separator: ", ")))"])
        }
        for modifier in contextModifiers {
            out.append(["….\(modifier.name)(\(requiredArguments(modifier.parameters).joined(separator: ", ")))"])
        }
        for state in contract.states where stateModifier(state) != nil {
            out.append(["….\(state)(is\(state.prefix(1).uppercased() + state.dropFirst()))"])
        }
        return out
    }

    /// The first example call on one line: `Text("…").textRole(…)`.
    var shortestCall: String? {
        examples().first.map { $0.map { $0.trimmingCharacters(in: .whitespaces) }.joined() }
    }

    /// An own component's modifier or view name.
    var ownName: String? {
        guard let apple = contract.apple, apple.strategy == AppleComponents.ownStrategy else { return nil }
        return try? AppleComponents.Own(contract, source: source).name
    }

    /// The modifiers of the context the contract sets, `.disclosureAlignsLeaves(_:)`, as the API declares them.
    var contextModifiers: [APIParity.ExpectedFunction] {
        contract.context.compactMap { setting in
            functions.first { $0.name == AppleComponents.contextModifier(setting, of: contract.id) }
        }
    }

    /// The shared modifiers of the context values the contract reads, `.category(_:)`, as the API declares them.
    var readModifiers: [APIParity.ExpectedFunction] {
        contract.reads.compactMap { value in
            functions.first { $0.name == value && $0.extends == "View" && stateModifier($0.name) == nil }
        }
    }

    /// The modifiers of the contract's marks, `.insertionMark(_:level:)`.
    var markModifiers: [(name: String, parameters: [SwiftDeclarations.Parameter])] {
        contract.marks.compactMap { mark in
            functions.first { $0.name == mark.name + "Mark" }.map { ($0.name, $0.parameters) }
        }
    }

    // MARK: - The card

    /// The details file's path inside the bundle.
    static func detailsPath(_ id: String) -> String { "components/\(id).details.md" }

    /// The card: what a product agent needs to write a call. How the component behaves and is built is in the
    /// details file (`details()`), which the card points to last.
    func markdown() -> String {
        var out = ContextMarkdown.header([source])
        out += ["", "# \(component)", ""]
        var meta = ["`\(contract.id)`", contract.status, strategySummary]
        if let consumers = document["consumers"]?.elements?.compactMap(\.string), !consumers.isEmpty {
            meta.append("used by " + consumers.joined(separator: ", "))
        }
        out += ContextMarkdown.wrap(meta.joined(separator: " · "))
        out += [""] + ContextMarkdown.wrap(usable(summary))
        out += callSection()
        out += optionsSection()
        out += slotsSection()
        out += statesSection()
        out += formsSection()
        out += marksSection()
        out += contextSection()
        out += accessibilitySection()
        out += constraintsSection()
        if hasDetails {
            out +=
                [""]
                + ContextMarkdown.wrap(
                    "More: `\(Self.fileName(Self.detailsPath(contract.id)))` holds "
                        + detailsContents.joined(separator: "; ") + ". Read it when this card does not settle a case. "
                        + "A reference such as \"decisions/0001\" or \"#120\" points into westron's repository, not "
                        + "into this bundle.")
        }
        return out.joined(separator: "\n") + "\n"
    }

    static func fileName(_ path: String) -> String { String(path.split(separator: "/").last ?? "") }

    /// What the details file holds, for the card's last line.
    private var detailsContents: [String] {
        var parts: [String] = []
        if !accessibilityProse.isEmpty { parts.append("how assistive technology reads it") }
        if !behaviorProse.isEmpty { parts.append("how it behaves, sizes and draws") }
        if document["platforms"]?["apple"] != nil { parts.append("how WestronUI builds it on Apple and each OS") }
        return parts
    }

    var hasDetails: Bool { !detailsContents.isEmpty }

    /// The details: the contract's prose on behavior, accessibility and Apple, as it stands, for the cases the card
    /// does not settle. Nil when the contract has none.
    func details() -> String? {
        guard hasDetails else { return nil }
        var out = ContextMarkdown.header([source])
        out += ["", "# \(component): details", ""]
        out += ContextMarkdown.wrap(
            "The prose of westron's contract for `\(contract.id)`, for the cases its card "
                + "(`\(Self.fileName(Self.path(contract.id)))`) does not settle. A reference such as "
                + "\"decisions/0001\" or \"#120\" here points into westron's repository: to the component's own "
                + "decisions, westron's decisions or an issue, none of which is in this bundle. Names such as "
                + "`container.gap` are the contract's bindings of westron's tokens, how WestronUI draws the component; "
                + "a product never sets them.")
        if !accessibilityProse.isEmpty {
            out += ["", "## Accessibility", ""]
            out += Array(accessibilityProse.map { ContextMarkdown.wrap($0) }.joined(separator: [""]))
        }
        if !behaviorProse.isEmpty {
            out += ["", "## Behavior", ""] + ContextMarkdown.wrap(behaviorProse)
        }
        out += appleSection()
        return out.joined(separator: "\n") + "\n"
    }

    // MARK: - Prose

    /// The names of the contract's token bindings, `container.indent`: how westron draws the component.
    var bindings: [String] { document["tokens"]?.members?.map(\.key) ?? [] }

    func external(_ text: String) -> String { ContextMarkdown.withoutTooling(text) }

    /// The prose a card keeps: without the sentences on westron's tooling, and without a token binding's name, which
    /// says how westron draws the component (the details file keeps it). The fact a sentence states stays: the phrase
    /// that names the binding goes, "indented by container.indent for each level" reads "indented for each level", and
    /// so does a clause after "; " that still names one; a sentence goes only when nothing is left of it.
    func usable(_ text: String) -> String {
        ContextMarkdown.sentences(external(text)).compactMap { sentence in
            var kept = sentence
            for binding in bindings {
                kept = ContextMarkdown.removingPhrases(naming: binding, in: kept)
            }
            return ContextMarkdown.withoutClauses(kept) { clause in
                bindings.contains { ContextMarkdown.names(clause, $0) }
            }
        }.joined(separator: " ")
    }

    /// The long accessibility prose: the contract's, then each form's.
    private var accessibilityProse: [String] {
        var out: [String] = []
        if let description = document["accessibility"]?["description"]?.string { out.append(external(description)) }
        for form in document["forms"]?.members ?? [] {
            if let description = form.value["accessibility"]?["description"]?.string {
                out.append("The form `\(form.key)`: " + external(description))
            }
        }
        return out.filter { !$0.isEmpty }
    }

    /// The description after its first sentence.
    private var behaviorProse: String {
        external(ContextMarkdown.firstSentence(document["description"]?.string ?? "").rest)
    }

    /// `own view on Apple`, `style on SwiftUI's Button`.
    var strategySummary: String {
        guard let apple = contract.apple else { return "not on Apple yet" }
        switch apple.strategy {
        case AppleComponents.strategy:
            let controls = apple.styledBases.map { "`\($0.base)`" }
            return "a style on \(ContextMarkdown.list(controls, conjunction: "or"))"
        case SystemStyles.extensionStrategy:
            return "an extension of `\(apple.base ?? "")`"
        case AppleComponents.ownStrategy:
            return apple.form == "modifier" ? "westron's own modifier" : "westron's own view"
        default:
            return apple.strategy
        }
    }

    private func callSection() -> [String] {
        var out = ["", "## In SwiftUI", ""]
        guard AppleComponents.givesAPI(contract) else {
            return out
                + ContextMarkdown.wrap(
                    contract.status == "draft"
                        ? "Its contract is a draft: WestronUI has no API for it yet. Do not use it or imitate it."
                        : "WestronUI has no API for it on Apple yet.")
        }
        if !problems.isEmpty {
            return out
                + ContextMarkdown.wrap(
                    "Its API cannot be derived from its contract: "
                        + problems.map(\.message).joined(separator: "; "))
        }
        let examples = examples()
        if !examples.isEmpty {
            out +=
                ["`import WestronUI`. A call writes at least:", "", "```swift"] + examples.flatMap { $0 } + ["```", ""]
        }
        let declarations = declarations()
        if !declarations.isEmpty {
            out += ["What WestronUI declares for it:", "", "```swift"] + declarations + ["```"]
        }
        let vocabulary = vocabularyDeclarations()
        if !vocabulary.isEmpty {
            out +=
                (declarations.isEmpty ? [] : [""])
                + ContextMarkdown.wrap(
                    "Its enums are in `WestronContract`, which `WestronUI` re-exports, so a view needs no other import. "
                        + "A product's shared code, which cannot import SwiftUI, imports `WestronContract` instead, and "
                        + "its models keep these values, never a size, a color or a font:")
                + ["", "```swift"] + vocabulary + ["```"]
        }
        for modifier in readModifiers {
            let entry = document["reads"]?[modifier.name]
            var text =
                "It reads `\(modifier.name)` from its context: `.\(modifier.name)(_:)` on the component itself, or "
                + "once on any view around it, such as a row or a list, sets it for every westron component below "
                + "that reads it, and the closest setting wins."
            if let description = entry?["description"]?.string { text += " " + usable(description) }
            if let unset = entry?["unset"]?.string { text += " Without it, " + usable(unset) }
            out += [""] + ContextMarkdown.wrap(text)
        }
        if let apple = contract.apple, !apple.unavailable.isEmpty, let condition = apple.availabilityCondition {
            let names = apple.unavailable.compactMap { AppleComponents.osNames[$0] }
            out +=
                [""]
                + ContextMarkdown.wrap(
                    "Not on \(ContextMarkdown.list(names)): SwiftUI has no base control there, so WestronUI declares all of "
                        + "it, and `WestronContract` its enums, under `#if \(condition)`; a product's call, and a model "
                        + "that names its enums, stand under the same condition.")
        }
        if let apple = contract.apple {
            for (option, api) in apple.systemOptions.sorted(by: { $0.key < $1.key }) {
                out +=
                    [""]
                    + ContextMarkdown.wrap(
                        "The option `\(option)` is the system's own `\(api)`: the product sets it where SwiftUI takes "
                            + "it, and westron reads it from there. westron adds no argument for it.")
            }
        }
        return out
    }

    /// The Swift type an option takes, or what stands for it.
    private func swiftType(_ option: ComponentContract.Option) -> String? {
        if let api = contract.apple?.systemOptions[option.name] { return "the system's `\(api)`" }
        let parameters =
            functions.filter { stateModifier($0.name) == nil }.flatMap(\.parameters)
            + views.flatMap { $0.initializers.flatMap(\.parameters) }
        if let match = parameters.first(where: { $0.label == option.name }) { return "`\(match.type)`" }
        switch option.kind {
        case .enumeration:
            let type = component + option.name.prefix(1).uppercased() + option.name.dropFirst()
            if parameters.contains(where: { $0.label == "_" && $0.type == type }) { return "`\(type)`" }
        case .icons:
            if parameters.contains(where: { $0.label == "_" && $0.type == AppleIcons.iconType }) {
                return "`\(AppleIcons.iconType)`"
            }
        case .tokenGroup(let group, _):
            if let accessor = AppleComponents.tokenAccessors[group] { return "`\(accessor)`" }
        default: break
        }
        return nil
    }

    private func optionsSection() -> [String] {
        guard !contract.options.isEmpty else { return [] }
        var out = ["", "## Options", ""]
        for option in contract.options {
            var parts: [String] = ["`\(option.name)`"]
            if let type = swiftType(option) { parts.append(type) }
            var text = parts.joined(separator: ", ") + ": "
            switch option.kind {
            case .enumeration(let values, let defaultValue):
                if contract.apple?.systemOptions[option.name] != nil {
                    text += "the values " + values.map { "`\($0)`" }.joined(separator: ", ") + "; "
                    text += defaultValue.map { "by default `\($0)`." } ?? "no default."
                } else {
                    text += values.map { ContextMarkdown.code("." + SwiftName.declared($0)) }.joined(separator: ", ")
                    text += "; "
                    if option.name == "size", contract.apple?.strategy == AppleComponents.strategy {
                        text += "left out, the size comes from `controlSize` (`regular` is `.\(defaultValue ?? "")`)."
                    } else {
                        text +=
                            defaultValue.map { "by default \(ContextMarkdown.code("." + SwiftName.declared($0)))." }
                            ?? "no default."
                    }
                }
            case .bool(let value):
                text += "by default `\(value)`."
            case .integer(let value, let minimum):
                text += "a whole number" + (minimum.map { ", at least \($0)" } ?? "") + "; by default `\(value)`."
            case .tokenGroup(let group, let defaultValue):
                text +=
                    "a token of `\(group)` (`../tokens/\(group == AppleTokenModel.textRoleGroup ? "typography" : group).md`); "
                if let defaultValue, let member = try? AppleComponents.member(defaultValue, of: group) {
                    text += "by default `.\(member)`."
                } else {
                    text += "no default."
                }
            case .icons(let optional):
                text +=
                    "a name of the icon registry (`../icons.md`); "
                    + (optional ? "by default `nil`, no glyph." : "every use names one.")
            }
            if let description = option.description { text += " " + usable(description) }
            text += textRoleSlotsNote(option)
            text += restrictions(option)
            out += ContextMarkdown.item(text)
        }
        return out
    }

    /// For the option of text roles on a system view, the slots other components draw in a role their contracts bind
    /// there: a text a product puts in one takes that role with no call of its own, so "every use" is every call.
    private func textRoleSlotsNote(_ option: ComponentContract.Option) -> String {
        guard case .tokenGroup(let group, _) = option.kind, group == AppleTokenModel.textRoleGroup,
            contract.apple?.strategy == SystemStyles.extensionStrategy, !textRoleSlots.isEmpty,
            let modifier = functions.first(where: { $0.extends == "View" && stateModifier($0.name) == nil })?.name
        else { return "" }
        let slots = textRoleSlots.map { entry in
            "the " + ContextMarkdown.list(entry.slots.map { "`\($0)`" }) + " of `\(entry.component)`"
        }
        return " What a product puts in a slot that a westron component draws in a role of its own, a text or an "
            + "icon, takes that role with no `.\(modifier)(_:)`: " + ContextMarkdown.list(slots)
            + "; a call sets another role there only where that component's card allows it."
    }

    /// What each Apple OS draws for the values it does not offer, from the contract's `platforms` block.
    private func restrictions(_ option: ComponentContract.Option) -> String {
        guard let apple = contract.apple, case .enumeration(let values, _) = option.kind else { return "" }
        var parts: [String] = []
        for os in apple.availableOSes {
            let drawn = values.compactMap { value -> String? in
                guard
                    let target = try? AppleComponents.API.drawn(
                        value, of: option.name, values: values, apple: apple, os: os, at: .root, source: source),
                    target != value
                else { return nil }
                return "`\(value)` as `\(target)`"
            }
            if !drawn.isEmpty {
                parts.append("on \(AppleComponents.osNames[os]!) it draws \(ContextMarkdown.list(drawn))")
            }
        }
        return parts.isEmpty ? "" : " Where an OS lacks a value: " + parts.joined(separator: "; ") + "."
    }

    /// For a view whose slots are closures its contract binds to text roles: the role is their content's with no call,
    /// as a role a view sets in SwiftUI's environment is, and content that sets its own keeps it (ListRow: a count in
    /// its trailing slot). The text card's list of such slots defers to this sentence.
    private var closureTextRoles: String {
        guard let slots = AgentContext.textRoleSlots(contract, document),
            let modifier = expected.functions.first(where: {
                $0.extends == "View" && $0.parameters.first?.type == AppleTokenModel.textRoleType
            })?.name
        else { return "" }
        let which = slots == contract.slots ? "them" : ContextMarkdown.list(slots.map { "`\($0)`" })
        return " What a product puts in \(which) takes the text role the component draws there, with no "
            + "`.\(modifier)(_:)`; content that sets another role with `.\(modifier)(_:)` keeps it there."
    }

    private func slotsSection() -> [String] {
        guard !contract.slots.isEmpty, let apple = contract.apple else { return [] }
        let slots = ContextMarkdown.list(contract.slots.map { "`\($0)`" })
        let text: String
        switch apple.strategy {
        case AppleComponents.strategy:
            text =
                "\(slots): through the system control's own initializer and label, never a westron parameter. "
                + (contract.slots.contains("icon") && Set(contract.slots).isSubset(of: ["label", "icon"])
                    ? "`label` and `icon` are the title and the icon of a `Label` in it: "
                        + "`Label(\"…\", icon: .\(exampleIcon))` (`../icons.md`)."
                    : "")
        case SystemStyles.extensionStrategy:
            text = "\(slots): the `\(apple.base?.split(separator: ".").last ?? "")` itself."
        case AppleComponents.ownStrategy where apple.form == "modifier":
            text = "\(slots): the view the modifier is applied to."
        default:
            if contract.slots.count > 1 {
                text =
                    "\(slots): each a `@ViewBuilder` closure named after it; `\(contract.slots[0])` is the content "
                    + "every instance has, the others default to nothing." + closureTextRoles
            } else if views.contains(where: {
                $0.initializers.contains { $0.parameters.first?.type == AppleIcons.iconType }
            }) {
                text =
                    "\(slots): the glyph's spoken name, the initializer's `label:`; an instance without one is "
                    + "decorative and hidden from assistive technology."
            } else {
                text = "\(slots): drawn text, the initializer's first, unlabeled argument."
            }
        }
        return ["", "## Slots", ""] + ContextMarkdown.wrap(text)
    }

    /// How a product puts the component into a state.
    private func stateHow(_ state: String) -> String {
        if stateModifier(state) != nil {
            return "`.\(state)(_:)`, westron's modifier, on the component: the product passes its own state"
        }
        switch state {
        case "disabled": return "`.disabled(_:)`, the system's"
        case "pressed": return "the system's, while a press is held"
        case "hover": return "the system's, under a pointer: a Mac, an iPad with a pointer; touch never enters it"
        case "focus": return "the system's keyboard focus"
        case "checked": return "the toggle's value, `isOn`"
        case "expanded": return "the group's `isExpanded`"
        default: return "the system control's own"
        }
    }

    private func statesSection() -> [String] {
        guard !contract.states.isEmpty, let apple = contract.apple else { return [] }
        var out = ["", "## States", ""]
        for state in contract.states {
            let missing = apple.availableOSes.filter { os in
                !(apple.targets[os]?.states ?? apple.restriction.states ?? contract.states).contains(state)
            }
            var text = "`\(state)`: \(stateHow(state))."
            if !missing.isEmpty {
                text += " Never entered on " + ContextMarkdown.list(missing.map { AppleComponents.osNames[$0]! }) + "."
            }
            out += ContextMarkdown.item(text)
        }
        return out
    }

    private func formsSection() -> [String] {
        guard let forms = document["forms"]?.members, !forms.isEmpty else { return [] }
        var out = ["", "## Forms", ""]
        out += ContextMarkdown.wrap("The same look in several forms; the product picks one by what it writes.")
        out.append("")
        for form in forms {
            var text = "`\(form.key)`"
            if let target = targets.first(where: { $0.form == form.key }) {
                text += ": `\(target.control)` with `.\(target.modifier)(…)`."
            } else if let typed = contract.forms.first(where: { $0.name == form.key }), !views.isEmpty {
                text += typed.activates ? ": the initializer with `action:`." : ": the initializer without `action:`."
            } else {
                text += "."
            }
            if let description = form.value["description"]?.string { text += " " + usable(description) }
            if let states = contract.forms.first(where: { $0.name == form.key })?.states {
                text +=
                    " States: " + (states.isEmpty ? "none." : states.map { "`\($0)`" }.joined(separator: ", ") + ".")
            }
            out += ContextMarkdown.item(text)
        }
        return out
    }

    private func marksSection() -> [String] {
        guard let marks = document["marks"]?.members, !marks.isEmpty else { return [] }
        var out = ["", "## Marks", ""]
        for mark in marks {
            var text = "`\(mark.key)`"
            if let modifier = markModifiers.first(where: { $0.name == mark.key + "Mark" }) {
                text += ", `.\(modifier.name)(\(modifier.parameters.map(\.description).joined(separator: ", ")))`"
            }
            text += ":"
            if let description = mark.value["description"]?.string { text += " " + usable(description) }
            for parameter in mark.value["parameters"]?.members ?? [] {
                if let description = parameter.value["description"]?.string {
                    text += " `\(parameter.key)`: \(usable(description))"
                }
            }
            out += ContextMarkdown.item(text)
        }
        return out
    }

    private func contextSection() -> [String] {
        guard let settings = document["context"]?.members, !settings.isEmpty else { return [] }
        var out = ["", "## Context it sets", ""]
        for setting in settings {
            let name = AppleComponents.contextModifier(setting.key, of: contract.id)
            var text = "`\(setting.key)`"
            if let modifier = contextModifiers.first(where: { $0.name == name }) {
                text += ", `.\(name)(\(modifier.parameters.map(\.description).joined(separator: ", ")))`"
            }
            text += ", on an ancestor:"
            if let description = setting.value["description"]?.string { text += " " + usable(description) }
            out += ContextMarkdown.item(text)
        }
        return out
    }

    private func accessibilitySection() -> [String] {
        guard let accessibility = document["accessibility"] else { return [] }
        var out = ["", "## Accessibility", ""]
        var facts: [String] = []
        if let role = accessibility["role"]?.string { facts.append("Role: `\(role)`.") }
        if let intents = accessibility["intents"]?.elements?.compactMap(\.string), !intents.isEmpty {
            facts.append("A person can " + ContextMarkdown.list(intents, conjunction: "or") + " it.")
        }
        if let states = accessibility["states"]?.members, !states.isEmpty {
            facts.append(
                "Announced: "
                    + states.map { "`\($0.key)` as \($0.value.string ?? "")" }.joined(separator: ", ") + ".")
        }
        if !facts.isEmpty { out += ContextMarkdown.item(facts.joined(separator: " ")) }
        if let duty = labelDuty(accessibility["label"]?.string) { out += ContextMarkdown.item(duty) }
        if let label = hiddenLabels.first?.api {
            out += ContextMarkdown.item(
                "A control beside its own title draws no label: write `\(label.control)("
                    + label.initializers[0].parameters.map { "\($0.label): …" }.joined(separator: ", ")
                    + ")`, which requires the name, and hide the title beside it from assistive technology.")
        }
        return out
    }

    /// Where the accessible name comes from and what the caller owes it, from the API: the system control's own
    /// label, an initializer's `label:`, a drawn text, or the component's content where no initializer takes one.
    private func labelDuty(_ label: String?) -> String? {
        guard let label, label == "required" || label == "optional", let apple = contract.apple else { return nil }
        let required = label == "required"
        let never = "Name what it does or holds, never what it looks like."
        let initializers = views.flatMap(\.initializers)
        var controls = targets.map(\.control)
        if controls.isEmpty, let base = apple.base?.split(separator: ".").last { controls = [String(base)] }
        if !controls.isEmpty,
            apple.strategy == AppleComponents.strategy || apple.strategy == SystemStyles.extensionStrategy
        {
            let label =
                contract.slots.contains("icon")
                ? ", such as a `Label`, whose title is the name also where only its icon is drawn" : ""
            return
                (required
                ? "**Every instance needs an accessible name**: " : "The accessible name, where it has one, is ")
                + "the label the system's own initializer of "
                + ContextMarkdown.list(controls.map { "`\($0)`" }, conjunction: "or")
                + " takes, its title or the view of its `label:`\(label). westron adds no parameter for it. " + never
        }
        if initializers.contains(where: { $0.parameters.contains { $0.label == "label" } }) {
            return required
                ? "**Every instance needs an accessible name**: the initializer's `label:`. " + never
                : "The accessible name is the initializer's `label:`. Give it when the instance means something on "
                    + "the screen; without it the instance is decorative and hidden from assistive technology. " + never
        }
        if initializers.contains(where: {
            $0.parameters.first.map { $0.label == "_" && $0.type == AppleComponents.Own.labelType } ?? false
        }) {
            return "The accessible name is the drawn text, the initializer's first argument"
                + (required ? "; every instance gives one." : "; an instance without it has none.")
        }
        guard required else { return nil }
        return "**The accessible name comes from the component's content**: no initializer takes a label, and the "
            + "caller adds no `.accessibilityLabel` of its own, which would replace that name. Which parts are read, "
            + "and in what order, is in the details file."
    }

    /// A condition of a constraint: `` `floating: true` ``, `` `variant: .secondary` ``, `` `variant` `.a` or `.b` ``.
    private func condition(_ option: String, _ values: [String]) -> String {
        let isBool =
            contract.options.first { $0.name == option }.map {
                if case .bool = $0.kind { true } else { false }
            } ?? false
        let written = values.map { isBool ? $0 : "." + SwiftName.declared($0) }
        if written.count == 1 { return ContextMarkdown.code("\(option): \(written[0])") }
        return "`\(option)` " + ContextMarkdown.list(written.map(ContextMarkdown.code), conjunction: "or")
    }

    /// The options of a condition in the contract's order.
    private func ordered(_ conditions: [String: [String]]) -> [(String, [String])] {
        contract.options.compactMap { option in conditions[option.name].map { (option.name, $0) } }
    }

    private func constraintsSection() -> [String] {
        let entries = document["constraints"]?.elements ?? []
        guard !entries.isEmpty else { return [] }
        var out = ["", "## Do not", ""]
        for (constraint, entry) in zip(contract.constraints, entries) {
            var when = ordered(constraint.when).map { condition($0.0, $0.1) }
            when += constraint.slots.map { "a filled `\($0)` slot" }
            let require = ordered(constraint.require).map { option, values -> String in
                let isBool =
                    contract.options.first { $0.name == option }.map {
                        if case .bool = $0.kind { true } else { false }
                    } ?? false
                let written = values.map { ContextMarkdown.code(isBool ? $0 : "." + SwiftName.declared($0)) }
                return "`\(option)` other than " + ContextMarkdown.list(written, conjunction: "or")
            }
            var text =
                (constraint.forbids ? "**Never**: " : "**Avoid**: ") + ContextMarkdown.list(when) + " with "
                + ContextMarkdown.list(require, conjunction: "or") + "."
            if let description = entry["description"]?.string { text += " " + usable(description) }
            out += ContextMarkdown.item(text)
        }
        return out
    }

    private func appleSection() -> [String] {
        guard let entry = document["platforms"]?["apple"] else { return [] }
        var out = ["", "## On Apple", ""]
        if let description = entry["description"]?.string {
            out += ContextMarkdown.wrap(external(description))
        } else if let status = entry["status"]?.string {
            out += ContextMarkdown.wrap("Apple: \(status).")
        }
        for os in ComponentContract.appleOSes {
            guard let target = entry[os] else { continue }
            var text = target["status"]?.string == ComponentContract.unavailableStatus ? "Unavailable. " : ""
            text += external(target["description"]?.string ?? "")
            if !text.isEmpty {
                out += ["", "### \(AppleComponents.osNames[os]!)", ""] + ContextMarkdown.wrap(text)
            }
        }
        return out
    }
}
