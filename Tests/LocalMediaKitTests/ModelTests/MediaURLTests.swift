import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MediaURL Tests")
struct MediaURLTests {
    let imageURL = URL(fileURLWithPath: "/tmp/image.heic")
    let videoURL = URL(fileURLWithPath: "/tmp/video.mp4")
    let avatarURL = URL(fileURLWithPath: "/tmp/avatar.jpg")

    @Test("image case: primaryImageURL returns the URL")
    func imagePrimaryImage() {
        let mediaURL = MediaURL.image(imageURL)
        #expect(mediaURL.primaryImageURL == imageURL)
    }

    @Test("image case: primaryVideoURL returns nil")
    func imagePrimaryVideo() {
        let mediaURL = MediaURL.image(imageURL)
        #expect(mediaURL.primaryVideoURL == nil)
    }

    @Test("livePhoto case: primaryImageURL returns imageURL")
    func livePhotoPrimaryImage() {
        let mediaURL = MediaURL.livePhoto(imageURL: imageURL, videoURL: videoURL)
        #expect(mediaURL.primaryImageURL == imageURL)
    }

    @Test("livePhoto case: primaryVideoURL returns videoURL")
    func livePhotoPrimaryVideo() {
        let mediaURL = MediaURL.livePhoto(imageURL: imageURL, videoURL: videoURL)
        #expect(mediaURL.primaryVideoURL == videoURL)
    }

    @Test("video case: primaryImageURL returns avatarURL")
    func videoPrimaryImage() {
        let mediaURL = MediaURL.video(avatarURL: avatarURL, videoURL: videoURL)
        #expect(mediaURL.primaryImageURL == avatarURL)
    }

    @Test("video case: primaryVideoURL returns videoURL")
    func videoPrimaryVideo() {
        let mediaURL = MediaURL.video(avatarURL: avatarURL, videoURL: videoURL)
        #expect(mediaURL.primaryVideoURL == videoURL)
    }
}
