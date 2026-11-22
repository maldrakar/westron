import SwiftUI
import WestronUI

// Chip's catalog entry, from spec/components/chip/chip.spec.yaml: `chip`, its three forms in every state each enters
// (the contract's `forms`), a live tag bar of selectable chips and a pressable one, the twelve list colors lit, and a
// long label truncated in a narrow place. The states come from the generated `ChipState` through `ChipCatalogState`,
// so the page follows the contract.

extension CatalogEntry {
    static let chip = CatalogEntry(id: "chip", title: "Chip", section: .components) {
        ChipPage()
    }
}

/// Accessibility identifiers of the live chips, which the catalog's UI tests (ChipBehaviorTests) press.
enum ChipCatalogID {
    /// The tag bar's selectable chips: Work off and Home on at launch, and Errands in the list color green, off.
    static let work = "chip.live.work"
    static let home = "chip.live.home"
    static let errands = "chip.live.errands"
    /// A pressable chip, the day of a task's card; each press counts once.
    static let day = "chip.live.day"
    /// The text that says which selectable chips are on and how often the pressable one was pressed: "on: home;
    /// pressed: 0".
    static let summary = "chip.live.summary"
}

/// The sample words of the chips, a tag's name and a day's, as the pilot's tag bar and card pills show them.
enum ChipSample {
    static let tag = "Work"
    static let tagIcon: Westron.Icon = .hash
    static let day = "Tue"
    static let dayIcon: Westron.Icon = .sun
    static let long = "A tag whose name runs much longer than its chip"
    /// The width a long label is given, narrower than it: four of the widest space step.
    static let narrowWidth: CGFloat = 4 * .space800
}

private struct ChipPage: View {
    @State private var work = false
    @State private var home = true
    @State private var errands = false
    @State private var presses = 0

    var body: some View {
        TokenPage(
            title: "Chip",
            summary: "A capsule with a label and an optional icon in three forms: selectable, a Toggle with "
                + ".toggleStyle(.chip), lit in the list's color, the accent without one; pressable, a Button with "
                + ".buttonStyle(.chip); static, a Label with .labelStyle(.chip). Height size.control.s, a hit area "
                + "at least size.target.minimum high for the two controls; one line, truncated at its end."
        ) {
            section("Selectable, in each state") {
                // Each state alone, and each other state with the chip on: a lit chip under the pointer or pressed.
                ForEach(ChipCatalogState.all.filter { $0.isEntered && $0.isEntered(by: .selectable) }, id: \.self) {
                    state in
                    ChipSamples {
                        selectable(state, checked: state.isChecked)
                        if !state.isChecked {
                            selectable(state, checked: true)
                        }
                    }
                }
            }
            section("Pressable, in each state") {
                ChipSamples {
                    pressable(nil)
                    ForEach(ChipCatalogState.all.filter { $0.isEntered && $0.isEntered(by: .pressable) }, id: \.self) {
                        pressable($0)
                    }
                }
            }
            section("Static") {
                // Words of their own, so that the UI tests find each sample's name once.
                ChipSamples {
                    Label("Garden", icon: ChipSample.tagIcon)
                        .labelStyle(.chip)
                    Label("Groceries", icon: .hash)
                        .labelStyle(.chip)
                }
            }
            section("Live") {
                ChipSamples {
                    Toggle(isOn: $work) { Label(ChipSample.tag, icon: ChipSample.tagIcon) }
                        .toggleStyle(.chip)
                        .accessibilityIdentifier(ChipCatalogID.work)
                    Toggle(isOn: $home) { Label("Home", icon: .hash) }
                        .toggleStyle(.chip)
                        .accessibilityIdentifier(ChipCatalogID.home)
                    Toggle(isOn: $errands) { Label("Errands", icon: .hash) }
                        .toggleStyle(.chip)
                        .category(.green)
                        .accessibilityIdentifier(ChipCatalogID.errands)
                    Button {
                        presses += 1
                    } label: {
                        Label(ChipSample.day, icon: ChipSample.dayIcon)
                    }
                    .buttonStyle(.chip)
                    .accessibilityIdentifier(ChipCatalogID.day)
                }
                Text(verbatim: summary)
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
                    .accessibilityIdentifier(ChipCatalogID.summary)
            }
            section("List colors, lit") {
                ChipColors()
            }
            section("A long label, in a narrow place") {
                ChipLongLabels()
            }
        }
    }

    /// A selectable chip in a state of the contract, labelled with it, and "on" after it when the toggle is on.
    private func selectable(_ state: ChipCatalogState?, checked: Bool) -> some View {
        let name = state.map { checked && !$0.isChecked ? "\($0.name), on" : $0.name } ?? "rest"
        return Toggle(isOn: .constant(checked)) {
            Label {
                Text(verbatim: name)
            } icon: {
                Image(ChipSample.tagIcon)
            }
        }
        .toggleStyle(.chip)
        .forcingChipStates(state.map { $0.isForced ? [$0] : [] } ?? [])
        .disabled(state?.isDisabled ?? false)
    }

    /// A pressable chip in a state of the contract, labelled with it; nil: at rest.
    private func pressable(_ state: ChipCatalogState?) -> some View {
        Button {
        } label: {
            Label {
                Text(verbatim: state?.name ?? "rest")
            } icon: {
                Image(ChipSample.dayIcon)
            }
        }
        .buttonStyle(.chip)
        .forcingChipStates(state.map { $0.isForced ? [$0] : [] } ?? [])
        .disabled(state?.isDisabled ?? false)
    }

    /// Which live chips are on, and how often the pressable one was pressed, for the UI tests.
    private var summary: String {
        let on = [("work", work), ("home", home), ("errands", errands)].filter(\.1).map(\.0)
        return "on: " + (on.isEmpty ? "none" : on.joined(separator: ", ")) + "; pressed: \(presses)"
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

/// Lit selectable chips, each in a list color through `.category(_:)` and named after it; nil: the accent. By default the
/// accent and the twelve list colors.
struct ChipColors: View {
    var colors: [Westron.Category?] = [nil] + Westron.Category.allCases.map(Optional.some)
    /// With `inLines`, three chips to a line, so that a matrix cell has a width of its own; without, they wrap to the
    /// page's width.
    var inLines = false

    var body: some View {
        if inLines {
            VStack(alignment: .leading, spacing: .space75) {
                ForEach(Array(stride(from: 0, to: colors.count, by: 3)), id: \.self) { start in
                    HStack(spacing: .space75) {
                        ForEach(colors[start..<min(start + 3, colors.count)], id: \.self) { chip($0) }
                    }
                }
            }
        } else {
            ChipSamples {
                ForEach(colors, id: \.self) { chip($0) }
            }
        }
    }

    /// A lit chip in `category`, named after it; nil: the accent.
    private func chip(_ category: Westron.Category?) -> some View {
        Toggle(isOn: .constant(true)) { Label(category?.rawValue ?? "accent", icon: ChipSample.tagIcon) }
            .toggleStyle(.chip)
            .category(category)
    }
}

/// A long label in each form, each given less width than it needs: one line, truncated at its end, the whole label
/// still the accessible name.
struct ChipLongLabels: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .space100) {
            Toggle(isOn: .constant(true)) { Label(ChipSample.long, icon: ChipSample.tagIcon) }
                .toggleStyle(.chip)
                .frame(maxWidth: ChipSample.narrowWidth, alignment: .leading)
            Button {
            } label: {
                Label(ChipSample.long, icon: ChipSample.dayIcon)
            }
            .buttonStyle(.chip)
            .frame(maxWidth: ChipSample.narrowWidth, alignment: .leading)
            Label(ChipSample.long, icon: ChipSample.tagIcon)
                .labelStyle(.chip)
                .frame(maxWidth: ChipSample.narrowWidth, alignment: .leading)
        }
    }
}

/// Samples side by side, wrapping onto as many lines as they need, as a tag bar wraps in a narrow pane.
private struct ChipSamples<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        FlowLayout(spacing: .space75) { content }
    }
}

/// One cell of Chip's snapshot matrix (#24; `ComponentMatrix.chip`, generated from the contract): the real chip in its
/// form, a tag with its icon, in the combination's state. checked is the toggle's own value; hover, focus and pressed
/// are forced, as on the `chip` page; disabled is the real `.disabled(_:)`.
struct ChipMatrixCell: View {
    let values: ChipMatrixValues

    init(_ values: ChipMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here.
        let (form, variant, stateName) = values.fields
        let state = stateName.flatMap(ChipCatalogState.init(named:))
        ChipFormSample(form: form, variant: variant, checked: state?.isChecked ?? false) {
            Label(ChipSample.tag, icon: ChipSample.tagIcon)
        }
        .forcingChipStates(state.map { $0.isForced ? [$0] : [] } ?? [])
        .disabled(state?.isDisabled ?? false)
    }
}

/// A chip in one of its forms around a label: a constant Toggle, a Button that does nothing, or the label alone.
struct ChipFormSample<Content: View>: View {
    let form: ChipForm
    var variant: ChipVariant = .chip
    let checked: Bool
    @ViewBuilder let label: Content

    var body: some View {
        switch form {
        case .selectable:
            Toggle(isOn: .constant(checked)) { label }
                .toggleStyle(variant)
        case .pressable:
            Button {
            } label: {
                label
            }
            .buttonStyle(variant)
        case .static:
            label
                .labelStyle(variant)
        }
    }
}

extension ComponentMatrix.Supplement {
    /// A chip lit in the accent, in each state of the selectable form (#72): a lit chip under the pointer or pressed
    /// holds two states at once, which the generated sheets, each state alone, do not draw.
    static let chipLitAccent = ComponentMatrix.Supplement(
        component: "chip", id: "lit", title: "lit, in each state",
        note: "The chip is on, and in the row's state too: the accent fill darkens under the pointer and pressed "
            + "(accent-hover, accent-pressed), which the generated sheets, each state alone, do not draw.",
        keeps: ["form": "selectable"]
    ) { combination in
        ChipColorsCell(combination: combination, colors: [nil])
    }

    /// The twelve list colors, lit, in each state of the selectable form (#72), three to a sheet, so that a cell is one
    /// line on an iPhone too: the list's color comes from the context through `.category(_:)`, not from a contract
    /// option, so the generated sheets, drawn in the accent, do not show it.
    static let chipListColors: [Self] = stride(from: 0, to: Westron.Category.allCases.count, by: 3).map { start in
        let colors = Array(Westron.Category.allCases.dropFirst(start).prefix(3))
        return ComponentMatrix.Supplement(
            component: "chip", id: "list-colors-\(start / 3 + 1)",
            title: "lit, in the list colors " + colors.map(\.rawValue).joined(separator: ", "),
            note: listColorsNote, keeps: ["form": "selectable"]
        ) { combination in
            ChipColorsCell(combination: combination, colors: colors.map(Optional.some))
        }
    }

    private static let listColorsNote =
        "Every chip is on, and in the row's state too: a list's fill stays under the pointer and pressed "
        + "(decisions/0001, Q4). The color comes from .category(_:). Drawn at the default text size at most: how "
        + "the chip grows is the generated sheets'."

    /// A long label in each form and state, given less width than it needs (#72): the width is the container's, not a
    /// contract option.
    static let chipLongLabel = ComponentMatrix.Supplement(
        component: "chip", id: "long-label", title: "a long label in a narrow place",
        note: "The chip is given \(Int(ChipSample.narrowWidth)) pt, less than its label needs: one line, truncated at "
            + "its end with an ellipsis.",
        keeps: [:]
    ) { combination in
        let state = combination.state.flatMap(ChipCatalogState.init(named:))
        let form = ChipForm(rawValue: combination.values[0]) ?? .selectable
        ChipFormSample(form: form, checked: state?.isChecked ?? false) {
            Label(ChipSample.long, icon: ChipSample.tagIcon)
        }
        .frame(maxWidth: ChipSample.narrowWidth, alignment: .leading)
        .forcingChipStates(state.map { $0.isForced ? [$0] : [] } ?? [])
        .disabled(state?.isDisabled ?? false)
    }
}

/// A supplement's cell of lit chips in `colors`, in the combination's state: hover, focus and pressed forced, disabled
/// real; its text size stops at the default.
private struct ChipColorsCell: View {
    let combination: ComponentMatrix.Combination
    let colors: [Westron.Category?]

    var body: some View {
        let state = combination.state.flatMap(ChipCatalogState.init(named:))
        ChipColors(colors: colors, inLines: true)
            .forcingChipStates(state.map { $0.isForced ? [$0] : [] } ?? [])
            .disabled(state?.isDisabled ?? false)
            .dynamicTypeSize(...DynamicTypeSize.large)
    }
}
