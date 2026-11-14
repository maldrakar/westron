import Testing
import WestronTools

private struct Fake: Generator {
    let name: String
    let files: [GeneratedFile]

    init(_ name: String, _ files: KeyValuePairs<String, String>) {
        self.name = name
        self.files = files.map { GeneratedFile(path: $0.key, contents: $0.value) }
    }

    func run() -> [GeneratedFile] { files }
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
}
