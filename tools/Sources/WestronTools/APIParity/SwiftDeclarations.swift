import Foundation
import SwiftParser
import SwiftSyntax

/// The declarations of a set of Swift files, read with Swift's own parser (swift-syntax), with the access each one
/// really has: a `public` member of an internal type is internal, a member of a `public extension` is public, an enum
/// case has its enum's access. The API parity lint (#21) compares the public ones with the contracts.
///
/// Only declarations are read: the bodies of functions, accessors and closures are skipped, since nothing declared
/// there is visible outside.
public struct SwiftDeclarations: Sendable {
    public enum Access: Int, Comparable, Sendable, CustomStringConvertible {
        case `private`, `fileprivate`, `internal`, `package`, `public`, `open`

        public static func < (lhs: Access, rhs: Access) -> Bool { lhs.rawValue < rhs.rawValue }

        public var description: String {
            switch self {
            case .private: "private"
            case .fileprivate: "fileprivate"
            case .internal: "internal"
            case .package: "package"
            case .public: "public"
            case .open: "open"
            }
        }

        /// Visible to a product that imports the module.
        public var isPublic: Bool { self >= .public }

        init?(keyword: String) {
            switch keyword {
            case "private": self = .private
            case "fileprivate": self = .fileprivate
            case "internal": self = .internal
            case "package": self = .package
            case "public": self = .public
            case "open": self = .open
            default: return nil
            }
        }
    }

    public struct Parameter: Equatable, Sendable, CustomStringConvertible {
        /// The argument label as written, `_` for none.
        public let label: String
        public let type: String
        /// The default value's expression, nil when there is none.
        public let defaultValue: String?

        public init(label: String, type: String, defaultValue: String? = nil) {
            self.label = label
            self.type = type
            self.defaultValue = defaultValue
        }

        public var description: String { "\(label): \(type)" + (defaultValue.map { " = \($0)" } ?? "") }
    }

    public struct Declaration: Equatable, Sendable {
        public enum Kind: String, Sendable {
            case `struct`, `class`, `enum`, `actor`, `protocol`, `typealias`, `associatedtype`
            case `case`, `func`, `var`, `subscript`, `macro`
            case initializer = "init"
            /// An extension: its name is the extended type; it is recorded for the conformances it adds.
            case `extension`

            /// A type declaration, which other declarations can be members of.
            public var isType: Bool { [.struct, .class, .enum, .actor, .protocol].contains(self) }
        }

        public let kind: Kind
        /// The simple name, without backticks: `ButtonVariant`, `primary`, `buttonStyle`, `init`; for an extension, the
        /// extended type without generic arguments.
        public let name: String
        /// The qualified name of the type the declaration is in, or that its extension extends: `CGFloat.radius`,
        /// `View`; empty at the top level.
        public let container: String
        /// Whether the closest enclosing scope is an extension.
        public let inExtension: Bool
        /// The access it really has, after its containers'.
        public let access: Access
        public let isStatic: Bool
        /// Inherited types and conformances as written.
        public let inheritance: [String]
        /// An enum case's raw value as written, such as `"m"`.
        public let rawValue: String?
        /// Whether an enum case has associated values.
        public let hasAssociatedValues: Bool
        public let parameters: [Parameter]
        /// The result of a function or subscript, the type of a variable.
        public let resultType: String?
        /// Attributes, generic parameters and requirements, effects, `mutating`: what a signature has beyond its
        /// parameters and result, as written.
        public let extras: [String]
        /// The `#if` clauses around it, outermost first: `#if os(watchOS)`.
        public let conditions: [String]
        public let file: String
        public let line: Int
        /// The first line of the declaration's text, for messages.
        public let text: String
        /// Marked `// westron-lint: allow <reason>` on its line or a comment line just above.
        public let allowed: Bool

        /// `CGFloat.radius.control`, `ButtonVariant`.
        public var qualifiedName: String { container.isEmpty ? name : container + "." + name }

        /// `buttonStyle(_ ButtonVariant, size ButtonSize? = nil) -> some View`.
        public var signature: String {
            let parameters = "(" + self.parameters.map(\.description).joined(separator: ", ") + ")"
            let result = resultType.map { " -> \($0)" } ?? ""
            let extras = self.extras.isEmpty ? "" : " [" + self.extras.joined(separator: " ") + "]"
            return (isStatic ? "static " : "") + name + parameters + result + extras
        }
    }

    public let declarations: [Declaration]

    /// Reads files; each path is used as given in the declarations, for messages.
    public init(files: [(path: String, text: String)]) {
        var raw: [RawDeclaration] = []
        for file in files {
            let tree = Parser.parse(source: file.text)
            let collector = Collector(file: file.path, text: file.text, tree: tree)
            collector.walk(tree)
            raw += collector.declarations
        }
        declarations = Self.resolve(raw)
    }

    /// A declaration before its effective access is known, which needs the access of the types in every file.
    struct RawDeclaration {
        var declaration: Declaration
        /// Its own access, or the default its extension gives; nil: the default for where it is.
        var ownAccess: Access?
        /// Whether its default access is its container's, as for an enum case or a protocol requirement.
        var takesContainerAccess: Bool
    }

    /// The effective access of every declaration: its own, no more than the type it is in. A type extended here and
    /// declared elsewhere, such as `View` or `Westron.Icon`, counts as public.
    static func resolve(_ raw: [RawDeclaration]) -> [Declaration] {
        var types: [String: RawDeclaration] = [:]
        for item in raw where item.declaration.kind.isType && types[item.declaration.qualifiedName] == nil {
            types[item.declaration.qualifiedName] = item
        }
        var memo: [String: Access] = [:]
        func typeAccess(_ name: String, depth: Int = 0) -> Access {
            if let known = memo[name] { return known }
            guard let item = types[name], depth < 32 else { return .public }
            let access = effective(item, depth: depth + 1)
            memo[name] = access
            return access
        }
        func effective(_ item: RawDeclaration, depth: Int) -> Access {
            let container = item.declaration.container.isEmpty ? Access.open : typeAccess(item.declaration.container)
            var own = item.ownAccess ?? .internal
            if item.ownAccess == nil, item.takesContainerAccess { own = container }
            // A private member of a type is visible in its file: as far as public API goes, it is not.
            return min(own, container)
        }
        return raw.map { item in
            let access = effective(item, depth: 0)
            let d = item.declaration
            return Declaration(
                kind: d.kind, name: d.name, container: d.container, inExtension: d.inExtension, access: access,
                isStatic: d.isStatic, inheritance: d.inheritance, rawValue: d.rawValue,
                hasAssociatedValues: d.hasAssociatedValues, parameters: d.parameters, resultType: d.resultType,
                extras: d.extras, conditions: d.conditions, file: d.file, line: d.line, text: d.text, allowed: d.allowed
            )
        }
    }

    /// Text of a syntax node on one line, its whitespace collapsed: `ButtonSize?`, `some View`.
    static func text(_ node: some SyntaxProtocol) -> String {
        node.trimmedDescription.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// A name without backticks.
    static func name(_ token: TokenSyntax) -> String {
        token.text.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
    }

    /// A type's name without generic arguments: `Label` for `Label<Text, Image>`.
    static func typeName(_ type: TypeSyntax) -> String {
        var name = text(type)
        if let open = name.firstIndex(of: "<") { name = String(name[..<open]) }
        return name
    }

    final class Collector: SyntaxVisitor {
        struct Scope {
            let name: String
            let isExtension: Bool
            /// The access an extension's modifier gives its members, or a protocol's its requirements.
            let memberAccess: Access?
            let kind: Declaration.Kind
        }

        let file: String
        let lines: [Substring]
        let converter: SourceLocationConverter
        var scopes: [Scope] = []
        var conditions: [String] = []
        var declarations: [RawDeclaration] = []

        init(file: String, text: String, tree: SourceFileSyntax) {
            self.file = file
            lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            converter = SourceLocationConverter(fileName: file, tree: tree)
            super.init(viewMode: .sourceAccurate)
        }

        var container: String { scopes.last?.name ?? "" }

        func line(of node: some SyntaxProtocol) -> Int {
            converter.location(for: node.positionAfterSkippingLeadingTrivia).line
        }

        /// The marker on the line, or on a comment line just above it.
        func allowed(at line: Int) -> Bool {
            func marked(_ text: Substring) -> Bool {
                guard let range = text.range(of: RawValues.allowMarker) else { return false }
                return !text[range.upperBound...].trimmingCharacters(in: .whitespaces).isEmpty
            }
            guard line >= 1, line <= lines.count else { return false }
            if marked(lines[line - 1]) { return true }
            guard line >= 2 else { return false }
            let previous = lines[line - 2].trimmingCharacters(in: .whitespaces)
            return previous.hasPrefix("//") && marked(Substring(previous))
        }

        func access(_ modifiers: DeclModifierListSyntax) -> Access? {
            for modifier in modifiers where modifier.detail == nil {
                if let access = Access(keyword: modifier.name.text) { return access }
            }
            return nil
        }

        func isStatic(_ modifiers: DeclModifierListSyntax) -> Bool {
            modifiers.contains { $0.name.text == "static" || $0.name.text == "class" }
        }

        /// Modifiers that change a signature beyond access and `static`: `mutating`, `nonisolated`, `override`, ….
        func otherModifiers(_ modifiers: DeclModifierListSyntax) -> [String] {
            modifiers.filter {
                Access(keyword: $0.name.text) == nil && $0.name.text != "static" && $0.name.text != "class"
            }
            .map { SwiftDeclarations.text($0) }
        }

        func record(
            _ node: some SyntaxProtocol, kind: Declaration.Kind, name: String, modifiers: DeclModifierListSyntax?,
            attributes: AttributeListSyntax? = nil, inheritance: InheritanceClauseSyntax? = nil,
            rawValue: String? = nil, hasAssociatedValues: Bool = false, parameters: [Parameter] = [],
            resultType: String? = nil, extras: [String] = [], takesContainerAccess: Bool = false
        ) {
            let line = line(of: node)
            let scope = scopes.last
            var own = modifiers.flatMap(access)
            var takes = takesContainerAccess
            if own == nil, let scope, let memberAccess = scope.memberAccess {
                if scope.isExtension {
                    // `public extension X { func f() }`: f is public; a `private extension` makes it fileprivate.
                    own = memberAccess == .private ? .fileprivate : memberAccess
                } else if scope.kind == .protocol {
                    takes = true
                }
            }
            var allExtras = attributes.map { $0.map { SwiftDeclarations.text($0) } } ?? []
            allExtras += modifiers.map(otherModifiers) ?? []
            allExtras += extras
            let text = lines.indices.contains(line - 1) ? lines[line - 1].trimmingCharacters(in: .whitespaces) : ""
            declarations.append(
                RawDeclaration(
                    declaration: Declaration(
                        kind: kind, name: name, container: container, inExtension: scope?.isExtension ?? false,
                        access: own ?? .internal, isStatic: modifiers.map(isStatic) ?? false,
                        inheritance: inheritance?.inheritedTypes.map { SwiftDeclarations.text($0.type) } ?? [],
                        rawValue: rawValue, hasAssociatedValues: hasAssociatedValues, parameters: parameters,
                        resultType: resultType, extras: allExtras, conditions: conditions, file: file, line: line,
                        text: text, allowed: allowed(at: line)),
                    ownAccess: own, takesContainerAccess: takes))
        }

        func parameters(_ clause: FunctionParameterClauseSyntax) -> [Parameter] {
            clause.parameters.map {
                Parameter(
                    label: SwiftDeclarations.name($0.firstName), type: SwiftDeclarations.text($0.type),
                    defaultValue: $0.defaultValue.map { SwiftDeclarations.text($0.value) })
            }
        }

        func genericExtras(_ generics: GenericParameterClauseSyntax?, _ requirements: GenericWhereClauseSyntax?)
            -> [String]
        {
            [generics.map { SwiftDeclarations.text($0) }, requirements.map { SwiftDeclarations.text($0) }]
                .compactMap { $0 }
        }

        // MARK: Scopes

        func enter(
            _ node: some SyntaxProtocol, kind: Declaration.Kind, name: TokenSyntax, modifiers: DeclModifierListSyntax,
            attributes: AttributeListSyntax, inheritance: InheritanceClauseSyntax?,
            generics: GenericParameterClauseSyntax?, requirements: GenericWhereClauseSyntax?
        ) -> SyntaxVisitorContinueKind {
            let simple = SwiftDeclarations.name(name)
            record(
                node, kind: kind, name: simple, modifiers: modifiers, attributes: attributes, inheritance: inheritance,
                extras: genericExtras(generics, requirements))
            let qualified = container.isEmpty ? simple : container + "." + simple
            scopes.append(
                Scope(
                    name: qualified, isExtension: false, memberAccess: kind == .protocol ? access(modifiers) : nil,
                    kind: kind))
            return .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(
                node, kind: .struct, name: node.name, modifiers: node.modifiers, attributes: node.attributes,
                inheritance: node.inheritanceClause, generics: node.genericParameterClause,
                requirements: node.genericWhereClause)
        }
        override func visitPost(_ node: StructDeclSyntax) { scopes.removeLast() }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(
                node, kind: .class, name: node.name, modifiers: node.modifiers, attributes: node.attributes,
                inheritance: node.inheritanceClause, generics: node.genericParameterClause,
                requirements: node.genericWhereClause)
        }
        override func visitPost(_ node: ClassDeclSyntax) { scopes.removeLast() }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(
                node, kind: .enum, name: node.name, modifiers: node.modifiers, attributes: node.attributes,
                inheritance: node.inheritanceClause, generics: node.genericParameterClause,
                requirements: node.genericWhereClause)
        }
        override func visitPost(_ node: EnumDeclSyntax) { scopes.removeLast() }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(
                node, kind: .actor, name: node.name, modifiers: node.modifiers, attributes: node.attributes,
                inheritance: node.inheritanceClause, generics: node.genericParameterClause,
                requirements: node.genericWhereClause)
        }
        override func visitPost(_ node: ActorDeclSyntax) { scopes.removeLast() }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(
                node, kind: .protocol, name: node.name, modifiers: node.modifiers, attributes: node.attributes,
                inheritance: node.inheritanceClause, generics: nil, requirements: node.genericWhereClause)
        }
        override func visitPost(_ node: ProtocolDeclSyntax) { scopes.removeLast() }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            let extended = SwiftDeclarations.typeName(node.extendedType)
            // An extension's container is the type it extends, so its record sits at that type's level.
            let saved = scopes
            scopes = []
            let parts = extended.split(separator: ".")
            let parent = parts.dropLast().joined(separator: ".")
            if !parent.isEmpty { scopes = [Scope(name: parent, isExtension: false, memberAccess: nil, kind: .struct)] }
            record(
                node, kind: .extension, name: String(parts.last ?? Substring(extended)), modifiers: node.modifiers,
                attributes: node.attributes, inheritance: node.inheritanceClause,
                extras: genericExtras(nil, node.genericWhereClause))
            scopes = saved
            scopes.append(
                Scope(name: extended, isExtension: true, memberAccess: access(node.modifiers), kind: .extension))
            return .visitChildren
        }
        override func visitPost(_ node: ExtensionDeclSyntax) { scopes.removeLast() }

        // MARK: Members

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                node, kind: .typealias, name: SwiftDeclarations.name(node.name), modifiers: node.modifiers,
                attributes: node.attributes, resultType: SwiftDeclarations.text(node.initializer.value),
                extras: genericExtras(node.genericParameterClause, node.genericWhereClause))
            return .skipChildren
        }

        override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                node, kind: .associatedtype, name: SwiftDeclarations.name(node.name), modifiers: node.modifiers,
                attributes: node.attributes, inheritance: node.inheritanceClause, takesContainerAccess: true)
            return .skipChildren
        }

        override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
            for element in node.elements {
                record(
                    element, kind: .case, name: SwiftDeclarations.name(element.name), modifiers: node.modifiers,
                    attributes: node.attributes,
                    rawValue: element.rawValue.map { SwiftDeclarations.text($0.value) },
                    hasAssociatedValues: element.parameterClause != nil, takesContainerAccess: true)
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            var extras = genericExtras(node.genericParameterClause, node.genericWhereClause)
            if let effects = node.signature.effectSpecifiers { extras.append(SwiftDeclarations.text(effects)) }
            record(
                node, kind: .func, name: SwiftDeclarations.name(node.name), modifiers: node.modifiers,
                attributes: node.attributes, parameters: parameters(node.signature.parameterClause),
                resultType: node.signature.returnClause.map { SwiftDeclarations.text($0.type) }, extras: extras)
            return .skipChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            var extras = genericExtras(node.genericParameterClause, node.genericWhereClause)
            if let mark = node.optionalMark { extras.append("init" + mark.text) }
            if let effects = node.signature.effectSpecifiers { extras.append(SwiftDeclarations.text(effects)) }
            record(
                node, kind: .initializer, name: "init", modifiers: node.modifiers, attributes: node.attributes,
                parameters: parameters(node.signature.parameterClause), extras: extras)
            return .skipChildren
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            var extras = genericExtras(node.genericParameterClause, node.genericWhereClause)
            if let accessors = node.accessorBlock, case .accessors(let list) = accessors.accessors {
                extras += list.map { $0.accessorSpecifier.text }
            }
            record(
                node, kind: .subscript, name: "subscript", modifiers: node.modifiers, attributes: node.attributes,
                parameters: node.parameterClause.parameters.map {
                    Parameter(
                        label: SwiftDeclarations.name($0.firstName), type: SwiftDeclarations.text($0.type),
                        defaultValue: $0.defaultValue.map { SwiftDeclarations.text($0.value) })
                }, resultType: SwiftDeclarations.text(node.returnClause.type), extras: extras)
            return .skipChildren
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            for binding in node.bindings {
                // `let (a, b)` declares each name; a typed pattern's type is the binding's annotation.
                let names = binding.pattern.tokens(viewMode: .sourceAccurate).filter {
                    if case .identifier = $0.tokenKind { return true }
                    return false
                }
                var extras = [node.bindingSpecifier.text]
                if let accessors = binding.accessorBlock, case .accessors(let list) = accessors.accessors {
                    extras += list.map { $0.accessorSpecifier.text }
                }
                for name in names {
                    record(
                        binding, kind: .var, name: SwiftDeclarations.name(name), modifiers: node.modifiers,
                        attributes: node.attributes,
                        resultType: binding.typeAnnotation.map { SwiftDeclarations.text($0.type) }, extras: extras)
                }
            }
            return .skipChildren
        }

        override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                node, kind: .macro, name: SwiftDeclarations.name(node.name), modifiers: node.modifiers,
                attributes: node.attributes, parameters: parameters(node.signature.parameterClause),
                resultType: node.signature.returnClause.map { SwiftDeclarations.text($0.type) })
            return .skipChildren
        }

        // MARK: Conditions

        override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
            let keyword = node.poundKeyword.text
            if let condition = node.condition {
                conditions.append("\(keyword) \(SwiftDeclarations.text(condition))")
            } else if let list = node.parent?.as(IfConfigClauseListSyntax.self), let first = list.first?.condition {
                conditions.append("#else of #if \(SwiftDeclarations.text(first))")
            } else {
                conditions.append(keyword)
            }
            return .visitChildren
        }
        override func visitPost(_ node: IfConfigClauseSyntax) { conditions.removeLast() }

        // Bodies declare nothing visible outside.
        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
        override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    }
}
