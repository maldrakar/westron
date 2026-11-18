// Hand-written. The list color of a subtree: the context a westron control takes its color from where its contract
// says the list's color fills it, as the checked Checkbox does (spec/components/checkbox, decisions/0001). It is not a
// contract option: a row does not pass its list's color to each control, it sets it once around them, as `.tint(_:)`
// sets the system controls' tint (spec/conventions.md, "Context a style reads").

import SwiftUI

extension EnvironmentValues {
    /// The list color of the westron controls in this subtree, as `.category(_:)` sets it; nil: the accent.
    @Entry var category: Westron.Category? = nil
}

extension View {
    /// Draws the westron controls in this view in a list's color, where their contracts take the list's color from
    /// the context: a checked `.toggleStyle(.check)` fills its disc with the color's `control` and draws its mark in
    /// `onControl`. nil, the default, draws them in the accent.
    ///
    ///     TaskRow(task)
    ///         .category(Westron.Category(rawValue: list.color))
    ///
    /// It cascades like `.tint(_:)`: the closest one wins.
    public func category(_ category: Westron.Category?) -> some View {
        environment(\.category, category)
    }
}
