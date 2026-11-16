// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The public SwiftUI accessors of westron's lengths and motions. Each calls an adapter in TokenAdapters.swift with a
// value from WestronTokens: `CGFloat.radius.card` is `CGFloat(Westron.Dimension.radius.card)`. Colors and text roles
// need none: a view passes `Westron.Color` to the overloads in TokenAdapters.swift, `.foregroundStyle(.text.primary)`,
// and a role to `.textRole(.body.strong)`.

import SwiftUI
import WestronTokens

extension Animation {
    /// A change of color or opacity: a hover tint, a selection, a fade in or out. It has no spring and no bounce.
    public static var fade: Animation {
        Animation(Westron.Transition.fade)
    }

    /// A control answering a press: its tint, and its scale down to 98 %.
    public static var press: Animation {
        Animation(Westron.Transition.press)
    }

    /// A small thing changing place: a switch's thumb, a segmented control's selection, a checkbox.
    public static var toggle: Animation {
        Animation(Westron.Transition.toggle)
    }

    /// A check popping into a done task. The one motion with a visible overshoot.
    public static var check: Animation {
        Animation(Westron.Transition.check)
    }

    /// Something moving to a new place: a reordered row, a dropped item, a section folding or unfolding.
    public static var move: Animation {
        Animation(Westron.Transition.move)
    }

    /// Something appearing: a popover, a menu, an inserted row.
    public static var enter: Animation {
        Animation(Westron.Transition.enter)
    }

    /// Something leaving: a deleted row, a closing popover. Leaving is quicker than entering and does not bounce.
    public static var leave: Animation {
        Animation(Westron.Transition.leave)
    }

    /// A large surface appearing: a sheet, a side panel, an opened card.
    public static var reveal: Animation {
        Animation(Westron.Transition.reveal)
    }
}

extension CGFloat {
    /// Step 25 of the radius ladder: 2 px.
    public static var radius25: CGFloat {
        CGFloat(Westron.Dimension.radius25)
    }

    /// Step 50 of the radius ladder: 4 px.
    public static var radius50: CGFloat {
        CGFloat(Westron.Dimension.radius50)
    }

    /// Step 75 of the radius ladder: 6 px.
    public static var radius75: CGFloat {
        CGFloat(Westron.Dimension.radius75)
    }

    /// Step 100 of the radius ladder: 8 px.
    public static var radius100: CGFloat {
        CGFloat(Westron.Dimension.radius100)
    }

    /// Step 150 of the radius ladder: 12 px.
    public static var radius150: CGFloat {
        CGFloat(Westron.Dimension.radius150)
    }

    /// Step 200 of the radius ladder: 16 px.
    public static var radius200: CGFloat {
        CGFloat(Westron.Dimension.radius200)
    }

    /// Step 300 of the radius ladder: 24 px.
    public static var radius300: CGFloat {
        CGFloat(Westron.Dimension.radius300)
    }

    /// Step 400 of the radius ladder: 32 px.
    public static var radius400: CGFloat {
        CGFloat(Westron.Dimension.radius400)
    }

    /// The lengths `radius.*` in points.
    public enum radius {
        /// A control westron draws: a button, a field, a segmented control. 8 px, a quarter of a 32 px control.
        public static var control: CGFloat {
            CGFloat(Westron.Dimension.radius.control)
        }

        /// The highlight of a row under the pointer or selected.
        public static var row: CGFloat {
            CGFloat(Westron.Dimension.radius.row)
        }

        /// A card or a panel on the canvas.
        public static var card: CGFloat {
            CGFloat(Westron.Dimension.radius.card)
        }

        /// A popover or a menu westron draws; system ones keep their own.
        public static var overlay: CGFloat {
            CGFloat(Westron.Dimension.radius.overlay)
        }

        /// A sheet or a dialog westron draws.
        public static var sheet: CGFloat {
            CGFloat(Westron.Dimension.radius.sheet)
        }
    }

    /// Step 25 of the space ladder: 2 px.
    public static var space25: CGFloat {
        CGFloat(Westron.Dimension.space25)
    }

    /// Step 50 of the space ladder: 4 px.
    public static var space50: CGFloat {
        CGFloat(Westron.Dimension.space50)
    }

    /// Step 75 of the space ladder: 6 px.
    public static var space75: CGFloat {
        CGFloat(Westron.Dimension.space75)
    }

    /// Step 100 of the space ladder: 8 px.
    public static var space100: CGFloat {
        CGFloat(Westron.Dimension.space100)
    }

    /// Step 125 of the space ladder: 10 px.
    public static var space125: CGFloat {
        CGFloat(Westron.Dimension.space125)
    }

    /// Step 150 of the space ladder: 12 px.
    public static var space150: CGFloat {
        CGFloat(Westron.Dimension.space150)
    }

    /// Step 200 of the space ladder: 16 px.
    public static var space200: CGFloat {
        CGFloat(Westron.Dimension.space200)
    }

    /// Step 250 of the space ladder: 20 px.
    public static var space250: CGFloat {
        CGFloat(Westron.Dimension.space250)
    }

    /// Step 300 of the space ladder: 24 px.
    public static var space300: CGFloat {
        CGFloat(Westron.Dimension.space300)
    }

    /// Step 400 of the space ladder: 32 px.
    public static var space400: CGFloat {
        CGFloat(Westron.Dimension.space400)
    }

    /// Step 500 of the space ladder: 40 px.
    public static var space500: CGFloat {
        CGFloat(Westron.Dimension.space500)
    }

    /// Step 600 of the space ladder: 48 px.
    public static var space600: CGFloat {
        CGFloat(Westron.Dimension.space600)
    }

    /// Step 800 of the space ladder: 64 px.
    public static var space800: CGFloat {
        CGFloat(Westron.Dimension.space800)
    }

    /// The lengths `stroke.*` in points.
    public enum stroke {
        /// The edge of glass and of a card on a fill.
        public static var hairline: CGFloat {
            CGFloat(Westron.Dimension.stroke.hairline)
        }

        /// Rules, dividers, tree guides in a sidebar.
        public static var thin: CGFloat {
            CGFloat(Westron.Dimension.stroke.thin)
        }

        /// Guides on a phone, a dashed outline, a small check's ring.
        public static var regular: CGFloat {
            CGFloat(Westron.Dimension.stroke.regular)
        }

        /// A focus ring, a drop indicator, a selection ring.
        public static var thick: CGFloat {
            CGFloat(Westron.Dimension.stroke.thick)
        }
    }
}
