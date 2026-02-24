//
//  MetadataManaging.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import Foundation

public protocol MetadataManaging: Sendable {
    func get(id: MediaID) async throws -> MediaMetadata?
    func get(id: MediaID) throws -> MediaMetadata?
    func save(_ metadata: MediaMetadata) async throws
}
