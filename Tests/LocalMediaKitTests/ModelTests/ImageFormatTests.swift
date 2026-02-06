import Testing
import Foundation
@testable import LocalMediaKit

@Suite("ImageFormat Tests")
struct ImageFormatTests {
    @Test("fileExtension values", arguments: [
        (ImageFormat.jpeg(quality: nil), "jpg"),
        (ImageFormat.png, "png"),
        (ImageFormat.heic(quality: nil), "heic"),
        (ImageFormat.gif, "gif"),
        (ImageFormat.webp, "webp"),
        (ImageFormat.unknown, "dat"),
    ])
    func fileExtensions(format: ImageFormat, expected: String) {
        #expect(format.fileExtension == expected)
    }

    @Test("default is heic with quality 1.0")
    func defaultFormat() {
        let fmt = ImageFormat.default
        if case .heic(let quality) = fmt {
            #expect(quality == 1.0)
        } else {
            Issue.record("Expected .heic")
        }
    }

    @Test("isAnimated only true for gif")
    func isAnimated() {
        #expect(ImageFormat.gif.isAnimated == true)
        #expect(ImageFormat.jpeg(quality: nil).isAnimated == false)
        #expect(ImageFormat.png.isAnimated == false)
        #expect(ImageFormat.heic(quality: nil).isAnimated == false)
        #expect(ImageFormat.webp.isAnimated == false)
        #expect(ImageFormat.unknown.isAnimated == false)
    }

    @Test("Equatable: same formats are equal")
    func equatable() {
        #expect(ImageFormat.png == ImageFormat.png)
        #expect(ImageFormat.gif == ImageFormat.gif)
        #expect(ImageFormat.jpeg(quality: 0.8) == ImageFormat.jpeg(quality: 0.8))
    }

    @Test("Equatable: different formats are not equal")
    func notEqual() {
        #expect(ImageFormat.png != ImageFormat.gif)
        #expect(ImageFormat.jpeg(quality: 0.5) != ImageFormat.jpeg(quality: 0.8))
    }
}
