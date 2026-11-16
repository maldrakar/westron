import Foundation
import Testing
import WestronTools

/// Cases an independent review of the tools found on 2026-11-15, each an input that used to pass or hang.
@Suite("Review regressions")
struct ReviewRegressionTests {
    @Test("a high-contrast override without its contrast declaration is an error, not a skipped pair")
    func overrideDropsDeclaration() throws {
        let files = [
            "r.resolver.json": resolver(
                ##"""
                "sets": { "base": { "sources": [{ "$ref": "base.tokens.json" }] } },
                "modifiers": {
                  "theme": {
                    "contexts": { "light": [], "light-hc": [{ "$ref": "hc.tokens.json" }] }, "default": "light"
                  }
                },
                "resolutionOrder": [{ "$ref": "#/sets/base" }, { "$ref": "#/modifiers/theme" }]
                """##),
            "base.tokens.json": ##"""
            {
              "color": {
                "$type": "color",
                "bg": { "$value": { "colorSpace": "srgb", "components": [1, 1, 1] } },
                "text": {
                  "$value": { "colorSpace": "srgb", "components": [0.4627, 0.4627, 0.4627] },
                  "$extensions": { "dev.westron.contrast": [{ "kind": "text", "on": ["color.bg"] }] }
                }
              }
            }
            """##,
            "hc.tokens.json": ##"""
            { "color": { "$type": "color", "text": { "$value": { "colorSpace": "srgb", "components": [0.8, 0.8, 0.8] } } } }
            """##,
        ]
        let error = #expect(throws: TokenErrors.self) { try ContrastCheck.run(resolution(files)) }
        #expect(
            error?.errors.map(\.message) == [
                "declares no dev.westron.contrast in theme light-hc, but does in theme light: an override replaces a "
                    + "token whole, so it must restate the declaration"
            ])
    }

    @Test("a huge or infinite chroma ends: it is mapped or clipped instead of looping forever")
    func hugeChroma() {
        let color = OKLCH(OKLab(l: 0.5, a: 1e200, b: 0, alpha: 1))
        #expect(color.c.isFinite)
        #expect(color.mapped(into: .sRGB).isInGamut())
        // Not a color any file can hold; it only has to return.
        _ = OKLCH(l: 0.5, c: .infinity, h: 0, alpha: 1).mapped(into: .sRGB)
    }

    @Test("a \\u escape takes exactly four hex digits, without a sign")
    func signedEscape() {
        #expect(throws: JSON.SyntaxError.self) { try JSON.parse(Data(#"["\u+041"]"#.utf8)) }
        #expect(throws: JSON.SyntaxError.self) { try JSON.parse(Data(#"["\u-000"]"#.utf8)) }
        #expect((try? JSON.parse(Data(#"["\u0041"]"#.utf8))) == .array([.string("A")]))
    }

    @Test("names are compared by code point: canonically equivalent keys are two names")
    func canonicalEquivalence() throws {
        let composed = "\u{E9}"
        let decomposed = "e\u{301}"
        let json =
            #"{ "\#(composed)": { "$type": "number", "$value": 1 }, "\#(decomposed)": { "$type": "number", "$value": 2 } }"#
        let tokens = try load(json).resolve()
        #expect(tokens.count == 2)
        #expect(TokenPath([composed]) != TokenPath([decomposed]))
    }

    @Test("a dot followed by a combining mark is still a dot in a name")
    func dotWithCombiningMark() {
        #expect(throws: TokenErrors.self) {
            try load(#"{ "a.\#u{301}b": { "$type": "number", "$value": 1 } }"#)
        }
    }

    @Test("a hex fallback takes ASCII hex digits only")
    func fullwidthHex() {
        #expect(throws: TokenErrors.self) {
            try load(
                ##"{ "c": { "$type": "color", "$value": { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#ＦＦＦＦＦＦ" } } }"##
            )
        }
    }
}
