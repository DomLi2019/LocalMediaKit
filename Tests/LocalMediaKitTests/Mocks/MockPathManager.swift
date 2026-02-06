import Foundation
@testable import LocalMediaKit

final class MockPathManager: PathManaging, @unchecked Sendable {
    // MARK: - Configuration
    var rootDirectory: URL

    // MARK: - Call Tracking
    var generatePathCallCount = 0
    var fullPathCallCount = 0
    var relativePathCallCount = 0
    var thumbnailPathCallCount = 0

    // MARK: - Return Value Overrides
    var generatePathResult: MediaURL?

    init(rootDirectory: URL = URL(fileURLWithPath: "/tmp/mock-media")) {
        self.rootDirectory = rootDirectory
    }

    // MARK: - Protocol Methods
    func generatePath(for id: MediaID, type: MediaType, ext: String) -> MediaURL {
        generatePathCallCount += 1
        if let result = generatePathResult { return result }
        switch type {
        case .image, .animatedImage:
            return .image(rootDirectory.appendingPathComponent("Images/image_\(id.raw).\(ext)"))
        case .livePhoto:
            return .livePhoto(
                imageURL: rootDirectory.appendingPathComponent("LivePhotos/live_still_\(id.raw).heic"),
                videoURL: rootDirectory.appendingPathComponent("LivePhotos/live_video_\(id.raw).mov")
            )
        case .video:
            return .video(
                avatarURL: rootDirectory.appendingPathComponent("Videos/video_\(id.raw).\(ext)"),
                videoURL: rootDirectory.appendingPathComponent("Videos/video_thumb_\(id.raw).jpg")
            )
        }
    }

    func fullPath(for relativePath: String) -> URL {
        fullPathCallCount += 1
        return rootDirectory.appendingPathComponent(relativePath)
    }

    func relativePath(for url: URL) -> String {
        relativePathCallCount += 1
        let fullPath = url.compatPath
        let rootPath = rootDirectory.compatPath
        if fullPath.hasPrefix(rootPath) {
            var relative = String(fullPath.dropFirst(rootPath.count))
            if relative.hasPrefix("/") {
                relative = String(relative.dropFirst())
            }
            return relative
        }
        return fullPath
    }

    func thumbnailPath(for id: MediaID, size: CGSize) -> URL {
        thumbnailPathCallCount += 1
        return rootDirectory.appendingPathComponent("Cache/thumbnail/thumb_\(id.raw)_\(Int(size.width))x\(Int(size.height)).jpg")
    }
}
