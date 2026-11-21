import SwiftUI
import WestronUI

// Text's catalog entry, from spec/components/text/text.spec.yaml: the system's `Text` in every role of the contract,
// the tokens under typography, through `.textRole(_:)`. The roles come from the generated matrix, so the page follows
// the contract and the tokens. The page is the typography page's layout (`TextRolesPage`) with the matrix cell's
// sample: the typography page shows the roles as tokens, this one as a product sets them.

extension CatalogEntry {
    static let text = CatalogEntry(id: "text", title: "Text", section: .components) {
        TextPage()
    }
}

/// A text in a role, as a product sets it: the system's `Text` with `.textRole(_:)`, the color from a color role, and
/// running text that wraps where it does not fit (the contract's P1). The page and the matrix cells draw this.
struct TextRoleSample: View {
    let role: Westron.TextRole

    /// Short words in Latin and in Cyrillic, which every font westron ships must have. Each word is narrower than a
    /// column of a matrix sheet on an iPhone 17 in `heading.large`, so the text wraps between words and never inside
    /// one ("Heading" does not fit a third of the screen at 34 points). The column names the role.
    static let text = "Tasks · Дела"

    var body: some View {
        Text(Self.text)
            .textRole(role)
            .foregroundStyle(.text.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// One cell of Text's snapshot matrix (#24): a role, drawn as `TextRoleSample`.
struct TextMatrixCell: View {
    let values: TextMatrixValues

    init(_ values: TextMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here. The
        // contract has no states, so the state is always rest.
        let (role, _) = values.fields
        TextRoleSample(role: role)
            // Running text: it wraps between its words in the column it is given.
            .matrixCellTakesOfferedWidth()
    }
}

/// Every role of the contract, in the matrix's order, each drawn as the matrix's cell draws it, on the typography
/// page's layout.
private struct TextPage: View {
    var body: some View {
        TextRolesPage(
            title: "Text",
            summary: "Text(…).textRole(_:) in every role: the role sets the font and the tracking, the product the "
                + "color (here text.primary). Running text wraps.",
            roles: ComponentMatrix.text.combinations.map { TextMatrixValues($0).fields.role }
        ) { role in
            TextRoleSample(role: role)
        }
    }
}
