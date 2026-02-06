import Foundation
@testable import LocalMediaKit

final class MockMetadataManager: MetadataManaging, @unchecked Sendable {
    // MARK: - Storage
    var storage: [MediaID: MediaMetadata] = [:]

    // MARK: - Call Tracking
    var getCallCount = 0
    var saveCallCount = 0

    // MARK: - Error Injection
    var getError: Error?
    var saveError: Error?

    // MARK: - Protocol Methods
    func get(id: MediaID) async throws -> MediaMetadata? {
        getCallCount += 1
        if let error = getError { throw error }
        return storage[id]
    }

    func save(_ metadata: MediaMetadata) async throws {
        saveCallCount += 1
        if let error = saveError { throw error }
        storage[metadata.id] = metadata
    }
}
