import Foundation
import Testing
import WestronTools

@Suite("Apple icon generator")
struct AppleIconsTests {
    static func generate() throws -> [GeneratedFile] {
        AppleIcons.files(for: try IconRegistry(yaml: iconRegistryFixture, source: "icons.yaml"), source: "icons.yaml")
    }

    @Test("writes the WestronTokens enum, then the WestronUI symbols, into the generated directories")
    func files() throws {
        #expect(try Self.generate().map(\.path) == [AppleIcons.tokensFile, AppleIcons.swiftUIFile])
        #expect(
            AppleIcons().ownedDirectories == [
                "platforms/apple/Sources/WestronTokens/Generated", "platforms/apple/Sources/WestronUI/Generated",
            ])
    }

    @Test("the WestronTokens file: the names in the registry's order and the fallback, with no imports and no symbols")
    func tokensFile() throws {
        let contents = try Self.generate()[0].contents
        #expect(contents == Self.tokens)
        #expect(!contents.split(separator: "\n").contains { $0.hasPrefix("import ") })
        #expect(!contents.contains("macwindow"), "SF Symbols stay out of the platform-neutral module")
    }

    @Test("the WestronUI file: the SF Symbol of every icon")
    func swiftUIFile() throws {
        #expect(try Self.generate()[1].contents == Self.swiftUI)
    }

    @Test("westron's registry generates an enum of 36 icons with bullets as the fallback")
    func realRegistry() throws {
        let file = repositoryRoot.appendingPathComponent(IconRegistry.defaultFile).path
        let files = AppleIcons.files(for: try IconRegistry.load(file: file), source: IconRegistry.defaultFile)
        #expect(files[0].contents.split(separator: "\n").filter { $0.hasPrefix("        case ") }.count == 36)
        #expect(files[0].contents.contains("public static let fallback = Westron.Icon.bullets"))
        #expect(files[1].contents.contains(#"case .newWindow: "macwindow.badge.plus""#))
    }

    @Test("an invalid registry fails generation with its problems")
    func invalidRegistry() {
        #expect(throws: IconRegistry.Problems.self) {
            try AppleIcons(registryFile: "no/such/icons.yaml").run()
        }
    }

    static let tokens = #"""
        // Generated from icons.yaml by `tools/westron generate`. Do not edit: change the registry and generate again
        // (decisions/0011).
        //
        // westron's icons by name, with no imports, so that shared code and its WebAssembly build can keep and read them; the
        // glyph each one draws on Apple is in WestronUI.

        extension Westron {
            /// An icon by its westron name, which says what the glyph draws, not what it means on a screen (decisions/0011).
            ///
            /// A product keeps an icon by its raw value and reads it back with `init(rawValue:)`. A name this version does not
            /// know, such as one a newer version wrote, reads as nil, and the product draws `fallback` instead:
            /// `Westron.Icon(rawValue: name) ?? .fallback`. A released name is never renamed or removed.
            ///
            /// On Apple, WestronUI draws an icon as its SF Symbol: `Icon(icon)`, `Label("Rename", icon: .pen)`.
            public enum Icon: String, CaseIterable, Sendable {
                /// An open tray.
                case tray

                /// Lines of text, each with a dot before it.
                case bullets

                /// A window with a plus badge.
                case newWindow

                /// The icon to draw for a name this version does not know: `bullets`.
                public static let fallback = Westron.Icon.bullets
            }
        }

        """#

    static let swiftUI = #"""
        // Generated from icons.yaml by `tools/westron generate`. Do not edit: change the registry and generate again
        // (decisions/0011).
        //
        // The SF Symbol of every westron icon. `Image(_:)` and `Label(_:icon:)` in TokenAdapters.swift draw it.

        import WestronTokens

        extension Westron.Icon {
            /// The name of the SF Symbol the icon draws, for the SwiftUI calls that take `systemImage:`, such as
            /// `Button(_:systemImage:action:)`. Each symbol exists on iOS 17, macOS 14 and watchOS 10 (decisions/0011).
            public var systemName: String {
                switch self {
                case .tray: "tray"
                case .bullets: "list.bullet"
                case .newWindow: "macwindow.badge.plus"
                }
            }
        }

        """#
}
