import SwiftUI
import WestronUI

// TextField's catalog entries, from spec/components/text-field/text-field.spec.yaml: `text-field` (variants × sizes at
// rest, empty with a placeholder and with text, then every state at size m), and three live pages with real fields:
// `text-field-behavior` (nothing focused; the UI tests tap and click around the fields), `text-field-focus-framed` and
// `text-field-focus-inline` (the field focused for real, to show westron's ring and no system ring). The variants,
// sizes and states come from the generated enums, so the pages follow the contract.

extension CatalogEntry {
    static let textField = CatalogEntry(id: "text-field", title: "TextField", section: .components) {
        TextFieldMatrixPage()
    }

    static let textFieldBehavior = CatalogEntry(
        id: "text-field-behavior", title: "TextField: live fields", section: .components
    ) {
        TextFieldLivePage(focusing: nil)
    }

    static let textFieldFocusFramed = CatalogEntry(
        id: "text-field-focus-framed", title: "TextField: framed, focused", section: .components
    ) {
        TextFieldLivePage(focusing: .framed)
    }

    static let textFieldFocusInline = CatalogEntry(
        id: "text-field-focus-inline", title: "TextField: inline, focused", section: .components
    ) {
        TextFieldLivePage(focusing: .inline)
    }
}

/// Accessibility identifiers of the live fields, which the catalog's UI tests (TextFieldBehaviorTests) tap and click.
enum TextFieldCatalogID {
    /// A framed field at size s, drawn lower than the platform's recommended target.
    static let small = "text-field.live.small"
    /// An inline field, a card's title.
    static let title = "text-field.live.title"
    /// A multiline inline field, a card's notes.
    static let notes = "text-field.live.notes"
    /// A framed SecureField.
    static let secure = "text-field.live.secure"
    /// The text that names the focused field: "Focused: small", "Focused: none".
    static let focused = "text-field.live.focused"
    /// The button that takes the focus away from every field.
    static let clearFocus = "text-field.live.clear-focus"
}

/// A sample field as a product writes it: a label that names what it holds, a prompt, and, for `inline`, the text role
/// and the color of its context, which a framed field does not take.
struct TextFieldSample: View {
    let variant: TextFieldVariant
    var size: TextFieldSize? = nil
    @State private var text: String

    init(variant: TextFieldVariant, size: TextFieldSize? = nil, filled: Bool) {
        self.variant = variant
        self.size = size
        _text = State(initialValue: filled ? Self.filledText : "")
    }

    /// The text of a filled sample; the prompt of an empty one is "Untitled".
    static let filledText = "Groceries"

    var body: some View {
        TextField("List name", text: $text, prompt: Text("Untitled"))
            .textFieldStyle(variant, size: size)
            // The product names the field: with a prompt, the system field takes no accessibility label from its
            // title (decisions/0001, I2). Every field in the catalog is named so.
            .accessibilityLabel("List name")
            // The context of an inline field: body text in the primary color. A framed field sets its own.
            .textRole(.body.regular)
            .foregroundStyle(.text.primary)
    }
}

/// One cell of TextField's snapshot matrix (#24; `ComponentMatrix.textField`, generated from the contract): the real
/// field with the combination's variant and size, empty with its placeholder and with text, in the combination's state.
/// Focus is forced, since only one field holds the keyboard focus (the live `text-field-focus-*` pages show the real
/// one); disabled is set with the real `.disabled(_:)`.
struct TextFieldMatrixCell: View {
    let values: TextFieldMatrixValues

    init(_ values: TextFieldMatrixValues) {
        self.values = values
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here.
        let (variant, size, stateName) = values.fields
        let state = stateName.flatMap(TextFieldCatalogState.init(named:))
        // Apart by more than two forced rings reach outside their fields, so they do not touch.
        VStack(alignment: .leading, spacing: .space150) {
            TextFieldSample(variant: variant, size: size, filled: false)
            TextFieldSample(variant: variant, size: size, filled: true)
        }
        // Room for the ring, which is drawn outside the field's frame: forced, it touches neither the next cell nor
        // the picture's edge (the contract's platforms.apple).
        .padding(variant.focusRingClearance)
        .forcingTextFieldState(state)
        .matrixCellContainer()
    }
}

extension View {
    /// Puts the fields in this view in a state of the contract for the catalog: focus forced, disabled real.
    fileprivate func forcingTextFieldState(_ state: TextFieldCatalogState?) -> some View {
        forcingTextFieldStates(state.map { $0.isForced ? [$0] : [] } ?? [])
            .disabled(state?.isDisabled ?? false)
    }

    /// Makes a matrix cell that holds several fields one accessibility element that contains them, so the sheet's
    /// identifier for the cell names the cell, not each field in it (SnapshotMatrixTests counts the cells by it).
    fileprivate func matrixCellContainer() -> some View {
        accessibilityElement(children: .contain)
    }
}

extension ComponentMatrix.Supplement {
    /// A card's title and notes (the pilot's open task card): the title in `heading.small` and the notes, a multiline
    /// field, in a smaller role and the secondary color, on the surface ground.
    static let textFieldCardNotes = ComponentMatrix.Supplement(
        component: "text-field", id: "card-notes", title: "a card's title and multiline notes",
        note: "The context of a field is not a contract option. Here, as in the pilot's open task card, the title is "
            + "set in heading.small and the notes, a multiline field (axis: .vertical), in subheadline.regular and "
            + "text.secondary, on the surface ground: an inline field takes them; a framed field keeps its own.",
        keeps: ["size": "m"],
        // A card with a title and two lines of notes is taller than a generated cell: at the largest text size two
        // rows of cards fill a picture, so a sheet is split into one picture per column and per two rows.
        rowsWhenSplit: 2
    ) { combination in
        TextFieldCardSample(values: TextFieldMatrixValues(combination))
    }

    /// The same style on SecureField.
    static let textFieldSecure = ComponentMatrix.Supplement(
        component: "text-field", id: "secure-field", title: "SecureField",
        note: "SecureField takes the same .textFieldStyle(_:size:) as TextField (the contract's platforms.apple); the "
            + "kind of field is not a contract option. Each cell holds an empty field and one with a password; iOS "
            + "keeps a secure field's text out of screen captures, so there the second looks empty.",
        keeps: ["size": "m"]
    ) { combination in
        TextFieldSecureSample(values: TextFieldMatrixValues(combination))
    }

    /// A field on the surface ground, for the outline's contrast; the generated sheets show it on the canvas.
    static let textFieldOnSurface = grounded(.background.surface, name: "surface")

    /// A field on the sunken ground, for the outline's contrast.
    static let textFieldOnSunken = grounded(.background.sunken, name: "sunken")

    private static func grounded(_ ground: Westron.Color, name: String) -> Self {
        ComponentMatrix.Supplement(
            component: "text-field", id: "on-\(name)", title: "on the \(name) ground",
            note: "The ground under a field is not a contract option. A framed field has no fill of its own, so the "
                + "ground shows through; its outline, border.strong, meets 3:1 against it. The generated sheets "
                + "stand on the canvas ground.",
            keeps: ["size": "m"]
        ) { combination in
            TextFieldGroundSample(values: TextFieldMatrixValues(combination), ground: ground)
        }
    }
}

/// A card on the surface ground with an inline title and multiline notes, as a product writes them.
private struct TextFieldCardSample: View {
    let values: TextFieldMatrixValues
    @State private var title = "Buy groceries"
    /// Two lines, so the multiline field shows it grows, and short ones, so the card fits a sheet's row at the largest
    /// text size.
    @State private var notes = "Milk, bread\nApples"

    var body: some View {
        let (variant, size, stateName) = values.fields
        // Apart by more than two forced rings reach outside their fields, so they do not touch.
        VStack(alignment: .leading, spacing: .space150) {
            TextField("Title", text: $title, prompt: Text("Untitled"))
                .textFieldStyle(variant, size: size)
                .accessibilityLabel("Title")
                .textRole(.heading.small)
                .foregroundStyle(.text.primary)
            TextField("Notes", text: $notes, prompt: Text("Notes"), axis: .vertical)
                .textFieldStyle(variant, size: size)
                .accessibilityLabel("Notes")
                .lineLimit(1...4)
                // A matrix sheet is laid out in the screen's height with no scroll view, and a field with a vertical
                // axis is the only view in it that can shrink: at the largest text sizes it took the missing height
                // and cut its second line. It keeps its height.
                .fixedSize(horizontal: false, vertical: true)
                .textRole(.subheadline.regular)
                .foregroundStyle(.text.secondary)
        }
        .padding(.space150)
        .background(.background.surface, in: RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
        .forcingTextFieldState(stateName.flatMap(TextFieldCatalogState.init(named:)))
        .matrixCellContainer()
    }
}

/// A SecureField, empty with its prompt and with a password.
private struct TextFieldSecureSample: View {
    let values: TextFieldMatrixValues
    @State private var empty = ""
    @State private var password = "correct horse"

    var body: some View {
        let (variant, size, stateName) = values.fields
        VStack(alignment: .leading, spacing: .space150) {
            SecureField("Password", text: $empty, prompt: Text("Required"))
                .textFieldStyle(variant, size: size)
                .accessibilityLabel("Password")
            SecureField("Password", text: $password, prompt: Text("Required"))
                .textFieldStyle(variant, size: size)
                .accessibilityLabel("Password")
        }
        .padding(variant.focusRingClearance)
        .textRole(.body.regular)
        .foregroundStyle(.text.primary)
        .forcingTextFieldState(stateName.flatMap(TextFieldCatalogState.init(named:)))
        .matrixCellContainer()
    }
}

/// A filled field on a ground.
private struct TextFieldGroundSample: View {
    let values: TextFieldMatrixValues
    let ground: Westron.Color

    var body: some View {
        let (variant, size, stateName) = values.fields
        TextFieldSample(variant: variant, size: size, filled: true)
            .padding(.space150)
            .background(ground, in: RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
            .forcingTextFieldState(stateName.flatMap(TextFieldCatalogState.init(named:)))
    }
}

/// Variants side by side, each column a variant; one under the other at accessibility text sizes, so a field keeps
/// the page's width (chapter 08: layout reflows, it never clips), and on macOS, where the sections stand side by side
/// in the catalog's wide window (`SectionRow`). The rows stand apart by more than a field's ring reaches above it
/// (`space.50`), so a forced ring does not cover a name.
private struct VariantColumns<Cell: View>: View {
    @ViewBuilder let cell: (TextFieldVariant) -> Cell
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var stacks: Bool {
        #if os(macOS)
            true
        #else
            dynamicTypeSize.isAccessibilitySize
        #endif
    }

    var body: some View {
        if stacks {
            VStack(alignment: .leading, spacing: .space150) {
                ForEach(TextFieldVariant.allCases, id: \.self) { variant in
                    VStack(alignment: .leading, spacing: .space150) {
                        TokenName(variant.rawValue)
                            // A short name: at its own size, not shrunk by the width a side-by-side row proposes.
                            .fixedSize()
                        cell(variant)
                    }
                }
            }
        } else {
            Grid(alignment: .topLeading, horizontalSpacing: .space200, verticalSpacing: .space150) {
                GridRow {
                    ForEach(TextFieldVariant.allCases, id: \.self) { TokenName($0.rawValue) }
                }
                GridRow {
                    ForEach(TextFieldVariant.allCases, id: \.self) { cell($0) }
                }
            }
        }
    }
}

/// Sections one under the other on a phone; side by side on macOS, whose catalog window is wide and short.
private struct SectionRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        #if os(macOS)
            HStack(alignment: .top, spacing: .space300) { content }
        #else
            VStack(alignment: .leading, spacing: SampleMetrics.pagePadding) { content }
        #endif
    }
}

/// Every variant at every size at rest, then every state of the contract at size m.
private struct TextFieldMatrixPage: View {
    var body: some View {
        TokenPage(
            title: "TextField",
            summary: "Each size empty with its placeholder, then with text; each state with text. inline takes the "
                + "context's role and color (here body.regular, text.primary). Focus is forced here."
        ) {
            SectionRow {
                ForEach(TextFieldSize.allCases, id: \.self) { size in
                    section("size \(size.rawValue)") {
                        VariantColumns { variant in
                            TextFieldMatrixCell(TextFieldMatrixValues(variant: variant, size: size, state: nil))
                        }
                    }
                }
            }
            SectionRow {
                ForEach(TextFieldCatalogState.all.filter(\.isEntered), id: \.self) { state in
                    section("\(state.name), size m") {
                        VariantColumns { variant in
                            TextFieldSample(variant: variant, size: .m, filled: true)
                                .forcingTextFieldState(state)
                        }
                    }
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space50) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}

extension TextFieldMatrixValues {
    /// A combination of the matrix, as its generated sheets name it.
    init(variant: TextFieldVariant, size: TextFieldSize, state: String?) {
        self.init(ComponentMatrix.Combination([variant.rawValue, size.rawValue], state: state))
    }
}

/// Live fields: a framed field at size s, a card's inline title and multiline notes, and a framed SecureField. With
/// `focusing`, the page focuses that field for real once it appears, as a product does with `.focused(_:)`, to show
/// westron's ring and that the system draws none.
private struct TextFieldLivePage: View {
    enum Field: String, Hashable {
        case small, title, notes, secure
    }

    /// The field to focus: `framed` focuses the size s field, `inline` the card's title.
    let focusing: TextFieldVariant?

    @State private var name = ""
    @State private var title = "Buy groceries"
    @State private var notes = "Milk, bread and apples"
    @State private var password = ""
    @FocusState private var focused: Field?

    var body: some View {
        TokenPage(
            title: "TextField · live",
            summary: "Real fields. A framed field at size s takes touches and clicks in the platform's target "
                + "around what it draws; a tap or a click on its padding focuses it."
        ) {
            VStack(alignment: .leading, spacing: .space200) {
                TextField("List name", text: $name, prompt: Text("Untitled"))
                    .textFieldStyle(.framed, size: .s)
                    .accessibilityLabel("List name")
                    .focused($focused, equals: .small)
                    .accessibilityIdentifier(TextFieldCatalogID.small)
                VStack(alignment: .leading, spacing: .space100) {
                    TextField("Title", text: $title, prompt: Text("Untitled"))
                        .textFieldStyle(.inline)
                        .accessibilityLabel("Title")
                        .textRole(.heading.small)
                        .foregroundStyle(.text.primary)
                        .focused($focused, equals: .title)
                        .accessibilityIdentifier(TextFieldCatalogID.title)
                    TextField("Notes", text: $notes, prompt: Text("Add notes"), axis: .vertical)
                        .textFieldStyle(.inline)
                        .accessibilityLabel("Notes")
                        .textRole(.subheadline.regular)
                        .foregroundStyle(.text.secondary)
                        .focused($focused, equals: .notes)
                        .accessibilityIdentifier(TextFieldCatalogID.notes)
                }
                .padding(.space.card)
                .background(.background.surface, in: RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
                SecureField("Password", text: $password, prompt: Text("Required"))
                    .textFieldStyle(.framed)
                    .accessibilityLabel("Password")
                    .focused($focused, equals: .secure)
                    .accessibilityIdentifier(TextFieldCatalogID.secure)
                HStack(spacing: .space200) {
                    Text("Focused: \(focused?.rawValue ?? "none")")
                        .textRole(.footnote.regular)
                        .foregroundStyle(.text.secondary)
                        .accessibilityIdentifier(TextFieldCatalogID.focused)
                    Button("Clear focus") { focused = nil }
                        .buttonStyle(.tertiary, size: .s)
                        .accessibilityIdentifier(TextFieldCatalogID.clearFocus)
                }
            }
            .textRole(.body.regular)
            .foregroundStyle(.text.primary)
        }
        .task {
            guard let focusing else { return }
            // Focus moves once the window holds the page.
            try? await Task.sleep(for: .milliseconds(300))
            focused = focusing == .framed ? .small : .title
        }
    }
}
