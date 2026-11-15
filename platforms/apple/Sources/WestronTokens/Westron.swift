// The types of westron's token values. The values themselves are generated into Generated/Tokens.swift from
// tokens/westron.resolver.json by `tools/westron generate` (decisions/0010), and the icons into Generated/Icons.swift
// from spec/icons/icons.yaml (decisions/0011).
//
// No imports, not even Foundation: the pilot's shared code and its WebAssembly build use this module, so it holds
// plain Swift numbers and strings only (decisions/0006, 0010). The SwiftUI side is in WestronUI.

/// westron's design tokens as plain values: every semantic token, resolved for Apple (decisions/0010).
///
/// Every type of the module is nested here, so its one top-level name is `Westron` and none of its names shadows
/// one a consumer's modules own, such as SwiftUI's `Color`, `Font` and `Animation`. Primitive tokens are not here:
/// components and products use the semantic ones only.
///
///     Westron.Color.textSecondary.dark          // the color in the dark theme
///     Westron.Category(rawValue: "amber")?.text // a list's color by the name the store keeps
///     Westron.TextRole.headingLarge.textStyle   // .largeTitle
///     Westron.Transition.move.spring            // Spring(duration: 0.35, bounce: 0.15)
///     Westron.Icon(rawValue: "sun") ?? .fallback // a list's icon by the name the store keeps
public enum Westron {}

extension Westron {
    /// A color theme: the contexts of the `theme` modifier (decisions/0010). A platform switches between them at run
    /// time, by its appearance and its contrast setting.
    public enum Theme: String, CaseIterable, Sendable {
        case light
        case dark
        case lightHighContrast = "light-hc"
        case darkHighContrast = "dark-hc"

        /// Whether the theme is a dark one.
        public var isDark: Bool { self == .dark || self == .darkHighContrast }

        /// Whether the theme is one of increased contrast.
        public var isHighContrast: Bool { self == .lightHighContrast || self == .darkHighContrast }
    }

    /// A gamma-encoded RGB color with its opacity: sRGB, or Display P3 for a color outside sRGB.
    ///
    /// A color inside sRGB is written in 8 bits, as the pilot's hex values are (`RGB(hex: 0x3653C9)`), so that its
    /// hex stays the same byte for byte.
    public struct RGB: Hashable, Sendable {
        /// The RGB space of the channels. Both have the D65 white and the sRGB transfer function.
        public enum Space: String, Hashable, Sendable {
            case sRGB = "srgb"
            case displayP3 = "display-p3"
        }

        public let space: Space
        /// From 0 to 1.
        public let red: Double
        /// From 0 to 1.
        public let green: Double
        /// From 0 to 1.
        public let blue: Double
        /// From 0 (transparent) to 1 (opaque).
        public let opacity: Double

        public init(_ space: Space, red: Double, green: Double, blue: Double, opacity: Double = 1) {
            self.space = space
            self.red = red
            self.green = green
            self.blue = blue
            self.opacity = opacity
        }

        /// An sRGB color written as `0xRRGGBB`: each byte divided by 255.
        public init(hex: UInt32, opacity: Double = 1) {
            self.init(
                .sRGB,
                red: Double((hex >> 16) & 0xFF) / 255,
                green: Double((hex >> 8) & 0xFF) / 255,
                blue: Double(hex & 0xFF) / 255,
                opacity: opacity)
        }
    }

    /// A semantic color: its value in each of the four themes.
    ///
    /// The colors are the static members of this type, named after their tokens (`color.text.secondary` is
    /// `textSecondary`); the list colors are `Westron.Category`'s. `all` lists every one.
    public struct Color: Hashable, Sendable {
        /// The token's path, `color.text.secondary`. In WestronUI it is also the name of the color's colorset.
        public let name: String
        public let light: RGB
        public let dark: RGB
        public let lightHighContrast: RGB
        public let darkHighContrast: RGB
        /// The backgrounds a foreground is drawn on, as its token declares them for the contrast check
        /// (`dev.westron.contrast`, decisions/0012): token names, each background a stack with its top layer first,
        /// such as `["color.category.amber.background", "color.background.canvas"]`. Empty for a background.
        public let backgrounds: [[String]]

        init(
            name: String, light: RGB, dark: RGB, lightHighContrast: RGB, darkHighContrast: RGB,
            backgrounds: [[String]] = []
        ) {
            self.name = name
            self.light = light
            self.dark = dark
            self.lightHighContrast = lightHighContrast
            self.darkHighContrast = darkHighContrast
            self.backgrounds = backgrounds
        }

        /// The color in a theme.
        public subscript(theme: Theme) -> RGB {
            switch theme {
            case .light: light
            case .dark: dark
            case .lightHighContrast: lightHighContrast
            case .darkHighContrast: darkHighContrast
            }
        }
    }

    /// A text role: the platform's text style it follows, so that it scales with the person's text size, a design and
    /// a weight (decisions/0011, 0013).
    ///
    /// `size`, `lineHeight` and `letterSpacing` are the cross-platform values at the default text size; on Apple the
    /// text style sets the size, and no line spacing or tracking is applied yet.
    public struct TextRole: Hashable, Sendable {
        /// The Apple text styles (Dynamic Type).
        public enum TextStyle: String, CaseIterable, Sendable {
            case largeTitle, title1, title2, title3, headline, body, callout, subheadline, footnote, caption, caption2
        }

        /// The design of the system font, and of the system font a shipped font falls back on (decisions/0011).
        public enum Design: String, CaseIterable, Sendable {
            case `default`, rounded, monospaced, serif
        }

        /// A weight, by its number on the CSS scale.
        public enum Weight: Int, CaseIterable, Sendable {
            case ultraLight = 100
            case thin = 200
            case light = 300
            case regular = 400
            case medium = 500
            case semibold = 600
            case bold = 700
            case heavy = 800
            case black = 900
        }

        /// The token's path, `typography.heading.large`.
        public let name: String
        public let textStyle: TextStyle
        public let design: Design
        public let weight: Weight
        /// The PostScript name of a font westron ships, `Onest-Bold`, at `weight`; nil for the system font in
        /// `design` (decisions/0011).
        public let font: String?
        /// The size at the default text size, in points (CSS px).
        public let size: Double
        /// The line height as a multiple of the size.
        public let lineHeight: Double
        /// The space between letters, in points.
        public let letterSpacing: Double

        init(
            name: String, textStyle: TextStyle, design: Design, weight: Weight, font: String?, size: Double,
            lineHeight: Double, letterSpacing: Double
        ) {
            self.name = name
            self.textStyle = textStyle
            self.design = design
            self.weight = weight
            self.font = font
            self.size = size
            self.lineHeight = lineHeight
            self.letterSpacing = letterSpacing
        }
    }

    /// A motion: how long it runs, how long it waits, its curve, and the spring that platforms with springs use
    /// instead of the curve (decisions/0013).
    public struct Transition: Hashable, Sendable {
        /// A cubic Bézier timing curve with the control points (x1, y1) and (x2, y2), as CSS `cubic-bezier` writes it.
        public struct Curve: Hashable, Sendable {
            public let x1: Double
            public let y1: Double
            public let x2: Double
            public let y2: Double

            init(x1: Double, y1: Double, x2: Double, y2: Double) {
                self.x1 = x1
                self.y1 = y1
                self.x2 = x2
                self.y2 = y2
            }
        }

        /// A spring by its perceived duration in seconds and its bounce, from -1 to 1, as SwiftUI's
        /// `Spring(duration:bounce:)` takes them; 0 is a spring without bounce.
        public struct Spring: Hashable, Sendable {
            public let duration: Double
            public let bounce: Double

            init(duration: Double, bounce: Double) {
                self.duration = duration
                self.bounce = bounce
            }
        }

        /// The token's path, `motion.row-leave`.
        public let name: String
        /// Seconds.
        public let duration: Double
        /// Seconds before the motion starts.
        public let delay: Double
        public let curve: Curve
        /// The spring that replaces the curve where the platform has springs; nil for a motion on its curve.
        public let spring: Spring?

        init(name: String, duration: Double, delay: Double, curve: Curve, spring: Spring?) {
            self.name = name
            self.duration = duration
            self.delay = delay
            self.curve = curve
            self.spring = spring
        }
    }

    /// A drop shadow: layers, each offset by `x` and `y` and blurred over `blur`, all in points (CSS px). The layers
    /// differ by theme: a dark theme casts stronger shadows, or none where a lighter surface shows the height
    /// (decisions/0013).
    public struct Shadow: Hashable, Sendable {
        /// One layer of a shadow.
        public struct Layer: Hashable, Sendable {
            public let color: RGB
            public let x: Double
            public let y: Double
            /// The CSS blur.
            public let blur: Double
            public let spread: Double

            /// The radius Apple's shadows take: half the CSS blur (decisions/0013).
            public var radius: Double { blur / 2 }

            init(color: RGB, x: Double, y: Double, blur: Double, spread: Double) {
                self.color = color
                self.x = x
                self.y = y
                self.blur = blur
                self.spread = spread
            }
        }

        /// The token's path, `shadow.raised`.
        public let name: String
        public let light: [Layer]
        public let dark: [Layer]
        public let lightHighContrast: [Layer]
        public let darkHighContrast: [Layer]

        /// The layers of a theme, near ones first; none where the theme casts no shadow.
        public subscript(theme: Theme) -> [Layer] {
            switch theme {
            case .light: light
            case .dark: dark
            case .lightHighContrast: lightHighContrast
            case .darkHighContrast: darkHighContrast
            }
        }

        init(name: String, light: [Layer], dark: [Layer], lightHighContrast: [Layer], darkHighContrast: [Layer]) {
            self.name = name
            self.light = light
            self.dark = dark
            self.lightHighContrast = lightHighContrast
            self.darkHighContrast = darkHighContrast
        }
    }

    /// A length: a step of the space or radius ladder, or a stroke width, in points (CSS px).
    public struct Dimension: Hashable, Sendable {
        /// The token's path, `space.100`.
        public let name: String
        public let value: Double

        init(name: String, value: Double) {
            self.name = name
            self.value = value
        }
    }
}
