//
//  ImageFormat.swift
//  静态图片的格式枚举
//
//  Created by 庄七七 on 2026/1/31.
//

import Foundation

/// 图片格式
public enum ImageFormat: Sendable, Equatable {
    /// JPEG 格式
    case jpeg(quality: CGFloat? = nil)
    
    /// PNG 格式
    case png
    
    /// HEIC 格式
    case heic(quality: CGFloat? = nil)
    
    /// GIF 格式
    case gif
    
    /// WEBP 格式
    case webp
    
    /// 未知格式
    case unknown
    
    /// 默认格式（HEIC）
    public static var `default`: ImageFormat {
        return .heic(quality: 1.0)
    }
    
    /// 文件扩展名
    var fileExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        case .gif:
            return "gif"
        case .webp:
            return "webp"
        case .unknown:
            return "dat"
        }
    }
    
    /// 是否是动图格式
    public var isAnimated: Bool {
        return self == .gif
    }
}

