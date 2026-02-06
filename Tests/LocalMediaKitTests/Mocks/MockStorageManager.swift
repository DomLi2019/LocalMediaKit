import Foundation
@testable import LocalMediaKit

final class MockStorageManager: StorageManaging, @unchecked Sendable {
    // MARK: - Storage
    var files: [URL: Data] = [:]
    var existsOverride: [URL: Bool] = [:]

    // MARK: - Call Tracking
    var writeCallCount = 0
    var readCallCount = 0
    var copyCallCount = 0
    var deleteCallCount = 0
    var deletedURLs: [URL] = []

    // MARK: - Error Injection
    var writeError: Error?
    var readError: Error?
    var copyError: Error?
    var deleteError: Error?
    var fileSizeError: Error?

    // MARK: - Return Value Overrides
    var fileSizeResult: Int64 = 1024

    // MARK: - Protocol Methods
    func write(_ data: Data, to url: URL) async throws {
        writeCallCount += 1
        if let error = writeError { throw error }
        files[url] = data
    }

    func read(from url: URL) async throws -> Data {
        readCallCount += 1
        if let error = readError { throw error }
        guard let data = files[url] else {
            throw MediaKitError.fileCorrupted(path: url.compatPath)
        }
        return data
    }

    func copy(at source: URL, to destination: URL) async throws {
        copyCallCount += 1
        if let error = copyError { throw error }
        files[destination] = files[source] ?? Data()
    }

    func delete(at url: URL) async throws {
        deleteCallCount += 1
        deletedURLs.append(url)
        if let error = deleteError { throw error }
        files.removeValue(forKey: url)
    }

    func exists(at url: URL) -> Bool {
        if let override = existsOverride[url] { return override }
        return files[url] != nil
    }

    func fileSize(at url: URL) throws -> Int64 {
        if let error = fileSizeError { throw error }
        if let data = files[url] {
            return Int64(data.count)
        }
        return fileSizeResult
    }
}
