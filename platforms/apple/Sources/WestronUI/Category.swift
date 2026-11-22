// Hand-written. The list color of a subtree: the context a westron control takes its color from where its contract
// says the list's color fills it, as the checked Checkbox does (spec/components/checkbox, decisions/0001) and IconTile
// does (spec/components/icon-tile). It is not a contract option: a row does not pass its list's color to each control,
// it sets it once around them, as `.tint(_:)` sets the system controls' tint (spec/conventions.md, "Context a style
// reads").

import SwiftUI

extension EnvironmentValues {
    /// The list color of the westron controls in this subtree, as `.category(_:)` sets it; nil: each contract's own
    /// default, the accent for a checked check, the neutral tile for an `IconTile`.
    @Entry var category: Westron.Category? = nil
}

extension View {
    /// Draws the westron controls in this view in a list's color, where their contracts take the list's color from
    /// the context: a checked `.toggleStyle(.check)` fills its disc with the color's `control` and draws its mark in
    /// `onControl`; an `IconTile` is filled with the color's `fill` and draws its glyph in `onFill`. nil, the default,
    /// draws each in its contract's default: a checked check in the accent, a tile neutral, in `background.muted` with
    /// its glyph in `text.secondary`, since a tile marks a thing and the accent marks the primary action and the
    /// selection.
    ///
    ///     TaskRow(task)
    ///         .category(Westron.Category(rawValue: list.color))
    ///
    /// It cascades like `.tint(_:)`: the closest one wins.
    public func category(_ category: Westron.Category?) -> some View {
        environment(\.category, category)
    }
}
