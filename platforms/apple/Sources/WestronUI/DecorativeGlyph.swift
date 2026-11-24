// Hand-written. A decorative glyph kept from assistive technology, which Chip and Button share (#131).

import SwiftUI

/// Hides a decorative glyph, such as a control's icon, its check or its progress indicator, from assistive technology:
/// on iOS and watchOS hidden, then represented by nothing; on macOS hidden alone.
///
/// Inside a button's label on iOS, `.accessibilityHidden(true)` alone left the glyph an element of its own under the
/// button: an image named after its symbol, the check with the trait selected, a progress indicator an activity
/// indicator (iOS 26.3, ButtonBehaviorTests' `testIconIsNoElement`, #131). The order of the two modifiers matters, as
/// measured there with the check in a Button's Label:
/// - hidden, then an empty representation (this one): nothing under the button, neither the glyph nor the label's
///   words, as under a button whose label is only text;
/// - an empty representation alone: the same;
/// - an empty representation, then hidden (Chip's before #131, and Disclosure's chevron): an element of type other with
///   no label, value or trait in the glyph's place, and the words as a text;
/// - `.accessibilityElement(children: .ignore)` and hidden: that empty element and the image both;
/// - hidden, with `.accessibilityRemoveTraits([.isImage, .isSelected])`: an element of type other named after the
///   symbol;
/// - hidden, with `.accessibilityElement(children: .combine)` around the label: the image, selected.
/// Outside a button, a Label in a label style that hides its icon so is read as its words alone.
///
/// On macOS 26.7 nothing is listed under a westron Button or Chip with the glyph hidden alone, hidden then represented
/// by nothing, or represented then hidden; but with the empty representation last, a loading Button's value is read
/// twice there, "Loading, Loading" (#131, ButtonBehaviorTests' `testLoadingButtonRefusesTouchAndPointerAndStaysEnabled`).
/// The cause is the progress indicator before the label, which the style's body lays out beside the button's label in
/// every loading button, with or without an icon: a progress view in it gave the button's value twice, a plain view in
/// its place once, and hidden alone, as Button's glyphs were before #131, or represented then hidden, once (read
/// in-process from the hosting view's NSAccessibility tree).
struct DecorativeGlyph: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
            content
                .accessibilityHidden(true)
        #else
            content
                .accessibilityHidden(true)
                .accessibilityRepresentation {
                    EmptyView()
                }
        #endif
    }
}
