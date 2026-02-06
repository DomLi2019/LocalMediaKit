import Testing
import Foundation
import UIKit
@testable import LocalMediaKit

@Suite("LoadCoordinator Tests")
struct LoadCoordinatorTests {
    let mockMetadata: MockMetadataManager
    let mockStorage: MockStorageManager
    let mockPath: MockPathManager
    let mockImage: MockImageProcessor
    let mockVideo: MockVideoProcessor
    let mockLivePhoto: MockLivePhotoProcessor
    let coordinator: LoadCoordinator

    init() {
        mockMetadata = MockMetadataManager()
        mockStorage = MockStorageManager()
        mockPath = MockPathManager()
        mockImage = MockImageProcessor()
        mockVideo = MockVideoProcessor()
        mockLivePhoto = MockLivePhotoProcessor()

        coordinator = LoadCoordinator(
            pathManager: mockPath,
            storageManager: mockStorage,
            metadataManager: mockMetadata,
            imageProcessor: mockImage,
            videoProcessor: mockVideo,
            livePhotoProcessor: mockLivePhoto
        )
    }

    // MARK: - load() dispatch
    @Test("load: metadata not found throws mediaNotFound")
    func loadMediaNotFound() async {
        let id = MediaID(raw: "missing")
        let request = LoadRequest.original(id: id)
        /// 预期：抛出MediaKitError错误
        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.load(request)
        }
    }

    @Test("load: image type dispatches to loadImage")
    func loadImageDispatches() async throws {
        let id = MediaID(raw: "img-dispatch")
        let metadata = TestHelpers.makeImageMetadata(id: id, imagePath: "Images/test.heic")
        mockMetadata.storage[id] = metadata
        // Setup file exists
        let fileURL = mockPath.fullPath(for: "Images/test.heic")
        mockStorage.files[fileURL] = TestHelpers.makeMinimalJPEG()

        let request = LoadRequest.original(id: id)
        let result = try await coordinator.load(request)
        if case .image = result {
            // OK
        } else {
            Issue.record("Expected .image result")
        }
        #expect(mockImage.decodeCallCount == 1)
    }

    @Test("load: video type dispatches to loadVideo")
    func loadVideoDispatches() async throws {
        let id = MediaID(raw: "vid-dispatch")
        let metadata = TestHelpers.makeVideoMetadata(id: id, videoPath: "Videos/test.mp4")
        mockMetadata.storage[id] = metadata
        let fileURL = mockPath.fullPath(for: "Videos/test.mp4")
        mockStorage.files[fileURL] = Data()

        let request = LoadRequest.original(id: id)
        let result = try await coordinator.load(request)
        if case .video = result {
            // OK
        } else {
            Issue.record("Expected .video result")
        }
    }

    // MARK: - loadImage
    @Test("loadImage: cache miss reads file and decodes")
    func loadImageCacheMissReadsFile() async throws {
        let id = MediaID(raw: "cache-miss")
        let metadata = TestHelpers.makeImageMetadata(id: id, imagePath: "Images/img.heic")
        let fileURL = mockPath.fullPath(for: "Images/img.heic")
        mockStorage.files[fileURL] = TestHelpers.makeMinimalJPEG()

        let request = LoadRequest.original(id: id)
        let result = try await coordinator.loadImage(metadata: metadata, request: request)

        #expect(mockStorage.readCallCount == 1)
        #expect(mockImage.decodeCallCount == 1)
        if case .image = result {
            // OK
        } else {
            Issue.record("Expected .image result")
        }
    }

    @Test("loadImage: cacheOnly throws cacheMiss when no cache")
    func loadImageCacheOnlyMiss() async {
        let id = MediaID(raw: "cache-only")
        let metadata = TestHelpers.makeImageMetadata(id: id)
        let request = LoadRequest(id: id, cachePolicy: .cacheOnly)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.loadImage(metadata: metadata, request: request)
        }
    }

    @Test("loadImage: file not found throws fileCorrupted")
    func loadImageFileNotFound() async {
        let id = MediaID(raw: "no-file")
        let metadata = TestHelpers.makeImageMetadata(id: id, imagePath: "Images/missing.heic")
        // Don't add file to mockStorage
        let request = LoadRequest.original(id: id)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.loadImage(metadata: metadata, request: request)
        }
    }

    @Test("loadImage: with targetSize calls loadThumbnail path")
    func loadImageWithTargetSize() async throws {
        let id = MediaID(raw: "thumb-size")
        let metadata = TestHelpers.makeImageMetadata(id: id, imagePath: "Images/img.heic")
        mockMetadata.storage[id] = metadata
        let fileURL = mockPath.fullPath(for: "Images/img.heic")
        mockStorage.files[fileURL] = TestHelpers.makeMinimalJPEG()

        let request = LoadRequest.thumbnail(id: id, targetSize: CGSize(width: 100, height: 100))
        let result = try await coordinator.loadImage(metadata: metadata, request: request)

        if case .image = result {
            // OK - thumbnail returned as .image
        } else {
            Issue.record("Expected .image result for thumbnail")
        }
    }

    // MARK: - loadVideo
    @Test("loadVideo: file exists returns video URL")
    func loadVideoReturnsURL() async throws {
        let id = MediaID(raw: "vid-ok")
        let metadata = TestHelpers.makeVideoMetadata(id: id, videoPath: "Videos/vid.mp4")
        let fileURL = mockPath.fullPath(for: "Videos/vid.mp4")
        mockStorage.files[fileURL] = Data()

        let request = LoadRequest.original(id: id)
        let result = try await coordinator.loadVideo(metadata: metadata, request: request)

        if case .video(let url, _) = result {
            #expect(url == fileURL)
        } else {
            Issue.record("Expected .video result")
        }
    }

    @Test("loadVideo: file not found throws fileCorrupted")
    func loadVideoFileNotFound() async {
        let id = MediaID(raw: "vid-missing")
        let metadata = TestHelpers.makeVideoMetadata(id: id, videoPath: "Videos/missing.mp4")
        let request = LoadRequest.original(id: id)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.loadVideo(metadata: metadata, request: request)
        }
    }

    // MARK: - loadLivePhoto
    @Test("loadLivePhoto: missing paths throws invalidMetadata")
    func loadLivePhotoMissingPaths() async {
        let id = MediaID(raw: "live-no-paths")
        let metadata = MediaMetadata(id: id, type: .livePhoto, fileSize: 100)
        let request = LoadRequest.original(id: id)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.loadLivePhoto(metadata: metadata, request: request)
        }
    }

    @Test("loadLivePhoto: image not found throws fileCorrupted")
    func loadLivePhotoImageNotFound() async {
        let id = MediaID(raw: "live-no-img")
        let metadata = TestHelpers.makeLivePhotoMetadata(id: id)
        // Video file exists but image doesn't
        let videoURL = mockPath.fullPath(for: metadata.videoPath!)
        mockStorage.files[videoURL] = Data()
        let request = LoadRequest.original(id: id)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.loadLivePhoto(metadata: metadata, request: request)
        }
    }

    @Test("loadLivePhoto: with targetSize returns image thumbnail")
    func loadLivePhotoWithTargetSize() async throws {
        let id = MediaID(raw: "live-thumb")
        let metadata = TestHelpers.makeLivePhotoMetadata(id: id)
        mockMetadata.storage[id] = metadata
        let imageURL = mockPath.fullPath(for: metadata.imagePath!)
        mockStorage.files[imageURL] = TestHelpers.makeMinimalJPEG()

        let request = LoadRequest.thumbnail(id: id, targetSize: CGSize(width: 50, height: 50))
        let result = try await coordinator.loadLivePhoto(metadata: metadata, request: request)

        if case .image = result {
            // OK - returns image thumbnail instead of live photo
        } else {
            Issue.record("Expected .image result for live photo thumbnail")
        }
    }

    // MARK: - loadAnimatedImage
    @Test("loadAnimatedImage: cache miss reads file")
    func loadAnimatedImageCacheMiss() async throws {
        let id = MediaID(raw: "anim-miss")
        let metadata = MediaMetadata(
            id: id, type: .animatedImage, fileSize: 100,
            imagePath: "Images/anim.gif"
        )
        let fileURL = mockPath.fullPath(for: "Images/anim.gif")
        mockStorage.files[fileURL] = TestHelpers.makeMinimalJPEG()

        let request = LoadRequest.original(id: id)
        let result = try await coordinator.loadAnimatedImage(metadata: metadata, request: request)

        if case .animatedImage(let data, _) = result {
            #expect(!data.isEmpty)
        } else {
            Issue.record("Expected .animatedImage result")
        }
        #expect(mockStorage.readCallCount == 1)
        #expect(mockImage.decodeCallCount == 1)
    }

    @Test("loadAnimatedImage: cacheOnly throws cacheMiss")
    func loadAnimatedImageCacheOnly() async {
        let id = MediaID(raw: "anim-cache-only")
        let metadata = MediaMetadata(
            id: id, type: .animatedImage, fileSize: 100,
            imagePath: "Images/anim.gif"
        )
        let request = LoadRequest(id: id, cachePolicy: .cacheOnly)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.loadAnimatedImage(metadata: metadata, request: request)
        }
    }
}
