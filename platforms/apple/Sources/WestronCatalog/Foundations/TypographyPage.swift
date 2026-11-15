import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The text roles, each in its own font, with its token name and the text style it follows.
    static let typography = CatalogEntry(id: "typography", title: "Typography", section: .foundations) {
        TypographyPage()
    }
}

private struct TypographyPage: View {
    var body: some View {
        TokenPage(
            title: "Text roles",
            summary: "typography.*: headings in Onest, body text in the system font, code in Geist Mono, each in a "
                + "text style, so the size follows Dynamic Type."
        ) {
            // A line per role where the window is wide enough, the sample above its name otherwise.
            ViewThatFits(in: .horizontal) {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: .space200, verticalSpacing: .space75) {
                    ForEach(Westron.TextRole.all, id: \.name) { role in
                        GridRow {
                            sample(role)
                            TokenDetail(Self.detail(role))
                        }
                    }
                }
                VStack(alignment: .leading, spacing: .space100) {
                    ForEach(Westron.TextRole.all, id: \.name) { role in
                        VStack(alignment: .leading, spacing: 0) {
                            sample(role)
                            TokenDetail(Self.detail(role))
                        }
                    }
                }
            }
        }
    }

    private func sample(_ role: Westron.TextRole) -> some View {
        Text(Self.sample(role))
            .textRole(role)
            .foregroundStyle(.textPrimary)
            .lineLimit(1)
            .fixedSize()
    }

    /// `typography.heading.large · largeTitle · Onest-Bold`, or `… · default · regular` for the system font.
    static func detail(_ role: Westron.TextRole) -> String {
        let font = role.font ?? "\(role.design.rawValue) · \(role.weight)"
        return "\(role.name) · \(role.textStyle.rawValue) · \(font)"
    }

    /// The role's name as words, `typography.heading.large` → "Heading large", and a word in Cyrillic, which
    /// every font westron ships must have.
    static func sample(_ role: Westron.TextRole) -> String {
        let words = role.name.split(separator: ".").dropFirst().joined(separator: " ")
        return words.prefix(1).uppercased() + words.dropFirst() + " · Задачи"
    }
}
