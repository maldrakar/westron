import SwiftUI

/// Идентификаторы доступности, по которым UI-тест скриншотов (`CatalogUITests`) понимает,
/// что изолированная запись отрисована или что показать её нельзя.
public enum CatalogAccessibilityID {
    /// Контейнер изолированной записи.
    public static let entry = "westron.catalog.entry"
    /// Сообщение о проблеме; его `label` — причина.
    public static let problem = "westron.catalog.problem"
}

/// Корневое представление каталога.
///
/// Без `-WestronEntry` показывает навигацию по всем записям. С ним — одну запись на весь экран, без навигации:
/// так её снимает `tools/apple/catalog-screenshot.sh`.
public struct CatalogRootView: View {
    private let options: Result<CatalogLaunchOptions, CatalogLaunchOptions.ParseError>

    public init(options: Result<CatalogLaunchOptions, CatalogLaunchOptions.ParseError> = CatalogLaunchOptions.current) {
        self.options = options
    }

    public var body: some View {
        switch options {
        case .failure(let error):
            CatalogProblemView(message: error.description)
        case .success(let options):
            content(options)
                .preferredColorScheme(options.appearance?.colorScheme)
                .modifier(DynamicTypeOverride(size: options.dynamicTypeSize))
        }
    }

    @ViewBuilder
    private func content(_ options: CatalogLaunchOptions) -> some View {
        if let id = options.entryID {
            if let entry = Catalog.entry(id: id) {
                entry.content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(CatalogAccessibilityID.entry)
            } else {
                let known = Catalog.entries.map(\.id).joined(separator: ", ")
                CatalogProblemView(message: "Нет записи каталога «\(id)». Есть: \(known)")
            }
        } else {
            CatalogBrowser()
        }
    }
}

private struct DynamicTypeOverride: ViewModifier {
    let size: DynamicTypeSize?

    func body(content: Content) -> some View {
        if let size {
            content.dynamicTypeSize(size)
        } else {
            content
        }
    }
}

private struct CatalogBrowser: View {
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(CatalogEntry.Section.allCases, id: \.self) { section in
                    let entries = Catalog.entries(in: section)
                    Section(section.title) {
                        if entries.isEmpty {
                            Text("Пока пусто")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(entries) { entry in
                            NavigationLink(entry.title, value: entry.id)
                        }
                    }
                }
            }
            .navigationTitle("Westron")
        } detail: {
            if let selection, let entry = Catalog.entry(id: selection) {
                entry.content()
                    .navigationTitle(entry.title)
            } else {
                ContentUnavailableView("Выберите запись", systemImage: "square.grid.2x2")
            }
        }
    }
}

private struct CatalogProblemView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Каталог не может показать запись", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(message))
        .accessibilityIdentifier(CatalogAccessibilityID.problem)
    }
}
