//
//  CacheKey.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/4.
//

import Foundation


/// 缓存键和文件名前缀生成器
public enum CacheKey {
    /// 图片
    public static func image(id: MediaID) -> String {
        return "image_\(id.raw)"
    }
    
    /// 缩略图
    public static func thumbnail(id: MediaID, size: CGSize) -> String {
        return "thumb_\(id.raw)_\(Int(size.width))x\(Int(size.height))"
    }
    
    /// 实况图图片
    public static func livePhotoStill(id: MediaID) -> String {
        return "live_still_\(id.raw)"
    }
    
    /// 实况图视频
    public static func livePhotoVideo(id: MediaID) -> String {
        return "live_video_\(id.raw)"
    }
    
    /// 视频
    public static func video(id: MediaID) -> String {
        return "video_\(id.raw)"
    }
    
    /// 视频缩略图
    public static func videoThumbnail(id: MediaID) -> String {
        return "video_thumb_\(id.raw)"
    }
    
    /// 动图
    public static func gif(id: MediaID) -> String {
        return "gif_\(id.raw)"
    }
}
