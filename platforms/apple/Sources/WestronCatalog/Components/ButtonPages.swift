import SwiftUI
import WestronUI

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

// Button's catalog entries, from spec/components/button/button.spec.yaml. The matrix is larger than one screen, so it
// is split into pages, each of which fits one screenshot on an iPhone 17 in portrait: `button` (variants × sizes ×
// label, icon and label, icon-only), `button-destructive` (the same in the destructive role), `button-states` (every
// state and the combinations the contract excludes), the same in the destructive role in two entries,
// `button-states-destructive` (the enabled rows) and `button-states-destructive-disabled` (the disabled rows),
// `button-behavior` (live buttons that count accepted presses, close neighbors and focus), and floating buttons over
// a busy ground, on glass and as before OS 26, in four entries at the end of this file: `button-floating` (live, over a
// pressable list, a group), `button-floating-sizes` (every size, over the stripes and the inverse band),
// `button-floating-states` (each state on glass) and `button-floating-before-26` (each state before OS 26, and
// loading). The variants, sizes and states come from the generated enums, so the pages follow the contract.

extension CatalogEntry {
    static let button = CatalogEntry(id: "button", title: "Button", section: .components) {
        ButtonMatrixPage(destructive: false)
    }

    static let buttonDestructive = CatalogEntry(
        id: "button-destructive", title: "Button: destructive role", section: .components
    ) {
        ButtonMatrixPage(destructive: true)
    }

    static let buttonStates = CatalogEntry(id: "button-states", title: "Button: states", section: .components) {
        ButtonStatesPage(destructive: false, rows: .all)
    }

    /// The destructive role's states are two entries: at accessibility5 the accessibility audit cannot finish a
    /// screenful that holds the disabled rows next to the others of this page (Button's decisions/0003, "Finding"),
    /// and finishes each half. Together they hold every row `button-states` holds.
    static let buttonStatesDestructive = CatalogEntry(
        id: "button-states-destructive", title: "Button: states, destructive role", section: .components
    ) {
        ButtonStatesPage(destructive: true, rows: .enabled)
    }

    static let buttonStatesDestructiveDisabled = CatalogEntry(
        id: "button-states-destructive-disabled", title: "Button: disabled states, destructive role",
        section: .components
    ) {
        ButtonStatesPage(destructive: true, rows: .disabled)
    }

    static let buttonBehavior = CatalogEntry(
        id: "button-behavior", title: "Button: presses, loading, neighbors", section: .components
    ) {
        ButtonBehaviorPage()
    }

    /// Floating buttons over content (#121) are four entries: at accessibility5 the accessibility audit could not
    /// finish one page that held them all ("Audit failed to complete in time" on four of its screens, its text-only
    /// first screen among them), and finishes each part. Together they hold every sample that page held. This one: the
    /// live buttons, the buttons over a pressable list and a group in the system's `GlassEffectContainer`, which the
    /// behavior tests press.
    static let buttonFloating = CatalogEntry(
        id: "button-floating", title: "Button: floating, over content", section: .components
    ) {
        ButtonFloatingPage(part: .live)
    }

    /// Floating buttons on glass at every size, over the stripes and over a band of the opposite tone, where the
    /// contract records that the label can read below 4.5:1 (decisions/0015, Q5).
    static let buttonFloatingSizes = CatalogEntry(
        id: "button-floating-sizes", title: "Button: floating, sizes on glass", section: .components
    ) {
        ButtonFloatingPage(part: .sizes)
    }

    /// Floating buttons on glass in each state but loading.
    static let buttonFloatingStates = CatalogEntry(
        id: "button-floating-states", title: "Button: floating, states on glass", section: .components
    ) {
        ButtonFloatingPage(part: .states)
    }

    /// Floating buttons as before OS 26 in each state, and loading, on glass and before OS 26.
    static let buttonFloatingBefore26 = CatalogEntry(
        id: "button-floating-before-26", title: "Button: floating, before OS 26 and loading", section: .components
    ) {
        ButtonFloatingPage(part: .before26)
    }
}

/// Accessibility identifiers of the live buttons, which the catalog's UI tests (ButtonBehaviorTests) press.
enum ButtonCatalogID {
    /// A primary button at rest.
    static let rest = "button.live.rest"
    /// A primary button, loading while `loadingToggle` is on (at launch), and the window's default action, Return.
    static let loading = "button.live.loading"
    /// The switch that puts `loading` in and out of loading.
    static let loadingToggle = "button.live.loading-toggle"
    /// A secondary button with a label and no icon, loading with Publish.
    static let loadingWithoutIcon = "button.live.loading-without-icon"
    /// The test control that presses `loading` and `loadingWithoutIcon` through the accessibility API.
    static let accessibilityPress = "button.live.accessibility-press"
    /// A secondary button, loading with Publish, whose ⌘E shortcut is dropped while it loads.
    static let export = "button.live.export"
    /// A secondary button at size s, drawn smaller than the recommended target.
    static let small = "button.live.small"
    /// A primary icon-only button with the checkmark, labelled "Save".
    static let iconOnly = "button.live.icon-only"
    /// Two size s icon-only buttons side by side, and the text that counts their presses: "first 1, second 0".
    static let firstNeighbor = "button.live.neighbor-first"
    static let secondNeighbor = "button.live.neighbor-second"
    static let neighbors = "button.live.neighbors"
    /// The text with the number of accepted presses: "Accepted presses: 3".
    static let count = "button.live.count"
}

/// Presses a view through the accessibility API, as VoiceOver, Switch Control and Voice Control do: the element with the
/// identifier, in the key window, gets `accessibilityPerformPress()` on macOS and `accessibilityActivate()` on iOS. The
/// elements exist while an assistive technology or a UI test is attached. Returns what happened: "pressed",
/// "refused" (the element reported the press as not performed) or "not found".
@MainActor
enum AccessibilityPress {
    static func press(identifier: String) -> String {
        #if os(macOS)
            for root in NSApplication.shared.windows.compactMap(\.contentView) {
                if let element = find(identifier, in: root) {
                    return element.accessibilityPerformPress?() == true ? "pressed" : "refused"
                }
            }
            return "not found"
        #elseif os(iOS)
            let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
            for window in windows {
                if let element = find(identifier, in: window) {
                    return element.accessibilityActivate() ? "pressed" : "refused"
                }
            }
            return "not found"
        #else
            return "not found"
        #endif
    }

    #if os(macOS)
        /// SwiftUI's accessibility elements answer NSAccessibility's methods without declaring the Swift protocol, so
        /// they are called by their Objective-C selectors.
        private static func find(_ identifier: String, in element: AnyObject, depth: Int = 0) -> AnyObject? {
            if element.accessibilityIdentifier?() == identifier { return element }
            guard depth < 60, let children = element.accessibilityChildren?() ?? nil else { return nil }
            for child in children {
                if let found = find(identifier, in: child as AnyObject, depth: depth + 1) { return found }
            }
            return nil
        }
    #elseif os(iOS)
        /// SwiftUI's accessibility elements are found through the views' `accessibilityElements` and the informal
        /// container methods, and asked for their identifier by its Objective-C selector.
        private static func find(_ identifier: String, in element: NSObject, depth: Int = 0) -> NSObject? {
            if (element as AnyObject).accessibilityIdentifier as String?? == identifier { return element }
            guard depth < 60 else { return nil }
            var children: [NSObject] = (element as? UIView)?.subviews ?? []
            children += (element.accessibilityElements as? [NSObject]) ?? []
            let count = element.accessibilityElementCount()
            if count != NSNotFound && count > 0 {
                children += (0..<count).compactMap { element.accessibilityElement(at: $0) as? NSObject }
            }
            for child in children {
                if let found = find(identifier, in: child, depth: depth + 1) { return found }
            }
            return nil
        }
    #endif
}

/// The two words and icons the pages use, by role.
///
/// The destructive samples use `xmarkCircleFill`: the owner's choice of 2026-11-17.
///
/// A known issue (#23, recorded in decisions/0001 of the Button contract): with `trash`, at accessibility5, on the
/// screenful of size m and l samples of the `button-destructive` page, `performAccessibilityAudit` gives up ("Audit
/// failed to complete in time") on every run on iPhone 17 Pro, iOS 26.3, while the catalog idles, whatever the
/// icon-only button's accessibility is built from (the system's icon-only label, a separate name with or without its
/// own size, a representation, a masked glyph), on the code before and after the icon-only changes (3d5208a). With any
/// other glyph the page passes. The cause is not found; a product's icon-only trash button may hit the same.
private struct ButtonSample {
    let title: LocalizedStringKey
    let icon: Westron.Icon

    init(destructive: Bool) {
        title = destructive ? "Delete" : "Save"
        icon = destructive ? .xmarkCircleFill : .check
    }
}

/// One sample button: a label, an icon and a label, or icon-only.
private struct SampleButton: View {
    enum Kind: CaseIterable {
        case label, iconAndLabel, iconOnly

        var title: String {
            switch self {
            case .label: "label"
            case .iconAndLabel: "icon + label"
            case .iconOnly: "icon-only"
            }
        }
    }

    let kind: Kind
    let variant: ButtonVariant
    var size: ButtonSize? = nil
    let destructive: Bool
    var floating = false
    var action: () -> Void = {}

    var body: some View {
        let sample = ButtonSample(destructive: destructive)
        Group {
            switch kind {
            case .label:
                Button(sample.title, role: destructive ? .destructive : nil, action: action)
                    .buttonStyle(variant, size: size, floating: floating)
            case .iconAndLabel:
                Button(role: destructive ? .destructive : nil, action: action) {
                    Label(sample.title, icon: sample.icon)
                }
                .buttonStyle(variant, size: size, floating: floating)
            case .iconOnly:
                Button(role: destructive ? .destructive : nil, action: action) {
                    Label(sample.title, icon: sample.icon)
                }
                .buttonStyle(variant, size: size, iconOnly: true, floating: floating)
            }
        }
    }
}

/// One cell of Button's snapshot matrix (#24; `ComponentMatrix.button`, generated from the contract): the real button
/// with the combination's variant, size, role and iconOnly, an icon and a label, in the combination's state. Hover,
/// focus and pressed are forced, as on the `button-states` pages; disabled and loading are set with the real
/// `.disabled(_:)` and `.loading(_:)`. With `withoutIcon`, for the supplementary sheets, the label has no icon.
///
/// A floating cell draws what the bindings say, the look where there is no glass, on every OS: the system's glass is
/// not the same pixel for pixel from one render to the next, and the generated sheets are the contract's. The glass
/// supplements draw it on glass (`onGlass`, decisions/0015).
struct ButtonMatrixCell: View {
    let values: ButtonMatrixValues
    let withoutIcon: Bool
    let onGlass: Bool

    init(_ values: ButtonMatrixValues, withoutIcon: Bool = false, onGlass: Bool = false) {
        self.values = values
        self.withoutIcon = withoutIcon
        self.onGlass = onGlass
    }

    var body: some View {
        // Every option at once: an option added to the contract changes `fields` and fails the build here.
        let (variant, size, role, iconOnly, floating, stateName) = values.fields
        let state = stateName.flatMap(ButtonCatalogState.init(named:))
        SampleButton(
            kind: iconOnly ? .iconOnly : withoutIcon ? .label : .iconAndLabel, variant: variant, size: size,
            // The style draws any role other than destructive as default (the contract's platforms.apple).
            destructive: role == "destructive", floating: floating
        )
        .forcingButtonStates(state.map { $0.isForced ? [$0] : [] } ?? [])
        .disabled(state?.isDisabled ?? false)
        .loading(state?.isLoading ?? false)
        .drawingButtonsWithoutGlass(!onGlass)
    }
}

extension ComponentMatrix.Supplement {
    /// Button's label without an icon, on the matrix's sheets that are not icon-only: every variant, size and role, at
    /// rest and in each state (#72). The contract has no option for it, so the generated matrix, whose cells have an
    /// icon and a label, does not show what the contract's description says of it: while loading, the indicator goes
    /// before the label and the button widens (P13).
    static let buttonLabelWithoutIcon = ComponentMatrix.Supplement(
        component: "button", id: "label-without-icon", title: "label without an icon",
        note: "A label without an icon is not a contract option, so the generated sheets, whose buttons have an icon "
            + "and a label, do not show it. While loading, the indicator goes before the label and the button widens "
            + "(the contract's description, P13).",
        keeps: ["iconOnly": "false"]
    ) { ButtonMatrixCell(ButtonMatrixValues($0), withoutIcon: true) }
}

/// Variants × sizes × the three kinds of label, in one role.
private struct ButtonMatrixPage: View {
    let destructive: Bool

    var body: some View {
        TokenPage(
            title: destructive ? "Button · destructive role" : "Button",
            summary: (destructive
                ? "Button(role: .destructive) recolors every variant in the danger colors. "
                : "Every variant at every size, at rest. ")
                + "Capsules; secondary is filled with background.muted, outlined only in high contrast. The height is "
                + "size.control.* and a minimum; the hit area is at least size.target.minimum, "
                + "except size s on macOS, which takes clicks in what it draws."
        ) {
            ForEach(ButtonSize.allCases, id: \.self) { size in
                VStack(alignment: .leading, spacing: SampleMetrics.rowSpacing) {
                    Text("size \(size.rawValue)")
                        .textRole(.subheadline.strong)
                        .foregroundStyle(.text.primary)
                    SampleRows(items: ButtonVariant.allCases, name: \.rawValue, wrapsCells: true) { variant in
                        ForEach(SampleButton.Kind.allCases, id: \.self) { kind in
                            SampleButton(kind: kind, variant: variant, size: size, destructive: destructive)
                        }
                    }
                }
            }
        }
    }
}

/// Rows of samples, each with its name: a grid with the names in the first column, or, at accessibility text sizes,
/// each name above its samples, which wrap onto as many lines as they need (`FlowLayout`). A grid column would squeeze
/// a button until its label breaks between letters (chapter 08: layout reflows, it never clips). The choice is eager,
/// by the text size, so the accessibility audit follows one layout. With `wrapsCells`, the grid's second column is
/// the row's samples in a `FlowLayout` that takes the width left after the names, so a row wider than the page goes
/// on to a second line instead of squeezing a button; without it, each sample is a column of its own, aligned.
private struct SampleRows<Item: Hashable, Cells: View>: View {
    let items: [Item]
    let name: (Item) -> String
    /// Names in the face of token names (variants), or of details (states).
    let monospaced: Bool
    /// Whether a row's samples wrap in one column rather than take a column each.
    let wrapsCells: Bool
    @ViewBuilder let cells: (Item) -> Cells

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        items: [Item], name: @escaping (Item) -> String, monospaced: Bool = true, wrapsCells: Bool = false,
        @ViewBuilder cells: @escaping (Item) -> Cells
    ) {
        self.items = items
        self.name = name
        self.monospaced = monospaced
        self.wrapsCells = wrapsCells
        self.cells = cells
    }

    @ViewBuilder private func label(_ item: Item) -> some View {
        if monospaced { TokenName(name(item)) } else { TokenDetail(name(item)) }
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: .space100) {
                ForEach(items, id: \.self) { item in
                    label(item)
                    FlowLayout(spacing: .space100) { cells(item) }
                }
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: .space100) {
                ForEach(items, id: \.self) { item in
                    GridRow {
                        label(item)
                        if wrapsCells {
                            FlowLayout(spacing: .space100) { cells(item) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            cells(item)
                        }
                    }
                }
            }
        }
    }
}

/// Places its subviews left to right at their ideal sizes, and starts a new line when the next one does not fit.
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = lines(subviews, width: proposal.width ?? .infinity)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: width, height: height)
    }

    /// A subview's ideal size, or, where that is wider than the layout, its size at the layout's width: a button wider
    /// than the page wraps its label between words instead of running off the page (Button's contract).
    private func size(_ subview: LayoutSubview, width: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard ideal.width > width, width.isFinite else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in line.indices {
                let size = size(subviews[index], width: bounds.width)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + line.height / 2), anchor: .leading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + spacing
        }
    }

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(_ subviews: Subviews, width: CGFloat) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let size = size(subviews[index], width: width)
            let needed = line.indices.isEmpty ? size.width : line.width + spacing + size.width
            if !line.indices.isEmpty && needed > width {
                lines.append(line)
                line = Line()
            }
            line.width = line.indices.isEmpty ? size.width : line.width + spacing + size.width
            line.height = max(line.height, size.height)
            line.indices.append(index)
        }
        if !line.indices.isEmpty { lines.append(line) }
        return lines
    }
}

/// Every state of the contract alone, and disabled and loading combined with a forced hover and pressed, which they
/// exclude: those rows must look as disabled and loading alone.
private struct ButtonStatesPage: View {
    /// Which rows a page shows.
    enum Rows {
        case all
        /// The rows where the button is enabled.
        case enabled
        /// The rows where the button is disabled, alone or with a state it excludes.
        case disabled
    }

    let destructive: Bool
    let rows: Rows

    /// A row of the matrix: the states it shows, forced or real, on buttons with an icon and a label, a label alone or
    /// icon-only.
    private struct Row: Hashable {
        let states: [ButtonCatalogState]
        var kind = SampleButton.Kind.iconAndLabel
        var name: String {
            let kindName =
                switch kind {
                case .iconAndLabel: ""
                case .label: ", no icon"
                case .iconOnly: ", icon-only"
                }
            return (states.isEmpty ? "rest" : states.map(\.name).joined(separator: " + ")) + kindName
        }
    }

    /// Rest, each state alone, then each state that excludes hover and pressed combined with each of them; last,
    /// loading on a label without an icon, where the indicator goes before the label and the button widens (P13), and
    /// on icon-only buttons, where the indicator replaces the icon.
    private static var allRows: [Row] {
        let entered = ButtonCatalogState.all.filter(\.isEntered)
        let excluding = entered.filter(\.excludesTint)
        let excluded = entered.filter(\.isTint)
        return [Row(states: [])] + entered.map { Row(states: [$0]) }
            + excluding.flatMap { state in excluded.map { Row(states: [state, $0]) } }
            + [.label, .iconOnly].map { Row(states: entered.filter(\.isLoading), kind: $0) }
    }

    var body: some View {
        TokenPage(
            title: title,
            summary: summary
        ) {
            // The row's buttons wrap rather than squeeze: with the padding of #85, three "Delete" buttons of size s
            // and the longest name are wider than a phone, and a squeezed label breaks inside its word.
            SampleRows(items: shownRows, name: \.name, monospaced: false, wrapsCells: true) { row in
                ForEach(ButtonVariant.allCases, id: \.self) { variant in
                    cell(row, variant: variant)
                }
            }
        }
    }

    /// What the page shows: the disabled rows alone say so, since they show no focus or loading.
    private var summary: String {
        switch rows {
        case .disabled:
            "Disabled is real; hover and pressed are forced on it, and disabled excludes them, so every row keeps the "
                + "resting fill at opacity.disabled. The enabled rows are on button-states-destructive."
        case .all, .enabled:
            "Hover, pressed and focus are forced for the screenshot; disabled and loading are real. "
                + "Disabled and loading exclude hover and pressed. The system draws focus, so its row looks at rest."
        }
    }

    private var shownRows: [Row] {
        switch rows {
        case .all: Self.allRows
        case .enabled: Self.allRows.filter { !$0.states.contains(where: \.isDisabled) }
        case .disabled: Self.allRows.filter { $0.states.contains(where: \.isDisabled) }
        }
    }

    private var title: String {
        switch (destructive, rows) {
        case (false, _): "Button · states"
        case (true, .disabled): "Button · disabled states, destructive"
        case (true, _): "Button · states, destructive"
        }
    }

    private func cell(_ row: Row, variant: ButtonVariant) -> some View {
        // Size s: the states' colors do not depend on the size, and it is the narrowest.
        SampleButton(kind: row.kind, variant: variant, size: .s, destructive: destructive)
            .forcingButtonStates(Set(row.states.filter(\.isForced)))
            .disabled(row.states.contains(where: \.isDisabled))
            .loading(row.states.contains(where: \.isLoading))
    }
}

/// Live buttons that count the presses they accept, close neighbors and, on macOS, focus. Growth with the text size is
/// on the `button` entry at accessibility sizes (a size pinned in the page would not follow the system's).
private struct ButtonBehaviorPage: View {
    @State private var accepted = 0
    @State private var isPublishing = true
    @State private var neighborPresses = (first: 0, second: 0)
    /// What the last accessibility press did, for the UI test: "" before any, then `AccessibilityPress`'s report.
    @State private var accessibilityPress = ""
    @FocusState private var isFocused: Bool
    @FocusState private var isLargeFocused: Bool

    var body: some View {
        TokenPage(
            title: "Button · behavior",
            summary: "A loading button refuses a touch, a click, assistive technology and a keyboard shortcut set "
                + "outside .loading(_:), and is neither dimmed nor announced as unavailable. Export drops its own "
                + "shortcut while loading, as a product may (#23)."
        ) {
            section("Presses") {
                Text("Accepted presses: \(accepted)")
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                    .accessibilityIdentifier(ButtonCatalogID.count)
                // Above the buttons, not below them: ButtonBehaviorTests taps 8 pt below "Add", and a control closer
                // than about 16 pt to a button shares the system's touch tolerance with it (#102).
                FlowLayout(spacing: .space200) {
                    // Its ideal width, and no wider than the page: at accessibility sizes its label wraps.
                    Toggle("Loading: Publish, Publish now, Export", isOn: $isPublishing)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(ButtonCatalogID.loadingToggle)
                    // A test control: it presses Publish as assistive technology does.
                    Button("Press Publish via accessibility") {
                        accessibilityPress = [ButtonCatalogID.loading, ButtonCatalogID.loadingWithoutIcon]
                            .map { AccessibilityPress.press(identifier: $0) }.joined(separator: ", ")
                    }
                    .buttonStyle(.tertiary)
                    .accessibilityIdentifier(ButtonCatalogID.accessibilityPress)
                    .accessibilityValue(accessibilityPress)
                }
                .textRole(.footnote.regular)
                .foregroundStyle(.text.secondary)
                FlowLayout(spacing: .space200) {
                    Button("Save") { accepted += 1 }
                        .buttonStyle(.primary)
                        .accessibilityIdentifier(ButtonCatalogID.rest)
                    // A label without an icon: while loading, the indicator goes before the whole label and the
                    // button widens (P13).
                    Button("Publish now") { accepted += 1 }
                        .buttonStyle(.secondary)
                        .loading(isPublishing)
                        .accessibilityIdentifier(ButtonCatalogID.loadingWithoutIcon)
                    Button {
                        accepted += 1
                    } label: {
                        Label("Publish", icon: .check)
                    }
                    .buttonStyle(.primary)
                    .loading(isPublishing)
                    #if !os(watchOS)
                        .keyboardShortcut(.defaultAction)
                    #endif
                    .accessibilityIdentifier(ButtonCatalogID.loading)
                    Button {
                        accepted += 1
                    } label: {
                        Label("Export", icon: .expand)
                    }
                    .buttonStyle(.secondary)
                    .loading(isPublishing)
                    #if !os(watchOS)
                        // A product that drops the shortcut itself while loading.
                        .keyboardShortcut(isPublishing ? nil : KeyboardShortcut("e", modifiers: .command))
                    #endif
                    .accessibilityIdentifier(ButtonCatalogID.export)
                    Button {
                        accepted += 1
                    } label: {
                        Label("Save", icon: .check)
                    }
                    .buttonStyle(.primary, iconOnly: true)
                    .accessibilityIdentifier(ButtonCatalogID.iconOnly)
                    // Last, so that it is on the flow's last line and no control lies within 16 pt of the tap 8 pt
                    // below it: below are the next section's title and, off to the side, its buttons (#102).
                    Button {
                        accepted += 1
                    } label: {
                        Label("Add", icon: .plus)
                    }
                    .buttonStyle(.secondary, size: .s)
                    .accessibilityIdentifier(ButtonCatalogID.small)
                }
            }
            section("Close neighbors: two size s icon-only buttons \(Int(CGFloat.space100)) pt apart") {
                HStack(spacing: .space100) {
                    Button {
                        neighborPresses.first += 1
                    } label: {
                        Label("First", icon: .plus)
                    }
                    .buttonStyle(.secondary, size: .s, iconOnly: true)
                    .accessibilityIdentifier(ButtonCatalogID.firstNeighbor)
                    Button {
                        neighborPresses.second += 1
                    } label: {
                        Label("Second", icon: .plus)
                    }
                    .buttonStyle(.secondary, size: .s, iconOnly: true)
                    .accessibilityIdentifier(ButtonCatalogID.secondNeighbor)
                    Text("first \(neighborPresses.first), second \(neighborPresses.second)")
                        .textRole(.footnote.regular)
                        .foregroundStyle(.text.secondary)
                        .accessibilityIdentifier(ButtonCatalogID.neighbors)
                }
            }
            #if os(macOS)
                section("Focus: the system's ring") {
                    // A button takes keyboard focus on a Mac only with the system's keyboard navigation on; the
                    // catalog makes this one focusable and focuses it, to show the ring the system draws.
                    HStack(spacing: .space200) {
                        Button("Focused") {}
                            .buttonStyle(.secondary)
                            .focusable()
                            .focused($isFocused)
                        Button("Focused") {}
                            .buttonStyle(.primary, size: .l)
                            .focusable()
                            .focused($isLargeFocused)
                    }
                    .onAppear { isFocused = true }
                }
            #endif
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}

// MARK: - Floating
//
// Button's floating look (#121, decisions/0015 at the repository's root). The generated sheets draw a floating button
// as the bindings say, the look where there is no glass, on every OS (`ButtonMatrixCell`), so they are the same on
// every run; the system's glass is only on these supplements and on the floating entries' pages, over content:
// a busy ground of stripes, and an inverse band, dark in the light theme and light in the dark one (Q5's test, and on
// the catalog page the contract's recorded limitation: a label on glass over content of the opposite tone).

/// Accessibility identifiers and words of the floating samples. The accessibility audit reports a button's text, which
/// carries no identifier, so the samples with a label are told apart by their words (CatalogAccessibilityAuditTests):
/// "Edit" is a secondary on glass, over the stripes; "Open" a secondary on glass over the inverse band, the contract's
/// recorded limitation (decisions/0015, Q5); a secondary
/// before OS 26 says the name of the state it is in ("Rest", "Pressed", …); a primary says "New", or "Delete" with the
/// destructive role.
enum ButtonFloatingID {
    /// The live buttons: a floating secondary "Back" and "More", icon-only, on glass; a floating primary "Add",
    /// icon-only; a disabled floating secondary "Share", icon-only, on glass.
    static let back = "button.floating.live.back"
    static let more = "button.floating.live.more"
    static let add = "button.floating.live.add"
    static let disabled = "button.floating.live.disabled"
    /// The text with the number of accepted presses: "Accepted presses: 3".
    static let count = "button.floating.live.count"
    /// Floating secondaries on glass over a pressable list, by size, `button.floating.over-list.m`.
    static func overList(_ size: ButtonSize) -> String { "button.floating.over-list.\(size.rawValue)" }
    /// The middle row of that list, under the floating buttons.
    static let overListRow = "button.floating.over-list.row"
    /// "Rows: 1, floating: 2", the presses each took.
    static let overListCount = "button.floating.over-list.count"
}

/// What a floating sample stands over: a busy ground of stripes, or the inverse band of Q5's test.
enum FloatingGroundKind: Sendable {
    /// Diagonal stripes in four list colors' fills.
    case stripes
    /// `text.primary`'s color: dark in the light themes, light in the dark ones, the ground that makes glass turn
    /// against its label: content of the tone opposite to the theme, where the contract records that the label can read
    /// below 4.5:1 (decisions/0015, Q5).
    case inverse
}

/// A fixed ground for floating buttons, which follows the theme. No images and no randomness, so a capture is the
/// same each time. Decorative.
struct FloatingGround: View {
    var kind = FloatingGroundKind.stripes

    var body: some View {
        Group {
            switch kind {
            case .stripes: stripes
            case .inverse: Rectangle().fill(.text.primary)
            }
        }
        .accessibilityHidden(true)
    }

    private var stripes: some View {
        Canvas { context, size in
            let colors: [Westron.Color] = [
                Westron.Category.orange.fill, Westron.Category.blue.fill, Westron.Category.green.fill,
                Westron.Category.violet.fill,
            ]
            let width = CGFloat.space150
            var x = -size.height
            var index = 0
            while x < size.width {
                var stripe = Path()
                stripe.move(to: CGPoint(x: x, y: size.height))
                stripe.addLine(to: CGPoint(x: x + size.height, y: 0))
                stripe.addLine(to: CGPoint(x: x + size.height + width, y: 0))
                stripe.addLine(to: CGPoint(x: x + width, y: size.height))
                stripe.closeSubpath()
                context.fill(stripe, with: .color(Color(colors[index % colors.count])))
                x += width
                index += 1
            }
        }
    }
}

/// Its content padded on a floating ground, in a card's corners.
private struct FloatingPanel<Content: View>: View {
    var ground = FloatingGroundKind.stripes
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.space200)
            .background { FloatingGround(kind: ground) }
            .clipShape(RoundedRectangle(cornerRadius: .radius.card, style: .continuous))
    }
}

/// One cell of Button's glass supplements: the matrix's cell on the system's glass, over a ground.
struct ButtonFloatingCell: View {
    let values: ButtonMatrixValues
    let ground: FloatingGroundKind

    var body: some View {
        FloatingPanel(ground: ground) {
            ButtonMatrixCell(values, onGlass: true)
        }
    }
}

extension ComponentMatrix.Supplement {
    /// Floating buttons on the system's glass over the busy ground, every size, label and icon-only, at rest and in
    /// each state (#121).
    static let buttonFloatingOnGlass = ComponentMatrix.Supplement(
        component: "button", id: "floating-on-glass", title: "floating, on glass over stripes",
        note: "The OS's glass and what a floating button stands over are not contract options: the generated sheets "
            + "draw the bindings, the look before OS 26, on every OS. Here a floating secondary stands on the "
            + "system's glass, regular, with no fill, outline, shadow or press scale of westron's, over a fixed busy "
            + "ground of four list colors' stripes; hover and pressed are the glass's own response to a pointer or a "
            + "touch, which a forced state does not show. A floating primary keeps its fill and casts shadow.overlay "
            + "(decisions/0015).",
        keeps: ["floating": "true", "role": "default"], columns: ["primary", "secondary"], rowsPerPicture: 3,
        splitsAtEverySize: true, notCompared: .glassOnIOS
    ) { ButtonFloatingCell(values: ButtonMatrixValues($0), ground: .stripes) }

    /// The same over the inverse band, Q5's test of the label's color on glass (#121).
    static let buttonFloatingOnGlassInverse = ComponentMatrix.Supplement(
        component: "button", id: "floating-on-glass-inverse", title: "floating, on glass over an inverse band",
        note: "Q5's test (decisions/0015): the glass over a band of text.primary's color, dark in the light themes and "
            + "light in the dark ones, where the glass turns against the label's color, which stays text.primary.",
        keeps: ["floating": "true", "role": "default"], columns: ["primary", "secondary"], rowsPerPicture: 3,
        splitsAtEverySize: true, notCompared: .glassOnIOS
    ) { ButtonFloatingCell(values: ButtonMatrixValues($0), ground: .inverse) }
}

extension ComponentMatrix.Supplement.NotCompared {
    /// The two glass supplements on iOS: drawn and shown for the review, not compared pixel by pixel (decisions/0015,
    /// the note of 2026-11-24). macOS draws the same glass the same every time, so it compares them.
    static let glassOnIOS = Self(
        on: ["ios"],
        reason: "the system's glass on the iOS simulator is not the same from one render to the next: on the CI "
            + "runner's iOS 27, two renders of one commit differed by up to 5 levels over thousands of pixels "
            + "(decisions/0015, the note of 2026-11-24). Checked for presence and size only; on macOS these sheets are "
            + "compared, and ButtonFloatingPixelTests measures the button on glass there.")
}

extension ComponentMatrix.SheetNote {
    /// Button's generated floating sheets draw the bindings, the look where there is no glass, on every OS (#121).
    static let buttonFloatingWithoutGlass = ComponentMatrix.SheetNote(
        component: "button", option: "floating", value: "true",
        text: "A floating button here is drawn as the bindings say, the look where there is no glass (before OS 26), "
            + "on every OS: the system's glass is not the same pixel for pixel from one render to the next. The "
            + "supplements \"floating, on glass\" show it on glass, over content (decisions/0015).")
}

/// Floating buttons over content, one part of them per catalog entry: live ones, over a pressable list, a group in
/// the system's `GlassEffectContainer` as a product writes it; every size, over the stripes and the inverse band; each
/// state on glass; each state as before OS 26, and loading.
private struct ButtonFloatingPage: View {
    /// What the page holds; each part is a catalog entry.
    enum Part {
        /// The live buttons, the buttons over a pressable list, a group in the system's container, and on macOS focus.
        case live
        /// Every size on glass, over the stripes and over a band of the opposite tone, the recorded limitation (Q5).
        case sizes
        /// Each state but loading, on glass.
        case states
        /// Each state but loading as before OS 26, then loading, on glass and before OS 26.
        case before26
    }

    let part: Part
    @State private var accepted = 0
    @State private var rowPresses = 0
    @State private var floatingPresses = 0
    @FocusState private var isFocused: Bool

    /// A row of the states: the states it forces or sets; loading has a section of its own, last, since its
    /// indicator keeps the page moving while the audit waits for it to settle.
    private struct Row: Hashable {
        let name: String
        let states: Set<ButtonCatalogState>

        static var all: [Row] {
            [Row(name: "rest", states: [])]
                + ButtonCatalogState.all.filter { $0.isEntered && !$0.isLoading }.map {
                    Row(name: $0.name, states: [$0])
                }
        }

        /// The row's name as a button's word: "Rest", "Pressed".
        var word: String { name.prefix(1).uppercased() + name.dropFirst() }
    }

    var body: some View {
        switch part {
        case .live:
            TokenPage(
                title: "Button · floating",
                summary: "A floating button stands over content, outside any bar. Secondary: the system's glass from "
                    + "OS 26, with nothing of westron's on it; before OS 26 an opaque raised surface. Primary: its "
                    + "fill and shadow.overlay. Tertiary and a destructive secondary do not float."
            ) { livePart }
        case .sizes:
            TokenPage(
                title: "Button · floating, sizes",
                summary: "Every size on the system's glass from OS 26, over stripes, then over content of the tone "
                    + "opposite to the theme, where the contract promises no contrast for the label."
            ) {
                section("Sizes, on glass from OS 26") { sizes(ground: .stripes, secondary: "Edit") }
                section("Over the opposite tone: a recorded limitation") {
                    Text(
                        "On glass the label keeps westron's colors, which follow the theme, while the glass follows "
                            + "what lies beneath. Over a light ground in the dark theme it can read below 4.5:1 "
                            + "(3.8:1 on iOS 26.3): the contract records this and promises no ratio. Over content "
                            + "whose tone it does not control, a product uses a floating primary or keeps the content "
                            + "in the theme's tone (decisions/0015, Q5)."
                    )
                    .textRole(.footnote.regular)
                    .foregroundStyle(.text.secondary)
                    sizes(ground: .inverse, secondary: "Open")
                }
            }
        case .states:
            TokenPage(
                title: "Button · floating, states",
                summary: "Each state on the system's glass from OS 26. Hover, pressed and focus are forced; the glass "
                    + "answers a real touch or pointer itself."
            ) {
                section("States, on glass from OS 26") { states(withoutGlass: false) }
            }
        case .before26:
            TokenPage(
                title: "Button · floating, before OS 26",
                summary: "Each state as before OS 26, an opaque raised surface, forced on this OS; then loading."
            ) {
                section("Before OS 26: forced on this OS") { states(withoutGlass: true) }
                section("Loading") { loading }
            }
        }
    }

    /// The live buttons, the buttons over a pressable list, on macOS the focus ring, and a group.
    @ViewBuilder private var livePart: some View {
        section("Live") {
            Text("Accepted presses: \(accepted)")
                .textRole(.body.regular)
                .foregroundStyle(.text.primary)
                .accessibilityIdentifier(ButtonFloatingID.count)
            FloatingPanel {
                HStack(spacing: .space200) {
                    live("Back", icon: .chevronLeft, variant: .secondary, id: ButtonFloatingID.back)
                    live("More", icon: .ellipsis, variant: .secondary, id: ButtonFloatingID.more)
                    live("Share", icon: .expand, variant: .secondary, id: ButtonFloatingID.disabled)
                        .disabled(true)
                    Spacer(minLength: 0)
                    live("Add", icon: .plus, variant: .primary, id: ButtonFloatingID.add)
                }
            }
        }
        section("Over a pressable list: sizes s, m and l") { overList }
        #if os(macOS)
            section("Focus: the system's ring over glass") {
                // A button takes keyboard focus on a Mac only with the system's keyboard navigation on; the
                // catalog makes this one focusable and focuses it, to show the ring the system draws over glass.
                FloatingPanel {
                    sample("Edit", icon: .pen, variant: .secondary)
                        .focusable()
                        .focused($isFocused)
                }
                .onAppear { isFocused = true }
            }
        #endif
        section("A group: the system's GlassEffectContainer") {
            FloatingPanel { group }
        }
    }

    /// A live floating button, icon-only, that counts accepted presses.
    private func live(_ title: LocalizedStringKey, icon: Westron.Icon, variant: ButtonVariant, id: String)
        -> some View
    {
        Button {
            accepted += 1
        } label: {
            Label(title, icon: icon)
        }
        .buttonStyle(variant, iconOnly: true, floating: true)
        .accessibilityIdentifier(id)
    }

    /// Three rows of a list a product presses, and over the middle one a floating secondary of each size on glass,
    /// far enough apart that no button's touch tolerance reaches another (ButtonBehaviorTests taps around them).
    private var overList: some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text("Rows: \(rowPresses), floating: \(floatingPresses)")
                .textRole(.body.regular)
                .foregroundStyle(.text.primary)
                .accessibilityIdentifier(ButtonFloatingID.overListCount)
            VStack(spacing: 0) {
                row("Groceries")
                row("Work").accessibilityIdentifier(ButtonFloatingID.overListRow)
                row("Home")
            }
            .overlay {
                HStack(spacing: .space800) {
                    ForEach(ButtonSize.allCases, id: \.self) { size in
                        Button {
                            floatingPresses += 1
                        } label: {
                            Label("Back", icon: .chevronLeft)
                        }
                        .buttonStyle(.secondary, size: size, iconOnly: true, floating: true)
                        .accessibilityIdentifier(ButtonFloatingID.overList(size))
                    }
                }
            }
        }
    }

    /// A row of the list that counts its presses.
    private func row(_ name: String) -> some View {
        ListRow(action: { rowPresses += 1 }) {
            Text(verbatim: name)
        }
    }

    /// Every size in a panel: a secondary icon-only and with a label, a primary icon-only and with a label, and a
    /// destructive primary.
    private func sizes(ground: FloatingGroundKind, secondary: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            ForEach(ButtonSize.allCases, id: \.self) { size in
                TokenDetail("size \(size.rawValue)")
                FloatingPanel(ground: ground) {
                    FlowLayout(spacing: .space200) {
                        sample("Back", icon: .chevronLeft, variant: .secondary, size: size, iconOnly: true)
                        sample(secondary, icon: .pen, variant: .secondary, size: size)
                        sample("Add", icon: .plus, variant: .primary, size: size, iconOnly: true)
                        if ground == .stripes {
                            sample("New", icon: .plus, variant: .primary, size: size)
                            sample("Delete", icon: .trash, variant: .primary, size: size, role: .destructive)
                        }
                    }
                }
            }
        }
    }

    /// Every state but loading, at size m, each row a panel: a secondary icon-only and with a label, and a primary
    /// icon-only. The secondary with a label says "Edit" on glass and the row's state before OS 26, so that the audit
    /// tells the pressed one, scaled down there, from the rest (the primaries with a label are in `sizes`, at rest).
    private func states(withoutGlass: Bool) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            ForEach(Row.all, id: \.self) { row in
                TokenDetail(row.name)
                FloatingPanel {
                    FlowLayout(spacing: .space200) {
                        sample("Back", icon: .chevronLeft, variant: .secondary, iconOnly: true)
                        sample(withoutGlass ? LocalizedStringKey(row.word) : "Edit", icon: .pen, variant: .secondary)
                        sample("Add", icon: .plus, variant: .primary, iconOnly: true)
                    }
                }
                .forcingButtonStates(row.states.filter(\.isForced))
                .disabled(row.states.contains(where: \.isDisabled))
                .drawingButtonsWithoutGlass(withoutGlass)
            }
        }
    }

    /// Loading, on glass and before OS 26, last on the page: its indicators keep moving.
    private var loading: some View {
        VStack(alignment: .leading, spacing: .space100) {
            ForEach([false, true], id: \.self) { withoutGlass in
                TokenDetail(withoutGlass ? "before OS 26" : "on glass")
                FloatingPanel {
                    FlowLayout(spacing: .space200) {
                        sample("Back", icon: .chevronLeft, variant: .secondary, iconOnly: true)
                        sample(withoutGlass ? "Loading" : "Edit", icon: .pen, variant: .secondary)
                        sample("New", icon: .plus, variant: .primary)
                    }
                }
                .loading(true)
                .drawingButtonsWithoutGlass(withoutGlass)
            }
        }
    }

    private func sample(
        _ title: LocalizedStringKey, icon: Westron.Icon, variant: ButtonVariant, size: ButtonSize? = nil,
        iconOnly: Bool = false, role: ButtonRole? = nil
    ) -> some View {
        Button(role: role) {
        } label: {
            Label(title, icon: icon)
        }
        .buttonStyle(variant, size: size, iconOnly: iconOnly, floating: true)
    }

    /// Two floating buttons that share one piece of glass, as a product writes them: the system's container, from OS
    /// 26; before it, two buttons side by side.
    @ViewBuilder private var group: some View {
        let pair = HStack(spacing: .space100) {
            sample("Back", icon: .chevronLeft, variant: .secondary, iconOnly: true)
            sample("More", icon: .ellipsis, variant: .secondary, iconOnly: true)
        }
        if #available(iOS 26, macOS 26, watchOS 26, *) {
            GlassEffectContainer(spacing: .space100) { pair }
        } else {
            pair
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.subheadline.strong)
                .foregroundStyle(.text.primary)
            content()
        }
    }
}
