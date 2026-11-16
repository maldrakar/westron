import Foundation

/// The token generator for Apple (#14, decisions/0010): from the semantic tokens of every theme it writes
///
/// - `WestronTokens/Generated/Tokens.swift`: the values as plain Swift, with no imports, for shared code and its
///   WebAssembly build;
/// - `WestronUI/Tokens.xcassets`: a colorset per semantic color with its four themes, and the watch's dark ones;
/// - `WestronUI/Generated/Tokens+SwiftUI.swift`: the `public` SwiftUI statics, which call the hand-written adapters
///   in `WestronUI/TokenAdapters.swift`.
///
/// Themes switch at run time through the colorsets. Density and platform switch nothing yet: a value that differs
/// by either fails generation until a token needs that mechanism.
public struct AppleTokens: Generator {
    public let name = "tokens-apple"
    /// The resolver, relative to the repository root.
    public let resolverFile: String

    public init(resolverFile: String = TokenCheck.defaultResolver) {
        self.resolverFile = resolverFile
    }

    public static let tokensFile = "platforms/apple/Sources/WestronTokens/Generated/Tokens.swift"
    public static let swiftUIFile = "platforms/apple/Sources/WestronUI/Generated/Tokens+SwiftUI.swift"
    public static let assetCatalog = "platforms/apple/Sources/WestronUI/Tokens.xcassets"

    public var ownedDirectories: [String] {
        [Self.tokensFile, Self.swiftUIFile].map { String($0[..<$0.lastIndex(of: "/")!]) } + [Self.assetCatalog]
    }

    public func run() throws -> [GeneratedFile] {
        try Self.files(for: Resolution(resolverFile: resolverFile))
    }

    /// The tokens of a resolution cannot be generated for Apple.
    public struct Failure: Error, Equatable, CustomStringConvertible {
        public let problems: [String]

        public init(_ problems: [String]) {
            self.problems = problems
        }

        public var description: String {
            (["the Apple tokens cannot be generated (\(problems.count) problem\(problems.count == 1 ? "" : "s")):"]
                + problems.map { "  " + $0 }).joined(separator: "\n")
        }
    }

    /// The generated files for a resolution, in a fixed order: the WestronTokens file, the SwiftUI file, the asset
    /// catalog's `Contents.json`, then a colorset per color in token order.
    /// - Throws: `Failure` with every problem found.
    public static func files(for resolution: Resolution) throws -> [GeneratedFile] {
        let model = try AppleTokenModel(resolution)
        let catalogColors =
            model.allColors.map { entry -> AppleTokenModel.Color in
                switch entry {
                case .plain(let index): model.colors[index]
                case .category(let caseName, let role):
                    model.categories!.categories.first { $0.caseName == caseName }!.colors.first {
                        $0.members.last?.name == role
                    }!
                }
            }
        return [
            GeneratedFile(path: tokensFile, contents: AppleTokensSwift.tokens(model)),
            GeneratedFile(path: swiftUIFile, contents: AppleTokensSwift.swiftUI(model)),
            GeneratedFile(path: assetCatalog + "/Contents.json", contents: AssetCatalog.root(model.resolver)),
        ]
            + catalogColors.map { color in
                GeneratedFile(
                    path: "\(assetCatalog)/\(color.path).colorset/Contents.json",
                    contents: AssetCatalog.colorset(color, resolver: model.resolver))
            }
    }
}
