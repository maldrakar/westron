import Foundation
import Testing
import WestronTools

@Suite("Apple token generator")
struct AppleTokensTests {
    @Test("writes the WestronTokens values, the SwiftUI accessors, the catalog and a colorset per color, in order")
    func files() throws {
        let catalog = AppleTokens.assetCatalog
        #expect(
            try AppleFixture.generate().map(\.path) == [
                AppleTokens.tokensFile,
                AppleTokens.swiftUIFile,
                "\(catalog)/Contents.json",
                "\(catalog)/color.text.primary.colorset/Contents.json",
                "\(catalog)/color.background.vivid.colorset/Contents.json",
                "\(catalog)/color.category.blue.background.colorset/Contents.json",
                "\(catalog)/color.category.blue.on-fill.colorset/Contents.json",
                "\(catalog)/color.category.light-green.background.colorset/Contents.json",
                "\(catalog)/color.category.light-green.on-fill.colorset/Contents.json",
            ])
        #expect(
            AppleTokens().ownedDirectories == [
                "platforms/apple/Sources/WestronTokens/Generated", "platforms/apple/Sources/WestronUI/Generated",
                "platforms/apple/Sources/WestronUI/Tokens.xcassets",
            ])
    }

    @Test("the WestronTokens file: plain values with no imports, semantic tokens only, the list colors as an enum")
    func tokensFile() throws {
        let contents = AppleFixture.file(try AppleFixture.generate(), AppleTokens.tokensFile)
        #expect(contents == Self.tokens)
        #expect(contents?.split(separator: "\n").contains { $0.hasPrefix("import ") } == false)
        #expect(contents?.contains("ink") == false, "primitives stay out")
    }

    @Test("the SwiftUI file: a static per length and motion that calls the hand-written adapter, an enum per group")
    func swiftUIFile() throws {
        #expect(AppleFixture.file(try AppleFixture.generate(), AppleTokens.swiftUIFile) == Self.swiftUI)
    }

    @Test("a colorset: the four themes in 8-bit sRGB, and the dark one for the watch")
    func colorset() throws {
        let files = try AppleFixture.generate()
        let catalog = AppleTokens.assetCatalog
        #expect(AppleFixture.file(files, "\(catalog)/Contents.json") == Self.catalog)
        #expect(AppleFixture.file(files, "\(catalog)/color.text.primary.colorset/Contents.json") == Self.colorset)
    }

    @Test("a color outside sRGB is written in Display P3, the same numbers in Swift and in the colorset")
    func displayP3() throws {
        let files = try AppleFixture.generate()
        let colorset = try #require(
            AppleFixture.file(files, "\(AppleTokens.assetCatalog)/color.background.vivid.colorset/Contents.json"))
        #expect(colorset.contains(#""color-space" : "display-p3""#))
        #expect(colorset.contains(#""green" : "0.800""#))
        #expect(!colorset.contains("srgb"))
        let tokens = try #require(AppleFixture.file(files, AppleTokens.tokensFile))
        #expect(tokens.contains("light: Westron.RGB(.displayP3, red: 0, green: 0.8, blue: 0.3),"))
    }

    @Test("an sRGB color whose components do not give its hex fails rather than drift from the hex")
    func hexMismatch() {
        let light = AppleFixture.light.replacingOccurrences(
            of: #""components": [0, 0, 1], "alpha": 0.15"#,
            with: ##""components": [0, 0, 1], "alpha": 0.15, "hex": "#0000FE""##)
        #expect(
            AppleFixture.problems(["light.tokens.json": light]) == [
                "color.category.blue.background: theme light: the components convert to #0000FF, but the hex "
                    + "fallback is #0000FE; the 8-bit value would not be the token's"
            ])
    }

    @Test("westron's tokens generate for Apple: every semantic color has a colorset, the list colors are an enum")
    func realTokens() throws {
        let resolver = repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path
        let files = try AppleTokens.files(for: Resolution(resolverFile: resolver))
        let colorsets = files.map(\.path).filter { $0.hasSuffix(".colorset/Contents.json") }
        #expect(colorsets.contains("\(AppleTokens.assetCatalog)/color.text.secondary.colorset/Contents.json"))
        #expect(colorsets.filter { $0.contains("/color.category.") }.count == 12 * 6)
        let tokens = try #require(AppleFixture.file(files, AppleTokens.tokensFile))
        #expect(tokens.contains("public enum Category: String, CaseIterable, Sendable {"))
        #expect(!tokens.contains("color.neutral."), "primitives stay out, also the ramps the theme contexts merge in")
        // The control heights: macOS's pointer sizes behind #if, the touch sizes of iOS and watchOS under #else.
        for (name, pointer, touch) in [("s", 24, 32), ("m", 32, 44), ("l", 40, 52)] {
            let declaration = "public static let \(name) = Westron.Dimension(name: \"size.control.\(name)\", value: "
            #expect(tokens.contains("#if os(macOS)\n") && tokens.contains(declaration + "\(pointer))"))
            #expect(tokens.contains(declaration + "\(touch))"))
        }
        #expect(!tokens.contains("os(watchOS)"), "watchOS takes the iOS values")
        #expect(tokens.contains(#"public static let disabled = Westron.Number(name: "opacity.disabled", value: 0.4)"#))
    }

    @Test("the same input gives the same bytes")
    func deterministic() throws {
        #expect(try AppleFixture.generate() == AppleFixture.generate())
        let reordered = AppleFixture.files().merging(
            ["compact.tokens.json": "{ }", "macos.tokens.json": "{\n}"]) { $1 }
        #expect(try AppleTokens.files(for: resolution(reordered)) == AppleFixture.generate())
    }

    @Test("a value that differs by density fails: Apple has no density mechanism yet")
    func densityGuard() {
        let compact = #"{ "space": { "100": { "$type": "dimension", "$value": { "value": 6, "unit": "px" } } } }"#
        #expect(
            AppleFixture.problems(["compact.tokens.json": compact]) == [
                "space.100: differs between theme=light, density=regular, platform=ios and theme=light, "
                    + "density=compact, platform=ios; values that differ by density are not generated for Apple yet"
            ])
    }

    @Test("a density compares with its own platform: a platform's value is not a density's difference")
    func densityOnEachPlatform() throws {
        let macos = #"{ "space": { "100": { "$type": "dimension", "$value": { "value": 6, "unit": "px" } } } }"#
        #expect(throws: Never.self) { try AppleFixture.generate(["macos.tokens.json": macos]) }
    }

    @Test("a length or a number that differs by platform is declared per value behind #if os(...), iOS's under #else")
    func platformValues() throws {
        let resolver = AppleFixture.resolver.replacingOccurrences(
            of: #""watchos": []"#, with: #""watchos": [{ "$ref": "watchos.tokens.json" }]"#)
        let macos = #"{ "space": { "100": { "$type": "dimension", "$value": { "value": 6, "unit": "px" } } } }"#
        let watchos = ##"""
            {
              "space": { "100": { "$type": "dimension", "$value": { "value": 6, "unit": "px" } } },
              "stroke": {
                "thin": {
                  "$type": "dimension", "$value": { "value": 2, "unit": "px" }, "$description": "Rules and dividers."
                }
              }
            }
            """##
        let files = try AppleFixture.generate([
            "r.resolver.json": resolver, "macos.tokens.json": macos, "watchos.tokens.json": watchos,
        ])
        let tokens = try #require(AppleFixture.file(files, AppleTokens.tokensFile))
        #expect(
            tokens.contains(
                """
                    #if os(macOS) || os(watchOS)
                        /// The token `space.100`.
                        public static let space100 = Westron.Dimension(name: "space.100", value: 6)
                    #else
                        /// The token `space.100`.
                        public static let space100 = Westron.Dimension(name: "space.100", value: 8)
                    #endif

                """))
        #expect(
            tokens.contains(
                """
                        #if os(watchOS)
                            /// Rules and dividers.
                            public static let thin = Westron.Dimension(name: "stroke.thin", value: 2)
                        #else
                            /// Rules and dividers.
                            public static let thin = Westron.Dimension(name: "stroke.thin", value: 1)
                        #endif

                """))
        #expect(tokens.contains("        space100,\n        stroke.thin,\n"), "`all` names each token once")
        #expect(AppleFixture.file(files, AppleTokens.swiftUIFile) == Self.swiftUI, "SwiftUI reads the value as built")
    }

    @Test(
        "only the value of a length or a number differs by platform: a color, a description, a token one platform has")
    func platformGuard() {
        let macos = ##"""
            {
              "stroke": { "thin": { "$type": "dimension", "$value": { "value": 0.5, "unit": "px" } } },
              "space": { "200": { "$type": "dimension", "$value": { "value": 16, "unit": "px" } } },
              "color": {
                "edge": {
                  "$type": "color", "$value": { "colorSpace": "srgb", "components": [0, 0, 0], "hex": "#000000" },
                  "$description": "An edge."
                }
              }
            }
            """##
        // A color in the semantic set, with the same description on macOS and another value.
        let semantic = AppleFixture.semantic.replacingOccurrences(
            of: #""space": {"#,
            with: ##"""
                "color": {
                  "edge": {
                    "$type": "color", "$value": { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#FFFFFF" },
                    "$description": "An edge."
                  }
                },
                "space": {
                """##)
        let differs =
            "differs between theme=light, density=regular, platform=ios and theme=light, density=regular, "
            + "platform=macos; on Apple only a length or a number differs by platform, and only in its value"
        #expect(
            Set(AppleFixture.problems(["macos.tokens.json": macos, "semantic.tokens.json": semantic])) == [
                "stroke.thin: \(differs)", "color.edge: \(differs)", "space.200: \(differs)",
            ])
    }

    @Test("a number is a Westron.Number, its name keeping its group, and a Double in SwiftUI")
    func numbers() throws {
        let semantic = AppleFixture.semantic.replacingOccurrences(
            of: #""space": {"#,
            with: #"""
                "opacity": {
                  "$type": "number",
                  "disabled": { "$value": 0.4, "$description": "A disabled control." }
                },
                "space": {
                """#)
        let files = try AppleFixture.generate(["semantic.tokens.json": semantic])
        let tokens = try #require(AppleFixture.file(files, AppleTokens.tokensFile))
        #expect(
            tokens.hasSuffix(
                """
                extension Westron.Number {
                    /// The numbers `opacity.*`.
                    public enum opacity {
                        /// A disabled control.
                        public static let disabled = Westron.Number(name: "opacity.disabled", value: 0.4)
                    }

                    /// Every number in token order.
                    public static let all: [Westron.Number] = [opacity.disabled]
                }

                """))
        let swiftUI = try #require(AppleFixture.file(files, AppleTokens.swiftUIFile))
        #expect(
            swiftUI.hasSuffix(
                """
                extension Double {
                    /// The numbers `opacity.*` as Double.
                    public enum opacity {
                        /// A disabled control.
                        public static var disabled: Double {
                            Double(Westron.Number.opacity.disabled)
                        }
                    }
                }

                """))
        let zero = AppleFixture.semantic.replacingOccurrences(
            of: #""space": {"#, with: #""zero": { "$type": "number", "$value": 0 }, "space": {"#)
        #expect(
            AppleFixture.problems(["semantic.tokens.json": zero]) == [
                "zero: its Swift name Double.zero collides with a member the type already has; rename the token"
            ])
    }

    @Test("a token other than a color or a shadow that differs by theme fails: only those switch with the theme")
    func themeGuard() {
        let dark = AppleFixture.dark.replacingOccurrences(
            of: #""color": {"#,
            with: #""space": { "100": { "$type": "dimension", "$value": { "value": 10, "unit": "px" } } }, "color": {"#)
        #expect(
            AppleFixture.problems(["dark.tokens.json": dark]) == [
                "space.100: differs between theme light and theme dark; on Apple only colors and shadows switch with "
                    + "the theme"
            ])
    }

    @Test("a shadow switches with the theme, layer by layer; a transparent layer is left out, so a theme casts none")
    func shadowByTheme() throws {
        let layer =
            #"{ "color": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": ALPHA }, "#
            + #""offsetX": { "value": 0, "unit": "px" }, "offsetY": { "value": 1, "unit": "px" }, "#
            + #""blur": { "value": 2, "unit": "px" }, "spread": { "value": 0, "unit": "px" } }"#
        let dark = AppleFixture.dark.replacingOccurrences(
            of: #""color": {"#,
            with: #""shadow": { "$type": "shadow", "raised": { "$value": ["#
                + layer.replacingOccurrences(of: "ALPHA", with: "0") + #"] } }, "color": {"#)
        let light = AppleFixture.light.replacingOccurrences(
            of: #""color": {"#,
            with: #""shadow": { "$type": "shadow", "raised": { "$value": ["#
                + layer.replacingOccurrences(of: "ALPHA", with: "0.06") + ", "
                + layer.replacingOccurrences(of: "ALPHA", with: "0.1") + #"] } }, "color": {"#)
        let files = try AppleTokens.files(
            for: resolution(
                AppleFixture.files().merging(["light.tokens.json": light, "dark.tokens.json": dark]) { $1 }))
        let tokens = try #require(AppleFixture.file(files, AppleTokens.tokensFile))
        #expect(tokens.contains("        dark: [],\n"))
        #expect(
            tokens.contains("Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.1), x: 0, y: 1, blur: 2, spread: 0)"))
    }

    @Test("a font westron ships needs a plain family name and a system family to fall back on")
    func shippedFontFamily() {
        let semantic = AppleFixture.semantic.replacingOccurrences(
            of: #""fontFamily": ["Onest", "system-ui"]"#, with: #""fontFamily": ["Onest"]"#)
        #expect(
            AppleFixture.problems(["semantic.tokens.json": semantic]) == [
                "typography.heading.large: font family Onest needs a plain name and a system family after it to fall "
                    + "back on, such as [\"Onest\", \"system-ui\"] (decisions/0011)"
            ])
    }

    @Test("a name that collides with SwiftUI's or with another token's fails, naming both")
    func collisions() {
        let semantic = AppleFixture.semantic
            .replacingOccurrences(of: #""label": {"#, with: #""font": {"#)
            .replacingOccurrences(of: #""row-leave": {"#, with: #""linear": {"#)
            .replacingOccurrences(
                of: #""space": {"#,
                with: #""pi": { "$type": "dimension", "$value": { "value": 3, "unit": "px" } }, "space": {"#)
        func theme(_ file: String) -> String {
            file.replacingOccurrences(
                of: #""text": {"#,
                with: #"""
                    "primary": { "$value": "{color.paper}" },
                    "tint": { "$value": "{color.ink}" },
                    "chart": { "1": { "$value": "{color.ink}" } },
                    "chart1": { "$value": "{color.ink}" },
                    "name": { "x": { "$value": "{color.ink}" } },
                    "text": {
                    """#)
        }
        let problems = AppleFixture.problems([
            "semantic.tokens.json": semantic, "light.tokens.json": theme(AppleFixture.light),
            "dark.tokens.json": theme(AppleFixture.dark),
        ])
        let collides = "collides with a member the type already has; rename the token"
        #expect(
            Set(problems) == [
                "color.primary: its Swift name Westron.Color.primary \(collides)",
                "color.tint: its Swift name Westron.Color.tint \(collides)",
                "color.name: its Swift name Westron.Color.name \(collides)",
                "color.chart1 and color.chart.1 have the same Swift name Westron.Color.chart1",
                "typography.font: its Swift name Westron.TextRole.font \(collides)",
                "motion.linear: its Swift name Animation.linear \(collides)",
                "pi: its Swift name CGFloat.pi \(collides)",
            ])
    }

    @Test("a group is an enum and may share its name with a ShapeStyle of SwiftUI; a color may not")
    func groupNames() throws {
        // The fixture's `color.background.vivid` is in a group named like SwiftUI's `.background`.
        let tokens = try #require(AppleFixture.file(try AppleFixture.generate(), AppleTokens.tokensFile))
        #expect(tokens.contains("    public enum background {\n"))
        #expect(tokens.contains("        public static let vivid = Westron.Color(\n"))
    }

    @Test("a name follows the path, a member per segment, without the group the Swift type names")
    func names() throws {
        func names(_ path: TokenPath, dropping group: String?) throws -> [String] {
            try SwiftName.members(path, dropping: group).map(\.name)
        }
        #expect(try names("color.text.on-accent", dropping: "color") == ["text", "onAccent"])
        #expect(try names("color.status.danger.on-fill", dropping: "color") == ["status", "danger", "onFill"])
        #expect(try names("typography.heading.large", dropping: "typography") == ["heading", "large"])
        #expect(try names("motion.row-leave", dropping: "motion") == ["rowLeave"])
        #expect(try names("space.100", dropping: nil) == ["space100"], "a step joins its ladder")
        #expect(try names("color.chart.1", dropping: "color") == ["chart1"])
        #expect(try names("radius.card", dropping: nil) == ["radius", "card"])
        #expect(try names("brand.accent", dropping: "color") == ["brand", "accent"], "another group stays")
        #expect(
            try SwiftName.members("color.status.danger.text", dropping: "color").map(\.path) == [
                "color.status", "color.status.danger", "color.status.danger.text",
            ])
        #expect(try SwiftName.members("space.100", dropping: nil).map(\.path) == ["space.100"])
        #expect(SwiftName.declared("default") == "`default`", "a keyword is declared in backticks")
        #expect(SwiftName.declared("canvas") == "canvas")
    }

    @Test("a segment that is not lowercase kebab-case, a leading digit or a word Swift cannot use as a member fails")
    func invalidNames() {
        func problem(_ path: TokenPath, dropping group: String?) -> String? {
            do {
                _ = try SwiftName.members(path, dropping: group)
                return nil
            } catch {
                return (error as? SwiftName.Problem)?.message
            }
        }
        #expect(
            problem("color.Text", dropping: "color") == "\"Text\" is not a lowercase kebab-case name (decisions/0010)")
        #expect(
            problem("color.text_x", dropping: "color")
                == "\"text_x\" is not a lowercase kebab-case name (decisions/0010)")
        #expect(problem("color.100", dropping: "color") == "the Swift name 100 would start with a digit")
        #expect(problem("motion.self", dropping: "motion") == "the Swift name self cannot be a member")
        #expect(problem("motion.default", dropping: "motion") == nil, "a keyword is declared in backticks")
        #expect(problem("color", dropping: "color") == "no name is left after the group the type names")
    }

    static let tokens = #"""
        // Generated from r.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate again
        // (decisions/0010).
        //
        // The values of westron's semantic tokens as plain Swift, with no imports, so that shared code and its WebAssembly
        // build can use them; their types are in Westron.swift, their SwiftUI accessors in WestronUI. A group of tokens is an
        // enum named after it, so `color.background.canvas` is `Westron.Color.background.canvas`, and each token is made on its
        // first use.

        extension Westron.Color {
            /// The colors `color.text.*`.
            public enum text {
                /// Words and glyphs.
                ///
                /// Use for: body text, titles. Avoid: Words on the accent: use text.on-accent.
                public static let primary = Westron.Color(
                    name: "color.text.primary",
                    light: Westron.RGB(hex: 0x1F1D1A),
                    dark: Westron.RGB(hex: 0xFFFFFF),
                    lightHighContrast: Westron.RGB(hex: 0x000000),
                    darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
                    backgrounds: [["color.background.vivid"], ["color.category.blue.background", "color.background.vivid"]])
            }

            /// The colors `color.background.*`.
            public enum background {
                /// A fill brighter than sRGB can show.
                public static let vivid = Westron.Color(
                    name: "color.background.vivid",
                    light: Westron.RGB(.displayP3, red: 0, green: 0.8, blue: 0.3),
                    dark: Westron.RGB(.displayP3, red: 0.1, green: 0.9, blue: 0.4),
                    lightHighContrast: Westron.RGB(.displayP3, red: 0, green: 0.8, blue: 0.3),
                    darkHighContrast: Westron.RGB(.displayP3, red: 0.1, green: 0.9, blue: 0.4))
            }

            /// Every semantic color in token order, the list colors included.
            public static let all: [Westron.Color] = [
                text.primary,
                background.vivid,
                Westron.Category.blue.background,
                Westron.Category.blue.onFill,
                Westron.Category.lightGreen.background,
                Westron.Category.lightGreen.onFill,
            ]
        }

        extension Westron {
            /// The list colors, `color.category.<name>.<role>`. A product keeps a list's color by the case's raw value, its
            /// name in the tokens, and reads it back with `init(rawValue:)`.
            public enum Category: String, CaseIterable, Sendable {
                case blue
                case lightGreen = "light-green"

                /// The tile under a glyph: the list color, translucent.
                public var background: Westron.Color {
                    switch self {
                    case .blue: Self.blueBackground
                    case .lightGreen: Self.lightGreenBackground
                    }
                }

                /// The mark on a fill.
                public var onFill: Westron.Color {
                    switch self {
                    case .blue: Self.blueOnFill
                    case .lightGreen: Self.lightGreenOnFill
                    }
                }

                /// The colors of the category, one per role, in token order.
                public var colors: [Westron.Color] { [background, onFill] }

                /// The tile under a glyph: the list color blue, translucent.
                private static let blueBackground = Westron.Color(
                    name: "color.category.blue.background",
                    light: Westron.RGB(hex: 0x0000FF, opacity: 0.15),
                    dark: Westron.RGB(hex: 0x0000CC, opacity: 0.24),
                    lightHighContrast: Westron.RGB(hex: 0x0000FF, opacity: 0.15),
                    darkHighContrast: Westron.RGB(hex: 0x0000CC, opacity: 0.24))

                /// The mark on a fill.
                private static let blueOnFill = Westron.Color(
                    name: "color.category.blue.on-fill",
                    light: Westron.RGB(hex: 0xFFFFFF),
                    dark: Westron.RGB(hex: 0xFFFFFF),
                    lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
                    darkHighContrast: Westron.RGB(hex: 0xFFFFFF))

                /// The tile under a glyph: the list color light-green, translucent.
                private static let lightGreenBackground = Westron.Color(
                    name: "color.category.light-green.background",
                    light: Westron.RGB(hex: 0x009900, opacity: 0.15),
                    dark: Westron.RGB(hex: 0x00CC00, opacity: 0.24),
                    lightHighContrast: Westron.RGB(hex: 0x009900, opacity: 0.15),
                    darkHighContrast: Westron.RGB(hex: 0x00CC00, opacity: 0.24))

                /// The mark on a fill.
                private static let lightGreenOnFill = Westron.Color(
                    name: "color.category.light-green.on-fill",
                    light: Westron.RGB(hex: 0x1F1D1A),
                    dark: Westron.RGB(hex: 0x1F1D1A),
                    lightHighContrast: Westron.RGB(hex: 0x1F1D1A),
                    darkHighContrast: Westron.RGB(hex: 0x1F1D1A))
            }
        }

        extension Westron.TextRole {
            /// The text roles `typography.heading.*`.
            public enum heading {
                /// The title of a screen.
                public static let large = Westron.TextRole(
                    name: "typography.heading.large",
                    textStyle: .largeTitle,
                    design: .default,
                    weight: .bold,
                    font: "Onest-Bold",
                    size: 34,
                    lineHeight: 1.206,
                    letterSpacing: 0)
            }

            /// Main text.
            public static let label = Westron.TextRole(
                name: "typography.label",
                textStyle: .body,
                design: .default,
                weight: .regular,
                font: nil,
                size: 17,
                lineHeight: 1.294,
                letterSpacing: 0)

            /// Every text role in token order.
            public static let all: [Westron.TextRole] = [
                heading.large,
                label,
            ]
        }

        extension Westron.Transition {
            /// Something popping into place.
            public static let pop = Westron.Transition(
                name: "motion.pop",
                duration: 0.45,
                delay: 0,
                curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
                spring: Spring(duration: 0.45, bounce: 0))

            /// A done row leaving.
            public static let rowLeave = Westron.Transition(
                name: "motion.row-leave",
                duration: 0.32,
                delay: 0.7,
                curve: Curve(x1: 0.42, y1: 0, x2: 1, y2: 1),
                spring: nil)

            /// Every motion in token order.
            public static let all: [Westron.Transition] = [
                pop,
                rowLeave,
            ]
        }

        extension Westron.Shadow {
            /// A control raised off what it stands on.
            public static let raised = Westron.Shadow(
                name: "shadow.raised",
                light: [
                    Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.12), x: 0, y: 5, blur: 24, spread: 0),
                ],
                dark: [
                    Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.12), x: 0, y: 5, blur: 24, spread: 0),
                ],
                lightHighContrast: [
                    Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.12), x: 0, y: 5, blur: 24, spread: 0),
                ],
                darkHighContrast: [
                    Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.12), x: 0, y: 5, blur: 24, spread: 0),
                ])

            /// Every shadow in token order.
            public static let all: [Westron.Shadow] = [raised]
        }

        extension Westron.Dimension {
            /// The token `space.100`.
            public static let space100 = Westron.Dimension(name: "space.100", value: 8)

            /// The lengths `stroke.*`.
            public enum stroke {
                /// Rules and dividers.
                public static let thin = Westron.Dimension(name: "stroke.thin", value: 1)
            }

            /// Every dimension in token order.
            public static let all: [Westron.Dimension] = [
                space100,
                stroke.thin,
            ]
        }

        """#

    static let swiftUI = #"""
        // Generated from r.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate again
        // (decisions/0010).
        //
        // The public SwiftUI accessors of westron's lengths, numbers and motions. Each calls an adapter in TokenAdapters.swift
        // with a value from WestronTokens: `CGFloat.radius.card` is `CGFloat(Westron.Dimension.radius.card)`,
        // `Double.opacity.disabled` is `Double(Westron.Number.opacity.disabled)`. Colors and text roles need none: a view
        // passes `Westron.Color` to the overloads in TokenAdapters.swift, `.foregroundStyle(.text.primary)`, and a role to
        // `.textRole(.body.strong)`.

        import SwiftUI
        import WestronTokens

        extension Animation {
            /// Something popping into place.
            public static var pop: Animation {
                Animation(Westron.Transition.pop)
            }

            /// A done row leaving.
            public static var rowLeave: Animation {
                Animation(Westron.Transition.rowLeave)
            }
        }

        extension CGFloat {
            /// The token `space.100`.
            public static var space100: CGFloat {
                CGFloat(Westron.Dimension.space100)
            }

            /// The lengths `stroke.*` in points.
            public enum stroke {
                /// Rules and dividers.
                public static var thin: CGFloat {
                    CGFloat(Westron.Dimension.stroke.thin)
                }
            }
        }

        """#

    static let catalog = #"""
        {
          "info" : {
            "author" : "westron",
            "comment" : "Generated from r.resolver.json by tools/westron generate. Do not edit.",
            "version" : 1
          }
        }

        """#

    static let colorset = #"""
        {
          "info" : {
            "author" : "westron",
            "comment" : "Generated from r.resolver.json by tools/westron generate. Do not edit.",
            "version" : 1
          },
          "colors" : [
            {
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0x1A",
                  "green" : "0x1D",
                  "red" : "0x1F"
                }
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0xFF",
                  "green" : "0xFF",
                  "red" : "0xFF"
                }
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "contrast",
                  "value" : "high"
                }
              ],
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0x00",
                  "green" : "0x00",
                  "red" : "0x00"
                }
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                },
                {
                  "appearance" : "contrast",
                  "value" : "high"
                }
              ],
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0xFF",
                  "green" : "0xFF",
                  "red" : "0xFF"
                }
              },
              "idiom" : "universal"
            },
            {
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0xFF",
                  "green" : "0xFF",
                  "red" : "0xFF"
                }
              },
              "idiom" : "watch"
            }
          ]
        }

        """#
}
