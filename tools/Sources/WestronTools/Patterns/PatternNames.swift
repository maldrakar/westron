import Foundation
import SwiftParser
import SwiftSyntax

/// The westron names a pattern's Swift example and its prose write, held to WestronUI's reviewed API as the agent
/// context's own prose is (`ContextNames`, decisions/0018, point 2): a renamed token, view, modifier or option value
/// fails `tools/westron patterns check` instead of leaving a stale name in a pattern.
///
/// What it holds, in Swift read by swift-syntax:
/// - an implicit member chain of two names or more that starts as a token does, `.space.page.narrow`,
///   `.text.secondary`, also as the base of a call, `.text.primary.opacity(…)`, is a token's Swift member; SwiftUI's
///   own, `.bounce.up`, `.tint.secondary`, start otherwise and are left alone;
/// - a call of a westron view, `ListRow(level:guides:action:) { … } leading: { … }`, `WestronUI.Icon(.check)`, matches
///   one of the initializers the API parity lint expects, by its argument labels and trailing closures;
/// - a call of a westron function, `.selected(_:)`, `.textRole(_:)`, `.category(_:)`, matches one of its overloads;
/// - an argument such a call passes as `.name` is a value of its parameter's type: a name of the icon registry, a list
///   color, a text role, a value of a contract's option. A style modifier's lone argument, `.buttonStyle(.plain)`, is
///   SwiftUI's own style when it is not written `.name` (`myStyle`, `MyStyle()`) or names one of the system's styles
///   for that modifier (`SystemStyles`); any other `.name` there is held to westron's variants.
///
/// A call whose arguments are elided, `ListRow(…) { … }`, as the repository's prose writes a call, is not held; an
/// `…` in a string literal or a closure elides nothing.
///
/// In prose, a code span wrapped over two lines is read as one, its line break a space. A code span that reads as a token's name, `space.page.narrow` or `footnote.regular`, is a token's path or
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
        tokenHeads = Set(
            (Array(names.tokens.keys) + Array(names.members)).compactMap {
                $0.split(separator: ".").first.map(String.init)
            })
    }

    /// The system's own styles of each style modifier, `buttonStyle`: `plain`, `bordered`, …; SwiftUI declares the
    /// modifier too, so its lone argument may be one of them, or a style of the product's own.
    static let systemStyles: [String: Set<String>] = Dictionary(
        SystemStyles.byBase.values.map { ($0.modifier, Set($0.styles)) }, uniquingKeysWith: { $0.union($1) })

    /// The first names of every token's path and Swift member, `space`, `color`, `text`, `footnote`: a code span that
    /// starts with one and is dotted is read as a token's name.
    let tokenHeads: Set<String>

    // MARK: - Prose

    /// A dotted name such as `space.page.narrow` or `footnote.regular`.
    private static let dotted = try! NSRegularExpression(pattern: #"^[a-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$"#)
    /// A code span, which may wrap onto the next line of its paragraph.
    private static let span = try! NSRegularExpression(pattern: #"`([^`]+)`"#)
    /// A line break inside a code span and the indent after it.
    private static let lineBreak = try! NSRegularExpression(pattern: #"[ \t]*\n[ \t]*"#)

    /// The code spans of a paragraph of prose, each with the index of the line it starts on; a line break inside a
    /// span is a space, as Markdown reads it.
    static func spans(_ paragraph: String) -> [(span: String, line: Int)] {
        let ns = NSString(string: paragraph)
        return span.matches(in: paragraph, range: NSRange(location: 0, length: ns.length)).map { match in
            let text = ns.substring(with: match.range(at: 1))
            let before = ns.substring(to: match.range.location)
            return (
                lineBreak.stringByReplacingMatches(
                    in: text, range: NSRange(location: 0, length: NSString(string: text).length), withTemplate: " "),
                before.filter { $0 == "\n" }.count
            )
        }
    }

    /// The prose's paragraphs, each as its lines joined and the file's line of its first: the lines between blank
    /// ones, a heading, a table's row and a list item each starting a paragraph of its own, since a code span does
    /// not cross into them.
    static func paragraphs(_ prose: [Pattern.Line]) -> [(text: String, line: Int)] {
        var out: [(text: String, line: Int)] = []
        var current: [Pattern.Line] = []
        // A heading or a table's row is a paragraph of one line.
        var lastWasSingle = false
        func flush() {
            if let first = current.first {
                out.append((current.map(\.text).joined(separator: "\n"), first.line))
            }
            current = []
        }
        for line in prose {
            let trimmed = line.text.drop { $0 == " " }
            if trimmed.isEmpty || current.last.map({ $0.line + 1 != line.line }) == true {
                flush()
                if trimmed.isEmpty { continue }
            }
            let single = trimmed.hasPrefix("#") || trimmed.hasPrefix("|")
            let starts =
                single || trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ")
                || trimmed.range(of: #"^\d+[.)] "#, options: .regularExpression) != nil
            if starts || lastWasSingle { flush() }
            current.append(line)
            lastWasSingle = single
        }
        flush()
        return out
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
            guard !names.textRoles.contains(value) else { return nil }
            // A chain of two names or more the chain's own check reports, where it is no token at all.
            if chain.count >= 2, !names.members.contains(value), tokenHeads.contains(chain[0]) { return nil }
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
            // The whole chain once: not a part of a longer one; for a method called on it, `.text.primary.opacity(…)`,
            // the chain it is called on.
            if let parent = node.parent?.as(MemberAccessExprSyntax.self), parent.base?.id == node.id {
                return .visitChildren
            }
            var chained: ExprSyntax? = ExprSyntax(node)
            if let call = node.parent?.as(FunctionCallExprSyntax.self), call.calledExpression.id == node.id {
                chained = node.base
            }
            if let chained, let chain = PatternNames.implicitChain(chained), chain.count >= 2,
                names.tokenHeads.contains(chain[0])
            {
                let value = chain.joined(separator: ".")
                if !names.names.members.contains(value) {
                    report(chained, "`.\(value)` is not a token's Swift member (the token pages list them)")
                }
            }
            return .visitChildren
        }

        /// Whether the call's arguments are elided, `ListRow(…)` or `ListRow(level: 1, …)`: the prose's way of naming
        /// a call, not one to hold. Only an `…` the arguments write as Swift counts: not one in a string literal,
        /// `label: "Move to…"`, nor in a closure, `action: { … }`, nor in the trailing closures, `ListRow(level: 1)
        /// { … }`, whose arguments are written and held.
        static func isElided(_ node: FunctionCallExprSyntax) -> Bool {
            let parts: [Syntax?] = [
                node.unexpectedBetweenLeftParenAndArguments.map(Syntax.init), Syntax(node.arguments),
                node.unexpectedBetweenArgumentsAndRightParen.map(Syntax.init),
            ]
            return parts.compactMap { $0 }.contains { part in
                part.tokens(viewMode: .sourceAccurate).contains { token in
                    guard token.text.contains("…") else { return false }
                    var ancestor = token.parent
                    while let current = ancestor, current.id != part.id {
                        if current.is(StringLiteralExprSyntax.self) || current.is(ClosureExprSyntax.self) {
                            return false
                        }
                        ancestor = current.parent
                    }
                    return true
                }
            }
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if Self.isElided(node) { return .visitChildren }
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
                    // A lone unlabeled style SwiftUI's own overload takes: `.buttonStyle(.plain)`, `myStyle`,
                    // `MyStyle()`; any other `.name` there is westron's variant.
                    var mayBeSystem = false
                    if let styles = PatternNames.systemStyles[name], arguments.count == 1, arguments[0].label == "_",
                        let expression = arguments[0].expression
                    {
                        if let chain = PatternNames.implicitChain(expression) {
                            mayBeSystem = chain.count == 1 && styles.contains(chain[0])
                        } else {
                            mayBeSystem = true
                        }
                    }
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
            // A value is wrong only where every overload the call fits rejects it; the message names what each
            // overload that rejects it takes, `.toggleStyle(.primary)` both `CheckboxVariant` and `ChipVariant`.
            var found: [(node: ExprSyntax, messages: [String])] = []
            for (index, pairs) in matches.enumerated() {
                let wrong = pairs.compactMap { argument, parameter -> (ExprSyntax, String)? in
                    guard let expression = argument.expression,
                        let message = names.valueProblem(expression, type: parameter.type)
                    else { return nil }
                    return (expression, message)
                }
                if wrong.isEmpty { return }
                if index == 0 {
                    found = wrong.map { ($0.0, [$0.1]) }
                    continue
                }
                for (node, message) in wrong {
                    guard let at = found.firstIndex(where: { $0.node.id == node.id }),
                        !found[at].messages.contains(message)
                    else { continue }
                    found[at].messages.append(message)
                }
            }
            for item in found { report(item.node, Self.joined(item.messages)) }
        }

        /// One value's problems on several overloads as one message: "`.primary` is not a value of `CheckboxVariant`:
        /// `.check`; nor of `ChipVariant`: `.filter`".
        static func joined(_ messages: [String]) -> String {
            guard let first = messages.first else { return "" }
            let marker = " is not a value of "
            let head = first.range(of: marker).map { String(first[..<$0.upperBound]) }
            return messages.dropFirst().reduce(first) { out, message in
                if let head, message.hasPrefix(head) { return out + "; nor of " + message.dropFirst(head.count) }
                return out + "; " + message
            }
        }
    }
}
