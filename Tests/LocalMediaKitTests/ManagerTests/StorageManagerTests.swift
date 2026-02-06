import Testing
import Foundation
@testable import LocalMediaKit

@Suite("StorageManager Tests")
struct StorageManagerTests {
    var tempDir: URL!
    let manager = StorageManager()

    init() {
        tempDir = TestHelpers.createTempDirectory()
    }

    func tempFile(_ name: String) -> URL {
        tempDir.appendingPathComponent(name)
    }

    @Test("write and read round trip")
    func writeAndRead() async throws {
        let url = tempFile("test.dat")
        let data = Data("Hello, World!".utf8)
        try await manager.write(data, to: url)
        let read = try await manager.read(from: url)
        #expect(read == data)
    }

    @Test("write creates parent directories")
    func writeCreatesParentDirs() async throws {
        let url = tempDir.appendingPathComponent("sub/dir/file.dat")
        let data = Data("nested".utf8)
        try await manager.write(data, to: url)
        #expect(manager.exists(at: url))
        let read = try await manager.read(from: url)
        #expect(read == data)
    }

    @Test("read nonexistent file throws")
    func readNonexistent() async throws {
        let url = tempFile("nonexistent.dat")
        await #expect(throws: Error.self) {
            try await manager.read(from: url)
        }
    }

    @Test("delete existing file")
    func deleteExisting() async throws {
        let url = tempFile("to-delete.dat")
        try await manager.write(Data("delete me".utf8), to: url)
        #expect(manager.exists(at: url))
        try await manager.delete(at: url)
        #expect(!manager.exists(at: url))
    }

    @Test("delete nonexistent file does not throw")
    func deleteNonexistent() async throws {
        let url = tempFile("not-here.dat")
        try await manager.delete(at: url)
    }

    @Test("copy creates destination file")
    func copy() async throws {
        let source = tempFile("source.dat")
        let dest = tempFile("dest.dat")
        let data = Data("copy me".utf8)
        try await manager.write(data, to: source)
        try await manager.copy(at: source, to: dest)
        #expect(manager.exists(at: dest))
        let read = try await manager.read(from: dest)
        #expect(read == data)
    }

    @Test("exists returns correct results")
    func exists() async throws {
        let url = tempFile("exists-test.dat")
        #expect(!manager.exists(at: url))
        try await manager.write(Data("x".utf8), to: url)
        #expect(manager.exists(at: url))
    }

    @Test("fileSize returns correct size")
    func fileSize() async throws {
        let url = tempFile("size-test.dat")
        let data = Data(repeating: 0xAA, count: 256)
        try await manager.write(data, to: url)
        let size = try manager.fileSize(at: url)
        #expect(size == 256)
    }

    @Test("fileSize on nonexistent file throws")
    func fileSizeNonexistent() throws {
        let url = tempFile("no-file.dat")
        #expect(throws: Error.self) {
            try manager.fileSize(at: url)
        }
    }

    @Test("ensureParentDirectoryExists creates directories")
    func ensureParentDirectoryExists() throws {
        let url = tempDir.appendingPathComponent("new/parent/file.txt")
        try manager.ensureParentDirectoryExists(at: url)
        let parentDir = url.deletingLastPathComponent()
        #expect(manager.isDirectory(at: parentDir))
    }

    @Test("temporaryFileURL preserves extension")
    func temporaryFileURL() {
        let original = URL(fileURLWithPath: "/path/to/file.heic")
        let temp = manager.temporaryFileURL(url: original)
        #expect(temp.pathExtension == "heic")
    }

    @Test("temporaryFileURL generates unique names")
    func temporaryFileURLUnique() {
        let original = URL(fileURLWithPath: "/path/to/file.jpg")
        let temp1 = manager.temporaryFileURL(url: original)
        let temp2 = manager.temporaryFileURL(url: original)
        #expect(temp1 != temp2)
    }

    @Test("temporaryURL generates file in temp directory")
    func temporaryURL() {
        let url = manager.temporaryURL()
        let tempDir = FileManager.default.temporaryDirectory.compatPath
        #expect(url.compatPath.hasPrefix(tempDir))
    }

    @Test("ensureDirectoryExists creates directory")
    func ensureDirectoryExists() throws {
        let dir = tempDir.appendingPathComponent("ensure-dir")
        try manager.ensureDirectoryExists(at: dir)
        #expect(manager.isDirectory(at: dir))
    }

    @Test("ensureDirectoryExists on existing directory does nothing")
    func ensureDirectoryExistsAlready() throws {
        let dir = tempDir.appendingPathComponent("already-exists")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try manager.ensureDirectoryExists(at: dir)
        #expect(manager.isDirectory(at: dir))
    }
}
