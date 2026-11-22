// Hand-written. ListRow's mark `insertion` (spec/components/list-row/list-row.spec.yaml, `marks`): where a dragged row
// would land beside this one. The modifier's signature follows spec/conventions.md, "Marks"; the API parity lint holds
// it to the contract, and its enum is generated (Generated/ListRow+Contract.swift).

import SwiftUI

extension View {
    /// Marks where a dragged row would land beside this ListRow: `Rule(purpose: .insertion)` over its top or bottom
    /// edge, from the leading edge of `level`'s leading slot to the row's trailing padding. No gap opens. nil draws no
    /// mark. The product follows its drag: `.insertionMark(drag.edge(for: row), level: drag.level)`. The mark moves to
    /// another edge or level with a fade, and it is not announced: the drag's other way is the product's
    /// (decisions/0001, Q4).
    ///
    /// - Parameters:
    ///   - edge: The edge of the row the mark is drawn over; nil for none.
    ///   - level: The level the dropped row would take, which may differ from this row's; by default 0.
    public func insertionMark(_ edge: ListRowInsertionEdge?, level: Int = 0) -> some View {
        modifier(ListRowInsertionMark(edge: edge, level: level))
    }
}

private struct ListRowInsertionMark: ViewModifier {
    let edge: ListRowInsertionEdge?
    let level: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var indent = CGFloat(ListRowMetrics.indent)
    @ScaledMetric(relativeTo: ListRowMetrics.textStyle) private var padding = CGFloat(
        ListRowMetrics.paddingHorizontal)

    func body(content: Content) -> some View {
        let motion = ListRowMotion(reduceMotion: reduceMotion)
        return content.overlay(alignment: edge == .bottom ? .bottom : .top) {
            ZStack {
                if let edge {
                    Rule(purpose: .insertion)
                        .padding(.leading, ListRowMetrics.slotStart(level: level, indent: indent, padding: padding))
                        .padding(.trailing, padding)
                        .transition(.opacity)
                        .id(MarkPlace(edge: edge, level: level))
                }
            }
            // Centred on the edge: half over the row, half over its neighbor.
            .alignmentGuide(edge == .bottom ? .bottom : .top) { dimensions in
                dimensions[VerticalAlignment.center]
            }
            .animation(motion.mark, value: MarkPlace(edge: edge, level: level))
        }
    }

    /// Where the mark stands, so that a move to another edge or level fades the old mark out and the new one in.
    private struct MarkPlace: Hashable {
        let edge: ListRowInsertionEdge?
        let level: Int
    }
}
