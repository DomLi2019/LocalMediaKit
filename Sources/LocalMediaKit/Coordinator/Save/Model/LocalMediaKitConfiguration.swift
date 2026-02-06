//
//  LocalMediaKitConfiguration.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import Foundation
import CoreGraphics


/// LocalMediaKit 配置
public struct LocalMediaKitConfiguration: Sendable {
    /// 路径配置
    public var path: PathConfiguration
    
    /// 缓存配置
    public var cache: CacheConfiguration
    
    /// 是否自动生成缩略图
    public var autoGenerateThumbnail: Bool
    
    /// 默认缩略图尺寸
    public var defaultThumbnailSize: CGSize
    
    /// 数据库路径
    public var databasePath: URL
    
    /// 是否启用调试日志
    public var enableDebugLog: Bool
    
    /// 初始化
    public init(
        path: PathConfiguration = .default,
        cache: CacheConfiguration = .default,
        autoGenerateThumbnail: Bool = true,
        defaultThumbnailSize: CGSize = CGSize(width: 200, height: 200),
        databasePath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPath("LocalMediaKit")
            .appendingPath("metadata.sqlite"),
        enableDebugLog: Bool = false
    ) {
        self.path = path
        self.cache = cache
        self.autoGenerateThumbnail = autoGenerateThumbnail
        self.defaultThumbnailSize = defaultThumbnailSize
        self.databasePath = databasePath
        self.enableDebugLog = enableDebugLog
    }
    
    
    public static var `default`: LocalMediaKitConfiguration {
        return LocalMediaKitConfiguration()
    }
}
