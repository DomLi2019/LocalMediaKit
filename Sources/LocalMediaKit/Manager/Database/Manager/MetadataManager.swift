//
//  MetadataManager.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/3.
//

import Foundation
import GRDB

public final class MetadataManager: MetadataManaging, Sendable {
    /// 数据库队列
    private let dbQueue: DatabaseQueue
    
    
    // MARK: - 初始化
    public init(databasePath: URL) throws {
        /// 确保父目录存在
        let fileManager = FileManager.default
        let parentDirectory = databasePath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDirectory.compatPath) {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        }
        
        
        var config = Configuration()
        #if DEBUG
//        config.prepareDatabase { db in
//            db.trace {
//                print("SQL: \($0)")     /// 打印所有执行的SQL
//            }
//        }
        #endif
        
        self.dbQueue = try DatabaseQueue(path: databasePath.compatPath, configuration: config)
        
        /// 执行迁移
        try migrator.migrate(dbQueue)
    }
    
    
    
    
    // MARK: - 数据库迁移
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        typealias MC = MediaMetadata.CodingKeys
        
        /// v1: 初始化表结构
        migrator.registerMigration("v1") { db in
            try db.create(table: MediaMetadata.databaseTableName) { t in
                t.column(MC.id.rawValue, .text).primaryKey()
                t.column(MC.type.rawValue, .integer).notNull()
                t.column(MC.createdAt.rawValue, .datetime).notNull()
                t.column(MC.fileSize.rawValue, .integer).notNull()
                t.column(MC.imagePath.rawValue, .text)
                t.column(MC.videoPath.rawValue, .text)
                t.column(MC.thumbnailPath.rawValue, .text)
                t.column(MC.pixelWidth.rawValue, .integer)
                t.column(MC.pixelHeight.rawValue, .integer)
                t.column(MC.duration.rawValue, .double)
                t.column(MC.videoCodec.rawValue, .text)
                t.column(MC.assetIdentifier.rawValue, .text)
                t.column(MC.userInfo.rawValue, .text)
            }
            
            /// 创建索引
            try db.create(index: "idx_media_type", on: MediaMetadata.databaseTableName, columns: [MC.type.rawValue])
            try db.create(index: "idx_media_createdAt", on: MediaMetadata.databaseTableName, columns: [MC.createdAt.rawValue])
            try db.create(index: "idx_media_fileSize", on: MediaMetadata.databaseTableName, columns: [MC.fileSize.rawValue])
        }
        
        // v2: 未来的迁移示例
        // migrator.registerMigration("v2") { db in
        //     try db.alter(table: "media") { t in
        //         t.add(column: "newColumn", .text)
        //     }
        // }
        
        return migrator
    }
    
    
    
    
    // MARK: - 数据库CRUD方法
    
    /// 写入保存
    /// - Parameter metadata: 媒体元数据
    public func save(_ metadata: MediaMetadata) async throws {
        do {
            try await dbQueue.write { db in
                try metadata.save(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 查询媒体id对应的媒体数据
    /// - Parameter id: 媒体id
    /// - Returns: 媒体元数据
    public func get(id: MediaID) async throws -> MediaMetadata? {
        do {
            return try await dbQueue.read { db in
                try MediaMetadata.fetchOne(db, key: id.raw)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 同步查询媒体id对应的媒体数据
    /// - Parameter id: 媒体id
    /// - Returns: 媒体元数据
    public func get(id: MediaID) throws -> MediaMetadata? {
        do {
            return try dbQueue.read { db in
                try MediaMetadata.fetchOne(db, key: id.raw)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 更新userInfo
    /// - Parameters:
    ///   - id: 媒体id
    ///   - updates: 更新内容和是否合并选项
    public func update(id: MediaID, updates: MetadataUpdates) async throws {
        do {
            try await dbQueue.write { db in
                guard var metadata = try MediaMetadata.fetchOne(db, key: id.raw) else {
                    throw MediaKitError.mediaNotFound(id)
                }
                
                if updates.mergeUserInfo {
                    var merged = metadata.userInfo ?? [:]
                    merged.merge(updates.userInfo) { _, new in new }    /// 合并字典，键-值冲突时，使用新的值
                    metadata.userInfo = merged
                } else {
                    metadata.userInfo = updates.userInfo
                }
                
                try metadata.update(db)
            }
        } catch let error as MediaKitError {
            throw error
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 删除媒体
    public func delete(id: MediaID) async throws {
        do {
            try await dbQueue.write { db in
                _ = try MediaMetadata.deleteOne(db, key: id.raw)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    
    
    // MARK: - 批量操作
    /// 批量保存。可以保证都成功或者都失败，减少磁盘写入次数，比循环save性能好
    /// - Parameter items: <#items description#>
    public func batchSave(_ items: [MediaMetadata]) async throws {
        do {
            try await dbQueue.write { db in
                for item in items {
                    try item.save(db)
                }
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 批量删除
    /// - Parameter items: <#items description#>
    public func batchDelete(_ ids: [MediaID]) async throws {
        guard !ids.isEmpty else { return }
        do {
            try await dbQueue.write { db in
                try _ = MediaMetadata
                    .filter(ids: ids)       /// 筛选出id匹配的行
                    .deleteAll(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    
    
    // MARK: - 查询
    /// 查询
    /// - Parameter filter: 过滤器
    /// - Returns: 元数据
    public func query(_ filter: MetadataFilter) async throws -> [MediaMetadata] {
        do {
            return try await dbQueue.read { db in
                try self.buildRequest(filter).fetchAll(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 计数
    /// - Parameter filter: <#filter description#>
    /// - Returns: <#description#>
    public func count(_ filter: MetadataFilter) async throws -> Int {
        do {
            return try await dbQueue.read { db in
                try self.buildRequest(filter).fetchCount(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 查询是否存在媒体项目
    public func exists(id: MediaID) async throws -> Bool {
        do {
            return try await dbQueue.read { db in
                try MediaMetadata.exists(db, key: id.raw)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 返回所有媒体ID
    /// - Returns: <#description#>
    public func allIDs() async throws -> [MediaID] {
        do {
            return try await dbQueue.read { db in
                try MediaMetadata
                    .select(MediaMetadata.CodingKeys.id)
                    .asRequest(of: MediaID.self)
                    .fetchAll(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 构建查询请求
    /// - Parameter filter: 过滤器
    /// - Returns: 查询请求
    private func buildRequest(_ filter: MetadataFilter) -> QueryInterfaceRequest<MediaMetadata> {
        typealias MC = MediaMetadata.CodingKeys
        var request = MediaMetadata.all()
        
        /// 类型过滤
        if let types = filter.types, !types.isEmpty {
            request = request.filter(types.contains(MC.type))
        }
        
        /// 创建时间过滤
        if let after = filter.createdAfter {
            request = request.filter(MC.createdAt >= after)
        }
        if let before = filter.createdBefore {
            request = request.filter(MC.createdAt <= before)
        }
        
        /// 文件大小过滤
        if let minSize = filter.minFileSize {
            request = request.filter(MC.fileSize >= minSize)
        }
        if let maxSize = filter.maxFileSize {
            request = request.filter(MC.fileSize <= maxSize)
        }
        
        /// 排序
        switch filter.sortBy {
        case .createdAt:
            request = filter.ascending == true ? request.order(MC.createdAt.asc) : request.order(MC.createdAt.desc)
        case .fileSize:
            request = filter.ascending == true ? request.order(MC.fileSize.asc) : request.order(MC.fileSize.desc)
        case .type:
            request = filter.ascending == true ? request.order(MC.type.asc) : request.order(MC.type.desc)
        }
        
        /// 分页
        if let limit = filter.limit {
            request = request.limit(limit, offset: filter.offset ?? 0)
        }
        
        return request
    }
    
    
    
    
    // MARK: - 清理
    public func vacuum() async throws {
        do {
            try await dbQueue.vacuum()
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    
    
    // MARK: - 便捷查询方法
    
    /// 获取所有媒体（分页）
    /// - Parameters:
    ///   - limit: 获取数量
    ///   - offset: 偏移值
    /// - Returns: 媒体元数据数组
    public func fetchAll(limit: Int = 100, offset: Int = 0) async throws -> [MediaMetadata] {
        try await query(MetadataFilter(limit: limit, offset: offset))
    }
    
    
    /// 获取对应类型的媒体
    public func fetch(types: [MediaType], limit: Int = 100, offset: Int = 0) async throws -> [MediaMetadata] {
        try await query(MetadataFilter(types: types, limit: limit, offset: offset))
    }
    
    
    /// 获取指定时间范围内的媒体
    public func fetch(from startDate: Date, to endDate: Date) async throws -> [MediaMetadata] {
        try await query(MetadataFilter(createdAfter: startDate, createdBefore: endDate))
    }
    
    
    /// 搜索包含指定键的媒体
    /// - Parameter userInfoKey: 键
    public func search(userInfoKey: String) async throws -> [MediaMetadata] {
        do {
            return try await dbQueue.read { db in
                try MediaMetadata
                    .filter(sql: "json_extract(userInfo, '$.\(userInfoKey)') IS NOT NULL")
                    .fetchAll(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    /// 搜索包含指定键值的媒体
    /// - Parameter userInfoKey: 键
    public func search(key: String, value: String) async throws -> [MediaMetadata] {
        do {
            return try await dbQueue.read { db in
                try MediaMetadata
                    .filter(sql: "json_extract(userInfo, '$.\(key)') = ?", arguments: [value])
                    .fetchAll(db)
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
    
    
    
    
    // MARK: - 统计方法
    /// 获取存储统计信息
    public func statistics() async throws -> StorageStatistics {
        do {
            return try await dbQueue.read { db in
                let totalCount = try MediaMetadata.fetchCount(db)
                let totalSize = try Int64.fetchOne(db, sql: "SELECT SUM(fileSize) FROM media") ?? 0
                
                var countByType: [MediaType: Int] = [:]
                var sizeByType: [MediaType: Int64] = [:]
                
                for type in MediaType.allCases {
                    let count = try MediaMetadata
                        .filter(MediaMetadata.CodingKeys.type == type)
                        .fetchCount(db)
                    
                    let size = try Int64.fetchOne(
                        db,
                        sql: "SELECT SUM(fileSize) FROM media WHERE type = ?",
                        arguments: [type.rawValue]
                    ) ?? 0
                    
                    countByType[type] = count
                    sizeByType[type] = size
                }
                
                return StorageStatistics(
                    totalCount: totalCount,
                    totalSize: totalSize,
                    countByType: countByType,
                    sizeByType: sizeByType
                )
            }
        } catch {
            throw MediaKitError.databaseError(underlying: error)
        }
    }
}
