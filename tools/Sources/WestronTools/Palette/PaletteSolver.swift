import Foundation

/// Solves the color ramps of the four themes from a palette source (decisions/0012).
///
/// Every ramp has twelve steps, and a step has the same job in every theme:
///
/// | Step | Job | How its lightness is found |
/// |---|---|---|
/// | 1 | canvas, or a faint tint of it | the canvas's lightness |
/// | 2–5 | subtle, hover, muted, selected backgrounds | the source's contrast against the canvas |
/// | 6–7 | separators, guides | the source's contrast; high contrast: 3 and 4.5 on every ground |
/// | 8 | borders of controls, focus rings, marks | 3 on every ground and on every step 5; high contrast 4.5 |
/// | 9 | solid fill | moved from the source's lightness until its label reaches 4.5; high contrast 7 |
/// | 10 | solid fill under the pointer | step 9, 0.04 further from its label |
/// | 11 | colored or secondary text | 4.5 on every ground and on every step 5; high contrast 7 |
/// | 12 | primary text | from the source's lightness, 13 on the canvas and 7 on every step 5; high contrast 16 |
///
/// The grounds are the canvas, raised and sunken surfaces. Each step moves away from the canvas, towards contrast,
/// the least lightness that meets its targets, keeping its hue and chroma; contrast is measured on the 8-bit sRGB
/// color the step becomes, as the contrast check measures it. Light themes walk darker, dark themes lighter; the dark
/// themes are solved again, not inverted. A high-contrast theme keeps its theme's canvas and steps 1–5.
///
/// `contrast` is the label of a ramp's solid fill. In dark high contrast a white label at 7:1 would sink the fill
/// into the canvas, so the fill turns light and the label takes the canvas's color.
public enum PaletteSolver {
    public static let themes = ["light", "dark", "light-hc", "dark-hc"]

    /// A solved color: its token path below `color` and its 8-bit sRGB value.
    public struct Entry: Equatable, Sendable {
        public let path: [String]
        public let color: RGB

        public init(path: [String], color: RGB) {
            self.path = path
            self.color = color
        }
    }

    /// A target that no lightness reaches.
    public struct Unreachable: Error, Equatable, CustomStringConvertible {
        public let theme: String
        public let path: [String]
        public let target: String

        public var description: String {
            "color.\(path.joined(separator: ".")) in \(theme): no lightness reaches \(target); lower the chroma or "
                + "move the anchor"
        }
    }

    /// The accessibility targets, by kind, in standard and in high-contrast themes (decisions/0012).
    enum Target {
        static let text = (standard: 4.5, highContrast: 7.0)
        static let nonText = (standard: 3.0, highContrast: 4.5)
        static let highContrastSeparator = 3.0
        static let highContrastGuide = 4.5
        static let primaryOnCanvas = (standard: 13.0, highContrast: 16.0)
        static let primaryOnSteps = 7.0
        static let series = 3.0
        static let hoverOffset = 0.04
        static let ink = (lightness: 0.2, chroma: 0.012)
    }

    /// The colors of each theme, by theme name. A high-contrast theme lists only what differs from its base theme,
    /// since its token file is merged over the base theme's.
    public static func solve(_ source: PaletteSource) throws -> [String: [Entry]] {
        var full: [String: [Entry]] = [:]
        var secondaryText: [String: Double] = [:]
        for theme in themes {
            full[theme] = try solve(source, theme: theme, darkSecondary: &secondaryText)
        }
        var result: [String: [Entry]] = [:]
        for theme in themes {
            guard theme.hasSuffix("-hc") else {
                result[theme] = full[theme]
                continue
            }
            let base = Dictionary(full[String(theme.dropLast(3))]!.map { ($0.path, $0.color) }) { first, _ in first }
            result[theme] = full[theme]!.filter { base[$0.path] != $0.color }
        }
        return result
    }

    /// One theme in full. `darkSecondary` carries the lightness of step 11 of each ramp from `dark` to `dark-hc`,
    /// where inverted fills start.
    static func solve(_ source: PaletteSource, theme: String, darkSecondary: inout [String: Double]) throws -> [Entry] {
        let dark = theme.hasPrefix("dark")
        let highContrast = theme.hasSuffix("-hc")
        let away: Double = dark ? 1 : -1
        let neutral = source.neutral
        let neutralChroma = neutral.chroma[dark: dark]
        let canvasLightness = neutral.canvas[dark: dark]
        let canvas = color(canvasLightness, neutralChroma, neutral.hue)
        let raised = color(neutral.raised[dark: dark], neutralChroma, neutral.hue)
        let sunken = color(neutral.sunken[dark: dark], neutralChroma, neutral.hue)
        let grounds = [canvas, raised, sunken]
        let targets = source.steps[dark: dark]

        struct Ramp {
            let name: String
            let hue: Double
            let chroma: [Double]
            let solid: Double
            let label: PaletteSource.Label
            let text: Double
        }
        let ramps =
            [
                Ramp(
                    name: "neutral", hue: neutral.hue, chroma: neutral.stepChroma.map { $0 * neutralChroma },
                    solid: neutral.solid, label: .light, text: neutral.text[dark: dark])
            ]
            + source.hues.map {
                Ramp(
                    name: $0.name, hue: $0.hue, chroma: source.stepChroma.map { [c = $0.chroma] in $0 * c },
                    solid: $0.solid, label: $0.label, text: source.text[dark: dark])
            }

        // Steps 1–5 of every ramp first: text and marks must read on the step 5 of every ramp, since equal targets
        // still round to slightly different luminances in 8 bits.
        var low: [String: [RGB]] = [:]
        for ramp in ramps {
            var steps = [ramp.name == "neutral" ? canvas : color(canvasLightness, ramp.chroma[0], ramp.hue)]
            for step in 2...5 {
                steps.append(
                    try solve(
                        theme, [ramp.name, "\(step)"], from: canvasLightness, ramp.chroma[step - 1], ramp.hue,
                        direction: away, "\(targets[step - 2]):1 on the canvas"
                    ) { ratio($0, canvas) >= targets[step - 2] }.color)
            }
            low[ramp.name] = steps
        }
        let onEverything = grounds + ramps.map { low[$0.name]![4] }

        var entries: [Entry] = [
            Entry(path: ["neutral", "raised"], color: raised), Entry(path: ["neutral", "sunken"], color: sunken),
        ]
        for ramp in ramps {
            var steps = low[ramp.name]!
            func solveStep(
                _ step: Int, from start: Double, direction: Double, _ target: String, _ accepts: (RGB) -> Bool
            )
                throws -> (color: RGB, lightness: Double)
            {
                try solve(
                    theme, [ramp.name, "\(step)"], from: start, ramp.chroma[step - 1], ramp.hue, direction: direction,
                    target, accepts)
            }
            if highContrast {
                let separators = grounds + [steps[1]]
                steps.append(
                    try solveStep(6, from: canvasLightness, direction: away, "3:1 on every ground") {
                        minimum($0, on: separators) >= Target.highContrastSeparator
                    }.color)
                steps.append(
                    try solveStep(7, from: canvasLightness, direction: away, "4.5:1 on every ground") {
                        minimum($0, on: separators) >= Target.highContrastGuide
                    }.color)
            } else {
                for step in 6...7 {
                    steps.append(
                        try solveStep(step, from: canvasLightness, direction: away, "\(targets[step - 2]):1") {
                            ratio($0, canvas) >= targets[step - 2]
                        }.color)
                }
            }
            let nonText = highContrast ? Target.nonText.highContrast : Target.nonText.standard
            steps.append(
                try solveStep(8, from: canvasLightness, direction: away, "\(nonText):1 on every step 5") {
                    minimum($0, on: onEverything) >= nonText
                }.color)

            // The solid fill moves away from its label until the label reads on it.
            let text = highContrast ? Target.text.highContrast : Target.text.standard
            let inverted = theme == "dark-hc" && ramp.label == .light
            let label: RGB
            let start: Double
            if inverted {
                label = canvas
                guard let secondary = darkSecondary[ramp.name] else {
                    preconditionFailure("dark is solved before dark-hc")
                }
                start = secondary
            } else {
                label =
                    ramp.label == .light
                    ? RGB(.sRGB, red: 1, green: 1, blue: 1) : color(Target.ink.lightness, Target.ink.chroma, ramp.hue)
                start = ramp.solid
            }
            let fromLabel: Double = WCAG.relativeLuminance(label) < 0.18 ? 1 : -1
            let solid = try solveStep(9, from: start, direction: fromLabel, "\(text):1 under its label") {
                ratio($0, label) >= text
            }
            steps.append(solid.color)
            let hover = min(max(solid.lightness + fromLabel * Target.hoverOffset, 0), 1)
            steps.append(color(hover, ramp.chroma[9], ramp.hue))

            let secondary = try solveStep(11, from: canvasLightness, direction: away, "\(text):1 on every step 5") {
                minimum($0, on: onEverything) >= text
            }
            steps.append(secondary.color)
            if theme == "dark" { darkSecondary[ramp.name] = secondary.lightness }
            let primary = highContrast ? Target.primaryOnCanvas.highContrast : Target.primaryOnCanvas.standard
            steps.append(
                try solveStep(12, from: ramp.text, direction: away, "\(primary):1 on the canvas") {
                    ratio($0, canvas) >= primary && minimum($0, on: onEverything) >= Target.primaryOnSteps
                }.color)

            entries += steps.enumerated().map { Entry(path: [ramp.name, "\($0.offset + 1)"], color: $0.element) }
            entries.append(Entry(path: [ramp.name, "contrast"], color: label))
        }

        let series = source.series[dark: dark]
        for (index, hex) in series.enumerated() {
            let start = OKLCH(try RGB(hex: hex))
            let path = ["series", "\(index + 1)"]
            entries.append(
                Entry(
                    path: path,
                    color: try solve(
                        theme, path, from: start.l, start.c, start.h ?? 0, direction: away, "3:1 on every ground"
                    ) { minimum($0, on: grounds) >= Target.series }.color))
        }
        return entries
    }

    /// The 8-bit sRGB color of an OKLCH color. Outside sRGB the chroma is reduced at constant lightness and hue until
    /// the color fits: CSS's mapping stops one just noticeable difference short and clips, which turns a light tint of
    /// blue towards cyan by some 20°. The tokens store the color this returns, so no platform maps it again.
    static func color(_ lightness: Double, _ chroma: Double, _ hue: Double) -> RGB {
        let lightness = min(max(lightness, 0), 1)
        func rgb(_ chroma: Double) -> RGB { RGB(OKLCH(l: lightness, c: chroma, h: hue), in: .sRGB) }
        var mapped = rgb(chroma)
        if !mapped.isInGamut(tolerance: 1e-6) {
            var low = 0.0
            var high = chroma
            while high - low > 1e-5 {
                let middle = (low + high) / 2
                if rgb(middle).isInGamut(tolerance: 1e-6) { low = middle } else { high = middle }
            }
            mapped = rgb(low)
        }
        let bytes = mapped.clipped().bytes
        return RGB(
            .sRGB, red: Double(bytes.red) / 255, green: Double(bytes.green) / 255, blue: Double(bytes.blue) / 255)
    }

    static func ratio(_ color: RGB, _ background: RGB) -> Double {
        WCAG.contrastRatio(of: color, on: background)
    }

    static func minimum(_ color: RGB, on backgrounds: [RGB]) -> Double {
        backgrounds.map { ratio(color, $0) }.min()!
    }

    /// The color at the least distance from `start` along `direction` (1 lighter, −1 darker) that `accepts`: a
    /// bisection, then small steps for the few places where 8-bit rounding is not monotonic.
    static func solve(
        _ theme: String, _ path: [String], from start: Double, _ chroma: Double, _ hue: Double, direction: Double,
        _ target: String, _ accepts: (RGB) -> Bool
    ) throws -> (color: RGB, lightness: Double) {
        let start = min(max(start, 0), 1)
        let end = direction > 0 ? 1 - start : start
        func at(_ distance: Double) -> RGB { color(start + direction * distance, chroma, hue) }
        if accepts(at(0)) { return (at(0), start) }
        guard accepts(at(end)) else { throw Unreachable(theme: theme, path: path, target: target) }
        var low = 0.0
        var high = end
        for _ in 0..<40 {
            let middle = (low + high) / 2
            if accepts(at(middle)) { high = middle } else { low = middle }
        }
        var distance = high
        while !accepts(at(distance)) {
            distance = min(distance + 0.0005, end)
        }
        return (at(distance), start + direction * distance)
    }
}
