import Foundation
import Testing
import WestronTools

@Suite("Merging token files")
struct TokenMergeTests {
    private func theme(_ names: String...) throws -> TokenTree {
        try TokenTree.merge(
            names.map { try TokenTree.load(fixtureData("tokens/theme/\($0).tokens.json"), source: "\($0).tokens.json") }
        )
    }

    @Test("a later file overrides an earlier one; references resolve in the merged tree")
    func laterOverrides() throws {
        let light = Dictionary(
            uniqueKeysWithValues: try theme("primitives", "semantic").resolve().map { ($0.path.description, $0) })
        #expect(light["color.background"]?.value == .color(.srgb(1, 1, 1)))
        #expect(light["color.text"]?.value == .color(.srgb(0, 0, 0)))
        #expect(light["inset.card"]?.value == .dimension(.px(8)))

        let dark = Dictionary(
            uniqueKeysWithValues: try theme("primitives", "semantic", "dark").resolve().map {
                ($0.path.description, $0)
            })
        #expect(dark["color.background"]?.value == .color(.srgb(0, 0, 0)))
        #expect(dark["color.text"]?.value == .color(.srgb(1, 1, 1)))
        #expect(dark["color.border"]?.value == .color(.srgb(0.5, 0.5, 0.5)))
        #expect(dark["color.background"]?.source == "dark.tokens.json")
        #expect(dark["inset.card"]?.source == "semantic.tokens.json")
    }

    @Test("a token is replaced whole: what the later token does not set is not kept from the earlier one")
    func tokenReplacedWhole() throws {
        let merged = try theme("primitives", "semantic", "dark")
        guard case .token(let background) = merged.node(at: "color.background") else {
            Issue.record("color.background is not a token")
            return
        }
        #expect(background.description == nil)
        #expect(background.extensions == nil)
        #expect(background.source == "dark.tokens.json")
    }

    @Test("groups merge name by name: a name keeps its first position, new names follow in the later order")
    func order() throws {
        let merged = try theme("primitives", "semantic", "dark")
        #expect(
            merged.tokens.map(\.path.description) == [
                "palette.white", "palette.gray", "palette.black", "space.s", "space.m", "color.background",
                "color.text", "color.border", "inset.card",
            ])
        #expect(merged.sources == ["primitives.tokens.json", "semantic.tokens.json", "dark.tokens.json"])
    }

    @Test("a group property the later group sets replaces the earlier one; the others stay")
    func groupProperties() throws {
        let earlier = try load(
            #"{ "g": { "$type": "number", "$description": "Old", "$extensions": { "a": 1 }, "x": { "$value": 1 } } }"#)
        let later = try load(#"{ "g": { "$description": "New", "$deprecated": true } }"#, source: "later.tokens.json")
        guard case .group(let group) = try earlier.merging(later).node(at: "g") else {
            Issue.record("g is not a group")
            return
        }
        #expect(group.description == "New")
        #expect(group.deprecated == .deprecated(reason: nil))
        #expect(group.type == .number)
        #expect(group.extensions == .object([.init("a", .number(1))]))
    }

    @Test("a token's inherited type is settled in its own file; another file's group $type does not change it")
    func inheritanceStaysInFile() throws {
        let earlier = try load(
            #"{ "size": { "$type": "dimension", "m": { "$value": { "value": 8, "unit": "px" } } } }"#)
        let later = try load(#"{ "size": { "$type": "number", "ratio": { "$value": 1.5 } } }"#, source: "b.tokens.json")
        let tokens = Dictionary(
            uniqueKeysWithValues: try earlier.merging(later).resolve().map { ($0.path.description, $0.type) })
        #expect(tokens == ["size.m": .dimension, "size.ratio": .number])
    }

    @Test("a token and a group at the same path is an error, in either order")
    func conflicts() throws {
        let token = try load(#"{ "color": { "accent": { "$type": "number", "$value": 1 } } }"#, source: "a.tokens.json")
        let group = try load(
            #"{ "color": { "accent": { "light": { "$type": "number", "$value": 2 } } } }"#, source: "b.tokens.json")

        let groupAfterToken = #expect(throws: TokenErrors.self) { try token.merging(group) }
        #expect(
            groupAfterToken?.errors.map(\.description) == [
                "b.tokens.json: color.accent: a group here, but a token in a.tokens.json"
            ])
        #expect(groupAfterToken?.errors.map(\.kind) == [.conflict])

        let tokenAfterGroup = #expect(throws: TokenErrors.self) { try group.merging(token) }
        #expect(
            tokenAfterGroup?.errors.map(\.description) == [
                "a.tokens.json: color.accent: a token here, but a group in b.tokens.json"
            ])
    }

    @Test("merging nothing gives an empty tree; merging one tree gives it back")
    func trivialMerges() throws {
        #expect(try TokenTree.merge([]) == TokenTree())
        let one = try theme("primitives")
        #expect(try TokenTree.merge([one]) == one)
    }
}

@Suite("Determinism")
struct TokenDeterminismTests {
    @Test("tokens come out in document order, not sorted and not in hash order")
    func documentOrder() throws {
        let tree = try TokenTree.load(fixtureData("tokens/order.tokens.json"), source: "order.tokens.json")
        let expected = ["zeta.9", "zeta.10", "zeta.1", "alpha.z", "alpha.a", "mid.Upper", "mid.lower"]
        #expect(tree.tokens.map(\.path.description) == expected)
        #expect(try tree.resolve().map(\.path.description) == expected)
    }

    @Test("the same input gives the same result every time")
    func repeatable() throws {
        let data = try fixtureData("tokens/aliases.tokens.json")
        let first = try TokenTree.load(data, source: "a").resolve()
        for _ in 0..<20 {
            #expect(try TokenTree.load(data, source: "a").resolve() == first)
        }
    }

    @Test("token paths sort name by name, so a group's tokens stay together")
    func pathOrder() {
        let paths: [TokenPath] = ["a.c", "a.b.c", "a", "a.b", "b", "a-b"]
        // Sorting the dotted strings would put "a-b" between "a" and "a.b", since "-" sorts before ".".
        #expect(paths.sorted().map(\.description) == ["a", "a.b", "a.b.c", "a.c", "a-b", "b"])
    }

    @Test("errors come out in the order of the file, the same every time")
    func errorOrder() {
        let document = #"""
            { "z": { "$type": "number", "$value": "{q}" }, "a": { "$type": "number", "$value": "{p}" },
              "m": { "$type": "number", "$value": "{o}" } }
            """#
        for _ in 0..<5 {
            #expect(summary(problems(document)) == ["unknownReference z", "unknownReference a", "unknownReference m"])
        }
    }
}
