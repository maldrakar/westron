import SwiftUI
import WestronUI

// Icon's catalog entry, from spec/components/icon/icon.spec.yaml: the real `Icon` at the system's three scales, beside
// text in a system-font role, a heading role and a code role, in the color roles chapter 07 lists, and decorative
// against labeled. Every glyph of the registry is on the icons page and in the snapshot matrix; the page takes a few.

extension CatalogEntry {
    static let icon = CatalogEntry(id: "icon", title: "Icon", section: .components) {
        IconPage()
    }
}

extension Image.Scale {
    /// The system scale a contract value of `scale` names: the contract's values are `Image.Scale`'s cases.
    init(contract value: String) {
        switch value {
        case "small": self = .small
        case "medium": self = .medium
        case "large": self = .large
        default: preconditionFailure("no Image.Scale for the contract's scale \(value)")
        }
    }
}

/// The roles an icon is shown beside: a system-font role, a heading in Onest and code in Geist Mono, whose weights
/// the symbol takes at rest and, under Bold Text, steps past (the contract's `platforms.apple`).
enum IconSampleRoles {
    static let all: [(name: String, role: Westron.TextRole, word: String)] = [
        ("body.regular", .body.regular, "Aa"),
        ("body.strong", .body.strong, "Aa"),
        ("heading.large", .heading.large, "Aa"),
        ("code.regular", .code.regular, "Aa"),
    ]

    /// The color roles `IconColorRoles` draws, in its order.
    static let colorNames = ["text.primary", "status.success.icon", "category.teal.icon", "icon.tertiary", "on-accent"]
}

/// An icon beside a word in a role, both taking it from their row, as a product sets them.
struct IconBesideText: View {
    let icon: Westron.Icon
    let role: Westron.TextRole
    let word: String

    var body: some View {
        HStack(spacing: .space50) {
            Icon(icon)
            Text(word)
        }
        .textRole(role)
        .foregroundStyle(.text.primary)
        // The word stays on the icon's line: wrapped, it would no longer show the two side by side.
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// The icon in each color role of design-language/07 ("One color"), with the role's name.
struct IconColorRoles: View {
    let icon: Westron.Icon

    var body: some View {
        // Two lines, so that the five fit a third of an iPhone at the large scale.
        VStack(alignment: .leading, spacing: .space50) {
            HStack(spacing: .space75) {
                Icon(icon).foregroundStyle(.text.primary)
                Icon(icon).foregroundStyle(.status.success.icon)
                Icon(icon).foregroundStyle(Westron.Category.teal.icon)
            }
            HStack(spacing: .space75) {
                Icon(icon).foregroundStyle(.icon.tertiary)
                Icon(icon)
                    .foregroundStyle(.text.onAccent)
                    .padding(.space25)
                    .background(.background.accent, in: RoundedRectangle(cornerRadius: .radius100))
            }
        }
        .textRole(.body.regular)
    }
}

/// One cell of Icon's snapshot matrix (#24): a glyph at a scale, in body text's role and color.
struct IconMatrixCell: View {
    let values: IconMatrixValues

    init(_ values: IconMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here. The
        // contract has no states, so the state is always rest.
        let (glyph, scale, _) = values.fields
        Icon(glyph)
            .imageScale(Image.Scale(contract: scale))
            .textRole(.body.regular)
            .foregroundStyle(.text.primary)
            // The icon is decorative and hidden; one element marks the cell for the sheet's count.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: glyph.rawValue))
    }
}

extension ComponentMatrix.Supplement {
    /// Six glyphs of the registry, the pilot's: a supplement draws them, not every glyph again.
    static let iconSampleGlyphs = ["tray", "sun", "pen", "check", "chevron", "flag"]
    /// Three of them beside text, whose four roles make a tall cell.
    static let iconBesideTextGlyphs = ["tray", "check", "chevron"]

    static let iconBesideText = ComponentMatrix.Supplement(
        component: "icon", id: "beside-text", title: "beside text",
        note:
            "The role is not a contract option: the icon takes the font of its text. Each cell, top down: body.regular, "
            + "body.strong, heading.large (Onest), code.regular (Geist Mono). Bold Text: the icon entry.",
        keeps: [:], rows: iconBesideTextGlyphs, rowsPerPicture: 1
    ) {
        let (glyph, scale, _) = IconMatrixValues($0).fields
        VStack(alignment: .leading, spacing: .space25) {
            ForEach(IconSampleRoles.all, id: \.name) { item in
                IconBesideText(icon: glyph, role: item.role, word: "Aa")
            }
        }
        .imageScale(Image.Scale(contract: scale))
        .accessibilityElement(children: .contain)
    }

    static let iconColorRoles = ComponentMatrix.Supplement(
        component: "icon", id: "color-roles", title: "color roles",
        note: "The color is not a contract option: the icon takes its context's foregroundStyle. Each cell: "
            + IconSampleRoles.colorNames.joined(separator: ", ") + " on background.accent (design-language/07).",
        keeps: [:], rows: iconSampleGlyphs, rowsPerPicture: 3
    ) {
        let (glyph, scale, _) = IconMatrixValues($0).fields
        IconColorRoles(icon: glyph)
            .imageScale(Image.Scale(contract: scale))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: glyph.rawValue))
    }
}

/// The scales, the roles, the color roles, and decorative against labeled.
private struct IconPage: View {
    private static let glyphs: [Westron.Icon] = [.tray, .sun, .pen, .check, .chevron, .flag]

    var body: some View {
        TokenPage(
            title: "Icon",
            summary: "Icon(.tray) draws the SF Symbol in the font and the color of its context, hidden from assistive "
                + "technology; Icon(.sun, label: \"Today\") is an image labeled Today. .imageScale(_:) sets the "
                + "system's scale. Every glyph is on the icons page."
        ) {
            VStack(alignment: .leading, spacing: .space.betweenGroups) {
                section("scale: small, medium, large, in body.regular") {
                    ForEach(ComponentMatrix.icon.options[1].values, id: \.self) { scale in
                        HStack(spacing: .space100) {
                            ForEach(Self.glyphs, id: \.self) { Icon($0) }
                        }
                        .imageScale(Image.Scale(contract: scale))
                        .textRole(.body.regular)
                        .foregroundStyle(.text.primary)
                    }
                }
                section("beside text: size and weight from the role") {
                    ForEach(IconSampleRoles.all, id: \.name) { item in
                        HStack(spacing: .space150) {
                            IconBesideText(icon: .tray, role: item.role, word: item.word)
                            IconBesideText(icon: .check, role: item.role, word: item.word)
                            TokenDetail(item.name.replacingOccurrences(of: ".", with: " "))
                        }
                    }
                }
                section("color roles: " + IconSampleRoles.colorNames.joined(separator: ", ")) {
                    IconColorRoles(icon: .flag)
                }
                section("decorative and labeled") {
                    HStack(spacing: .space150) {
                        Icon(.sun)
                        TokenDetail("Icon(.sun): hidden")
                    }
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                    HStack(spacing: .space150) {
                        Icon(.sun, label: "Today")
                            .accessibilityIdentifier(IconPageID.labeled)
                        TokenDetail("Icon(.sun, label: \"Today\"): an image, Today")
                    }
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                    HStack(spacing: .space150) {
                        Label("Rename", icon: .pen)
                            .accessibilityIdentifier(IconPageID.label)
                        TokenDetail("Label: as the system reads it")
                    }
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                }
                section("in a menu: Label(_:icon:), and a Label with Icon") {
                    // A system menu builds its items from the labels: IconAccessibilityTests opens it and reads
                    // what each item is (decisions/0001, "The Apple view").
                    Menu {
                        Button {
                        } label: {
                            Label("Rename", icon: .pen)
                        }
                        Button(role: .destructive) {
                        } label: {
                            Label {
                                Text("Delete")
                            } icon: {
                                Icon(.trash)
                            }
                        }
                    } label: {
                        Text("Actions")
                            .textRole(.body.regular)
                    }
                    .accessibilityIdentifier(IconPageID.menu)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .space75) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }
}

/// Identifiers of the icon page's samples, which the catalog's UI tests read.
enum IconPageID {
    static let labeled = "westron.catalog.icon.labeled"
    static let label = "westron.catalog.icon.label"
    static let menu = "westron.catalog.icon.menu"
}
