// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The public SwiftUI accessors of westron's semantic tokens. Each calls an adapter in TokenAdapters.swift with a value
// from WestronTokens: `Color.textSecondary` is `Color(Westron.Color.textSecondary)`, the colorset of that name.

import SwiftUI
import WestronTokens

extension Color {
    /// The ground of a screen and of the rows on it.
    ///
    /// Use for: screen background, row background. Avoid: Cards and fields: use background.surface.
    public static var backgroundCanvas: Color {
        Color(Westron.Color.backgroundCanvas)
    }

    /// Something raised off the canvas: a card, a field, a dragged item.
    ///
    /// Use for: card, field, dragged item. Avoid: The ground of a whole screen: use background.canvas.
    public static var backgroundSurface: Color {
        Color(Westron.Color.backgroundSurface)
    }

    /// The sidebar column and its rows.
    public static var backgroundSidebar: Color {
        Color(Westron.Color.backgroundSidebar)
    }

    /// A quiet fill inside content: chips, pills, columns, a highlighted row on a phone.
    ///
    /// Use for: chip, pill, column, highlighted row. Avoid: The selected row in a sidebar: use background.selected.
    public static var backgroundMuted: Color {
        Color(Westron.Color.backgroundMuted)
    }

    /// The selected row in a sidebar: the accent laid lightly over the sidebar, mixed opaque.
    public static var backgroundSelected: Color {
        Color(Westron.Color.backgroundSelected)
    }

    /// Laid over a control or row under the pointer. Translucent.
    ///
    /// Use for: pointer hover. Avoid: Selection: use background.selected.
    public static var backgroundHover: Color {
        Color(Westron.Color.backgroundHover)
    }

    /// Laid over a control while it is pressed. Translucent.
    public static var backgroundPressed: Color {
        Color(Westron.Color.backgroundPressed)
    }

    /// Laid under something that just moved, fading out. Translucent.
    public static var backgroundHighlight: Color {
        Color(Westron.Color.backgroundHighlight)
    }

    /// A quiet accent fill: the slot a dragged item will drop into. Opaque.
    public static var backgroundAccentSubtle: Color {
        Color(Westron.Color.backgroundAccentSubtle)
    }

    /// The face of a floating control where the system has no glass of its own (before OS 26). Translucent; the
    /// platform blurs what is under it.
    ///
    /// Use for: floating control before OS 26. Avoid: The content layer; on OS 26 and later use the system's glass.
    public static var backgroundGlass: Color {
        Color(Westron.Color.backgroundGlass)
    }

    /// The fill of the primary action: a floating "+", Done. The accent, the same in light and dark.
    ///
    /// Use for: primary action fill. Avoid: Large areas, or more than one filled control on a screen; text and borders
    /// in the accent use text.accent and border.accent.
    public static var backgroundAccent: Color {
        Color(Westron.Color.backgroundAccent)
    }

    /// The fill of a destructive action, such as a swipe's Delete.
    public static var backgroundDanger: Color {
        Color(Westron.Color.backgroundDanger)
    }

    /// Main text and glyphs.
    public static var textPrimary: Color {
        Color(Westron.Color.textPrimary)
    }

    /// Supporting text and glyphs: counts, dates, metadata, notes, a done task's title.
    public static var textSecondary: Color {
        Color(Westron.Color.textSecondary)
    }

    /// What a field shows while it is empty. Translucent.
    public static var textPlaceholder: Color {
        Color(Westron.Color.textPlaceholder)
    }

    /// Text and glyphs on background.accent.
    ///
    /// Use for: on background.accent. Avoid: Any other background.
    public static var textOnAccent: Color {
        Color(Westron.Color.textOnAccent)
    }

    /// Text and glyphs on background.danger.
    ///
    /// Use for: on background.danger. Avoid: Any other background.
    public static var textOnDanger: Color {
        Color(Westron.Color.textOnDanger)
    }

    /// A word or glyph in the accent that acts, such as an action on an edit bar, or marks the chosen option.
    ///
    /// Use for: action word, chosen option's check. Avoid: Fills: use color.background.accent. Rings and indicators:
    /// use color.border.accent.
    public static var textAccent: Color {
        Color(Westron.Color.textAccent)
    }

    /// Text and glyphs that warn: a due deadline.
    public static var textDanger: Color {
        Color(Westron.Color.textDanger)
    }

    /// Quiet glyphs and decorations: a grip, a strike-through line. Meets 3:1, not 4.5:1.
    ///
    /// Use for: grip, strike-through. Avoid: Words of any size: use text.secondary.
    public static var iconTertiary: Color {
        Color(Westron.Color.iconTertiary)
    }

    /// Rules, dividers and outlines.
    public static var borderDefault: Color {
        Color(Westron.Color.borderDefault)
    }

    /// The guides down the branches of a tree in a sidebar.
    public static var borderGuide: Color {
        Color(Westron.Color.borderGuide)
    }

    /// The hairline round glass and round a card on a fill. Translucent.
    public static var borderGlass: Color {
        Color(Westron.Color.borderGlass)
    }

    /// A focus ring, a drop indicator, the outline of a drop slot.
    ///
    /// Use for: focus ring, drop indicator. Avoid: Text: use text.accent. Fills: use background.accent.
    public static var borderAccent: Color {
        Color(Westron.Color.borderAccent)
    }

    /// The tile under a list's glyph: the list color, translucent.
    public static func categoryBackground(_ category: Westron.Category) -> Color {
        Color(category.background)
    }

    /// A column or block tinted while something would drop into it: the list color, translucent.
    public static func categoryBackgroundSubtle(_ category: Westron.Category) -> Color {
        Color(category.backgroundSubtle)
    }

    /// Text and glyphs in the list color: a section title, the glyph on the list's tile.
    public static func categoryText(_ category: Westron.Category) -> Color {
        Color(category.text)
    }

    /// The ring of an open check in the list color.
    public static func categoryBorder(_ category: Westron.Category) -> Color {
        Color(category.border)
    }

    /// The disc of a done check, a lit chip: the list color.
    ///
    /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
    public static func categoryFill(_ category: Westron.Category) -> Color {
        Color(category.fill)
    }

    /// The mark on category fill: white, or the light ink where white would not stand out (amber).
    public static func categoryOnFill(_ category: Westron.Category) -> Color {
        Color(category.onFill)
    }
}

extension ShapeStyle where Self == Color {
    /// The ground of a screen and of the rows on it.
    ///
    /// Use for: screen background, row background. Avoid: Cards and fields: use background.surface.
    public static var backgroundCanvas: Color {
        Color(Westron.Color.backgroundCanvas)
    }

    /// Something raised off the canvas: a card, a field, a dragged item.
    ///
    /// Use for: card, field, dragged item. Avoid: The ground of a whole screen: use background.canvas.
    public static var backgroundSurface: Color {
        Color(Westron.Color.backgroundSurface)
    }

    /// The sidebar column and its rows.
    public static var backgroundSidebar: Color {
        Color(Westron.Color.backgroundSidebar)
    }

    /// A quiet fill inside content: chips, pills, columns, a highlighted row on a phone.
    ///
    /// Use for: chip, pill, column, highlighted row. Avoid: The selected row in a sidebar: use background.selected.
    public static var backgroundMuted: Color {
        Color(Westron.Color.backgroundMuted)
    }

    /// The selected row in a sidebar: the accent laid lightly over the sidebar, mixed opaque.
    public static var backgroundSelected: Color {
        Color(Westron.Color.backgroundSelected)
    }

    /// Laid over a control or row under the pointer. Translucent.
    ///
    /// Use for: pointer hover. Avoid: Selection: use background.selected.
    public static var backgroundHover: Color {
        Color(Westron.Color.backgroundHover)
    }

    /// Laid over a control while it is pressed. Translucent.
    public static var backgroundPressed: Color {
        Color(Westron.Color.backgroundPressed)
    }

    /// Laid under something that just moved, fading out. Translucent.
    public static var backgroundHighlight: Color {
        Color(Westron.Color.backgroundHighlight)
    }

    /// A quiet accent fill: the slot a dragged item will drop into. Opaque.
    public static var backgroundAccentSubtle: Color {
        Color(Westron.Color.backgroundAccentSubtle)
    }

    /// The face of a floating control where the system has no glass of its own (before OS 26). Translucent; the
    /// platform blurs what is under it.
    ///
    /// Use for: floating control before OS 26. Avoid: The content layer; on OS 26 and later use the system's glass.
    public static var backgroundGlass: Color {
        Color(Westron.Color.backgroundGlass)
    }

    /// The fill of the primary action: a floating "+", Done. The accent, the same in light and dark.
    ///
    /// Use for: primary action fill. Avoid: Large areas, or more than one filled control on a screen; text and borders
    /// in the accent use text.accent and border.accent.
    public static var backgroundAccent: Color {
        Color(Westron.Color.backgroundAccent)
    }

    /// The fill of a destructive action, such as a swipe's Delete.
    public static var backgroundDanger: Color {
        Color(Westron.Color.backgroundDanger)
    }

    /// Main text and glyphs.
    public static var textPrimary: Color {
        Color(Westron.Color.textPrimary)
    }

    /// Supporting text and glyphs: counts, dates, metadata, notes, a done task's title.
    public static var textSecondary: Color {
        Color(Westron.Color.textSecondary)
    }

    /// What a field shows while it is empty. Translucent.
    public static var textPlaceholder: Color {
        Color(Westron.Color.textPlaceholder)
    }

    /// Text and glyphs on background.accent.
    ///
    /// Use for: on background.accent. Avoid: Any other background.
    public static var textOnAccent: Color {
        Color(Westron.Color.textOnAccent)
    }

    /// Text and glyphs on background.danger.
    ///
    /// Use for: on background.danger. Avoid: Any other background.
    public static var textOnDanger: Color {
        Color(Westron.Color.textOnDanger)
    }

    /// A word or glyph in the accent that acts, such as an action on an edit bar, or marks the chosen option.
    ///
    /// Use for: action word, chosen option's check. Avoid: Fills: use color.background.accent. Rings and indicators:
    /// use color.border.accent.
    public static var textAccent: Color {
        Color(Westron.Color.textAccent)
    }

    /// Text and glyphs that warn: a due deadline.
    public static var textDanger: Color {
        Color(Westron.Color.textDanger)
    }

    /// Quiet glyphs and decorations: a grip, a strike-through line. Meets 3:1, not 4.5:1.
    ///
    /// Use for: grip, strike-through. Avoid: Words of any size: use text.secondary.
    public static var iconTertiary: Color {
        Color(Westron.Color.iconTertiary)
    }

    /// Rules, dividers and outlines.
    public static var borderDefault: Color {
        Color(Westron.Color.borderDefault)
    }

    /// The guides down the branches of a tree in a sidebar.
    public static var borderGuide: Color {
        Color(Westron.Color.borderGuide)
    }

    /// The hairline round glass and round a card on a fill. Translucent.
    public static var borderGlass: Color {
        Color(Westron.Color.borderGlass)
    }

    /// A focus ring, a drop indicator, the outline of a drop slot.
    ///
    /// Use for: focus ring, drop indicator. Avoid: Text: use text.accent. Fills: use background.accent.
    public static var borderAccent: Color {
        Color(Westron.Color.borderAccent)
    }

    /// The tile under a list's glyph: the list color, translucent.
    public static func categoryBackground(_ category: Westron.Category) -> Color {
        Color(category.background)
    }

    /// A column or block tinted while something would drop into it: the list color, translucent.
    public static func categoryBackgroundSubtle(_ category: Westron.Category) -> Color {
        Color(category.backgroundSubtle)
    }

    /// Text and glyphs in the list color: a section title, the glyph on the list's tile.
    public static func categoryText(_ category: Westron.Category) -> Color {
        Color(category.text)
    }

    /// The ring of an open check in the list color.
    public static func categoryBorder(_ category: Westron.Category) -> Color {
        Color(category.border)
    }

    /// The disc of a done check, a lit chip: the list color.
    ///
    /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
    public static func categoryFill(_ category: Westron.Category) -> Color {
        Color(category.fill)
    }

    /// The mark on category fill: white, or the light ink where white would not stand out (amber).
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
