import Testing
import Foundation
@testable import LocalMediaKit

@Suite("CachePolicy Tests")
struct CachePolicyTests {
    @Test("default: uses both caches and reads original")
    func defaultPolicy() {
        let policy = CachePolicy.default
        #expect(policy.useMemoryCache == true)
        #expect(policy.useDiskCache == true)
        #expect(policy.canReadOriginalFile == true)
    }

    @Test("ignoreMemory: skips memory, uses disk")
    func ignoreMemory() {
        let policy = CachePolicy.ignoreMemory
        #expect(policy.useMemoryCache == false)
        #expect(policy.useDiskCache == true)
        #expect(policy.canReadOriginalFile == true)
    }

    @Test("ignoreDisk: uses memory, skips disk")
    func ignoreDisk() {
        let policy = CachePolicy.ignoreDisk
        #expect(policy.useMemoryCache == true)
        #expect(policy.useDiskCache == false)
        #expect(policy.canReadOriginalFile == true)
    }

    @Test("ignoreCache: skips all caches")
    func ignoreCache() {
        let policy = CachePolicy.ignoreCache
        #expect(policy.useMemoryCache == false)
        #expect(policy.useDiskCache == false)
        #expect(policy.canReadOriginalFile == true)
    }

    @Test("cacheOnly: uses caches only, no original file")
    func cacheOnly() {
        let policy = CachePolicy.cacheOnly
        #expect(policy.useMemoryCache == true)
        #expect(policy.useDiskCache == true)
        #expect(policy.canReadOriginalFile == false)
    }
}
