import Testing
import WestronTools

@Suite("WCAG contrast")
struct ContrastTests {
    @Test("the ends of the scale and the published examples")
    func knownValues() {
        let white = sRGB("#FFFFFF")
        let black = sRGB("#000000")
        #expect(WCAG.relativeLuminance(white) == 1)
        #expect(WCAG.relativeLuminance(black) == 0)
        #expect(WCAG.contrastRatio(of: white, on: black) == 21)
        #expect(WCAG.contrastRatio(of: black, on: white) == 21)
        #expect(WCAG.contrastRatio(of: sRGB("#3653C9"), on: sRGB("#3653C9")) == 1)
        // WebAIM's contrast checker: #767676 on white is 4.54:1, the lightest gray that passes AA; #777777 is 4.48:1.
        // Published to two decimals, so the tolerance is 0.005.
        #expect(near(WCAG.contrastRatio(of: sRGB("#767676"), on: white), 4.54, 0.005))
        #expect(near(WCAG.contrastRatio(of: sRGB("#777777"), on: white), 4.48, 0.005))
    }

    /// culori 4.0.1, `wcagLuminance`, tolerance 1e-12.
    @Test(
        "relative luminance matches culori",
        arguments: [
            ("#D49408", 0.35194389461426778), ("#808080", 0.21586050011389923), ("#3653C9", 0.11187828937555630),
        ])
    func luminance(hex: String, expected: Double) {
        #expect(near(WCAG.relativeLuminance(sRGB(hex)), expected, 1e-12))
    }

    /// The pilot's own note (todo-app, `CheckColorTests.amberAloneDrawsItsMarkInInk`): white's contrast on amber's
    /// fill is 2.61 in the light (#D49408) and 2.41 in the dark (#D79D1C), under the canvas's 3, so amber alone draws
    /// its check mark in ink; the next lowest, dark stone (#938E85) and dark orange (#DA713D), come to 3.26 and 3.28.
    /// Two decimals there, so the tolerance is 0.005; the full values are culori 4.0.1's `wcagContrast`, within 1e-9.
    @Test("white on the pilot's amber is 2.61, under the 3 its check mark rule relies on")
    func pilotAmber() {
        let white = sRGB("#FFFFFF")
        let notes: [(String, Double, Double)] = [
            ("#D49408", 2.61, 2.6123048865007648), ("#D79D1C", 2.41, 2.4057818464235292),
            ("#938E85", 3.26, 3.2565711712577952), ("#DA713D", 3.28, 3.2758650208183089),
        ]
        for (fill, note, culori) in notes {
            let contrast = WCAG.contrastRatio(of: white, on: sRGB(fill))
            #expect(near(contrast, note, 0.005) && near(contrast, culori, 1e-9), "\(fill): \(contrast)")
        }
        // The eleven list colors' light fills: white is under 3 on amber alone.
        let fills = [
            "#3E6EC5", "#D49408", "#D2455A", "#36925C", "#8A847A", "#5B55D8", "#168985", "#C64C88", "#D7652C",
            "#8452C8", "#2A86B9",
        ]
        #expect(fills.filter { WCAG.contrastRatio(of: white, on: sRGB($0)) < 3 } == ["#D49408"])
    }

    /// culori 4.0.1, `wcagContrast`, tolerance 1e-9: the pilot's text colors on its backgrounds.
    @Test(
        "the pilot's text on its backgrounds matches culori",
        arguments: [
            ("#1F1D1A", [15.734563541301000, 16.814481290022094, 14.428868604288779]),
            ("#625C53", [6.1891815694439627, 6.6139665982346232, 5.6755872127743050]),
            ("#A39C90", [2.5470130282380090, 2.7218233792336530, 2.3356552739065815]),
            ("#C2362B", [5.0957313103917752, 5.4454690498823792, 4.6728742953313462]),
            ("#3653C9", [6.0697655856891375, 6.4863546807318215, 5.5660806774117244]),
            ("#EEEAE3", [14.651615958295164, 13.231813937865430, 13.902055065509099]),
            ("#ABA498", [7.1068638165573352, 6.4181793987846794, 6.7432843177218000]),
            ("#6F6A62", [3.2742653508932782, 2.9569755329063843, 3.1067574618918243]),
            ("#F07468", [6.1932679379733884, 5.5931147291787688, 5.8764270203528044]),
        ])
    func pilotText(text: String, expected: [Double]) {
        let light = ["#1F1D1A", "#625C53", "#A39C90", "#C2362B", "#3653C9"].contains(text)
        let backgrounds = light ? ["#FAF7F2", "#FFFFFF", "#F2EDE5"] : ["#1A1917", "#24221F", "#1F1E1B"]
        for (background, value) in zip(backgrounds, expected) {
            let contrast = WCAG.contrastRatio(of: sRGB(text), on: sRGB(background))
            #expect(near(contrast, value, 1e-9), "\(text) on \(background): \(contrast)")
        }
    }

    /// culori 4.0.1, `blend([background, foreground], "normal")` and `wcagContrast` of the result on the background;
    /// tolerance 1e-12 for channels and 1e-9 for contrast.
    @Test(
        "a translucent color is composited over its background before the contrast",
        arguments: [
            (
                "#1F1D1A", 0.08, "#FAF7F2", (0.91168627450980388, 0.90023529411764713, 0.88125490196078438),
                1.1696311420952512
            ),
            (
                "#FFFFFF", 0.08, "#1A1917", (0.17380392156862745, 0.17019607843137255, 0.16298039215686275),
                1.2487760782500246
            ),
            (
                "#3653C9", 0.12, "#FFFFFF", (0.90541176470588236, 0.91905882352941182, 0.97458823529411764),
                1.1954990029690458
            ),
            (
                "#3E6EC5", 0.15, "#FAF7F2", (0.86980392156862740, 0.88803921568627453, 0.92254901960784308),
                1.2108223099397064
            ),
            (
                "#3E6EC5", 0.24, "#1A1917", (0.13584313725490196, 0.17803921568627451, 0.25396078431372549),
                1.2778513309679824
            ),
        ])
    func composited(
        foreground: String, alpha: Double, background: String, expected: (Double, Double, Double), contrast: Double
    ) {
        var color = sRGB(foreground)
        color.alpha = alpha
        let result = color.composited(over: sRGB(background))
        #expect(result.alpha == 1 && near(result, expected, 1e-12), "\(result)")
        #expect(near(WCAG.contrastRatio(of: color, on: sRGB(background)), contrast, 1e-9))
        #expect(
            WCAG.contrastRatio(of: color, on: sRGB(background)) == WCAG.contrastRatio(of: result, on: sRGB(background)))
    }

    @Test("compositing over a translucent backdrop and across spaces")
    func compositingRules() {
        // culori 4.0.1: #C2362B at 50 % over #3653C9 at 50 %.
        var red = sRGB("#C2362B")
        red.alpha = 0.5
        var blue = sRGB("#3653C9")
        blue.alpha = 0.5
        let result = red.composited(over: blue)
        #expect(near(result, (0.57777777777777772, 0.24967320261437909, 0.37516339869281046), 1e-12))
        #expect(result.alpha == 0.75)
        // Opaque over anything is itself; transparent over transparent stays transparent.
        #expect(sRGB("#3653C9").composited(over: sRGB("#FAF7F2")) == sRGB("#3653C9"))
        #expect(
            RGB(.sRGB, red: 1, green: 0, blue: 0, alpha: 0).composited(
                over: RGB(.sRGB, red: 0, green: 0, blue: 1, alpha: 0)
            ).alpha == 0)
        // A Display P3 color is converted into the background's space first.
        let p3 = RGB(.displayP3, red: 0.5, green: 0.5, blue: 0.5)
        #expect(p3.composited(over: sRGB("#FFFFFF")) == p3.converted(to: .sRGB))
        // culori 4.0.1: Display P3 white has relative luminance 1.
        #expect(near(WCAG.relativeLuminance(RGB(.displayP3, red: 1, green: 1, blue: 1)), 1, 1e-12))
    }
}
