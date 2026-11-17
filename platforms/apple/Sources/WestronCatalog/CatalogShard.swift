/// One of several slices of a list of catalog entries, so that a long run can be split into parallel ones:
/// `WESTRON_ENTRY_SHARD=<i>/<n>` takes every n-th entry, starting from the i-th (1-based). The `n` slices of a list
/// hold each of its entries exactly once, and each slice keeps the list's order.
public struct CatalogShard: Equatable, Sendable, CustomStringConvertible {
    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case invalid(String)

        public var description: String {
            switch self {
            case .invalid(let text):
                "WESTRON_ENTRY_SHARD=\"\(text)\": expected <i>/<n>, whole numbers with 1 ≤ i ≤ n, such as 2/3"
            }
        }
    }

    /// Which slice, from 1.
    public let index: Int
    /// How many slices.
    public let count: Int

    /// Parses `<i>/<n>`.
    public init(_ text: String) throws(ParseError) {
        let parts = text.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2, let index = Int(parts[0]), let count = Int(parts[1]), count >= 1,
            (1...count).contains(index)
        else { throw .invalid(text) }
        self.index = index
        self.count = count
    }

    /// The slice's items: those at positions index − 1, index − 1 + count, and so on.
    public func select<Item>(_ items: [Item]) -> [Item] {
        items.enumerated().filter { $0.offset % count == index - 1 }.map(\.element)
    }

    public var description: String { "\(index)/\(count)" }
}
