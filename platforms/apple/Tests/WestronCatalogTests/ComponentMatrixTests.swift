import SwiftUI
import Testing
import WestronUI

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

    @Test("Text's matrix: the 17 roles at rest, each in exactly one cell of its 6 sheets; one role a picture at AX5")
    func text() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "text" })
        #expect(matrix.states.isEmpty && matrix.notes.isEmpty)
        #expect(matrix.drawnCombinations.count == 17)
        #expect(matrix.drawnCombinations.first?.values == ["heading.large"])
        #expect(matrix.drawnCombinations.last?.values == ["code.strong"])
        #expect(matrix.sheets.count == 6)
        #expect(matrix.sheets.map(matrix.drawnCount(in:)).reduce(0, +) == 17)
        #expect(Westron.TextRole.all.map(\.name) == matrix.drawnCombinations.map { "typography." + $0.values[0] })
        #expect(Catalog.entry(id: "text")?.section == .components)
        #if !os(macOS)
            let pictures = matrix.sheets.flatMap { matrix.pictures(of: $0, at: .accessibility5) }
            #expect(pictures.count == 17 && pictures.allSatisfy { $0.columns.count == 1 })
        #endif
    }

    @Test("Icon's matrix: 36 glyphs down the rows × 3 scales across, each in exactly one cell of its 6 sheets")
    func icon() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "icon" })
        #expect(matrix.states.isEmpty && matrix.notes.isEmpty)
        #expect(matrix.rowOption == "glyph" && matrix.columnName == "scale")
        #expect(matrix.rowsName == "glyph")
        #expect(matrix.drawnCombinations.count == 36 * 3)
        #expect(Westron.Icon.allCases.map(\.rawValue) == matrix.options[0].values)
        #expect(matrix.sheets.count == 6)
        var seen: Set<ComponentMatrix.Combination> = []
        for sheet in matrix.sheets {
            #expect(sheet.fixed.isEmpty && sheet.columns == ["small", "medium", "large"] && sheet.rows.count == 6)
            #expect(matrix.title(of: sheet) == "every combination")
            for row in matrix.rows(of: sheet) {
                for column in sheet.columns {
                    guard case .drawn(let combination, _, _) = matrix.cell(sheet, row: row, column: column) else {
                        Issue.record("\(row ?? "rest"), \(column) is not drawn")
                        continue
                    }
                    #expect(combination.values == [row, column] && combination.state == nil)
                    #expect(seen.insert(combination).inserted, "\(combination) on two cells")
                }
            }
        }
        #expect(seen == Set(matrix.drawnCombinations))
        #expect(Catalog.entry(id: "icon")?.section == .components)
    }

    @Test("Icon's supplements: one sheet each, of a few glyphs, on the generated scales")
    func iconSupplements() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "icon" })
        let supplements = matrix.supplements
        #expect(supplements.map { $0.supplement?.id } == ["beside-text", "color-roles"])
        for supplement in supplements {
            #expect(supplement.sheets.count == 1)
            let sheet = try #require(supplement.sheets.first)
            let rows = supplement.supplement?.rows ?? []
            #expect(
                rows
                    == (supplement.supplement?.id == "beside-text"
                        ? ComponentMatrix.Supplement.iconBesideTextGlyphs : ComponentMatrix.Supplement.iconSampleGlyphs)
            )
            #expect(sheet.rows == rows)
            #expect(sheet.columns == ["small", "medium", "large"])
            #expect(
                supplement.drawnCount(in: sheet) == rows.count * 3
                    && supplement.drawnCombinations.count == rows.count * 3)
            #expect(sheet.id == "\(supplement.supplement?.id ?? "")_all")
            #expect(
                ComponentMatrix.sheet(key: supplement.key(of: sheet))?.matrix.supplement?.id
                    == supplement.supplement?.id)
        }
        #expect(matrix.sheets.count == 6, "the generated matrix stays the contract's")
        #if !os(macOS)
            // At accessibility5 a supplement's taller cells take fewer rows to a picture: one beside text, three of
            // the color roles, a column at a time.
            let parts = supplements.map { s in s.sheets.flatMap { s.pictures(of: $0, at: .accessibility5) }.count }
            #expect(parts == [9, 6])
        #endif
    }

    @Test("IconTile's matrix: 36 glyphs down the rows × 3 scales across, as Icon's, and its catalog entry")
    func iconTile() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "icon-tile" })
        #expect(matrix.states.isEmpty && matrix.notes.isEmpty)
        #expect(matrix.rowOption == "glyph" && matrix.columnName == "scale")
        #expect(matrix.drawnCombinations.count == 36 * 3)
        #expect(Westron.Icon.allCases.map(\.rawValue) == matrix.options[0].values)
        #expect(matrix.sheets.count == 6)
        for sheet in matrix.sheets {
            #expect(sheet.fixed.isEmpty && sheet.columns == ["small", "medium", "large"] && sheet.rows.count == 6)
        }
        #expect(Catalog.entry(id: "icon-tile")?.section == .components)
    }

    @Test("IconTile's supplements: list colors, beside a title, an empty screen on iOS only; one sheet of one glyph")
    func iconTileSupplements() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "icon-tile" })
        let supplements = matrix.supplements
        #if os(iOS)
            #expect(supplements.map { $0.supplement?.id } == ["list-colors", "beside-title", "empty-screen"])
        #else
            #expect(supplements.map { $0.supplement?.id } == ["list-colors", "beside-title"])
        #endif
        for supplement in supplements {
            #expect(supplement.sheets.count == 1)
            let sheet = try #require(supplement.sheets.first)
            #expect(sheet.rows.count == 1 && sheet.columns == ["small", "medium", "large"])
            #expect(supplement.drawnCombinations.count == 3)
            #expect(sheet.id == "\(supplement.supplement?.id ?? "")_all")
        }
        #expect(matrix.sheets.count == 6, "the generated matrix stays the contract's")
    }

    #if !os(macOS)
        @Test("Checkbox's list colors take three rows to a picture at accessibility5, so they fit an iPhone's screen")
        func checkboxListColorsAtAccessibility5() throws {
            let matrix = try #require(ComponentMatrix.all.first { $0.component == "checkbox" })
            let colors = try #require(matrix.supplements.first { $0.supplement?.id == "list-colors" })
            let pictures = colors.sheets.flatMap { colors.pictures(of: $0, at: .accessibility5) }
            #expect(pictures.map { colors.rows(of: $0).count } == [3, 2])
        }
    #endif

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

    @Test("a sheet is found by its key; names follow component, sheet and capture")
    func keys() throws {
        let found = try #require(ComponentMatrix.sheet(key: "button.size-l_role-destructive_iconOnly-true"))
        #expect(found.matrix.title(of: found.sheet) == "size l · role destructive · iconOnly true")
        #expect(
            found.matrix.fileName(of: found.sheet, capture: .init(theme: .darkHighContrast, textSize: .large))
                == "button.size-l_role-destructive_iconOnly-true.dark-hc.png", "as before text sizes")
        #expect(
            found.matrix.fileName(of: found.sheet, capture: .init(theme: .light, textSize: .xSmall))
                == "button.size-l_role-destructive_iconOnly-true.light.xSmall.png")
        #expect(ComponentMatrix.sheet(key: "button.nothing") == nil)
        #expect(ComponentMatrix.Theme.allCases.map(\.rawValue) == ["light", "dark", "light-hc", "dark-hc"])
    }

    @Test("the captures: four themes at the default text size; on iOS the light theme at xSmall and accessibility5")
    func captures() {
        let names = ComponentMatrix.Capture.all.map(\.name)
        #if os(macOS)
            #expect(names == ["light", "dark", "light-hc", "dark-hc"])
            #expect(ComponentMatrix.TextSize.notCapturedNote != nil)
        #else
            #expect(names == ["light", "dark", "light-hc", "dark-hc", "light.xSmall", "light.accessibility5"])
            #expect(ComponentMatrix.TextSize.notCapturedNote == nil)
        #endif
        let sizes = CatalogLaunchOptions.dynamicTypeSizes.map(\.name)
        #expect(ComponentMatrix.TextSize.allCases.allSatisfy { sizes.contains($0.rawValue) }, "-WestronDynamicType")
    }

    @Test("a sheet that does not fit at a text size is split into parts holding each of its cells once")
    func parts() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "button" })
        for size in ComponentMatrix.TextSize.allCases {
            var cells = 0
            for sheet in matrix.sheets {
                let pictures = matrix.pictures(of: sheet, at: size)
                cells += pictures.map(matrix.drawnCount(in:)).reduce(0, +)
                if let limit = size.limit {
                    #expect(pictures.allSatisfy { $0.columns.count <= limit.columns && $0.rows.count <= limit.rows })
                    #expect(pictures.count > 1)
                    #expect(pictures.allSatisfy { ComponentMatrix.sheet(key: matrix.key(of: $0))?.sheet.id == $0.id })
                } else {
                    #expect(pictures.map(\.id) == [sheet.id], "the generated sheet itself")
                }
            }
            #expect(cells == matrix.drawnCombinations.count, "\(size): every combination once")
        }
        #if os(macOS)
            #expect(ComponentMatrix.TextSize.allCases.allSatisfy { $0.limit == nil }, "a Mac captures large alone")
        #else
            let sheet = try #require(matrix.sheets.first)
            let parts = matrix.pictures(of: sheet, at: .accessibility5)
            #expect(parts.first?.id == "size-s_role-default_iconOnly-false_part-1-of-\(parts.count)")
            #expect(parts.first.flatMap(matrix.partTitle(of:))?.hasPrefix("part 1 of \(parts.count): primary;") == true)
        #endif
    }

    @Test("a cap of columns to a picture splits a sheet whose cells do not fit side by side; each part is found by key")
    func columnCap() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "button" })
        let sheet = try #require(matrix.sheets.first { $0.id == "size-l_role-destructive_iconOnly-false" })
        #expect(matrix.pictures(of: sheet, at: .large, columns: 3).map(\.id) == [sheet.id], "a cap that fits all")
        let parts = matrix.pictures(of: sheet, at: .large, columns: 2)
        #expect(parts.map(\.id) == [1, 2].map { "\(sheet.id)_part-\($0)-of-2" })
        #expect(parts.map(\.columns) == [["primary", "secondary"], ["tertiary"]])
        #expect(parts.allSatisfy { matrix.rows(of: $0) == matrix.rows(of: sheet) }, "every row in each part")
        #expect(parts.map(matrix.drawnCount(in:)).reduce(0, +) == matrix.drawnCount(in: sheet))
        for part in parts {
            let found = try #require(ComponentMatrix.sheet(key: matrix.key(of: part)))
            #expect(found.sheet.columns == part.columns && found.sheet.rows == part.rows)
        }
        #expect(
            matrix.pictures(of: sheet, at: .large, columns: 1).map(\.columns) == [
                ["primary"], ["secondary"], ["tertiary"],
            ]
        )
        #if !os(macOS)
            // A cap never undoes a text size's own split: at accessibility5 on iOS, a column to a picture.
            #expect(
                matrix.pictures(of: sheet, at: .accessibility5, columns: 2).map(\.id)
                    == matrix.pictures(of: sheet, at: .accessibility5).map(\.id))
        #endif
        // Columns go as evenly as they can, so that a part's name, which counts the parts, tells its columns: five of
        // at most four to a picture go three and two, as of at most three.
        let columns = ["a", "b", "c", "d", "e"]
        let wide = ComponentMatrix(
            component: "fixture", options: [.init("variant", values: columns)], states: [], unbound: [],
            columns: "variant", platforms: [], excluded: [], advisedAgainst: [],
            combinations: columns.map { ComponentMatrix.Combination([$0], state: nil) },
            sheets: [.init("all", fixed: [], columns: columns, rows: [nil])]
        ) { _ in EmptyView() }
        let all = try #require(wide.sheets.first)
        for cap in [3, 4] {
            #expect(wide.pictures(of: all, at: .large, columns: cap).map(\.columns) == [["a", "b", "c"], ["d", "e"]])
        }
    }

    @Test("Button's supplement: a label without an icon on the generated axes, kept apart from the contract's matrix")
    func supplement() throws {
        let matrix = try #require(ComponentMatrix.all.first { $0.component == "button" })
        #expect(matrix.supplement == nil)
        let supplements = matrix.supplements
        #expect(supplements.map { $0.supplement?.id } == ["label-without-icon"])
        let labels = try #require(supplements.first)
        #expect(labels.supplements.isEmpty)
        // Variant × size × role × (rest + 5 states), iconOnly kept false: half of the generated matrix.
        #expect(labels.drawnCombinations.count == 3 * 3 * 2 * 6)
        #expect(labels.drawnCombinations.allSatisfy { $0.values[3] == "false" })
        #expect(labels.sheets.count == 6)
        #expect(labels.sheets.map(labels.drawnCount(in:)).reduce(0, +) == 108)
        #expect(labels.sheets[0].id == "label-without-icon_size-s_role-default_iconOnly-false")
        #expect(labels.title(of: labels.sheets[0]) == "label without an icon · size s · role default · iconOnly false")
        let found = try #require(
            ComponentMatrix.sheet(key: "button.label-without-icon_size-m_role-destructive_iconOnly-false"))
        #expect(found.matrix.supplement?.id == "label-without-icon")
        // The generated matrix is the contract's alone.
        #expect(matrix.drawnCombinations.count == 216 && matrix.sheets.count == 12)
        #expect(!Catalog.entries.contains { $0.id.contains("label-without-icon") }, "not an audited catalog entry")
    }

    #if os(macOS)
        /// The reason a Mac captures the default text size alone: macOS has no Dynamic Type, and a cell measures the
        /// same at every `dynamicTypeSize`. If a macOS starts to scale, this fails, and the Mac's text sizes are due.
        @Test("on macOS a matrix cell is the same size at every text size")
        @MainActor
        func macOSHasNoDynamicType() throws {
            let matrix = try #require(ComponentMatrix.all.first { $0.component == "button" })
            let combination = try #require(
                matrix.drawnCombinations.first { $0.values == ["primary", "l", "destructive", "false"] })
            let sizes = ComponentMatrix.TextSize.allCases.map { size in
                let host = NSHostingView(
                    rootView: matrix.content(combination)
                        .dynamicTypeSize(
                            CatalogLaunchOptions.dynamicTypeSizes.first { $0.name == size.rawValue }!.size))
                host.layoutSubtreeIfNeeded()
                return host.fittingSize
            }
            #expect(sizes.allSatisfy { $0 == sizes[0] }, "\(sizes)")
            #expect(sizes[0].width > 0)
        }
    #endif
}
