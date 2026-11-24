import Foundation
import Testing
import WestronTools

private struct Fake: Generator {
    let name: String
    let files: [GeneratedFile]
    let ownedDirectories: [String]

    init(_ name: String, _ files: KeyValuePairs<String, String>, owning ownedDirectories: [String] = []) {
        self.name = name
        self.files = files.map { GeneratedFile(path: $0.key, contents: $0.value) }
        self.ownedDirectories = ownedDirectories
    }

    func run() -> [GeneratedFile] { files }
}

/// A new empty directory for one test, removed when the body returns.
private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("westron-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: url) }
    try body(url)
}

private func write(_ text: String, _ path: String, in root: URL) throws {
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
}

@Suite("Generator registry")
struct GenerateTests {
    @Test("collects the outputs of all generators")
    func collectsOutputs() throws {
        #expect(
            try Generate.collect([Fake("a", ["x.swift": "1"]), Fake("b", ["y.css": "2"])]) == [
                GeneratedFile(path: "x.swift", contents: "1"),
                GeneratedFile(path: "y.css", contents: "2"),
            ])
    }

    @Test("two generators cannot produce the same file")
    func rejectsDuplicateFiles() {
        let error = #expect(throws: Generate.DuplicateFile.self) {
            try Generate.collect([Fake("a", ["x.swift": "1"]), Fake("b", ["x.swift": "2"])])
        }
        #expect(error?.path == "x.swift")
        #expect(error?.generator == "b")
    }

    @Test("finds missing and changed files")
    func findsDrift() {
        let disk = ["same.swift": "1", "changed.swift": "old"]
        let files = [
            GeneratedFile(path: "same.swift", contents: "1"),
            GeneratedFile(path: "changed.swift", contents: "new"),
            GeneratedFile(path: "missing.swift", contents: "3"),
        ]
        #expect(
            Generate.findDrift(files) { disk[$0] } == [
                .init(path: "changed.swift", reason: .differs),
                .init(path: "missing.swift", reason: .missing),
            ])
    }

    @Test("a generator owns directories; two generators may own the same one; a directory outside the repository fails")
    func ownedDirectories() throws {
        let output = try Generate.run([
            Fake("a", ["gen/x.swift": "1"], owning: ["gen", "assets"]),
            Fake("b", ["gen/y.swift": "2"], owning: ["gen"]),
        ])
        #expect(output.ownedDirectories == ["assets", "gen"])
        #expect(output.files.map(\.path) == ["gen/x.swift", "gen/y.swift"])
        for directory in ["", "/tmp", "../x", "a/./b", "a//b"] {
            #expect(throws: Generate.InvalidOwnedDirectory.self) {
                try Generate.run([Fake("a", [:], owning: [directory])])
            }
        }
    }

    @Test("a file in an owned directory that no generator produces is stale")
    func findsStale() {
        let disk = ["gen": ["gen/kept.swift", "gen/old.swift", "gen/sub/older.json"], "other": ["other/z.swift"]]
        let files = [GeneratedFile(path: "gen/kept.swift", contents: "1")]
        #expect(
            Generate.findStale(files, in: ["gen"]) { disk[$0] ?? [] } == [
                .init(path: "gen/old.swift", reason: .stale), .init(path: "gen/sub/older.json", reason: .stale),
            ])
    }

    @Test(
        "check reports missing, changed and stale files; hidden files and files outside owned directories are not stale"
    )
    func checksDisk() throws {
        try withTemporaryDirectory { root in
            try write("1", "gen/same.swift", in: root)
            try write("old", "gen/changed.swift", in: root)
            try write("x", "gen/stale.colorset/Contents.json", in: root)
            try write("", "gen/.DS_Store", in: root)
            try write("hand", "hand/written.swift", in: root)
            let output = try Generate.run([
                Fake(
                    "a", ["gen/same.swift": "1", "gen/changed.swift": "new", "gen/missing.swift": "3"],
                    owning: ["gen"])
            ])
            #expect(
                Generate.check(output, root: root) == [
                    .init(path: "gen/changed.swift", reason: .differs),
                    .init(path: "gen/missing.swift", reason: .missing),
                    .init(path: "gen/stale.colorset/Contents.json", reason: .stale),
                ])
        }
    }

    @Test("write writes what differs, removes stale files and the directories they leave empty, then check passes")
    func writesDisk() throws {
        try withTemporaryDirectory { root in
            try write("1", "gen/same.swift", in: root)
            try write("x", "gen/stale.colorset/Contents.json", in: root)
            try write("", "gen/.DS_Store", in: root)
            let output = try Generate.run([
                Fake("a", ["gen/same.swift": "1", "gen/new/file.json": "2"], owning: ["gen"])
            ])
            let result = try Generate.write(output, root: root)
            #expect(result.written == ["gen/new/file.json"])
            #expect(result.removed == ["gen/stale.colorset/Contents.json"])
            let manager = FileManager.default
            #expect(!manager.fileExists(atPath: root.appendingPathComponent("gen/stale.colorset").path))
            #expect(manager.fileExists(atPath: root.appendingPathComponent("gen/.DS_Store").path))
            #expect(try String(contentsOf: root.appendingPathComponent("gen/new/file.json"), encoding: .utf8) == "2")
            #expect(Generate.check(output, root: root).isEmpty)
            #expect(try Generate.write(output, root: root) == .init(written: [], removed: []))
        }
    }

    @Test("the registry holds the palette, the Apple token, icon, API and matrix generators, then the agent context")
    func registry() {
        #expect(Generate.sourceGenerators.map(\.name) == ["tokens-palette"])
        #expect(
            Generate.generators.map(\.name) == [
                "tokens-palette", "tokens-apple", "icons-apple", "components-apple", "matrix-apple", "agent-context",
            ])
    }
}
