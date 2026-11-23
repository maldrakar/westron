import SwiftUI

/// A component's snapshot matrix (#24): every combination of its contract's options, each at rest and in each of its
/// states alone, less what a constraint forbids, on sheets that each fit one screenshot.
///
/// `tools/westron generate` writes each component's matrix from its contract into `Generated/<Component>+Matrix.swift`
/// and the list of them into `Generated/ComponentMatrix+All.swift`; the hand-written `<Component>MatrixCell` draws one
/// cell with the real component. The matrix is not a catalog entry: `Catalog.entries` drives the accessibility audit,
/// and the matrix is for the owner's review, so the catalog shows a sheet only with `-WestronMatrixSheet`, and
/// `tools/apple/snapshot-matrix.sh` captures every sheet in every theme at the default text size, and in the light
/// theme at the smallest and the largest text size (`Capture`).
///
/// Two things here are the catalog's, not the contract's (#72): a text size at which a generated sheet does not fit one
/// picture, or whose cells do not fit side by side on the device, splits it into parts (`pictures(of:at:columns:)`),
/// and a component's catalog code may add supplementary sheets for what no contract option sets (`Supplement`,
/// `supplements`), hand-written on the generated axes and marked as such.
/// Neither changes the generated matrix: the contract still drives every generated sheet and combination.
public struct ComponentMatrix: Sendable {
    struct Option: Sendable {
        let name: String
        /// An enum option's values; `false` and `true` for a bool option.
        let values: [String]
        /// The system API that carries the option on Apple, such as `SwiftUI.ButtonRole`.
        let system: String?
        /// The value at which a sheet does not name the option, in its id or its title: the default of an option with
        /// `nameInMatrixAtDefault: false` in the contract (Button's `floating`); nil: named at every value.
        let unnamed: String?

        init(_ name: String, values: [String], system: String? = nil, unnamed: String? = nil) {
            self.name = name
            self.values = values
            self.system = system
            self.unnamed = unnamed
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

    /// One screenshot: the combinations with the values `fixed` of every option but the column one, and the row one
    /// where the matrix has one.
    public struct Sheet: Sendable, Identifiable {
        /// `size-s_role-default_iconOnly-false`: unique in its matrix; a part adds `_part-<n>-of-<count>`.
        public let id: String
        /// The values of every option but the column option and the row option, in the options' order.
        let fixed: [String]
        /// The column option's values.
        let columns: [String]
        /// The states of the rows, nil for rest; with a row option (`rowOption`), its values.
        let rows: [String?]
        /// For a part of a sheet that does not fit one picture at a text size (`pictures(of:at:columns:)`), its number
        /// from 1 and the number of parts; nil for a whole sheet.
        public let part: (number: Int, count: Int)?

        init(
            _ id: String, fixed: [String], columns: [String], rows: [String?],
            part: (number: Int, count: Int)? = nil
        ) {
            self.id = id
            self.fixed = fixed
            self.columns = columns
            self.rows = rows
            self.part = part
        }
    }

    /// A group of hand-written sheets for what a contract option does not set, such as Button's label without an
    /// icon (#72). Its sheets are the generated sheets that keep the option values in `keeps`, with their axes, states
    /// and rows as generated, and each cell is drawn by `cell` instead of the matrix's cell: nothing the contract
    /// already lists is listed again by hand. The sheet and the review page mark them "not a contract option".
    public struct Supplement: Sendable {
        /// The contract's id of the component.
        public let component: String
        /// `label-without-icon`: the start of its sheets' ids.
        public let id: String
        /// `label without an icon`.
        public let title: String
        /// What it shows and why no contract option sets it; the sheet and the review page show it.
        public let note: String
        /// Contract options and the value each keeps; the column option and the row option are not among them.
        let keeps: [String: String]
        /// For a matrix whose rows are an option (Icon's glyphs), the values of it the supplement keeps, so that it
        /// draws one sheet of a few rows rather than every generated sheet again; nil keeps every row.
        let rows: [String]?
        /// The values of the column option the supplement keeps, so that a column whose every cell a constraint forbids
        /// on its sheets is not drawn again (Button's tertiary, which does not float); nil keeps every column.
        let columns: [String]?
        /// The most rows of one picture at a text size that splits sheets (`TextSize.limit`), where its cells are
        /// taller than a generated cell; nil takes the text size's own limit.
        let rowsPerPicture: Int?
        /// The OSes it is drawn on, as `currentOS` names them, where a render on another is not worth reading or not
        /// the same twice (its note says why); nil draws it on every OS.
        let onlyOn: [String]?
        /// Whether `rowsPerPicture` splits the sheet at every text size, also one that splits no generated sheet: for
        /// a cell of several stacked components (ListRow's tree), too tall for a sheet's rows at any size.
        let splitsAtEverySize: Bool
        /// The most columns of one picture at every text size, for a cell that needs a sheet's whole width (ListRow
        /// forced to accessibility5); nil: as many as the text size takes.
        let columnsPerPicture: Int?
        /// The OSes, as `currentOS` names them, where its pictures are drawn and shown but not the same from one render
        /// to the next (the system's glass on the iOS simulator), and why: there the comparison holds them to their
        /// presence and size, not their pixels (`tools/apple/snapshot-matrix.sh`, "not compared"). nil compares them
        /// pixel by pixel on every OS. Not a tolerance: how far such a picture varies is not known.
        let notCompared: NotCompared?
        let cell: @MainActor @Sendable (Combination) -> AnyView

        /// Where a supplement's pictures are not compared pixel by pixel, and why (`notCompared`).
        struct NotCompared: Sendable {
            /// The OSes, as `currentOS` names them.
            let on: [String]
            /// For the review page and the comparison's report: what varies, and what holds the look instead.
            let reason: String
        }

        init<Content: View>(
            component: String, id: String, title: String, note: String, keeps: [String: String],
            rows: [String]? = nil, columns: [String]? = nil, rowsPerPicture: Int? = nil, onlyOn: [String]? = nil,
            splitsAtEverySize: Bool = false, columnsPerPicture: Int? = nil, notCompared: NotCompared? = nil,
            @ViewBuilder cell: @escaping @MainActor @Sendable (Combination) -> Content
        ) {
            precondition(
                notCompared.map { !$0.on.isEmpty && !$0.reason.isEmpty } ?? true,
                "\(component), supplement \(id): notCompared names no OS or gives no reason")
            self.notCompared = notCompared
            self.rowsPerPicture = rowsPerPicture
            self.onlyOn = onlyOn
            self.splitsAtEverySize = splitsAtEverySize
            self.columnsPerPicture = columnsPerPicture
            self.component = component
            self.id = id
            self.title = title
            self.note = note
            self.keeps = keeps
            self.rows = rows
            self.columns = columns
            self.cell = { AnyView(cell($0)) }
        }
    }

    /// By component, the most rows of one picture at a text size that splits sheets, where its cells grow taller
    /// than the size's own limit allows: a ListRow at accessibility5 on an iPhone wraps its words over several lines
    /// beside its scaled indent and slots, about 230 pt a row, and a supplement's cell holds several rows.
    static let rowsAtLimit: [String: Int] = ["list-row": 1, "disclosure": 1]

    /// The text sizes the matrix is captured at (design-language/08-accessibility.md, "Text size"): the smallest, the
    /// default and the largest accessibility size, the one the accessibility audit uses. The names are the catalog's
    /// `-WestronDynamicType` values, which are SwiftUI's `DynamicTypeSize` cases.
    public enum TextSize: String, CaseIterable, Sendable {
        case xSmall
        case large
        case accessibility5

        public var launchArguments: [String] { ["-WestronDynamicType", rawValue] }

        /// The themes a sheet is captured in at this size: all four at the default; the light theme alone at the
        /// others, which show how the component grows with the text, not its colors.
        public var themes: [Theme] { self == .large ? Theme.allCases : [.light] }

        /// The most columns and rows of one picture at this size, whatever the cells; nil when a generated sheet (at
        /// most 3 × 6) may fit whole, and the snapshot tests split it only where its cells do not fit side by side
        /// (`pictures(of:at:columns:)`). At accessibility5 a button of size l with an icon and a label takes about 320
        /// of an iPhone 17's 402 points, so a picture holds one column of a sheet: its six rows fit the screen's height
        /// under a short header (`MatrixSheetView`).
        var limit: (columns: Int, rows: Int)? {
            #if os(macOS)
                nil
            #else
                self == .accessibility5 ? (columns: 1, rows: 6) : nil
            #endif
        }

        /// The text sizes the current OS is captured at, the default first. macOS has no Dynamic Type: SwiftUI there
        /// draws the same at every `dynamicTypeSize` (`ComponentMatrixTests`), so a Mac is captured at the default
        /// alone.
        public static var captured: [TextSize] {
            #if os(macOS)
                [.large]
            #else
                [.large, .xSmall, .accessibility5]
            #endif
        }

        /// Why the current OS is captured at fewer text sizes, for the review page; nil when it takes them all.
        public static var notCapturedNote: String? {
            #if os(macOS)
                "macOS has no Dynamic Type: SwiftUI draws a component the same at every text size there (the catalog's "
                    + "-WestronDynamicType changes nothing on a Mac; ComponentMatrixTests checks it), so the matrix is "
                    + "captured at the default text size only."
            #else
                nil
            #endif
        }
    }

    /// One capture of every sheet: a theme at a text size.
    public struct Capture: Hashable, Sendable {
        public let theme: Theme
        public let textSize: TextSize

        public init(theme: Theme, textSize: TextSize) {
            self.theme = theme
            self.textSize = textSize
        }

        /// The capture's name in file names and in the manifest: the theme at the default text size, `dark-hc`, as
        /// before text sizes were captured; the theme and the size at another, `light.accessibility5`.
        public var name: String { textSize == .large ? theme.rawValue : "\(theme.rawValue).\(textSize.rawValue)" }

        public var launchArguments: [String] { theme.launchArguments + textSize.launchArguments }

        /// Every capture of the current OS: the four themes at the default text size, then each other text size in
        /// the light theme.
        public static var all: [Capture] {
            TextSize.captured.flatMap { size in size.themes.map { Capture(theme: $0, textSize: size) } }
        }
    }

    /// What a cell of a sheet holds.
    public enum Cell: Sendable {
        /// A combination the current OS draws; `fallbacks` names the values it draws in place of the combination's,
        /// `advisedAgainst` the index of a constraint of severity `warning` the combination breaks.
        case drawn(
            Combination, fallbacks: [(option: String, value: String, drawn: String)], advisedAgainst: Int?)
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
    /// The states no case of a token binding names: they draw as rest, and only what the platform adds itself, such
    /// as the system's focus ring, which a screenshot does not show, would tell them apart.
    public let unboundStates: [String]
    let columnOption: String?
    /// The option down the rows in place of the states: Icon's glyphs, in a contract with no states; nil otherwise.
    public let rowOption: String?
    let platforms: [Platform]
    let excluded: [Exclusion]
    let advisedAgainst: [Exclusion]
    /// Every combination of the matrix, on every OS.
    private(set) var combinations: [Combination]
    private(set) var allSheets: [Sheet]
    private var makeCell: @MainActor @Sendable (Combination) -> AnyView
    /// The supplement whose sheets these are (`supplements`); nil for the matrix generated from the contract.
    public private(set) var supplement: Supplement?

    init<Content: View>(
        component: String, options: [Option], states: [String], unbound: [String], columns: String?,
        rows: String? = nil, platforms: [Platform],
        excluded: [Exclusion], advisedAgainst: [Exclusion], combinations: [Combination], sheets: [Sheet],
        @ViewBuilder cell: @escaping @MainActor @Sendable (Combination) -> Content
    ) {
        self.component = component
        self.options = options
        self.states = states
        self.unboundStates = unbound
        self.columnOption = columns
        self.rowOption = rows
        self.platforms = platforms
        self.excluded = excluded
        self.advisedAgainst = advisedAgainst
        self.combinations = combinations
        self.allSheets = sheets
        self.makeCell = { AnyView(cell($0)) }
        self.supplement = nil
    }

    /// The component's supplementary sheets (`Supplement.all`) on the current OS, each group as a matrix of its own:
    /// the combinations and the sheets of this matrix that keep the supplement's values, the sheets' ids starting with
    /// the supplement's id, and the supplement's cell. Empty for a supplement itself.
    public var supplements: [ComponentMatrix] {
        guard supplement == nil else { return [] }
        return Supplement.all.filter { $0.component == component && ($0.onlyOn?.contains(Self.currentOS) ?? true) }
            .map(supplemented(by:))
    }

    private func supplemented(by supplement: Supplement) -> ComponentMatrix {
        let kept = supplement.keeps.sorted { $0.key < $1.key }.map { name, value in
            guard let index = options.firstIndex(where: { $0.name == name }), name != columnOption, name != rowOption,
                options[index].values.contains(value)
            else {
                preconditionFailure("\(component), supplement \(supplement.id): no option \(name) with value \(value)")
            }
            return (index: index, value: value)
        }
        let keeps = { (values: [String]) in kept.allSatisfy { values[$0.index] == $0.value } }
        var matrix = self
        matrix.combinations = combinations.filter { combination in
            guard keeps(combination.values) else { return false }
            guard let rows = supplement.rows, let rowIndex else { return true }
            return rows.contains(combination.values[rowIndex])
        }
        let keptSheets = allSheets.filter { sheet in keeps(values(sheet, column: sheet.columns[0], row: sheet.rows[0]))
        }.map { sheet in
            guard let columns = supplement.columns else { return sheet }
            return Sheet(
                sheet.id, fixed: sheet.fixed, columns: sheet.columns.filter(columns.contains), rows: sheet.rows)
        }.filter { !$0.columns.isEmpty }
        if let rows = supplement.rows {
            // A supplement that names rows of a row option draws those alone, on one sheet per value of the other
            // axes, its columns the generated sheets' in their order.
            var merged: [Sheet] = []
            for sheet in keptSheets {
                if let index = merged.firstIndex(where: { $0.fixed == sheet.fixed }) {
                    let columns = merged[index].columns + sheet.columns.filter { !merged[index].columns.contains($0) }
                    merged[index] = Sheet(merged[index].id, fixed: sheet.fixed, columns: columns, rows: rows)
                } else {
                    let fixed = namedValues(of: sheet).map { "\($0.option)-\($0.value)" }
                    let id = "\(supplement.id)_" + (fixed.isEmpty ? "all" : fixed.joined(separator: "_"))
                    merged.append(Sheet(id, fixed: sheet.fixed, columns: sheet.columns, rows: rows))
                }
            }
            matrix.allSheets = merged
        } else {
            matrix.allSheets = keptSheets.map { sheet in
                Sheet("\(supplement.id)_\(sheet.id)", fixed: sheet.fixed, columns: sheet.columns, rows: sheet.rows)
            }
        }
        matrix.makeCell = supplement.cell
        matrix.supplement = supplement
        return matrix
    }

    /// Why the comparison holds this supplement's pictures on the current OS to their presence and size, not their
    /// pixels (`Supplement.notCompared`); nil where it compares them pixel by pixel, and for the generated matrix.
    var notComparedReason: String? {
        supplement?.notCompared.flatMap { $0.on.contains(Self.currentOS) ? $0.reason : nil }
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

    /// Whether the current OS ever enters a row's state; rest, and a row of a row option, always.
    func isEntered(_ state: String?) -> Bool {
        guard rowOption == nil else { return true }
        return state.map { !(platform?.notEntered.contains($0) ?? false) } ?? true
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

    /// The pictures a sheet is captured in at a text size: the sheet itself where it fits, otherwise its parts, the
    /// columns and the rows the current OS draws taken `TextSize.limit` at a time, column by column, top to bottom.
    /// `columns` caps the columns of one picture further, where the sheet's cells do not fit side by side at that text
    /// size: the snapshot tests find that by drawing the sheet and checking each cell's width against the width it
    /// needs (SnapshotMatrixRenderTests, "squeezed"), and take fewer columns to a picture until they fit. The split is
    /// the catalog's, not the contract's: on one device the parts are the same on every run.
    public func pictures(of sheet: Sheet, at size: TextSize, columns: Int? = nil) -> [Sheet] {
        let columnLimit = min(
            size.limit?.columns ?? sheet.columns.count, columns ?? sheet.columns.count,
            supplement?.columnsPerPicture ?? sheet.columns.count)
        let rows = rows(of: sheet)
        // Rows are split only at a text size whose cells are too tall for a sheet's rows to fit the screen's height,
        // or at every size for a supplement whose cells are that tall at every size. A component whose cells grow
        // taller than the text size's limit allows (`rowsAtLimit`) takes fewer.
        let everySize = supplement?.splitsAtEverySize == true ? supplement?.rowsPerPicture : nil
        let rowLimit =
            size.limit.map {
                min($0.rows, supplement?.rowsPerPicture ?? $0.rows, Self.rowsAtLimit[component] ?? $0.rows)
            } ?? everySize ?? max(rows.count, 1)
        let parts = Self.groups(sheet.columns, ofAtMost: max(columnLimit, 1)).flatMap { columns in
            Self.chunks(rows, of: rowLimit).map { (columns: columns, rows: $0) }
        }
        guard parts.count > 1 else { return [sheet] }
        return parts.enumerated().map { index, part in
            Sheet(
                "\(sheet.id)_part-\(index + 1)-of-\(parts.count)", fixed: sheet.fixed, columns: part.columns,
                rows: part.rows, part: (number: index + 1, count: parts.count))
        }
    }

    private static func chunks<T>(_ items: [T], of size: Int) -> [[T]] {
        stride(from: 0, to: items.count, by: size).map { Array(items[$0..<min($0 + size, items.count)]) }
    }

    /// The items in as few groups of at most `size` as there can be, the groups as even as they can be, the larger
    /// first: five columns of at most three to a picture go three and two, of at most four three and two as well. So
    /// a part's name, which counts the parts, tells which columns it holds (`sheet(key:)`).
    private static func groups<T>(_ items: [T], ofAtMost size: Int) -> [[T]] {
        guard !items.isEmpty else { return [] }
        let count = (items.count + size - 1) / size
        var groups: [[T]] = []
        var start = 0
        for index in 0..<count {
            let length = items.count / count + (index < items.count % count ? 1 : 0)
            groups.append(Array(items[start..<start + length]))
            start += length
        }
        return groups
    }

    private var columnIndex: Int? { options.firstIndex { $0.name == columnOption } }
    private var rowIndex: Int? { options.firstIndex { $0.name == rowOption } }

    /// The option values of a cell: the sheet's fixed values with the column's value, and the row's where the rows are
    /// an option, in their places.
    private func values(_ sheet: Sheet, column: String, row: String?) -> [String] {
        var inserted: [(index: Int, value: String)] = []
        if let columnIndex { inserted.append((columnIndex, column)) }
        if let rowIndex, let row { inserted.append((rowIndex, row)) }
        var values = sheet.fixed
        for item in inserted.sorted(by: { $0.index < $1.index }) { values.insert(item.value, at: item.index) }
        return values
    }

    /// The cell of a sheet at a row and a column.
    public func cell(_ sheet: Sheet, row: String?, column: String) -> Cell {
        let values = values(sheet, column: column, row: row)
        let combination = Combination(values, state: rowOption == nil ? row : nil)
        if let exclusion = excluded.first(where: { $0.values == values }) {
            return .excluded(constraint: exclusion.constraint)
        }
        precondition(combinations.contains(combination), "\(component): no combination \(values), \(row ?? "rest")")
        var fallbacks: [(option: String, value: String, drawn: String)] = []
        for (option, value) in zip(options, values) {
            if let drawn = platform?.drawn[option.name]?[value] { fallbacks.append((option.name, value, drawn)) }
        }
        let advised = advisedAgainst.first { $0.values == values }?.constraint
        return .drawn(combination, fallbacks: fallbacks, advisedAgainst: advised)
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
        let names = options.indices.filter { $0 != columnIndex && $0 != rowIndex }.map { options[$0].name }
        return Array(zip(names, sheet.fixed)).map { (option: $0.0, value: $0.1) }
    }

    /// The values a sheet fixes that its id and title name: all but an option at the value it is not named at
    /// (`Option.unnamed`), so that the sheets of a button that does not float keep the names they had before `floating`.
    func namedValues(of sheet: Sheet) -> [(option: String, value: String)] {
        fixedValues(of: sheet).filter { fixed in options.first { $0.name == fixed.option }?.unnamed != fixed.value }
    }

    /// `size s · role default · iconOnly false`; a supplement's title first, `label without an icon · size s · …`.
    /// A part's number is not in it (`partTitle(of:)`).
    public func title(of sheet: Sheet) -> String {
        let fixed = namedValues(of: sheet).map { "\($0.option) \($0.value)" }
        let title = fixed.isEmpty ? "every combination" : fixed.joined(separator: " · ")
        return supplement.map { "\($0.title) · \(title)" } ?? title
    }

    /// `part 2 of 6: primary; hover, focus, pressed`, what a part of a sheet holds; nil for a whole sheet.
    public func partTitle(of sheet: Sheet) -> String? {
        guard let part = sheet.part else { return nil }
        let rows = rows(of: sheet).map { $0 ?? "rest" }.joined(separator: ", ")
        return "part \(part.number) of \(part.count): \(sheet.columns.joined(separator: ", ")); \(rows)"
    }

    /// The column option's name, or `""` for a contract without options.
    public var columnName: String { columnOption ?? "" }

    /// What the rows are, for the sheet and the review page: `rest and each state alone`, or the row option's name.
    public var rowsName: String { rowOption ?? "rest and each state alone" }

    /// The sheet's key across matrices, `button.size-s_role-default_iconOnly-false`: the value of
    /// `-WestronMatrixSheet`, and the start of its file names.
    public func key(of sheet: Sheet) -> String { "\(component).\(sheet.id)" }

    /// The file name of a sheet's picture in a capture: `button.size-s_role-default_iconOnly-false.dark-hc.png` at the
    /// default text size, `button.size-s_role-default_iconOnly-false_part-1-of-6.light.accessibility5.png` at another.
    public func fileName(of sheet: Sheet, capture: Capture) -> String { "\(key(of: sheet)).\(capture.name).png" }

    /// A note a component's catalog code gives its generated sheets that fix an option at a value, for what the sheet
    /// draws that its title does not say (Button's floating sheets draw the look where there is no glass). Hand-written
    /// beside the component's cell, registered in `all`.
    public struct SheetNote: Sendable {
        let component: String
        let option: String
        let value: String
        let text: String

        /// Every component's sheet notes.
        static let all: [SheetNote] = [.buttonFloatingWithoutGlass]
    }

    /// The note of a generated sheet that fixes an option at a value a `SheetNote` names; nil for any other sheet and
    /// for a supplement's, which has its own.
    public func sheetNote(of sheet: Sheet) -> String? {
        guard supplement == nil else { return nil }
        let fixed = fixedValues(of: sheet)
        return SheetNote.all.first { note in
            note.component == component && fixed.contains { $0.option == note.option && $0.value == note.value }
        }?.text
    }

    /// What the sheet and the review page say about the states that draw as rest; nil when every state is bound.
    public var unboundNote: String? {
        guard !unboundStates.isEmpty else { return nil }
        let names = unboundStates.joined(separator: ", ")
        let rows = unboundStates.count == 1 ? "its row looks" : "their rows look"
        return "No token binding of the contract depends on \(names), so \(rows) at rest; what the platform draws "
            + "itself, such as the system's focus ring, is not in the picture."
    }

    /// Lines for the review page: what the current OS draws differently, the states that draw as rest, and what the
    /// constraints change.
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
        if let note = unboundNote { notes.append(note) }
        if !advisedAgainst.isEmpty {
            notes.append("\(advisedAgainst.count) combinations of options are advised against by a constraint; drawn.")
        }
        return notes
    }

    @MainActor
    func content(_ combination: Combination) -> AnyView {
        makeCell(combination)
    }

    /// A sheet by its key, `button.size-s_role-default_iconOnly-false`, among the sheets the current OS draws, their
    /// parts at every text size and with every cap of columns to a picture (`pictures(of:at:columns:)`), and the
    /// supplements' sheets and parts. Two splits that give a part the same name give it the same columns and rows.
    public static func sheet(key: String) -> (matrix: ComponentMatrix, sheet: Sheet)? {
        for matrix in all.flatMap({ [$0] + $0.supplements }) {
            for sheet in matrix.sheets {
                guard key == matrix.key(of: sheet) || key.hasPrefix(matrix.key(of: sheet) + "_part-") else { continue }
                let pictures =
                    [sheet]
                    + TextSize.allCases.flatMap { size in
                        (1...max(sheet.columns.count, 1)).reversed().flatMap {
                            matrix.pictures(of: sheet, at: size, columns: $0)
                        }
                    }
                if let found = pictures.first(where: { matrix.key(of: $0) == key }) { return (matrix, found) }
            }
        }
        return nil
    }
}
