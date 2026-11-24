import Foundation

@testable import WestronTools

/// The sources the generator writes for a contract, for the API parity lint, at their paths with
/// `platforms/apple/Sources/` replaced by `prefix`: WestronContract's under `<prefix>WestronContract/`, WestronUI's
/// under `<prefix>WestronUI/` (decisions/0017).
func generatedSources(_ contract: ComponentContract, source: String, prefix: String = "") throws -> [(
    path: String, text: String
)] {
    try AppleComponents.files(for: contract, source: source).map { file in
        let sources = "platforms/apple/Sources/"
        let path = file.path.hasPrefix(sources) ? prefix + file.path.dropFirst(sources.count) : file.path
        return (path, file.contents)
    }
}

/// The real repository's WestronUI and WestronContract, as the lint's `run` reads them: their roots, and every Swift
/// file under each, sorted.
func repositoryModules() throws -> (sources: String, contractSources: String, files: [(path: String, text: String)]) {
    let sources = repositoryRoot.appendingPathComponent(APIParity.defaultSources).path
    let contractSources = repositoryRoot.appendingPathComponent(APIParity.defaultContractSources).path
    var files: [(path: String, text: String)] = []
    for root in [sources, contractSources] {
        let paths = try FileManager.default.subpathsOfDirectory(atPath: root).filter { $0.hasSuffix(".swift") }.sorted()
        files += try paths.map { (root + "/" + $0, try String(contentsOfFile: root + "/" + $0, encoding: .utf8)) }
    }
    return (sources, contractSources, files)
}

/// Every file the generator writes for a contract, joined: what a test reads when it does not care which module a
/// declaration lands in.
func generatedText(_ contract: ComponentContract, source: String) throws -> String {
    try AppleComponents.files(for: contract, source: source).map(\.contents).joined(separator: "\n")
}
