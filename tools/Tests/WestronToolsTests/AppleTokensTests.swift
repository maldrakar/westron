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

    @Test("the SwiftUI file: a static per token that calls the hand-written adapter")
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
                    + "density=compact, platform=ios; values that differ by density or platform are not generated for "
                    + "Apple yet"
            ])
    }

    @Test("a value that differs by platform fails, and so does a token only one platform has")
    func platformGuard() {
        let macos = ##"""
            {
              "stroke": { "thin": { "$type": "dimension", "$value": { "value": 0.5, "unit": "px" } } },
              "space": { "200": { "$type": "dimension", "$value": { "value": 16, "unit": "px" } } }
            }
            """##
        let problems = AppleFixture.problems(["macos.tokens.json": macos])
        #expect(
            problems == [
                "stroke.thin: differs between theme=light, density=regular, platform=ios and theme=light, "
                    + "density=regular, platform=macos; values that differ by density or platform are not generated "
                    + "for Apple yet",
                "space.200: differs between theme=light, density=regular, platform=ios and theme=light, "
                    + "density=regular, platform=macos; values that differ by density or platform are not generated "
                    + "for Apple yet",
            ])
    }

    @Test("a token other than a color that differs by theme fails: only colors switch with the theme")
    func themeGuard() {
        let dark = AppleFixture.dark.replacingOccurrences(
            of: #""color": {"#,
            with: #""space": { "100": { "$type": "dimension", "$value": { "value": 10, "unit": "px" } } }, "color": {"#)
        #expect(
            AppleFixture.problems(["dark.tokens.json": dark]) == [
                "space.100: differs between theme light and theme dark; on Apple only colors switch with the theme"
            ])
    }

    @Test("a name that collides with SwiftUI's or with another token's fails, naming both")
    func collisions() {
        let semantic = AppleFixture.semantic
            .replacingOccurrences(of: #""label": {"#, with: #""body": {"#)
            .replacingOccurrences(of: #""row-leave": {"#, with: #""linear": {"#)
            .replacingOccurrences(
                of: #""space": {"#,
                with: #""pi": { "$type": "dimension", "$value": { "value": 3, "unit": "px" } }, "space": {"#)
        func theme(_ file: String) -> String {
            file.replacingOccurrences(
                of: #""text": {"#,
                with: #"""
                    "primary": { "$value": "{color.paper}" },
                    "text-secondary": { "$value": "{color.ink}" },
                    "text": { "secondary": { "$value": "{color.ink}" },
                    """#)
        }
        let problems = AppleFixture.problems([
            "semantic.tokens.json": semantic, "light.tokens.json": theme(AppleFixture.light),
            "dark.tokens.json": theme(AppleFixture.dark),
        ])
        let collides = "collides with a member the type already has; rename the token"
        #expect(
            Set(problems) == [
                "color.primary: its Swift name Color.primary \(collides)",
                "color.text.secondary and color.text-secondary have the same Swift name Color.textSecondary",
                "typography.body: its Swift name Font.body \(collides)",
                "motion.linear: its Swift name Animation.linear \(collides)",
                "pi: its Swift name CGFloat.pi \(collides)",
            ])
    }

    @Test("names in lowerCamelCase from the path, without the group the Swift type names")
    func names() throws {
        #expect(try SwiftName.member("color.text.on-accent", dropping: "color") == "textOnAccent")
        #expect(
            try SwiftName.member("color.category.blue.background-subtle", dropping: "color")
                == "categoryBlueBackgroundSubtle")
        #expect(try SwiftName.member("typography.heading.large", dropping: "typography") == "headingLarge")
        #expect(try SwiftName.member("motion.row-leave", dropping: "motion") == "rowLeave")
        #expect(try SwiftName.member("space.100", dropping: nil) == "space100")
        #expect(try SwiftName.member("radius.150", dropping: nil) == "radius150")
        #expect(try SwiftName.member("stroke.thin", dropping: nil) == "strokeThin")
        #expect(try SwiftName.member("brand.accent", dropping: "color") == "brandAccent", "another group stays")
    }

    @Test("a segment that is not lowercase kebab-case, a leading digit or a keyword fails")
    func invalidNames() {
        func problem(_ path: TokenPath, dropping group: String?) -> String? {
            do {
                _ = try SwiftName.member(path, dropping: group)
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
        #expect(problem("motion.default", dropping: "motion") == "the Swift name default is a Swift keyword")
        #expect(problem("color", dropping: "color") == "no name is left after the group the type names")
    }

    static let tokens = #"""
        // Generated from r.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate again
        // (decisions/0010).
        //
        // The values of westron's semantic tokens as plain Swift, with no imports, so that shared code and its WebAssembly
        // build can use them; their types are in Westron.swift, their SwiftUI accessors in WestronUI.

        extension Westron.Color {
            /// Words and glyphs.
            ///
            /// Use for: body text, titles. Avoid: Words on the accent: use text.on-accent.
            public static let textPrimary = Westron.Color(
                name: "color.text.primary",
                light: Westron.RGB(hex: 0x1F1D1A),
                dark: Westron.RGB(hex: 0xFFFFFF),
                lightHighContrast: Westron.RGB(hex: 0x000000),
                darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
                backgrounds: [["color.background.vivid"], ["color.category.blue.background", "color.background.vivid"]])

            /// A fill brighter than sRGB can show.
            public static let backgroundVivid = Westron.Color(
                name: "color.background.vivid",
                light: Westron.RGB(.displayP3, red: 0, green: 0.8, blue: 0.3),
                dark: Westron.RGB(.displayP3, red: 0.1, green: 0.9, blue: 0.4),
                lightHighContrast: Westron.RGB(.displayP3, red: 0, green: 0.8, blue: 0.3),
                darkHighContrast: Westron.RGB(.displayP3, red: 0.1, green: 0.9, blue: 0.4))

            /// Every semantic color in token order, the list colors included.
            public static let all: [Westron.Color] = [
                textPrimary,
                backgroundVivid,
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
            /// The title of a screen.
            public static let headingLarge = Westron.TextRole(
                name: "typography.heading.large",
                textStyle: .largeTitle,
                design: .rounded,
                weight: .heavy,
                size: 34,
                lineHeight: 1.206,
                letterSpacing: 0)

            /// Main text.
            public static let label = Westron.TextRole(
                name: "typography.label",
                textStyle: .body,
                design: .default,
                weight: .regular,
                size: 17,
                lineHeight: 1.294,
                letterSpacing: 0)

            /// Every text role in token order.
            public static let all: [Westron.TextRole] = [
                headingLarge,
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
                color: Westron.RGB(hex: 0x000000, opacity: 0.12),
                x: 0,
                y: 5,
                blur: 24,
                spread: 0)

            /// Every shadow in token order.
            public static let all: [Westron.Shadow] = [
                raised,
            ]
        }

        extension Westron.Dimension {
            /// The token `space.100`.
            public static let space100 = Westron.Dimension(name: "space.100", value: 8)

            /// Rules and dividers.
            public static let strokeThin = Westron.Dimension(name: "stroke.thin", value: 1)

            /// Every dimension in token order.
            public static let all: [Westron.Dimension] = [
                space100,
                strokeThin,
            ]
        }

        """#

    static let swiftUI = #"""
        // Generated from r.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate again
        // (decisions/0010).
        //
        // The public SwiftUI accessors of westron's semantic tokens. Each calls an adapter in TokenAdapters.swift with a value
        // from WestronTokens: `Color.textSecondary` is `Color(Westron.Color.textSecondary)`, the colorset of that name.

        import SwiftUI
        import WestronTokens

        extension Color {
            /// Words and glyphs.
            ///
            /// Use for: body text, titles. Avoid: Words on the accent: use text.on-accent.
            public static var textPrimary: Color {
                Color(Westron.Color.textPrimary)
            }

            /// A fill brighter than sRGB can show.
            public static var backgroundVivid: Color {
                Color(Westron.Color.backgroundVivid)
            }

            /// The tile under a glyph: the list color, translucent.
            public static func categoryBackground(_ category: Westron.Category) -> Color {
                Color(category.background)
            }

            /// The mark on a fill.
            public static func categoryOnFill(_ category: Westron.Category) -> Color {
                Color(category.onFill)
            }
        }

        extension ShapeStyle where Self == Color {
            /// Words and glyphs.
            ///
            /// Use for: body text, titles. Avoid: Words on the accent: use text.on-accent.
            public static var textPrimary: Color {
                Color(Westron.Color.textPrimary)
            }

            /// A fill brighter than sRGB can show.
            public static var backgroundVivid: Color {
                Color(Westron.Color.backgroundVivid)
            }

            /// The tile under a glyph: the list color, translucent.
            public static func categoryBackground(_ category: Westron.Category) -> Color {
                Color(category.background)
            }

            /// The mark on a fill.
            public static func categoryOnFill(_ category: Westron.Category) -> Color {
                Color(category.onFill)
            }
        }

        extension Font {
            /// The title of a screen.
            public static var headingLarge: Font {
                Font(Westron.TextRole.headingLarge)
            }

            /// Main text.
            public static var label: Font {
                Font(Westron.TextRole.label)
            }
        }

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

            /// Rules and dividers.
            public static var strokeThin: CGFloat {
                CGFloat(Westron.Dimension.strokeThin)
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
