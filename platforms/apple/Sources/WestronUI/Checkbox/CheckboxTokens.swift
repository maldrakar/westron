// Hand-written. Checkbox's token bindings from its contract, spec/components/checkbox/checkbox.spec.yaml, as pure
// functions of the context's list color and the states, so that CheckboxVariantStyle draws exactly what they return
// and the tests compare them with the contract's `tokens` block (Tests/WestronUITests/CheckboxStyleTests.swift).

import SwiftUI

/// The tokens a Checkbox draws with, for one list color and set of states: the contract's bindings, each resolved by
/// the first case that matches.
struct CheckboxTokens: Equatable, Sendable {
    /// `ring.color`; nil: no ring (checked).
    var ringColor: Westron.Color?
    /// `ring.width`; nil: no ring (checked).
    var ringWidth: Westron.Dimension?
    /// `disc.background`; nil: no disc (unchecked).
    var disc: Westron.Color?
    /// `mark.color`; nil: no mark (unchecked).
    var mark: Westron.Color?
    /// `container.opacity`; nil: drawn whole.
    var opacity: Westron.Number?

    /// The tokens of a check in `states`, which hold at once, in the list color `category` of its context; nil: the
    /// accent, the contract's bindings. A list color takes the disc and the mark from `color.category.<name>.control`
    /// and `.on-control` (the contract's description). A state the current OS never enters is ignored. `highContrast`:
    /// one of the high-contrast themes, `colorSchemeContrast == .increased`, where the ring is `color.border.strong`
    /// instead of the quiet `color.border.default` the bindings give (the contract's description, decisions/0003).
    init(category: Westron.Category?, states: Set<CheckboxState>, highContrast: Bool) {
        let states = states.filter(\.isEntered)
        if states.contains(.checked) {
            ringColor = nil
            ringWidth = nil
            disc = category?.control ?? .background.accent
            mark = category?.onControl ?? .text.onAccent
        } else {
            ringColor = highContrast ? .border.strong : .border.default
            ringWidth = .stroke.regular
            disc = nil
            mark = nil
        }
        opacity = states.contains(.disabled) ? .opacity.disabled : nil
    }

    /// Whether a press scales the check down (`container.pressMotion`, chapter 05): pressed and not disabled. A disabled
    /// toggle takes no press; the catalog can force both. Reduce Motion drops the scale (`CheckboxMotion`).
    static func scalesDown(states: Set<CheckboxState>) -> Bool {
        let states = states.filter(\.isEntered)
        return states.contains(.pressed) && !states.contains(.disabled)
    }
}

/// What moves when a check is checked, unchecked and pressed, and how far (the contract's description, P7, P14;
/// design-language/05): the shapes belong to the contract, the timing to the motion tokens.
struct CheckboxMotion: Equatable {
    let reduceMotion: Bool

    /// The scale the disc and its mark pop in from as the check is checked, 80 %, to full size on `motion.check`, whose
    /// bounce carries them past it and back; with Reduce Motion, full size: the fill only appears.
    var popScale: CGFloat { reduceMotion ? 1 : Self.popFrom }

    /// The motion of checking: `motion.check`; with Reduce Motion, a fade, which a spring's bounce does not belong to
    /// (chapter 05: travel becomes a fade, color fades stay).
    var check: Animation { reduceMotion ? .fade : .check }

    /// The motion of unchecking: the disc and the mark fade out, with no pop, on `motion.fade`.
    var uncheck: Animation { .fade }

    /// The scale of the check while `scalesDown`: 98 %, on `motion.press`; with Reduce Motion, none.
    func scale(pressed scalesDown: Bool) -> CGFloat {
        scalesDown && !reduceMotion ? Self.pressScale : 1
    }

    /// The scale of a pressed control, 98 % (`motion.press`). Chapter 05 ("Shapes belong to components") fixes this
    /// one shape for every control, and puts a motion's shape in the component, not in the motion tokens.
    /// `ButtonTokens.pressScale` repeats it: change both.
    static let pressScale: CGFloat = 0.98  // westron-lint: allow a motion's shape, fixed by chapter 05, is not a token

    /// The scale a check pops in from, 80 % (the contract's description, P14): a shape of the contract, not a token.
    static let popFrom: CGFloat = 0.8  // westron-lint: allow a motion's shape, set by the contract (P14)
}

/// The size of the check, which follows the text role of its label (the contract's description, P10): the circle's
/// diameter is a proportion of the line height of the text beside it, and its hit area is at least the platform's
/// recommended target.
enum CheckboxMetrics {
    /// The circle's diameter as a multiple of the line height of its label's text: 1.2, from the pilot, whose task
    /// check is 24 pt beside 17 pt body text on the phone (a line of about 20.3 pt) and 18 pt beside 13 pt on the Mac
    /// (a line of about 15.5 pt); both are about 1.2 lines (decisions/0001 of the contract, P10).
    static let diameterPerLine: CGFloat = 1.2  // westron-lint: allow a proportion to the text, set from the pilot (P10)

    /// The mark's side as a part of the circle's diameter: the pilot's mark is 15 pt in a 24 pt circle, and the
    /// registry's check glyph fills about nine tenths of its frame, so 0.55 of the diameter draws it about that size
    /// (P8: the mark is sized by the circle).
    static let markPerDiameter: CGFloat = 0.55  // westron-lint: allow the mark's proportion to its circle (P8)

    /// The circle's diameter beside text whose line is `lineHeight` tall.
    static func diameter(lineHeight: CGFloat) -> CGFloat {
        lineHeight * diameterPerLine
    }

    /// The side of the mark in a circle of `diameter`.
    static func mark(diameter: CGFloat) -> CGFloat {
        diameter * markPerDiameter
    }

    /// The least side of the check's hit area: the larger of `size.target.minimum`, the recommended target, and
    /// `size.control.m`, so 44 pt on iOS and watchOS and 32 pt on macOS, above its recommended 28 (chapter 08;
    /// tokens/platform; the contract, P17). Where the circle is smaller, the hit area stays this size around it; where
    /// it grows past it with the text, the hit area grows too.
    static var minimumHitSide: CGFloat { max(.size.target.minimum, .size.control.m) }

    /// The hit area's side around a circle of `diameter`.
    static func hitSide(diameter: CGFloat) -> CGFloat {
        max(minimumHitSide, diameter)
    }
}
