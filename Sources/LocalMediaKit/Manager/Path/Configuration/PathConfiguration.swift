//
//  PathConfiguration.swift
//  路径配置结构体，给文件管理器用
//
//  Created by 庄七七 on 2026/1/24.
//

import Foundation


public struct PathConfiguration: Sendable {
    /// 根目录，比如/Documents/LocalMediaKit
    public var rootDirectory: URL?
    
    /// 图片目录
    public var imageDirectory: String
    
    /// 实况图目录
    public var livePhotoDirectory: String
    
    /// 视频目录
    public var videoDirectory: String
    
    /// 缓存目录
    public var cacheDirectory: String
    
    
    
    
    // MARK: - 初始化方法 - 带默认值的
    public init(
        rootDirectory: URL? = nil,
        imageDirectory: String = MediaType.image.directory,
        livePhotoDirectory: String = MediaType.livePhoto.directory,
        videoDirectory: String = MediaType.video.directory,
        cacheDirectory: String = "Cache"
    ) {
        self.rootDirectory = rootDirectory
        self.imageDirectory = imageDirectory
        self.livePhotoDirectory = livePhotoDirectory
        self.videoDirectory = videoDirectory
        self.cacheDirectory = cacheDirectory
    }
    
    
    /// 默认配置
    public static var `default`: PathConfiguration {
        return PathConfiguration()
    }
    
    
    /// 获取对应类型的子目录路径
    public func subDirectory(for type: MediaType) -> String {
        switch type {
        case .image, .animatedImage:
            return imageDirectory
        case .livePhoto:
            return livePhotoDirectory
        case .video:
            return videoDirectory
        }
    }
}
