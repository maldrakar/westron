import SwiftUI
import WestronUI

// ListRow's catalog entries, from spec/components/list-row/list-row.spec.yaml: `list-row`, both forms in every state
// each enters (the contract's `forms`), a tree of levels with guides, the insertion mark and a drop target, the
// Disclosure chevron on a branch and a leaf's empty cell, and a live sample; `list-row-in-list`, rows in a system
// List with swipe actions, and the insertion mark in a List. The states come from the generated `ListRowState` through `ListRowCatalogState`, so the pages follow the
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
    /// The live branch's row, Projects; the identifier reaches the Disclosure chevron's cell inside it too.
    static let branch = "list-row.live.branch"
    /// The text that says which live row is selected, how often a row's action ran, whether the task is done, how often
    /// the branch's chevron cell was pressed and how many presses a row's system Button began:
    /// "selected: inbox; actions: 0; done: no; cell: 0; presses: 0".
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

/// A tree of levels 0 to 3, with guides, the second row selected; with or without a count in each trailing slot.
struct ListRowTree: View {
    var guides = true
    var counts = true

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(["Work", "Projects", "Garden", "Seeds", "Home"].enumerated()), id: \.offset) { index, title in
                let level = [0, 1, 2, 3, 0][index]
                ListRow(level: level, guides: guides, action: {}) {
                    Text(verbatim: title)
                } leading: {
                    Icon(level == 0 ? .briefcase : .folder)
                } trailing: {
                    if counts {
                        Text(verbatim: "\(index + 2)")
                            .textRole(.subheadline.regular)
                            .foregroundStyle(.text.secondary)
                    }
                }
                .selected(index == 1)
            }
        }
    }
}

/// A branch of a tree: the row as the label of a DisclosureGroup in westron's chevron style (#120), folding `content`,
/// so that the row draws the chevron's cell as its last trailing item. watchOS has no DisclosureGroup: there the row
/// and its content stand one above the other, with no chevron.
struct ListRowBranch<Label: View, Content: View>: View {
    @State var isExpanded = false
    @ViewBuilder let label: Label
    @ViewBuilder var content: Content

    var body: some View {
        #if os(watchOS)
            VStack(spacing: 0) {
                label
                if isExpanded { content }
            }
        #else
            DisclosureGroup(isExpanded: $isExpanded) {
                content
            } label: {
                label
            }
            .disclosureGroupStyle(.chevron)
        #endif
    }
}

extension ListRowBranch where Content == EmptyView {
    /// A collapsed branch whose lists the sample leaves out.
    init(@ViewBuilder label: () -> Label) {
        self.label = label()
        content = EmptyView()
    }
}

extension View {
    /// Lines the leaves up with the branches, as `.disclosureAlignsLeaves()` does; watchOS has no Disclosure.
    func listRowLeavesAligned() -> some View {
        #if os(watchOS)
            self
        #else
            disclosureAlignsLeaves()
        #endif
    }

    /// Calls `action` each time a branch's chevron in this view folds or unfolds its branch; watchOS has none.
    func listRowChevronToggles(_ action: @escaping @MainActor @Sendable () -> Void) -> some View {
        #if os(watchOS)
            self
        #else
            onDisclosureToggle { _ in action() }
        #endif
    }
}

/// A branch and a leaf of a tree, the branch collapsed: the branch's row ends with the chevron's cell, the leaf's with
/// the empty cell `.disclosureAlignsLeaves()` keeps, so that the counts stand in one column.
struct ListRowCellColumn: View {
    var body: some View {
        VStack(spacing: 0) {
            ListRowBranch {
                ListRow(action: {}) {
                    Text(verbatim: "Work")
                } leading: {
                    Icon(.briefcase)
                } trailing: {
                    Text(verbatim: "4").textRole(.subheadline.regular).foregroundStyle(.text.secondary)
                }
            }
            ListRow(action: {}) {
                Text(verbatim: "Errands")
            } leading: {
                Icon(.bag)
            } trailing: {
                Text(verbatim: "7").textRole(.subheadline.regular).foregroundStyle(.text.secondary)
            }
        }
        .listRowLeavesAligned()
    }
}

/// The lists screen's rows (the `composition` supplement): a list's IconTile at the start, a count or a static Chip at
/// the end, flat and then as a Disclosure branch with a leaf and a collapsed branch whose row is disabled.
struct ListRowComposition: View {
    var body: some View {
        VStack(spacing: 0) {
            ListRow(action: {}) {
                Text(verbatim: ListRowSample.title)
            } leading: {
                IconTile(.tray)
            } trailing: {
                count(ListRowSample.count)
            }
            ListRow(action: {}) {
                Text(verbatim: "Groceries")
            } leading: {
                IconTile(.bag).category(.green)
            } trailing: {
                Label("Shared", icon: .hash).labelStyle(.chip)
            }
            ListRowBranch(isExpanded: true) {
                ListRow(action: {}) {
                    Text(verbatim: "Work")
                } leading: {
                    IconTile(.briefcase).category(.blue)
                } trailing: {
                    count("9")
                }
            } content: {
                ListRow(level: 1, action: {}) {
                    Text(verbatim: "Errands")
                } leading: {
                    IconTile(.bag).category(.green)
                } trailing: {
                    Label("Today", icon: .sun).labelStyle(.chip)
                }
                // A branch whose row is disabled alone: the row dims its words and slots once, and its chevron,
                // which takes its group's state, is drawn whole and still folds (the contracts' disabled).
                ListRowBranch {
                    ListRow(level: 1, action: {}) {
                        Text(verbatim: "Archive")
                    } leading: {
                        IconTile(.logbook)
                    } trailing: {
                        Label("Old", icon: .hash).labelStyle(.chip)
                    }
                    .disabled(true)
                }
            }
        }
        .listRowLeavesAligned()
    }

    private func count(_ words: String) -> some View {
        Text(verbatim: words).textRole(.subheadline.regular).foregroundStyle(.text.secondary)
    }
}

/// Rows with the insertion mark over the top edge at level 0 and over the bottom edge at level 2, the row under that
/// mark selected and not a drop target, so that its highlight shows the mark drawn above it, and a drop target.
struct ListRowDragSamples: View {
    var guides = true

    var body: some View {
        VStack(spacing: 0) {
            ListRowSampleRow(level: 0, guides: guides, subtitle: nil)
                .insertionMark(.top, level: 0)
            ListRowSampleRow(level: 1, guides: guides, title: "Garden", subtitle: nil)
                .insertionMark(.bottom, level: 2)
            ListRowSampleRow(level: 1, guides: guides, title: "Seeds", subtitle: nil)
                .selected(true)
            ListRowSampleRow(level: 1, guides: guides, title: "Errands", subtitle: nil)
                .dropTarget(true)
        }
    }
}

private struct ListRowPage: View {
    @State private var chosen = "inbox"
    @State private var actions = 0
    @State private var done = false
    @State private var cellPresses = 0
    @State private var presses = 0

    var body: some View {
        TokenPage(
            title: "ListRow",
            summary: "ListRow(level:guides:action:) { title } subtitle: leading: trailing:, an own view: a title, a "
                + "second line, a leading and a trailing slot, indented by space.300 per level with guides in "
                + "border.guide; a highlight at radius.row, hover, pressed, selected (a border.focus bar at its "
                + "leading edge, body.strong) and a drop target (accent-subtle, an insertion ring). .selected(_:), "
                + ".dropTarget(_:), .insertionMark(_:level:)."
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
            section("Levels without guides (guides: false), as a picker's") {
                ListRowTree(guides: false)
            }
            section("Drag and drop: the insertion mark and a drop target") {
                ListRowDragSamples()
            }
            section("A branch's chevron (Disclosure) and a leaf's empty cell") {
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
                    // A branch, expanded: its chevron folds the static row under it.
                    ListRowBranch(isExpanded: true) {
                        ListRow(action: { choose("projects") }) {
                            Text(verbatim: "Projects")
                        } leading: {
                            Icon(.folder)
                        }
                        .selected(chosen == "projects")
                        .accessibilityIdentifier(ListRowCatalogID.branch)
                    } content: {
                        ListRow(level: 1) {
                            Text(verbatim: "Buy washers")
                        } leading: {
                            Icon(.note)
                        }
                        .selected(true)
                    }
                    ListRow(action: { choose("archived") }) {
                        Text(verbatim: "Archived")
                    } leading: {
                        Icon(.logbook)
                    }
                    .disabled(true)
                }
                .listRowPressObserver { pressed in
                    if pressed { presses += 1 }
                }
                .listRowChevronToggles { cellPresses += 1 }
                Text(
                    verbatim: "selected: \(chosen); actions: \(actions); done: \(done ? "yes" : "no"); "
                        + "cell: \(cellPresses); presses: \(presses)"
                )
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
/// deletes. Under the summary, rows with insertion marks, where the List's cells, not one stack, decide what each mark
/// shows.
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
            // The insertion mark in a List, where each row is a cell of its own and `zIndex` orders nothing across
            // cells: a bottom mark over a selected next row, then a selected row over a top mark (decisions/0001,
            // "The insertion mark in a List").
            dragRow("Garden").insertionMark(.bottom, level: 2)
            dragRow("Seeds").selected(true)
            dragRow("Errands").selected(true)
            dragRow("Home").insertionMark(.top, level: 2)
            dragRow("Work").insertionMark(.bottom, level: 2)
            dragRow("Bills")
            dragRow("Notes").insertionMark(.bottom, level: 2)
            dragRow("Trips").insertionMark(.top, level: 2)
        }
        .listStyle(.plain)
    }

    /// A row of the drag samples, at level 1, laid out in the List as the contract's Apple entry gives it.
    private func dragRow(_ title: String) -> some View {
        ListRow(level: 1, action: {}) {
            Text(verbatim: title)
        } leading: {
            Icon(.folder)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparatorHidden()
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

extension ComponentMatrix.Supplement {
    /// The state of a supplement's cell.
    fileprivate static func state(_ combination: ComponentMatrix.Combination) -> ListRowCatalogState? {
        combination.state.flatMap(ListRowCatalogState.init(named:))
    }

    /// Whether a supplement's cell draws its guides: the column's value of `guides`.
    fileprivate static func guides(_ combination: ComponentMatrix.Combination) -> Bool {
        ListRowMatrixValues(combination).fields.guides
    }

    /// A selected row in each state of the pressable form: selected with pressed, with disabled and with a drop onto
    /// it, which the generated sheets, each state alone, do not draw; and a title whose role the product set.
    static let listRowSelected = ComponentMatrix.Supplement(
        component: "list-row", id: "selected", title: "selected, in each state",
        note: "The row is selected, and in the row's state too: pressed draws pressed over selected, disabled dims "
            + "the selected highlight, a drop target draws its ring. In every theme a selected row draws a "
            + "border.focus bar at stroke.thick at its highlight's leading edge; the second row's title sets its own "
            + "role, callout.regular, so only the bar and the tint show the selection.",
        keeps: ["form": "pressable"], rowsPerPicture: 3, splitsAtEverySize: true
    ) { combination in
        VStack(spacing: 0) {
            ListRowSampleRow(level: 1, guides: guides(combination))
            ListRow(level: 1, guides: guides(combination), action: {}) {
                Text(verbatim: "Own role").textRole(.callout.regular)
            } leading: {
                Icon(.folder)
            }
        }
        .listRowCatalogState(state(combination))
        .selected(true)
        .matrixCellTakesOfferedWidth()
    }

    /// A tree of levels 0 to 3 with its guides, one row selected (the level is a quantity, not an axis).
    static let listRowTree = ComponentMatrix.Supplement(
        component: "list-row", id: "tree", title: "a tree of levels 0 to 3",
        note: "Five rows at levels 0, 1, 2, 3 and 0, the second selected: each indented by container.indent per "
            + "level, one guide per ancestor level under that level's leading slot, joining into lines. No counts, so "
            + "that the tree is one screen high at accessibility5, where a count stands under the title.",
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true
    ) { combination in
        ListRowTree(guides: guides(combination), counts: false)
            .listRowCatalogState(state(combination))
            .matrixCellTakesOfferedWidth()
    }

    /// The slots: the title alone, with the leading slot, with the second line, and all four with the chevron's cell.
    static let listRowSlots = ComponentMatrix.Supplement(
        component: "list-row", id: "slots", title: "the slots",
        note: "Title alone; leading and title; title and second line; all four, and the Disclosure chevron's cell "
            + "after the trailing slot, the row a collapsed branch.",
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
            ListRowBranch { ListRowSampleRow(level: 1, guides: guides(combination)) }
        }
        .listRowCatalogState(state(combination))
        .matrixCellTakesOfferedWidth()
    }

    /// A task's row: the check at the start, a title over two lines, a second line.
    static let listRowTask = ComponentMatrix.Supplement(
        component: "list-row", id: "task", title: "a task's row",
        note: "Static: a Checkbox with no drawn label at the start, its hit area standing in the row's padding, a "
            + "title that wraps, and the meta line under it.",
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
        .matrixCellTakesOfferedWidth()
    }

    /// A long title on one line, at level 4, given less width than it needs.
    static let listRowLongTitle = ComponentMatrix.Supplement(
        component: "list-row", id: "long-title", title: "a long title at level 4",
        note: "The product sets one line; the row is given less width than the title needs at level 4: the indent and "
            + "the slots keep their size, the title truncates at its end with an ellipsis.",
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
        .matrixCellTakesOfferedWidth()
    }

    /// The largest text size, on every platform: the trailing slot under the title and the second line.
    static let listRowLargeText = ComponentMatrix.Supplement(
        component: "list-row", id: "accessibility5", title: "accessibility5: the trailing slot under the text",
        note: "At the accessibility text sizes the trailing slot moves under the title and the second line, from the "
            + "title's leading edge; the chevron's cell stays on the first line at the end. Drawn at "
            + "accessibility5 whatever the sheet's text size, at level 0, one column a picture: the row needs an "
            + "iPhone's whole width.",
        keeps: ["form": "pressable"], rowsPerPicture: 1, splitsAtEverySize: true, columnsPerPicture: 1
    ) { combination in
        ListRowBranch { ListRowSampleRow(level: 0, guides: guides(combination)) }
            .listRowCatalogState(state(combination))
            .dynamicTypeSize(.accessibility5)
            .matrixCellTakesOfferedWidth()
    }

    /// The insertion mark and a drop target.
    static let listRowDrag = ComponentMatrix.Supplement(
        component: "list-row", id: "drag", title: "the insertion mark and a drop target",
        note: "Four rows: Rule(purpose: .insertion) over the first row's top edge at level 0, over the second's "
            + "bottom edge at level 2, drawn above the third row's selected highlight, and the fourth a drop target. "
            + "The mark is no state: .insertionMark(_:level:).",
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true
    ) { combination in
        ListRowDragSamples(guides: guides(combination))
            .listRowCatalogState(state(combination))
            .padding(.vertical, .space50)
            .matrixCellTakesOfferedWidth()
    }

    /// Right to left.
    static let listRowRightToLeft = ComponentMatrix.Supplement(
        component: "list-row", id: "right-to-left", title: "right to left",
        note: "The row mirrors: the leading slot and the indent from the right, the guides under it, the trailing slot "
            + "and the chevron's cell at the left, pointing left while collapsed.",
        keeps: ["form": "pressable"], rowsPerPicture: 2, splitsAtEverySize: true, columnsPerPicture: 1
    ) { combination in
        VStack(spacing: 0) {
            ListRowSampleRow(level: 1, guides: guides(combination))
            ListRowBranch { ListRowSampleRow(level: 2, guides: guides(combination)) }
        }
        .listRowCatalogState(state(combination))
        .environment(\.layoutDirection, .rightToLeft)
        .matrixCellTakesOfferedWidth()
    }

    /// The lists screen's rows, composed as the pilot composes them (decisions/0014): IconTiles at the start, a count or
    /// a static Chip at the end, then the same rows as a branch, a leaf and a branch in a Disclosure, one row disabled.
    static let listRowComposition = ComponentMatrix.Supplement(
        component: "list-row", id: "composition", title: "the lists screen's rows, composed",
        note: "IconTile at the start of every row; Inbox ends with a count, Groceries with a static Chip, both as high "
            + "as a row with the title alone. Below, the same rows as a Disclosure branch, Work, expanded, a leaf and a "
            + "collapsed branch, lined up with .disclosureAlignsLeaves(); Archive's row is disabled alone: its words "
            + "and slots dimmed once, its chevron whole, since it still folds. Drawn at most at xxxLarge: at accessibility5 five rows with stacked trailing slots are taller than "
            + "a phone's screen; the sheet accessibility5 shows a row there.",
        keeps: ["form": "pressable"], columns: ["true"], rowsPerPicture: 2, splitsAtEverySize: true,
        columnsPerPicture: 1
    ) { combination in
        ListRowComposition()
            .listRowCatalogState(state(combination))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .matrixCellTakesOfferedWidth()
    }

    /// Every ListRow supplement, in order.
    static let listRowAll: [Self] = [
        .listRowSelected, .listRowTree, .listRowSlots, .listRowTask, .listRowLongTitle, .listRowLargeText,
        .listRowDrag, .listRowRightToLeft, .listRowComposition,
    ]
}
