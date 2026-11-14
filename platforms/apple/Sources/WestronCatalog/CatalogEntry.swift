import SwiftUI

/// Одна запись каталога: компонент, образец основы или служебная страница.
///
/// Каталог рендерит любую запись изолированно по её `id` (аргумент запуска `-WestronEntry`),
/// поэтому `id` стабилен и совпадает с `id` компонента в контракте (`spec/components/<id>/`).
public struct CatalogEntry: Identifiable, Sendable {
    /// Раздел каталога, в котором показывается запись.
    public enum Section: String, CaseIterable, Sendable {
        /// Компоненты из `spec/components/`.
        case components
        /// Образцы токенов: цвет, типографика, отступы (появятся в фазе 1).
        case foundations
        /// Служебные страницы каталога.
        case utilities

        public var title: LocalizedStringKey {
            switch self {
            case .components: "Компоненты"
            case .foundations: "Основы"
            case .utilities: "Служебное"
            }
        }
    }

    public let id: String
    public let title: String
    public let section: Section
    private let makeContent: @MainActor @Sendable () -> AnyView

    public init<Content: View>(
        id: String,
        title: String,
        section: Section,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> Content
    ) {
        self.id = id
        self.title = title
        self.section = section
        self.makeContent = { AnyView(content()) }
    }

    @MainActor
    public func content() -> AnyView {
        makeContent()
    }
}
