import Foundation
import Testing
import WestronTools

/// The resolved tokens of a token file written inline.
private func tokens(_ json: String) throws -> [ResolvedToken] {
    try load(json, source: "theme.tokens.json").resolve()
}

/// A token file with the backgrounds below, a dimension, and the given foreground tokens in `color.text`.
private func theme(_ foregrounds: [String]) -> String {
    """
    {
      "color": {
        "$type": "color",
        "background": {
          "white": {"$value": {"colorSpace": "srgb", "components": [1, 1, 1]}},
          "red": {"$value": {"colorSpace": "srgb", "components": [1, 0, 0]}},
          "veil": {"$value": {"colorSpace": "srgb", "components": [0, 0, 0], "alpha": 0.5}},
          "mist": {"$value": {"colorSpace": "srgb", "components": [1, 1, 1], "alpha": 0.5}},
          "green-p3": {"$value": {"colorSpace": "display-p3", "components": [0, 1, 0]}},
          "lab": {"$value": {"colorSpace": "lab", "components": [50, 0, 0]}}
        },
        "text": {\(foregrounds.joined(separator: ", "))}
      },
      "space": {"m": {"$type": "dimension", "$value": {"value": 8, "unit": "px"}}}
    }
    """
}

/// A foreground token in `color.text` with a color value and a contrast declaration.
private func foreground(_ name: String, _ value: String, _ declaration: String) -> String {
    #""\#(name)": {"$value": \#(value), "$extensions": {"dev.westron.contrast": \#(declaration)}}"#
}

/// An opaque sRGB color as a token value.
private func srgb(_ red: Double, _ green: Double, _ blue: Double, alpha: Double = 1) -> String {
    #"{"colorSpace": "srgb", "components": [\#(red), \#(green), \#(blue)], "alpha": \#(alpha)}"#
}

/// `kind path: message` of each error of the check.
private func contrastProblems(_ json: String) throws -> [String] {
    let resolved = try tokens(json)
    do {
        _ = try ContrastCheck.run(resolved, theme: .standard)
        return []
    } catch let errors as TokenErrors {
        return errors.errors.map { "\($0.kind.rawValue) \($0.path): \($0.message)" }
    }
}

@Suite("Contrast check")
struct ContrastCheckTests {
    /// Expected ratios from the Python reference implementation of the color tests (CSS Color 4 conversion and gamut
    /// mapping, WCAG 2 luminance, compositing in gamma-encoded sRGB), tolerance 1e-9.
    @Test("measures plain, stacked, translucent, OkLCh and Display P3 colors")
    func ratios() throws {
        let json = theme([
            foreground(
                "black", srgb(0, 0, 0),
                #"[{"kind": "text", "on": ["color.background.white", ["color.background.veil", "color.background.white"]]}]"#
            ),
            foreground(
                "half", srgb(0, 0, 0, alpha: 0.5), #"[{"kind": "large-text", "on": ["color.background.white"]}]"#),
            foreground(
                "ink", #"{"colorSpace": "oklch", "components": [0.2319, 0.00644, 78.2]}"#,
                #"[{"kind": "text", "on": ["color.background.white"]}, {"kind": "non-text", "on": ["color.background.green-p3"]}]"#
            ),
            foreground(
                "white", srgb(1, 1, 1),
                #"[{"kind": "text", "on": [["color.background.veil", "color.background.mist", "color.background.red"]]}]"#
            ),
        ])
        let expected: [(foreground: String, background: [String], kind: ContrastCheck.Kind, ratio: Double)] = [
            ("text.black", ["color.background.white"], .text, 21),
            // The veil, black at 50 %, over white is gray 0.5.
            ("text.black", ["color.background.veil", "color.background.white"], .text, 5.280822809644651),
            // A translucent foreground is composited too: black at 50 % over white.
            ("text.half", ["color.background.white"], .largeText, 3.976653024912438),
            // oklch(0.2319 0.00644 78.2), the pilot's ink #1F1D1A rounded to 4, 5 and 2 decimals.
            ("text.ink", ["color.background.white"], .text, 16.812435119752816),
            // Display P3 green mapped into sRGB, (0, 0.98576, 0.15974).
            ("text.ink", ["color.background.green-p3"], .nonText, 11.910225015847828),
            // Mist over red is (1, 0.5, 0.5); the veil over that is (0.5, 0.25, 0.25).
            (
                "text.white", ["color.background.veil", "color.background.mist", "color.background.red"], .text,
                7.745363243684572
            ),
        ]
        let results = try ContrastCheck.run(tokens(json), theme: .standard)
        #expect(results.count == expected.count)
        for (result, row) in zip(results, expected) {
            #expect(result.foreground == TokenPath("color." + row.foreground))
            #expect(result.background == row.background.map { TokenPath($0) })
            #expect(result.kind == row.kind)
            #expect(near(result.ratio, row.ratio, 1e-9), "\(row.foreground) on \(row.background): \(result.ratio)")
            #expect(result.target == row.kind.target(in: .standard) && result.passes)
        }
    }

    @Test("targets by kind and kind of theme, as decisions/0012 gives them")
    func targets() {
        let table: [(ContrastCheck.Kind, Double?, Double?)] = [
            (.text, 4.5, 7), (.largeText, 3, 4.5), (.nonText, 3, 4.5), (.separator, nil, 3), (.chart, 3, 3),
        ]
        #expect(table.map(\.0) == ContrastCheck.Kind.allCases)
        for (kind, standard, high) in table {
            #expect(kind.target(in: .standard) == standard && kind.target(in: .highContrast) == high, "\(kind)")
        }
    }

    /// WebAIM's contrast checker gives #767676 on white 4.54 and #777777 4.48.
    @Test("passes and fails against the target of the theme")
    func passAndFail() throws {
        let json = theme([
            foreground(
                "gray76", srgb(118.0 / 255, 118.0 / 255, 118.0 / 255),
                #"[{"kind": "text", "on": ["color.background.white"]}]"#),
            foreground(
                "gray77", srgb(119.0 / 255, 119.0 / 255, 119.0 / 255),
                #"[{"kind": "text", "on": ["color.background.white"]}, {"kind": "large-text", "on": ["color.background.white"]}]"#
            ),
            foreground(
                "rule", srgb(224.0 / 255, 224.0 / 255, 224.0 / 255),
                #"[{"kind": "separator", "on": ["color.background.white"]}]"#),
        ])
        let standard = try ContrastCheck.run(tokens(json), theme: .standard)
        #expect(standard.map(\.passes) == [true, false, true, true])
        #expect(near(standard[0].ratio, 4.54, 0.005) && near(standard[1].ratio, 4.48, 0.005))
        // A separator has no target in a standard theme, so even 1.32 passes.
        #expect(standard[3].target == nil && near(standard[3].ratio, 1.32, 0.005))
        let high = try ContrastCheck.run(tokens(json), theme: .highContrast)
        #expect(high.map(\.passes) == [false, false, false, false])
        #expect(high.map(\.target) == [7, 7, 4.5, 3])
    }

    /// The shape of a declaration and whether its paths name color tokens are the reader's to check
    /// (`WestronExtensionsTests`); these are the problems only the colors of a resolved theme show.
    @Test("an unconvertible color and a translucent bottom are errors")
    func errors() throws {
        let json = theme([
            foreground(
                "d", srgb(0, 0, 0),
                #"[{"kind": "text", "on": ["color.background.lab", ["color.background.veil"], "#
                    + #"["color.background.veil", "color.background.mist"]]}]"#
            ),
            foreground(
                "e", #"{"colorSpace": "hsl", "components": [0, 0, 0]}"#,
                #"[{"kind": "text", "on": ["color.background.white"]}]"#),
        ])
        let found = try contrastProblems(json)
        let prefix = "dev.westron.contrast"
        #expect(
            found == [
                "unsupported color.text.d: \(prefix)[0].on[0]: color.background.lab is in lab, which the contrast check "
                    + "cannot convert",
                "invalidValue color.text.d: \(prefix)[0].on[1]: color.background.veil is translucent (alpha 0.5); write "
                    + "the background as a stack, top first, that ends in an opaque color",
                "invalidValue color.text.d: \(prefix)[0].on[2]: the bottom of the stack, color.background.mist, is "
                    + "translucent (alpha 0.5); a stack must end in an opaque color",
                "unsupported color.text.e: the token is in hsl, which the contrast check cannot convert",
            ], "\(found)")
    }

    /// colorjs.io 0.5.2 for the Display P3 and Oklab values; the other spaces are exact.
    @Test("token colors convert to sRGB from every space the color code supports")
    func tokenColors() {
        func color(_ space: TokenValue.Color.Space, _ components: [TokenValue.Color.Component], alpha: Double = 1)
            -> RGB?
        {
            TokenValue.Color(colorSpace: space, components: components, alpha: alpha).mapped(into: .sRGB)
        }
        #expect(
            color(.srgb, [.number(0.2), .none, .number(1)], alpha: 0.4)
                == RGB(.sRGB, red: 0.2, green: 0, blue: 1, alpha: 0.4))
        #expect(
            near(
                color(.srgbLinear, [.number(0.21586050011389926), .number(0), .number(1)])!, (0.5019607843137255, 0, 1),
                1e-12))
        #expect(
            near(
                color(.xyzD65, [.number(0.95045592705167159), .number(1), .number(1.0890577507598784)])!, (1, 1, 1),
                1e-9))
        #expect(
            near(
                color(.displayP3, [.number(1), .number(1), .number(0)])!, (0.99623327296097253, 0.99901389584961053, 0),
                1e-9))
        #expect(
            near(
                color(
                    .oklab, [.number(0.62795536392143114), .number(0.22486306842627440), .number(0.12584627733058501)])!,
                (1, 0, 0), 1e-9))
        let gray = color(.oklch, [.number(0.5998708056221469), .number(0), .none])
        #expect(gray.map { near($0, (0.5019607843137255, 0.5019607843137255, 0.5019607843137255), 1e-9) } == true)
        for space in [TokenValue.Color.Space.hsl, .hwb, .lab, .lch, .a98RGB, .prophotoRGB, .rec2020, .xyzD50] {
            #expect(color(space, [.number(0), .number(0), .number(0)]) == nil, "\(space)")
        }
    }

    @Test("the report lists each theme's failures first, then a summary line")
    func report() throws {
        let json = theme([
            foreground(
                "gray76", srgb(118.0 / 255, 118.0 / 255, 118.0 / 255),
                #"[{"kind": "text", "on": ["color.background.white"]}]"#),
            foreground(
                "gray77", srgb(119.0 / 255, 119.0 / 255, 119.0 / 255),
                #"[{"kind": "text", "on": ["color.background.white", ["color.background.veil", "color.background.white"]]}]"#
            ),
            foreground(
                "rule", srgb(224.0 / 255, 224.0 / 255, 224.0 / 255),
                #"[{"kind": "separator", "on": ["color.background.white"]}]"#),
        ])
        let resolved = try tokens(json)
        let report = ContrastCheck.report([
            .init(name: "light", kind: .standard, results: try ContrastCheck.run(resolved, theme: .standard)),
            .init(
                name: "light-hc", kind: .highContrast, results: try ContrastCheck.run(resolved, theme: .highContrast)),
        ])
        // The Python reference gives #777777 on white 4.478…, shown truncated as 4.47, and on the veil over white
        // 1.126…; #767676 on white 4.542…; #E0E0E0 on white 1.320….
        #expect(
            report == """
                light (standard): 4 checks, 2 failed
                foreground         background                                         kind       ratio  target  result
                color.text.gray77  color.background.white                             text        4.47     4.5  FAIL
                color.text.gray77  color.background.veil over color.background.white  text        1.12     4.5  FAIL
                color.text.gray76  color.background.white                             text        4.54     4.5  ok
                color.text.rule    color.background.white                             separator   1.32    none  ok

                light-hc (high contrast): 4 checks, 4 failed
                foreground         background                                         kind       ratio  target  result
                color.text.gray76  color.background.white                             text        4.54       7  FAIL
                color.text.gray77  color.background.white                             text        4.47       7  FAIL
                color.text.gray77  color.background.veil over color.background.white  text        1.12       7  FAIL
                color.text.rule    color.background.white                             separator   1.32       3  FAIL

                contrast: 2 themes, 8 checks, 6 failed (light 2, light-hc 4)

                """)
        #expect(ContrastCheck.report([]) == "contrast: 0 themes, 0 checks, 0 failed\n")
    }
}
