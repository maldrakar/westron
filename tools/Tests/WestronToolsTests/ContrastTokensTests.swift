import Foundation
import Testing
import WestronTools

/// The four themes of `tokens/`, resolved through `tokens/westron.resolver.json` at the default density on iOS.
func realThemes() throws -> [(name: String, kind: ContrastCheck.ThemeKind, tokens: [ResolvedToken])] {
    let resolution = try Resolution(
        resolverFile: repositoryRoot.appendingPathComponent(TokenCheck.defaultResolver).path)
    return try resolution.inputs.filter { $0["density"] == "regular" && $0["platform"] == "ios" }.map { input in
        let theme = input[ContrastCheck.themeModifier]!
        return (theme, ContrastCheck.themeKind(of: theme), try resolution.resolve(input).tokens)
    }
}

@Suite("Contrast of the tokens")
struct ContrastTokensTests {
    /// A pair that fails today, by theme, foreground and background.
    ///
    /// dark-hc `color.border.default`, oklch(0.5298 0.00919 73.67), on `color.background.surface` measures 2.9998
    /// from its OkLCh components and 3.00001 from its hex #6F6B66: the shade was tuned on the hex. L 0.5299 measures
    /// 3.0011 and still converts to #6F6B66. Remove the entry when the token moves; the test then fails as a reminder.
    static let knownFailures: Set<String> = []

    @Test("every declared pair passes in all four themes")
    func realTokens() throws {
        let themes = try realThemes().map { theme in
            ContrastCheck.ThemeResults(
                name: theme.name, kind: theme.kind, results: try ContrastCheck.run(theme.tokens, theme: theme.kind))
        }
        let report = ContrastCheck.report(themes)
        var known: Set<String> = []
        for theme in themes {
            #expect(!theme.results.isEmpty, "\(theme.name) declares no checks")
            for result in theme.results {
                let pair =
                    "\(theme.name) \(result.foreground) on "
                    + result.background.map(\.description).joined(separator: " over ")
                if Self.knownFailures.contains(pair) {
                    known.insert(pair)
                    withKnownIssue("\(pair) misses its target (\(result.ratio))") {
                        #expect(result.passes)
                    }
                } else {
                    #expect(result.passes, "\(pair): \(result.ratio) under \(result.target ?? 0)\n\(report)")
                }
            }
        }
        #expect(known == Self.knownFailures, "a known failure names no check")
    }
}
