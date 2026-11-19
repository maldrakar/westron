/// The tokens a contract may bind: which paths exist, in which modes, and which are primitives.
public struct ContractTokens: Sendable {
    /// Paths that resolve in every input of the resolver.
    public let everywhere: Set<TokenPath>
    /// Paths that resolve in some inputs only, with the inputs they are missing from, described.
    public let somewhere: [TokenPath: [String]]
    /// Paths of primitive tokens, from a file under a `primitive/` directory: components never bind them
    /// (tokens/README.md, decisions/0010).
    public let primitive: Set<TokenPath>
    /// The type of each path; a path without one is not checked for it.
    public let types: [TokenPath: TokenType]
    /// The paths in token order, as the resolver's first input lists them: the order of a group's values
    /// (`group(_:)`). A path not in it comes after the ones that are, sorted.
    public let order: [TokenPath]

    public init(
        everywhere: Set<TokenPath>, somewhere: [TokenPath: [String]] = [:], primitive: Set<TokenPath> = [],
        types: [TokenPath: TokenType] = [:], order: [TokenPath] = []
    ) {
        self.everywhere = everywhere
        self.somewhere = somewhere
        self.primitive = primitive
        self.types = types
        self.order = order
    }

    /// The tokens of every input of a resolution.
    /// - Throws: `TokenErrors` if an input does not resolve.
    public init(_ resolution: Resolution) throws {
        let all = try resolution.resolveAll()
        var counts: [TokenPath: Int] = [:]
        var primitive: Set<TokenPath> = []
        var types: [TokenPath: TokenType] = [:]
        for input in all {
            for token in input.tokens {
                counts[token.path, default: 0] += 1
                types[token.path] = token.type
                if token.source.split(separator: "/").contains("primitive") { primitive.insert(token.path) }
            }
        }
        var everywhere: Set<TokenPath> = []
        var somewhere: [TokenPath: [String]] = [:]
        for (path, count) in counts {
            if count == all.count {
                everywhere.insert(path)
            } else {
                somewhere[path] = all.filter { $0[path] == nil }.map { resolution.describe($0.input) }
            }
        }
        self.init(
            everywhere: everywhere, somewhere: somewhere, primitive: primitive, types: types,
            order: all.first?.tokens.map(\.path) ?? [])
    }

    /// Why a contract cannot bind a path, or nil if it can.
    func problem(_ path: TokenPath) -> String? {
        if let missing = somewhere[path] {
            let shown = missing.prefix(3).joined(separator: "; ")
            let more = missing.count > 3 ? " and \(missing.count - 3) more" : ""
            return "the token \(path) does not exist in every mode: it is missing from \(shown)\(more)"
        }
        guard everywhere.contains(path) else { return "no token \(path) in tokens/" }
        if primitive.contains(path) {
            return "\(path) is a primitive token; bind a semantic one (tokens/README.md)"
        }
        return nil
    }

    /// The tokens under a group, such as `typography`, by their path after it (`heading.large`), in token order
    /// (`order`); and why an option cannot take its values from the group: it is a token itself, holds no token, holds
    /// a primitive, a token missing from some mode, or tokens of more than one type.
    func group(_ group: TokenPath) -> (values: [String], problems: [String]) {
        let rank = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let paths = (everywhere.union(somewhere.keys)).filter {
            $0.names.count > group.names.count && Array($0.names.prefix(group.names.count)) == group.names
        }.sorted { (rank[$0] ?? Int.max, $0) < (rank[$1] ?? Int.max, $1) }
        if everywhere.contains(group) || somewhere[group] != nil {
            return (
                [], ["\(group) is a token, not a group: name the group whose tokens are the option's values"]
            )
        }
        guard !paths.isEmpty else { return ([], ["no token group \(group) in tokens/"]) }
        var problems: [String] = []
        func listed(_ items: [TokenPath]) -> String {
            items.sorted().prefix(3).map(\.description).joined(separator: ", ")
                + (items.count > 3 ? " and \(items.count - 3) more" : "")
        }
        let primitives = paths.filter(primitive.contains)
        if !primitives.isEmpty {
            problems.append(
                "\(group) holds primitive tokens (\(listed(primitives))): an option takes its values from semantic "
                    + "tokens (tokens/README.md)")
        }
        for path in paths where somewhere[path] != nil {
            if let problem = problem(path) { problems.append(problem) }
        }
        var byType: [TokenType: [TokenPath]] = [:]
        for path in paths { if let type = types[path] { byType[type, default: []].append(path) } }
        if byType.count > 1 {
            let kinds = byType.sorted { $0.key.rawValue < $1.key.rawValue }.map { type, paths in
                "\(type.rawValue): \(listed(paths))"
            }
            problems.append(
                "the tokens of \(group) are of more than one type (\(kinds.joined(separator: "; "))): an option's "
                    + "values are tokens of one type; name a narrower group")
        }
        let values = paths.map { TokenPath(Array($0.names.dropFirst(group.names.count))).description }
        return (values, problems)
    }
}
