import SwiftUI
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
                    if case .drawn(let combination, let fallbacks, let advised) = matrix.cell(
                        sheet, row: row, column: column)
                    {
                        #expect(seen.insert(combination).inserted, "\(combination) on two cells")
                        #expect(fallbacks.isEmpty, "iOS and macOS offer every value")
                        #expect(advised == nil, "Button has no constraints")
                    }
                }
            }
        }
        #expect(seen == Set(matrix.drawnCombinations))
    }

    @Test("a state no token binding names draws as rest, and the sheet and the review page say so")
    func unboundStates() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "button" })
        #expect(matrix.unboundStates == ["focus"])
        let note = try #require(matrix.unboundNote)
        #expect(note.contains("focus") && note.contains("its row looks at rest"))
        #expect(matrix.notes.contains(note))
    }

    @Test("a combination a warning constraint advises against is drawn and marked; a forbidden one is excluded")
    func constraintMarks() throws {
        let rows: [String?] = [nil, "hover"]
        let allowed = [["a", "false"], ["b", "false"], ["a", "true"]]
        let matrix = ComponentMatrix(
            component: "fixture",
            options: [.init("variant", values: ["a", "b"]), .init("dense", values: ["false", "true"])],
            states: ["hover"], unbound: [], columns: "variant", platforms: [],
            excluded: [.init(["b", "true"], constraint: 0)], advisedAgainst: [.init(["a", "true"], constraint: 1)],
            combinations: allowed.flatMap { values in rows.map { ComponentMatrix.Combination(values, state: $0) } },
            sheets: [
                .init("dense-false", fixed: ["false"], columns: ["a", "b"], rows: rows),
                .init("dense-true", fixed: ["true"], columns: ["a", "b"], rows: rows),
            ]
        ) { _ in EmptyView() }
        let dense = try #require(matrix.sheets.last)
        guard case .drawn(_, _, let advised) = matrix.cell(dense, row: "hover", column: "a") else {
            Issue.record("a, dense: drawn")
            return
        }
        #expect(advised == 1)
        guard case .excluded(let constraint) = matrix.cell(dense, row: nil, column: "b") else {
            Issue.record("b, dense: excluded")
            return
        }
        #expect(constraint == 0)
        guard case .drawn(_, _, let plain) = matrix.cell(matrix.sheets[0], row: nil, column: "a") else {
            Issue.record("a, not dense: drawn")
            return
        }
        #expect(plain == nil)
        #expect(matrix.drawnCount(in: dense) == 2)
        #expect(matrix.notes.contains { $0.contains("advised against") })
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
