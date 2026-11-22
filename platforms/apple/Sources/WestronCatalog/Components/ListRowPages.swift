import SwiftUI
import WestronUI

// ListRow's catalog entries, from spec/components/list-row/list-row.spec.yaml: `list-row`, both forms in every state
// each enters (the contract's `forms`), a tree of levels with guides, the insertion mark and a drop target, the
// Disclosure chevron's cell with a stand-in, and a live sample; `list-row-in-list`, rows in a system List with swipe
// actions. The states come from the generated `ListRowState` through `ListRowCatalogState`, so the pages follow the
// contract.

extension View {
    /// Hides the List's separator under the row, where the system draws one: watchOS has no separators to hide.
    fileprivate func listRowSeparatorHidden() -> some View {
        #if os(watchOS)
            self
        #else
            listRowSeparator(.hidden)
        #endif
    }
}

extension CatalogEntry {
    static let listRow = CatalogEntry(id: "list-row", title: "ListRow", section: .components) {
        ListRowPage()
    }

    static let listRowInList = CatalogEntry(id: "list-row-in-list", title: "ListRow: in a List", section: .components) {
        ListRowListPage()
    }
}

/// Accessibility identifiers of the live rows, which the catalog's UI tests (ListRowBehaviorTests) press.
enum ListRowCatalogID {
    /// The check at the start of the live task's row.
    static let check = "list-row.live.check"
    /// The text that says which live row is selected, how often a row's action ran and whether the task is done:
    /// "selected: inbox; actions: 0; done: no".
    static let summary = "list-row.live.summary"
    /// The check at the start of the first row in the List.
    static let listCheck = "list-row.list.check"
    /// The List page's summary: "actions: 0; done: no; deleted: none".
    static let listSummary = "list-row.list.summary"
}

/// The sample words of the rows: a list's title and count, and a task's.
enum ListRowSample {
    static let title = "Inbox"
    static let subtitle = "Due today"
    static let count = "12"
    static let icon: Westron.Icon = .tray
    static let task = "Call the plumber"
    static let long = "A list whose name runs much longer than the room its row leaves"
    /// The width a long title is given, narrower than it: four of the widest space step.
    static let narrowWidth: CGFloat = 4 * .space800
}

/// A sample row: the tray, a title, a second line and a count, at `level`, with an action or without.
struct ListRowSampleRow: View {
    var form: ListRowForm = .pressable
    var level = 1
    var guides = true
    var title = ListRowSample.title
    var subtitle: String? = ListRowSample.subtitle

    var body: some View {
        switch form {
        case .pressable:
            ListRow(level: level, guides: guides, action: {}) {
                Text(verbatim: title)
            } subtitle: {
                if let subtitle { Text(verbatim: subtitle) }
            } leading: {
                Icon(ListRowSample.icon)
            } trailing: {
                count
            }
        case .static:
            ListRow(level: level, guides: guides) {
                Text(verbatim: title)
            } subtitle: {
                if let subtitle { Text(verbatim: subtitle) }
            } leading: {
                Icon(ListRowSample.icon)
            } trailing: {
                count
            }
        }
    }

    private var count: some View {
        Text(verbatim: ListRowSample.count)
            .textRole(.subheadline.regular)
            .foregroundStyle(.text.secondary)
    }
}

/// A tree of levels 0 to 3, with guides, the second row selected.
struct ListRowTree: View {
    var guides = true

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(["Work", "Projects", "Garden", "Seeds", "Home"].enumerated()), id: \.offset) { index, title in
                let level = [0, 1, 2, 3, 0][index]
                ListRow(level: level, guides: guides, action: {}) {
                    Text(verbatim: title)
                } leading: {
                    Icon(level == 0 ? .briefcase : .folder)
                } trailing: {
                    Text(verbatim: "\(index + 2)")
                        .textRole(.subheadline.regular)
                        .foregroundStyle(.text.secondary)
                }
                .selected(index == 1)
            }
        }
    }
}

/// The Disclosure chevron's cell, a stand-in until Disclosure exists (#120): a chevron in a frame
/// size.target.minimum across, its own button.
struct ListRowCellStandIn: View {
    var body: some View {
        Button {
        } label: {
            Icon(.chevron)
                .frame(minWidth: .size.target.minimum, minHeight: .size.target.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Collapse"))
    }
}

/// A leaf and a branch of a tree, the branch with the chevron's stand-in, the leaf with an empty frame of the cell's
/// width at the end of its trailing slot, so that the counts stand in one column.
struct ListRowCellColumn: View {
    var body: some View {
        VStack(spacing: 0) {
            ListRow(action: {}) {
                Text(verbatim: "Work")
            } leading: {
                Icon(.briefcase)
            } trailing: {
                Text(verbatim: "4").textRole(.subheadline.regular).foregroundStyle(.text.secondary)
            }
            .listRowDisclosureCell { ListRowCellStandIn() }
            ListRow(action: {}) {
                Text(verbatim: "Errands")
            } leading: {
                Icon(.bag)
            } trailing: {
                HStack(spacing: 0) {
                    Text(verbatim: "7").textRole(.subheadline.regular).foregroundStyle(.text.secondary)
                    // The leaf's empty cell: the chevron cell's width, after the trailing gap the row puts before it.
                    Color.clear.frame(width: .space100 + .size.target.minimum, height: 0)
                }
            }
        }
    }
}

/// Rows with the insertion mark over the top edge at level 0 and over the bottom edge at level 2, and a drop target.
struct ListRowDragSamples: View {
    var guides = true

    var body: some View {
        VStack(spacing: 0) {
            ListRowSampleRow(level: 0, guides: guides, subtitle: nil)
                .insertionMark(.top, level: 0)
            ListRowSampleRow(level: 1, guides: guides, title: "Garden", subtitle: nil)
                .insertionMark(.bottom, level: 2)
            ListRowSampleRow(level: 1, guides: guides, title: "Errands", subtitle: nil)
                .dropTarget(true)
        }
    }
}

private struct ListRowPage: View {
    @State private var chosen = "inbox"
    @State private var actions = 0
    @State private var done = false

    var body: some View {
        TokenPage(
            title: "ListRow",
            summary: "ListRow(level:guides:action:) { title } subtitle: leading: trailing:, an own view: a title, a "
                + "second line, a leading and a trailing slot, indented by space.300 per level with guides in "
                + "border.guide; a highlight at radius.row, hover, pressed, selected (body.strong, a ring in high "
                + "contrast) and a drop target (accent-subtle, an insertion ring). .selected(_:), .dropTarget(_:), "
                + ".insertionMark(_:level:)."
        ) {
            section("Pressable, in each state") {
                states(.pressable)
            }
            section("Static, in each state") {
                states(.static)
            }
            section("Levels and guides") {
                ListRowTree()
            }
            section("Drag and drop: the insertion mark and a drop target") {
                ListRowDragSamples()
            }
            section("The Disclosure chevron's cell, a stand-in, and a leaf's empty cell") {
                ListRowCellColumn()
            }
            section("A long title on one line, at level 4") {
                ListRow(level: 4, action: {}) {
                    Text(verbatim: ListRowSample.long).lineLimit(1)
                } leading: {
                    Icon(.folder)
                }
                .frame(maxWidth: ListRowSample.narrowWidth * 1.5)
            }
            section("Live") {
                VStack(spacing: 0) {
                    ListRow(action: { choose("inbox") }) {
                        Text(verbatim: ListRowSample.title)
                    } leading: {
                        Icon(.tray)
                    } trailing: {
                        Text(verbatim: ListRowSample.count)
                            .textRole(.subheadline.regular)
                            .foregroundStyle(.text.secondary)
                    }
                    .selected(chosen == "inbox")
                    ListRow(level: 1, action: { choose("today") }) {
                        Text(verbatim: "Today")
                    } leading: {
                        Icon(.sun)
                    }
                    .selected(chosen == "today")
                    ListRow(action: { choose("task") }) {
                        Text(verbatim: ListRowSample.task)
                    } subtitle: {
                        Text(verbatim: "Tomorrow")
                    } leading: {
                        Toggle(isOn: $done, accessibilityLabel: ListRowSample.task)
                            .toggleStyle(.check)
                            .accessibilityIdentifier(ListRowCatalogID.check)
                    }
                    .selected(chosen == "task")
                    ListRow(action: {}) {
                        Text(verbatim: "Archived")
                    } leading: {
                        Icon(.logbook)
                    }
                    .disabled(true)
                }
                Text(verbatim: "selected: \(chosen); actions: \(actions); done: \(done ? "yes" : "no")")
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
                    .accessibilityIdentifier(ListRowCatalogID.summary)
            }
        }
    }

    private func choose(_ row: String) {
        chosen = row
        actions += 1
    }

    /// A row of the form in each state it enters, labelled with the state.
    private func states(_ form: ListRowForm) -> some View {
        VStack(spacing: 0) {
            ListRowSampleRow(form: form, title: "\(form.rawValue), rest", subtitle: nil)
            ForEach(ListRowCatalogState.all.filter { $0.isEntered && $0.isEntered(by: form) }, id: \.self) { state in
                ListRowSampleRow(form: form, title: "\(form.rawValue), \(state.name)", subtitle: nil)
                    .listRowCatalogState(state)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}

/// Rows in a system `List`, as the contract's Apple entry gives them: no insets, no background and no separator of the
/// List's, no List selection; the List keeps its swipe actions. A row's action counts, its check toggles, and a swipe
/// deletes.
private struct ListRowListPage: View {
    @State private var rows = ["Call the plumber", "Pay the rent", "Buy seeds"]
    @State private var actions = 0
    @State private var done = false
    @State private var deleted: [String] = []

    var body: some View {
        List {
            ForEach(Array(rows.enumerated()), id: \.element) { index, title in
                ListRow(action: { actions += 1 }) {
                    Text(verbatim: title)
                } leading: {
                    if index == 0 {
                        Toggle(isOn: $done, accessibilityLabel: title)
                            .toggleStyle(.check)
                            .accessibilityIdentifier(ListRowCatalogID.listCheck)
                    } else {
                        Icon(.note)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparatorHidden()
                .swipeActions {
                    Button(role: .destructive) {
                        deleted.append(title)
                        rows.removeAll { $0 == title }
                    } label: {
                        Label("Delete", icon: .trash)
                    }
                }
            }
            Text(
                verbatim: "actions: \(actions); done: \(done ? "yes" : "no"); deleted: "
                    + (deleted.isEmpty ? "none" : deleted.joined(separator: ", "))
            )
            .textRole(.footnote.regular)
            .foregroundStyle(.text.secondary)
            .accessibilityIdentifier(ListRowCatalogID.listSummary)
        }
        .listStyle(.plain)
    }
}

/// One cell of ListRow's snapshot matrix (#24; `ComponentMatrix.listRow`, generated from the contract): the sample row
/// at level 1, so that `guides` shows, in its form and the combination's state: hover, focus and pressed forced,
/// selected, disabled and dropTarget through their real modifiers.
struct ListRowMatrixCell: View {
    let values: ListRowMatrixValues

    init(_ values: ListRowMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here.
        let (form, guides, stateName) = values.fields
        ListRowSampleRow(form: form, level: 1, guides: guides)
            .listRowCatalogState(stateName.flatMap(ListRowCatalogState.init(named:)))
            .matrixCellTakesOfferedWidth()
    }
}

/// The largest text size the supplements of rows at level 2 and deeper are drawn at. At accessibility5 an iPhone's
/// width leaves such a row no room for its words: the indent, the padding and the gaps scale with the text, about
/// threefold, 75 pt a level (decisions/0001, "Measured", open for the second gate). The generated sheets and the
/// accessibility5 supplement draw accessibility5 itself.
private let listRowDeepestTextSize = DynamicTypeSize.accessibility2

/// The note a capped supplement adds.
private let listRowCappedNote =
    " At the accessibility sizes drawn at accessibility2 at most: at accessibility5 an iPhone leaves a row at level 2 "
    + "or deeper no room for its words (decisions/0001, \"Measured\")."

extension ComponentMatrix.Supplement {
    /// The state of a supplement's cell.
    fileprivate static func state(_ combination: ComponentMatrix.Combination) -> ListRowCatalogState? {
        combination.state.flatMap(ListRowCatalogState.init(named:))
    }

    /// Whether a supplement's cell draws its guides: the column's value of `guides`.
    fileprivate static func guides(_ combination: ComponentMatrix.Combination) -> Bool {
        ListRowMatrixValues(combination).fields.guides
    }

    /// A selected row in each state of the pressable form: selected with pressed, with disabled, and in the
    /// high-contrast themes its ring, which the generated sheets, each state alone, do not draw.
    static let listRowSelected = ComponentMatrix.Supplement(
        component: "list-row", id: "selected", title: "selected, in each state",
        note: "The row is selected, and in the row's state too: pressed draws pressed over selected, disabled dims "
            + "the selected highlight, and in the high-contrast themes a selected row draws border.focus at "
            + "stroke.thick inside its highlight.",
        keeps: ["form": "pressable"]
    ) { combination in
        ListRowSampleRow(level: 1, guides: guides(combination))
            .listRowCatalogState(state(combination))
            .selected(true)
            .matrixCellTakesOfferedWidth()
    }

    /// A tree of levels 0 to 3 with its guides, one row selected (the level is a quantity, not an axis).
    static let listRowTree = ComponentMatrix.Supplement(
        component: "list-row", id: "tree", title: "a tree of levels 0 to 3",
        note: "Five rows at levels 0, 1, 2, 3 and 0, the second selected: each indented by container.indent per "
            + "level, one guide per ancestor level under that level's leading slot, joining into lines."
            + listRowCappedNote,
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true
    ) { combination in
        ListRowTree(guides: guides(combination))
            .listRowCatalogState(state(combination))
            .dynamicTypeSize(...listRowDeepestTextSize)
            .matrixCellTakesOfferedWidth()
    }

    /// The slots: the title alone, with the leading slot, with the second line, and all four with the chevron's cell.
    static let listRowSlots = ComponentMatrix.Supplement(
        component: "list-row", id: "slots", title: "the slots",
        note: "Title alone; leading and title; title and second line; all four, and the Disclosure chevron's cell "
            + "(a stand-in until #120) after the trailing slot."
            + listRowCappedNote,
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true, columnsPerPicture: 1
    ) { combination in
        VStack(spacing: 0) {
            ListRow(level: 1, guides: guides(combination), action: {}) { Text(verbatim: "Title") }
            ListRow(level: 1, guides: guides(combination), action: {}) {
                Text(verbatim: "Leading")
            } leading: {
                Icon(.tray)
            }
            ListRow(level: 1, guides: guides(combination), action: {}) {
                Text(verbatim: "Second line")
            } subtitle: {
                Text(verbatim: "Under the title")
            }
            ListRowSampleRow(level: 1, guides: guides(combination))
                .listRowDisclosureCell { ListRowCellStandIn() }
        }
        .listRowCatalogState(state(combination))
        .dynamicTypeSize(...listRowDeepestTextSize)
        .matrixCellTakesOfferedWidth()
    }

    /// A task's row: the check at the start, a title over two lines, a second line.
    static let listRowTask = ComponentMatrix.Supplement(
        component: "list-row", id: "task", title: "a task's row",
        note: "Static: a Checkbox with no drawn label at the start, its hit area standing in the row's padding, a "
            + "title that wraps, and the meta line under it."
            + listRowCappedNote,
        keeps: ["form": "static"], rowsPerPicture: 2, splitsAtEverySize: true
    ) { combination in
        ListRow(level: 1, guides: guides(combination)) {
            Text(verbatim: "Call the plumber about the kitchen tap that drips at night")
        } subtitle: {
            Text(verbatim: "Tomorrow · Home")
        } leading: {
            Toggle(isOn: .constant(false), accessibilityLabel: "Call the plumber").toggleStyle(.check)
        }
        .listRowCatalogState(state(combination))
        .dynamicTypeSize(...listRowDeepestTextSize)
        .matrixCellTakesOfferedWidth()
    }

    /// A long title on one line, at level 4, given less width than it needs.
    static let listRowLongTitle = ComponentMatrix.Supplement(
        component: "list-row", id: "long-title", title: "a long title at level 4",
        note: "The product sets one line; the row is given less width than the title needs at level 4: the indent and "
            + "the slots keep their size, the title truncates at its end with an ellipsis."
            + listRowCappedNote,
        keeps: ["form": "pressable"]
    ) { combination in
        ListRow(level: 4, guides: guides(combination), action: {}) {
            Text(verbatim: ListRowSample.long).lineLimit(1)
        } leading: {
            Icon(.folder)
        } trailing: {
            Text(verbatim: ListRowSample.count).textRole(.subheadline.regular).foregroundStyle(.text.secondary)
        }
        .listRowCatalogState(state(combination))
        .dynamicTypeSize(...listRowDeepestTextSize)
        .matrixCellTakesOfferedWidth()
    }

    /// The largest text size, on every platform: the trailing slot under the title and the second line.
    static let listRowLargeText = ComponentMatrix.Supplement(
        component: "list-row", id: "accessibility5", title: "accessibility5: the trailing slot under the text",
        note: "At the accessibility text sizes the trailing slot moves under the title and the second line, from the "
            + "title's leading edge; the chevron's cell (a stand-in) stays on the first line at the end. Drawn at "
            + "accessibility5 whatever the sheet's text size, at level 0, one column a picture: the row needs an "
            + "iPhone's whole width.",
        keeps: ["form": "pressable"], rowsPerPicture: 1, splitsAtEverySize: true, columnsPerPicture: 1
    ) { combination in
        ListRowSampleRow(level: 0, guides: guides(combination))
            .listRowDisclosureCell { ListRowCellStandIn() }
            .listRowCatalogState(state(combination))
            .dynamicTypeSize(.accessibility5)
            .matrixCellTakesOfferedWidth()
    }

    /// The insertion mark and a drop target.
    static let listRowDrag = ComponentMatrix.Supplement(
        component: "list-row", id: "drag", title: "the insertion mark and a drop target",
        note: "Three rows: Rule(purpose: .insertion) over the first row's top edge at level 0, over the second's "
            + "bottom edge at level 2, and the third a drop target. The mark is no state: .insertionMark(_:level:)."
            + listRowCappedNote,
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true
    ) { combination in
        ListRowDragSamples(guides: guides(combination))
            .listRowCatalogState(state(combination))
            .padding(.vertical, .space50)
            .dynamicTypeSize(...listRowDeepestTextSize)
            .matrixCellTakesOfferedWidth()
    }

    /// Right to left.
    static let listRowRightToLeft = ComponentMatrix.Supplement(
        component: "list-row", id: "right-to-left", title: "right to left",
        note: "The row mirrors: the leading slot and the indent from the right, the guides under it, the trailing slot "
            + "and the chevron's cell (a stand-in) at the left."
            + listRowCappedNote,
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true, columnsPerPicture: 1
    ) { combination in
        VStack(spacing: 0) {
            ListRowSampleRow(level: 1, guides: guides(combination))
            ListRowSampleRow(level: 2, guides: guides(combination))
                .listRowDisclosureCell { ListRowCellStandIn() }
        }
        .listRowCatalogState(state(combination))
        .environment(\.layoutDirection, .rightToLeft)
        .dynamicTypeSize(...listRowDeepestTextSize)
        .matrixCellTakesOfferedWidth()
    }

    /// Every ListRow supplement, in order.
    static let listRowAll: [Self] = [
        .listRowSelected, .listRowTree, .listRowSlots, .listRowTask, .listRowLongTitle, .listRowLargeText,
        .listRowDrag, .listRowRightToLeft,
    ]
}
