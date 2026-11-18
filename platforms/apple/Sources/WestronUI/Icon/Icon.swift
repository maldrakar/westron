// Hand-written. Icon from its contract, spec/components/icon/icon.spec.yaml: an icon of westron's registry drawn as
// its SF Symbol. It is an own component in the form of a view (`platforms.apple.form`), not an initializer of
// SwiftUI's `Image`: an `Image` of a symbol always carries the system's spoken name of the symbol, and SwiftUI has no
// way to hide or rename it that keeps the value an `Image` (spec/components/icon, decisions/0001, "The Apple view").
// The API parity lint holds `Icon` and its initializers to the contract (spec/conventions.md, "Own components"). The
// glyph's type, `Westron.Icon`, is generated from spec/icons/icons.yaml; `scale` is the system's `.imageScale(_:)`.

import SwiftUI

/// An icon of westron's registry, as its SF Symbol (decisions/0011). It takes the font of its context, so next to text
/// it gets the text's size and weight and grows with Dynamic Type, and the context's foreground style, its color;
/// `.imageScale(_:)` makes it smaller or larger than the text (design-language/07):
///
///     Label { Text(list.title) } icon: { Icon(.folder) }
///     Icon(.chevron).foregroundStyle(.icon.tertiary).imageScale(.small)
///     Icon(.sun, label: "Today")
///
/// Without a label it is decorative and hidden from assistive technology: beside its own words it would only repeat
/// them, and the system's name for a symbol says what it draws ("Increase Brightness" for the sun), not what it means
/// here. A standalone icon that means something takes a label, and is announced as an image with it. An icon-only
/// control is labeled by the control, not by its icon. Where only an `Image` fits, as inside `Text` interpolation,
/// `Image(_: Westron.Icon)` draws the same glyph, with the system's spoken name.
public struct Icon: View {
    let icon: Westron.Icon
    /// The spoken label; nil for a decorative icon.
    let label: Text?

    /// A decorative icon, hidden from assistive technology: `Icon(.tray)`.
    ///
    /// - Parameter icon: The glyph; a stored name reads as `Westron.Icon(rawValue: name) ?? .fallback`.
    public init(_ icon: Westron.Icon) {
        self.icon = icon
        label = nil
    }

    /// A meaningful icon, announced as an image with a localized label that says what it means here:
    /// `Icon(.sun, label: "Today")`.
    public init(_ icon: Westron.Icon, label: LocalizedStringKey) {
        self.icon = icon
        self.label = Text(label)
    }

    /// A meaningful icon with a label that is not localized, such as a name the person gave:
    /// `Icon(.folder, label: list.title)`.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ icon: Westron.Icon, label: S) {
        self.icon = icon
        self.label = Text(label)
    }

    public var body: some View {
        Image(icon)
            .accessibilityLabel(label ?? Text(verbatim: ""))
            .accessibilityHidden(label == nil)
    }
}
