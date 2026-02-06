import Testing
import Foundation
import UIKit
@testable import LocalMediaKit

@Suite("SaveRequest Tests")
struct SaveRequestTests {
    @Test("Init default values")
    func initDefaults() {
        let request = SaveRequest(type: .image, data: .imageData(Data()))
        #expect(request.type == .image)
        #expect(request.userInfo == nil)
        #expect(request.generateThumbnail == true)
        #expect(request.thumbnailSize == CGSize(width: 200, height: 200))
    }

    @Test("image(Data) factory without thumbnailSize: no thumbnail")
    func imageDataFactory() {
        let data = Data([0x01, 0x02])
        let request = SaveRequest.image(data, userInfo: ["k": "v"])
        #expect(request.type == .image)
        #expect(request.generateThumbnail == false)
        #expect(request.userInfo?["k"] == "v")
        if case .imageData(let d) = request.data {
            #expect(d == data)
        } else {
            Issue.record("Expected .imageData")
        }
    }

    @Test("image(Data) factory with thumbnailSize: generates thumbnail")
    func imageDataFactoryWithThumbnail() {
        let data = Data([0x01, 0x02])
        let size = CGSize(width: 150, height: 150)
        let request = SaveRequest.image(data, thumbnailSize: size)
        #expect(request.generateThumbnail == true)
        #expect(request.thumbnailSize == size)
    }

    @Test("image(UIImage) factory")
    func imageUIImageFactory() {
        let image = TestHelpers.makeTestImage()
        let request = SaveRequest.image(image, format: .png)
        #expect(request.type == .image)
        if case .image(_, let format) = request.data {
            #expect(format == .png)
        } else {
            Issue.record("Expected .image")
        }
    }

    @Test("livePhoto() factory")
    func livePhotoFactory() {
        let data = Data([0x01])
        let url = URL(fileURLWithPath: "/tmp/video.mov")
        let request = SaveRequest.livePhoto(imageData: data, videoURL: url)
        #expect(request.type == .livePhoto)
        if case .livePhoto(let imageData, let videoURL) = request.data {
            #expect(imageData == data)
            #expect(videoURL == url)
        } else {
            Issue.record("Expected .livePhoto")
        }
    }

    @Test("video() factory")
    func videoFactory() {
        let url = URL(fileURLWithPath: "/tmp/video.mp4")
        let request = SaveRequest.video(at: url, userInfo: ["source": "camera"])
        #expect(request.type == .video)
        #expect(request.userInfo?["source"] == "camera")
        if case .videoURL(let videoURL) = request.data {
            #expect(videoURL == url)
        } else {
            Issue.record("Expected .videoURL")
        }
    }
}
