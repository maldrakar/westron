import Foundation

/// A DTCG 2025.10 resolver document (Resolver module, 4): sets, modifiers, and the order in which their sources merge.
///
/// Read with the references resolved: each step of `resolutionOrder` holds its sources in merge order, with the sets
/// a source refers to inlined. The subset westron reads is in `README.md` next to this file; what it rejects fails
/// with an error that names the place in the document.
public struct ResolverDocument: Equatable, Sendable {
    /// Where a source's tokens come from.
    public enum Source: Hashable, Sendable {
        /// A token file: the resolver's directory joined with the `$ref`, so a path relative to the repository root.
        case file(String)
        /// Tokens written inside the resolver document, at a JSON Pointer such as `#/sets/base/sources/0`. Their
        /// JSON is in `inlineTokens`.
        case inline(String)

        /// The name the source's tokens carry in errors: the file, or the resolver file with the pointer.
        func name(resolver: String) -> String {
            switch self {
            case .file(let path): path
            case .inline(let pointer): resolver + pointer
            }
        }
    }

    /// A context of a modifier: its name and its sources in merge order.
    public struct Context: Equatable, Sendable {
        public let name: String
        public let sources: [Source]
    }

    public struct Modifier: Equatable, Sendable {
        public let name: String
        public let description: String?
        /// In document order.
        public let contexts: [Context]
        /// The context used when an input does not name this modifier; nil if every input must name it.
        public let defaultContext: String?

        public var contextNames: [String] { contexts.map(\.name) }

        public func context(named name: String) -> Context? {
            contexts.first { $0.name == name }
        }
    }

    /// An item of `resolutionOrder`.
    public enum Step: Equatable, Sendable {
        case set(name: String, sources: [Source])
        case modifier(Modifier)
    }

    /// The resolver file, for errors.
    public let source: String
    public let name: String?
    public let description: String?
    /// `resolutionOrder`, in order.
    public let steps: [Step]
    /// The JSON of each inline source, by its pointer.
    public let inlineTokens: [String: JSON]

    /// The modifiers of `resolutionOrder`, in order. A modifier that `resolutionOrder` does not use takes no input.
    public var modifiers: [Modifier] {
        steps.compactMap {
            if case .modifier(let modifier) = $0 { modifier } else { nil }
        }
    }

    /// Every source the document uses, each once, in the order of first use.
    public var sources: [Source] {
        var seen: Set<Source> = []
        var result: [Source] = []
        for step in steps {
            let sources: [Source] =
                switch step {
                case .set(_, let sources): sources
                case .modifier(let modifier): modifier.contexts.flatMap(\.sources)
                }
            for source in sources where seen.insert(source).inserted {
                result.append(source)
            }
        }
        return result
    }

    /// Every input: each combination of the modifiers' contexts, the first modifier varying slowest, contexts in
    /// document order (Resolver, 4.1.5.4).
    public var allInputs: [[String: String]] {
        modifiers.reduce([[:]]) { inputs, modifier in
            inputs.flatMap { input in
                modifier.contexts.map { context in input.merging([modifier.name: context.name]) { $1 } }
            }
        }
    }

    /// An input as `theme=dark, density=regular`, in the order of the modifiers.
    public func describe(_ input: [String: String]) -> String {
        let known = modifiers.compactMap { modifier in input[modifier.name].map { "\(modifier.name)=\($0)" } }
        let unknown = input.keys.filter { key in !modifiers.contains { $0.name == key } }.sorted()
            .map { "\($0)=\(input[$0]!)" }
        return (known + unknown).joined(separator: ", ")
    }

    /// The input with a context for every modifier: the defaults filled in (Resolver, 6.1). Inputs are
    /// case-sensitive.
    /// - Throws: `TokenErrors` for an unknown modifier, an unknown context, or a modifier without a default that the
    ///   input does not name.
    public func complete(_ input: [String: String]) throws -> [String: String] {
        var problems: [String] = []
        for key in input.keys.sorted() where !modifiers.contains(where: { $0.name == key }) {
            problems.append(
                "unknown modifier \"\(key)\"; the modifiers are \(modifiers.map(\.name).joined(separator: ", "))")
        }
        var complete: [String: String] = [:]
        for modifier in modifiers {
            if let context = input[modifier.name] {
                guard modifier.context(named: context) != nil else {
                    problems.append(
                        "invalid context \"\(context)\" for modifier \"\(modifier.name)\"; its contexts are "
                            + modifier.contextNames.joined(separator: ", "))
                    continue
                }
                complete[modifier.name] = context
            } else if let context = modifier.defaultContext {
                complete[modifier.name] = context
            } else {
                problems.append(
                    "missing modifier \"\(modifier.name)\", which has no default; its contexts are "
                        + modifier.contextNames.joined(separator: ", "))
            }
        }
        guard problems.isEmpty else {
            throw TokenErrors(problems.map { TokenError(.input, source: source, path: .root, "input: \($0)") })
        }
        return complete
    }

    /// The sources to merge for an input, in order (Resolver, 6.2).
    /// - Throws: `TokenErrors` for an invalid input (`complete(_:)`).
    public func sources(for input: [String: String]) throws -> [Source] {
        let input = try complete(input)
        return steps.flatMap { step -> [Source] in
            switch step {
            case .set(_, let sources): sources
            case .modifier(let modifier): modifier.context(named: input[modifier.name]!)!.sources
            }
        }
    }
}

// MARK: - Reading

extension ResolverDocument {
    /// Reads a resolver document. `source` is its path relative to the repository root; file references in it are
    /// relative to its directory.
    /// - Throws: `TokenErrors` with every problem found.
    public static func load(_ data: Data, source: String) throws -> ResolverDocument {
        let json: JSON
        do {
            json = try JSON.parse(data)
        } catch let error as JSON.SyntaxError {
            throw TokenErrors([TokenError(.syntax, source: source, path: .root, "invalid JSON at \(error)")])
        }
        return try load(json, source: source)
    }

    /// Reads a resolver document that is already parsed; see `load(_:source:)`.
    public static func load(_ json: JSON, source: String) throws -> ResolverDocument {
        var reader = ResolverReader(source: source)
        let document = reader.document(json)
        guard reader.errors.isEmpty, let document else { throw TokenErrors(reader.errors) }
        return document
    }
}

private struct ResolverReader {
    static let version = "2025.10"

    let source: String
    /// The directory file references are relative to, with a trailing slash; empty for the current directory.
    let directory: String
    var errors: [TokenError] = []
    var inline: [String: JSON] = [:]
    var sets: [String: JSON] = [:]
    var modifiers: [String: JSON] = [:]
    /// Sets already read, by name.
    var setSources: [String: [ResolverDocument.Source]] = [:]
    /// Sets being read, to find a cycle.
    var setStack: [String] = []
    /// Sets whose problems are already reported.
    var failedSets: Set<String> = []

    init(source: String) {
        self.source = source
        let slash = source.lastIndex(of: "/")
        self.directory = slash.map { String(source[...$0]) } ?? ""
    }

    mutating func document(_ json: JSON) -> ResolverDocument? {
        guard case .object(let members) = json else {
            report(.resolver, "#", "a resolver document is an object, found \(json.typeName)")
            return nil
        }
        var name: String?
        var description: String?
        var version: String?
        var order: [JSON]?
        for member in members {
            switch member.key {
            case "$schema": _ = string(member.value, at: "#/$schema")
            case "$defs": break  // Resolver 4.5: tools that do not use $defs ignore it.
            case "name": name = string(member.value, at: "#/name")
            case "description": description = string(member.value, at: "#/description")
            case "version": version = string(member.value, at: "#/version")
            case "sets": sets = definitions(member.value, at: "#/sets")
            case "modifiers": modifiers = definitions(member.value, at: "#/modifiers")
            case "resolutionOrder":
                guard case .array(let items) = member.value else {
                    report(.resolver, "#/resolutionOrder", "expected an array, found \(member.value.typeName)")
                    continue
                }
                order = items
            default:
                report(
                    .resolver, "#/\(member.key)",
                    "unknown property; a resolver has $schema, name, version, description, sets, modifiers, "
                        + "resolutionOrder and $defs")
            }
        }
        if version == nil, !members.contains(where: { $0.key == "version" }) {
            report(.resolver, "#", "missing \"version\"; it must be \"\(Self.version)\"")
        } else if let version, version != Self.version {
            report(.resolver, "#/version", "must be \"\(Self.version)\", found \"\(version)\"")
        }
        // Every definition is read, also one that resolutionOrder does not use.
        for name in sets.keys.sorted() {
            _ = self.setSources(name, at: "#/sets/\(escape(name))")
        }
        var readModifiers: [String: ResolverDocument.Modifier] = [:]
        for name in modifiers.keys.sorted() {
            readModifiers[name] = modifier(name: name, modifiers[name]!, at: "#/modifiers/\(escape(name))")
        }

        var steps: [ResolverDocument.Step] = []
        var names: Set<String> = []
        guard let order else {
            report(.resolver, "#", "missing \"resolutionOrder\"")
            return nil
        }
        if order.isEmpty { report(.resolver, "#/resolutionOrder", "must name at least one set or modifier") }
        for (index, item) in order.enumerated() {
            let location = "#/resolutionOrder/\(index)"
            guard let step = step(item, at: location, modifiers: readModifiers) else { continue }
            let stepName: String =
                switch step {
                case .set(let name, _): name
                case .modifier(let modifier): modifier.name
                }
            if !names.insert(stepName).inserted {
                report(.resolver, location, "the name \"\(stepName)\" is already used in resolutionOrder")
            }
            steps.append(step)
        }
        return ResolverDocument(
            source: source, name: name, description: description, steps: steps, inlineTokens: inline)
    }

    /// An item of `resolutionOrder`: a reference to a set or a modifier, or an inline one.
    mutating func step(
        _ json: JSON, at location: String, modifiers: [String: ResolverDocument.Modifier]
    ) -> ResolverDocument.Step? {
        guard case .object(let members) = json else {
            report(.resolver, location, "expected a reference object, a set or a modifier, found \(json.typeName)")
            return nil
        }
        if members.contains(where: { $0.key == "$ref" }) {
            guard let pointer = reference(members, at: location) else { return nil }
            switch pointer {
            case .set(let name):
                guard let sources = setSources(name, at: location) else { return nil }
                return .set(name: name, sources: sources)
            case .modifier(let name):
                guard let modifier = modifiers[name] else {
                    if self.modifiers[name] == nil { report(.resolver, location, "no modifier named \"\(name)\"") }
                    return nil
                }
                return .modifier(modifier)
            case .file:
                report(
                    .unsupported, location,
                    "a file in resolutionOrder is not supported: put it in a set, and name the set here")
                return nil
            }
        }
        guard case .string(let type) = json["type"], case .string(let name) = json["name"] else {
            report(
                .resolver, location,
                "an inline set or modifier needs \"type\" (set or modifier) and \"name\" (Resolver 4.1.6.1)")
            return nil
        }
        switch type {
        case "set":
            let keys: Set<String> = ["type", "name", "description", "sources", "$extensions"]
            guard checkKeys(members, allowed: keys, at: location) else { return nil }
            guard let sources = sourceList(json["sources"], at: location + "/sources", inSet: true) else { return nil }
            return .set(name: name, sources: sources)
        case "modifier":
            let keys: Set<String> = ["type", "name", "description", "contexts", "default", "$extensions"]
            guard checkKeys(members, allowed: keys, at: location) else { return nil }
            let definition = members.filter { $0.key != "type" && $0.key != "name" }
            return modifier(name: name, .object(definition), at: location).map { .modifier($0) }
        default:
            report(.resolver, location + "/type", "must be \"set\" or \"modifier\", found \"\(type)\"")
            return nil
        }
    }

    /// The sources of a named set, its references to other sets inlined.
    mutating func setSources(_ name: String, at location: String) -> [ResolverDocument.Source]? {
        if let sources = setSources[name] { return sources }
        if failedSets.contains(name) { return nil }
        guard let json = sets[name] else {
            report(.resolver, location, "no set named \"\(name)\"")
            return nil
        }
        if let start = setStack.firstIndex(of: name) {
            let cycle = (setStack[start...] + [name]).map { "#/sets/\(escape($0))" }.joined(separator: " → ")
            report(.circularReference, location, "circular reference between sets: \(cycle)")
            failedSets.formUnion(setStack[start...])
            return nil
        }
        setStack.append(name)
        defer { setStack.removeLast() }
        let sources = readSet(json, at: "#/sets/\(escape(name))")
        if let sources {
            setSources[name] = sources
        } else {
            failedSets.insert(name)
        }
        return sources
    }

    private mutating func readSet(_ json: JSON, at location: String) -> [ResolverDocument.Source]? {
        guard case .object(let members) = json else {
            report(.resolver, location, "a set is an object, found \(json.typeName)")
            return nil
        }
        guard checkKeys(members, allowed: ["description", "sources", "$extensions"], at: location) else { return nil }
        return sourceList(json["sources"], at: location + "/sources", inSet: true)
    }

    mutating func modifier(name: String, _ json: JSON, at location: String) -> ResolverDocument.Modifier? {
        guard case .object(let members) = json else {
            report(.resolver, location, "a modifier is an object, found \(json.typeName)")
            return nil
        }
        guard checkKeys(members, allowed: ["description", "contexts", "default", "$extensions"], at: location) else {
            return nil
        }
        guard case .object(let contextMembers) = json["contexts"] else {
            report(.resolver, location, "a modifier needs \"contexts\", an object of context names to sources")
            return nil
        }
        // Resolver 4.1.5.1: no contexts is an error; one context is a set, and tools should reject it.
        guard contextMembers.count >= 2 else {
            report(
                .resolver, location + "/contexts",
                "a modifier needs at least two contexts, found \(contextMembers.count); one context is a set")
            return nil
        }
        var contexts: [ResolverDocument.Context] = []
        for member in contextMembers {
            let contextLocation = "\(location)/contexts/\(escape(member.key))"
            guard let sources = sourceList(member.value, at: contextLocation, inSet: false) else { continue }
            contexts.append(ResolverDocument.Context(name: member.key, sources: sources))
        }
        var defaultContext: String?
        if let value = json["default"] {
            defaultContext = string(value, at: location + "/default")
            if let context = defaultContext, !contextMembers.contains(where: { $0.key == context }) {
                report(.resolver, location + "/default", "\"\(context)\" is not one of the contexts")
            }
        }
        guard contexts.count == contextMembers.count else { return nil }
        return ResolverDocument.Modifier(
            name: name, description: json["description"]?.string, contexts: contexts, defaultContext: defaultContext)
    }

    /// An array of sources: reference objects and inline tokens.
    mutating func sourceList(_ json: JSON?, at location: String, inSet: Bool) -> [ResolverDocument.Source]? {
        guard case .array(let items) = json else {
            report(.resolver, location, "expected an array of sources, found \(json?.typeName ?? "nothing")")
            return nil
        }
        var sources: [ResolverDocument.Source] = []
        var valid = true
        for (index, item) in items.enumerated() {
            let itemLocation = "\(location)/\(index)"
            guard case .object(let members) = item else {
                report(.resolver, itemLocation, "a source is a reference object or tokens, found \(item.typeName)")
                valid = false
                continue
            }
            guard members.contains(where: { $0.key == "$ref" }) else {
                inline[itemLocation] = item
                sources.append(.inline(itemLocation))
                continue
            }
            switch reference(members, at: itemLocation) {
            case .file(let path)?: sources.append(.file(path))
            case .set(let name)?:
                if let setSources = setSources(name, at: itemLocation) {
                    sources += setSources
                } else {
                    valid = false
                }
            case .modifier?:
                report(
                    .resolver, itemLocation,
                    (inSet ? "a set" : "a modifier's context")
                        + " cannot refer to a modifier; only resolutionOrder can (Resolver 4.2.1)")
                valid = false
            case nil: valid = false
            }
        }
        return valid ? sources : nil
    }

    enum Pointer {
        case set(String)
        case modifier(String)
        case file(String)
    }

    /// What a reference object points to, or nil after reporting why it cannot be used.
    mutating func reference(_ members: [JSON.Member], at location: String) -> Pointer? {
        guard members.count == 1, case .string(let ref) = members[0].value else {
            if members.contains(where: { $0.key == "$ref" && $0.value.string == nil }) {
                report(.resolver, location + "/$ref", "must be a string")
            } else {
                report(
                    .unsupported, location,
                    "a reference object with keys besides $ref (Resolver 4.2.2, extending) is not supported")
            }
            return nil
        }
        if ref.hasPrefix("#") {
            let names = ref.dropFirst().split(separator: "/", omittingEmptySubsequences: false).dropFirst()
                .map { unescape(String($0)) }
            if names.first == "resolutionOrder" {
                report(.resolver, location, "\"\(ref)\": nothing may refer into resolutionOrder (Resolver 4.2.1)")
                return nil
            }
            if ref.hasPrefix("#/"), names.count == 2, !names[1].isEmpty {
                switch names[0] {
                case "sets": return .set(names[1])
                case "modifiers": return .modifier(names[1])
                default: break
                }
            }
            report(
                .unsupported, location,
                "\"\(ref)\": westron refers only to #/sets/<name>, #/modifiers/<name> and token files")
            return nil
        }
        if ref.contains("://") || ref.contains("#") || ref.hasPrefix("/") || ref.isEmpty {
            report(
                .unsupported, location,
                "\"\(ref)\": a token file is referred to by a path relative to the resolver, without a fragment")
            return nil
        }
        let segments = ref.split(separator: "/", omittingEmptySubsequences: false).filter { $0 != "." }
        if segments.contains("..") || segments.contains("") {
            report(
                .unsupported, location,
                "\"\(ref)\": a token file must be inside the resolver's directory, by a plain path")
            return nil
        }
        return .file(directory + segments.joined(separator: "/"))
    }

    /// The members of `sets` or `modifiers`, by name.
    mutating func definitions(_ json: JSON, at location: String) -> [String: JSON] {
        guard case .object(let members) = json else {
            report(.resolver, location, "expected an object of names to definitions, found \(json.typeName)")
            return [:]
        }
        return Dictionary(members.map { ($0.key, $0.value) }) { first, _ in first }
    }

    /// Checks the keys of a set or a modifier, and the types of `description` and `$extensions`.
    mutating func checkKeys(_ members: [JSON.Member], allowed: Set<String>, at location: String) -> Bool {
        var valid = true
        for member in members {
            let memberLocation = "\(location)/\(escape(member.key))"
            switch member.key {
            case let key where !allowed.contains(key):
                report(
                    .resolver, memberLocation, "unknown property; allowed: \(allowed.sorted().joined(separator: ", "))")
                valid = false
            case "description" where member.value.string == nil, "name" where member.value.string == nil:
                report(.resolver, memberLocation, "expected a string, found \(member.value.typeName)")
                valid = false
            case "$extensions" where member.value.members == nil:
                report(.resolver, memberLocation, "expected an object, found \(member.value.typeName)")
                valid = false
            default: break
            }
        }
        return valid
    }

    mutating func string(_ json: JSON, at location: String) -> String? {
        guard case .string(let value) = json else {
            report(.resolver, location, "expected a string, found \(json.typeName)")
            return nil
        }
        return value
    }

    mutating func report(_ kind: TokenError.Kind, _ location: String, _ message: String) {
        errors.append(TokenError(kind, source: source, path: .root, "\(location): \(message)"))
    }

    /// A name as a JSON Pointer segment (RFC 6901).
    func escape(_ name: String) -> String {
        name.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
    }

    func unescape(_ segment: String) -> String {
        segment.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~")
    }
}
