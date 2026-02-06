import Testing
import Foundation
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import LocalMediaKit

@Suite("ImageProcessor Tests")
struct ImageProcessorTests {
    let processor = ImageProcessor()

    // MARK: - Format Detection
    @Test("detectFormat JPEG")
    func detectJPEG() {
        let data = TestHelpers.makeMinimalJPEG()
        let format = processor.detectFormat(from: data)
        if case .jpeg = format {
            // OK
        } else {
            Issue.record("Expected .jpeg, got \(String(describing: format))")
        }
    }

    @Test("detectFormat PNG")
    func detectPNG() {
        let data = TestHelpers.makeMinimalPNG()
        let format = processor.detectFormat(from: data)
        #expect(format == .png)
    }

    @Test("detectFormat GIF")
    func detectGIF() {
        let data = TestHelpers.makeGIFMagicBytes()
        let format = processor.detectFormat(from: data)
        #expect(format == .gif)
    }

    @Test("detectFormat HEIC")
    func detectHEIC() {
        let data = TestHelpers.makeHEICMagicBytes()
        let format = processor.detectFormat(from: data)
        if case .heic = format {
            // OK
        } else {
            Issue.record("Expected .heic, got \(String(describing: format))")
        }
    }

    @Test("detectFormat WebP")
    func detectWebP() {
        let data = TestHelpers.makeWebPMagicBytes()
        let format = processor.detectFormat(from: data)
        #expect(format == .webp)
    }

    @Test("detectFormat unknown data returns .unknown")
    func detectUnknown() {
        let data = Data(repeating: 0x00, count: 20)
        let format = processor.detectFormat(from: data)
        #expect(format == .unknown)
    }

    @Test("detectFormat data too short returns nil")
    func detectTooShort() {
        let data = Data([0x01, 0x02])
        let format = processor.detectFormat(from: data)
        #expect(format == nil)
    }

    // MARK: - Image Size
    @Test("imageSize throws decodingFailed for invalid data")
    func imageSizeInvalidData() {
        let invalidData = Data(repeating: 0x00, count: 20)
        #expect(throws: MediaKitError.self) {
            _ = try processor.imageSize(from: invalidData)
        }
    }

    @Test("imageSize throws decodingFailed for empty data")
    func imageSizeEmptyData() {
        let emptyData = Data()
        #expect(throws: MediaKitError.self) {
            _ = try processor.imageSize(from: emptyData)
        }
    }

    // MARK: - Decode & Encode
    @Test("decode valid data returns UIImage")
    func decodeValid() async throws {
        // Create valid PNG data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: 20, height: 20,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ), let cgImage = ctx.makeImage() else {
            Issue.record("Failed to create CGImage")
            return
        }

        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData, UTType.png.identifier as CFString, 1, nil) else {
            Issue.record("Failed to create image destination")
            return
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else {
            Issue.record("Failed to finalize")
            return
        }

        let decoded = try await processor.decode(mutableData as Data)
        #expect(decoded.size.width > 0)
        #expect(decoded.size.height > 0)
    }

    @Test("encode produces non-empty data")
    func encodeProducesData() async throws {
        let image = TestHelpers.makeTestImage(width: 10, height: 10)
        let data = try await processor.encode(image, format: .jpeg(quality: 0.8))
        #expect(!data.isEmpty)
    }
}
