/// A component's snapshot matrix (#24), from its contract: every combination of its options, each at rest and in each
/// of its states, less what a constraint forbids, split into sheets that each fit one screenshot.
///
/// - The axes are the contract's options in its order: an enum option's values, `false` and `true` for a bool option,
///   the tokens of its group for an option whose values are tokens (Text's `role`: the seventeen typography tokens, in
///   token order, read from `tokens/`), and an option that is the system's own API on Apple
///   (`platforms.apple.systemOptions`, Button's `role`) like any other, since it changes the drawing.
/// - Each combination of the axes is drawn at rest and in each state of the contract alone: the matrix shows what each
///   state does, and the contract's cases resolve states held at once.
/// - A combination that breaks a constraint of severity `error` is left out (spec/conventions.md, "Constraints between
///   options"); one that breaks a `warning` stays, and the catalog marks its cells as advised against.
/// - A state that no token binding of the contract names in a case changes no token, so it draws as rest
///   (`unboundStates`): Button's focus, whose ring the system draws on Apple. The catalog says so on the sheet.
/// - What each Apple OS does with it comes from `platforms.apple` and its OS entries: the value it draws for a value it
///   does not offer, and the states it never enters. The catalog leaves out the rows of states an OS never enters, as
///   the `button-states` pages do, and marks a cell whose value falls back.
/// - A sheet holds the combinations with one value of every axis but the column axis (the variant, else the first
///   option): its columns are the column axis's values and its rows rest and the states, at most `maxColumns` by
///   `maxRows`, so a sheet fits an iPhone in portrait and the catalog's macOS window at the default text size. A sheet
///   whose every combination a constraint forbids is left out.
/// - A contract with no states and an option whose values are the icon registry's names runs that option down the
///   rows instead (`rowAxis`): Icon's 36 glyphs at rest would otherwise make sheets of three glyphs each, twelve to a
///   scale. Its sheets hold one value of every other axis but the column axis, which is then the variant, else the
///   first other option that is not a bool.
/// - An optional option whose values are icons (`optional: true`, TextField's `leadingIcon`) is no axis: the matrix
///   draws every combination without the glyph, and the component's hand-written supplements draw it, marked "not a
///   contract option" as the other supplements are. A decoration would otherwise multiply every sheet.
/// - A contract with forms (`forms`) has the form as its first axis, `formAxis`, never the columns: each form is drawn
///   at rest and in each state it enters alone, on sheets of its own (`form-selectable`), and a form that enters no
///   state is drawn at rest only (spec/conventions.md, "Forms").
/// - An integer option (ListRow's `level`) is a quantity, not a choice, and is no axis: the hand-written cell draws
///   its sample at a value it names (ListRow's at level 1, so that `guides` shows), and what other values do is the
///   catalog's supplements'.
/// - A bool option with `nameInMatrixAtDefault: false` (Button's `floating`) is an axis like any other, but a sheet
///   names it only at its other value (`Axis.unnamed`): a sheet at its default keeps the id and the catalog's title it
///   had before the option was added, so its recorded reference stays the same file, and the sheets at the other value
///   are new ones beside them.
///
/// What the generator does not do (#72), so that the contract alone drives every generated combination and sheet: the
/// catalog (`WestronCatalog/SnapshotMatrix/ComponentMatrix.swift`) captures the sheets at other text sizes too and
/// splits a sheet into parts where it does not fit one picture at a text size, and a component's catalog code adds
/// hand-written supplementary sheets for what no contract option sets (Button's label without an icon), on these
/// sheets' axes and marked "not a contract option". Neither reaches this type or the generated files.
public struct SnapshotMatrix: Equatable, Sendable {
    public struct Axis: Equatable, Sendable {
        public let name: String
        /// An enum option's values in the contract's order; `false`, `true` for a bool option; a token option's
        /// tokens by their path after the group, in token order.
        public let values: [String]
        public let isBool: Bool
        /// The system API that carries the option on Apple, such as `SwiftUI.ButtonRole`; nil for westron's own.
        public let systemType: String?
        /// The token group a token option takes its values from, `typography`; nil for any other option.
        public let tokenGroup: String?
        /// The Swift accessor of the group's tokens on Apple, `Westron.TextRole` (`AppleComponents.tokenAccessors`);
        /// for an option whose values are icons, `Westron.Icon` (`AppleIcons.iconType`).
        public let accessor: String?
        /// Whether its values are the icon registry's names, in the registry's order.
        public let isIcons: Bool
        /// Whether it is the contract's forms (`forms`), not an option: the first axis of a contract with forms.
        public let isForm: Bool
        /// The value at which a sheet does not name the axis, in its id or its title: the default of a bool option
        /// with `nameInMatrixAtDefault: false`; nil for every other axis, named at every value.
        public let unnamed: String?

        init(
            name: String, values: [String], isBool: Bool = false, systemType: String? = nil, tokenGroup: String? = nil,
            accessor: String? = nil, isIcons: Bool = false, isForm: Bool = false, unnamed: String? = nil
        ) {
            self.name = name
            self.values = values
            self.isBool = isBool
            self.systemType = systemType
            self.tokenGroup = tokenGroup
            self.accessor = accessor
            self.isIcons = isIcons
            self.isForm = isForm
            self.unnamed = unnamed
        }
    }

    public struct Combination: Hashable, Sendable {
        /// The value of each axis, in the axes' order.
        public let values: [String]
        /// nil: at rest.
        public let state: String?

        public init(_ values: [String], state: String?) {
            self.values = values
            self.state = state
        }
    }

    /// Values of the axes, without a state, that a constraint matches, and which constraint, by its index.
    public struct Exclusion: Equatable, Sendable {
        public let values: [String]
        public let constraint: Int
    }

    /// What one Apple OS does differently from the contract.
    public struct Platform: Equatable, Sendable {
        /// `ios`, `macos` or `watchos`.
        public let os: String
        /// By option, the value the OS draws for each value it does not offer, in the option's order.
        public let drawn: [(option: String, map: [(value: String, drawn: String)])]
        /// The states it never enters, in the contract's order.
        public let notEntered: [String]

        public static func == (lhs: Platform, rhs: Platform) -> Bool {
            lhs.os == rhs.os && lhs.notEntered == rhs.notEntered
                && lhs.drawn.map(\.option) == rhs.drawn.map(\.option)
                && zip(lhs.drawn, rhs.drawn).allSatisfy { left, right in
                    left.map.map(\.value) == right.map.map(\.value) && left.map.map(\.drawn) == right.map.map(\.drawn)
                }
        }
    }

    public struct Sheet: Equatable, Sendable {
        /// `size-s_role-default_iconOnly-false`, with `_columns-<n>` or `_rows-<n>` where the axis is split.
        public let id: String
        /// The value of every axis but the column axis, in the axes' order.
        public let fixed: [String]
        /// Values of the column axis.
        public let columns: [String]
        /// The states of the rows, nil for rest; with a row axis, its values.
        public let rows: [String?]
    }

    /// The most columns and rows of a sheet: three buttons of size l side by side fit an iPhone in portrait, and six
    /// rows of them the catalog's macOS window.
    public static let maxColumns = 3
    public static let maxRows = 6

    /// The name of the axis of a contract with forms: its forms, each drawn in the states it enters.
    public static let formAxis = "form"

    public let component: String
    public let axes: [Axis]
    /// The contract's states, in its order; the matrix adds rest before them.
    public let states: [String]
    /// The states no case of a token binding names, in the contract's order: they draw as rest.
    public let unboundStates: [String]
    /// The axis of the columns; nil when the contract has no options.
    public let columnAxis: String?
    /// The axis down the rows in place of the states: an option whose values are icons, in a contract with no states;
    /// nil otherwise.
    public let rowAxis: String?
    /// In order: the first axis outermost, the state innermost, rest first.
    public let combinations: [Combination]
    /// Combinations of options that a constraint of severity `error` forbids, left out with every state.
    public let excluded: [Exclusion]
    /// Combinations of options that a constraint of severity `warning` advises against; they stay in the matrix.
    public let advisedAgainst: [Exclusion]
    /// The Apple OSes that differ from the contract, in `ComponentContract.appleOSes` order.
    public let platforms: [Platform]
    /// The Swift condition the matrix compiles under, `!os(watchOS)` for a component some Apple OS lacks
    /// (`ComponentContract.Apple.availabilityCondition`); nil when every Apple OS has it.
    public let availabilityCondition: String?
    public let sheets: [Sheet]
    /// Whether the forms are an own view's initializers rather than system controls (`own-component`).
    public let ownForms: Bool

    /// `tokens` gives the values of an option whose values are tokens, `icons` the registry's names, in its order, for
    /// one whose values are icons; a contract without such an option needs neither.
    /// - Throws: `ContractProblem` when a value an Apple OS drops has no fallback, which `spec check` rejects first;
    ///   when an option takes its values from a token group without the tokens, or from a group that has no accessor
    ///   of its own on Apple (`AppleComponents.tokenAccessors`), for the cell to take its value as; when an option
    ///   takes its values from the icon registry without its names.
    public init(
        _ contract: ComponentContract, source: String, tokens: ContractTokens? = nil, icons: [String]? = nil
    ) throws(ContractProblem) {
        component = contract.id
        ownForms = !contract.forms.isEmpty && contract.apple?.strategy == AppleComponents.ownStrategy
        let systemOptions = contract.apple?.systemOptions ?? [:]
        var axes: [Axis] = []
        // A contract with forms: the form first, each value drawn in the states that form enters.
        if !contract.forms.isEmpty {
            if contract.options.contains(where: { $0.name == Self.formAxis }) {
                throw ContractProblem(
                    source: source, path: .root.key("options").key(Self.formAxis),
                    "the matrix of a contract with forms has an axis \(Self.formAxis), the forms: rename the option")
            }
            axes.append(Axis(name: Self.formAxis, values: contract.forms.map(\.name), isForm: true))
        }
        for option in contract.options {
            switch option.kind {
            case .integer:
                // A quantity, not a choice: the cell names the value it draws, and the catalog's supplements show
                // others (ListRow's nesting levels).
                continue
            case .enumeration(let values, _):
                axes.append(Axis(name: option.name, values: values, systemType: systemOptions[option.name]))
            case .bool(let value):
                axes.append(
                    Axis(
                        name: option.name, values: ["false", "true"], isBool: true,
                        systemType: systemOptions[option.name],
                        unnamed: option.namedInMatrixAtDefault ? nil : String(value)))
            case .icons(optional: true):
                // An optional glyph is no axis: the matrix draws it absent, and hand-written supplements draw the
                // glyphs (spec/conventions.md, "Option whose values are icons"). As an axis it would multiply every
                // sheet for a decoration: TextField's two glyphs would take its 36 combinations to 144.
                continue
            case .icons(optional: false):
                guard let icons, !icons.isEmpty else {
                    throw ContractProblem(
                        source: source, path: .root.key("options").key(option.name),
                        "\(option.name) takes its values from the icon registry: the matrix needs its names")
                }
                axes.append(Axis(name: option.name, values: icons, accessor: AppleIcons.iconType, isIcons: true))
            case .tokenGroup(let group, _):
                let path = DocumentPath.root.key("options").key(option.name)
                guard let accessor = AppleComponents.tokenAccessors[group] else {
                    throw ContractProblem(
                        source: source, path: path.key("group"),
                        "\(option.name) takes its values from the tokens of \(group), which have no accessor of their "
                            + "own on Apple for a matrix cell to take them as (AppleComponents.tokenAccessors)")
                }
                guard let tokens else {
                    throw ContractProblem(
                        source: source, path: path,
                        "\(option.name) takes its values from the tokens of \(group): the matrix needs the tokens")
                }
                let found = tokens.group(TokenPath(group))
                guard found.problems.isEmpty, !found.values.isEmpty else {
                    throw ContractProblem(
                        source: source, path: path.key("group"), found.problems.joined(separator: "; "))
                }
                axes.append(
                    Axis(name: option.name, values: found.values, tokenGroup: group, accessor: accessor))
            }
        }
        self.axes = axes
        states = contract.states
        unboundStates = contract.states.filter { !contract.boundStates.contains($0) }
        let names = axes.map(\.name)

        var tuples: [[String]] = [[]]
        for axis in axes {
            tuples = tuples.flatMap { tuple in axis.values.map { tuple + [$0] } }
        }
        var excluded: [Exclusion] = []
        var advised: [Exclusion] = []
        var allowed: [[String]] = []
        for tuple in tuples {
            let values = Dictionary(uniqueKeysWithValues: zip(names, tuple))
            let broken = contract.constraints.indices.filter { contract.constraints[$0].isBroken(by: values) }
            if let forbidding = broken.first(where: { contract.constraints[$0].forbids }) {
                excluded.append(Exclusion(values: tuple, constraint: forbidding))
                continue
            }
            if let advising = broken.first { advised.append(Exclusion(values: tuple, constraint: advising)) }
            allowed.append(tuple)
        }
        self.excluded = excluded
        advisedAgainst = advised
        let rows: [String?] = [nil] + contract.states
        // By form, the rows it is drawn in: rest and the states it enters.
        let formRows = Dictionary(
            uniqueKeysWithValues: contract.forms.map { form in (form.name, [nil] + form.states.map(Optional.some)) })
        let formIndex = axes.firstIndex(where: \.isForm)
        func rowsOf(_ tuple: [String]) -> [String?] {
            formIndex.flatMap { formRows[tuple[$0]] } ?? rows
        }
        combinations = allowed.flatMap { tuple in rowsOf(tuple).map { Combination(tuple, state: $0) } }

        var platforms: [Platform] = []
        if let apple = contract.apple {
            let applePath = DocumentPath.root.key("platforms").key("apple")
            // An OS where the component is unavailable has no matrix at all, rather than one that differs.
            for os in apple.availableOSes {
                var drawn: [(option: String, map: [(value: String, drawn: String)])] = []
                // A token or icons option has no platform restriction: spec check rejects one that names it; the
                // forms are not an option.
                for axis in axes where !axis.isBool && axis.systemType == nil && axis.accessor == nil && !axis.isForm {
                    var map: [(value: String, drawn: String)] = []
                    for value in axis.values {
                        let target = try AppleComponents.API.drawn(
                            value, of: axis.name, values: axis.values, apple: apple, os: os, at: applePath,
                            source: source)
                        if target != value { map.append((value, target)) }
                    }
                    if !map.isEmpty { drawn.append((axis.name, map)) }
                }
                let entered = apple.targets[os]?.states ?? apple.restriction.states ?? contract.states
                let notEntered = contract.states.filter { !entered.contains($0) }
                if !drawn.isEmpty || !notEntered.isEmpty {
                    platforms.append(Platform(os: os, drawn: drawn, notEntered: notEntered))
                }
            }
        }
        self.platforms = platforms
        availabilityCondition = contract.apple?.availabilityCondition

        let rowIndex = contract.states.isEmpty ? axes.firstIndex(where: \.isIcons) : nil
        rowAxis = rowIndex.map { axes[$0].name }
        let others = axes.indices.filter { $0 != rowIndex }
        // The forms are never the columns: each form has a sheet of its own, in its own states.
        let columnIndex =
            others.first { axes[$0].name == "variant" && !axes[$0].isForm }
            ?? others.first { !axes[$0].isBool && !axes[$0].isForm } ?? others.first { !axes[$0].isForm }
        columnAxis = columnIndex.map { axes[$0].name }
        let fixedAxes = others.filter { $0 != columnIndex }
        var fixedTuples: [[String]] = [[]]
        for index in fixedAxes {
            fixedTuples = fixedTuples.flatMap { tuple in axes[index].values.map { tuple + [$0] } }
        }
        let columnChunks = Self.chunks(columnIndex.map { axes[$0].values } ?? [""], of: Self.maxColumns)
        let allowedSet = Set(allowed)
        var sheets: [Sheet] = []
        for fixed in fixedTuples {
            // The rows of this sheet: the row axis, or rest and the states, of its form where it has one.
            let form = fixedAxes.firstIndex { axes[$0].isForm }.map { fixed[$0] }
            let rowValues: [String?] =
                rowIndex.map { axes[$0].values.map { Optional($0) } } ?? form.flatMap { formRows[$0] } ?? rows
            let rowChunks = Self.chunks(rowValues, of: Self.maxRows)
            // An axis at the value it is not named at (`Axis.unnamed`) is left out of the id.
            let base = zip(fixedAxes, fixed).filter { axes[$0.0].unnamed != $0.1 }.map { "\(axes[$0.0].name)-\($0.1)" }
            for (columnNumber, columns) in columnChunks.enumerated() {
                // A sheet with no allowed combination is left out.
                for (rowNumber, rowChunk) in rowChunks.enumerated() {
                    let drawsSomething = columns.contains { column in
                        rowChunk.contains { row in
                            let rowValue = rowIndex.map { (index: $0, value: row ?? "") }
                            return allowedSet.contains(
                                Self.values(fixed, column: (columnIndex, column), row: rowValue))
                        }
                    }
                    guard drawsSomething else { continue }
                    var parts = base.isEmpty ? ["all"] : base
                    if columnChunks.count > 1 { parts.append("columns-\(columnNumber + 1)") }
                    if rowChunks.count > 1 { parts.append("rows-\(rowNumber + 1)") }
                    sheets.append(
                        Sheet(id: parts.joined(separator: "_"), fixed: fixed, columns: columns, rows: rowChunk))
                }
            }
        }
        self.sheets = sheets
    }

    /// The values of every axis: the fixed ones with the column's and the row's in their places.
    static func values(_ fixed: [String], column: (index: Int?, value: String), row: (index: Int, value: String)?)
        -> [String]
    {
        var inserted: [(index: Int, value: String)] = []
        if let index = column.index { inserted.append((index, column.value)) }
        if let row { inserted.append(row) }
        var values = fixed
        for item in inserted.sorted(by: { $0.index < $1.index }) { values.insert(item.value, at: item.index) }
        return values
    }

    private static func chunks<T>(_ items: [T], of size: Int) -> [[T]] {
        stride(from: 0, to: items.count, by: size).map { Array(items[$0..<min($0 + size, items.count)]) }
    }

    /// The combinations an Apple OS draws: all but those in states it never enters.
    public func combinations(on os: String) -> [Combination] {
        let notEntered = platforms.first { $0.os == os }?.notEntered ?? []
        return combinations.filter { combination in combination.state.map { !notEntered.contains($0) } ?? true }
    }

    /// How many combinations of options there are before constraints: the product of the axes' sizes.
    public var optionCombinations: Int { axes.map(\.values.count).reduce(1, *) }
}
