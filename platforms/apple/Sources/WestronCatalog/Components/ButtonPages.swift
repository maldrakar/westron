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
// `button-states-destructive` (every state and the combinations the contract excludes), and `button-behavior` (live
// buttons that count accepted presses, loading's width and Dynamic Type). The variants, sizes and states come from the
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
        id: "button-behavior", title: "Button: presses, loading, text size", section: .components
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
    /// The test control that presses `loading` through the accessibility API.
    static let accessibilityPress = "button.live.accessibility-press"
    /// A secondary button at size s, drawn smaller than the recommended target.
    static let small = "button.live.small"
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
private struct ButtonSample {
    let title: LocalizedStringKey
    let icon: Westron.Icon

    init(destructive: Bool) {
        title = destructive ? "Delete" : "Save"
        icon = destructive ? .trash : .check
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
                    SampleRows(items: ButtonVariant.allCases, name: \.rawValue) { variant in
                        ForEach(SampleButton.Kind.allCases, id: \.self) { kind in
                            SampleButton(kind: kind, variant: variant, size: size, destructive: destructive)
                        }
                    }
                }
            }
        }
    }
}

/// Rows of samples, each with its name: a grid with the names in the first column, or, when the grid is wider than the
/// page (accessibility text sizes, long labels), each name above its samples, which then wrap onto lines of their own when they do not fit side by side. A grid
/// column would squeeze a button until its label breaks between letters (chapter 08: layout reflows, it never clips).
private struct SampleRows<Item: Hashable, Cells: View>: View {
    let items: [Item]
    let name: (Item) -> String
    /// Names in the face of token names (variants), or of details (states).
    let monospaced: Bool
    @ViewBuilder let cells: (Item) -> Cells

    init(
        items: [Item], name: @escaping (Item) -> String, monospaced: Bool = true,
        @ViewBuilder cells: @escaping (Item) -> Cells
    ) {
        self.items = items
        self.name = name
        self.monospaced = monospaced
        self.cells = cells
    }

    @ViewBuilder private func label(_ item: Item) -> some View {
        if monospaced { TokenName(name(item)) } else { TokenDetail(name(item)) }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Grid(alignment: .leading, horizontalSpacing: .space100, verticalSpacing: .space100) {
                ForEach(items, id: \.self) { item in
                    GridRow {
                        label(item)
                        cells(item)
                    }
                }
            }
            VStack(alignment: .leading, spacing: .space100) {
                ForEach(items, id: \.self) { item in
                    label(item)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: .space100) { cells(item) }
                        VStack(alignment: .leading, spacing: .space100) { cells(item) }
                    }
                }
            }
        }
    }
}

/// Every state of the contract alone, and disabled and loading combined with a forced hover and pressed, which they
/// exclude: those rows must look as disabled and loading alone.
private struct ButtonStatesPage: View {
    let destructive: Bool

    /// A row of the matrix: the states it shows, forced or real.
    private struct Row: Hashable {
        let states: [ButtonCatalogState]
        var name: String { states.isEmpty ? "rest" : states.map(\.name).joined(separator: " + ") }
    }

    /// Rest, each state alone, then each state that excludes hover and pressed combined with each of them.
    private static var rows: [Row] {
        let entered = ButtonCatalogState.all.filter(\.isEntered)
        let excluding = entered.filter { ["disabled", "loading"].contains($0.name) }
        let excluded = entered.filter { ["hover", "pressed"].contains($0.name) }
        return [Row(states: [])] + entered.map { Row(states: [$0]) }
            + excluding.flatMap { state in excluded.map { Row(states: [state, $0]) } }
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
        let names = Set(row.states.map(\.name))
        // Size s: the states' colors do not depend on the size, and three buttons of s fit beside the names on a phone.
        return SampleButton(kind: .iconAndLabel, variant: variant, size: .s, destructive: destructive)
            .forcingButtonStates(Set(row.states.filter { !["disabled", "loading"].contains($0.name) }))
            .disabled(names.contains("disabled"))
            .loading(names.contains("loading"))
    }
}

/// Live buttons that count the presses they accept, loading's width, and Dynamic Type.
private struct ButtonBehaviorPage: View {
    @State private var accepted = 0
    @State private var isPublishing = true
    /// What the last accessibility press did, for the UI test: "" before any, then `AccessibilityPress`'s report.
    @State private var accessibilityPress = ""
    @FocusState private var isFocused: Bool
    @FocusState private var isLargeFocused: Bool

    var body: some View {
        TokenPage(
            title: "Button · behavior",
            summary: "A loading button refuses a touch or a click, and is neither dimmed nor announced as unavailable. "
                + "An accessibility press, and a keyboard shortcut on macOS, still reach it: a contract gap (#23)."
        ) {
            section("Presses") {
                Text("Accepted presses: \(accepted)")
                    .textRole(.body.regular)
                    .foregroundStyle(.text.primary)
                    .accessibilityIdentifier(ButtonCatalogID.count)
                HStack(spacing: .space200) {
                    Button("Save") { accepted += 1 }
                        .buttonStyle(.primary)
                        .accessibilityIdentifier(ButtonCatalogID.rest)
                    Button("Publish") { accepted += 1 }
                        .buttonStyle(.primary)
                        .loading(isPublishing)
                        #if !os(watchOS)
                            .keyboardShortcut(.defaultAction)
                        #endif
                        .accessibilityIdentifier(ButtonCatalogID.loading)
                    Button {
                        accepted += 1
                    } label: {
                        Label("Add", icon: .plus)
                    }
                    .buttonStyle(.secondary, size: .s)
                    .accessibilityIdentifier(ButtonCatalogID.small)
                }
                HStack(spacing: .space200) {
                    Toggle("Publish is loading", isOn: $isPublishing)
                        .fixedSize()
                        .accessibilityIdentifier(ButtonCatalogID.loadingToggle)
                    // A test control in the system's own style: it presses Publish as assistive technology does.
                    Button("Press Publish via accessibility") {
                        accessibilityPress = AccessibilityPress.press(identifier: ButtonCatalogID.loading)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier(ButtonCatalogID.accessibilityPress)
                    .accessibilityValue(accessibilityPress)
                }
                .textRole(.footnote.regular)
                .foregroundStyle(.text.secondary)
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
            section("Loading keeps the width") {
                Grid(alignment: .leading, horizontalSpacing: .space150, verticalSpacing: .space100) {
                    ForEach(SampleButton.Kind.allCases, id: \.self) { kind in
                        GridRow {
                            TokenDetail(kind.title)
                            SampleButton(kind: kind, variant: .primary, destructive: false)
                            SampleButton(kind: kind, variant: .primary, destructive: false)
                                .loading(true)
                            SampleButton(kind: kind, variant: .secondary, destructive: false)
                                .loading(true)
                        }
                    }
                }
            }
            section("Text size accessibility3: the height grows") {
                VStack(alignment: .leading, spacing: .space100) {
                    ForEach(ButtonSize.allCases, id: \.self) { size in
                        HStack(spacing: .space100) {
                            ForEach(SampleButton.Kind.allCases, id: \.self) { kind in
                                SampleButton(kind: kind, variant: .secondary, size: size, destructive: false)
                            }
                        }
                    }
                }
                .dynamicTypeSize(.accessibility3)
            }
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
