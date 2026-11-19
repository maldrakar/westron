// Hand-written. TextField's token bindings from its contract, spec/components/text-field/text-field.spec.yaml, as pure
// functions of its options and states, so that TextFieldVariantStyle draws exactly what they return and the tests
// compare them with the contract's `tokens` block, case by case (Tests/WestronUITests/TextFieldStyleTests.swift).

import SwiftUI

/// The tokens a text field draws with, for one variant and set of states: the contract's `cases` bindings, each one
/// resolved as the contract resolves it, by the first case that matches. nil where no case matches: the binding draws
/// nothing, or, for the text, leaves the font or the color to the context.
///
/// `placeholder.color` is not here: a `TextFieldStyle` cannot color the system field's prompt (the probe of #30), so
/// the field draws its prompt in the system's placeholder color: a platform difference the contract's `platforms.apple`
/// records (decisions/0001, I1). On iOS a product reaches `color.text.placeholder` by coloring its prompt itself.
struct TextFieldTokens: Equatable, Sendable {
    /// `container.borderColor`; nil: no outline.
    var borderColor: Westron.Color?
    /// `container.borderWidth`; nil: no outline.
    var borderWidth: Westron.Dimension?
    /// `container.opacity`; nil: drawn whole.
    var opacity: Westron.Number?
    /// `text.font`; nil: the context's text role.
    var textFont: Westron.TextRole?
    /// `text.color`; nil: the context's foreground style.
    var textColor: Westron.Color?
    /// `focusRing.color`; nil: no ring.
    var focusRingColor: Westron.Color?
    /// `focusRing.width`; nil: no ring.
    var focusRingWidth: Westron.Dimension?

    /// The tokens of a field in `states`, which hold at once. A state the current OS never enters is ignored
    /// (`TextFieldState.isEntered`).
    init(variant: TextFieldVariant, states: Set<TextFieldState>) {
        let states = states.filter(\.isEntered)
        switch variant.offered {
        case .framed:
            borderColor = .border.strong
            borderWidth = .stroke.thin
            textFont = .body.regular
            textColor = .text.primary
        case .inline:
            borderColor = nil
            borderWidth = nil
            textFont = nil
            textColor = nil
        }
        opacity = states.contains(.disabled) ? .opacity.disabled : nil
        let focused = states.contains(.focus)
        focusRingColor = focused ? .border.focus : nil
        focusRingWidth = focused ? .stroke.thick : nil
    }
}

/// The bindings of TextField that vary by variant and size: the contract's `container` bindings.
struct TextFieldMetrics: Equatable, Sendable {
    /// `container.height`: a minimum, the field grows with its text; nil: the context's (inline).
    var height: Westron.Dimension?
    /// `container.paddingHorizontal`; nil: none (inline).
    var paddingHorizontal: Westron.Dimension?
    /// `container.radius`; nil: no shape of its own (inline).
    var radius: Westron.Dimension?

    /// The metrics of `variant` at the size the current OS draws for `size` (`TextFieldSize.offered`).
    init(variant: TextFieldVariant, size: TextFieldSize) {
        switch variant.offered {
        case .framed:
            switch size.offered {
            case .s:
                height = .size.control.s
                paddingHorizontal = .space100
            case .m:
                height = .size.control.m
                paddingHorizontal = .space150
            case .l:
                height = .size.control.l
                paddingHorizontal = .space200
            }
            radius = .radius.control
        case .inline:
            // The size changes nothing on an inline field (the contract's `size`).
            height = nil
            paddingHorizontal = nil
            radius = nil
        }
    }

    /// The corners of the focus ring around an `inline` field. The contract binds the ring's color and width; its
    /// place is the implementation's (decisions/0001, "Open points"). On `framed` the ring stands outside the outline,
    /// `framedRingGap` away, and the outline stays: focus changes the field's shape, one line to two, not only its
    /// color, since `border.focus` and `border.strong` are about as light (design-language/08, "Color is never the only
    /// signal"). Its corners follow the outline's, grown by the distance. On `inline`, which has no shape of its own,
    /// the ring stands around the field with the corners of a control.
    static let ringRadius: Westron.Dimension = .radius.control

    /// The gap between a `framed` field's outline and its ring.
    static let framedRingGap: Westron.Dimension = .space25

    /// How far the ring of an `inline` field stands outside its frame across, so that it does not touch the text: as
    /// far as a framed field's text stands from its outline at size s.
    static let inlineRingOutsetHorizontal: Westron.Dimension = .space100

    /// How far the ring of an `inline` field stands outside its frame up and down: less than across, since the line's
    /// own leading already holds the glyphs off the frame, and so that the ring reaches little into the space between
    /// the field and the text above and below it.
    static let inlineRingOutsetVertical: Westron.Dimension = .space50

    /// The smallest height of the area that takes a touch or a click on a `framed` field: the platform's recommended
    /// target (design-language/08, "Hit targets"), 44 pt on iOS, iPadOS and watchOS, which is `size.control.m` there,
    /// and 28 pt on macOS. Below it the field takes touches and clicks around what it draws. `inline` has no height of
    /// its own, and the contract binds it none.
    static var minimumHitHeight: CGFloat {
        #if os(macOS)
            // No token carries macOS's recommended target; chapter 08's table does.
            28  // westron-lint: allow chapter 08's recommended target on macOS, 28 pt, which no token carries
        #else
            CGFloat(Westron.Dimension.size.control.m)
        #endif
    }
}

extension TextFieldSize {
    /// The size a call draws: an explicit `size:` wins over the environment's `controlSize` (spec/conventions.md), and
    /// then the size the current OS offers in its place (on watchOS, m).
    static func resolved(explicit: TextFieldSize?, controlSize: ControlSize) -> TextFieldSize {
        (explicit ?? TextFieldSize(controlSize)).offered
    }
}
