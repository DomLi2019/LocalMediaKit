import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MetadataManager Tests")
struct MetadataManagerTests {
    var tempDir: URL!
    var manager: MetadataManager!

    init() throws {
        tempDir = TestHelpers.createTempDirectory()
        let dbPath = tempDir.appendingPathComponent("test.sqlite")
        manager = try MetadataManager(databasePath: dbPath)
    }

    // MARK: - CRUD
    @Test("save and get returns metadata")
    func saveAndGet() async throws {
        let metadata = TestHelpers.makeImageMetadata()
        try await manager.save(metadata)
        let result = try await manager.get(id: metadata.id)
        #expect(result != nil)
        #expect(result?.id == metadata.id)
        #expect(result?.type == .image)
    }

    @Test("get nonexistent returns nil")
    func getNonexistent() async throws {
        let result = try await manager.get(id: MediaID(raw: "nonexistent"))
        #expect(result == nil)
    }

    @Test("delete removes metadata")
    func delete() async throws {
        let metadata = TestHelpers.makeImageMetadata()
        try await manager.save(metadata)
        try await manager.delete(id: metadata.id)
        let result = try await manager.get(id: metadata.id)
        #expect(result == nil)
    }

    @Test("exists returns correct result")
    func exists() async throws {
        let metadata = TestHelpers.makeImageMetadata()
        #expect(try await manager.exists(id: metadata.id) == false)
        try await manager.save(metadata)
        #expect(try await manager.exists(id: metadata.id) == true)
    }

    @Test("allIDs returns saved IDs")
    func allIDs() async throws {
        let m1 = TestHelpers.makeImageMetadata()
        let m2 = TestHelpers.makeVideoMetadata()
        try await manager.save(m1)
        try await manager.save(m2)
        let ids = try await manager.allIDs()
        #expect(ids.count == 2)
        #expect(ids.contains(m1.id))
        #expect(ids.contains(m2.id))
    }

    // MARK: - Batch Operations
    @Test("batchSave saves all items")
    func batchSave() async throws {
        let items = (0..<5).map { _ in TestHelpers.makeImageMetadata() }
        try await manager.batchSave(items)
        let ids = try await manager.allIDs()
        #expect(ids.count == 5)
    }

    @Test("batchDelete removes items")
    func batchDelete() async throws {
        let items = (0..<3).map { _ in TestHelpers.makeImageMetadata() }
        try await manager.batchSave(items)
        let idsToDelete = items.prefix(2).map(\.id)
        try await manager.batchDelete(Array(idsToDelete))
        let remaining = try await manager.allIDs()
        #expect(remaining.count == 1)
        #expect(remaining.first == items.last?.id)
    }

    @Test("batchDelete with empty array does nothing")
    func batchDeleteEmpty() async throws {
        try await manager.batchDelete([])
        let ids = try await manager.allIDs()
        #expect(ids.isEmpty)
    }

    // MARK: - Update
    @Test("update merges userInfo")
    func updateMerge() async throws {
        let id = MediaID(raw: "update-test")
        var metadata = TestHelpers.makeImageMetadata(id: id)
        metadata.userInfo = ["key1": "val1"]
        try await manager.save(metadata)

        let updates = MetadataUpdates(userInfo: ["key2": "val2"], mergeUserInfo: true)
        try await manager.update(id: id, updates: updates)

        let result = try await manager.get(id: id)
        #expect(result?.userInfo?["key1"] == "val1")
        #expect(result?.userInfo?["key2"] == "val2")
    }

    @Test("update replaces userInfo when mergeUserInfo is false")
    func updateReplace() async throws {
        let id = MediaID(raw: "replace-test")
        var metadata = TestHelpers.makeImageMetadata(id: id)
        metadata.userInfo = ["old": "value"]
        try await manager.save(metadata)

        let updates = MetadataUpdates(userInfo: ["new": "value"], mergeUserInfo: false)
        try await manager.update(id: id, updates: updates)

        let result = try await manager.get(id: id)
        #expect(result?.userInfo?["old"] == nil)
        #expect(result?.userInfo?["new"] == "value")
    }

    @Test("update nonexistent throws mediaNotFound")
    func updateNonexistent() async throws {
        let updates = MetadataUpdates(userInfo: ["k": "v"])
        await #expect(throws: MediaKitError.self) {
            try await manager.update(id: MediaID(raw: "missing"), updates: updates)
        }
    }

    // MARK: - Query
    @Test("query by type")
    func queryByType() async throws {
        try await manager.save(TestHelpers.makeImageMetadata())
        try await manager.save(TestHelpers.makeVideoMetadata())
        try await manager.save(TestHelpers.makeImageMetadata())

        let filter = MetadataFilter(types: [.image])
        let results = try await manager.query(filter)
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.type == .image })
    }

    @Test("query by date range")
    func queryByDate() async throws {
        let now = Date()
        let m = TestHelpers.makeImageMetadata()
        try await manager.save(m)

        let filter = MetadataFilter(
            createdAfter: now.addingTimeInterval(-60),
            createdBefore: now.addingTimeInterval(60)
        )
        let results = try await manager.query(filter)
        #expect(results.count == 1)
    }

    @Test("query by file size range")
    func queryByFileSize() async throws {
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 100))
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 500))
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 1000))

        let filter = MetadataFilter(minFileSize: 200, maxFileSize: 600)
        let results = try await manager.query(filter)
        #expect(results.count == 1)
        #expect(results.first?.fileSize == 500)
    }

    @Test("query with sorting ascending")
    func querySortAscending() async throws {
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 300))
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 100))
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 200))

        let filter = MetadataFilter(sortBy: .fileSize, ascending: true)
        let results = try await manager.query(filter)
        #expect(results.count == 3)
        #expect(results[0].fileSize == 100)
        #expect(results[1].fileSize == 200)
        #expect(results[2].fileSize == 300)
    }

    @Test("query with pagination")
    func queryWithPagination() async throws {
        for i in 0..<10 {
            try await manager.save(TestHelpers.makeImageMetadata(fileSize: Int64(i * 100)))
        }

        let filter = MetadataFilter(sortBy: .fileSize, ascending: true, limit: 3, offset: 2)
        let results = try await manager.query(filter)
        #expect(results.count == 3)
    }

    @Test("count returns correct number")
    func count() async throws {
        try await manager.save(TestHelpers.makeImageMetadata())
        try await manager.save(TestHelpers.makeImageMetadata())
        try await manager.save(TestHelpers.makeVideoMetadata())

        let imageCount = try await manager.count(MetadataFilter(types: [.image]))
        #expect(imageCount == 2)

        let totalCount = try await manager.count(.default)
        #expect(totalCount == 3)
    }

    // MARK: - Statistics
    @Test("statistics returns correct counts and sizes")
    func statistics() async throws {
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 100))
        try await manager.save(TestHelpers.makeImageMetadata(fileSize: 200))
        try await manager.save(TestHelpers.makeVideoMetadata(fileSize: 500))

        let stats = try await manager.statistics()
        #expect(stats.totalCount == 3)
        #expect(stats.totalSize == 800)
        #expect(stats.countByType[.image] == 2)
        #expect(stats.countByType[.video] == 1)
        #expect(stats.sizeByType[.image] == 300)
        #expect(stats.sizeByType[.video] == 500)
    }

    // MARK: - Search
    @Test("search by userInfo key")
    func searchByKey() async throws {
        var m1 = TestHelpers.makeImageMetadata()
        m1.userInfo = ["source": "camera"]
        try await manager.save(m1)

        var m2 = TestHelpers.makeImageMetadata()
        m2.userInfo = ["tag": "sunset"]
        try await manager.save(m2)

        let results = try await manager.search(userInfoKey: "source")
        #expect(results.count == 1)
        #expect(results.first?.id == m1.id)
    }

    @Test("search by key and value")
    func searchByKeyValue() async throws {
        var m1 = TestHelpers.makeImageMetadata()
        m1.userInfo = ["category": "nature"]
        try await manager.save(m1)

        var m2 = TestHelpers.makeImageMetadata()
        m2.userInfo = ["category": "city"]
        try await manager.save(m2)

        let results = try await manager.search(key: "category", value: "nature")
        #expect(results.count == 1)
        #expect(results.first?.id == m1.id)
    }

    // MARK: - Convenience Methods
    @Test("fetchAll with pagination")
    func fetchAll() async throws {
        for _ in 0..<5 {
            try await manager.save(TestHelpers.makeImageMetadata())
        }
        let results = try await manager.fetchAll(limit: 3, offset: 0)
        #expect(results.count == 3)
    }

    @Test("fetch by types")
    func fetchByTypes() async throws {
        try await manager.save(TestHelpers.makeImageMetadata())
        try await manager.save(TestHelpers.makeVideoMetadata())
        let results = try await manager.fetch(types: [.video])
        #expect(results.count == 1)
        #expect(results.first?.type == .video)
    }
}
