import Foundation
import Testing
import WestronTools

@Suite("Token files")
struct TokenLoadTests {
    @Test("a token inherits $type from the closest group in its file; its own $type wins")
    func typeInheritance() throws {
        let tree = try load(
            #"""
            {
              "$type": "number",
              "ratio": { "$value": 1.5 },
              "size": {
                "$type": "dimension",
                "m": { "$value": { "value": 8, "unit": "px" } },
                "inner": { "deep": { "$value": { "value": 2, "unit": "rem" } } },
                "count": { "$type": "number", "$value": 3 }
              }
            }
            """#)
        let types = Dictionary(uniqueKeysWithValues: tree.tokens.map { ($0.path.description, $0.token.type) })
        #expect(
            types == [
                "ratio": .number, "size.m": .dimension, "size.inner.deep": .dimension, "size.count": .number,
            ])
    }

    @Test("$description, $deprecated and $extensions are kept; $deprecated is inherited and can be cancelled")
    func metadata() throws {
        let tree = try load(
            #"""
            {
              "old": {
                "$type": "number",
                "$deprecated": "Use new",
                "$description": "Old numbers",
                "$extensions": { "org.example.group": { "rank": 1 } },
                "a": { "$value": 1 },
                "b": { "$value": 2, "$deprecated": false },
                "c": { "$value": 3, "$deprecated": true, "$description": "Three",
                       "$extensions": { "org.example.note": "Counting", "org.example.tool": [1, 2] } }
              }
            }
            """#)
        guard case .group(let group) = tree.node(at: "old") else {
            Issue.record("old is not a group")
            return
        }
        #expect(group.description == "Old numbers")
        #expect(group.deprecated == .deprecated(reason: "Use new"))
        #expect(group.extensions?["org.example.group"]?["rank"] == .number(1))
        let tokens = Dictionary(uniqueKeysWithValues: try tree.resolve().map { ($0.path.description, $0) })
        #expect(tokens["old.a"]?.deprecated == .deprecated(reason: "Use new"))
        #expect(tokens["old.b"]?.deprecated == .notDeprecated)
        #expect(tokens["old.b"]?.deprecated?.isDeprecated == false)
        #expect(tokens["old.c"]?.deprecated == .deprecated(reason: nil))
        #expect(tokens["old.c"]?.description == "Three")
        #expect(tokens["old.c"]?.extensions?["org.example.note"] == .string("Counting"))
        #expect(tokens["old.c"]?.extensions?.members?.map(\.key) == ["org.example.note", "org.example.tool"])
        #expect(tokens["old.a"]?.extensions == nil)
    }

    @Test("an empty group and the $schema property at the root are allowed")
    func emptyGroupAndSchema() throws {
        let tree = try load(#"{ "$schema": "https://www.designtokens.org/schemas/2025.10/format.json", "empty": {} }"#)
        #expect(tree.node(at: "empty") == .group(TokenGroup()))
        #expect(tree.tokens.isEmpty)
        #expect(tree.sources == ["test.tokens.json"])
    }

    @Test(
        "names follow the DTCG rules",
        arguments: [
            (#"{ "a.b": { "$type": "number", "$value": 1 } }"#, ["a.b"]),
            (#"{ "{a}": { "$type": "number", "$value": 1 } }"#, ["{a}"]),
            (#"{ "g": { "x}": { "$type": "number", "$value": 1 } } }"#, ["g", "x}"]),
            (#"{ "": { "$type": "number", "$value": 1 } }"#, [""]),
        ])
    func invalidNames(_ document: String, _ names: [String]) {
        let errors = problems(document)
        #expect(errors.map(\.kind) == [.invalidName])
        #expect(errors.first?.path == TokenPath(names))
    }

    @Test("a name may contain spaces, slashes and other characters, and differ only in case")
    func validNames() throws {
        let tokens = try resolve(
            #"{ "brand colors": { "$type": "number", "a/b": { "$value": 1 }, "A/B": { "$value": 2 }, "ü-1": { "$value": 3 } } }"#
        )
        #expect(
            Set(tokens.keys) == [
                TokenPath(["brand colors", "a/b"]), TokenPath(["brand colors", "A/B"]),
                TokenPath(["brand colors", "ü-1"]),
            ])
    }

    @Test(
        "rejects properties DTCG does not define and objects that are both token and group",
        arguments: [
            (#"{ "t": { "$type": "number", "$value": 1, "$customProp": 2 } }"#, "t"),
            (#"{ "g": { "$type": "number", "$custom": 1 } }"#, "g"),
            (#"{ "g": { "$schema": "x" } }"#, "g"),
            (#"{ "t": { "$type": "number", "$value": 1, "child": { "$value": 2 } } }"#, "t"),
            (#"{ "$value": 1, "$type": "number" }"#, ""),
        ])
    func unknownProperties(_ document: String, _ path: String) {
        let errors = problems(document)
        #expect(summary(errors) == ["unknownProperty \(path)"])
    }

    @Test(
        "rejects malformed properties",
        arguments: [
            #"{ "t": { "$type": 7, "$value": 1 } }"#,
            #"{ "t": { "$type": "Number", "$value": 1 } }"#,
            #"{ "t": { "$type": "number", "$value": 1, "$description": 7 } }"#,
            #"{ "t": { "$type": "number", "$value": 1, "$deprecated": 1 } }"#,
            #"{ "t": { "$type": "number", "$value": 1, "$deprecated": {} } }"#,
            #"{ "t": { "$type": "number", "$value": 1, "$extensions": "x" } }"#,
            #"{ "t": { "$type": "number", "$value": null } }"#,
            #"{ "t": 7 }"#,
            #"[]"#,
        ])
    func malformedProperties(_ document: String) {
        let errors = problems(document)
        #expect(errors.map(\.kind) == [.invalidValue], "\(document)")
    }

    @Test("a token whose type cannot be determined is an error; DTCG does not infer types")
    func missingType() {
        let errors = problems(#"{ "g": { "t": { "$value": { "colorSpace": "srgb", "components": [0, 0, 0] } } } }"#)
        #expect(summary(errors) == ["missingType g.t"])
        #expect(errors.first?.description.hasPrefix("test.tokens.json: g.t: the token has no $type") == true)
    }

    @Test("an invalid group $type is reported once, not again for each token in the group")
    func invalidGroupTypeReportedOnce() {
        let document = #"{ "g": { "$type": "colour", "a": { "$value": 1 }, "b": { "$value": 2 } } }"#
        #expect(summary(problems(document)) == ["invalidValue g"])
    }

    @Test(
        "rejects malformed references",
        arguments: ["{}", "{a", "a}", "{a..b}", "{.a}", "{a.}", "{a}{b}"])
    func malformedReferences(_ reference: String) {
        let errors = problems(
            #"{ "a": { "$type": "number", "$value": 1 }, "t": { "$type": "number", "$value": "\#(reference)" } }"#)
        #expect(!errors.isEmpty, "\(reference)")
        #expect(errors.allSatisfy { $0.path == "t" }, "\(reference)")
    }

    @Test("errors name the file and the token path, and every problem in a file is reported")
    func errorsNameFileAndPath() {
        let document = #"""
            {
              "color": {
                "$type": "color",
                "bad": { "$value": { "colorSpace": "srgb", "components": [0, 0, 2] } }
              },
              "size": { "$type": "dimension", "m": { "$value": { "value": 8, "unit": "pt" } } }
            }
            """#
        let error = #expect(throws: TokenErrors.self) {
            try TokenTree.load(Data(document.utf8), source: "tokens/primitives.tokens.json")
        }
        #expect(
            error?.errors.map(\.description) == [
                "tokens/primitives.tokens.json: color.bad: $value.components[2]: 2 is outside [0, 1] for srgb",
                #"tokens/primitives.tokens.json: size.m: $value.unit: a dimension unit is px or rem, found "pt""#,
            ])
    }

    @Test("a file that is not JSON is a syntax error with its position")
    func syntaxError() {
        let error = #expect(throws: TokenErrors.self) {
            try TokenTree.load(Data("{\n  \"a\": }".utf8), source: "x.tokens.json")
        }
        #expect(error?.errors.map(\.kind) == [.syntax])
        #expect(error?.errors.first?.description == "x.tokens.json: invalid JSON at 2:8: unexpected character")
    }
}

@Suite("DTCG features outside the subset")
struct UnsupportedFeatureTests {
    @Test(
        "are rejected with an error that names the token or group, never skipped",
        arguments: [
            ("group $extends", #"{ "base": {}, "ext": { "$extends": "{base}" } }"#, "ext"),
            ("$root token", #"{ "accent": { "$root": { "$type": "number", "$value": 1 } } }"#, "accent.$root"),
            (
                "JSON Pointer token",
                ##"{ "a": { "$type": "number", "$value": 1 }, "t": { "$type": "number", "$ref": "#/a/$value" } }"##, "t"
            ),
            (
                "JSON Pointer sub-value",
                ##"{ "a": { "$type": "number", "$value": 1 }, "t": { "$type": "dimension", "$value": { "value": { "$ref": "#/a/$value" }, "unit": "px" } } }"##,
                "t"
            ),
            (
                "JSON Pointer color component",
                ##"{ "t": { "$type": "color", "$value": { "colorSpace": "srgb", "components": [{ "$ref": "#/x" }, 0, 0] } } }"##,
                "t"
            ),
            (
                "JSON Pointer in a composite",
                ##"{ "t": { "$type": "typography", "$value": { "$ref": "#/x" } } }"##,
                "t"
            ),
            ("reference to $root", #"{ "t": { "$type": "number", "$value": "{a.$root}" } }"#, "t"),
            ("strokeStyle", #"{ "t": { "$type": "strokeStyle", "$value": "solid" } }"#, "t"),
            ("border", #"{ "t": { "$type": "border", "$value": {} } }"#, "t"),
            ("gradient", #"{ "t": { "$type": "gradient", "$value": [] } }"#, "t"),
            ("gradient on a group", #"{ "g": { "$type": "gradient", "t": { "$value": [] } } }"#, "g"),
        ])
    func rejected(_ feature: String, _ document: String, _ path: String) {
        let errors = problems(document)
        #expect(summary(errors) == ["unsupported \(path)"], "\(feature)")
        #expect(errors.first?.source == "test.tokens.json")
    }
}
