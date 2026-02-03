//
//  LoadRequest.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/3.
//

import Foundation


/// 媒体加载请求
public struct LoadRequest: Sendable {
    /// 媒体标识符
    public let id : MediaID
    
    /// 目标尺寸，nil表示原图
    public var targetSize: CGSize?
    
    /// 缓存策略
    public var cachePolicy: CachePolicy
    
    
    public init(
        id: MediaID,
        targetSize: CGSize? = nil,
        cachePolicy: CachePolicy
    ) {
        self.id = id
        self.targetSize = targetSize
        self.cachePolicy = cachePolicy
    }
}




// MARK: - 便捷初始化
extension LoadRequest {
    /// 加载原图
    public static func original(id: MediaID) -> LoadRequest {
        return LoadRequest(id: id, targetSize: nil, cachePolicy: .default)
    }
    
    /// 加载缩略图
    public static func thumbnail(id: MediaID, targetSize: CGSize) -> LoadRequest {
        return LoadRequest(id: id, targetSize: targetSize, cachePolicy: .default)
    }
    
    /// 仅从缓存加载
    public static func cached(id: MediaID, targetSize: CGSize) -> LoadRequest {
        return LoadRequest(id: id, targetSize: targetSize, cachePolicy: .cacheOnly)
    }
}
