import Testing
import WestronTools

@Suite("Gamut mapping")
struct GamutMappingTests {
    /// Out-of-gamut OkLCh colors mapped by colorjs.io 0.5.2, `toGamut({space, method: "css"})`, which implements
    /// CSS Color 4 §14.2.2 and which the spec cites for it; a separate implementation in Python, written from the
    /// §14.2.2 pseudocode, agrees to 1e-15. The tolerance, 1e-9, only absorbs platform differences in `pow` and
    /// `cbrt`: one step more or less of the binary search would move a channel by about 1e-4.
    static let colorjs: [RGBSpace: [(oklch: (Double, Double, Double), mapped: (Double, Double, Double))]] = [
        .sRGB: [
            ((0.7, 0.3, 30), (1, 0.34513507874832117, 0.26457511225176500)),
            ((0.9, 0.3, 120), (0.79883261461618371, 0.94981107389222597, 0)),
            ((0.5, 0.4, 264), (0, 0.20175324551541635, 1)),
            ((0.76, 0.27, 60), (1, 0.54855450692184693, 0)),
            ((0.62, 0.25, 145), (0, 0.65172339849975447, 0)),
            ((0.98, 0.1, 200), (0.77729773753650422, 1, 1)),
            ((0.2, 0.3, 300), (0.13198899596540004, 0, 0.27332753469520799)),
            ((0.8, 0.5, 330), (1, 0.49558696322112966, 1)),
            ((0.6, 0.35, 180), (0, 0.59727114573982976, 0.51413384773424042)),
            ((0.4, 0.2, 90), (0.36321200058629310, 0.26544587259765517, 0)),
        ],
        .displayP3: [
            ((0.7, 0.3, 30), (1, 0.28509550961159352, 0.19277696636614494)),
            ((0.9, 0.3, 120), (0.82360119691083233, 0.95237466389895242, 0)),
            ((0.5, 0.4, 264), (0.031189130570132728, 0.14610372609031241, 1)),
            ((0.76, 0.27, 60), (1, 0.54579207159275245, 0)),
            ((0.62, 0.25, 145), (0.14986318448757682, 0.64898484458236172, 0.095851480495834446)),
            ((0.98, 0.1, 200), (0.81040692812140613, 1, 1)),
            ((0.2, 0.3, 300), (0.11597967352491309, 0, 0.26676165943762753)),
            ((0.8, 0.5, 330), (1, 0.44380677241347355, 1)),
            ((0.6, 0.35, 180), (0, 0.60873756772618282, 0.52025821106714421)),
            ((0.4, 0.2, 90), (0.35638457081005892, 0.26617550469615858, 0)),
        ],
    ]

    @Test(
        "out-of-gamut OkLCh colors map into sRGB and Display P3 as colorjs.io maps them", arguments: RGBSpace.allCases)
    func matchesColorjs(space: RGBSpace) {
        for (oklch, expected) in Self.colorjs[space]! {
            let color = OKLCH(l: oklch.0, c: oklch.1, h: oklch.2, alpha: 0.6)
            let mapped = color.mapped(into: space)
            #expect(near(mapped, expected, 1e-9), "oklch\(oklch) in \(space): \(mapped)")
            #expect(mapped.space == space && mapped.alpha == 0.6 && mapped.isInGamut())
            // Every one is out of sRGB; oklch(0.62 0.25 145) is inside Display P3, so it converts unchanged.
            #expect(color.isInGamut(of: space) == (space == .displayP3 && oklch == (0.62, 0.25, 145)))
        }
    }

    /// Display P3 colors mapped into sRGB (their sRGB fallback) by colorjs.io 0.5.2, tolerance 1e-9; and the
    /// CSS Color 4 §14.2 example: color(display-p3 1.1 0.4 0.2) maps to "such as color(display-p3 1 0.473 0.314)",
    /// tolerance half of the last printed digit.
    @Test("Display P3 colors map into sRGB as colorjs.io maps them, and into Display P3 as CSS Color 4 §14.2 shows")
    func displayP3() {
        let fallbacks: [((Double, Double, Double), (Double, Double, Double))] = [
            ((1, 1, 0), (0.99623327296097253, 0.99901389584961053, 0)),
            ((0, 1, 0), (0, 0.98576371077103275, 0.15974244397343720)),
            ((1, 0, 0), (1, 0.044569516204190078, 0.045931611140175292)),
            ((0, 0, 1), (0, 0, 1)),
            ((1.1, 0.4, 0.2), (1, 0.50105538223403379, 0.36711261233471776)),
        ]
        for (p3, expected) in fallbacks {
            let color = RGB(.displayP3, red: p3.0, green: p3.1, blue: p3.2)
            let fallback = color.mapped(into: .sRGB)
            #expect(fallback.space == .sRGB && near(fallback, expected, 1e-9), "\(p3) → \(fallback)")
        }
        let spec = RGB(.displayP3, red: 1.1, green: 0.4, blue: 0.2).mapped(into: .displayP3)
        #expect(near(spec, (1, 0.473, 0.314), 0.0005), "\(spec)")
        // CSS Color 4 §14.2: oklch(76% 0.27 60) maps into Display P3 as "such as color(display-p3 1 0.546 0)".
        #expect(near(OKLCH(l: 0.76, c: 0.27, h: 60).mapped(into: .displayP3), (1, 0.546, 0), 0.0005))
    }

    @Test("colors in gamut are unchanged, lightness at the ends is white or black")
    func edges() {
        let inside = RGB(.sRGB, red: 0.2, green: 0.5, blue: 0.9, alpha: 0.3)
        #expect(inside.mapped(into: .sRGB) == inside)
        #expect(inside.mapped(into: .displayP3) == inside.converted(to: .displayP3))
        for hex in pilotHexes {
            let color = sRGB(hex)
            #expect(color.mapped(into: .sRGB) == color)
            #expect(OKLCH(color).mapped(into: .sRGB).hex == hex)
        }

        // CSS Color 4 §14.2.2: L ≥ 1 is oklab(1 0 0), L ≤ 0 oklab(0 0 0), with the color's alpha.
        let white = RGB(.sRGB, red: 1, green: 1, blue: 1, alpha: 0.5)
        let black = RGB(.sRGB, red: 0, green: 0, blue: 0, alpha: 0.5)
        #expect(OKLCH(l: 1, c: 0.2, h: 30, alpha: 0.5).mapped(into: .sRGB) == white)
        #expect(OKLCH(l: 1.2, c: 0, h: nil, alpha: 0.5).mapped(into: .sRGB) == white)
        #expect(OKLCH(l: 0, c: 0.2, h: 30, alpha: 0.5).mapped(into: .sRGB) == black)
        #expect(OKLCH(l: -0.1, c: 0.1, h: 200, alpha: 0.5).mapped(into: .sRGB) == black)
        #expect(OKLCH(l: 1, c: 0, h: nil).mapped(into: .displayP3) == RGB(.displayP3, red: 1, green: 1, blue: 1))
    }

    @Test("clipping, the gamut check and its tolerance")
    func clipAndCheck() {
        let color = RGB(.displayP3, red: -0.1, green: 0.5, blue: 1.0000001, alpha: 0.7)
        #expect(color.clipped() == RGB(.displayP3, red: 0, green: 0.5, blue: 1, alpha: 0.7))
        #expect(!color.isInGamut())
        #expect(!color.isInGamut(tolerance: 0.01))
        #expect(RGB(.sRGB, red: 0, green: 1.0000001, blue: -0.0000001).isInGamut(tolerance: 0.000001))
        #expect(!RGB(.sRGB, red: 0, green: 1.0000001, blue: 0).isInGamut())
    }

    /// colorjs.io 0.5.2, `deltaE(other, "OK")`; tolerance 1e-12.
    @Test(
        "ΔEOK matches colorjs.io",
        arguments: [
            ("#FF0000", "#00FF00", 0.51981290155191662), ("#1F1D1A", "#1A1917", 0.018238852649837215),
            ("#D49408", "#D79D1C", 0.022751990278979964),
        ])
    func deltaEOK(first: String, second: String, expected: Double) {
        let distance = OKLab(sRGB(first)).deltaEOK(OKLab(sRGB(second)))
        #expect(near(distance, expected, 1e-12))
        #expect(OKLab(sRGB(second)).deltaEOK(OKLab(sRGB(first))) == distance)
    }
}
