import Foundation
import Testing
import WestronTools

@Suite("SwiftUI type names")
struct SwiftUITypesTests {
    @Test(
        "an interface's public top-level types, after attributes and modifiers; nested, internal and underscored left out"
    )
    func parsing() {
        let text = """
            import SwiftUICore
            @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
            public struct Button<Label> : SwiftUICore.View where Label : SwiftUICore.View {
              public struct Nested {
              }
            }
            @available(*, deprecated, message: "Use (this) \\"instead\\"") @frozen public enum MenuOrder : Swift.Hashable {
            @_Concurrency.MainActor @preconcurrency public protocol ButtonStyle {
            final public class Store {
            nonisolated public struct Isolated {
            public typealias Alias = Swift.Int
            open class Subclassable {
            internal struct Hidden {
            struct Implicit {
            public struct _Underscored {
            public func buttonStyle<S>(_ style: S) -> some SwiftUICore.View where S : SwiftUI.PrimitiveButtonStyle
            extension SwiftUICore.View {
            public var body: some View { get }
            """
        #expect(
            SwiftUIInterface.typeNames(text) == [
                "Button", "MenuOrder", "ButtonStyle", "Store", "Isolated", "Alias", "Subclassable",
            ])
    }

    @Test("the checked-in list has SwiftUI's types, and none of the names Button generates")
    func checkedIn() {
        for name in [
            "Button", "ButtonRole", "ButtonToggleStyle", "ButtonMenuStyle", "MenuOrder", "ControlSize", "Color",
        ] {
            #expect(SwiftUITypes.names.contains(name), "\(name)")
        }
        for name in ["ButtonVariant", "ButtonSize", "ButtonState", "ButtonVariantStyle"] {
            #expect(!SwiftUITypes.names.contains(name), "\(name)")
        }
    }

    #if os(macOS)
        /// The `Contents/Developer` of the Xcode in `.xcode-version`: `DEVELOPER_DIR` when it is that one, as
        /// `tools/apple/xcode-env.sh` sets it, or else the one in /Applications.
        private static func pinnedXcode(_ pin: String) -> String? {
            func version(_ developer: String) -> String? {
                let plist = URL(fileURLWithPath: developer).deletingLastPathComponent().appendingPathComponent(
                    "version.plist")
                guard let data = try? Data(contentsOf: plist),
                    let values = try? PropertyListSerialization.propertyList(from: data, format: nil)
                        as? [String: Any]
                else { return nil }
                return values["CFBundleShortVersionString"] as? String
            }
            var candidates: [String] = []
            if let developer = ProcessInfo.processInfo.environment["DEVELOPER_DIR"] { candidates.append(developer) }
            let applications = (try? FileManager.default.contentsOfDirectory(atPath: "/Applications")) ?? []
            candidates += applications.sorted().filter { $0.hasPrefix("Xcode") && $0.hasSuffix(".app") }.map {
                "/Applications/\($0)/Contents/Developer"
            }
            return candidates.first { version($0) == pin }
        }

        @Test("SwiftUITypes.swift is not stale for the pinned Xcode, and every SystemStyles modifier exists in SwiftUI")
        func notStale() throws {
            let pin = try String(
                contentsOf: repositoryRoot.appendingPathComponent(".xcode-version"), encoding: .utf8
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            let developer = try #require(
                Self.pinnedXcode(pin), "Xcode \(pin) from .xcode-version is neither DEVELOPER_DIR nor in /Applications")
            var names: Set<String> = []
            var interfaces: [String] = []
            for sdk in SwiftUIInterface.sdks {
                for module in SwiftUIInterface.modules {
                    let path = SwiftUIInterface.interfacePath(
                        developer: developer, platform: sdk.platform, sdk: sdk.sdk, interface: sdk.interface,
                        module: module)
                    let text = try String(contentsOfFile: path, encoding: .utf8)
                    names.formUnion(SwiftUIInterface.typeNames(text))
                    interfaces.append(text)
                }
            }
            let expected = SwiftUIInterface.source(names: names, xcode: pin)
            let file = repositoryRoot.appendingPathComponent("tools/Sources/WestronTools/Contracts/SwiftUITypes.swift")
            if ProcessInfo.processInfo.environment["WESTRON_REFRESH_SWIFTUI_TYPES"] == "1" {
                try expected.write(to: file, atomically: true, encoding: .utf8)
            } else {
                let current = try String(contentsOf: file, encoding: .utf8)
                #expect(
                    current == expected,
                    "SwiftUITypes.swift is stale for Xcode \(pin): run `\(SwiftUIInterface.refreshCommand)`")
            }
            for (base, entry) in SystemStyles.byBase {
                #expect(
                    interfaces.contains {
                        $0.contains("func \(entry.modifier)<") || $0.contains("func \(entry.modifier)(")
                    },
                    "\(base): SwiftUI declares no \(entry.modifier)")
            }
        }
    #endif
}
