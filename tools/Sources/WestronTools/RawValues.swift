import Foundation

/// The "no raw values" lint: in westron component code, colors, sizes, spacing, radii, opacity and animation
/// come only from tokens (decisions/0005).
///
/// An exception for a line: a `// westron-lint: allow <reason>` comment on it or on the line above.
public enum RawValues {
    public struct Violation: Equatable, Sendable {
        public let line: Int
        public let column: Int
        public let text: String
        public let kind: String
    }

    public static let allowMarker = "westron-lint: allow"
    /// What `tools/westron lint raw-values` checks without arguments, relative to the repository root.
    public static let defaultRoots = ["platforms/apple/Sources/WestronUI"]

    struct Rule {
        let kind: String
        let pattern: Regex<AnyRegexOutput>
        /// Allowed numbers: if the first captured group is one of them, the match is skipped.
        let allowed: Set<Double>

        init(_ kind: String, _ pattern: String, allowed: Set<Double> = []) {
            self.kind = kind
            // The patterns are constants, so a bad one is a programming error that every test run catches.
            self.pattern = try! Regex(pattern).wordBoundaryKind(.simple)
            self.allowed = allowed
        }
    }

    static func rules() -> [Rule] {
        let number = #"(-?\d+(?:\.\d+)?)"#
        let layoutLabels = [
            "spacing", "cornerRadius", "radius", "lineWidth", "width", "height", "minWidth", "idealWidth", "maxWidth",
            "minHeight", "idealHeight", "maxHeight", "minLength", "top", "leading", "bottom", "trailing", "x", "y",
        ].joined(separator: "|")
        let motionLabels = ["duration", "response", "dampingFraction", "bounce", "blendDuration", "delay"]
            .joined(separator: "|")
        return [
            Rule(
                "color",
                #"\b(?:Color|UIColor|NSColor)\(\s*(?:red|hue|white|\.sRGB|\.displayP3|hex)\s*[:,]|#colorLiteral\("#),
            Rule("color", ##""#[0-9a-fA-F]{3,8}""##),
            Rule("font", #"\bsize:\s*"# + number),
            Rule("font", #"\.(?:lineSpacing|tracking|kerning)\(\s*"# + number + #"\s*\)"#, allowed: [0]),
            Rule(
                "size or spacing", #"\bCGFloat\s*(?:=\s*"# + number + #"|\(\s*"# + number + #"\s*\))"#, allowed: [0]),
            Rule("size or spacing", #"\b(?:"# + layoutLabels + #"):\s*"# + number, allowed: [0]),
            Rule(
                "size or spacing",
                #"\.(?:padding|cornerRadius)\(\s*(?:(?:\.\w+|\[[^\]]*\])\s*,\s*)?"# + number + #"\s*\)"#,
                allowed: [0]),
            Rule("opacity or scale", #"\.(?:opacity|scaleEffect)\(\s*"# + number + #"\s*\)"#, allowed: [0, 1]),
            Rule("animation", #"\b(?:"# + motionLabels + #"):\s*"# + number, allowed: [0]),
        ]
    }

    public static func find(in source: String) -> [Violation] {
        let rules = rules()
        let lines = source.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        var violations: [Violation] = []
        var inBlockComment = false
        for (index, rawLine) in lines.enumerated() {
            var line = rawLine
            if inBlockComment {
                guard let end = line.range(of: "*/") else { continue }
                blank(&line, line.startIndex..<end.upperBound)
                inBlockComment = false
            }
            while let start = line.range(of: "/*"),
                let end = line.range(of: "*/", range: start.upperBound..<line.endIndex)
            {
                blank(&line, start.lowerBound..<end.upperBound)
            }
            if let blockStart = line.range(of: "/*") {
                inBlockComment = true
                line = String(line[..<blockStart.lowerBound])
            }
            if let commentStart = line.range(of: "//") {
                line = String(line[..<commentStart.lowerBound])
            }

            let previous = index > 0 ? lines[index - 1] : ""
            if rawLine.contains(allowMarker)
                || (previous.trimmingCharacters(in: .whitespaces).hasPrefix("//") && previous.contains(allowMarker))
            {
                continue
            }

            for rule in rules {
                for match in line.matches(of: rule.pattern) {
                    let captured = match.output.dropFirst().lazy.compactMap(\.substring).first
                    if let captured, let value = Double(captured), rule.allowed.contains(value) { continue }
                    violations.append(
                        Violation(
                            line: index + 1,
                            column: line.distance(from: line.startIndex, to: match.range.lowerBound) + 1,
                            text: String(line[match.range]),
                            kind: rule.kind
                        ))
                }
            }
        }
        return violations.sorted { ($0.line, $0.column) < ($1.line, $1.column) }
    }

    /// Replaces a range with spaces, so that the columns of what follows stay the same.
    private static func blank(_ line: inout String, _ range: Range<String.Index>) {
        line.replaceSubrange(
            range, with: String(repeating: " ", count: line.distance(from: range.lowerBound, to: range.upperBound)))
    }
}
