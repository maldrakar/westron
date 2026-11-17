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
    /// It also refuses the button's keyboard shortcut, which it takes away while loading, when the shortcut is set
    /// outside it, after it in the chain:
    ///
    ///     Button("Save") { save() }
    ///         .buttonStyle(.primary)
    ///         .loading(isSaving)
    ///         .keyboardShortcut(.defaultAction)
    ///
    /// A shortcut set before it, closer to the button, wins over it, and SwiftUI runs that shortcut's action itself,
    /// around the button's style: `.keyboardShortcut(.defaultAction).loading(isSaving)` still saves on Return.
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

/// Sets the state, and while loading refuses the two activations SwiftUI runs a button's own action for without the
/// button's style, so the style alone cannot refuse them:
/// - assistive technology: the default accessibility action of the element it is applied to is replaced with one that
///   does nothing; that action is what VoiceOver, Switch Control and Voice Control run;
/// - a keyboard shortcut: the button takes its shortcut from the environment, the closest `.keyboardShortcut(_:)`
///   winning, so the shortcut set outside this modifier is passed on at rest and replaced with none while loading.
///
/// Both branches have the same type, so the view keeps its identity, and its state, when loading toggles.
private struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    #if !os(watchOS)
        @Environment(\.keyboardShortcut) private var keyboardShortcut
    #endif

    func body(content: Content) -> some View {
        let gated = isLoading ? content.accessibilityAction {} : content.accessibilityAddTraits([])
        #if os(watchOS)
            gated.environment(\.isLoading, isLoading)
        #else
            gated
                .keyboardShortcut(isLoading ? nil : keyboardShortcut)
                .environment(\.isLoading, isLoading)
        #endif
    }
}
