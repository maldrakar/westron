import Foundation

// Hex notation of sRGB colors: `#rrggbb` and `#rrggbbaa`, as in CSS and in the `hex` fallback of a DTCG color.

extension RGB {
    /// A string that is not `#rrggbb` or `#rrggbbaa`.
    public struct HexError: Error, CustomStringConvertible {
        public let text: String

        public var description: String { "not a #rrggbb or #rrggbbaa color: \(text)" }
    }

    /// Parses `#rrggbb` or `#rrggbbaa`, in either case, as an sRGB color: each byte divided by 255.
    public init(hex: String) throws {
        func nibble(_ ascii: UInt8) -> Int? {
            switch ascii {
            case UInt8(ascii: "0")...UInt8(ascii: "9"): Int(ascii - UInt8(ascii: "0"))
            case UInt8(ascii: "a")...UInt8(ascii: "f"): Int(ascii - UInt8(ascii: "a")) + 10
            case UInt8(ascii: "A")...UInt8(ascii: "F"): Int(ascii - UInt8(ascii: "A")) + 10
            default: nil
            }
        }
        let utf8 = Array(hex.utf8)
        let nibbles = utf8.dropFirst().compactMap(nibble)
        guard utf8.first == UInt8(ascii: "#"), nibbles.count == utf8.count - 1, [6, 8].contains(nibbles.count) else {
            throw HexError(text: hex)
        }
        let bytes = stride(from: 0, to: nibbles.count, by: 2).map { Double(nibbles[$0] * 16 + nibbles[$0 + 1]) / 255 }
        self.init(.sRGB, red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes.count == 4 ? bytes[3] : 1)
    }

    /// The channels and alpha in 8 bits: each clamped to 0...1, multiplied by 255 and rounded, ties away from zero.
    public var bytes: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        func byte(_ value: Double) -> UInt8 { UInt8((Swift.min(Swift.max(value, 0), 1) * 255).rounded()) }
        return (byte(red), byte(green), byte(blue), byte(alpha))
    }

    /// `#RRGGBB`, or `#RRGGBBAA` when the alpha byte is under FF, in upper case as the pilot writes it; from `bytes`.
    /// Hex is sRGB notation, so the color must be sRGB: convert or map a Display P3 color first.
    public var hex: String {
        precondition(space == .sRGB, "hex notation is sRGB; this color is \(space.rawValue)")
        let (red, green, blue, alpha) = bytes
        let digits = (alpha == 255 ? [red, green, blue] : [red, green, blue, alpha]).map { byte in
            let text = String(byte, radix: 16, uppercase: true)
            return text.count == 1 ? "0" + text : text
        }
        return "#" + digits.joined()
    }
}
