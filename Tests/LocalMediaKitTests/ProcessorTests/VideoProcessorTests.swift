import Testing
import Foundation
@testable import LocalMediaKit

@Suite("VideoProcessor Tests")
struct VideoProcessorTests {
    let processor = VideoProcessor()

    @Test("detectVideoFormat mp4")
    func detectMP4() {
        let url = URL(fileURLWithPath: "/path/to/video.mp4")
        #expect(processor.detectVideoFormat(at: url) == "mp4")
    }

    @Test("detectVideoFormat m4v maps to mp4")
    func detectM4V() {
        let url = URL(fileURLWithPath: "/path/to/video.m4v")
        #expect(processor.detectVideoFormat(at: url) == "mp4")
    }

    @Test("detectVideoFormat mov")
    func detectMOV() {
        let url = URL(fileURLWithPath: "/path/to/video.mov")
        #expect(processor.detectVideoFormat(at: url) == "mov")
    }

    @Test("detectVideoFormat avi")
    func detectAVI() {
        let url = URL(fileURLWithPath: "/path/to/video.avi")
        #expect(processor.detectVideoFormat(at: url) == "avi")
    }

    @Test("detectVideoFormat unknown extension returns as-is")
    func detectUnknown() {
        let url = URL(fileURLWithPath: "/path/to/video.flv")
        #expect(processor.detectVideoFormat(at: url) == "flv")
    }
}
