import Testing
import Foundation
import UIKit
@testable import LocalMediaKit

@Suite("SaveCoordinator Tests")
struct SaveCoordinatorTests {
    let mockMetadata: MockMetadataManager
    let mockStorage: MockStorageManager
    let mockPath: MockPathManager
    let mockImage: MockImageProcessor
    let mockVideo: MockVideoProcessor
    let mockLivePhoto: MockLivePhotoProcessor
    let coordinator: SaveCoordinator

    init() {
        mockMetadata = MockMetadataManager()
        mockStorage = MockStorageManager()
        mockPath = MockPathManager()
        mockImage = MockImageProcessor()
        mockVideo = MockVideoProcessor()
        mockLivePhoto = MockLivePhotoProcessor()

        let config = LocalMediaKitConfiguration()
        coordinator = SaveCoordinator(
            pathManager: mockPath,
            storageManager: mockStorage,
            metadataManager: mockMetadata,
            imageProcessor: mockImage,
            videoProcessor: mockVideo,
            livePhotoProcessor: mockLivePhoto,
            configuration: config
        )
    }

    // MARK: - save() dispatch
    @Test("save dispatches image type to saveImage")
    func saveDispatchImage() async throws {
        let request = SaveRequest.image(Data(repeating: 0xAA, count: 20))
        let id = try await coordinator.save(request)
        #expect(!id.raw.isEmpty)
        #expect(mockStorage.writeCallCount >= 1)
        #expect(mockMetadata.saveCallCount == 1)
    }

    @Test("save dispatches video type to saveVideo")
    func saveDispatchVideo() async throws {
        let sourceURL = URL(fileURLWithPath: "/tmp/source.mp4")
        mockStorage.files[sourceURL] = Data(repeating: 0, count: 50)
        let request = SaveRequest.video(at: sourceURL)
        let id = try await coordinator.save(request)
        #expect(!id.raw.isEmpty)
        #expect(mockStorage.copyCallCount >= 1)
    }

    @Test("save dispatches livePhoto type to saveLivePhoto")
    func saveDispatchLivePhoto() async throws {
        let videoURL = URL(fileURLWithPath: "/tmp/live.mov")
        mockStorage.files[videoURL] = Data(repeating: 0, count: 30)
        let request = SaveRequest.livePhoto(imageData: Data(repeating: 0xBB, count: 20), videoURL: videoURL)
        let id = try await coordinator.save(request)
        #expect(!id.raw.isEmpty)
        #expect(mockStorage.writeCallCount >= 1)
        #expect(mockStorage.copyCallCount >= 1)
    }

    // MARK: - saveImage
    @Test("saveImage with imageData writes and saves metadata")
    func saveImageImageData() async throws {
        let imageData = Data(repeating: 0xCC, count: 50)
        let request = SaveRequest(type: .image, data: .imageData(imageData), generateThumbnail: false)
        let id = try await coordinator.saveImage(request)

        #expect(!id.raw.isEmpty)
        #expect(mockStorage.writeCallCount == 1)
        #expect(mockMetadata.saveCallCount == 1)
        #expect(mockImage.detectFormatCallCount == 1)
    }

    @Test("saveImage with UIImage encodes then writes")
    func saveImageUIImage() async throws {
        let image = TestHelpers.makeTestImage()
        let request = SaveRequest(type: .image, data: .image(image, format: .png), generateThumbnail: false)
        let id = try await coordinator.saveImage(request)

        #expect(!id.raw.isEmpty)
        #expect(mockImage.encodeCallCount == 1)
        #expect(mockStorage.writeCallCount == 1)
    }

    @Test("saveImage with invalid data throws invalidMediaData")
    func saveImageInvalidData() async {
        let request = SaveRequest(type: .image, data: .videoURL(URL(fileURLWithPath: "/tmp/v.mp4")), generateThumbnail: false)
        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.saveImage(request)
        }
    }

    @Test("saveImage: metadata save fails triggers rollback")
    func saveImageMetadataFailsRollback() async {
        mockMetadata.saveError = MediaKitError.databaseError(underlying: NSError(domain: "test", code: 1))
        let request = SaveRequest(type: .image, data: .imageData(Data(repeating: 0, count: 10)), generateThumbnail: false)

        await #expect(throws: Error.self) {
            _ = try await coordinator.saveImage(request)
        }
        // Rollback: delete should be called for the written file
        #expect(mockStorage.deleteCallCount >= 1)
    }

    // MARK: - saveVideo
    @Test("saveVideo with valid video copies and saves metadata")
    func saveVideoValid() async throws {
        let sourceURL = URL(fileURLWithPath: "/tmp/video.mp4")
        mockStorage.files[sourceURL] = Data(repeating: 0, count: 100)
        let request = SaveRequest(type: .video, data: .videoURL(sourceURL), generateThumbnail: false)

        let id = try await coordinator.saveVideo(request)
        #expect(!id.raw.isEmpty)
        #expect(mockStorage.copyCallCount >= 1)
        #expect(mockVideo.isValidCallCount == 1)
    }

    @Test("saveVideo with invalid video throws invalidVideo")
    func saveVideoInvalid() async {
        mockVideo.isValidResult = false
        let sourceURL = URL(fileURLWithPath: "/tmp/bad.mp4")
        mockStorage.files[sourceURL] = Data()
        let request = SaveRequest(type: .video, data: .videoURL(sourceURL), generateThumbnail: false)

        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.saveVideo(request)
        }
    }

    @Test("saveVideo with invalid data type throws invalidMediaData")
    func saveVideoInvalidData() async {
        let request = SaveRequest(type: .video, data: .imageData(Data()), generateThumbnail: false)
        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.saveVideo(request)
        }
    }

    @Test("saveVideo: metadata save fails triggers rollback")
    func saveVideoMetadataFailsRollback() async {
        mockMetadata.saveError = MediaKitError.databaseError(underlying: NSError(domain: "test", code: 1))
        let sourceURL = URL(fileURLWithPath: "/tmp/video.mp4")
        mockStorage.files[sourceURL] = Data(repeating: 0, count: 50)
        let request = SaveRequest(type: .video, data: .videoURL(sourceURL), generateThumbnail: false)

        await #expect(throws: Error.self) {
            _ = try await coordinator.saveVideo(request)
        }
        // Rollback: delete should be called
        #expect(mockStorage.deleteCallCount >= 1)
    }

    // MARK: - saveLivePhoto
    @Test("saveLivePhoto success writes image and copies video")
    func saveLivePhotoSuccess() async throws {
        let videoURL = URL(fileURLWithPath: "/tmp/live.mov")
        mockStorage.files[videoURL] = Data(repeating: 0, count: 40)
        let imageData = Data(repeating: 0xDD, count: 30)
        let request = SaveRequest(type: .livePhoto, data: .livePhoto(imageData: imageData, videoURL: videoURL), generateThumbnail: false)

        let id = try await coordinator.saveLivePhoto(request)
        #expect(!id.raw.isEmpty)
        #expect(mockStorage.writeCallCount >= 1)
        #expect(mockStorage.copyCallCount >= 1)
        #expect(mockMetadata.saveCallCount == 1)
    }

    @Test("saveLivePhoto with invalid data throws invalidMediaData")
    func saveLivePhotoInvalidData() async {
        let request = SaveRequest(type: .livePhoto, data: .imageData(Data()), generateThumbnail: false)
        await #expect(throws: MediaKitError.self) {
            _ = try await coordinator.saveLivePhoto(request)
        }
    }

    @Test("saveLivePhoto: metadata save fails triggers rollback of both files")
    func saveLivePhotoMetadataFailsRollback() async {
        mockMetadata.saveError = MediaKitError.databaseError(underlying: NSError(domain: "test", code: 1))
        let videoURL = URL(fileURLWithPath: "/tmp/live.mov")
        mockStorage.files[videoURL] = Data(repeating: 0, count: 20)
        let request = SaveRequest(type: .livePhoto, data: .livePhoto(imageData: Data(repeating: 0, count: 10), videoURL: videoURL), generateThumbnail: false)

        await #expect(throws: Error.self) {
            _ = try await coordinator.saveLivePhoto(request)
        }
        // Rollback: both image and video files should be deleted
        #expect(mockStorage.deleteCallCount >= 2)
    }
}
