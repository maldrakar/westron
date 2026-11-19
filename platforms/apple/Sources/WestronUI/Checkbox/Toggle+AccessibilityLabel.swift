// Hand-written. A check with no drawn label, from Checkbox's contract (`accessibility.hiddenLabel`,
// spec/components/checkbox/checkbox.spec.yaml) and its decisions/0002: an initializer of the system Toggle that takes no
// label view and requires the accessible name, for a row whose title is a separate text. The API parity lint holds it
// to the contract (spec/conventions.md, "A label that is not drawn"; AppleComponents.HiddenLabel).
//
// The label is an `EmptyView` that carries the name. `CheckboxVariantStyle` lays the label out beside the circle, and an
// `EmptyView` takes no place there and no gap, so the check is its hit area alone; the system Toggle of the style's
// accessibility representation takes its name from the same label. Measured on iOS 17.5 and 26.3: a switch named by
// the given name, with its value, 44 pt square, nothing drawn beside the circle (decisions/0002). `.labelsHidden()`
// does the same only from iOS 18, macOS 15 and watchOS 11, where a custom style can see it.

import SwiftUI

extension Toggle where Label == ModifiedContent<EmptyView, AccessibilityAttachmentModifier> {
    /// A toggle that draws no label, named for assistive technology by a localized name, as a check beside a separate
    /// title is:
    ///
    ///     HStack {
    ///         Toggle(isOn: $task.isDone, accessibilityLabel: "Buy milk").toggleStyle(.check)
    ///         Text("Buy milk").accessibilityHidden(true)
    ///     }
    ///
    /// The separate title is hidden from assistive technology, so the name is read once. The same on every OS, unlike
    /// `.labelsHidden()`, which a custom style sees only from iOS 18, macOS 15 and watchOS 11. The name is a required
    /// argument; an empty string still compiles and gives a toggle with no name, as `Toggle("", isOn:)` does.
    ///
    /// - Parameters:
    ///   - isOn: Whether the toggle is on.
    ///   - accessibilityLabel: The name assistive technology reads, a task's title; it is never drawn.
    public init(isOn: Binding<Bool>, accessibilityLabel: LocalizedStringKey) {
        self.init(isOn: isOn) {
            EmptyView().accessibilityLabel(Text(accessibilityLabel))
        }
    }

    /// A toggle that draws no label, named for assistive technology by a name that is not localized, such as a title
    /// the person gave: `Toggle(isOn: $task.isDone, accessibilityLabel: task.title).toggleStyle(.check)`.
    ///
    /// - Parameters:
    ///   - isOn: Whether the toggle is on.
    ///   - accessibilityLabel: The name assistive technology reads; it is never drawn.
    @_disfavoredOverload
    public init<S: StringProtocol>(isOn: Binding<Bool>, accessibilityLabel: S) {
        self.init(isOn: isOn) {
            EmptyView().accessibilityLabel(Text(accessibilityLabel))
        }
    }
}
