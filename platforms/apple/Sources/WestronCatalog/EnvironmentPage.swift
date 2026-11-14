import SwiftUI

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

    var body: some View {
        Form {
            Section("Platform") {
                LabeledContent("System", value: Self.platform)
                LabeledContent("Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                #if os(iOS)
                    LabeledContent(
                        "Size class", value: "\(describe(horizontalSizeClass)) × \(describe(verticalSizeClass))")
                #endif
            }
            Section("Appearance") {
                LabeledContent("Theme", value: colorScheme == .dark ? "dark" : "light")
                LabeledContent("Contrast", value: contrast == .increased ? "increased" : "standard")
                LabeledContent("Font size", value: String(describing: dynamicTypeSize))
                LabeledContent("Bold text", value: legibilityWeight == .bold ? "yes" : "no")
            }
            Section("Accessibility") {
                LabeledContent("Reduce motion", value: reduceMotion ? "yes" : "no")
                LabeledContent("Reduce transparency", value: reduceTransparency ? "yes" : "no")
                LabeledContent("Differentiate without color", value: differentiateWithoutColor ? "yes" : "no")
            }
            Section("Language") {
                LabeledContent("Locale", value: locale.identifier)
                LabeledContent(
                    "Direction", value: layoutDirection == .rightToLeft ? "right to left" : "left to right")
            }
        }
        #if os(macOS)
            .formStyle(.grouped)
        #endif
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
