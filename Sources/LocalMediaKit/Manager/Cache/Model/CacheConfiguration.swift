//
//  CacheConfiguration.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/2.
//

import Foundation

// MARK: - 缓存配置
struct CacheConfiguration: Sendable {
    // MARK: - 内存缓存配置
    /// 内存缓存最大条数
    public var memoryCountLimit: Int
    
    /// 内存缓存最大字节数
    public var memoryCostLimit: Int
    
    
    
    
    // MARK: - 磁盘缓存配置
    /// 磁盘缓存最大字节数
    public var diskCostLimit: Int
    
    /// 磁盘缓存默认过期时间（秒），nil表示永不过期
    public var defaultExpiration: TimeInterval?
    
    /// 后台清理间隔（秒）
    public var cleanupInterval: TimeInterval
    
    
    
    
    // MARK: - 初始化
    public init(
        memoryCountLimit: Int = 200,                /// 内存缓存 -> 200个
        memoryCostLimit: Int = 200 * 1024 * 1024,   /// 内存缓存 -> 200MB
        diskCostLimit: Int = 300 * 1024 * 1024,     /// 磁盘缓存 -> 300MB
        defaultExpiration: TimeInterval? = nil,     /// 磁盘缓存 -> 不过期
        cleanupInterval: TimeInterval = 60 * 5      /// 清理间隔 -> 5分钟
    ) {
        self.memoryCountLimit = memoryCountLimit
        self.memoryCostLimit = memoryCostLimit
        self.diskCostLimit = diskCostLimit
        self.defaultExpiration = defaultExpiration
        self.cleanupInterval = cleanupInterval
    }
    
    /// 默认配置
    public static var `default`: CacheConfiguration {
        return CacheConfiguration()
    }
    
    /// 低性能配置，适用于内存受限的设备
    public static var lowMemory: CacheConfiguration {
        return CacheConfiguration(
            memoryCountLimit: 50,
            memoryCostLimit: 50 * 1024 * 1024,
            diskCostLimit: 200 * 1024 * 1024
        )
    }
    
    /// 高性能配置，适用于内存充足的设备
    public static var highMemory: CacheConfiguration {
        return CacheConfiguration(
            memoryCountLimit: 500,
            memoryCostLimit: 500 * 1024 * 1024,
            diskCostLimit: 500 * 1024 * 1024
        )
    }
}
