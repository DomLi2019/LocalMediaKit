//
//  ImageProcessor.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/1/30.
//


import Foundation

/// LocalMediaKit 错误类型
public enum MediaKitError: Error, Sendable {
    
    // MARK: - 配置错误
    
    /// 无效的根目录
    case invalidRootDirectory(URL)
    
    /// 模块未配置
    case notConfigured
    
    // MARK: - 保存错误
    
    /// 磁盘空间不足
    case insufficientDiskSpace(required: Int64, available: Int64)
    
    /// 图片编码失败
    case imageEncodingFailed(underlying: Error?)
    
    /// 文件写入失败
    case writeFailed(underlying: Error)
    
    /// 无效的媒体数据
    case invalidMediaData(reason: String)
    
    /// 实况图组装失败
    case livePhotoAssemblyFailed(underlying: Error?)
    
    /// 视频无效
    case invalidVideo(reason: String)
    
    // MARK: - 加载错误
    
    /// 媒体未找到
    case mediaNotFound(MediaID)
    
    /// 文件损坏
    case fileCorrupted(path: String)
    
    /// 解码失败
    case decodingFailed(underlying: Error?)
    
    /// 缓存未命中（仅在 cacheOnly 策略下）
    case cacheMiss(MediaID)
    
    /// 不支持的媒体格式
    case unsupportedFormat(String)
    
    // MARK: - 删除错误
    
    /// 删除失败
    case deleteFailed(underlying: Error)
    
    // MARK: - 元数据错误
    
    /// 数据库错误
    case databaseError(underlying: Error)
    
    /// 无效的元数据
    case invalidMetadata(reason: String)
    
    // MARK: - 导出错误
    
    /// 导出失败
    case exportFailed(underlying: Error)
    
    /// 无相册访问权限
    case photoLibraryAccessDenied
    
    // MARK: - 其他错误
    
    /// 操作被取消
    case cancelled
    
    /// 未知错误
    case unknown(underlying: Error)
}

// MARK: - LocalizedError

extension MediaKitError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidRootDirectory(let url):
            return "Invalid root directory: \(url.path)"
        case .notConfigured:
            return "LocalMediaKit is not configured. Call configure() first."
            
        case .insufficientDiskSpace(let required, let available):
            return "Insufficient disk space. Required: \(formatBytes(required)), Available: \(formatBytes(available))"
        case .imageEncodingFailed(let error):
            return "Failed to encode image: \(error?.localizedDescription ?? "Unknown error")"
        case .writeFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .invalidMediaData(let reason):
            return "Invalid media data: \(reason)"
        case .livePhotoAssemblyFailed(let error):
            return "Failed to assemble Live Photo: \(error?.localizedDescription ?? "Unknown error")"
        case .invalidVideo(let reason):
            return "Invalid video: \(reason)"
            
        case .mediaNotFound(let id):
            return "Media not found: \(id)"
        case .fileCorrupted(let path):
            return "File corrupted: \(path)"
        case .decodingFailed(let error):
            return "Failed to decode media: \(error?.localizedDescription ?? "Unknown error")"
        case .cacheMiss(let id):
            return "Cache miss for media: \(id)"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
            
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
            
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .invalidMetadata(let reason):
            return "Invalid metadata: \(reason)"
            
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .photoLibraryAccessDenied:
            return "Photo library access denied"
            
        case .cancelled:
            return "Operation cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Equatable

extension MediaKitError: Equatable {
    public static func == (lhs: MediaKitError, rhs: MediaKitError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidRootDirectory(let l), .invalidRootDirectory(let r)):
            return l == r
        case (.notConfigured, .notConfigured):
            return true
        case (.insufficientDiskSpace(let l1, let l2), .insufficientDiskSpace(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.mediaNotFound(let l), .mediaNotFound(let r)):
            return l == r
        case (.cacheMiss(let l), .cacheMiss(let r)):
            return l == r
        case (.unsupportedFormat(let l), .unsupportedFormat(let r)):
            return l == r
        case (.fileCorrupted(let l), .fileCorrupted(let r)):
            return l == r
        case (.invalidMediaData(let l), .invalidMediaData(let r)):
            return l == r
        case (.invalidVideo(let l), .invalidVideo(let r)):
            return l == r
        case (.invalidMetadata(let l), .invalidMetadata(let r)):
            return l == r
        case (.photoLibraryAccessDenied, .photoLibraryAccessDenied):
            return true
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}
