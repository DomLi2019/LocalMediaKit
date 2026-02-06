import Testing
import Foundation
@testable import LocalMediaKit

@Suite("CacheKey Tests")
struct CacheKeyTests {
    let testID = MediaID(raw: "test-id")

    @Test("image key has correct prefix")
    func imageKey() {
        let key = CacheKey.image(id: testID)
        #expect(key == "image_test-id")
        #expect(key.hasPrefix("image_"))
    }

    @Test("thumbnail key contains size")
    func thumbnailKey() {
        let key = CacheKey.thumbnail(id: testID, size: CGSize(width: 200, height: 300))
        #expect(key == "thumb_test-id_200x300")
        #expect(key.hasPrefix("thumb_"))
        #expect(key.contains("200x300"))
    }

    @Test("livePhotoStill key has correct prefix")
    func livePhotoStillKey() {
        let key = CacheKey.livePhotoStill(id: testID)
        #expect(key == "live_still_test-id")
        #expect(key.hasPrefix("live_still_"))
    }

    @Test("livePhotoVideo key has correct prefix")
    func livePhotoVideoKey() {
        let key = CacheKey.livePhotoVideo(id: testID)
        #expect(key == "live_video_test-id")
        #expect(key.hasPrefix("live_video_"))
    }

    @Test("video key has correct prefix")
    func videoKey() {
        let key = CacheKey.video(id: testID)
        #expect(key == "video_test-id")
        #expect(key.hasPrefix("video_"))
    }

    @Test("videoThumbnail key has correct prefix")
    func videoThumbnailKey() {
        let key = CacheKey.videoThumbnail(id: testID)
        #expect(key == "video_thumb_test-id")
        #expect(key.hasPrefix("video_thumb_"))
    }

    @Test("gif key has correct prefix")
    func gifKey() {
        let key = CacheKey.gif(id: testID)
        #expect(key == "gif_test-id")
        #expect(key.hasPrefix("gif_"))
    }
}
