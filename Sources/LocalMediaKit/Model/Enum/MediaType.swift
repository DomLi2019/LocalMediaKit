//
//  LocalMediaType.swift
//  媒体类型枚举
//
//  Created by 庄七七 on 2026/1/24.
//

import Foundation
import GRDB

public enum LocalMediaType: Int, Hashable, Equatable, Codable, Sendable, CaseIterable {
    case image = 0
    case livePhoto = 1
    case video = 2
    case animatedImage = 3
    
    
    /// 默认文件拓展名
    public var defaultExtension: String {
        switch self {
        case .image:
            return "heic"
        case .livePhoto:
            return "heic"
        case .video:
            return "mp4"
        case .animatedImage:
            return "gif"
        }
    }
    
    
    /// 默认文件路径后缀
    public var directory: String {
        switch self {
        case .image, .animatedImage:
            return "Images"
        case .livePhoto:
            return "LivePhotos"
        case .video:
            return "Videos"
        }
    }
}

/// GRDB支持
extension LocalMediaType: DatabaseValueConvertible {}
