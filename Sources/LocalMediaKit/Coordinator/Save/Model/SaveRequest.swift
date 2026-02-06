//
//  SaveRequest.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import UIKit
import CoreGraphics

/// 媒体保存请求
public struct SaveRequest: Sendable {
    /// 媒体类型
    public let type: MediaType
    
    /// 媒体数据
    public let data: MediaData
    
    /// 用户信息
    public var userInfo: [String: String]?
    
    /// 是否生成缩略图
    public var generateThumbnail: Bool
    
    /// 缩略图尺寸
    public var thumbnailSize: CGSize
    
    
    /// 初始化
    public init(
        type: MediaType,
        data: MediaData,
        userInfo: [String : String]? = nil,
        generateThumbnail: Bool = true,
        thumbnailSize: CGSize = CGSize(width: 200, height: 200)
    ) {
        self.type = type
        self.data = data
        self.userInfo = userInfo
        self.generateThumbnail = generateThumbnail
        self.thumbnailSize = thumbnailSize
    }
}




// MARK: - 便捷初始化
extension SaveRequest {
    
    /// 创建图片保存请求
    /// - Parameters:
    ///   - data: 图片数据
    ///   - userInfo: 用户自定义信息
    /// - Returns: 保存请求
    public static func image(_ data: Data, thumbnailSize: CGSize? = nil, userInfo: [String: String]? = nil) -> SaveRequest {
        if let thumbnailSize {
            return SaveRequest(type: .image, data: .imageData(data), userInfo: userInfo, generateThumbnail: true, thumbnailSize: thumbnailSize)
        }
        return SaveRequest(type: .image, data: .imageData(data), userInfo: userInfo, generateThumbnail: false)
    }
    
    
    /// 创建图片保存请求，用UIImage
    public static func image(
        _ image: UIImage,
        format: ImageFormat = .default,
        userInfo: [String: String]? = nil
    ) -> SaveRequest {
        return SaveRequest(type: .image, data: .image(image, format: format), userInfo: userInfo)
    }
    
    
    /// 创建实况图保存请求
    public static func livePhoto(
        imageData: Data,
        videoURL: URL,
        userInfo: [String: String]? = nil
    ) -> SaveRequest {
        return SaveRequest(type: .livePhoto, data: .livePhoto(imageData: imageData, videoURL: videoURL), userInfo: userInfo)
    }
    
    
    /// 创建视频保存请求
    public static func video(
        at url: URL,
        userInfo: [String: String]? = nil
    ) -> SaveRequest {
        return SaveRequest(type: .video, data: .videoURL(url), userInfo: userInfo)
    }
}
