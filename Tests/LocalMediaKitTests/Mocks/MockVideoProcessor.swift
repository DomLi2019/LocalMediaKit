import UIKit
import AVFoundation
@testable import LocalMediaKit

final class MockVideoProcessor: VideoProcessing, @unchecked Sendable {
    // MARK: - Call Tracking
    var extractThumbnailCallCount = 0
    var videoInfoCallCount = 0
    var isValidCallCount = 0
    var durationCallCount = 0
    var detectFormatCallCount = 0

    // MARK: - Error Injection
    var extractThumbnailError: Error?
    var videoInfoError: Error?
    var durationError: Error?

    // MARK: - Return Value Overrides
    var extractThumbnailResult: UIImage?
    var videoInfoResult: VideoInfo?
    var isValidResult: Bool = true
    var durationResult: TimeInterval = 10.0
    var detectFormatResult: String = "mp4"

    // MARK: - Protocol Methods
    func extractThumbnail(from url: URL, at time: CMTime?) async throws -> UIImage {
        extractThumbnailCallCount += 1
        if let error = extractThumbnailError { throw error }
        return extractThumbnailResult ?? TestHelpers.makeTestImage()
    }

    func videoInfo(of url: URL) async throws -> VideoInfo {
        videoInfoCallCount += 1
        if let error = videoInfoError { throw error }
        return videoInfoResult ?? VideoInfo(
            dimensions: CGSize(width: 1920, height: 1080),
            duration: 10.0,
            codec: "H.264",
            frameRate: 30.0,
            bitRate: 5_000_000
        )
    }

    func isValid(at url: URL) async -> Bool {
        isValidCallCount += 1
        return isValidResult
    }

    func duration(from url: URL) async throws -> TimeInterval {
        durationCallCount += 1
        if let error = durationError { throw error }
        return durationResult
    }

    func detectVideoFormat(at url: URL) -> String {
        detectFormatCallCount += 1
        return detectFormatResult
    }
}
