import Foundation

/// Contrast as WCAG 2.2 defines it (https://www.w3.org/TR/WCAG22/, the definitions of "relative luminance" and
/// "contrast ratio"): what the contrast check of the semantic tokens measures.
public enum WCAG {
    /// The relative luminance of an opaque color, 0 for black and 1 for white:
    /// 0.2126 R + 0.7152 G + 0.0722 B over linear sRGB channels, each linear from c ≤ 0.04045 ? c / 12.92 :
    /// ((c + 0.055) / 1.055)^2.4.
    ///
    /// WCAG 2.0 and 2.1 wrote the threshold as 0.03928; no 8-bit channel lies between the two (10/255 is under both,
    /// 11/255 over), so for hex colors they agree. A Display P3 color is converted to sRGB first, without gamut
    /// mapping; alpha is ignored, so composite a translucent color first.
    public static func relativeLuminance(_ color: RGB) -> Double {
        let linear = LinearRGB(color.converted(to: .sRGB))
        return Swift.max(0, 0.2126 * linear.red + 0.7152 * linear.green + 0.0722 * linear.blue)
    }

    /// The contrast ratio of a foreground on a background, (L1 + 0.05) / (L2 + 0.05) with L1 the lighter relative
    /// luminance: from 1 to 21, symmetric in its arguments.
    ///
    /// A translucent foreground, such as ink at 8 %, is composited over the background first
    /// (`RGB.composited(over:)`); the background must be opaque, so composite translucent layers under it first.
    public static func contrastRatio(of foreground: RGB, on background: RGB) -> Double {
        precondition(background.alpha == 1, "the background of a contrast ratio must be opaque")
        let first = relativeLuminance(foreground.alpha < 1 ? foreground.composited(over: background) : foreground)
        let second = relativeLuminance(background)
        return (Swift.max(first, second) + 0.05) / (Swift.min(first, second) + 0.05)
    }
}

extension RGB {
    /// This color drawn over a background: simple alpha compositing, source-over, of Compositing and Blending
    /// Level 1 §5.1, which CSS Color 4 §10.13 requires. As in browsers and in the pilot's canvas, it works on the
    /// gamma-encoded channels, in the background's space (this color is converted to it first, without gamut mapping):
    ///
    ///     αo = αs + αb (1 − αs)      co = (cs αs + cb αb (1 − αs)) / αo
    ///
    /// Over an opaque background the result is opaque, `cs αs + cb (1 − αs)`.
    public func composited(over background: RGB) -> RGB {
        let source = converted(to: background.space)
        let backdrop = background.alpha * (1 - source.alpha)
        // Exactly 1 over an opaque background, without the rounding of αs + (1 − αs).
        let alpha = background.alpha == 1 ? 1 : source.alpha + backdrop
        guard alpha > 0 else { return RGB(background.space, red: 0, green: 0, blue: 0, alpha: 0) }
        func channel(_ color: Double, _ under: Double) -> Double {
            (color * source.alpha + under * backdrop) / alpha
        }
        return RGB(
            background.space, red: channel(source.red, background.red),
            green: channel(source.green, background.green), blue: channel(source.blue, background.blue), alpha: alpha)
    }
}
