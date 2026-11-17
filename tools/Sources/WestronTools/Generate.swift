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
    /// Directories, relative to the repository root, that hold generated files only. A file in one of them that no
    /// generator produces any more is stale: `generate` removes it and `generate --check` reports it. Hidden files,
    /// such as `.DS_Store`, are ignored. Empty by default.
    var ownedDirectories: [String] { get }
    func run() throws -> [GeneratedFile]
}

extension Generator {
    public var ownedDirectories: [String] { [] }
}

/// The single entry point for the westron generators (`tools/westron generate [--check]`).
///
/// Generated code is committed (decisions/0001), and CI runs `--check`: a mismatch means that someone changed
/// the source but did not rerun generation, or edited a generated file by hand.
public enum Generate {
    /// The generators that write sources other generators read: the palette writes the color ramps into `tokens/`.
    /// `generate` writes their files before it runs the rest.
    public static let sourceGenerators: [any Generator] = [PaletteTokens()]
    /// The generator registry, in order.
    public static let generators: [any Generator] =
        sourceGenerators + [AppleTokens(), AppleIcons(), AppleComponents(), AppleSnapshotMatrix()]

    /// The files of all generators and the directories they own.
    public struct Output: Equatable, Sendable {
        public let files: [GeneratedFile]
        /// Sorted, each once.
        public let ownedDirectories: [String]

        public init(files: [GeneratedFile], ownedDirectories: [String]) {
            self.files = files
            self.ownedDirectories = ownedDirectories
        }
    }

    public struct Drift: Equatable, Sendable {
        public enum Reason: String, Sendable {
            /// A file the generators produce is not on disk.
            case missing
            /// A file on disk differs from what the generators produce.
            case differs
            /// A file in an owned directory that no generator produces.
            case stale
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

    /// An owned directory that is not a plain relative path inside the repository.
    public struct InvalidOwnedDirectory: Error, CustomStringConvertible {
        public let generator: String
        public let path: String

        public var description: String {
            "\(generator): owned directory \"\(path)\" must be a relative path inside the repository, without . or .."
        }
    }

    /// The outputs of all generators, in order. Two generators cannot produce the same file.
    public static func collect(_ generators: [any Generator]) throws -> [GeneratedFile] {
        try run(generators).files
    }

    /// Runs every generator: their files in order, and the directories they own. Two generators cannot produce the
    /// same file; two may own the same directory.
    public static func run(_ generators: [any Generator]) throws -> Output {
        var files: [GeneratedFile] = []
        var paths: Set<String> = []
        var owned: Set<String> = []
        for generator in generators {
            for directory in generator.ownedDirectories {
                let components = directory.split(separator: "/", omittingEmptySubsequences: false)
                guard !directory.hasPrefix("/"), !components.contains(where: { ["", ".", ".."].contains($0) }) else {
                    throw InvalidOwnedDirectory(generator: generator.name, path: directory)
                }
                owned.insert(directory)
            }
            for file in try generator.run() {
                guard paths.insert(file.path).inserted else {
                    throw DuplicateFile(generator: generator.name, path: file.path)
                }
                files.append(file)
            }
        }
        return Output(files: files, ownedDirectories: owned.sorted())
    }

    /// The files whose contents on disk differ from a fresh generation. `read` returns nil for a missing file.
    public static func findDrift(_ files: [GeneratedFile], read: (String) -> String?) -> [Drift] {
        files.compactMap { file in
            guard let current = read(file.path) else { return Drift(path: file.path, reason: .missing) }
            return current == file.contents ? nil : Drift(path: file.path, reason: .differs)
        }
    }

    /// The files in the owned directories that no generator produces, sorted. `list` returns the files under a
    /// directory, recursively, as paths that start with it; none for a missing directory.
    public static func findStale(
        _ files: [GeneratedFile], in directories: [String], list: (String) -> [String]
    ) -> [Drift] {
        let produced = Set(files.map(\.path))
        let onDisk = Set(directories.flatMap(list))
        return onDisk.subtracting(produced).sorted().map { Drift(path: $0, reason: .stale) }
    }

    /// What `generate --check` reports: missing and changed files in generation order, then stale files.
    /// - Parameter root: the directory the paths are relative to, the repository root.
    public static func check(_ output: Output, root: URL) -> [Drift] {
        findDrift(output.files) { try? String(contentsOf: root.appendingPathComponent($0), encoding: .utf8) }
            + findStale(output.files, in: output.ownedDirectories) { filesOnDisk(in: $0, root: root) }
    }

    /// What `generate` changed on disk.
    public struct WriteResult: Equatable, Sendable {
        /// Files written because they were missing or differed, in generation order.
        public let written: [String]
        /// Stale files removed, sorted.
        public let removed: [String]

        public init(written: [String], removed: [String]) {
            self.written = written
            self.removed = removed
        }
    }

    /// Writes the files that are missing or differ, leaving the others untouched so that their dates do not change,
    /// and removes stale files and the directories they leave empty inside the owned directories.
    /// - Parameter root: the directory the paths are relative to, the repository root.
    @discardableResult
    public static func write(_ output: Output, root: URL) throws -> WriteResult {
        let manager = FileManager.default
        var written: [String] = []
        for file in output.files {
            let url = root.appendingPathComponent(file.path)
            if (try? String(contentsOf: url, encoding: .utf8)) == file.contents { continue }
            try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(file.contents.utf8).write(to: url)
            written.append(file.path)
        }
        let stale = findStale(output.files, in: output.ownedDirectories) { filesOnDisk(in: $0, root: root) }
        for drift in stale {
            try manager.removeItem(at: root.appendingPathComponent(drift.path))
        }
        for directory in output.ownedDirectories {
            try removeEmptyDirectories(in: root.appendingPathComponent(directory))
        }
        return WriteResult(written: written, removed: stale.map(\.path))
    }

    /// The files under a directory, recursively, as paths that start with it and are relative to `root`, sorted;
    /// none for a missing directory. Hidden files and directories are skipped.
    public static func filesOnDisk(in directory: String, root: URL) -> [String] {
        let manager = FileManager.default
        let url = root.appendingPathComponent(directory)
        guard let names = try? manager.contentsOfDirectory(atPath: url.path) else { return [] }
        return names.filter { !$0.hasPrefix(".") }.sorted().flatMap { name -> [String] in
            let path = directory + "/" + name
            var isDirectory: ObjCBool = false
            manager.fileExists(atPath: root.appendingPathComponent(path).path, isDirectory: &isDirectory)
            return isDirectory.boolValue ? filesOnDisk(in: path, root: root) : [path]
        }
    }

    /// Removes the directories under `url` that hold nothing but hidden files, deepest first; `url` itself stays.
    private static func removeEmptyDirectories(in url: URL) throws {
        let manager = FileManager.default
        guard let names = try? manager.contentsOfDirectory(atPath: url.path) else { return }
        for name in names where !name.hasPrefix(".") {
            let child = url.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            guard manager.fileExists(atPath: child.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            try removeEmptyDirectories(in: child)
            let rest = try manager.contentsOfDirectory(atPath: child.path)
            if rest.allSatisfy({ $0.hasPrefix(".") }) { try manager.removeItem(at: child) }
        }
    }
}
