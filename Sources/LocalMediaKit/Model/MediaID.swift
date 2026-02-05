//
//  MediaID.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/1/24.
//

import Foundation
import GRDB

/// 媒体项的ID，作为模块通信的唯一标识符
public struct MediaID: Hashable, Sendable, Codable {
    public let raw: String
    
    /// 默认初始化为UUIDString
    public init() {
        self.raw = UUID().uuidString
    }
    
    public init(raw: String) {
        self.raw = raw
    }
}




// MARK: - GRDB支持
extension MediaID: DatabaseValueConvertible {
    /// 转换成数据库可存储的格式
    public var databaseValue: DatabaseValue {
        raw.databaseValue
    }
    
    /// 从数据库格式转换成原始格式
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> MediaID? {
        guard let raw = String.fromDatabaseValue(dbValue) else { return nil }
        return MediaID(raw: raw)
    }
}




// MARK: - 拓展
/// CustomStringConvertible定义String(describing: {MediaID})打印的内容
/// CustomDebugStringConvertible定义 debugPrint({MediaID}) 和 String(reflecting: {MediaID}) 的内容
/// 如果不实现CustomDebugStringConvertible协议，调试时 MediaID 实例可能只会显示默认的内存地址或类名，比如 MediaID
extension MediaID: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return raw
    }
    
    public var debugDescription: String {
        return "MediaID: \(raw)"
    }
}
