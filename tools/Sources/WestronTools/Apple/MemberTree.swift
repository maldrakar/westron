/// The Swift names of one token type as a tree, in token order: a leaf is a token, a group holds the tokens and groups
/// whose names start with it (`Westron.Color.status.danger.text`; decisions/0010, "Apple API").
struct MemberTree: Equatable {
    indirect enum Node: Equatable {
        /// A token: its member name and its index in the generator's list of that type.
        case leaf(name: String, item: Int)
        case group(Group)

        var name: String {
            switch self {
            case .leaf(let name, _): name
            case .group(let group): group.name
            }
        }
    }

    struct Group: Equatable {
        let name: String
        /// The token group, `color.status.danger`.
        let path: TokenPath
        /// The members up to this group: `status`, `danger`.
        let members: [String]
        var children: [Node]

        /// The Swift type of the group, `StatusDanger`.
        var typeName: String { SwiftName.typeName(members) }

        /// The groups below this one, depth first, in token order.
        var descendants: [Group] {
            children.flatMap { node -> [Group] in
                guard case .group(let group) = node else { return [] }
                return [group] + group.descendants
            }
        }
    }

    var roots: [Node] = []

    /// The tree of the tokens' members, each token a list of members as `SwiftName.members` gives them.
    init(_ items: [[SwiftName.Member]]) {
        for (index, members) in items.enumerated() where !members.isEmpty {
            Self.insert(members[...], item: index, prefix: [], into: &roots)
        }
    }

    private static func insert(
        _ members: ArraySlice<SwiftName.Member>, item: Int, prefix: [String], into nodes: inout [Node]
    ) {
        let first = members.first!
        guard members.count > 1 else {
            nodes.append(.leaf(name: first.name, item: item))
            return
        }
        let existing = nodes.firstIndex { node in
            if case .group(let group) = node { group.name == first.name } else { false }
        }
        var group: Group
        if let existing, case .group(let found) = nodes[existing] {
            group = found
        } else {
            group = Group(name: first.name, path: first.path, members: prefix + [first.name], children: [])
        }
        insert(members.dropFirst(), item: item, prefix: group.members, into: &group.children)
        if let existing {
            nodes[existing] = .group(group)
        } else {
            nodes.append(.group(group))
        }
    }

    /// Every group, depth first, in token order.
    var groups: [Group] {
        roots.flatMap { node -> [Group] in
            guard case .group(let group) = node else { return [] }
            return [group] + group.descendants
        }
    }

    /// Every token's members joined by dots, in tree order: `status.danger.text`.
    var leafPaths: [(item: Int, path: String)] {
        func walk(_ nodes: [Node], _ prefix: String) -> [(item: Int, path: String)] {
            nodes.flatMap { node -> [(item: Int, path: String)] in
                switch node {
                case .leaf(let name, let item): [(item, prefix + name)]
                case .group(let group): walk(group.children, prefix + group.name + ".")
                }
            }
        }
        return walk(roots, "")
    }

    /// Names that two tokens or groups share in one place, that the type or a group's type already has, and group
    /// types that two groups share or that westron already has.
    /// - Parameters:
    ///   - type: the Swift type in the messages, `Color`.
    ///   - paths: each token's path, by its index.
    ///   - reservedLeaf: names a token directly on the type cannot take.
    ///   - reservedGroup: names a group directly on the type cannot take.
    func collisions(
        type: String, paths: [TokenPath], reservedLeaf: Set<String>, reservedGroup: Set<String>
    ) -> [String] {
        var problems: [String] = []
        func path(_ node: Node) -> TokenPath {
            switch node {
            case .leaf(_, let item): paths[item]
            case .group(let group): group.path
            }
        }
        func check(_ nodes: [Node], prefix: String, top: Bool) {
            var seen: [String: TokenPath] = [:]
            for node in nodes {
                let isGroup: Bool
                if case .group = node { isGroup = true } else { isGroup = false }
                let reserved = top ? (isGroup ? reservedGroup : reservedLeaf) : SwiftName.Reserved.group
                if reserved.contains(node.name) {
                    let owner = top ? "the type" : "a group's type"
                    problems.append(
                        "\(path(node)): its Swift name \(type).\(prefix)\(node.name) collides with a member \(owner) "
                            + "already has; rename the token")
                } else if let other = seen[node.name] {
                    problems.append(
                        "\(path(node)) and \(other) have the same Swift name \(type).\(prefix)\(node.name)")
                } else {
                    seen[node.name] = path(node)
                }
                if case .group(let group) = node {
                    check(group.children, prefix: prefix + group.name + ".", top: false)
                }
            }
        }
        check(roots, prefix: "", top: true)
        var types: [String: TokenPath] = [:]
        for group in groups {
            if SwiftName.Reserved.types.contains(group.typeName) {
                problems.append(
                    "\(group.path): its Swift type \(group.typeName) collides with a type westron already has; rename "
                        + "the group")
            } else if let other = types[group.typeName], other != group.path {
                problems.append("\(group.path) and \(other) have the same Swift type \(group.typeName)")
            } else {
                types[group.typeName] = group.path
            }
        }
        return problems
    }
}
