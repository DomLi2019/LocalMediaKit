//
//  LivePhotoProcessing.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import Foundation
import Photos

public protocol LivePhotoProcessing: Sendable {
    func assemble(imageURL: URL, videoURL: URL) async throws -> PHLivePhoto
}
