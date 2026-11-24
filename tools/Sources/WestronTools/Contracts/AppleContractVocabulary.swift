import Foundation

extension AppleComponents {
    /// Where the generator writes the contracts' vocabulary: the module `WestronContract`, which imports nothing, not
    /// even Foundation, so that a product's shared code, which cannot import SwiftUI, can name the options of westron's
    /// components (decisions/0017). `WestronUI` depends on it and re-exports it.
    public static let contractDirectory = "platforms/apple/Sources/WestronContract/Generated"

    /// One enum of a contract's vocabulary: an enum option's, or an enum parameter of a mark's.
    struct VocabularyEnum {
        /// The paragraphs of its doc comment.
        let paragraphs: [String]
        /// `ButtonVariant`.
        let type: String
        let values: [String]
    }

    /// `WestronContract/Generated/<Component>+Contract.swift`: the enums of a contract, with their doc comments,
    /// `String` raw values, `CaseIterable` and `Sendable`, and no import at all; nil when the contract has none.
    ///
    /// A component that some Apple OS lacks keeps its vocabulary under the same `#if` as its API (`absence` says why),
    /// so a model that names it builds where the component does (decisions/0017, open points).
    static func vocabularyFile(
        component: String, source: String, enums: [VocabularyEnum], ofMarks: Bool, condition: String?,
        absence: String?
    ) -> GeneratedFile? {
        guard !enums.isEmpty else { return nil }
        let width = AppleTokensSwift.lineLength - 3
        let origin =
            "Generated from \(source) by `tools/westron generate`. Do not edit: change the contract and generate "
            + "again (spec/conventions.md)."
        let what = ofMarks ? "the enums of its options and of its marks' parameters" : "the enums of its options"
        let purpose =
            "\(component)'s vocabulary from its contract: \(what). WestronContract imports nothing, so that a "
            + "product's shared code names them without SwiftUI; WestronUI re-exports it and adds the SwiftUI side "
            + "(decisions/0017)."
        var out =
            AppleTokensSwift.wrap(origin, width: width).map { "// " + $0 } + ["//"]
            + AppleTokensSwift.wrap(purpose, width: width).map { "// " + $0 }
        func declarations() -> [String] {
            var lines: [String] = []
            for item in enums {
                lines.append("")
                lines += AppleIcons.paragraphs(item.paragraphs, indent: 0)
                lines.append("public enum \(item.type): String, CaseIterable, Sendable {")
                lines += item.values.map { "    case \(SwiftName.declared($0))" }
                lines.append("}")
            }
            return lines
        }
        if let condition {
            out.append("")
            if let absence { out += AppleTokensSwift.wrap(absence, width: width).map { "// " + $0 } }
            let body = AppleTokensSwift.$nesting.withValue(4) { Array(declarations().dropFirst()) }
            out += AppleTokensSwift.conditional(condition, body)
        } else {
            out += declarations()
        }
        return GeneratedFile(
            path: "\(contractDirectory)/\(component)+Contract.swift", contents: out.joined(separator: "\n") + "\n")
    }

    /// The generated files of a contract, in order: its vocabulary in `WestronContract`, then its SwiftUI side in
    /// `WestronUI`; none when the generator skips it.
    /// - Throws: `ContractProblem` when the contract cannot give the API the conventions prescribe.
    public static func files(for contract: ComponentContract, source: String) throws(ContractProblem) -> [GeneratedFile]
    {
        if givesAPI(contract), contract.apple?.strategy == ownStrategy {
            let own = try Own(contract, source: source)
            return [own.vocabularyFile(source: source, contract: contract), own.file(source: source)].compactMap { $0 }
        }
        guard generates(contract), let apple = contract.apple else { return [] }
        let api = try API(contract, apple: apple, source: source)
        return [api.vocabularyFile(), api.file()].compactMap { $0 }
    }

    /// The generated vocabulary of a contract, `WestronContract/Generated/<Component>+Contract.swift`, or nil when the
    /// contract has no enum or the generator skips it.
    public static func contractFile(for contract: ComponentContract, source: String) throws(ContractProblem)
        -> GeneratedFile?
    {
        try files(for: contract, source: source).first { $0.path.hasPrefix(contractDirectory + "/") }
    }
}
