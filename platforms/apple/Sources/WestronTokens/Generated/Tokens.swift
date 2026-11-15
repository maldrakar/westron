// Generated from tokens/westron.resolver.json by `tools/westron generate`. Do not edit: change the tokens and generate
// again (decisions/0010).
//
// The values of westron's semantic tokens as plain Swift, with no imports, so that shared code and its WebAssembly
// build can use them; their types are in Westron.swift, their SwiftUI accessors in WestronUI.

extension Westron.Color {
    /// The ground of a screen and of the rows on it.
    ///
    /// Use for: screen background, row background. Avoid: Cards and fields: use background.surface.
    public static let backgroundCanvas = Westron.Color(
        name: "color.background.canvas",
        light: Westron.RGB(hex: 0xFAF7F2),
        dark: Westron.RGB(hex: 0x1A1917),
        lightHighContrast: Westron.RGB(hex: 0xFAF7F2),
        darkHighContrast: Westron.RGB(hex: 0x1A1917))

    /// Something raised off the canvas: a card, a field, a dragged item.
    ///
    /// Use for: card, field, dragged item. Avoid: The ground of a whole screen: use background.canvas.
    public static let backgroundSurface = Westron.Color(
        name: "color.background.surface",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0x24221F),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0x24221F))

    /// The sidebar column and its rows.
    public static let backgroundSidebar = Westron.Color(
        name: "color.background.sidebar",
        light: Westron.RGB(hex: 0xF2EDE5),
        dark: Westron.RGB(hex: 0x1F1E1B),
        lightHighContrast: Westron.RGB(hex: 0xF2EDE5),
        darkHighContrast: Westron.RGB(hex: 0x1F1E1B))

    /// A quiet fill inside content: chips, pills, columns, a highlighted row on a phone.
    ///
    /// Use for: chip, pill, column, highlighted row. Avoid: The selected row in a sidebar: use background.selected.
    public static let backgroundMuted = Westron.Color(
        name: "color.background.muted",
        light: Westron.RGB(hex: 0xF0EBE3),
        dark: Westron.RGB(hex: 0x2E2B27),
        lightHighContrast: Westron.RGB(hex: 0xF0EBE3),
        darkHighContrast: Westron.RGB(hex: 0x2E2B27))

    /// The selected row in a sidebar: the accent laid lightly over the sidebar, mixed opaque.
    public static let backgroundSelected = Westron.Color(
        name: "color.background.selected",
        light: Westron.RGB(hex: 0xD8D7E1),
        dark: Westron.RGB(hex: 0x323645),
        lightHighContrast: Westron.RGB(hex: 0xD8D7E1),
        darkHighContrast: Westron.RGB(hex: 0x323645))

    /// Laid over a control or row under the pointer. Translucent.
    ///
    /// Use for: pointer hover. Avoid: Selection: use background.selected.
    public static let backgroundHover = Westron.Color(
        name: "color.background.hover",
        light: Westron.RGB(hex: 0x1F1D1A, opacity: 0.05),
        dark: Westron.RGB(hex: 0xFFFFFF, opacity: 0.05),
        lightHighContrast: Westron.RGB(hex: 0x1F1D1A, opacity: 0.05),
        darkHighContrast: Westron.RGB(hex: 0xFFFFFF, opacity: 0.05))

    /// Laid over a control while it is pressed. Translucent.
    public static let backgroundPressed = Westron.Color(
        name: "color.background.pressed",
        light: Westron.RGB(hex: 0x1F1D1A, opacity: 0.08),
        dark: Westron.RGB(hex: 0xFFFFFF, opacity: 0.09),
        lightHighContrast: Westron.RGB(hex: 0x1F1D1A, opacity: 0.08),
        darkHighContrast: Westron.RGB(hex: 0xFFFFFF, opacity: 0.09))

    /// Laid under something that just moved, fading out. Translucent.
    public static let backgroundHighlight = Westron.Color(
        name: "color.background.highlight",
        light: Westron.RGB(hex: 0x3653C9, opacity: 0.12),
        dark: Westron.RGB(hex: 0xFFFFFF, opacity: 0.08),
        lightHighContrast: Westron.RGB(hex: 0x3653C9, opacity: 0.12),
        darkHighContrast: Westron.RGB(hex: 0xFFFFFF, opacity: 0.08))

    /// A quiet accent fill: the slot a dragged item will drop into. Opaque.
    public static let backgroundAccentSubtle = Westron.Color(
        name: "color.background.accent-subtle",
        light: Westron.RGB(hex: 0xE7EAF9),
        dark: Westron.RGB(hex: 0x212742),
        lightHighContrast: Westron.RGB(hex: 0xE7EAF9),
        darkHighContrast: Westron.RGB(hex: 0x212742))

    /// The face of a floating control where the system has no glass of its own (before OS 26). Translucent; the
    /// platform blurs what is under it.
    ///
    /// Use for: floating control before OS 26. Avoid: The content layer; on OS 26 and later use the system's glass.
    public static let backgroundGlass = Westron.Color(
        name: "color.background.glass",
        light: Westron.RGB(hex: 0xFFFFFF, opacity: 0.72),
        dark: Westron.RGB(hex: 0x322F2B, opacity: 0.72),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF, opacity: 0.72),
        darkHighContrast: Westron.RGB(hex: 0x322F2B, opacity: 0.72))

    /// The fill of the primary action: a floating "+", Done. The accent, the same in light and dark.
    ///
    /// Use for: primary action fill. Avoid: Large areas, or more than one filled control on a screen; text and borders
    /// in the accent use text.accent and border.accent.
    public static let backgroundAccent = Westron.Color(
        name: "color.background.accent",
        light: Westron.RGB(hex: 0x3653C9),
        dark: Westron.RGB(hex: 0x3653C9),
        lightHighContrast: Westron.RGB(hex: 0x324DC3),
        darkHighContrast: Westron.RGB(hex: 0x324DC3))

    /// The fill of a destructive action, such as a swipe's Delete.
    public static let backgroundDanger = Westron.Color(
        name: "color.background.danger",
        light: Westron.RGB(hex: 0xC2362B),
        dark: Westron.RGB(hex: 0xC75046),
        lightHighContrast: Westron.RGB(hex: 0xAD1F17),
        darkHighContrast: Westron.RGB(hex: 0xA32E28))

    /// Main text and glyphs.
    public static let textPrimary = Westron.Color(
        name: "color.text.primary",
        light: Westron.RGB(hex: 0x1F1D1A),
        dark: Westron.RGB(hex: 0xEEEAE3),
        lightHighContrast: Westron.RGB(hex: 0x1F1D1A),
        darkHighContrast: Westron.RGB(hex: 0xEEEAE3),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sidebar"],
            ["color.background.muted"],
            ["color.background.selected"],
            ["color.background.hover", "color.background.canvas"],
            ["color.background.hover", "color.background.muted"],
            ["color.background.highlight", "color.background.canvas"],
            ["color.background.glass", "color.background.canvas"],
            ["color.background.accent-subtle"],
        ])

    /// Supporting text and glyphs: counts, dates, metadata, notes, a done task's title.
    public static let textSecondary = Westron.Color(
        name: "color.text.secondary",
        light: Westron.RGB(hex: 0x625C53),
        dark: Westron.RGB(hex: 0xABA498),
        lightHighContrast: Westron.RGB(hex: 0x474139),
        darkHighContrast: Westron.RGB(hex: 0xCCC5B8),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sidebar"],
            ["color.background.muted"],
            ["color.background.selected"],
            ["color.background.hover", "color.background.canvas"],
            ["color.background.hover", "color.background.muted"],
            ["color.background.highlight", "color.background.canvas"],
            ["color.background.glass", "color.background.canvas"],
        ])

    /// What a field shows while it is empty. Translucent.
    public static let textPlaceholder = Westron.Color(
        name: "color.text.placeholder",
        light: Westron.RGB(hex: 0x625C53, opacity: 0.87),
        dark: Westron.RGB(hex: 0xABA498, opacity: 0.8),
        lightHighContrast: Westron.RGB(hex: 0x5A544B),
        darkHighContrast: Westron.RGB(hex: 0xB3ACA0),
        backgrounds: [["color.background.surface"], ["color.background.canvas"]])

    /// Text and glyphs on background.accent.
    ///
    /// Use for: on background.accent. Avoid: Any other background.
    public static let textOnAccent = Westron.Color(
        name: "color.text.on-accent",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
        backgrounds: [["color.background.accent"]])

    /// Text and glyphs on background.danger.
    ///
    /// Use for: on background.danger. Avoid: Any other background.
    public static let textOnDanger = Westron.Color(
        name: "color.text.on-danger",
        light: Westron.RGB(hex: 0xFFFFFF),
        dark: Westron.RGB(hex: 0xFFFFFF),
        lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
        darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
        backgrounds: [["color.background.danger"]])

    /// A word or glyph in the accent that acts, such as an action on an edit bar, or marks the chosen option.
    ///
    /// Use for: action word, chosen option's check. Avoid: Fills: use color.background.accent. Rings and indicators:
    /// use color.border.accent.
    public static let textAccent = Westron.Color(
        name: "color.text.accent",
        light: Westron.RGB(hex: 0x3653C9),
        dark: Westron.RGB(hex: 0x6488FF),
        lightHighContrast: Westron.RGB(hex: 0x2A42B7),
        darkHighContrast: Westron.RGB(hex: 0x97B2FF),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sidebar"],
            ["color.background.glass", "color.background.canvas"],
        ])

    /// Text and glyphs that warn: a due deadline.
    public static let textDanger = Westron.Color(
        name: "color.text.danger",
        light: Westron.RGB(hex: 0xC2362B),
        dark: Westron.RGB(hex: 0xF07468),
        lightHighContrast: Westron.RGB(hex: 0x9F0706),
        darkHighContrast: Westron.RGB(hex: 0xFF9D91),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.muted"]])

    /// Quiet glyphs and decorations: a grip, a strike-through line. Meets 3:1, not 4.5:1.
    ///
    /// Use for: grip, strike-through. Avoid: Words of any size: use text.secondary.
    public static let iconTertiary = Westron.Color(
        name: "color.icon.tertiary",
        light: Westron.RGB(hex: 0x80796E),
        dark: Westron.RGB(hex: 0x847F76),
        lightHighContrast: Westron.RGB(hex: 0x645E53),
        darkHighContrast: Westron.RGB(hex: 0xA39E94),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sidebar"],
            ["color.background.muted"],
            ["color.background.selected"],
        ])

    /// Rules, dividers and outlines.
    public static let borderDefault = Westron.Color(
        name: "color.border.default",
        light: Westron.RGB(hex: 0xE8E2D8),
        dark: Westron.RGB(hex: 0x35322D),
        lightHighContrast: Westron.RGB(hex: 0x8E887F),
        darkHighContrast: Westron.RGB(hex: 0x6F6C66),
        backgrounds: [["color.background.canvas"], ["color.background.surface"], ["color.background.sidebar"]])

    /// The guides down the branches of a tree in a sidebar.
    public static let borderGuide = Westron.Color(
        name: "color.border.guide",
        light: Westron.RGB(hex: 0xE0D9CC),
        dark: Westron.RGB(hex: 0x36332E),
        lightHighContrast: Westron.RGB(hex: 0x8F887C),
        darkHighContrast: Westron.RGB(hex: 0x6B6862),
        backgrounds: [["color.background.sidebar"]])

    /// The hairline round glass and round a card on a fill. Translucent.
    public static let borderGlass = Westron.Color(
        name: "color.border.glass",
        light: Westron.RGB(hex: 0x1F1D1A, opacity: 0.08),
        dark: Westron.RGB(hex: 0xFFFFFF, opacity: 0.08),
        lightHighContrast: Westron.RGB(hex: 0x1F1D1A, opacity: 0.49),
        darkHighContrast: Westron.RGB(hex: 0xFFFFFF, opacity: 0.35),
        backgrounds: [["color.background.canvas"], ["color.background.muted"]])

    /// A focus ring, a drop indicator, the outline of a drop slot.
    ///
    /// Use for: focus ring, drop indicator. Avoid: Text: use text.accent. Fills: use background.accent.
    public static let borderAccent = Westron.Color(
        name: "color.border.accent",
        light: Westron.RGB(hex: 0x3653C9),
        dark: Westron.RGB(hex: 0x5377F0),
        lightHighContrast: Westron.RGB(hex: 0x3653C9),
        darkHighContrast: Westron.RGB(hex: 0x789BFF),
        backgrounds: [
            ["color.background.canvas"],
            ["color.background.surface"],
            ["color.background.sidebar"],
            ["color.background.muted"],
            ["color.background.selected"],
            ["color.background.accent-subtle"],
        ])

    /// Every semantic color in token order, the list colors included.
    public static let all: [Westron.Color] = [
        backgroundCanvas,
        backgroundSurface,
        backgroundSidebar,
        backgroundMuted,
        backgroundSelected,
        backgroundHover,
        backgroundPressed,
        backgroundHighlight,
        backgroundAccentSubtle,
        backgroundGlass,
        backgroundAccent,
        backgroundDanger,
        textPrimary,
        textSecondary,
        textPlaceholder,
        textOnAccent,
        textOnDanger,
        textAccent,
        textDanger,
        iconTertiary,
        borderDefault,
        borderGuide,
        borderGlass,
        borderAccent,
        Westron.Category.blue.background,
        Westron.Category.blue.backgroundSubtle,
        Westron.Category.blue.text,
        Westron.Category.blue.border,
        Westron.Category.blue.fill,
        Westron.Category.blue.onFill,
        Westron.Category.amber.background,
        Westron.Category.amber.backgroundSubtle,
        Westron.Category.amber.text,
        Westron.Category.amber.border,
        Westron.Category.amber.fill,
        Westron.Category.amber.onFill,
        Westron.Category.rose.background,
        Westron.Category.rose.backgroundSubtle,
        Westron.Category.rose.text,
        Westron.Category.rose.border,
        Westron.Category.rose.fill,
        Westron.Category.rose.onFill,
        Westron.Category.green.background,
        Westron.Category.green.backgroundSubtle,
        Westron.Category.green.text,
        Westron.Category.green.border,
        Westron.Category.green.fill,
        Westron.Category.green.onFill,
        Westron.Category.stone.background,
        Westron.Category.stone.backgroundSubtle,
        Westron.Category.stone.text,
        Westron.Category.stone.border,
        Westron.Category.stone.fill,
        Westron.Category.stone.onFill,
        Westron.Category.indigo.background,
        Westron.Category.indigo.backgroundSubtle,
        Westron.Category.indigo.text,
        Westron.Category.indigo.border,
        Westron.Category.indigo.fill,
        Westron.Category.indigo.onFill,
        Westron.Category.teal.background,
        Westron.Category.teal.backgroundSubtle,
        Westron.Category.teal.text,
        Westron.Category.teal.border,
        Westron.Category.teal.fill,
        Westron.Category.teal.onFill,
        Westron.Category.pink.background,
        Westron.Category.pink.backgroundSubtle,
        Westron.Category.pink.text,
        Westron.Category.pink.border,
        Westron.Category.pink.fill,
        Westron.Category.pink.onFill,
        Westron.Category.orange.background,
        Westron.Category.orange.backgroundSubtle,
        Westron.Category.orange.text,
        Westron.Category.orange.border,
        Westron.Category.orange.fill,
        Westron.Category.orange.onFill,
        Westron.Category.violet.background,
        Westron.Category.violet.backgroundSubtle,
        Westron.Category.violet.text,
        Westron.Category.violet.border,
        Westron.Category.violet.fill,
        Westron.Category.violet.onFill,
        Westron.Category.sky.background,
        Westron.Category.sky.backgroundSubtle,
        Westron.Category.sky.text,
        Westron.Category.sky.border,
        Westron.Category.sky.fill,
        Westron.Category.sky.onFill,
    ]
}

extension Westron {
    /// The list colors, `color.category.<name>.<role>`. A product keeps a list's color by the case's raw value, its
    /// name in the tokens, and reads it back with `init(rawValue:)`.
    public enum Category: String, CaseIterable, Sendable {
        case blue
        case amber
        case rose
        case green
        case stone
        case indigo
        case teal
        case pink
        case orange
        case violet
        case sky

        /// The tile under a list's glyph: the list color, translucent.
        public var background: Westron.Color {
            switch self {
            case .blue: Self.blueBackground
            case .amber: Self.amberBackground
            case .rose: Self.roseBackground
            case .green: Self.greenBackground
            case .stone: Self.stoneBackground
            case .indigo: Self.indigoBackground
            case .teal: Self.tealBackground
            case .pink: Self.pinkBackground
            case .orange: Self.orangeBackground
            case .violet: Self.violetBackground
            case .sky: Self.skyBackground
            }
        }

        /// A column or block tinted while something would drop into it: the list color, translucent.
        public var backgroundSubtle: Westron.Color {
            switch self {
            case .blue: Self.blueBackgroundSubtle
            case .amber: Self.amberBackgroundSubtle
            case .rose: Self.roseBackgroundSubtle
            case .green: Self.greenBackgroundSubtle
            case .stone: Self.stoneBackgroundSubtle
            case .indigo: Self.indigoBackgroundSubtle
            case .teal: Self.tealBackgroundSubtle
            case .pink: Self.pinkBackgroundSubtle
            case .orange: Self.orangeBackgroundSubtle
            case .violet: Self.violetBackgroundSubtle
            case .sky: Self.skyBackgroundSubtle
            }
        }

        /// Text and glyphs in the list color: a section title, the glyph on the list's tile.
        public var text: Westron.Color {
            switch self {
            case .blue: Self.blueText
            case .amber: Self.amberText
            case .rose: Self.roseText
            case .green: Self.greenText
            case .stone: Self.stoneText
            case .indigo: Self.indigoText
            case .teal: Self.tealText
            case .pink: Self.pinkText
            case .orange: Self.orangeText
            case .violet: Self.violetText
            case .sky: Self.skyText
            }
        }

        /// The ring of an open check in the list color.
        public var border: Westron.Color {
            switch self {
            case .blue: Self.blueBorder
            case .amber: Self.amberBorder
            case .rose: Self.roseBorder
            case .green: Self.greenBorder
            case .stone: Self.stoneBorder
            case .indigo: Self.indigoBorder
            case .teal: Self.tealBorder
            case .pink: Self.pinkBorder
            case .orange: Self.orangeBorder
            case .violet: Self.violetBorder
            case .sky: Self.skyBorder
            }
        }

        /// The disc of a done check, a lit chip: the list color.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        public var fill: Westron.Color {
            switch self {
            case .blue: Self.blueFill
            case .amber: Self.amberFill
            case .rose: Self.roseFill
            case .green: Self.greenFill
            case .stone: Self.stoneFill
            case .indigo: Self.indigoFill
            case .teal: Self.tealFill
            case .pink: Self.pinkFill
            case .orange: Self.orangeFill
            case .violet: Self.violetFill
            case .sky: Self.skyFill
            }
        }

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        public var onFill: Westron.Color {
            switch self {
            case .blue: Self.blueOnFill
            case .amber: Self.amberOnFill
            case .rose: Self.roseOnFill
            case .green: Self.greenOnFill
            case .stone: Self.stoneOnFill
            case .indigo: Self.indigoOnFill
            case .teal: Self.tealOnFill
            case .pink: Self.pinkOnFill
            case .orange: Self.orangeOnFill
            case .violet: Self.violetOnFill
            case .sky: Self.skyOnFill
            }
        }

        /// The colors of the category, one per role, in token order.
        public var colors: [Westron.Color] { [background, backgroundSubtle, text, border, fill, onFill] }

        /// The tile under a list's glyph: the list color blue, translucent.
        private static let blueBackground = Westron.Color(
            name: "color.category.blue.background",
            light: Westron.RGB(hex: 0x3E6EC5, opacity: 0.15),
            dark: Westron.RGB(hex: 0x3E6EC5, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x3E6EC5, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x3E6EC5, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color blue, translucent.
        private static let blueBackgroundSubtle = Westron.Color(
            name: "color.category.blue.background-subtle",
            light: Westron.RGB(hex: 0x3E6EC5, opacity: 0.1),
            dark: Westron.RGB(hex: 0x3E6EC5, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x3E6EC5, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x3E6EC5, opacity: 0.2))

        /// Text and glyphs in the list color blue: a section title, the glyph on the list's tile.
        private static let blueText = Westron.Color(
            name: "color.category.blue.text",
            light: Westron.RGB(hex: 0x385EA3),
            dark: Westron.RGB(hex: 0x789AD6),
            lightHighContrast: Westron.RGB(hex: 0x284C90),
            darkHighContrast: Westron.RGB(hex: 0x95B8F6),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.blue.background", "color.background.canvas"],
                ["color.category.blue.background", "color.background.surface"],
                ["color.category.blue.background", "color.background.sidebar"],
                ["color.category.blue.background", "color.background.muted"],
                ["color.category.blue.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color blue.
        private static let blueBorder = Westron.Color(
            name: "color.category.blue.border",
            light: Westron.RGB(hex: 0x385EA3),
            dark: Westron.RGB(hex: 0x6188CF),
            lightHighContrast: Westron.RGB(hex: 0x385EA3),
            darkHighContrast: Westron.RGB(hex: 0x6289D0),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color blue.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let blueFill = Westron.Color(
            name: "color.category.blue.fill",
            light: Westron.RGB(hex: 0x3E6EC5),
            dark: Westron.RGB(hex: 0x4D7ACA),
            lightHighContrast: Westron.RGB(hex: 0x3E6EC5),
            darkHighContrast: Westron.RGB(hex: 0x4975C5))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let blueOnFill = Westron.Color(
            name: "color.category.blue.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.blue.fill"]])

        /// The tile under a list's glyph: the list color amber, translucent.
        private static let amberBackground = Westron.Color(
            name: "color.category.amber.background",
            light: Westron.RGB(hex: 0xD49408, opacity: 0.15),
            dark: Westron.RGB(hex: 0xD49408, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0xD49408, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0xD49408, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color amber, translucent.
        private static let amberBackgroundSubtle = Westron.Color(
            name: "color.category.amber.background-subtle",
            light: Westron.RGB(hex: 0xD49408, opacity: 0.1),
            dark: Westron.RGB(hex: 0xD49408, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0xD49408, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0xD49408, opacity: 0.2))

        /// Text and glyphs in the list color amber: a section title, the glyph on the list's tile.
        private static let amberText = Westron.Color(
            name: "color.category.amber.text",
            light: Westron.RGB(hex: 0x8E6200),
            dark: Westron.RGB(hex: 0xE1B452),
            lightHighContrast: Westron.RGB(hex: 0x694800),
            darkHighContrast: Westron.RGB(hex: 0xE6B957),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.amber.background", "color.background.canvas"],
                ["color.category.amber.background", "color.background.surface"],
                ["color.category.amber.background", "color.background.sidebar"],
                ["color.category.amber.background", "color.background.muted"],
                ["color.category.amber.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color amber.
        private static let amberBorder = Westron.Color(
            name: "color.category.amber.border",
            light: Westron.RGB(hex: 0xB07C0C),
            dark: Westron.RGB(hex: 0xDCA734),
            lightHighContrast: Westron.RGB(hex: 0x986900),
            darkHighContrast: Westron.RGB(hex: 0xDCA734),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color amber.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let amberFill = Westron.Color(
            name: "color.category.amber.fill",
            light: Westron.RGB(hex: 0xD49408),
            dark: Westron.RGB(hex: 0xD79D1C),
            lightHighContrast: Westron.RGB(hex: 0xD49408),
            darkHighContrast: Westron.RGB(hex: 0xD79D1C))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let amberOnFill = Westron.Color(
            name: "color.category.amber.on-fill",
            light: Westron.RGB(hex: 0x1F1D1A),
            dark: Westron.RGB(hex: 0x1F1D1A),
            lightHighContrast: Westron.RGB(hex: 0x1F1D1A),
            darkHighContrast: Westron.RGB(hex: 0x1F1D1A),
            backgrounds: [["color.category.amber.fill"]])

        /// The tile under a list's glyph: the list color rose, translucent.
        private static let roseBackground = Westron.Color(
            name: "color.category.rose.background",
            light: Westron.RGB(hex: 0xD2455A, opacity: 0.15),
            dark: Westron.RGB(hex: 0xD2455A, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0xD2455A, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0xD2455A, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color rose, translucent.
        private static let roseBackgroundSubtle = Westron.Color(
            name: "color.category.rose.background-subtle",
            light: Westron.RGB(hex: 0xD2455A, opacity: 0.1),
            dark: Westron.RGB(hex: 0xD2455A, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0xD2455A, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0xD2455A, opacity: 0.2))

        /// Text and glyphs in the list color rose: a section title, the glyph on the list's tile.
        private static let roseText = Westron.Color(
            name: "color.category.rose.text",
            light: Westron.RGB(hex: 0xAE3D4D),
            dark: Westron.RGB(hex: 0xE07D8C),
            lightHighContrast: Westron.RGB(hex: 0x932237),
            darkHighContrast: Westron.RGB(hex: 0xFF9AA8),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.rose.background", "color.background.canvas"],
                ["color.category.rose.background", "color.background.surface"],
                ["color.category.rose.background", "color.background.sidebar"],
                ["color.category.rose.background", "color.background.muted"],
                ["color.category.rose.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color rose.
        private static let roseBorder = Westron.Color(
            name: "color.category.rose.border",
            light: Westron.RGB(hex: 0xAE3D4D),
            dark: Westron.RGB(hex: 0xDA6678),
            lightHighContrast: Westron.RGB(hex: 0xAE3D4D),
            darkHighContrast: Westron.RGB(hex: 0xDA6678),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color rose.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let roseFill = Westron.Color(
            name: "color.category.rose.fill",
            light: Westron.RGB(hex: 0xD2455A),
            dark: Westron.RGB(hex: 0xD65467),
            lightHighContrast: Westron.RGB(hex: 0xD04359),
            darkHighContrast: Westron.RGB(hex: 0xCA495E))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let roseOnFill = Westron.Color(
            name: "color.category.rose.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.rose.fill"]])

        /// The tile under a list's glyph: the list color green, translucent.
        private static let greenBackground = Westron.Color(
            name: "color.category.green.background",
            light: Westron.RGB(hex: 0x36925C, opacity: 0.15),
            dark: Westron.RGB(hex: 0x36925C, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x36925C, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x36925C, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color green, translucent.
        private static let greenBackgroundSubtle = Westron.Color(
            name: "color.category.green.background-subtle",
            light: Westron.RGB(hex: 0x36925C, opacity: 0.1),
            dark: Westron.RGB(hex: 0x36925C, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x36925C, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x36925C, opacity: 0.2))

        /// Text and glyphs in the list color green: a section title, the glyph on the list's tile.
        private static let greenText = Westron.Color(
            name: "color.category.green.text",
            light: Westron.RGB(hex: 0x2E784C),
            dark: Westron.RGB(hex: 0x72B38D),
            lightHighContrast: Westron.RGB(hex: 0x035A30),
            darkHighContrast: Westron.RGB(hex: 0x83C59E),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.green.background", "color.background.canvas"],
                ["color.category.green.background", "color.background.surface"],
                ["color.category.green.background", "color.background.sidebar"],
                ["color.category.green.background", "color.background.muted"],
                ["color.category.green.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color green.
        private static let greenBorder = Westron.Color(
            name: "color.category.green.border",
            light: Westron.RGB(hex: 0x317B4F),
            dark: Westron.RGB(hex: 0x5AA679),
            lightHighContrast: Westron.RGB(hex: 0x317B4F),
            darkHighContrast: Westron.RGB(hex: 0x5AA679),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color green.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let greenFill = Westron.Color(
            name: "color.category.green.fill",
            light: Westron.RGB(hex: 0x36925C),
            dark: Westron.RGB(hex: 0x469B69),
            lightHighContrast: Westron.RGB(hex: 0x288651),
            darkHighContrast: Westron.RGB(hex: 0x2F8656))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let greenOnFill = Westron.Color(
            name: "color.category.green.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.green.fill"]])

        /// The tile under a list's glyph: the list color stone, translucent.
        private static let stoneBackground = Westron.Color(
            name: "color.category.stone.background",
            light: Westron.RGB(hex: 0x8A847A, opacity: 0.15),
            dark: Westron.RGB(hex: 0x8A847A, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x8A847A, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x8A847A, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color stone, translucent.
        private static let stoneBackgroundSubtle = Westron.Color(
            name: "color.category.stone.background-subtle",
            light: Westron.RGB(hex: 0x8A847A, opacity: 0.1),
            dark: Westron.RGB(hex: 0x8A847A, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x8A847A, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x8A847A, opacity: 0.2))

        /// Text and glyphs in the list color stone: a section title, the glyph on the list's tile.
        private static let stoneText = Westron.Color(
            name: "color.category.stone.text",
            light: Westron.RGB(hex: 0x706A62),
            dark: Westron.RGB(hex: 0xADA9A2),
            lightHighContrast: Westron.RGB(hex: 0x534D46),
            darkHighContrast: Westron.RGB(hex: 0xBBB7B0),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.stone.background", "color.background.canvas"],
                ["color.category.stone.background", "color.background.surface"],
                ["color.category.stone.background", "color.background.sidebar"],
                ["color.category.stone.background", "color.background.muted"],
                ["color.category.stone.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color stone.
        private static let stoneBorder = Westron.Color(
            name: "color.category.stone.border",
            light: Westron.RGB(hex: 0x756F67),
            dark: Westron.RGB(hex: 0x9F9A92),
            lightHighContrast: Westron.RGB(hex: 0x756F67),
            darkHighContrast: Westron.RGB(hex: 0x9F9A92),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color stone.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let stoneFill = Westron.Color(
            name: "color.category.stone.fill",
            light: Westron.RGB(hex: 0x8A847A),
            dark: Westron.RGB(hex: 0x938E85),
            lightHighContrast: Westron.RGB(hex: 0x7C766C),
            darkHighContrast: Westron.RGB(hex: 0x7B766E))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let stoneOnFill = Westron.Color(
            name: "color.category.stone.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.stone.fill"]])

        /// The tile under a list's glyph: the list color indigo, translucent.
        private static let indigoBackground = Westron.Color(
            name: "color.category.indigo.background",
            light: Westron.RGB(hex: 0x5B55D8, opacity: 0.15),
            dark: Westron.RGB(hex: 0x5B55D8, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x5B55D8, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x5B55D8, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color indigo, translucent.
        private static let indigoBackgroundSubtle = Westron.Color(
            name: "color.category.indigo.background-subtle",
            light: Westron.RGB(hex: 0x5B55D8, opacity: 0.1),
            dark: Westron.RGB(hex: 0x5B55D8, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x5B55D8, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x5B55D8, opacity: 0.2))

        /// Text and glyphs in the list color indigo: a section title, the glyph on the list's tile.
        private static let indigoText = Westron.Color(
            name: "color.category.indigo.text",
            light: Westron.RGB(hex: 0x4F4AB2),
            dark: Westron.RGB(hex: 0x8C88E4),
            lightHighContrast: Westron.RGB(hex: 0x463FA6),
            darkHighContrast: Westron.RGB(hex: 0xB1B0FF),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.indigo.background", "color.background.canvas"],
                ["color.category.indigo.background", "color.background.surface"],
                ["color.category.indigo.background", "color.background.sidebar"],
                ["color.category.indigo.background", "color.background.muted"],
                ["color.category.indigo.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color indigo.
        private static let indigoBorder = Westron.Color(
            name: "color.category.indigo.border",
            light: Westron.RGB(hex: 0x4F4AB2),
            dark: Westron.RGB(hex: 0x7974DF),
            lightHighContrast: Westron.RGB(hex: 0x4F4AB2),
            darkHighContrast: Westron.RGB(hex: 0x807CE8),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color indigo.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let indigoFill = Westron.Color(
            name: "color.category.indigo.fill",
            light: Westron.RGB(hex: 0x5B55D8),
            dark: Westron.RGB(hex: 0x6863DB),
            lightHighContrast: Westron.RGB(hex: 0x5B55D8),
            darkHighContrast: Westron.RGB(hex: 0x6863DB))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let indigoOnFill = Westron.Color(
            name: "color.category.indigo.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.indigo.fill"]])

        /// The tile under a list's glyph: the list color teal, translucent.
        private static let tealBackground = Westron.Color(
            name: "color.category.teal.background",
            light: Westron.RGB(hex: 0x168985, opacity: 0.15),
            dark: Westron.RGB(hex: 0x168985, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x168985, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x168985, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color teal, translucent.
        private static let tealBackgroundSubtle = Westron.Color(
            name: "color.category.teal.background-subtle",
            light: Westron.RGB(hex: 0x168985, opacity: 0.1),
            dark: Westron.RGB(hex: 0x168985, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x168985, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x168985, opacity: 0.2))

        /// Text and glyphs in the list color teal: a section title, the glyph on the list's tile.
        private static let tealText = Westron.Color(
            name: "color.category.teal.text",
            light: Westron.RGB(hex: 0x187370),
            dark: Westron.RGB(hex: 0x5CACAA),
            lightHighContrast: Westron.RGB(hex: 0x005855),
            darkHighContrast: Westron.RGB(hex: 0x75C5C2),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.teal.background", "color.background.canvas"],
                ["color.category.teal.background", "color.background.surface"],
                ["color.category.teal.background", "color.background.sidebar"],
                ["color.category.teal.background", "color.background.muted"],
                ["color.category.teal.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color teal.
        private static let tealBorder = Westron.Color(
            name: "color.category.teal.border",
            light: Westron.RGB(hex: 0x187370),
            dark: Westron.RGB(hex: 0x409E9B),
            lightHighContrast: Westron.RGB(hex: 0x187370),
            darkHighContrast: Westron.RGB(hex: 0x409E9B),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color teal.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let tealFill = Westron.Color(
            name: "color.category.teal.fill",
            light: Westron.RGB(hex: 0x168985),
            dark: Westron.RGB(hex: 0x29928F),
            lightHighContrast: Westron.RGB(hex: 0x0B8481),
            darkHighContrast: Westron.RGB(hex: 0x118482))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let tealOnFill = Westron.Color(
            name: "color.category.teal.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.teal.fill"]])

        /// The tile under a list's glyph: the list color pink, translucent.
        private static let pinkBackground = Westron.Color(
            name: "color.category.pink.background",
            light: Westron.RGB(hex: 0xC64C88, opacity: 0.15),
            dark: Westron.RGB(hex: 0xC64C88, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0xC64C88, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0xC64C88, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color pink, translucent.
        private static let pinkBackgroundSubtle = Westron.Color(
            name: "color.category.pink.background-subtle",
            light: Westron.RGB(hex: 0xC64C88, opacity: 0.1),
            dark: Westron.RGB(hex: 0xC64C88, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0xC64C88, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0xC64C88, opacity: 0.2))

        /// Text and glyphs in the list color pink: a section title, the glyph on the list's tile.
        private static let pinkText = Westron.Color(
            name: "color.category.pink.text",
            light: Westron.RGB(hex: 0xA54372),
            dark: Westron.RGB(hex: 0xD782AC),
            lightHighContrast: Westron.RGB(hex: 0x882859),
            darkHighContrast: Westron.RGB(hex: 0xF49DC7),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.pink.background", "color.background.canvas"],
                ["color.category.pink.background", "color.background.surface"],
                ["color.category.pink.background", "color.background.sidebar"],
                ["color.category.pink.background", "color.background.muted"],
                ["color.category.pink.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color pink.
        private static let pinkBorder = Westron.Color(
            name: "color.category.pink.border",
            light: Westron.RGB(hex: 0xA54372),
            dark: Westron.RGB(hex: 0xD06C9D),
            lightHighContrast: Westron.RGB(hex: 0xA54372),
            darkHighContrast: Westron.RGB(hex: 0xD06C9D),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color pink.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let pinkFill = Westron.Color(
            name: "color.category.pink.fill",
            light: Westron.RGB(hex: 0xC64C88),
            dark: Westron.RGB(hex: 0xCB5A92),
            lightHighContrast: Westron.RGB(hex: 0xC34986),
            darkHighContrast: Westron.RGB(hex: 0xBE4F87))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let pinkOnFill = Westron.Color(
            name: "color.category.pink.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.pink.fill"]])

        /// The tile under a list's glyph: the list color orange, translucent.
        private static let orangeBackground = Westron.Color(
            name: "color.category.orange.background",
            light: Westron.RGB(hex: 0xD7652C, opacity: 0.15),
            dark: Westron.RGB(hex: 0xD7652C, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0xD7652C, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0xD7652C, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color orange, translucent.
        private static let orangeBackgroundSubtle = Westron.Color(
            name: "color.category.orange.background-subtle",
            light: Westron.RGB(hex: 0xD7652C, opacity: 0.1),
            dark: Westron.RGB(hex: 0xD7652C, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0xD7652C, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0xD7652C, opacity: 0.2))

        /// Text and glyphs in the list color orange: a section title, the glyph on the list's tile.
        private static let orangeText = Westron.Color(
            name: "color.category.orange.text",
            light: Westron.RGB(hex: 0xAB5121),
            dark: Westron.RGB(hex: 0xE3936B),
            lightHighContrast: Westron.RGB(hex: 0x863500),
            darkHighContrast: Westron.RGB(hex: 0xF5A47B),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.orange.background", "color.background.canvas"],
                ["color.category.orange.background", "color.background.surface"],
                ["color.category.orange.background", "color.background.sidebar"],
                ["color.category.orange.background", "color.background.muted"],
                ["color.category.orange.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color orange.
        private static let orangeBorder = Westron.Color(
            name: "color.category.orange.border",
            light: Westron.RGB(hex: 0xB25728),
            dark: Westron.RGB(hex: 0xDE8152),
            lightHighContrast: Westron.RGB(hex: 0xB25728),
            darkHighContrast: Westron.RGB(hex: 0xDE8152),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color orange.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let orangeFill = Westron.Color(
            name: "color.category.orange.fill",
            light: Westron.RGB(hex: 0xD7652C),
            dark: Westron.RGB(hex: 0xDA713D),
            lightHighContrast: Westron.RGB(hex: 0xC55416),
            darkHighContrast: Westron.RGB(hex: 0xBF5821))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let orangeOnFill = Westron.Color(
            name: "color.category.orange.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.orange.fill"]])

        /// The tile under a list's glyph: the list color violet, translucent.
        private static let violetBackground = Westron.Color(
            name: "color.category.violet.background",
            light: Westron.RGB(hex: 0x8452C8, opacity: 0.15),
            dark: Westron.RGB(hex: 0x8452C8, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x8452C8, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x8452C8, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color violet, translucent.
        private static let violetBackgroundSubtle = Westron.Color(
            name: "color.category.violet.background-subtle",
            light: Westron.RGB(hex: 0x8452C8, opacity: 0.1),
            dark: Westron.RGB(hex: 0x8452C8, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x8452C8, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x8452C8, opacity: 0.2))

        /// Text and glyphs in the list color violet: a section title, the glyph on the list's tile.
        private static let violetText = Westron.Color(
            name: "color.category.violet.text",
            light: Westron.RGB(hex: 0x7047A5),
            dark: Westron.RGB(hex: 0xA986D8),
            lightHighContrast: Westron.RGB(hex: 0x623895),
            darkHighContrast: Westron.RGB(hex: 0xCAA7FC),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.violet.background", "color.background.canvas"],
                ["color.category.violet.background", "color.background.surface"],
                ["color.category.violet.background", "color.background.sidebar"],
                ["color.category.violet.background", "color.background.muted"],
                ["color.category.violet.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color violet.
        private static let violetBorder = Westron.Color(
            name: "color.category.violet.border",
            light: Westron.RGB(hex: 0x7047A5),
            dark: Westron.RGB(hex: 0x9A71D2),
            lightHighContrast: Westron.RGB(hex: 0x7047A5),
            darkHighContrast: Westron.RGB(hex: 0x9E75D6),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color violet.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let violetFill = Westron.Color(
            name: "color.category.violet.fill",
            light: Westron.RGB(hex: 0x8452C8),
            dark: Westron.RGB(hex: 0x8E60CC),
            lightHighContrast: Westron.RGB(hex: 0x8452C8),
            darkHighContrast: Westron.RGB(hex: 0x8D5FCB))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let violetOnFill = Westron.Color(
            name: "color.category.violet.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.violet.fill"]])

        /// The tile under a list's glyph: the list color sky, translucent.
        private static let skyBackground = Westron.Color(
            name: "color.category.sky.background",
            light: Westron.RGB(hex: 0x2A86B9, opacity: 0.15),
            dark: Westron.RGB(hex: 0x2A86B9, opacity: 0.24),
            lightHighContrast: Westron.RGB(hex: 0x2A86B9, opacity: 0.15),
            darkHighContrast: Westron.RGB(hex: 0x2A86B9, opacity: 0.24))

        /// A column or block tinted while something would drop into it: the list color sky, translucent.
        private static let skyBackgroundSubtle = Westron.Color(
            name: "color.category.sky.background-subtle",
            light: Westron.RGB(hex: 0x2A86B9, opacity: 0.1),
            dark: Westron.RGB(hex: 0x2A86B9, opacity: 0.2),
            lightHighContrast: Westron.RGB(hex: 0x2A86B9, opacity: 0.1),
            darkHighContrast: Westron.RGB(hex: 0x2A86B9, opacity: 0.2))

        /// Text and glyphs in the list color sky: a section title, the glyph on the list's tile.
        private static let skyText = Westron.Color(
            name: "color.category.sky.text",
            light: Westron.RGB(hex: 0x287199),
            dark: Westron.RGB(hex: 0x6AAACE),
            lightHighContrast: Westron.RGB(hex: 0x005378),
            darkHighContrast: Westron.RGB(hex: 0x7EBFE3),
            backgrounds: [
                ["color.background.canvas"],
                ["color.background.muted"],
                ["color.background.surface"],
                ["color.category.sky.background", "color.background.canvas"],
                ["color.category.sky.background", "color.background.surface"],
                ["color.category.sky.background", "color.background.sidebar"],
                ["color.category.sky.background", "color.background.muted"],
                ["color.category.sky.background", "color.background.selected"],
            ])

        /// The ring of an open check in the list color sky.
        private static let skyBorder = Westron.Color(
            name: "color.category.sky.border",
            light: Westron.RGB(hex: 0x287199),
            dark: Westron.RGB(hex: 0x509CC6),
            lightHighContrast: Westron.RGB(hex: 0x287199),
            darkHighContrast: Westron.RGB(hex: 0x509CC6),
            backgrounds: [["color.background.canvas"], ["color.background.surface"]])

        /// The disc of a done check, a lit chip: the list color sky.
        ///
        /// Use for: things that carry a list's color. Avoid: States such as danger or success: use their own tokens.
        private static let skyFill = Westron.Color(
            name: "color.category.sky.fill",
            light: Westron.RGB(hex: 0x2A86B9),
            dark: Westron.RGB(hex: 0x3B90BF),
            lightHighContrast: Westron.RGB(hex: 0x1E7DB0),
            darkHighContrast: Westron.RGB(hex: 0x267EAC))

        /// The mark on category fill: white, or the light ink where white would not stand out (amber).
        private static let skyOnFill = Westron.Color(
            name: "color.category.sky.on-fill",
            light: Westron.RGB(hex: 0xFFFFFF),
            dark: Westron.RGB(hex: 0xFFFFFF),
            lightHighContrast: Westron.RGB(hex: 0xFFFFFF),
            darkHighContrast: Westron.RGB(hex: 0xFFFFFF),
            backgrounds: [["color.category.sky.fill"]])
    }
}

extension Westron.TextRole {
    /// The title of a screen. The size follows the largeTitle text style (the pilot's largeTitle).
    public static let headingLarge = Westron.TextRole(
        name: "typography.heading.large",
        textStyle: .largeTitle,
        design: .rounded,
        weight: .heavy,
        size: 34,
        lineHeight: 1.206,
        letterSpacing: 0)

    /// The title of an empty state or a short standalone message. The size follows the title3 text style (the pilot's
    /// emptyScreenTitle).
    public static let headingMedium = Westron.TextRole(
        name: "typography.heading.medium",
        textStyle: .title3,
        design: .rounded,
        weight: .heavy,
        size: 20,
        lineHeight: 1.25,
        letterSpacing: 0)

    /// The title of a section or a block inside a screen. The size follows the headline text style (the pilot's
    /// sectionTitle).
    public static let headingSmall = Westron.TextRole(
        name: "typography.heading.small",
        textStyle: .headline,
        design: .rounded,
        weight: .heavy,
        size: 17,
        lineHeight: 1.294,
        letterSpacing: 0)

    /// A short label above a group, written in capitals by the product, such as an area's name in a sidebar. The size
    /// follows the caption text style (the pilot's areaCaption).
    public static let headingOverline = Westron.TextRole(
        name: "typography.heading.overline",
        textStyle: .caption,
        design: .rounded,
        weight: .heavy,
        size: 12,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// Main text: a row's title, a field's text, a search field. The size follows the body text style (the pilot's
    /// rowTitle, search).
    public static let bodyRegular = Westron.TextRole(
        name: "typography.body.regular",
        textStyle: .body,
        design: .default,
        weight: .regular,
        size: 17,
        lineHeight: 1.294,
        letterSpacing: 0)

    /// Main text that needs emphasis: a row with children, the selected row, a card's title. The size follows the body
    /// text style (the pilot's rowTitleEmphasized).
    public static let bodyStrong = Westron.TextRole(
        name: "typography.body.strong",
        textStyle: .body,
        design: .default,
        weight: .semibold,
        size: 17,
        lineHeight: 1.294,
        letterSpacing: 0)

    /// Text one step below the main text: a nested row's title, a card in a column. The size follows the callout text
    /// style (the pilot's nestedRowTitle).
    public static let calloutRegular = Westron.TextRole(
        name: "typography.callout.regular",
        textStyle: .callout,
        design: .default,
        weight: .regular,
        size: 16,
        lineHeight: 1.312,
        letterSpacing: 0)

    /// `callout.regular` with emphasis. The size follows the callout text style (the pilot's nestedRowTitleEmphasized).
    public static let calloutStrong = Westron.TextRole(
        name: "typography.callout.strong",
        textStyle: .callout,
        design: .default,
        weight: .semibold,
        size: 16,
        lineHeight: 1.312,
        letterSpacing: 0)

    /// Supporting text: counts, a subtitle, notes, a subtask's title. The size follows the subheadline text style (the
    /// pilot's count, notes).
    public static let subheadlineRegular = Westron.TextRole(
        name: "typography.subheadline.regular",
        textStyle: .subheadline,
        design: .default,
        weight: .regular,
        size: 15,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// A row that adds something, such as "Add task". The size follows the subheadline text style (the pilot's addRow).
    public static let subheadlineMedium = Westron.TextRole(
        name: "typography.subheadline.medium",
        textStyle: .subheadline,
        design: .default,
        weight: .medium,
        size: 15,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// A word on a bar or a button beside a glyph. The size follows the subheadline text style (the pilot's barLabel).
    public static let subheadlineStrong = Westron.TextRole(
        name: "typography.subheadline.strong",
        textStyle: .subheadline,
        design: .default,
        weight: .semibold,
        size: 15,
        lineHeight: 1.333,
        letterSpacing: 0)

    /// A hint under a title that says what to do. The size follows the footnote text style (the pilot's hint).
    public static let footnoteRegular = Westron.TextRole(
        name: "typography.footnote.regular",
        textStyle: .footnote,
        design: .default,
        weight: .regular,
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// A small label: an area's name, a date, a tag's name. The size follows the footnote text style (the pilot's
    /// areaLabel).
    public static let footnoteMedium = Westron.TextRole(
        name: "typography.footnote.medium",
        textStyle: .footnote,
        design: .default,
        weight: .medium,
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// The words on a chip or a pill. The size follows the footnote text style (the pilot's pill).
    public static let footnoteStrong = Westron.TextRole(
        name: "typography.footnote.strong",
        textStyle: .footnote,
        design: .default,
        weight: .semibold,
        size: 13,
        lineHeight: 1.385,
        letterSpacing: 0)

    /// A line of metadata under a title. The size follows the caption text style (the pilot's meta).
    public static let captionMedium = Westron.TextRole(
        name: "typography.caption.medium",
        textStyle: .caption,
        design: .default,
        weight: .medium,
        size: 12,
        lineHeight: 1.333,
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
    ]
}

extension Westron.Transition {
    /// A check popping as a task is done.
    public static let check = Westron.Transition(
        name: "motion.check",
        duration: 0.45,
        delay: 0,
        curve: Curve(x1: 0.34, y1: 1.56, x2: 0.64, y2: 1),
        spring: Spring(duration: 0.45, bounce: 0))

    /// A check's ring and fill changing color.
    public static let checkFill = Westron.Transition(
        name: "motion.check-fill",
        duration: 0.22,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A check's mark drawing itself in and out, after its colors start.
    public static let checkMark = Westron.Transition(
        name: "motion.check-mark",
        duration: 0.26,
        delay: 0.08,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A title changing color as its task is checked.
    public static let titleFade = Westron.Transition(
        name: "motion.title-fade",
        duration: 0.25,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A done row leaving, after a wait long enough to read its check.
    public static let rowLeave = Westron.Transition(
        name: "motion.row-leave",
        duration: 0.32,
        delay: 0.7,
        curve: Curve(x1: 0.42, y1: 0, x2: 1, y2: 1),
        spring: nil)

    /// A deleted row leaving at once.
    public static let rowDelete = Westron.Transition(
        name: "motion.row-delete",
        duration: 0.32,
        delay: 0,
        curve: Curve(x1: 0.42, y1: 0, x2: 1, y2: 1),
        spring: nil)

    /// A small element appearing or moving into place: a row, a chevron, a dragged item.
    public static let popover = Westron.Transition(
        name: "motion.popover",
        duration: 0.2,
        delay: 0,
        curve: Curve(x1: 0.34, y1: 1.4, x2: 0.64, y2: 1),
        spring: Spring(duration: 0.2, bounce: 0))

    /// A card opening in place of its row.
    public static let cardOpen = Westron.Transition(
        name: "motion.card-open",
        duration: 0.26,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0.8, x2: 0.2, y2: 1),
        spring: nil)

    /// Something landing where it was dropped.
    public static let drop = Westron.Transition(
        name: "motion.drop",
        duration: 0.32,
        delay: 0,
        curve: Curve(x1: 0.34, y1: 1.56, x2: 0.64, y2: 1),
        spring: Spring(duration: 0.32, bounce: 0))

    /// A row sliding aside for its actions and back.
    public static let swipe = Westron.Transition(
        name: "motion.swipe",
        duration: 0.25,
        delay: 0,
        curve: Curve(x1: 0.2, y1: 0.8, x2: 0.2, y2: 1),
        spring: nil)

    /// A chevron turning as a section folds or opens.
    public static let fold = Westron.Transition(
        name: "motion.fold",
        duration: 0.22,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// The highlight under something just moved, fading out.
    public static let highlightFade = Westron.Transition(
        name: "motion.highlight-fade",
        duration: 1.6,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A chip lighting and going out.
    public static let chipToggle = Westron.Transition(
        name: "motion.chip-toggle",
        duration: 0.18,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A drop target tinting under a drag, a dragged item dimming.
    public static let dropHighlight = Westron.Transition(
        name: "motion.drop-highlight",
        duration: 0.15,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A control's tint coming and going under the pointer.
    public static let hoverTint = Westron.Transition(
        name: "motion.hover-tint",
        duration: 0.12,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// A card's shadow deepening under the pointer and back.
    public static let hoverShadow = Westron.Transition(
        name: "motion.hover-shadow",
        duration: 0.15,
        delay: 0,
        curve: Curve(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1),
        spring: nil)

    /// Every motion in token order.
    public static let all: [Westron.Transition] = [
        check,
        checkFill,
        checkMark,
        titleFade,
        rowLeave,
        rowDelete,
        popover,
        cardOpen,
        drop,
        swipe,
        fold,
        highlightFade,
        chipToggle,
        dropHighlight,
        hoverTint,
        hoverShadow,
    ]
}

extension Westron.Shadow {
    /// A card at rest on a fill.
    public static let resting = Westron.Shadow(
        name: "shadow.resting",
        color: Westron.RGB(hex: 0x000000, opacity: 0.06),
        x: 0,
        y: 1,
        blur: 2,
        spread: 0)

    /// A card under the pointer.
    public static let hovered = Westron.Shadow(
        name: "shadow.hovered",
        color: Westron.RGB(hex: 0x000000, opacity: 0.08),
        x: 0,
        y: 3,
        blur: 10,
        spread: 0)

    /// A control raised off what it stands on: a floating button, an open card.
    public static let raised = Westron.Shadow(
        name: "shadow.raised",
        color: Westron.RGB(hex: 0x000000, opacity: 0.12),
        x: 0,
        y: 5,
        blur: 24,
        spread: 0)

    /// Something a drag carries.
    public static let lifted = Westron.Shadow(
        name: "shadow.lifted",
        color: Westron.RGB(hex: 0x000000, opacity: 0.22),
        x: 0,
        y: 10,
        blur: 36,
        spread: 0)

    /// Every shadow in token order.
    public static let all: [Westron.Shadow] = [
        resting,
        hovered,
        raised,
        lifted,
    ]
}

extension Westron.Dimension {
    /// Step 75 of the radius ladder: 6 px.
    public static let radius75 = Westron.Dimension(name: "radius.75", value: 6)

    /// Step 100 of the radius ladder: 8 px.
    public static let radius100 = Westron.Dimension(name: "radius.100", value: 8)

    /// Step 125 of the radius ladder: 10 px.
    public static let radius125 = Westron.Dimension(name: "radius.125", value: 10)

    /// Step 150 of the radius ladder: 12 px.
    public static let radius150 = Westron.Dimension(name: "radius.150", value: 12)

    /// Step 175 of the radius ladder: 14 px.
    public static let radius175 = Westron.Dimension(name: "radius.175", value: 14)

    /// Step 225 of the radius ladder: 18 px.
    public static let radius225 = Westron.Dimension(name: "radius.225", value: 18)

    /// Step 25 of the space ladder: 2 px at the regular density.
    public static let space25 = Westron.Dimension(name: "space.25", value: 2)

    /// Step 50 of the space ladder: 4 px at the regular density.
    public static let space50 = Westron.Dimension(name: "space.50", value: 4)

    /// Step 75 of the space ladder: 6 px at the regular density.
    public static let space75 = Westron.Dimension(name: "space.75", value: 6)

    /// Step 100 of the space ladder: 8 px at the regular density.
    public static let space100 = Westron.Dimension(name: "space.100", value: 8)

    /// Step 125 of the space ladder: 10 px at the regular density.
    public static let space125 = Westron.Dimension(name: "space.125", value: 10)

    /// Step 150 of the space ladder: 12 px at the regular density.
    public static let space150 = Westron.Dimension(name: "space.150", value: 12)

    /// Step 175 of the space ladder: 14 px at the regular density.
    public static let space175 = Westron.Dimension(name: "space.175", value: 14)

    /// Step 200 of the space ladder: 16 px at the regular density.
    public static let space200 = Westron.Dimension(name: "space.200", value: 16)

    /// Step 250 of the space ladder: 20 px at the regular density.
    public static let space250 = Westron.Dimension(name: "space.250", value: 20)

    /// Step 300 of the space ladder: 24 px at the regular density.
    public static let space300 = Westron.Dimension(name: "space.300", value: 24)

    /// Step 500 of the space ladder: 40 px at the regular density.
    public static let space500 = Westron.Dimension(name: "space.500", value: 40)

    /// Step 600 of the space ladder: 48 px at the regular density.
    public static let space600 = Westron.Dimension(name: "space.600", value: 48)

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
        radius75,
        radius100,
        radius125,
        radius150,
        radius175,
        radius225,
        space25,
        space50,
        space75,
        space100,
        space125,
        space150,
        space175,
        space200,
        space250,
        space300,
        space500,
        space600,
        strokeHairline,
        strokeThin,
        strokeRegular,
        strokeThick,
    ]
}
