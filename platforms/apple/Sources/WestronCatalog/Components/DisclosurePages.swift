// Disclosure's catalog entry, from spec/components/disclosure/disclosure.spec.yaml: `disclosure`, a group collapsed and
// expanded in every state, a block's header, a three-level tree of ListRows with its leaves lined up, the tree right to
// left, a live sample with a readout, and the style in a system List, which the contract does not promise (Q5). The
// states come from the generated `DisclosureState` through `DisclosureCatalogState`, so the page follows the contract.
// SwiftUI has no DisclosureGroup on watchOS, so nothing here exists there.

#if !os(watchOS)
    import SwiftUI
    import WestronUI

    extension CatalogEntry {
        static let disclosure = CatalogEntry(id: "disclosure", title: "Disclosure", section: .components) {
            DisclosurePage()
        }
    }

    /// Accessibility identifiers of the live samples, which the catalog's UI tests (DisclosureBehaviorTests) press.
    enum DisclosureCatalogID {
        /// The live branch's row, whose action chooses it.
        static let row = "disclosure.live.row"
        /// The live block header's title, a button that opens the block.
        static let title = "disclosure.live.title"
        /// The readout: "branch: expanded; block: collapsed; toggles: 0; actions: 0; opened: 0; hover: no; static:
        /// collapsed".
        static let summary = "disclosure.live.summary"
        /// The live static branch's row, a ListRow with no action.
        static let staticRow = "disclosure.live.static"
        /// The text inside the live static branch, shown while it is expanded.
        static let staticContent = "disclosure.live.static-content"
        /// The text inside the live branch, shown while it is expanded.
        static let branchContent = "disclosure.live.branch-content"
        /// The text inside the live block, shown while it is expanded.
        static let blockContent = "disclosure.live.block-content"
    }

    /// A node of the sample tree: a list, its count, and the lists inside it.
    struct DisclosureNode: Identifiable, Sendable {
        let title: String
        let icon: Westron.Icon
        let count: Int
        var children: [DisclosureNode] = []

        var id: String { title }

        /// Three levels: two branches, one inside the other, and leaves beside them at every level.
        static let tree: [DisclosureNode] = [
            DisclosureNode(
                title: "Work", icon: .briefcase, count: 9,
                children: [
                    DisclosureNode(
                        title: "Projects", icon: .folder, count: 5,
                        children: [
                            DisclosureNode(title: "Garden", icon: .note, count: 3),
                            DisclosureNode(title: "Seeds", icon: .note, count: 2),
                        ]),
                    DisclosureNode(title: "Errands", icon: .bag, count: 4),
                ]),
            DisclosureNode(title: "Home", icon: .tray, count: 12),
        ]

        /// The tree in a system List: the same, but for its top-level leaf, named apart, so that the audit can tell the
        /// List's row from the tree's outside it (CatalogAccessibilityAuditTests, the suppression for Q5).
        static let listTree: [DisclosureNode] =
            tree.dropLast() + [DisclosureNode(title: "Someday", icon: .tray, count: 12)]
    }

    /// A branch of the tree, recursive: a DisclosureGroup whose label is the list's row, or the row alone for a leaf, as
    /// the pilot composes it (the contract's decisions/0001, "How the pilot composes it").
    struct DisclosureBranch: View {
        let node: DisclosureNode
        var level = 0
        @Binding var folded: Set<String>

        var body: some View {
            if node.children.isEmpty {
                row
            } else {
                DisclosureGroup(isExpanded: expanded) {
                    ForEach(node.children) { child in
                        DisclosureBranch(node: child, level: level + 1, folded: $folded)
                    }
                } label: {
                    row
                }
            }
        }

        private var row: some View {
            ListRow(level: level, action: {}) {
                Text(verbatim: node.title)
            } leading: {
                Icon(node.icon)
            } trailing: {
                Text(verbatim: "\(node.count)")
                    .textRole(.subheadline.regular)
                    .foregroundStyle(.text.secondary)
            }
        }

        private var expanded: Binding<Bool> {
            Binding(
                get: { !folded.contains(node.id) },
                set: { isExpanded in
                    if isExpanded { folded.remove(node.id) } else { folded.insert(node.id) }
                })
        }
    }

    /// The sample tree, every branch expanded unless `folded` names it, its leaves lined up with its branches.
    struct DisclosureTree: View {
        @State var folded: Set<String> = []

        var body: some View {
            VStack(spacing: 0) {
                ForEach(DisclosureNode.tree) { node in
                    DisclosureBranch(node: node, folded: $folded)
                }
            }
            .disclosureGroupStyle(.chevron)
            .disclosureAlignsLeaves()
        }
    }

    /// A sample group: a one-line text label, and two lines of content under it.
    struct DisclosureSample: View {
        var title = "Groceries"
        @State var isExpanded: Bool

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: .space50) {
                    Text(verbatim: "Milk, eggs, bread")
                    Text(verbatim: "Apples and pears")
                }
                .textRole(.body.regular)
                .foregroundStyle(.text.secondary)
            } label: {
                Text(verbatim: title)
                    .textRole(.body.strong)
                    .foregroundStyle(.text.primary)
            }
            .disclosureGroupStyle(.chevron)
        }
    }

    /// A block's header, as the List screen's: the title opens the block, a date beside it, the chevron folds it.
    struct DisclosureBlockHeader: View {
        var title = "Today"
        @Binding var isExpanded: Bool
        var open: () -> Void = {}

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(spacing: 0) {
                    ForEach(["Call the plumber", "Pay the rent"], id: \.self) { task in
                        ListRow {
                            Text(verbatim: task)
                        } leading: {
                            Toggle(isOn: .constant(false), accessibilityLabel: task).toggleStyle(.check)
                        }
                    }
                }
            } label: {
                Button(action: open) {
                    HStack(alignment: .firstTextBaseline, spacing: .space100) {
                        Text(verbatim: title)
                            .textRole(.heading.small)
                            .foregroundStyle(.text.primary)
                        Text(verbatim: "Sat 22 Nov")
                            .textRole(.footnote.regular)
                            .foregroundStyle(.text.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .disclosureGroupStyle(.chevron)
        }
    }

    private struct DisclosurePage: View {
        @State private var branchExpanded = true
        @State private var blockExpanded = false
        @State private var toggles = 0
        @State private var actions = 0
        @State private var opened = 0
        @State private var hovered = false
        @State private var staticExpanded = false
        @State private var listFolded: Set<String> = []

        var body: some View {
            TokenPage(
                title: "Disclosure",
                summary:
                    "DisclosureGroup(isExpanded:) { content } label: { label }.disclosureGroupStyle(.chevron): the "
                    + "collapse chevron in icon.tertiary at the label's end, pointing down while expanded and to the "
                    + "trailing side while collapsed, turning in motion.move; a circle of size.control.s under the "
                    + "pointer (background.hover) and pressed (background.pressed); a hit area of size.target.minimum. "
                    + "Only the chevron folds: the label keeps its own action. On a ListRow the cell is the row's "
                    + "last trailing item; .disclosureAlignsLeaves() keeps a leaf's cell empty."
            ) {
                section("Collapsed, in each state") {
                    states(expanded: false)
                }
                section("Expanded, in each state") {
                    states(expanded: true)
                }
                section("A block's header: the title opens the block, the chevron folds it") {
                    DisclosureBlockHeader(isExpanded: .constant(true))
                }
                section("A tree of ListRows, three levels, leaves lined up with branches") {
                    DisclosureTree()
                }
                section("Right to left") {
                    DisclosureTree()
                        .environment(\.layoutDirection, .rightToLeft)
                }
                section("Live") {
                    live
                }
                section("In a system List: westron's look is not promised there (Q5)") {
                    inList
                }
            }
        }

        /// A sample group in each state, collapsed or expanded, labelled with the state.
        private func states(expanded: Bool) -> some View {
            let shown = DisclosureCatalogState.all.filter { $0.isEntered && !$0.isExpanded }
            return VStack(alignment: .leading, spacing: 0) {
                DisclosureSample(title: "rest", isExpanded: expanded)
                ForEach(shown, id: \.self) { state in
                    DisclosureSample(title: state.name, isExpanded: expanded)
                        .forcingDisclosureStates([state])
                        .disabled(state.isDisabled)
                }
            }
        }

        private var live: some View {
            VStack(alignment: .leading, spacing: .space100) {
                VStack(spacing: 0) {
                    DisclosureGroup(isExpanded: $branchExpanded) {
                        ListRow(level: 1) {
                            Text(verbatim: "Buy washers")
                        } leading: {
                            Icon(.note)
                        }
                        .accessibilityIdentifier(DisclosureCatalogID.branchContent)
                    } label: {
                        ListRow(action: { actions += 1 }) {
                            Text(verbatim: "Projects")
                        } leading: {
                            Icon(.folder)
                        } trailing: {
                            Text(verbatim: "5")
                                .textRole(.subheadline.regular)
                                .foregroundStyle(.text.secondary)
                        }
                        .accessibilityIdentifier(DisclosureCatalogID.row)
                    }
                    DisclosureGroup(isExpanded: $blockExpanded) {
                        Text(verbatim: "Call the plumber")
                            .textRole(.body.regular)
                            .foregroundStyle(.text.primary)
                            .accessibilityIdentifier(DisclosureCatalogID.blockContent)
                    } label: {
                        Button {
                            opened += 1
                        } label: {
                            Text(verbatim: "Tomorrow")
                                .textRole(.heading.small)
                                .foregroundStyle(.text.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(DisclosureCatalogID.title)
                    }
                    // A static branch: a row with no action, whose cell is still its own element and folds it.
                    DisclosureGroup(isExpanded: $staticExpanded) {
                        ListRow(level: 1) {
                            Text(verbatim: "Old receipts")
                        } leading: {
                            Icon(.note)
                        }
                        .accessibilityIdentifier(DisclosureCatalogID.staticContent)
                    } label: {
                        ListRow {
                            Text(verbatim: "Archive")
                        } leading: {
                            Icon(.folder)
                        } trailing: {
                            Text(verbatim: "1")
                                .textRole(.subheadline.regular)
                                .foregroundStyle(.text.secondary)
                        }
                        .accessibilityIdentifier(DisclosureCatalogID.staticRow)
                    }
                }
                .disclosureGroupStyle(.chevron)
                .onDisclosureToggle { _ in toggles += 1 }
                .onDisclosureHover { hovered = $0 }
                Text(
                    verbatim: "branch: \(branchExpanded ? "expanded" : "collapsed"); "
                        + "block: \(blockExpanded ? "expanded" : "collapsed"); toggles: \(toggles); "
                        + "actions: \(actions); opened: \(opened); hover: \(hovered ? "yes" : "no"); "
                        + "static: \(staticExpanded ? "expanded" : "collapsed")"
                )
                .textRole(.footnote.regular)
                .foregroundStyle(.text.secondary)
                .accessibilityIdentifier(DisclosureCatalogID.summary)
            }
        }

        /// The tree in a system List, as a product might write it; the contract promises nothing here (Q5), and the
        /// decision records what each OS draws.
        private var inList: some View {
            List {
                ForEach(DisclosureNode.listTree) { node in
                    DisclosureBranch(node: node, folded: $listFolded)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .disclosureGroupStyle(.chevron)
            .disclosureAlignsLeaves()
            .frame(height: 6 * .size.target.minimum)
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

    /// One cell of Disclosure's snapshot matrix (#24; `ComponentMatrix.disclosure`, generated from the contract): a group
    /// with a one-line label and two lines of content, collapsed unless the state is expanded, in the combination's
    /// state: hover, focus and pressed forced, disabled through the system's `.disabled(_:)`.
    struct DisclosureMatrixCell: View {
        let values: DisclosureMatrixValues

        init(_ values: DisclosureMatrixValues) {
            self.values = values
        }

        var body: some View {
            // Every option at once: an option added to the contract changes `fields` and fails the build here.
            let (variant, stateName) = values.fields
            let state = stateName.flatMap(DisclosureCatalogState.init(named:))
            DisclosureSample(isExpanded: state?.isExpanded ?? false)
                .disclosureGroupStyle(variant)
                .forcingDisclosureStates(state.map { [$0] } ?? [])
                .disabled(state?.isDisabled ?? false)
                .matrixCellTakesOfferedWidth()
        }
    }

    extension ComponentMatrix.Supplement {
        /// The state of a supplement's cell.
        fileprivate static func disclosureState(_ combination: ComponentMatrix.Combination) -> DisclosureCatalogState? {
            combination.state.flatMap(DisclosureCatalogState.init(named:))
        }

        /// Expanded, with each other state: pressed, disabled and the rest, which the generated sheets, each state alone,
        /// do not draw.
        static let disclosureExpanded = ComponentMatrix.Supplement(
            component: "disclosure", id: "expanded", title: "expanded, in each state",
            note: "The group is expanded, and in the row's state too: the chevron points down, the content shows under "
                + "the header, and the cell draws the state's circle or dims as it does collapsed.",
            keeps: [:], rowsPerPicture: 3, splitsAtEverySize: true
        ) { combination in
            let state = disclosureState(combination)
            DisclosureSample(isExpanded: true)
                .forcingDisclosureStates(state.map { [$0] } ?? [])
                .disabled(state?.isDisabled ?? false)
                .matrixCellTakesOfferedWidth()
        }

        /// Right to left, collapsed and expanded.
        static let disclosureRightToLeft = ComponentMatrix.Supplement(
            component: "disclosure", id: "right-to-left", title: "right to left",
            note:
                "The header mirrors: the chevron's cell at the left; collapsed, the chevron points left, the trailing "
                + "side; expanded, down. Above collapsed, below expanded.",
            keeps: [:], rowsPerPicture: 3, splitsAtEverySize: true
        ) { combination in
            let state = disclosureState(combination)
            VStack(alignment: .leading, spacing: 0) {
                DisclosureSample(isExpanded: false)
                DisclosureSample(isExpanded: true)
            }
            .forcingDisclosureStates(state.map { [$0] } ?? [])
            .disabled(state?.isDisabled ?? false)
            .environment(\.layoutDirection, .rightToLeft)
            .matrixCellTakesOfferedWidth()
        }

        /// A three-level tree of ListRows, its leaves lined up with its branches.
        static let disclosureTree = ComponentMatrix.Supplement(
            component: "disclosure", id: "tree", title: "a tree of ListRows",
            note: "Work and Projects are branches, expanded; Garden, Seeds, Errands and Home are leaves. Each branch's "
                + "chevron is its row's last trailing item, inside the row's highlight; .disclosureAlignsLeaves() keeps "
                + "each leaf's cell empty, so the counts stand in one column. The state is forced on every chevron. "
                + "Drawn at most at xxxLarge: at accessibility5 six rows are taller than a phone's screen; ListRow's "
                + "own sheets show a row there, and this component's accessibility5 sheet the chevron.",
            keeps: [:], rowsPerPicture: 2, splitsAtEverySize: true
        ) { combination in
            let state = disclosureState(combination)
            DisclosureTree()
                .forcingDisclosureStates(state.map { [$0] } ?? [])
                .disabled(state?.isDisabled ?? false)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .matrixCellTakesOfferedWidth()
        }

        /// A block's header, whose label is a button and not a ListRow: the cell after the label.
        static let disclosureBlockHeader = ComponentMatrix.Supplement(
            component: "disclosure", id: "block-header", title: "a block's header",
            note: "The label is the product's button, a heading.small title and a date, not a ListRow: the style lays "
                + "the chevron's cell out after it, at the header's trailing edge, on the title's first baseline. "
                + "Expanded, two task rows under it.",
            keeps: [:], rowsPerPicture: 3, splitsAtEverySize: true
        ) { combination in
            let state = disclosureState(combination)
            DisclosureBlockHeader(isExpanded: .constant(true))
                .forcingDisclosureStates(state.map { [$0] } ?? [])
                .disabled(state?.isDisabled ?? false)
                .matrixCellTakesOfferedWidth()
        }

        /// A label that wraps, at accessibility5.
        static let disclosureLargeText = ComponentMatrix.Supplement(
            component: "disclosure", id: "accessibility5", title: "accessibility5: a label that wraps",
            note: "Drawn at accessibility5 whatever the sheet's text size: the label wraps over several lines and the "
                + "chevron stays on its first line, at the end; the cell stops growing at xxxLarge, where a ListRow's "
                + "structure stops.",
            keeps: [:], rowsPerPicture: 1, splitsAtEverySize: true, columnsPerPicture: 1
        ) { combination in
            let state = disclosureState(combination)
            DisclosureSample(title: "Groceries for the whole week", isExpanded: false)
                .forcingDisclosureStates(state.map { [$0] } ?? [])
                .disabled(state?.isDisabled ?? false)
                .dynamicTypeSize(.accessibility5)
                .matrixCellTakesOfferedWidth()
        }

        /// Every Disclosure supplement, in order.
        static let disclosureAll: [Self] = [
            .disclosureExpanded, .disclosureRightToLeft, .disclosureTree, .disclosureBlockHeader,
            .disclosureLargeText,
        ]
    }
#else
    extension ComponentMatrix.Supplement {
        /// None: Disclosure does not exist on watchOS.
        static let disclosureAll: [Self] = []
    }
#endif
