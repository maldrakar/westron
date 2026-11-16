import Foundation

// westron's own color math (decisions/0009): the color types and the conversions between them, after CSS Color 4
// (W3C Candidate Recommendation Draft, 12 November 2026, https://www.w3.org/TR/css-color-4/). Section numbers below
// refer to that draft.
//
//   OKLCH ⇄ OKLab ⇄ XYZ (D65) ⇄ LinearRGB ⇄ RGB      sRGB and Display P3 on the RGB side
//
// Every type carries alpha, and every conversion passes it through unchanged. Conversions do not clamp: a color out
// of an RGB gamut keeps channels below 0 or above 1; `mapped(into:)` brings it into gamut (GamutMapping.swift).

/// The RGB spaces westron writes colors in. Both have the D65 white and the sRGB transfer function; the raw value is
/// the space's identifier in CSS Color 4 and in DTCG 2025.10 (`colorSpace`).
public enum RGBSpace: String, CaseIterable, Sendable {
    /// sRGB (CSS Color 4 §10.2).
    case sRGB = "srgb"
    /// Display P3 (CSS Color 4 §10.4): wider primaries than sRGB, the same white and transfer function.
    case displayP3 = "display-p3"
}

/// A gamma-encoded RGB color: `srgb` or `display-p3`. In gamut, each channel is in 0...1.
public struct RGB: Hashable, Sendable {
    public var space: RGBSpace
    public var red: Double
    public var green: Double
    public var blue: Double
    /// Opacity in 0...1.
    public var alpha: Double

    public init(_ space: RGBSpace, red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.space = space
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

/// A linear-light RGB color: `srgb-linear` (CSS Color 4 §10.3) or `display-p3-linear` (§10.5).
public struct LinearRGB: Hashable, Sendable {
    public var space: RGBSpace
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(_ space: RGBSpace, red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.space = space
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

/// CIE XYZ relative to the D65 white (`xyz-d65`, CSS Color 4 §10.9): the space RGB and Oklab convert through.
/// `y` is the luminance, 1 for the white.
public struct XYZ: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var alpha: Double

    public init(x: Double, y: Double, z: Double, alpha: Double = 1) {
        self.x = x
        self.y = y
        self.z = z
        self.alpha = alpha
    }
}

/// Oklab (CSS Color 4 §9.2): `l` is the lightness, 0 for black and 1 for white; `a` and `b` are signed and in practice
/// within ±0.5.
public struct OKLab: Hashable, Sendable {
    public var l: Double
    public var a: Double
    public var b: Double
    public var alpha: Double

    public init(l: Double, a: Double, b: Double, alpha: Double = 1) {
        self.l = l
        self.a = a
        self.b = b
        self.alpha = alpha
    }
}

/// OkLCh (CSS Color 4 §9.2, §9.4), the polar form of Oklab: lightness `l` in 0...1, chroma `c` from 0 (in practice
/// under 0.5) and hue `h` in degrees.
///
/// A nil hue is missing (`none` in CSS and DTCG). Conversion from Oklab produces it when the hue is powerless, that is
/// when the chroma is at most `powerlessChroma`; conversion to Oklab reads a missing hue as 0 (§9.6).
public struct OKLCH: Hashable, Sendable {
    public var l: Double
    public var c: Double
    public var h: Double?
    public var alpha: Double

    /// The chroma at or below which the hue is powerless: ε for OkLCh, `C <= 0.000004` (CSS Color 4 §9.4).
    public static let powerlessChroma = 0.000004

    public init(l: Double, c: Double, h: Double?, alpha: Double = 1) {
        self.l = l
        self.c = c
        self.h = h
        self.alpha = alpha
    }
}

// MARK: - Conversions

extension LinearRGB {
    /// Removes the transfer function: `lin_sRGB` and `lin_P3` (CSS Color 4 §19), which Display P3 shares with sRGB.
    /// Extended to negative values by reflection, as §19 does, so out-of-gamut colors convert too.
    public init(_ color: RGB) {
        func linear(_ value: Double) -> Double {
            let magnitude = value.magnitude
            if magnitude <= 0.04045 { return value / 12.92 }
            let result = pow((magnitude + 0.055) / 1.055, 2.4)
            return value < 0 ? -result : result
        }
        self.init(
            color.space, red: linear(color.red), green: linear(color.green), blue: linear(color.blue),
            alpha: color.alpha)
    }

    /// `XYZ_to_lin_sRGB` and `XYZ_to_lin_P3` (CSS Color 4 §19).
    public init(_ color: XYZ, in space: RGBSpace) {
        let (red, green, blue) = Matrix3.fromXYZ(space).apply((color.x, color.y, color.z))
        self.init(space, red: red, green: green, blue: blue, alpha: color.alpha)
    }
}

extension RGB {
    /// Applies the transfer function: `gam_sRGB` and `gam_P3` (CSS Color 4 §19), extended to negative values by
    /// reflection.
    public init(_ color: LinearRGB) {
        func encoded(_ value: Double) -> Double {
            let magnitude = value.magnitude
            if magnitude <= 0.0031308 { return 12.92 * value }
            let result = 1.055 * pow(magnitude, 1 / 2.4) - 0.055
            return value < 0 ? -result : result
        }
        self.init(
            color.space, red: encoded(color.red), green: encoded(color.green), blue: encoded(color.blue),
            alpha: color.alpha)
    }

    /// An Oklab color in an RGB space, with no gamut mapping (CSS Color 4 §10.11).
    public init(_ color: OKLab, in space: RGBSpace) {
        self.init(LinearRGB(XYZ(color), in: space))
    }

    /// An OkLCh color in an RGB space, with no gamut mapping. For a color that has to be displayed, use
    /// `OKLCH.mapped(into:)`.
    public init(_ color: OKLCH, in space: RGBSpace) {
        self.init(OKLab(color), in: space)
    }

    /// The same color in another RGB space, through XYZ (CSS Color 4 §10.12), with no gamut mapping.
    public func converted(to space: RGBSpace) -> RGB {
        space == self.space ? self : RGB(LinearRGB(XYZ(LinearRGB(self)), in: space))
    }
}

extension XYZ {
    /// `lin_sRGB_to_XYZ` and `lin_P3_to_XYZ` (CSS Color 4 §19).
    public init(_ color: LinearRGB) {
        let (x, y, z) = Matrix3.toXYZ(color.space).apply((color.red, color.green, color.blue))
        self.init(x: x, y: y, z: z, alpha: color.alpha)
    }

    /// `OKLab_to_XYZ` (CSS Color 4 §19).
    public init(_ color: OKLab) {
        let (l, m, s) = Matrix3.okLabToLMS.apply((color.l, color.a, color.b))
        let (x, y, z) = Matrix3.lmsToXYZ.apply((l * l * l, m * m * m, s * s * s))
        self.init(x: x, y: y, z: z, alpha: color.alpha)
    }
}

extension OKLab {
    /// `XYZ_to_OKLab` (CSS Color 4 §19). The cube root is sign-matched, as §19 warns it must be.
    public init(_ color: XYZ) {
        let (l, m, s) = Matrix3.xyzToLMS.apply((color.x, color.y, color.z))
        let (lightness, a, b) = Matrix3.lmsToOKLab.apply((cbrt(l), cbrt(m), cbrt(s)))
        self.init(l: lightness, a: a, b: b, alpha: color.alpha)
    }

    /// The rectangular form of an OkLCh color (CSS Color 4 §9.6): a missing hue is 0.
    public init(_ color: OKLCH) {
        let radians = (color.h ?? 0) * Double.pi / 180
        self.init(l: color.l, a: color.c * cos(radians), b: color.c * sin(radians), alpha: color.alpha)
    }

    /// An RGB color in Oklab.
    public init(_ color: RGB) {
        self.init(XYZ(LinearRGB(color)))
    }
}

extension OKLCH {
    /// The polar form of an Oklab color (CSS Color 4 §9.5). The hue is in 0..<360; when the chroma is at most
    /// `powerlessChroma`, the hue is powerless, so it becomes missing and the chroma 0 (§4.4.1).
    public init(_ color: OKLab) {
        let chroma = hypot(color.a, color.b)
        guard chroma > Self.powerlessChroma else {
            self.init(l: color.l, c: 0, h: nil, alpha: color.alpha)
            return
        }
        var hue = atan2(color.b, color.a) * 180 / Double.pi
        if hue < 0 { hue += 360 }
        if hue >= 360 { hue -= 360 }
        self.init(l: color.l, c: chroma, h: hue, alpha: color.alpha)
    }

    /// An RGB color in OkLCh.
    public init(_ color: RGB) {
        self.init(OKLab(color))
    }
}

// MARK: - Matrices

/// A 3×3 matrix by rows; `apply` multiplies a column vector, as `multiplyMatrices` does in CSS Color 4 §19.
struct Matrix3: Sendable {
    typealias Vector = (Double, Double, Double)

    let rows: (Vector, Vector, Vector)

    init(_ rows: [[Double]]) {
        precondition(rows.count == 3 && rows.allSatisfy { $0.count == 3 }, "a 3×3 matrix")
        self.rows = (
            (rows[0][0], rows[0][1], rows[0][2]), (rows[1][0], rows[1][1], rows[1][2]),
            (rows[2][0], rows[2][1], rows[2][2])
        )
    }

    func apply(_ v: Vector) -> Vector {
        func dot(_ row: Vector) -> Double { row.0 * v.0 + row.1 * v.1 + row.2 * v.2 }
        return (dot(rows.0), dot(rows.1), dot(rows.2))
    }

    static func toXYZ(_ space: RGBSpace) -> Matrix3 {
        switch space {
        case .sRGB: sRGBToXYZ
        case .displayP3: displayP3ToXYZ
        }
    }

    static func fromXYZ(_ space: RGBSpace) -> Matrix3 {
        switch space {
        case .sRGB: xyzToSRGB
        case .displayP3: xyzToDisplayP3
        }
    }

    // The RGB matrices are the rationals of CSS Color 4 §19, each evaluated as a Double division.

    /// `lin_sRGB_to_XYZ`.
    static let sRGBToXYZ = Matrix3([
        [506752 / 1228815, 87881 / 245763, 12673 / 70218],
        [87098 / 409605, 175762 / 245763, 12673 / 175545],
        [7918 / 409605, 87881 / 737289, 1001167 / 1053270],
    ])
    /// `XYZ_to_lin_sRGB`.
    static let xyzToSRGB = Matrix3([
        [12831 / 3959, -329 / 214, -1974 / 3959],
        [-851781 / 878810, 1648619 / 878810, 36519 / 878810],
        [705 / 12673, -2585 / 12673, 705 / 667],
    ])
    /// `lin_P3_to_XYZ`.
    static let displayP3ToXYZ = Matrix3([
        [608311 / 1250200, 189793 / 714400, 198249 / 1000160],
        [35783 / 156275, 247089 / 357200, 198249 / 2500400],
        [0 / 1, 32229 / 714400, 5220557 / 5000800],
    ])
    /// `XYZ_to_lin_P3`.
    static let xyzToDisplayP3 = Matrix3([
        [446124 / 178915, -333277 / 357830, -72051 / 178915],
        [-14852 / 17905, 63121 / 35810, 423 / 17905],
        [11844 / 330415, -50337 / 660830, 316169 / 330415],
    ])

    // The Oklab matrices of CSS Color 4 §19, recalculated there for a consistent D65 white and 64-bit precision.

    /// `XYZtoLMS` in `XYZ_to_OKLab`.
    static let xyzToLMS = Matrix3([
        [0.8190224379967030, 0.3619062600528904, -0.1288737815209879],
        [0.0329836539323885, 0.9292868615863434, 0.0361446663506424],
        [0.0481771893596242, 0.2642395317527308, 0.6335478284694309],
    ])
    /// `LMStoOKLab` in `XYZ_to_OKLab`.
    static let lmsToOKLab = Matrix3([
        [0.2104542683093140, 0.7936177747023054, -0.0040720430116193],
        [1.9779985324311684, -2.4285922420485799, 0.4505937096174110],
        [0.0259040424655478, 0.7827717124575296, -0.8086757549230774],
    ])
    /// `OKLabtoLMS` in `OKLab_to_XYZ`.
    static let okLabToLMS = Matrix3([
        [1.0000000000000000, 0.3963377773761749, 0.2158037573099136],
        [1.0000000000000000, -0.1055613458156586, -0.0638541728258133],
        [1.0000000000000000, -0.0894841775298119, -1.2914855480194092],
    ])
    /// `LMStoXYZ` in `OKLab_to_XYZ`.
    static let lmsToXYZ = Matrix3([
        [1.2268798758459243, -0.5578149944602171, 0.2813910456659647],
        [-0.0405757452148008, 1.1122868032803170, -0.0717110580655164],
        [-0.0763729366746601, -0.4214933324022432, 1.5869240198367816],
    ])
}
