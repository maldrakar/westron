import SwiftUI
import WestronUI

extension CatalogEntry {
    /// The text roles, each in its own font, with its token name and the text style it follows.
    static let typography = CatalogEntry(id: "typography", title: "Typography", section: .foundations) {
        TextRolesPage(
            title: "Text roles",
            summary: "typography.*: headings in Onest, body text in the system font, code in Geist Mono, each in a "
                + "text style, so the size follows Dynamic Type.",
            roles: Westron.TextRole.all
        ) { role in
            Text(role.sample)
                .textRole(role)
                .foregroundStyle(.text.primary)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

/// A sample of each text role with its token name, text style and font: the typography page, and Text's entry
/// (`Components/TextPages.swift`), which draws each sample with the cell of Text's snapshot matrix.
struct TextRolesPage<Sample: View>: View {
    let title: String
    let summary: String
    let roles: [Westron.TextRole]
    @ViewBuilder let sample: (Westron.TextRole) -> Sample

    var body: some View {
        TokenPage(title: title, summary: summary) {
            // A line per role where the window is wide enough, the sample above its name otherwise.
            ViewThatFits(in: .horizontal) {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: .space200, verticalSpacing: .space75) {
                    ForEach(roles, id: \.name) { role in
                        GridRow {
                            sample(role)
                            TokenDetail(role.detail)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: .space100) {
                    ForEach(roles, id: \.name) { role in
                        VStack(alignment: .leading, spacing: 0) {
                            sample(role)
                            TokenDetail(role.detail)
                        }
                    }
                }
            }
        }
    }
}

extension Westron.TextRole {
    /// `typography.heading.large · largeTitle · Onest-Bold`, or `… · default · regular` for the system font.
    var detail: String {
        let font = self.font ?? "\(design.rawValue) · \(weight)"
        return "\(name) · \(textStyle.rawValue) · \(font)"
    }

    /// The role's name as words, `typography.heading.large` → "Heading large", and a word in Cyrillic, which
    /// every font westron ships must have.
    var sample: String {
        let words = name.split(separator: ".").dropFirst().joined(separator: " ")
        return words.prefix(1).uppercased() + words.dropFirst() + " · Задачи"
    }
}
