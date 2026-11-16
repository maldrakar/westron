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
    public func loading(_ isLoading: Bool) -> some View {
        environment(\.isLoading, isLoading)
    }
}
