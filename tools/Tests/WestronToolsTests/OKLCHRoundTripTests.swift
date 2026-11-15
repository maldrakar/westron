import Testing
import WestronTools

@Suite("Hex to OkLCh and back")
struct OKLCHRoundTripTests {
    /// The pilot's hexes at L 4, C 5, H 2 decimals, from a separate Python implementation written from CSS Color 4
    /// and rounded with Python's `decimal` (ties away from zero). Exact strings: the closest of these components to a
    /// rounding tie is 0.00075 of a last digit away, far beyond any platform difference.
    static let pilot: [(hex: String, l: String, c: String, h: String?)] = [
        ("#FAF7F2", "0.9771", "0.00737", "80.72"), ("#1A1917", "0.2138", "0.00416", "84.59"),
        ("#FFFFFF", "1.0000", "0.00000", nil), ("#24221F", "0.2530", "0.00630", "78.21"),
        ("#F2EDE5", "0.9478", "0.01196", "79.78"), ("#1F1E1B", "0.2350", "0.00583", "91.61"),
        ("#F0EBE3", "0.9418", "0.01198", "79.78"), ("#2E2B27", "0.2908", "0.00836", "75.25"),
        ("#E8E2D8", "0.9147", "0.01494", "80.71"), ("#35322D", "0.3185", "0.00968", "80.66"),
        ("#1F1D1A", "0.2319", "0.00644", "78.20"), ("#EEEAE3", "0.9382", "0.01031", "81.79"),
        ("#625C53", "0.4776", "0.01609", "78.16"), ("#ABA498", "0.7212", "0.01886", "81.31"),
        ("#A39C90", "0.6952", "0.01902", "81.31"), ("#6F6A62", "0.5264", "0.01379", "79.74"),
        ("#C2362B", "0.5438", "0.17865", "28.86"), ("#F07468", "0.7019", "0.15514", "27.36"),
        ("#E0D9CC", "0.8873", "0.01915", "83.06"), ("#36332E", "0.3224", "0.00965", "80.66"),
        ("#3653C9", "0.4933", "0.18610", "268.19"), ("#E7EAF9", "0.9392", "0.02046", "276.95"),
        ("#3E6EC5", "0.5492", "0.14537", "261.23"), ("#D49408", "0.7114", "0.14711", "77.53"),
        ("#D2455A", "0.5939", "0.17643", "15.75"), ("#36925C", "0.5909", "0.12032", "154.31"),
        ("#8A847A", "0.6156", "0.01643", "80.68"), ("#5B55D8", "0.5315", "0.19429", "279.53"),
        ("#168985", "0.5712", "0.09380", "191.09"), ("#C64C88", "0.5963", "0.16696", "352.81"),
        ("#D7652C", "0.6365", "0.15905", "44.31"), ("#8452C8", "0.5518", "0.17724", "300.18"),
        ("#2A86B9", "0.5904", "0.11426", "238.01"),
    ]

    @Test("the pilot's hexes become OkLCh components that give back the same hex")
    func pilot() throws {
        #expect(Self.pilot.map(\.hex) == pilotHexes)
        let precision = OKLCHPrecision.hexRoundTrip
        for row in Self.pilot {
            let color = try OKLCH(hex: row.hex)
            #expect(DecimalFormat.fixed(color.l, decimals: precision.l) == row.l, "\(row.hex) L")
            #expect(DecimalFormat.fixed(color.c, decimals: precision.c) == row.c, "\(row.hex) C")
            #expect(color.h.map { DecimalFormat.fixed($0, decimals: precision.h) } == row.h, "\(row.hex) H")
            #expect(color.mapped(into: .sRGB).hex == row.hex)
            // The components as a token file would hold them, read back from text.
            let read = OKLCH(l: Double(row.l)!, c: Double(row.c)!, h: row.h.map { Double($0)! })
            #expect(read == color && read.mapped(into: .sRGB).hex == row.hex)
        }
    }

    /// All 16,777,216 colors take 26 s in a debug build, so they ran outside the suite: in a separate Python
    /// implementation and through this code in a release build. Here: every color on a grid of 18 levels per channel,
    /// every gray, every color with a channel at 0 or 255 and the others in steps of 5 (where the round trip is
    /// tightest), the color with the least margin (#09FF00), and the first failures of one decimal fewer.
    @Test("every color in the hardest regions round-trips")
    func coverage() throws {
        let grid = stride(from: 0, through: 255, by: 15)
        let steps = stride(from: 0, through: 255, by: 5)
        var colors: [(Int, Int, Int)] = []
        for a in grid { for b in grid { for c in grid { colors.append((a, b, c)) } } }
        for gray in 0...255 { colors.append((gray, gray, gray)) }
        for edge in [0, 255] {
            for a in steps {
                for b in steps { colors += [(edge, a, b), (a, edge, b), (a, b, edge)] }
            }
        }
        colors += [(0x09, 0xFF, 0x00), (0x00, 0xC5, 0xD5), (0x00, 0x00, 0xDA), (0x00, 0x00, 0xD5)]
        for (red, green, blue) in colors {
            let hex = RGB(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255).hex
            _ = try OKLCH(hex: hex)
        }
    }

    /// The colors the exhaustive search found first for one decimal fewer in a single component, with the other two
    /// at L 6, C 6, H 4.
    @Test(
        "one decimal fewer for any component loses a color",
        arguments: [
            ("#0000DA", OKLCHPrecision(l: 3, c: 6, h: 4)), ("#00C5D5", OKLCHPrecision(l: 6, c: 4, h: 4)),
            ("#0000D5", OKLCHPrecision(l: 6, c: 6, h: 1)),
        ])
    func minimal(hex: String, precision: OKLCHPrecision) throws {
        let error = #expect(throws: OKLCH.RoundTripError.self) { try OKLCH(hex: hex, precision: precision) }
        #expect(error?.hex == hex && error?.result != hex)
        _ = try OKLCH(hex: hex)
    }

    @Test("rounding keeps the hue in 0..<360, drops it with the chroma, and keeps alpha")
    func rounding() throws {
        let precision = OKLCHPrecision(l: 4, c: 5, h: 2)
        #expect(OKLCH(l: 0.5, c: 0.1, h: 359.996).rounded(to: precision).h == 0)
        #expect(OKLCH(l: 0.5, c: 0.000004, h: 120).rounded(to: precision) == OKLCH(l: 0.5, c: 0, h: nil))
        #expect(OKLCH(l: 0.5, c: 0.000006, h: 120).rounded(to: precision) == OKLCH(l: 0.5, c: 0.00001, h: 120))
        #expect(OKLCH(l: 0.123456, c: 0.1, h: nil, alpha: 0.3).rounded(to: precision).alpha == 0.3)
        let translucent = try OKLCH(hex: "#1F1D1A14")
        #expect(translucent.alpha == 20.0 / 255 && translucent.mapped(into: .sRGB).hex == "#1F1D1A14")
        #expect(throws: RGB.HexError.self) { try OKLCH(hex: "1F1D1A") }
    }
}
