//
//  StorageManaging.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import Foundation

public protocol StorageManaging: Sendable {
    func write(_ data: Data, to url: URL) async throws
    func read(from url: URL) async throws -> Data
    func copy(at source: URL, to destination: URL) async throws
    func delete(at url: URL) async throws
    func exists(at url: URL) -> Bool
    func fileSize(at url: URL) throws -> Int64
    func extractExtension(url: URL) -> String
    func ensureDirectoryExists(at url: URL) throws
}
