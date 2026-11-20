import CoreText
import SwiftUI
import Testing
import WestronUI

#if os(macOS)
    import AppKit
#endif

/// The SwiftUI side of the tokens against WestronTokens: the colorsets, the fonts, the animations and the lengths.
@Suite("Token accessors")
@MainActor
struct TokenAccessorTests {
    /// SwiftUI's environment in a theme: its color scheme and its contrast.
    static func environment(_ theme: Westron.Theme) -> EnvironmentValues {
        var environment = EnvironmentValues()
        environment.colorScheme = theme.isDark ? .dark : .light
        environment._colorSchemeContrast = theme.isHighContrast ? .increased : .standard
        return environment
    }

    /// Whether two resolved colors are within one 8-bit step in every channel and in opacity.
    static func close(_ first: Color.Resolved, _ second: Color.Resolved) -> Bool {
        let step: Float = 1 / 255
        return abs(first.red - second.red) <= step && abs(first.green - second.green) <= step
            && abs(first.blue - second.blue) <= step && abs(first.opacity - second.opacity) <= step
    }

    /// A WestronTokens color as SwiftUI resolves it, built without the adapter under test.
    static func resolved(_ rgb: Westron.RGB) -> Color.Resolved {
        Color.Resolved(
            colorSpace: rgb.space == .sRGB ? .sRGB : .displayP3, red: Float(rgb.red), green: Float(rgb.green),
            blue: Float(rgb.blue), opacity: Float(rgb.opacity))
    }

    @Test("every colorset resolves to the WestronTokens value of the theme", arguments: Westron.Theme.allCases)
    func colorsets(theme: Westron.Theme) {
        let environment = Self.environment(theme)
        #expect(!Westron.Color.all.isEmpty)
        for token in Westron.Color.all {
            let actual = Color(token).resolve(in: environment)
            let expected = Self.resolved(token[theme])
            #expect(Self.close(actual, expected), "\(token.name) in \(theme.rawValue): \(actual), expected \(expected)")
        }
    }

    @Test("the list of colors holds every semantic color once, the list colors included")
    func colorList() {
        let names = Westron.Color.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(names.contains(Westron.Color.text.secondary.name))
        for category in Westron.Category.allCases {
            #expect(category.colors.allSatisfy { names.contains($0.name) })
        }
    }

    @Test("the backgrounds a foreground declares are semantic colors; every text color declares one")
    func declaredBackgrounds() {
        let names = Set(Westron.Color.all.map(\.name))
        for color in Westron.Color.all {
            for name in color.backgrounds.joined() {
                #expect(names.contains(name), "\(color.name) is declared on \(name), which is no semantic color")
            }
        }
        #expect(Westron.Color.text.secondary.backgrounds.first == ["color.background.canvas"])
        #expect(Westron.Color.all.filter { $0.name.hasPrefix("color.text.") }.allSatisfy { !$0.backgrounds.isEmpty })
        #expect(Westron.Color.background.canvas.backgrounds.isEmpty)
    }

    @Test("a theme switches the color: the canvas differs in each theme")
    func themesSwitch() {
        let canvas = Westron.Theme.allCases.map { theme in
            Color(.text.secondary).resolve(in: Self.environment(theme))
        }
        #expect(!Self.close(canvas[0], canvas[1]))
        #expect(!Self.close(canvas[0], canvas[2]))
        #expect(!Self.close(canvas[1], canvas[3]))
    }

    @Test("a color of one theme converts its channels")
    func rgb() {
        let environment = Self.environment(.light)
        let accent = Westron.RGB(hex: 0x3653C9, opacity: 0.5)
        #expect(Self.close(Color(accent).resolve(in: environment), Self.resolved(accent)))
        let green = Westron.RGB(.displayP3, red: 0, green: 1, blue: 0)
        let resolved = Color(green).resolve(in: environment)
        #expect(Self.close(resolved, Self.resolved(green)))
        #expect(resolved.green > 1, "a Display P3 green is outside sRGB")
    }

    /// The color of the middle pixel of a view drawn in a theme, in 8-bit sRGB.
    static func pixel(of view: some View, theme: Westron.Theme) -> Color.Resolved? {
        let renderer = ImageRenderer(
            content: view.frame(width: 4, height: 4)
                .environment(\.colorScheme, theme.isDark ? .dark : .light)
                .environment(\._colorSchemeContrast, theme.isHighContrast ? .increased : .standard))
        renderer.scale = 1
        guard let image = renderer.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var bytes = [UInt8](repeating: 0, count: 4)
        guard
            let context = CGContext(
                data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.draw(image, in: CGRect(x: -2, y: -2, width: image.width, height: image.height))
        return Color.Resolved(
            colorSpace: .sRGB, red: Float(bytes[0]) / 255, green: Float(bytes[1]) / 255, blue: Float(bytes[2]) / 255,
            opacity: Float(bytes[3]) / 255)
    }

    @Test(
        "a westron color reaches SwiftUI's modifiers through the overloads, in every theme",
        arguments: Westron.Theme.allCases)
    func modifierOverloads(theme: Westron.Theme) throws {
        let token = Westron.Color.background.accent
        let views: [(String, AnyView)] = [
            ("fill", AnyView(Rectangle().fill(.background.accent))),
            ("foregroundStyle", AnyView(Rectangle().foregroundStyle(.background.accent))),
            ("background", AnyView(Color.clear.background(.background.accent))),
            ("background(_:in:)", AnyView(Color.clear.background(.background.accent, in: Rectangle()))),
            ("strokeBorder", AnyView(Rectangle().strokeBorder(.background.accent, lineWidth: .space50))),
        ]
        let expected = Self.resolved(token[theme])
        for (name, view) in views {
            let pixel = try #require(Self.pixel(of: view, theme: theme), "\(name) drew nothing")
            let step: Float = 2 / 255
            #expect(
                abs(pixel.red - expected.red) <= step && abs(pixel.green - expected.green) <= step
                    && abs(pixel.blue - expected.blue) <= step,
                "\(name) in \(theme.rawValue): \(pixel), expected \(expected)")
        }
    }

    @Test("SwiftUI's own styles keep their names next to westron's groups")
    func systemStylesStay() {
        // `.background` is SwiftUI's BackgroundStyle and `.red` its Color; `.background.canvas` is westron's. The
        // test is that this compiles without ambiguity.
        _ = Text("a").foregroundStyle(.background)
        _ = Text("a").foregroundStyle(.red)
        _ = Text("a").foregroundStyle(.background.canvas)
        _ = Rectangle().fill(.background.secondary)
        _ = Text("a").foregroundStyle(.text.primary) + Text("b").foregroundStyle(.text.secondary)
    }

    @Test("a list color is found by its name, and each role is its colorset")
    func categories() {
        #expect(
            Westron.Category.allCases.map(\.rawValue) == [
                "blue", "sky", "teal", "emerald", "green", "olive", "amber", "orange", "red", "pink", "violet",
                "indigo",
            ])
        #expect(Westron.Category(rawValue: "amber") == .amber)
        #expect(Westron.Category.amber.text.name == "color.category.amber.text")
        for theme in Westron.Theme.allCases {
            let environment = Self.environment(theme)
            for category in Westron.Category.allCases {
                #expect(category.colors.count == 8)
                for token in category.colors {
                    #expect(
                        Self.close(Color(token).resolve(in: environment), Self.resolved(token[theme])),
                        "\(token.name) in \(theme.rawValue)")
                }
            }
        }
    }

    @Test("a heading is Onest and code Geist Mono, in their text styles; other roles are the system font")
    func fonts() {
        #expect(Westron.TextRole.heading.large.font == "Onest-Bold")
        #expect(Westron.TextRole.heading.small.font == "Onest-SemiBold")
        #expect(Westron.TextRole.code.regular.font == "GeistMono-Regular")
        // At the text style's size on this platform, as the system font: the Mac's sizes are smaller than iOS's.
        #if os(macOS)
            let large = NSFont.preferredFont(forTextStyle: .largeTitle).pointSize
        #else
            let large = CGFloat(34)
        #endif
        #expect(Font(.heading.large) == .custom("Onest-Bold", size: large, relativeTo: .largeTitle))
        #expect(Font(.heading.large) != .custom("Onest-SemiBold", size: large, relativeTo: .largeTitle))
        #expect(Font(.body.regular) == .system(.body, design: .default, weight: .regular))
        #expect(Font(.subheadline.strong) == .system(.subheadline, design: .default, weight: .semibold))
        #expect(Font(.caption.medium) == .system(.caption, design: .default, weight: .medium))
        #expect(Font(.heading.large) != Font(.heading.medium))
        // SwiftUI's own text styles stay unambiguous: westron adds no statics to Font (decisions/0010).
        let body = Font.body
        #expect(body == .system(.body))
        #expect(Westron.TextRole.all.count == Set(Westron.TextRole.all.map(\.name)).count)
    }

    @Test("every font a text role names is registered from WestronUI's Fonts folder and draws Cyrillic")
    func shippedFonts() {
        for role in Westron.TextRole.all {
            guard let name = role.font else { continue }
            _ = Font(role)  // The first use registers the fonts.
            let font = CTFontCreateWithName(name as CFString, 17, nil)
            #expect(CTFontCopyPostScriptName(font) as String == name, "\(role.name): \(name) is not registered")
            let characters = Array("Задачи".utf16)
            var glyphs = [CGGlyph](repeating: 0, count: characters.count)
            #expect(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count), "\(name): no Cyrillic")
        }
    }

    @Test("a motion is its spring, or its curve")
    func animations() {
        #expect(Animation.move == .spring(duration: 0.35, bounce: 0.15))
        #expect(Animation.check == .spring(duration: 0.35, bounce: 0.2))
        #expect(Animation.press == .spring(duration: 0.15, bounce: 0))
        #expect(Animation.fade == .timingCurve(0.25, 0.1, 0.25, 1, duration: 0.2))
        #expect(Animation.leave == .timingCurve(0.3, 0, 1, 1, duration: 0.2))
        #expect(Animation.enter != Animation.leave)
    }

    @Test("space, radius and stroke are points")
    func lengths() {
        #expect(CGFloat.space25 == 2)
        #expect(CGFloat.space100 == 8)
        #expect(CGFloat.space600 == 48)
        #expect(CGFloat.space800 == 64)
        #expect(CGFloat.radius150 == 12)
        #expect(CGFloat.radius.control == 8 && CGFloat.radius.card == 12 && CGFloat.radius.sheet == 16)
        #expect(CGFloat.stroke.hairline == 0.5)
        #expect(CGFloat.stroke.thick == 2)
    }

    @Test("a control's height and its least hit area are the platform's (decisions/0013, revision of 2026-11-20)")
    func controlHeights() {
        let heights = [CGFloat.size.control.s, .size.control.m, .size.control.l]
        #if os(macOS)
            #expect(heights == [24, 32, 40])
            #expect(CGFloat.size.target.minimum == 28)
        #elseif os(watchOS)
            #expect(heights == [32, 44, 52])
            #expect(CGFloat.size.target.minimum == 44)
        #else
            #expect(heights == [28, 36, 50])
            #expect(CGFloat.size.target.minimum == 44)
        #endif
        #expect(Westron.Dimension.all.contains(.size.control.m))
        #expect(Westron.Dimension.all.contains(.size.target.minimum))
    }

    @Test("a number is a Double as it is: the opacity of a disabled control")
    func numbers() {
        #expect(Double.opacity.disabled == 0.4)
        #expect(Westron.Number.all == [.opacity.disabled])
        _ = Text("Save").opacity(.opacity.disabled)
    }

    @Test("a shadow has two layers in light, three times as opaque in dark, none on a raised card in dark")
    func shadows() {
        let overlay = Westron.Shadow.overlay
        #expect(overlay.light.map(\.radius) == [6, 16])
        #expect(overlay.light.map(\.color.opacity) == [0.08, 0.12])
        #expect(overlay.dark.map(\.color.opacity) == [0.24, 0.36])
        #expect(overlay[.lightHighContrast] == overlay.light && overlay[.darkHighContrast] == overlay.dark)
        #expect(Westron.Shadow.raised.light.count == 2 && Westron.Shadow.raised.dark.isEmpty)
        #expect(Westron.Theme(colorScheme: .dark, contrast: .increased) == .darkHighContrast)
        #expect(Westron.Theme(colorScheme: .light, contrast: .standard) == .light)
    }

    @Test("the accessors read as SwiftUI's own")
    func callSites() {
        let view = Text("Inbox")
            .textRole(.heading.small)
            .foregroundStyle(.text.secondary)
            .padding(.horizontal, .space200)
            .background(.background.surface, in: RoundedRectangle(cornerRadius: .radius150))
            .overlay(RoundedRectangle(cornerRadius: .radius150).stroke(.border.default, lineWidth: .stroke.thin))
            .shadow(.raised)
            .tint(Westron.Category.amber.fill)
            .animation(.move, value: 0)
        _ = view
        let stack = VStack(spacing: .space100) { Text("Today").foregroundStyle(Westron.Category.blue.text) }
        _ = stack
    }
}
