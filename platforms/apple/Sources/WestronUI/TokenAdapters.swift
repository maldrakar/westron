// The adapters that turn WestronTokens values into SwiftUI values. The generated statics in
// Generated/Tokens+SwiftUI.swift call them: `Color.textSecondary` is `Color(Westron.Color.textSecondary)`. An icon
// draws the SF Symbol that Generated/Icons+SwiftUI.swift names for it.

import CoreText
import SwiftUI
import WestronTokens

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

extension Color.RGBColorSpace {
    init(_ space: Westron.RGB.Space) {
        switch space {
        case .sRGB: self = .sRGB
        case .displayP3: self = .displayP3
        }
    }
}

extension Font {
    /// A text role in its text style, so that it follows Dynamic Type (decisions/0011): a font westron ships as
    /// `Font.custom(_:size:relativeTo:)`, and the system font as `Font.system(_:design:weight:)`.
    public init(_ role: Westron.TextRole) {
        if let font = role.font, BundledFonts.registered {
            self = .custom(font, size: CGFloat(role.size), relativeTo: Font.TextStyle(role.textStyle))
        } else {
            self = .system(
                Font.TextStyle(role.textStyle), design: Font.Design(role.design), weight: Font.Weight(role.weight))
        }
    }
}

/// The fonts westron ships, in WestronUI's `Fonts` folder with their licenses. They are registered for the process
/// the first time a text role needs one, so a product has nothing to set up.
enum BundledFonts {
    /// Whether the fonts are registered. A failure leaves the roles on the system font, which every one of them
    /// names as its fallback.
    static let registered: Bool = {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts"), !urls.isEmpty
        else { return false }
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
    /// An icon as its SF Symbol (decisions/0011). Next to text it takes that text's font, so it sits on the line like a
    /// letter and scales with Dynamic Type, and the color of that text (design-language/07-icons.md):
    ///
    ///     Image(Westron.Icon(rawValue: list.icon) ?? .fallback)
    ///         .font(.bodyRegular)
    ///         .foregroundStyle(.categoryText(.amber))
    public init(_ icon: Westron.Icon) {
        self.init(systemName: icon.systemName)
    }
}

extension Label where Title == Text, Icon == Image {
    /// A label with an icon, as `Label(_:systemImage:)` makes one: `Label("Rename", icon: .pen)`.
    public init(_ titleKey: LocalizedStringKey, icon: Westron.Icon) {
        self.init(titleKey, systemImage: icon.systemName)
    }

    /// A label with an icon and a title that is not localized: `Label(list.title, icon: .folder)`.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, icon: Westron.Icon) {
        self.init(title, systemImage: icon.systemName)
    }
}
