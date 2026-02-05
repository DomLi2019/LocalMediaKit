//
//  MediaResource.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/3.
//

import UIKit
import Photos


public enum MediaResource: Sendable {
    /// 静态图片
    case image(UIImage)
    
    /// 实况图（实况图对象 + 可选缩略图）
    case livePhoto(livePhoto: PHLivePhoto, thumbnail: UIImage?)
    
    /// 视频（本地文件URL + 可选缩略图
    case video(url: URL, thumbnail: UIImage?)
    
    /// 动图（原始数据 + 首帧预览图）
    case animatedImage(data: Data, preview: UIImage)
    
    
    /// 获取预览图
    public var previewImage: UIImage? {
        switch self {
        case .image(let image):
            return image
        case .livePhoto(_, let thumbnail):
            return thumbnail
        case .video(_, let thumbnail):
            return thumbnail
        case .animatedImage(_, let preview):
            return preview
        }
    }
}
