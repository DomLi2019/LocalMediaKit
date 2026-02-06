import Testing
import Foundation
@testable import LocalMediaKit

@Suite("MediaID Tests")
struct MediaIDTests {
    @Test("Default init generates UUID string")
    func defaultInit() {
        let id = MediaID()
        #expect(!id.raw.isEmpty)
        #expect(UUID(uuidString: id.raw) != nil)
    }

    @Test("Init with raw string preserves value")
    func initWithRaw() {
        let id = MediaID(raw: "custom-id")
        #expect(id.raw == "custom-id")
    }

    @Test("Two default inits produce unique IDs")
    func uniqueness() {
        let id1 = MediaID()
        let id2 = MediaID()
        #expect(id1 != id2)
    }

    @Test("Equatable: same raw are equal")
    func equatable() {
        let id1 = MediaID(raw: "same")
        let id2 = MediaID(raw: "same")
        #expect(id1 == id2)
    }

    @Test("Hashable: same raw produce same hash")
    func hashable() {
        let id1 = MediaID(raw: "hash-test")
        let id2 = MediaID(raw: "hash-test")
        #expect(id1.hashValue == id2.hashValue)
        var set = Set<MediaID>()
        set.insert(id1)
        set.insert(id2)
        #expect(set.count == 1)
    }

    @Test("description returns raw string")
    func description() {
        let id = MediaID(raw: "desc-test")
        #expect(id.description == "desc-test")
        #expect(String(describing: id) == "desc-test")
    }

    @Test("debugDescription includes prefix")
    func debugDescription() {
        let id = MediaID(raw: "debug-test")
        #expect(id.debugDescription == "MediaID: debug-test")
    }

    @Test("Codable round trip")
    func codable() throws {
        let original = MediaID(raw: "codable-test")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MediaID.self, from: data)
        #expect(original == decoded)
    }
}
