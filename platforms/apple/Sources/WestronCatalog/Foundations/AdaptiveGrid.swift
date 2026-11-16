import SwiftUI

/// The layout of `LazyVGrid` with one adaptive `GridItem` aligned to the top, laid out eagerly: as many columns of
/// equal width as fit, each at least `minimum` wide; a cell's view is centered in its column, at the top of its row.
///
/// A sample page has a few dozen cells, so laziness gains nothing, and it costs the accessibility audit (#25): when
/// the audit changes the text size, a lazy grid makes its cells again, and the audit reports every text in them as not
/// following Dynamic Type.
struct AdaptiveGrid: Layout {
    let minimum: CGFloat
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? naturalWidth(subviews.count)
        let rows = rows(subviews, width: width)
        let height = rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let columns = columns(bounds.width)
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            for (column, index) in row.indices.enumerated() {
                let size = row.sizes[column]
                let x = bounds.minX + CGFloat(column) * (columns.width + spacing) + (columns.width - size.width) / 2
                subviews[index].place(
                    at: CGPoint(x: x, y: y), anchor: .topLeading,
                    proposal: ProposedViewSize(width: columns.width, height: size.height))
            }
            y += row.height + rowSpacing
        }
    }

    /// The number of columns that fit the width and the width of each.
    private func columns(_ width: CGFloat) -> (count: Int, width: CGFloat) {
        let count = max(1, Int((width + spacing) / (minimum + spacing)))
        return (count, (width - spacing * CGFloat(count - 1)) / CGFloat(count))
    }

    /// Without a proposed width, one row of the narrowest columns.
    private func naturalWidth(_ count: Int) -> CGFloat {
        minimum * CGFloat(count) + spacing * CGFloat(max(count - 1, 0))
    }

    private struct Row {
        var indices: [Int] = []
        var sizes: [CGSize] = []
        var height: CGFloat = 0
    }

    private func rows(_ subviews: Subviews, width: CGFloat) -> [Row] {
        let columns = columns(width)
        var rows: [Row] = []
        for index in subviews.indices {
            if index % columns.count == 0 { rows.append(Row()) }
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: columns.width, height: nil))
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].sizes.append(size)
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}
