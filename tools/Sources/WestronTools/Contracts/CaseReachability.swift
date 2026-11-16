/// Which cases of a token binding are never used: cases apply first match, so a case is unreachable when every
/// combination it matches is matched by some earlier case, by one alone or by several together (#62).
///
/// A combination is a value of each option and a set of states, since a component can be in several states at once.
/// A case's `when` matches when each option it names has one of the listed values and, if it names `state`, the
/// component is in at least one of the listed states; a case without `state` matches every set of states, none
/// included. Options are finite (an enum's values, a bool's `true` and `false`), so the check enumerates.
///
/// Only what the cases name can tell two combinations apart: an option no case names, or a state no case names,
/// changes no match. So the combinations enumerated are the product of the value counts of the options the cases
/// name, times 2^n for the n states they name: Button's `container.background` names variant (3 values), role (2)
/// and 4 states, 96 combinations. Each is matched against the cases in order, so the work is that product times the
/// number of cases; past `limit` combinations the check gives up and says so instead of hanging.
struct CaseReachability {
    /// By case, in order: the accepted values by option, and by `stateKey` the states named.
    let cases: [[String: Set<String>]]
    /// By option, its values: an enum's values, or `false` and `true`.
    let domains: [String: [String]]
    /// The declared states, in order.
    let states: [String]
    let stateKey: String

    static let limit = 1 << 22

    /// The options the cases name, sorted, and the states they name, in declared order.
    private var named: (options: [String], states: [String]) {
        let keys = Set(cases.flatMap(\.keys))
        return (
            keys.filter { $0 != stateKey && domains[$0] != nil }.sorted(),
            states.filter { state in
                cases.contains { $0[stateKey]?.contains(state) == true }
            }
        )
    }

    /// How many combinations the check enumerates.
    var combinations: Int {
        let (options, states) = named
        var count = 1
        for option in options {
            count = count.multipliedReportingOverflow(by: max(domains[option]!.count, 1)).partialValue
            if count > Self.limit { return count }
        }
        return states.count >= 62 ? Int.max : count.multipliedReportingOverflow(by: 1 << states.count).partialValue
    }

    /// The unreachable cases, each by its position in `cases`, with the positions of the earlier cases that take the
    /// combinations it matches, ascending; nil when there are more than `limit` combinations.
    func unreachable() -> [(position: Int, coveredBy: [Int])]? {
        let total = combinations
        guard total <= Self.limit else { return nil }
        let (options, named) = self.named
        let sizes = options.map { domains[$0]!.count }
        // Each case as, by option position, which value indices it accepts (nil: any), and a mask of the named states
        // it lists (nil: any set of states).
        let compiled: [(accepts: [[Bool]?], states: Int?)] = cases.map { when in
            let accepts = options.enumerated().map { position, option -> [Bool]? in
                guard let values = when[option] else { return nil }
                return domains[option]!.map(values.contains)
            }
            let mask = when[stateKey].map { listed in
                named.enumerated().reduce(0) { mask, state in
                    listed.contains(state.element) ? mask | 1 << state.offset : mask
                }
            }
            return (accepts, mask)
        }
        var reached = [Bool](repeating: false, count: cases.count)
        var takenBy = [Set<Int>](repeating: [], count: cases.count)
        var counter = [Int](repeating: 0, count: options.count)
        let stateSets = 1 << named.count
        for _ in 0..<(total / stateSets) {
            for stateSet in 0..<stateSets {
                var first: Int?
                for (position, item) in compiled.enumerated() {
                    let matches =
                        item.accepts.enumerated().allSatisfy { $0.element?[counter[$0.offset]] ?? true }
                        && (item.states.map { $0 & stateSet != 0 } ?? true)
                    guard matches else { continue }
                    if let first {
                        takenBy[position].insert(first)
                    } else {
                        first = position
                        reached[position] = true
                    }
                }
            }
            // The next combination of option values, the last option fastest.
            for position in counter.indices.reversed() {
                counter[position] += 1
                if counter[position] < sizes[position] { break }
                counter[position] = 0
            }
        }
        return cases.indices.filter { !reached[$0] }.map { ($0, takenBy[$0].sorted()) }
    }
}
