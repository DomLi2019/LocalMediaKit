import Testing
import Foundation
@testable import LocalMediaKit

@Suite("LocalMediaType Tests")
struct LocalMediaTypeTests {
    @Test("Raw values are correct", arguments: [
        (LocalMediaType.image, 0),
        (LocalMediaType.livePhoto, 1),
        (LocalMediaType.video, 2),
        (LocalMediaType.animatedImage, 3),
    ])
    func rawValues(type: LocalMediaType, expected: Int) {
        #expect(type.rawValue == expected)
    }

    @Test("Default extensions", arguments: [
        (LocalMediaType.image, "heic"),
        (LocalMediaType.livePhoto, "heic"),
        (LocalMediaType.video, "mp4"),
        (LocalMediaType.animatedImage, "gif"),
    ])
    func defaultExtensions(type: LocalMediaType, expected: String) {
        #expect(type.defaultExtension == expected)
    }

    @Test("Directory names", arguments: [
        (LocalMediaType.image, "Images"),
        (LocalMediaType.livePhoto, "LivePhotos"),
        (LocalMediaType.video, "Videos"),
        (LocalMediaType.animatedImage, "Images"),
    ])
    func directoryNames(type: LocalMediaType, expected: String) {
        #expect(type.directory == expected)
    }

    @Test("CaseIterable contains all 4 cases")
    func caseIterable() {
        let allCases = LocalMediaType.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.image))
        #expect(allCases.contains(.livePhoto))
        #expect(allCases.contains(.video))
        #expect(allCases.contains(.animatedImage))
    }

    @Test("Init from raw value")
    func initFromRawValue() {
        #expect(LocalMediaType(rawValue: 0) == .image)
        #expect(LocalMediaType(rawValue: 1) == .livePhoto)
        #expect(LocalMediaType(rawValue: 2) == .video)
        #expect(LocalMediaType(rawValue: 3) == .animatedImage)
        #expect(LocalMediaType(rawValue: 99) == nil)
    }

    @Test("Codable round trip")
    func codable() throws {
        for type in LocalMediaType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(LocalMediaType.self, from: data)
            #expect(type == decoded)
        }
    }
}
