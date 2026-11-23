import CoreText
import SwiftUI
import Testing

@testable import WestronUI

/// A text role's behaviour on Apple (spec/components/text): the tracking as a share of the size the font is drawn at,
/// the heavier instance under Bold Text, the watch's system font, and the six shipped instances.
///
/// SwiftUI resolves a `Font` in an environment only from OS 26 (`Font.resolve(in:)`), so the checks against what
/// SwiftUI draws run there; the test runs, macOS 26 and the iOS 26 simulator or later, take them.
@Suite("Text roles")
@MainActor
struct TextRoleTests {
    /// The roles in a font westron ships, with the instance each takes under Bold Text.
    static let boldTextInstances: [(role: Westron.TextRole, font: String, bold: String)] = [
        (.heading.large, "Onest-Bold", "Onest-ExtraBold"),
        (.heading.medium, "Onest-Bold", "Onest-ExtraBold"),
        (.heading.small, "Onest-SemiBold", "Onest-Bold"),
        (.heading.overline, "Onest-SemiBold", "Onest-Bold"),
        (.code.regular, "GeistMono-Regular", "GeistMono-SemiBold"),
        (.code.strong, "GeistMono-SemiBold", "GeistMono-Bold"),
    ]

    /// The six instances in WestronUI's Fonts folder.
    static let shippedInstances = [
        "GeistMono-Bold", "GeistMono-Regular", "GeistMono-SemiBold", "Onest-Bold", "Onest-ExtraBold", "Onest-SemiBold",
    ]

    /// An environment at a Dynamic Type size, with Bold Text on or off.
    static func environment(_ size: DynamicTypeSize, boldText: Bool = false) -> EnvironmentValues {
        var environment = EnvironmentValues()
        environment.dynamicTypeSize = size
        environment.legibilityWeight = boldText ? .bold : .regular
        return environment
    }

    @Test("the tracking is the token's letterSpacing over its fontSize: −1 % for headings, +6 % for the overline")
    func trackingShare() {
        let shares: [(Westron.TextRole, CGFloat)] = [
            (.heading.large, -0.01), (.heading.medium, -0.01), (.heading.small, -0.01), (.heading.overline, 0.06),
        ]
        for (role, share) in shares {
            #expect(abs(role.tracking(atSize: 100) - share * 100) < 1e-9, "\(role.name)")
            #expect(abs(role.tracking(atSize: CGFloat(role.size)) - CGFloat(role.letterSpacing)) < 1e-9)
        }
        let tracked = Set(shares.map(\.0.name))
        for role in Westron.TextRole.all where !tracked.contains(role.name) {
            #expect(role.tracking(atSize: 100) == 0, "\(role.name) is not tracked")
        }
    }

    @Test("the tracking follows the size the role is drawn at, at more than one Dynamic Type size")
    func trackingAtSizes() {
        let large = Westron.TextRole.heading.large
        let overline = Westron.TextRole.heading.overline
        let atDefault = large.drawnSize(at: .large)
        let atLargest = large.drawnSize(at: .accessibility5)
        #expect(atDefault == large.platformSize)
        #if os(macOS)
            // macOS has no Dynamic Type: the Mac's sizes, 26 points for largeTitle, at every size.
            #expect(atDefault == 26 && atLargest == 26)
            #expect(abs(large.tracking(atSize: atDefault) - -0.26) < 1e-9)
            #expect(abs(overline.tracking(atSize: overline.drawnSize(at: .xSmall)) - 0.06 * 10) < 1e-9)
        #else
            // iOS: Onest at largeTitle is 34 points at the default size and 58 at accessibility5; the overline, at
            // caption, 12, 38 at accessibility5 and 10 at xSmall, which no fixed tracking would follow.
            #expect(atDefault == 34 && atLargest == 58)
            #expect(abs(large.tracking(atSize: atDefault) - -0.34) < 1e-9)
            #expect(abs(large.tracking(atSize: atLargest) - -0.58) < 1e-9)
            #expect(overline.drawnSize(at: .xSmall) == 10)
            #expect(abs(overline.tracking(atSize: overline.drawnSize(at: .accessibility5)) - 0.06 * 38) < 1e-9)
        #endif
    }

    @Test(
        "the size the tracking is computed from is the size SwiftUI draws the font at, at every Dynamic Type size",
        arguments: DynamicTypeSize.allCases)
    func drawnSizeIsSwiftUIs(size: DynamicTypeSize) throws {
        guard #available(iOS 26, macOS 26, watchOS 26, *) else { return }
        for boldText in [false, true] {
            let context = Self.environment(size, boldText: boldText).fontResolutionContext
            for role in Westron.TextRole.all {
                let resolved = role.font(boldText: boldText).resolve(in: context)
                #expect(
                    role.drawnSize(at: size) == resolved.pointSize,
                    "\(role.name) at \(size), Bold Text \(boldText): \(role.drawnSize(at: size)), SwiftUI draws \(resolved.pointSize)"
                )
            }
        }
    }

    #if os(iOS)
        @Test(
            "the drawn size is the same at every display scale, so a 2x screen draws what a 3x one does (#133)",
            arguments: DynamicTypeSize.allCases)
        func drawnSizeAtEveryDisplayScale(size: DynamicTypeSize) {
            for role in Westron.TextRole.all {
                let atOne = role.drawnSize(at: size, displayScale: 1)
                #expect(role.drawnSize(at: size) == atOne, "\(role.name) at \(size), this screen's scale")
                for scale: CGFloat in [1, 2, 3] {
                    let drawn = role.drawnSize(at: size, displayScale: scale)
                    #expect(drawn == atOne, "\(role.name) at \(size), \(scale)x: \(drawn), at 1x \(atOne)")
                }
            }
        }

        @Test("the overline at accessibility5 is drawn at 38 points on a 2x screen, not 39 (#133)")
        func overlineAtTwoX() {
            // The caption's 12 points scale to 38.333 at accessibility5: pixel-rounded at 2x first, 38.5, then 39.
            #expect(Westron.TextRole.heading.overline.drawnSize(at: .accessibility5, displayScale: 2) == 38)
        }
    #endif

    @Test("under Bold Text a role in Onest or Geist Mono takes the instance one weight up; the system font's do not")
    func boldTextStep() {
        for (role, font, bold) in Self.boldTextInstances {
            #expect(role.shippedFont(boldText: false) == font)
            #expect(role.shippedFont(boldText: true) == bold, "\(role.name)")
            #expect(role.font(boldText: true) != role.font(boldText: false))
        }
        #expect(Westron.TextRole.Weight.regular.boldTextStep == .semibold)
        #expect(Westron.TextRole.Weight.semibold.boldTextStep == .bold)
        #expect(Westron.TextRole.Weight.bold.boldTextStep == .heavy)
        #expect(Westron.TextRole.Weight.heavy.postScriptStyle == "ExtraBold")
        let shipped = Set(Self.boldTextInstances.map(\.role.name))
        for role in Westron.TextRole.all where !shipped.contains(role.name) {
            #expect(role.shippedFont(boldText: true) == nil)
            // The system font is the same `Font` either way: it reads Bold Text when SwiftUI resolves it.
            #expect(role.font(boldText: true) == role.font(boldText: false))
        }
    }

    @Test("SwiftUI draws the heavier instance under Bold Text, and the system font draws heavier by itself")
    func boldTextAsDrawn() throws {
        guard #available(iOS 26, macOS 26, watchOS 26, *) else { return }
        let regular = Self.environment(.large).fontResolutionContext
        let bold = Self.environment(.large, boldText: true).fontResolutionContext
        for (role, font, heavier) in Self.boldTextInstances {
            let name = CTFontCopyPostScriptName(role.font(boldText: true).resolve(in: bold).ctFont) as String
            #expect(name == heavier, "\(role.name)")
            // SwiftUI itself does not move a custom font: what Font(_:) and Text.textRole(_:) draw.
            let own = CTFontCopyPostScriptName(Font(role).resolve(in: bold).ctFont) as String
            #expect(own == font, "\(role.name)")
        }
        let body = Font(.body.regular)
        #expect(body.resolve(in: bold).weight != body.resolve(in: regular).weight)
    }

    @Test("on watchOS every role is the system font, in its text style, its design and its weight")
    func watchFont() {
        // The watch's choice is `systemFontOnly`; this runs it on macOS and iOS. What the watch then draws, its sizes
        // and the tracking from them, needs a watchOS test run, which the package does not have.
        for role in Westron.TextRole.all {
            for boldText in [false, true] {
                #expect(role.shippedFont(boldText: boldText, systemFontOnly: true) == nil)
                #expect(
                    role.font(boldText: boldText, systemFontOnly: true)
                        == .system(
                            Font.TextStyle(role.textStyle), design: Font.Design(role.design),
                            weight: Font.Weight(role.weight)))
            }
        }
        #expect(
            Westron.TextRole.code.strong.font(boldText: false, systemFontOnly: true)
                == .system(.subheadline, design: .monospaced, weight: .semibold))
        #expect(
            Westron.TextRole.heading.large.font(boldText: false, systemFontOnly: true)
                == .system(.largeTitle, design: .default, weight: .bold))
        #expect(!Westron.TextRole.systemFontOnly, "macOS and iOS draw Onest and Geist Mono")
    }

    @Test("the six instances are registered from WestronUI's Fonts folder and draw Cyrillic")
    func registration() {
        #expect(
            BundledFonts.urls.map { $0.deletingPathExtension().lastPathComponent }.sorted() == Self.shippedInstances)
        #expect(BundledFonts.registered)
        for name in Self.shippedInstances {
            let font = CTFontCreateWithName(name as CFString, 17, nil)
            #expect(CTFontCopyPostScriptName(font) as String == name, "\(name) is not registered")
            let characters = Array("Задачи".utf16)
            var glyphs = [CGGlyph](repeating: 0, count: characters.count)
            #expect(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count), "\(name): no Cyrillic")
        }
        let named = Set(Self.boldTextInstances.flatMap { [$0.font, $0.bold] })
        #expect(named == Set(Self.shippedInstances), "every instance is a role's or its Bold Text instance")
    }

    /// Takes only a `Text`: a call that compiles as its argument resolved to the twin, not to the View modifier.
    static func part(_ text: Text) -> Text { text }

    @Test("Text.textRole gives a part of a Text the role's font and the tracking of the default text size")
    func textTwin() {
        for role in Westron.TextRole.all {
            let part: Text = Text("Inbox").textRole(role)
            #expect(part == Text("Inbox").font(Font(role)).tracking(role.tracking(atSize: role.platformSize)))
        }
        // A heading's tracking is its share of the default size, whatever size Dynamic Type draws: −1 % of the Mac's
        // 26 points for largeTitle, of iOS's 34; Onest Bold stays Onest Bold under Bold Text (`Font(role)`).
        #if os(macOS)
            let largeTitle: CGFloat = 26
        #else
            let largeTitle: CGFloat = 34
        #endif
        let large = Westron.TextRole.heading.large
        #expect(large.platformSize == largeTitle)
        #expect(
            Text("Inbox").textRole(large) as Text
                == Text("Inbox").font(.custom("Onest-Bold", size: largeTitle, relativeTo: .largeTitle))
                .tracking(-0.01 * largeTitle))
        #expect(
            Text("Inbox").textRole(.code.strong) as Text
                == Text("Inbox").font(
                    .custom(
                        "GeistMono-SemiBold", size: Westron.TextRole.code.strong.platformSize,
                        relativeTo: .subheadline)
                ).tracking(0))
    }

    @Test("where only a Text fits the call takes the twin; where a view fits, the View modifier")
    func twinResolution() {
        let styled = Text("3").font(Font(.footnote.medium)).tracking(0)
        // Inside interpolation, with the role written as `.footnote.medium`: the styled part, not a description.
        #expect(Text("Inbox \(Text("3").textRole(.footnote.medium))") == Text("Inbox \(styled)"))
        #expect(Self.part(Text("3").textRole(.footnote.medium)) == styled)
        // A role in a variable: typed as Text first, as TokenAdapters.swift says. Interpolated directly it would take
        // the View modifier through SwiftUI's deprecated catch-all and print a debug description (the compiler warns).
        let role = Westron.TextRole.footnote.medium
        let part: Text = Text("3").textRole(role)
        #expect(Text("Inbox \(part)") == Text("Inbox \(styled)"))
        #expect(Text("Inbox \(Text("3").textRole(role) as Text)") == Text("Inbox \(styled)"))
        // Joined with `+`.
        _ = Text("Inbox ") + Text("3").textRole(.footnote.medium) + Text("3").textRole(role)
        // As a view, the View modifier, which reads the environment.
        let view = Text("Inbox").textRole(.heading.large)
        #expect(!(view is Text))
    }

    @Test("Font(role) is the role's own weight in its text style, following Dynamic Type but not Bold Text")
    func fontInitializer() throws {
        for role in Westron.TextRole.all {
            #expect(Font(role) == role.font(boldText: false))
        }
        guard #available(iOS 26, macOS 26, watchOS 26, *) else { return }
        let font = Font(.heading.large)
        let largest = font.resolve(in: Self.environment(.accessibility5, boldText: true).fontResolutionContext)
        #expect(CTFontCopyPostScriptName(largest.ctFont) as String == "Onest-Bold")
        #expect(largest.pointSize == Westron.TextRole.heading.large.drawnSize(at: .accessibility5))
    }
}
