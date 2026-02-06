//
//  PathManager.swift
//  文件路径管理器类
//
//  Created by 庄七七 on 2026/1/25.
//

import Foundation

public final class PathManager: PathManaging, Sendable {
    /// 路径配置
    private let configuration: PathConfiguration
    
    /// 根目录
    private let rootDirectory: URL
    
    
    public init(configuration: PathConfiguration = .default) throws {
        /// 获取用户的路径配置，默认是默认配置
        self.configuration = configuration
        
        /// 如果用户自定义了根目录
        if let customRootDirectory = configuration.rootDirectory {
            self.rootDirectory = customRootDirectory
        }
        /// 如果没有定义根目录，使用默认根目录/Documents/LocalMediaKit
        else {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw MediaKitError.invalidRootDirectory(URL(fileURLWithPath: "/"))
            }
            self.rootDirectory = documentsDirectory.appendingPathComponent("LocalMediaKit")
        }
        
        try ensureRootDirectoryExist()
    }
    
    
    
    
    // MARK: - 外部路径方法
    
    /// 生成完整存储路径
    /// - Parameters:
    ///   - id: 媒体 ID
    ///   - type: 媒体类型
    ///   - ext: 媒体拓展名
    /// - Returns: 路径url
    public func generatePath(for id: MediaID, type: MediaType, ext: String = "heic") -> MediaURL {
        switch type {
        case .image:
            let url = imagePath(for: id, ext: ext)
            return .image(url)
        case .livePhoto:
            let urls = livePhotoPath(for: id)
            return .livePhoto(imageURL: urls.image, videoURL: urls.video)
        case .video:
            let urls = videoPath(for: id, ext: ext)
            return .video(avatarURL: urls.image, videoURL: urls.video)
        case .animatedImage:
            let url = gifPath(for: id)
            return .image(url)
        }
    }
    
    
    /// 拼接完整路径
    /// - Parameter relativePath: 相对路径，比如/Images/FileName.ext
    /// - Returns: 完整路径，比如/Documents/LocalMediaKit/Images/FileName.ext
    public func fullPath(for relativePath: String) -> URL {
        return rootDirectory.appendingPath(relativePath)
    }
    
    
    /// 获取相对路径，解析失败会返回原路径
    /// - Parameter url: 完整路径
    /// - Returns: 相对路径String
    public func relativePath(for url: URL) -> String {
        let fullPath = url.compatPath
        let rootPath = rootDirectory.compatPath
        
        if fullPath.hasPrefix(rootPath) {
            var relative = String(fullPath.dropFirst(rootPath.count))
            if relative.hasPrefix("/") {
                relative = String(relative.dropFirst())
            }
            return relative
        }
        
        return fullPath
    }
    
    
    /// 获取缓存目录，磁盘缓存使用
    public func cacheDirectory(for category: CacheCategory) -> URL {
        return rootDirectory.appendingPath(configuration.cacheDirectory).appendingPath(category.rawValue)
    }
    
    
    
    
    // MARK: - 分类路径
    public func imagePath(for id: MediaID, ext: String) -> URL {
        return buildMediaPath(subDirectory: configuration.imageDirectory, key: CacheKey.image(id: id), ext: ext)
    }
    
    public func livePhotoPath(for id: MediaID) -> (image: URL, video: URL) {
        return (
            buildMediaPath(subDirectory: configuration.livePhotoDirectory, key: CacheKey.livePhotoStill(id: id), ext: "heic"),
            buildMediaPath(subDirectory: configuration.livePhotoDirectory, key: CacheKey.livePhotoVideo(id: id), ext: "mov")
        )
    }
    
    public func videoPath(for id: MediaID, ext: String = "mp4") -> (image: URL, video: URL) {
        return (
            buildMediaPath(subDirectory: configuration.videoDirectory, key: CacheKey.video(id: id), ext: ext),
            buildMediaPath(subDirectory: configuration.videoDirectory, key: CacheKey.videoThumbnail(id: id), ext: "jpg")
        )
    }
    
    
    public func gifPath(for id: MediaID) -> URL {
        return buildMediaPath(subDirectory: configuration.imageDirectory, key: CacheKey.gif(id: id), ext: "gif")
    }
    
    
    /// 获取缩略图存储路径
    /// - Parameters:
    ///   - id: 媒体id
    ///   - size: 媒体尺寸
    /// - Returns: 缓存存储路径
    public func thumbnailPath(for id: MediaID, size: CGSize) -> URL {
        let cacheDirectory = cacheDirectory(for: .thumbnail)
        let fileName = CacheKey.thumbnail(id: id, size: size) + ".jpg"
        return cacheDirectory.appendingPath(fileName)
    }
    
    
    
    
    // MARK: - 私有方法
    /// 确保根目录存在，不存在则创建
    private func ensureRootDirectoryExist() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: rootDirectory.path) {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        }
    }
    
    
    /// 组装媒体路径
    private func buildMediaPath(subDirectory: String, key: String, ext: String) -> URL {
        var paths: [String] = [subDirectory]
        
        let fileName = "\(key).\(ext)"
        paths.append(fileName)
        
        let finalPath = paths.joined(separator: "/")
        
        return rootDirectory.appendingPath(finalPath)
    }
}
