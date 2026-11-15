/// westron's keys in `$extensions`, `dev.westron.*` (decisions/0010), read and checked.
///
/// They are read when a file is loaded, so a misspelled or malformed key fails instead of being ignored. What
/// depends on other tokens (a spring only on a transition, contrast backgrounds that are color tokens) is checked
/// when references are resolved. Other vendors' keys are kept as written in the token's `extensions`.
public struct WestronExtensions: Equatable, Sendable {
    public static let prefix = "dev.westron."
    /// The keys westron knows; any other `dev.westron.*` key is an error.
    public static let keys = ["dev.westron.usage", "dev.westron.contrast", "dev.westron.apple", "dev.westron.spring"]

    /// `dev.westron.usage`: where an agent uses the token and where it does not.
    public struct Usage: Equatable, Sendable {
        /// Where the token goes, as short phrases.
        public var use: [String]
        /// Where it does not, and what to use instead.
        public var avoid: String

        public init(use: [String], avoid: String) {
            self.use = use
            self.avoid = avoid
        }
    }

    /// An entry of `dev.westron.contrast`: the backgrounds a color is drawn on, for one kind of use (decisions/0012).
    public struct Contrast: Equatable, Sendable {
        /// The kind of use, which sets the minimum WCAG 2 ratio per theme (decisions/0012).
        public enum Kind: String, CaseIterable, Sendable {
            case text
            case largeText = "large-text"
            case nonText = "non-text"
            case separator
        }

        public var kind: Kind
        /// Each background as a stack of color tokens by their whole paths (`color.background.canvas`), top first; a
        /// single background is a stack of one.
        public var on: [[TokenPath]]

        public init(kind: Kind, on: [[TokenPath]]) {
            self.kind = kind
            self.on = on
        }
    }

    /// `dev.westron.apple`: what DTCG has no word for on Apple.
    public struct Apple: Equatable, Sendable {
        /// The SwiftUI text styles (`Font.TextStyle`).
        public enum TextStyle: String, CaseIterable, Sendable {
            case largeTitle, title1, title2, title3, headline, body, callout, subheadline, footnote, caption, caption2
        }

        /// The Dynamic Type text style a typography token follows. Only on typography tokens.
        public var textStyle: TextStyle?

        public init(textStyle: TextStyle? = nil) {
            self.textStyle = textStyle
        }
    }

    /// `dev.westron.spring`: a spring, which DTCG has no type for. Only on transition tokens; platforms with springs
    /// use it instead of the transition's curve.
    public struct Spring: Equatable, Sendable {
        /// Seconds, more than 0.
        public var duration: Double
        /// From -1 to 1; 0 is a spring without bounce (SwiftUI `Spring(duration:bounce:)`).
        public var bounce: Double

        public init(duration: Double, bounce: Double) {
            self.duration = duration
            self.bounce = bounce
        }
    }

    public var usage: Usage?
    /// Empty when the token has no `dev.westron.contrast`.
    public var contrast: [Contrast]
    public var apple: Apple?
    public var spring: Spring?

    public init(usage: Usage? = nil, contrast: [Contrast] = [], apple: Apple? = nil, spring: Spring? = nil) {
        self.usage = usage
        self.contrast = contrast
        self.apple = apple
        self.spring = spring
    }
}

extension WestronExtensions {
    /// Reads westron's keys of a token's `$extensions`.
    /// - Throws: `ValueFailure` for an unknown `dev.westron.*` key or a malformed value.
    static func parse(_ extensions: JSON?) throws -> WestronExtensions {
        var result = WestronExtensions()
        for member in extensions?.members ?? [] where member.key.hasPrefix(prefix) {
            let location = "$extensions.\(member.key)"
            switch member.key {
            case "dev.westron.usage": result.usage = try usage(member.value, at: location)
            case "dev.westron.contrast": result.contrast = try contrast(member.value, at: location)
            case "dev.westron.apple": result.apple = try apple(member.value, at: location)
            case "dev.westron.spring": result.spring = try spring(member.value, at: location)
            default:
                throw ValueFailure(
                    .unknownProperty,
                    "\(location): unknown westron key; the keys are \(keys.joined(separator: ", ")) (decisions/0010)")
            }
        }
        return result
    }

    /// The first westron key of a group's `$extensions`: westron's keys go on tokens only.
    static func groupKey(_ extensions: JSON?) -> String? {
        extensions?.members?.first { $0.key.hasPrefix(prefix) }?.key
    }

    private static func usage(_ json: JSON, at location: String) throws -> Usage {
        let members = try object(json, at: location, keys: ["use", "avoid"])
        guard case .array(let list) = members["use"]!, !list.isEmpty else {
            throw ValueFailure(.invalidValue, "\(location).use: expected a non-empty list of strings")
        }
        let use = try list.enumerated().map { index, element in
            try text(element, at: "\(location).use[\(index)]")
        }
        return Usage(use: use, avoid: try text(members["avoid"]!, at: location + ".avoid"))
    }

    private static func contrast(_ json: JSON, at location: String) throws -> [Contrast] {
        guard case .array(let entries) = json, !entries.isEmpty else {
            throw ValueFailure(.invalidValue, "\(location): expected a non-empty list of { kind, on }")
        }
        return try entries.enumerated().map { index, entry in
            let entryLocation = "\(location)[\(index)]"
            let members = try object(entry, at: entryLocation, keys: ["kind", "on"])
            let kindName = try text(members["kind"]!, at: entryLocation + ".kind")
            guard let kind = Contrast.Kind(rawValue: kindName) else {
                throw ValueFailure(
                    .invalidValue,
                    "\(entryLocation).kind: unknown kind \"\(kindName)\"; the kinds are "
                        + Contrast.Kind.allCases.map(\.rawValue).joined(separator: ", "))
            }
            guard case .array(let backgrounds) = members["on"]!, !backgrounds.isEmpty else {
                throw ValueFailure(.invalidValue, "\(entryLocation).on: expected a non-empty list of backgrounds")
            }
            let on = try backgrounds.enumerated().map { backgroundIndex, background -> [TokenPath] in
                let backgroundLocation = "\(entryLocation).on[\(backgroundIndex)]"
                switch background {
                case .string: return [try path(background, at: backgroundLocation)]
                case .array(let layers) where !layers.isEmpty:
                    return try layers.enumerated().map { layerIndex, layer in
                        try path(layer, at: "\(backgroundLocation)[\(layerIndex)]")
                    }
                default:
                    throw ValueFailure(
                        .invalidValue,
                        "\(backgroundLocation): expected a color path or a non-empty stack of them, top first")
                }
            }
            return Contrast(kind: kind, on: on)
        }
    }

    private static func apple(_ json: JSON, at location: String) throws -> Apple {
        let members = try object(json, at: location, keys: [], optional: ["textStyle"])
        guard let style = members["textStyle"] else { return Apple() }
        let name = try text(style, at: location + ".textStyle")
        guard let textStyle = Apple.TextStyle(rawValue: name) else {
            throw ValueFailure(
                .invalidValue,
                "\(location).textStyle: unknown text style \"\(name)\"; the styles are "
                    + Apple.TextStyle.allCases.map(\.rawValue).joined(separator: ", "))
        }
        return Apple(textStyle: textStyle)
    }

    private static func spring(_ json: JSON, at location: String) throws -> Spring {
        let members = try object(json, at: location, keys: ["duration", "bounce"])
        guard case .number(let duration) = members["duration"]!, duration > 0 else {
            throw ValueFailure(.invalidValue, "\(location).duration: expected a number of seconds above 0")
        }
        guard case .number(let bounce) = members["bounce"]!, (-1...1).contains(bounce) else {
            throw ValueFailure(.invalidValue, "\(location).bounce: expected a number from -1 to 1")
        }
        return Spring(duration: duration, bounce: bounce)
    }

    /// A whole token path, `color.background.canvas`, written without braces.
    private static func path(_ json: JSON, at location: String) throws -> TokenPath {
        let written = try text(json, at: location)
        let path = TokenPath(written)
        if let problem = path.names.lazy.compactMap(TokenName.problem).first {
            throw ValueFailure(.invalidValue, "\(location): \"\(written)\" is not a token path: \(problem)")
        }
        return path
    }

    private static func object(
        _ json: JSON, at location: String, keys: [String], optional: [String] = []
    ) throws -> [String: JSON] {
        guard case .object(let list) = json else {
            throw ValueFailure(.invalidValue, "\(location): expected an object, found \(json.typeName)")
        }
        var members: [String: JSON] = [:]
        for member in list {
            guard keys.contains(member.key) || optional.contains(member.key) else {
                throw ValueFailure(
                    .unknownProperty,
                    "\(location): unknown property \"\(member.key)\"; allowed: "
                        + (keys + optional).joined(separator: ", "))
            }
            members[member.key] = member.value
        }
        for key in keys where members[key] == nil {
            throw ValueFailure(.invalidValue, "\(location): missing \"\(key)\"")
        }
        return members
    }

    /// A non-empty string.
    private static func text(_ json: JSON, at location: String) throws -> String {
        guard case .string(let value) = json, !value.isEmpty else {
            let found = json == .string("") ? "an empty string" : json.typeName
            throw ValueFailure(.invalidValue, "\(location): expected a non-empty string, found \(found)")
        }
        return value
    }
}
