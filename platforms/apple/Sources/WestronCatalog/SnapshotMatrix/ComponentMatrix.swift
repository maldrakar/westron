import SwiftUI

/// A component's snapshot matrix (#24): every combination of its contract's options, each at rest and in each of its
/// states alone, less what a constraint forbids, on sheets that each fit one screenshot.
///
/// `tools/westron generate` writes each component's matrix from its contract into `Generated/<Component>+Matrix.swift`
/// and the list of them into `Generated/ComponentMatrix+All.swift`; the hand-written `<Component>MatrixCell` draws one
/// cell with the real component. The matrix is not a catalog entry: `Catalog.entries` drives the accessibility audit,
/// and the matrix is for the owner's review, so the catalog shows a sheet only with `-WestronMatrixSheet`, and
/// `tools/apple/snapshot-matrix.sh` captures every sheet in every theme.
public struct ComponentMatrix: Sendable {
    struct Option: Sendable {
        let name: String
        /// An enum option's values; `false` and `true` for a bool option.
        let values: [String]
        /// The system API that carries the option on Apple, such as `SwiftUI.ButtonRole`.
        let system: String?

        init(_ name: String, values: [String], system: String? = nil) {
            self.name = name
            self.values = values
            self.system = system
        }
    }

    /// One combination: a value of every option, in the options' order, and a state, nil at rest.
    public struct Combination: Hashable, Sendable {
        public let values: [String]
        public let state: String?

        init(_ values: [String], state: String?) {
            self.values = values
            self.state = state
        }
    }

    /// Values of the options that a constraint matches, by the constraint's index in the contract.
    struct Exclusion: Sendable {
        let values: [String]
        let constraint: Int

        init(_ values: [String], constraint: Int) {
            self.values = values
            self.constraint = constraint
        }
    }

    /// What one Apple OS does differently from the contract.
    struct Platform: Sendable {
        let os: String
        /// By option, the value the OS draws for a value it does not offer.
        let drawn: [String: [String: String]]
        /// The states the OS never enters.
        let notEntered: [String]

        init(_ os: String, drawn: [String: [String: String]], notEntered: [String]) {
            self.os = os
            self.drawn = drawn
            self.notEntered = notEntered
        }
    }

    /// One screenshot: the combinations with the values `fixed` of every option but the column one.
    public struct Sheet: Sendable, Identifiable {
        /// `size-s_role-default_iconOnly-false`: unique in its matrix.
        public let id: String
        /// The values of every option but the column option, in the options' order.
        let fixed: [String]
        /// The column option's values.
        let columns: [String]
        /// The states of the rows; nil is rest.
        let rows: [String?]

        init(_ id: String, fixed: [String], columns: [String], rows: [String?]) {
            self.id = id
            self.fixed = fixed
            self.columns = columns
            self.rows = rows
        }
    }

    /// What a cell of a sheet holds.
    public enum Cell: Sendable {
        /// A combination the current OS draws; `fallbacks` names the values it draws in place of the combination's.
        case drawn(Combination, fallbacks: [(option: String, value: String, drawn: String)])
        /// The combination a constraint forbids, by the constraint's index.
        case excluded(constraint: Int)
    }

    /// The four themes the matrix is captured in (decisions/0010): the name in file names and the catalog's launch
    /// arguments.
    public enum Theme: String, CaseIterable, Sendable {
        case light
        case dark
        case lightHighContrast = "light-hc"
        case darkHighContrast = "dark-hc"

        public var launchArguments: [String] {
            switch self {
            case .light: ["-WestronAppearance", "light", "-WestronContrast", "standard"]
            case .dark: ["-WestronAppearance", "dark", "-WestronContrast", "standard"]
            case .lightHighContrast: ["-WestronAppearance", "light", "-WestronContrast", "high"]
            case .darkHighContrast: ["-WestronAppearance", "dark", "-WestronContrast", "high"]
            }
        }
    }

    /// The contract's id.
    public let component: String
    let options: [Option]
    /// The contract's states, in its order.
    public let states: [String]
    let columnOption: String?
    let platforms: [Platform]
    let excluded: [Exclusion]
    let advisedAgainst: [Exclusion]
    /// Every combination of the matrix, on every OS.
    let combinations: [Combination]
    let allSheets: [Sheet]
    private let makeCell: @MainActor @Sendable (Combination) -> AnyView

    init<Content: View>(
        component: String, options: [Option], states: [String], columns: String?, platforms: [Platform],
        excluded: [Exclusion], advisedAgainst: [Exclusion], combinations: [Combination], sheets: [Sheet],
        @ViewBuilder cell: @escaping @MainActor @Sendable (Combination) -> Content
    ) {
        self.component = component
        self.options = options
        self.states = states
        self.columnOption = columns
        self.platforms = platforms
        self.excluded = excluded
        self.advisedAgainst = advisedAgainst
        self.combinations = combinations
        self.allSheets = sheets
        self.makeCell = { AnyView(cell($0)) }
    }

    /// `ios`, `macos` or `watchos`: the key of the current OS in the contract's `platforms.apple`.
    static var currentOS: String {
        #if os(iOS)
            "ios"
        #elseif os(macOS)
            "macos"
        #else
            "watchos"
        #endif
    }

    private var platform: Platform? { platforms.first { $0.os == Self.currentOS } }

    /// Whether the current OS ever enters a row's state; rest always.
    func isEntered(_ state: String?) -> Bool {
        state.map { !(platform?.notEntered.contains($0) ?? false) } ?? true
    }

    /// The rows of a sheet the current OS draws: the states it never enters are left out, as on the `button-states`
    /// pages.
    public func rows(of sheet: Sheet) -> [String?] {
        sheet.rows.filter(isEntered)
    }

    /// The combinations the current OS draws.
    public var drawnCombinations: [Combination] {
        combinations.filter { isEntered($0.state) }
    }

    /// The sheets the current OS draws: those with a row left.
    public var sheets: [Sheet] {
        allSheets.filter { !rows(of: $0).isEmpty }
    }

    private var columnIndex: Int? { options.firstIndex { $0.name == columnOption } }

    /// The option values of a cell: the sheet's fixed values with the column's value in its place.
    private func values(_ sheet: Sheet, column: String) -> [String] {
        var values = sheet.fixed
        if let columnIndex { values.insert(column, at: columnIndex) }
        return values
    }

    /// The cell of a sheet at a row and a column.
    public func cell(_ sheet: Sheet, row: String?, column: String) -> Cell {
        let values = values(sheet, column: column)
        let combination = Combination(values, state: row)
        if let exclusion = excluded.first(where: { $0.values == values }) {
            return .excluded(constraint: exclusion.constraint)
        }
        precondition(combinations.contains(combination), "\(component): no combination \(values), \(row ?? "rest")")
        var fallbacks: [(option: String, value: String, drawn: String)] = []
        for (option, value) in zip(options, values) {
            if let drawn = platform?.drawn[option.name]?[value] { fallbacks.append((option.name, value, drawn)) }
        }
        return .drawn(combination, fallbacks: fallbacks)
    }

    /// How many cells of a sheet the current OS draws.
    public func drawnCount(in sheet: Sheet) -> Int {
        rows(of: sheet).reduce(0) { count, row in
            count
                + sheet.columns.filter { column in
                    if case .drawn = cell(sheet, row: row, column: column) { return true }
                    return false
                }.count
        }
    }

    /// The option and value a sheet fixes, in the options' order: `[("size", "s"), ("role", "default")]`.
    public func fixedValues(of sheet: Sheet) -> [(option: String, value: String)] {
        let names = options.indices.filter { $0 != columnIndex }.map { options[$0].name }
        return Array(zip(names, sheet.fixed)).map { (option: $0.0, value: $0.1) }
    }

    /// `size s · role default · iconOnly false`.
    public func title(of sheet: Sheet) -> String {
        let fixed = fixedValues(of: sheet).map { "\($0.option) \($0.value)" }
        return fixed.isEmpty ? "every combination" : fixed.joined(separator: " · ")
    }

    /// The column option's name, or `""` for a contract without options.
    public var columnName: String { columnOption ?? "" }

    /// The sheet's key across matrices, `button.size-s_role-default_iconOnly-false`: the value of
    /// `-WestronMatrixSheet`, and the start of its file names.
    public func key(of sheet: Sheet) -> String { "\(component).\(sheet.id)" }

    /// The file name of a sheet's capture in a theme: `button.size-s_role-default_iconOnly-false.dark-hc.png`.
    public func fileName(of sheet: Sheet, theme: Theme) -> String { "\(key(of: sheet)).\(theme.rawValue).png" }

    /// Lines for the review page: what the current OS draws differently and what the constraints change.
    public var notes: [String] {
        var notes: [String] = []
        if let platform {
            for (option, map) in platform.drawn.sorted(by: { $0.key < $1.key }) {
                let pairs = map.sorted { $0.key < $1.key }.map { "\($0.key) → \($0.value)" }
                notes.append("This OS does not offer every \(option): it draws " + pairs.joined(separator: ", ") + ".")
            }
            if !platform.notEntered.isEmpty {
                notes.append(
                    "This OS never enters " + platform.notEntered.joined(separator: ", ")
                        + ": those rows are left out.")
            }
        }
        if !excluded.isEmpty {
            notes.append(
                "\(excluded.count) combinations of options are forbidden by a constraint and left out with every state."
            )
        }
        if !advisedAgainst.isEmpty {
            notes.append("\(advisedAgainst.count) combinations of options are advised against by a constraint; drawn.")
        }
        return notes
    }

    @MainActor
    func content(_ combination: Combination) -> AnyView {
        makeCell(combination)
    }

    /// A sheet by its key, `button.size-s_role-default_iconOnly-false`, among the sheets the current OS draws.
    public static func sheet(key: String) -> (matrix: ComponentMatrix, sheet: Sheet)? {
        for matrix in all {
            if let sheet = matrix.sheets.first(where: { matrix.key(of: $0) == key }) { return (matrix, sheet) }
        }
        return nil
    }
}
