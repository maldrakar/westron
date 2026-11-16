import Foundation

extension ContrastCheck {
    /// The results of one theme, for `report`.
    public struct ThemeResults: Equatable, Sendable {
        /// The theme's name, such as `light-hc`.
        public let name: String
        public let kind: ThemeKind
        public let results: [Result]

        public init(name: String, kind: ThemeKind, results: [Result]) {
            self.name = name
            self.kind = kind
            self.results = results
        }

        public var failures: Int { results.count { !$0.passes } }
    }

    /// A plain-text report: for each theme in the order given, a line with its counts and a table of its checks,
    /// failures first, then the rest in check order; then one summary line. The same results give the same bytes.
    ///
    /// The columns are the foreground, the background (a stack as `top over … over bottom`), the kind, the ratio, the
    /// target (`none` where there is none) and `ok` or `FAIL`. The ratio is truncated to 2 decimals, not rounded, so
    /// a failing ratio never shows as its target: 4.4999 is `4.49`.
    public static func report(_ themes: [ThemeResults]) -> String {
        var lines: [String] = []
        for theme in themes {
            if !lines.isEmpty { lines.append("") }
            lines.append(
                "\(theme.name) (\(theme.kind.rawValue)): \(theme.results.count) checks, \(theme.failures) failed")
            let ordered = theme.results.filter { !$0.passes } + theme.results.filter(\.passes)
            let rows =
                [["foreground", "background", "kind", "ratio", "target", "result"]]
                + ordered.map { result in
                    [
                        result.foreground.description,
                        result.background.map(\.description).joined(separator: " over "),
                        result.kind.rawValue,
                        formatRatio(result.ratio),
                        result.target.map { DecimalFormat.fixed($0, decimals: 2, trimmingZeros: true) } ?? "none",
                        result.passes ? "ok" : "FAIL",
                    ]
                }
            lines += table(rows, rightAligned: [3, 4])
        }

        let checks = themes.reduce(0) { $0 + $1.results.count }
        let failures = themes.reduce(0) { $0 + $1.failures }
        var summary = "contrast: \(themes.count) themes, \(checks) checks, \(failures) failed"
        let failing = themes.filter { $0.failures > 0 }.map { "\($0.name) \($0.failures)" }
        if !failing.isEmpty { summary += " (\(failing.joined(separator: ", ")))" }
        if !lines.isEmpty { lines.append("") }
        lines.append(summary)
        return lines.joined(separator: "\n") + "\n"
    }

    /// The ratio truncated to 2 decimals.
    static func formatRatio(_ ratio: Double) -> String {
        DecimalFormat.fixed((ratio * 100).rounded(.down) / 100, decimals: 2)
    }

    /// Columns padded to their widest cell and separated by two spaces, with no trailing spaces.
    private static func table(_ rows: [[String]], rightAligned: Set<Int>) -> [String] {
        let widths = rows[0].indices.map { column in rows.map { $0[column].count }.max() ?? 0 }
        return rows.map { row in
            let cells = row.enumerated().map { column, cell in
                let padding = String(repeating: " ", count: widths[column] - cell.count)
                if rightAligned.contains(column) { return padding + cell }
                return column == row.count - 1 ? cell : cell + padding
            }
            return cells.joined(separator: "  ")
        }
    }
}
