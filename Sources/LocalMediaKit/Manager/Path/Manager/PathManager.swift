//
//  PathManager.swift
//  文件路径管理器类
//
//  Created by 庄七七 on 2026/1/25.
//

import Foundation

public final class PathManager: Sendable {
    /// 路径配置
    private let configuration: PathConfiguration
    
    /// 根目录
    private let rootDirectory: URL
    
    
    public init(configuration: PathConfiguration = .default) throws {
        /// 获取用户的路径配置，默认是默认配置
        self.configuration = configuration
        
        /// 如果用户自定义了根目录
        if let customRootDirectory = configuration.rootDirectory {
            self.rootDirectory = customRootDirectory
        }
        /// 如果没有定义根目录，使用默认根目录/Documents/LocalMediaKit
        else {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw MediaKitError.invalidRootDirectory(URL(fileURLWithPath: "/"))
            }
            self.rootDirectory = documentsDirectory.appendingPathComponent("LocalMediaKit")
        }
        
        try ensureRootDirectoryExist()
    }
    
    
    
    // MARK: - 私有方法
    /// 确保根目录存在，不存在则创建
    private func ensureRootDirectoryExist() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: rootDirectory.path) {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        }
    }
}
