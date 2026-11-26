import Foundation
import Testing

@testable import WestronCatalog

/// A pattern's Apple example runs in the catalog as the document writes it (decisions/0018, point 4, stage 2): the
/// swift block of `spec/patterns/<id>.md` is the catalog's source of that example, character for character, after the
/// file's leading comment. The document is the truth: a change to either that the other does not repeat fails here.
@Suite("Patterns in the catalog")
struct PatternExampleTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// A pattern entry's example in the catalog: the pattern's id, and the file under
    /// `platforms/apple/Sources/WestronCatalog/Patterns/` that holds the document's swift block.
    struct Example: Sendable, CustomTestStringConvertible {
        let id: String
        let file: String

        var testDescription: String { id }
    }

    static let examples = [
        Example(id: "choice-list-sheet", file: "ChoiceListSheet/ChoiceSheet.swift")
    ]

    static func text(_ path: String) throws -> String {
        try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
    }

    /// The document's swift blocks, each without its fences.
    static func swiftBlocks(_ markdown: String) -> [String] {
        var blocks: [String] = []
        var block: [Substring]?
        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            if block == nil, line == "```swift" {
                block = []
            } else if let lines = block, line == "```" {
                blocks.append(lines.map { $0 + "\n" }.joined())
                block = nil
            } else {
                block?.append(line)
            }
        }
        return blocks
    }

    /// The catalog file without its leading comment lines and the blank line after them.
    static func withoutHeader(_ source: String) -> String {
        var lines = source.split(separator: "\n", omittingEmptySubsequences: false)[...]
        while let first = lines.first, first.hasPrefix("//") { lines = lines.dropFirst() }
        if lines.first == "" { lines = lines.dropFirst() }
        return lines.joined(separator: "\n")
    }

    @Test("Every pattern entry is an approved pattern of spec/patterns/ with its example in the catalog")
    func entries() throws {
        let ids = Catalog.entries(in: .patterns).map(\.id)
        #expect(ids == ["choice-list-sheet"])
        #expect(
            Set(ids) == Set(Self.examples.map(\.id)),
            "a pattern entry without its example in `examples`, or the reverse")
        for id in ids {
            let document = try Self.text("spec/patterns/\(id).md")
            #expect(document.hasPrefix("---\nid: \(id)\n"), "spec/patterns/\(id).md does not start with its id")
            #expect(document.contains("\nstatus: approved\n"), "the pattern \(id) is not approved")
        }
    }

    @Test("A pattern's swift block is its catalog example, character for character", arguments: examples)
    func exampleIsTheDocuments(_ example: Example) throws {
        let blocks = Self.swiftBlocks(try Self.text("spec/patterns/\(example.id).md"))
        try #require(blocks.count == 1, "spec/patterns/\(example.id).md has \(blocks.count) swift blocks, not one")
        let source = Self.withoutHeader(
            try Self.text("platforms/apple/Sources/WestronCatalog/Patterns/\(example.file)"))
        #expect(source.hasPrefix("import SwiftUI\n"), "\(example.file) has more than a comment before its code")
        if blocks[0] != source {
            let document = blocks[0].split(separator: "\n", omittingEmptySubsequences: false)
            let catalog = source.split(separator: "\n", omittingEmptySubsequences: false)
            let line =
                zip(document, catalog).enumerated().first { $0.element.0 != $0.element.1 }?.offset
                ?? min(document.count, catalog.count)
            Issue.record(
                """
                spec/patterns/\(example.id).md's swift block and \(example.file) differ from the block's line \
                \(line + 1): "\(line < document.count ? document[line] : "<end>")" in the document, \
                "\(line < catalog.count ? catalog[line] : "<end>")" in the catalog. Change the two together.
                """)
        }
    }

    @Test("The comparison sees a difference of one character, and the header is all it leaves out")
    func comparisonIsStrict() {
        let markdown = "Text\n\n```swift\nimport SwiftUI\nlet a = 1\n```\n\nMore\n"
        #expect(Self.swiftBlocks(markdown) == ["import SwiftUI\nlet a = 1\n"])
        #expect(Self.withoutHeader("// one\n// two\n\nimport SwiftUI\nlet a = 1\n") == "import SwiftUI\nlet a = 1\n")
        #expect(Self.withoutHeader("// one\n\nimport SwiftUI\nlet a = 2\n") != Self.swiftBlocks(markdown)[0])
    }
}
