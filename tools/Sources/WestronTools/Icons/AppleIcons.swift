/// The icon generator for Apple (decisions/0011): from the icon registry it writes
///
/// - `WestronTokens/Generated/Icons.swift`: `Westron.Icon`, a `String`-backed enum of the names in the registry's
///   order, with the fallback for an unknown name; no SF Symbol names, because that module is platform-neutral;
/// - `WestronUI/Generated/Icons+SwiftUI.swift`: `Westron.Icon.systemName`, the SF Symbol of each icon, which the
///   hand-written `Image(_:)` and `Label(_:icon:)` in `WestronUI/TokenAdapters.swift` draw.
///
/// It is a generator of its own, not a part of `AppleTokens`, because it reads another source: an invalid registry
/// fails only this generator, and each one is tested with a fixture of its own source. It writes into the same
/// generated directories, which both own.
public struct AppleIcons: Generator {
    public let name = "icons-apple"
    /// The registry, relative to the repository root.
    public let registryFile: String

    public init(registryFile: String = IconRegistry.defaultFile) {
        self.registryFile = registryFile
    }

    /// The Swift type of an icon, which `tokens(_:source:)` declares: an option whose values are the registry's names
    /// takes it as its type (`AppleComponents.Own`), as a token option takes its group's accessor.
    public static let iconType = "Westron.Icon"
    /// The member that names the icon drawn for an unknown name, and the one that gives an icon's SF Symbol; the agent
    /// context names them too (`ContextNames`).
    static let fallbackMember = "fallback"
    static let systemNameMember = "systemName"

    public static let tokensFile = "platforms/apple/Sources/WestronTokens/Generated/Icons.swift"
    public static let swiftUIFile = "platforms/apple/Sources/WestronUI/Generated/Icons+SwiftUI.swift"

    public var ownedDirectories: [String] {
        [Self.tokensFile, Self.swiftUIFile].map { String($0[..<$0.lastIndex(of: "/")!]) }
    }

    public func run() throws -> [GeneratedFile] {
        Self.files(for: try IconRegistry.load(file: registryFile), source: registryFile)
    }

    /// The generated files for a registry: the WestronTokens file, then the WestronUI file. `source` is the
    /// registry's path, which the headers name.
    public static func files(for registry: IconRegistry, source: String) -> [GeneratedFile] {
        [
            GeneratedFile(path: tokensFile, contents: tokens(registry, source: source)),
            GeneratedFile(path: swiftUIFile, contents: swiftUI(registry, source: source)),
        ]
    }

    typealias Doc = AppleTokenModel.Doc

    /// A doc comment of several paragraphs, a blank comment line between them.
    static func paragraphs(_ paragraphs: [String], indent: Int) -> [String] {
        let blank = String(repeating: "    ", count: indent) + "///"
        return Array(
            paragraphs.map { AppleTokensSwift.doc(Doc(description: $0), indent: indent) }.joined(separator: [blank]))
    }

    /// What generated the file from what, then what it holds.
    static func header(_ source: String, _ purpose: String) -> [String] {
        let width = AppleTokensSwift.lineLength - 3
        let origin =
            "Generated from \(source) by `tools/westron generate`. Do not edit: change the registry and generate "
            + "again (decisions/0011)."
        return AppleTokensSwift.wrap(origin, width: width).map { "// " + $0 } + ["//"]
            + AppleTokensSwift.wrap(purpose, width: width).map { "// " + $0 }
    }

    static func tokens(_ registry: IconRegistry, source: String) -> String {
        var out = header(
            source,
            "westron's icons by name, with no imports, so that shared code and its WebAssembly build can keep and read "
                + "them; the glyph each one draws on Apple is in WestronUI.")
        out += ["", "extension Westron {"]
        out += paragraphs(
            [
                "An icon by its westron name, which says what the glyph draws, not what it means on a screen "
                    + "(decisions/0011).",
                "A product keeps an icon by its raw value and reads it back with `init(rawValue:)`. A name this "
                    + "version does not know, such as one a newer version wrote, reads as nil, and the product draws "
                    + "`fallback` instead: `Westron.Icon(rawValue: name) ?? .fallback`. A released name is never "
                    + "renamed or removed.",
                "On Apple, WestronUI draws an icon as its SF Symbol: `Icon(icon)`, `Label(\"Rename\", icon: .pen)`.",
            ], indent: 1)
        out.append("    public enum \(iconType.split(separator: ".").last!): String, CaseIterable, Sendable {")
        for icon in registry.icons {
            out += AppleTokensSwift.doc(Doc(description: icon.description), indent: 2)
            out += ["        case \(icon.name)", ""]
        }
        out += AppleTokensSwift.doc(
            Doc(
                description:
                    "The icon to draw for a name this version does not know: `\(registry.fallback)`."),
            indent: 2)
        out.append("        public static let \(fallbackMember) = \(iconType).\(registry.fallback)")
        out += ["    }", "}"]
        return out.joined(separator: "\n") + "\n"
    }

    static func swiftUI(_ registry: IconRegistry, source: String) -> String {
        var out = header(
            source,
            "The SF Symbol of every westron icon. `Image(_:)` and `Label(_:icon:)` in TokenAdapters.swift draw it.")
        out += ["", "import WestronTokens", "", "extension Westron.Icon {"]
        out += AppleTokensSwift.doc(
            Doc(
                description:
                    "The name of the SF Symbol the icon draws, for the SwiftUI calls that take `systemImage:`, such "
                    + "as `Button(_:systemImage:action:)`. Each symbol exists on iOS 17, macOS 14 and watchOS 10 "
                    + "(decisions/0011)."),
            indent: 1)
        out += ["    public var \(systemNameMember): String {", "        switch self {"]
        for icon in registry.icons {
            out.append("        case .\(icon.name): \(AppleTokensSwift.literal(icon.apple))")
        }
        out += ["        }", "    }", "}"]
        return out.joined(separator: "\n") + "\n"
    }
}
