// Hand-written. Surface from its contract, spec/components/surface/surface.spec.yaml: the ground a card or a panel
// stands on, drawn behind the content a product lays out. It is an own component in the form of a modifier
// (`platforms.apple.form`): the generated `SurfaceVariant` (Generated/Surface+Contract.swift) names its kinds, and the
// API parity lint holds `surface(_:outlined:)` to the contract (spec/conventions.md, "Own components").

import SwiftUI

extension View {
    /// Draws westron's surface behind this view: its kind's background in a continuous rounded rectangle of
    /// `radius.card`, the kind's shadow in the environment's theme, and its edge, `.surface(.raised)` or
    /// `.surface(.sunken, outlined: true)`. It adds no padding, so the product pads the content with a token,
    /// `space.card` for a card, and no role, trait or label: assistive technology reads the content as if the surface
    /// were not there.
    ///
    /// - Parameters:
    ///   - variant: See `SurfaceVariant`. Every call names one.
    ///   - outlined: The hairline, `color.border.default` at `stroke.hairline`, for a surface on a fill rather than on
    ///     the canvas. By default `false`. In the high-contrast themes a raised or dragged surface draws
    ///     `stroke.thin` in that color instead, whether or not it is outlined.
    public func surface(_ variant: SurfaceVariant, outlined: Bool = false) -> some View {
        modifier(SurfaceModifier(variant: variant, outlined: outlined))
    }
}

/// The tokens a surface draws with: the contract's bindings, and in the high-contrast themes the line its description
/// adds to every raised or dragged surface, which replaces the hairline of an outlined one (P12).
struct SurfaceTokens: Equatable, Sendable {
    /// `container.radius`, the same for every kind; drawn with continuous corners on Apple.
    static let radius: Westron.Dimension = .radius.card

    /// `container.background`.
    var background: Westron.Color
    /// `container.shadow`; nil: none.
    var shadow: Westron.Shadow?
    /// `container.borderColor`, or the high-contrast line's; nil: no edge.
    var borderColor: Westron.Color?
    /// `container.borderWidth`, or the high-contrast line's; nil: no edge.
    var borderWidth: Westron.Dimension?

    /// `highContrast`: one of the high-contrast themes, `colorSchemeContrast == .increased`.
    init(variant: SurfaceVariant, outlined: Bool, highContrast: Bool) {
        switch variant {
        case .raised:
            background = .background.surface
            shadow = .raised
        case .dragged:
            background = .background.surface
            shadow = .dragged
        case .sunken:
            background = .background.sunken
            shadow = nil
        }
        if highContrast, Self.edgedInHighContrast(variant) {
            borderColor = .border.default
            borderWidth = .stroke.thin
        } else if outlined {
            borderColor = .border.default
            borderWidth = .stroke.hairline
        } else {
            borderColor = nil
            borderWidth = nil
        }
    }

    /// Whether the high-contrast themes draw the line on this kind: a raised or a dragged surface, which a shadow alone
    /// does not edge (decisions/0013); not a well (P6).
    static func edgedInHighContrast(_ variant: SurfaceVariant) -> Bool {
        switch variant {
        case .raised, .dragged: true
        case .sunken: false
        }
    }
}

/// Draws a surface behind the content, and its edge over the content's border, so that content that reaches the edge
/// does not hide it.
struct SurfaceModifier: ViewModifier {
    let variant: SurfaceVariant
    let outlined: Bool

    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let tokens = SurfaceTokens(variant: variant, outlined: outlined, highContrast: contrast == .increased)
        let shape = RoundedRectangle(cornerRadius: CGFloat(SurfaceTokens.radius), style: .continuous)
        content
            .background {
                // The shadow follows the ground's shape, not the content's glyphs.
                if let shadow = tokens.shadow {
                    shape.fill(tokens.background).shadow(shadow)
                } else {
                    shape.fill(tokens.background)
                }
            }
            .overlay {
                if let color = tokens.borderColor, let width = tokens.borderWidth {
                    shape.strokeBorder(color, lineWidth: CGFloat(width))
                        .allowsHitTesting(false)
                }
            }
    }
}
