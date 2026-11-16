import Foundation

/// Writes numbers into generated code the same way on every machine: a fixed number of decimals, a point as the
/// separator whatever the locale, no exponent and no `-0`.
///
/// The rounding is exact: it rounds the number the Double actually holds, not a product with its own rounding error,
/// so 0.35, which is held as 0.34999999999999997…, is "0.3" with one decimal. Ties, which only numbers like 0.125 that
/// are exact in binary can have, go away from zero. It uses only IEEE 754 arithmetic, which is the same on macOS and
/// Linux, and neither `printf` nor `NumberFormatter`.
public enum DecimalFormat {
    /// The largest number of decimals `fixed` writes.
    public static let maximumDecimals = 9

    /// `value` rounded to `decimals` places and written with exactly that many, for example "0.9771" or "-12.5000".
    /// With `trimmingZeros`, trailing zeros and then a bare point are dropped: "0.5", "1".
    ///
    /// `value` must be finite, `decimals` in 0...9, and `value` scaled by 10^decimals under 2^50 (with 9 decimals,
    /// a magnitude up to about a million).
    public static func fixed(_ value: Double, decimals: Int, trimmingZeros: Bool = false) -> String {
        precondition(value.isFinite, "a finite number: \(value)")
        precondition((0...maximumDecimals).contains(decimals), "0 to \(maximumDecimals) decimals: \(decimals)")
        let scale = powersOfTen[decimals]
        let magnitude = value.magnitude
        let product = magnitude * scale
        precondition(product < 0x1p50, "too large for \(decimals) decimals: \(value)")

        // The exact magnitude × scale is product + error: the rounding error of a product is itself a Double, and a
        // fused multiply-add computes it exactly. `product - whole` is exact too, so the comparison below is exact.
        let error = (-product).addingProduct(magnitude, scale)
        let whole = product.rounded(.down)
        let fraction = product - whole
        var units = UInt64(whole)
        if fraction - 0.5 >= -error { units += 1 }

        var digits = String(units)
        if decimals > 0 {
            if digits.count <= decimals { digits = String(repeating: "0", count: decimals + 1 - digits.count) + digits }
            digits.insert(".", at: digits.index(digits.endIndex, offsetBy: -decimals))
            if trimmingZeros {
                while digits.last == "0" { digits.removeLast() }
                if digits.last == "." { digits.removeLast() }
            }
        }
        return value < 0 && units > 0 ? "-" + digits : digits
    }

    private static let powersOfTen: [Double] = [1, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9]
}
