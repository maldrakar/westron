import Testing
import WestronTools

@Suite("Decimal format")
struct DecimalFormatTests {
    /// Expected strings from Python's `decimal`: `Decimal(x).quantize(Decimal(1).scaleb(-d), ROUND_HALF_UP)`, which
    /// rounds the exact value of the Double with ties away from zero; then without `-0`. Several of them are where
    /// rounding `x * 10^d` would be wrong: 0.35 × 10 and 2.675 × 100 round up to ties that the exact values are under.
    @Test(
        "rounds the exact value, ties away from zero",
        arguments: [
            (0.5, 0, "1"), (-0.5, 0, "-1"), (2.5, 0, "3"), (-1.5, 0, "-2"), (0.125, 2, "0.13"), (1.005, 2, "1.00"),
            (2.675, 2, "2.67"), (0.35, 1, "0.3"), (0.45, 1, "0.5"), (1.0000000000000002, 4, "1.0000"),
            (-0.00004, 4, "0.0000"), (-0.00005, 4, "-0.0001"), (0.00005, 4, "0.0001"), (123456.789, 3, "123456.789"),
            (1e-20, 4, "0.0000"), (0.97706044556579985, 4, "0.9771"), (-0.0, 4, "0.0000"),
            (0.0073663682842351466, 5, "0.00737"),
            (80.721159878281867, 2, "80.72"), (359.996, 2, "360.00"), (0.1 + 0.2, 9, "0.300000000"),
            (1e6, 9, "1000000.000000000"),
            (-12.5, 4, "-12.5000"), (42, 0, "42"), (0, 0, "0"),
        ])
    func fixed(value: Double, decimals: Int, expected: String) {
        #expect(DecimalFormat.fixed(value, decimals: decimals) == expected)
    }

    @Test(
        "trims trailing zeros and a bare point on request",
        arguments: [
            (0.5, 4, "0.5"), (1, 4, "1"), (-0.00004, 4, "0"), (0.9771, 4, "0.9771"), (120, 2, "120"), (-2.5, 3, "-2.5"),
            (0.0001, 3, "0"),
        ])
    func trimmed(value: Double, decimals: Int, expected: String) {
        #expect(DecimalFormat.fixed(value, decimals: decimals, trimmingZeros: true) == expected)
    }

    @Test("writes plain digits: no exponent, no grouping, the same for every value")
    func plainDigits() {
        #expect(DecimalFormat.fixed(1e-7, decimals: 9) == "0.000000100")
        #expect(DecimalFormat.fixed(-1e15, decimals: 0) == "-1000000000000000")
        // Every number of 4 decimals in 0...1 comes back as itself.
        for units in 0...10000 {
            let text = DecimalFormat.fixed(Double(units) / 10000, decimals: 4)
            #expect(Double(text) == Double(units) / 10000 && text.count == 6, "\(units): \(text)")
        }
    }
}
