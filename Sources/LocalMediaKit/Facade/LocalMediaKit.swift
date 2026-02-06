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
    
    
    
    
    // MARK: - 加载API
    
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
    
    
    
    
    // MARK: - 保存API
    
    /// 用SaveRequest保存
    /// - Parameter request: 保存请求
    /// - Returns: 媒体 ID
    public func save(_ request: SaveRequest) async throws -> MediaID {
        return try await saveCoordinator.save(request)
    }
    
    
    
    
    // MARK: - 保存图片
    
    /// 保存图片Data
    /// - Parameters:
    ///   - imageData: 图片数据Data
    ///   - thumbnailSize: 缩略图尺寸，如果为 nil 就代表不需要缩略图
    ///   - userInfo: 自定义用户信息
    /// - Returns: 媒体 ID
    public func saveImage(
        imageData: Data,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        let request = SaveRequest.image(imageData, thumbnailSize: thumbnailSize, userInfo: userInfo)
        return try await saveCoordinator.save(request)
    }
    
    
    /// 保存图片UIImage
    /// - Parameters:
    ///   - image: UIImage对象
    ///   - format: 图片格式
    ///   - userInfo: 自定义用户信息
    /// - Returns: 媒体 ID
    public func saveImage(
        image: UIImage,
        format: ImageFormat,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        let request = SaveRequest.image(image, format: format, thumbnailSize: thumbnailSize, userInfo: userInfo)
        return try await saveCoordinator.save(request)
    }
    
    
    
    
    // MARK: - 保存实况图
    
    /// 保存实况图
    /// - Parameters:
    ///   - image: 实况图
    ///   - format: 图片格式
    ///   - userInfo: 自定义用户信息
    /// - Returns: 媒体 ID
    public func saveLivePhoto(
        imageData: Data,
        videoURL: URL,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        let request = SaveRequest.livePhoto(imageData: imageData, videoURL: videoURL, thumbnailSize: thumbnailSize, userInfo: userInfo)
        return try await saveCoordinator.save(request)
    }
    
    
    /// 保存实况图
    /// - Parameter livePhoto: 实况图对象PHLivePhoto
    /// - Returns: 媒体 ID
    public func saveLivePhoto(
        livePhoto: PHLivePhoto,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        let (imageData, videoURL) = try await livePhotoProcessor.disassemble(livePhoto)
        return try await saveLivePhoto(imageData: imageData, videoURL: videoURL, thumbnailSize: thumbnailSize, userInfo: userInfo)
    }
    
    
    
    
    // MARK: - 保存视频
    
    /// 保存视频
    /// - Parameters:
    ///   - url: 视频路径
    ///   - thumbnailSize: 缩略图尺寸
    ///   - userInfo: 自定义用户信息
    /// - Returns: 媒体 ID
    public func saveVideo(
        at url: URL,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        let request = SaveRequest.video(at: url, thumbnailSize: thumbnailSize, userInfo: userInfo)
        return try await saveCoordinator.save(request)
    }
    
    
    
    
    // MARK: - 删除 API
    /// 删除媒体
    public func delete(id: MediaID) async throws {
        /// 获取元数据
        guard let metadata = try await metadataManager.get(id: id) else {
            throw MediaKitError.mediaNotFound(id)
        }
        
        /// 删除图片
        if let imagePath = metadata.imagePath {
            let imageURL = pathManager.fullPath(for: imagePath)
            try await storageManager.delete(at: imageURL)
        }
        
        /// 删除视频。实况图同时有图片、视频。
        if let videoPath = metadata.videoPath {
            let videoURL = pathManager.fullPath(for: videoPath)
            try await storageManager.delete(at: videoURL)
        }
        
        /// 删除缩略图
        if let thumbnailPath = metadata.thumbnailPath {
            let thumbnailURL = pathManager.fullPath(for: thumbnailPath)
            try await storageManager.delete(at: thumbnailURL)
        }
        
        /// 删除元数据
        try await metadataManager.delete(id: id)
        
        /// 清理缓存。其实只有图片、视频在load的时候会缓存UIImage
        var cacheKey: String
        switch metadata.type {
        case .image:
            cacheKey = CacheKey.image(id: id)
        case .livePhoto:
            cacheKey = "LivePhoto is never cached."
        case .video:
            cacheKey = CacheKey.videoThumbnail(id: id)
        case .animatedImage:
            cacheKey = CacheKey.gif(id: id)
        }
        
        imageCache?.remove(cacheKey)
    }
    
    
    
    
    // MARK: - 缓存
    /// 清理内存缓存
    public func cleanupMemoryCache() async {
        imageCache?.cleanup()
        thumbnailCache?.cleanup()
        dataCache?.cleanup()
    }
}




// MARK: - 导出方法
extension LocalMediaKit {
    /// 导出媒体到相册
    /// 这里必须保证plist有相册权限申请说明，否则会直接崩溃
    /// - Parameter id: 媒体 ID
    public func exportToPhotoLibrary(id: MediaID) async throws {
        /// 检查相册权限
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw MediaKitError.photoLibraryAccessDenied
        }
        
        /// 获取元数据
        guard let metadata = try await metadataManager.get(id: id) else {
            throw MediaKitError.mediaNotFound(id)
        }
        
        /// 主文件
        let primaryFileURL = pathManager.fullPath(for: metadata.primaryPath)
        
        try await PHPhotoLibrary.shared().performChanges {
            switch metadata.type {
            case .image, .animatedImage:
                PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: primaryFileURL)
            case .video:
                PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: primaryFileURL)
            case .livePhoto:
                /// 获取视频相对路径
                guard let videoPath = metadata.videoPath else { return }
                let videoURL = self.pathManager.fullPath(for: videoPath)
                
                /// 写入相册
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: primaryFileURL, options: nil)
                request.addResource(with: .pairedVideo, fileURL: videoURL, options: nil)
            }
        }
    }
    
    
    /// 导出媒体到目标路径
    /// - Parameters:
    ///   - id: 媒体 ID
    ///   - destination: 目标路径
    public func export(id: MediaID, to destination: URL) async throws {
        /// 获取元数据
        guard let metadata = try await metadataManager.get(id: id) else {
            throw MediaKitError.mediaNotFound(id)
        }
        
        /// 主文件
        let primaryFileURL = pathManager.fullPath(for: metadata.primaryPath)
        
        /// 计算文件目录和主文件目标路径
        let targerDirectory: URL
        let primaryTargerURL: URL
        
        /// 检查路径是目录还是文件名级别
        if storageManager.isDirectory(at: destination) {
            targerDirectory = destination
            primaryTargerURL = destination.appendingPath(primaryFileURL.lastPathComponent)
        } else {
            targerDirectory = destination.deletingLastPathComponent()
            primaryTargerURL = destination
        }
        
        /// 确保目录存在
        try storageManager.ensureDirectoryExists(at: targerDirectory)
            
        /// 把主文件写入目标路径
        try await storageManager.copy(at: primaryFileURL, to: primaryTargerURL)
            
        /// 实况图还需要导出视频
        if metadata.type == .livePhoto, let videoPath = metadata.videoPath {
            let videoURL = pathManager.fullPath(for: videoPath)
            let videoTargetURL = destination.appendingPath(videoURL.lastPathComponent)
            try await storageManager.copy(at: videoURL, to: videoTargetURL)
        }
    }
}




// MARK: - 工具方法
extension LocalMediaKit {
    /// 获取媒体主文件URL
    public func fileURL(for id: MediaID) async throws -> URL {
        return try await loadCoordinator.fileURL(for: id)
    }
    
    /// 获取磁盘可用空间
    public var volumnAvailableCapacity: Int64 {
        return storageManager.availableDiskSpace()
    }
    
    
    /// 清理数据库无效空间
    public func vacumm() async throws {
        try await metadataManager.vacuum()
    }
    
    
    
    
    // MARK: - 数据库方法
    /// 检查媒体是否存在
    public func exists(id: MediaID) async throws -> Bool {
        return try await metadataManager.exists(id: id)
    }
    
    
    /// 更新媒体的userInfo
    /// - Parameters:
    ///   - id: 媒体 ID
    ///   - userInfo: 用户自定义信息
    ///   - merge: 合并信息还是覆盖信息
    public func updateUserInfo(for id: MediaID, userInfo: [String: String], merge: Bool = true) async throws  {
        let updates = MetadataUpdates(userInfo: userInfo, mergeUserInfo: merge)
        try await metadataManager.update(id: id, updates: updates)
    }
    
    
    
    
    // MARK: - 预加载
    
    /// 预加载缩略图
    /// - Parameters:
    ///   - ids: 媒体 ID 数组
    ///   - size: 缩略图尺寸
    public func preloadThumbnail(ids: [MediaID], size: CGSize? = nil) async {
        let thumbnailSize = size ?? configuration.defaultThumbnailSize
        await loadCoordinator.preloadThumbnail(ids: ids, size: thumbnailSize)
    }
}
