import Foundation
import WestronTools

// The westron generators and checks. Run it through `tools/westron`, which picks the toolchain and builds it.
// Paths are relative to the repository root.

let usage = """
    usage: tools/westron lint raw-values [FILE.swift | DIRECTORY …]
           tools/westron generate [--check]
    """

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

struct NoSuchPath: Error, CustomStringConvertible {
    let path: String
    var description: String { "no such file or directory: \(path)" }
}

/// The .swift files at a path: the file itself, or every one inside a directory, in a stable order.
func swiftFiles(at path: String) throws -> [String] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
        throw NoSuchPath(path: path)
    }
    guard isDirectory.boolValue else { return path.hasSuffix(".swift") ? [path] : [] }
    let directory = path.hasSuffix("/") ? path : path + "/"
    return try FileManager.default.contentsOfDirectory(atPath: path).sorted().flatMap {
        try swiftFiles(at: directory + $0)
    }
}

func displayPath(_ path: String) -> String {
    let prefix = FileManager.default.currentDirectoryPath + "/"
    return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
}

func lintRawValues(_ paths: [String]) throws -> Int32 {
    let files = try (paths.isEmpty ? RawValues.defaultRoots : paths).flatMap(swiftFiles(at:))
    var count = 0
    for file in files {
        for v in RawValues.find(in: try String(contentsOfFile: file, encoding: .utf8)) {
            count += 1
            printError(
                "\(displayPath(file)):\(v.line):\(v.column): raw value (\(v.kind)) `\(v.text)`: "
                    + "use a token; for a deliberate exception: // \(RawValues.allowMarker) <reason>")
        }
    }
    if count > 0 {
        printError("raw-values: violations: \(count)")
        return 1
    }
    print("raw-values: files checked: \(files.count), no violations")
    return 0
}

func generate(check: Bool) throws -> Int32 {
    if Generate.generators.isEmpty {
        print("generate: no generators yet; they arrive in phase 1")
        return 0
    }
    let files = try Generate.collect(Generate.generators)
    if check {
        let drift = Generate.findDrift(files) { try? String(contentsOfFile: $0, encoding: .utf8) }
        for d in drift {
            printError("\(d.path): \(d.reason.rawValue) (compared with a fresh generation)")
        }
        if !drift.isEmpty {
            printError("generate --check: run `tools/westron generate` and commit the result")
            return 1
        }
        print("generate --check: files: \(files.count), all match")
        return 0
    }
    for file in files {
        let url = URL(fileURLWithPath: file.path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(file.contents.utf8).write(to: url)
    }
    print("generate: files written: \(files.count)")
    return 0
}

let arguments = Array(CommandLine.arguments.dropFirst())
do {
    switch (arguments.first, arguments.dropFirst().first) {
    case ("lint", "raw-values"):
        exit(try lintRawValues(Array(arguments.dropFirst(2))))
    case ("generate", nil):
        exit(try generate(check: false))
    case ("generate", "--check") where arguments.count == 2:
        exit(try generate(check: true))
    default:
        printError(usage)
        exit(2)
    }
} catch {
    printError("westron: \(error)")
    exit(1)
}
