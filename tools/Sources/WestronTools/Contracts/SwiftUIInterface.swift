/// SwiftUI's public type names, read from its module interfaces, so that the API generator can refuse a generated
/// `<Component><Option>` that would shadow one of them in every file that imports WestronUI (#62).
///
/// The tools build on Linux, where there is no SDK, so the generator reads the checked-in list,
/// `SwiftUITypes.swift`, and only a test on macOS reads the interfaces of the Xcode in `.xcode-version`: it fails while
/// the list is stale and rewrites it when `WESTRON_REFRESH_SWIFTUI_TYPES=1` (`SwiftUITypesTests`, tools/README.md).
/// Parsing the text is Foundation-free and is tested on every platform.
public enum SwiftUIInterface {
    /// The modules whose interfaces the list reads: `import SwiftUI` re-exports SwiftUICore, where many of its types
    /// moved in OS 26.
    public static let modules = ["SwiftUI", "SwiftUICore"]

    /// The SDKs whose interfaces the list reads, with the interface file of each: the generated enum is one for every
    /// Apple OS, so a name taken on any of them is taken.
    public static let sdks: [(platform: String, sdk: String, interface: String)] = [
        ("MacOSX", "MacOSX.sdk", "arm64e-apple-macos.swiftinterface"),
        ("iPhoneOS", "iPhoneOS.sdk", "arm64e-apple-ios.swiftinterface"),
        ("WatchOS", "WatchOS.sdk", "arm64e-apple-watchos.swiftinterface"),
    ]

    /// The path of a module's interface for one SDK, under an Xcode's `Contents/Developer`.
    public static func interfacePath(
        developer: String, platform: String, sdk: String, interface: String, module: String
    )
        -> String
    {
        "\(developer)/Platforms/\(platform).platform/Developer/SDKs/\(sdk)/System/Library/Frameworks/"
            + "\(module).framework/Modules/\(module).swiftmodule/\(interface)"
    }

    private static let declarations: Set<Substring> = ["struct", "enum", "class", "protocol", "actor", "typealias"]
    private static let modifiers: Set<Substring> = [
        "public", "open", "package", "internal", "fileprivate", "private", "final", "indirect", "nonisolated",
    ]

    /// The names of the public types an interface declares at the top level (`struct`, `enum`, `class`, `protocol`,
    /// `actor`, `typealias`): a declaration that starts a line, after its attributes and modifiers, one of which is
    /// `public` or `open`. Nested types are indented, so they are left out, as are names that start with `_`.
    public static func typeNames(_ text: String) -> Set<String> {
        var names: Set<String> = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let first = line.first, first.isLetter || first == "@" else { continue }
            if let name = typeName(line) { names.insert(name) }
        }
        return names
    }

    private static func isIdentifier(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
    }

    private static func typeName(_ line: Substring) -> String? {
        var rest = line
        var isPublic = false
        while true {
            rest = rest.drop { $0 == " " }
            if rest.first == "@" {
                rest = rest.dropFirst().drop { isIdentifier($0) || $0 == ":" || $0 == "." }
                if rest.first == "(" { rest = skipParentheses(rest) }
                continue
            }
            let word = rest.prefix(while: isIdentifier)
            if declarations.contains(word) {
                guard isPublic else { return nil }
                let name = rest.dropFirst(word.count).drop { $0 == " " }.prefix(while: isIdentifier)
                return name.isEmpty || name.hasPrefix("_") ? nil : String(name)
            }
            guard modifiers.contains(word) else { return nil }
            if word == "public" || word == "open" { isPublic = true }
            rest = rest.dropFirst(word.count)
            // `nonisolated(unsafe)` and the like.
            if rest.first == "(" { rest = skipParentheses(rest) }
        }
    }

    /// The text after the parenthesized group it starts with, quoted strings included.
    private static func skipParentheses(_ text: Substring) -> Substring {
        var depth = 0
        var quoted = false
        var escaped = false
        for index in text.indices {
            let character = text[index]
            if quoted {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    quoted = false
                }
                continue
            }
            switch character {
            case "\"": quoted = true
            case "(": depth += 1
            case ")":
                depth -= 1
                if depth == 0 { return text[text.index(after: index)...] }
            default: break
            }
        }
        return text[text.endIndex...]
    }

    /// The command that refreshes `SwiftUITypes.swift`, for its header and for messages.
    public static let refreshCommand =
        "source tools/apple/xcode-env.sh && WESTRON_REFRESH_SWIFTUI_TYPES=1 swift test --package-path tools "
        + "--filter SwiftUITypesTests"

    /// The Swift source of `SwiftUITypes.swift` for the names read from an Xcode's interfaces.
    public static func source(names: Set<String>, xcode: String) -> String {
        let width = AppleTokensSwift.lineLength - 3
        let header =
            "Generated from the \(modules.joined(separator: " and ")) module interfaces of Xcode \(xcode), the macOS, "
            + "iOS and watchOS SDKs, by `\(refreshCommand)`. Do not edit: refresh it when .xcode-version changes."
        var out = AppleTokensSwift.wrap(header, width: width).map { "// " + $0 }
        out += [
            "",
            "/// Every public type SwiftUI declares at the top level, on any Apple OS: a generated `<Component><Option>` must",
            "/// not take one of these names (`SwiftUIInterface`).",
            "public enum SwiftUITypes {",
            "    /// The Xcode whose interfaces the list was read from.",
            "    public static let xcode = \"\(xcode)\"",
            "",
            "    public static let names: Set<String> = [",
        ]
        var line = "       "
        for name in names.sorted() {
            let item = " \"\(name)\","
            if line.count + item.count > AppleTokensSwift.lineLength {
                out.append(line)
                line = "       "
            }
            line += item
        }
        if line != "       " { out.append(line) }
        out += ["    ]", "}"]
        return out.joined(separator: "\n") + "\n"
    }
}
