import Testing
import WestronTools

@Suite("Color conversions")
struct ColorConversionTests {
    /// colorjs.io 0.5.2, `new Color(hex).to("oklch")`, printed with 17 significant digits. The code under test uses
    /// the same CSS Color 4 matrices, so the tolerance only absorbs `pow` and `cbrt` differences between platforms:
    /// 1e-9 for every component, hue included.
    static let colorjsOKLCH: [(hex: String, l: Double, c: Double, h: Double?)] = [
        ("#FAF7F2", 0.97706044556579985, 0.0073663682842351466, 80.721159878281867),
        ("#1A1917", 0.21376591285100197, 0.0041604176515431723, 84.588885373051880),
        ("#FFFFFF", 1, 0, nil),
        ("#24221F", 0.25303090919253668, 0.0063042993702458012, 78.212134036951284),
        ("#F2EDE5", 0.94778629170122886, 0.011956953764379590, 79.783814086263192),
        ("#1F1E1B", 0.23499365212565923, 0.0058280908168701307, 91.608130794189265),
        ("#F0EBE3", 0.94175460218039875, 0.011975699328128553, 79.783543340234644),
        ("#2E2B27", 0.29083365058657656, 0.0083601142659233789, 75.252981132895002),
        ("#E8E2D8", 0.91474913372351208, 0.014937626368548495, 80.705404453723759),
        ("#35322D", 0.31849970584316334, 0.0096753970146705309, 80.662806771623707),
        ("#1F1D1A", 0.23185284564566933, 0.0064376022774675712, 78.196478366755002),
        ("#EEEAE3", 0.93821921917349693, 0.010312285129572173, 81.794822711572635),
        ("#625C53", 0.47760663482981341, 0.016087794066372306, 78.160778976745746),
        ("#ABA498", 0.72115007496828387, 0.018855372366593553, 81.313636854865592),
        ("#A39C90", 0.69523170393339284, 0.019020124135661780, 81.310174994246154),
        ("#6F6A62", 0.52637577805826585, 0.013790679350043997, 79.737511590901136),
        ("#C2362B", 0.54375995708399572, 0.17864556659133149, 28.857234499409685),
        ("#F07468", 0.70194225533233490, 0.15513690905742036, 27.357529596113636),
        ("#E0D9CC", 0.88729450223424233, 0.019151653773225714, 83.062935236657097),
        ("#36332E", 0.32244910730541698, 0.0096473109116633135, 80.664571611616680),
        ("#3653C9", 0.49333422874397914, 0.18609846271228919, 268.18653211251984),
        ("#E7EAF9", 0.93917439474377851, 0.020459461869666597, 276.95084579311469),
        ("#3E6EC5", 0.54922393726252561, 0.14537289383873778, 261.23063597262023),
        ("#D49408", 0.71140307675058068, 0.14711337311515243, 77.533406616941534),
        ("#D2455A", 0.59390673659264159, 0.17643444729104321, 15.747249316676005),
        ("#36925C", 0.59093109329739191, 0.12031624318123585, 154.31236912822806),
        ("#8A847A", 0.61562250702241894, 0.016433938830190582, 80.676222485451717),
        ("#5B55D8", 0.53148847166625268, 0.19429212274215632, 279.52599340885291),
        ("#168985", 0.57116553439258433, 0.093801314202300493, 191.09476307109821),
        ("#C64C88", 0.59633825814106700, 0.16696115259220407, 352.80690580430706),
        ("#D7652C", 0.63645952191595923, 0.15904863785115178, 44.307909154843401),
        ("#8452C8", 0.55180214384945137, 0.17723526631720940, 300.18349686537061),
        ("#2A86B9", 0.59044992158740617, 0.11426208411289954, 238.00762461043809),
    ]

    /// colorjs.io 0.5.2, `new Color(hex).to("p3")`, tolerance 1e-9.
    static let colorjsDisplayP3: [(hex: String, rgb: (Double, Double, Double))] = [
        ("#FAF7F2", (0.97831715172806277, 0.96902101166126953, 0.95100357354194009)),
        ("#1A1917", (0.10127459373216133, 0.098171651676085409, 0.090994939273902342)),
        ("#FFFFFF", (1, 1, 1)),
        ("#24221F", (0.13981617921658396, 0.13360104493170891, 0.12281563673190288)),
        ("#F2EDE5", (0.94557767889151678, 0.93007142085186967, 0.90125917472114636)),
        ("#1F1E1B", (0.12088132010295258, 0.11777923731864226, 0.10705856749636189)),
        ("#F0EBE3", (0.93773485087343145, 0.92222835431513339, 0.89341668364493054)),
        ("#2E2B27", (0.17836383670186964, 0.16903194007081121, 0.15464067084267852)),
        ("#E8E2D8", (0.90568533693799536, 0.88706879270964090, 0.85109669434072210)),
        ("#35322D", (0.20580848943801555, 0.19648138697392259, 0.17854984292049286)),
        ("#1F1D1A", (0.12021192119856217, 0.11399406116186814, 0.10321534477383343)),
        ("#EEEAE3", (0.93057390676984042, 0.91817344352590868, 0.89297886247509950)),
        ("#625C53", (0.38026577158452846, 0.36159541688681651, 0.32930236431937088)),
        ("#ABA498", (0.66582114992521824, 0.64407280162666447, 0.60100953484449648)),
        ("#A39C90", (0.63445343026431233, 0.61270140167521003, 0.56964973260908147)),
        ("#6F6A62", (0.43189341341746973, 0.41635555927939144, 0.38762483867859798)),
        ("#C2362B", (0.70158623445182811, 0.25663412257075680, 0.20247904513772397)),
        ("#F07468", (0.87961404430320655, 0.48201948380812082, 0.42830154165964995)),
        ("#E0D9CC", (0.87364051185667135, 0.85191034158343448, 0.80525041164246680)),
        ("#36332E", (0.20972926079339343, 0.20040276358885334, 0.18246934570643872)),
        ("#3653C9", (0.23665772614095010, 0.32245502389139302, 0.76029777888340166)),
        ("#E7EAF9", (0.90798574200980386, 0.91725973202101141, 0.97121327276874048)),
        ("#3E6EC5", (0.28771394603121603, 0.42669231426616622, 0.74869547320803387)),
        ("#D49408", (0.79421239420214729, 0.59101706881081106, 0.20566500404107058)),
        ("#D2455A", (0.76150595731437087, 0.31124123891081179, 0.36302253804294038)),
        ("#36925C", (0.31592266638489563, 0.56491851623593969, 0.37940168642662109)),
        ("#8A847A", (0.53709435466341648, 0.51844989750511239, 0.48255711450054645)),
        ("#5B55D8", (0.35282345686749317, 0.33414657272560921, 0.81732180804226406)),
        ("#168985", (0.25033768477951646, 0.52925060569966920, 0.51875286106189389)),
        ("#C64C88", (0.72019287315130831, 0.32934383307193144, 0.52615187326088608)),
        ("#D7652C", (0.78698494957244725, 0.42141382097676072, 0.23199373583727434)),
        ("#8452C8", (0.48983720176295015, 0.33045594208014073, 0.75855545063872154)),
        ("#2A86B9", (0.27478166650163527, 0.51817685198518593, 0.70795017738344090)),
    ]

    @Test("the pilot's hexes in OkLCh and Display P3 match colorjs.io")
    func pilotMatchesColorjs() {
        #expect(Self.colorjsOKLCH.map(\.hex) == pilotHexes && Self.colorjsDisplayP3.map(\.hex) == pilotHexes)
        for row in Self.colorjsOKLCH {
            let oklch = OKLCH(sRGB(row.hex))
            #expect(near(oklch.l, row.l, 1e-9), "\(row.hex) L \(oklch.l)")
            #expect(near(oklch.c, row.c, 1e-9), "\(row.hex) C \(oklch.c)")
            #expect(hueDistance(oklch.h, row.h) <= 1e-9, "\(row.hex) H \(String(describing: oklch.h))")
        }
        for row in Self.colorjsDisplayP3 {
            let p3 = sRGB(row.hex).converted(to: .displayP3)
            #expect(p3.space == .displayP3 && near(p3, row.rgb, 1e-9), "\(row.hex) in Display P3: \(p3)")
        }
    }

    /// colorjs.io 0.5.2: `.to("oklab")`, `.to("xyz-d65")`, `.to("p3-linear")` of the sRGB primaries and two more.
    @Test(
        "every step of the chain matches colorjs.io",
        arguments: [
            (
                "#FF0000", (0.62795536392143114, 0.22486306842627440, 0.12584627733058501),
                (0.41239079926595934, 0.21263900587151027, 0.019330818715591822),
                (0.82246196871436206, 0.033194198850961636, 0.017082630721120033)
            ),
            (
                "#00FF00", (0.86643961752343679, -0.23388758093655815, 0.17949844516093760),
                (0.35758433938387801, 0.71516867876775603, 0.11919477979462598),
                (0.17753803128563761, 0.96680580114903825, 0.072397440663963392)
            ),
            (
                "#0000FF", (0.45201371817442365, -0.032456975170797708, -0.31152816567757780),
                (0.18048078840183429, 0.072192315360733714, 0.95053215224966070), (0, 0, 0.91051992861491660)
            ),
            (
                "#808080", (0.59987080562214690, 0, 0), (0.20516589174959360, 0.21586050011389926, 0.23508455073194565),
                (0.21586050011389918, 0.21586050011389923, 0.21586050011389926)
            ),
            (
                "#3653C9", (0.49333422874397914, -0.0058892163448839852, -0.18600525518038580),
                (0.15155901385862480, 0.11187253054771337, 0.56620882244346638),
                (0.045697291736946560, 0.084853664251125283, 0.53870762029017982)
            ),
        ])
    func chainMatchesColorjs(
        hex: String, oklab: (Double, Double, Double), xyz: (Double, Double, Double), p3Linear: (Double, Double, Double)
    ) {
        let linear = LinearRGB(sRGB(hex))
        let toXYZ = XYZ(linear)
        #expect(near(toXYZ.x, xyz.0, 1e-12) && near(toXYZ.y, xyz.1, 1e-12) && near(toXYZ.z, xyz.2, 1e-12))
        let lab = OKLab(toXYZ)
        #expect(near(lab.l, oklab.0, 1e-12) && near(lab.a, oklab.1, 1e-12) && near(lab.b, oklab.2, 1e-12))
        let p3 = LinearRGB(toXYZ, in: .displayP3)
        #expect(near(p3.red, p3Linear.0, 1e-12) && near(p3.green, p3Linear.1, 1e-12))
        #expect(near(p3.blue, p3Linear.2, 1e-12))
    }

    /// CSS Color 4 §9.4 prints these pairs: Oklab a and b to 4 decimals, so the tolerance is half of that last
    /// digit, 0.00005.
    @Test(
        "OkLCh to Oklab gives the pairs printed in CSS Color 4 §9.4",
        arguments: [
            (0.40101, 0.12332, 21.555, 0.1147, 0.0453), (0.59686, 0.15619, 49.7694, 0.1009, 0.1192),
            (0.65125, 0.13138, 104.097, -0.0320, 0.1274), (0.66016, 0.15546, 134.231, -0.1084, 0.1114),
            (0.72322, 0.12403, 247.996, -0.0465, -0.1150),
        ])
    func specOklabPairs(l: Double, c: Double, h: Double, a: Double, b: Double) {
        let lab = OKLab(OKLCH(l: l, c: c, h: h))
        #expect(lab.l == l)
        #expect(near(lab.a, a, 0.00005) && near(lab.b, b, 0.00005), "\(lab)")
    }

    /// Other examples printed in CSS Color 4, each to the precision printed there (tolerance: half of the last
    /// digit; one digit for the §14.1.3 result, whose own input was rounded before printing).
    @Test("conversions give the examples printed in CSS Color 4")
    func specExamples() {
        // §7: sRGB blue is oklch(0.452 0.313 264.1), sRGB yellow oklch(0.968 0.211 109.8).
        let blue = OKLCH(sRGB("#0000FF"))
        #expect(near(blue.l, 0.452, 0.0005) && near(blue.c, 0.313, 0.0005) && hueDistance(blue.h, 264.1) <= 0.05)
        let yellow = OKLCH(sRGB("#FFFF00"))
        #expect(near(yellow.l, 0.968, 0.0005) && near(yellow.c, 0.211, 0.0005))
        #expect(hueDistance(yellow.h, 109.8) <= 0.05)

        // §14.1.3: color(display-p3 1 1 0) is color(srgb 1 1 -0.3463), which is oklch(0.96476 0.24503 110.23);
        // oklch(0.96476 0.21094 110.23) is color(srgb 0.99116 0.99733 0.00001).
        let p3Yellow = RGB(.displayP3, red: 1, green: 1, blue: 0)
        #expect(near(p3Yellow.converted(to: .sRGB), (1, 1, -0.3463), 0.00005))
        let p3YellowLCH = OKLCH(p3Yellow)
        #expect(near(p3YellowLCH.l, 0.96476, 0.000005) && near(p3YellowLCH.c, 0.24503, 0.000005))
        #expect(hueDistance(p3YellowLCH.h, 110.23) <= 0.005)
        #expect(near(RGB(OKLCH(l: 0.96476, c: 0.21094, h: 110.23), in: .sRGB), (0.99116, 0.99733, 0.00001), 0.00001))

        // §14.2: oklch(76% 0.27 60) in Display P3 is color(display-p3 1.062 0.4954 -0.3115) before gamut mapping.
        #expect(near(RGB(OKLCH(l: 0.76, c: 0.27, h: 60), in: .displayP3), (1.062, 0.4954, -0.3115), 0.0005))
    }

    @Test("conversions round-trip")
    func roundTrips() {
        let levels = stride(from: 0.0, through: 1.0, by: 0.125)
        for red in levels {
            for green in levels {
                for blue in levels {
                    for space in RGBSpace.allCases {
                        let color = RGB(space, red: red, green: green, blue: blue, alpha: 0.5)
                        let back = RGB(OKLCH(color), in: space)
                        #expect(near(back, (red, green, blue), 1e-12) && back.alpha == 0.5, "\(color) → \(back)")
                        let other = color.converted(to: space == .sRGB ? .displayP3 : .sRGB)
                        #expect(near(other.converted(to: space), (red, green, blue), 1e-12), "\(color) via \(other)")
                    }
                }
            }
        }
        // Out of gamut, through the extended transfer function.
        let outside = RGB(.sRGB, red: -0.2, green: 1.3, blue: 0.5)
        #expect(near(RGB(OKLab(outside), in: .sRGB), (-0.2, 1.3, 0.5), 1e-12))
        let lch = OKLCH(l: 0.7, c: 0.15, h: 200)
        let back = OKLCH(OKLab(lch))
        #expect(near(back.l, 0.7, 1e-15) && near(back.c, 0.15, 1e-15) && hueDistance(back.h, 200) <= 1e-12)
    }

    @Test("a hue is missing when the chroma is at most 0.000004, and a missing hue reads as 0")
    func powerlessHue() {
        for hex in ["#000000", "#808080", "#FFFFFF", "#1F1F1F"] {
            let gray = OKLCH(sRGB(hex))
            #expect(gray.h == nil && gray.c == 0, "\(hex): \(gray)")
        }
        let atEpsilon = OKLCH(OKLab(l: 0.5, a: 0.000004, b: 0))
        #expect(atEpsilon.h == nil && atEpsilon.c == 0)
        let aboveEpsilon = OKLCH(OKLab(l: 0.5, a: 0, b: -0.00001))
        #expect(aboveEpsilon.h == 270 && aboveEpsilon.c == 0.00001)

        // §9.6: a missing hue is 0, so with chroma it points along +a.
        #expect(OKLab(OKLCH(l: 0.5, c: 0.1, h: nil)) == OKLab(l: 0.5, a: 0.1, b: 0))
        #expect(OKLab(OKLCH(l: 0.5, c: 0, h: nil)) == OKLab(l: 0.5, a: 0, b: 0))
    }

    @Test("hues are in 0..<360 and alpha passes through every conversion")
    func huesAndAlpha() {
        let pink = OKLCH(sRGB("#C64C88"))
        #expect(pink.h.map { $0 > 352 && $0 < 353 } == true)
        let translucent = RGB(.displayP3, red: 0.2, green: 0.4, blue: 0.6, alpha: 0.25)
        #expect(OKLCH(translucent).alpha == 0.25)
        #expect(XYZ(LinearRGB(translucent)).alpha == 0.25)
        #expect(translucent.converted(to: .sRGB).alpha == 0.25)
        #expect(RGB(OKLCH(l: 0.5, c: 0.1, h: 30, alpha: 0.4), in: .sRGB).alpha == 0.4)
    }
}
