import Foundation
import SwiftParser
import SwiftSyntax

/// The westron names a pattern's Swift example and its prose write, held to WestronUI's reviewed API as the agent
/// context's own prose is (`ContextNames`, decisions/0018, point 2): a renamed token, view, modifier or option value
/// fails `tools/westron patterns check` instead of leaving a stale name in a pattern.
///
/// What it holds, in Swift read by swift-syntax:
/// - an implicit member chain of two names or more, `.space.page.narrow`, `.text.secondary`, is a token's Swift member;
/// - a call of a westron view, `ListRow(level:guides:action:) { … } leading: { … }`, `WestronUI.Icon(.check)`, matches
///   one of the initializers the API parity lint expects, by its argument labels and trailing closures;
/// - a call of a westron function, `.selected(_:)`, `.textRole(_:)`, `.category(_:)`, matches one of its overloads;
/// - an argument such a call passes as `.name` is a value of its parameter's type: a name of the icon registry, a list
///   color, a text role, a value of a contract's option.
///
/// In prose, a code span that reads as a token's name, `space.page.narrow` or `footnote.regular`, is a token's path or
/// Swift member; any other code span is read as Swift and held as above. What is not westron's, SwiftUI's own calls
/// and the product's, is left alone: it cannot be told from a typo without the SDK, and the catalog's example, which
/// compiles, covers it.
struct PatternNames {
    let names: ContextNames
    let icons: Set<String>
    /// westron's views by type, with their initializers.
    let views: [String: [AppleComponents.Own.Initializer]]
    /// westron's functions by name, each overload's parameters.
    let functions: [String: [[SwiftDeclarations.Parameter]]]
    /// The option enums by type, with their Swift cases.
    let enums: [String: Set<String>]

    init(expected: APIParity.Expected, names: ContextNames, icons: Set<String>) {
        self.names = names
        self.icons = icons
        var views: [String: [AppleComponents.Own.Initializer]] = [:]
        for view in expected.views { views[view.type, default: []] += view.initializers }
        self.views = views
        var functions: [String: [[SwiftDeclarations.Parameter]]] = [:]
        for function in expected.functions where !functions[function.name, default: []].contains(function.parameters) {
            functions[function.name, default: []].append(function.parameters)
        }
        self.functions = functions
        var enums: [String: Set<String>] = [:]
        for item in expected.enums { enums[item.type] = Set(item.values.map(SwiftName.declared)) }
        self.enums = enums
    }

    /// The style modifiers of the system's controls, `buttonStyle`: SwiftUI declares them too, so a call with one
    /// unlabeled argument that is not westron's may be the system's own style.
    static let systemStyleModifiers = Set(SystemStyles.byBase.values.map(\.modifier))

    /// The first names of every token's path and Swift member, `space`, `color`, `text`, `footnote`: a code span that
    /// starts with one and is dotted is read as a token's name.
    var tokenHeads: Set<String> {
        Set(
            (Array(names.tokens.keys) + Array(names.members)).compactMap {
                $0.split(separator: ".").first.map(String.init)
            })
    }

    // MARK: - Prose

    /// A dotted name such as `space.page.narrow` or `footnote.regular`.
    private static let dotted = try! NSRegularExpression(pattern: #"^[a-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$"#)
    /// A code span on one line.
    private static let span = try! NSRegularExpression(pattern: #"`([^`\n]+)`"#)

    /// The code spans of a line of prose.
    static func spans(_ line: String) -> [String] {
        let ns = NSString(string: line)
        return span.matches(in: line, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range(at: 1))
        }
    }

    /// The problems of one code span of prose.
    func problems(span: String) -> [String] {
        let range = NSRange(location: 0, length: NSString(string: span).length)
        if Self.dotted.firstMatch(in: span, range: range) != nil {
            guard let head = span.split(separator: ".").first.map(String.init), tokenHeads.contains(head) else {
                return []
            }
            if names.tokens[span] != nil || names.members.contains(span) { return [] }
            return [
                "`\(span)` names no token: neither a token's path (`space.page.narrow`) nor its Swift member "
                    + "(`space.withinGroup`, `footnote.regular`)"
            ]
        }
        return problems(swift: span).map(\.message)
    }

    // MARK: - Swift

    /// The problems of Swift code, each with its line in the code, from 1.
    func problems(swift code: String) -> [(line: Int, message: String)] {
        let tree = Parser.parse(source: code)
        let visitor = Visitor(names: self, converter: SourceLocationConverter(fileName: "", tree: tree))
        visitor.walk(tree)
        return visitor.problems
    }

    /// An argument of a call: its label (`_` for none) and its expression, or a trailing closure, labeled or not.
    struct Argument {
        let label: String
        let expression: ExprSyntax?
        /// The unlabeled trailing closure, which takes the next parameter that takes a closure.
        let isTrailingClosure: Bool

        /// The call's arguments as Swift writes a call's name: `(level:_:) { … } leading: { … }`.
        static func written(_ arguments: [Argument]) -> String {
            let explicit = arguments.prefix { !$0.isTrailingClosure && $0.expression != nil }
            var out = "(" + explicit.map { $0.label + ":" }.joined() + ")"
            for argument in arguments.dropFirst(explicit.count) {
                out += argument.isTrailingClosure ? " { … }" : " \(argument.label): { … }"
            }
            return out
        }
    }

    /// The arguments matched to the parameters of one overload, in order, or nil when they do not fit it: each
    /// argument takes the next parameter with its label, a parameter with a default may be left out, and the
    /// unlabeled trailing closure takes the next parameter of a function type.
    static func match(_ arguments: [Argument], _ parameters: [SwiftDeclarations.Parameter])
        -> [(Argument, SwiftDeclarations.Parameter)]?
    {
        var index = 0
        var pairs: [(Argument, SwiftDeclarations.Parameter)] = []
        for parameter in parameters {
            if index < arguments.count {
                let argument = arguments[index]
                let fits =
                    argument.isTrailingClosure ? parameter.type.contains("->") : argument.label == parameter.label
                if fits {
                    pairs.append((argument, parameter))
                    index += 1
                    continue
                }
            }
            if parameter.defaultValue == nil { return nil }
        }
        return index == arguments.count ? pairs : nil
    }

    /// The `.name` of an implicit member chain, `.space.page.narrow` as its names, or nil when the expression is not
    /// one.
    static func implicitChain(_ expression: ExprSyntax) -> [String]? {
        var names: [String] = []
        var current: ExprSyntax? = expression
        while let member = current?.as(MemberAccessExprSyntax.self) {
            names.insert(member.declName.baseName.text, at: 0)
            current = member.base
        }
        return current == nil && !names.isEmpty ? names : nil
    }

    /// The problem of an argument's value for its parameter's type, when the value is a westron name it is not.
    func valueProblem(_ expression: ExprSyntax, type: String) -> String? {
        guard let chain = Self.implicitChain(expression) else { return nil }
        let value = chain.joined(separator: ".")
        let type = Self.unwrapped(type)
        if type == AppleIcons.iconType {
            guard chain.count == 1, !icons.contains(value) else { return nil }
            return "`.\(value)` is not a name of the icon registry (spec/icons/icons.yaml)"
        }
        if type == AppleTokenModel.textRoleType {
            // A name that is no token at all the chain's own check reports.
            guard !names.textRoles.contains(value), names.members.contains(value) else { return nil }
            return "`.\(value)` is not a text role"
        }
        if type == AppleComponents.contextValues["category"].map({ Self.unwrapped($0.type) }) {
            guard chain.count == 1, !names.categories.contains(value) else { return nil }
            return "`.\(value)` is not a list color"
        }
        guard let values = enums[type], chain.count == 1, !values.contains(value) else { return nil }
        return "`.\(value)` is not a value of `\(type)`: " + values.sorted().map { "`.\($0)`" }.joined(separator: ", ")
    }

    /// `Westron.Icon` for `Westron.Icon?`.
    static func unwrapped(_ type: String) -> String { type.hasSuffix("?") ? String(type.dropLast()) : type }

    final class Visitor: SyntaxVisitor {
        let names: PatternNames
        let converter: SourceLocationConverter
        var problems: [(line: Int, message: String)] = []

        init(names: PatternNames, converter: SourceLocationConverter) {
            self.names = names
            self.converter = converter
            super.init(viewMode: .sourceAccurate)
        }

        func report(_ node: some SyntaxProtocol, _ message: String) {
            problems.append((node.startLocation(converter: converter).line, message))
        }

        override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
            // The whole chain once: not a part of a longer one, not a method called on it.
            if let parent = node.parent?.as(MemberAccessExprSyntax.self), parent.base?.id == node.id {
                return .visitChildren
            }
            if let call = node.parent?.as(FunctionCallExprSyntax.self), call.calledExpression.id == node.id {
                return .visitChildren
            }
            if let chain = PatternNames.implicitChain(ExprSyntax(node)), chain.count >= 2 {
                let value = chain.joined(separator: ".")
                if !names.names.members.contains(value) {
                    report(node, "`.\(value)` is not a token's Swift member (the token pages list them)")
                }
            }
            return .visitChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            var arguments = node.arguments.map {
                Argument(label: $0.label?.text ?? "_", expression: $0.expression, isTrailingClosure: false)
            }
            if node.trailingClosure != nil {
                arguments.append(Argument(label: "_", expression: nil, isTrailingClosure: true))
            }
            for closure in node.additionalTrailingClosures {
                arguments.append(Argument(label: closure.label.text, expression: nil, isTrailingClosure: false))
            }
            let callee = node.calledExpression
            var view: String?
            if let reference = callee.as(DeclReferenceExprSyntax.self) {
                view = reference.baseName.text
            } else if let member = callee.as(MemberAccessExprSyntax.self),
                member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "WestronUI"
            {
                view = member.declName.baseName.text
            }
            let written = Argument.written(arguments)
            if let view, let initializers = names.views[view] {
                check(
                    node, arguments, overloads: initializers.map(\.parameters),
                    else: "`\(view)\(written)` matches no initializer WestronUI declares for \(view): "
                        + initializers.map { "`\($0)`" }.joined(separator: "; "))
            } else if view == nil, let member = callee.as(MemberAccessExprSyntax.self) {
                let name = member.declName.baseName.text
                if let overloads = names.functions[name] {
                    let system = PatternNames.systemStyleModifiers.contains(name)
                    // A lone unlabeled style, `.buttonStyle(.plain)`, may be SwiftUI's own overload.
                    let mayBeSystem = system && arguments.count == 1 && arguments[0].label == "_"
                    check(
                        node, arguments, overloads: overloads, values: !mayBeSystem,
                        else: "`.\(name)\(written)` matches no overload WestronUI declares: "
                            + overloads.map { "`.\(name)(\($0.map(\.description).joined(separator: ", ")))`" }
                            .joined(separator: "; "))
                }
            }
            return .visitChildren
        }

        /// Reports the call when it fits no overload, and each westron value it passes that is not one.
        private func check(
            _ node: FunctionCallExprSyntax, _ arguments: [Argument], overloads: [[SwiftDeclarations.Parameter]],
            values: Bool = true, else message: String
        ) {
            let matches = overloads.compactMap { PatternNames.match(arguments, $0) }
            guard !matches.isEmpty else {
                report(node, message)
                return
            }
            guard values else { return }
            // A value is wrong only where every overload the call fits rejects it.
            var found: [(node: ExprSyntax, message: String)]?
            for pairs in matches {
                let wrong = pairs.compactMap { argument, parameter -> (ExprSyntax, String)? in
                    guard let expression = argument.expression,
                        let message = names.valueProblem(expression, type: parameter.type)
                    else { return nil }
                    return (expression, message)
                }
                if wrong.isEmpty { return }
                if found == nil { found = wrong }
            }
            for item in found ?? [] { report(item.node, item.message) }
        }
    }
}
