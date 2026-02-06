//
//  PathManaging.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import Foundation

public protocol PathManaging: Sendable {
    func generatePath(for id: MediaID, type: MediaType, ext: String) -> MediaURL
    func fullPath(for relativePath: String) -> URL
    func relativePath(for url: URL) -> String
    func thumbnailPath(for id: MediaID, size: CGSize) -> URL
}

extension PathManaging {
    public func generatePath(for id: MediaID, type: MediaType) -> MediaURL {
        generatePath(for: id, type: type, ext: "heic")
    }
}
