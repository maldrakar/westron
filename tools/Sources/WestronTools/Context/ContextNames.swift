import Foundation

/// The westron names the agent context writes in its own prose, each looked up where WestronUI's API is declared, so
/// that a renamed token, adapter or modifier fails `tools/westron generate` instead of leaving a stale name in the
/// bundle (decisions/0016). The pattern check holds a pattern's example and prose to the same names (`PatternNames`,
/// decisions/0018).
///
/// Prose is written as a template whose placeholders name what they mean:
/// - `{token:color.text.primary}` is the token's Swift member, `text.primary` (`AppleTokenModel`);
/// - `{adapter:View.foregroundStyle}` is a reviewed adapter of `TokenAdapters.swift` (`APIParity.adapters`), written
///   as its name;
/// - `{api:textRole}` is a function of a contract's API (`APIParity.expected`), written as its name, a context's
///   shared modifier too (`{api:category}`);
/// - `{category:text}` is a role of the list colors, `{icon:fallback}` and `{icon:systemName}` the icon API's members
///   (`AppleIcons`).
///
/// `{!kind:name}` checks the name and writes nothing, for prose that names the API without spelling it, such as
/// `Color(.text.primary)`, an initializer.
struct ContextNames {
    /// Each token's dotted path to its Swift member.
    let tokens: [String: String]
    let categoryRoles: Set<String>
    /// The functions every contract's API declares.
    let functions: Set<String>
    /// The text roles' Swift members, `footnote.regular`.
    let textRoles: Set<String>
    /// The list colors' cases, `amber`.
    let categories: Set<String>

    /// Every token's Swift member, `space.withinGroup`.
    var members: Set<String> { Set(tokens.values) }

    init(model: AppleTokenModel, functions: Set<String>) {
        var tokens: [String: String] = [:]
        func add(_ path: TokenPath, _ members: [SwiftName.Member]) {
            tokens[path.description] = AppleTokensSwift.reference(members)
        }
        for color in model.colors { add(color.path, color.members) }
        for role in model.textRoles { add(role.path, role.members) }
        for scalar in model.dimensions + model.numbers { add(scalar.path, scalar.members) }
        for transition in model.transitions { add(transition.path, transition.members) }
        for shadow in model.shadows { add(shadow.path, shadow.members) }
        self.tokens = tokens
        categoryRoles = Set(model.categories?.roles.map(\.name) ?? [])
        self.functions = functions
        textRoles = Set(model.textRoles.map { AppleTokensSwift.reference($0.members) })
        categories = Set(model.categories?.categories.map(\.caseName) ?? [])
    }

    struct Missing: Error, CustomStringConvertible {
        let placeholder: String
        var description: String {
            "the agent context names \(placeholder), which WestronUI's API does not declare: change the text in "
                + "tools/Sources/WestronTools/Context (decisions/0016)"
        }
    }

    /// The template with every placeholder replaced.
    /// - Throws: `Missing` for a placeholder whose name is not declared.
    func fill(_ template: String) throws -> String {
        var out = ""
        var rest = Substring(template)
        while let open = rest.range(of: "{") {
            out += rest[..<open.lowerBound]
            let after = rest[open.upperBound...]
            let silent = after.hasPrefix("!")
            let start = silent ? after.index(after: after.startIndex) : after.startIndex
            guard let close = after.firstIndex(of: "}"), let colon = after[start..<close].firstIndex(of: ":"),
                let kind = Kind(rawValue: String(after[start..<colon]))
            else {
                out += "{"
                rest = after
                continue
            }
            let name = String(after[after.index(after: colon)..<close])
            let resolved = try resolve(kind, name)
            if !silent { out += resolved }
            rest = after[after.index(after: close)...]
        }
        return out + rest
    }

    enum Kind: String {
        case token, adapter, api, category, icon
    }

    func resolve(_ kind: Kind, _ name: String) throws -> String {
        let missing = Missing(placeholder: "{\(kind.rawValue):\(name)}")
        switch kind {
        case .token:
            guard let member = tokens[name] else { throw missing }
            return member
        case .adapter:
            let parts = name.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { throw missing }
            guard APIParity.adapters[parts[0]]?.contains(parts[1]) == true else { throw missing }
            return parts[1]
        case .api:
            guard functions.contains(name) else { throw missing }
            return name
        case .category:
            guard categoryRoles.contains(name) else { throw missing }
            return name
        case .icon:
            guard [AppleIcons.fallbackMember, AppleIcons.systemNameMember].contains(name) else { throw missing }
            return name
        }
    }
}
