import Foundation
import Testing
import WestronTools

@Suite("Token references")
struct TokenResolveTests {
    private func aliases() throws -> [String: ResolvedToken] {
        let tokens = try TokenTree.load(fixtureData("tokens/aliases.tokens.json"), source: "aliases.tokens.json")
            .resolve()
        return Dictionary(uniqueKeysWithValues: tokens.map { ($0.path.description, $0) })
    }

    @Test("references inside a typography value resolve to the referenced values")
    func typographySubValues() throws {
        #expect(
            try aliases()["typography.body"]?.value
                == .typography(
                    .init(
                        fontFamily: ["Inter", "system-ui"], fontSize: .px(16), fontWeight: .init(400),
                        letterSpacing: .px(0), lineHeight: 1.5)))
    }

    @Test("references inside a shadow and in a shadow list resolve; a list is not flattened")
    func shadowSubValues() throws {
        let tokens = try aliases()
        let ink = TokenValue.Color.srgb(0, 0, 0, alpha: 0.25)
        let base = TokenValue.Shadow(color: ink, offsetX: .px(0), offsetY: .px(2), blur: .px(4), spread: .px(0))
        let second = TokenValue.Shadow(color: ink, offsetX: .px(0), offsetY: .px(8), blur: .px(16), spread: .px(0))
        #expect(tokens["shadow.base"]?.value == .shadow([base]))
        #expect(tokens["shadow.stack"]?.value == .shadow([base, second]))
        #expect(tokens["shadow.card"]?.value == .shadow([base, second]))
    }

    @Test("a chain of aliases resolves to the value at its end; each alias knows its direct target")
    func chains() throws {
        let tokens = try aliases()
        let black = TokenValue.color(.srgb(0, 0, 0, alpha: 0.25))
        #expect(tokens["palette.ink"]?.value == black)
        #expect(tokens["palette.ink"]?.aliasOf == "palette.black")
        #expect(tokens["color.shadow"]?.value == black)
        #expect(tokens["color.shadow"]?.aliasOf == "palette.ink")
        #expect(tokens["palette.black"]?.aliasOf == nil)
        #expect(tokens["shadow.base"]?.aliasOf == nil)
        #expect(tokens["shadow.card"]?.aliasOf == "shadow.stack")
    }

    @Test("an alias with no $type takes the type of its target")
    func untypedAliasTakesTargetType() throws {
        let tokens = try aliases()
        #expect(tokens["color.shadow"]?.type == .color)
        #expect(tokens["color.shadow"]?.description == "No $type: an alias takes the type of the token it refers to")
    }

    @Test("a reference may point at a token defined later in the file")
    func forwardReference() throws {
        let tokens = try resolve(#"{ "a": { "$value": "{b}" }, "b": { "$type": "number", "$value": 2 } }"#)
        #expect(tokens["a"]?.value == .number(2))
    }

    @Test(
        "a cycle is an error, reported once with the whole cycle",
        arguments: [
            (#"{ "a": { "$value": "{a}" } }"#, "a", "{a} → {a}"),
            (#"{ "a": { "$value": "{b}" }, "b": { "$value": "{a}" } }"#, "a", "{a} → {b} → {a}"),
            (
                #"{ "a": { "$value": "{b}" }, "b": { "$value": "{c}" }, "c": { "$value": "{a}" } }"#, "a",
                "{a} → {b} → {c} → {a}"
            ),
        ])
    func cycles(_ document: String, _ path: String, _ cycle: String) {
        let errors = problems(document)
        #expect(summary(errors) == ["circularReference \(path)"])
        #expect(errors.first?.message == "circular reference: \(cycle)")
    }

    @Test("a cycle through a composite sub-value is found; a token that only points into a cycle is not reported")
    func cycleThroughComposite() {
        let document = #"""
            {
              "size": { "$type": "dimension", "$value": "{gap}" },
              "gap": { "$type": "dimension", "$value": "{size}" },
              "outside": { "$type": "dimension", "$value": "{size}" },
              "shadow": {
                "$type": "shadow",
                "$value": {
                  "color": { "colorSpace": "srgb", "components": [0, 0, 0] },
                  "offsetX": "{size}", "offsetY": "{size}", "blur": "{size}", "spread": "{size}"
                }
              }
            }
            """#
        #expect(summary(problems(document)) == ["circularReference size"])
    }

    @Test("a reference to a missing token or to a group is an error")
    func unknownReferences() {
        let document = #"""
            {
              "group": { "$type": "number", "one": { "$value": 1 } },
              "missing": { "$type": "number", "$value": "{nothing.here}" },
              "toGroup": { "$type": "number", "$value": "{group}" },
              "intoValue": { "$type": "number", "$value": "{group.one.value}" },
              "text": {
                "$type": "typography",
                "$value": {
                  "fontFamily": "Inter", "fontSize": "{size.body}", "fontWeight": 400,
                  "letterSpacing": { "value": 0, "unit": "px" }, "lineHeight": 1.5
                }
              }
            }
            """#
        let errors = problems(document)
        #expect(
            summary(errors) == [
                "unknownReference missing", "unknownReference toGroup", "unknownReference intoValue",
                "unknownReference text",
            ])
        #expect(
            errors.map(\.message) == [
                "$value: {nothing.here} does not exist",
                "$value: {group} is a group, not a token",
                "$value: {group.one.value} points inside the token {group.one}; a reference names a whole token",
                "$value.fontSize: {size.body} does not exist",
            ])
    }

    @Test("a reference to a token of another type is an error, also inside a composite and through a group $type")
    func typeMismatch() {
        let document = #"""
            {
              "size": { "$type": "dimension", "$value": { "value": 8, "unit": "px" } },
              "ratio": { "$type": "number", "$value": 1.5 },
              "declared": { "$type": "color", "$value": "{size}" },
              "colors": { "$type": "color", "inherited": { "$value": "{size}" } },
              "text": {
                "$type": "typography",
                "$value": {
                  "fontFamily": "Inter", "fontSize": "{ratio}", "fontWeight": 400,
                  "letterSpacing": { "value": 0, "unit": "px" }, "lineHeight": "{size}"
                }
              }
            }
            """#
        let errors = problems(document)
        #expect(summary(errors) == ["typeMismatch declared", "typeMismatch colors.inherited", "typeMismatch text"])
        #expect(errors.first?.message == "$value: {size} is a dimension token, expected color")
        #expect(errors.last?.message == "$value.fontSize: {ratio} is a number token, expected dimension")
    }

    @Test("a reference in a shadow list must point to a single shadow")
    func shadowListReferenceToLayers() {
        let layer = #"""
            { "color": { "colorSpace": "srgb", "components": [0, 0, 0] }, "offsetX": { "value": 0, "unit": "px" },
              "offsetY": { "value": 1, "unit": "px" }, "blur": { "value": 2, "unit": "px" },
              "spread": { "value": 0, "unit": "px" } }
            """#
        let document = #"""
            {
              "$type": "shadow",
              "one": { "$value": [\#(layer)] },
              "two": { "$value": [\#(layer), \#(layer)] },
              "ok": { "$value": ["{one}", \#(layer)] },
              "nested": { "$value": ["{two}"] }
            }
            """#
        let errors = problems(document)
        #expect(summary(errors) == ["typeMismatch nested"])
        #expect(errors.first?.message.contains("{two} has 2 layers") == true)
    }

    @Test("a token whose referenced token fails is not reported again")
    func dependentNotReported() {
        let document = #"""
            {
              "a": { "$type": "number", "$value": "{missing}" },
              "b": { "$value": "{a}" },
              "c": { "$value": "{b}" }
            }
            """#
        #expect(summary(problems(document)) == ["unknownReference a"])
    }
}
