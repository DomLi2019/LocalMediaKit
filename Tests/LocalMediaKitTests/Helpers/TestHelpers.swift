import Foundation
import UIKit
@testable import LocalMediaKit

enum TestHelpers {
    /// Create a temporary directory for tests
    static func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalMediaKitTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    /// Clean up a temporary directory
    static func cleanupTempDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Create a test UIImage programmatically
    static func makeTestImage(width: Int = 100, height: Int = 100, color: UIColor = .red) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Create minimal valid JPEG data
    static func makeMinimalJPEG() -> Data {
        let image = makeTestImage(width: 2, height: 2, color: .blue)
        return image.jpegData(compressionQuality: 0.5)!
    }

    /// Create minimal valid PNG data
    static func makeMinimalPNG() -> Data {
        let image = makeTestImage(width: 2, height: 2, color: .green)
        return image.pngData()!
    }

    /// GIF magic bytes for format detection
    static func makeGIFMagicBytes() -> Data {
        // GIF89a header + enough padding
        var bytes: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
        bytes += Array(repeating: 0x00, count: 10)
        return Data(bytes)
    }

    /// WebP magic bytes for format detection
    static func makeWebPMagicBytes() -> Data {
        // RIFF....WEBP
        var bytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]
        return Data(bytes)
    }

    /// HEIC magic bytes for format detection
    static func makeHEICMagicBytes() -> Data {
        // ....ftypheic
        var bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        bytes += Array("ftyp".utf8)
        bytes += Array("heic".utf8)
        return Data(bytes)
    }

    /// Create a test MediaMetadata for image
    static func makeImageMetadata(
        id: MediaID = MediaID(),
        imagePath: String = "Images/test.heic",
        fileSize: Int64 = 1024
    ) -> MediaMetadata {
        MediaMetadata.image(
            id: id,
            fileSize: fileSize,
            imagePath: imagePath,
            pixelWidth: 100,
            pixelHeight: 100
        )
    }

    /// Create a test MediaMetadata for video
    static func makeVideoMetadata(
        id: MediaID = MediaID(),
        videoPath: String = "Videos/test.mp4",
        fileSize: Int64 = 2048
    ) -> MediaMetadata {
        MediaMetadata.video(
            id: id,
            fileSize: fileSize,
            videoPath: videoPath,
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 10.0,
            videoCodec: "H.264"
        )
    }

    /// Create a test MediaMetadata for livePhoto
    static func makeLivePhotoMetadata(
        id: MediaID = MediaID(),
        imagePath: String = "LivePhotos/test.heic",
        videoPath: String = "LivePhotos/test.mov",
        fileSize: Int64 = 3072
    ) -> MediaMetadata {
        MediaMetadata.livePhoto(
            id: id,
            fileSize: fileSize,
            imagePath: imagePath,
            videoPath: videoPath,
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 3.0,
            assetIdentifier: "test-asset-id"
        )
    }
}
