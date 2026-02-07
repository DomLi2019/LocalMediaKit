import UIKit
@testable import LocalMediaKit

final class MockImageProcessor: ImageProcessing, @unchecked Sendable {
    // MARK: - Call Tracking
    var decodeCallCount = 0
    var encodeCallCount = 0
    var thumbnailCallCount = 0
    var detectFormatCallCount = 0
    var imageSizeCallCount = 0

    // MARK: - Error Injection
    var decodeError: Error?
    var encodeError: Error?
    var thumbnailError: Error?
    var imageSizeError: Error?

    // MARK: - Return Value Overrides
    var decodeResult: UIImage?
    var encodeResult: Data?
    var thumbnailResult: UIImage?
    var detectFormatResult: ImageFormat?
    var imageSizeResult: CGSize = CGSize(width: 100, height: 100)

    // MARK: - Protocol Methods
    func decode(_ data: Data) async throws -> UIImage {
        decodeCallCount += 1
        if let error = decodeError { throw error }
        return decodeResult ?? TestHelpers.makeTestImage()
    }

    func encode(_ image: UIImage, format: ImageFormat) async throws -> Data {
        encodeCallCount += 1
        if let error = encodeError { throw error }
        return encodeResult ?? Data(repeating: 0xAB, count: 100)
    }

    func thumbnail(at source: ImageSource, targetSize: CGSize) async throws -> UIImage {
        thumbnailCallCount += 1
        if let error = thumbnailError { throw error }
        return thumbnailResult ?? TestHelpers.makeTestImage(width: Int(targetSize.width), height: Int(targetSize.height))
    }

    func detectFormat(from data: Data) -> ImageFormat? {
        detectFormatCallCount += 1
        return detectFormatResult ?? .jpeg(quality: nil)
    }

    func imageSize(from data: Data) throws -> CGSize {
        imageSizeCallCount += 1
        if let error = imageSizeError { throw error }
        return imageSizeResult
    }
    
    func imageSize(at url: URL) throws -> CGSize {
        imageSizeCallCount += 1
        if let error = imageSizeError { throw error }
        return imageSizeResult
    }
}
