import Foundation
import Testing
import WestronTools

/// A small resolver in the shape of westron's, for the Apple generator: primitives, semantic tokens of every type
/// Apple generates, four themes, two densities and the three Apple platforms. Each file can be replaced.
enum AppleFixture {
    static let resolver = ##"""
        {
          "version": "2025.10",
          "sets": {
            "primitive": { "sources": [{ "$ref": "primitive.tokens.json" }] },
            "semantic": { "sources": [{ "$ref": "semantic.tokens.json" }] }
          },
          "modifiers": {
            "theme": {
              "contexts": {
                "light": [{ "$ref": "light.tokens.json" }],
                "dark": [{ "$ref": "dark.tokens.json" }],
                "light-hc": [{ "$ref": "light.tokens.json" }, { "$ref": "light-hc.tokens.json" }],
                "dark-hc": [{ "$ref": "dark.tokens.json" }]
              },
              "default": "light"
            },
            "density": {
              "contexts": { "regular": [], "compact": [{ "$ref": "compact.tokens.json" }] },
              "default": "regular"
            },
            "platform": {
              "contexts": { "ios": [], "macos": [{ "$ref": "macos.tokens.json" }], "watchos": [] }
            }
          },
          "resolutionOrder": [
            { "$ref": "#/sets/primitive" },
            { "$ref": "#/sets/semantic" },
            { "$ref": "#/modifiers/theme" },
            { "$ref": "#/modifiers/density" },
            { "$ref": "#/modifiers/platform" }
          ]
        }
        """##

    static let primitive = ##"""
        {
          "color": {
            "$type": "color",
            "ink": { "$value": { "colorSpace": "srgb", "components": [0.1216, 0.1137, 0.102], "hex": "#1F1D1A" } },
            "paper": { "$value": { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#FFFFFF" } }
          },
          "easing": { "$type": "cubicBezier", "standard": { "$value": [0.25, 0.1, 0.25, 1] } }
        }
        """##

    static let semantic = ##"""
        {
          "motion": {
            "$type": "transition",
            "pop": {
              "$value": {
                "duration": { "value": 450, "unit": "ms" },
                "delay": { "value": 0, "unit": "ms" },
                "timingFunction": "{easing.standard}"
              },
              "$description": "Something popping into place.",
              "$extensions": { "dev.westron.spring": { "duration": 0.45, "bounce": 0 } }
            },
            "row-leave": {
              "$value": {
                "duration": { "value": 320, "unit": "ms" },
                "delay": { "value": 0.7, "unit": "s" },
                "timingFunction": [0.42, 0, 1, 1]
              },
              "$description": "A done row leaving."
            }
          },
          "shadow": {
            "$type": "shadow",
            "raised": {
              "$value": {
                "color": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": 0.12 },
                "offsetX": { "value": 0, "unit": "px" },
                "offsetY": { "value": 5, "unit": "px" },
                "blur": { "value": 24, "unit": "px" },
                "spread": { "value": 0, "unit": "px" }
              },
              "$description": "A control raised off what it stands on."
            }
          },
          "space": { "$type": "dimension", "100": { "$value": { "value": 8, "unit": "px" } } },
          "stroke": {
            "$type": "dimension",
            "thin": { "$value": { "value": 1, "unit": "px" }, "$description": "Rules and dividers." }
          },
          "typography": {
            "$type": "typography",
            "heading": {
              "large": {
                "$value": {
                  "fontFamily": ["Onest", "system-ui"],
                  "fontSize": { "value": 34, "unit": "px" },
                  "fontWeight": 700,
                  "letterSpacing": { "value": 0, "unit": "px" },
                  "lineHeight": 1.206
                },
                "$description": "The title of a screen.",
                "$extensions": { "dev.westron.apple": { "textStyle": "largeTitle" } }
              }
            },
            "label": {
              "$value": {
                "fontFamily": "system-ui",
                "fontSize": { "value": 17, "unit": "px" },
                "fontWeight": 400,
                "letterSpacing": { "value": 0, "unit": "px" },
                "lineHeight": 1.294
              },
              "$description": "Main text.",
              "$extensions": { "dev.westron.apple": { "textStyle": "body" } }
            }
          }
        }
        """##

    /// A theme file: the text color, a fill outside sRGB, and two list colors with two roles each.
    static func theme(text: String, fill: String, blue: String, green: String, alpha: Double) -> String {
        ##"""
        {
          "color": {
            "$type": "color",
            "text": {
              "primary": {
                "$value": \##(text),
                "$description": "Words and glyphs.",
                "$extensions": {
                  "dev.westron.usage": { "use": ["body text", "titles"], "avoid": "Words on the accent: use text.on-accent." },
                  "dev.westron.contrast": [
                    { "kind": "text", "on": ["color.background.vivid"] },
                    { "kind": "large-text", "on": ["color.background.vivid", ["color.category.blue.background", "color.background.vivid"]] }
                  ]
                }
              }
            },
            "background": {
              "vivid": { "$value": \##(fill), "$description": "A fill brighter than sRGB can show." }
            },
            "category": {
              "blue": {
                "background": {
                  "$value": { "colorSpace": "srgb", "components": [0, 0, \##(blue)], "alpha": \##(alpha) },
                  "$description": "The tile under a glyph: the list color blue, translucent."
                },
                "on-fill": { "$value": "{color.paper}", "$description": "The mark on a fill." }
              },
              "light-green": {
                "background": {
                  "$value": { "colorSpace": "srgb", "components": [0, \##(green), 0], "alpha": \##(alpha) },
                  "$description": "The tile under a glyph: the list color light-green, translucent."
                },
                "on-fill": { "$value": "{color.ink}", "$description": "The mark on a fill." }
              }
            }
          }
        }
        """##
    }

    static let light = theme(
        text: "\"{color.ink}\"", fill: #"{ "colorSpace": "display-p3", "components": [0, 0.8, 0.3] }"#, blue: "1",
        green: "0.6", alpha: 0.15)
    static let dark = theme(
        text: "\"{color.paper}\"", fill: #"{ "colorSpace": "display-p3", "components": [0.1, 0.9, 0.4] }"#,
        blue: "0.8", green: "0.8", alpha: 0.24)
    static let lightHighContrast = ##"""
        {
          "color": {
            "$type": "color",
            "text": { "primary": { "$value": { "colorSpace": "srgb", "components": [0, 0, 0], "hex": "#000000" } } }
          }
        }
        """##

    /// The files of the resolution, with replacements by file name.
    static func files(_ replacements: [String: String] = [:]) -> [String: String] {
        [
            "r.resolver.json": resolver, "primitive.tokens.json": primitive, "semantic.tokens.json": semantic,
            "light.tokens.json": light, "dark.tokens.json": dark, "light-hc.tokens.json": lightHighContrast,
            "compact.tokens.json": "{}", "macos.tokens.json": "{}",
        ].merging(replacements) { $1 }
    }

    /// The generated files of the fixture, with replacements by file name.
    static func generate(_ replacements: [String: String] = [:]) throws -> [GeneratedFile] {
        try AppleTokens.files(for: resolution(files(replacements)))
    }

    /// The problems that stop generation, with replacements by file name.
    static func problems(
        _ replacements: [String: String], sourceLocation: SourceLocation = #_sourceLocation
    ) -> [String] {
        do {
            _ = try generate(replacements)
            Issue.record("generation succeeded", sourceLocation: sourceLocation)
            return []
        } catch let failure as AppleTokens.Failure {
            return failure.problems
        } catch {
            Issue.record("unexpected error: \(error)", sourceLocation: sourceLocation)
            return []
        }
    }

    /// The generated file at a path.
    static func file(_ files: [GeneratedFile], _ path: String) -> String? {
        files.first { $0.path == path }?.contents
    }
}
