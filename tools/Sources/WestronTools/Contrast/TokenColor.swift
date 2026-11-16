import Foundation

extension TokenValue.Color {
    /// The color in an RGB space and inside its gamut: converted with westron's color code (`Color/`), and mapped by
    /// CSS Color 4 gamut mapping (§14.2) when it falls outside; alpha is the token's.
    ///
    /// A missing component (`none`) counts as 0, except a missing OkLCh hue, which stays missing (CSS Color 4 §9.6
    /// then reads it as 0 too). Returns nil for the color spaces the color code does not convert: `hsl`, `hwb`, `lab`,
    /// `lch`, `a98-rgb`, `prophoto-rgb`, `rec2020`, `xyz-d50`.
    public func mapped(into space: RGBSpace) -> RGB? {
        guard components.count == 3 else { return nil }
        let numbers = components.map { component -> Double in
            if case .number(let value) = component { return value }
            return 0
        }
        let (first, second, third) = (numbers[0], numbers[1], numbers[2])
        let color: RGB
        switch colorSpace {
        case .srgb:
            color = RGB(.sRGB, red: first, green: second, blue: third, alpha: alpha)
        case .displayP3:
            color = RGB(.displayP3, red: first, green: second, blue: third, alpha: alpha)
        case .srgbLinear:
            color = RGB(LinearRGB(.sRGB, red: first, green: second, blue: third, alpha: alpha))
        case .xyzD65:
            color = RGB(LinearRGB(XYZ(x: first, y: second, z: third, alpha: alpha), in: space))
        case .oklab:
            return OKLCH(OKLab(l: first, a: second, b: third, alpha: alpha)).mapped(into: space)
        case .oklch:
            let hue = components[2] == .none ? nil : third
            return OKLCH(l: first, c: second, h: hue, alpha: alpha).mapped(into: space)
        case .hsl, .hwb, .lab, .lch, .a98RGB, .prophotoRGB, .rec2020, .xyzD50:
            return nil
        }
        return color.mapped(into: space)
    }
}
