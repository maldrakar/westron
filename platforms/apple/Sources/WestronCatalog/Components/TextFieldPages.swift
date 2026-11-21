import SwiftUI
import WestronUI

// TextField's catalog entries, from spec/components/text-field/text-field.spec.yaml: `text-field` (variants × sizes at
// rest on one line, empty with a placeholder and with text, then multiple lines and every state at size m), and three
// live pages with real fields:
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
/// and the color of its context, which a framed field does not take. On one line (`axis` horizontal, the contract's
/// `lines: single`) a list's name; on several (vertical, `multiple`) a list's notes, whose text wraps to two lines.
struct TextFieldSample: View {
    let variant: TextFieldVariant
    var size: TextFieldSize? = nil
    var axis: Axis = .horizontal
    @State private var text: String

    init(variant: TextFieldVariant, size: TextFieldSize? = nil, axis: Axis = .horizontal, filled: Bool) {
        self.variant = variant
        self.size = size
        self.axis = axis
        _text = State(initialValue: filled ? (axis == .vertical ? Self.filledNotes : Self.filledText) : "")
    }

    /// The text of a filled sample on one line; the prompt of an empty one is "Untitled".
    static let filledText = "Groceries"

    /// The text of a filled sample on several lines, two short ones, which stay two at the largest text size; the prompt
    /// of an empty one is "Add a note".
    static let filledNotes = "Milk\nApples"

    var body: some View {
        Group {
            if axis == .vertical {
                TextField("Notes", text: $text, prompt: Text("Add a note"), axis: .vertical)
                    .textFieldStyle(variant, size: size)
                    .accessibilityLabel("Notes")
                    .lineLimit(1...4)
                // No fixed size of its own: the style keeps a field's height (the contract's description).
            } else {
                TextField("List name", text: $text, prompt: Text("Untitled"))
                    .textFieldStyle(variant, size: size)
                    // The product names the field: with a prompt, the system field takes no accessibility label from
                    // its title (decisions/0001, I2). Every field in the catalog is named so.
                    .accessibilityLabel("List name")
            }
        }
        // The context of an inline field: body text in the primary color. A framed field sets its own.
        .textRole(.body.regular)
        .foregroundStyle(.text.primary)
    }
}

extension Axis {
    /// The field's axis for a value of the contract's `lines`, which is the system's axis on Apple (its
    /// `systemOptions`): `multiple` is vertical, `single` horizontal.
    init(textFieldLines lines: String) {
        self = lines == "multiple" ? .vertical : .horizontal
    }
}

/// One cell of TextField's snapshot matrix (#24; `ComponentMatrix.textField`, generated from the contract): the real
/// field with the combination's variant, size and lines, empty with its placeholder and with text, in the combination's
/// state.
/// Focus is forced, since only one field holds the keyboard focus (the live `text-field-focus-*` pages show the real
/// one); disabled is set with the real `.disabled(_:)`.
struct TextFieldMatrixCell: View {
    let values: TextFieldMatrixValues
    /// Whether the cell always holds both fields, as on the scrolling `text-field` entry; otherwise, as on a matrix
    /// sheet, which does not scroll, a multiline cell at the accessibility text sizes holds the two-line field alone.
    let whole: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ values: TextFieldMatrixValues, whole: Bool = false) {
        self.values = values
        self.whole = whole
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here.
        let (variant, size, lines, stateName) = values.fields
        let state = stateName.flatMap(TextFieldCatalogState.init(named:))
        let axis = Axis(textFieldLines: lines)
        // Apart by more than two forced rings reach outside their fields, so they do not touch.
        VStack(alignment: .leading, spacing: .space150) {
            // On a matrix sheet at the accessibility text sizes, three rows of multiline cells holding an empty field
            // and one of two lines are taller than an iPhone's screen, and the matrix splits a sheet's columns there,
            // not its rows. So there a multiline cell holds the two-line field alone, which fits; the empty one is on
            // the other text sizes' sheets and, at every text size, on the `text-field` entry, which the
            // accessibility audit walks.
            if whole || axis == .horizontal || !dynamicTypeSize.isAccessibilitySize {
                TextFieldSample(variant: variant, size: size, axis: axis, filled: false)
            }
            TextFieldSample(variant: variant, size: size, axis: axis, filled: true)
        }
        // Room for the ring, which is drawn outside the field's frame: forced, it touches neither the next cell nor
        // the picture's edge (the contract's platforms.apple).
        .padding(variant.focusRingClearance)
        .forcingTextFieldState(state)
    }
}

extension View {
    /// Puts the fields in this view in a state of the contract for the catalog: focus forced, disabled real.
    fileprivate func forcingTextFieldState(_ state: TextFieldCatalogState?) -> some View {
        forcingTextFieldStates(state.map { $0.isForced ? [$0] : [] } ?? [])
            .disabled(state?.isDisabled ?? false)
    }
}

extension ComponentMatrix.Supplement {
    /// A card's title and notes (the pilot's open task card): the title in `heading.small` and the notes, a multiline
    /// field, in a smaller role and the secondary color, on a raised surface.
    static let textFieldCardNotes = ComponentMatrix.Supplement(
        component: "text-field", id: "card-notes", title: "a card's one-line title and its notes",
        note: "The context of a field is not a contract option. Here, as in the pilot's open task card, the title, a "
            + "field of one line, is set in heading.small and the notes, a multiline field (lines multiple, axis: "
            + ".vertical), in subheadline.regular and text.secondary, on a raised surface: an inline field takes "
            + "them; a framed field keeps its own.",
        // The sheet's lines are the notes'; the title is always one line.
        keeps: ["size": "m", "lines": "multiple"],
        // A card with a title and two lines of notes is taller than a generated cell: at the largest text size one card
        // fills most of a picture, so a sheet is split into one picture per column and per row.
        rowsPerPicture: 1
    ) { combination in
        TextFieldCardSample(values: TextFieldMatrixValues(combination))
    }

    /// The same style on SecureField.
    static let textFieldSecure = ComponentMatrix.Supplement(
        component: "text-field", id: "secure-field", title: "SecureField",
        note: "SecureField takes the same .textFieldStyle(_:size:) as TextField (the contract's platforms.apple); the "
            + "kind of field is not a contract option. Each cell holds an empty field and one with a password; iOS "
            + "keeps a secure field's text out of screen captures, so there the second looks empty.",
        keeps: ["size": "m", "lines": "single"]
    ) { combination in
        TextFieldSecureSample(values: TextFieldMatrixValues(combination))
    }

    /// A field on the surface ground, for its fill's contrast; the generated sheets show it on the canvas. The ground is
    /// the bare fill, not `.surface(_:)`: the sheet is about the field against a colour, and `.surface(.raised)` would
    /// add its shadow and, in high contrast, its line.
    static let textFieldOnSurface = grounded(.background.surface, name: "surface")

    /// A field on the sunken ground, for its fill's contrast. `.surface(.sunken)` would draw this ground the same,
    /// with no shadow or line; it stays on `grounded(_:name:)` so the two sheets are drawn alike.
    static let textFieldOnSunken = grounded(.background.sunken, name: "sunken")

    private static func grounded(_ ground: Westron.Color, name: String) -> Self {
        ComponentMatrix.Supplement(
            component: "text-field", id: "on-\(name)", title: "on the \(name) ground",
            note: "The ground under a field is not a contract option. A framed field's muted fill stands about 1.16:1 "
                + "off the surface and 1.04:1 off the sunken ground in light, below 3:1, as the owner accepted "
                + "(decisions/0002); in high contrast its outline, border.strong, meets the target. The generated "
                + "sheets stand on the canvas ground.",
            keeps: ["size": "m", "lines": "single"]
        ) { combination in
            TextFieldGroundSample(values: TextFieldMatrixValues(combination), ground: ground)
        }
    }
}

/// A card, a raised surface, with an inline title and multiline notes, as a product writes them.
private struct TextFieldCardSample: View {
    let values: TextFieldMatrixValues
    @State private var title = "Buy groceries"
    /// Two lines, so the multiline field shows it grows, and short ones, so the card fits a sheet's row at the largest
    /// text size.
    @State private var notes = "Milk, bread\nApples"
    /// Whether the title holds the keyboard focus, which the sample keeps off (below).
    @FocusState private var titleFocused: Bool

    var body: some View {
        let (variant, size, _, stateName) = values.fields
        // Apart by more than two forced rings reach outside their fields, so they do not touch.
        VStack(alignment: .leading, spacing: .space150) {
            TextField("Title", text: $title, prompt: Text("Untitled"))
                .textFieldStyle(variant, size: size)
                .accessibilityLabel("Title")
                .textRole(.heading.small)
                .foregroundStyle(.text.primary)
                .focused($titleFocused)
            TextField("Notes", text: $notes, prompt: Text("Notes"), axis: .vertical)
                .textFieldStyle(variant, size: size)
                .accessibilityLabel("Notes")
                .lineLimit(1...4)
                // Neither field fixes its own height: a matrix sheet is laid out in the screen's height with no scroll
                // view, and the style keeps each field's height there (the contract's description), the title's one
                // line too, which a sheet once squeezed below its text.
                .textRole(.subheadline.regular)
                .foregroundStyle(.text.secondary)
        }
        .padding(.space150)
        // The card's ground as a product draws it, a raised surface (spec/components/surface): the surface fill, and
        // its shadow and, in the high-contrast themes, its line.
        .surface(.raised)
        .forcingTextFieldState(stateName.flatMap(TextFieldCatalogState.init(named:)))
        // On macOS the window the sheet opens in gave the first card's title the keyboard focus for real, its text
        // selected, in the rest row of every theme (the matrix of #85, since the style fixes a field's height). A
        // sheet shows each state as the matrix sets it, so the sample takes that focus away once it appears and once
        // more after the window settles.
        .task {
            titleFocused = false
            try? await Task.sleep(for: .milliseconds(300))
            titleFocused = false
        }
    }
}

/// A SecureField, empty with its prompt and with a password.
private struct TextFieldSecureSample: View {
    let values: TextFieldMatrixValues
    @State private var empty = ""
    @State private var password = "correct horse"

    var body: some View {
        let (variant, size, _, stateName) = values.fields
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
    }
}

/// A filled field on a ground.
private struct TextFieldGroundSample: View {
    let values: TextFieldMatrixValues
    let ground: Westron.Color

    var body: some View {
        let (variant, size, _, stateName) = values.fields
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
            summary: "Each size on one line, empty with its placeholder, then with text; multiple lines; each state "
                + "with text. framed is a capsule on one line and a rounded rectangle on several. inline takes the "
                + "context's role and color (here body.regular, text.primary). Focus is forced here."
        ) {
            SectionRow {
                ForEach(TextFieldSize.allCases, id: \.self) { size in
                    section("size \(size.rawValue)") {
                        VariantColumns { variant in
                            TextFieldMatrixCell(
                                TextFieldMatrixValues(variant: variant, size: size, lines: "single", state: nil))
                        }
                    }
                }
                section("multiple lines, size m") {
                    VariantColumns { variant in
                        // Both fields at every text size: the page scrolls, and the accessibility audit walks it.
                        TextFieldMatrixCell(
                            TextFieldMatrixValues(variant: variant, size: .m, lines: "multiple", state: nil),
                            whole: true)
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
    init(variant: TextFieldVariant, size: TextFieldSize, lines: String, state: String?) {
        self.init(ComponentMatrix.Combination([variant.rawValue, size.rawValue, lines], state: state))
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
                .surface(.raised)
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
