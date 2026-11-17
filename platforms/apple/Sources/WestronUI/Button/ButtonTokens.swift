// Hand-written. Button's token bindings from its contract, spec/components/button/button.spec.yaml, as pure functions
// of its options and states, so that ButtonVariantStyle draws exactly what they return and the tests compare them with
// the contract's `tokens` block, case by case (Tests/WestronUITests/ButtonStyleTests.swift).

import SwiftUI

/// The tokens a Button draws with, for one variant, role and set of states: the contract's `cases` bindings, each one
/// resolved as the contract resolves it, by the first case that matches.
struct ButtonTokens: Equatable, Sendable {
    /// `container.background`; nil: no fill.
    var background: Westron.Color?
    /// `container.borderColor`; nil: no border.
    var borderColor: Westron.Color?
    /// `container.borderWidth`; nil: no border.
    var borderWidth: Westron.Dimension?
    /// `container.opacity`; nil: drawn whole.
    var opacity: Westron.Number?
    /// `label.color`.
    var label: Westron.Color
    /// `icon.color`.
    var icon: Westron.Color
    /// `progress.color`.
    var progress: Westron.Color

    /// The tokens of a button in `states`, which hold at once. A state the current OS never enters is ignored
    /// (`ButtonState.isEntered`). `destructive` is SwiftUI's `ButtonRole.destructive`; any other role draws as default.
    init(variant: ButtonVariant, destructive: Bool, states: Set<ButtonState>) {
        let states = states.filter(\.isEntered)
        let variant = variant.offered
        // The cases of container.background, in the contract's order: disabled and loading first, so that they
        // exclude hover and pressed and the resting fill holds.
        let excludesTint = !states.isDisjoint(with: [.disabled, .loading])
        switch variant {
        case .primary:
            if excludesTint {
                background = destructive ? .status.danger.fill : .background.accent
            } else if destructive {
                background =
                    states.contains(.pressed)
                    ? .status.danger.fillPressed
                    : states.contains(.hover) ? .status.danger.fillHover : .status.danger.fill
            } else {
                background =
                    states.contains(.pressed)
                    ? .background.accentPressed
                    : states.contains(.hover) ? .background.accentHover : .background.accent
            }
        case .secondary, .tertiary:
            if excludesTint {
                background = nil
            } else {
                background =
                    states.contains(.pressed) ? .background.pressed : states.contains(.hover) ? .background.hover : nil
            }
        }

        switch variant {
        case .secondary:
            borderColor = destructive ? .status.danger.border : .border.strong
            borderWidth = .stroke.thin
        case .primary, .tertiary:
            borderColor = nil
            borderWidth = nil
        }

        opacity = states.contains(.disabled) ? .opacity.disabled : nil

        // label.color, icon.color and progress.color bind the same cases (P5).
        let ink: Westron.Color =
            switch variant {
            case .primary: destructive ? .status.danger.onFill : .text.onAccent
            case .secondary: destructive ? .status.danger.text : .text.primary
            case .tertiary: destructive ? .status.danger.text : .text.accent
            }
        label = ink
        icon = ink
        progress = ink
    }

    /// Whether a press scales the button down (`container.pressMotion`, chapter 05): pressed, and neither disabled nor
    /// loading, which exclude pressed. Reduce Motion drops the scale; the style checks that.
    static func scalesDown(states: Set<ButtonState>) -> Bool {
        let states = states.filter(\.isEntered)
        return states.contains(.pressed) && states.isDisjoint(with: [.disabled, .loading])
    }

    /// The scale of a pressed button, 98 % (`motion.press`). Chapter 05 ("Shapes belong to components") puts a motion's
    /// shape in the component's contract, not in the motion tokens, and fixes this one for every control, so it is a
    /// number here, under the lint's exemption, not a token.
    static let pressScale: CGFloat = 0.98  // westron-lint: allow a motion's shape, fixed by chapter 05, is not a token
}

/// The bindings of Button that vary by size: the contract's per-size maps.
struct ButtonMetrics: Equatable, Sendable {
    /// `container.height`: a minimum, the button grows with its text (P11).
    var height: Westron.Dimension
    /// `container.paddingHorizontal`; icon-only has none.
    var paddingHorizontal: Westron.Dimension
    /// `container.gap`, between the icon (or the progress indicator) and the label.
    var gap: Westron.Dimension
    /// `label.font`.
    var labelFont: Westron.TextRole
    /// `icon.font`.
    var iconFont: Westron.TextRole

    /// The metrics of the size the current OS draws for `size` (`ButtonSize.offered`).
    init(_ size: ButtonSize) {
        switch size.offered {
        case .s:
            height = .size.control.s
            paddingHorizontal = .space100
            gap = .space50
            labelFont = .footnote.strong
        case .m:
            height = .size.control.m
            paddingHorizontal = .space150
            gap = .space75
            labelFont = .subheadline.strong
        case .l:
            height = .size.control.l
            paddingHorizontal = .space200
            gap = .space100
            labelFont = .subheadline.strong
        }
        // icon.font equals label.font by size (P4).
        iconFont = labelFont
    }

    /// How far the hit area reaches past the drawn button on each side, so that it covers the platform's recommended
    /// target (contract, `size`; chapter 08) where the drawn button is smaller: on macOS, size s, drawn 24 pt tall
    /// against a target of 28. The height grows, and the width of icon-only, a square; a label and its padding make a
    /// button at least as wide as the target. On iOS and watchOS none: the system's touch tolerance reaches past the
    /// target (ButtonVariantStyle.swift). From the size's least height: a button that grows taller with its text keeps
    /// the same outset.
    func hitOutset(iconOnly: Bool) -> EdgeInsets {
        #if os(macOS)
            let side = max(0, (Self.hitTarget - CGFloat(height)) / 2)
            return EdgeInsets(top: side, leading: iconOnly ? side : 0, bottom: side, trailing: iconOnly ? side : 0)
        #else
            return EdgeInsets()
        #endif
    }

    #if os(macOS)
        /// The recommended hit target on macOS, 28 × 28 pt (chapter 08, "Hit targets"; HIG Accessibility).
        static let hitTarget: CGFloat = 28  // westron-lint: allow the platform's hit target, which has no token yet
    #endif

    /// `container.radius`.
    static let radius: Westron.Dimension = .radius.control
}

extension ButtonSize {
    /// The size a call draws: an explicit `size:` wins over the environment's `controlSize`
    /// (spec/conventions.md), and then the size the current OS offers in its place (on watchOS, m).
    static func resolved(explicit: ButtonSize?, controlSize: ControlSize) -> ButtonSize {
        (explicit ?? ButtonSize(controlSize)).offered
    }
}
