// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The public SwiftUI accessors of westron's lengths, numbers and motions. Each calls an adapter in TokenAdapters.swift
// with a value from WestronTokens: `CGFloat.radius.card` is `CGFloat(Westron.Dimension.radius.card)`,
// `Double.opacity.disabled` is `Double(Westron.Number.opacity.disabled)`. Colors and text roles need none: a view
// passes `Westron.Color` to the overloads in TokenAdapters.swift, `.foregroundStyle(.text.primary)`, and a role to
// `.textRole(.body.strong)`.

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

    /// The lengths `space.*` in points.
    public enum space {
        /// A card's padding: the inset between a card's or a panel's edge and its content. 16 px in the comfortable
        /// density.
        ///
        /// Use for: card padding, panel padding, inset of a grouped block the product draws. Avoid: A system List, Form
        /// or bar, which keeps its own insets. A gap between elements: use space.within-group or space.between-groups.
        public static var card: CGFloat {
            CGFloat(Westron.Dimension.space.card)
        }

        /// The gap between the elements of one group: the fields of a form section, the cards of a column, the lines of
        /// a block. 12 px in the comfortable density, half the gap between groups, so the grouping shows through space.
        ///
        /// Use for: stack spacing inside a group, gap between cards in a column, gap between a heading and its content.
        /// Avoid: The gap between two groups: use space.between-groups. A component's own internal gap, which its
        /// contract gives.
        public static var withinGroup: CGFloat {
            CGFloat(Westron.Dimension.space.withinGroup)
        }

        /// The gap between two groups or sections of a screen. 24 px, twice the gap within a group; a density keeps it.
        ///
        /// Use for: stack spacing between sections, gap between groups of a form, gap between blocks of a page. Avoid:
        /// The gap inside a group: use space.within-group. A separator line where the space already shows the grouping.
        public static var betweenGroups: CGFloat {
            CGFloat(Westron.Dimension.space.betweenGroups)
        }

        /// The lengths `space.page.*` in points.
        public enum page {
            /// The page margin on a narrow window: on Apple, the horizontal size class compact. 20 px; a density keeps
            /// it. It applies to layout the product builds itself, such as a ScrollView or a stack; the system's List,
            /// Form and bars keep their own insets.
            ///
            /// Use for: horizontal margin of a scrolling page on a phone, margin of a stack laid out by the product.
            /// Avoid: A system List, Form or bar, which keeps its own insets. A wide window: use space.page.wide.
            public static var narrow: CGFloat {
                CGFloat(Westron.Dimension.space.page.narrow)
            }

            /// The page margin on a wide window: on Apple, the horizontal size class regular, and always on a Mac. 32
            /// px; a density keeps it. It applies to layout the product builds itself, such as a ScrollView or a stack;
            /// the system's List, Form and bars keep their own insets.
            ///
            /// Use for: horizontal margin of a page on an iPad or a Mac, margin of a stack laid out by the product.
            /// Avoid: A system List, Form or bar, which keeps its own insets. A narrow window: use space.page.narrow.
            public static var wide: CGFloat {
                CGFloat(Westron.Dimension.space.page.wide)
            }
        }
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

    /// The lengths `size.*` in points.
    public enum size {
        /// The lengths `size.control.*` in points.
        public enum control {
            /// The height of a control at size s: 24 on macOS, 32 on iOS, iPadOS and watchOS. On touch platforms it is
            /// below the recommended target, so its hit area stays the target's size (chapter 08).
            ///
            /// Use for: small button, small field, control in a toolbar or a table row. Avoid: The default size: use
            /// size.control.m. A row's height: rows have heights of their own.
            public static var s: CGFloat {
                CGFloat(Westron.Dimension.size.control.s)
            }

            /// The height of a control at the default size m: a button, a field, a segmented control. 32 on macOS,
            /// westron's control (decisions/0013); 44 on iOS, iPadOS and watchOS, the touch target (chapter 08).
            ///
            /// Use for: button, field, segmented control. Avoid: A row's height: rows have heights of their own. A
            /// fixed height where text can grow: the height is a minimum.
            public static var m: CGFloat {
                CGFloat(Westron.Dimension.size.control.m)
            }

            /// The height of a control at size l: the one prominent action of a form, a sheet or an empty state. 40 on
            /// macOS, 52 on iOS, iPadOS and watchOS.
            ///
            /// Use for: prominent button, call to action. Avoid: Every control on a screen: the large size marks the
            /// one action that leads.
            public static var l: CGFloat {
                CGFloat(Westron.Dimension.size.control.l)
            }
        }
    }
}

extension Double {
    /// The numbers `opacity.*` as Double.
    public enum opacity {
        /// A disabled control, drawn whole at this opacity: its fill, border, label and icon together, so it keeps its
        /// shape and its variant but reads as unavailable. It sits between Apple's disabled labels (iOS's tertiary
        /// label is 30 %) and libadwaita's --disabled-opacity (50 %, 40 % in high contrast). WCAG exempts an inactive
        /// control from contrast (chapter 08).
        ///
        /// Use for: disabled button, disabled field, disabled toggle, disabled row. Avoid: Colors of its own for the
        /// disabled state, or dimming the parts one by one; and something that is only secondary, which takes
        /// text.secondary and stays readable. A system control that the platform disables keeps the platform's look.
        public static var disabled: Double {
            Double(Westron.Number.opacity.disabled)
        }
    }
}
