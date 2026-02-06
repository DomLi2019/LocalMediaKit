//
//  MediaURLs.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/4.
//

import Foundation

/// 返回多个路径时使用
public enum MediaURL: Sendable {
    case image(URL)
    case livePhoto(imageURL: URL, videoURL: URL)
    case video(avatarURL: URL, videoURL: URL)
    
    
    /// 图片链接
    public var primaryImageURL: URL {
        switch self {
        case .image(let url):
            return url
        case .livePhoto(let imageURL, _):
            return imageURL
        case .video(let avatarURL, _):
            return avatarURL
        }
    }
    
    
    /// 视频
    public var primaryVideoURL: URL? {
        switch self {
        case .image(_):
            return nil
        case .livePhoto(_, let videoURL):
            return videoURL
        case .video(_, let videoURL):
            return videoURL
        }
    }
    
    
    /// 主要URL
    public var primaryURL: URL {
        switch self {
        case .image(let url):
            return url
        case .livePhoto(let imageURL, _):
            return imageURL
        case .video(_, let videoURL):
            return videoURL
        }
    }
}
