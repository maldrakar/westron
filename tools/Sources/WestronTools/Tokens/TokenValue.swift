/// A token value with every reference resolved, in the form DTCG 2025.10 writes it. Units and color spaces are
/// kept as written; converting them is the generators' job.
public enum TokenValue: Equatable, Sendable {
    case color(Color)
    case dimension(Dimension)
    case number(Double)
    case duration(Duration)
    case cubicBezier(CubicBezier)
    /// Font names from the most to the least preferred; a single name is a list of one.
    case fontFamily([String])
    case fontWeight(FontWeight)
    case typography(Typography)
    /// Shadow layers in the order written; a single shadow object is a list of one.
    case shadow([Shadow])
    case transition(Transition)

    public var type: TokenType {
        switch self {
        case .color: .color
        case .dimension: .dimension
        case .number: .number
        case .duration: .duration
        case .cubicBezier: .cubicBezier
        case .fontFamily: .fontFamily
        case .fontWeight: .fontWeight
        case .typography: .typography
        case .shadow: .shadow
        case .transition: .transition
        }
    }
}

extension TokenValue {
    /// A color as the DTCG 2025.10 Color module writes it. Conversion between color spaces is not done here.
    public struct Color: Equatable, Sendable {
        /// The color spaces of the Color module (4.2), with their DTCG names.
        public enum Space: String, CaseIterable, Sendable {
            case srgb
            case srgbLinear = "srgb-linear"
            case hsl
            case hwb
            case lab
            case lch
            case oklab
            case oklch
            case displayP3 = "display-p3"
            case a98RGB = "a98-rgb"
            case prophotoRGB = "prophoto-rgb"
            case rec2020
            case xyzD65 = "xyz-d65"
            case xyzD50 = "xyz-d50"

            /// The allowed range of each component, in order (Color module, 4.2). Every space has three.
            public var componentRanges: [ComponentRange] {
                switch self {
                case .srgb, .srgbLinear, .displayP3, .a98RGB, .prophotoRGB, .rec2020, .xyzD65, .xyzD50:
                    [.unit, .unit, .unit]
                case .hsl, .hwb: [.hue, .percentage, .percentage]
                case .lab: [.percentage, .unbounded, .unbounded]
                case .lch: [.percentage, .nonNegative, .hue]
                case .oklab: [.unit, .unbounded, .unbounded]
                case .oklch: [.unit, .nonNegative, .hue]
                }
            }
        }

        public enum ComponentRange: Sendable {
            /// [0, 1].
            case unit
            /// [0, 100].
            case percentage
            /// [0, 360): 360 itself is not allowed.
            case hue
            /// [0, ∞), such as chroma.
            case nonNegative
            /// Any number, such as the a and b axes of Lab.
            case unbounded

            public func contains(_ value: Double) -> Bool {
                switch self {
                case .unit: (0...1).contains(value)
                case .percentage: (0...100).contains(value)
                case .hue: (0..<360).contains(value)
                case .nonNegative: value >= 0
                case .unbounded: true
                }
            }

            var text: String {
                switch self {
                case .unit: "[0, 1]"
                case .percentage: "[0, 100]"
                case .hue: "[0, 360)"
                case .nonNegative: "[0, ∞)"
                case .unbounded: "any number"
                }
            }
        }

        /// A component: a number, or the `none` keyword for a missing component (Color module, 4.1.1).
        public enum Component: Equatable, Sendable {
            case number(Double)
            case none
        }

        public var colorSpace: Space
        public var components: [Component]
        /// From 0 (transparent) to 1 (opaque); 1 when the file omits it, as the Color module requires.
        public var alpha: Double
        /// The optional fallback, `#rrggbb` as written.
        public var hex: String?

        public init(colorSpace: Space, components: [Component], alpha: Double = 1, hex: String? = nil) {
            self.colorSpace = colorSpace
            self.components = components
            self.alpha = alpha
            self.hex = hex
        }
    }

    /// A distance (Format, 8.2). DTCG units are px and rem; the generators derive pt, dp and sp.
    public struct Dimension: Equatable, Sendable {
        public enum Unit: String, CaseIterable, Sendable {
            case px, rem
        }

        public var value: Double
        public var unit: Unit

        public init(_ value: Double, _ unit: Unit) {
            self.value = value
            self.unit = unit
        }
    }

    /// A length of time (Format, 8.5).
    public struct Duration: Equatable, Sendable {
        public enum Unit: String, CaseIterable, Sendable {
            case ms, s
        }

        public var value: Double
        public var unit: Unit

        public init(_ value: Double, _ unit: Unit) {
            self.value = value
            self.unit = unit
        }

        public var milliseconds: Double { unit == .s ? value * 1000 : value }
    }

    /// Control points `[x1, y1, x2, y2]` of a timing curve (Format, 8.6); x1 and x2 are in [0, 1].
    public struct CubicBezier: Equatable, Sendable {
        public var x1: Double
        public var y1: Double
        public var x2: Double
        public var y2: Double

        public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
            self.x1 = x1
            self.y1 = y1
            self.x2 = x2
            self.y2 = y2
        }
    }

    /// A weight in [1, 1000] (Format, 8.4). A named weight is kept with the number it stands for.
    public struct FontWeight: Equatable, Sendable {
        /// The named weights of Format 8.4 and their numbers. Names are case-sensitive.
        public static let names: [String: Double] = [
            "thin": 100, "hairline": 100,
            "extra-light": 200, "ultra-light": 200,
            "light": 300,
            "normal": 400, "regular": 400, "book": 400,
            "medium": 500,
            "semi-bold": 600, "demi-bold": 600,
            "bold": 700,
            "extra-bold": 800, "ultra-bold": 800,
            "black": 900, "heavy": 900,
            "extra-black": 950, "ultra-black": 950,
        ]

        public var value: Double
        /// The name the file used, such as `bold`; nil for a number.
        public var name: String?

        public init(_ value: Double, name: String? = nil) {
            self.value = value
            self.name = name
        }
    }

    /// A text style (Format, 9.8). All five properties are required.
    public struct Typography: Equatable, Sendable {
        public var fontFamily: [String]
        public var fontSize: Dimension
        public var fontWeight: FontWeight
        public var letterSpacing: Dimension
        /// A multiplier of `fontSize`.
        public var lineHeight: Double

        public init(
            fontFamily: [String], fontSize: Dimension, fontWeight: FontWeight, letterSpacing: Dimension,
            lineHeight: Double
        ) {
            self.fontFamily = fontFamily
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.letterSpacing = letterSpacing
            self.lineHeight = lineHeight
        }
    }

    /// An animated change (Format, 9.5). A spring is not a transition: it lives in
    /// `$extensions.dev.westron.spring` (decisions/0010).
    public struct Transition: Equatable, Sendable {
        public var duration: Duration
        /// The wait before the change starts.
        public var delay: Duration
        public var timingFunction: CubicBezier

        public init(duration: Duration, delay: Duration, timingFunction: CubicBezier) {
            self.duration = duration
            self.delay = delay
            self.timingFunction = timingFunction
        }
    }

    /// One shadow layer (Format, 9.6).
    public struct Shadow: Equatable, Sendable {
        public var color: Color
        public var offsetX: Dimension
        public var offsetY: Dimension
        public var blur: Dimension
        public var spread: Dimension
        /// An inner shadow; false when the file omits it.
        public var inset: Bool

        public init(
            color: Color, offsetX: Dimension, offsetY: Dimension, blur: Dimension, spread: Dimension,
            inset: Bool = false
        ) {
            self.color = color
            self.offsetX = offsetX
            self.offsetY = offsetY
            self.blur = blur
            self.spread = spread
            self.inset = inset
        }
    }
}
