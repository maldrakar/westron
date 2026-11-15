// The adapters that turn WestronTokens values into SwiftUI values. The generated statics in
// Generated/Tokens+SwiftUI.swift call them: `Color.textSecondary` is `Color(Westron.Color.textSecondary)`. An icon
// draws the SF Symbol that Generated/Icons+SwiftUI.swift names for it.

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
    /// A text role as the system font in the role's text style, design and weight, so that it follows Dynamic Type
    /// (decisions/0011): `Font.system(_:design:weight:)`, never `Font.custom`.
    public init(_ role: Westron.TextRole) {
        self = .system(
            Font.TextStyle(role.textStyle), design: Font.Design(role.design), weight: Font.Weight(role.weight))
    }
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
    /// Casts a shadow token: its color, its radius (half the CSS blur) and its offset (decisions/0013).
    ///
    ///     card.shadow(.raised)
    public func shadow(_ shadow: Westron.Shadow) -> some View {
        self.shadow(
            color: Color(shadow.color), radius: CGFloat(shadow.radius), x: CGFloat(shadow.x), y: CGFloat(shadow.y))
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
