//
//  StorageStatistics.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/4.
//

import Foundation

/// 数据库的数据统计结果
public struct StorageStatistics: Sendable {
    public let totalCount: Int
    public let totalSize: Int64
    public let countByType: [LocalMediaType: Int]
    public let sizeByType: [LocalMediaType: Int64]
    
    
    /// 格式化的总大小
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    /// 格式化指定类型的大小
    public func formattedSize(for type: LocalMediaType) -> String {
        ByteCountFormatter.string(fromByteCount: sizeByType[type] ?? 0, countStyle: .file)
    }
}
