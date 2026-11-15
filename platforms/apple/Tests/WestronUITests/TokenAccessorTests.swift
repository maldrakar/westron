import SwiftUI
import Testing
import WestronUI

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
        #expect(names.contains(Westron.Color.textSecondary.name))
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
        #expect(Westron.Color.textSecondary.backgrounds.first == ["color.background.canvas"])
        #expect(Westron.Color.all.filter { $0.name.hasPrefix("color.text.") }.allSatisfy { !$0.backgrounds.isEmpty })
        #expect(Westron.Color.backgroundCanvas.backgrounds.isEmpty)
    }

    @Test("a theme switches the color: the canvas differs in each theme")
    func themesSwitch() {
        let canvas = Westron.Theme.allCases.map { theme in
            Color.textSecondary.resolve(in: Self.environment(theme))
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
                let pairs: [(Color, Westron.Color)] = [
                    (.categoryBackground(category), category.background),
                    (.categoryBorder(category), category.border),
                    (.categoryIcon(category), category.icon),
                    (.categoryFill(category), category.fill),
                    (.categoryOnFill(category), category.onFill),
                    (.categoryText(category), category.text),
                ]
                for (color, token) in pairs {
                    #expect(
                        Self.close(color.resolve(in: environment), Self.resolved(token[theme])),
                        "\(token.name) in \(theme.rawValue)")
                }
            }
        }
    }

    @Test("a text role is the system font in its text style, design and weight")
    func fonts() {
        #expect(Font.headingLarge == .system(.largeTitle, design: .rounded, weight: .heavy))
        #expect(Font.headingOverline == .system(.caption, design: .rounded, weight: .heavy))
        #expect(Font.bodyRegular == .system(.body, design: .default, weight: .regular))
        #expect(Font.subheadlineStrong == .system(.subheadline, design: .default, weight: .semibold))
        #expect(Font.captionMedium == .system(.caption, design: .default, weight: .medium))
        #expect(Font.headingLarge != Font.headingMedium)
        #expect(Westron.TextRole.all.count == Set(Westron.TextRole.all.map(\.name)).count)
    }

    @Test("a motion is its spring, or its curve and delay")
    func animations() {
        #expect(Animation.check == .spring(duration: 0.45, bounce: 0))
        #expect(Animation.popover == .spring(duration: 0.2, bounce: 0))
        #expect(Animation.fold == .timingCurve(0.25, 0.1, 0.25, 1, duration: 0.22))
        #expect(Animation.checkMark == .timingCurve(0.25, 0.1, 0.25, 1, duration: 0.26).delay(0.08))
        #expect(Animation.rowLeave == .timingCurve(0.42, 0, 1, 1, duration: 0.32).delay(0.7))
        #expect(Animation.rowLeave != Animation.rowDelete)
    }

    @Test("space, radius and stroke are points")
    func lengths() {
        #expect(CGFloat.space25 == 2)
        #expect(CGFloat.space100 == 8)
        #expect(CGFloat.space600 == 48)
        #expect(CGFloat.radius150 == 12)
        #expect(CGFloat.strokeHairline == 0.5)
        #expect(CGFloat.strokeThick == 2)
    }

    @Test("a shadow's radius is half its CSS blur")
    func shadows() {
        #expect(Westron.Shadow.raised.radius == 12)
        #expect(Westron.Shadow.resting.radius == 1)
        #expect(Westron.Shadow.lifted.color == Westron.RGB(hex: 0x000000, opacity: 0.22))
    }

    @Test("the accessors read as SwiftUI's own")
    func callSites() {
        let view = Text("Inbox")
            .font(.headingSmall)
            .foregroundStyle(.textSecondary)
            .padding(.horizontal, .space200)
            .background(.backgroundSurface, in: RoundedRectangle(cornerRadius: .radius150))
            .overlay(RoundedRectangle(cornerRadius: .radius150).stroke(.borderDefault, lineWidth: .strokeThin))
            .shadow(.raised)
            .tint(.categoryFill(.amber))
            .animation(.fold, value: 0)
        _ = view
        let stack = VStack(spacing: .space100) { Text("Today").foregroundColor(.categoryText(.blue)) }
        _ = stack
    }
}
