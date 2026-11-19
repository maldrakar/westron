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

    @Test("an interface's static styles, by protocol, unquoted; those unavailable on every westron OS left out")
    func styleNames() {
        let text = """
            @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
            extension SwiftUI.PrimitiveButtonStyle where Self == SwiftUI.PlainButtonStyle {
              @export(implementation) @_Concurrency.MainActor @preconcurrency public static var plain: SwiftUI.PlainButtonStyle {
                get { .init() }
              }
            }
            @available(watchOS, unavailable)
            @available(visionOS, unavailable)
            extension SwiftUI.ToggleStyle where Self == SwiftUI.CheckboxToggleStyle {
              nonisolated public static var checkbox: SwiftUI.CheckboxToggleStyle {
              }
            }
            @available(iOS 13.0, macOS 10.15, tvOS 18.0, watchOS 6.0, *)
            extension SwiftUI.ToggleStyle where Self == SwiftUI.SwitchToggleStyle {
              nonisolated public static var `switch`: SwiftUI.SwitchToggleStyle {
              }
            }
            @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
            extension SwiftUICore.PrimitiveButtonStyle where Self == SwiftUI.GlassButtonStyle {
              nonisolated public static func glass(_ glass: SwiftUICore.Glass) -> Self
            }
            @available(tvOS 14.0, *)
            @available(iOS, unavailable)
            @available(macOS, unavailable)
            @available(watchOS, unavailable)
            extension SwiftUI.PrimitiveButtonStyle where Self == SwiftUI.CardButtonStyle {
              public static var card: SwiftUI.CardButtonStyle {
              }
            }
            @available(*, unavailable)
            extension SwiftUI.ToggleStyle where Self == SwiftUI.GoneToggleStyle {
              public static var gone: SwiftUI.GoneToggleStyle { get }
            }
            extension SwiftUI.TextFieldStyle where Self == SwiftUI.PlainTextFieldStyle {
              public static var plain: SwiftUI.PlainTextFieldStyle {
              }
            }
            extension SwiftUI.ToggleStyle {
              public static var notAStyle: Swift.Int { get }
            }
            """
        #expect(
            SwiftUIInterface.styleNames(of: ["ButtonStyle", "PrimitiveButtonStyle"], in: text) == ["plain", "glass"])
        #expect(SwiftUIInterface.styleNames(of: ["ToggleStyle"], in: text) == ["checkbox", "switch"])
        #expect(SwiftUIInterface.styleNames(of: ["TextFieldStyle"], in: text) == ["plain"])
    }

    @Test("SystemStyles: every base names its style protocols, and lists each style once")
    func systemStylesEntries() {
        for (base, entry) in SystemStyles.byBase {
            #expect(!entry.protocols.isEmpty, "\(base)")
            #expect(Set(entry.styles).count == entry.styles.count, "\(base)")
            #expect(entry.modifier.hasSuffix("Style"), "\(base)")
        }
        #expect(SystemStyles.byBase["SwiftUI.TextField"]?.modifier == "textFieldStyle")
        #expect(SystemStyles.byBase["SwiftUI.Toggle"]?.modifier == "toggleStyle")
        #expect(SystemStyles.withoutStyle == ["SwiftUI.Image", "SwiftUI.Text"])
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
                // The styles a westron value would shadow: every static style of the protocols on iOS, macOS or
                // watchOS, in any of the SDKs.
                let declared = interfaces.reduce(into: Set<String>()) {
                    $0.formUnion(SwiftUIInterface.styleNames(of: Set(entry.protocols), in: $1))
                }
                #expect(
                    Set(entry.styles) == declared,
                    "\(base): SystemStyles lists \(entry.styles.sorted()), SwiftUI declares \(declared.sorted())")
            }
            // A base without a style has no `<control>Style` modifier: SwiftUI.Text has no `textStyle`.
            for base in SystemStyles.withoutStyle {
                let control = base.split(separator: ".").last.map(String.init) ?? base
                let modifier = control.prefix(1).lowercased() + control.dropFirst() + "Style"
                #expect(
                    !interfaces.contains { $0.contains("func \(modifier)<") || $0.contains("func \(modifier)(") },
                    "\(base): SwiftUI declares \(modifier), so it takes a style: move it to SystemStyles.byBase")
            }
        }
    #endif
}
