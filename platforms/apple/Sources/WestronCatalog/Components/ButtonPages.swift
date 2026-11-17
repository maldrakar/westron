import SwiftUI
import WestronUI

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

// Button's catalog entries, from spec/components/button/button.spec.yaml. The matrix is larger than one screen, so it
// is split into pages, each of which fits one screenshot on an iPhone 17 in portrait: `button` (variants × sizes ×
// label, icon and label, icon-only), `button-destructive` (the same in the destructive role), `button-states` and
// `button-states-destructive` (every state and the combinations the contract excludes), `button-behavior` (live
// buttons that count accepted presses, close neighbors and focus). The variants, sizes and states come from the
// generated enums, so the pages follow the contract.

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
        ButtonStatesPage(destructive: false)
    }

    static let buttonStatesDestructive = CatalogEntry(
        id: "button-states-destructive", title: "Button: states, destructive role", section: .components
    ) {
        ButtonStatesPage(destructive: true)
    }

    static let buttonBehavior = CatalogEntry(
        id: "button-behavior", title: "Button: presses, loading, neighbors", section: .components
    ) {
        ButtonBehaviorPage()
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
    var action: () -> Void = {}

    var body: some View {
        let sample = ButtonSample(destructive: destructive)
        Group {
            switch kind {
            case .label:
                Button(sample.title, role: destructive ? .destructive : nil, action: action)
                    .buttonStyle(variant, size: size)
            case .iconAndLabel:
                Button(role: destructive ? .destructive : nil, action: action) {
                    Label(sample.title, icon: sample.icon)
                }
                .buttonStyle(variant, size: size)
            case .iconOnly:
                Button(role: destructive ? .destructive : nil, action: action) {
                    Label(sample.title, icon: sample.icon)
                }
                .buttonStyle(variant, size: size, iconOnly: true)
            }
        }
    }
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
                + "The height is size.control.* and a minimum; the hit area is at least the platform's target."
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

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
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
            let size = subviews[index].sizeThatFits(.unspecified)
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
    let destructive: Bool

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
    private static var rows: [Row] {
        let entered = ButtonCatalogState.all.filter(\.isEntered)
        let excluding = entered.filter(\.excludesTint)
        let excluded = entered.filter(\.isTint)
        return [Row(states: [])] + entered.map { Row(states: [$0]) }
            + excluding.flatMap { state in excluded.map { Row(states: [state, $0]) } }
            + [.label, .iconOnly].map { Row(states: entered.filter(\.isLoading), kind: $0) }
    }

    var body: some View {
        TokenPage(
            title: destructive ? "Button · states, destructive" : "Button · states",
            summary: "Hover, pressed and focus are forced for the screenshot; disabled and loading are real. "
                + "Disabled and loading exclude hover and pressed. The system draws focus, so its row looks at rest."
        ) {
            SampleRows(items: Self.rows, name: \.name, monospaced: false) { row in
                ForEach(ButtonVariant.allCases, id: \.self) { variant in
                    cell(row, variant: variant)
                }
            }
        }
    }

    private func cell(_ row: Row, variant: ButtonVariant) -> some View {
        // Size s: the states' colors do not depend on the size, and three buttons of s fit beside the names on a phone.
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
            summary: "A loading button refuses a touch, a click and assistive technology, and is neither dimmed nor "
                + "announced as unavailable. A keyboard shortcut on macOS still reaches it unless the product drops it "
                + "while loading, as Export does (#23)."
        ) {
            section("Presses") {
                Text("Accepted presses: \(accepted)")
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                    .accessibilityIdentifier(ButtonCatalogID.count)
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
                        // The spelling `.loading(_:)` documents: no shortcut while loading.
                        .keyboardShortcut(isPublishing ? nil : KeyboardShortcut("e", modifiers: .command))
                    #endif
                    .accessibilityIdentifier(ButtonCatalogID.export)
                    Button {
                        accepted += 1
                    } label: {
                        Label("Add", icon: .plus)
                    }
                    .buttonStyle(.secondary, size: .s)
                    .accessibilityIdentifier(ButtonCatalogID.small)
                    Button {
                        accepted += 1
                    } label: {
                        Label("Save", icon: .check)
                    }
                    .buttonStyle(.primary, iconOnly: true)
                    .accessibilityIdentifier(ButtonCatalogID.iconOnly)
                }
                FlowLayout(spacing: .space200) {
                    Toggle("Loading: Publish, Publish now, Export", isOn: $isPublishing)
                        .fixedSize()
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
