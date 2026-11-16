import Foundation

// Gamut check and gamut mapping as CSS Color 4 defines them (§14): the binary search with local MINDE (§14.2.1,
// pseudocode in §14.2.2), which reduces OkLCh chroma at constant lightness and hue, measures the difference with ΔEOK
// and stops within one just noticeable difference of the clipped color.

extension RGB {
    /// Whether every channel is within 0...1, allowing `tolerance` on either side. CSS gamut mapping uses none.
    public func isInGamut(tolerance: Double = 0) -> Bool {
        [red, green, blue].allSatisfy { $0 >= -tolerance && $0 <= 1 + tolerance }
    }

    /// Each channel clamped to 0...1 (clipping, CSS Color 4 §14.1.1).
    public func clipped() -> RGB {
        func clamp(_ value: Double) -> Double { Swift.min(Swift.max(value, 0), 1) }
        return RGB(space, red: clamp(red), green: clamp(green), blue: clamp(blue), alpha: alpha)
    }

    /// This color in the gamut of `space`: converted as is when it fits, otherwise mapped as CSS Color 4 §14.2 maps
    /// it. For example, the sRGB fallback of a Display P3 color.
    public func mapped(into space: RGBSpace) -> RGB {
        let converted = converted(to: space)
        return converted.isInGamut() ? converted : OKLCH(self).mapped(into: space)
    }
}

extension OKLCH {
    /// Whether the color fits the gamut of an RGB space; see `RGB.isInGamut(tolerance:)`.
    public func isInGamut(of space: RGBSpace, tolerance: Double = 0) -> Bool {
        RGB(self, in: space).isInGamut(tolerance: tolerance)
    }

    /// The color in the gamut of an RGB space by the binary search with local MINDE (CSS Color 4 §14.2.2).
    ///
    /// A lightness of 1 or more is white and of 0 or less is black, with the color's alpha; a color in gamut converts
    /// unchanged; otherwise the chroma is reduced until the clipped color is within one JND (ΔEOK 0.02) of the
    /// reduced one, and the clipped color is the result, which is always in gamut.
    public func mapped(into space: RGBSpace) -> RGB {
        // §14.2.2 converts oklab(1 0 0) and oklab(0 0 0) to the destination. Both spaces have Oklab's D65 white, so
        // those are exactly 1, 1, 1 and 0, 0, 0; written out, without the conversion's noise (0.9999999999999998).
        if l >= 1 { return RGB(space, red: 1, green: 1, blue: 1, alpha: alpha) }
        if l <= 0 { return RGB(space, red: 0, green: 0, blue: 0, alpha: alpha) }

        var current = self
        let origin = RGB(current, in: space)
        if origin.isInGamut() { return origin }

        let jnd = 0.02
        let epsilon = 0.0001
        func delta(_ clipped: RGB, _ color: OKLCH) -> Double { OKLab(clipped).deltaEOK(OKLab(color)) }

        var clipped = origin.clipped()
        if delta(clipped, current) < jnd { return clipped }

        // An infinite or undefined chroma would never narrow below epsilon; clipping is all that can be done.
        guard c.isFinite, l.isFinite, h?.isFinite ?? true else { return clipped }
        var min = 0.0
        var max = c
        var minInGamut = true
        while max - min > epsilon {
            let chroma = (min + max) / 2
            current.c = chroma
            let converted = RGB(current, in: space)
            if minInGamut && converted.isInGamut() {
                min = chroma
                continue
            }
            clipped = converted.clipped()
            let e = delta(clipped, current)
            if e < jnd {
                if jnd - e < epsilon { return clipped }
                minInGamut = false
                min = chroma
            } else {
                max = chroma
            }
        }
        return clipped
    }
}

extension OKLab {
    /// ΔEOK (CSS Color 4 §20.3): the Euclidean distance in Oklab. One just noticeable difference is 0.02 (§14.2.1).
    public func deltaEOK(_ other: OKLab) -> Double {
        let (dl, da, db) = (l - other.l, a - other.a, b - other.b)
        return (dl * dl + da * da + db * db).squareRoot()
    }
}
