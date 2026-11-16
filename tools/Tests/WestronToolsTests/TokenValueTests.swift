import Foundation
import Testing
import WestronTools

@Suite("Token values")
struct TokenValueTests {
    @Test("reads a token of every supported type")
    func everySupportedType() throws {
        let tokens = try TokenTree.load(fixtureData("tokens/types.tokens.json"), source: "types.tokens.json")
            .resolve()
        let values = Dictionary(uniqueKeysWithValues: tokens.map { ($0.path.description, $0.value) })
        let black = TokenValue.Color.srgb(0, 0, 0, alpha: 0.2)
        #expect(
            values == [
                "color.accent": .color(
                    .init(
                        colorSpace: .oklch, components: [.number(0.62), .number(0.19), .number(259.8)], alpha: 1,
                        hex: "#3366e6")),
                "color.overlay": .color(.srgb(0, 0, 0, alpha: 0.4)),
                "color.white": .color(.init(colorSpace: .hsl, components: [.none, .number(0), .number(100)])),
                "color.wide": .color(
                    .init(colorSpace: .displayP3, components: [.number(1), .number(0), .number(0.5)])),
                "space.m": .dimension(.px(8)),
                "space.text": .dimension(.init(1.25, .rem)),
                "opacity.disabled": .number(0.4),
                "motion.duration.fast": .duration(.init(150, .ms)),
                "motion.duration.slow": .duration(.init(0.5, .s)),
                "motion.easing.standard": .cubicBezier(.init(0.2, 0, 0, 1)),
                "motion.fade": .transition(
                    .init(duration: .init(150, .ms), delay: .init(0, .ms), timingFunction: .init(0.2, 0, 0, 1))),
                "motion.drop": .transition(
                    .init(duration: .init(0.32, .s), delay: .init(40, .ms), timingFunction: .init(0.34, 1.56, 0.64, 1))),
                "font.family.body": .fontFamily(["Inter", "system-ui"]),
                "font.family.mono": .fontFamily(["JetBrains Mono"]),
                "font.weight.regular": .fontWeight(.init(400, name: "regular")),
                "font.weight.semibold": .fontWeight(.init(600)),
                "text.body": .typography(
                    .init(
                        fontFamily: ["Inter"], fontSize: .px(16), fontWeight: .init(400), letterSpacing: .px(0),
                        lineHeight: 1.5)),
                "shadow.card": .shadow([
                    .init(color: black, offsetX: .px(0), offsetY: .px(2), blur: .px(8), spread: .px(0))
                ]),
                "shadow.pressed": .shadow([
                    .init(
                        color: .srgb(0, 0, 0, alpha: 0.1), offsetX: .px(0), offsetY: .px(1), blur: .px(2),
                        spread: .px(0)),
                    .init(
                        color: .srgb(0, 0, 0, alpha: 0.3), offsetX: .px(0), offsetY: .px(1), blur: .px(3),
                        spread: .px(-1), inset: true),
                ]),
            ])
        #expect(Set(tokens.map(\.type)) == Set(TokenType.allCases))
        #expect(TokenValue.Duration(0.5, .s).milliseconds == 500)
    }

    @Test("a color has three components in every color space", arguments: TokenValue.Color.Space.allCases)
    func componentCount(_ space: TokenValue.Color.Space) {
        #expect(problems(token("color", #"{ "colorSpace": "\#(space.rawValue)", "components": [0, 0, 0] }"#)) == [])
        for components in ["[0, 0]", "[0, 0, 0, 0]"] {
            let errors = problems(
                token("color", #"{ "colorSpace": "\#(space.rawValue)", "components": \#(components) }"#))
            #expect(summary(errors) == ["invalidValue t"])
            #expect(errors.first?.message.contains("has 3 components") == true)
        }
    }

    @Test(
        "each color component must be in the range of its color space",
        arguments: [
            ("srgb", "[0, 0, 1.01]"), ("srgb", "[-0.1, 0, 0]"), ("srgb-linear", "[0, 2, 0]"),
            ("display-p3", "[1.5, 0, 0]"), ("a98-rgb", "[0, 0, -1]"), ("prophoto-rgb", "[2, 0, 0]"),
            ("rec2020", "[0, 1.1, 0]"), ("xyz-d65", "[0, 0, 1.2]"), ("xyz-d50", "[-0.1, 0, 0]"),
            ("hsl", "[360, 50, 50]"), ("hsl", "[0, 101, 50]"), ("hsl", "[0, 50, -1]"), ("hwb", "[-1, 0, 0]"),
            ("hwb", "[0, 0, 100.5]"), ("lab", "[101, 0, 0]"), ("lch", "[50, -1, 0]"), ("lch", "[50, 10, 360]"),
            ("oklab", "[1.1, 0, 0]"), ("oklch", "[0.5, -0.1, 0]"), ("oklch", "[0.5, 0.1, 360]"),
            ("srgb", #"["none", "nan", 0]"#),
        ])
    func componentRange(_ space: String, _ components: String) {
        let errors = problems(token("color", #"{ "colorSpace": "\#(space)", "components": \#(components) }"#))
        #expect(summary(errors) == ["invalidValue t"], "\(space) \(components)")
    }

    @Test("unbounded components, edges of ranges and none are allowed")
    func componentEdges() throws {
        let documents = [
            #"{ "colorSpace": "lab", "components": [100, -160, 160] }"#,
            #"{ "colorSpace": "oklab", "components": [0, -0.5, 0.5] }"#,
            #"{ "colorSpace": "oklch", "components": [1, 0.5, 359.99] }"#,
            #"{ "colorSpace": "lch", "components": [0, 230, 0] }"#,
            #"{ "colorSpace": "srgb", "components": ["none", "none", "none"], "alpha": 0 }"#,
        ]
        for document in documents {
            #expect(problems(token("color", document)) == [], "\(document)")
        }
    }

    @Test(
        "rejects a malformed color",
        arguments: [
            #"{ "colorSpace": "cmyk", "components": [0, 0, 0] }"#,
            #"{ "colorSpace": "srgb" }"#,
            #"{ "components": [0, 0, 0] }"#,
            #"{ "colorSpace": "srgb", "components": "0 0 0" }"#,
            #"{ "colorSpace": "srgb", "components": [0, 0, 0], "alpha": 1.5 }"#,
            #"{ "colorSpace": "srgb", "components": [0, 0, 0], "alpha": -0.1 }"#,
            ##"{ "colorSpace": "srgb", "components": [0, 0, 0], "hex": "#fff" }"##,
            ##"{ "colorSpace": "srgb", "components": [0, 0, 0], "hex": "#ff00ff80" }"##,
            ##"{ "colorSpace": "srgb", "components": [0, 0, 0], "hex": "ff00ff" }"##,
            ##"{ "colorSpace": "srgb", "components": [0, 0, 0], "hex": "#gg0000" }"##,
            ##""#000000""##,
        ])
    func malformedColor(_ value: String) {
        #expect(summary(problems(token("color", value))) == ["invalidValue t"], "\(value)")
    }

    @Test(
        "rejects a malformed dimension, duration, number or cubic Bézier",
        arguments: [
            ("dimension", #"{ "value": 8, "unit": "pt" }"#), ("dimension", #"{ "value": "8", "unit": "px" }"#),
            ("dimension", #"{ "value": 8 }"#), ("dimension", #""8px""#),
            ("duration", #"{ "value": 1, "unit": "min" }"#),
            ("duration", #"{ "unit": "ms" }"#), ("number", #""1""#), ("number", "true"), ("number", "[1]"),
            ("cubicBezier", "[0, 0, 1]"), ("cubicBezier", "[0, 0, 1, 1, 1]"), ("cubicBezier", "[-0.1, 0, 1, 1]"),
            ("cubicBezier", "[0, 0, 1.1, 1]"), ("cubicBezier", #"["0", 0, 1, 1]"#),
        ])
    func malformedSimpleValue(_ type: String, _ value: String) {
        #expect(summary(problems(token(type, value))) == ["invalidValue t"], "\(type) \(value)")
    }

    @Test("cubic Bézier y coordinates may be outside [0, 1]")
    func cubicBezierOvershoot() throws {
        let tokens = try resolve(token("cubicBezier", "[0.3, -0.5, 0.7, 1.5]"))
        #expect(tokens["t"]?.value == .cubicBezier(.init(0.3, -0.5, 0.7, 1.5)))
    }

    @Test("a font weight is a number in [1, 1000] or a case-sensitive name")
    func fontWeights() throws {
        for (name, value) in TokenValue.FontWeight.names {
            #expect(
                try resolve(token("fontWeight", "\"\(name)\""))["t"]?.value == .fontWeight(.init(value, name: name)))
        }
        #expect(try resolve(token("fontWeight", "1"))["t"]?.value == .fontWeight(.init(1)))
        #expect(try resolve(token("fontWeight", "1000"))["t"]?.value == .fontWeight(.init(1000)))
        for value in ["0", "1001", #""Bold""#, #""heavyweight""#, "[400]"] {
            #expect(summary(problems(token("fontWeight", value))) == ["invalidValue t"], "\(value)")
        }
    }

    @Test("a font family is a name or a non-empty list of names without references")
    func fontFamilies() {
        for value in ["[]", "[1]", #"[""]"#, #"["Inter", "{font.other}"]"#, "{}", "7"] {
            #expect(summary(problems(token("fontFamily", value))) == ["invalidValue t"], "\(value)")
        }
    }

    @Test("typography needs all five properties and no others")
    func typographyProperties() {
        let complete = [
            #""fontFamily": "Inter""#, #""fontSize": { "value": 16, "unit": "px" }"#, #""fontWeight": 400"#,
            #""letterSpacing": { "value": 0, "unit": "px" }"#, #""lineHeight": 1.5"#,
        ]
        #expect(problems(token("typography", "{ \(complete.joined(separator: ", ")) }")) == [])
        for index in complete.indices {
            var missing = complete
            missing.remove(at: index)
            #expect(
                summary(problems(token("typography", "{ \(missing.joined(separator: ", ")) }"))) == ["invalidValue t"])
        }
        let extra = complete + [#""fontStyle": "italic""#]
        #expect(summary(problems(token("typography", "{ \(extra.joined(separator: ", ")) }"))) == ["unknownProperty t"])
        let dimensionLineHeight = complete.dropLast() + [#""lineHeight": { "value": 24, "unit": "px" }"#]
        #expect(
            summary(problems(token("typography", "{ \(dimensionLineHeight.joined(separator: ", ")) }")))
                == ["invalidValue t"])
    }

    @Test("a transition needs a duration, a delay and a cubic Bézier, each written out or a reference of that type")
    func transitions() {
        let duration = #""duration": { "value": 200, "unit": "ms" }"#
        let delay = #""delay": { "value": 0, "unit": "ms" }"#
        let curve = #""timingFunction": [0.2, 0, 0, 1]"#
        #expect(problems(token("transition", "{ \(duration), \(delay), \(curve) }")) == [])
        for missing in [[delay, curve], [duration, curve], [duration, delay]] {
            #expect(
                summary(problems(token("transition", "{ \(missing.joined(separator: ", ")) }"))) == ["invalidValue t"])
        }
        #expect(
            summary(problems(token("transition", #"{ \#(duration), \#(delay), "timingFunction": [1.5, 0, 0, 1] }"#)))
                == ["invalidValue t"])
        #expect(
            summary(problems(token("transition", #"{ \#(duration), \#(delay), \#(curve), "easing": "ease" }"#)))
                == ["unknownProperty t"])
        let wrongReference = #"""
            {
              "n": { "$type": "number", "$value": 0.5 },
              "t": { "$type": "transition", "$value": { "duration": "{n}", "delay": { "value": 0, "unit": "ms" },
                     "timingFunction": [0.2, 0, 0, 1] } }
            }
            """#
        let errors = problems(wrongReference)
        #expect(summary(errors) == ["typeMismatch t"])
        #expect(errors.first?.message == "$value.duration: {n} is a number token, expected duration")
    }

    @Test("a shadow is one object or a non-empty list; inset is a boolean")
    func shadows() {
        let layer = #"""
            "color": { "colorSpace": "srgb", "components": [0, 0, 0] }, "offsetX": { "value": 0, "unit": "px" },
            "offsetY": { "value": 1, "unit": "px" }, "blur": { "value": 2, "unit": "px" }
            """#
        #expect(summary(problems(token("shadow", "{ \(layer) }"))) == ["invalidValue t"])
        let full = layer + #", "spread": { "value": 0, "unit": "px" }"#
        #expect(problems(token("shadow", "{ \(full) }")) == [])
        #expect(problems(token("shadow", "[{ \(full) }, { \(full), \"inset\": false }]")) == [])
        #expect(summary(problems(token("shadow", "[]"))) == ["invalidValue t"])
        #expect(summary(problems(token("shadow", #"{ \#(full), "inset": "yes" }"#))) == ["invalidValue t"])
        #expect(summary(problems(token("shadow", "[{ \(full) }, 7]"))) == ["invalidValue t"])
    }

    @Test("a reference is not allowed inside a value of a simple type")
    func referenceInSimpleSubValue() {
        let document = #"""
            {
              "n": { "$type": "number", "$value": 0.5 },
              "c": { "$type": "color", "$value": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": "{n}" } },
              "d": { "$type": "dimension", "$value": { "value": "{n}", "unit": "px" } },
              "e": { "$type": "cubicBezier", "$value": ["{n}", 0, 1, 1] }
            }
            """#
        let errors = problems(document)
        #expect(summary(errors) == ["invalidValue c", "invalidValue d", "invalidValue e"])
        #expect(errors.allSatisfy { $0.message.contains("a reference is allowed only as a whole $value") })
    }
}
