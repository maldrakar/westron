import Foundation

/// `tools/westron spec check`: each component contract passes the schema, `spec/schema/component.schema.json`, and
/// the rules the schema cannot express (`ContractRules`). Every problem is reported, the schema's and the rules' in
/// one run.
public enum ContractCheck {
    /// The contracts' directory, relative to the repository root: one folder per component.
    public static let defaultDirectory = "spec/components"
    public static let fileSuffix = ".spec.yaml"

    /// The contracts under a directory, `<directory>/*/*.spec.yaml`, sorted; none if it does not exist.
    public static func files(in directory: String) throws -> [String] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory), isDirectory.boolValue
        else { return [] }
        let prefix = directory.hasSuffix("/") ? directory : directory + "/"
        return try FileManager.default.contentsOfDirectory(atPath: directory).sorted().flatMap { name -> [String] in
            let folder = prefix + name
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: folder, isDirectory: &isDirectory), isDirectory.boolValue
            else { return [] }
            return try FileManager.default.contentsOfDirectory(atPath: folder).sorted()
                .filter { $0.hasSuffix(fileSuffix) }.map { folder + "/" + $0 }
        }
    }

    /// Checks contract files, with the schema and the tokens of the default resolver.
    /// - Throws: `ContractSchema.LoadError` or `TokenErrors` if the schema or the tokens cannot be loaded.
    public static func run(files: [String], schemaFile: String = ContractSchema.defaultFile) throws
        -> [ContractProblem]
    {
        let schema = try ContractSchema(file: schemaFile)
        let tokens = try ContractTokens(Resolution(resolverFile: TokenCheck.defaultResolver))
        return files.flatMap { check(file: $0, schema: schema, tokens: tokens) }
    }

    /// The problems of one contract file, at a path relative to the working directory.
    public static func check(file: String, schema: ContractSchema, tokens: ContractTokens) -> [ContractProblem] {
        guard let text = try? String(contentsOfFile: file, encoding: .utf8) else {
            return [ContractProblem(source: file, place: "(root)", "cannot be read as UTF-8 text")]
        }
        return check(yaml: text, source: file, schema: schema, tokens: tokens)
    }

    /// The problems of a contract's text; `source` is its path, which must be `<id>/<id>.spec.yaml`.
    public static func check(yaml: String, source: String, schema: ContractSchema, tokens: ContractTokens)
        -> [ContractProblem]
    {
        let document: JSON
        do {
            document = try ContractYAML.parse(yaml, source: source)
        } catch {
            return [error]
        }
        var rules = ContractRules(document: document, source: source, tokens: tokens)
        rules.run()
        var seen: Set<String> = []
        return (schema.validate(document) + rules.problems)
            .map { ContractProblem(source: source, path: $0.path, $0.message) }
            .filter { seen.insert($0.description).inserted }
    }
}
