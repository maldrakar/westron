import Foundation
import Testing
import WestronTools

/// westron's Disclosure contract, the one component an Apple OS lacks (watchOS, #120).
private let disclosureSource = "spec/components/disclosure/disclosure.spec.yaml"
private let disclosureText = try! String(
    contentsOf: repositoryRoot.appendingPathComponent(disclosureSource), encoding: .utf8)

private func disclosure(_ text: String = disclosureText) throws -> ComponentContract {
    try ComponentContract(yaml: text, source: disclosureSource)
}

/// The Disclosure contract with one part replaced, which must occur in it.
private func replacing(_ old: String, with new: String) -> String {
    precondition(disclosureText.contains(old), old)
    return disclosureText.replacingOccurrences(of: old, with: new)
}

/// The watchOS entry of the Disclosure contract, as it stands.
private let watchEntry = """
        watchos:
          status: unavailable
    """

private let schema = try! ContractSchema(file: repositoryRoot.appendingPathComponent(ContractSchema.defaultFile).path)
private let tokens = try! ContractTokens(
    Resolution(resolverFile: repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path))

/// The problems of a text checked as the Disclosure contract, as `place: message`.
private func problems(_ text: String) -> [String] {
    ContractCheck.check(yaml: text, source: disclosureSource, schema: schema, tokens: tokens)
        .map { "\($0.place): \($0.message)" }
}

@Suite("A component an Apple OS lacks, and a context it sets")
struct UnavailableOSTests {
    @Test("SwiftUI's DisclosureGroup is a base with its style modifier and protocol, and no watchOS")
    func systemStyle() throws {
        let base = try #require(SystemStyles.byBase["SwiftUI.DisclosureGroup"])
        #expect(base.modifier == "disclosureGroupStyle")
        #expect(base.protocols == ["DisclosureGroupStyle"])
        #expect(base.styles == ["automatic"])
        #expect(base.unavailableOn == ["watchos"])
        #expect(SystemStyles.byBase["SwiftUI.Button"]?.unavailableOn == [])
    }

    @Test("the contract reads an unavailable OS: no OS of its own, a condition for the generated code")
    func contractReadsIt() throws {
        let apple = try #require(try disclosure().apple)
        #expect(apple.unavailable == ["watchos"])
        #expect(apple.availableOSes == ["ios", "macos"])
        #expect(apple.availabilityCondition == "!os(watchOS)")
        #expect(try disclosure().context == ["alignsLeaves"])
    }

    @Test("Disclosure is valid; the schema wants an unavailable OS's description and nothing else")
    func schema() {
        #expect(problems(disclosureText) == [])
        let bare = replacing(
            "      status: unavailable\n      description: >-\n",
            with: "      status: unavailable\n      notes: >-\n")
        #expect(!problems(bare).isEmpty, "an unavailable OS without a description, with another key, is valid")
        let withStates = replacing(
            "      status: unavailable\n", with: "      status: unavailable\n      states: [hover]\n")
        #expect(!problems(withStates).isEmpty, "an unavailable OS with states is valid")
        let otherStatus = replacing("      status: unavailable\n", with: "      status: missing\n")
        #expect(!problems(otherStatus).isEmpty, "an OS status other than unavailable is valid")
    }

    @Test("the rules: a DisclosureGroup base must leave watchOS out; one OS must remain; only a style is derived")
    func rules() {
        // The watchOS entry taken out: SwiftUI has no DisclosureGroup there, so the contract must say so.
        let start = disclosureText.range(of: "    watchos:\n")!
        let end = disclosureText.range(of: "  web:\n")!
        let withWatch = disclosureText.replacingCharacters(in: start.lowerBound..<end.lowerBound, with: "")
        #expect(
            problems(withWatch).contains {
                $0.hasPrefix("platforms.apple.base: ")
                    && $0.contains("SwiftUI has no SwiftUI.DisclosureGroup on watchOS")
            }, "\(problems(withWatch))")
        // Every OS unavailable.
        let none = replacing(
            "    ios:\n      description: >-\n",
            with: "    ios:\n      status: unavailable\n      description: >-\n"
        ).replacingOccurrences(
            of: "    macos:\n      keyboardIntents: [expand, collapse]\n      description: >-\n",
            with: "    macos:\n      status: unavailable\n      description: >-\n")
        #expect(
            problems(none).contains { $0.contains("unavailable on every Apple OS") }, "\(problems(none))")
    }

    @Test("the generated API is all under #if !os(watchOS), with the context's modifier expected, not generated")
    func generatedAPI() throws {
        let file = try #require(try AppleComponents.file(for: disclosure(), source: disclosureSource))
        let lines = file.contents.split(separator: "\n", omittingEmptySubsequences: false)
        let opening = try #require(lines.firstIndex(of: "#if !os(watchOS)"))
        #expect(lines.filter { $0 == "#if !os(watchOS)" }.count == 1)
        #expect(lines.last { !$0.isEmpty } == "#endif")
        // Everything after the header is inside, indented once; nothing public stands outside it.
        for line in lines[..<opening] { #expect(!line.contains("public "), "\(line)") }
        #expect(file.contents.contains("        public func disclosureGroupStyle(_ variant: DisclosureVariant)"))
        // The vocabulary in WestronContract keeps the component's availability, under the same #if (decisions/0017).
        let vocabulary = try #require(try AppleComponents.contractFile(for: disclosure(), source: disclosureSource))
        let vocabularyLines = vocabulary.contents.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(vocabularyLines.filter { $0 == "#if !os(watchOS)" }.count == 1)
        #expect(vocabularyLines.last { !$0.isEmpty } == "#endif")
        #expect(vocabulary.contents.contains("    public enum DisclosureVariant: String, CaseIterable, Sendable {"))
        #expect(!vocabulary.contents.contains("\nimport "))
        #expect(
            try String(contentsOf: repositoryRoot.appendingPathComponent(vocabulary.path), encoding: .utf8)
                == vocabulary.contents)
        // The context's modifier is hand-written (`.disclosureAlignsLeaves(_:)`): the generator writes none.
        #expect(!file.contents.contains("disclosureAlignsLeaves"))
        // westron's own file on disk is this generation.
        let onDisk = try String(contentsOf: repositoryRoot.appendingPathComponent(file.path), encoding: .utf8)
        #expect(onDisk == file.contents)
    }

    @Test("the matrix has no watchOS restriction, is under #if, and the registry appends it under the same #if")
    func matrix() throws {
        let contract = try disclosure()
        let matrix = try SnapshotMatrix(contract, source: disclosureSource)
        #expect(matrix.platforms.map(\.os).allSatisfy { $0 != "watchos" })
        #expect(matrix.availabilityCondition == "!os(watchOS)")
        let files = try AppleSnapshotMatrix.files(for: [(contract, disclosureSource)])
        #expect(files[0].contents.contains("\n#if !os(watchOS)\n    extension ComponentMatrix {\n"))
        let registry = files[1].contents
        #expect(registry.contains("    public static let all: [ComponentMatrix] = {\n"))
        #expect(registry.contains("        #if !os(watchOS)\n            all.append(.disclosure)\n        #endif\n"))
        // With nothing conditional, the registry stays a literal.
        let button = try ComponentContract(
            yaml: try String(
                contentsOf: repositoryRoot.appendingPathComponent("spec/components/button/button.spec.yaml"),
                encoding: .utf8), source: "spec/components/button/button.spec.yaml")
        let plain = try AppleSnapshotMatrix.files(for: [(button, "spec/components/button/button.spec.yaml")])
        #expect(plain[1].contents.contains("    public static let all: [ComponentMatrix] = [.button]\n"))
    }

    @Test("the parity lint: the API under the contract's own #if passes, the context's modifier is expected")
    func parity() throws {
        let directory = repositoryRoot.appendingPathComponent(ContractCheck.defaultDirectory).path
        let (sources, contractSources, swiftFiles) = try repositoryModules()
        let report = try APIParity.run(
            contractsDirectory: directory, sourceRoot: sources, contractRoot: contractSources)
        #expect(report.problems.isEmpty, "\(report.problems.map(\.description))")
        // Without the hand-written modifier, the lint misses it.
        var contracts: [APIParity.Contract] = []
        for file in try ContractCheck.files(in: directory) {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            contracts.append(
                APIParity.Contract(contract: try ComponentContract(yaml: text, source: file), source: file, text: text))
        }
        let without = swiftFiles.map { file in
            (
                path: file.path,
                text: file.text.replacingOccurrences(
                    of: "public func disclosureAlignsLeaves(", with: "func disclosureAlignsLeaves(")
            )
        }
        let missing = APIParity.check(
            contracts: contracts, files: without, sourceRoot: sources, contractRoot: contractSources
        ).problems.map(\.description)
        #expect(missing.contains { $0.contains("disclosureAlignsLeaves") }, "\(missing)")
        // A public declaration under another #if is still a problem.
        let otherCondition = swiftFiles.map { file in
            (path: file.path, text: file.text.replacingOccurrences(of: "#if !os(watchOS)", with: "#if os(iOS)"))
        }
        let conditioned = APIParity.check(
            contracts: contracts, files: otherCondition, sourceRoot: sources, contractRoot: contractSources
        ).problems.map(\.description)
        #expect(conditioned.contains { $0.contains("#if") }, "\(conditioned)")
        // The vocabulary under another #if is a problem too: its availability is the component's.
        let vocabularyOnly = swiftFiles.map { file in
            guard file.path.hasPrefix(contractSources) else { return file }
            return (path: file.path, text: file.text.replacingOccurrences(of: "#if !os(watchOS)", with: "#if os(iOS)"))
        }
        let vocabularyConditioned = APIParity.check(
            contracts: contracts, files: vocabularyOnly, sourceRoot: sources, contractRoot: contractSources
        ).problems.map(\.description)
        #expect(
            vocabularyConditioned.contains {
                $0.contains("WestronContract/Generated/Disclosure+Contract.swift:")
                    && $0.contains("public API under #if os(iOS)")
            },
            "\(vocabularyConditioned)")
    }
}
