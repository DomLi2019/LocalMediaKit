//
//  VideoProcessing.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import UIKit
import AVFoundation

public protocol VideoProcessing: Sendable {
    func extractThumbnail(from url: URL, at time: CMTime?) async throws -> UIImage
    func extractThumbnailSync(from url: URL, at time: CMTime?) throws -> UIImage
    func videoInfo(of url: URL) async throws -> VideoInfo
    func isValid(at url: URL) async -> Bool
    func duration(from url: URL) async throws -> TimeInterval
    func detectVideoFormat(at url: URL) -> String
}
