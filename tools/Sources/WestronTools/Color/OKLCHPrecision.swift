import Foundation

/// How many decimals each OkLCh component is written with.
public struct OKLCHPrecision: Hashable, Sendable {
    public var l: Int
    public var c: Int
    public var h: Int

    public init(l: Int, c: Int, h: Int) {
        self.l = l
        self.c = c
        self.h = h
    }

    /// The fewest decimals with which every 8-bit sRGB color survives hex → OkLCh → hex: L 4, C 5, H 2.
    ///
    /// Found by an exhaustive search over all 16,777,216 colors, back to sRGB by CSS gamut mapping and rounded to
    /// 8 bits. One decimal fewer for any single component fails even with the other two at L 6, C 6, H 4: L 3 fails
    /// on 400,956 colors (#0000DA first), C 4 on 7,897 (#00C5D5), H 1 on 501,487 (#0000D5). The failures are where a
    /// channel is near 0, where the sRGB transfer function is steepest. With L 4, C 5, H 2 the largest deviation of a
    /// channel from its byte is 0.455 of a step (#09FF00), under the 0.5 that would change it.
    public static let hexRoundTrip = OKLCHPrecision(l: 4, c: 5, h: 2)
}

extension OKLCH {
    /// A hex color that does not come back from OkLCh at the given precision.
    public struct RoundTripError: Error, CustomStringConvertible {
        public let hex: String
        public let result: String
        public let precision: OKLCHPrecision

        public var description: String {
            "\(hex) does not round-trip through OkLCh with L \(precision.l), C \(precision.c), H \(precision.h) "
                + "decimals: it comes back as \(result)"
        }
    }

    /// Each component rounded to its decimals as `DecimalFormat.fixed` writes them, so the result is exactly what a
    /// reader of the written numbers gets. The hue stays in 0..<360; when the chroma rounds to 0, the hue becomes
    /// missing.
    public func rounded(to precision: OKLCHPrecision) -> OKLCH {
        func round(_ value: Double, _ decimals: Int) -> Double {
            // The written number parses back exactly: `Double(String)` rounds correctly on every platform.
            Double(DecimalFormat.fixed(value, decimals: decimals))!
        }
        let chroma = round(c, precision.c)
        var hue = h.map { round($0, precision.h) }
        if let value = hue, value >= 360 { hue = value - 360 }
        return OKLCH(l: round(l, precision.l), c: chroma, h: chroma == 0 ? nil : hue, alpha: alpha)
    }

    /// The OkLCh components of an sRGB hex color, rounded to `precision`, such that mapping them back into sRGB and
    /// rounding to 8 bits gives exactly the same hex. This is how a primitive is stored in OkLCh with the pilot's hex
    /// as its fallback.
    ///
    /// Throws `RGB.HexError` for a malformed hex, and `RoundTripError` if a precision lower than `hexRoundTrip` loses
    /// the color.
    public init(hex: String, precision: OKLCHPrecision = .hexRoundTrip) throws {
        let color = try RGB(hex: hex)
        self = OKLCH(color).rounded(to: precision)
        let result = mapped(into: .sRGB).hex
        guard result == color.hex else {
            throw RoundTripError(hex: hex, result: result, precision: precision)
        }
    }
}
