import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MemoryCache Tests")
struct MemoryCacheTests {
    @Test("set and get returns value")
    func setAndGet() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        cache.set("key1", value: "hello", cost: 5)
        #expect(cache.get("key1") == "hello")
    }

    @Test("get nonexistent key returns nil")
    func getNonexistent() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        #expect(cache.get("missing") == nil)
    }

    @Test("LRU eviction by countLimit")
    func lruEvictionByCount() {
        let cache = MemoryCache<String>(countLimit: 3, costLimit: 10000)
        cache.set("a", value: "1", cost: 1)
        cache.set("b", value: "2", cost: 1)
        cache.set("c", value: "3", cost: 1)
        // Adding 4th should evict the least recently used ("a")
        cache.set("d", value: "4", cost: 1)
        #expect(cache.get("a") == nil)
        #expect(cache.get("b") == "2")
        #expect(cache.get("c") == "3")
        #expect(cache.get("d") == "4")
    }

    @Test("LRU eviction by costLimit")
    func lruEvictionByCost() {
        let cache = MemoryCache<String>(countLimit: 100, costLimit: 10)
        cache.set("a", value: "1", cost: 4)
        cache.set("b", value: "2", cost: 4)
        // Total cost = 8, under limit 10
        #expect(cache.get("a") == "1")
        // Adding c with cost 4 → total 12 > 10, evict tail ("a" since "b" was accessed by "a" get)
        cache.set("c", value: "3", cost: 4)
        #expect(cache.currentCost <= 10)
    }

    @Test("Access keeps item alive in LRU")
    func accessKeepsAlive() {
        let cache = MemoryCache<String>(countLimit: 3, costLimit: 10000)
        cache.set("a", value: "1", cost: 1)
        cache.set("b", value: "2", cost: 1)
        cache.set("c", value: "3", cost: 1)
        // Access "a" to make it recently used
        _ = cache.get("a")
        // Adding "d" should evict "b" (now least recently used)
        cache.set("d", value: "4", cost: 1)
        #expect(cache.get("a") == "1")
        #expect(cache.get("b") == nil)
        #expect(cache.get("c") == "3")
        #expect(cache.get("d") == "4")
    }

    @Test("Update existing key preserves position")
    func updateExistingKey() {
        let cache = MemoryCache<String>(countLimit: 3, costLimit: 10000)
        cache.set("a", value: "1", cost: 1)
        cache.set("b", value: "2", cost: 1)
        cache.set("c", value: "3", cost: 1)
        // Update "a" → moves to head
        cache.set("a", value: "updated", cost: 1)
        #expect(cache.get("a") == "updated")
        // Adding "d" should evict "b" (least recently used)
        cache.set("d", value: "4", cost: 1)
        #expect(cache.get("b") == nil)
        #expect(cache.get("a") == "updated")
    }

    @Test("Update existing key adjusts cost")
    func updateCost() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 10000)
        cache.set("a", value: "1", cost: 100)
        #expect(cache.currentCost == 100)
        cache.set("a", value: "1-updated", cost: 200)
        #expect(cache.currentCost == 200)
    }

    @Test("remove deletes item")
    func remove() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        cache.set("key", value: "val", cost: 10)
        cache.remove("key")
        #expect(cache.get("key") == nil)
        #expect(cache.currentCount == 0)
        #expect(cache.currentCost == 0)
    }

    @Test("remove nonexistent key does nothing")
    func removeNonexistent() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        cache.remove("missing")
        #expect(cache.currentCount == 0)
    }

    @Test("cleanup clears all")
    func cleanup() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        cache.set("a", value: "1", cost: 10)
        cache.set("b", value: "2", cost: 20)
        cache.cleanup()
        #expect(cache.get("a") == nil)
        #expect(cache.get("b") == nil)
        #expect(cache.currentCount == 0)
        #expect(cache.currentCost == 0)
    }

    @Test("contains returns correct results")
    func contains() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        cache.set("exists", value: "yes", cost: 1)
        #expect(cache.contains("exists") == true)
        #expect(cache.contains("missing") == false)
    }

    @Test("currentCount tracks items")
    func currentCount() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        #expect(cache.currentCount == 0)
        cache.set("a", value: "1", cost: 1)
        #expect(cache.currentCount == 1)
        cache.set("b", value: "2", cost: 1)
        #expect(cache.currentCount == 2)
        cache.remove("a")
        #expect(cache.currentCount == 1)
    }

    @Test("currentCost tracks total cost")
    func currentCost() {
        let cache = MemoryCache<String>(countLimit: 10, costLimit: 1000)
        #expect(cache.currentCost == 0)
        cache.set("a", value: "1", cost: 50)
        #expect(cache.currentCost == 50)
        cache.set("b", value: "2", cost: 30)
        #expect(cache.currentCost == 80)
    }

    @Test("Concurrent access is safe")
    func concurrentSafety() async {
        let cache = MemoryCache<Int>(countLimit: 1000, costLimit: 100000)
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    cache.set("key-\(i)", value: i, cost: 1)
                    _ = cache.get("key-\(i)")
                }
            }
        }
        // Should not crash; count should be reasonable
        #expect(cache.currentCount <= 1000)
    }

    @Test("Single item cache evicts on second insert")
    func singleItemCache() {
        let cache = MemoryCache<String>(countLimit: 1, costLimit: 10000)
        cache.set("a", value: "1", cost: 1)
        cache.set("b", value: "2", cost: 1)
        #expect(cache.get("a") == nil)
        #expect(cache.get("b") == "2")
        #expect(cache.currentCount == 1)
    }
}
