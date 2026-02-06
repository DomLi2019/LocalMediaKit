import Foundation
import Photos
@testable import LocalMediaKit

final class MockLivePhotoProcessor: LivePhotoProcessing, @unchecked Sendable {
    // MARK: - Call Tracking
    var assembleCallCount = 0

    // MARK: - Error Injection
    var assembleError: Error?

    // MARK: - Return Value Overrides
    var assembleResult: PHLivePhoto?

    // MARK: - Protocol Methods
    func assemble(imageURL: URL, videoURL: URL) async throws -> PHLivePhoto {
        assembleCallCount += 1
        if let error = assembleError { throw error }
        if let result = assembleResult { return result }
        // PHLivePhoto cannot be programmatically created in tests
        throw MediaKitError.livePhotoAssemblyFailed(underlying: nil)
    }
}
