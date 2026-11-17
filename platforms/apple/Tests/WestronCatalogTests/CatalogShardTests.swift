import Testing

@testable import WestronCatalog

@Suite("Catalog entry shards")
struct CatalogShardTests {
    @Test("<i>/<n> is parsed, 1-based")
    func parse() throws {
        let shard = try CatalogShard("2/3")
        #expect(shard.index == 2 && shard.count == 3)
        #expect(shard.description == "2/3")
        #expect(try CatalogShard("1/1") == CatalogShard("1/1"))
    }

    @Test(
        "an invalid value is an error, never all entries or none",
        arguments: [
            "", "2", "0/2", "3/2", "-1/2", "1/0", "a/b", "1/2/3", " 1/2", "1/ 2", "1.0/2",
        ])
    func invalid(_ text: String) {
        #expect(throws: CatalogShard.ParseError.invalid(text)) { try CatalogShard(text) }
    }

    @Test("the shards of the registry hold every entry exactly once, each in the registry's order", arguments: 1...6)
    func cover(count: Int) throws {
        let ids = Catalog.entries.map(\.id)
        let shards = try (1...count).map { try CatalogShard("\($0)/\(count)").select(ids) }
        #expect(shards.flatMap { $0 }.sorted() == ids.sorted())
        for shard in shards {
            #expect(shard == ids.filter { shard.contains($0) }, "a shard is not in the registry's order")
        }
        // Every n-th: the sizes differ by one at most.
        #expect((shards.map(\.count).max() ?? 0) - (shards.map(\.count).min() ?? 0) <= 1)
    }
}
