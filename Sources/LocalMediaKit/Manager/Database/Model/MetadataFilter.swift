//
//  MetadataFilter.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/4.
//

import Foundation

/// SQL查询过滤条件
public struct MetadataFilter: Sendable {
    public var types: [LocalMediaType]?
    public var createdAfter: Date?
    public var createdBefore: Date?
    public var minFileSize: Int64?
    public var maxFileSize: Int64?
    public var sortBy: SortField
    public var ascending: Bool?
    public var limit: Int?
    public var offset: Int?
    
    
    public enum SortField: String, Sendable {
        case createdAt
        case fileSize
        case type
    }
    
    
    public init(
        types: [LocalMediaType]? = nil,
        createdAfter: Date? = nil,
        createdBefore: Date? = nil,
        minFileSize: Int64? = nil,
        maxFileSize: Int64? = nil,
        sortBy: SortField = .createdAt,
        ascending: Bool? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.types = types
        self.createdAfter = createdAfter
        self.createdBefore = createdBefore
        self.minFileSize = minFileSize
        self.maxFileSize = maxFileSize
        self.sortBy = sortBy
        self.ascending = ascending
        self.limit = limit
        self.offset = offset
    }
    
    /// 默认过滤器，返回全部，按照创建时间倒序
    public static let `default` = MetadataFilter()
    
    public static let images = MetadataFilter(types: [.image])
    public static let videos = MetadataFilter(types: [.video])
    public static let livePhotos = MetadataFilter(types: [.livePhoto])
}
