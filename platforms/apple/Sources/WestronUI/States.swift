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
    /// and SwiftUI gives it to every element inside (#23). Nor does any control inside take a keyboard shortcut set
    /// outside the container while it loads, a system one included: the shortcut is taken away for the whole subtree.
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

extension EnvironmentValues {
    /// Whether the components in this subtree are selected, as `.selected(_:)` sets it.
    @Entry var isSelected = false
    /// Whether the components in this subtree hold the current value of a single choice, as `.chosen(_:)` sets it.
    @Entry var isChosen = false
    /// Whether the components in this subtree are where a dragged item would be dropped onto, as `.dropTarget(_:)`
    /// sets it.
    @Entry var isDropTarget = false
}

extension View {
    /// Puts the westron components in this view that have the state `selected` into it, or takes them out of it, as
    /// `.disabled(_:)` does for `disabled`: `ListRow(action: open) { Text(list.title) }.selected(list == chosen)`.
    /// Each component's contract says what selected does to it; a selected ListRow is highlighted and announced as
    /// selected. The product passes its own selection, or a List's; westron keeps none.
    public func selected(_ isSelected: Bool) -> some View {
        environment(\.isSelected, isSelected)
    }

    /// Puts the westron components in this view that have the state `chosen` into it, or takes them out of it, as
    /// `.disabled(_:)` does for `disabled`: they hold the current value of a single choice, such as the destination a
    /// list stands in now in a "Move to…" sheet. Each component's contract says what chosen does to it; a chosen ListRow
    /// draws nothing of its own, drawn as at rest, and is announced as selected. The product marks it with a decorative
    /// check in its trailing slot, which carries no label, the trait saying what a word would:
    ///
    ///     ListRow(action: { choose(list) }) {
    ///         Text(list.title)
    ///     } trailing: {
    ///         if list == current { Icon(.check) }
    ///     }
    ///     .chosen(list == current)
    ///
    /// `.selected(_:)` is the other state: the row that is open, its content shown beside it, drawn with its look. A row
    /// both chosen and selected is drawn selected and announced as selected once
    /// (spec/components/list-row/decisions/0002).
    public func chosen(_ isChosen: Bool) -> some View {
        environment(\.isChosen, isChosen)
    }

    /// Puts the westron components in this view that have the state `dropTarget` into it, or takes them out of it:
    /// a dragged item would be dropped onto them, as a child. The product passes the `isTargeted` of its
    /// `.dropDestination`: `ListRow { … }.dropTarget(isTargeted)`. Each component's contract says what it does; a
    /// ListRow draws its accent-subtle highlight with a ring. It is not announced: a drag has another way, which is the
    /// product's.
    public func dropTarget(_ isDropTarget: Bool) -> some View {
        environment(\.isDropTarget, isDropTarget)
    }
}
