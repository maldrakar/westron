import SwiftUI

/// Views in a row on their first text baselines, each at its ideal size, where the width holds them all; one under
/// another otherwise, each offered the width: what a `ViewThatFits(in: .horizontal)` of an `HStack` and a `VStack`
/// shows, with the same views in both arrangements.
///
/// A `ViewThatFits` draws a branch's own views, and when the accessibility audit (#25) enlarges the text so that the
/// row no longer fits, the column's views take its place: the audit loses track of the row's text and reports it as
/// not following Dynamic Type, though it does (`typography-in-text`, 2026-11-19). A page that shows the same views side
/// by side or stacked uses this layout instead; a `ViewThatFits` whose branches hold different views stays one.
struct SideBySideOrStacked: Layout {
    /// Between the views in a row.
    let spacing: CGFloat
    /// Between the views in a column.
    var stackedSpacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let ideal = subviews.map { $0.dimensions(in: .unspecified) }
        if fitsInRow(ideal, width: proposal.width) {
            let ascent = ideal.map { $0[.firstTextBaseline] }.max() ?? 0
            let descent = ideal.map { $0.height - $0[.firstTextBaseline] }.max() ?? 0
            return CGSize(width: rowWidth(ideal), height: ascent + descent)
        }
        let sizes = subviews.map { $0.sizeThatFits(Self.stacked(proposal)) }
        let height = sizes.map(\.height).reduce(0, +) + stackedSpacing * CGFloat(max(sizes.count - 1, 0))
        return CGSize(width: sizes.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let ideal = subviews.map { $0.dimensions(in: .unspecified) }
        if fitsInRow(ideal, width: proposal.width) {
            let ascent = ideal.map { $0[.firstTextBaseline] }.max() ?? 0
            var x = bounds.minX
            for (subview, size) in zip(subviews, ideal) {
                let y = bounds.minY + ascent - size[.firstTextBaseline]
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
                x += size.width + spacing
            }
        } else {
            var y = bounds.minY
            for subview in subviews {
                subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: Self.stacked(proposal))
                y += subview.sizeThatFits(Self.stacked(proposal)).height + stackedSpacing
            }
        }
    }

    /// Whether the row fits the width; with no width, or an infinite one, the ideal size, the row.
    private func fitsInRow(_ sizes: [ViewDimensions], width: CGFloat?) -> Bool {
        guard let width, width.isFinite else { return true }
        return rowWidth(sizes) <= width
    }

    private func rowWidth(_ sizes: [ViewDimensions]) -> CGFloat {
        sizes.map(\.width).reduce(0, +) + spacing * CGFloat(max(sizes.count - 1, 0))
    }

    /// What a view in the column is offered, as a `VStack` offers it: the width, and its own height.
    private static func stacked(_ proposal: ProposedViewSize) -> ProposedViewSize {
        ProposedViewSize(width: proposal.width, height: nil)
    }
}
