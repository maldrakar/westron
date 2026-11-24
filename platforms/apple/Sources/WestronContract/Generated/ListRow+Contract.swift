// Generated from spec/components/list-row/list-row.spec.yaml by `tools/westron generate`. Do not edit: change the
// contract and generate again (spec/conventions.md).
//
// ListRow's vocabulary from its contract: the enums of its options and of its marks' parameters. WestronContract
// imports nothing, so that a product's shared code names them without SwiftUI; WestronUI re-exports it and adds the
// SwiftUI side (decisions/0017).

/// The parameter `edge` of ListRow's mark `insertion`, from its contract: `.insertionMark(…)`, hand-written in
/// WestronUI/ListRow/.
///
/// The edge of the row the mark is drawn over.
public enum ListRowInsertionEdge: String, CaseIterable, Sendable {
    case top
    case bottom
}
