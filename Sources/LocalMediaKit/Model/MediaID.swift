//
//  MediaID.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/1/24.
//

import Foundation

/// 媒体项的ID，作为模块通信的唯一标识符
public struct MediaID: Hashable, Sendable, Codable {
    public let id: String
    
    /// 默认初始化为UUIDString
    public init() {
        self.id = UUID().uuidString.lowercased()
    }
}




// MARK: - 拓展
/// CustomStringConvertible定义String(describing: {MediaID})打印的内容
/// CustomDebugStringConvertible定义 debugPrint({MediaID}) 和 String(reflecting: {MediaID}) 的内容
/// 如果不实现CustomDebugStringConvertible协议，调试时 MediaID 实例可能只会显示默认的内存地址或类名，比如 MediaID
extension MediaID: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return id
    }
    
    public var debugDescription: String {
        return "MediaID: \(id)"
    }
}
