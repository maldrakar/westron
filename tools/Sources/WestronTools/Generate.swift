import Foundation

/// A file a generator produces: a path relative to the repository root and its contents.
public struct GeneratedFile: Equatable, Sendable {
    public let path: String
    public let contents: String

    public init(path: String, contents: String) {
        self.path = path
        self.contents = contents
    }
}

/// A westron generator. It is deterministic: for the same input it produces the same bytes.
public protocol Generator: Sendable {
    /// A short name for the output, for example `tokens-apple`.
    var name: String { get }
    func run() throws -> [GeneratedFile]
}

/// The single entry point for the westron generators (`tools/westron generate [--check]`).
///
/// Generated code is committed (decisions/0001), and CI runs `--check`: a mismatch means that someone changed
/// the source but did not rerun generation, or edited a generated file by hand.
public enum Generate {
    /// The generator registry. Empty for now: the first generators are tokens for Apple (phase 1, #13, #14)
    /// and the API from the contracts (phase 2, #20).
    public static let generators: [any Generator] = []

    public struct Drift: Equatable, Sendable {
        public enum Reason: String, Sendable {
            case missing, differs
        }

        public let path: String
        public let reason: Reason

        public init(path: String, reason: Reason) {
            self.path = path
            self.reason = reason
        }
    }

    public struct DuplicateFile: Error, CustomStringConvertible {
        public let generator: String
        public let path: String

        public var description: String { "\(generator): file \(path) is already produced by another generator" }
    }

    /// The outputs of all generators, in order. Two generators cannot produce the same file.
    public static func collect(_ generators: [any Generator]) throws -> [GeneratedFile] {
        var files: [GeneratedFile] = []
        var paths: Set<String> = []
        for generator in generators {
            for file in try generator.run() {
                guard paths.insert(file.path).inserted else {
                    throw DuplicateFile(generator: generator.name, path: file.path)
                }
                files.append(file)
            }
        }
        return files
    }

    /// The files whose contents on disk differ from a fresh generation. `read` returns nil for a missing file.
    public static func findDrift(_ files: [GeneratedFile], read: (String) -> String?) -> [Drift] {
        files.compactMap { file in
            guard let current = read(file.path) else { return Drift(path: file.path, reason: .missing) }
            return current == file.contents ? nil : Drift(path: file.path, reason: .differs)
        }
    }
}
