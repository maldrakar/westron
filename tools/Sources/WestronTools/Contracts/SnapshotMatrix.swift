/// A component's snapshot matrix (#24), from its contract: every combination of its options, each at rest and in each
/// of its states, less what a constraint forbids, split into sheets that each fit one screenshot.
///
/// - The axes are the contract's options in its order: an enum option's values, `false` and `true` for a bool option,
///   and an option that is the system's own API on Apple (`platforms.apple.systemOptions`, Button's `role`) like any
///   other, since it changes the drawing.
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
///   `maxRows`, so a sheet fits an iPhone in portrait and the catalog's macOS window. A sheet whose every combination a
///   constraint forbids is left out.
public struct SnapshotMatrix: Equatable, Sendable {
    public struct Axis: Equatable, Sendable {
        public let name: String
        /// An enum option's values in the contract's order; `false`, `true` for a bool option.
        public let values: [String]
        public let isBool: Bool
        /// The system API that carries the option on Apple, such as `SwiftUI.ButtonRole`; nil for westron's own.
        public let systemType: String?
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
        /// The states of the rows; nil is rest.
        public let rows: [String?]
    }

    /// The most columns and rows of a sheet: three buttons of size l side by side fit an iPhone in portrait, and six
    /// rows of them the catalog's macOS window.
    public static let maxColumns = 3
    public static let maxRows = 6

    public let component: String
    public let axes: [Axis]
    /// The contract's states, in its order; the matrix adds rest before them.
    public let states: [String]
    /// The states no case of a token binding names, in the contract's order: they draw as rest.
    public let unboundStates: [String]
    /// The axis of the columns; nil when the contract has no options.
    public let columnAxis: String?
    /// In order: the first axis outermost, the state innermost, rest first.
    public let combinations: [Combination]
    /// Combinations of options that a constraint of severity `error` forbids, left out with every state.
    public let excluded: [Exclusion]
    /// Combinations of options that a constraint of severity `warning` advises against; they stay in the matrix.
    public let advisedAgainst: [Exclusion]
    /// The Apple OSes that differ from the contract, in `ComponentContract.appleOSes` order.
    public let platforms: [Platform]
    public let sheets: [Sheet]

    /// - Throws: `ContractProblem` when a value an Apple OS drops has no fallback; `spec check` rejects such a
    ///   contract first.
    public init(_ contract: ComponentContract, source: String) throws(ContractProblem) {
        component = contract.id
        let systemOptions = contract.apple?.systemOptions ?? [:]
        let axes = contract.options.map { option in
            switch option.kind {
            case .enumeration(let values, _):
                Axis(name: option.name, values: values, isBool: false, systemType: systemOptions[option.name])
            case .bool:
                Axis(
                    name: option.name, values: ["false", "true"], isBool: true, systemType: systemOptions[option.name])
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
        combinations = allowed.flatMap { tuple in rows.map { Combination(tuple, state: $0) } }

        var platforms: [Platform] = []
        if let apple = contract.apple {
            let applePath = DocumentPath.root.key("platforms").key("apple")
            for os in ComponentContract.appleOSes {
                var drawn: [(option: String, map: [(value: String, drawn: String)])] = []
                for axis in axes where !axis.isBool && axis.systemType == nil {
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

        let columnIndex =
            axes.firstIndex { $0.name == "variant" } ?? axes.firstIndex { !$0.isBool } ?? axes.indices.first
        columnAxis = columnIndex.map { axes[$0].name }
        let fixedAxes = axes.indices.filter { $0 != columnIndex }
        var fixedTuples: [[String]] = [[]]
        for index in fixedAxes {
            fixedTuples = fixedTuples.flatMap { tuple in axes[index].values.map { tuple + [$0] } }
        }
        let columnChunks = Self.chunks(columnIndex.map { axes[$0].values } ?? [""], of: Self.maxColumns)
        let rowChunks = Self.chunks(rows, of: Self.maxRows)
        let allowedSet = Set(allowed)
        var sheets: [Sheet] = []
        for fixed in fixedTuples {
            let base = zip(fixedAxes, fixed).map { "\(axes[$0.0].name)-\($0.1)" }
            for (columnNumber, columns) in columnChunks.enumerated() {
                // A sheet with no allowed combination is left out.
                let drawsSomething = columns.contains { column in
                    var tuple = fixed
                    if let columnIndex { tuple.insert(column, at: columnIndex) }
                    return allowedSet.contains(tuple)
                }
                guard drawsSomething else { continue }
                for (rowNumber, rowChunk) in rowChunks.enumerated() {
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
