//
//  LoadCoordinator.swift
//  媒体加载协调器类，负责所有加载流程协调
//
//  Created by 庄七七 on 2026/2/1.
//

import UIKit
import Photos

/// 加载协调器
public final class LoadCoordinator: Sendable {
    private let pathManager: any PathManaging
    private let storageManager: any StorageManaging
    private let metadataManager: any MetadataManaging
    private let imageProcessor: any ImageProcessing
    private let videoProcessor: any VideoProcessing
    private let livePhotoProcessor: any LivePhotoProcessing


    /// 缓存
    private let imageCache: CacheManager<UIImage>?
    private let thumbnailCache: CacheManager<UIImage>?
    private let dataCache: CacheManager<Data>?


    init(
        pathManager: any PathManaging,
        storageManager: any StorageManaging,
        metadataManager: any MetadataManaging,
        imageProcessor: any ImageProcessing,
        videoProcessor: any VideoProcessing,
        livePhotoProcessor: any LivePhotoProcessing,
        imageCache: CacheManager<UIImage>?,
        thumbnailCache: CacheManager<UIImage>?,
        dataCache: CacheManager<Data>?
    ) {
        self.pathManager = pathManager
        self.storageManager = storageManager
        self.metadataManager = metadataManager
        self.imageProcessor = imageProcessor
        self.videoProcessor = videoProcessor
        self.livePhotoProcessor = livePhotoProcessor
        self.imageCache = imageCache
        self.thumbnailCache = thumbnailCache
        self.dataCache = dataCache
    }
    
    
    
    
    // MARK: - 加载
    
    /// 加载媒体资源，总调度函数
    /// - Parameter request: 加载请求
    /// - Returns: 媒体资源
    public func load(_ request: LoadRequest) async throws -> MediaResource {
        guard let metadata = try await metadataManager.get(id: request.id) else {
            throw MediaKitError.mediaNotFound(request.id)
        }
        
        switch metadata.type {
        case .image:
            return try await loadImage(metadata: metadata, request: request)
        case .livePhoto:
            return try await loadLivePhoto(metadata: metadata, request: request)
        case .video:
            return try await loadVideo(metadata: metadata, request: request)
        case .animatedImage:
            return try await loadAnimatedImage(metadata: metadata, request: request)
        }
    }
    
    
    /// 加载缩略图
    /// - Parameters:
    ///   - id: 媒体 ID
    ///   - size: 缩略图尺寸
    /// - Returns: 缩略图
    public func loadThumbnail(id: MediaID, size: CGSize) async throws -> UIImage {
        /// 获取元数据
        guard let metadata = try await metadataManager.get(id: id) else {
            throw MediaKitError.mediaNotFound(id)
        }
        
        /// 组件Key
        let cacheKey = CacheKey.thumbnail(id: id, size: size)
        
        /// 查缓存
        if let cache = thumbnailCache, let cached = await cache.get(cacheKey) {
            return cached
        }
        
        /// 查磁盘缓存
        if let thumbnailPath = metadata.thumbnailPath {
            let thumbnailURL = pathManager.fullPath(for: thumbnailPath)
            
            if storageManager.exists(at: thumbnailURL) {
                let imageData = try await storageManager.read(from: thumbnailURL)
                let thumbnail = try await imageProcessor.decode(imageData)
                debugPrint("loadThumbnail read from disk cache: \(thumbnailURL)")
                
                /// 放入缓存
                if let cache = thumbnailCache {
                    await cache.set(cacheKey, value: thumbnail)
                }
                
                return thumbnail
            }
        }
        
        // 从源文件生产缩略图
        /// 获取完整路径
        let fileURL = pathManager.fullPath(for: metadata.primaryPath)
        
        /// 获取缩略图
        let thumbnail: UIImage
        switch metadata.type {
        case .image, .animatedImage, .livePhoto:
            thumbnail = try await imageProcessor.thumbnail(at: .url(fileURL), targetSize: size)
            
        case .video:
            thumbnail = try await videoProcessor.extractThumbnail(from: fileURL)
        }
        
        /// 放入缓存
        if let cache = thumbnailCache {
            await cache.set(cacheKey, value: thumbnail)
        }
        
        return thumbnail
    }
    
    
    
    
    // MARK: - 加载图片
    public func loadImage(metadata: MediaMetadata, request: LoadRequest) async throws -> MediaResource {
        /// 如果有目标尺寸，加载缩略图
        if let targetSize = request.targetSize {
            let thumbnail = try await loadThumbnail(id: metadata.id, size: targetSize)
            return .image(thumbnail)
        }
        
        /// 获取缓存Key
        let cacheKey = CacheKey.image(id: metadata.id)
        
        /// 查缓存
        if request.cachePolicy.useMemoryCache, let cache = imageCache {
            if let cached = await cache.get(cacheKey) {
                return .image(cached)
            }
        }
        
        /// 仅缓存模式，停止
        if request.cachePolicy == .cacheOnly {
            throw MediaKitError.cacheMiss(metadata.id)
        }
        
        /// 检查文件
        let fileURL = pathManager.fullPath(for: metadata.primaryPath)
        guard storageManager.exists(at: fileURL) else {
            throw MediaKitError.fileCorrupted(path: fileURL.compatPath)
        }
        
        /// 读取文件，生成图片
        let data = try await storageManager.read(from: fileURL)
        let image = try await imageProcessor.decode(data)
        
        /// 写入缓存
        if request.cachePolicy.useMemoryCache, let cache = imageCache {
            await cache.set(cacheKey, value: image)
        }
        
        return .image(image)
    }
    
    
    
    
    // MARK: - 加载视频
    public func loadVideo(metadata: MediaMetadata, request: LoadRequest) async throws -> MediaResource {
        let fileURL = pathManager.fullPath(for: metadata.primaryPath)
        
        guard storageManager.exists(at: fileURL) else {
            throw MediaKitError.fileCorrupted(path: fileURL.compatPath)
        }
        
        var thumbnail: UIImage?
        let cacheKey = CacheKey.videoThumbnail(id: metadata.id)
        
        if let cache = thumbnailCache, let cached = await cache.get(cacheKey) {
            thumbnail = cached
        } else {
            do {
                thumbnail = try await videoProcessor.extractThumbnail(from: fileURL)
            } catch {
                debugPrint("loadVideo 视频缩略图加载失败: \(error)")
            }
        }
        
        return .video(url: fileURL, thumbnail: thumbnail)
    }
    
    
    
    
    // MARK: - 加载实况图
    public func loadLivePhoto(metadata: MediaMetadata, request: LoadRequest) async throws -> MediaResource {
        /// 如果有目标尺寸，返回静态图
        if let targetSize = request.targetSize {
            let thumbnail = try await loadThumbnail(id: metadata.id, size: targetSize)
            return .image(thumbnail)
        }
        
        /// 检查文件路径
        guard let imagePath = metadata.imagePath,
              let videoPath = metadata.videoPath
        else {
            throw MediaKitError.invalidMetadata(reason: "Live photo missing path")
        }
        let imageURL = pathManager.fullPath(for: imagePath)
        let videoURL = pathManager.fullPath(for: videoPath)
        
        /// 检查文件是否存在
        guard storageManager.exists(at: imageURL) else {
            throw MediaKitError.fileCorrupted(path: imageURL.compatPath)
        }
        guard storageManager.exists(at: videoURL) else {
            throw MediaKitError.fileCorrupted(path: videoURL.compatPath)
        }
        
        /// 组装实况图
        let livePhoto = try await livePhotoProcessor.assemble(imageURL: imageURL, videoURL: videoURL)
        
        return .livePhoto(livePhoto: livePhoto, thumbnail: nil)
    }
    
    
    
    
    // MARK: - 加载动图
    public func loadAnimatedImage(metadata: MediaMetadata, request: LoadRequest) async throws -> MediaResource {
        /// 如果有目标尺寸，加载缩略图
        if let targetSize = request.targetSize {
            let thumbnail = try await loadThumbnail(id: metadata.id, size: targetSize)
            return .image(thumbnail)
        }
        
        /// 获取缓存Key
        let cacheKey = CacheKey.gif(id: metadata.id)
        
        /// 查缓存
        if request.cachePolicy.useMemoryCache, let cache = dataCache {
            if let cachedData = await cache.get(cacheKey) {
                let preview = try await imageProcessor.decode(cachedData)
                return .animatedImage(data: cachedData, preview: preview)
            }
        }
        
        /// 仅缓存模式，停止
        if request.cachePolicy == .cacheOnly {
            throw MediaKitError.cacheMiss(metadata.id)
        }
        
        /// 检查文件
        let fileURL = pathManager.fullPath(for: metadata.primaryPath)
        guard storageManager.exists(at: fileURL) else {
            throw MediaKitError.fileCorrupted(path: fileURL.compatPath)
        }
        
        /// 读取文件，生成图片
        let data = try await storageManager.read(from: fileURL)
        let preview = try await imageProcessor.decode(data)
        
        /// 写入缓存
        if request.cachePolicy.useMemoryCache, let cache = dataCache {
            await cache.set(cacheKey, value: data)
        }
        
        return .animatedImage(data: data, preview: preview)
    }
    
    
    
    
    // MARK: - URL加载
    
    /// 用URL加载图片
    /// - Parameters:
    ///   - url: 图片路径URL
    ///   - cacheKey: 缓存Key，建议传文件名或其他已有id
    /// - Returns: 图片
    public func loadImage(at url: URL, cacheKey: String? = nil) async throws -> UIImage {
        let key = cacheKey ?? url.lastPathComponent
        
        /// 查缓存
        if let cache = imageCache, let cached = await cache.get(key) {
            return cached
        }
        
        /// 检查文件是否存在
        guard storageManager.exists(at: url) else {
            throw MediaKitError.fileNotFound(url)
        }
        
        /// 读取文件并解码成图片
        let data = try await storageManager.read(from: url)
        let image = try await imageProcessor.decode(data)
        
        /// 写入缓存
        if let cache = imageCache {
            await cache.set(key, value: image)
        }
        return image
    }
    
    
    /// 用URL加载实况图
    /// - Parameters:
    ///   - imageURL: 图片路径
    ///   - videoURL: 视频路径
    /// - Returns: 实况图对象
    public func loadLivePhoto(imageURL: URL, videoURL: URL) async throws -> PHLivePhoto {
        /// 检查文件是否存在
        guard storageManager.exists(at: imageURL), storageManager.exists(at: videoURL) else {
            throw MediaKitError.fileNotFound(imageURL)
        }
        let livePhoto = try await livePhotoProcessor.assemble(imageURL: imageURL, videoURL: videoURL)
        return livePhoto
    }
    
    
    /// 用URL加载缩略图
    public func loadThumbnail(at url: URL, size: CGSize, cacheKey: String? = nil) async throws -> UIImage {
        let key = cacheKey ?? "\(url.lastPathComponent)_\(Int(size.width))x\(Int(size.height))"
        
        /// 查缓存
        if let cache = thumbnailCache, let cached = await cache.get(key) {
            debugPrint("🟢 loadThumbnail 缩略图缓存命中: \(key)")
            return cached
        }
        
        debugPrint("🔴 loadThumbnail 缩略图缓存未命中，从文件加载: \(key)")
        /// 检查文件是否存在
        guard storageManager.exists(at: url) else {
            throw MediaKitError.fileNotFound(url)
        }
        
        /// 获取缩略图
        let thumbnail = try await imageProcessor.thumbnail(at: .url(url), targetSize: size)
        
        /// 写入缓存
        if let cache = thumbnailCache {
            await cache.set(key, value: thumbnail)
        }
        return thumbnail
    }
    
    
    /// 用URL加载视频缩略图
    public func loadVideoThumbnail(at url: URL, size: CGSize, cacheKey: String? = nil) async throws -> UIImage {
        let key = cacheKey ?? "\(url.lastPathComponent)_\(Int(size.width))x\(Int(size.height))"
        
        /// 查缓存
        if let cache = thumbnailCache, let cached = await cache.get(key) {
            return cached
        }
        
        /// 检查文件是否存在
        guard storageManager.exists(at: url) else {
            throw MediaKitError.fileNotFound(url)
        }
        /// 获取缩略图
        let thumbnail = try await videoProcessor.extractThumbnail(from: url)
        
        /// 写入缓存
        if let cache = thumbnailCache {
            await cache.set(key, value: thumbnail)
        }
        return thumbnail
    }
    
    
    
    
    // MARK: - 获取文件URL
    /// 获取文件 URL（不加载到内存）
    /// - Parameter id: 媒体 ID
    /// - Returns: 文件 URL
    public func loadMediaURL(for id: MediaID) async throws -> MediaURL {
        guard let metadata = try await metadataManager.get(id: id) else {
            throw MediaKitError.mediaNotFound(id)
        }
        
        switch metadata.type {
        case .image, .animatedImage:
            /// 获取Path
            guard let imagePath = metadata.imagePath else {
                throw MediaKitError.invalidMediaData(reason: "Image path is nil ")
            }
            
            /// 获取完整 URL
            let imageURL = pathManager.fullPath(for: imagePath)
            
            /// 检查 URL 是否存在
            guard storageManager.exists(at: imageURL) else {
                throw MediaKitError.fileCorrupted(path: imagePath)
            }
            
            return .image(imageURL)
            
        case .livePhoto:
            /// 获取Path
            guard let imagePath = metadata.imagePath, let videoPath = metadata.videoPath else {
                throw MediaKitError.invalidMediaData(reason: "Meida paths are nil ")
            }
            /// 获取完整 URL
            let imageURL = pathManager.fullPath(for: imagePath)
            let videoURL = pathManager.fullPath(for: videoPath)
            
            /// 检查 URL 是否存在
            guard storageManager.exists(at: imageURL), storageManager.exists(at: videoURL) else {
                throw MediaKitError.fileCorrupted(path: imagePath)
            }
            
            /// 返回
            return .livePhoto(imageURL: imageURL, videoURL: videoURL)
            
        case .video:
            /// 获取Path
            guard let videoPath = metadata.videoPath else {
                throw MediaKitError.invalidMediaData(reason: "Video path is nil ")
            }
            /// 获取 URL
            let videoURL = pathManager.fullPath(for: videoPath)
            
            /// 检查 URL 是否存在
            guard storageManager.exists(at: videoURL) else {
                throw MediaKitError.fileCorrupted(path: videoPath)
            }
            
            /// 检查缩略图是否存在
            if let thumbnailPath = metadata.thumbnailPath {
                let thumbnailURL = pathManager.fullPath(for: thumbnailPath)
                if storageManager.exists(at: thumbnailURL) {
                    return .video(avatarURL: thumbnailURL, videoURL: videoURL)
                }
            }
            
            return .video(avatarURL: nil, videoURL: videoURL)
        }
    }
    
    
    
    
    // MARK: - 获取媒体元数据
    public func loadMediaMetadata(for id: MediaID) async throws -> MediaMetadata {
        guard let metadata = try await metadataManager.get(id: id) else {
            throw MediaKitError.mediaNotFound(id)
        }
        return metadata
    }
        
    
    
    
    // MARK: - 预加载
    /// 预加载缩略图
    /// - Parameters:
    ///   - ids: 媒体 ID 数组
    ///   - size: 缩略图尺寸
    public func preloadThumbnail(ids: [MediaID], size: CGSize) async {
        for id in ids {
            do {
                _ = try await loadThumbnail(id: id, size: size)
            } catch {
                debugPrint("preloadThumbnail 失败, 媒体 ID： \(id)")
            }
        }
    }
}
