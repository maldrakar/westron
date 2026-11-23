import SwiftUI
import WestronUI

// Button's floating look (#121, decisions/0015 at the repository's root), over a busy ground: the `button-floating`
// entry, its live buttons for ButtonBehaviorTests, and two supplementary sheets of the snapshot matrix, one on the
// system's glass and one in the look before OS 26, which the catalog forces on a newer OS
// (`drawingButtonsWithoutGlass()`). The generated sheets draw floating buttons on the plain canvas, where glass shows
// little; these draw them over content, where it is used.

extension CatalogEntry {
    static let buttonFloating = CatalogEntry(
        id: "button-floating", title: "Button: floating, over content", section: .components
    ) {
        ButtonFloatingPage()
    }
}

/// Accessibility identifiers of the floating samples. The ones that stand on the system's glass start with
/// `glassPrefix`: the accessibility audit matches them by it (CatalogAccessibilityAuditTests).
enum ButtonFloatingID {
    /// The start of the identifier of every sample that stands on glass.
    static let glassPrefix = "button.floating.glass."
    /// The start of the identifier of every sample drawn as before OS 26.
    static let surfacePrefix = "button.floating.surface."
    /// The live buttons: a floating secondary "Back" and "More", icon-only, on glass; a floating primary "Add",
    /// icon-only; a disabled floating secondary "Share", icon-only, on glass.
    static let back = glassPrefix + "live.back"
    static let more = glassPrefix + "live.more"
    static let add = "button.floating.live.add"
    static let disabled = glassPrefix + "live.disabled"
    /// The text with the number of accepted presses: "Accepted presses: 3".
    static let count = "button.floating.live.count"
}

/// A fixed busy ground for floating buttons: diagonal stripes in four list colors' fills, which follow the theme. No
/// images and no randomness, so a capture is the same each time. Decorative.
struct FloatingGround: View {
    var body: some View {
        Canvas { context, size in
            let colors: [Westron.Color] = [
                Westron.Category.orange.fill, Westron.Category.blue.fill, Westron.Category.green.fill,
                Westron.Category.violet.fill,
            ]
            let width = CGFloat.space150
            var x = -size.height
            var index = 0
            while x < size.width {
                var stripe = Path()
                stripe.move(to: CGPoint(x: x, y: size.height))
                stripe.addLine(to: CGPoint(x: x + size.height, y: 0))
                stripe.addLine(to: CGPoint(x: x + size.height + width, y: 0))
                stripe.addLine(to: CGPoint(x: x + width, y: size.height))
                stripe.closeSubpath()
                context.fill(stripe, with: .color(Color(colors[index % colors.count])))
                x += width
                index += 1
            }
        }
        .accessibilityHidden(true)
    }
}

/// Its content padded on the busy ground, in a card's corners.
private struct FloatingPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.space200)
            .background { FloatingGround() }
            .clipShape(RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
    }
}

/// One cell of Button's floating supplements: the matrix's cell over the busy ground, on glass or as before OS 26.
struct ButtonFloatingCell: View {
    let values: ButtonMatrixValues
    let withoutGlass: Bool

    var body: some View {
        FloatingPanel {
            ButtonMatrixCell(values)
                .drawingButtonsWithoutGlass(withoutGlass)
        }
    }
}

extension ComponentMatrix.Supplement {
    /// Floating buttons over content, on the system's glass where the OS has it (#121).
    static let buttonFloatingOverContent = ComponentMatrix.Supplement(
        component: "button", id: "floating-over-content", title: "floating, over content",
        note: "What a floating button stands over is not a contract option: here a fixed busy ground of four list "
            + "colors' stripes, at size m. A floating secondary stands on the system's glass, regular and "
            + "interactive, with no fill, outline, shadow or press scale of westron's; pressed and hover are the "
            + "glass's own response to a touch or a pointer, which a forced state does not show. A floating primary "
            + "keeps its fill and casts shadow.overlay (decisions/0015).",
        keeps: ["floating": "true", "size": "m"], rowsPerPicture: 3, splitsAtEverySize: true
    ) { ButtonFloatingCell(values: ButtonMatrixValues($0), withoutGlass: false) }

    /// The same, drawn as an OS before 26 draws it, which the catalog forces on a newer one (#121).
    static let buttonFloatingBeforeGlass = ComponentMatrix.Supplement(
        component: "button", id: "floating-before-26", title: "floating, before OS 26",
        note: "The OS is not a contract option: the catalog forces the look of iOS 17 to 18, macOS 14 to 15 and "
            + "watchOS 10 to 11, where there is no glass, on a newer OS. A floating secondary stands on "
            + "background.surface with shadow.overlay, tinted hover and pressed as a row is, and in the high-contrast "
            + "themes outlined as every secondary is. A floating primary is the same as on glass (decisions/0015).",
        keeps: ["floating": "true", "size": "m"], rowsPerPicture: 3, splitsAtEverySize: true
    ) { ButtonFloatingCell(values: ButtonMatrixValues($0), withoutGlass: true) }
}

/// Floating buttons over a busy ground: live ones, each state, the destructive role, a group in the system's
/// `GlassEffectContainer` as a product writes it, and the look before OS 26.
private struct ButtonFloatingPage: View {
    @State private var accepted = 0

    /// A row of the states: the states it forces or sets.
    private struct Row: Hashable {
        let name: String
        let states: Set<ButtonCatalogState>

        static var all: [Row] {
            [Row(name: "rest", states: [])]
                + ButtonCatalogState.all.filter(\.isEntered).map { Row(name: $0.name, states: [$0]) }
        }
    }

    var body: some View {
        TokenPage(
            title: "Button · floating",
            summary: "A floating button stands over content, outside any bar. Secondary: the system's glass from OS "
                + "26, with nothing of westron's on it; before OS 26 an opaque raised surface. Primary: its fill and "
                + "shadow.overlay. Tertiary does not float. Hover, pressed and focus are forced; on glass the glass "
                + "answers a real touch or pointer itself."
        ) {
            section("Live") {
                Text("Accepted presses: \(accepted)")
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                    .accessibilityIdentifier(ButtonFloatingID.count)
                FloatingPanel {
                    HStack(spacing: .space200) {
                        live("Back", icon: .chevronLeft, variant: .secondary, id: ButtonFloatingID.back)
                        live("More", icon: .ellipsis, variant: .secondary, id: ButtonFloatingID.more)
                        live("Share", icon: .expand, variant: .secondary, id: ButtonFloatingID.disabled)
                            .disabled(true)
                        Spacer(minLength: 0)
                        live("Add", icon: .plus, variant: .primary, id: ButtonFloatingID.add)
                    }
                }
            }
            section("States, on glass from OS 26") { states(withoutGlass: false) }
            section("A group: the system's GlassEffectContainer") {
                FloatingPanel { group }
            }
            section("Before OS 26: forced on this OS") { states(withoutGlass: true) }
        }
    }

    /// A live floating button, icon-only, that counts accepted presses.
    private func live(_ title: LocalizedStringKey, icon: Westron.Icon, variant: ButtonVariant, id: String)
        -> some View
    {
        Button {
            accepted += 1
        } label: {
            Label(title, icon: icon)
        }
        .buttonStyle(variant, iconOnly: true, floating: true)
        .accessibilityIdentifier(id)
    }

    /// Every state, each row a panel with a secondary icon-only, a secondary with a label, a destructive secondary and
    /// a primary icon-only.
    private func states(withoutGlass: Bool) -> some View {
        let prefix = withoutGlass ? ButtonFloatingID.surfacePrefix : ButtonFloatingID.glassPrefix
        return VStack(alignment: .leading, spacing: .space100) {
            ForEach(Row.all, id: \.self) { row in
                TokenDetail(row.name)
                FloatingPanel {
                    FlowLayout(spacing: .space200) {
                        sample("Back", icon: .chevronLeft, variant: .secondary, iconOnly: true)
                            .accessibilityIdentifier(prefix + row.name + ".back")
                        sample("Edit", icon: .pen, variant: .secondary)
                            .accessibilityIdentifier(prefix + row.name + ".edit")
                        sample("Delete", icon: .trash, variant: .secondary, role: .destructive)
                            .accessibilityIdentifier(prefix + row.name + ".delete")
                        sample("Add", icon: .plus, variant: .primary, iconOnly: true)
                            .accessibilityIdentifier("button.floating.primary." + row.name + ".add")
                    }
                }
                .forcingButtonStates(row.states.filter(\.isForced))
                .disabled(row.states.contains(where: \.isDisabled))
                .loading(row.states.contains(where: \.isLoading))
                .drawingButtonsWithoutGlass(withoutGlass)
            }
        }
    }

    private func sample(
        _ title: LocalizedStringKey, icon: Westron.Icon, variant: ButtonVariant, iconOnly: Bool = false,
        role: ButtonRole? = nil
    ) -> some View {
        Button(role: role) {
        } label: {
            Label(title, icon: icon)
        }
        .buttonStyle(variant, iconOnly: iconOnly, floating: true)
    }

    /// Two floating buttons that share one piece of glass, as a product writes them: the system's container, from OS
    /// 26; before it, two buttons side by side.
    @ViewBuilder private var group: some View {
        let pair = HStack(spacing: .space100) {
            sample("Back", icon: .chevronLeft, variant: .secondary, iconOnly: true)
                .accessibilityIdentifier(ButtonFloatingID.glassPrefix + "group.back")
            sample("More", icon: .ellipsis, variant: .secondary, iconOnly: true)
                .accessibilityIdentifier(ButtonFloatingID.glassPrefix + "group.more")
        }
        if #available(iOS 26, macOS 26, watchOS 26, *) {
            GlassEffectContainer(spacing: .space100) { pair }
        } else {
            pair
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}
