//
//  CachePolicy.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/3.
//

import Foundation

/// 缓存策略
public enum CachePolicy: Sendable {
    /// 默认策略：先内存 → 再磁盘缓存 → 再原始文件
    case `default`
    
    /// 跳过内存缓存
    case ignoreMemory
    
    /// 跳过磁盘缓存
    case ignoreDisk
    
    /// 跳过缓存，直接读取文件
    case ignoreCache
    
    /// 只查缓存，不读取原始文件
    case cacheOnly
    
    /// 是否使用内存缓存
    var useMemoryCache: Bool {
        switch self {
        case .default, .ignoreDisk, .cacheOnly:
            return true
        case .ignoreMemory, .ignoreCache:
            return false
        }
    }
    
    /// 是否使用磁盘缓存
    var useDiskCache: Bool {
        switch self {
        case .default, .ignoreMemory, .cacheOnly:
            return true
        case .ignoreDisk, .ignoreCache:
            return false
        }
    }
    
    /// 是否可以读取原始文件
    var canReadOriginalFile: Bool {
        return self != .cacheOnly
    }
}
