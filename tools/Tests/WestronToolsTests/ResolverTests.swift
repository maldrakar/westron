import Foundation
import Testing
import WestronTools

@Suite("Resolver")
struct ResolverTests {
    private func fixtureResolution() throws -> Resolution {
        try Resolution(resolverFile: fixture("resolver/test.resolver.json").path, schemaDirectory: schemaDirectory)
    }

    @Test("tokens/westron.resolver.json has the modifiers and contexts of decisions/0010")
    func westronResolver() throws {
        let tokens = repositoryRoot.appendingPathComponent("tokens").path
        let resolution = try Resolution(resolverFile: tokens + "/westron.resolver.json")
        #expect(resolution.modifiers.map(\.name) == ["theme", "density", "platform"])
        #expect(
            resolution.modifiers.map(\.contextNames) == [
                ["light", "dark", "light-hc", "dark-hc"], ["regular", "compact"], ["ios", "macos", "watchos"],
            ])
        #expect(resolution.modifiers.map(\.defaultContext) == ["light", "regular", nil])
        #expect(resolution.inputs.count == 24)
        let theme = resolution.modifiers[0]
        #expect(
            theme.context(named: "light-hc")?.sources == [
                .file(tokens + "/primitive/color.light.tokens.json"),
                .file(tokens + "/primitive/color.light-hc.tokens.json"),
                .file(tokens + "/semantic/shadow.light.tokens.json"),
            ])
        #expect(
            theme.context(named: "dark-hc")?.sources == [
                .file(tokens + "/primitive/color.dark.tokens.json"),
                .file(tokens + "/primitive/color.dark-hc.tokens.json"),
                .file(tokens + "/semantic/shadow.dark.tokens.json"),
            ])
    }

    @Test("enumerates every input, the first modifier varying slowest, contexts in document order")
    func inputs() throws {
        let resolution = try fixtureResolution()
        let inputs = resolution.inputs.map(resolution.describe)
        #expect(inputs.count == 12)
        #expect(
            inputs.prefix(5) == [
                "theme=light, density=regular, platform=ios", "theme=light, density=regular, platform=macos",
                "theme=light, density=compact, platform=ios", "theme=light, density=compact, platform=macos",
                "theme=light-hc, density=regular, platform=ios",
            ])
    }

    @Test("resolves an input: the sets, then each modifier's context; a modifier not named takes its default")
    func resolvesInputs() throws {
        let resolution = try fixtureResolution()
        let light = try resolution.resolve(["platform": "ios"])
        #expect(light.input == ["theme": "light", "density": "regular", "platform": "ios"])
        #expect(light["color.background.canvas"]?.value == .color(.srgb(1, 1, 1)))
        #expect(light["inset.card"]?.value == .dimension(.px(8)))
        #expect(light["radius.window"] == nil)

        let dark = try resolution.resolve(["theme": "dark", "density": "compact", "platform": "macos"])
        #expect(dark["color.background.canvas"]?.value == .color(.srgb(0, 0, 0)))
        #expect(dark["inset.card"]?.value == .dimension(.px(4)))
        #expect(dark["radius.window"]?.value == .dimension(.px(10)))
        #expect(dark.tokens.count == light.tokens.count + 1)

        let highContrast = try resolution.resolve(["theme": "light-hc", "platform": "ios"])
        #expect(highContrast["color.accent"]?.value == .color(.srgb(0.1, 0.2, 0.6)))
        #expect(highContrast["color.accent"]?.source.hasSuffix("theme/light-hc.tokens.json") == true)
        #expect(highContrast["color.text.primary"] == light["color.text.primary"])
    }

    @Test("an input with an unknown modifier, an unknown context, or no context for a modifier without default fails")
    func invalidInputs() throws {
        let resolution = try fixtureResolution()
        let error = #expect(throws: TokenErrors.self) { try resolution.resolve(["theme": "sepia", "size": "l"]) }
        #expect(error?.errors.allSatisfy { $0.kind == .input } == true)
        let messages = error?.errors.map(\.message) ?? []
        #expect(messages.count == 3)
        #expect(messages[0].hasPrefix(##"input: unknown modifier "size""##))
        #expect(messages[1].hasPrefix(##"input: invalid context "sepia" for modifier "theme""##))
        #expect(messages[2].hasPrefix(##"input: missing modifier "platform""##))
    }

    @Test("westron's extensions come out read: contrast backgrounds as full paths, stacks top first")
    func westronExtensions() throws {
        let light = try fixtureResolution().resolve(["platform": "ios"])
        let text = try #require(light["color.text.primary"])
        #expect(
            text.westron.contrast == [
                .init(
                    kind: .text,
                    on: [["color.background.canvas"], ["color.background.hover", "color.background.canvas"]])
            ])
        #expect(text.westron.usage == .init(use: ["body text"], avoid: "Text on the accent: use text.on-accent."))
        #expect(text.extensions?["org.example.tool"]?["kept"] == .bool(true))
    }

    @Test("a context may refer to a set and hold inline tokens; within a context the later source wins")
    func setsInContextsAndInlineTokens() throws {
        let files = [
            "r.resolver.json": resolver(
                ##"""
                "sets": { "base": { "sources": [{ "$ref": "a.tokens.json" }] } },
                "modifiers": {
                  "mode": {
                    "contexts": {
                      "one": [{ "$ref": "#/sets/base" }, { "n": { "$type": "number", "$value": 2 } }],
                      "two": [{ "$ref": "#/sets/base" }]
                    },
                    "default": "one"
                  }
                },
                "resolutionOrder": [{ "$ref": "#/modifiers/mode" }]
                """##),
            "a.tokens.json": ##"{ "n": { "$type": "number", "$value": 1 } }"##,
        ]
        let resolution = try resolution(files)
        #expect(try resolution.resolve([:])["n"]?.value == .number(2))
        #expect(try resolution.resolve([:])["n"]?.source == "r.resolver.json#/modifiers/mode/contexts/one/1")
        #expect(try resolution.resolve(["mode": "two"])["n"]?.value == .number(1))
        #expect(resolution.files == ["a.tokens.json"])
    }

    @Test("two modifiers that set the same token fail, naming the token, both modifiers and the files")
    func modifierOverlap() throws {
        let files = [
            "r.resolver.json": resolver(
                ##"""
                "sets": { "base": { "sources": [{ "$ref": "base.tokens.json" }] } },
                "modifiers": {
                  "a": { "contexts": { "x": [{ "$ref": "a.tokens.json" }], "y": [] }, "default": "x" },
                  "b": { "contexts": { "p": [], "q": [{ "$ref": "b.tokens.json" }] }, "default": "p" }
                },
                "resolutionOrder": [{ "$ref": "#/sets/base" }, { "$ref": "#/modifiers/a" }, { "$ref": "#/modifiers/b" }]
                """##),
            "base.tokens.json": ##"{ "shared": { "$type": "number", "$value": 0 } }"##,
            "a.tokens.json":
                ##"{ "shared": { "$type": "number", "$value": 1 }, "t": { "$type": "number", "$value": 1 } }"##,
            "b.tokens.json": ##"{ "t": { "$type": "number", "$value": 2 } }"##,
        ]
        let errors = resolutionProblems(files)
        #expect(errors.map(\.kind) == [.modifierOverlap])
        #expect(errors.first?.path == "t")
        #expect(
            errors.first?.description
                == "r.resolver.json: t: set by modifier a (context x, a.tokens.json) and by modifier b (context q, "
                + "b.tokens.json); two modifiers must not set the same token, or their order would matter "
                + "(decisions/0010)")
    }

    @Test("a problem found in some inputs only says in which")
    func problemInSomeInputs() {
        let files = [
            "r.resolver.json": resolver(
                ##"""
                "modifiers": {
                  "theme": { "contexts": { "light": [{ "$ref": "l.tokens.json" }], "dark": [{ "$ref": "d.tokens.json" }] } },
                  "density": { "contexts": { "regular": [], "compact": [] } }
                },
                "resolutionOrder": [{ "$ref": "#/modifiers/theme" }, { "$ref": "#/modifiers/density" }]
                """##),
            "l.tokens.json": ##"{ "t": { "$type": "number", "$value": 1 } }"##,
            "d.tokens.json": ##"{ "t": { "$type": "number", "$value": "{missing}" } }"##,
        ]
        #expect(
            resolutionProblems(files).map(\.description) == [
                "d.tokens.json: t: $value: {missing} does not exist (in theme=dark)"
            ])
    }

    @Test(
        "rejects what the Resolver module forbids and what westron does not support",
        arguments: [
            (
                ##"{ "resolutionOrder": [{ "$ref": "#/sets/s" }], "sets": { "s": { "sources": [] } } }"##,
                "missing \"version\""
            ),
            (##"{ "version": "2024.01", "resolutionOrder": [] }"##, "must be \"2025.10\""),
            (resolver(##""sets": {}"##), "missing \"resolutionOrder\""),
            (resolver(##""resolutionOrder": []"##), "at least one set or modifier"),
            (
                resolver(##""tokens": {}, "resolutionOrder": [{ "type": "set", "name": "s", "sources": [] }]"##),
                "unknown property"
            ),
            (
                resolver(
                    ##""modifiers": { "m": { "contexts": { "only": [] } } }, "resolutionOrder": [{ "$ref": "#/modifiers/m" }]"##
                ),
                "at least two contexts"
            ),
            (
                resolver(
                    ##""modifiers": { "m": { "contexts": { "a": [], "b": [] }, "default": "c" } }, "resolutionOrder": [{ "$ref": "#/modifiers/m" }]"##
                ),
                "\"c\" is not one of the contexts"
            ),
            (
                resolver(
                    ##""sets": { "s": { "sources": [{ "$ref": "#/modifiers/m" }] } }, "modifiers": { "m": { "contexts": { "a": [], "b": [] } } }, "resolutionOrder": [{ "$ref": "#/sets/s" }]"##
                ),
                "cannot refer to a modifier"
            ),
            (
                resolver(
                    ##""modifiers": { "m": { "contexts": { "a": [{ "$ref": "#/modifiers/m" }], "b": [] } } }, "resolutionOrder": [{ "$ref": "#/modifiers/m" }]"##
                ),
                "cannot refer to a modifier"
            ),
            (
                resolver(
                    ##""resolutionOrder": [{ "type": "set", "name": "s", "sources": [{ "$ref": "#/resolutionOrder/0" }] }]"##
                ),
                "nothing may refer into resolutionOrder"
            ),
            (
                resolver(
                    ##""resolutionOrder": [{ "type": "set", "name": "s", "sources": [] }, { "type": "set", "name": "s", "sources": [] }]"##
                ),
                "already used in resolutionOrder"
            ),
            (resolver(##""resolutionOrder": [{ "name": "s", "sources": [] }]"##), "needs \"type\""),
            (resolver(##""resolutionOrder": [{ "type": "set", "sources": [] }]"##), "needs \"type\""),
            (
                resolver(
                    ##""sets": { "a": { "sources": [{ "$ref": "#/sets/b" }] }, "b": { "sources": [{ "$ref": "#/sets/a" }] } }, "resolutionOrder": [{ "$ref": "#/sets/a" }]"##
                ),
                "circular reference between sets: #/sets/a → #/sets/b → #/sets/a"
            ),
            (resolver(##""resolutionOrder": [{ "$ref": "#/sets/nothing" }]"##), "no set named \"nothing\""),
            (
                resolver(
                    ##""sets": { "s": { "sources": [], "description": 7 } }, "resolutionOrder": [{ "$ref": "#/sets/s" }]"##
                ),
                "#/sets/s/description: expected a string"
            ),
            (
                resolver(
                    ##""modifiers": { "m": { "contexts": { "a": [], "b": [] }, "$extensions": [] } }, "resolutionOrder": [{ "$ref": "#/modifiers/m" }]"##
                ),
                "#/modifiers/m/$extensions: expected an object"
            ),
            (resolver(##""resolutionOrder": [{ "$ref": "#/modifiers/nothing" }]"##), "no modifier named \"nothing\""),
            (
                resolver(
                    ##""resolutionOrder": [{ "type": "set", "name": "s", "sources": [{ "$ref": "missing.tokens.json" }] }]"##
                ),
                "cannot read missing.tokens.json"
            ),
        ])
    func invalidDocuments(_ document: String, _ message: String) {
        let errors = resolutionProblems(["r.resolver.json": document])
        #expect(!errors.isEmpty, "\(message)")
        #expect(errors.contains { $0.message.contains(message) }, "\(errors)")
        #expect(errors.allSatisfy { $0.source == "r.resolver.json" })
    }

    @Test(
        "rejects references westron does not support, naming the place",
        arguments: [
            "https://example.com/a.tokens.json", "a.tokens.json#/color", "../a.tokens.json", "/a.tokens.json",
            "#/$defs/tokens", "#/sets/s/sources/0",
        ])
    func unsupportedReferences(_ reference: String) {
        let document = resolver(
            ##""sets": { "s": { "sources": [] } }, "resolutionOrder": [{ "type": "set", "name": "t", "sources": [{ "$ref": "\##(reference)" }] }]"##
        )
        let errors = resolutionProblems(["r.resolver.json": document])
        #expect(errors.map(\.kind) == [.unsupported], "\(reference)")
        #expect(errors.first?.message.hasPrefix("#/resolutionOrder/0/sources/0: ") == true)
    }

    @Test("rejects a reference object with keys besides $ref, and a file in resolutionOrder")
    func unsupportedForms() {
        let extending = resolver(
            ##""sets": { "s": { "sources": [] } }, "resolutionOrder": [{ "$ref": "#/sets/s", "description": "x" }]"##)
        #expect(resolutionProblems(["r.resolver.json": extending]).map(\.kind) == [.unsupported])
        let file = resolver(##""resolutionOrder": [{ "$ref": "a.tokens.json" }]"##)
        #expect(resolutionProblems(["r.resolver.json": file]).map(\.kind) == [.unsupported])
    }

    @Test("$defs is ignored, as the Resolver module requires of tools that do not use it")
    func defsIgnored() throws {
        let document = resolver(
            ##""$defs": { "anything": [1, 2] }, "resolutionOrder": [{ "type": "set", "name": "s", "sources": [{ "n": { "$type": "number", "$value": 1 } }] }]"##
        )
        #expect(try resolution(["r.resolver.json": document]).resolve([:])["n"]?.value == .number(1))
    }
}

@Suite("DTCG resolver test suite")
struct ResolverSuiteTests {
    /// Invalid resolver fixtures the schema lets through: none known yet.
    static let schemaGaps: Set<String> = []

    @Test("the resolver schema agrees with the DTCG test suite")
    func schemaConformance() throws {
        let schema = try TokenSchema(directory: schemaDirectory, rootID: TokenSchema.resolverID)
        var disagreements: Set<String> = []
        for test in SuiteCase.cases("resolver") where !test.needsPreprocessing {
            let valid = try schema.validate(test.data()).isEmpty
            if valid != test.positive { disagreements.insert(test.id) }
        }
        #expect(disagreements == Self.schemaGaps)
    }

    @Test("westron's resolver reads and resolves every valid fixture and rejects every invalid one")
    func readerConformance() throws {
        var wrong: [String] = []
        for test in SuiteCase.cases("resolver") {
            let path = fixture("dtcg-test-suite/resolver/\(test.input)").path
            do {
                let results = try Resolution(resolverFile: path).resolveAll()
                if !test.positive || results.isEmpty { wrong.append(test.id) }
            } catch let errors as TokenErrors {
                if test.positive { wrong.append("\(test.id): \(errors)") }
            }
        }
        #expect(wrong == [])
    }
}
