import Testing
import Foundation
@testable import LocalMediaKit

@Suite("CacheManager Tests")
struct CacheManagerTests {
    func makeManager(countLimit: Int = 10, costLimit: Int = 1000) -> CacheManager<Data> {
        let config = CacheConfiguration(
            memoryCountLimit: countLimit,
            memoryCostLimit: costLimit
        )
        return CacheManager<Data>(configuration: config, cacheDirectory: nil)
    }

    @Test("set and get returns value")
    func setAndGet() async {
        let manager = makeManager()
        let data = Data([0x01, 0x02, 0x03])
        await manager.set("key1", value: data, cost: 3)
        let result = await manager.get("key1")
        #expect(result == data)
    }

    @Test("get nonexistent returns nil")
    func getNonexistent() async {
        let manager = makeManager()
        let result = await manager.get("missing")
        #expect(result == nil)
    }

    @Test("set with CacheCostCalculable auto-calculates cost")
    func setWithCacheCostCalculable() async {
        let manager = makeManager()
        let data = Data(repeating: 0xAB, count: 100)
        await manager.set("auto-cost", value: data)
        let result = await manager.get("auto-cost")
        #expect(result == data)
        #expect(manager.memoryCost == 100)
    }

    @Test("remove deletes item")
    func remove() async {
        let manager = makeManager()
        await manager.set("key", value: Data([1]), cost: 1)
        manager.remove("key")
        let result = await manager.get("key")
        #expect(result == nil)
    }

    @Test("cleanup clears all")
    func cleanup() async {
        let manager = makeManager()
        await manager.set("a", value: Data([1]), cost: 1)
        await manager.set("b", value: Data([2]), cost: 1)
        manager.cleanup()
        let a = await manager.get("a")
        let b = await manager.get("b")
        #expect(a == nil)
        #expect(b == nil)
    }

    @Test("contains returns correct results")
    func contains() async {
        let manager = makeManager()
        await manager.set("exists", value: Data([1]), cost: 1)
        #expect(manager.contains("exists") == true)
        #expect(manager.contains("missing") == false)
    }

    @Test("totalCost returns memory cost")
    func totalCost() async {
        let manager = makeManager()
        await manager.set("a", value: Data([1]), cost: 10)
        await manager.set("b", value: Data([2]), cost: 20)
        let cost = await manager.totalCost
        #expect(cost == 30)
    }

    @Test("totalCount returns item count")
    func totalCount() async {
        let manager = makeManager()
        await manager.set("a", value: Data([1]), cost: 1)
        await manager.set("b", value: Data([2]), cost: 1)
        let count = await manager.totalCount
        #expect(count == 2)
    }

    @Test("memoryCost tracks correctly")
    func memoryCost() async {
        let manager = makeManager()
        await manager.set("x", value: Data(repeating: 0, count: 50), cost: 50)
        #expect(manager.memoryCost == 50)
    }
}
