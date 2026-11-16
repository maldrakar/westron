import SwiftUI
import WestronUI

extension CatalogEntry {
    /// A utility page: the conditions in which the catalog renders entries right now.
    /// It helps confirm that the launch arguments (appearance, font size) took effect.
    static let environment = CatalogEntry(id: "environment", title: "Environment", section: .utilities) {
        EnvironmentPage()
    }
}

struct EnvironmentPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.locale) private var locale
    @Environment(\.legibilityWeight) private var legibilityWeight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    /// A scroll view over stacks rather than a `Form`: a form is a lazy list, and the accessibility audit (#25) loses
    /// its rows when it changes the text size.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space300) {
                section("Platform") {
                    row("System", Self.platform)
                    row("Version", ProcessInfo.processInfo.operatingSystemVersionString)
                    #if os(iOS)
                        row("Size class", "\(describe(horizontalSizeClass)) × \(describe(verticalSizeClass))")
                    #endif
                }
                section("Appearance") {
                    row("Theme", colorScheme == .dark ? "dark" : "light")
                    row("Contrast", contrast == .increased ? "increased" : "standard")
                    row("Font size", String(describing: dynamicTypeSize))
                    row("Bold text", legibilityWeight == .bold ? "yes" : "no")
                }
                section("Accessibility") {
                    row("Reduce motion", reduceMotion ? "yes" : "no")
                    row("Reduce transparency", reduceTransparency ? "yes" : "no")
                    row("Differentiate without color", differentiateWithoutColor ? "yes" : "no")
                }
                section("Language") {
                    row("Locale", locale.identifier)
                    row("Direction", layoutDirection == .rightToLeft ? "right to left" : "left to right")
                }
            }
            .padding(.space200)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.background.canvas)
    }

    /// A setting and its value, two texts. Combined into one element (as `LabeledContent` does), the row made the
    /// accessibility audit report text that no element represents.
    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .space100) {
            Text(title)
            Spacer(minLength: 0)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space100) {
            Text(title)
                .textRole(.heading.small)
                .foregroundStyle(.text.primary)
                .accessibilityAddTraits(.isHeader)
            rows()
                .textRole(.body.regular)
                .foregroundStyle(.text.primary)
        }
    }

    private static var platform: String {
        #if os(iOS)
            "iOS"
        #elseif os(macOS)
            "macOS"
        #elseif os(watchOS)
            "watchOS"
        #else
            "other"
        #endif
    }

    #if os(iOS)
        private func describe(_ sizeClass: UserInterfaceSizeClass?) -> String {
            switch sizeClass {
            case .compact: "compact"
            case .regular: "regular"
            case nil: "—"
            @unknown default: "?"
            }
        }
    #endif
}
