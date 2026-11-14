/// Реестр записей каталога.
///
/// Новый компонент добавляет сюда запись в том же pull request, что и реализацию.
/// Снапшот-тесты (фаза 2) перебирают эти же записи, поэтому реестр живёт в пакете, а не в приложении.
public enum Catalog {
    public static let entries: [CatalogEntry] = [
        .environment
    ]

    public static func entry(id: String) -> CatalogEntry? {
        entries.first { $0.id == id }
    }

    public static func entries(in section: CatalogEntry.Section) -> [CatalogEntry] {
        entries.filter { $0.section == section }
    }
}
