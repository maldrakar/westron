import Testing

@testable import WestronCatalog

@Suite("Snapshot matrix in the catalog")
struct ComponentMatrixTests {
    @Test("-WestronMatrixSheet names a sheet to show")
    func launchArgument() throws {
        let options = try CatalogLaunchOptions(arguments: [
            "-WestronMatrixSheet", "button.size-s_role-default_iconOnly-false", "-WestronAppearance", "dark",
        ])
        #expect(options.matrixSheet == "button.size-s_role-default_iconOnly-false")
        #expect(options.appearance == .dark)
    }

    @Test("Button's matrix: 216 combinations, every one in exactly one cell of its 12 sheets")
    func button() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "button" })
        #expect(matrix.drawnCombinations.count == 216)
        #expect(matrix.sheets.count == 12)
        #expect(matrix.sheets.map(matrix.drawnCount(in:)).reduce(0, +) == matrix.drawnCombinations.count)
        var seen: Set<ComponentMatrix.Combination> = []
        for sheet in matrix.sheets {
            for row in matrix.rows(of: sheet) {
                for column in sheet.columns {
                    if case .drawn(let combination, let fallbacks) = matrix.cell(sheet, row: row, column: column) {
                        #expect(seen.insert(combination).inserted, "\(combination) on two cells")
                        #expect(fallbacks.isEmpty, "iOS and macOS offer every value")
                    }
                }
            }
        }
        #expect(seen == Set(matrix.drawnCombinations))
    }

    @Test("a sheet is found by its key; names follow component, sheet and theme")
    func keys() throws {
        let found = try #require(ComponentMatrix.sheet(key: "button.size-l_role-destructive_iconOnly-true"))
        #expect(found.matrix.title(of: found.sheet) == "size l · role destructive · iconOnly true")
        #expect(
            found.matrix.fileName(of: found.sheet, theme: .darkHighContrast)
                == "button.size-l_role-destructive_iconOnly-true.dark-hc.png")
        #expect(ComponentMatrix.sheet(key: "button.nothing") == nil)
        #expect(ComponentMatrix.Theme.allCases.map(\.rawValue) == ["light", "dark", "light-hc", "dark-hc"])
    }
}
