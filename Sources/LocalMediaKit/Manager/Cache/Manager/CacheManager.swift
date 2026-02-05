//
//  CacheManager.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/2.
//

import UIKit


public final class CacheManager<T: Sendable>: Sendable {
    /// 内存缓存
    private let memoryCache: MemoryCache<T>
    
    private let configuration: CacheConfiguration
    
    
    // MARK: - 初始化
    init(
        configuration: CacheConfiguration,
        cacheDirectory: URL?
    ) {
        self.configuration = configuration
        
        /// 初始化内存缓存
        self.memoryCache = MemoryCache(
            countLimit: configuration.memoryCountLimit,
            costLimit: configuration.memoryCostLimit
        )
        
        /// 监听内存警告
        setupMemoryWarningObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    
    // MARK: - 公开方法
    /// 获取缓存值
    public func get(_ key: String) async -> T? {
        /// 检查内存
        if let value = memoryCache.get(key) {
            return value
        }
        
        /// TODO：检查磁盘缓存逻辑
        
        return nil
    }
    
    
    /// 写入缓存
    public func set(_ key: String, value: T, cost: Int) async {
        memoryCache.set(key, value: value, cost: cost)
        /// TODO：写入磁盘缓存
    }
    
    
    /// 图片写入缓存，自动计算开销
    public func set(_ key: String, value: T) async where T: CacheCostCalculable {
        let cost = value.cost
        memoryCache.set(key, value: value, cost: cost)
        /// TODO：写入磁盘缓存
    }
    
    
    /// 清理指定缓存
    public func remove(_ key: String) {
        memoryCache.remove(key)
        /// TODO：清理磁盘缓存
    }
    
    
    /// 清空缓存
    public func cleanup() {
        memoryCache.cleanup()
        /// TODO：清空磁盘缓存
    }
    
    
    /// 检查缓存是否存在
    public func contains(_ key: String) -> Bool {
        if memoryCache.contains(key) {
            return true
        }
        /// TODO：检查磁盘缓存
        return false
    }
    
    
    
    
    // MARK: - 便捷属性
    /// 缓存总开销
    public var totalCost: Int {
        get async {
            let memoryCost = memoryCache.currentCost
            /// TODO：检查磁盘缓存
            return memoryCost
        }
    }
    
    /// 缓存总条目数
    public var totalCount: Int {
        get async {
            let memoryCount = memoryCache.currentCount
            /// TODO：检查磁盘缓存
            return memoryCount
        }
    }
    
    /// 内存缓存开销
    public var memoryCost: Int {
        return memoryCache.currentCost
    }
    
    
    
    
    // MARK: - 监听
    /// 监听内存警告
    private func setupMemoryWarningObserver() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cleanup()
        }
        #endif
    }
}




// MARK: - 开销计算
public protocol CacheCostCalculable {
    var cost: Int { get }
}


extension UIImage: CacheCostCalculable {
    public var cost: Int {
        if let cgImage = cgImage {
            let size = cgImage.bytesPerRow * cgImage.height
            if size > 0 { return size }
            
            /// 如果bytesPerRow为0导致size == 0，则兜底使用bitsPerPixel计算
            let bitsPerPixel = cgImage.bitsPerPixel
            let bytesPerPixel = (bitsPerPixel + 7) / 8
            return bytesPerPixel * cgImage.width * cgImage.height
        }
        
        /// 获取cgImage失败，返回估算值
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)
        return width * height * 4
    }
}

extension Data: CacheCostCalculable {
    public var cost: Int {
        return count
    }
}
