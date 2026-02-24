//
//  MediaMetadata.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/3.
//

import Foundation
import GRDB

/// 媒体元数据
public struct MediaMetadata: Codable, Sendable, Identifiable {
    // MARK: - 通用字段
    /// 媒体id，唯一标识符
    public let id: MediaID
    
    /// 媒体类型
    public let type: LocalMediaType
    
    /// 创建时间
    public let createdAt: Date
    
    /// 文件大小，单位字节
    public let fileSize: Int64
    
    
    
    
    // MARK: - 文件路径
    /// 图片的相对路径
    public let imagePath: String?
    
    /// 视频的相对路径
    public let videoPath: String?
    
    /// 缩略图的相对路径
    public let thumbnailPath: String?
    
    
    
    
    // MARK: - 图片特有字段
    /// 像素宽度
    public var pixelWidth: Int?
    /// 像素高度
    public var pixelHeight: Int?
    
    
    
    
    // MARK: - 视频特有字段
    /// 视频时长，单位秒
    public var duration: TimeInterval?
    /// 视频编码格式
    public var videoCodec: String?
    
    
    
    
    // MARK: - 实况图特有字段
    /// 实况图配对标识符
    public var assetIdentifier: String?
    
    
    
    
    // MARK: - 拓展字段
    /// 自定义用户信息，存储为JSON
    public var userInfo: [String: String]?
    
    
    
    
    // MARK: - 初始化
    public init(
        id: MediaID = MediaID(),
        type: LocalMediaType,
        createdAt: Date = Date(),
        fileSize: Int64,
        imagePath: String? = nil,
        videoPath: String? = nil,
        thumbnailPath: String? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        duration: TimeInterval? = nil,
        videoCodec: String? = nil,
        assetIdentifier: String? = nil,
        userInfo: [String : String]? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.fileSize = fileSize
        self.imagePath = imagePath
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.duration = duration
        self.videoCodec = videoCodec
        self.assetIdentifier = assetIdentifier
        self.userInfo = userInfo
    }
    
    
    /// 遵守ColumnExpression，让rawValue作为GRDB列名
    public enum CodingKeys: String, CodingKey, ColumnExpression {
        case id
        case type
        case createdAt
        case fileSize
        case imagePath
        case videoPath
        case thumbnailPath
        case pixelWidth
        case pixelHeight
        case duration
        case videoCodec
        case assetIdentifier
        case userInfo
    }
}




// MARK: - 便捷计算属性
extension MediaMetadata {
    /// 图片尺寸
    public var pixelSize: CGSize? {
        guard let width = pixelWidth, let height = pixelHeight else { return nil }
        return CGSize(width: width, height: height)
    }
    
    
    /// 格式化的文件大小字符串
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    
    /// 格式化的视频时长字符串
    public var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration)
    }
    
    
    /// 是否视频类型
    public var isVideo: Bool {
        type == .video || type == .livePhoto
    }
    
    
    /// 是否为图片类型
    public var isImage: Bool {
        type == .image || type == .animatedImage
    }
    
    /// 主路径
    public var primaryPath: String {
        switch type {
        case .image, .livePhoto, .animatedImage:
            return imagePath!
        case .video:
            return videoPath!
        }
    }
}




// MARK: - 便捷初始化
extension MediaMetadata {
    /// 创建图片元数据
    public static func image(
        id: MediaID = MediaID(),
        createdAt: Date = Date(),
        fileSize: Int64,
        imagePath: String,
        pixelWidth: Int,
        pixelHeight: Int,
        userInfo: [String : String]? = nil
    ) -> MediaMetadata {
        MediaMetadata(
            id: id,
            type: .image,
            createdAt: createdAt,
            fileSize: fileSize,
            imagePath: imagePath,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            userInfo: userInfo
        )
    }
    
    /// 构建视频元数据
    public static func video(
        id: MediaID = MediaID(),
        createdAt: Date = Date(),
        fileSize: Int64,
        videoPath: String,
        pixelWidth: Int,
        pixelHeight: Int,
        duration: TimeInterval,
        videoCodec: String? = nil,
        userInfo: [String : String]? = nil
    ) -> MediaMetadata {
        MediaMetadata(
            id: id,
            type: .video,
            createdAt: createdAt,
            fileSize: fileSize,
            videoPath: videoPath,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            duration: duration,
            videoCodec: videoCodec,
            userInfo: userInfo
        )
    }
    
    /// 构建实况图元数据
    public static func livePhoto(
        id: MediaID = MediaID(),
        createdAt: Date = Date(),
        fileSize: Int64,
        imagePath: String,
        videoPath: String,
        pixelWidth: Int,
        pixelHeight: Int,
        duration: TimeInterval,
        assetIdentifier: String,
        userInfo: [String : String]? = nil
    ) -> MediaMetadata {
        MediaMetadata(
            id: id,
            type: .livePhoto,
            createdAt: createdAt,
            fileSize: fileSize,
            imagePath: imagePath,
            videoPath: videoPath,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            duration: duration,
            assetIdentifier: assetIdentifier,
            userInfo: userInfo
        )
    }
}




// MARK: - Hashable & Equatable
extension MediaMetadata: Hashable, Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}




// MARK: - GRDB支持
extension MediaMetadata: FetchableRecord, PersistableRecord {
    /// 表名
    public static var databaseTableName: String { "media" }
}
