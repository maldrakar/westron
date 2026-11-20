import SwiftUI
import WestronUI

// Checkbox's catalog entry, from spec/components/checkbox/checkbox.spec.yaml: `checkbox`, every state of the contract
// on a task's title, live checks that toggle (a task, a subtask in a smaller text role, a task in a list's color),
// and the twelve list colors checked. The states come from the generated `CheckboxState` through
// `CheckboxCatalogState`, so the page follows the contract.

extension CatalogEntry {
    static let checkbox = CatalogEntry(id: "checkbox", title: "Checkbox", section: .components) {
        CheckboxPage()
    }

    /// Checks in the rows of a system `List`, as the pilot's task rows are, for what a row does with a check whose body
    /// is a `Button` (CheckboxBehaviorTests).
    static let checkboxInList = CatalogEntry(
        id: "checkbox-in-list", title: "Checkbox: in a List", section: .components
    ) {
        CheckboxListPage()
    }
}

/// Two task rows in a system `List`, each a check with no drawn label beside a separate title, and a row that says
/// which are on: what a tap on a title does, and whether the row highlights, are the List's.
private struct CheckboxListPage: View {
    @State private var first = false
    @State private var second = true

    var body: some View {
        List {
            row("Call the plumber", isOn: $first, id: CheckboxCatalogID.listFirst)
            row("Pay the rent", isOn: $second, id: CheckboxCatalogID.listSecond)
            Text(
                verbatim: "on: "
                    + ([("first", first), ("second", second)].filter(\.1).map(\.0).joined(separator: ", "))
            )
            .textRole(.footnote.regular)
            .foregroundStyle(.text.secondary)
            .accessibilityIdentifier(CheckboxCatalogID.listSummary)
        }
    }

    private func row(_ title: LocalizedStringKey, isOn: Binding<Bool>, id: String) -> some View {
        HStack(spacing: .space50) {
            Toggle(isOn: isOn, accessibilityLabel: title)
                .toggleStyle(.check)
                .accessibilityIdentifier(id)
            Text(title)
                .foregroundStyle(.text.primary)
                .accessibilityHidden(true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .textRole(CheckboxSampleRole.task)
    }
}

/// Accessibility identifiers of the live checks, which the catalog's UI tests (CheckboxBehaviorTests) toggle.
enum CheckboxCatalogID {
    /// A task's check in the accent, its label in body text, unchecked at launch.
    static let task = "checkbox.live.task"
    /// A subtask's check, its label in subheadline text, checked at launch.
    static let subtask = "checkbox.live.subtask"
    /// A task's check in the list color green, unchecked at launch.
    static let listColor = "checkbox.live.list-color"
    /// A task's check with no drawn label, beside a separate title, as in a row; unchecked at launch.
    static let row = "checkbox.live.row"
    /// The checks of the two rows of `checkbox-in-list`, and the row that says which are on: "on: second".
    static let listFirst = "checkbox.list.first"
    static let listSecond = "checkbox.list.second"
    static let listSummary = "checkbox.list.summary"
    /// The text that says which live checks are on: "on: subtask".
    static let summary = "checkbox.live.summary"
}

/// The text roles of the two kinds of row the pilot has: a task's title and a subtask's (P10).
enum CheckboxSampleRole {
    static let task: Westron.TextRole = .body.regular
    static let subtask: Westron.TextRole = .subheadline.regular
}

private struct CheckboxPage: View {
    @State private var task = false
    @State private var subtask = true
    @State private var listColor = false
    @State private var row = false

    var body: some View {
        TokenPage(
            title: "Checkbox",
            summary: "Toggle with .toggleStyle(.check): a ring in border.strong, checked a disc in the list's color, "
                + "the accent without one, with a check mark. The circle follows the text role set on the toggle, "
                + "and its hit area is at least size.target.minimum and size.control.m."
        ) {
            section("States") {
                // Each state alone, and each other state with the toggle on: a pressed or disabled done task.
                ForEach(CheckboxCatalogState.all.filter(\.isEntered), id: \.self) { state in
                    CheckboxSamples(spacing: .space200) {
                        stateSample(state, checked: state.isChecked)
                        if !state.isChecked {
                            stateSample(state, checked: true)
                        }
                    }
                }
            }
            section("Live") {
                Toggle("Write the report", isOn: $task)
                    .toggleStyle(.check)
                    .textRole(CheckboxSampleRole.task)
                    .accessibilityIdentifier(CheckboxCatalogID.task)
                Toggle("Outline the sections", isOn: $subtask)
                    .toggleStyle(.check)
                    .textRole(CheckboxSampleRole.subtask)
                    .accessibilityIdentifier(CheckboxCatalogID.subtask)
                Toggle("Water the plants", isOn: $listColor)
                    .toggleStyle(.check)
                    .textRole(CheckboxSampleRole.task)
                    .category(.green)
                    .accessibilityIdentifier(CheckboxCatalogID.listColor)
                // A row whose title is a separate text: the toggle draws no label and takes its name from
                // `accessibilityLabel:`, on every OS, and the title is not read a second time.
                HStack(spacing: .space50) {
                    Toggle(isOn: $row, accessibilityLabel: "Call the plumber")
                        .toggleStyle(.check)
                        .accessibilityIdentifier(CheckboxCatalogID.row)
                    Text("Call the plumber")
                        .accessibilityHidden(true)
                }
                .textRole(CheckboxSampleRole.task)
                Text(verbatim: summary)
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
                    .accessibilityIdentifier(CheckboxCatalogID.summary)
            }
            .foregroundStyle(.text.primary)
            section("List colors, checked") {
                CheckboxColors(isChecked: true, labelsShown: true)
            }
        }
    }

    /// A check in a state of the contract, labelled with it, and "checked" after it when the toggle is on.
    private func stateSample(_ state: CheckboxCatalogState, checked: Bool) -> some View {
        Toggle(isOn: .constant(checked)) {
            Text(verbatim: checked && !state.isChecked ? "\(state.name), checked" : state.name)
        }
        .toggleStyle(.check)
        .textRole(CheckboxSampleRole.task)
        .foregroundStyle(.text.primary)
        .forcingCheckboxStates(state.isForced ? [state] : [])
        .disabled(state.isDisabled)
    }

    /// Which live checks are on, for the UI tests.
    private var summary: String {
        let on = [("task", task), ("subtask", subtask), ("list color", listColor), ("row", row)].filter(\.1).map(\.0)
        return "on: " + (on.isEmpty ? "none" : on.joined(separator: ", "))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}

/// The twelve list colors, each a check in that color through `.category(_:)`, in two text roles: the first six with
/// a task's, the last six with a subtask's. With `labelsShown`, each check's label is its color's name; without, the
/// label is hidden with `.labelsHidden()` and stays the name. This is the catalog's one use of `.labelsHidden()`, on
/// the snapshot matrix's list-colors sheet, captured on iOS 26.3 and macOS 26, where a custom style sees it; a row
/// that must also draw no label on iOS 17, macOS 14 and watchOS 10 writes `Toggle(isOn:accessibilityLabel:)`.
struct CheckboxColors: View {
    let isChecked: Bool
    let labelsShown: Bool

    var body: some View {
        let all = Westron.Category.allCases
        VStack(alignment: .leading, spacing: 0) {
            line(all.prefix(6), role: CheckboxSampleRole.task)
            line(all.suffix(6), role: CheckboxSampleRole.subtask)
        }
        .foregroundStyle(.text.primary)
    }

    private func line(_ categories: ArraySlice<Westron.Category>, role: Westron.TextRole) -> some View {
        CheckboxSamples(spacing: labelsShown ? .space100 : 0, stacks: labelsShown) {
            ForEach(categories, id: \.self) { category in
                Toggle(category.rawValue, isOn: .constant(isChecked))
                    .toggleStyle(.check)
                    .category(category)
                    .modifier(LabelsHidden(isHidden: !labelsShown))
            }
        }
        .textRole(role)
    }
}

/// Samples side by side, wrapping onto as many lines as they need (`FlowLayout`), or, at the accessibility text sizes
/// with `stacks`, one under another: `FlowLayout` lays a sample out at its ideal width, so a label never wraps and a
/// long one would run past the screen (chapter 08: layout reflows, it never clips). The choice is eager, by the text
/// size, so the accessibility audit follows one layout.
private struct CheckboxSamples<Content: View>: View {
    let spacing: CGFloat
    var stacks = true
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if stacks && dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 0) { content }
        } else {
            FlowLayout(spacing: spacing) { content }
        }
    }
}

/// Hides a toggle's label, which stays its accessible name.
private struct LabelsHidden: ViewModifier {
    let isHidden: Bool

    func body(content: Content) -> some View {
        if isHidden { content.labelsHidden() } else { content }
    }
}

/// One cell of Checkbox's snapshot matrix (#24; `ComponentMatrix.checkbox`, generated from the contract): the real
/// check with a task's title, in the combination's state. checked is the toggle's own value; pressed and focus are
/// forced, as on the `checkbox` page; disabled is the real `.disabled(_:)`.
struct CheckboxMatrixCell: View {
    let values: CheckboxMatrixValues

    init(_ values: CheckboxMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here.
        let (variant, stateName) = values.fields
        let state = stateName.flatMap(CheckboxCatalogState.init(named:))
        Toggle("Buy milk", isOn: .constant(state?.isChecked ?? false))
            .toggleStyle(variant)
            .textRole(CheckboxSampleRole.task)
            .foregroundStyle(.text.primary)
            .forcingCheckboxStates(state.map { $0.isForced ? [$0] : [] } ?? [])
            .disabled(state?.isDisabled ?? false)
    }
}

extension ComponentMatrix.Supplement {
    /// The twelve list colors, in each state of the matrix (#72): the list's color comes from the context through
    /// `.category(_:)`, not from a contract option, so the generated sheets, drawn in the accent, do not show it.
    static let checkboxListColors = ComponentMatrix.Supplement(
        component: "checkbox", id: "list-colors", title: "the twelve list colors",
        note: "The color comes from .category(_:). Blue to olive in body.regular, amber to indigo in "
            + "subheadline.regular; no labels; growth stops at accessibility1.",
        // Two lines of six checks to a cell: at accessibility5 a picture of all five rows runs under the status bar
        // and to the screen's bottom edge on an iPhone 17, so it takes three rows at a time there.
        keeps: [:], rowsPerPicture: 3
    ) { combination in
        CheckboxSupplementCell(combination: combination) { isChecked in
            CheckboxColors(isChecked: isChecked, labelsShown: false)
        }
    }

    /// A task's check and a subtask's beside labels of their text roles, in each state of the matrix (#72): the circle
    /// is sized by the text role of its label, which is not a contract option.
    static let checkboxTextRoles = ComponentMatrix.Supplement(
        component: "checkbox", id: "text-roles", title: "two text roles",
        note: "The circle follows the text role of its label (P10): a task's, body.regular, and a subtask's, "
            + "subheadline.regular. The cells stop growing at accessibility1.",
        keeps: [:]
    ) { combination in
        CheckboxSupplementCell(combination: combination) { isChecked in
            HStack(spacing: .space200) {
                Toggle("Task", isOn: .constant(isChecked))
                    .toggleStyle(.check)
                    .textRole(CheckboxSampleRole.task)
                Toggle("Subtask", isOn: .constant(isChecked))
                    .toggleStyle(.check)
                    .textRole(CheckboxSampleRole.subtask)
            }
            .foregroundStyle(.text.primary)
        }
    }
}

/// A supplement's cell in the combination's state: checked from the content's own value, pressed and focus forced,
/// disabled real; its text size stops at accessibility1.
private struct CheckboxSupplementCell<Content: View>: View {
    let combination: ComponentMatrix.Combination
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        let state = combination.state.flatMap(CheckboxCatalogState.init(named:))
        content(state?.isChecked ?? false)
            .forcingCheckboxStates(state.map { $0.isForced ? [$0] : [] } ?? [])
            .disabled(state?.isDisabled ?? false)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            // One cell for the sheet's test, which counts the cells by their identifier.
            .accessibilityElement(children: .contain)
    }
}
