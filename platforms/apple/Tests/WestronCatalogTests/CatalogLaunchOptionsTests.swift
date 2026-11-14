import SwiftUI
import Testing

@testable import WestronCatalog

@Suite("Аргументы запуска каталога")
struct CatalogLaunchOptionsTests {
    @Test("Без аргументов — навигация по каталогу")
    func empty() throws {
        #expect(try CatalogLaunchOptions(arguments: []) == CatalogLaunchOptions())
    }

    @Test("Все аргументы разбираются")
    func all() throws {
        let options = try CatalogLaunchOptions(arguments: [
            "-WestronEntry", "environment",
            "-WestronAppearance", "dark",
            "-WestronDynamicType", "accessibility2",
        ])
        #expect(
            options
                == CatalogLaunchOptions(
                    entryID: "environment",
                    appearance: .dark,
                    dynamicTypeSize: .accessibility2
                )
        )
    }

    @Test("Чужие аргументы пропускаются")
    func foreignArguments() throws {
        let options = try CatalogLaunchOptions(arguments: [
            "-NSDocumentRevisionsDebugMode", "YES", "-WestronEntry", "environment", "-ApplePersistenceIgnoreState",
        ])
        #expect(options.entryID == "environment")
    }

    @Test("Флаг без значения — ошибка")
    func missingValue() {
        #expect(throws: CatalogLaunchOptions.ParseError.missingValue(flag: "-WestronEntry")) {
            try CatalogLaunchOptions(arguments: ["-WestronEntry"])
        }
        #expect(throws: CatalogLaunchOptions.ParseError.missingValue(flag: "-WestronEntry")) {
            try CatalogLaunchOptions(arguments: ["-WestronEntry", "-WestronAppearance", "dark"])
        }
    }

    @Test("Недопустимое значение — ошибка со списком допустимых")
    func invalidValue() {
        #expect(
            throws: CatalogLaunchOptions.ParseError.invalidValue(
                flag: "-WestronAppearance",
                value: "sepia",
                allowed: ["light", "dark"]
            )
        ) {
            try CatalogLaunchOptions(arguments: ["-WestronAppearance", "sepia"])
        }
    }

    @Test("Имена размеров шрифта покрывают все DynamicTypeSize")
    func dynamicTypeNames() {
        let named = CatalogLaunchOptions.dynamicTypeSizes.map(\.size)
        #expect(named == DynamicTypeSize.allCases)
    }
}

@Suite("Реестр каталога")
struct CatalogRegistryTests {
    @Test("id записей уникальны и не пусты")
    func uniqueIDs() {
        let ids = Catalog.entries.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { !$0.isEmpty })
    }

    @Test("Запись находится по id")
    func lookup() {
        #expect(Catalog.entry(id: "environment")?.title == "Окружение")
        #expect(Catalog.entry(id: "нет-такой") == nil)
    }
}
