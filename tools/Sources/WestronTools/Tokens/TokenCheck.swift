import Foundation

/// `tools/westron tokens check`: the resolver file and every token file pass the official DTCG schemas and
/// westron's reader, every token file is used, no two modifiers overlap, and every input resolves.
public enum TokenCheck {
    /// The directory of the resolver and its token files, relative to the repository root.
    public static let defaultDirectory = "tokens"
    /// The resolver, relative to the repository root.
    public static let defaultResolver = "tokens/westron.resolver.json"
    public static let fileSuffix = ".tokens.json"

    public struct Report: Equatable, Sendable {
        /// One resolved input and its number of tokens.
        public struct Combination: Equatable, Sendable {
            public let input: [String: String]
            public let tokens: Int
        }

        public let resolver: String
        /// The token files the resolver uses, in the order of first use.
        public let files: [String]
        /// The modifiers, in resolution order.
        public let modifiers: [ResolverDocument.Modifier]
        /// Every input, in the order of `Resolution.inputs`.
        public let combinations: [Combination]

        /// One line per context of a modifier, such as `theme=light: 6 combinations, 612 tokens`. Without a
        /// modifier of that name, per context of the first modifier; without modifiers, one line.
        public func summary(by modifier: String = "theme") -> [String] {
            guard let chosen = modifiers.first(where: { $0.name == modifier }) ?? modifiers.first else {
                return [line(nil, combinations)]
            }
            return chosen.contextNames.map { context in
                line("\(chosen.name)=\(context)", combinations.filter { $0.input[chosen.name] == context })
            }
        }

        private func line(_ label: String?, _ combinations: [Combination]) -> String {
            let counts = combinations.map(\.tokens)
            let tokens =
                counts.min() == counts.max() ? "\(counts.first ?? 0)" : "\(counts.min() ?? 0)–\(counts.max() ?? 0)"
            let text = "\(combinations.count) combination\(combinations.count == 1 ? "" : "s"), \(tokens) tokens"
            return label.map { "\($0): \(text)" } ?? text
        }
    }

    /// The token files under a directory, as paths that start with the directory, sorted; none if it does not
    /// exist.
    public static func files(in directory: String) throws -> [String] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory), isDirectory.boolValue
        else { return [] }
        let prefix = directory.hasSuffix("/") ? directory : directory + "/"
        return try FileManager.default.contentsOfDirectory(atPath: directory).sorted().flatMap { name -> [String] in
            let path = prefix + name
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            if isDirectory.boolValue { return try files(in: path) }
            return name.hasSuffix(fileSuffix) ? [path] : []
        }
    }

    /// Checks a resolver and the token files in its directory.
    ///
    /// The stages run in order, each only when the earlier ones pass: the resolver and each token file it uses
    /// (reader, then schema); the modifiers' overlaps (`Resolution`); token files in the resolver's directory that it
    /// does not use; every input (`Resolution.resolveAll`).
    /// - Throws: `TokenErrors` with every problem of the first stage that has any.
    public static func run(resolverFile: String, schemaDirectory: String? = TokenSchema.defaultDirectory) throws
        -> Report
    {
        let resolution = try Resolution(resolverFile: resolverFile, schemaDirectory: schemaDirectory)
        let slash = resolverFile.lastIndex(of: "/")
        let directory = slash.map { String(resolverFile[..<$0]) } ?? "."
        let used = Set(resolution.files)
        let unused = try files(in: directory).filter { path in
            !used.contains(path) && !used.contains(path.hasPrefix("./") ? String(path.dropFirst(2)) : path)
        }
        guard unused.isEmpty else {
            throw TokenErrors(
                unused.map {
                    TokenError(
                        .resolver, source: $0, path: .root,
                        "\(resolverFile) does not use this file: add it to a set or a context, or delete it")
                })
        }
        let all = try resolution.resolveAll()
        return Report(
            resolver: resolverFile, files: resolution.files,
            modifiers: resolution.modifiers,
            combinations: all.map { Report.Combination(input: $0.input, tokens: $0.tokens.count) })
    }
}

extension TokenPath {
    /// The token or group a JSON Pointer into a token file points into: its names up to the first `$`-property.
    public init(pointer: String) {
        let names = pointer.split(separator: "/", omittingEmptySubsequences: false).dropFirst()
            .map { $0.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~") }
        self.init(Array(names.prefix { !$0.hasPrefix("$") }))
    }
}
