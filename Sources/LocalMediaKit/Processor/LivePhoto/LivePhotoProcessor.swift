//
//  LivePhotoProcessor.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import Foundation
import Photos


public final class LivePhotoProcessor: LivePhotoProcessing, Sendable {
    private let imageProcessor: ImageProcessor
    private let videoProcessor: VideoProcessor
    private let storageManager: StorageManager
    
    private let processingQueue = DispatchQueue(
        label: "com.localmediakit.livephotoprocessor",
        qos: .userInitiated
    )
    
    
    // MARK: - 初始化
    public init(
        imageProcessor: ImageProcessor = ImageProcessor(),
        videoProcessor: VideoProcessor = VideoProcessor(),
        storageManager: StorageManager = StorageManager()
    ) {
        self.imageProcessor = imageProcessor
        self.videoProcessor = videoProcessor
        self.storageManager = storageManager
    }
    
    
    
    
    // MARK: - 实况图处理
    
    /// 组装实况图
    /// - Parameters:
    ///   - imageURL: 图片URL
    ///   - videoURL: 视频URL
    /// - Returns: 实况图对象
    public func assemble(imageURL: URL, videoURL: URL, targetSize: CGSize = .zero) async throws -> PHLivePhoto {
        let state = RequestState()
        
        return try await withTaskCancellationHandler {
            // 检查任务是否被取消
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { continuation in
                let requestID = PHLivePhoto.request(
                    withResourceFileURLs: [imageURL, videoURL],
                    placeholderImage: nil,
                    targetSize: targetSize,
                    contentMode: .default
                ) { livePhoto, info in
                    /// 被取消的情况
                    if let cancelled = info[PHLivePhotoInfoCancelledKey] as? Bool, cancelled {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    
                    /// 错误检查
                    if let error = info[PHLivePhotoInfoErrorKey] as? Error {
                        continuation.resume(throwing: MediaKitError.livePhotoAssemblyFailed(underlying: error))
                        return
                    }
                    
                    /// 等待非降级版本
                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                    
                    /// 获取实况图
                    guard let livePhoto = livePhoto else {
                        continuation.resume(throwing: MediaKitError.livePhotoAssemblyFailed(underlying: nil))
                        return
                    }
                    
                    continuation.resume(returning: livePhoto)
                }
                
                state.setRequestID(requestID)
            }
        } onCancel: {
            if let id = state.getRequestID() {
                PHLivePhoto.cancelRequest(withRequestID: id)
            }
        }

        /// 线程安全的请求状态定义
        final class RequestState: @unchecked Sendable {
            private let lock = NSLock()
            private var requestID: PHLivePhotoRequestID?
            
            func setRequestID(_ id: PHLivePhotoRequestID) {
                lock.lock()
                defer { lock.unlock() }
                requestID = id
            }
            
            func getRequestID() -> PHLivePhotoRequestID? {
                lock.lock()
                defer { lock.unlock() }
                return requestID
            }
        }
    }
    
    
    /// 解析实况图，获取图片data和视频路径
    /// - Parameter livePhoto: 实况图对象
    /// - Returns: 图片Data， 视频路径
    public func disassemble(_ livePhoto: PHLivePhoto) async throws -> (imageData: Data, videoURL: URL) {
        let resources = PHAssetResource.assetResources(for: livePhoto)
        
        var imageData: Data?
        var videoURL: URL?
        
        let tempDirectory = storageManager.temporaryURL()
        try storageManager.ensureDirectoryExists(at: tempDirectory)
        
        for resource in resources {
            /// 提取图片
            if resource.type == .photo || resource.type == .fullSizePhoto {
                imageData = try await extractResourceData(resource)
            } else if resource.type == .pairedVideo || resource.type == .fullSizePairedVideo {
            /// 提取视频
                let key = CacheKey.livePhotoVideo(id: MediaID())
                let outputURL = tempDirectory.appendingPath("\(key).mov")
                try await extractResourceToFile(resource, outputURL: outputURL)
                videoURL = outputURL
            }
        }
        
        /// 检查不为nil
        guard let imageData, let videoURL else {
            throw MediaKitError.livePhotoAssemblyFailed(underlying: nil)
        }
        
        return (imageData, videoURL)
    }
    
    
    
    
    // MARK: - 解析方法
    
    /// 从媒体资源中提取二进制数据Data
    /// - Parameter resource: 图片、视频、实况图的资源对象
    /// - Returns: Data二进制数据
    public func extractResourceData(_ resource: PHAssetResource) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            /// 创建空的数据容器，用来累积接收到的数据块
            var data = Data()
            /// 创建请求选项
            let options = PHAssetResourceRequestOptions()
            /// 配置允许从iCloud下载。如果为false则无法下载iCloud数据
            options.isNetworkAccessAllowed = true
            /// 请求资源数据
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options
            ) { chunk in        /// 数据回调闭包。每次都写入data容器
                data.append(chunk)
            } completionHandler: { error in     /// 完成回调
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }
    
    
    /// 提取媒体资源写入文件路径
    /// - Parameters:
    ///   - resource: 媒体资源对象
    ///   - outputURL: 写入路径
    public func extractResourceToFile(_ resource: PHAssetResource, outputURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: outputURL,
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
}
