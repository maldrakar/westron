// Generated from spec/icons/icons.yaml by `tools/westron generate`. Do not edit: change the registry and generate again
// (decisions/0011).
//
// westron's icons by name, with no imports, so that shared code and its WebAssembly build can keep and read them; the
// glyph each one draws on Apple is in WestronUI.

extension Westron {
    /// An icon by its westron name, which says what the glyph draws, not what it means on a screen (decisions/0011).
    ///
    /// A product keeps an icon by its raw value and reads it back with `init(rawValue:)`. A name this version does not
    /// know, such as one a newer version wrote, reads as nil, and the product draws `fallback` instead:
    /// `Westron.Icon(rawValue: name) ?? .fallback`. A released name is never renamed or removed.
    ///
    /// On Apple, WestronUI draws an icon as its SF Symbol: `Image(icon)`, `Label("Rename", icon: .pen)`.
    public enum Icon: String, CaseIterable, Sendable {
        /// An open tray, as for incoming mail.
        case tray

        /// The sun with its rays.
        case sun

        /// A calendar page.
        case calendar

        /// A calendar page with a clock badge.
        case week

        /// A closed book with lines of text on its cover.
        case logbook

        /// A trash can.
        case trash

        /// A briefcase.
        case briefcase

        /// A house.
        case house

        /// An hourglass.
        case hourglass

        /// A pencil.
        case pen

        /// A shopping bag.
        case bag

        /// A wrench.
        case wrench

        /// An open book.
        case book

        /// A folder.
        case folder

        /// Lines of text, each after a round check box, the first one checked.
        case list

        /// Lines of text, each after a dot.
        case bullets

        /// Three dots in a row.
        case ellipsis

        /// A plus sign.
        case plus

        /// A check mark.
        case check

        /// A chevron pointing down.
        case chevron

        /// Three horizontal lines, one above another.
        case grip

        /// A magnifying glass.
        case magnifier

        /// A microphone.
        case microphone

        /// A window with a plus badge.
        case newWindow

        /// A check mark in a circle.
        case checkCircle

        /// A rectangle split by a horizontal line into a top and a bottom half.
        case divider

        /// A flag on a pole.
        case flag

        /// A number sign.
        case hash

        /// A note card with lines of text.
        case note

        /// Two diagonal arrows pointing away from each other.
        case expand

        /// A rectangle split into three columns.
        case columns

        /// A chevron pointing left.
        case chevronLeft

        /// The icon to draw for a name this version does not know: `bullets`.
        public static let fallback = Westron.Icon.bullets
    }
}
