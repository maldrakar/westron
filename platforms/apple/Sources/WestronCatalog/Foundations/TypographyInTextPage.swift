import SwiftUI
import WestronUI

extension CatalogEntry {
    /// A role two ways side by side: the View modifier, which reads the environment, and its `Text` twin inside
    /// interpolation, which cannot (spec/components/text, P2). At accessibility5 and with Bold Text on
    /// (`-WestronLegibilityWeight bold`) they show what the twin does not follow.
    static let typographyInText = CatalogEntry(
        id: "typography-in-text", title: "Text roles in a Text", section: .foundations
    ) {
        TypographyInTextPage()
    }
}

private struct TypographyInTextPage: View {
    /// The roles in Onest or Geist Mono, where the two can differ, and a role in the system font, where they cannot.
    static let roles: [Westron.TextRole] = [
        .heading.large, .heading.medium, .heading.small, .heading.overline, .code.regular, .code.strong, .body.strong,
    ]

    var body: some View {
        TokenPage(
            title: "Text roles in a Text",
            summary: "Left or above, .textRole(_:) on the view: the tracking is a share of the drawn size, and Onest "
                + "and Geist Mono move a weight up under Bold Text. Right or below, Text.textRole(_:) inside a Text: "
                + "the size follows, the tracking is the default size's, the weight the role's own."
        ) {
            VStack(alignment: .leading, spacing: .space150) {
                ForEach(Self.roles, id: \.name) { role in
                    RoleComparison(role: role)
                }
            }
        }
    }
}

/// One role drawn both ways, with the width each takes: the same text in the same font differs in width only by its
/// tracking, or by its face under Bold Text.
private struct RoleComparison: View {
    let role: Westron.TextRole
    @State private var viewWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SideBySideOrStacked(spacing: .space300) {
                modifierSample
                twinSample
            }
            TokenDetail(detail)
        }
    }

    private var sample: String {
        role.name == Westron.TextRole.heading.overline.name ? "ЗАДАЧИ" : "Задачи"
    }

    /// The View modifier.
    private var modifierSample: some View {
        Text(sample)
            .textRole(role)
            .foregroundStyle(.text.primary)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { viewWidth = $0 })
    }

    /// The `Text` twin inside interpolation, where only a `Text` fits. The role is a variable, so the part is typed as
    /// `Text` first: interpolated directly, it would take the View modifier and print a debug description.
    private var twinSample: some View {
        let part: Text = Text(sample).textRole(role)
        return Text("\(part)")
            .foregroundStyle(.text.primary)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { textWidth = $0 })
    }

    /// `heading.large · view 98.5 pt · in a Text 98.5 pt`.
    private var detail: String {
        let name = role.name.split(separator: ".").dropFirst().joined(separator: ".")
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1))
        let view = Double(viewWidth).formatted(format)
        let text = Double(textWidth).formatted(format)
        return "\(name) · view \(view) pt · in a Text \(text) pt"
    }
}
