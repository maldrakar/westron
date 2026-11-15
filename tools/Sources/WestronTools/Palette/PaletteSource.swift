import Foundation

/// The palette source, `tokens/palette.json` (decisions/0012): the anchors from which `PaletteSolver` solves the
/// color ramps of each theme. Hue and chroma are OKLCH; the neutral grounds are OKLCH lightness; every other
/// lightness is solved for a contrast target.
public struct PaletteSource: Decodable, Equatable, Sendable {
    /// A value for the light themes and one for the dark themes; a high-contrast theme takes its base theme's.
    public struct ByTheme<Value: Decodable & Equatable & Sendable>: Decodable, Equatable, Sendable {
        public let light: Value
        public let dark: Value

        public init(light: Value, dark: Value) {
            self.light = light
            self.dark = dark
        }

        public subscript(dark isDark: Bool) -> Value { isDark ? dark : light }
    }

    /// The gray ramp: the canvas and the other grounds are anchors, the rest is solved.
    public struct Neutral: Decodable, Equatable, Sendable {
        public let hue: Double
        /// The chroma of the canvas.
        public let chroma: ByTheme<Double>
        /// The chroma of steps 1–12 as multiples of `chroma`: text reads as ink, not as a color, at about 1.6.
        public let stepChroma: [Double]
        /// The lightness of the canvas (step 1), of raised surfaces and of sunken ones.
        public let canvas: ByTheme<Double>
        public let raised: ByTheme<Double>
        public let sunken: ByTheme<Double>
        /// Where the solid fill (step 9) starts before it is moved to carry its label.
        public let solid: Double
        /// Where primary text (step 12) starts before it is moved to its targets.
        public let text: ByTheme<Double>
    }

    /// The color of the label on a ramp's solid fill.
    public enum Label: String, Decodable, Equatable, Sendable {
        /// White; in dark high contrast the fill turns light and the label takes the canvas.
        case light
        /// A dark ink of the ramp's hue, for bright fills such as amber.
        case dark
    }

    public struct Hue: Decodable, Equatable, Sendable {
        /// The ramp's name, which becomes its token group: `blue`.
        public let name: String
        public let hue: Double
        /// The chroma of the solid fill; the other steps take a part of it (`stepChroma`).
        public let chroma: Double
        /// Where the solid fill starts before it is moved to carry its label.
        public let solid: Double
        public let label: Label
    }

    public let neutral: Neutral
    /// The contrast against the canvas of steps 2–7 in the standard themes, which carry no accessibility target.
    public let steps: ByTheme<[Double]>
    /// The chroma of steps 1–12 of a hue ramp, as parts of the hue's chroma.
    public let stepChroma: [Double]
    /// Where colored text (step 12 of a hue ramp) starts.
    public let text: ByTheme<Double>
    /// The hue ramps, in the order the tokens list them.
    public let hues: [Hue]
    /// The chart series in order, as sRGB hex: the solver moves each until it reaches its target on every ground.
    public let series: ByTheme<[String]>

    /// The palette source, relative to the repository root.
    public static let defaultFile = "tokens/palette.json"

    /// A palette source that does not hold what the solver needs.
    public struct Invalid: Error, Equatable, CustomStringConvertible {
        public let source: String
        public let problems: [String]

        public var description: String {
            problems.map { "\(source): \($0)" }.joined(separator: "\n")
        }
    }

    /// Reads and validates a palette source.
    /// - Throws: `Invalid` with every problem, or the decoder's error for JSON of the wrong shape.
    public static func load(_ data: Data, source: String) throws -> PaletteSource {
        let palette = try JSONDecoder().decode(PaletteSource.self, from: data)
        let problems = palette.problems()
        guard problems.isEmpty else { throw Invalid(source: source, problems: problems) }
        return palette
    }

    public static func load(file: String) throws -> PaletteSource {
        try load(Data(contentsOf: URL(fileURLWithPath: file)), source: file)
    }

    /// What makes the source unusable: wrong counts, names that are not token names, values out of range.
    func problems() -> [String] {
        var problems: [String] = []
        if neutral.stepChroma.count != 12 { problems.append("neutral.stepChroma has 12 values, one per step") }
        if stepChroma.count != 12 { problems.append("stepChroma has 12 values, one per step") }
        for (name, values) in [("steps.light", steps.light), ("steps.dark", steps.dark)] {
            if values.count != 6 { problems.append("\(name) has 6 values, for steps 2–7") }
            if values.contains(where: { $0 < 1 }) { problems.append("\(name): a contrast is at least 1") }
            if values != values.sorted() { problems.append("\(name): each step contrasts more than the one before") }
        }
        let lightness = [
            ("neutral.canvas", neutral.canvas), ("neutral.raised", neutral.raised), ("neutral.sunken", neutral.sunken),
            ("neutral.text", neutral.text), ("text", text),
        ]
        for (name, value) in lightness where !(0...1).contains(value.light) || !(0...1).contains(value.dark) {
            problems.append("\(name): a lightness is in 0...1")
        }
        if neutral.raised.light < neutral.canvas.light || neutral.raised.dark < neutral.canvas.dark {
            problems.append("neutral.raised is lighter than the canvas: higher is lighter in every theme")
        }
        if neutral.sunken.light > neutral.canvas.light || neutral.sunken.dark > neutral.canvas.dark {
            problems.append("neutral.sunken is darker than the canvas")
        }
        var names: Set<String> = ["neutral", "series"]
        for hue in hues {
            if hue.name.isEmpty || !hue.name.allSatisfy({ ("a"..."z").contains($0) || $0 == "-" }) {
                problems.append("hues: \(hue.name) is not a token name in lowercase kebab-case")
            }
            if !names.insert(hue.name).inserted { problems.append("hues: \(hue.name) is taken") }
            if !(0...1).contains(hue.solid) { problems.append("hues.\(hue.name).solid: a lightness is in 0...1") }
        }
        if series.light.count != series.dark.count {
            problems.append("series: light and dark have the same number of colors")
        }
        for hex in series.light + series.dark where (try? RGB(hex: hex)) == nil {
            problems.append("series: \(hex) is not a #rrggbb color")
        }
        return problems
    }
}
