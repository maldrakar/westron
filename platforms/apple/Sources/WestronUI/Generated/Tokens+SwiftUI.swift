// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The public SwiftUI accessors of westron's semantic tokens. Each calls an adapter in TokenAdapters.swift with a value
// from WestronTokens: `Color.textSecondary` is `Color(Westron.Color.textSecondary)`, the colorset of that name.

import SwiftUI
import WestronTokens

extension Color {
    /// The ground of a screen, a list or a table.
    ///
    /// Use for: screen background, list background. Avoid: Cards and sheets: use background.surface.
    public static var backgroundCanvas: Color {
        Color(Westron.Color.backgroundCanvas)
    }

    /// Something raised off the canvas: a card, a sheet or a popover westron draws, a dragged row. White in light; one
    /// step lighter than the canvas in dark, where higher is lighter.
    ///
    /// Use for: card, sheet, popover, dragged row. Avoid: A well below the content: use background.sunken.
    public static var backgroundSurface: Color {
        Color(Westron.Color.backgroundSurface)
    }

    /// A well below the canvas: a sidebar, a code block, a log, a table header.
    ///
    /// Use for: sidebar, code block, log, table header. Avoid: A control's fill: use background.muted.
    public static var backgroundSunken: Color {
        Color(Westron.Color.backgroundSunken)
    }

    /// A quiet fill inside content: the track of a segmented control, a tag or a badge without a color.
    ///
    /// Use for: segmented track, neutral tag, neutral badge. Avoid: A row under the pointer: use background.hover.
    public static var backgroundMuted: Color {
        Color(Westron.Color.backgroundMuted)
    }

    /// A row or a control under the pointer.
    public static var backgroundHover: Color {
        Color(Westron.Color.backgroundHover)
    }

    /// A row or a control while it is pressed.
    public static var backgroundPressed: Color {
        Color(Westron.Color.backgroundPressed)
    }

    /// A selected row or item, tinted with the accent.
    ///
    /// Use for: selected row, selected item. Avoid: Color alone: in high contrast a selected row also shows a check or
    /// a border.focus outline.
    public static var backgroundSelected: Color {
        Color(Westron.Color.backgroundSelected)
    }

    /// A quiet accent ground: the tile behind an empty state's icon, a highlighted tip.
    public static var backgroundAccentSubtle: Color {
        Color(Westron.Color.backgroundAccentSubtle)
    }

    /// The fill of the one primary action on a screen, a checked box, a switch that is on.
    ///
    /// Use for: primary button, checked box, switch on. Avoid: Status: use status.info.fill, even though info is the
    /// accent's blue today.
    public static var backgroundAccent: Color {
        Color(Westron.Color.backgroundAccent)
    }

    /// The accent fill under the pointer.
    public static var backgroundAccentHover: Color {
        Color(Westron.Color.backgroundAccentHover)
    }

    /// Main text and glyphs.
    public static var textPrimary: Color {
        Color(Westron.Color.textPrimary)
    }

    /// Text and glyphs that come second: captions, metadata, a row's details, timestamps.
    public static var textSecondary: Color {
        Color(Westron.Color.textSecondary)
    }

    /// The placeholder of an empty field. It meets the text target, as all words do.
    public static var textPlaceholder: Color {
        Color(Westron.Color.textPlaceholder)
    }

    /// Text and glyphs on the accent fill: white, and the canvas's color in dark high contrast, where the fill turns
    /// light.
    public static var textOnAccent: Color {
        Color(Westron.Color.textOnAccent)
    }

    /// Links and accent text.
    ///
    /// Use for: link, accent text. Avoid: Status text: use status.<name>.text.
    public static var textAccent: Color {
        Color(Westron.Color.textAccent)
    }

    /// Glyphs that carry no words and need only 3:1: a chevron, a grip, a disclosure triangle.
    ///
    /// Use for: chevron, grip, disclosure. Avoid: Words: words are text.secondary at least.
    public static var iconTertiary: Color {
        Color(Westron.Color.iconTertiary)
    }

    /// Separators and the outline of a card: decorative in standard themes, 3:1 in high contrast, where every raised
    /// surface gets one.
    public static var borderDefault: Color {
        Color(Westron.Color.borderDefault)
    }

    /// The border of a control that must be seen: a field, a checkbox, a radio ring, a secondary button.
    public static var borderStrong: Color {
        Color(Westron.Color.borderStrong)
    }

    /// The focus ring, and the outline of a selected item in high contrast.
    public static var borderFocus: Color {
        Color(Westron.Color.borderFocus)
    }

    /// The quiet ground of a badge, a banner or a row in the status danger.
    public static var statusDangerBackground: Color {
        Color(Westron.Color.statusDangerBackground)
    }

    /// The border of a field or a banner in the status danger.
    public static var statusDangerBorder: Color {
        Color(Westron.Color.statusDangerBorder)
    }

    /// The icon or dot of the status danger.
    public static var statusDangerIcon: Color {
        Color(Westron.Color.statusDangerIcon)
    }

    /// Text in the status danger.
    public static var statusDangerText: Color {
        Color(Westron.Color.statusDangerText)
    }

    /// The solid fill of the status danger: a button or a count badge.
    public static var statusDangerFill: Color {
        Color(Westron.Color.statusDangerFill)
    }

    /// Text and glyphs on the danger fill.
    public static var statusDangerOnFill: Color {
        Color(Westron.Color.statusDangerOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status warning.
    public static var statusWarningBackground: Color {
        Color(Westron.Color.statusWarningBackground)
    }

    /// The border of a field or a banner in the status warning.
    public static var statusWarningBorder: Color {
        Color(Westron.Color.statusWarningBorder)
    }

    /// The icon or dot of the status warning.
    public static var statusWarningIcon: Color {
        Color(Westron.Color.statusWarningIcon)
    }

    /// Text in the status warning.
    public static var statusWarningText: Color {
        Color(Westron.Color.statusWarningText)
    }

    /// The solid fill of the status warning: a button or a count badge.
    public static var statusWarningFill: Color {
        Color(Westron.Color.statusWarningFill)
    }

    /// Text and glyphs on the warning fill.
    public static var statusWarningOnFill: Color {
        Color(Westron.Color.statusWarningOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status success.
    public static var statusSuccessBackground: Color {
        Color(Westron.Color.statusSuccessBackground)
    }

    /// The border of a field or a banner in the status success.
    public static var statusSuccessBorder: Color {
        Color(Westron.Color.statusSuccessBorder)
    }

    /// The icon or dot of the status success.
    public static var statusSuccessIcon: Color {
        Color(Westron.Color.statusSuccessIcon)
    }

    /// Text in the status success.
    public static var statusSuccessText: Color {
        Color(Westron.Color.statusSuccessText)
    }

    /// The solid fill of the status success: a button or a count badge.
    public static var statusSuccessFill: Color {
        Color(Westron.Color.statusSuccessFill)
    }

    /// Text and glyphs on the success fill.
    public static var statusSuccessOnFill: Color {
        Color(Westron.Color.statusSuccessOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status info.
    public static var statusInfoBackground: Color {
        Color(Westron.Color.statusInfoBackground)
    }

    /// The border of a field or a banner in the status info.
    public static var statusInfoBorder: Color {
        Color(Westron.Color.statusInfoBorder)
    }

    /// The icon or dot of the status info.
    public static var statusInfoIcon: Color {
        Color(Westron.Color.statusInfoIcon)
    }

    /// Text in the status info.
    public static var statusInfoText: Color {
        Color(Westron.Color.statusInfoText)
    }

    /// The solid fill of the status info: a button or a count badge.
    public static var statusInfoFill: Color {
        Color(Westron.Color.statusInfoFill)
    }

    /// Text and glyphs on the info fill.
    public static var statusInfoOnFill: Color {
        Color(Westron.Color.statusInfoOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status neutral.
    public static var statusNeutralBackground: Color {
        Color(Westron.Color.statusNeutralBackground)
    }

    /// The border of a field or a banner in the status neutral.
    public static var statusNeutralBorder: Color {
        Color(Westron.Color.statusNeutralBorder)
    }

    /// The icon or dot of the status neutral.
    public static var statusNeutralIcon: Color {
        Color(Westron.Color.statusNeutralIcon)
    }

    /// Text in the status neutral.
    public static var statusNeutralText: Color {
        Color(Westron.Color.statusNeutralText)
    }

    /// The solid fill of the status neutral: a button or a count badge.
    public static var statusNeutralFill: Color {
        Color(Westron.Color.statusNeutralFill)
    }

    /// Text and glyphs on the neutral fill.
    public static var statusNeutralOnFill: Color {
        Color(Westron.Color.statusNeutralOnFill)
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

    /// The quiet ground of a tag or a row in the list color.
    public static func categoryBackground(_ category: Westron.Category) -> Color {
        Color(category.background)
    }

    /// The border of an outlined tag in the list color.
    public static func categoryBorder(_ category: Westron.Category) -> Color {
        Color(category.border)
    }

    /// A dot or an icon in the list color.
    public static func categoryIcon(_ category: Westron.Category) -> Color {
        Color(category.icon)
    }

    /// Text in the list color.
    public static func categoryText(_ category: Westron.Category) -> Color {
        Color(category.text)
    }

    /// The solid fill of a lit tag in the list color.
    public static func categoryFill(_ category: Westron.Category) -> Color {
        Color(category.fill)
    }

    /// Text and glyphs on the fill of the list color.
    public static func categoryOnFill(_ category: Westron.Category) -> Color {
        Color(category.onFill)
    }
}

extension ShapeStyle where Self == Color {
    /// The ground of a screen, a list or a table.
    ///
    /// Use for: screen background, list background. Avoid: Cards and sheets: use background.surface.
    public static var backgroundCanvas: Color {
        Color(Westron.Color.backgroundCanvas)
    }

    /// Something raised off the canvas: a card, a sheet or a popover westron draws, a dragged row. White in light; one
    /// step lighter than the canvas in dark, where higher is lighter.
    ///
    /// Use for: card, sheet, popover, dragged row. Avoid: A well below the content: use background.sunken.
    public static var backgroundSurface: Color {
        Color(Westron.Color.backgroundSurface)
    }

    /// A well below the canvas: a sidebar, a code block, a log, a table header.
    ///
    /// Use for: sidebar, code block, log, table header. Avoid: A control's fill: use background.muted.
    public static var backgroundSunken: Color {
        Color(Westron.Color.backgroundSunken)
    }

    /// A quiet fill inside content: the track of a segmented control, a tag or a badge without a color.
    ///
    /// Use for: segmented track, neutral tag, neutral badge. Avoid: A row under the pointer: use background.hover.
    public static var backgroundMuted: Color {
        Color(Westron.Color.backgroundMuted)
    }

    /// A row or a control under the pointer.
    public static var backgroundHover: Color {
        Color(Westron.Color.backgroundHover)
    }

    /// A row or a control while it is pressed.
    public static var backgroundPressed: Color {
        Color(Westron.Color.backgroundPressed)
    }

    /// A selected row or item, tinted with the accent.
    ///
    /// Use for: selected row, selected item. Avoid: Color alone: in high contrast a selected row also shows a check or
    /// a border.focus outline.
    public static var backgroundSelected: Color {
        Color(Westron.Color.backgroundSelected)
    }

    /// A quiet accent ground: the tile behind an empty state's icon, a highlighted tip.
    public static var backgroundAccentSubtle: Color {
        Color(Westron.Color.backgroundAccentSubtle)
    }

    /// The fill of the one primary action on a screen, a checked box, a switch that is on.
    ///
    /// Use for: primary button, checked box, switch on. Avoid: Status: use status.info.fill, even though info is the
    /// accent's blue today.
    public static var backgroundAccent: Color {
        Color(Westron.Color.backgroundAccent)
    }

    /// The accent fill under the pointer.
    public static var backgroundAccentHover: Color {
        Color(Westron.Color.backgroundAccentHover)
    }

    /// Main text and glyphs.
    public static var textPrimary: Color {
        Color(Westron.Color.textPrimary)
    }

    /// Text and glyphs that come second: captions, metadata, a row's details, timestamps.
    public static var textSecondary: Color {
        Color(Westron.Color.textSecondary)
    }

    /// The placeholder of an empty field. It meets the text target, as all words do.
    public static var textPlaceholder: Color {
        Color(Westron.Color.textPlaceholder)
    }

    /// Text and glyphs on the accent fill: white, and the canvas's color in dark high contrast, where the fill turns
    /// light.
    public static var textOnAccent: Color {
        Color(Westron.Color.textOnAccent)
    }

    /// Links and accent text.
    ///
    /// Use for: link, accent text. Avoid: Status text: use status.<name>.text.
    public static var textAccent: Color {
        Color(Westron.Color.textAccent)
    }

    /// Glyphs that carry no words and need only 3:1: a chevron, a grip, a disclosure triangle.
    ///
    /// Use for: chevron, grip, disclosure. Avoid: Words: words are text.secondary at least.
    public static var iconTertiary: Color {
        Color(Westron.Color.iconTertiary)
    }

    /// Separators and the outline of a card: decorative in standard themes, 3:1 in high contrast, where every raised
    /// surface gets one.
    public static var borderDefault: Color {
        Color(Westron.Color.borderDefault)
    }

    /// The border of a control that must be seen: a field, a checkbox, a radio ring, a secondary button.
    public static var borderStrong: Color {
        Color(Westron.Color.borderStrong)
    }

    /// The focus ring, and the outline of a selected item in high contrast.
    public static var borderFocus: Color {
        Color(Westron.Color.borderFocus)
    }

    /// The quiet ground of a badge, a banner or a row in the status danger.
    public static var statusDangerBackground: Color {
        Color(Westron.Color.statusDangerBackground)
    }

    /// The border of a field or a banner in the status danger.
    public static var statusDangerBorder: Color {
        Color(Westron.Color.statusDangerBorder)
    }

    /// The icon or dot of the status danger.
    public static var statusDangerIcon: Color {
        Color(Westron.Color.statusDangerIcon)
    }

    /// Text in the status danger.
    public static var statusDangerText: Color {
        Color(Westron.Color.statusDangerText)
    }

    /// The solid fill of the status danger: a button or a count badge.
    public static var statusDangerFill: Color {
        Color(Westron.Color.statusDangerFill)
    }

    /// Text and glyphs on the danger fill.
    public static var statusDangerOnFill: Color {
        Color(Westron.Color.statusDangerOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status warning.
    public static var statusWarningBackground: Color {
        Color(Westron.Color.statusWarningBackground)
    }

    /// The border of a field or a banner in the status warning.
    public static var statusWarningBorder: Color {
        Color(Westron.Color.statusWarningBorder)
    }

    /// The icon or dot of the status warning.
    public static var statusWarningIcon: Color {
        Color(Westron.Color.statusWarningIcon)
    }

    /// Text in the status warning.
    public static var statusWarningText: Color {
        Color(Westron.Color.statusWarningText)
    }

    /// The solid fill of the status warning: a button or a count badge.
    public static var statusWarningFill: Color {
        Color(Westron.Color.statusWarningFill)
    }

    /// Text and glyphs on the warning fill.
    public static var statusWarningOnFill: Color {
        Color(Westron.Color.statusWarningOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status success.
    public static var statusSuccessBackground: Color {
        Color(Westron.Color.statusSuccessBackground)
    }

    /// The border of a field or a banner in the status success.
    public static var statusSuccessBorder: Color {
        Color(Westron.Color.statusSuccessBorder)
    }

    /// The icon or dot of the status success.
    public static var statusSuccessIcon: Color {
        Color(Westron.Color.statusSuccessIcon)
    }

    /// Text in the status success.
    public static var statusSuccessText: Color {
        Color(Westron.Color.statusSuccessText)
    }

    /// The solid fill of the status success: a button or a count badge.
    public static var statusSuccessFill: Color {
        Color(Westron.Color.statusSuccessFill)
    }

    /// Text and glyphs on the success fill.
    public static var statusSuccessOnFill: Color {
        Color(Westron.Color.statusSuccessOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status info.
    public static var statusInfoBackground: Color {
        Color(Westron.Color.statusInfoBackground)
    }

    /// The border of a field or a banner in the status info.
    public static var statusInfoBorder: Color {
        Color(Westron.Color.statusInfoBorder)
    }

    /// The icon or dot of the status info.
    public static var statusInfoIcon: Color {
        Color(Westron.Color.statusInfoIcon)
    }

    /// Text in the status info.
    public static var statusInfoText: Color {
        Color(Westron.Color.statusInfoText)
    }

    /// The solid fill of the status info: a button or a count badge.
    public static var statusInfoFill: Color {
        Color(Westron.Color.statusInfoFill)
    }

    /// Text and glyphs on the info fill.
    public static var statusInfoOnFill: Color {
        Color(Westron.Color.statusInfoOnFill)
    }

    /// The quiet ground of a badge, a banner or a row in the status neutral.
    public static var statusNeutralBackground: Color {
        Color(Westron.Color.statusNeutralBackground)
    }

    /// The border of a field or a banner in the status neutral.
    public static var statusNeutralBorder: Color {
        Color(Westron.Color.statusNeutralBorder)
    }

    /// The icon or dot of the status neutral.
    public static var statusNeutralIcon: Color {
        Color(Westron.Color.statusNeutralIcon)
    }

    /// Text in the status neutral.
    public static var statusNeutralText: Color {
        Color(Westron.Color.statusNeutralText)
    }

    /// The solid fill of the status neutral: a button or a count badge.
    public static var statusNeutralFill: Color {
        Color(Westron.Color.statusNeutralFill)
    }

    /// Text and glyphs on the neutral fill.
    public static var statusNeutralOnFill: Color {
        Color(Westron.Color.statusNeutralOnFill)
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

    /// The quiet ground of a tag or a row in the list color.
    public static func categoryBackground(_ category: Westron.Category) -> Color {
        Color(category.background)
    }

    /// The border of an outlined tag in the list color.
    public static func categoryBorder(_ category: Westron.Category) -> Color {
        Color(category.border)
    }

    /// A dot or an icon in the list color.
    public static func categoryIcon(_ category: Westron.Category) -> Color {
        Color(category.icon)
    }

    /// Text in the list color.
    public static func categoryText(_ category: Westron.Category) -> Color {
        Color(category.text)
    }

    /// The solid fill of a lit tag in the list color.
    public static func categoryFill(_ category: Westron.Category) -> Color {
        Color(category.fill)
    }

    /// Text and glyphs on the fill of the list color.
    public static func categoryOnFill(_ category: Westron.Category) -> Color {
        Color(category.onFill)
    }
}

extension Font {
    /// The title of a screen. The size follows the largeTitle text style (the pilot's largeTitle).
    public static var headingLarge: Font {
        Font(Westron.TextRole.headingLarge)
    }

    /// The title of an empty state or a short standalone message. The size follows the title3 text style (the pilot's
    /// emptyScreenTitle).
    public static var headingMedium: Font {
        Font(Westron.TextRole.headingMedium)
    }

    /// The title of a section or a block inside a screen. The size follows the headline text style (the pilot's
    /// sectionTitle).
    public static var headingSmall: Font {
        Font(Westron.TextRole.headingSmall)
    }

    /// A short label above a group, written in capitals by the product, such as an area's name in a sidebar. The size
    /// follows the caption text style (the pilot's areaCaption).
    public static var headingOverline: Font {
        Font(Westron.TextRole.headingOverline)
    }

    /// Main text: a row's title, a field's text, a search field. The size follows the body text style (the pilot's
    /// rowTitle, search).
    public static var bodyRegular: Font {
        Font(Westron.TextRole.bodyRegular)
    }

    /// Main text that needs emphasis: a row with children, the selected row, a card's title. The size follows the body
    /// text style (the pilot's rowTitleEmphasized).
    public static var bodyStrong: Font {
        Font(Westron.TextRole.bodyStrong)
    }

    /// Text one step below the main text: a nested row's title, a card in a column. The size follows the callout text
    /// style (the pilot's nestedRowTitle).
    public static var calloutRegular: Font {
        Font(Westron.TextRole.calloutRegular)
    }

    /// `callout.regular` with emphasis. The size follows the callout text style (the pilot's nestedRowTitleEmphasized).
    public static var calloutStrong: Font {
        Font(Westron.TextRole.calloutStrong)
    }

    /// Supporting text: counts, a subtitle, notes, a subtask's title. The size follows the subheadline text style (the
    /// pilot's count, notes).
    public static var subheadlineRegular: Font {
        Font(Westron.TextRole.subheadlineRegular)
    }

    /// A row that adds something, such as "Add task". The size follows the subheadline text style (the pilot's addRow).
    public static var subheadlineMedium: Font {
        Font(Westron.TextRole.subheadlineMedium)
    }

    /// A word on a bar or a button beside a glyph. The size follows the subheadline text style (the pilot's barLabel).
    public static var subheadlineStrong: Font {
        Font(Westron.TextRole.subheadlineStrong)
    }

    /// A hint under a title that says what to do. The size follows the footnote text style (the pilot's hint).
    public static var footnoteRegular: Font {
        Font(Westron.TextRole.footnoteRegular)
    }

    /// A small label: an area's name, a date, a tag's name. The size follows the footnote text style (the pilot's
    /// areaLabel).
    public static var footnoteMedium: Font {
        Font(Westron.TextRole.footnoteMedium)
    }

    /// The words on a chip or a pill. The size follows the footnote text style (the pilot's pill).
    public static var footnoteStrong: Font {
        Font(Westron.TextRole.footnoteStrong)
    }

    /// A line of metadata under a title. The size follows the caption text style (the pilot's meta).
    public static var captionMedium: Font {
        Font(Westron.TextRole.captionMedium)
    }
}

extension Animation {
    /// A check popping as a task is done.
    public static var check: Animation {
        Animation(Westron.Transition.check)
    }

    /// A check's ring and fill changing color.
    public static var checkFill: Animation {
        Animation(Westron.Transition.checkFill)
    }

    /// A check's mark drawing itself in and out, after its colors start.
    public static var checkMark: Animation {
        Animation(Westron.Transition.checkMark)
    }

    /// A title changing color as its task is checked.
    public static var titleFade: Animation {
        Animation(Westron.Transition.titleFade)
    }

    /// A done row leaving, after a wait long enough to read its check.
    public static var rowLeave: Animation {
        Animation(Westron.Transition.rowLeave)
    }

    /// A deleted row leaving at once.
    public static var rowDelete: Animation {
        Animation(Westron.Transition.rowDelete)
    }

    /// A small element appearing or moving into place: a row, a chevron, a dragged item.
    public static var popover: Animation {
        Animation(Westron.Transition.popover)
    }

    /// A card opening in place of its row.
    public static var cardOpen: Animation {
        Animation(Westron.Transition.cardOpen)
    }

    /// Something landing where it was dropped.
    public static var drop: Animation {
        Animation(Westron.Transition.drop)
    }

    /// A row sliding aside for its actions and back.
    public static var swipe: Animation {
        Animation(Westron.Transition.swipe)
    }

    /// A chevron turning as a section folds or opens.
    public static var fold: Animation {
        Animation(Westron.Transition.fold)
    }

    /// The highlight under something just moved, fading out.
    public static var highlightFade: Animation {
        Animation(Westron.Transition.highlightFade)
    }

    /// A chip lighting and going out.
    public static var chipToggle: Animation {
        Animation(Westron.Transition.chipToggle)
    }

    /// A drop target tinting under a drag, a dragged item dimming.
    public static var dropHighlight: Animation {
        Animation(Westron.Transition.dropHighlight)
    }

    /// A control's tint coming and going under the pointer.
    public static var hoverTint: Animation {
        Animation(Westron.Transition.hoverTint)
    }

    /// A card's shadow deepening under the pointer and back.
    public static var hoverShadow: Animation {
        Animation(Westron.Transition.hoverShadow)
    }
}

extension CGFloat {
    /// Step 75 of the radius ladder: 6 px.
    public static var radius75: CGFloat {
        CGFloat(Westron.Dimension.radius75)
    }

    /// Step 100 of the radius ladder: 8 px.
    public static var radius100: CGFloat {
        CGFloat(Westron.Dimension.radius100)
    }

    /// Step 125 of the radius ladder: 10 px.
    public static var radius125: CGFloat {
        CGFloat(Westron.Dimension.radius125)
    }

    /// Step 150 of the radius ladder: 12 px.
    public static var radius150: CGFloat {
        CGFloat(Westron.Dimension.radius150)
    }

    /// Step 175 of the radius ladder: 14 px.
    public static var radius175: CGFloat {
        CGFloat(Westron.Dimension.radius175)
    }

    /// Step 225 of the radius ladder: 18 px.
    public static var radius225: CGFloat {
        CGFloat(Westron.Dimension.radius225)
    }

    /// Step 25 of the space ladder: 2 px at the regular density.
    public static var space25: CGFloat {
        CGFloat(Westron.Dimension.space25)
    }

    /// Step 50 of the space ladder: 4 px at the regular density.
    public static var space50: CGFloat {
        CGFloat(Westron.Dimension.space50)
    }

    /// Step 75 of the space ladder: 6 px at the regular density.
    public static var space75: CGFloat {
        CGFloat(Westron.Dimension.space75)
    }

    /// Step 100 of the space ladder: 8 px at the regular density.
    public static var space100: CGFloat {
        CGFloat(Westron.Dimension.space100)
    }

    /// Step 125 of the space ladder: 10 px at the regular density.
    public static var space125: CGFloat {
        CGFloat(Westron.Dimension.space125)
    }

    /// Step 150 of the space ladder: 12 px at the regular density.
    public static var space150: CGFloat {
        CGFloat(Westron.Dimension.space150)
    }

    /// Step 175 of the space ladder: 14 px at the regular density.
    public static var space175: CGFloat {
        CGFloat(Westron.Dimension.space175)
    }

    /// Step 200 of the space ladder: 16 px at the regular density.
    public static var space200: CGFloat {
        CGFloat(Westron.Dimension.space200)
    }

    /// Step 250 of the space ladder: 20 px at the regular density.
    public static var space250: CGFloat {
        CGFloat(Westron.Dimension.space250)
    }

    /// Step 300 of the space ladder: 24 px at the regular density.
    public static var space300: CGFloat {
        CGFloat(Westron.Dimension.space300)
    }

    /// Step 500 of the space ladder: 40 px at the regular density.
    public static var space500: CGFloat {
        CGFloat(Westron.Dimension.space500)
    }

    /// Step 600 of the space ladder: 48 px at the regular density.
    public static var space600: CGFloat {
        CGFloat(Westron.Dimension.space600)
    }

    /// The edge of glass and of a card on a fill.
    public static var strokeHairline: CGFloat {
        CGFloat(Westron.Dimension.strokeHairline)
    }

    /// Rules, dividers, tree guides in a sidebar.
    public static var strokeThin: CGFloat {
        CGFloat(Westron.Dimension.strokeThin)
    }

    /// Guides on a phone, a dashed outline, a small check's ring.
    public static var strokeRegular: CGFloat {
        CGFloat(Westron.Dimension.strokeRegular)
    }

    /// A focus ring, a drop indicator, a selection ring.
    public static var strokeThick: CGFloat {
        CGFloat(Westron.Dimension.strokeThick)
    }
}
