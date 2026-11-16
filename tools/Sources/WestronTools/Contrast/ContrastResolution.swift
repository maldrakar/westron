import Foundation

extension ContrastCheck {
    /// The modifier whose contexts are the themes (decisions/0010).
    public static let themeModifier = "theme"

    /// The kind of a theme by its context name: a name that ends in `-hc` is a high-contrast theme
    /// (`light-hc`, `dark-hc`; decisions/0010).
    public static func themeKind(of name: String) -> ThemeKind {
        name.hasSuffix("-hc") ? .highContrast : .standard
    }

    /// Checks every combination of the resolution and returns the results by theme, in the order of the `theme`
    /// modifier's contexts.
    ///
    /// Colors belong to the `theme` modifier alone, so every combination of one theme gives the same results; a theme
    /// is reported once, from its first combination. Every combination is still checked, and a problem in any of them
    /// is thrown, so a color that another modifier overrides cannot hide.
    ///
    /// A token declares the same pairs in every theme. A theme file that overrides a token replaces it whole, so an
    /// override that leaves out `dev.westron.contrast` would drop its pairs from that theme without a word; that is an
    /// error instead.
    public static func run(_ resolution: Resolution) throws -> [ThemeResults] {
        guard let modifier = resolution.modifiers.first(where: { $0.name == themeModifier }) else {
            throw TokenErrors([
                TokenError(
                    .resolver, source: resolution.document.source, path: .root,
                    "the resolver has no `\(themeModifier)` modifier, so there are no themes to check")
            ])
        }
        var byTheme: [String: [Result]] = [:]
        var declared: (theme: String, pairs: [TokenPath: [WestronExtensions.Contrast]])?
        var errors: [TokenError] = []
        for input in resolution.inputs {
            guard let theme = input[themeModifier] else { continue }
            do {
                let tokens = try resolution.resolve(input).tokens
                let pairs = Dictionary(
                    tokens.filter { !$0.westron.contrast.isEmpty }.map { ($0.path, $0.westron.contrast) },
                    uniquingKeysWith: { _, later in later })
                if let first = declared {
                    // Once per theme: its other combinations give the same tokens.
                    if byTheme[theme] == nil {
                        errors += mismatches(pairs, first.pairs, in: theme, against: first.theme, tokens: tokens)
                    }
                } else {
                    declared = (theme, pairs)
                }
                let results = try run(tokens, theme: themeKind(of: theme))
                if let first = byTheme[theme] {
                    if first != results {
                        errors.append(
                            TokenError(
                                .modifierOverlap, source: resolution.document.source, path: .root,
                                "the contrast of theme \(theme) differs in \(resolution.describe(input))"))
                    }
                } else {
                    byTheme[theme] = results
                }
            } catch let problems as TokenErrors {
                errors += problems.errors
            }
        }
        guard errors.isEmpty else { throw TokenErrors(errors) }
        return modifier.contextNames.compactMap { name in
            byTheme[name].map { ThemeResults(name: name, kind: themeKind(of: name), results: $0) }
        }
    }

    /// The tokens whose contrast declarations in `theme` differ from those in `reference`.
    private static func mismatches(
        _ pairs: [TokenPath: [WestronExtensions.Contrast]], _ reference: [TokenPath: [WestronExtensions.Contrast]],
        in theme: String, against referenceTheme: String, tokens: [ResolvedToken]
    ) -> [TokenError] {
        let source = Dictionary(tokens.map { ($0.path, $0.source) }, uniquingKeysWith: { _, later in later })
        return Set(pairs.keys).union(reference.keys).sorted().compactMap { path in
            guard pairs[path] != reference[path] else { return nil }
            let what =
                pairs[path] == nil
                ? "declares no \(extensionKey) in theme \(theme), but does in theme \(referenceTheme): an override "
                    + "replaces a token whole, so it must restate the declaration"
                : reference[path] == nil
                    ? "declares \(extensionKey) in theme \(theme), but not in theme \(referenceTheme)"
                    : "declares other \(extensionKey) pairs in theme \(theme) than in theme \(referenceTheme)"
            return TokenError(.invalidValue, source: source[path] ?? "", path: path, what)
        }
    }
}
