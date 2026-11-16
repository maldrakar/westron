// Hand-written. The states a contract declares that the system controls lack: a modifier sets each one through the
// environment, it cascades like `.disabled(_:)`, and every westron style in the subtree that has the state reads it
// (decisions/0003, spec/conventions.md, "States").

import SwiftUI

extension EnvironmentValues {
    /// Whether the components in this subtree are loading, as `.loading(_:)` sets it.
    @Entry var isLoading = false
}

extension View {
    /// Puts the westron components in this view that have the state `loading` into it, or takes them out of it, as
    /// `.disabled(_:)` does for `disabled`: `Button("Save") { save() }.buttonStyle(.primary).loading(isSaving)`. Each
    /// component's contract says what loading does to it.
    ///
    /// A loading westron button refuses a touch, a click and an activation by assistive technology (VoiceOver, Switch
    /// Control, Voice Control), and stays enabled: it is not drawn or announced as unavailable.
    ///
    /// It cannot refuse a keyboard shortcut on macOS: SwiftUI runs a shortcut's action itself, around any style or
    /// modifier. A product that gives a loading button a shortcut guards its action or drops the shortcut while
    /// loading:
    ///
    ///     Button("Save") { save() }
    ///         .buttonStyle(.primary)
    ///         .loading(isSaving)
    ///         .keyboardShortcut(isSaving ? nil : .defaultAction)
    ///
    /// Put `.loading(_:)` on the button itself, not on a container. On a container it sets the state for every
    /// westron component inside, but while loading assistive technology can activate nothing in it, not even a system
    /// `Toggle` or `Button` that knows nothing of loading: the refusal is the container's default accessibility action,
    /// and SwiftUI gives it to every element inside (#23).
    ///
    /// A loading button announces "Loading" as its accessibility value. A value the product gives the same button,
    /// `.accessibilityValue("3 selected")`, wins over it, and then loading is not announced.
    public func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

/// Sets the state, and while loading replaces the default accessibility action of the element it is applied to with
/// one that does nothing: that action is what VoiceOver, Switch Control and Voice Control run, and SwiftUI runs a
/// button's own action for it without the button's style, so the style alone cannot refuse it.
///
/// Both branches have the same type, so the view keeps its identity, and its state, when loading toggles.
private struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        let gated = isLoading ? content.accessibilityAction {} : content.accessibilityAddTraits([])
        gated.environment(\.isLoading, isLoading)
    }
}
