import Foundation
import Testing
import WestronTools

/// A contract with the parts the API generator reads; each test replaces some of them.
private func contractYAML(
    id: String = "button",
    status: String = "approved",
    options: String = """
      variant: { type: enum, values: [primary, secondary], description: Every use names its variant. }
      size: { type: enum, values: [s, m, l], default: m }
      role: { type: enum, values: [default, destructive], default: default }
      iconOnly: { type: bool, default: false, description: Only the icon. The label stays accessible. }
    """,
    states: String = "[hover, pressed, loading]",
    apple: String = """
        strategy: style-on-system-control
        base: SwiftUI.Button
        systemOptions: { role: SwiftUI.ButtonRole }
        watchos:
          options: { size: [m] }
          fallback: { size: m }
          states: [pressed, loading]
    """
) -> String {
    """
    id: \(id)
    status: \(status)
    consumers: [todo-app/list-screen]
    options:
    \(options)
    states: \(states)
    accessibility: { role: button }
    platforms:
      apple:
    \(apple)
      web: { status: planned }
      linux: { status: planned }
      android: { status: planned }

    """
}

private let source = "spec/components/button/button.spec.yaml"

/// An Apple entry with no system options and no restrictions.
private let plainApple = """
            strategy: style-on-system-control
            base: SwiftUI.Button
    """

/// The generated file for a contract, or nil when the generator skips it.
private func generated(_ yaml: String) throws -> GeneratedFile? {
    try AppleComponents.file(for: ComponentContract(yaml: yaml, source: source), source: source)
}

private func swift(_ yaml: String) throws -> String {
    try #require(try generated(yaml)).contents
}

/// The message of the problem generation throws.
private func failure(_ yaml: String) -> String? {
    do {
        _ = try generated(yaml)
        return nil
    } catch {
        return "\(error)"
    }
}

@Suite("Apple component API generator")
struct AppleComponentsTests {
    @Test("a Button-shaped contract generates its enums, the overload, the controlSize mapping, fallbacks and states")
    func wholeFile() throws {
        let file = try #require(try generated(contractYAML()))
        #expect(file.path == "platforms/apple/Sources/WestronUI/Generated/Button+Contract.swift")
        #expect(file.contents == Self.button)
    }

    @Test("names: <Component><Option> in UpperCamelCase, cases the values as written, a keyword in backticks")
    func names() throws {
        let contents = try swift(
            contractYAML(
                id: "list-row",
                options: """
                      emphasisLevel: { type: enum, values: [default, strongerStill], default: default }
                    """,
                states: "[]", apple: plainApple))
        #expect(contents.contains("public enum ListRowEmphasisLevel: String, CaseIterable, Sendable {"))
        #expect(contents.contains("    case `default`\n    case strongerStill\n"))
        #expect(contents.contains("Applies westron's ListRow style"))
        #expect(contents.contains("listRowStyle") == false, "the modifier comes from the base control")
        #expect(
            contents.contains(
                "    public func buttonStyle(emphasisLevel: ListRowEmphasisLevel = .default) -> some View {\n"
                    + "        buttonStyle(ListRowVariantStyle(emphasisLevel: emphasisLevel))\n"))
        #expect(!contents.contains("enum ListRowState"), "no states, no state enum")
    }

    @Test("the variant has no default, so it is a required unlabeled argument; other options are labeled")
    func optionsWithoutDefault() throws {
        let contents = try swift(
            contractYAML(
                options: """
                      tone: { type: enum, values: [calm, loud] }
                      variant: { type: enum, values: [primary, secondary], default: secondary }
                      density: { type: enum, values: [tight, loose], default: loose }
                    """, apple: plainApple))
        #expect(
            contents.contains(
                """
                    public func buttonStyle(
                        _ variant: ButtonVariant = .secondary, tone: ButtonTone, density: ButtonDensity = .loose
                    ) -> some View {

                """), "a signature longer than a line puts its parameters on a line of their own")
        #expect(
            contents.contains("buttonStyle(ButtonVariantStyle(tone: tone, variant: variant, density: density))"))
        #expect(try swift(contractYAML()).contains("buttonStyle(_ variant: ButtonVariant, size: ButtonSize? = nil"))
    }

    @Test("a bool option is a labeled Bool with the contract's default")
    func boolOption() throws {
        #expect(try swift(contractYAML()).contains("iconOnly: Bool = false) -> some View {"))
        let yaml = contractYAML().replacingOccurrences(
            of: "iconOnly: { type: bool, default: false", with: "iconOnly: { type: bool, default: true")
        #expect(try swift(yaml).contains("iconOnly: Bool = true) -> some View {"))
    }

    @Test(
        "an option in systemOptions gets no enum and no argument; without the field, ButtonRole would shadow SwiftUI's")
    func systemOptions() throws {
        let contents = try swift(contractYAML())
        #expect(!contents.contains("ButtonRole:"))
        #expect(!contents.contains("role:"))
        #expect(contents.contains("The option `role` is the system's own `SwiftUI.ButtonRole`"))
        let without = contractYAML().replacingOccurrences(
            of: "systemOptions: { role: SwiftUI.ButtonRole }", with: "")
        #expect(
            failure(without)
                == "spec/components/button/button.spec.yaml: options.role: ButtonRole would shadow SwiftUI's ButtonRole: "
                + "if the option is the system's own API on Apple, name it in platforms.apple.systemOptions "
                + "(spec/conventions.md)")
        // The field, not the name, decides: another option given to the system disappears too.
        let iconOnly = contractYAML().replacingOccurrences(
            of: "{ role: SwiftUI.ButtonRole }", with: "{ role: SwiftUI.ButtonRole, iconOnly: SwiftUI.LabelStyle }")
        #expect(!(try swift(iconOnly)).contains("iconOnly: Bool"))
        let unknown = contractYAML().replacingOccurrences(of: "{ role: SwiftUI.ButtonRole }", with: "{ kind: X }")
        #expect(failure(unknown)?.contains("platforms.apple.systemOptions.kind: no option kind") == true)
    }

    @Test("a value an OS drops draws its fallback there; Apple's fallback first, then the OS's")
    func fallbacks() throws {
        #expect(
            try swift(contractYAML()).contains(
                """
                    var offered: ButtonSize {
                        #if os(watchOS)
                            switch self {
                            case .s: return .m
                            case .m: return .m
                            case .l: return .m
                            }
                        #else
                            return self
                        #endif
                    }
                """))
        let chained = contractYAML(
            apple: """
                    strategy: style-on-system-control
                    base: SwiftUI.Button
                    systemOptions: { role: SwiftUI.ButtonRole }
                    options: { size: [s, m] }
                    fallback: { size: m }
                    macos:
                      options: { size: [s] }
                      fallback: { size: { m: s } }
                """)
        let contents = try swift(chained)
        #expect(contents.contains("on macOS, m → s, l → s; on watchOS, l → m"))
        #expect(contents.contains("on iOS, l → m; on macOS, m → s, l → s; on watchOS, l → m"))
        #expect(contents.contains("        #if os(iOS)\n"))
        #expect(contents.contains("        #elseif os(macOS)\n"))
        #expect(contents.contains("        #elseif os(watchOS)\n"))
        #expect(contents.contains("            case .l: return .s\n"))
        let missing = contractYAML().replacingOccurrences(of: "fallback: { size: m }", with: "")
        #expect(failure(missing)?.contains("platforms.apple.watchos.options.size: drops s with no fallback") == true)
    }

    @Test("controlSize maps mini and small to s, regular to the default, large and extraLarge to l")
    func controlSize() throws {
        #expect(
            try swift(contractYAML()).contains(
                """
                        case .mini: self = .s
                        case .small: self = .s
                        case .regular: self = .m
                        case .large: self = .l
                        case .extraLarge: self = .l
                        @unknown default: self = .m
                """))
        // A size the contract lacks takes the default, so removing a size reaches the hand-written switch.
        let noLarge = contractYAML().replacingOccurrences(
            of: "values: [s, m, l], default: m", with: "values: [s, m], default: m"
        )
        .replacingOccurrences(of: "options: { size: [m] }", with: "")
        .replacingOccurrences(of: "fallback: { size: m }", with: "")
        #expect(!noLarge.contains("size: [m]"))
        #expect(try swift(noLarge).contains("        case .large: self = .m\n        case .extraLarge: self = .m\n"))
        let noDefault = contractYAML().replacingOccurrences(
            of: "values: [s, m, l], default: m", with: "values: [s, m, l]")
        #expect(failure(noDefault)?.contains("options.size: the size needs a default") == true)
    }

    @Test("the declared states, with the ones an OS does not enter")
    func states() throws {
        let contents = try swift(contractYAML())
        #expect(contents.contains("enum ButtonState: String, CaseIterable, Sendable {\n    case hover\n"))
        #expect(contents.contains("            case .hover: return false\n            case .pressed: return true\n"))
        #expect(contents.contains("Not entered: on watchOS, hover"))
    }

    @Test("drafts, own components and a planned Apple are skipped")
    func skipped() throws {
        #expect(try generated(contractYAML(status: "draft")) == nil)
        #expect(try generated(contractYAML(status: "stable")) != nil)
        #expect(try generated(contractYAML(apple: "        strategy: own-component")) == nil)
        #expect(try generated(contractYAML(apple: "        status: planned")) == nil)
    }

    @Test("the same contracts give the same bytes; files come in the contracts' sorted order")
    func deterministic() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "westron-components-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        for id in ["toggle", "button", "chip"] {
            let folder = directory.appendingPathComponent(id)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let yaml = contractYAML(id: id, status: id == "chip" ? "draft" : "approved")
            try yaml.write(to: folder.appendingPathComponent("\(id).spec.yaml"), atomically: true, encoding: .utf8)
        }
        let generator = AppleComponents(
            directory: directory.path,
            schemaFile: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)
        let first = try generator.run()
        #expect(
            first.map(\.path) == ["Button", "Toggle"].map { "\(AppleComponents.outputDirectory)/\($0)+Contract.swift" })
        #expect(try generator.run() == first)
        #expect(generator.ownedDirectories == ["platforms/apple/Sources/WestronUI/Generated"])
    }

    @Test("a contract that fails the schema fails generation")
    func invalidContract() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "westron-components-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let folder = directory.appendingPathComponent("button")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try contractYAML(status: "ready").write(
            to: folder.appendingPathComponent("button.spec.yaml"), atomically: true, encoding: .utf8)
        let generator = AppleComponents(
            directory: directory.path,
            schemaFile: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)
        #expect(throws: AppleComponents.Problems.self) { try generator.run() }
    }

    @Test("westron's Button contract generates ButtonVariant and ButtonSize, and no ButtonRole")
    func realContract() throws {
        let file = repositoryRoot.appendingPathComponent(source).path
        let contract = try ComponentContract(yaml: String(contentsOfFile: file, encoding: .utf8), source: source)
        let contents = try #require(try AppleComponents.file(for: contract, source: source)).contents
        #expect(contents.contains("public enum ButtonVariant: String, CaseIterable, Sendable {\n    case primary\n"))
        #expect(contents.contains("public enum ButtonSize: String, CaseIterable, Sendable {\n    case s\n"))
        #expect(!contents.contains("enum ButtonRole"))
        #expect(
            contents.contains(
                "public func buttonStyle(_ variant: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false)"))
    }

    static let button = """
        // Generated from spec/components/button/button.spec.yaml by `tools/westron generate`. Do not edit: change the contract
        // and generate again (spec/conventions.md).
        //
        // Button's API from its contract: the enums of its options, the overload of `buttonStyle` that products call, which
        // applies the hand-written `ButtonVariantStyle` (decisions/0001), and the tables that style reads.

        import SwiftUI

        /// Button's option `variant`, from its contract.
        ///
        /// Every use names its variant.
        public enum ButtonVariant: String, CaseIterable, Sendable {
            case primary
            case secondary
        }

        /// Button's option `size`, from its contract.
        ///
        /// A call without `size:` takes the size from `controlSize`: mini and small → s, regular → m, large and extraLarge → l.
        /// An explicit `size:` wins.
        public enum ButtonSize: String, CaseIterable, Sendable {
            case s
            case m
            case l
        }

        extension View {
            /// Applies westron's Button style, from its contract, to the system's `Button` in this view:
            /// `.buttonStyle(.primary, size: .m)`.
            ///
            /// The option `role` is the system's own `SwiftUI.ButtonRole`, which the style reads from the control.
            ///
            /// - Parameters:
            ///   - variant: See `ButtonVariant`. Every call names one.
            ///   - size: The size; without it, the size comes from `controlSize` (`ButtonSize.init(_:)`).
            ///   - iconOnly: Only the icon. By default `false`.
            public func buttonStyle(_ variant: ButtonVariant, size: ButtonSize? = nil, iconOnly: Bool = false) -> some View {
                buttonStyle(ButtonVariantStyle(variant: variant, size: size, iconOnly: iconOnly))
            }
        }

        extension ButtonSize {
            /// The size of a call without `size:`, from the environment's `controlSize`: mini and small → s, regular → m, large
            /// and extraLarge → l (spec/conventions.md). SwiftUI cannot tell an unset `controlSize` from `regular`, so a call
            /// with neither takes the contract's default.
            init(_ controlSize: ControlSize) {
                switch controlSize {
                case .mini: self = .s
                case .small: self = .s
                case .regular: self = .m
                case .large: self = .l
                case .extraLarge: self = .l
                @unknown default: self = .m
                }
            }
        }

        extension ButtonVariant {
            /// The variant the current OS draws for this one (the contract's `platforms` block). Every Apple OS offers every
            /// variant, so it is the value itself.
            var offered: ButtonVariant {
                self
            }
        }

        extension ButtonSize {
            /// The size the current OS draws for this one (the contract's `platforms` block). Where an OS does not offer a
            /// value, the fallback the contract names: on watchOS, s → m, l → m.
            var offered: ButtonSize {
                #if os(watchOS)
                    switch self {
                    case .s: return .m
                    case .m: return .m
                    case .l: return .m
                    }
                #else
                    return self
                #endif
            }
        }

        /// The states of a Button in its contract, in its order. The system control has some of them; the others are set
        /// through the environment (spec/conventions.md).
        ///
        /// Not entered: on watchOS, hover (the contract's `platforms` block).
        enum ButtonState: String, CaseIterable, Sendable {
            case hover
            case pressed
            case loading

            /// Whether the current OS ever enters the state.
            var isEntered: Bool {
                #if os(watchOS)
                    switch self {
                    case .hover: return false
                    case .pressed: return true
                    case .loading: return true
                    }
                #else
                    return true
                #endif
            }
        }

        """
}
