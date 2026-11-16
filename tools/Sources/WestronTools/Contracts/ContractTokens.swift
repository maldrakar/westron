/// The tokens a contract may bind: which paths exist, in which modes, and which are primitives.
public struct ContractTokens: Sendable {
    /// Paths that resolve in every input of the resolver.
    public let everywhere: Set<TokenPath>
    /// Paths that resolve in some inputs only, with the inputs they are missing from, described.
    public let somewhere: [TokenPath: [String]]
    /// Paths of primitive tokens, from a file under a `primitive/` directory: components never bind them
    /// (tokens/README.md, decisions/0010).
    public let primitive: Set<TokenPath>

    public init(everywhere: Set<TokenPath>, somewhere: [TokenPath: [String]] = [:], primitive: Set<TokenPath> = []) {
        self.everywhere = everywhere
        self.somewhere = somewhere
        self.primitive = primitive
    }

    /// The tokens of every input of a resolution.
    /// - Throws: `TokenErrors` if an input does not resolve.
    public init(_ resolution: Resolution) throws {
        let all = try resolution.resolveAll()
        var counts: [TokenPath: Int] = [:]
        var primitive: Set<TokenPath> = []
        for input in all {
            for token in input.tokens {
                counts[token.path, default: 0] += 1
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
        self.init(everywhere: everywhere, somewhere: somewhere, primitive: primitive)
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
}
