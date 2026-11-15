// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The values of westron's semantic tokens as plain Swift, with no imports, so that shared code and its WebAssembly
// build can use them; their types are in Westron.swift, their SwiftUI accessors in WestronUI.

extension Westron.Color {
    /// The ground of a screen, a list or a table.
    ///
    /// Use for: screen background, list background. Avoid: Cards and sheets: use background.surface.
    public static let backgroundCanvas = Westron.Color(
        name: "color.background.canvas",
        light: Westron.RGB(hex: 0xF7FAFF),
        dark: Westron.RGB(hex: 0x101318),
        lightHighContrast: Westron.RGB(hex: 0xF7FAFF),
        darkHighContrast: Westron.RGB(hex: 0x101318))

    /// Something raised off the canvas: a card, a sheet or a popover westron draws, a dragged row. White in light; one
    /// step lighter than the canvas in dark, where higher is lighter.
    ///
    /// Use for: card, sheet, popover, dragged row. Avoid: A well below the content: use background.sunken.
    public static let backgroundSurface = Westron.Color(
        name: "color.background.surface",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0x181C21),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x181C21))

    /// A well below the canvas: a sidebar, a code block, a log, a table header.
    ///
    /// Use for: sidebar, code block, log, table header. Avoid: A control's fill: use background.muted.
    public static let backgroundSunken = Westron.Color(
        name: "color.background.sunken",
        light: Westron.RGB(hex: 0xF0F3F8),
        dark: Westron.RGB(hex: 0x090C10),
        lightHighContrast: Westron.RGB(hex: 0xF0F3F8),
        darkHighContrast: Westron.RGB(hex: 0x090C10))

    /// A quiet fill inside content: the track of a segmented control, a tag or a badge without a color.
    ///
    /// Use for: segmented track, neutral tag, neutral badge. Avoid: A row under the pointer: use background.hover.
    public static let backgroundMuted = Westron.Color(
        name: "color.background.muted",
        light: Westron.RGB(hex: 0xEBEEF4),
        dark: Westron.RGB(hex: 0x22272D),
        lightHighContrast: Westron.RGB(hex: 0xEBEEF4),
        darkHighContrast: Westron.RGB(hex: 0x22272D))

    /// A row or a control under the pointer.
    public static let backgroundHover = Westron.Color(
        name: "color.background.hover",
        light: Westron.RGB(hex: 0xEDF0F6),
        dark: Westron.RGB(hex: 0x1F232A),
        lightHighContrast: Westron.RGB(hex: 0xEDF0F6),
        darkHighContrast: Westron.RGB(hex: 0x1F232A))

    /// A row or a control while it is pressed.
    public static let backgroundPressed = Westron.Color(
        name: "color.background.pressed",
        light: Westron.RGB(hex: 0xE6E9EF),
        dark: Westron.RGB(hex: 0x292E34),
        lightHighContrast: Westron.RGB(hex: 0xE6E9EF),
        darkHighContrast: Westron.RGB(hex: 0x292E34))

    /// A selected row or item, tinted with the accent.
    ///
    /// Use for: selected row, selected item. Avoid: Color alone: in high contrast a selected row also shows a check or
    /// a border.focus outline.
    public static let backgroundSelected = Westron.Color(
        name: "color.background.selected",
        light: Westron.RGB(hex: 0xDDEAFF),
        dark: Westron.RGB(hex: 0x202E45),
        lightHighContrast: Westron.RGB(hex: 0xDDEAFF),
        darkHighContrast: Westron.RGB(hex: 0x202E45))

    /// A quiet accent ground: the tile behind an empty state's icon, a highlighted tip.
    public static let backgroundAccentSubtle = Westron.Color(
        name: "color.background.accent-subtle",
        light: Westron.RGB(hex: 0xE8F0FF),
        dark: Westron.RGB(hex: 0x182336),
        lightHighContrast: Westron.RGB(hex: 0xE8F0FF),
        darkHighContrast: Westron.RGB(hex: 0x182336))

    /// The fill of the one primary action on a screen, a checked box, a switch that is on.
    ///
    /// Use for: primary button, checked box, switch on. Avoid: Status: use status.info.fill, even though info is the
    /// accent's blue today.
    public static let backgroundAccent = Westron.Color(
        name: "color.background.accent",
        light: Westron.RGB(hex: 0x2863D7),
        dark: Westron.RGB(hex: 0x2863D7),
        lightHighContrast: Westron.RGB(hex: 0x1651C3),
        darkHighContrast: Westron.RGB(hex: 0x6A9EFF))

    /// The accent fill under the pointer.
    public static let backgroundAccentHover = Westron.Color(
        name: "color.background.accent-hover",
        light: Westron.RGB(hex: 0x1C56C9),
        dark: Westron.RGB(hex: 0x1C56C9),
        lightHighContrast: Westron.RGB(hex: 0x0844B6),
        darkHighContrast: Westron.RGB(hex: 0x7EACFF))

    /// Main text and glyphs.
    public static let textPrimary = Westron.Color(
        name: "color.text.primary",
        light: Westron.RGB(hex: 0x23272C),
        dark: Westron.RGB(hex: 0xD7DFEA),
        lightHighContrast: Westron.RGB(hex: 0x1A1E23),
        darkHighContrast: Westron.RGB(hex: 0xE7EFFA),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.muted"],
            ["color.background.hover"],
            ["color.background.pressed"],
            ["color.background.selected"],
            ["color.background.accent-subtle"],
        ])

    /// Text and glyphs that come second: captions, metadata, a row's details, timestamps.
    public static let textSecondary = Westron.Color(
        name: "color.text.secondary",
        light: Westron.RGB(hex: 0x656970),
        dark: Westron.RGB(hex: 0x8E96A0),
        lightHighContrast: Westron.RGB(hex: 0x484C52),
        darkHighContrast: Westron.RGB(hex: 0xB4BBC6),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.muted"],
            ["color.background.hover"],
            ["color.background.pressed"],
            ["color.background.selected"],
            ["color.background.accent-subtle"],
        ])

    /// The placeholder of an empty field. It meets the text target, as all words do.
    public static let textPlaceholder = Westron.Color(
        name: "color.text.placeholder",
        light: Westron.RGB(hex: 0x656970),
        dark: Westron.RGB(hex: 0x8E96A0),
        lightHighContrast: Westron.RGB(hex: 0x484C52),
        darkHighContrast: Westron.RGB(hex: 0xB4BBC6),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.muted"],
        ])

    /// Text and glyphs on the accent fill: white, and the canvas's color in dark high contrast, where the fill turns
    /// light.
    public static let textOnAccent = Westron.Color(
        name: "color.text.on-accent",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x101318),
        backgrounds: [["color.background.accent"], ["color.background.accent-hover"]])

    /// Links and accent text.
    ///
    /// Use for: link, accent text. Avoid: Status text: use status.<name>.text.
    public static let textAccent = Westron.Color(
        name: "color.text.accent",
        light: Westron.RGB(hex: 0x2C63D1),
        dark: Westron.RGB(hex: 0x5992FF),
        lightHighContrast: Westron.RGB(hex: 0x0C43AF),
        darkHighContrast: Westron.RGB(hex: 0x96BCFF),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.hover"],
            ["color.background.selected"],
            ["color.background.accent-subtle"],
        ])

    /// Glyphs that carry no words and need only 3:1: a chevron, a grip, a disclosure triangle.
    ///
    /// Use for: chevron, grip, disclosure. Avoid: Words: words are text.secondary at least.
    public static let iconTertiary = Westron.Color(
        name: "color.icon.tertiary",
        light: Westron.RGB(hex: 0x81868D),
        dark: Westron.RGB(hex: 0x717781),
        lightHighContrast: Westron.RGB(hex: 0x656970),
        darkHighContrast: Westron.RGB(hex: 0x8E96A0),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.hover"],
            ["color.background.selected"],
        ])

    /// Separators and the outline of a card: decorative in standard themes, 3:1 in high contrast, where every raised
    /// surface gets one.
    public static let borderDefault = Westron.Color(
        name: "color.border.default",
        light: Westron.RGB(hex: 0xDCDFE5),
        dark: Westron.RGB(hex: 0x2E3339),
        lightHighContrast: Westron.RGB(hex: 0x898D92),
        darkHighContrast: Westron.RGB(hex: 0x656B72),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// The border of a control that must be seen: a field, a checkbox, a radio ring, a secondary button.
    public static let borderStrong = Westron.Color(
        name: "color.border.strong",
        light: Westron.RGB(hex: 0x81868D),
        dark: Westron.RGB(hex: 0x717781),
        lightHighContrast: Westron.RGB(hex: 0x656970),
        darkHighContrast: Westron.RGB(hex: 0x8E96A0),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.muted"],
        ])

    /// The focus ring, and the outline of a selected item in high contrast.
    public static let borderFocus = Westron.Color(
        name: "color.border.focus",
        light: Westron.RGB(hex: 0x5283E1),
        dark: Westron.RGB(hex: 0x4474D0),
        lightHighContrast: Westron.RGB(hex: 0x3765C0),
        darkHighContrast: Westron.RGB(hex: 0x6194F2),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.background.hover"],
            ["color.background.selected"],
        ])

    /// The quiet ground of a badge, a banner or a row in the status danger.
    public static let statusDangerBackground = Westron.Color(
        name: "color.status.danger.background",
        light: Westron.RGB(hex: 0xFFEFED),
        dark: Westron.RGB(hex: 0x2F1B18),
        lightHighContrast: Westron.RGB(hex: 0xFFEFED),
        darkHighContrast: Westron.RGB(hex: 0x2F1B18))

    /// The border of a field or a banner in the status danger.
    public static let statusDangerBorder = Westron.Color(
        name: "color.status.danger.border",
        light: Westron.RGB(hex: 0xCF665C),
        dark: Westron.RGB(hex: 0xBF564D),
        lightHighContrast: Westron.RGB(hex: 0xAE4840),
        darkHighContrast: Westron.RGB(hex: 0xE1766B),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.danger.background"],
        ])

    /// The icon or dot of the status danger.
    public static let statusDangerIcon = Westron.Color(
        name: "color.status.danger.icon",
        light: Westron.RGB(hex: 0xCF665C),
        dark: Westron.RGB(hex: 0xBF564D),
        lightHighContrast: Westron.RGB(hex: 0xAE4840),
        darkHighContrast: Westron.RGB(hex: 0xE1766B),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.danger.background"],
        ])

    /// Text in the status danger.
    public static let statusDangerText = Westron.Color(
        name: "color.status.danger.text",
        light: Westron.RGB(hex: 0xBA3D37),
        dark: Westron.RGB(hex: 0xEE6D62),
        lightHighContrast: Westron.RGB(hex: 0x961818),
        darkHighContrast: Westron.RGB(hex: 0xFFA297),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.danger.background"],
        ])

    /// The solid fill of the status danger: a button or a count badge.
    public static let statusDangerFill = Westron.Color(
        name: "color.status.danger.fill",
        light: Westron.RGB(hex: 0xA72120),
        dark: Westron.RGB(hex: 0xA72120),
        lightHighContrast: Westron.RGB(hex: 0xA72120),
        darkHighContrast: Westron.RGB(hex: 0xFE7469))

    /// Text and glyphs on the danger fill.
    public static let statusDangerOnFill = Westron.Color(
        name: "color.status.danger.on-fill",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x101318),
        backgrounds: [["color.status.danger.fill"]])

    /// The quiet ground of a badge, a banner or a row in the status warning.
    public static let statusWarningBackground = Westron.Color(
        name: "color.status.warning.background",
        light: Westron.RGB(hex: 0xFEF1DD),
        dark: Westron.RGB(hex: 0x281F0F),
        lightHighContrast: Westron.RGB(hex: 0xFEF1DD),
        darkHighContrast: Westron.RGB(hex: 0x281F0F))

    /// The border of a field or a banner in the status warning.
    public static let statusWarningBorder = Westron.Color(
        name: "color.status.warning.border",
        light: Westron.RGB(hex: 0xAF7C04),
        dark: Westron.RGB(hex: 0x9C6F00),
        lightHighContrast: Westron.RGB(hex: 0x8A6100),
        darkHighContrast: Westron.RGB(hex: 0xBF8C24),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.warning.background"],
        ])

    /// The icon or dot of the status warning.
    public static let statusWarningIcon = Westron.Color(
        name: "color.status.warning.icon",
        light: Westron.RGB(hex: 0xAF7C04),
        dark: Westron.RGB(hex: 0x9C6F00),
        lightHighContrast: Westron.RGB(hex: 0x8A6100),
        darkHighContrast: Westron.RGB(hex: 0xBF8C24),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.warning.background"],
        ])

    /// Text in the status warning.
    public static let statusWarningText = Westron.Color(
        name: "color.status.warning.text",
        light: Westron.RGB(hex: 0x8A6100),
        dark: Westron.RGB(hex: 0xC28B00),
        lightHighContrast: Westron.RGB(hex: 0x654700),
        darkHighContrast: Westron.RGB(hex: 0xEFB02E),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.warning.background"],
        ])

    /// The solid fill of the status warning: a button or a count badge.
    public static let statusWarningFill = Westron.Color(
        name: "color.status.warning.fill",
        light: Westron.RGB(hex: 0xF3B01D),
        dark: Westron.RGB(hex: 0xF3B01D),
        lightHighContrast: Westron.RGB(hex: 0xF3B01D),
        darkHighContrast: Westron.RGB(hex: 0xF3B01D))

    /// Text and glyphs on the warning fill.
    public static let statusWarningOnFill = Westron.Color(
        name: "color.status.warning.on-fill",
        light: Westron.RGB(hex: 0x191610),
        dark: Westron.RGB(hex: 0x191610),
        lightHighContrast: Westron.RGB(hex: 0x191610),
        darkHighContrast: Westron.RGB(hex: 0x191610),
        backgrounds: [["color.status.warning.fill"]])

    /// The quiet ground of a badge, a banner or a row in the status success.
    public static let statusSuccessBackground = Westron.Color(
        name: "color.status.success.background",
        light: Westron.RGB(hex: 0xE6F7F0),
        dark: Westron.RGB(hex: 0x15231D),
        lightHighContrast: Westron.RGB(hex: 0xE6F7F0),
        darkHighContrast: Westron.RGB(hex: 0x15231D))

    /// The border of a field or a banner in the status success.
    public static let statusSuccessBorder = Westron.Color(
        name: "color.status.success.border",
        light: Westron.RGB(hex: 0x449378),
        dark: Westron.RGB(hex: 0x348469),
        lightHighContrast: Westron.RGB(hex: 0x23765C),
        darkHighContrast: Westron.RGB(hex: 0x55A387),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.success.background"],
        ])

    /// The icon or dot of the status success.
    public static let statusSuccessIcon = Westron.Color(
        name: "color.status.success.icon",
        light: Westron.RGB(hex: 0x449378),
        dark: Westron.RGB(hex: 0x348469),
        lightHighContrast: Westron.RGB(hex: 0x23765C),
        darkHighContrast: Westron.RGB(hex: 0x55A387),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.success.background"],
        ])

    /// Text in the status success.
    public static let statusSuccessText = Westron.Color(
        name: "color.status.success.text",
        light: Westron.RGB(hex: 0x00775A),
        dark: Westron.RGB(hex: 0x41A684),
        lightHighContrast: Westron.RGB(hex: 0x005741),
        darkHighContrast: Westron.RGB(hex: 0x6BCDAA),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.success.background"],
        ])

    /// The solid fill of the status success: a button or a count badge.
    public static let statusSuccessFill = Westron.Color(
        name: "color.status.success.fill",
        light: Westron.RGB(hex: 0x018766),
        dark: Westron.RGB(hex: 0x018766),
        lightHighContrast: Westron.RGB(hex: 0x00654C),
        darkHighContrast: Westron.RGB(hex: 0x46B18D))

    /// Text and glyphs on the success fill.
    public static let statusSuccessOnFill = Westron.Color(
        name: "color.status.success.on-fill",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x101318),
        backgrounds: [["color.status.success.fill"]])

    /// The quiet ground of a badge, a banner or a row in the status info.
    public static let statusInfoBackground = Westron.Color(
        name: "color.status.info.background",
        light: Westron.RGB(hex: 0xEDF3FF),
        dark: Westron.RGB(hex: 0x172031),
        lightHighContrast: Westron.RGB(hex: 0xEDF3FF),
        darkHighContrast: Westron.RGB(hex: 0x172031))

    /// The border of a field or a banner in the status info.
    public static let statusInfoBorder = Westron.Color(
        name: "color.status.info.border",
        light: Westron.RGB(hex: 0x5283E1),
        dark: Westron.RGB(hex: 0x4474D0),
        lightHighContrast: Westron.RGB(hex: 0x3765C0),
        darkHighContrast: Westron.RGB(hex: 0x6194F2),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.info.background"],
        ])

    /// The icon or dot of the status info.
    public static let statusInfoIcon = Westron.Color(
        name: "color.status.info.icon",
        light: Westron.RGB(hex: 0x5283E1),
        dark: Westron.RGB(hex: 0x4474D0),
        lightHighContrast: Westron.RGB(hex: 0x3765C0),
        darkHighContrast: Westron.RGB(hex: 0x6194F2),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.info.background"],
        ])

    /// Text in the status info.
    public static let statusInfoText = Westron.Color(
        name: "color.status.info.text",
        light: Westron.RGB(hex: 0x2C63D1),
        dark: Westron.RGB(hex: 0x5992FF),
        lightHighContrast: Westron.RGB(hex: 0x0C43AF),
        darkHighContrast: Westron.RGB(hex: 0x96BCFF),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.info.background"],
        ])

    /// The solid fill of the status info: a button or a count badge.
    public static let statusInfoFill = Westron.Color(
        name: "color.status.info.fill",
        light: Westron.RGB(hex: 0x2863D7),
        dark: Westron.RGB(hex: 0x2863D7),
        lightHighContrast: Westron.RGB(hex: 0x1651C3),
        darkHighContrast: Westron.RGB(hex: 0x6A9EFF))

    /// Text and glyphs on the info fill.
    public static let statusInfoOnFill = Westron.Color(
        name: "color.status.info.on-fill",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x101318),
        backgrounds: [["color.status.info.fill"]])

    /// The quiet ground of a badge, a banner or a row in the status neutral.
    public static let statusNeutralBackground = Westron.Color(
        name: "color.status.neutral.background",
        light: Westron.RGB(hex: 0xEBEEF4),
        dark: Westron.RGB(hex: 0x22272D),
        lightHighContrast: Westron.RGB(hex: 0xEBEEF4),
        darkHighContrast: Westron.RGB(hex: 0x22272D))

    /// The border of a field or a banner in the status neutral.
    public static let statusNeutralBorder = Westron.Color(
        name: "color.status.neutral.border",
        light: Westron.RGB(hex: 0x81868D),
        dark: Westron.RGB(hex: 0x717781),
        lightHighContrast: Westron.RGB(hex: 0x656970),
        darkHighContrast: Westron.RGB(hex: 0x8E96A0),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.neutral.background"],
        ])

    /// The icon or dot of the status neutral.
    public static let statusNeutralIcon = Westron.Color(
        name: "color.status.neutral.icon",
        light: Westron.RGB(hex: 0x81868D),
        dark: Westron.RGB(hex: 0x717781),
        lightHighContrast: Westron.RGB(hex: 0x656970),
        darkHighContrast: Westron.RGB(hex: 0x8E96A0),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.neutral.background"],
        ])

    /// Text in the status neutral.
    public static let statusNeutralText = Westron.Color(
        name: "color.status.neutral.text",
        light: Westron.RGB(hex: 0x656970),
        dark: Westron.RGB(hex: 0x8E96A0),
        lightHighContrast: Westron.RGB(hex: 0x484C52),
        darkHighContrast: Westron.RGB(hex: 0xB4BBC6),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sunken"],
            ["color.status.neutral.background"],
        ])

    /// The solid fill of the status neutral: a button or a count badge.
    public static let statusNeutralFill = Westron.Color(
        name: "color.status.neutral.fill",
        light: Westron.RGB(hex: 0x5F646A),
        dark: Westron.RGB(hex: 0x5D646E),
        lightHighContrast: Westron.RGB(hex: 0x555960),
        darkHighContrast: Westron.RGB(hex: 0x98A0AA))

    /// Text and glyphs on the neutral fill.
    public static let statusNeutralOnFill = Westron.Color(
        name: "color.status.neutral.on-fill",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x101318),
        backgrounds: [["color.status.neutral.fill"]])

    /// Series 1 of a chart.
    public static let chart1 = Westron.Color(
        name: "color.chart.1",
        light: Westron.RGB(hex: 0x1E68BD),
        dark: Westron.RGB(hex: 0x80B8FF),
        lightHighContrast: Westron.RGB(hex: 0x1E68BD),
        darkHighContrast: Westron.RGB(hex: 0x80B8FF),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 2 of a chart.
    public static let chart2 = Westron.Color(
        name: "color.chart.2",
        light: Westron.RGB(hex: 0x349D11),
        dark: Westron.RGB(hex: 0xEDC700),
        lightHighContrast: Westron.RGB(hex: 0x349D11),
        darkHighContrast: Westron.RGB(hex: 0xEDC700),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 3 of a chart.
    public static let chart3 = Westron.Color(
        name: "color.chart.3",
        light: Westron.RGB(hex: 0x873D00),
        dark: Westron.RGB(hex: 0xE24947),
        lightHighContrast: Westron.RGB(hex: 0x873D00),
        darkHighContrast: Westron.RGB(hex: 0xE24947),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 4 of a chart.
    public static let chart4 = Westron.Color(
        name: "color.chart.4",
        light: Westron.RGB(hex: 0x009F84),
        dark: Westron.RGB(hex: 0x9975EB),
        lightHighContrast: Westron.RGB(hex: 0x009F84),
        darkHighContrast: Westron.RGB(hex: 0x9975EB),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 5 of a chart.
    public static let chart5 = Westron.Color(
        name: "color.chart.5",
        light: Westron.RGB(hex: 0xBA368C),
        dark: Westron.RGB(hex: 0xFF8025),
        lightHighContrast: Westron.RGB(hex: 0xBA368C),
        darkHighContrast: Westron.RGB(hex: 0xFF8025),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 6 of a chart.
    public static let chart6 = Westron.Color(
        name: "color.chart.6",
        light: Westron.RGB(hex: 0x9369EC),
        dark: Westron.RGB(hex: 0x00A78B),
        lightHighContrast: Westron.RGB(hex: 0x9369EC),
        darkHighContrast: Westron.RGB(hex: 0x00A78B),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 7 of a chart.
    public static let chart7 = Westron.Color(
        name: "color.chart.7",
        light: Westron.RGB(hex: 0xDE6862),
        dark: Westron.RGB(hex: 0xFF82CD),
        lightHighContrast: Westron.RGB(hex: 0xDE6862),
        darkHighContrast: Westron.RGB(hex: 0xFF82CD),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Series 8 of a chart.
    public static let chart8 = Westron.Color(
        name: "color.chart.8",
        light: Westron.RGB(hex: 0x816B00),
        dark: Westron.RGB(hex: 0x8EC682),
        lightHighContrast: Westron.RGB(hex: 0x816B00),
        darkHighContrast: Westron.RGB(hex: 0x8EC682),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sunken"]])

    /// Every semantic color in token order, the list colors included.
    public static let all: [Westron.Color] = [
        backgroundCanvas,
        backgroundSurface,
        backgroundSunken,
        backgroundMuted,
        backgroundHover,
        backgroundPressed,
        backgroundSelected,
        backgroundAccentSubtle,
        backgroundAccent,
        backgroundAccentHover,
        textPrimary,
        textSecondary,
        textPlaceholder,
        textOnAccent,
        textAccent,
        iconTertiary,
        borderDefault,
        borderStrong,
        borderFocus,
        statusDangerBackground,
        statusDangerBorder,
        statusDangerIcon,
        statusDangerText,
        statusDangerFill,
        statusDangerOnFill,
        statusWarningBackground,
        statusWarningBorder,
        statusWarningIcon,
        statusWarningText,
        statusWarningFill,
        statusWarningOnFill,
        statusSuccessBackground,
        statusSuccessBorder,
        statusSuccessIcon,
        statusSuccessText,
        statusSuccessFill,
        statusSuccessOnFill,
        statusInfoBackground,
        statusInfoBorder,
        statusInfoIcon,
        statusInfoText,
        statusInfoFill,
        statusInfoOnFill,
        statusNeutralBackground,
        statusNeutralBorder,
        statusNeutralIcon,
        statusNeutralText,
        statusNeutralFill,
        statusNeutralOnFill,
        Westron.Category.blue.background,
        Westron.Category.blue.border,
        Westron.Category.blue.icon,
        Westron.Category.blue.text,
        Westron.Category.blue.fill,
        Westron.Category.blue.onFill,
        Westron.Category.sky.background,
        Westron.Category.sky.border,
        Westron.Category.sky.icon,
        Westron.Category.sky.text,
        Westron.Category.sky.fill,
        Westron.Category.sky.onFill,
        Westron.Category.teal.background,
        Westron.Category.teal.border,
        Westron.Category.teal.icon,
        Westron.Category.teal.text,
        Westron.Category.teal.fill,
        Westron.Category.teal.onFill,
        Westron.Category.emerald.background,
        Westron.Category.emerald.border,
        Westron.Category.emerald.icon,
        Westron.Category.emerald.text,
        Westron.Category.emerald.fill,
        Westron.Category.emerald.onFill,
        Westron.Category.green.background,
        Westron.Category.green.border,
        Westron.Category.green.icon,
        Westron.Category.green.text,
        Westron.Category.green.fill,
        Westron.Category.green.onFill,
        Westron.Category.olive.background,
        Westron.Category.olive.border,
        Westron.Category.olive.icon,
        Westron.Category.olive.text,
        Westron.Category.olive.fill,
        Westron.Category.olive.onFill,
        Westron.Category.amber.background,
        Westron.Category.amber.border,
        Westron.Category.amber.icon,
        Westron.Category.amber.text,
        Westron.Category.amber.fill,
        Westron.Category.amber.onFill,
        Westron.Category.orange.background,
        Westron.Category.orange.border,
        Westron.Category.orange.icon,
        Westron.Category.orange.text,
        Westron.Category.orange.fill,
        Westron.Category.orange.onFill,
        Westron.Category.red.background,
        Westron.Category.red.border,
        Westron.Category.red.icon,
        Westron.Category.red.text,
        Westron.Category.red.fill,
        Westron.Category.red.onFill,
        Westron.Category.pink.background,
        Westron.Category.pink.border,
        Westron.Category.pink.icon,
        Westron.Category.pink.text,
        Westron.Category.pink.fill,
        Westron.Category.pink.onFill,
        Westron.Category.violet.background,
        Westron.Category.violet.border,
        Westron.Category.violet.icon,
        Westron.Category.violet.text,
        Westron.Category.violet.fill,
        Westron.Category.violet.onFill,
        Westron.Category.indigo.background,
        Westron.Category.indigo.border,
        Westron.Category.indigo.icon,
        Westron.Category.indigo.text,
        Westron.Category.indigo.fill,
        Westron.Category.indigo.onFill,
        chart1,
        chart2,
        chart3,
        chart4,
        chart5,
        chart6,
        chart7,
        chart8,
    ]
}

extension Westron {
    /// The list colors, `color.category.<name>.<role>`. A product keeps a list's color by the case's raw value, its
    /// name in the tokens, and reads it back with `init(rawValue:)`.
    public enum Category: String, CaseIterable, Sendable {
        case blue
        case sky
        case teal
        case emerald
        case green
        case olive
        case amber
        case orange
        case red
        case pink
        case violet
        case indigo

        /// The quiet ground of a tag or a row in the list color.
        public var background: Westron.Color {
            switch self {
            case .blue: Self.blueBackground
            case .sky: Self.skyBackground
            case .teal: Self.tealBackground
            case .emerald: Self.emeraldBackground
            case .green: Self.greenBackground
            case .olive: Self.oliveBackground
            case .amber: Self.amberBackground
            case .orange: Self.orangeBackground
            case .red: Self.redBackground
            case .pink: Self.pinkBackground
            case .violet: Self.violetBackground
            case .indigo: Self.indigoBackground
            }
        }

        /// The border of an outlined tag in the list color.
        public var border: Westron.Color {
            switch self {
            case .blue: Self.blueBorder
            case .sky: Self.skyBorder
            case .teal: Self.tealBorder
            case .emerald: Self.emeraldBorder
            case .green: Self.greenBorder
            case .olive: Self.oliveBorder
            case .amber: Self.amberBorder
            case .orange: Self.orangeBorder
            case .red: Self.redBorder
            case .pink: Self.pinkBorder
            case .violet: Self.violetBorder
            case .indigo: Self.indigoBorder
            }
        }

        /// A dot or an icon in the list color.
        public var icon: Westron.Color {
            switch self {
            case .blue: Self.blueIcon
            case .sky: Self.skyIcon
            case .teal: Self.tealIcon
            case .emerald: Self.emeraldIcon
            case .green: Self.greenIcon
            case .olive: Self.oliveIcon
            case .amber: Self.amberIcon
            case .orange: Self.orangeIcon
            case .red: Self.redIcon
            case .pink: Self.pinkIcon
            case .violet: Self.violetIcon
            case .indigo: Self.indigoIcon
            }
        }

        /// Text in the list color.
        public var text: Westron.Color {
            switch self {
            case .blue: Self.blueText
            case .sky: Self.skyText
            case .teal: Self.tealText
            case .emerald: Self.emeraldText
            case .green: Self.greenText
            case .olive: Self.oliveText
            case .amber: Self.amberText
            case .orange: Self.orangeText
            case .red: Self.redText
            case .pink: Self.pinkText
            case .violet: Self.violetText
            case .indigo: Self.indigoText
            }
        }

        /// The solid fill of a lit tag in the list color.
        public var fill: Westron.Color {
            switch self {
            case .blue: Self.blueFill
            case .sky: Self.skyFill
            case .teal: Self.tealFill
            case .emerald: Self.emeraldFill
            case .green: Self.greenFill
            case .olive: Self.oliveFill
            case .amber: Self.amberFill
            case .orange: Self.orangeFill
            case .red: Self.redFill
            case .pink: Self.pinkFill
            case .violet: Self.violetFill
            case .indigo: Self.indigoFill
            }
        }

        /// Text and glyphs on the fill of the list color.
        public var onFill: Westron.Color {
            switch self {
            case .blue: Self.blueOnFill
            case .sky: Self.skyOnFill
            case .teal: Self.tealOnFill
            case .emerald: Self.emeraldOnFill
            case .green: Self.greenOnFill
            case .olive: Self.oliveOnFill
            case .amber: Self.amberOnFill
            case .orange: Self.orangeOnFill
            case .red: Self.redOnFill
            case .pink: Self.pinkOnFill
            case .violet: Self.violetOnFill
            case .indigo: Self.indigoOnFill
            }
        }

        /// The colors of the category, one per role, in token order.
        public var colors: [Westron.Color] { [background, border, icon, text, fill, onFill] }

        /// The quiet ground of a tag or a row in the list color blue.
        private static let blueBackground = Westron.Color(
            name: "color.category.blue.background",
            light: Westron.RGB(hex: 0xE8F0FF),
            dark: Westron.RGB(hex: 0x182336),
            lightHighContrast: Westron.RGB(hex: 0xE8F0FF),
            darkHighContrast: Westron.RGB(hex: 0x182336))

        /// The border of an outlined tag in the list color blue.
        private static let blueBorder = Westron.Color(
            name: "color.category.blue.border",
            light: Westron.RGB(hex: 0x5283E1),
            dark: Westron.RGB(hex: 0x4474D0),
            lightHighContrast: Westron.RGB(hex: 0x3765C0),
            darkHighContrast: Westron.RGB(hex: 0x6194F2),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.blue.background"],
            ])

        /// A dot or an icon in the list color blue.
        private static let blueIcon = Westron.Color(
            name: "color.category.blue.icon",
            light: Westron.RGB(hex: 0x5283E1),
            dark: Westron.RGB(hex: 0x4474D0),
            lightHighContrast: Westron.RGB(hex: 0x3765C0),
            darkHighContrast: Westron.RGB(hex: 0x6194F2),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.blue.background"],
            ])

        /// Text in the list color blue.
        private static let blueText = Westron.Color(
            name: "color.category.blue.text",
            light: Westron.RGB(hex: 0x2C63D1),
            dark: Westron.RGB(hex: 0x5992FF),
            lightHighContrast: Westron.RGB(hex: 0x0C43AF),
            darkHighContrast: Westron.RGB(hex: 0x96BCFF),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.blue.background"],
            ])

        /// The solid fill of a lit tag in the list color blue.
        private static let blueFill = Westron.Color(
            name: "color.category.blue.fill",
            light: Westron.RGB(hex: 0x2863D7),
            dark: Westron.RGB(hex: 0x2863D7),
            lightHighContrast: Westron.RGB(hex: 0x1651C3),
            darkHighContrast: Westron.RGB(hex: 0x6A9EFF))

        /// Text and glyphs on the fill of the list color blue.
        private static let blueOnFill = Westron.Color(
            name: "color.category.blue.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.blue.fill"]])

        /// The quiet ground of a tag or a row in the list color sky.
        private static let skyBackground = Westron.Color(
            name: "color.category.sky.background",
            light: Westron.RGB(hex: 0xDFF3FF),
            dark: Westron.RGB(hex: 0x14252D),
            lightHighContrast: Westron.RGB(hex: 0xDFF3FF),
            darkHighContrast: Westron.RGB(hex: 0x14252D))

        /// The border of an outlined tag in the list color sky.
        private static let skyBorder = Westron.Color(
            name: "color.category.sky.border",
            light: Westron.RGB(hex: 0x358EB8),
            dark: Westron.RGB(hex: 0x207FA7),
            lightHighContrast: Westron.RGB(hex: 0x047198),
            darkHighContrast: Westron.RGB(hex: 0x469EC7),
            backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.category.sky.background"]])

        /// A dot or an icon in the list color sky.
        private static let skyIcon = Westron.Color(
            name: "color.category.sky.icon",
            light: Westron.RGB(hex: 0x358EB8),
            dark: Westron.RGB(hex: 0x207FA7),
            lightHighContrast: Westron.RGB(hex: 0x047198),
            darkHighContrast: Westron.RGB(hex: 0x469EC7),
            backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.category.sky.background"]])

        /// Text in the list color sky.
        private static let skyText = Westron.Color(
            name: "color.category.sky.text",
            light: Westron.RGB(hex: 0x007099),
            dark: Westron.RGB(hex: 0x2A9FD1),
            lightHighContrast: Westron.RGB(hex: 0x005271),
            darkHighContrast: Westron.RGB(hex: 0x58C6F9),
            backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.category.sky.background"]])

        /// The solid fill of a lit tag in the list color sky.
        private static let skyFill = Westron.Color(
            name: "color.category.sky.fill",
            light: Westron.RGB(hex: 0x007FAC),
            dark: Westron.RGB(hex: 0x007FAC),
            lightHighContrast: Westron.RGB(hex: 0x006082),
            darkHighContrast: Westron.RGB(hex: 0x2BAADF))

        /// Text and glyphs on the fill of the list color sky.
        private static let skyOnFill = Westron.Color(
            name: "color.category.sky.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.sky.fill"]])

        /// The quiet ground of a tag or a row in the list color teal.
        private static let tealBackground = Westron.Color(
            name: "color.category.teal.background",
            light: Westron.RGB(hex: 0xDEF4F4),
            dark: Westron.RGB(hex: 0x142625),
            lightHighContrast: Westron.RGB(hex: 0xDEF4F4),
            darkHighContrast: Westron.RGB(hex: 0x142625))

        /// The border of an outlined tag in the list color teal.
        private static let tealBorder = Westron.Color(
            name: "color.category.teal.border",
            light: Westron.RGB(hex: 0x329393),
            dark: Westron.RGB(hex: 0x1D8484),
            lightHighContrast: Westron.RGB(hex: 0x007576),
            darkHighContrast: Westron.RGB(hex: 0x44A3A2),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.teal.background"],
            ])

        /// A dot or an icon in the list color teal.
        private static let tealIcon = Westron.Color(
            name: "color.category.teal.icon",
            light: Westron.RGB(hex: 0x329393),
            dark: Westron.RGB(hex: 0x1D8484),
            lightHighContrast: Westron.RGB(hex: 0x007576),
            darkHighContrast: Westron.RGB(hex: 0x44A3A2),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.teal.background"],
            ])

        /// Text in the list color teal.
        private static let tealText = Westron.Color(
            name: "color.category.teal.text",
            light: Westron.RGB(hex: 0x007576),
            dark: Westron.RGB(hex: 0x24A5A5),
            lightHighContrast: Westron.RGB(hex: 0x005556),
            darkHighContrast: Westron.RGB(hex: 0x57CCCB),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.teal.background"],
            ])

        /// The solid fill of a lit tag in the list color teal.
        private static let tealFill = Westron.Color(
            name: "color.category.teal.fill",
            light: Westron.RGB(hex: 0x008485),
            dark: Westron.RGB(hex: 0x008485),
            lightHighContrast: Westron.RGB(hex: 0x006364),
            darkHighContrast: Westron.RGB(hex: 0x26B0B0))

        /// Text and glyphs on the fill of the list color teal.
        private static let tealOnFill = Westron.Color(
            name: "color.category.teal.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.teal.fill"]])

        /// The quiet ground of a tag or a row in the list color emerald.
        private static let emeraldBackground = Westron.Color(
            name: "color.category.emerald.background",
            light: Westron.RGB(hex: 0xE1F4EC),
            dark: Westron.RGB(hex: 0x162620),
            lightHighContrast: Westron.RGB(hex: 0xE1F4EC),
            darkHighContrast: Westron.RGB(hex: 0x162620))

        /// The border of an outlined tag in the list color emerald.
        private static let emeraldBorder = Westron.Color(
            name: "color.category.emerald.border",
            light: Westron.RGB(hex: 0x449378),
            dark: Westron.RGB(hex: 0x348469),
            lightHighContrast: Westron.RGB(hex: 0x23765C),
            darkHighContrast: Westron.RGB(hex: 0x55A387),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.emerald.background"],
            ])

        /// A dot or an icon in the list color emerald.
        private static let emeraldIcon = Westron.Color(
            name: "color.category.emerald.icon",
            light: Westron.RGB(hex: 0x449378),
            dark: Westron.RGB(hex: 0x348469),
            lightHighContrast: Westron.RGB(hex: 0x23765C),
            darkHighContrast: Westron.RGB(hex: 0x55A387),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.emerald.background"],
            ])

        /// Text in the list color emerald.
        private static let emeraldText = Westron.Color(
            name: "color.category.emerald.text",
            light: Westron.RGB(hex: 0x00775A),
            dark: Westron.RGB(hex: 0x41A684),
            lightHighContrast: Westron.RGB(hex: 0x005741),
            darkHighContrast: Westron.RGB(hex: 0x6BCDAA),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.emerald.background"],
            ])

        /// The solid fill of a lit tag in the list color emerald.
        private static let emeraldFill = Westron.Color(
            name: "color.category.emerald.fill",
            light: Westron.RGB(hex: 0x018766),
            dark: Westron.RGB(hex: 0x018766),
            lightHighContrast: Westron.RGB(hex: 0x00654C),
            darkHighContrast: Westron.RGB(hex: 0x46B18D))

        /// Text and glyphs on the fill of the list color emerald.
        private static let emeraldOnFill = Westron.Color(
            name: "color.category.emerald.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.emerald.fill"]])

        /// The quiet ground of a tag or a row in the list color green.
        private static let greenBackground = Westron.Color(
            name: "color.category.green.background",
            light: Westron.RGB(hex: 0xE3F4E3),
            dark: Westron.RGB(hex: 0x192619),
            lightHighContrast: Westron.RGB(hex: 0xE3F4E3),
            darkHighContrast: Westron.RGB(hex: 0x192619))

        /// The border of an outlined tag in the list color green.
        private static let greenBorder = Westron.Color(
            name: "color.category.green.border",
            light: Westron.RGB(hex: 0x549357),
            dark: Westron.RGB(hex: 0x458548),
            lightHighContrast: Westron.RGB(hex: 0x37763B),
            darkHighContrast: Westron.RGB(hex: 0x63A466),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.green.background"],
            ])

        /// A dot or an icon in the list color green.
        private static let greenIcon = Westron.Color(
            name: "color.category.green.icon",
            light: Westron.RGB(hex: 0x549357),
            dark: Westron.RGB(hex: 0x458548),
            lightHighContrast: Westron.RGB(hex: 0x37763B),
            darkHighContrast: Westron.RGB(hex: 0x63A466),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.green.background"],
            ])

        /// Text in the list color green.
        private static let greenText = Westron.Color(
            name: "color.category.green.text",
            light: Westron.RGB(hex: 0x287830),
            dark: Westron.RGB(hex: 0x57A65B),
            lightHighContrast: Westron.RGB(hex: 0x005913),
            darkHighContrast: Westron.RGB(hex: 0x7DCD80),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.green.background"],
            ])

        /// The solid fill of a lit tag in the list color green.
        private static let greenFill = Westron.Color(
            name: "color.category.green.fill",
            light: Westron.RGB(hex: 0x32873A),
            dark: Westron.RGB(hex: 0x32873A),
            lightHighContrast: Westron.RGB(hex: 0x03681A),
            darkHighContrast: Westron.RGB(hex: 0x5DB161))

        /// Text and glyphs on the fill of the list color green.
        private static let greenOnFill = Westron.Color(
            name: "color.category.green.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.green.fill"]])

        /// The quiet ground of a tag or a row in the list color olive.
        private static let oliveBackground = Westron.Color(
            name: "color.category.olive.background",
            light: Westron.RGB(hex: 0xEFF1DE),
            dark: Westron.RGB(hex: 0x232415),
            lightHighContrast: Westron.RGB(hex: 0xEFF1DE),
            darkHighContrast: Westron.RGB(hex: 0x232415))

        /// The border of an outlined tag in the list color olive.
        private static let oliveBorder = Westron.Color(
            name: "color.category.olive.border",
            light: Westron.RGB(hex: 0x868A42),
            dark: Westron.RGB(hex: 0x777B32),
            lightHighContrast: Westron.RGB(hex: 0x696D23),
            darkHighContrast: Westron.RGB(hex: 0x959A51),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.olive.background"],
            ])

        /// A dot or an icon in the list color olive.
        private static let oliveIcon = Westron.Color(
            name: "color.category.olive.icon",
            light: Westron.RGB(hex: 0x868A42),
            dark: Westron.RGB(hex: 0x777B32),
            lightHighContrast: Westron.RGB(hex: 0x696D23),
            darkHighContrast: Westron.RGB(hex: 0x959A51),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.olive.background"],
            ])

        /// Text in the list color olive.
        private static let oliveText = Westron.Color(
            name: "color.category.olive.text",
            light: Westron.RGB(hex: 0x6A6D01),
            dark: Westron.RGB(hex: 0x969A40),
            lightHighContrast: Westron.RGB(hex: 0x4D4F00),
            darkHighContrast: Westron.RGB(hex: 0xBBC167),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.olive.background"],
            ])

        /// The solid fill of a lit tag in the list color olive.
        private static let oliveFill = Westron.Color(
            name: "color.category.olive.fill",
            light: Westron.RGB(hex: 0xBFC566),
            dark: Westron.RGB(hex: 0xBFC566),
            lightHighContrast: Westron.RGB(hex: 0xBFC566),
            darkHighContrast: Westron.RGB(hex: 0xBFC566))

        /// Text and glyphs on the fill of the list color olive.
        private static let oliveOnFill = Westron.Color(
            name: "color.category.olive.on-fill",
            light: Westron.RGB(hex: 0x161710),
            dark: Westron.RGB(hex: 0x161710),
            lightHighContrast: Westron.RGB(hex: 0x161710),
            darkHighContrast: Westron.RGB(hex: 0x161710),
            backgrounds: [["color.category.olive.fill"]])

        /// The quiet ground of a tag or a row in the list color amber.
        private static let amberBackground = Westron.Color(
            name: "color.category.amber.background",
            light: Westron.RGB(hex: 0xFDEED8),
            dark: Westron.RGB(hex: 0x2C210F),
            lightHighContrast: Westron.RGB(hex: 0xFDEED8),
            darkHighContrast: Westron.RGB(hex: 0x2C210F))

        /// The border of an outlined tag in the list color amber.
        private static let amberBorder = Westron.Color(
            name: "color.category.amber.border",
            light: Westron.RGB(hex: 0xAF7C04),
            dark: Westron.RGB(hex: 0x9C6F00),
            lightHighContrast: Westron.RGB(hex: 0x8A6100),
            darkHighContrast: Westron.RGB(hex: 0xBF8C24),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.amber.background"],
            ])

        /// A dot or an icon in the list color amber.
        private static let amberIcon = Westron.Color(
            name: "color.category.amber.icon",
            light: Westron.RGB(hex: 0xAF7C04),
            dark: Westron.RGB(hex: 0x9C6F00),
            lightHighContrast: Westron.RGB(hex: 0x8A6100),
            darkHighContrast: Westron.RGB(hex: 0xBF8C24),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.amber.background"],
            ])

        /// Text in the list color amber.
        private static let amberText = Westron.Color(
            name: "color.category.amber.text",
            light: Westron.RGB(hex: 0x8A6100),
            dark: Westron.RGB(hex: 0xC28B00),
            lightHighContrast: Westron.RGB(hex: 0x654700),
            darkHighContrast: Westron.RGB(hex: 0xEFB02E),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.amber.background"],
            ])

        /// The solid fill of a lit tag in the list color amber.
        private static let amberFill = Westron.Color(
            name: "color.category.amber.fill",
            light: Westron.RGB(hex: 0xF3B01D),
            dark: Westron.RGB(hex: 0xF3B01D),
            lightHighContrast: Westron.RGB(hex: 0xF3B01D),
            darkHighContrast: Westron.RGB(hex: 0xF3B01D))

        /// Text and glyphs on the fill of the list color amber.
        private static let amberOnFill = Westron.Color(
            name: "color.category.amber.on-fill",
            light: Westron.RGB(hex: 0x191610),
            dark: Westron.RGB(hex: 0x191610),
            lightHighContrast: Westron.RGB(hex: 0x191610),
            darkHighContrast: Westron.RGB(hex: 0x191610),
            backgrounds: [["color.category.amber.fill"]])

        /// The quiet ground of a tag or a row in the list color orange.
        private static let orangeBackground = Westron.Color(
            name: "color.category.orange.background",
            light: Westron.RGB(hex: 0xFFECE3),
            dark: Westron.RGB(hex: 0x311F14),
            lightHighContrast: Westron.RGB(hex: 0xFFECE3),
            darkHighContrast: Westron.RGB(hex: 0x311F14))

        /// The border of an outlined tag in the list color orange.
        private static let orangeBorder = Westron.Color(
            name: "color.category.orange.border",
            light: Westron.RGB(hex: 0xC56F3B),
            dark: Westron.RGB(hex: 0xB5602A),
            lightHighContrast: Westron.RGB(hex: 0xA55219),
            darkHighContrast: Westron.RGB(hex: 0xD67F4A),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.orange.background"],
            ])

        /// A dot or an icon in the list color orange.
        private static let orangeIcon = Westron.Color(
            name: "color.category.orange.icon",
            light: Westron.RGB(hex: 0xC56F3B),
            dark: Westron.RGB(hex: 0xB5602A),
            lightHighContrast: Westron.RGB(hex: 0xA55219),
            darkHighContrast: Westron.RGB(hex: 0xD67F4A),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.orange.background"],
            ])

        /// Text in the list color orange.
        private static let orangeText = Westron.Color(
            name: "color.category.orange.text",
            light: Westron.RGB(hex: 0xAB4E00),
            dark: Westron.RGB(hex: 0xE17935),
            lightHighContrast: Westron.RGB(hex: 0x7E3800),
            darkHighContrast: Westron.RGB(hex: 0xFFA571),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.orange.background"],
            ])

        /// The solid fill of a lit tag in the list color orange.
        private static let orangeFill = Westron.Color(
            name: "color.category.orange.fill",
            light: Westron.RGB(hex: 0xBF5900),
            dark: Westron.RGB(hex: 0xBF5900),
            lightHighContrast: Westron.RGB(hex: 0x914200),
            darkHighContrast: Westron.RGB(hex: 0xF08139))

        /// Text and glyphs on the fill of the list color orange.
        private static let orangeOnFill = Westron.Color(
            name: "color.category.orange.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.orange.fill"]])

        /// The quiet ground of a tag or a row in the list color red.
        private static let redBackground = Westron.Color(
            name: "color.category.red.background",
            light: Westron.RGB(hex: 0xFFEBE9),
            dark: Westron.RGB(hex: 0x331D1B),
            lightHighContrast: Westron.RGB(hex: 0xFFEBE9),
            darkHighContrast: Westron.RGB(hex: 0x331D1B))

        /// The border of an outlined tag in the list color red.
        private static let redBorder = Westron.Color(
            name: "color.category.red.border",
            light: Westron.RGB(hex: 0xCF665C),
            dark: Westron.RGB(hex: 0xBF564D),
            lightHighContrast: Westron.RGB(hex: 0xAE4840),
            darkHighContrast: Westron.RGB(hex: 0xE1766B),
            backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.category.red.background"]])

        /// A dot or an icon in the list color red.
        private static let redIcon = Westron.Color(
            name: "color.category.red.icon",
            light: Westron.RGB(hex: 0xCF665C),
            dark: Westron.RGB(hex: 0xBF564D),
            lightHighContrast: Westron.RGB(hex: 0xAE4840),
            darkHighContrast: Westron.RGB(hex: 0xE1766B),
            backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.category.red.background"]])

        /// Text in the list color red.
        private static let redText = Westron.Color(
            name: "color.category.red.text",
            light: Westron.RGB(hex: 0xBA3D37),
            dark: Westron.RGB(hex: 0xEE6D62),
            lightHighContrast: Westron.RGB(hex: 0x961818),
            darkHighContrast: Westron.RGB(hex: 0xFFA297),
            backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.category.red.background"]])

        /// The solid fill of a lit tag in the list color red.
        private static let redFill = Westron.Color(
            name: "color.category.red.fill",
            light: Westron.RGB(hex: 0xA72120),
            dark: Westron.RGB(hex: 0xA72120),
            lightHighContrast: Westron.RGB(hex: 0xA72120),
            darkHighContrast: Westron.RGB(hex: 0xFE7469))

        /// Text and glyphs on the fill of the list color red.
        private static let redOnFill = Westron.Color(
            name: "color.category.red.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.red.fill"]])

        /// The quiet ground of a tag or a row in the list color pink.
        private static let pinkBackground = Westron.Color(
            name: "color.category.pink.background",
            light: Westron.RGB(hex: 0xFFEAF3),
            dark: Westron.RGB(hex: 0x311D26),
            lightHighContrast: Westron.RGB(hex: 0xFFEAF3),
            darkHighContrast: Westron.RGB(hex: 0x311D26))

        /// The border of an outlined tag in the list color pink.
        private static let pinkBorder = Westron.Color(
            name: "color.category.pink.border",
            light: Westron.RGB(hex: 0xC36795),
            dark: Westron.RGB(hex: 0xB25986),
            lightHighContrast: Westron.RGB(hex: 0xA34A78),
            darkHighContrast: Westron.RGB(hex: 0xD477A5),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.pink.background"],
            ])

        /// A dot or an icon in the list color pink.
        private static let pinkIcon = Westron.Color(
            name: "color.category.pink.icon",
            light: Westron.RGB(hex: 0xC36795),
            dark: Westron.RGB(hex: 0xB25986),
            lightHighContrast: Westron.RGB(hex: 0xA34A78),
            darkHighContrast: Westron.RGB(hex: 0xD477A5),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.pink.background"],
            ])

        /// Text in the list color pink.
        private static let pinkText = Westron.Color(
            name: "color.category.pink.text",
            light: Westron.RGB(hex: 0xAC427B),
            dark: Westron.RGB(hex: 0xDF6FA8),
            lightHighContrast: Westron.RGB(hex: 0x8A215D),
            darkHighContrast: Westron.RGB(hex: 0xFF9CCC),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.pink.background"],
            ])

        /// The solid fill of a lit tag in the list color pink.
        private static let pinkFill = Westron.Color(
            name: "color.category.pink.fill",
            light: Westron.RGB(hex: 0xB54481),
            dark: Westron.RGB(hex: 0xB54481),
            lightHighContrast: Westron.RGB(hex: 0x9C2C6C),
            darkHighContrast: Westron.RGB(hex: 0xEE77B3))

        /// Text and glyphs on the fill of the list color pink.
        private static let pinkOnFill = Westron.Color(
            name: "color.category.pink.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.pink.fill"]])

        /// The quiet ground of a tag or a row in the list color violet.
        private static let violetBackground = Westron.Color(
            name: "color.category.violet.background",
            light: Westron.RGB(hex: 0xF3EDFF),
            dark: Westron.RGB(hex: 0x262032),
            lightHighContrast: Westron.RGB(hex: 0xF3EDFF),
            darkHighContrast: Westron.RGB(hex: 0x262032))

        /// The border of an outlined tag in the list color violet.
        private static let violetBorder = Westron.Color(
            name: "color.category.violet.border",
            light: Westron.RGB(hex: 0x9774CF),
            dark: Westron.RGB(hex: 0x8865BE),
            lightHighContrast: Westron.RGB(hex: 0x7A57AF),
            darkHighContrast: Westron.RGB(hex: 0xA684DF),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.violet.background"],
            ])

        /// A dot or an icon in the list color violet.
        private static let violetIcon = Westron.Color(
            name: "color.category.violet.icon",
            light: Westron.RGB(hex: 0x9774CF),
            dark: Westron.RGB(hex: 0x8865BE),
            lightHighContrast: Westron.RGB(hex: 0x7A57AF),
            darkHighContrast: Westron.RGB(hex: 0xA684DF),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.violet.background"],
            ])

        /// Text in the list color violet.
        private static let violetText = Westron.Color(
            name: "color.category.violet.text",
            light: Westron.RGB(hex: 0x7E52BC),
            dark: Westron.RGB(hex: 0xAA7FEE),
            lightHighContrast: Westron.RGB(hex: 0x61339B),
            darkHighContrast: Westron.RGB(hex: 0xCAACFF),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.violet.background"],
            ])

        /// The solid fill of a lit tag in the list color violet.
        private static let violetFill = Westron.Color(
            name: "color.category.violet.fill",
            light: Westron.RGB(hex: 0x7F51C1),
            dark: Westron.RGB(hex: 0x7F51C1),
            lightHighContrast: Westron.RGB(hex: 0x6F3FAE),
            darkHighContrast: Westron.RGB(hex: 0xB588FD))

        /// Text and glyphs on the fill of the list color violet.
        private static let violetOnFill = Westron.Color(
            name: "color.category.violet.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.violet.fill"]])

        /// The quiet ground of a tag or a row in the list color indigo.
        private static let indigoBackground = Westron.Color(
            name: "color.category.indigo.background",
            light: Westron.RGB(hex: 0xEDEFFF),
            dark: Westron.RGB(hex: 0x202233),
            lightHighContrast: Westron.RGB(hex: 0xEDEFFF),
            darkHighContrast: Westron.RGB(hex: 0x202233))

        /// The border of an outlined tag in the list color indigo.
        private static let indigoBorder = Westron.Color(
            name: "color.category.indigo.border",
            light: Westron.RGB(hex: 0x7A7DD3),
            dark: Westron.RGB(hex: 0x6B6FC3),
            lightHighContrast: Westron.RGB(hex: 0x5E60B3),
            darkHighContrast: Westron.RGB(hex: 0x888DE4),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.indigo.background"],
            ])

        /// A dot or an icon in the list color indigo.
        private static let indigoIcon = Westron.Color(
            name: "color.category.indigo.icon",
            light: Westron.RGB(hex: 0x7A7DD3),
            dark: Westron.RGB(hex: 0x6B6FC3),
            lightHighContrast: Westron.RGB(hex: 0x5E60B3),
            darkHighContrast: Westron.RGB(hex: 0x888DE4),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.indigo.background"],
            ])

        /// Text in the list color indigo.
        private static let indigoText = Westron.Color(
            name: "color.category.indigo.text",
            light: Westron.RGB(hex: 0x5E5DC1),
            dark: Westron.RGB(hex: 0x878BF3),
            lightHighContrast: Westron.RGB(hex: 0x433F9F),
            darkHighContrast: Westron.RGB(hex: 0xAEB5FF),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.surface"],
                ["color.category.indigo.background"],
            ])

        /// The solid fill of a lit tag in the list color indigo.
        private static let indigoFill = Westron.Color(
            name: "color.category.indigo.fill",
            light: Westron.RGB(hex: 0x5A58C2),
            dark: Westron.RGB(hex: 0x5A58C2),
            lightHighContrast: Westron.RGB(hex: 0x4F4BB3),
            darkHighContrast: Westron.RGB(hex: 0x9095FF))

        /// Text and glyphs on the fill of the list color indigo.
        private static let indigoOnFill = Westron.Color(
            name: "color.category.indigo.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0x101318),
            backgrounds: [["color.category.indigo.fill"]])
    }
}

extension Westron.TextRole {
    /// The title of a screen. Onest Bold at the size of the largeTitle text style, tracked in by 1 % of its size.
    public static let headingLarge = Westron.TextRole(
        name: "typography.heading.large",
        textStyle: .largeTitle,
        design: .default,
        weight: .bold,
        font: "Onest-Bold",
        size: 34,
        lineHeight: 1.206,
        letterSpacing: -0.34)

    /// The title of a card, a section of a screen or an empty state. Onest Bold at the size of the title3 text style.
    public static let headingMedium = Westron.TextRole(
        name: "typography.heading.medium",
        textStyle: .title3,
        design: .default,
        weight: .bold,
        font: "Onest-Bold",
        size: 20,
        lineHeight: 1.25,
        letterSpacing: -0.2)

    /// The title of a block inside a card or a list. Onest SemiBold at the size of the headline text style.
    public static let headingSmall = Westron.TextRole(
        name: "typography.heading.small",
        textStyle: .headline,
        design: .default,
        weight: .semibold,
        font: "Onest-SemiBold",
        size: 17,
        lineHeight: 1.294,
        letterSpacing: -0.17)

    /// A short label above a group, written in capitals by the product, such as a sidebar section. Onest SemiBold at
    /// the size of the caption text style, tracked out by 6 % of its size.
    public static let headingOverline = Westron.TextRole(
        name: "typography.heading.overline",
        textStyle: .caption,
        design: .default,
        weight: .semibold,
        font: "Onest-SemiBold",
        size: 12,
        lineHeight: 1.333,
        letterSpacing: 0.72)

    /// Main text: a row's title, a field's text, a paragraph. The size follows the body text style.
    public static let bodyRegular = Westron.TextRole(
        name: "typography.body.regular",
        textStyle: .body,
        design: .default,
        weight: .regular,
        font: nil,
        size: 17,
        lineHeight: 1.294,
        letterSpacing: 0)

    /// Main text that needs emphasis: the selected row, a row with children. The size follows the body text style.
    public static let bodyStrong = Westron.TextRole(
        name: "typography.body.strong",
        textStyle: .body,
        design: .default,
        weight: .semibold,
        font: nil,
        size: 17,
        lineHeight: 1.294,
        letterSpacing: 0)

    /// Text one step below the main text: a nested row's title, a card in a column. The size follows the callout text
    /// style.
    public static let calloutRegular = Westron.TextRole(
        name: "typography.callout.regular",
        textStyle: .callout,
        design: .default,
        weight: .regular,
        font: nil,
        size: 16,
        lineHeight: 1.312,
        letterSpacing: 0)

    /// `callout.regular` with emphasis. The size follows the callout text style.
    public static let calloutStrong = Westron.TextRole(
        name: "typography.callout.strong",
        textStyle: .callout,
        design: .default,
        weight: .semibold,
        font: nil,
        size: 16,
        lineHeight: 1.312,
        letterSpacing: 0)

    /// Supporting text: a subtitle, notes, a count. The size follows the subheadline text style.
    public static let subheadlineRegular = Westron.TextRole(
        name: "typography.subheadline.regular",
        textStyle: .subheadline,
        design: .default,
        weight: .regular,
        font: nil,
        size: 15,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// A row that adds something, such as "Add task". The size follows the subheadline text style.
    public static let subheadlineMedium = Westron.TextRole(
        name: "typography.subheadline.medium",
        textStyle: .subheadline,
        design: .default,
        weight: .medium,
        font: nil,
        size: 15,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// The label of a button or of a bar item. The size follows the subheadline text style.
    public static let subheadlineStrong = Westron.TextRole(
        name: "typography.subheadline.strong",
        textStyle: .subheadline,
        design: .default,
        weight: .semibold,
        font: nil,
        size: 15,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// Secondary detail: a hint, a cell in a dense table, a line under a title. The size follows the footnote text
    /// style.
    public static let footnoteRegular = Westron.TextRole(
        name: "typography.footnote.regular",
        textStyle: .footnote,
        design: .default,
        weight: .regular,
        font: nil,
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// A small label: a column header, a date, a tag's name. The size follows the footnote text style.
    public static let footnoteMedium = Westron.TextRole(
        name: "typography.footnote.medium",
        textStyle: .footnote,
        design: .default,
        weight: .medium,
        font: nil,
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// The words on a chip, a pill or a small button. The size follows the footnote text style.
    public static let footnoteStrong = Westron.TextRole(
        name: "typography.footnote.strong",
        textStyle: .footnote,
        design: .default,
        weight: .semibold,
        font: nil,
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// Metadata and badges: a status badge, a line of metadata under a title. The size follows the caption text style.
    public static let captionMedium = Westron.TextRole(
        name: "typography.caption.medium",
        textStyle: .caption,
        design: .default,
        weight: .medium,
        font: nil,
        size: 12,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// Code, logs, identifiers and hashes: Geist Mono at the size of the footnote text style.
    public static let codeRegular = Westron.TextRole(
        name: "typography.code.regular",
        textStyle: .footnote,
        design: .monospaced,
        weight: .regular,
        font: "GeistMono-Regular",
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// Emphasis inside code or a log: a keyword, a level. Geist Mono SemiBold at the size of the footnote text style.
    public static let codeStrong = Westron.TextRole(
        name: "typography.code.strong",
        textStyle: .footnote,
        design: .monospaced,
        weight: .semibold,
        font: "GeistMono-SemiBold",
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// Every text role in token order.
    public static let all: [Westron.TextRole] = [
        headingLarge,
        headingMedium,
        headingSmall,
        headingOverline,
        bodyRegular,
        bodyStrong,
        calloutRegular,
        calloutStrong,
        subheadlineRegular,
        subheadlineMedium,
        subheadlineStrong,
        footnoteRegular,
        footnoteMedium,
        footnoteStrong,
        captionMedium,
        codeRegular,
        codeStrong,
    ]
}

extension Westron.Transition {
    /// A change of color or opacity: a hover tint, a selection, a fade in or out. It has no spring and no bounce.
    public static let fade = Westron.Transition(
        name: "motion.fade",
        duration: 0.2,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A control answering a press: its tint, and its scale down to 98 %.
    public static let press = Westron.Transition(
        name: "motion.press",
        duration: 0.15,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0, x2: 0, y2: 1),
        spring: Spring(duration: 0.15, bounce: 0))

    /// A small thing changing place: a switch's thumb, a segmented control's selection, a checkbox.
    public static let toggle = Westron.Transition(
        name: "motion.toggle",
        duration: 0.25,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0, x2: 0, y2: 1),
        spring: Spring(duration: 0.25, bounce: 0.1))

    /// A check popping into a done task. The one motion with a visible overshoot.
    public static let check = Westron.Transition(
        name: "motion.check",
        duration: 0.35,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0, x2: 0, y2: 1),
        spring: Spring(duration: 0.35, bounce: 0.2))

    /// Something moving to a new place: a reordered row, a dropped item, a section folding or unfolding.
    public static let move = Westron.Transition(
        name: "motion.move",
        duration: 0.35,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0, x2: 0, y2: 1),
        spring: Spring(duration: 0.35, bounce: 0.15))

    /// Something appearing: a popover, a menu, an inserted row.
    public static let enter = Westron.Transition(
        name: "motion.enter",
        duration: 0.35,
        delay: 0,
        curve: Curve(x1: 0, y1: 0, x2: 0, y2: 1),
        spring: Spring(duration: 0.35, bounce: 0.15))

    /// Something leaving: a deleted row, a closing popover. Leaving is quicker than entering and does not bounce.
    public static let leave = Westron.Transition(
        name: "motion.leave",
        duration: 0.2,
        delay: 0,
        curve: Curve(x1: 0.3, y1: 0, x2: 1, y2: 1),
        spring: nil)

    /// A large surface appearing: a sheet, a side panel, an opened card.
    public static let reveal = Westron.Transition(
        name: "motion.reveal",
        duration: 0.5,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0, x2: 0, y2: 1),
        spring: Spring(duration: 0.5, bounce: 0.1))

    /// Every motion in token order.
    public static let all: [Westron.Transition] = [
        fade,
        press,
        toggle,
        check,
        move,
        enter,
        leave,
        reveal,
    ]
}

extension Westron.Shadow {
    /// A card or a panel raised off the canvas.
    public static let raised = Westron.Shadow(
        name: "shadow.raised",
        light: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.06), x: 0, y: 1, blur: 2, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.1), x: 0, y: 1, blur: 3, spread: 0),
        ],
        dark: [],
        lightHighContrast: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.06), x: 0, y: 1, blur: 2, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.1), x: 0, y: 1, blur: 3, spread: 0),
        ],
        darkHighContrast: [])

    /// A popover, a menu or a floating button westron draws over the content.
    public static let overlay = Westron.Shadow(
        name: "shadow.overlay",
        light: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.08), x: 0, y: 4, blur: 12, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.12), x: 0, y: 12, blur: 32, spread: 0),
        ],
        dark: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.24), x: 0, y: 4, blur: 12, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.36), x: 0, y: 12, blur: 32, spread: 0),
        ],
        lightHighContrast: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.08), x: 0, y: 4, blur: 12, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.12), x: 0, y: 12, blur: 32, spread: 0),
        ],
        darkHighContrast: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.24), x: 0, y: 4, blur: 12, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.36), x: 0, y: 12, blur: 32, spread: 0),
        ])

    /// Something a drag carries.
    public static let dragged = Westron.Shadow(
        name: "shadow.dragged",
        light: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.1), x: 0, y: 8, blur: 16, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.16), x: 0, y: 16, blur: 40, spread: 0),
        ],
        dark: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.3), x: 0, y: 8, blur: 16, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.48), x: 0, y: 16, blur: 40, spread: 0),
        ],
        lightHighContrast: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.1), x: 0, y: 8, blur: 16, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.16), x: 0, y: 16, blur: 40, spread: 0),
        ],
        darkHighContrast: [
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.3), x: 0, y: 8, blur: 16, spread: 0),
            Layer(color: Westron.RGB(hex: 0x000000, opacity: 0.48), x: 0, y: 16, blur: 40, spread: 0),
        ])

    /// Every shadow in token order.
    public static let all: [Westron.Shadow] = [
        raised,
        overlay,
        dragged,
    ]
}

extension Westron.Dimension {
    /// Step 25 of the radius ladder: 2 px.
    public static let radius25 = Westron.Dimension(name: "radius.25", value: 2)

    /// Step 50 of the radius ladder: 4 px.
    public static let radius50 = Westron.Dimension(name: "radius.50", value: 4)

    /// Step 75 of the radius ladder: 6 px.
    public static let radius75 = Westron.Dimension(name: "radius.75", value: 6)

    /// Step 100 of the radius ladder: 8 px.
    public static let radius100 = Westron.Dimension(name: "radius.100", value: 8)

    /// Step 150 of the radius ladder: 12 px.
    public static let radius150 = Westron.Dimension(name: "radius.150", value: 12)

    /// Step 200 of the radius ladder: 16 px.
    public static let radius200 = Westron.Dimension(name: "radius.200", value: 16)

    /// Step 300 of the radius ladder: 24 px.
    public static let radius300 = Westron.Dimension(name: "radius.300", value: 24)

    /// Step 400 of the radius ladder: 32 px.
    public static let radius400 = Westron.Dimension(name: "radius.400", value: 32)

    /// A control westron draws: a button, a field, a segmented control. 8 px, a quarter of a 32 px control.
    public static let radiusControl = Westron.Dimension(name: "radius.control", value: 8)

    /// The highlight of a row under the pointer or selected.
    public static let radiusRow = Westron.Dimension(name: "radius.row", value: 8)

    /// A card or a panel on the canvas.
    public static let radiusCard = Westron.Dimension(name: "radius.card", value: 12)

    /// A popover or a menu westron draws; system ones keep their own.
    public static let radiusOverlay = Westron.Dimension(name: "radius.overlay", value: 12)

    /// A sheet or a dialog westron draws.
    public static let radiusSheet = Westron.Dimension(name: "radius.sheet", value: 16)

    /// Step 25 of the space ladder: 2 px.
    public static let space25 = Westron.Dimension(name: "space.25", value: 2)

    /// Step 50 of the space ladder: 4 px.
    public static let space50 = Westron.Dimension(name: "space.50", value: 4)

    /// Step 75 of the space ladder: 6 px.
    public static let space75 = Westron.Dimension(name: "space.75", value: 6)

    /// Step 100 of the space ladder: 8 px.
    public static let space100 = Westron.Dimension(name: "space.100", value: 8)

    /// Step 125 of the space ladder: 10 px.
    public static let space125 = Westron.Dimension(name: "space.125", value: 10)

    /// Step 150 of the space ladder: 12 px.
    public static let space150 = Westron.Dimension(name: "space.150", value: 12)

    /// Step 200 of the space ladder: 16 px.
    public static let space200 = Westron.Dimension(name: "space.200", value: 16)

    /// Step 250 of the space ladder: 20 px.
    public static let space250 = Westron.Dimension(name: "space.250", value: 20)

    /// Step 300 of the space ladder: 24 px.
    public static let space300 = Westron.Dimension(name: "space.300", value: 24)

    /// Step 400 of the space ladder: 32 px.
    public static let space400 = Westron.Dimension(name: "space.400", value: 32)

    /// Step 500 of the space ladder: 40 px.
    public static let space500 = Westron.Dimension(name: "space.500", value: 40)

    /// Step 600 of the space ladder: 48 px.
    public static let space600 = Westron.Dimension(name: "space.600", value: 48)

    /// Step 800 of the space ladder: 64 px.
    public static let space800 = Westron.Dimension(name: "space.800", value: 64)

    /// The edge of glass and of a card on a fill.
    public static let strokeHairline = Westron.Dimension(name: "stroke.hairline", value: 0.5)

    /// Rules, dividers, tree guides in a sidebar.
    public static let strokeThin = Westron.Dimension(name: "stroke.thin", value: 1)

    /// Guides on a phone, a dashed outline, a small check's ring.
    public static let strokeRegular = Westron.Dimension(name: "stroke.regular", value: 1.5)

    /// A focus ring, a drop indicator, a selection ring.
    public static let strokeThick = Westron.Dimension(name: "stroke.thick", value: 2)

    /// Every dimension in token order.
    public static let all: [Westron.Dimension] = [
        radius25,
        radius50,
        radius75,
        radius100,
        radius150,
        radius200,
        radius300,
        radius400,
        radiusControl,
        radiusRow,
        radiusCard,
        radiusOverlay,
        radiusSheet,
        space25,
        space50,
        space75,
        space100,
        space125,
        space150,
        space200,
        space250,
        space300,
        space400,
        space500,
        space600,
        space800,
        strokeHairline,
        strokeThin,
        strokeRegular,
        strokeThick,
    ]
}
