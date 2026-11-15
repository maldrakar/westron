import SwiftUI
import Testing

@testable import WestronCatalog

@Suite("Catalog launch arguments")
struct CatalogLaunchOptionsTests {
    @Test("No arguments: navigation over the catalog")
    func empty() throws {
        #expect(try CatalogLaunchOptions(arguments: []) == CatalogLaunchOptions())
    }

    @Test("All arguments are parsed")
    func all() throws {
        let options = try CatalogLaunchOptions(arguments: [
            "-WestronEntry", "environment",
            "-WestronAppearance", "dark",
            "-WestronContrast", "high",
            "-WestronDynamicType", "accessibility2",
        ])
        #expect(
            options
                == CatalogLaunchOptions(
                    entryID: "environment",
                    appearance: .dark,
                    contrast: .high,
                    dynamicTypeSize: .accessibility2
                )
        )
    }

    @Test("Foreign arguments are skipped")
    func foreignArguments() throws {
        let options = try CatalogLaunchOptions(arguments: [
            "-NSDocumentRevisionsDebugMode", "YES", "-WestronEntry", "environment", "-ApplePersistenceIgnoreState",
        ])
        #expect(options.entryID == "environment")
    }

    @Test("A flag without a value is an error")
    func missingValue() {
        #expect(throws: CatalogLaunchOptions.ParseError.missingValue(flag: "-WestronEntry")) {
            try CatalogLaunchOptions(arguments: ["-WestronEntry"])
        }
        #expect(throws: CatalogLaunchOptions.ParseError.missingValue(flag: "-WestronEntry")) {
            try CatalogLaunchOptions(arguments: ["-WestronEntry", "-WestronAppearance", "dark"])
        }
    }

    @Test("An invalid value is an error that lists the allowed values")
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
        #expect(
            throws: CatalogLaunchOptions.ParseError.invalidValue(
                flag: "-WestronContrast",
                value: "increased",
                allowed: ["standard", "high"]
            )
        ) {
            try CatalogLaunchOptions(arguments: ["-WestronContrast", "increased"])
        }
    }

    @Test("Contrast maps to SwiftUI's color scheme contrast")
    func contrast() throws {
        #expect(try CatalogLaunchOptions(arguments: ["-WestronContrast", "standard"]).contrast == .standard)
        #expect(CatalogLaunchOptions.Contrast.standard.colorSchemeContrast == .standard)
        #expect(CatalogLaunchOptions.Contrast.high.colorSchemeContrast == .increased)
        #expect(throws: CatalogLaunchOptions.ParseError.missingValue(flag: "-WestronContrast")) {
            try CatalogLaunchOptions(arguments: ["-WestronContrast"])
        }
    }

    @Test("Font size names cover every DynamicTypeSize")
    func dynamicTypeNames() {
        let named = CatalogLaunchOptions.dynamicTypeSizes.map(\.size)
        #expect(named == DynamicTypeSize.allCases)
    }
}

@Suite("Catalog registry")
struct CatalogRegistryTests {
    @Test("Entry ids are unique and not empty")
    func uniqueIDs() {
        let ids = Catalog.entries.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { !$0.isEmpty })
    }

    @Test("Foundations hold the token samples")
    func foundations() {
        #expect(
            Catalog.entries(in: .foundations).map(\.id) == [
                "color-backgrounds", "color-foregrounds", "color-categories", "color-status", "color-in-use",
                "typography", "space", "shape", "motion", "icons",
            ])
    }

    @Test("An entry is found by its id")
    func lookup() {
        #expect(Catalog.entry(id: "environment")?.title == "Environment")
        #expect(Catalog.entry(id: "no-such-entry") == nil)
    }
}
