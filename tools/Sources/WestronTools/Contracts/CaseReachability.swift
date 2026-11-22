/// Which cases of a token binding are never used: cases apply first match, so a case is unreachable when every
/// combination it matches is matched by some earlier case, by one alone or by several together (#62).
///
/// A combination is a value of each option and a set of states, since a component can be in several states at once.
/// A case's `when` matches when each option it names has one of the listed values and, if it names `state`, the
/// component is in at least one of the listed states; a case without `state` matches every set of states, none
/// included.
///
/// Options are finite (an enum's values, a bool's `true` and `false`), so the check enumerates their values; only
/// the options some case names are enumerated, since the others change no match. States are not enumerated: for one
/// value of each option, the earlier cases that match those values either include one without `state`, which takes
/// every set of states, or together name a set of states U. A case naming states S then still matches a set the
/// earlier ones miss exactly when S has a state outside U (the component in that state alone), and a case without
/// `state` exactly when no earlier case lacks `state` (the component in no state). So the work is the product of the
/// value counts of the named options times the number of cases, whatever the number of states: Button's
/// `container.background` names variant (3 values) and role (2), 6 combinations. Past `limit` combinations the check
/// reports the binding instead of checking it.
///
/// A case may instead require several states at once (`state: {all: [checked, pressed]}`): it matches only when the
/// component is in every one of them. The shortcut above does not hold for such a case, so a binding with one is
/// checked by enumeration: every combination of option values with every set of the states its cases name, 2ⁿ sets
/// for n states (Chip's `container.background` names four states and no option: 16 sets). The count it enumerates is
/// the option combinations times 2ⁿ, held to the same `limit`, past which the binding is reported instead; with 20
/// states named it is past the limit even with no option.
struct CaseReachability {
    /// One case's `when`: by option, the values it accepts; the states it names, any of which matches, or nil when it
    /// names none; the states it requires all at once, or nil.
    struct Case: Equatable {
        let options: [String: Set<String>]
        let states: Set<String>?
        var allStates: Set<String>? = nil
    }

    /// Whether some case requires several states at once, so that sets of states are enumerated.
    private var enumeratesStates: Bool { cases.contains { $0.allStates != nil } }

    /// Every state the cases name, sorted.
    private var namedStates: [String] {
        Array(Set(cases.flatMap { ($0.states ?? []).union($0.allStates ?? []) })).sorted()
    }

    /// The cases, in order. Each names options of `domains` with values from them, and none with an empty list.
    let cases: [Case]
    /// By option, its values: an enum's values, or `false` and `true`.
    let domains: [String: [String]]

    /// At most this many combinations of option values; a check at the limit with 40 cases takes about a second in a
    /// debug build.
    static let limit = 20_000

    /// The options the cases name, sorted.
    private var options: [String] {
        Set(cases.flatMap(\.options.keys)).sorted()
    }

    /// How many combinations of option values the check enumerates; `Int.max` past the range of `Int`.
    var optionCombinations: Int {
        var count = 1
        for option in options {
            let (product, overflow) = count.multipliedReportingOverflow(by: domains[option]?.count ?? 0)
            if overflow { return .max }
            count = product
        }
        return count
    }

    /// How many combinations the check enumerates: of option values, and with a case that requires several states at
    /// once, times every set of the named states; `Int.max` past the range of `Int`.
    var combinations: Int {
        let count = optionCombinations
        guard enumeratesStates else { return count }
        let states = namedStates.count
        guard states < Int.bitWidth - 1 else { return .max }
        let (product, overflow) = count.multipliedReportingOverflow(by: 1 << states)
        return overflow ? .max : product
    }

    /// Whether the check counts sets of states among its combinations, for a message.
    var countsStates: Bool { enumeratesStates }

    /// A set of states as bits, one per state the cases name.
    private struct States: Equatable {
        var words: [UInt64]

        init(count: Int) { words = [UInt64](repeating: 0, count: (count + 63) / 64) }

        mutating func insert(_ index: Int) { words[index / 64] |= 1 << UInt64(index % 64) }
        mutating func formUnion(_ other: States) {
            for index in words.indices { words[index] |= other.words[index] }
        }
        func isSubset(of other: States) -> Bool {
            words.indices.allSatisfy { words[$0] & ~other.words[$0] == 0 }
        }
        func isDisjoint(with other: States) -> Bool {
            words.indices.allSatisfy { words[$0] & other.words[$0] == 0 }
        }
    }

    /// The cases compiled: by case, whether it matches each combination of option values, and its states.
    private struct Compiled {
        let matches: [[Bool]]
        let states: [States?]
        let combinations: Int
    }

    private func compile(_ extra: [Case]) -> Compiled {
        let all = cases + extra
        let options = self.options
        let named = Array(Set(all.compactMap(\.states).flatMap { $0 })).sorted()
        let stateIndex = Dictionary(uniqueKeysWithValues: named.enumerated().map { ($0.element, $0.offset) })
        let total = optionCombinations
        let sizes = options.map { domains[$0]!.count }
        // By case and option, which value indices it accepts; nil: every value.
        let accepts: [[[Bool]?]] = all.map { item in
            options.map { option in item.options[option].map { accepted in domains[option]!.map(accepted.contains) } }
        }
        var matches = [[Bool]](repeating: [Bool](repeating: false, count: total), count: all.count)
        var counter = [Int](repeating: 0, count: options.count)
        for combination in 0..<total {
            for (position, item) in accepts.enumerated() {
                matches[position][combination] = item.indices.allSatisfy { item[$0]?[counter[$0]] ?? true }
            }
            for position in counter.indices.reversed() {
                counter[position] += 1
                if counter[position] < sizes[position] { break }
                counter[position] = 0
            }
        }
        let states: [States?] = all.map { item in
            item.states.map { listed in
                var bits = States(count: named.count)
                for state in listed { bits.insert(stateIndex[state]!) }
                return bits
            }
        }
        return Compiled(matches: matches, states: states, combinations: total)
    }

    /// Whether the case at `target` matches no combination that the cases at `earlier` (in order) do not match
    /// first.
    private static func isCovered(_ target: Int, by earlier: [Int], in compiled: Compiled) -> Bool {
        let empty = States(count: (compiled.states.compactMap { $0 }.first?.words.count ?? 0) * 64)
        for combination in 0..<compiled.combinations where compiled.matches[target][combination] {
            var named = empty
            var takesAll = false
            for index in earlier where compiled.matches[index][combination] {
                guard let states = compiled.states[index] else {
                    takesAll = true
                    break
                }
                named.formUnion(states)
            }
            if takesAll { continue }
            // Without state, the component in no state escapes every earlier case that names states.
            guard let states = compiled.states[target], states.isSubset(of: named) else { return false }
        }
        return true
    }

    /// The earlier cases that cover a target, none of them needless: the first reachable earlier case that covers it
    /// alone, or else the reachable earlier cases that share a combination with it, less each one the others cover
    /// without, tried from the last.
    private static func cover(_ target: Int, reachable: [Int], in compiled: Compiled) -> [Int] {
        if let alone = reachable.first(where: { isCovered(target, by: [$0], in: compiled) }) { return [alone] }
        var chosen = reachable.filter { index in
            if let one = compiled.states[index], let other = compiled.states[target], one.isDisjoint(with: other) {
                return false
            }
            return (0..<compiled.combinations).contains {
                compiled.matches[index][$0] && compiled.matches[target][$0]
            }
        }
        for candidate in chosen.reversed() {
            let without = chosen.filter { $0 != candidate }
            if isCovered(target, by: without, in: compiled) { chosen = without }
        }
        return chosen
    }

    /// The result of the check: the unreachable cases, each by its position, with the earlier cases that cover it
    /// (by position, ascending); and when the cases match every combination, the ones that do, since a binding's
    /// `token` is then never used. Nil when there are more than `limit` combinations. An option the cases name with
    /// no values gives no combination, so nothing is reported; it is reported where the option is declared.
    func check() -> (unreachable: [(position: Int, coveredBy: [Int])], coverAll: [Int]?)? {
        guard combinations <= Self.limit else { return nil }
        guard combinations > 0 else { return ([], nil) }
        if enumeratesStates { return checkByEnumeration() }
        // One more case at the end that matches everything: the binding's `token`.
        let compiled = compile([Case(options: [:], states: nil)])
        // Which cases are reached, in one pass per combination: the earlier matches either take every set of states
        // or name the states a later case must go beyond.
        var reached = [Bool](repeating: false, count: cases.count + 1)
        let width = (compiled.states.compactMap { $0 }.first?.words.count ?? 0) * 64
        for combination in 0..<compiled.combinations {
            var named = States(count: width)
            for position in reached.indices where compiled.matches[position][combination] {
                guard let states = compiled.states[position] else {
                    reached[position] = true
                    break
                }
                if !states.isSubset(of: named) { reached[position] = true }
                named.formUnion(states)
            }
        }
        let reachable = cases.indices.filter { reached[$0] }
        let unreachable = cases.indices.filter { !reached[$0] }.map { position in
            (position, Self.cover(position, reachable: reachable.filter { $0 < position }, in: compiled))
        }
        let coverAll = reached[cases.count] ? nil : Self.cover(cases.count, reachable: reachable, in: compiled)
        return (unreachable, coverAll)
    }

    /// The check of a binding with a case that requires several states at once: every combination of option values
    /// with every set of the named states, each a point that a case matches or not, the first match taking it.
    private func checkByEnumeration() -> (unreachable: [(position: Int, coveredBy: [Int])], coverAll: [Int]?) {
        let all = cases + [Case(options: [:], states: nil)]
        let compiled = compile([Case(options: [:], states: nil)])
        let named = namedStates
        let sets = 1 << named.count
        // By case, the sets of states it matches, as bit masks over `named`.
        func mask(_ states: Set<String>) -> Int {
            named.enumerated().reduce(0) { $0 | (states.contains($1.element) ? 1 << $1.offset : 0) }
        }
        let anyMasks = all.map { $0.states.map(mask) }
        let allMasks = all.map { $0.allStates.map(mask) }
        func matches(_ index: Int, _ combination: Int, _ set: Int) -> Bool {
            guard compiled.matches[index][combination] else { return false }
            if let any = anyMasks[index], set & any == 0 { return false }
            if let every = allMasks[index], set & every != every { return false }
            return true
        }
        // The points each case matches.
        let points: [[(Int, Int)]] = all.indices.map { index in
            (0..<compiled.combinations).flatMap { combination in
                (0..<sets).filter { matches(index, combination, $0) }.map { (combination, $0) }
            }
        }
        var reached = [Bool](repeating: false, count: all.count)
        for combination in 0..<compiled.combinations {
            for set in 0..<sets {
                if let first = all.indices.first(where: { matches($0, combination, set) }) { reached[first] = true }
            }
        }
        func isCovered(_ target: Int, by earlier: [Int]) -> Bool {
            points[target].allSatisfy { point in earlier.contains { matches($0, point.0, point.1) } }
        }
        // As `cover`: the first reachable earlier case that covers it alone, or else those that share a point with it,
        // less each one the others cover without, tried from the last.
        func cover(_ target: Int, reachable: [Int]) -> [Int] {
            if let alone = reachable.first(where: { isCovered(target, by: [$0]) }) { return [alone] }
            var chosen = reachable.filter { index in points[target].contains { matches(index, $0.0, $0.1) } }
            for candidate in chosen.reversed() {
                let without = chosen.filter { $0 != candidate }
                if isCovered(target, by: without) { chosen = without }
            }
            return chosen
        }
        let reachable = cases.indices.filter { reached[$0] }
        let unreachable = cases.indices.filter { !reached[$0] }.map { position in
            (position, cover(position, reachable: reachable.filter { $0 < position }))
        }
        let coverAll = reached[cases.count] ? nil : cover(cases.count, reachable: reachable)
        return (unreachable, coverAll)
    }
}
