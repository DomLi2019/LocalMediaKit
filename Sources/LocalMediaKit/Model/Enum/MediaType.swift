//
//  MediaType.swift
//  媒体类型枚举
//
//  Created by 庄七七 on 2026/1/24.
//

import Foundation

public enum MediaType: Int, Hashable, Equatable, Codable, Sendable {
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
        case .image:
            return "images"
        case .livePhoto:
            return "livePhotos"
        case .video:
            return "videos"
        case .animatedImage:
            return "gifs"
        }
    }
}
