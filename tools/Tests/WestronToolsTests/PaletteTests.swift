import Foundation
import Testing

@testable import WestronTools

/// westron's own palette source, `tokens/palette.json`.
private func realPalette() throws -> PaletteSource {
    try PaletteSource.load(file: repositoryRoot.appendingPathComponent(PaletteSource.defaultFile).path)
}

/// Every color of a theme in full: a high-contrast theme merged over its base theme.
private func full(_ solved: [String: [PaletteSolver.Entry]], _ theme: String) -> [String: RGB] {
    var colors: [String: RGB] = [:]
    let layers = theme.hasSuffix("-hc") ? [String(theme.dropLast(3)), theme] : [theme]
    for layer in layers {
        for entry in solved[layer]! { colors[entry.path.joined(separator: ".")] = entry.color }
    }
    return colors
}

private func ratio(_ a: RGB, _ b: RGB) -> Double { WCAG.contrastRatio(of: a, on: b) }

/// A small valid source; tests replace parts of it.
private let fixture = """
    {
      "neutral": {
        "hue": 258, "chroma": {"light": 0.007, "dark": 0.011},
        "stepChroma": [1, 1.2, 1.2, 1.2, 1.2, 1.2, 1.2, 1.6, 1.6, 1.6, 1.6, 1.6],
        "canvas": {"light": 0.984, "dark": 0.186}, "raised": {"light": 1, "dark": 0.224},
        "sunken": {"light": 0.963, "dark": 0.153}, "solid": 0.5, "text": {"light": 0.27, "dark": 0.9}
      },
      "steps": {"light": [1.06, 1.09, 1.11, 1.16, 1.27, 1.6], "dark": [1.14, 1.18, 1.23, 1.36, 1.45, 1.8]},
      "stepChroma": [0.06, 0.19, 0.21, 0.23, 0.25, 0.32, 0.5, 0.8, 1, 1, 0.95, 0.45],
      "text": {"light": 0.32, "dark": 0.93},
      "hues": [
        {"name": "blue", "hue": 262, "chroma": 0.189, "solid": 0.531, "label": "light"},
        {"name": "amber", "hue": 80, "chroma": 0.16, "solid": 0.8, "label": "dark"}
      ],
      "series": {"light": ["#1E68BD", "#349D11"], "dark": ["#80B8FF", "#EDC700"]}
    }
    """

private func load(_ json: String) throws -> PaletteSource {
    try PaletteSource.load(Data(json.utf8), source: "palette.json")
}

@Suite("Palette")
struct PaletteTests {
    @Test("every step of westron's palette meets its job's targets in every theme")
    func realTargets() throws {
        let palette = try realPalette()
        let solved = try PaletteSolver.solve(palette)
        let ramps = ["neutral"] + palette.hues.map(\.name)
        for theme in PaletteSolver.themes {
            let highContrast = theme.hasSuffix("-hc")
            let colors = full(solved, theme)
            let grounds = ["neutral.1", "neutral.raised", "neutral.sunken"].map { colors[$0]! }
            let fives = ramps.map { colors["\($0).5"]! }
            for ramp in ramps {
                func step(_ name: String) -> RGB { colors["\(ramp).\(name)"]! }
                let onEverything = (grounds + fives).map { ratio(step("11"), $0) }.min()!
                #expect(onEverything >= (highContrast ? 7 : 4.5), "\(theme) \(ramp).11: \(onEverything)")
                let marks = (grounds + fives).map { ratio(step("8"), $0) }.min()!
                #expect(marks >= (highContrast ? 4.5 : 3), "\(theme) \(ramp).8: \(marks)")
                let label = ratio(step("contrast"), step("9"))
                #expect(label >= (highContrast ? 7 : 4.5), "\(theme) \(ramp).9 under its label: \(label)")
                // Under the pointer and pressed, the fill moves further from its label, step by step.
                let hover = ratio(step("contrast"), step("10"))
                let pressed = ratio(step("contrast"), step("fill-pressed"))
                #expect(
                    hover > label && pressed > hover, "\(theme) \(ramp): 9 \(label), 10 \(hover), pressed \(pressed)")
                #expect(ratio(step("12"), grounds[0]) >= (highContrast ? 16 : 13), "\(theme) \(ramp).12")
                // A checked control's fill stands out from every ground, under a label that reads on it; where the
                // solid fill already stands out, it is the solid fill under the solid fill's label.
                let nonText = highContrast ? 4.5 : 3
                let control = grounds.map { ratio(step("control"), $0) }.min()!
                #expect(control >= nonText, "\(theme) \(ramp).control: \(control)")
                let controlLabel = ratio(step("control-contrast"), step("control"))
                #expect(controlLabel >= (highContrast ? 7 : 4.5), "\(theme) \(ramp).control-contrast: \(controlLabel)")
                if grounds.allSatisfy({ ratio(step("9"), $0) >= nonText }) {
                    #expect(step("control") == step("9"), "\(theme) \(ramp).control moved though 9 stands out")
                    #expect(step("control-contrast") == step("contrast"), "\(theme) \(ramp).control-contrast")
                }
            }
            for index in 1...palette.series.light.count {
                let series = colors["series.\(index)"]!
                #expect(grounds.allSatisfy { ratio(series, $0) >= 3 }, "\(theme) series.\(index)")
            }
        }
    }

    @Test("a high-contrast theme keeps its canvas and steps 1–5, and its file lists only what differs")
    func highContrast() throws {
        let palette = try load(fixture)
        let solved = try PaletteSolver.solve(palette)
        for theme in ["light-hc", "dark-hc"] {
            let base = full(solved, String(theme.dropLast(3)))
            let paths = Set(solved[theme]!.map { $0.path.joined(separator: ".") })
            #expect(!paths.isEmpty)
            for entry in solved[theme]! {
                #expect(base[entry.path.joined(separator: ".")] != entry.color, "\(theme) repeats \(entry.path)")
            }
            for ramp in ["neutral", "blue", "amber"] {
                for step in 1...5 { #expect(!paths.contains("\(ramp).\(step)"), "\(theme) changes \(ramp).\(step)") }
            }
            #expect(!paths.contains("neutral.raised") && !paths.contains("neutral.sunken"))
        }
    }

    @Test("dark high contrast turns a white-labeled fill light with a canvas-colored label; a dark label stays")
    func darkHighContrastInverts() throws {
        let solved = try PaletteSolver.solve(load(fixture))
        let dark = full(solved, "dark")
        let darkHC = full(solved, "dark-hc")
        let white = RGB(.sRGB, red: 1, green: 1, blue: 1)
        #expect(dark["blue.contrast"] == white)
        #expect(darkHC["blue.contrast"] == darkHC["neutral.1"])
        #expect(WCAG.relativeLuminance(darkHC["blue.9"]!) > WCAG.relativeLuminance(dark["blue.9"]!))
        #expect(darkHC["amber.contrast"] == dark["amber.contrast"])
        #expect(full(solved, "light-hc")["blue.contrast"] == white)
    }

    @Test("a control fill is the solid fill where it stands out; a bright fill darkens under its own dark label")
    func controlFill() throws {
        let solved = try PaletteSolver.solve(load(fixture))
        let light = full(solved, "light")
        let grounds = ["neutral.1", "neutral.raised", "neutral.sunken"].map { light[$0]! }
        #expect(light["blue.control"] == light["blue.9"] && light["blue.control-contrast"] == light["blue.contrast"])
        // Amber's bright fill is below 3:1 on the light grounds: it moves darker, as little as it must, and its
        // dark label still reads on it.
        #expect(grounds.contains { ratio(light["amber.9"]!, $0) < 3 })
        let amber = try #require(light["amber.control"])
        #expect(grounds.allSatisfy { ratio(amber, $0) >= 3 })
        #expect(WCAG.relativeLuminance(amber) < WCAG.relativeLuminance(light["amber.9"]!))
        #expect(light["amber.control-contrast"] == light["amber.contrast"])
        #expect(ratio(light["amber.control-contrast"]!, amber) >= 4.5)
    }

    @Test("a control fill that moved is the least move: a little closer to the canvas, it misses a target")
    func controlFillIsTheLeastMove() throws {
        let palette = try realPalette()
        let solved = try PaletteSolver.solve(palette)
        // Half a percent of OKLCH lightness: more than the 8-bit rounding of the stored color moves it.
        let back = 0.005
        var moved: [String] = []
        for theme in PaletteSolver.themes {
            let highContrast = theme.hasSuffix("-hc")
            let nonText = highContrast ? 4.5 : 3
            let text = highContrast ? 7 : 4.5
            // Toward the canvas: lighter in a light theme, darker in a dark one.
            let towardCanvas: Double = theme.hasPrefix("dark") ? -1 : 1
            let colors = full(solved, theme)
            let grounds = ["neutral.1", "neutral.raised", "neutral.sunken"].map { colors[$0]! }
            for hue in palette.hues {
                let control = try #require(colors["\(hue.name).control"])
                guard control != colors["\(hue.name).9"] else { continue }
                moved.append("\(theme) \(hue.name)")
                let label = try #require(colors["\(hue.name).control-contrast"])
                // The solver's own color at the stored lightness, stepped back, with step 9's chroma and hue.
                let closer = PaletteSolver.color(
                    OKLCH(control).l + towardCanvas * back, hue.chroma * palette.stepChroma[8], hue.hue)
                let meets = grounds.allSatisfy { ratio(closer, $0) >= nonText } && ratio(label, closer) >= text
                #expect(!meets, "\(theme) \(hue.name).control moved further from the canvas than it must")
            }
        }
        // The light themes move amber and olive at least, so the check is not empty.
        #expect(moved.contains("light amber") && moved.contains("light olive"), "moved: \(moved)")
    }

    @Test("a dark label at 7:1 on a fill at 4.5:1 to a light canvas is impossible, so the control takes white")
    func controlLabelFlips() throws {
        let solved = try PaletteSolver.solve(load(fixture))
        let base = full(solved, "light")
        let highContrast = full(solved, "light-hc")
        let white = RGB(.sRGB, red: 1, green: 1, blue: 1)
        let ink = try #require(base["amber.contrast"])
        #expect(highContrast["amber.contrast"] == ink, "the solid fill keeps its dark label")
        #expect(highContrast["amber.control-contrast"] == white)
        let control = try #require(highContrast["amber.control"])
        let grounds = ["neutral.1", "neutral.raised", "neutral.sunken"].map { highContrast[$0]! }
        #expect(grounds.allSatisfy { ratio(control, $0) >= 4.5 })
        #expect(ratio(white, control) >= 7)

        // The same case, solved directly: a fill under a dark label, held to 4.5 on a light canvas and 7 under it.
        // Under the ink no fill meets both, since 4.5 × 7 exceeds the 21:1 that WCAG's ratio can reach.
        let canvas = base["neutral.1"]!
        let start = PaletteSolver.color(0.8, 0.16, 80)
        let solvedControl = try PaletteSolver.solveControl(
            "light-hc", "amber", from: (start, 0.8), label: ink, chroma: 0.16, hue: 80, grounds: [canvas],
            direction: -1, nonText: 4.5, text: 7)
        #expect(solvedControl.label == white)
        #expect(ratio(solvedControl.fill, canvas) >= 4.5 && ratio(white, solvedControl.fill) >= 7)
    }

    @Test("light themes walk darker from the canvas, dark themes lighter; neither is an inversion of the other")
    func directions() throws {
        let solved = try PaletteSolver.solve(load(fixture))
        for (theme, darker) in [("light", true), ("dark", false)] {
            let colors = full(solved, theme)
            let luminances = (1...8).map { WCAG.relativeLuminance(colors["blue.\($0)"]!) }
            #expect(luminances == (darker ? luminances.sorted(by: >) : luminances.sorted()), "\(theme)")
        }
    }

    @Test("a light tint outside sRGB loses chroma, not hue: blue stays blue instead of turning cyan")
    func keepsHue() throws {
        let tint = PaletteSolver.color(0.96, 0.0359, 262)
        let hue = try #require(OKLCH(tint).h)
        #expect(abs(hue - 262) < 4, "hue \(hue)")
    }

    @Test("token files: generated header, one token per line, OKLCH that converts back to the hex")
    func tokenFiles() throws {
        let files = try PaletteTokens.files(for: load(fixture), source: "tokens/palette.json")
        #expect(files.map(\.path) == PaletteSolver.themes.map { "tokens/primitive/color.\($0).tokens.json" })
        let light = files[0].contents
        #expect(light.contains(#""$description": "Generated by `tools/westron generate` from tokens/palette.json"#))
        #expect(
            light.contains(
                ##""raised": {"$value": {"colorSpace": "oklch", "components": [1, 0, "none"], "hex": "#FFFFFF"}}"##))
        let tree = try TokenTree.load(Data(light.utf8), source: "color.light.tokens.json")
        #expect(tree.node(at: "color.neutral.raised") != nil && tree.node(at: "color.blue.contrast") != nil)
        #expect(tree.node(at: "color.blue.fill-pressed") != nil && tree.node(at: "color.amber.fill-pressed") != nil)
        #expect(tree.node(at: "color.amber.control") != nil && tree.node(at: "color.amber.control-contrast") != nil)
        #expect(try PaletteTokens.files(for: load(fixture), source: "tokens/palette.json") == files, "deterministic")
    }

    @Test("a source with wrong counts, names or ranges is rejected with every problem")
    func invalid() {
        let broken = fixture.replacingOccurrences(of: #""name": "amber""#, with: #""name": "Amber""#)
            .replacingOccurrences(of: #""light": [1.06, 1.09, 1.11, 1.16, 1.27, 1.6]"#, with: #""light": [1.09, 1.06]"#)
            .replacingOccurrences(
                of: #""raised": {"light": 1, "dark": 0.224}"#, with: #""raised": {"light": 1, "dark": 0.1}"#)
        #expect(throws: PaletteSource.Invalid.self) { try load(broken) }
        do {
            _ = try load(broken)
        } catch let invalid as PaletteSource.Invalid {
            #expect(
                invalid.problems == [
                    "steps.light has 6 values, for steps 2–7",
                    "steps.light: each step contrasts more than the one before",
                    "neutral.raised is lighter than the canvas: higher is lighter in every theme",
                    "hues: Amber is not a token name in lowercase kebab-case",
                ])
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("a target no lightness reaches names the token and the theme")
    func unreachable() throws {
        let palette = try load(
            fixture.replacingOccurrences(
                of: #""dark": [1.14, 1.18, 1.23, 1.36, 1.45, 1.8]"#,
                with: #""dark": [1.14, 1.18, 1.23, 1.36, 1.45, 30]"#))
        #expect(throws: PaletteSolver.Unreachable(theme: "dark", path: ["neutral", "7"], target: "30.0:1")) {
            try PaletteSolver.solve(palette)
        }
    }
}
