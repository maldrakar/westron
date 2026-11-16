import Foundation
import Testing
import WestronTools

@Suite("tokens check")
struct TokenCheckTests {
    /// A temporary directory with files, created in the order given; removed by the caller.
    private func directory(_ files: [(String, String)]) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("westron-\(UUID().uuidString)")
        for (path, contents) in files {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(contents.utf8).write(to: url)
        }
        return root
    }

    /// A resolver with one theme modifier over the given token files, which it uses.
    private let resolverFile = (
        "r.resolver.json",
        #"""
        {
          "version": "2025.10",
          "modifiers": {
            "theme": { "contexts": { "light": [{ "$ref": "a.tokens.json" }], "dark": [] }, "default": "light" }
          },
          "resolutionOrder": [{ "$ref": "#/modifiers/theme" }]
        }
        """#
    )

    @Test("finds *.tokens.json files recursively, sorted by path, whatever order they were created in")
    func findsFiles() throws {
        let root = try directory([
            ("z.tokens.json", "{}"), ("themes/dark.tokens.json", "{}"), ("a.tokens.json", "{}"),
            ("westron.resolver.json", "{}"), ("notes.md", ""), ("themes/a/light.tokens.json", "{}"),
        ])
        defer { try? FileManager.default.removeItem(at: root) }
        let prefix = root.path + "/"
        #expect(
            try TokenCheck.files(in: root.path).map { String($0.dropFirst(prefix.count)) } == [
                "a.tokens.json", "themes/a/light.tokens.json", "themes/dark.tokens.json", "z.tokens.json",
            ])
        #expect(try TokenCheck.files(in: root.appendingPathComponent("missing").path) == [])
    }

    @Test("passes a valid resolver and reports every combination, with one summary line per theme")
    func passes() throws {
        let report = try TokenCheck.run(
            resolverFile: fixture("resolver/test.resolver.json").path, schemaDirectory: schemaDirectory)
        #expect(report.files.count == 7)
        #expect(report.combinations.count == 12)
        #expect(
            report.summary() == [
                "theme=light: 4 combinations, 10–11 tokens", "theme=light-hc: 4 combinations, 10–11 tokens",
                "theme=dark: 4 combinations, 10–11 tokens",
            ])
        #expect(
            report.summary(by: "platform") == [
                "platform=ios: 6 combinations, 10 tokens", "platform=macos: 6 combinations, 11 tokens",
            ])
    }

    @Test("reports a token file in the resolver's directory that the resolver does not use")
    func unusedFile() throws {
        let root = try directory([
            resolverFile, ("a.tokens.json", #"{ "n": { "$type": "number", "$value": 1 } }"#),
            ("old/b.tokens.json", "{}"),
        ])
        defer { try? FileManager.default.removeItem(at: root) }
        let error = #expect(throws: TokenErrors.self) {
            try TokenCheck.run(resolverFile: root.appendingPathComponent("r.resolver.json").path, schemaDirectory: nil)
        }
        #expect(error?.errors.map(\.kind) == [.resolver])
        #expect(error?.errors.first?.source.hasSuffix("old/b.tokens.json") == true)
    }

    @Test("reports schema violations of a file the reader accepts")
    func reportsSchemaViolations() throws {
        // The reader accepts this file; the official schema does not (TokenSchemaTests.inheritedFontWeightNameDefect).
        let root = try directory([
            resolverFile, ("a.tokens.json", #"{ "weight": { "$type": "fontWeight", "bold": { "$value": "bold" } } }"#),
        ])
        defer { try? FileManager.default.removeItem(at: root) }
        let error = #expect(throws: TokenErrors.self) {
            try TokenCheck.run(
                resolverFile: root.appendingPathComponent("r.resolver.json").path, schemaDirectory: schemaDirectory)
        }
        #expect(error?.errors.isEmpty == false)
        #expect(error?.errors.allSatisfy { $0.kind == .schema && $0.path == "weight.bold" } == true)
        #expect(error?.errors.first?.message.hasPrefix("DTCG schema: /weight/bold/$value: ") == true)
    }

    @Test("validates the resolver file, its inline tokens included, against the resolver schema")
    func resolverSchema() throws {
        // The reader accepts these inline tokens; the format schema, which the resolver schema applies to inline
        // tokens, does not (TokenSchemaTests.inheritedFontWeightNameDefect).
        let root = try directory([
            (
                "r.resolver.json",
                #"""
                { "version": "2025.10",
                  "sets": { "s": { "sources": [{ "weight": { "$type": "fontWeight", "bold": { "$value": "bold" } } }] } },
                  "resolutionOrder": [{ "$ref": "#/sets/s" }] }
                """#
            )
        ])
        defer { try? FileManager.default.removeItem(at: root) }
        let resolver = root.appendingPathComponent("r.resolver.json").path
        _ = try TokenCheck.run(resolverFile: resolver, schemaDirectory: nil)
        let error = #expect(throws: TokenErrors.self) {
            try TokenCheck.run(resolverFile: resolver, schemaDirectory: schemaDirectory)
        }
        #expect(error?.errors.isEmpty == false)
        #expect(error?.errors.allSatisfy { $0.kind == .schema && $0.source == resolver } == true)
    }

    @Test("a JSON Pointer into a token file names the token or group it points into")
    func pointerPaths() {
        #expect(TokenPath(pointer: "/a~1b/c~0d/$value/x") == TokenPath(["a/b", "c~d"]))
        #expect(TokenPath(pointer: "") == .root)
    }
}
