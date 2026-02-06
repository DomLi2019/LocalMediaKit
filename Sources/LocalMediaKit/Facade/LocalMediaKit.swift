//
//  LocalMediaKit.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import UIKit
import Photos

/// 本地媒体资源管理工具
public final class LocalMediaKit: Sendable {
    private let configuration: LocalMediaKitConfiguration
    
    /// 协调器
    private let saveCoordinator: SaveCoordinator
    private let loadCoordinator: LoadCoordinator
    
    
    /// 管理器
    private let pathManager: PathManager
    private let storageManager: StorageManager
    private let metadataManager: MetadataManager
    
    
    /// 媒体处理器
    private let imageProcessor: ImageProcessor
    private let videoProcessor: VideoProcessor
    private let livePhotoProcessor: LivePhotoProcessor


    /// 缓存
    private let imageCache: CacheManager<UIImage>?
    private let thumbnailCache: CacheManager<UIImage>?
    private let dataCache: CacheManager<Data>?
    
    
    // MARK: - 初始化
    /// 初始化方法。多个实例必须保证databasePath不一样！！！否则出现数据污染！！
    public init(configuration: LocalMediaKitConfiguration) throws {
        self.configuration = configuration
        
        /// 工具类初始化
        self.pathManager = try PathManager(configuration: configuration.path)
        self.storageManager = StorageManager()
        self.metadataManager = try MetadataManager(databasePath: configuration.databasePath)
        
        /// 处理器初始化
        self.imageProcessor = ImageProcessor()
        self.videoProcessor = VideoProcessor()
        self.livePhotoProcessor = LivePhotoProcessor(
            imageProcessor: imageProcessor,
            videoProcessor: videoProcessor,
            storageManager: storageManager
        )
        
        /// 缓存初始化
        self.imageCache = CacheManager(
            configuration: configuration.cache,
            cacheDirectory: pathManager.cacheDirectory(for: .processedImage)
        )
        self.thumbnailCache = CacheManager(
            configuration: CacheConfiguration.highMemory,
            cacheDirectory: pathManager.cacheDirectory(for: .thumbnail)
        )
        self.dataCache = CacheManager(
            configuration: CacheConfiguration.highMemory,
            cacheDirectory: pathManager.cacheDirectory(for: .thumbnail)
        )
        
        /// 协调器
        self.saveCoordinator = SaveCoordinator(
            pathManager: pathManager,
            storageManager: storageManager,
            metadataManager: metadataManager,
            imageProcessor: imageProcessor,
            videoProcessor: videoProcessor,
            livePhotoProcessor: livePhotoProcessor
        )
        
        self.loadCoordinator = LoadCoordinator(
            pathManager: pathManager,
            storageManager: storageManager,
            metadataManager: metadataManager,
            imageProcessor: imageProcessor,
            videoProcessor: videoProcessor,
            livePhotoProcessor: livePhotoProcessor,
            imageCache: imageCache,
            thumbnailCache: thumbnailCache,
            dataCache: dataCache
        )
        
        if configuration.enableDebugLog {
            debugPrint("LocalMediaKit Configured with root: \(pathManager.rootDirectory.compatPath), databasePath: \(configuration.databasePath.compatPath)")
        }
    }
    
    
    
    
    // MARK: - 加载
    
    /// 加载媒体资源
    /// - Parameters:
    ///   - id: 媒体 ID
    ///   - targetSize: 目标尺寸，nil 表示原图
    /// - Returns: 媒体资源对象
    public func load(id: MediaID, targetSize: CGSize? = nil) async throws -> MediaResource {
        let request = LoadRequest(id: id, targetSize: targetSize)
        return try await loadCoordinator.load(request)
    }
    
    /// 用 LoadRequest 加载媒体
    public func load(_ request: LoadRequest) async throws -> MediaResource {
        return try await loadCoordinator.load(request)
    }
    
    /// 加载缩略图
    public func loadThumbnail(id: MediaID, size: CGSize) async throws -> UIImage {
        return try await loadCoordinator.loadThumbnail(id: id, size: size)
    }
    
    
    
    
    // MARK: - 保存
    
    /// 保存图片Data
    /// - Parameters:
    ///   - imageData: 图片数据Data
    ///   - thumbnailSize: 缩略图尺寸，如果为 nil 就代表不需要缩略图
    ///   - userInfo: 自定义用户信息
    /// - Returns: 媒体 ID
    public func save(
        imageData: Data,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        var request: SaveRequest
        if let thumbnailSize {
            request = SaveRequest.image(imageData, userInfo: userInfo)
        } else {
            request = SaveRequest.image(imageData, userInfo: userInfo)
        }
        return try await saveCoordinator.save(request)
    }
    
    
    /// 保存UIImage
    /// - Parameters:
    ///   - image: UIImage对象
    ///   - format: 图片格式
    ///   - userInfo: 自定义用户信息
    /// - Returns: 媒体 ID
    public func save(image: UIImage, format: ImageFormat, userInfo: [String: String]? = nil) async throws -> MediaID {
        let request = SaveRequest.image(image, format: format, userInfo: userInfo)
        return try await saveCoordinator.save(request)
    }
}
