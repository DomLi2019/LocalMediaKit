import Testing
import Foundation
@testable import LocalMediaKit

@Suite("LoadRequest Tests")
struct LoadRequestTests {
    @Test("Init stores properties")
    func initProperties() {
        let id = MediaID(raw: "load-test")
        let size = CGSize(width: 200, height: 200)
        let request = LoadRequest(id: id, targetSize: size, cachePolicy: .ignoreMemory)
        #expect(request.id == id)
        #expect(request.targetSize == size)
        #expect(request.cachePolicy == .ignoreMemory)
    }

    @Test("original() factory: no targetSize, default policy")
    func originalFactory() {
        let id = MediaID(raw: "orig")
        let request = LoadRequest.original(id: id)
        #expect(request.id == id)
        #expect(request.targetSize == nil)
        #expect(request.cachePolicy == .default)
    }

    @Test("thumbnail() factory: has targetSize, default policy")
    func thumbnailFactory() {
        let id = MediaID(raw: "thumb")
        let size = CGSize(width: 100, height: 100)
        let request = LoadRequest.thumbnail(id: id, targetSize: size)
        #expect(request.id == id)
        #expect(request.targetSize == size)
        #expect(request.cachePolicy == .default)
    }

    @Test("cached() factory: has targetSize, cacheOnly policy")
    func cachedFactory() {
        let id = MediaID(raw: "cached")
        let size = CGSize(width: 50, height: 50)
        let request = LoadRequest.cached(id: id, targetSize: size)
        #expect(request.id == id)
        #expect(request.targetSize == size)
        #expect(request.cachePolicy == .cacheOnly)
    }

    @Test("targetSize defaults to nil")
    func targetSizeDefault() {
        let request = LoadRequest(id: MediaID(), cachePolicy: .default)
        #expect(request.targetSize == nil)
    }
}
