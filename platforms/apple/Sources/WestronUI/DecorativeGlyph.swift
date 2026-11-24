// Hand-written. A decorative glyph kept from assistive technology, which Chip and Button share (#131).

import SwiftUI

/// Hides a decorative glyph, such as a control's icon, its check or its progress indicator, from assistive technology:
/// hidden, then represented by nothing.
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
struct DecorativeGlyph: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accessibilityHidden(true)
            .accessibilityRepresentation {
                EmptyView()
            }
    }
}
