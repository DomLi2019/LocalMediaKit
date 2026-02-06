import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MediaMetadata Tests")
struct MediaMetadataTests {
    // MARK: - Init
    @Test("Full init stores all fields")
    func fullInit() {
        let id = MediaID(raw: "test")
        let date = Date()
        let metadata = MediaMetadata(
            id: id,
            type: .image,
            createdAt: date,
            fileSize: 1024,
            imagePath: "img.heic",
            videoPath: "vid.mp4",
            thumbnailPath: "thumb.jpg",
            pixelWidth: 100,
            pixelHeight: 200,
            duration: 5.0,
            videoCodec: "H.264",
            assetIdentifier: "asset-1",
            userInfo: ["key": "value"]
        )
        #expect(metadata.id == id)
        #expect(metadata.type == .image)
        #expect(metadata.fileSize == 1024)
        #expect(metadata.imagePath == "img.heic")
        #expect(metadata.videoPath == "vid.mp4")
        #expect(metadata.thumbnailPath == "thumb.jpg")
        #expect(metadata.pixelWidth == 100)
        #expect(metadata.pixelHeight == 200)
        #expect(metadata.duration == 5.0)
        #expect(metadata.videoCodec == "H.264")
        #expect(metadata.assetIdentifier == "asset-1")
        #expect(metadata.userInfo?["key"] == "value")
    }

    // MARK: - Factory Methods
    @Test("image() factory sets correct type and fields")
    func imageFactory() {
        let m = MediaMetadata.image(fileSize: 500, imagePath: "test.jpg", pixelWidth: 800, pixelHeight: 600)
        #expect(m.type == .image)
        #expect(m.fileSize == 500)
        #expect(m.imagePath == "test.jpg")
        #expect(m.pixelWidth == 800)
        #expect(m.pixelHeight == 600)
        #expect(m.videoPath == nil)
        #expect(m.duration == nil)
    }

    @Test("video() factory sets correct type and fields")
    func videoFactory() {
        let m = MediaMetadata.video(fileSize: 2000, videoPath: "test.mp4", pixelWidth: 1920, pixelHeight: 1080, duration: 30.0, videoCodec: "HEVC")
        #expect(m.type == .video)
        #expect(m.videoPath == "test.mp4")
        #expect(m.duration == 30.0)
        #expect(m.videoCodec == "HEVC")
        #expect(m.imagePath == nil)
    }

    @Test("livePhoto() factory sets correct type and fields")
    func livePhotoFactory() {
        let m = MediaMetadata.livePhoto(fileSize: 3000, imagePath: "live.heic", videoPath: "live.mov", pixelWidth: 1920, pixelHeight: 1080, duration: 3.0, assetIdentifier: "asset-id")
        #expect(m.type == .livePhoto)
        #expect(m.imagePath == "live.heic")
        #expect(m.videoPath == "live.mov")
        #expect(m.assetIdentifier == "asset-id")
    }

    // MARK: - Computed Properties
    @Test("pixelSize returns CGSize when both dimensions present")
    func pixelSizePresent() {
        let m = MediaMetadata.image(fileSize: 100, imagePath: "t", pixelWidth: 640, pixelHeight: 480)
        #expect(m.pixelSize == CGSize(width: 640, height: 480))
    }

    @Test("pixelSize returns nil when dimensions missing")
    func pixelSizeNil() {
        let m = MediaMetadata(type: .image, fileSize: 100)
        #expect(m.pixelSize == nil)
    }

    @Test("formattedFileSize returns non-empty string")
    func formattedFileSize() {
        let m = MediaMetadata(type: .image, fileSize: 1024 * 1024)
        let formatted = m.formattedFileSize
        #expect(!formatted.isEmpty)
    }

    @Test("formattedDuration returns string for video")
    func formattedDurationPresent() {
        let m = MediaMetadata.video(fileSize: 100, videoPath: "v", pixelWidth: 100, pixelHeight: 100, duration: 125.0)
        let formatted = m.formattedDuration
        #expect(formatted != nil)
        #expect(!formatted!.isEmpty)
    }

    @Test("formattedDuration returns nil when no duration")
    func formattedDurationNil() {
        let m = MediaMetadata(type: .image, fileSize: 100)
        #expect(m.formattedDuration == nil)
    }

    @Test("isVideo returns true for video and livePhoto")
    func isVideo() {
        #expect(MediaMetadata(type: .video, fileSize: 0).isVideo == true)
        #expect(MediaMetadata(type: .livePhoto, fileSize: 0).isVideo == true)
        #expect(MediaMetadata(type: .image, fileSize: 0).isVideo == false)
        #expect(MediaMetadata(type: .animatedImage, fileSize: 0).isVideo == false)
    }

    @Test("isImage returns true for image and animatedImage")
    func isImage() {
        #expect(MediaMetadata(type: .image, fileSize: 0).isImage == true)
        #expect(MediaMetadata(type: .animatedImage, fileSize: 0).isImage == true)
        #expect(MediaMetadata(type: .video, fileSize: 0).isImage == false)
        #expect(MediaMetadata(type: .livePhoto, fileSize: 0).isImage == false)
    }

    @Test("primaryPath returns imagePath for image types")
    func primaryPathImage() {
        let m = MediaMetadata.image(fileSize: 100, imagePath: "img.heic", pixelWidth: 10, pixelHeight: 10)
        #expect(m.primaryPath == "img.heic")
    }

    @Test("primaryPath returns videoPath for video type")
    func primaryPathVideo() {
        let m = MediaMetadata.video(fileSize: 100, videoPath: "vid.mp4", pixelWidth: 10, pixelHeight: 10, duration: 1.0)
        #expect(m.primaryPath == "vid.mp4")
    }

    // MARK: - Equatable / Hashable
    @Test("Equatable based on id")
    func equatable() {
        let id = MediaID(raw: "same-id")
        let m1 = MediaMetadata(id: id, type: .image, fileSize: 100)
        let m2 = MediaMetadata(id: id, type: .video, fileSize: 200)
        #expect(m1 == m2)
    }

    @Test("Different ids are not equal")
    func notEqual() {
        let m1 = MediaMetadata(id: MediaID(raw: "a"), type: .image, fileSize: 100)
        let m2 = MediaMetadata(id: MediaID(raw: "b"), type: .image, fileSize: 100)
        #expect(m1 != m2)
    }
}
