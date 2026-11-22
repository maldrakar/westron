// Hand-written. ListRow's mark `insertion` (spec/components/list-row/list-row.spec.yaml, `marks`): where a dragged row
// would land beside this one. The modifier's signature follows spec/conventions.md, "Marks"; the API parity lint holds
// it to the contract, and its enum is generated (Generated/ListRow+Contract.swift).

import SwiftUI

extension View {
    /// Marks where a dragged row would land beside this ListRow: `Rule(purpose: .insertion)` over its top or bottom
    /// edge, from the leading edge of `level`'s leading slot to the row's trailing padding. No gap opens. nil draws no
    /// mark. The product follows its drag: `.insertionMark(drag.edge(for: row), level: drag.level)`. The mark does not
    /// travel: moved to another edge or level, the old mark fades out and the new one in. It is drawn above the rows
    /// beside it in one stack, and it is not announced: the drag's other way is the product's (decisions/0001, Q4). In a
    /// `List`, where each row is a cell of its own, mark one row on iOS and both rows beside the place on macOS, whose
    /// cells clip each mark to its own row's half (the contract's `platforms`). watchOS has no drag and drop, so there
    /// the modifier draws nothing.
    ///
    /// - Parameters:
    ///   - edge: The edge of the row the mark is drawn over; nil for none.
    ///   - level: The level the dropped row would take, which may differ from this row's; by default 0.
    public func insertionMark(_ edge: ListRowInsertionEdge?, level: Int = 0) -> some View {
        modifier(ListRowInsertionMark(edge: edge, level: max(0, level)))
    }
}

private struct ListRowInsertionMark: ViewModifier {
    let edge: ListRowInsertionEdge?
    let level: Int

    func body(content: Content) -> some View {
        #if os(watchOS)
            content
        #else
            content
                .overlay(alignment: .top) { ListRowSpacingReader { mark(.top, spacing: $0) } }
                .overlay(alignment: .bottom) { ListRowSpacingReader { mark(.bottom, spacing: $0) } }
                // Above the next row, whose highlight would otherwise cover the half of a bottom mark that stands on it.
                .zIndex(edge == nil ? 0 : 1)
        #endif
    }

    /// The mark over one edge, in a place of its own: shown while the mark is on this edge, under the level's slot
    /// start, and faded in and out by its edge and level, never moved.
    private func mark(_ place: ListRowInsertionEdge, spacing: ListRowSpacing) -> some View {
        ZStack {
            if edge == place {
                Rule(purpose: .insertion)
                    .listRowProbed("mark")
                    .padding(
                        .leading,
                        ListRowMetrics.slotStart(level: level, indent: spacing.indent, padding: spacing.padding)
                    )
                    .padding(.trailing, spacing.padding)
                    .id(level)
                    .transition(.opacity)
            }
        }
        // Centred on the edge: half over the row, half over its neighbor.
        .alignmentGuide(place == .bottom ? .bottom : .top) { dimensions in
            dimensions[VerticalAlignment.center]
        }
        .animation(ListRowMotion.mark, value: edge == place ? level : -1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
