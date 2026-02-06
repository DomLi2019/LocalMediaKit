import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MediaType Tests")
struct MediaTypeTests {
    @Test("Raw values are correct", arguments: [
        (MediaType.image, 0),
        (MediaType.livePhoto, 1),
        (MediaType.video, 2),
        (MediaType.animatedImage, 3),
    ])
    func rawValues(type: MediaType, expected: Int) {
        #expect(type.rawValue == expected)
    }

    @Test("Default extensions", arguments: [
        (MediaType.image, "heic"),
        (MediaType.livePhoto, "heic"),
        (MediaType.video, "mp4"),
        (MediaType.animatedImage, "gif"),
    ])
    func defaultExtensions(type: MediaType, expected: String) {
        #expect(type.defaultExtension == expected)
    }

    @Test("Directory names", arguments: [
        (MediaType.image, "Images"),
        (MediaType.livePhoto, "LivePhotos"),
        (MediaType.video, "Videos"),
        (MediaType.animatedImage, "Images"),
    ])
    func directoryNames(type: MediaType, expected: String) {
        #expect(type.directory == expected)
    }

    @Test("CaseIterable contains all 4 cases")
    func caseIterable() {
        let allCases = MediaType.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.image))
        #expect(allCases.contains(.livePhoto))
        #expect(allCases.contains(.video))
        #expect(allCases.contains(.animatedImage))
    }

    @Test("Init from raw value")
    func initFromRawValue() {
        #expect(MediaType(rawValue: 0) == .image)
        #expect(MediaType(rawValue: 1) == .livePhoto)
        #expect(MediaType(rawValue: 2) == .video)
        #expect(MediaType(rawValue: 3) == .animatedImage)
        #expect(MediaType(rawValue: 99) == nil)
    }

    @Test("Codable round trip")
    func codable() throws {
        for type in MediaType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(MediaType.self, from: data)
            #expect(type == decoded)
        }
    }
}
