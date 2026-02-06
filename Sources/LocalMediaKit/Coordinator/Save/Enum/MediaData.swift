//
//  MediaData.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import UIKit


/// 媒体数据的输入类型
public enum MediaData: Sendable {
    /// 原始图片数据
    case imageData(Data)
    
    /// UIImage对象，指定编码格式
    case image(UIImage, format: ImageFormat)
    
    /// 实况图，图片数据 + 视频URL
    case livePhoto(imageData: Data, videoURL: URL)
    
    /// 视频文件URL，拷贝到内部存储
    case videoURL(URL)
}
