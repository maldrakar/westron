// Hand-written. Disclosure's token bindings from its contract, spec/components/disclosure/disclosure.spec.yaml, as pure
// functions of the states, so that the style draws exactly what they return and the tests compare them with the
// contract's `tokens` block, case by case (Tests/WestronUITests/DisclosureStyleTests.swift).

#if !os(watchOS)
    import SwiftUI

    /// The tokens the chevron's cell draws with, for one set of states: the contract's bindings, each resolved by the
    /// first case that matches.
    struct DisclosureTokens: Equatable, Sendable {
        /// `chevron.color`.
        var chevron: Westron.Color
        /// `indicator.background`, the circle under the chevron; nil: no circle.
        var indicator: Westron.Color?
        /// `indicator.opacity`; nil: drawn whole.
        var opacity: Westron.Number?

        /// The tokens of a cell in `states`, which hold at once. A state the current OS never enters is ignored, and a
        /// disabled cell never enters hover or pressed (the contract's description).
        init(states: Set<DisclosureState>) {
            let states = Self.effective(states)
            chevron = .icon.tertiary
            // The cases of indicator.background, in the contract's order: disabled (none), pressed, hover.
            if states.contains(.disabled) {
                indicator = nil
            } else if states.contains(.pressed) {
                indicator = .background.pressed
            } else if states.contains(.hover) {
                indicator = .background.hover
            } else {
                indicator = nil
            }
            opacity = states.contains(.disabled) ? .opacity.disabled : nil
        }

        /// The states a cell is drawn in: those the current OS enters, and in disabled neither hover nor pressed.
        static func effective(_ states: Set<DisclosureState>) -> Set<DisclosureState> {
            var states = states.filter(\.isEntered)
            if states.contains(.disabled) { states.subtract([.hover, .pressed]) }
            return states
        }

        /// Whether a press scales the chevron and its circle down (`indicator.pressMotion`, chapter 05): pressed and not
        /// disabled. Reduce Motion drops the scale (`DisclosureMotion`).
        static func scalesDown(states: Set<DisclosureState>) -> Bool {
            effective(states).contains(.pressed)
        }

        /// The scale of a pressed control, 98 % (`motion.press`). Chapter 05 ("Shapes belong to components") fixes this
        /// one shape for every control, and puts a motion's shape in the component, not in the motion tokens.
        /// `ButtonTokens.pressScale`, `CheckboxMotion.pressScale` and `ChipTokens.pressScale` repeat it: change all.
        static let pressScale: CGFloat = 0.98  // westron-lint: allow a motion shape fixed by chapter 05
    }

    /// What moves when the group folds and the cell is hovered and pressed, and how (the contract's description;
    /// design-language/05): the shapes belong to the contract, the timing to the motion tokens.
    struct DisclosureMotion: Equatable {
        let reduceMotion: Bool

        /// The motion of a toggle by the chevron or the keyboard: `content.revealMotion` and `chevron.turnMotion`,
        /// `motion.move`, "a section folding", for the turn, the reveal and what stands after the group. With Reduce
        /// Motion none: nothing slides, the group's height and what follows it change at once (chapter 05).
        var toggle: Animation? { reduceMotion ? nil : .move }

        /// How the content comes and goes: with the toggle's own motion, or, with Reduce Motion, a fade of its own in
        /// `motion.fade`, travel's reduced form (decisions/0013), while the layout around it jumps.
        var contentTransition: AnyTransition { reduceMotion ? AnyTransition.opacity.animation(.fade) : .opacity }

        /// Whether the chevron turns between its directions; with Reduce Motion it points its new way at once, as a turn
        /// is travel (chapter 05).
        var turns: Bool { !reduceMotion }

        /// The scale of the cell while `scalesDown` (`DisclosureTokens.scalesDown`): 98 %, on `motion.press`; with Reduce
        /// Motion, none, as chapter 05 drops a scale and keeps the tint.
        func scale(pressed scalesDown: Bool) -> CGFloat {
            scalesDown && !reduceMotion ? DisclosureTokens.pressScale : 1
        }

        /// The motion of the circle's tint as a press begins and ends: `indicator.pressMotion`, `motion.press`, which
        /// Reduce Motion keeps.
        var press: Animation { .press }

        /// The motion of the circle's tint under the pointer: `indicator.hoverMotion`, `motion.fade`, which Reduce Motion
        /// keeps.
        var hover: Animation { .fade }
    }

    /// Disclosure's bindings that do not depend on the states.
    enum DisclosureMetrics {
        /// `indicator.size`, the circle's diameter at the default text size; it grows with the glyph, up to
        /// `structureLimit`.
        static let indicatorSize: Westron.Dimension = .size.control.s

        /// The glyph's symbol scale: the platform's small scale, relative to the text role that reaches the style
        /// (design-language/07, "Size relative to text").
        static let chevronScale: Image.Scale = .small

        /// The text size past which the cell stops growing, the glyph and the circle with it: where a ListRow's horizontal
        /// structure stops (`ListRowMetrics.structureLimit`), so that the cell in a row and the empty cell of a leaf keep
        /// one width at every size.
        static let structureLimit: DynamicTypeSize = ListRowMetrics.structureLimit

        /// The text style the circle scales relative to: the title's and the slots' of a ListRow, the label it is made for.
        static let textStyle: Font.TextStyle = ListRowMetrics.textStyle

        /// The least height and the least width of the cell, its hit area: `hitArea.size`, `size.target.minimum`, 44 pt on
        /// iOS and 28 pt on macOS, laid out around the circle, which stays centred in it.
        static var minimumHitSide: CGFloat { .size.target.minimum }

        /// The chevron's turn from the glyph, which points down: none while expanded; collapsed, a quarter turn to the
        /// trailing side, right in a left-to-right layout and left in a right-to-left one (the contract's description).
        static func angle(expanded: Bool, layoutDirection: LayoutDirection) -> Angle {
            if expanded { return .zero }
            return .degrees(layoutDirection == .rightToLeft ? quarterTurn : -quarterTurn)
        }

        /// A quarter turn, in degrees: the contract's shape of the chevron's turn, not a token.
        static let quarterTurn: Double = 90  // westron-lint: allow the contract's geometry
    }
#endif
