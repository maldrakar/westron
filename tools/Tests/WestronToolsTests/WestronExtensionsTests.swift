import Foundation
import Testing
import WestronTools

/// A document with two color tokens, `color.background.canvas` and `color.text.primary`; the text token has these
/// `$extensions`.
private func colors(_ extensions: String) -> String {
    ##"""
    {
      "color": {
        "$type": "color",
        "background": { "canvas": { "$value": { "colorSpace": "srgb", "components": [1, 1, 1] } } },
        "text": {
          "primary": { "$value": { "colorSpace": "srgb", "components": [0, 0, 0] }, "$extensions": \##(extensions) }
        }
      },
      "space": { "m": { "$type": "dimension", "$value": { "value": 8, "unit": "px" } } }
    }
    """##
}

/// A token of a type with these `$extensions`.
private func token(_ type: String, _ value: String, extensions: String) -> String {
    ##"{ "t": { "$type": "\##(type)", "$value": \##(value), "$extensions": \##(extensions) } }"##
}

private let transition =
    #"{ "duration": { "value": 200, "unit": "ms" }, "delay": { "value": 0, "unit": "ms" }, "timingFunction": [0.2, 0, 0, 1] }"#
private let typography = #"""
    { "fontFamily": "Inter", "fontSize": { "value": 17, "unit": "px" }, "fontWeight": 400,
      "letterSpacing": { "value": 0, "unit": "px" }, "lineHeight": 1.3 }
    """#

@Suite("westron $extensions keys")
struct WestronExtensionsTests {
    @Test("reads usage, contrast, apple and spring; other vendors' keys pass through")
    func readsEveryKey() throws {
        let text = try resolve(
            colors(
                #"""
                {
                  "dev.westron.usage": { "use": ["body text", "labels"], "avoid": "Text on the accent." },
                  "dev.westron.contrast": [
                    { "kind": "text", "on": ["color.background.canvas"] },
                    { "kind": "large-text", "on": [["color.background.canvas", "color.background.canvas"]] }
                  ],
                  "com.example.tool": { "anything": [1, 2, 3] }
                }
                """#))["color.text.primary"]
        #expect(text?.westron.usage == .init(use: ["body text", "labels"], avoid: "Text on the accent."))
        #expect(
            text?.westron.contrast == [
                .init(kind: .text, on: [["color.background.canvas"]]),
                .init(kind: .largeText, on: [["color.background.canvas", "color.background.canvas"]]),
            ])
        #expect(text?.extensions?["com.example.tool"]?["anything"] == .array([.number(1), .number(2), .number(3)]))

        let style = try resolve(
            token("typography", typography, extensions: #"{ "dev.westron.apple": { "textStyle": "headline" } }"#))
        #expect(style["t"]?.westron.apple == .init(textStyle: .headline))
        let motion = try resolve(
            token(
                "transition", transition, extensions: #"{ "dev.westron.spring": { "duration": 0.45, "bounce": 0.2 } }"#)
        )
        #expect(motion["t"]?.westron.spring == .init(duration: 0.45, bounce: 0.2))
        #expect(motion["t"]?.westron.usage == nil)
        #expect(motion["t"]?.westron.contrast == [])
    }

    @Test("every contrast kind and every text style is accepted")
    func allKinds() throws {
        for kind in WestronExtensions.Contrast.Kind.allCases {
            #expect(
                problems(
                    colors(
                        #"{ "dev.westron.contrast": [{ "kind": "\#(kind.rawValue)", "on": ["color.background.canvas"] }] }"#
                    ))
                    == [])
        }
        for style in WestronExtensions.Apple.TextStyle.allCases {
            let extensions = #"{ "dev.westron.apple": { "textStyle": "\#(style.rawValue)" } }"#
            #expect(problems(token("typography", typography, extensions: extensions)) == [])
        }
    }

    @Test(
        "rejects an unknown westron key and malformed values",
        arguments: [
            (#"{ "dev.westron.usages": {} }"#, "unknownProperty"),
            (#"{ "dev.westron.usage": { "use": ["x"] } }"#, "invalidValue"),
            (#"{ "dev.westron.usage": { "use": [], "avoid": "y" } }"#, "invalidValue"),
            (#"{ "dev.westron.usage": { "use": "x", "avoid": "y" } }"#, "invalidValue"),
            (#"{ "dev.westron.usage": { "use": ["x"], "avoid": "" } }"#, "invalidValue"),
            (#"{ "dev.westron.usage": { "use": ["x"], "avoid": "y", "why": "z" } }"#, "unknownProperty"),
            (#"{ "dev.westron.contrast": [] }"#, "invalidValue"),
            (#"{ "dev.westron.contrast": { "kind": "text", "on": ["color.background.canvas"] } }"#, "invalidValue"),
            (#"{ "dev.westron.contrast": [{ "kind": "body", "on": ["color.background.canvas"] }] }"#, "invalidValue"),
            (#"{ "dev.westron.contrast": [{ "kind": "text", "on": [] }] }"#, "invalidValue"),
            (#"{ "dev.westron.contrast": [{ "kind": "text", "on": [[]] }] }"#, "invalidValue"),
            (#"{ "dev.westron.contrast": [{ "kind": "text", "on": [7] }] }"#, "invalidValue"),
            (#"{ "dev.westron.contrast": [{ "kind": "text", "on": ["background..canvas"] }] }"#, "invalidValue"),
            (
                #"{ "dev.westron.contrast": [{ "kind": "text", "on": ["color.background.canvas"], "min": 4.5 }] }"#,
                "unknownProperty"
            ),
            (#"{ "dev.westron.apple": "headline" }"#, "invalidValue"),
            (#"{ "dev.westron.apple": { "textStyle": "Headline" } }"#, "invalidValue"),
            (#"{ "dev.westron.apple": { "design": "rounded" } }"#, "unknownProperty"),
            (#"{ "dev.westron.spring": { "duration": 0, "bounce": 0 } }"#, "invalidValue"),
            (#"{ "dev.westron.spring": { "duration": 0.3, "bounce": 1.5 } }"#, "invalidValue"),
            (#"{ "dev.westron.spring": { "duration": 0.3 } }"#, "invalidValue"),
            (#"{ "dev.westron.spring": { "response": 0.3, "bounce": 0 } }"#, "unknownProperty"),
        ])
    func malformed(_ extensions: String, _ kind: String) {
        let errors = problems(colors(extensions))
        #expect(summary(errors) == ["\(kind) color.text.primary"], "\(extensions)")
        #expect(errors.first?.message.hasPrefix("$extensions.dev.westron.") == true)
    }

    @Test("westron's keys go on tokens, not on groups")
    func notOnGroups() {
        let document =
            #"{ "g": { "$extensions": { "dev.westron.usage": { "use": ["x"], "avoid": "y" } }, "t": { "$type": "number", "$value": 1 } } }"#
        #expect(summary(problems(document)) == ["unknownProperty g"])
        #expect(
            problems(#"{ "g": { "$extensions": { "com.example": 1 }, "t": { "$type": "number", "$value": 1 } } }"#)
                == [])
    }

    @Test("a spring only on a transition, a text style only on typography, contrast only on a color")
    func onTheRightType() {
        let spring = #"{ "dev.westron.spring": { "duration": 0.3, "bounce": 0 } }"#
        #expect(summary(problems(token("number", "1", extensions: spring))) == ["typeMismatch t"])
        let textStyle = #"{ "dev.westron.apple": { "textStyle": "body" } }"#
        #expect(
            summary(problems(token("dimension", #"{ "value": 1, "unit": "px" }"#, extensions: textStyle))) == [
                "typeMismatch t"
            ])
        #expect(problems(token("transition", transition, extensions: #"{ "dev.westron.apple": {} }"#)) == [])
        let contrast = #"{ "dev.westron.contrast": [{ "kind": "text", "on": ["color.background.canvas"] }] }"#
        #expect(summary(problems(token("number", "1", extensions: contrast))) == ["typeMismatch t"])
    }

    @Test("a contrast background must be a color token of the same resolution, by its whole path")
    func contrastBackgrounds() {
        let missing = problems(
            colors(#"{ "dev.westron.contrast": [{ "kind": "text", "on": ["color.background.surface"] }] }"#))
        #expect(summary(missing) == ["unknownReference color.text.primary"])
        #expect(
            missing.first?.message
                == "$extensions.dev.westron.contrast[0].on[0]: color.background.surface does not exist "
                + "(a background is a whole path)")
        let relative = problems(
            colors(#"{ "dev.westron.contrast": [{ "kind": "text", "on": ["background.canvas"] }] }"#))
        #expect(summary(relative) == ["unknownReference color.text.primary"])
        let notColor = problems(
            #"""
            {
              "color": {
                "ring": { "$type": "dimension", "$value": { "value": 2, "unit": "px" } },
                "text": { "$type": "color", "$value": { "colorSpace": "srgb", "components": [0, 0, 0] },
                  "$extensions": { "dev.westron.contrast": [{ "kind": "non-text", "on": ["color.ring"] }] } }
              }
            }
            """#)
        #expect(summary(notColor) == ["typeMismatch color.text"])
        #expect(notColor.first?.message.contains("color.ring is a dimension token, not a color") == true)
    }

    @Test("the contrast backgrounds are checked in each resolution, so a theme without the background fails")
    func contrastPerResolution() {
        let files = [
            "r.resolver.json": resolver(
                ##"""
                "modifiers": { "theme": { "contexts": { "light": [{ "$ref": "l.tokens.json" }], "dark": [{ "$ref": "d.tokens.json" }] } } },
                "resolutionOrder": [{ "$ref": "#/modifiers/theme" }]
                """##),
            "l.tokens.json": colors(
                #"{ "dev.westron.contrast": [{ "kind": "text", "on": ["color.background.canvas"] }] }"#),
            "d.tokens.json": ##"""
            { "color": { "$type": "color", "text": { "primary": {
              "$value": { "colorSpace": "srgb", "components": [1, 1, 1] },
              "$extensions": { "dev.westron.contrast": [{ "kind": "text", "on": ["color.background.canvas"] }] } } } } }
            """##,
        ]
        let errors = resolutionProblems(files)
        #expect(errors.map(\.kind) == [.unknownReference])
        #expect(errors.first?.source == "d.tokens.json")
        #expect(errors.first?.message.hasSuffix("(in theme=dark)") == true)
    }
}
