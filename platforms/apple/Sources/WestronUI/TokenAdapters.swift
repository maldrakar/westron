// The adapters that turn WestronTokens values into SwiftUI values. The generated statics in
// Generated/Tokens+SwiftUI.swift call them: `CGFloat.radius.card` is `CGFloat(Westron.Dimension.radius.card)`. A color
// goes to SwiftUI through the modifier overloads below, `.foregroundStyle(.text.primary)`, or `Color(.text.primary)`.
// An icon draws the SF Symbol that Generated/Icons+SwiftUI.swift names for it.

import CoreText
import SwiftUI
import WestronTokens

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

extension Color {
    /// A semantic color from its colorset in WestronUI's asset catalog, so that it switches with the appearance and
    /// the contrast setting, both the system's and the SwiftUI environment's.
    public init(_ token: Westron.Color) {
        self.init(token.name, bundle: .module)
    }

    /// A color of one theme, which does not switch: a shadow's color, a sample of a theme.
    public init(_ rgb: Westron.RGB) {
        self.init(Color.RGBColorSpace(rgb.space), red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.opacity)
    }
}

// MARK: - Colors where SwiftUI takes a style
//
// SwiftUI's modifiers take `some ShapeStyle`, where Swift finds a short name only among the statics of `ShapeStyle`
// extensions, and a group of tokens is an enum, which cannot live there. These overloads take a `Westron.Color`, so
// `.foregroundStyle(.text.primary)` finds westron's group, while `.foregroundStyle(.background)` and `.red` stay
// SwiftUI's (decisions/0010). A call without an overload takes `Color(.text.primary)`.

extension View {
    /// Sets the foreground of the view's content to a westron color.
    public func foregroundStyle(_ color: Westron.Color) -> some View {
        foregroundStyle(Color(color))
    }

    /// Puts a westron color behind the view, to the edges of the safe area it names.
    public func background(_ color: Westron.Color, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View {
        background(Color(color), ignoresSafeAreaEdges: edges)
    }

    /// Puts a shape filled with a westron color behind the view.
    public func background<S: Shape>(_ color: Westron.Color, in shape: S, fillStyle: FillStyle = FillStyle())
        -> some View
    {
        background(Color(color), in: shape, fillStyle: fillStyle)
    }

    /// Tints the view's controls with a westron color.
    public func tint(_ color: Westron.Color) -> some View {
        tint(Color(color))
    }
}

extension Text {
    /// Sets the text's color to a westron color, keeping it a `Text` that can join others with `+`.
    public func foregroundStyle(_ color: Westron.Color) -> Text {
        foregroundStyle(Color(color))
    }
}

extension Shape {
    /// Fills the shape with a westron color.
    public func fill(_ color: Westron.Color, style: FillStyle = FillStyle()) -> some View {
        fill(Color(color), style: style)
    }

    /// Strokes the shape's outline with a westron color.
    public func stroke(_ color: Westron.Color, lineWidth: CGFloat = .stroke.thin) -> some View {
        stroke(Color(color), lineWidth: lineWidth)
    }

    /// Strokes the shape's outline with a westron color in a stroke style.
    public func stroke(_ color: Westron.Color, style: StrokeStyle) -> some View {
        stroke(Color(color), style: style)
    }
}

extension InsettableShape {
    /// Strokes the shape's outline with a westron color, inside its frame.
    public func strokeBorder(_ color: Westron.Color, lineWidth: CGFloat = .stroke.thin) -> some View {
        strokeBorder(Color(color), lineWidth: lineWidth)
    }

    /// Strokes the shape's outline with a westron color in a stroke style, inside its frame.
    public func strokeBorder(_ color: Westron.Color, style: StrokeStyle) -> some View {
        strokeBorder(Color(color), style: style)
    }
}

extension Color.RGBColorSpace {
    init(_ space: Westron.RGB.Space) {
        switch space {
        case .sRGB: self = .sRGB
        case .displayP3: self = .displayP3
        }
    }
}

// MARK: - Text roles
//
// A role is its font and its tracking (spec/components/text). The tracking is a share of the size the font is drawn
// at, the token's letterSpacing over its fontSize, so it is recomputed for each Dynamic Type size and on each OS. Under
// Bold Text a role in a font westron ships takes the instance one weight up; the system font does so by itself. On
// watchOS every role is the system font. `.textRole(_:)` on a view reads the environment for all of it; `Font(_:)`
// and `Text.textRole(_:)` cannot (spec/components/text, P2).
//
// `Text.textRole(_:) -> Text` is `@_disfavoredOverload`, so that `Text("Inbox").textRole(.heading.medium)` as a view
// takes the View modifier. The twin is what the call resolves to where only a `Text` fits: inside interpolation with
// a role written as `.heading.large`, and in `Text + Text`. It follows Dynamic Type's size, but its tracking is the
// role's share of `platformSize`, which a `Text` reads without the environment: on iOS the size at the default Dynamic
// Type size, on macOS the Mac's size, which is the drawn size, on watchOS the size the system gives the text style
// now. Under Bold Text a role in Onest or Geist Mono keeps its own weight; the system font's roles still draw heavier
// by themselves. One trap: inside interpolation, a role in a variable or written in full
// (`Westron.TextRole.heading.large`) resolves to the View modifier through SwiftUI's deprecated catch-all, which
// prints a debug description; the compiler warns "'appendInterpolation' is deprecated". An untyped
// `let part = Text(count).textRole(…)` is no way out: it takes the View modifier however the role is spelled, so
// interpolating `part` does the same. Type the part first: `let part: Text = Text(count).textRole(role)`, or
// `Text(count).textRole(role) as Text`, then interpolate it.

extension Font {
    /// A text role's font in its text style, so that it follows Dynamic Type (decisions/0011): a font westron ships as
    /// `Font.custom(_:size:relativeTo:)` at the text style's size on this platform, and the system font as
    /// `Font.system(_:design:weight:)`; on watchOS always the system font.
    ///
    /// A font carries no tracking, and an initializer cannot read the environment: this is the role's own weight
    /// whatever the Bold Text setting, where the system font still draws heavier by itself. `.textRole(_:)` applies
    /// the tracking and the heavier instance of a font westron ships.
    public init(_ role: Westron.TextRole) {
        self = role.font(boldText: false)
    }
}

extension Text {
    /// Sets a text role on a part of a text, keeping it a `Text`: inside interpolation,
    /// `Text("\(title) \(Text(count).textRole(.footnote.medium))")`, or joined with `+`.
    ///
    /// A `Text` cannot read the environment: the part takes the role's font, which follows Dynamic Type, and the
    /// tracking of `platformSize`, which does not (on iOS the default Dynamic Type size's, on macOS the Mac's, which
    /// is the drawn size, on watchOS the system's current size); under Bold Text a role in Onest or Geist Mono keeps
    /// its own weight. A role in a variable inside interpolation takes the View modifier and prints a debug
    /// description (the compiler warns), and so does an untyped `let part = Text(count).textRole(…)`, however the
    /// role is spelled: write `let part: Text = Text(count).textRole(role)` and interpolate `part`.
    @_disfavoredOverload
    public func textRole(_ role: Westron.TextRole) -> Text {
        font(role.font(boldText: false)).tracking(role.tracking(atSize: role.platformSize))
    }
}

extension View {
    /// Sets a text role: its font and its tracking, which a font cannot carry, from the environment. The tracking is
    /// the role's share of the size Dynamic Type draws the font at, and under Bold Text a role in Onest or Geist Mono
    /// takes the instance one weight up (spec/components/text):
    ///
    ///     Text("Inbox").textRole(.heading.medium)
    public func textRole(_ role: Westron.TextRole) -> some View {
        modifier(TextRoleModifier(role: role))
    }
}

private struct TextRoleModifier: ViewModifier {
    let role: Westron.TextRole
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        content
            .font(role.font(boldText: legibilityWeight == .bold))
            .tracking(role.tracking(atSize: role.drawnSize(at: dynamicTypeSize)))
    }
}

extension Westron.TextRole {
    /// Whether this platform draws every role in the system font: the watch does, for its screen
    /// (spec/components/text, `platforms.apple.watchos`).
    static var systemFontOnly: Bool {
        #if os(watchOS)
            true
        #else
            false
        #endif
    }

    /// The PostScript name of the font westron ships that draws the role, or nil for the system font: the role's own,
    /// or under Bold Text the instance of its family one weight up (`Weight.boldTextStep`).
    func shippedFont(boldText: Bool, systemFontOnly: Bool = Self.systemFontOnly) -> String? {
        guard !systemFontOnly, let font else { return nil }
        guard boldText else { return font }
        let family = font.split(separator: "-").first.map(String.init) ?? font
        return family + "-" + weight.boldTextStep.postScriptStyle
    }

    /// The role's SwiftUI font: the shipped font at the text style's size on this platform, relative to the text style,
    /// or the system font in the text style, its design and weight, where the role names no shipped font, on watchOS,
    /// and where registration failed.
    func font(boldText: Bool, systemFontOnly: Bool = Self.systemFontOnly) -> Font {
        if let name = shippedFont(boldText: boldText, systemFontOnly: systemFontOnly), BundledFonts.registered {
            return .custom(name, size: platformSize, relativeTo: Font.TextStyle(textStyle))
        }
        return .system(Font.TextStyle(textStyle), design: Font.Design(design), weight: Font.Weight(weight))
    }

    /// The tracking at a size, in points: the token's letterSpacing over its fontSize, as a share of `size`.
    func tracking(atSize size: CGFloat) -> CGFloat {
        CGFloat(letterSpacing / self.size) * size
    }

    /// The role's size at the default text size on this platform, as the system font takes it for the text style:
    /// the Mac's smaller sizes on macOS, iOS's at the default content size on iOS. watchOS has no API for its default
    /// size, so there it is the size the system gives the text style now.
    var platformSize: CGFloat {
        #if os(macOS)
            NSFont.preferredFont(forTextStyle: NSFont.TextStyle(textStyle)).pointSize
        #elseif os(watchOS)
            UIFont.preferredFont(forTextStyle: UIFont.TextStyle(textStyle)).pointSize
        #else
            UIFont.preferredFont(
                forTextStyle: UIFont.TextStyle(textStyle),
                compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
            ).pointSize
        #endif
    }

    /// The size SwiftUI draws the role's font at, at a Dynamic Type size. On iOS a shipped font is scaled as
    /// `Font.custom(_:size:relativeTo:)` scales it, by its text style's metrics to whole points, and the system font
    /// takes the text style's own size, which differs at the accessibility sizes (58 and 60 points for largeTitle at
    /// accessibility5); `TextRoleTests` holds both to what SwiftUI resolves. macOS has no Dynamic Type, so it is the
    /// Mac's size. watchOS reads it from SwiftUI where it can (watchOS 26), and before that takes the size the system
    /// gives the text style now, which an app's own `dynamicTypeSize` does not change.
    ///
    /// The shipped font's size is the point size of `UIFontMetrics.scaledFont`, which rounds the scaled size once, as
    /// SwiftUI does. `scaledValue(for:)` rounds to the screen's pixels first, to half points at 2x, and rounding that
    /// again sends a size just under a half point up: the caption's 12 points at accessibility5 came out 38.5, so 39
    /// where SwiftUI draws 38, on every 2x screen, iOS 17 and 26 alike (#133).
    ///
    /// `displayScale` is for tests only: on iOS it adds a display scale to the traits the size is computed with, so
    /// that `TextRoleTests` can hold the size to be the same at 1x, 2x and 3x on any one device. UIKit takes the scale
    /// from the screen, not from the current trait collection. Nil, as every caller passes, computes with the screen's.
    /// macOS and watchOS ignore it.
    func drawnSize(at dynamicTypeSize: DynamicTypeSize, displayScale: CGFloat? = nil) -> CGFloat {
        #if os(macOS)
            return platformSize
        #elseif os(watchOS)
            if #available(watchOS 26, *) {
                var environment = EnvironmentValues()
                environment.dynamicTypeSize = dynamicTypeSize
                return font(boldText: false).resolve(in: environment.fontResolutionContext).pointSize
            }
            return platformSize
        #else
            var traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
            if let displayScale {
                traits = traits.modifyingTraits { $0.displayScale = displayScale }
            }
            let style = UIFont.TextStyle(textStyle)
            if let name = shippedFont(boldText: false), BundledFonts.registered,
                let font = UIFont(name: name, size: platformSize)
            {
                return UIFontMetrics(forTextStyle: style).scaledFont(for: font, compatibleWith: traits).pointSize
            }
            return UIFont.preferredFont(forTextStyle: style, compatibleWith: traits).pointSize
        #endif
    }
}

extension Westron.TextRole.Weight {
    /// The weight a font westron ships takes under Bold Text, the rule the owner set (spec/components/text,
    /// decisions/0001): Regular to SemiBold, skipping Medium, SemiBold to Bold, Bold to ExtraBold (`heavy`, 800); any
    /// other weight one step up. The system font has a step of its own and takes it by itself.
    var boldTextStep: Self {
        switch self {
        case .ultraLight: .thin
        case .thin: .light
        case .light: .regular
        case .regular: .semibold
        case .medium: .semibold
        case .semibold: .bold
        case .bold: .heavy
        case .heavy: .black
        case .black: .black
        }
    }

    /// How a static instance's PostScript name ends at this weight, as the token generator names them:
    /// `Onest-SemiBold`, `Onest-ExtraBold` (decisions/0011).
    var postScriptStyle: String {
        switch self {
        case .ultraLight: "Thin"
        case .thin: "ExtraLight"
        case .light: "Light"
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .heavy: "ExtraBold"
        case .black: "Black"
        }
    }
}

#if os(macOS)
    extension NSFont.TextStyle {
        init(_ style: Westron.TextRole.TextStyle) {
            switch style {
            case .largeTitle: self = .largeTitle
            case .title1: self = .title1
            case .title2: self = .title2
            case .title3: self = .title3
            case .headline: self = .headline
            case .body: self = .body
            case .callout: self = .callout
            case .subheadline: self = .subheadline
            case .footnote: self = .footnote
            case .caption: self = .caption1
            case .caption2: self = .caption2
            }
        }
    }
#else
    extension UIFont.TextStyle {
        init(_ style: Westron.TextRole.TextStyle) {
            switch style {
            case .largeTitle: self = .largeTitle
            case .title1: self = .title1
            case .title2: self = .title2
            case .title3: self = .title3
            case .headline: self = .headline
            case .body: self = .body
            case .callout: self = .callout
            case .subheadline: self = .subheadline
            case .footnote: self = .footnote
            case .caption: self = .caption1
            case .caption2: self = .caption2
            }
        }
    }
#endif

/// The fonts westron ships, in WestronUI's `Fonts` folder with their licenses: six static instances, the weights the
/// roles use and the ones they take under Bold Text (decisions/0011). They are registered for the process the first
/// time a text role needs one, so a product has nothing to set up. watchOS never registers them: it draws every role
/// in the system font.
enum BundledFonts {
    /// The font files in WestronUI's bundle.
    static var urls: [URL] {
        Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
    }

    /// Whether the fonts are registered. A failure leaves the roles on the system font, which every one of them
    /// names as its fallback.
    static let registered: Bool = {
        let urls = Self.urls
        guard !urls.isEmpty else { return false }
        var failed = false
        for url in urls {
            var error: Unmanaged<CFError>?
            // A font that is already registered, by an earlier test run or by the app itself, is not a failure.
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error), let error {
                let code = CFErrorGetCode(error.takeRetainedValue())
                failed = failed || code != CTFontManagerError.alreadyRegistered.rawValue
            }
        }
        return !failed
    }()
}

extension Font.TextStyle {
    init(_ style: Westron.TextRole.TextStyle) {
        switch style {
        case .largeTitle: self = .largeTitle
        case .title1: self = .title
        case .title2: self = .title2
        case .title3: self = .title3
        case .headline: self = .headline
        case .body: self = .body
        case .callout: self = .callout
        case .subheadline: self = .subheadline
        case .footnote: self = .footnote
        case .caption: self = .caption
        case .caption2: self = .caption2
        }
    }
}

extension Font.Design {
    init(_ design: Westron.TextRole.Design) {
        switch design {
        case .default: self = .default
        case .rounded: self = .rounded
        case .monospaced: self = .monospaced
        case .serif: self = .serif
        }
    }
}

extension Font.Weight {
    init(_ weight: Westron.TextRole.Weight) {
        switch weight {
        case .ultraLight: self = .ultraLight
        case .thin: self = .thin
        case .light: self = .light
        case .regular: self = .regular
        case .medium: self = .medium
        case .semibold: self = .semibold
        case .bold: self = .bold
        case .heavy: self = .heavy
        case .black: self = .black
        }
    }
}

extension Animation {
    /// A motion as a SwiftUI animation: its spring where it has one (`spring(duration:bounce:)`), otherwise its curve
    /// (`timingCurve`), and its delay when it waits.
    public init(_ transition: Westron.Transition) {
        let animation: Animation
        if let spring = transition.spring {
            animation = .spring(duration: spring.duration, bounce: spring.bounce)
        } else {
            let curve = transition.curve
            animation = .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2, duration: transition.duration)
        }
        self = transition.delay > 0 ? animation.delay(transition.delay) : animation
    }
}

extension CGFloat {
    /// A length in points.
    public init(_ dimension: Westron.Dimension) {
        self.init(dimension.value)
    }
}

extension Double {
    /// A number as it is, such as an opacity: `.opacity(.opacity.disabled)`.
    public init(_ number: Westron.Number) {
        self = number.value
    }
}

extension View {
    /// Casts a shadow token in the theme of the environment: each layer's color, its radius (half the CSS blur) and
    /// its offset (decisions/0013). A theme without layers casts none.
    ///
    ///     card.shadow(.raised)
    public func shadow(_ shadow: Westron.Shadow) -> some View {
        modifier(ShadowModifier(shadow: shadow))
    }
}

private struct ShadowModifier: ViewModifier {
    let shadow: Westron.Shadow
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let theme = Westron.Theme(colorScheme: colorScheme, contrast: contrast)
        return shadow[theme].reduce(AnyView(content)) { view, layer in
            AnyView(
                view.shadow(
                    color: Color(layer.color), radius: CGFloat(layer.radius), x: CGFloat(layer.x), y: CGFloat(layer.y)))
        }
    }
}

extension Westron.Theme {
    /// The theme of a SwiftUI environment: its color scheme and its contrast.
    public init(colorScheme: ColorScheme, contrast: ColorSchemeContrast) {
        switch (colorScheme, contrast) {
        case (.dark, .increased): self = .darkHighContrast
        case (.dark, _): self = .dark
        case (_, .increased): self = .lightHighContrast
        default: self = .light
        }
    }
}

extension Image {
    /// An icon's SF Symbol as an `Image` (decisions/0011), for where only an `Image` fits, such as inside `Text`
    /// interpolation: `Text("\(Image(.flag)) Yesterday")`, which then reads the symbol's system name, so such a text
    /// takes an `.accessibilityLabel` that says what the line means. It takes the font and the color of its context,
    /// as the icon does.
    ///
    /// It is not the Icon component: an `Image` of a symbol keeps the system's spoken name of the symbol ("Increase
    /// Brightness" for `.sun`), which SwiftUI cannot hide or replace on an `Image`. A standalone icon is `Icon(.tray)`,
    /// decorative, or `Icon(.sun, label: "Today")` (spec/components/icon).
    public init(_ icon: Westron.Icon) {
        self.init(systemName: icon.systemName)
    }
}

extension Label where Title == Text, Icon == Image {
    /// A label with an icon, as `Label(_:systemImage:)` makes one: `Label("Rename", icon: .pen)`.
    ///
    /// Its icon is the system's `Image`, which keeps the symbol's spoken name, and the system decides whether to read
    /// it beside the title: in a control the title names it. Hiding the icon here hides a menu item built from the
    /// label as a whole (spec/components/icon, decisions/0001), so the icon stays as the system makes it.
    public init(_ titleKey: LocalizedStringKey, icon: Westron.Icon) {
        self.init(titleKey, systemImage: icon.systemName)
    }

    /// A label with an icon and a title that is not localized: `Label(list.title, icon: .folder)`.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, icon: Westron.Icon) {
        self.init(title, systemImage: icon.systemName)
    }
}
