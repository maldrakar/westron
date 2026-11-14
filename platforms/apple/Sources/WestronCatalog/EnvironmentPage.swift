import SwiftUI

extension CatalogEntry {
    /// Служебная страница: условия, в которых каталог сейчас рендерит записи.
    /// Помогает убедиться, что аргументы запуска (оформление, размер шрифта) применились.
    static let environment = CatalogEntry(id: "environment", title: "Окружение", section: .utilities) {
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
            Section("Платформа") {
                LabeledContent("Система", value: Self.platform)
                LabeledContent("Версия", value: ProcessInfo.processInfo.operatingSystemVersionString)
                #if os(iOS)
                    LabeledContent(
                        "Size class", value: "\(describe(horizontalSizeClass)) × \(describe(verticalSizeClass))")
                #endif
            }
            Section("Оформление") {
                LabeledContent("Тема", value: colorScheme == .dark ? "тёмная" : "светлая")
                LabeledContent("Контраст", value: contrast == .increased ? "повышенный" : "стандартный")
                LabeledContent("Размер шрифта", value: String(describing: dynamicTypeSize))
                LabeledContent("Жирный текст", value: legibilityWeight == .bold ? "да" : "нет")
            }
            Section("Доступность") {
                LabeledContent("Уменьшение движения", value: reduceMotion ? "да" : "нет")
                LabeledContent("Уменьшение прозрачности", value: reduceTransparency ? "да" : "нет")
                LabeledContent("Без различения цветом", value: differentiateWithoutColor ? "да" : "нет")
            }
            Section("Язык") {
                LabeledContent("Локаль", value: locale.identifier)
                LabeledContent(
                    "Направление", value: layoutDirection == .rightToLeft ? "справа налево" : "слева направо")
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
            "другая"
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
