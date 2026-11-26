import Foundation
import WestronTools

// The westron generators and checks. Run it through `tools/westron`, which picks the toolchain and builds it.
// Paths are relative to the repository root.

let usage = """
    usage: tools/westron lint raw-values [FILE.swift | DIRECTORY …]
           tools/westron lint api-parity            (an exception: // westron-api-parity: allow <reason>)
           tools/westron generate [--check]
           tools/westron tokens check [RESOLVER.json]
           tools/westron tokens contrast [--all] [RESOLVER.json]
           tools/westron icons check [REGISTRY.yaml]
           tools/westron spec check [FILE.spec.yaml …]
           tools/westron patterns check [FILE.md …]
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

/// The API parity lint (#21): the public API of WestronUI and WestronContract against the contracts and
/// spec/conventions.md.
func lintAPIParity() throws -> Int32 {
    let report = try APIParity.run()
    for problem in report.problems { printError(problem.description) }
    if !report.problems.isEmpty {
        printError("api-parity: problems: \(report.problems.count)")
        return 1
    }
    print(
        "api-parity: contracts: \(report.contracts), files: \(report.files), public declarations: "
            + "\(report.publicDeclarations), of them the contracts' component API: \(report.expected), no problems")
    return 0
}

func generate(check: Bool) throws -> Int32 {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    if check {
        let output = try Generate.run(Generate.generators)
        let drift = Generate.check(output, root: root)
        for d in drift {
            let reason =
                d.reason == .stale
                ? "stale (no generator produces it)" : "\(d.reason.rawValue) (compared with a fresh generation)"
            printError("\(d.path): \(reason)")
        }
        if !drift.isEmpty {
            printError("generate --check: run `tools/westron generate` and commit the result")
            return 1
        }
        print("generate --check: files: \(output.files.count), all match")
        return 0
    }
    // The platform generators read what the source generators write, so those files go to disk first.
    let sources = try Generate.write(try Generate.run(Generate.sourceGenerators), root: root)
    let output = try Generate.run(Generate.generators)
    let result = try Generate.write(output, root: root)
    let written = sources.written + result.written.filter { !sources.written.contains($0) }
    for path in result.removed { print("generate: removed \(path)") }
    print("generate: files: \(output.files.count), written: \(written.count), removed: \(result.removed.count)")
    return 0
}

func checkTokens(_ resolver: String?) throws -> Int32 {
    let resolver = resolver ?? TokenCheck.defaultResolver
    do {
        let report = try TokenCheck.run(resolverFile: resolver)
        print(
            "tokens check: \(report.resolver): token files: \(report.files.count), "
                + "combinations: \(report.combinations.count), all valid")
        for line in report.summary() { print("tokens check: \(line)") }
        return 0
    } catch let errors as TokenErrors {
        for error in errors.errors { printError(error.description) }
        printError(
            "tokens check: problems: \(errors.errors.count) "
                + "(the supported DTCG subset: tools/Sources/WestronTools/Tokens/README.md)")
        return 1
    }
}

/// The icon registry (decisions/0011): its keys, names, symbols and default.
func checkIcons(_ file: String?) throws -> Int32 {
    let file = file ?? IconRegistry.defaultFile
    do {
        let registry = try IconRegistry.load(file: file)
        print("icons check: \(file): icons: \(registry.icons.count), default: \(registry.fallback), all valid")
        return 0
    } catch let problems as IconRegistry.Problems {
        for problem in problems.problems { printError(problem.description) }
        printError("icons check: problems: \(problems.problems.count)")
        return 1
    }
}

/// Component contracts (#18): the given files, or every `spec/components/*/*.spec.yaml`.
func checkSpecs(_ files: [String]) throws -> Int32 {
    let files = files.isEmpty ? try ContractCheck.files(in: ContractCheck.defaultDirectory) : files
    guard !files.isEmpty else {
        print("spec check: contracts: 0")
        return 0
    }
    do {
        let problems = try ContractCheck.run(files: files)
        for problem in problems { printError(problem.description) }
        if !problems.isEmpty {
            printError("spec check: contracts: \(files.count), problems: \(problems.count)")
            return 1
        }
        print("spec check: contracts: \(files.count), all valid")
        return 0
    } catch let errors as TokenErrors {
        for error in errors.errors { printError(error.description) }
        printError("spec check: the tokens do not load; run tools/westron tokens check")
        return 1
    }
}

/// Patterns (decisions/0018): the given files, or every `spec/patterns/*.md`, against the contracts, the tokens, the
/// icon registry and WestronUI's API.
func checkPatterns(_ files: [String]) throws -> Int32 {
    let files = files.isEmpty ? try PatternCheck.files(in: PatternCheck.defaultDirectory) : files
    guard !files.isEmpty else {
        print("patterns check: patterns: 0")
        return 0
    }
    do {
        let problems = try PatternCheck.run(files: files)
        for problem in problems { printError(problem.description) }
        if !problems.isEmpty {
            printError("patterns check: patterns: \(files.count), problems: \(problems.count) (decisions/0018)")
            return 1
        }
        print("patterns check: patterns: \(files.count), all valid")
        return 0
    } catch let problems as AppleComponents.Problems {
        for problem in problems.problems { printError(problem.description) }
        printError("patterns check: the contracts do not pass; run tools/westron spec check")
        return 1
    } catch let errors as TokenErrors {
        for error in errors.errors { printError(error.description) }
        printError("patterns check: the tokens do not load; run tools/westron tokens check")
        return 1
    } catch let problems as IconRegistry.Problems {
        for problem in problems.problems { printError(problem.description) }
        printError("patterns check: the icon registry does not load; run tools/westron icons check")
        return 1
    }
}

/// The WCAG 2 contrast of every declared "text/background" pair in every theme (#15). Prints the failures and a
/// summary; with `--all`, every pair.
func checkContrast(_ options: [String]) throws -> Int32 {
    let all = options.contains("--all")
    let rest = options.filter { $0 != "--all" }
    guard rest.count <= 1 else {
        printError(usage)
        return 2
    }
    do {
        let resolution = try Resolution(resolverFile: rest.first ?? TokenCheck.defaultResolver)
        let themes = try ContrastCheck.run(resolution)
        let failures = themes.reduce(0) { $0 + $1.failures }
        if all || failures > 0 {
            let shown =
                all
                ? themes
                : themes.map {
                    ContrastCheck.ThemeResults(name: $0.name, kind: $0.kind, results: $0.results.filter { !$0.passes })
                }
            print(ContrastCheck.report(shown))
        }
        if !all || failures > 0 {
            for theme in themes {
                print(
                    "contrast: \(theme.name) (\(theme.kind.rawValue)): \(theme.results.count) pairs, \(theme.failures) failed"
                )
            }
        }
        return failures == 0 ? 0 : 1
    } catch let errors as TokenErrors {
        for error in errors.errors { printError(error.description) }
        printError("tokens contrast: problems: \(errors.errors.count)")
        return 1
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
do {
    switch (arguments.first, arguments.dropFirst().first) {
    case ("lint", "raw-values"):
        exit(try lintRawValues(Array(arguments.dropFirst(2))))
    case ("lint", "api-parity") where arguments.count == 2:
        exit(try lintAPIParity())
    case ("generate", nil):
        exit(try generate(check: false))
    case ("generate", "--check") where arguments.count == 2:
        exit(try generate(check: true))
    case ("tokens", "check") where arguments.count <= 3:
        exit(try checkTokens(arguments.dropFirst(2).first))
    case ("tokens", "contrast"):
        exit(try checkContrast(Array(arguments.dropFirst(2))))
    case ("icons", "check") where arguments.count <= 3:
        exit(try checkIcons(arguments.dropFirst(2).first))
    case ("spec", "check"):
        exit(try checkSpecs(Array(arguments.dropFirst(2))))
    case ("patterns", "check"):
        exit(try checkPatterns(Array(arguments.dropFirst(2))))
    default:
        printError(usage)
        exit(2)
    }
} catch {
    printError("westron: \(error)")
    exit(1)
}
