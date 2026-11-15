import Foundation

/// The WCAG 2 contrast check of the semantic colors (#15; decisions/0012, section Contrast).
///
/// A foreground color lists the backgrounds it is drawn on in `$extensions["dev.westron.contrast"]`, by kind:
///
///     [{"kind": "text", "on": ["color.background.canvas", ["color.background.hover", "color.background.canvas"]]}]
///
/// A background is the whole path of an opaque color, or a stack of paths, top first, whose last color is opaque.
///
/// Colors are converted to sRGB with CSS gamut mapping (`TokenValue.Color.mapped(into:)`). Each translucent layer of
/// a stack is composited over what is under it, and a translucent foreground over the whole stack, in gamma-encoded
/// sRGB as browsers and the pilot do (`RGB.composited(over:)`). The ratio is WCAG 2's (`WCAG.contrastRatio(of:on:)`)
/// and is compared with the target unrounded.
public enum ContrastCheck {
    /// The `$extensions` key a foreground declares its backgrounds under (decisions/0010).
    public static let extensionKey = "dev.westron.contrast"

    /// The kind of theme, which sets the targets: each of light and dark has a high-contrast theme (decisions/0010).
    public enum ThemeKind: String, Sendable {
        case standard
        case highContrast = "high contrast"
    }

    /// What a foreground is where it is drawn: the kind a token declares in `dev.westron.contrast`.
    public typealias Kind = WestronExtensions.Contrast.Kind

    /// One foreground on one background.
    public struct Result: Equatable, Sendable {
        public let foreground: TokenPath
        /// The layers of the background, top first; the last is opaque.
        public let background: [TokenPath]
        public let kind: Kind
        /// The WCAG 2 contrast ratio, from 1 to 21.
        public let ratio: Double
        /// The least ratio that passes; nil where the kind has none in this kind of theme.
        public let target: Double?

        public init(foreground: TokenPath, background: [TokenPath], kind: Kind, ratio: Double, target: Double?) {
            self.foreground = foreground
            self.background = background
            self.kind = kind
            self.ratio = ratio
            self.target = target
        }

        public var passes: Bool { target.map { ratio >= $0 } ?? true }
    }

    /// Every check the tokens of one theme declare: in token order, and for each token in the order written.
    ///
    /// - Parameter tokens: the resolved tokens of one theme, as `TokenTree.resolve()` returns them.
    /// - Throws: `TokenErrors` with every problem, each reported on the foreground token that declares it: a path to
    ///   no token, a foreground or background that is not a color, a color in a space the color code does not
    ///   convert, a background whose only or bottom layer is not opaque. Nothing is skipped. The shape of the
    ///   declaration is the reader's to check (`WestronExtensions`).
    public static func run(_ tokens: [ResolvedToken], theme: ThemeKind) throws -> [Result] {
        let byPath = Dictionary(tokens.map { ($0.path, $0) }, uniquingKeysWith: { _, later in later })
        var results: [Result] = []
        var errors: [TokenError] = []
        for token in tokens {
            guard !token.westron.contrast.isEmpty else { continue }
            var checker = Checker(token: token, byPath: byPath)
            results += checker.check(token.westron.contrast, theme: theme)
            errors += checker.errors
        }
        guard errors.isEmpty else { throw TokenErrors(errors) }
        return results
    }
}

/// The checks one foreground token declares, and the problems in its declaration.
private struct Checker {
    let token: ResolvedToken
    let byPath: [TokenPath: ResolvedToken]
    var errors: [TokenError] = []

    init(token: ResolvedToken, byPath: [TokenPath: ResolvedToken]) {
        self.token = token
        self.byPath = byPath
    }

    mutating func check(_ declarations: [WestronExtensions.Contrast], theme: ContrastCheck.ThemeKind)
        -> [ContrastCheck.Result]
    {
        let key = ContrastCheck.extensionKey
        guard case .color(let value) = token.value else {
            report(.typeMismatch, "\(key) is for colors; this token is a \(token.type.rawValue)")
            return []
        }
        guard let foreground = value.mapped(into: .sRGB) else {
            report(
                .unsupported, "the token is in \(value.colorSpace.rawValue), which the contrast check cannot convert")
            return []
        }
        var results: [ContrastCheck.Result] = []
        for (index, declaration) in declarations.enumerated() {
            for (position, stack) in declaration.on.enumerated() {
                guard let (paths, under) = composite(stack, at: "\(key)[\(index)].on[\(position)]") else { continue }
                results.append(
                    ContrastCheck.Result(
                        foreground: token.path, background: paths, kind: declaration.kind,
                        ratio: WCAG.contrastRatio(of: foreground, on: under), target: declaration.kind.target(in: theme)
                    ))
            }
        }
        return results
    }

    /// The layers of a background and their composite, or nil after reporting why there is none.
    private mutating func composite(_ written: [TokenPath], at location: String) -> ([TokenPath], RGB)? {
        var layers: [(path: TokenPath, color: RGB)] = []
        for path in written {
            guard let layer = byPath[path] else {
                report(.unknownReference, "\(location): no token \(path); a background is a whole token path")
                continue
            }
            guard case .color(let value) = layer.value else {
                report(.typeMismatch, "\(location): \(path) is a \(layer.type.rawValue), not a color")
                continue
            }
            guard let color = value.mapped(into: .sRGB) else {
                report(
                    .unsupported,
                    "\(location): \(path) is in \(value.colorSpace.rawValue), which the contrast check cannot convert")
                continue
            }
            layers.append((path, color))
        }
        guard layers.count == written.count, let bottom = layers.last else { return nil }
        guard bottom.color.alpha == 1 else {
            let alpha = DecimalFormat.fixed(bottom.color.alpha, decimals: 4, trimmingZeros: true)
            report(
                .invalidValue,
                layers.count == 1
                    ? "\(location): \(bottom.path) is translucent (alpha \(alpha)); write the background as a stack, "
                        + "top first, that ends in an opaque color"
                    : "\(location): the bottom of the stack, \(bottom.path), is translucent (alpha \(alpha)); a "
                        + "stack must end in an opaque color")
            return nil
        }
        var under = bottom.color
        for layer in layers.dropLast().reversed() {
            under = layer.color.composited(over: under)
        }
        return (layers.map(\.path), under)
    }

    private mutating func report(_ kind: TokenError.Kind, _ message: String) {
        errors.append(TokenError(kind, source: token.source, path: token.path, message))
    }
}

extension WestronExtensions.Contrast.Kind {
    /// The least ratio that passes; nil where there is none, a separator in a standard theme (decisions/0012).
    public func target(in theme: ContrastCheck.ThemeKind) -> Double? {
        switch (self, theme) {
        case (.text, .standard): 4.5
        case (.text, .highContrast): 7
        case (.largeText, .standard), (.nonText, .standard): 3
        case (.largeText, .highContrast), (.nonText, .highContrast): 4.5
        case (.separator, .standard): nil
        case (.separator, .highContrast): 3
        }
    }
}
