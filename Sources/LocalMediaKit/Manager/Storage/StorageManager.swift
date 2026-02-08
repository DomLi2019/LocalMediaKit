//
//  StorageManager.swift
//  文件系统的包装
//
//  Created by 庄七七 on 2026/1/23.
//


import Foundation


/// 文件系统操作封装
public final class StorageManager: StorageManaging, Sendable {
    /// 安全余量，默认50MB
    private let safetyMargin: Int64 = 50 * 1024 * 1024
    
    
    // MARK: - 初始化
    public init() {}
    
    
    
    
    // MARK: - 写入
    public func write(_ data: Data, to url: URL) async throws {
        let available = availableDiskSpace()
        let fileSize = Int64(data.count)
        let required = fileSize + safetyMargin
        
        guard available >= required else {
            throw MediaKitError.insufficientDiskSpace(required: fileSize, available: available)
        }
        
        try await Task.detached { [self] in
            /// 确保父目录存在
            try self.ensureParentDirectoryExists(at: url)
            /// 原子性写入
            try data.write(to: url, options: .atomic)
        }.value
    }
    
    public func write(_ data: Data, to url: URL) throws {
        let available = availableDiskSpace()
        let fileSize = Int64(data.count)
        let required = fileSize + safetyMargin
        
        guard available >= required else {
            throw MediaKitError.insufficientDiskSpace(required: fileSize, available: available)
        }
        
        /// 确保父目录存在
        try ensureParentDirectoryExists(at: url)
        /// 原子性写入
        try data.write(to: url, options: .atomic)
    }
    
    
    
    
    // MARK: - 拷贝
    public func copy(at source: URL, to destination: URL) async throws {
        try await Task.detached { [self] in
            try self.copy(at: source, to: destination)
        }.value
    }
    
    public func copy(at source: URL, to destination: URL) throws {
        let available = availableDiskSpace()
        let fileSize = try fileSize(at: source)
        let required = fileSize + safetyMargin
        
        guard available >= required else {
            throw MediaKitError.insufficientDiskSpace(required: fileSize, available: available)
        }
        
        /// 获取临时文件路径
        let tempURL = temporaryFileURL(url: destination)
        
        /// 先尝试拷贝到临时文件路径，确保文件能完整拷贝
        try FileManager.default.copyItem(at: source, to: tempURL)
        
        /// 原子性移动临时文件到目标路径
        do {
            /// 方法已经确保父目录存在且目标路径文件不存在，再执行移动，不需要在这里处理了
            try move(at: tempURL, to: destination)
        } catch {
            /// 移动失败，删除临时路径文件，避免文件残留
            try? delete(at: tempURL)
            throw error
        }
    }
    
    
    
    
    // MARK: - 移动
    public func move(at source: URL, to destination: URL) async throws {
        try await Task.detached { [self] in
            try self.move(at: source, to: destination)
        }.value
    }
    
    public func move(at source: URL, to destination: URL) throws {
        /// 确保父目录存在
        try ensureParentDirectoryExists(at: destination)
        
        /// 如果目标路径文件已存在，先删除
        if exists(at: destination) {
            try delete(at: destination)
        }
        
        /// 移动文件到目标路径
        try FileManager.default.moveItem(at: source, to: destination)
    }
    
    
    
    
    // MARK: - 删除
    public func delete(at url: URL) async throws {
        try await Task.detached { [self] in
            try self.delete(at: url)
        }.value
    }
    
    public func delete(at url: URL) throws {
        guard exists(at: url) else { return }
        try FileManager.default.removeItem(at: url)
    }
    
    
    
    
    // MARK: - 读取Data
    public func read(from url: URL) async throws -> Data {
        return try await Task.detached { [self] in
            try self.read(from: url)
        }.value
    }
    
    public func read(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
    
    
    
    
    // MARK: - 拷贝到临时目录
    /// 拷贝到临时路径
    public func copyToTemp(at url: URL) throws -> URL {
        /// 检查文件是否存在
        guard exists(at: url) else {
            throw MediaKitError.fileNotFound(url)
        }
        /// 检查磁盘空间
        let available = availableDiskSpace()
        let fileSize = try fileSize(at: url)
        let required = fileSize + safetyMargin
        
        guard available >= required else {
            throw MediaKitError.insufficientDiskSpace(required: fileSize, available: available)
        }
        
        /// 获取临时文件路径
        let tempURL = temporaryFileURL(url: url)
        
        /// 先尝试拷贝到临时文件路径，确保文件能完整拷贝
        try FileManager.default.copyItem(at: url, to: tempURL)
        
        return tempURL
    }
    
    
    
    
    // MARK: - 文件大小
    public func fileSize(at url: URL) throws -> Int64 {
        /// 获取文件的[FileAttributeKey: Any]字典，如果文件不存在会抛出错误
        let attributes = try FileManager.default.attributesOfItem(atPath: url.compatPath)
        /// 获取[FileAttributeKey: Any]字典中的.size关键字的值，FileAttributeKey.size是系统预定义的Key，对应文件字节大小，类型是NSNumber，强转成Int64避免溢出
        guard let size = attributes[.size] as? Int64 else { return 0 }
        return size
    }
    
    
    
    
    // MARK: - 文件修改时间
    public func modificationDate(at url: URL) throws -> Date? {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.compatPath)
        return attributes[.modificationDate] as? Date
    }
    
    
    
    
    // MARK: - 可用磁盘空间
    public func availableDiskSpace(at url: URL = URL.filePath(NSHomeDirectory(), isDirectory: true)) -> Int64 {
        do {
            /// 获取”可用于重要用途的可用容量“
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage ?? 0
        } catch {
            return 0
        }
    }
    
    
    
    
    // MARK: - 是否存在、是否目录
    
    /// 检查文件是否存在
    /// - Parameter url: 路径
    /// - Returns: 是否存在
    public func exists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.compatPath)
    }
    
    
    /// 检查路径是否目录
    /// - Parameter url: 路径
    /// - Returns: 是否目录
    public func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.compatPath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    
    
    
    // MARK: - 辅助方法
    
    /// 确保父目录存在
    /// - Parameter url: 完整目录
    public func ensureParentDirectoryExists(at url: URL) throws {
        /// 获取父目录
        let parentDirectory = url.deletingLastPathComponent()
        /// 确保父目录存在
        try ensureDirectoryExists(at: parentDirectory)
    }
    
    
    /// 确保目录存在，不存在就创建
    /// - Parameter url: 目标目录
    public func ensureDirectoryExists(at url: URL) throws {
        /// 如果路径目录不存在，就创建该目录，否则直接返回，什么都不做
        guard !FileManager.default.fileExists(atPath: url.compatPath) else { return }
        
        /// 创建该目录
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    
    /// 创建临时文件路径
    /// - Parameter url: 目标路径
    /// - Returns: 临时文件路径
    public func temporaryFileURL(url: URL) -> URL {
        /// 获取目标文件的拓展名
        let ext = url.pathExtension
        
        /// 如果拓展名含.前缀，去掉
        let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
        
        /// 随机创建一个文件名 + 拓展名
        let fileName = UUID().uuidString + (cleanExt.isEmpty ? "" : ".\(cleanExt)")
        
        /// 获取系统默认临时路径
        let tempDirectory = FileManager.default.temporaryDirectory
        
        /// 返回临时文件路径（带拓展名）
        return tempDirectory.appendingPath(fileName)
    }
    
    
    /// 随机创建临时文件路径
    public func temporaryURL() -> URL {
        /// 随机创建一个文件名
        let fileName = UUID().uuidString
        
        /// 获取系统默认临时路径
        let tempDirectory = FileManager.default.temporaryDirectory
        
        /// 返回临时文件路径（不带拓展名）
        return tempDirectory.appendingPath(fileName)
    }
    
    
    /// 提取拓展名
    public func extractExtension(url: URL) -> String {
        /// 获取目标文件的拓展名
        let ext = url.pathExtension
        
        /// 如果拓展名含.前缀，去掉
        let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
        
        return cleanExt
    }
}




// MARK: - 兼容iOS 16.0新API
extension URL {
    /// 兼容 url.path 和 url.path(percnetEncoded: false)
    public var compatPath: String {
        if #available(iOS 16.0, macOS 13.0, *) {
            return path(percentEncoded: false)
        } else {
            return path
        }
    }
    
    /// 兼容 appendingPathComponent 和 appending(component: fileName)
    public func appendingPath(_ path: String, isDirectory: Bool = false) -> URL {
        if #available(iOS 16.0, macOS 13.0, *) {
            return appending(path: path, directoryHint: isDirectory ? .isDirectory : .notDirectory)
        } else {
            return appendingPathComponent(path, isDirectory: isDirectory)
        }
    }
    
    /// 兼容 URL(fileURLWithPath: isDirectory:) 和 URL(filePath: directoryHint:)
    public static func filePath(_ path: String, isDirectory: Bool) -> URL {
        if #available(iOS 16.0, macOS 13.0, *) {
            return URL(filePath: path, directoryHint: isDirectory ? .isDirectory : .notDirectory)
        } else {
            return URL(fileURLWithPath: path, isDirectory: isDirectory)
        }
    }
}
