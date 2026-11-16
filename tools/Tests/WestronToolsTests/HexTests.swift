import Testing
import WestronTools

@Suite("Hex colors")
struct HexTests {
    @Test("parses #rrggbb and #rrggbbaa in either case")
    func parses() throws {
        #expect(try RGB(hex: "#D49408") == RGB(.sRGB, red: 212.0 / 255, green: 148.0 / 255, blue: 8.0 / 255))
        #expect(try RGB(hex: "#d49408") == RGB(hex: "#D49408"))
        #expect(
            try RGB(hex: "#1F1D1A14")
                == RGB(.sRGB, red: 31.0 / 255, green: 29.0 / 255, blue: 26.0 / 255, alpha: 20.0 / 255))
        #expect(try RGB(hex: "#00000000").alpha == 0)
        #expect(try RGB(hex: "#FFFFFFFF") == RGB(.sRGB, red: 1, green: 1, blue: 1))
    }

    @Test(
        "rejects anything else",
        arguments: [
            "D49408", "#D4940", "#D494081", "#D49408FFF", "#FFF", "#GG0000", "#+F0000",
            " #D49408", "#D49408 ", "", "#", "#D4 408",
        ])
    func rejects(text: String) {
        let error = #expect(throws: RGB.HexError.self) { try RGB(hex: text) }
        #expect(error?.text == text)
    }

    @Test("formats in upper case, with alpha only when it is under FF")
    func formats() {
        for hex in pilotHexes {
            #expect(sRGB(hex).hex == hex)
        }
        #expect(sRGB("#3e6ec5").hex == "#3E6EC5")
        #expect(sRGB("#1F1D1A14").hex == "#1F1D1A14")
        #expect(RGB(.sRGB, red: 1, green: 1, blue: 1, alpha: 0.08).hex == "#FFFFFF14")
        #expect(RGB(.sRGB, red: 0, green: 0, blue: 0, alpha: 0.999).hex == "#000000")
    }

    @Test("rounds each channel to the nearest byte, ties away from zero, after clamping to 0...1")
    func roundsToBytes() {
        // 127.5 / 255 is a tie: up to 128. Just under the tie stays at 127.
        #expect(RGB(.sRGB, red: 127.5 / 255, green: 127.49 / 255, blue: 0.5 / 255).bytes == (128, 127, 1, 255))
        #expect(RGB(.sRGB, red: -0.2, green: 1.3, blue: 0.0019, alpha: 1.5).bytes == (0, 255, 0, 255))
        #expect(RGB(.sRGB, red: 0.002, green: 0.998, blue: 0.5).hex == "#01FE80")
        for byte in 0...255 {
            let value = Double(byte) / 255
            #expect(RGB(.sRGB, red: value, green: value, blue: value).bytes.red == UInt8(byte))
        }
    }
}
