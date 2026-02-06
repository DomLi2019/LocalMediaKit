import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MediaKitError Tests")
struct MediaKitErrorTests {
    // MARK: - Equatable
    @Test("Same case with same values are equal")
    func equalSameCases() {
        let id = MediaID(raw: "test")
        #expect(MediaKitError.mediaNotFound(id) == MediaKitError.mediaNotFound(id))
        #expect(MediaKitError.cacheMiss(id) == MediaKitError.cacheMiss(id))
        #expect(MediaKitError.notConfigured == MediaKitError.notConfigured)
        #expect(MediaKitError.cancelled == MediaKitError.cancelled)
        #expect(MediaKitError.photoLibraryAccessDenied == MediaKitError.photoLibraryAccessDenied)
    }

    @Test("Different cases are not equal")
    func differentCases() {
        let id = MediaID(raw: "test")
        #expect(MediaKitError.mediaNotFound(id) != MediaKitError.cacheMiss(id))
        #expect(MediaKitError.notConfigured != MediaKitError.cancelled)
    }

    @Test("Same case with different values are not equal")
    func sameCaseDifferentValues() {
        let id1 = MediaID(raw: "a")
        let id2 = MediaID(raw: "b")
        #expect(MediaKitError.mediaNotFound(id1) != MediaKitError.mediaNotFound(id2))
    }

    // MARK: - errorDescription
    @Test("mediaNotFound contains media ID")
    func mediaNotFoundDescription() {
        let id = MediaID(raw: "abc123")
        let desc = MediaKitError.mediaNotFound(id).errorDescription
        #expect(desc?.contains("abc123") == true)
    }

    @Test("fileCorrupted contains path")
    func fileCorruptedDescription() {
        let desc = MediaKitError.fileCorrupted(path: "/some/path").errorDescription
        #expect(desc?.contains("/some/path") == true)
    }

    @Test("insufficientDiskSpace contains size info")
    func diskSpaceDescription() {
        let desc = MediaKitError.insufficientDiskSpace(required: 1024, available: 512).errorDescription
        #expect(desc != nil)
        #expect(!desc!.isEmpty)
    }

    @Test("invalidMediaData contains reason")
    func invalidMediaDataDescription() {
        let desc = MediaKitError.invalidMediaData(reason: "bad format").errorDescription
        #expect(desc?.contains("bad format") == true)
    }

    @Test("cacheMiss contains media ID")
    func cacheMissDescription() {
        let id = MediaID(raw: "cache-test")
        let desc = MediaKitError.cacheMiss(id).errorDescription
        #expect(desc?.contains("cache-test") == true)
    }

    @Test("notConfigured has description")
    func notConfiguredDescription() {
        let desc = MediaKitError.notConfigured.errorDescription
        #expect(desc != nil)
        #expect(desc!.contains("configure"))
    }

    @Test("cancelled has description")
    func cancelledDescription() {
        let desc = MediaKitError.cancelled.errorDescription
        #expect(desc != nil)
        #expect(desc!.contains("cancel"))
    }

    @Test("invalidVideo contains reason")
    func invalidVideoDescription() {
        let desc = MediaKitError.invalidVideo(reason: "too short").errorDescription
        #expect(desc?.contains("too short") == true)
    }
}
