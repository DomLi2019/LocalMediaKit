//
//  SaveCoordinator.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import UIKit
import Photos

/// 保存协调器
public final class SaveCoordinator: Sendable {
    // MARK: - 依赖
    private let pathManager: any PathManaging
    private let storageManager: any StorageManaging
    private let metadataManager: any MetadataManaging
    private let imageProcessor: any ImageProcessing
    private let videoProcessor: any VideoProcessing
    private let livePhotoProcessor: any LivePhotoProcessing

    private let queue = DispatchQueue(
        label: "com.localmediakit.savecoordinator",
        qos: .userInitiated
    )




    // MARK: - 初始化
    init(
        pathManager: any PathManaging,
        storageManager: any StorageManaging = StorageManager(),
        metadataManager: any MetadataManaging,
        imageProcessor: any ImageProcessing = ImageProcessor(),
        videoProcessor: any VideoProcessing = VideoProcessor(),
        livePhotoProcessor: any LivePhotoProcessing = LivePhotoProcessor()
    ) {
        self.pathManager = pathManager
        self.storageManager = storageManager
        self.metadataManager = metadataManager
        self.imageProcessor = imageProcessor
        self.videoProcessor = videoProcessor
        self.livePhotoProcessor = livePhotoProcessor
    }
    
    
    
    
    // MARK: - 对外方法
    
    public func save(_ request: SaveRequest) async throws -> MediaID {
        switch request.type {
        case .image, .animatedImage:
            return try await saveImage(request)
        case .livePhoto:
            return try await saveLivePhoto(request)
        case .video:
            return try await saveVideo(request)
        }
    }
    
    
    
    
    // MARK: - 图片
    /// 保存图片
    public func saveImage(_ request: SaveRequest) async throws -> MediaID {
        /// 生成ID
        let id = MediaID()
        /// 编码图片，获取拓展名
        let (imageData, ext) = try await prepareImageData(request)
        /// 生成路径
        let imageURL = pathManager.generatePath(for: id, type: request.type, ext: ext).primaryImageURL!
        /// 检查磁盘空间 + 写入文件
        try await storageManager.write(imageData, to: imageURL)
        
        /// 存储缩略图
        var thumbnailRelativePath: String? = nil
        if request.generateThumbnail {
            thumbnailRelativePath = await generateAndSaveThumbnail(
                id: id,
                source: .data(imageData),
                size: request.thumbnailSize
            )
        }
        
        /// 构建图片元数据
        let metadata = try await createMetadata(
            id: id,
            type: request.type,
            imageData: imageData,
            mediaURL: .image(imageURL),
            thumbnailPath: thumbnailRelativePath,
            userInfo: request.userInfo
        )
        
        /// 写入数据库
        do {
            try await metadataManager.save(metadata)
        } catch {
            try? await storageManager.delete(at: imageURL)
            throw error
        }
        
        return id
    }
    
    
    /// URL 保存图片
    public func saveImage(
        at url: URL,
        thumbnailSize: CGSize? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaID {
        /// 生成ID
        let id = MediaID()
        
        /// 获取拓展名
        let ext = storageManager.extractExtension(url: url)
        
        /// 生成路径
        let imageURL = pathManager.generatePath(for: id, type: .image, ext: ext).primaryImageURL!
        
        /// 检查磁盘空间 + 拷贝文件
        try await storageManager.copy(at: url, to: imageURL)
        
        /// 保存缩略图
        var thumbnailRelativePath: String? = nil
        if let thumbnailSize {
            thumbnailRelativePath = await generateAndSaveThumbnail(
                id: id,
                source: .url(url),
                size: thumbnailSize
            )
        }
        
        /// 构建图片元数据
        let metadata = try await createMetadata(
            id: id,
            type: .image,
            imageData: nil,
            mediaURL: .image(imageURL),
            thumbnailPath: thumbnailRelativePath,
            userInfo: userInfo
        )
        
        /// 写入数据库
        do {
            try await metadataManager.save(metadata)
        } catch {
            try? await storageManager.delete(at: imageURL)
            throw error
        }
        
        return id
    }
    
    
    /// PHAsset 保存图片
    public func saveImage(from asset: PHAsset, thumbnailSize: CGSize? = nil, userInfo: [String: String]? = nil) async throws -> MediaID {
        /// 生成ID
        let id = MediaID()
        
        let resource = PHAssetResource.assetResources(for: asset)
        let editedResource = resource.first(where: { $0.type == .fullSizePhoto }) ?? resource.first(where: { $0.type == .photo })
        guard let imageResource = editedResource else {
            throw MediaKitError.invalidMediaData(reason: "PHAssetResource doesn't exist.")
        }
        
        /// 获取拓展名
        let ext = (imageResource.originalFilename as NSString).pathExtension.lowercased()
        
        /// 生成路径
        let imageURL = pathManager.generatePath(for: id, type: .image, ext: ext).primaryImageURL!
        
        /// 确保路径存在
        try storageManager.ensureParentDirectoryExists(at: imageURL)
        
        /// 写入文件
        try await writeAssetResource(imageResource, to: imageURL)
        
        /// 重新读取图片数据
        let imageData = try await storageManager.read(from: imageURL)
                
        /// 保存缩略图
        var thumbnailRelativePath: String? = nil
        if let thumbnailSize {
            thumbnailRelativePath = await generateAndSaveThumbnail(
                id: id,
                source: .data(imageData),
                size: thumbnailSize
            )
        }
        
        /// 构建图片元数据
        let metadata = try await createMetadata(
            id: id,
            type: .image,
            imageData: imageData,
            mediaURL: .image(imageURL),
            thumbnailPath: thumbnailRelativePath,
            userInfo: userInfo
        )
        
        /// 写入数据库
        do {
            try await metadataManager.save(metadata)
        } catch {
            try? await storageManager.delete(at: imageURL)
            throw error
        }
        
        return id
    }
    
    /// 桥接 PHAssetResourceManager 接口 writeData
    private func writeAssetResource(_ resource: PHAssetResource, to url: URL) async throws {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        
        return try await withCheckedThrowingContinuation { continuation in
            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: url,
                options: options
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    
    /// 获取图片Data和拓展名
    private func prepareImageData(_ request: SaveRequest) async throws -> (Data, String) {
        switch request.data {
        case .imageData(let data):
            /// 检测格式
            let format = imageProcessor.detectFormat(from: data)
            let ext = format?.fileExtension ?? "dat"
            return (data, ext)
            
        case .image(let image, let format):
            /// 编码图片
            let data = try await imageProcessor.encode(image, format: format)
            return (data, format.fileExtension)
            
        default:
            throw MediaKitError.invalidMediaData(reason: "Invalid data for image type")
        }
    }
    
    
    /// 生成缩略图并转为Data写入磁盘
    /// - Parameters:
    ///   - id: 媒体ID
    ///   - source: 图片资源
    ///   - size: 缩略图目标尺寸
    /// - Returns: 缩略图的相对路径
    public func generateAndSaveThumbnail(
        id: MediaID,
        source: ImageSource,
        size: CGSize
    ) async -> String? {
        do {
            let thumbnail = try await imageProcessor.thumbnail(at: source, targetSize: size)
            let thumbPath = pathManager.thumbnailPath(for: id, size: size)
            
            /// 转为Data并写入
            if let thumbnailData = thumbnail.jpegData(compressionQuality: 1.0) {
                try await storageManager.write(thumbnailData, to: thumbPath)
            }
            
            return pathManager.relativePath(for: thumbPath)
        } catch {
            debugPrint("saveImage Thumbnail generation failed: \(error)")
            return nil
        }
    }
    
    
    
    
    // MARK: - 实况图
    /// 保存实况图
    public func saveLivePhoto(_ request: SaveRequest) async throws -> MediaID {
        guard case .livePhoto(let imageData, let videoURL) = request.data else {
            throw MediaKitError.invalidMediaData(reason: "Invalid data for live photo type")
        }
        
        /// 生成媒体ID
        let id = MediaID()
        
        /// 获取写入文件路径
        let urls = pathManager.generatePath(for: id, type: .livePhoto)
        let imageTargeteURL = urls.primaryImageURL!
        let videoTargetURL = urls.primaryVideoURL!
        
        /// 写入/拷贝到目标路径
        do {
            try await storageManager.write(imageData, to: imageTargeteURL)
            try await storageManager.copy(at: videoURL, to: videoTargetURL)
        } catch {
            throw MediaKitError.livePhotoAssemblyFailed(underlying: error)
        }
        
        /// 保存缩略图
        var thumbnailRelativePath: String? = nil
        if request.generateThumbnail {
            thumbnailRelativePath = await generateAndSaveThumbnail(
                id: id,
                source: .data(imageData),
                size: request.thumbnailSize
            )
        }
        
        /// 创建元数据
        let metadata = try await createMetadata(
            id: id,
            type: .livePhoto,
            imageData: imageData,
            mediaURL: .livePhoto(imageURL: imageTargeteURL, videoURL: videoTargetURL),
            thumbnailPath: thumbnailRelativePath,
            userInfo: request.userInfo
        )
        
        /// 写入数据库
        do {
            try await metadataManager.save(metadata)
        } catch {
        /// 失败回滚，删除已写入的文件
            try? await storageManager.delete(at: imageTargeteURL)
            try? await storageManager.delete(at: videoTargetURL)
            throw error
        }
        
        return id
    }
    
    
    
    
    // MARK: - 视频
    /// 保存视频
    public func saveVideo(_ request: SaveRequest) async throws -> MediaID {
        guard case .videoURL(let sourceURL) = request.data else {
            throw MediaKitError.invalidMediaData(reason: "Invalid data for video type")
        }
        
        guard await videoProcessor.isValid(at: sourceURL) else {
            throw MediaKitError.invalidVideo(reason: "Video file is not valid or playable")
        }
        
        let id = MediaID()
        
        let ext = sourceURL.pathExtension.lowercased().isEmpty ? "mp4" : sourceURL.pathExtension.lowercased()
        
        let urls = pathManager.generatePath(for: id, type: .video, ext: ext)
        let videoTargetURL = urls.primaryVideoURL!
        let thumbnailTargetURL = urls.primaryImageURL!   /// 缩略图存储路径
        
        do {
            try await storageManager.copy(at: sourceURL, to: videoTargetURL)
        } catch {
            throw error
        }
        
        var thumbnailRelativePath: String? = nil
        if request.generateThumbnail {
            if let thumbnail = try? await videoProcessor.extractThumbnail(from: sourceURL),
               let jpgData = thumbnail.jpegData(compressionQuality: 1.0) {
                
                try? await storageManager.write(jpgData, to: thumbnailTargetURL)
                thumbnailRelativePath = pathManager.relativePath(for: thumbnailTargetURL)
            }
        }
        
        let metadata = try await createMetadata(
            id: id,
            type: .video,
            mediaURL: urls,
            thumbnailPath: thumbnailRelativePath,
            userInfo: request.userInfo
        )
        
        do {
            try await metadataManager.save(metadata)
        } catch  {
            try? await storageManager.delete(at: videoTargetURL)
            try? await storageManager.delete(at: thumbnailTargetURL)
            throw error
        }
        
        return id
    }
    
    
    
    
    // MARK: - 元数据
    /// 构建元数据
    /// - Parameters:
    ///   - id: 媒体ID
    ///   - type: 媒体类型
    ///   - data: 媒体二进制数据
    ///   - targetURL: 媒体目标存储路径
    ///   - userInfo: 用户自定义信息
    /// - Returns: 媒体元数据
    private func createMetadata(
        id: MediaID,
        type: MediaType,
        imageData: Data? = nil,
        mediaURL: MediaURL,
        thumbnailPath: String? = nil,
        assetIdentifier: String? = nil,
        userInfo: [String: String]? = nil
    ) async throws -> MediaMetadata {
        switch type {
        case .image, .animatedImage:
            let imageURL = mediaURL.primaryImageURL!
            let size = imageData != nil ? try? imageProcessor.imageSize(from: imageData!) : try? imageProcessor.imageSize(at: imageURL)
            let fileSize = (imageData != nil ? Int64(imageData!.count) : try? storageManager.fileSize(at: imageURL))  ?? 0
            
            return MediaMetadata(
                id: id,
                type: type,
                fileSize: fileSize,
                imagePath: pathManager.relativePath(for: imageURL),
                thumbnailPath: thumbnailPath,
                pixelWidth: size != nil ? Int(size!.width) : nil,
                pixelHeight: size != nil ? Int(size!.height) : nil,
                userInfo: userInfo
            )
            
        case .livePhoto:
            let imageURL = mediaURL.primaryImageURL!
            let videoURL = mediaURL.primaryVideoURL!
            
            let imageSize = try? imageProcessor.imageSize(from: imageData!)
            let videoInfo = try? await videoProcessor.videoInfo(of: videoURL)
            
            let imageFileSize = (try? storageManager.fileSize(at: imageURL)) ?? 0
            let videoFileSize = (try? storageManager.fileSize(at: videoURL)) ?? 0
            let totalSize = imageFileSize + videoFileSize
            
            return MediaMetadata(
                id: id,
                type: type,
                fileSize: totalSize,
                imagePath: pathManager.relativePath(for: imageURL),
                videoPath: pathManager.relativePath(for: videoURL),
                thumbnailPath: thumbnailPath,
                pixelWidth: imageSize != nil ? Int(imageSize!.width) : nil,
                pixelHeight: imageSize != nil ? Int(imageSize!.height) : nil,
                duration: videoInfo?.duration,
                videoCodec: videoInfo?.codec,
                assetIdentifier: assetIdentifier,
                userInfo: userInfo
            )
        case .video:
            let videoURL = mediaURL.primaryVideoURL!
            let info = try? await videoProcessor.videoInfo(of: videoURL)
            let fileSize = (try? storageManager.fileSize(at: videoURL)) ?? 0
            
            return MediaMetadata(
                id: id,
                type: type,
                fileSize: fileSize,
                videoPath: pathManager.relativePath(for: videoURL),
                thumbnailPath: thumbnailPath,
                pixelWidth: info != nil ? Int(info!.dimensions.width) : nil,
                pixelHeight: info != nil ? Int(info!.dimensions.height) : nil,
                duration: info?.duration,
                videoCodec: info?.codec,
                userInfo: userInfo
            )
        }
    }
}

