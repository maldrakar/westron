// Hand-written. TextField's token bindings from its contract, spec/components/text-field/text-field.spec.yaml, as pure
// functions of its options and states, so that TextFieldVariantStyle draws exactly what they return and the tests
// compare them with the contract's `tokens` block, case by case (Tests/WestronUITests/TextFieldStyleTests.swift).

import SwiftUI

/// The tokens a text field draws with, for one variant and set of states: the contract's `cases` bindings, each one
/// resolved as the contract resolves it, by the first case that matches; and in the high-contrast themes the outline the
/// contract's description adds to a framed field. nil where no case matches: the binding draws nothing, or, for the
/// text, leaves the font or the color to the context.
///
/// `placeholder.color` is not here: a `TextFieldStyle` cannot color the system field's prompt (the probe of #30), so
/// the field draws its prompt in the system's placeholder color: a platform difference the contract's `platforms.apple`
/// records (decisions/0001, I1). On iOS a product reaches `color.text.placeholder` by coloring its prompt itself.
struct TextFieldTokens: Equatable, Sendable {
    /// `container.background`; nil: no fill.
    var background: Westron.Color?
    /// The high-contrast outline's color; nil: no outline. The contract's bindings give none (decisions/0002).
    var borderColor: Westron.Color?
    /// The high-contrast outline's width; nil: no outline.
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
    /// (`TextFieldState.isEntered`). `highContrast`: one of the high-contrast themes, `colorSchemeContrast ==
    /// .increased`.
    init(variant: TextFieldVariant, states: Set<TextFieldState>, highContrast: Bool) {
        let states = states.filter(\.isEntered)
        switch variant.offered {
        case .framed:
            background = .background.muted
            textFont = .body.regular
            textColor = .text.primary
            // The muted fill stands about 1.1:1 off the canvas in every theme, the high-contrast ones included, so
            // there a framed field also draws its edge, in every state, as a secondary button does (the contract's
            // description). In the standard themes it has none: the owner accepted the fill alone (decisions/0002).
            borderColor = highContrast ? .border.strong : nil
            borderWidth = highContrast ? .stroke.thin : nil
        case .inline:
            background = nil
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

/// The bindings of TextField that vary by variant, size and lines: the contract's `container` bindings. `lines` is the
/// system field's own axis (the contract's `systemOptions`): `.vertical` is `multiple`, `.horizontal` is `single`.
struct TextFieldMetrics: Equatable, Sendable {
    /// `container.height`: a minimum, the field grows with its text; nil: the context's (inline).
    var height: Westron.Dimension?
    /// `container.paddingHorizontal`; nil: none (inline).
    var paddingHorizontal: Westron.Dimension?
    /// `container.paddingVertical`; nil: none (single, inline).
    var paddingVertical: Westron.Dimension?
    /// `container.shape`: whether the field is the platform's capsule (framed, single).
    var isCapsule: Bool
    /// `container.radius`; nil: no corners of its own, a capsule or none (inline).
    var radius: Westron.Dimension?

    /// The metrics of `variant` at the size the current OS draws for `size` (`TextFieldSize.offered`), on a field of
    /// `axis`.
    init(variant: TextFieldVariant, size: TextFieldSize, axis: Axis) {
        switch variant.offered {
        case .framed:
            let multiple = axis == .vertical
            switch size.offered {
            case .s:
                height = .size.control.s
                paddingHorizontal = .space200
                paddingVertical = multiple ? .space50 : nil
            case .m:
                height = .size.control.m
                paddingHorizontal = .space250
                paddingVertical = multiple ? .space100 : nil
            case .l:
                height = .size.control.l
                paddingHorizontal = .space300
                paddingVertical = multiple ? .space150 : nil
            }
            // One line is a capsule; several are a rounded rectangle, since a capsule's ends would cut into them.
            isCapsule = !multiple
            radius = multiple ? .radius150 : nil
        case .inline:
            // The size and the lines change nothing on an inline field (the contract's `size` and `lines`).
            height = nil
            paddingHorizontal = nil
            paddingVertical = nil
            isCapsule = false
            radius = nil
        }
    }

    /// The corners of the focus ring around an `inline` field. The contract binds the ring's color and width; its
    /// place is the implementation's (decisions/0001, "Open points"). On `framed` the ring stands outside the field's
    /// frame, its inner edge against the field's edge with no gap (the owner's decision of 2026-11-20, decisions/0002),
    /// and follows its shape: around a capsule a capsule, around a rounded rectangle one whose corners are grown by the
    /// ring's width. Focus adds a line where there was none, so it changes the field's shape, not only a color
    /// (design-language/08, "Color is never the only signal"); in the high-contrast themes, where the field has an
    /// outline, the ring lies against the outline and the line grows from `stroke.thin` to `stroke.thin` plus
    /// `stroke.thick`, in a second color. On `inline`, which has no shape of its own, the ring stands around the field
    /// with the corners of a control.
    static let ringRadius: Westron.Dimension = .radius.control

    /// How far the ring of an `inline` field stands outside its frame across, so that it does not touch the text.
    static let inlineRingOutsetHorizontal: Westron.Dimension = .space100

    /// How far the ring of an `inline` field stands outside its frame up and down: less than across, since the line's
    /// own leading already holds the glyphs off the frame, and so that the ring reaches little into the space between
    /// the field and the text above and below it.
    static let inlineRingOutsetVertical: Westron.Dimension = .space50

    /// The smallest height of the area that takes a touch or a click on a `framed` field: the platform's recommended
    /// target, `size.target.minimum` (design-language/08, "Hit targets"), 44 pt on iOS, iPadOS and watchOS and 28 pt on
    /// macOS. Below it the field takes touches and clicks around what it draws. `inline` has no height of its own, and
    /// the contract binds it none.
    static var minimumHitHeight: CGFloat { .size.target.minimum }
}

/// The axis of a system text field, which gives the contract's `lines` (its `systemOptions`). A `TextFieldStyle` is
/// given the field itself, and SwiftUI offers no public way to read its axis, so it is read by reflection: the field
/// stores the axis it was created with, `TextField(_:text:axis:)`, as `axis`, measured with Xcode 27.1 on iOS 26.3 and
/// macOS 26.7 (TextFieldStyleTests; decisions/0002, pending the owner's confirmation). Where reflection finds no axis,
/// as in a SwiftUI that would store it otherwise, the field is drawn as a single line.
enum TextFieldAxis {
    static func of(_ field: Any) -> Axis {
        read(field) ?? .horizontal
    }

    /// The axis reflection finds, or nil where it finds none.
    static func read(_ field: Any) -> Axis? {
        Mirror(reflecting: field).children.first { $0.label == "axis" }?.value as? Axis
    }
}

extension TextFieldSize {
    /// The size a call draws: an explicit `size:` wins over the environment's `controlSize` (spec/conventions.md), and
    /// then the size the current OS offers in its place (on watchOS, m).
    static func resolved(explicit: TextFieldSize?, controlSize: ControlSize) -> TextFieldSize {
        (explicit ?? TextFieldSize(controlSize)).offered
    }
}
