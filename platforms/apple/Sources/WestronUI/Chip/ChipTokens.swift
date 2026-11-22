// Hand-written. Chip's token bindings from its contract, spec/components/chip/chip.spec.yaml, as pure functions of the
// context's list color and the states, so that the three Chip styles draw exactly what they return and the tests compare
// them with the contract's `tokens` block, case by case (Tests/WestronUITests/ChipStyleTests.swift).

import SwiftUI

/// The tokens a Chip draws with, for one list color and set of states: the contract's bindings, each resolved by the
/// first case that matches; and in the high-contrast themes the outline the contract's description adds.
struct ChipTokens: Equatable, Sendable {
    /// `container.background`.
    var background: Westron.Color
    /// The high-contrast outline's color; nil: no border. The contract's bindings give no border.
    var borderColor: Westron.Color?
    /// The high-contrast outline's width; nil: no border.
    var borderWidth: Westron.Dimension?
    /// `container.opacity`; nil: drawn whole.
    var opacity: Westron.Number?
    /// `label.color`.
    var label: Westron.Color
    /// `icon.color`, also the check's color while the chip shows it.
    var icon: Westron.Color
    /// Whether the chip shows the check, the registry's `check` glyph, in the icon's place, or before a label that is
    /// only text: checked (the contract's description; decisions/0001, revision A). The check is drawn in `icon`.
    var mark: Bool

    /// The tokens of a chip in `states`, which hold at once, in the list color `category` of its context; nil: the
    /// accent, the contract's bindings. A state the current OS never enters is ignored, and a disabled chip never
    /// enters hover or pressed (the contract's description). Checked in a list's color, the fill is
    /// `color.category.<name>.fill` and the words `on-fill`, and the fill stays under the pointer and pressed
    /// (decisions/0001, Q4, Q5). `highContrast`: one of the high-contrast themes, `colorSchemeContrast == .increased`,
    /// where every chip also draws `color.border.strong` at `stroke.thin`.
    init(category: Westron.Category?, states: Set<ChipState>, highContrast: Bool) {
        let states = Self.effective(states)
        let pressed = states.contains(.pressed)
        let hover = states.contains(.hover)
        // The cases of container.background, in the contract's order: checked and pressed, checked and hover,
        // checked, pressed, hover; then the binding's token.
        if states.contains(.checked) {
            if let category {
                background = category.fill
            } else {
                background = pressed ? .background.accentPressed : hover ? .background.accentHover : .background.accent
            }
            label = category?.onFill ?? .text.onAccent
            icon = category?.onFill ?? .text.onAccent
        } else {
            background = pressed ? .background.mutedPressed : hover ? .background.mutedHover : .background.muted
            label = .text.primary
            icon = .text.secondary
        }
        if highContrast {
            borderColor = .border.strong
            borderWidth = .stroke.thin
        } else {
            borderColor = nil
            borderWidth = nil
        }
        opacity = states.contains(.disabled) ? .opacity.disabled : nil
        mark = states.contains(.checked)
    }

    /// The states a chip is drawn in: those the current OS enters, and in disabled neither hover nor pressed.
    static func effective(_ states: Set<ChipState>) -> Set<ChipState> {
        var states = states.filter(\.isEntered)
        if states.contains(.disabled) { states.subtract([.hover, .pressed]) }
        return states
    }

    /// Whether a press scales the chip down (`container.pressMotion`, chapter 05): pressed and not disabled. Reduce
    /// Motion drops the scale (`ChipMotion`).
    static func scalesDown(states: Set<ChipState>) -> Bool {
        effective(states).contains(.pressed)
    }

    /// The scale of a pressed chip, 98 % (`motion.press`). Chapter 05 ("Shapes belong to components") fixes this one
    /// shape for every control, and puts a motion's shape in the component, not in the motion tokens.
    /// `ButtonTokens.pressScale` and `CheckboxMotion.pressScale` repeat it: change all three.
    static let pressScale: CGFloat = 0.98  // westron-lint: allow a motion's shape, fixed by chapter 05, is not a token
}

/// What moves when a chip is hovered, pressed and checked, and how (the contract's description; design-language/05):
/// the shapes belong to the contract, the timing to the motion tokens.
struct ChipMotion: Equatable {
    let reduceMotion: Bool

    /// The scale of the chip while `scalesDown` (`ChipTokens.scalesDown`): 98 %, on `motion.press`; with Reduce Motion,
    /// none, as chapter 05 drops a scale and keeps the tint.
    func scale(pressed scalesDown: Bool) -> CGFloat {
        scalesDown && !reduceMotion ? ChipTokens.pressScale : 1
    }

    /// The motion of the fill's tint as a press begins and ends: `container.pressMotion`, `motion.press`, with or
    /// without Reduce Motion, which keeps a press's tint.
    var press: Animation { .press }

    /// The motion of the fill's tint under the pointer: `container.hoverMotion`, `motion.fade`, a color fade, which
    /// Reduce Motion keeps.
    var hover: Animation { .fade }

    /// The motion of checking: the fill, the words' color and the check coming in or going, as a fade
    /// (`container.checkMotion`, `motion.fade`), which Reduce Motion keeps.
    var check: Animation { .fade }

    /// The motion of a text-only chip's width as the check comes in or goes before its label: with the fill, in
    /// `motion.fade`; with Reduce Motion, none, so that nothing slides: the width changes at once (chapter 05, "Travel
    /// becomes a fade").
    var resize: Animation? { reduceMotion ? nil : .fade }
}

/// Chip's bindings that do not depend on the states: its one size.
enum ChipMetrics {
    /// `container.height`: a minimum, the chip grows with its text (the contract's description).
    static let height: Westron.Dimension = .size.control.s
    /// `container.paddingHorizontal`, on both sides (decisions/0001, Q10).
    static let paddingHorizontal: Westron.Dimension = .space125
    /// `container.gap`, between the icon and the label.
    static let gap: Westron.Dimension = .space50
    /// `label.font`.
    static let labelFont: Westron.TextRole = .footnote.strong
    /// `icon.font`, the label's.
    static let iconFont: Westron.TextRole = .footnote.strong
    /// The icon's symbol scale: small, in `icon.font`, as Button's (the contract's `platforms.apple`).
    static let iconScale: Image.Scale = .small

    /// The least height and the least width of the hit area of the selectable and pressable forms:
    /// `size.target.minimum`, 44 pt on iOS and watchOS and 28 pt on macOS, laid out around the drawn chip, which stays
    /// centred in it (decisions/0001, Q11 and revision C). Where the chip is larger, across or with the text, the hit
    /// area is the chip on that side.
    static var minimumHitSide: CGFloat { .size.target.minimum }
}
