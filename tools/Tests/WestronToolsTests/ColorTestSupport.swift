import Testing
import WestronTools

// Shared by the color tests. Reference values come from sources independent of the code under test, named at each
// table: examples printed in CSS Color 4 (CRD 2026-11-12), colorjs.io 0.5.2 (by the editors of CSS Color 4, cited
// by its §14.2.1 for gamut mapping), culori 4.0.1, Python's `decimal`, and WCAG and WebAIM published values.

/// The sRGB hexes of the pilot (todo-app) that become westron primitives.
let pilotHexes = """
    FAF7F2 1A1917 FFFFFF 24221F F2EDE5 1F1E1B F0EBE3 2E2B27 E8E2D8 35322D 1F1D1A EEEAE3 625C53 ABA498 A39C90 6F6A62
    C2362B F07468 E0D9CC 36332E 3653C9 E7EAF9 3E6EC5 D49408 D2455A 36925C 8A847A 5B55D8 168985 C64C88 D7652C 8452C8
    2A86B9
    """.split(whereSeparator: \.isWhitespace).map { "#" + $0 }

func sRGB(_ hex: String) -> RGB {
    // The tests' hexes are literals, so a malformed one is a mistake in the test.
    try! RGB(hex: hex)
}

/// Whether two numbers differ by at most `tolerance`.
func near(_ actual: Double, _ expected: Double, _ tolerance: Double) -> Bool {
    (actual - expected).magnitude <= tolerance
}

/// Whether every channel of `color` is within `tolerance` of the expected one.
func near(_ color: RGB, _ expected: (Double, Double, Double), _ tolerance: Double) -> Bool {
    near(color.red, expected.0, tolerance) && near(color.green, expected.1, tolerance)
        && near(color.blue, expected.2, tolerance)
}

/// The difference of two hue angles the short way round, across 0/360; infinite if only one is missing.
func hueDistance(_ first: Double?, _ second: Double?) -> Double {
    guard let first, let second else { return first == nil && second == nil ? 0 : .infinity }
    let difference = (first - second).magnitude.truncatingRemainder(dividingBy: 360)
    return Swift.min(difference, 360 - difference)
}
