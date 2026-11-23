// Button's floating look by its pixels (#121, decisions/0015), on the snapshot matrix's own sheets, drawn in-process as
// the matrix draws them (SnapshotRenderer): what the accessibility audit does not see, since it never reports an
// icon-only button, and what no pure function shows, the order of the glass and the disabled opacity.
// macOS only, in every `swift test`: on iOS the renderer needs the catalog app's window scene, and the catalog's hosted
// bundle runs only the matrix's render (WESTRON_SNAPSHOTS), where these are off as FieldHeightsTests are.
#if os(macOS)

    import CoreGraphics
    import Foundation
    import SwiftUI
    import Testing
    import WestronUI

    @testable import WestronCatalog

    @Suite("Button floating, by its pixels", .enabled(if: snapshotOutput == nil), .serialized)
    @MainActor
    struct ButtonFloatingPixelTests {
        /// A sheet drawn once in a capture: its picture, cut to the sheet, and the frame of each cell in the picture's
        /// points.
        struct Drawn {
            let image: CGImage
            let scale: CGFloat
            let cells: [ComponentMatrix.Combination: CGRect]
            let bytes: [UInt8]

            /// The pixel at a point of the picture, 8-bit sRGB.
            func color(_ point: CGPoint) -> (red: Int, green: Int, blue: Int)? {
                let column = Int((point.x * scale).rounded(.down))
                let row = Int((point.y * scale).rounded(.down))
                guard (0..<image.width).contains(column), (0..<image.height).contains(row) else { return nil }
                let index = (row * image.width + column) * 4
                return (Int(bytes[index]), Int(bytes[index + 1]), Int(bytes[index + 2]))
            }
        }

        static func draw(_ key: String, theme: ComponentMatrix.Theme) async throws -> Drawn {
            let probe = MatrixSheetProbe()
            let capture = ComponentMatrix.Capture(theme: theme, textSize: .large)
            let window = try SnapshotRenderer.show(
                try SnapshotRenderer.view(key: key, capture: capture, probe: probe), dark: theme.isDark)
            defer { SnapshotRenderer.hide(window) }
            await SnapshotRenderer.pause(0.5)
            let result = try SnapshotRenderer.draw(window, probe: probe)
            guard case .success(let draw) = result else {
                throw SnapshotRenderError.noImage("\(key), \(theme.rawValue): \(result)")
            }
            let image = draw.image
            let scale = CGFloat(image.width) / draw.size.width
            // The picture starts at the sheet's top: the cells' frames are in the window's points.
            let top = max(0, draw.sheet.minY)
            let cells = probe.cells.mapValues { $0.offsetBy(dx: 0, dy: -top) }
            let context = try #require(SnapshotRenderer.context(width: image.width, height: image.height, alpha: true))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            let data = try #require(context.data)
            let bytes = Array(
                UnsafeBufferPointer(
                    start: data.assumingMemoryBound(to: UInt8.self), count: image.width * image.height * 4))
            return Drawn(image: image, scale: scale, cells: cells, bytes: bytes)
        }

        /// WCAG 2's relative luminance of an 8-bit sRGB color.
        static func luminance(_ color: (red: Int, green: Int, blue: Int)) -> Double {
            func linear(_ channel: Int) -> Double {
                let value = Double(channel) / 255
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
        }

        static func ratio(_ a: (red: Int, green: Int, blue: Int), _ b: (red: Int, green: Int, blue: Int)) -> Double {
            let (x, y) = (luminance(a), luminance(b))
            return (max(x, y) + 0.05) / (min(x, y) + 0.05)
        }

        static func ratio(_ a: Westron.RGB, _ b: Westron.RGB) -> Double {
            func byte(_ value: Double) -> Int { Int((value * 255).rounded()) }
            return ratio((byte(a.red), byte(a.green), byte(a.blue)), (byte(b.red), byte(b.green), byte(b.blue)))
        }

        static func distance(_ a: (red: Int, green: Int, blue: Int), _ b: (red: Int, green: Int, blue: Int)) -> Double {
            let (r, g, b) = (Double(a.red - b.red), Double(a.green - b.green), Double(a.blue - b.blue))
            return (r * r + g * g + b * b).squareRoot()
        }

        /// The icon-only samples where there is no glass, the generated sheet of size m: a floating primary's glyph on its
        /// accent fill and a floating secondary's on the surface. The audit never reports an icon-only button, so this is
        /// what measures them: the glyph's darkest or lightest pixel against the fill reaches the non-text target of the
        /// theme (WCAG 1.4.11: 3:1, 4.5:1 in the high-contrast themes) and, so that the glyph is drawn in its token, at
        /// least 90 % of the ratio of the two tokens, which `tools/westron tokens contrast` checks as a declared pair.
        @Test(
            "an icon-only floating button's glyph reaches its declared contrast, primary and before OS 26 secondary",
            arguments: ComponentMatrix.Theme.allCases)
        func iconOnlyGlyphContrast(theme: ComponentMatrix.Theme) async throws {
            let drawn = try await Self.draw("button.size-m_role-default_iconOnly-true_floating-true", theme: theme)
            let westronTheme = try #require(Westron.Theme(rawValue: theme.rawValue))
            let samples: [(variant: String, ink: Westron.Color, fill: Westron.Color)] = [
                ("primary", .text.onAccent, .background.accent), ("secondary", .text.primary, .background.surface),
            ]
            for sample in samples {
                let combination = ComponentMatrix.Combination(
                    [sample.variant, "m", "default", "true", "true"], state: nil)
                let frame = try #require(drawn.cells[combination], "no cell \(sample.variant)")
                // The fill near the circle's top, clear of the glyph; the ink, the pixel of the middle that stands out most.
                let fill = try #require(drawn.color(CGPoint(x: frame.midX, y: frame.minY + frame.height * 0.15)))
                var ink = fill
                var stride: CGFloat = 0
                let reach = frame.height * 0.25
                while stride <= 2 * reach {
                    var across: CGFloat = 0
                    while across <= 2 * reach {
                        let point = CGPoint(x: frame.midX - reach + across, y: frame.midY - reach + stride)
                        if let pixel = drawn.color(point), Self.ratio(pixel, fill) > Self.ratio(ink, fill) {
                            ink = pixel
                        }
                        across += 0.5 / drawn.scale * 2
                    }
                    stride += 0.5 / drawn.scale * 2
                }
                let measured = Self.ratio(ink, fill)
                let declared = Self.ratio(sample.ink[westronTheme], sample.fill[westronTheme])
                let target = theme.rawValue.hasSuffix("-hc") ? 4.5 : 3
                print(
                    String(
                        format: "MEASURE icon-only %@ %@: glyph %.2f:1, tokens %.2f:1", sample.variant, theme.rawValue,
                        measured, declared))
                #expect(measured >= target, "\(sample.variant), \(theme.rawValue): \(measured)")
                #expect(measured >= declared * 0.9, "\(sample.variant), \(theme.rawValue): \(measured) of \(declared)")
            }
        }

        /// The disabled opacity is laid outside the glass, so a disabled floating secondary dims its glass too
        /// (decisions/0015, the contract's description): over the inverse band, a plain ground, the disabled glass stands
        /// at most about the opacity's share as far from the band as the glass at rest does.
        @Test("a disabled floating secondary dims its glass with it", arguments: ComponentMatrix.Theme.allCases)
        func disabledDimsTheGlass(theme: ComponentMatrix.Theme) async throws {
            guard #available(iOS 26, macOS 26, *) else { return }
            let drawn = try await Self.draw(
                "button.floating-on-glass-inverse_size-m_role-default_iconOnly-true_floating-true", theme: theme)
            func cell(_ state: String?) throws -> CGRect {
                let combination = ComponentMatrix.Combination(
                    ["secondary", "m", "default", "true", "true"], state: state)
                return try #require(drawn.cells[combination], "no cell \(state ?? "rest")")
            }
            let rest = try cell(nil)
            let disabled = try cell("disabled")
            // The panel pads the button by space.200 on the band: the band at the panel's left, the glass near the top of
            // the circle, clear of the glyph.
            func band(_ frame: CGRect) throws -> (red: Int, green: Int, blue: Int) {
                try #require(drawn.color(CGPoint(x: frame.minX + 6, y: frame.midY)))
            }
            func glass(_ frame: CGRect) throws -> (red: Int, green: Int, blue: Int) {
                let side = CGFloat(Westron.Dimension.size.control.m)
                return try #require(drawn.color(CGPoint(x: frame.midX, y: frame.midY - side * 0.35)))
            }
            let ground = try band(rest)
            let atRest = Self.distance(try glass(rest), ground)
            let dimmed = Self.distance(try glass(disabled), try band(disabled))
            print(
                String(
                    format: "MEASURE glass %@: at rest %.1f from the band, disabled %.1f", theme.rawValue, atRest,
                    dimmed))
            #expect(atRest > 30, "the glass stands off the band at rest: \(atRest)")
            #expect(dimmed < atRest * 0.7, "\(theme.rawValue): disabled \(dimmed), at rest \(atRest)")
        }

        /// Q5's test (decisions/0015): text.primary, the label and the glyph of a floating secondary at rest, on the
        /// system's glass over the inverse band, dark in the light themes and light in the dark ones, and over the busy
        /// stripes. The ink is the pixels of the capsule's middle within 60 levels of text.primary; the glass every other
        /// pixel there. It prints the ink against the glass's median and against its 5 % nearest the ink, and holds the
        /// label to text's target against the median (4.5:1, 7:1 in the high-contrast themes) over the inverse band, the
        /// ground the question names; over the stripes the numbers are recorded in the decision.
        ///
        /// It holds the supplement's cell, a band only space.200 wider than the button, and that is not the whole of Q5:
        /// on the catalog page, over a wider band, the glass on iOS 26.3 turns otherwise, and in the dark theme the label
        /// reads at 3.8:1 there (decisions/0015, "Q5's test"). A pass here says the supplement's picture holds, not that
        /// text.primary does on glass over any light ground.
        @Test(
            "text.primary on glass over the inverse band and the stripes, by pixels",
            arguments: ComponentMatrix.Theme.allCases, ["floating-on-glass-inverse", "floating-on-glass"])
        func labelOnGlass(theme: ComponentMatrix.Theme, supplement: String) async throws {
            guard #available(iOS 26, macOS 26, *) else { return }
            let westronTheme = try #require(Westron.Theme(rawValue: theme.rawValue))
            let ink = Westron.Color.text.primary[westronTheme]
            func byte(_ value: Double) -> Int { Int((value * 255).rounded()) }
            let inkColor = (red: byte(ink.red), green: byte(ink.green), blue: byte(ink.blue))
            let target = theme.rawValue.hasSuffix("-hc") ? 7.0 : 4.5
            for iconOnly in ["false", "true"] {
                let drawn = try await Self.draw(
                    "button.\(supplement)_size-m_role-default_iconOnly-\(iconOnly)_floating-true", theme: theme)
                let combination = ComponentMatrix.Combination(
                    ["secondary", "m", "default", iconOnly, "true"], state: nil)
                let panel = try #require(drawn.cells[combination], "no cell")
                let capsule = panel.insetBy(dx: CGFloat.space200, dy: CGFloat.space200)
                // The middle of the capsule, clear of its round ends and its edge.
                let middle =
                    iconOnly == "true"
                    ? capsule.insetBy(dx: capsule.height * 0.2, dy: capsule.height * 0.2)
                    : capsule.insetBy(dx: capsule.height / 2, dy: capsule.height * 0.12)
                var inkPixels: [(red: Int, green: Int, blue: Int)] = []
                var glass: [Double] = []
                let step = 1 / drawn.scale
                var y = middle.minY
                while y < middle.maxY {
                    var x = middle.minX
                    while x < middle.maxX {
                        if let pixel = drawn.color(CGPoint(x: x, y: y)) {
                            if Self.distance(pixel, inkColor) < 60 {
                                inkPixels.append(pixel)
                            } else {
                                glass.append(Self.luminance(pixel))
                            }
                        }
                        x += step
                    }
                    y += step
                }
                try #require(!inkPixels.isEmpty && !glass.isEmpty, "no ink or no glass in \(middle)")
                let inkLuminance = inkPixels.map(Self.luminance).reduce(0, +) / Double(inkPixels.count)
                let median = glass.sorted()[glass.count / 2]
                // The glass's 5 % whose luminance is nearest the ink's: the worst ground under the label.
                let nearest = glass.sorted { abs($0 - inkLuminance) < abs($1 - inkLuminance) }
                let worst = nearest[min(nearest.count - 1, nearest.count / 20)]
                func contrast(_ a: Double, _ b: Double) -> Double { (max(a, b) + 0.05) / (min(a, b) + 0.05) }
                let onMedian = contrast(inkLuminance, median)
                let onWorst = contrast(inkLuminance, worst)
                print(
                    String(
                        format:
                            "MEASURE %@ %@ %@: text.primary on glass %.2f:1 against its median, %.2f:1 against its worst 5 %%",
                        supplement, iconOnly == "true" ? "glyph" : "label", theme.rawValue, onMedian, onWorst))
                if supplement == "floating-on-glass-inverse" {
                    #expect(onMedian >= target, "\(theme.rawValue), iconOnly \(iconOnly): \(onMedian)")
                }
            }
        }
    }
#endif
