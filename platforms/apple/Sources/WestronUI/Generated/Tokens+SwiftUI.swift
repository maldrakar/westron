// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The public SwiftUI accessors of westron's semantic tokens. Each calls an adapter in TokenAdapters.swift with a value
// from WestronTokens: `Color.text.secondary` is `Color(Westron.Color.text.secondary)`, the colorset of that name, and
// `Color.text` is WestronTokens' group `Westron.Color.text` with SwiftUI colors. Text roles have no statics on `Font`,
// where `Font.body` would become ambiguous: a role is `.textRole(.body.strong)` or `Font(.body.strong)`.

import SwiftUI
import WestronTokens

extension Color {
    /// The colors `color.background.*` as SwiftUI colors, from their colorsets.
    public static let background = Westron.Color.background.map { Color($0) }

    /// The colors `color.text.*` as SwiftUI colors, from their colorsets.
    public static let text = Westron.Color.text.map { Color($0) }

    /// The colors `color.icon.*` as SwiftUI colors, from their colorsets.
    public static let icon = Westron.Color.icon.map { Color($0) }

    /// The colors `color.border.*` as SwiftUI colors, from their colorsets.
    public static let border = Westron.Color.border.map { Color($0) }

    /// The colors `color.status.*` as SwiftUI colors, from their colorsets.
    public static let status = Westron.Color.status.map { Color($0) }

    /// Series 1 of a chart.
    public static var chart1: Color {
        Color(Westron.Color.chart1)
    }

    /// Series 2 of a chart.
    public static var chart2: Color {
        Color(Westron.Color.chart2)
    }

    /// Series 3 of a chart.
    public static var chart3: Color {
        Color(Westron.Color.chart3)
    }

    /// Series 4 of a chart.
    public static var chart4: Color {
        Color(Westron.Color.chart4)
    }

    /// Series 5 of a chart.
    public static var chart5: Color {
        Color(Westron.Color.chart5)
    }

    /// Series 6 of a chart.
    public static var chart6: Color {
        Color(Westron.Color.chart6)
    }

    /// Series 7 of a chart.
    public static var chart7: Color {
        Color(Westron.Color.chart7)
    }

    /// Series 8 of a chart.
    public static var chart8: Color {
        Color(Westron.Color.chart8)
    }

    /// A list's colors by role, as SwiftUI colors from their colorsets: `.category(.amber).text`.
    public static func category(_ category: Westron.Category) -> Westron.Category.Roles<Color> {
        category.roles.map { Color($0) }
    }
}

extension ShapeStyle where Self == Color {
    /// The colors `color.background.*` as SwiftUI colors, from their colorsets.
    public static var background: Westron.Color.Background<Color> {
        Color.background
    }

    /// The colors `color.text.*` as SwiftUI colors, from their colorsets.
    public static var text: Westron.Color.Text<Color> {
        Color.text
    }

    /// The colors `color.icon.*` as SwiftUI colors, from their colorsets.
    public static var icon: Westron.Color.Icon<Color> {
        Color.icon
    }

    /// The colors `color.border.*` as SwiftUI colors, from their colorsets.
    public static var border: Westron.Color.Border<Color> {
        Color.border
    }

    /// The colors `color.status.*` as SwiftUI colors, from their colorsets.
    public static var status: Westron.Color.Status<Color> {
        Color.status
    }

    /// Series 1 of a chart.
    public static var chart1: Color {
        Color(Westron.Color.chart1)
    }

    /// Series 2 of a chart.
    public static var chart2: Color {
        Color(Westron.Color.chart2)
    }

    /// Series 3 of a chart.
    public static var chart3: Color {
        Color(Westron.Color.chart3)
    }

    /// Series 4 of a chart.
    public static var chart4: Color {
        Color(Westron.Color.chart4)
    }

    /// Series 5 of a chart.
    public static var chart5: Color {
        Color(Westron.Color.chart5)
    }

    /// Series 6 of a chart.
    public static var chart6: Color {
        Color(Westron.Color.chart6)
    }

    /// Series 7 of a chart.
    public static var chart7: Color {
        Color(Westron.Color.chart7)
    }

    /// Series 8 of a chart.
    public static var chart8: Color {
        Color(Westron.Color.chart8)
    }

    /// A list's colors by role, as SwiftUI colors from their colorsets: `.category(.amber).text`.
    public static func category(_ category: Westron.Category) -> Westron.Category.Roles<Color> {
        Color.category(category)
    }
}

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
    public static let radius = Westron.Dimension.radius.map { CGFloat($0) }

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
    public static let stroke = Westron.Dimension.stroke.map { CGFloat($0) }
}
