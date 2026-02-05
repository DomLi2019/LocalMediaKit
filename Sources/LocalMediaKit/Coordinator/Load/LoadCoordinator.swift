//
//  LoadCoordinator.swift
//  媒体加载协调器类，负责所有加载流程协调
//
//  Created by 庄七七 on 2026/2/1.
//

import UIKit


/// 加载协调器
public final class LoadCoordinator: Sendable {
    private let pathManager: PathManager
    private let storageManager: StorageManager
    private let metadataManager: MetadataManager
    private let imageProcessor: ImageProcessor
    private let videoProcessor: VideoProcessor
    private let livePhotoProcessor: LivePhotoProcessor
    
    
    /// 缓存
    private let imageCache: CacheManager<UIImage>?
    private let thumbnailCache: CacheManager<UIImage>?
    private let dataCache: CacheManager<Data>?
    
    
    init(
        pathManager: PathManager,
        storageManager: StorageManager = StorageManager(),
        metadataManager: MetadataManager,
        imageProcessor: ImageProcessor = ImageProcessor(),
        videoProcessor: VideoProcessor = VideoProcessor(),
        livePhotoProcessor: LivePhotoProcessor = LivePhotoProcessor(),
        imageCache: CacheManager<UIImage>? = nil,
        thumbnailCache: CacheManager<UIImage>? = nil,
        dataCache: CacheManager<Data>? = nil
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
}
