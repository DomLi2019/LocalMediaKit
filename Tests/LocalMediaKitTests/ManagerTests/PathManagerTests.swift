import Testing
import Foundation
@testable import LocalMediaKit

@Suite("PathManager Tests")
struct PathManagerTests {
    var tempDir: URL!
    var manager: PathManager!

    init() throws {
        tempDir = TestHelpers.createTempDirectory()
        let config = PathConfiguration(rootDirectory: tempDir)
        manager = try PathManager(configuration: config)
    }

    @Test("generatePath for image returns .image case")
    func generatePathImage() {
        let id = MediaID(raw: "img-1")
        let result = manager.generatePath(for: id, type: .image, ext: "jpg")
        if case .image(let url) = result {
            #expect(url.pathExtension == "jpg")
            #expect(url.compatPath.contains("Images"))
        } else {
            Issue.record("Expected .image case")
        }
    }

    @Test("generatePath for livePhoto returns .livePhoto case")
    func generatePathLivePhoto() {
        let id = MediaID(raw: "live-1")
        let result = manager.generatePath(for: id, type: .livePhoto)
        if case .livePhoto(let imageURL, let videoURL) = result {
            #expect(imageURL.pathExtension == "heic")
            #expect(videoURL.pathExtension == "mov")
            #expect(imageURL.compatPath.contains("LivePhotos"))
        } else {
            Issue.record("Expected .livePhoto case")
        }
    }

    @Test("generatePath for video returns .video case")
    func generatePathVideo() {
        let id = MediaID(raw: "vid-1")
        let result = manager.generatePath(for: id, type: .video, ext: "mp4")
        if case .video(let avatarURL, let videoURL) = result {
            #expect(avatarURL.pathExtension == "mp4")
            #expect(videoURL.pathExtension == "jpg")
            #expect(videoURL.compatPath.contains("Videos"))
        } else {
            Issue.record("Expected .video case")
        }
    }

    @Test("generatePath for animatedImage returns .image case with gif ext")
    func generatePathAnimatedImage() {
        let id = MediaID(raw: "gif-1")
        let result = manager.generatePath(for: id, type: .animatedImage)
        if case .image(let url) = result {
            #expect(url.pathExtension == "gif")
        } else {
            Issue.record("Expected .image case")
        }
    }

    @Test("fullPath and relativePath round trip")
    func fullPathAndRelativePath() {
        let relativePath = "Images/test_image.heic"
        let fullURL = manager.fullPath(for: relativePath)
        #expect(fullURL.compatPath.hasSuffix(relativePath))
        let recovered = manager.relativePath(for: fullURL)
        #expect(recovered == relativePath)
    }

    @Test("relativePath for external URL returns full path")
    func relativePathExternal() {
        let externalURL = URL(fileURLWithPath: "/some/other/path/file.txt")
        let result = manager.relativePath(for: externalURL)
        #expect(result == externalURL.compatPath)
    }

    @Test("thumbnailPath includes size in filename")
    func thumbnailPath() {
        let id = MediaID(raw: "thumb-test")
        let size = CGSize(width: 100, height: 200)
        let path = manager.thumbnailPath(for: id, size: size)
        #expect(path.compatPath.contains("100x200"))
        #expect(path.pathExtension == "jpg")
        #expect(path.compatPath.contains("Cache"))
    }

    @Test("cacheDirectory creates correct path")
    func cacheDirectory() {
        let thumbDir = manager.cacheDirectory(for: .thumbnail)
        #expect(thumbDir.compatPath.contains("Cache"))
        #expect(thumbDir.compatPath.contains("thumbnail"))
    }

    @Test("Custom rootDirectory is used")
    func customRootDirectory() throws {
        let customDir = TestHelpers.createTempDirectory()
        defer { TestHelpers.cleanupTempDirectory(customDir) }
        let config = PathConfiguration(rootDirectory: customDir)
        let pm = try PathManager(configuration: config)
        let full = pm.fullPath(for: "test.txt")
        #expect(full.compatPath.hasPrefix(customDir.compatPath))
    }

    @Test("generatePath default ext is heic")
    func generatePathDefaultExt() {
        let id = MediaID(raw: "default-ext")
        let result = manager.generatePath(for: id, type: .image)
        if case .image(let url) = result {
            #expect(url.pathExtension == "heic")
        } else {
            Issue.record("Expected .image case")
        }
    }
}
